import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_database.dart';
import '../../../core/db/user_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/look_kit.dart';
import '../../../l10n/app_localizations.dart';
import '../../khatma/domain/day.dart';
import '../../khatma/domain/khatmah.dart';
import '../../khatma/domain/planner.dart';
import '../../khatma/domain/quran_index.dart';
import '../../khatma/domain/recovery.dart';
import '../../khatma/khatma_providers.dart'
    show quranIndexProvider, khatmaServiceProvider, reminderSchedulerProvider;
import '../../mushaf/mushaf_providers.dart';
import '../../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import '../data/hifz_repository.dart';
import '../data/recitation_store.dart';
import '../domain/hifz_goal.dart';
import '../hifz_providers.dart';
import 'hifz_screen.dart' show openHifzTest;
import 'progress_tabs.dart';
import '../../../core/ui/meta_separator.dart';

String _n(BuildContext context, int v) =>
    NumberFormatter(Localizations.localeOf(context))(v);

String goalTemplateLabel(AppLocalizations l, GoalTemplate? t) => switch (t) {
  GoalTemplate.amma => l.goalTemplateAmma,
  GoalTemplate.pageDaily => l.goalTemplatePageDaily,
  GoalTemplate.hizbWeekly => l.goalTemplateHizbWeekly,
  GoalTemplate.fixSurah => l.goalTemplateFixSurah,
  null => l.goalOpen,
};

/// Goals: each with today's «احفظ» and «راجع», its share mastered, the
/// kind catch-up of the khatma engine, pause and reminder.
class GoalsTab extends ConsumerWidget {
  const GoalsTab({super.key, this.onReview});

  /// Opens today's review (the «اليوم» tab).
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final goals = ref.watch(goalStatusesProvider).value;
    if (goals == null) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        FilledButton.icon(
          onPressed: () => showNewGoalSheet(context, ref),
          icon: const Icon(Icons.add),
          label: Text(l.goalNew),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            l.goalCountedByMastery,
            style: TextStyle(color: t.muted, fontSize: 13),
          ),
        ),
        if (goals.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.goalsEmpty),
            ),
          ),
        for (final (row, status) in goals)
          _GoalCard(row: row, status: status, onReview: onReview),
      ],
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.row, required this.status, this.onReview});

  final HifzGoalRow row;
  final GoalStatus status;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final index = ref.watch(quranIndexProvider).value;
    final surahs = ref.watch(surahsProvider).value;
    final due = dueToday(
      ref.watch(srsItemsProvider).value ?? const [],
      DateTime.now(),
    ).length;
    final hard = {
      for (final h in ref.watch(hardWordsProvider).value ?? const <HardWord>[])
        h.verse,
    }.length;
    final g = status.goal;
    final w = status.wird;
    final paused = g.status == KhatmahStatus.paused;
    final r = status.recovery;
    final pages = index?.madina1441;
    final title = goalTemplateLabel(l, g.template);
    final span = index == null
        ? ''
        : verseSpan(
            context,
            surahs,
            index.keyOf(g.rangeStart),
            index.keyOf(g.rangeEnd),
          );
    return LookGroup(
      icon: Icons.flag_outlined,
      title: title,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(span, style: TextStyle(color: t.muted, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ShareBars(
                      memorized: status.share,
                      mastered: status.share,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l.goalMasteredShare(hifzPercent(context, status.share)),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              MetaText(
                [
                  l.goalLeft(
                    r.remainingWeight.ceil(),
                    _n(context, r.remainingWeight.ceil()),
                  ),
                  if (g.targetDate case final d?)
                    l.goalUntil(reviewDay(context, d)),
                  if (paused) l.goalPaused,
                ].join(' · '),
                style: TextStyle(color: t.ink, fontSize: 13),
              ),
            ],
          ),
        ),
        if (status.complete)
          ListTile(
            leading: Icon(Icons.check_circle_outline, color: t.goldText),
            title: Text(l.goalComplete),
          )
        else ...[
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(
              g.review ? l.goalReview : l.goalMemorize,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              w == null || pages == null
                  ? l.goalNothingToday
                  : l.khatmaPagesRange(
                      _n(context, pages.pageOf(w.from)),
                      _n(context, pages.lastPageOf(w.to)),
                    ),
            ),
            trailing: w == null || index == null
                ? null
                : OutlinedButton(
                    onPressed: () {
                      final a = index.keyOf(w.from), b = index.keyOf(w.to);
                      openHifzTest(
                        context,
                        ref,
                        kind: HifzUnitKind.page,
                        fromRef: '${a.surah}:${a.ayah}',
                        toRef: '${b.surah}:${b.ayah}',
                      );
                    },
                    child: Text(l.goalRecite),
                  ),
          ),
          if (!g.review)
            ListTile(
              leading: const Icon(Icons.replay),
              title: Text(
                l.goalReview,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${l.goalReviewDue(_n(context, due))}\n'
                '${l.goalReviewHard(_n(context, hard))}',
              ),
              isThreeLine: true,
              onTap: onReview,
            ),
          if (r.suggest && !paused)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.goalBehind(
                      r.deficit.ceil(),
                      _n(context, r.deficit.ceil()),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => _recover(ref, (rc, k, lg, d) {
                          return rc.spread(k, lg, d);
                        }),
                        child: Text(l.goalCatchUp),
                      ),
                      if (g.targetDate != null)
                        OutlinedButton(
                          onPressed: () => _recover(ref, (rc, k, lg, d) {
                            return rc.extend(k, lg, d);
                          }),
                          child: Text(l.goalExtend),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
        OverflowBar(
          alignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => _reminder(context, ref),
              icon: const Icon(Icons.notifications_none, size: 18),
              label: Text(
                row.reminderTime == null
                    ? l.goalReminder
                    : l.goalReminderAt(
                        MaterialLocalizations.of(context).formatTimeOfDay(
                          TimeOfDay(
                            hour: row.reminderTime! ~/ 60,
                            minute: row.reminderTime! % 60,
                          ),
                        ),
                      ),
              ),
            ),
            if (!status.complete)
              TextButton(
                onPressed: () => paused ? _resume(ref) : _pause(ref),
                child: Text(paused ? l.goalResume : l.goalPause),
              ),
            IconButton(
              tooltip: l.goalDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await ref.read(userDatabaseProvider).deleteHifzGoal(row.id);
                await _refreshReminders(ref);
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _recover(
    WidgetRef ref,
    Khatmah Function(Recovery, Khatmah, Ledger, Day) how,
  ) async {
    final index = await ref.read(quranIndexProvider.future);
    final k = how(
      Recovery(Planner(index)),
      status.goal.khatmah,
      status.ledger,
      Day.today(),
    );
    await ref
        .read(userDatabaseProvider)
        .updateHifzGoal(
          row.id,
          HifzGoalsCompanion(
            recovery: Value(k.recovery?.toJson()),
            planFrom: Value(k.planFrom?.key),
            targetDate: Value(k.targetDate?.key),
            dailyWeight: Value(k.dailyWeight),
          ),
        );
    await _refreshReminders(ref);
  }

  Future<void> _pause(WidgetRef ref) async {
    final pauses = [...status.goal.pauses, PausePeriod(Day.today())];
    await ref
        .read(userDatabaseProvider)
        .updateHifzGoal(
          row.id,
          HifzGoalsCompanion(
            status: Value(KhatmahStatus.paused.name),
            pauses: Value(HifzGoal.pausesToJson(pauses)),
          ),
        );
    await _refreshReminders(ref);
  }

  Future<void> _resume(WidgetRef ref) async {
    final today = Day.today();
    final pauses = [
      for (final p in status.goal.pauses)
        if (p.to != null)
          p
        else if (p.from.isBefore(today))
          PausePeriod(p.from, today.add(-1)),
    ];
    await ref
        .read(userDatabaseProvider)
        .updateHifzGoal(
          row.id,
          HifzGoalsCompanion(
            status: Value(KhatmahStatus.active.name),
            pauses: Value(HifzGoal.pausesToJson(pauses)),
          ),
        );
    await _refreshReminders(ref);
  }

  Future<void> _reminder(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final now = row.reminderTime;
    if (now != null) {
      final off = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(l.goalReminder),
                onTap: () => Navigator.pop(context, false),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_off_outlined),
                title: Text(l.goalReminderOff),
                onTap: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      );
      if (off == null || !context.mounted) return;
      if (off) {
        await _setReminder(ref, null);
        return;
      }
    }
    final time = await showTimePicker(
      context: context,
      initialTime: now == null
          ? const TimeOfDay(hour: 6, minute: 0)
          : TimeOfDay(hour: now ~/ 60, minute: now % 60),
    );
    if (time == null) return;
    await ref.read(reminderSchedulerProvider).requestPermission();
    await _setReminder(ref, time.hour * 60 + time.minute);
  }

  Future<void> _setReminder(WidgetRef ref, int? minutes) async {
    await ref
        .read(userDatabaseProvider)
        .updateHifzGoal(
          row.id,
          HifzGoalsCompanion(reminderTime: Value(minutes)),
        );
    await _refreshReminders(ref);
  }
}

Future<void> _refreshReminders(WidgetRef ref) async {
  try {
    await ref.read(khatmaServiceProvider).refresh();
  } catch (e) {
    debugPrint('goals: reminder refresh failed: $e');
  }
}

/// A day as «الثلاثاء، ١٣ أكتوبر».
String reviewDay(BuildContext context, Day d) =>
    MaterialLocalizations.of(context).formatMediumDate(d.start);

// -- هدف جديد ----------------------------------------------------------------

/// Picks a ready goal or makes an open one, and saves it.
Future<void> showNewGoalSheet(BuildContext context, WidgetRef ref) async {
  final index = await ref.read(quranIndexProvider.future);
  final surahs = await ref.read(surahsProvider.future);
  if (!context.mounted) return;
  final goal = await showModalBottomSheet<HifzGoalsCompanion>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => LookTheme(
      child: _NewGoalSheet(index: index, surahs: surahs),
    ),
  );
  if (goal == null) return;
  await ref.read(userDatabaseProvider).addHifzGoal(goal);
  await _refreshReminders(ref);
}

class _NewGoalSheet extends StatefulWidget {
  const _NewGoalSheet({required this.index, required this.surahs});

  final QuranIndex index;
  final List<SurahRow> surahs;

  @override
  State<_NewGoalSheet> createState() => _NewGoalSheetState();
}

class _NewGoalSheetState extends State<_NewGoalSheet> {
  /// Null: the open goal.
  GoalTemplate? _template = GoalTemplate.amma;
  int _surah = 67;
  int _toSurah = 67;
  int _hizb = 60;
  double _days = 30;
  WirdUnit _unit = WirdUnit.page;

  String _name(int s) => Localizations.localeOf(context).languageCode == 'ar'
      ? widget.surahs[s - 1].nameAr
      : widget.surahs[s - 1].nameEn;

  Widget _surahPicker(String label, int value, ValueChanged<int> on) =>
      DropdownButtonFormField<int>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (var s = 1; s <= 114; s++)
            DropdownMenuItem(
              value: s,
              child: Text('${_n(context, s)}. ${_name(s)}'),
            ),
        ],
        onChanged: (v) => v == null ? null : setState(() => on(v)),
      );

  HifzGoalsCompanion _make() {
    final today = Day.today();
    final t = _template;
    if (t == null) {
      final a = widget.index.surahFirst(_surah);
      final last = _toSurah < _surah ? _surah : _toSurah;
      final b =
          widget.index.surahFirst(last) + widget.index.ayahCountOf(last) - 1;
      return HifzGoalsCompanion.insert(
        rangeStart: a,
        rangeEnd: b,
        startDate: today.key,
        targetDate: Value(today.add(_days.round() - 1).key),
        unit: Value(_unit.name),
      );
    }
    final p = templatePlan(t, widget.index, surah: _surah, hizb: _hizb);
    return HifzGoalsCompanion.insert(
      template: Value(t.name),
      rangeStart: p.from,
      rangeEnd: p.to,
      startDate: today.key,
      targetDate: Value(p.days == null ? null : today.add(p.days! - 1).key),
      dailyWeight: Value(p.daily),
      unit: Value(p.unit.name),
      review: Value(p.review),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = _template;
    final unitNames = {
      WirdUnit.page: l.hifzUnitPage,
      WirdUnit.rub: l.hifzUnitQuarter,
      WirdUnit.hizb: l.goalHizb,
      WirdUnit.juz: l.progressJuzCount,
    };
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LookSheetHeader(title: l.goalNew, icon: Icons.flag_outlined),
              const SizedBox(height: 12),
              RadioGroup<GoalTemplate?>(
                groupValue: t,
                onChanged: (v) => setState(() => _template = v),
                child: Column(
                  children: [
                    for (final x in [...GoalTemplate.values, null])
                      RadioListTile<GoalTemplate?>(
                        value: x,
                        title: Text(goalTemplateLabel(l, x)),
                        subtitle: x == null ? Text(l.goalOpenHint) : null,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (t == GoalTemplate.pageDaily)
                _surahPicker(l.goalFromSurah, _surah, (v) => _surah = v),
              if (t == GoalTemplate.fixSurah)
                _surahPicker(l.goalSurah, _surah, (v) => _surah = v),
              if (t == GoalTemplate.hizbWeekly)
                DropdownButtonFormField<int>(
                  initialValue: _hizb,
                  decoration: InputDecoration(labelText: l.goalHizb),
                  items: [
                    for (var h = 1; h <= 60; h++)
                      DropdownMenuItem(value: h, child: Text(_n(context, h))),
                  ],
                  onChanged: (v) =>
                      v == null ? null : setState(() => _hizb = v),
                ),
              if (t == null) ...[
                _surahPicker(l.goalFromSurah, _surah, (v) => _surah = v),
                const SizedBox(height: 8),
                _surahPicker(l.goalToSurah, _toSurah, (v) => _toSurah = v),
                const SizedBox(height: 12),
                Text(l.goalDays(_days.round(), _n(context, _days.round()))),
                Slider(
                  value: _days,
                  min: 7,
                  max: 365,
                  divisions: 358,
                  label: _n(context, _days.round()),
                  onChanged: (v) => setState(() => _days = v),
                ),
                DropdownButtonFormField<WirdUnit>(
                  initialValue: _unit,
                  decoration: InputDecoration(labelText: l.goalUnit),
                  items: [
                    for (final e in unitNames.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) =>
                      v == null ? null : setState(() => _unit = v),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context, _make()),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(l.goalCreate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
