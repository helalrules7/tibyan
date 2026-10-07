import 'dart:math';

import 'day.dart';
import 'khatmah.dart';
import 'planner.dart';

const _eps = 1e-9;

/// Where a khatma stands against its plan (4.6), always said kindly in
/// the screens: «تبقّى» (left), never «فاتك» (missed).
class RecoveryState {
  const RecoveryState({
    required this.remainingWeight,
    required this.remainingDays,
    required this.currentDailyAverage,
    required this.targetDailyAverage,
    required this.deficit,
    required this.surplus,
    required this.nominal,
    required this.todayTarget,
    required this.readToday,
    required this.askAhead,
    required this.choosing,
  });

  /// Weight left to read, and reading days left (null with no end date).
  final double remainingWeight;
  final int? remainingDays;

  /// Weight read a reading day since the plan's start, and what is left a
  /// day to end on time.
  final double currentDailyAverage;
  final double targetDailyAverage;

  /// Behind the plan's pace at the end of yesterday, and ahead of it now.
  final double deficit;
  final double surplus;

  /// The plan's amount a day.
  final double nominal;
  final double todayTarget;
  final double readToday;

  /// Ask once for this khatma: «finish early, or a lighter portion?».
  final bool askAhead;

  /// A catch-up the reader chose is under way.
  final bool choosing;

  /// Suggest catching up only past half a day's amount behind, and not
  /// while a catch-up is under way.
  bool get suggest => !choosing && deficit > nominal / 2 + _eps;

  /// Read beyond today's portion («وقرأت 7 صفحات إضافية»).
  double get extraToday => max(0, readToday - todayTarget);
}

/// The ways to catch up (4.6).
class RecoveryOptions {
  const RecoveryOptions({
    required this.allToday,
    this.spreadDays,
    this.spreadExtra,
    this.extendTo,
  });

  /// Read it all today: today's amount with what is behind.
  final double allToday;

  /// Over the fewest days that add at most 25% to the daily amount; null
  /// when the days left are too few.
  final int? spreadDays;
  final double? spreadExtra;

  /// Keep the daily amount and move the end date to this day.
  final Day? extendTo;
}

/// The Recovery engine, over the planner.
class Recovery {
  const Recovery(this.planner);

  final Planner planner;

  /// The most a catch-up adds to a day: 25% of the daily amount.
  static const maxExtra = 0.25;

  /// What the plan expected read from its start to the end of [day]: the
  /// daily amount on each reading day, at most what there was to read.
  double expectedBy(Khatmah k, Ledger l, Day day) {
    final from = k.paceFrom;
    if (day.isBefore(from)) return 0;
    final start = planner.unread(k, l.coveredBefore(from));
    final days = planner.readingDays(k, from, day);
    return min(start, planner.nominal(k) * days);
  }

  /// What was read for the khatma from the plan's start to the end of
  /// [day].
  double readBy(Khatmah k, Ledger l, Day day) {
    var sum = 0.0;
    for (final e in l.dailyWeight.entries) {
      if (!e.key.isBefore(k.paceFrom) && !e.key.isAfter(day)) sum += e.value;
    }
    return sum;
  }

  RecoveryState state(Khatmah k, Ledger l, Day today) {
    final yesterday = today.add(-1);
    final deficit = max(
      0.0,
      expectedBy(k, l, yesterday) - readBy(k, l, yesterday),
    );
    final surplus = max(0.0, readBy(k, l, today) - expectedBy(k, l, today));
    final remaining = planner.unread(k, l.covered);
    final end = k.targetDate;
    final daysLeft = end == null
        ? null
        : today.isAfter(end)
        ? 0
        : planner.readingDays(k, today, end);
    final elapsed = planner.readingDays(k, k.paceFrom, today);
    final nominal = planner.nominal(k);
    return RecoveryState(
      remainingWeight: remaining,
      remainingDays: daysLeft,
      currentDailyAverage: elapsed == 0 ? 0 : readBy(k, l, today) / elapsed,
      targetDailyAverage: daysLeft == null || daysLeft == 0
          ? nominal
          : planner.unread(k, l.coveredBefore(today)) / daysLeft,
      deficit: deficit,
      surplus: surplus,
      nominal: nominal,
      todayTarget: planner.target(k, l, today),
      readToday: l.weightOn(today),
      askAhead: k.aheadChoice == null && surplus >= nominal - _eps,
      choosing: k.recovery?.covers(today) ?? false,
    );
  }

  RecoveryOptions options(Khatmah k, Ledger l, Day today) {
    final s = state(k, l, today);
    final cap = s.nominal * maxExtra;
    int? days;
    double? extra;
    if (s.deficit > _eps && cap > _eps) {
      final n = max(1, (s.deficit / cap - _eps).ceil());
      final left = s.remainingDays;
      if (left == null || n <= left) {
        days = n;
        extra = s.deficit / n;
      }
    }
    return RecoveryOptions(
      allToday: s.nominal + s.deficit,
      spreadDays: days,
      spreadExtra: extra,
      extendTo: _extendTo(k, l, today),
    );
  }

  /// The end date that keeps the daily amount for what is left from today.
  Day? _extendTo(Khatmah k, Ledger l, Day today) {
    final left = planner.unread(k, l.coveredBefore(today));
    if (left <= _eps) return null;
    final days = max(1, (left / planner.nominal(k) - _eps).ceil());
    return planner.dayAfterReading(k, today, days);
  }

  /// «أكمل الكل اليوم»: today's portion takes what is behind.
  Khatmah allToday(Khatmah k, Ledger l, Day today) {
    final s = state(k, l, today);
    return k.copyWith(
      recovery: () => RecoveryChoice(from: today, days: 1, extra: s.deficit),
    );
  }

  /// «عوّض على N أيام»: what is behind, spread over the fewest days that
  /// add at most 25% a day.
  Khatmah spread(Khatmah k, Ledger l, Day today) {
    final o = options(k, l, today);
    if (o.spreadDays == null) return spreadRest(k, l, today);
    return k.copyWith(
      recovery: () => RecoveryChoice(
        from: today,
        days: o.spreadDays!,
        extra: o.spreadExtra!,
      ),
    );
  }

  /// «وزّع الباقي»: what is left over the days left; the plan's pace is
  /// counted again from today (the old «spread the rest»).
  Khatmah spreadRest(Khatmah k, Ledger l, Day today) {
    final end = k.targetDate;
    final left = planner.unread(k, l.coveredBefore(today));
    final days = end == null || today.isAfter(end)
        ? 1
        : max(1, planner.readingDays(k, today, end));
    return k.copyWith(
      planFrom: () => today,
      dailyWeight: () => end == null ? k.dailyWeight : left / days,
      recovery: () => null,
    );
  }

  /// «مد الموعد»: the daily amount stays and the end date moves.
  Khatmah extend(Khatmah k, Ledger l, Day today) {
    final to = _extendTo(k, l, today);
    return k.copyWith(
      planFrom: () => today,
      targetDate: () => to ?? k.targetDate,
      dailyWeight: () => planner.nominal(k),
      recovery: () => null,
    );
  }

  /// The answer to «finish early, or a lighter portion?», kept for the
  /// khatma so it is asked once.
  Khatmah answerAhead(Khatmah k, AheadChoice choice) =>
      k.copyWith(aheadChoice: () => choice);
}
