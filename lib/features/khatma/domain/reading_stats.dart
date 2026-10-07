import 'day.dart';

/// What was read and heard on one day.
class DayActivity {
  DayActivity(this.day);

  final Day day;
  int pages = 0;
  int readingSeconds = 0;
  int listeningSeconds = 0;

  /// A day counts when a page was read, or a minute was spent reading or
  /// listening.
  bool get active =>
      pages > 0 || readingSeconds >= 60 || listeningSeconds >= 60;
}

/// Totals over a stretch of days.
class ReadingReport {
  ReadingReport({required this.days});

  /// Every day of the stretch, oldest first (inactive days included).
  final List<DayActivity> days;

  int get activeDays => days.where((d) => d.active).length;
  int get pages => days.fold(0, (s, d) => s + d.pages);
  int get readingMinutes =>
      (days.fold(0, (s, d) => s + d.readingSeconds) / 60).round();
  int get listeningMinutes =>
      (days.fold(0, (s, d) => s + d.listeningSeconds) / 60).round();
}

/// Builds the report for the [count] days ending [today] from sessions:
/// reading as (start, end, pages), listening as (start, seconds). A session
/// counts on the day it started.
ReadingReport buildReport({
  required Day today,
  required int count,
  required Iterable<(DateTime, DateTime, int)> reading,
  required Iterable<(DateTime, int)> listening,
}) {
  final first = today.add(-(count - 1));
  final days = [for (var i = 0; i < count; i++) DayActivity(first.add(i))];
  DayActivity? at(DateTime t) {
    final i = Day.of(t).difference(first);
    return i >= 0 && i < count ? days[i] : null;
  }

  for (final (start, end, pages) in reading) {
    final d = at(start);
    if (d == null) continue;
    d.pages += pages;
    d.readingSeconds += end.difference(start).inSeconds.clamp(0, 86400);
  }
  for (final (start, seconds) in listening) {
    at(start)?.listeningSeconds += seconds;
  }
  return ReadingReport(days: days);
}

/// «قرأت 24 من آخر 27 يوما» (decision 1: no days-in-a-row count): the
/// days with reading or listening in a window ending [today].
///
/// The window runs back to the first day with activity, at least
/// [minWindow] and at most [maxWindow] days (11..30 keeps the Arabic
/// counted noun in one form). Null with no activity in it.
({int read, int days})? readDaysOfLast(
  Set<Day> active,
  Day today, {
  int minWindow = 11,
  int maxWindow = 30,
}) {
  final first = today.add(-(maxWindow - 1));
  final inWindow = [
    for (final d in active)
      if (d.difference(first) >= 0 && today.difference(d) >= 0) d,
  ];
  if (inWindow.isEmpty) return null;
  final earliest = inWindow.reduce((a, b) => a.difference(b) <= 0 ? a : b);
  final days = (today.difference(earliest) + 1).clamp(minWindow, maxWindow);
  return (read: inWindow.length, days: days);
}

/// The gentle note shown above the week (plan D9 and decision 1: a missed
/// day is never shown as a failure, nothing counts days in a row, and the
/// notes can be turned off).
enum StreakNote {
  /// Nothing to say: no activity recorded yet, or not yet today after
  /// reading yesterday.
  none,

  /// Read today.
  readToday,

  /// Some days since the last reading: an invitation, without counting.
  welcomeBack,
}

StreakNote streakNote(Set<Day> active, Day today) {
  if (active.isEmpty) return StreakNote.none;
  if (active.contains(today)) return StreakNote.readToday;
  if (active.contains(today.add(-1))) return StreakNote.none;
  return StreakNote.welcomeBack;
}
