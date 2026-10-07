import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/khatma/domain/day.dart';
import 'package:tibyan/features/khatma/domain/reminder_plan.dart';

void main() {
  test('per-plan reminders use non-overlapping reserved id ranges', () {
    final today = Day.parse('2026-10-10');
    final reminders = portionReminders(
      now: DateTime(2026, 10, 10, 10),
      today: today,
      minutes: 20 * 60,
      portions: {today: (from: 1, to: 2), today.add(1): (from: 3, to: 4)},
      days: khatmaReminderDaysAhead,
      idBase: khatmaReminderIdBase + khatmaReminderDaysAhead,
    );

    expect(reminders.map((reminder) => reminder.id), [
      khatmaReminderIdBase + 3,
      khatmaReminderIdBase + 4,
    ]);
  });

  test('a reminder before the logical day start falls on the next date', () {
    final today = Day.parse('2026-10-10');
    final reminders = portionReminders(
      now: DateTime(2026, 10, 10, 23),
      today: today,
      minutes: 2 * 60,
      portions: {today: (from: 1, to: 2)},
      days: 1,
      dayStartHour: 3,
    );

    expect(reminders.single.at, DateTime(2026, 10, 11, 2));
  });

  test('notification ids reserve distinct plan, day, and type slots', () {
    final ids = {
      khatmaReminderId(0, 0, KhatmaReminderType.portion),
      khatmaReminderId(0, 0, KhatmaReminderType.missed),
      khatmaReminderId(0, 1, KhatmaReminderType.portion),
      khatmaReminderId(1, 0, KhatmaReminderType.portion),
      khatmaReminderId(19, 2, KhatmaReminderType.missed),
      khatmaCompletionIdBase,
      khatmaCompletionIdBase + maxKhatmaReminderPlans - 1,
    };

    expect(ids, hasLength(7));
    expect(
      ids.every(
        (id) => id >= khatmaReminderIdBase && id < khatmaReminderIdLimit,
      ),
      isTrue,
    );
  });

  test('missed-portion follow-up stays in the daytime quiet window', () {
    final today = Day.parse('2026-10-10');
    final reminder = missedPortionReminder(
      now: DateTime(2026, 10, 10, 19, 30),
      today: today,
      minutes: 20 * 60,
      range: (from: 1, to: 2),
      planIndex: 0,
      planKey: 'plan',
      dayStartHour: 3,
    );

    expect(reminder?.at, DateTime(2026, 10, 10, 21));
    expect(
      missedPortionReminder(
        now: DateTime(2026, 10, 10, 19),
        today: today,
        minutes: 21 * 60,
        range: (from: 1, to: 2),
        planIndex: 0,
        planKey: 'plan',
        dayStartHour: 3,
      ),
      isNull,
    );
  });

  test('the rolling schedule caps notices and rotates plan slots', () {
    final today = Day.parse('2026-10-10');
    final candidates = [
      for (var dayOffset = 0; dayOffset < 2; dayOffset++)
        for (var planIndex = 0; planIndex < 4; planIndex++)
          PlannedReminder(
            id: dayOffset * 4 + planIndex,
            at: DateTime(2026, 10, 10 + dayOffset, 20),
            day: today.add(dayOffset),
            planIndex: planIndex,
            planKey: 'plan$planIndex',
          ),
      PlannedReminder(
        id: 20,
        at: DateTime(2026, 10, 10, 20),
        day: today,
        planIndex: 0,
        planKey: 'plan0',
        type: KhatmaReminderType.missed,
      ),
    ];

    final selected = limitKhatmaReminders(candidates, planCount: 4);
    final todaySelected = selected.where((reminder) => reminder.day == today);
    final tomorrowSelected = selected.where(
      (reminder) => reminder.day == today.add(1),
    );
    expect(todaySelected, hasLength(maxKhatmaNotificationsPerDay));
    expect(tomorrowSelected, hasLength(maxKhatmaNotificationsPerDay));
    for (final day in [today, today.add(1)]) {
      final dailyCounts = <String, int>{};
      for (final reminder in selected.where(
        (reminder) => reminder.day == day,
      )) {
        dailyCounts[reminder.planKey] =
            (dailyCounts[reminder.planKey] ?? 0) + 1;
      }
      expect(
        dailyCounts.values,
        everyElement(lessThanOrEqualTo(maxKhatmaNotificationsPerPlanDay)),
      );
    }
    expect(
      todaySelected.map((reminder) => reminder.planKey).toSet(),
      isNot(tomorrowSelected.map((reminder) => reminder.planKey).toSet()),
    );
  });

  test(
    'each plan gets at most two notices per day, with completions first',
    () {
      final today = Day.parse('2026-10-10');
      final candidates = [
        for (final type in [
          KhatmaReminderType.target,
          KhatmaReminderType.recovery,
          KhatmaReminderType.completion,
        ])
          PlannedReminder(
            id: type.index,
            at: DateTime(2026, 10, 10, 20),
            day: today,
            planIndex: 0,
            planKey: 'completed',
            type: type,
          ),
        PlannedReminder(
          id: 10,
          at: DateTime(2026, 10, 10, 20),
          day: today,
          planIndex: 1,
          planKey: 'other',
        ),
      ];

      final selected = limitKhatmaReminders(candidates, planCount: 2);

      expect(
        selected.where((reminder) => reminder.planKey == 'completed'),
        hasLength(2),
      );
      expect(selected.first.type, KhatmaReminderType.completion);
    },
  );

  test(
    'the follow-up is still written after the portion reminder went off',
    () {
      final today = Day.parse('2026-10-10');
      PlannedReminder? at(DateTime now) => missedPortionReminder(
        now: now,
        today: today,
        minutes: 20 * 60,
        range: (from: 1, to: 2),
        planIndex: 3,
        planKey: 'plan',
        dayStartHour: 3,
      );
      // Opened at 20:30 without reading: the 21:00 follow-up stays.
      expect(
        at(DateTime(2026, 10, 10, 20, 30))?.at,
        DateTime(2026, 10, 10, 21),
      );
      expect(
        at(DateTime(2026, 10, 10, 20, 30))?.id,
        khatmaReminderId(3, 0, KhatmaReminderType.missed),
      );
      // Its time has passed: nothing.
      expect(at(DateTime(2026, 10, 10, 21, 5)), isNull);
    },
  );

  test('ids of every plan, day and kind stay inside the reserved range', () {
    final ids = <int>{
      for (var plan = 0; plan < maxKhatmaReminderPlans; plan++)
        for (var day = 0; day < khatmaReminderDaysAhead; day++)
          for (final type in KhatmaReminderType.values)
            khatmaReminderId(plan, day, type),
      for (var i = 0; i < maxKhatmaReminderPlans; i++)
        khatmaCompletionIdBase + i,
    };
    expect(
      ids,
      hasLength(
        maxKhatmaReminderPlans *
                khatmaReminderDaysAhead *
                KhatmaReminderType.values.length +
            maxKhatmaReminderPlans,
      ),
    );
    expect(ids.reduce((a, b) => a < b ? a : b), khatmaReminderIdBase);
    expect(ids.reduce((a, b) => a > b ? a : b), khatmaReminderIdLimit - 1);
    // Clear of the old single-khatma range (7100..7113).
    expect(khatmaReminderIdBase, greaterThanOrEqualTo(reminderIdBase + 14));
    expect(
      () => khatmaReminderId(20, 0, KhatmaReminderType.portion),
      throwsRangeError,
    );
    expect(
      () => khatmaReminderId(0, 3, KhatmaReminderType.portion),
      throwsRangeError,
    );
  });

  test('twenty plans with every kind stay far under iOS\'s 64 pending', () {
    final today = Day.parse('2026-10-10');
    final candidates = [
      for (var plan = 0; plan < maxKhatmaReminderPlans; plan++)
        for (var day = 0; day < khatmaReminderDaysAhead; day++)
          for (final type in KhatmaReminderType.values)
            PlannedReminder(
              id: khatmaReminderId(plan, day, type),
              at: DateTime(2026, 10, 10 + day, 20),
              day: today.add(day),
              planIndex: plan,
              planKey: 'plan$plan',
              type: type,
            ),
    ];
    final selected = limitKhatmaReminders(
      candidates,
      planCount: maxKhatmaReminderPlans,
    );
    expect(
      selected,
      hasLength(khatmaReminderDaysAhead * maxKhatmaNotificationsPerDay),
    );
    expect(selected.length, lessThan(64));
  });
}
