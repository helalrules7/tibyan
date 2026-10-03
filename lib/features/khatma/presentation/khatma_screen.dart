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
import '../khatma_providers.dart';

String formatDay(BuildContext context, Day d) =>
    MaterialLocalizations.of(context).formatMediumDate(d.start);

String formatMinutes(BuildContext context, int minutes) =>
    MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));

/// The khatma being read: today's portion, progress, catch-up and the
/// reminder. Reports and the tadabbur journal open from the bar.
class KhatmaScreen extends ConsumerWidget {
  const KhatmaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final status = ref.watch(khatmaStatusProvider);
    final past = ref.watch(completedKhatmasProvider).value ?? const [];
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
      body: switch (status) {
        AsyncData(value: final s?) => _Active(status: s, past: past),
        AsyncData() => _Empty(past: past),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
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
    final title = Theme.of(context).textTheme.titleMedium
        ?.copyWith(color: t.goldText, fontWeight: FontWeight.w600);

    return ListView(
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
                            'edition': s.row.edition,
                          },
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(l.khatmaReadNow),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  TextButton(
                    onPressed: service.markTodayRead,
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
                      Icon(Icons.check_circle_outline, color: t.control),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l.khatmaTodayDone)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final next = s.plan.nextPage(s.read);
                      if (next == null) return;
                      context.go(
                        await service.routeFor(
                          Uri(
                            queryParameters: {
                              'page': '$next',
                              'edition': s.row.edition,
                            },
                          ),
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
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.khatmaBehindBody,
                    style: TextStyle(color: t.muted, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: service.spreadRest,
                    child: Text(l.khatmaSpread),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton(
                    onPressed: service.moveTarget,
                    child: Text(
                      '${l.khatmaExtend} · '
                      '${formatDay(context, s.extendedTarget())}',
                    ),
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
                Text(l.khatmaProgress(digits(s.done), digits(s.total))),
                Text(
                  '${l.khatmaEnds(formatDay(context, s.plan.target))} · '
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
            onTap: () => _pickReminder(context, service, reminder),
            trailing: Switch(
              value: reminder != null,
              onChanged: (on) => on
                  ? _pickReminder(context, service, null)
                  : service.setReminder(null),
            ),
          ),
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
    );
  }
}

Future<void> _pickReminder(
  BuildContext context,
  KhatmaService service,
  int? current,
) async {
  final at = current ?? 20 * 60;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: at ~/ 60, minute: at % 60),
  );
  if (time != null) await service.setReminder(time.hour * 60 + time.minute);
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
            ),
        ],
      ),
    );
  }
}
