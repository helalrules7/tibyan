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

/// Days in a row with reading or listening, ending today, or yesterday when
/// today has had nothing yet (the day is not over, so nothing is lost).
int currentStreak(Set<Day> active, Day today) {
  var d = active.contains(today) ? today : today.add(-1);
  var n = 0;
  while (active.contains(d)) {
    n++;
    d = d.add(-1);
  }
  return n;
}

/// The gentle note shown with the streak (plan D9: a missed day is never
/// shown as a failure, and the notes can be turned off).
enum StreakNote {
  /// Nothing to say: no activity recorded yet.
  none,

  /// Read today, and on [currentStreak] days in a row.
  readToday,

  /// Not yet today; the run so far is waiting for today's page.
  continueToday,

  /// Some days since the last reading: an invitation, without counting.
  welcomeBack,
}

StreakNote streakNote(Set<Day> active, Day today) {
  if (active.isEmpty) return StreakNote.none;
  if (active.contains(today)) return StreakNote.readToday;
  if (active.contains(today.add(-1))) return StreakNote.continueToday;
  return StreakNote.welcomeBack;
}
