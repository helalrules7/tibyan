import 'dart:math';

import 'day.dart';
import 'interval_set.dart';
import 'khatmah.dart';
import 'quran_index.dart';

const _eps = 1e-9;

/// Where a day's portion may end, by priority: the end of a unit of the
/// khatma ([WirdUnit]), then the smaller units under it (hizb quarter, then
/// page of the edition being read), and failing all those within ±20% of
/// the day's amount, the end of a verse. A portion never ends inside a
/// verse.
///
/// Page ends are the open edition's ([pages]): a portion is shown and cut
/// in the pages being read. The riwaya editions have no hizb quarters in
/// their sources (decision 2): their portions end on a page, then a verse.
class Snapper {
  Snapper(this.index, this.pages, {required this.quarters});

  final QuranIndex index;
  final EditionPageMap pages;

  /// Whether hizb, quarter and juz ends may be used (Hafs editions).
  final bool quarters;

  /// ±20% of the day's amount.
  static const tolerance = 0.2;

  /// The boundary lists to try, best first.
  List<List<int>> levels(WirdUnit unit) {
    if (!quarters) return [pages.pageEnds];
    return switch (unit) {
      WirdUnit.page => [pages.pageEnds],
      WirdUnit.rub => [index.quarterEnds, pages.pageEnds],
      WirdUnit.hizb => [index.hizbEnds, index.quarterEnds, pages.pageEnds],
      WirdUnit.juz => [
        index.juzEnds,
        index.hizbEnds,
        index.quarterEnds,
        pages.pageEnds,
      ],
    };
  }

  /// The end (order position) of a portion of [target] weight starting at
  /// order position [from], counting only verses not in [covered]. [slack]
  /// is the weight the end may be off by (by default 20% of [target]).
  int snap({
    required KhatmahOrder order,
    required int from,
    required double target,
    required IntervalSet covered,
    required WirdUnit unit,
    double? slack,
  }) {
    final last = order.length - 1;
    double weightTo(int pos) =>
        order.span(from, pos).subtract(covered).weigh(index.weightOf);
    final left = weightTo(last);
    final allow = slack ?? target * tolerance;
    // The rest fits: to the end.
    if (left <= target + allow + _eps) return last;
    for (final ends in levels(unit)) {
      int? best;
      var bestOff = double.infinity;
      for (final id in ends) {
        if (id < order.start || id > order.end) continue;
        final pos = order.indexOf(id);
        if (pos < from) continue;
        final off = (weightTo(pos) - target).abs();
        if (off <= allow + _eps && off < bestOff) {
          best = pos;
          bestOff = off;
        }
      }
      // The wrap of a rotated order is the end of the range: a boundary.
      if (order.startAt > order.start) {
        final pos = order.indexOf(order.end);
        if (pos >= from) {
          final off = (weightTo(pos) - target).abs();
          if (off <= allow + _eps && off < bestOff) {
            best = pos;
            bestOff = off;
          }
        }
      }
      if (best != null) return best;
    }
    // The end of the verse in which the amount is reached.
    var lo = from, hi = last;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (weightTo(mid) >= target - _eps) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    return lo;
  }
}

/// A day's portion of a khatma.
class Wird {
  const Wird({
    required this.day,
    required this.from,
    required this.to,
    required this.ranges,
    required this.target,
    required this.required,
    required this.read,
    required this.left,
  });

  final Day day;

  /// First and last verse (`ayah.id`), in the khatma's order.
  final int from;
  final int to;

  /// Its verses (two runs when it wraps round the range).
  final IntervalSet ranges;

  /// The amount the plan asked of the day, before rounding.
  final double target;

  /// The weight to read: the portion's verses unread when the day began.
  final double required;

  /// Weight newly read for the khatma today (anywhere in it).
  final double read;

  /// The portion's verses still unread.
  final double left;

  /// Read the day's amount, or every verse of the portion.
  bool get done => left <= _eps || read >= required - _eps;
}

/// Turns a khatma's plan into days: how much a day, which verses, and the
/// days available. Every date is a logical day (see [Day.logical]).
class Planner {
  const Planner(this.index);

  final QuranIndex index;

  /// Days with a portion from [from] to [to], both included: rest days and
  /// paused days are not counted.
  int readingDays(Khatmah k, Day from, Day to) {
    var n = 0;
    for (var d = from; !d.isAfter(to); d = d.add(1)) {
      if (k.readsOn(d)) n++;
    }
    return n;
  }

  /// The weight of [k]'s verses unread in [covered].
  double unread(Khatmah k, IntervalSet covered) =>
      k.range.subtract(covered).weigh(index.weightOf);

  /// The planned amount a day (Madina pages): [Khatmah.dailyWeight], or
  /// what the plan's days come to.
  double nominal(Khatmah k) {
    final w = k.dailyWeight;
    if (w != null && w > 0) return w;
    final end = k.targetDate;
    final total = index.weightOf(k.rangeStart, k.rangeEnd);
    if (end == null) return total / 30;
    return total / max(1, readingDays(k, k.paceFrom, end));
  }

  /// The plan's amount for [day] (adaptive): 0 on a rest day, a paused
  /// day or for a khatma not active.
  ///
  /// - By end date or duration: what is left when the day begins over the
  ///   days left ("lighter" when ahead; at least the planned amount when
  ///   the reader chose to finish early).
  /// - By daily amount, or open-ended: the planned amount.
  /// - A catch-up the reader chose adds its extra to the planned amount.
  double target(Khatmah k, Ledger l, Day day) {
    if (!k.isActive || !k.readsOn(day)) return 0;
    final left = unread(k, l.coveredBefore(day));
    if (left <= _eps) return 0;
    final daily = nominal(k);
    final r = k.recovery;
    if (r != null && r.covers(day)) return min(left, daily + r.extra);
    final end = k.targetDate;
    final dated =
        end != null &&
        (k.pacing == PacingMode.endDate || k.pacing == PacingMode.duration);
    double base;
    if (dated) {
      final days = day.isAfter(end) ? 1 : max(1, readingDays(k, day, end));
      base = left / days;
      if (k.aheadChoice == AheadChoice.finishEarly) base = max(base, daily);
    } else if (k.aheadChoice == AheadChoice.lighter && end != null) {
      final days = day.isAfter(end) ? 1 : max(1, readingDays(k, day, end));
      base = min(daily, left / days);
    } else {
      base = daily;
    }
    return min(left, base);
  }

  /// [day]'s portion, worked out from the verses read before the day
  /// began (so it does not change during the day), its page ends in
  /// [snap]'s edition. Null when the day has none (rest, pause, complete).
  Wird? wird(Khatmah k, Ledger l, Day day, Snapper snap) {
    if (!k.isActive || !k.readsOn(day)) return null;
    final before = l.coveredBefore(day);
    final order = k.order;
    final start = order.frontier(before);
    if (start == null) return null;
    final from = order.indexOf(start);
    final int to;
    final double target;
    if (k.schedule == ScheduleMode.fixed) {
      final sched = fixedSchedule(k, l, snap);
      final end = sched[day];
      if (end == null) return null;
      if (end < from) return null;
      to = end;
      target = order.span(from, to).subtract(before).weigh(index.weightOf);
    } else {
      target = this.target(k, l, day);
      if (target <= _eps) return null;
      to = snap.snap(
        order: order,
        from: from,
        target: target,
        covered: before,
        unit: k.unit,
      );
    }
    final ranges = order.span(from, to);
    return Wird(
      day: day,
      from: order.idAt(from),
      to: order.idAt(to),
      ranges: ranges,
      target: target,
      required: ranges.subtract(before).weigh(index.weightOf),
      read: l.weightOn(day),
      left: ranges.subtract(l.covered).weigh(index.weightOf),
    );
  }

  /// The fixed schedule: the end (order position) of each reading day's
  /// portion, laid out once from the plan's start ([Khatmah.paceFrom], and
  /// the first verse unread then) to its end date, each day ending on the
  /// best boundary near an equal share. Empty for a khatma with no end.
  Map<Day, int> fixedSchedule(Khatmah k, Ledger l, Snapper snap) {
    final end = k.targetDate;
    if (end == null) return const {};
    final from = k.paceFrom;
    final before = l.coveredBefore(from);
    final order = k.order;
    final first = order.frontier(before);
    if (first == null) return const {};
    final days = [
      for (var d = from; !d.isAfter(end); d = d.add(1))
        if (k.readsOn(d)) d,
    ];
    if (days.isEmpty) return const {};
    final startPos = order.indexOf(first);
    final total = order
        .span(startPos, order.length - 1)
        .subtract(before)
        .weigh(index.weightOf);
    final share = total / days.length;
    final out = <Day, int>{};
    var pos = startPos;
    var done = 0.0;
    for (var i = 0; i < days.length; i++) {
      if (pos > order.length - 1) break;
      if (i == days.length - 1) {
        out[days[i]] = order.length - 1;
        break;
      }
      final ideal = total * (i + 1) / days.length - done;
      final endPos = snap.snap(
        order: order,
        from: pos,
        target: ideal,
        covered: before,
        unit: k.unit,
        slack: share * Snapper.tolerance,
      );
      out[days[i]] = endPos;
      done += order.span(pos, endPos).subtract(before).weigh(index.weightOf);
      pos = endPos + 1;
    }
    return out;
  }

  /// The portions of the [count] days from [today], assuming each day's
  /// portion is read (for reminders and the widget). Days with none are
  /// left out.
  Map<Day, Wird> upcoming(
    Khatmah k,
    Ledger l,
    Day today,
    Snapper snap, {
    int count = 14,
  }) {
    final out = <Day, Wird>{};
    var credits = <Credit>[];
    var ledger = l;
    for (var i = 0; i < count; i++) {
      final d = today.add(i);
      final w = wird(k, ledger, d, snap);
      if (w == null) {
        if (ledger.complete) break;
        continue;
      }
      if (!w.done || i > 0) out[d] = w;
      if (i == 0 && w.done) {
        // Today's is read: the next days start after what is read.
        continue;
      }
      // Suppose it read at the end of the day.
      credits = [
        ...credits,
        Credit(
          sessionUuid: 'plan-$i',
          khatmaUuid: k.uuid,
          ranges: w.ranges,
          newWeight: 0,
          decidedBy: DecidedBy.auto,
          day: d,
          at: d.start.add(const Duration(hours: 23)),
        ),
      ];
      ledger = l.withCredits(credits);
    }
    return out;
  }

  /// The day the khatma ends at its planned amount from [today]: the end
  /// date of a dated plan, or where the daily amount leads (a daily amount
  /// or open-ended plan).
  Day? projectedEnd(Khatmah k, Ledger l, Day today) {
    final left = unread(k, l.covered);
    if (left <= _eps) return null;
    final daily = nominal(k);
    final dated =
        k.targetDate != null &&
        (k.pacing == PacingMode.endDate || k.pacing == PacingMode.duration);
    if (dated && k.aheadChoice != AheadChoice.finishEarly) return k.targetDate;
    return dayAfterReading(k, today, (left / daily - _eps).ceil());
  }

  /// The day on which [days] reading days from [from] (included) are done.
  Day dayAfterReading(Khatmah k, Day from, int days) {
    var d = from;
    var n = 0;
    // Ten years at most: a khatma resting every day, or paused with no
    // end, would never get there.
    for (var i = 0; i < 3660; i++) {
      if (k.readsOn(d)) n++;
      if (n >= days) return d;
      d = d.add(1);
    }
    return from.add(days - 1);
  }
}

/// A ready-made plan (4.5): its days, schedule and unit.
enum KhatmahPreset {
  /// A khatma in a month.
  month('month', days: 30, unit: WirdUnit.page),

  /// Ramadan: a juz a day, laid out once.
  ramadan30(
    'ramadan_30',
    days: 30,
    unit: WirdUnit.juz,
    schedule: ScheduleMode.fixed,
  ),

  /// Two khatmas in Ramadan: 15 days, then the same once more.
  ramadanTwice(
    'ramadan_twice',
    days: 15,
    unit: WirdUnit.hizb,
    schedule: ScheduleMode.fixed,
    autoRestart: true,
  ),

  /// Done before the last ten nights: 20 days.
  beforeLastTen(
    'before_last_ten',
    days: 20,
    unit: WirdUnit.hizb,
    schedule: ScheduleMode.fixed,
  ),

  /// A khatma in a week, by hizb.
  weekly('weekly', days: 7, unit: WirdUnit.hizb),

  /// An open daily portion of a juz, starting again at the end.
  dailyJuz(
    'daily_juz',
    unit: WirdUnit.juz,
    autoRestart: true,
    pacing: PacingMode.openEnded,
    kind: KhatmahKind.dailyWird,
  );

  const KhatmahPreset(
    this.id, {
    this.days,
    required this.unit,
    this.schedule = ScheduleMode.adaptive,
    this.autoRestart = false,
    this.pacing = PacingMode.duration,
    this.kind = KhatmahKind.fullQuran,
  });

  /// Stored in `presetId`.
  final String id;
  final int? days;
  final WirdUnit unit;
  final ScheduleMode schedule;
  final bool autoRestart;
  final PacingMode pacing;
  final KhatmahKind kind;

  static KhatmahPreset? byId(String? id) =>
      values.where((p) => p.id == id).firstOrNull;

  /// The khatma of this preset, the whole Quran from [start].
  Khatmah plan({
    required String uuid,
    required String title,
    required Day start,
    required double totalWeight,
    bool primary = true,
    String edition = 'madina1441',
  }) {
    final d = days;
    return Khatmah(
      uuid: uuid,
      title: title,
      kind: kind,
      pacing: pacing,
      schedule: schedule,
      unit: unit,
      startDate: start,
      targetDate: d == null ? null : start.add(d - 1),
      dailyWeight: d == null ? totalWeight / 30 : totalWeight / d,
      autoRestart: autoRestart,
      presetId: id,
      isPrimary: primary,
      counting: primary ? CountingMode.auto : CountingMode.ask,
      edition: edition,
    );
  }
}
