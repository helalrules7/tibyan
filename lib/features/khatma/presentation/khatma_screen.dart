import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/user_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../mushaf/mushaf_providers.dart';
import '../../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import '../domain/day.dart';
import '../domain/khatma_stats.dart';
import '../domain/khatmah.dart'
    show CountingMode, EntryPoint, Khatmah, KhatmahStatus;
import '../khatma_providers.dart';

enum _RecoveryAction { today, gradually, spread, extend }

String formatDay(BuildContext context, Day d) =>
    MaterialLocalizations.of(context).formatMediumDate(d.start);

String formatMinutes(BuildContext context, int minutes) =>
    MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));

/// The khatma being read: today's portion, progress, catch-up and the
/// reminder. Reports and the tadabbur journal open from the bar.
class KhatmaScreen extends ConsumerStatefulWidget {
  const KhatmaScreen({super.key, this.selectedPlanId});

  final String? selectedPlanId;

  @override
  ConsumerState<KhatmaScreen> createState() => _KhatmaScreenState();
}

class _KhatmaScreenState extends ConsumerState<KhatmaScreen> {
  bool _completionScheduled = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final statuses = ref.watch(khatmaStatusesProvider);
    final past = ref.watch(completedKhatmasProvider).value ?? const [];
    final completed = widget.selectedPlanId == null
        ? null
        : ref.watch(completedKhatmaStatusProvider(widget.selectedPlanId!));
    final event = ref.watch(khatmahEventsProvider);
    if (event != null && event.completed.isNotEmpty) {
      _scheduleCompletion(event.completed.last);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l.khatmaTitle),
        actions: [
          IconButton(
            tooltip: l.reportsTitle,
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => context.push('/khatma/reports'),
          ),
          IconButton(
            tooltip: l.journalTitle,
            icon: const Icon(Icons.edit_note_outlined),
            onPressed: () => context.push('/khatma/journal'),
          ),
        ],
      ),
      // A wide window (a tablet, the Mac) keeps a readable column.
      body: _Column(
        child: switch (statuses) {
          AsyncData(value: final plans) when widget.selectedPlanId != null =>
            _selectedPlanBody(plans, past, completed),
          AsyncData(value: final plans) when plans.isEmpty => _Empty(
            past: past,
          ),
          AsyncData(value: final plans) => _Overview(
            statuses: plans,
            past: past,
          ),
          AsyncError(:final error) => Center(child: Text('$error')),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Widget _selectedPlanBody(
    List<KhatmaStatus> statuses,
    List<KhatmaRow> past,
    AsyncValue<KhatmaStatus?>? completed,
  ) {
    final active = statuses
        .where((status) => status.khatmah.uuid == widget.selectedPlanId)
        .firstOrNull;
    if (active != null) return _Active(status: active, past: past);
    if (completed == null) return _Overview(statuses: statuses, past: past);
    return completed.when(
      data: (status) => status == null
          ? _Overview(statuses: statuses, past: past)
          : _Completed(status: status),
      error: (error, _) => Center(child: Text('$error')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  void _scheduleCompletion(Khatmah completed) {
    if (_completionScheduled) return;
    _completionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.read(khatmahEventsProvider.notifier).seen();
      await _showCompletion(completed);
      _completionScheduled = false;
    });
  }

  Future<void> _showCompletion(Khatmah completed) async {
    final l = AppLocalizations.of(context);
    final reuse = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.auto_awesome_outlined),
        title: Text(l.khatmaComplete),
        content: Text(l.khatmaCompletionBody, textAlign: TextAlign.justify),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.khatmaReusePlan),
          ),
        ],
      ),
    );
    if (reuse == true && mounted) await _reusePlan(completed);
  }

  Future<void> _reusePlan(Khatmah completed) async {
    final l = AppLocalizations.of(context);
    final today = ref.read(todayProvider);
    final duration = completed.targetDate?.difference(completed.startDate);
    final replay = completed.copyWith(
      uuid: '',
      startDate: today,
      targetDate: () =>
          duration == null ? null : today.add(duration < 0 ? 0 : duration),
      planFrom: () => null,
      isPrimary: true,
      status: KhatmahStatus.active,
      pauses: const [],
      createdAt: () => DateTime.now(),
      completedAt: () => null,
    );
    try {
      await ref.read(khatmaServiceProvider).createPlan(replay);
    } catch (error) {
      if (!mounted) rethrow;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.khatmaCreateFailed(error.toString()))),
      );
    }
  }
}

/// The khatma screens' width on a wide window: a centred column.
class _Column extends StatelessWidget {
  const _Column({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: child,
    ),
  );
}

class _Overview extends StatelessWidget {
  const _Overview({required this.statuses, required this.past});

  final List<KhatmaStatus> statuses;
  final List<KhatmaRow> past;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final primary =
        statuses.where((s) => s.khatmah.isPrimary).firstOrNull ??
        statuses.first;
    final others = statuses.where(
      (s) => s.khatmah.uuid != primary.khatmah.uuid,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l.khatmaPrimaryLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _PlanCard(status: primary),
        if (others.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            l.khatmaOtherPlans,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final status in others) _PlanCard(status: status),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => context.push('/khatma/new'),
          icon: const Icon(Icons.add),
          label: Text(l.khatmaNew),
        ),
        _Past(past: past),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.status});

  final KhatmaStatus status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          Uri(
            path: '/khatma',
            queryParameters: {'plan': status.khatmah.uuid},
          ).toString(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      status.row.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (!status.khatmah.isActive)
                    Text(l.khatmaPaused, style: TextStyle(color: t.muted)),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: status.progress,
                minHeight: 7,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(l.khatmaProgress(digits(status.done), digits(status.total))),
              if (status.todayPortion case final portion?)
                Text(
                  '${l.khatmaToday}: ${l.khatmaPagesRange(digits(portion.range.from), digits(portion.range.to))}',
                  style: TextStyle(color: t.muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.past});

  final List<KhatmaRow> past;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 24),
        Icon(Icons.auto_stories_outlined, size: 56, color: t.goldText),
        const SizedBox(height: 12),
        Text(
          l.khatmaEmptyTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          l.khatmaEmptyBody,
          textAlign: TextAlign.center,
          style: TextStyle(color: t.muted, height: 1.6),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => context.push('/khatma/new'),
          icon: const Icon(Icons.add),
          label: Text(l.khatmaNew),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        _Past(past: past),
      ],
    );
  }
}

class _Active extends ConsumerWidget {
  const _Active({required this.status, required this.past});

  final KhatmaStatus status;
  final List<KhatmaRow> past;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final s = status;
    final service = ref.read(khatmaServiceProvider);
    final portion = s.todayPortion;
    final reminder = s.row.reminderTime;
    // Readings a khatma in `ask` mode has not been asked about, or that
    // went unanswered in the reader (plan 4.3).
    final pending = [
      for (final p in ref.watch(pendingCreditsProvider).value ?? const [])
        if (p.khatmaUuid == s.khatmah.uuid) p,
    ];
    final title = Theme.of(context).textTheme.titleMedium
        ?.copyWith(color: t.goldText, fontWeight: FontWeight.w600);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: l.khatmaTabPlan),
              Tab(text: l.khatmaTabStats),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.khatmaToday, style: title),
                            const SizedBox(height: 8),
                            if (portion != null) ...[
                              Text(
                                l.khatmaPagesRange(
                                  digits(portion.range.from),
                                  digits(portion.range.to),
                                ),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                l.khatmaPagesCount(digits(portion.pages)),
                                style: TextStyle(color: t.muted),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () async => context.go(
                                  await service.routeFor(
                                    Uri(
                                      queryParameters: {
                                        'page': '${portion.range.from}',
                                        'edition': s.edition.name,
                                      },
                                    ),
                                    entry: EntryPoint.khatmahContinue,
                                  ),
                                ),
                                icon: const Icon(Icons.menu_book_outlined),
                                label: Text(l.khatmaReadNow),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    service.markTodayRead(uuid: s.khatmah.uuid),
                                child: Text(l.khatmaMarkRead),
                              ),
                            ] else if (s.complete) ...[
                              Text(
                                l.khatmaComplete,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: t.control,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(l.khatmaTodayDone)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: () async {
                                  final next = s.nextPage;
                                  if (next == null) return;
                                  context.go(
                                    await service.routeFor(
                                      Uri(
                                        queryParameters: {
                                          'page': '$next',
                                          'edition': s.edition.name,
                                        },
                                      ),
                                      entry: EntryPoint.khatmahContinue,
                                    ),
                                  );
                                },
                                child: Text(l.khatmaContinue),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (s.behind > 0 && portion != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l.khatmaBehindTitle(digits(s.behind)),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l.khatmaBehindBody,
                                textAlign: TextAlign.justify,
                                style: TextStyle(color: t.muted, height: 1.5),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: () => _chooseRecovery(
                                  context,
                                  service,
                                  s.khatmah.uuid,
                                ),
                                icon: const Icon(Icons.tune),
                                label: Text(l.khatmaReplan),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (pending.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.khatmaPendingTitle, style: title),
                              for (final p in pending)
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        l.khatmaPendingOn(
                                          formatDay(context, p.day),
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          service.declinePending(p),
                                      child: Text(l.askCreditNo),
                                    ),
                                    TextButton(
                                      onPressed: () => service.acceptPending(p),
                                      child: Text(l.askCreditCount),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.row.title, style: title),
                            Text(
                              l.khatmaEditionNote(editionName(l, s.edition)),
                              style: TextStyle(color: t.muted, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            Semantics(
                              value: '${(s.fraction * 100).round()}%',
                              child: LinearProgressIndicator(
                                value: s.fraction,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l.khatmaProgress(digits(s.done), digits(s.total)),
                            ),
                            Text(
                              '${l.khatmaEnds(formatDay(context, s.target))} · '
                              '${l.khatmaDaysLeft(digits(s.daysLeft))}',
                              style: TextStyle(color: t.muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.notifications_outlined),
                        title: Text(l.khatmaReminder),
                        subtitle: Text(
                          reminder == null
                              ? l.khatmaReminderOff
                              : formatMinutes(context, reminder),
                        ),
                        // Tapping the row changes the time.
                        onTap: () => _pickReminder(
                          context,
                          service,
                          reminder,
                          uuid: s.khatmah.uuid,
                        ),
                        trailing: Switch(
                          value: reminder != null,
                          onChanged: (on) => on
                              ? _pickReminder(
                                  context,
                                  service,
                                  null,
                                  uuid: s.khatmah.uuid,
                                )
                              : service.setReminder(null, uuid: s.khatmah.uuid),
                        ),
                      ),
                    ),
                    if (!s.khatmah.isPrimary)
                      OutlinedButton.icon(
                        onPressed: () => service.setPrimary(s.khatmah.uuid),
                        icon: const Icon(Icons.star_outline),
                        label: Text(l.khatmaSetPrimary),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => s.khatmah.isActive
                          ? service.pause(s.khatmah.uuid)
                          : service.resume(s.khatmah.uuid),
                      icon: Icon(
                        s.khatmah.isActive
                            ? Icons.pause_circle_outline
                            : Icons.play_arrow,
                      ),
                      label: Text(
                        s.khatmah.isActive ? l.khatmaPause : l.khatmaResume,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _editSettings(context, service, s.khatmah),
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(l.khatmaSettings),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/khatma/new'),
                      icon: const Icon(Icons.add),
                      label: Text(l.khatmaNew),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (d) => AlertDialog(
                            title: Text(l.khatmaDelete),
                            content: Text(l.khatmaDeleteBody),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(d).pop(false),
                                child: Text(l.cancel),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(d).pop(true),
                                child: Text(l.delete),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) await service.delete(s.row.uuid);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l.khatmaDelete),
                    ),
                    _Past(past: past),
                  ],
                ),
                _KhatmaStatsTab(status: s),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Completed extends StatelessWidget {
  const _Completed({required this.status});

  final KhatmaStatus status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        ListTile(
          title: Text(status.row.title),
          subtitle: status.row.completedAt == null
              ? null
              : Text(
                  l.khatmaCompletedOn(
                    formatDay(context, Day.of(status.row.completedAt!)),
                  ),
                ),
        ),
        Expanded(child: _KhatmaStatsTab(status: status)),
      ],
    );
  }
}

class _KhatmaStatsTab extends StatefulWidget {
  const _KhatmaStatsTab({required this.status});

  final KhatmaStatus status;

  @override
  State<_KhatmaStatsTab> createState() => _KhatmaStatsTabState();
}

class _KhatmaStatsTabState extends State<_KhatmaStatsTab> {
  late DateTime _anchor = DateTime.now();
  _KhatmaStatsPeriod _period = _KhatmaStatsPeriod.month;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final localization = MaterialLocalizations.of(context);
    final current = DateTime.now();
    final first = switch (_period) {
      _KhatmaStatsPeriod.week => _weekStart(_anchor),
      _KhatmaStatsPeriod.month => DateTime(_anchor.year, _anchor.month),
      _KhatmaStatsPeriod.year => DateTime(_anchor.year),
    };
    final days = switch (_period) {
      _KhatmaStatsPeriod.week => 7,
      _KhatmaStatsPeriod.month => DateTime(
        _anchor.year,
        _anchor.month + 1,
        0,
      ).day,
      _KhatmaStatsPeriod.year =>
        DateTime(_anchor.year, 3, 0).day == 29 ? 366 : 365,
    };
    final totals = KhatmaPeriodStats.forDays(
      widget.status.ledger,
      Day.of(first),
      days,
    );
    final canAdvance = switch (_period) {
      _KhatmaStatsPeriod.week => _weekStart(
        _anchor,
      ).isBefore(_weekStart(current)),
      _KhatmaStatsPeriod.month => DateTime(
        _anchor.year,
        _anchor.month,
      ).isBefore(DateTime(current.year, current.month)),
      _KhatmaStatsPeriod.year => _anchor.year < current.year,
    };
    final periodLabel = switch (_period) {
      _KhatmaStatsPeriod.week =>
        '${localization.formatShortDate(first)} – ${localization.formatShortDate(DateTime(first.year, first.month, first.day + 6))}',
      _KhatmaStatsPeriod.month => localization.formatMonthYear(first),
      _KhatmaStatsPeriod.year => digits(_anchor.year),
    };
    final weekdays = localization.narrowWeekdays;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final visibleDays = _period == _KhatmaStatsPeriod.week
        ? 7
        : _period == _KhatmaStatsPeriod.month
        ? days
        : 0;
    final leadingDays = _period == _KhatmaStatsPeriod.month
        ? first.weekday - DateTime.monday
        : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<_KhatmaStatsPeriod>(
          segments: [
            ButtonSegment(
              value: _KhatmaStatsPeriod.week,
              label: Text(l.khatmaStatsWeek),
            ),
            ButtonSegment(
              value: _KhatmaStatsPeriod.month,
              label: Text(l.khatmaStatsMonth),
            ),
            ButtonSegment(
              value: _KhatmaStatsPeriod.year,
              label: Text(l.khatmaStatsYear),
            ),
          ],
          selected: {_period},
          onSelectionChanged: (selected) =>
              setState(() => _period = selected.single),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: _period == _KhatmaStatsPeriod.month
                          ? localization.previousMonthTooltip
                          : l.khatmaStatsPreviousPeriod,
                      onPressed: () => setState(() {
                        _anchor = switch (_period) {
                          _KhatmaStatsPeriod.week => DateTime(
                            _anchor.year,
                            _anchor.month,
                            _anchor.day - 7,
                          ),
                          _KhatmaStatsPeriod.month => DateTime(
                            _anchor.year,
                            _anchor.month - 1,
                          ),
                          _KhatmaStatsPeriod.year => DateTime(_anchor.year - 1),
                        };
                      }),
                      icon: Icon(
                        rtl ? Icons.chevron_right : Icons.chevron_left,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        periodLabel,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: _period == _KhatmaStatsPeriod.month
                          ? localization.nextMonthTooltip
                          : l.khatmaStatsNextPeriod,
                      onPressed: canAdvance
                          ? () => setState(() {
                              _anchor = switch (_period) {
                                _KhatmaStatsPeriod.week => DateTime(
                                  _anchor.year,
                                  _anchor.month,
                                  _anchor.day + 7,
                                ),
                                _KhatmaStatsPeriod.month => DateTime(
                                  _anchor.year,
                                  _anchor.month + 1,
                                ),
                                _KhatmaStatsPeriod.year => DateTime(
                                  _anchor.year + 1,
                                ),
                              };
                            })
                          : null,
                      icon: Icon(
                        rtl ? Icons.chevron_left : Icons.chevron_right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_period != _KhatmaStatsPeriod.year)
                  GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 4,
                    children: [
                      for (var weekday = 0; weekday < 7; weekday++)
                        Center(
                          child: Text(
                            weekdays[(weekday + DateTime.monday) % 7],
                            style: TextStyle(color: colors.muted, fontSize: 12),
                          ),
                        ),
                      for (var i = 0; i < leadingDays; i++)
                        const SizedBox.shrink(),
                      for (var i = 0; i < visibleDays; i++)
                        _CalendarDay(
                          date: DateTime(
                            first.year,
                            first.month,
                            first.day + i,
                          ),
                          digits: digits,
                          active:
                              widget.status.ledger.weightOn(
                                Day.of(
                                  DateTime(
                                    first.year,
                                    first.month,
                                    first.day + i,
                                  ),
                                ),
                              ) >
                              0,
                          activeColor: colors.control,
                          activeTextColor: colors.onControl,
                          textColor: colors.ink,
                          activeLabel: l.reportsDayRead,
                        ),
                    ],
                  )
                else
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.8,
                    children: [
                      for (
                        var month = 1;
                        month <=
                            (_anchor.year == current.year ? current.month : 12);
                        month++
                      )
                        _YearMonthSummary(
                          month: DateTime(_anchor.year, month),
                          status: widget.status,
                          onTap: () => setState(() {
                            _period = _KhatmaStatsPeriod.month;
                            _anchor = DateTime(_anchor.year, month);
                          }),
                          digits: digits,
                          formatMonth: localization.formatMonthYear,
                          muted: colors.muted,
                          daysLabel: l.reportsDays,
                          pagesLabel: l.khatmaStatsPageEquivalents,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.8,
          children: [
            _KhatmaStat(
              label: l.khatmaStatsPageEquivalents,
              value: digits(totals.weight.round()),
            ),
            _KhatmaStat(
              label: l.reportsDays,
              value: digits(totals.readingDays),
            ),
            _KhatmaStat(
              label: l.khatmaStatsSessions,
              value: digits(totals.sessions),
            ),
            _KhatmaStat(
              label: l.khatmaStatsMinutes,
              value: digits((totals.seconds / 60).round()),
            ),
          ],
        ),
        if (totals.readingDays == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l.khatmaStatsNoActivity,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.muted),
            ),
          ),
      ],
    );
  }
}

enum _KhatmaStatsPeriod { week, month, year }

DateTime _weekStart(DateTime date) =>
    DateTime(date.year, date.month, date.day - date.weekday + DateTime.monday);

class _YearMonthSummary extends StatelessWidget {
  const _YearMonthSummary({
    required this.month,
    required this.status,
    required this.onTap,
    required this.digits,
    required this.formatMonth,
    required this.muted,
    required this.daysLabel,
    required this.pagesLabel,
  });

  final DateTime month;
  final KhatmaStatus status;
  final VoidCallback onTap;
  final NumberFormatter digits;
  final String Function(DateTime) formatMonth;
  final Color muted;
  final String daysLabel;
  final String pagesLabel;

  @override
  Widget build(BuildContext context) {
    final totals = KhatmaPeriodStats.forDays(
      status.ledger,
      Day.of(month),
      DateTime(month.year, month.month + 1, 0).day,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatMonth(month),
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                '$daysLabel: ${digits(totals.readingDays)} · $pagesLabel: ${digits(totals.weight.round())}',
                style: TextStyle(color: muted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.digits,
    required this.active,
    required this.activeColor,
    required this.activeTextColor,
    required this.textColor,
    required this.activeLabel,
  });

  final DateTime date;
  final NumberFormatter digits;
  final bool active;
  final Color activeColor;
  final Color activeTextColor;
  final Color textColor;
  final String activeLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: active
        ? '${MaterialLocalizations.of(context).formatFullDate(date)}, $activeLabel'
        : MaterialLocalizations.of(context).formatFullDate(date),
    child: Center(
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? activeColor : null,
        ),
        child: Text(
          digits(date.day),
          style: TextStyle(
            color: active ? activeTextColor : textColor,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    ),
  );
}

class _KhatmaStat extends StatelessWidget {
  const _KhatmaStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _chooseRecovery(
  BuildContext context,
  KhatmaService service,
  String uuid,
) async {
  final l = AppLocalizations.of(context);
  final action = await showModalBottomSheet<_RecoveryAction>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(l.khatmaReplan),
            subtitle: Text(l.khatmaBehindBody, textAlign: TextAlign.justify),
          ),
          ListTile(
            leading: const Icon(Icons.today_outlined),
            title: Text(l.khatmaCatchUpToday),
            onTap: () => Navigator.of(sheetContext).pop(_RecoveryAction.today),
          ),
          ListTile(
            leading: const Icon(Icons.trending_up),
            title: Text(l.khatmaCatchUpGradually),
            onTap: () =>
                Navigator.of(sheetContext).pop(_RecoveryAction.gradually),
          ),
          ListTile(
            leading: const Icon(Icons.balance_outlined),
            title: Text(l.khatmaSpread),
            onTap: () => Navigator.of(sheetContext).pop(_RecoveryAction.spread),
          ),
          ListTile(
            leading: const Icon(Icons.event_repeat_outlined),
            title: Text(l.khatmaExtend),
            onTap: () => Navigator.of(sheetContext).pop(_RecoveryAction.extend),
          ),
        ],
      ),
    ),
  );
  if (action == null) return;
  try {
    switch (action) {
      case _RecoveryAction.today:
        await service.catchUpToday(uuid: uuid);
      case _RecoveryAction.gradually:
        await service.catchUpGradually(uuid: uuid);
      case _RecoveryAction.spread:
        await service.spreadRest(uuid: uuid);
      case _RecoveryAction.extend:
        await service.moveTarget(uuid: uuid);
    }
  } catch (error) {
    if (!context.mounted) rethrow;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.khatmaSaveFailed(error.toString()))),
    );
  }
}

Future<void> _editSettings(
  BuildContext context,
  KhatmaService service,
  Khatmah plan,
) async {
  final l = AppLocalizations.of(context);
  final updated = await showModalBottomSheet<Khatmah>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _KhatmaSettingsSheet(plan: plan),
  );
  if (updated == null) return;
  try {
    await service.updatePlan(updated);
  } catch (error) {
    if (!context.mounted) rethrow;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.khatmaSaveFailed(error.toString()))),
    );
  }
}

class _KhatmaSettingsSheet extends StatefulWidget {
  const _KhatmaSettingsSheet({required this.plan});

  final Khatmah plan;

  @override
  State<_KhatmaSettingsSheet> createState() => _KhatmaSettingsSheetState();
}

class _KhatmaSettingsSheetState extends State<_KhatmaSettingsSheet> {
  late final TextEditingController _title;
  late CountingMode _counting;
  late bool _autoRestart;
  late final Set<int> _restWeekdays;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.plan.title);
    _counting =
        widget.plan.isPrimary && widget.plan.counting == CountingMode.ask
        ? CountingMode.auto
        : widget.plan.counting;
    _autoRestart = widget.plan.autoRestart;
    _restWeekdays = {...widget.plan.restWeekdays};
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final weekdays = MaterialLocalizations.of(context).narrowWeekdays;
    final colors = context.tokens.colors;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.khatmaSettings,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: l.khatmaNameLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CountingMode>(
              initialValue: _counting,
              decoration: InputDecoration(
                labelText: l.khatmaCountingMode,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: CountingMode.auto,
                  child: Text(l.khatmaCountAuto),
                ),
                if (!widget.plan.isPrimary)
                  DropdownMenuItem(
                    value: CountingMode.ask,
                    child: Text(l.khatmaCountAsk),
                  ),
                DropdownMenuItem(
                  value: CountingMode.manual,
                  child: Text(l.khatmaCountManual),
                ),
              ],
              onChanged: (mode) {
                if (mode != null) setState(() => _counting = mode);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.khatmaAutoRestart),
              value: _autoRestart,
              onChanged: (value) => setState(() => _autoRestart = value),
            ),
            const SizedBox(height: 8),
            Text(l.khatmaRestDays),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (
                  var weekday = DateTime.monday;
                  weekday <= DateTime.sunday;
                  weekday++
                )
                  FilterChip(
                    label: Text(weekdays[weekday % 7]),
                    selected: _restWeekdays.contains(weekday),
                    onSelected: (selected) => setState(() {
                      if (selected && _restWeekdays.length < 6) {
                        _restWeekdays.add(weekday);
                      } else {
                        _restWeekdays.remove(weekday);
                      }
                    }),
                  ),
              ],
            ),
            if (_restWeekdays.length >= 6) ...[
              const SizedBox(height: 6),
              Text(
                l.khatmaAtLeastOneReadingDay,
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _restWeekdays.length < 7 ? _save : null,
                child: Text(l.khatmaSaveSettings),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final title = _title.text.trim();
    Navigator.of(context).pop(
      widget.plan.copyWith(
        title: title.isEmpty ? widget.plan.title : title,
        counting: _counting,
        autoRestart: _autoRestart,
        restWeekdays: Set.unmodifiable(_restWeekdays),
      ),
    );
  }
}

Future<void> _pickReminder(
  BuildContext context,
  KhatmaService service,
  int? current, {
  required String uuid,
}) async {
  final at = current ?? 20 * 60;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: at ~/ 60, minute: at % 60),
  );
  if (time != null) {
    try {
      await service.setReminder(time.hour * 60 + time.minute, uuid: uuid);
    } catch (error) {
      if (!context.mounted) rethrow;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.khatmaSaveFailed(error.toString()))),
      );
    }
  }
}

class _Past extends StatelessWidget {
  const _Past({required this.past});

  final List<KhatmaRow> past;

  @override
  Widget build(BuildContext context) {
    if (past.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.khatmaPast,
            style: TextStyle(color: t.goldText, fontWeight: FontWeight.w600),
          ),
          for (final k in past)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.task_alt, color: t.control),
              title: Text(k.title),
              subtitle: Text(
                l.khatmaCompletedOn(formatDay(context, Day.of(k.completedAt!))),
              ),
              onTap: () => context.push(
                Uri(
                  path: '/khatma',
                  queryParameters: {'plan': k.uuid},
                ).toString(),
              ),
            ),
        ],
      ),
    );
  }
}
