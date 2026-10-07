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
  return portionReminders(
    now: now,
    today: Day.of(now),
    minutes: minutes,
    portions: plan.upcoming(Day.of(now), read, count: days),
    last: plan.target,
    days: days,
  );
}

/// The reminders for the coming days' [portions] (pages of the edition
/// being read) at [minutes] after midnight, from [today] (a logical day):
/// one a day with a portion, none past [last] or once its time has passed.
List<PlannedReminder> portionReminders({
  required DateTime now,
  required Day today,
  required int minutes,
  required Map<Day, PageRange> portions,
  Day? last,
  int days = reminderDaysAhead,
}) {
  final out = <PlannedReminder>[];
  for (var i = 0; i < days; i++) {
    final day = today.add(i);
    if (last != null && day.isAfter(last)) break;
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
