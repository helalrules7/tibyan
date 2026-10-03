import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/user_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import '../domain/day.dart';
import '../domain/reading_stats.dart';
import '../khatma_providers.dart';

final _readingProvider = StreamProvider.family<List<ReadingSessionRow>, int>(
  (ref, days) => ref
      .watch(activityRepositoryProvider)
      .watchReadingSince(ref.watch(todayProvider).add(-(days - 1)).start),
);

final _listeningProvider =
    StreamProvider.family<List<ListeningSessionRow>, int>(
      (ref, days) => ref
          .watch(activityRepositoryProvider)
          .watchListeningSince(ref.watch(todayProvider).add(-(days - 1)).start),
    );

/// Reading and listening over the last [days] days.
final reportProvider = Provider.family<ReadingReport?, int>((ref, days) {
  final reading = ref.watch(_readingProvider(days)).value;
  final listening = ref.watch(_listeningProvider(days)).value;
  if (reading == null || listening == null) return null;
  return buildReport(
    today: ref.watch(todayProvider),
    count: days,
    reading: [for (final r in reading) (r.startedAt, r.endedAt, r.pages)],
    listening: [for (final s in listening) (s.startedAt, s.seconds)],
  );
});

/// Days with reading or listening over the last year, for the streak.
final activeDaysProvider = Provider<Set<Day>>(
  (ref) => {
    for (final d in ref.watch(reportProvider(366))?.days ?? const [])
      if (d.active) d.day,
  },
);

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final report = ref.watch(reportProvider(_days));
    final week = ref.watch(reportProvider(7));
    final active = ref.watch(activeDaysProvider);
    final notesOn = ref.watch(streakNotesProvider);
    final today = ref.watch(todayProvider);
    final streak = currentStreak(active, today);
    final note = switch (streakNote(active, today)) {
      StreakNote.none => null,
      StreakNote.readToday => l.streakReadToday(digits(streak)),
      StreakNote.continueToday => l.streakContinue(digits(streak)),
      StreakNote.welcomeBack => l.streakWelcome,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l.reportsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (notesOn && note != null)
            Card(
              child: ListTile(
                leading: Icon(Icons.wb_twilight_outlined, color: t.goldText),
                title: Text(note),
              ),
            ),
          if (week != null) _WeekStrip(report: week),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 7, label: Text(l.reportsWeek)),
              ButtonSegment(value: 30, label: Text(l.reportsMonth)),
            ],
            selected: {_days},
            onSelectionChanged: (s) => setState(() => _days = s.single),
          ),
          const SizedBox(height: 12),
          if (report != null)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.7,
              children: [
                _Stat(l.reportsDays, digits(report.activeDays)),
                _Stat(l.reportsPages, digits(report.pages)),
                _Stat(l.reportsReadingMinutes, digits(report.readingMinutes)),
                _Stat(
                  l.reportsListeningMinutes,
                  digits(report.listeningMinutes),
                ),
              ],
            ),
          if (report != null && report.activeDays == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l.reportsEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(color: t.muted),
              ),
            ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.streakNotesToggle),
            subtitle: Text(l.streakNotesHint),
            value: notesOn,
            onChanged: (on) => ref.read(streakNotesProvider.notifier).set(on),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
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
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: t.ink,
              ),
            ),
            Text(label, style: TextStyle(color: t.muted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// The last seven days: a filled dot on days with reading or listening.
/// Other days are plain, never marked as missed (plan D9).
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.report});

  final ReadingReport report;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final names = MaterialLocalizations.of(context).narrowWeekdays;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final d in report.days)
              Semantics(
                label: d.active ? l.reportsDayRead : null,
                child: Column(
                  children: [
                    Text(
                      names[d.day.start.weekday % 7],
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: d.active ? t.control : null,
                        border: Border.all(
                          color: d.active ? t.control : t.border,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
