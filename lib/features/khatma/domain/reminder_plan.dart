import 'day.dart';
import 'khatma_plan.dart';

/// Days of reminders kept scheduled ahead. iOS keeps at most 64 pending
/// notifications per app, so reminders are scheduled one at a time for the
/// next days and scheduled again (rolling) whenever the app opens, the
/// plan changes or a portion is read.
const reminderDaysAhead = 14;

/// First notification id of the khatma reminders; they use
/// `reminderIdBase .. reminderIdBase + reminderDaysAhead - 1`.
const reminderIdBase = 7100;

/// One reminder to schedule.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.day,
    this.range,
  });

  final int id;

  /// Local time it shows.
  final DateTime at;
  final Day day;

  /// The day's portion, when known.
  final PageRange? range;

  @override
  String toString() => 'PlannedReminder($id, $at, $range)';
}

/// The reminders for the coming days at [minutes] after midnight: one a
/// day while the khatma lasts, with that day's portion. A day whose time
/// has passed, or whose portion is already read, gets none.
List<PlannedReminder> planReminders({
  required DateTime now,
  required int minutes,
  required KhatmaPlan plan,
  required Set<int> read,
  int days = reminderDaysAhead,
}) {
  if (plan.isComplete(read)) return const [];
  final today = Day.of(now);
  final portions = plan.upcoming(today, read, count: days);
  final out = <PlannedReminder>[];
  for (var i = 0; i < days; i++) {
    final day = today.add(i);
    if (day.isAfter(plan.target)) break;
    final range = portions[day];
    // Nothing due that day (already read ahead, or a day with no new unit).
    if (range == null) continue;
    // Built from the clock time, not midnight plus a duration, so a
    // daylight-saving change does not move it.
    final at = DateTime(
      day.year,
      day.month,
      day.day,
      minutes ~/ 60,
      minutes % 60,
    );
    if (!at.isAfter(now)) continue;
    out.add(
      PlannedReminder(id: reminderIdBase + i, at: at, day: day, range: range),
    );
  }
  return out;
}
