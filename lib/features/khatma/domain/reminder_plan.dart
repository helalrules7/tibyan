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

/// Per-plan rolling reminders: three days for up to twenty khatmas.
const khatmaReminderDaysAhead = 3;
const maxKhatmaReminderPlans = 20;
const khatmaReminderIdBase = 7200;
const khatmaReminderTypesPerDay = 5;
const maxKhatmaNotificationsPerDay = 3;
const maxKhatmaNotificationsPerPlanDay = 2;
const khatmaCompletionIdBase =
    khatmaReminderIdBase +
    maxKhatmaReminderPlans *
        khatmaReminderDaysAhead *
        khatmaReminderTypesPerDay;
const khatmaReminderIdLimit = khatmaCompletionIdBase + maxKhatmaReminderPlans;

enum KhatmaReminderType { completion, recovery, target, portion, missed }

int khatmaReminderId(int planIndex, int dayOffset, KhatmaReminderType type) {
  if (planIndex < 0 || planIndex >= maxKhatmaReminderPlans) {
    throw RangeError.range(planIndex, 0, maxKhatmaReminderPlans - 1);
  }
  if (dayOffset < 0 || dayOffset >= khatmaReminderDaysAhead) {
    throw RangeError.range(dayOffset, 0, khatmaReminderDaysAhead - 1);
  }
  return khatmaReminderIdBase +
      (planIndex * khatmaReminderDaysAhead + dayOffset) *
          khatmaReminderTypesPerDay +
      type.index;
}

/// One reminder to schedule.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.day,
    this.range,
    this.planIndex = 0,
    this.planKey = '',
    this.type = KhatmaReminderType.portion,
  });

  final int id;

  /// Local time it shows.
  final DateTime at;
  final Day day;

  /// The day's portion, when known.
  final PageRange? range;
  final int planIndex;
  final String planKey;
  final KhatmaReminderType type;

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
  int idBase = reminderIdBase,
  int idStep = 1,
  int dayStartHour = 0,
  int planIndex = 0,
  String planKey = '',
  KhatmaReminderType type = KhatmaReminderType.portion,
}) {
  final out = <PlannedReminder>[];
  for (var i = 0; i < days; i++) {
    final day = today.add(i);
    if (last != null && day.isAfter(last)) break;
    final range = portions[day];
    // Nothing due that day (already read ahead, or a day with no new unit).
    if (range == null) continue;
    final at = reminderAt(day, minutes, dayStartHour);
    if (!at.isAfter(now)) continue;
    out.add(
      PlannedReminder(
        id: idBase + i * idStep,
        at: at,
        day: day,
        range: range,
        planIndex: planIndex,
        planKey: planKey,
        type: type,
      ),
    );
  }

  return out;
}

DateTime reminderAt(Day day, int minutes, int dayStartHour) {
  if (minutes < 0 || minutes >= 24 * 60) {
    throw RangeError.range(minutes, 0, 24 * 60 - 1);
  }
  if (dayStartHour < 0 || dayStartHour > 23) {
    throw RangeError.range(dayStartHour, 0, 23);
  }
  final clockDay = minutes ~/ 60 < dayStartHour ? day.add(1) : day;
  return DateTime(
    clockDay.year,
    clockDay.month,
    clockDay.day,
    minutes ~/ 60,
    minutes % 60,
  );
}

/// The follow-up an hour after the portion's reminder, only between 08:00
/// and 22:00, for a portion not read yet when the schedule is written.
PlannedReminder? missedPortionReminder({
  required DateTime now,
  required Day today,
  required int minutes,
  required PageRange range,
  required int planIndex,
  required String planKey,
  required int dayStartHour,
}) {
  // Still due after the portion's own reminder has gone off: the schedule
  // is rewritten on every open and resume, and the follow-up stays as long
  // as its time is ahead.
  final followUpMinutes = minutes + 60;
  if (followUpMinutes < 8 * 60 || followUpMinutes >= 22 * 60) return null;
  final at = reminderAt(today, followUpMinutes, dayStartHour);
  if (!at.isAfter(now)) return null;
  return PlannedReminder(
    id: khatmaReminderId(planIndex, 0, KhatmaReminderType.missed),
    at: at,
    day: today,
    range: range,
    planIndex: planIndex,
    planKey: planKey,
    type: KhatmaReminderType.missed,
  );
}

/// Limits a rolling schedule to three notices per logical day and two per
/// plan, rotating which plans get a slot when there are more than three.
List<PlannedReminder> limitKhatmaReminders(
  Iterable<PlannedReminder> candidates, {
  required int planCount,
}) {
  if (planCount <= 0) {
    if (candidates.isEmpty) return const [];
    throw ArgumentError.value(planCount, 'planCount');
  }
  final byDay = <Day, List<PlannedReminder>>{};
  for (final candidate in candidates) {
    (byDay[candidate.day] ??= []).add(candidate);
  }
  final selected = <PlannedReminder>[];
  final days = byDay.keys.toList()..sort();
  for (final day in days) {
    final rotation = day.difference(const Day(2024, 1, 1)) % planCount;
    final sorted = byDay[day]!
      ..sort((a, b) {
        final byType = a.type.index.compareTo(b.type.index);
        if (byType != 0) return byType;
        final aOrder = (a.planIndex - rotation + planCount) % planCount;
        final bOrder = (b.planIndex - rotation + planCount) % planCount;
        return aOrder.compareTo(bOrder);
      });
    final planCounts = <String, int>{};
    var dayCount = 0;
    for (final candidate in sorted) {
      if (dayCount >= maxKhatmaNotificationsPerDay) break;
      final count = planCounts[candidate.planKey] ?? 0;
      if (count >= maxKhatmaNotificationsPerPlanDay) continue;
      selected.add(candidate);
      planCounts[candidate.planKey] = count + 1;
      dayCount++;
    }
  }
  return selected;
}
