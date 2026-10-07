import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/khatma/domain/day.dart';
import 'package:tibyan/features/khatma/domain/interval_set.dart';
import 'package:tibyan/features/khatma/domain/khatmah.dart';
import 'package:tibyan/features/khatma/domain/khatmah_engine.dart';
import 'package:tibyan/features/khatma/domain/planner.dart';
import 'package:tibyan/features/khatma/domain/quran_index.dart';
import 'package:tibyan/features/khatma/domain/recovery.dart';

import 'support.dart';

/// 2026-10-01 is a Thursday.
final day1 = Day(2026, 10, 1);

void main() {
  late QuranIndex index;
  late Planner planner;
  late Recovery recovery;
  late Snapper madina;
  late EditionPageMap pages;
  late List<Credit> credits;
  var session = 0;

  setUpAll(() async {
    index = await realIndex();
    planner = Planner(index);
    recovery = Recovery(planner);
    pages = index.madina1441;
    madina = Snapper(index, pages, quarters: true);
  });
  setUp(() {
    credits = [];
    session = 0;
  });

  Khatmah month({
    WirdUnit unit = WirdUnit.page,
    ScheduleMode schedule = ScheduleMode.adaptive,
    Set<int> rest = const {},
    AheadChoice? ahead,
  }) => Khatmah(
    uuid: 'k',
    title: 'k',
    startDate: day1,
    targetDate: day1.add(29),
    dailyWeight: 604 / 30,
    unit: unit,
    schedule: schedule,
    restWeekdays: rest,
    aheadChoice: ahead,
    isPrimary: true,
  );

  Ledger ledger(Khatmah k) => Ledger(k, credits, index);

  void read(IntervalSet verses, Day day, {int hour = 9}) => credits.add(
    Credit(
      sessionUuid: 's${++session}',
      khatmaUuid: 'k',
      ranges: verses,
      newWeight: 0,
      decidedBy: DecidedBy.auto,
      day: day,
      at: day.start.add(Duration(hours: hour, minutes: session)),
    ),
  );

  void readPages(int from, int to, Day day) =>
      read(pages.versesReadOn([for (var p = from; p <= to; p++) p]), day);

  /// Reads [w] Madina pages' weight in order from the khatma's frontier.
  void readWeight(Khatmah k, double w, Day day) {
    final l = ledger(k);
    final from = l.frontier!;
    read(IntervalSet.range(from, index.ayahAtWeightOffset(from, w)), day);
  }

  (int, int) wirdPages(Wird w, [EditionPageMap? p]) =>
      ((p ?? pages).pageOf(w.from), (p ?? pages).lastPageOf(w.to));

  group('logical day (2.6)', () {
    test('scenario 6: reading at 1:30 at night counts for the day before', () {
      expect(Day.logical(DateTime(2026, 10, 2, 1, 30), 3), Day(2026, 10, 1));
      expect(Day.logical(DateTime(2026, 10, 2, 3), 3), Day(2026, 10, 2));
      expect(Day.logical(DateTime(2026, 10, 2, 0, 10), 0), Day(2026, 10, 2));
      // Across a month end and a daylight-saving night.
      expect(Day.logical(DateTime(2026, 11, 1, 2), 3), Day(2026, 10, 31));
      expect(Day.logical(DateTime(2027, 3, 28, 2, 30), 3), Day(2027, 3, 27));
    });
  });

  group('adaptive (scenarios 1, 4, 5)', () {
    test('scenario 1: 20 pages a day for 3 days, on page ends', () {
      final k = month();
      for (var d = 0; d < 3; d++) {
        final w = planner.wird(k, ledger(k), day1.add(d), madina)!;
        expect(wirdPages(w), (d * 20 + 1, d * 20 + 20));
        expect(w.done, isFalse);
        readPages(d * 20 + 1, d * 20 + 20, day1.add(d));
        expect(planner.wird(k, ledger(k), day1.add(d), madina)!.done, isTrue);
      }
      final l = ledger(k);
      expect(l.coveredWeight, closeTo(60, 1e-9));
      expect(pages.pageOf(l.frontier!), 61);
      final r = recovery.state(k, l, day1.add(2));
      // 20 pages a day against 20.13 planned: a little behind, nothing to
      // suggest.
      expect(r.deficit, closeTo(2 * (604 / 30 - 20), 1e-9));
      expect(r.suggest, isFalse);
    });

    test('the portion does not change during the day', () {
      final k = month();
      final before = planner.wird(k, ledger(k), day1, madina)!;
      readPages(1, 10, day1);
      final after = planner.wird(k, ledger(k), day1, madina)!;
      expect((after.from, after.to), (before.from, before.to));
      expect(after.read, closeTo(10, 1e-9));
      expect(after.left, closeTo(10, 1e-9));
    });

    test('scenario 4: 27 pages read for 20: «7 more», tomorrow lighter', () {
      final k = month();
      readPages(1, 27, day1);
      final r = recovery.state(k, ledger(k), day1);
      expect(r.extraToday, closeTo(27 - 604 / 30, 1e-9));
      expect(r.askAhead, isFalse, reason: 'not a whole day ahead');
      final tomorrow = planner.target(k, ledger(k), day1.add(1));
      expect(tomorrow, closeTo((604 - 27) / 29, 1e-9));
      expect(tomorrow, lessThan(604 / 30));
    });

    test('a whole day ahead: asked once; the answer is kept', () {
      var k = month();
      readPages(1, 41, day1);
      expect(recovery.state(k, ledger(k), day1).askAhead, isTrue);
      k = recovery.answerAhead(k, AheadChoice.finishEarly);
      expect(recovery.state(k, ledger(k), day1).askAhead, isFalse);
      // Finishing early keeps the planned amount.
      expect(
        planner.target(k, ledger(k), day1.add(1)),
        closeTo(604 / 30, 1e-9),
      );
      expect(planner.projectedEnd(k, ledger(k), day1.add(1)), day1.add(28));
      // A lighter portion spreads what is left over the days left.
      final lighter = recovery.answerAhead(month(), AheadChoice.lighter);
      expect(
        planner.target(lighter, ledger(lighter), day1.add(1)),
        closeTo((604 - 41) / 29, 1e-9),
      );
    });

    test('scenario 5: 12 of 20: no suggestion; then a day with none: the '
        'options', () {
      final k = month();
      readPages(1, 12, day1);
      var r = recovery.state(k, ledger(k), day1.add(1));
      expect(r.deficit, closeTo(604 / 30 - 12, 1e-9));
      expect(r.suggest, isFalse, reason: 'less than half a portion behind');
      final tomorrow = planner.target(k, ledger(k), day1.add(1));
      expect(tomorrow, greaterThan(604 / 30));
      // Day 2 with no reading.
      r = recovery.state(k, ledger(k), day1.add(2));
      expect(r.deficit, closeTo(2 * 604 / 30 - 12, 1e-9));
      expect(r.suggest, isTrue);
      final o = recovery.options(k, ledger(k), day1.add(2));
      expect(o.allToday, closeTo(604 / 30 + r.deficit, 1e-9));
      // At most 25% more a day: the fewest days that allow it.
      expect(o.spreadDays, 6);
      expect(o.spreadExtra! <= 0.25 * 604 / 30 + 1e-9, isTrue);
      expect(o.extendTo, isNotNull);
      expect(o.extendTo!.isAfter(k.targetDate!), isTrue);
    });

    test('catching up: all today, over N days, or a later end', () {
      final k = month();
      readPages(1, 12, day1);
      final today = day1.add(2);
      final all = recovery.allToday(k, ledger(k), today);
      final s = recovery.state(k, ledger(k), today);
      expect(
        planner.target(all, ledger(all), today),
        closeTo(604 / 30 + s.deficit, 1e-9),
      );
      expect(recovery.state(all, ledger(all), today).suggest, isFalse);
      expect(
        planner.target(all, ledger(all), today.add(1)),
        isNot(closeTo(604 / 30 + s.deficit, 1e-6)),
      );

      final spread = recovery.spread(k, ledger(k), today);
      expect(spread.recovery!.days, 6);
      for (var d = 0; d < 6; d++) {
        expect(
          planner.target(spread, ledger(spread), today.add(d)),
          closeTo(604 / 30 + s.deficit / 6, 1e-9),
        );
      }

      final extended = recovery.extend(k, ledger(k), today);
      expect(extended.planFrom, today);
      expect(extended.dailyWeight, closeTo(604 / 30, 1e-9));
      expect(recovery.state(extended, ledger(extended), today).deficit, 0);
      expect(
        planner.target(extended, ledger(extended), today),
        lessThanOrEqualTo(604 / 30 + 1e-9),
      );

      final rest = recovery.spreadRest(k, ledger(k), today);
      expect(rest.planFrom, today);
      expect(rest.dailyWeight, closeTo((604 - 12) / 28, 1e-9));
      expect(recovery.state(rest, ledger(rest), today).deficit, 0);
    });
  });

  group('rest days and pauses', () {
    test('a Friday rest: no portion, and the days left skip Fridays', () {
      final k = month(rest: {DateTime.friday});
      final friday = day1.add(1);
      expect(friday.start.weekday, DateTime.friday);
      expect(planner.wird(k, ledger(k), friday, madina), isNull);
      // 30 days, 5 of them Fridays.
      expect(planner.readingDays(k, day1, day1.add(29)), 25);
      expect(planner.target(k, ledger(k), day1), closeTo(604 / 25, 1e-9));
      // A rest day is never behind.
      readPages(1, 25, day1);
      expect(recovery.state(k, ledger(k), day1.add(2)).deficit, 0);
    });

    test('scenario 10: a 5-day pause: no portion, nothing behind, the end '
        'moves', () {
      final engine = KhatmahEngine(index);
      var k = month();
      readPages(1, 20, day1);
      k = engine.pause(k, day1.add(1));
      for (var d = 1; d <= 5; d++) {
        expect(planner.wird(k, ledger(k), day1.add(d), madina), isNull);
      }
      k = engine.resume(k, day1.add(6));
      expect(k.targetDate, day1.add(34));
      final r = recovery.state(k, ledger(k), day1.add(6));
      // Only day 1 counts: 20 of 20.13; the paused days ask nothing.
      expect(r.deficit, closeTo(604 / 30 - 20, 1e-9));
      expect(r.suggest, isFalse);
      expect(planner.readingDays(k, day1, k.targetDate!), 30);
      final w = planner.wird(k, ledger(k), day1.add(6), madina)!;
      expect(wirdPages(w).$1, 21);
      expect(w.target, closeTo(584 / 29, 1e-9));
    });
  });

  group('snapping', () {
    test('a juz a day ends on each juz end', () {
      final k = month(unit: WirdUnit.juz);
      for (var d = 0; d < 3; d++) {
        final w = planner.wird(k, ledger(k), day1.add(d), madina)!;
        expect(w.to, index.juzEnds[d]);
        read(w.ranges, day1.add(d));
      }
    });

    test('hizb quarters: a portion ends on a quarter end within 20%', () {
      final k = month(unit: WirdUnit.rub);
      final w = planner.wird(k, ledger(k), day1, madina)!;
      expect(index.quarterEnds, contains(w.to));
      final weight = index.weightOf(w.from, w.to);
      expect((weight - 604 / 30).abs(), lessThanOrEqualTo(0.2 * 604 / 30));
    });

    test('never inside a verse: a tiny amount ends on a verse end', () {
      final k = month().copyWith(
        pacing: PacingMode.dailyAmount,
        dailyWeight: () => 0.05,
      );
      final w = planner.wird(k, ledger(k), day1, madina)!;
      expect(w.from, 1);
      expect(index.weightOf(1, w.to), greaterThanOrEqualTo(0.05 - 1e-9));
      expect(index.weightOf(1, w.to - 1), lessThan(0.05));
    });

    test('a riwaya edition has no quarters: page end, then verse', () {
      final riwaya = Snapper(index, pages, quarters: false);
      expect(riwaya.levels(WirdUnit.juz), [pages.pageEnds]);
      final k = month(unit: WirdUnit.rub);
      final w = planner.wird(k, ledger(k), day1, riwaya)!;
      expect(pages.pageEnds, contains(w.to));
    });

    test('scenario 11: changing the edition keeps the frontier; the '
        'portion is cut in the new pages', () {
      final k = month();
      readPages(1, 20, day1);
      final shamarly = Snapper(index, index.shamarly, quarters: true);
      final inMadina = planner.wird(k, ledger(k), day1.add(1), madina)!;
      final inShamarly = planner.wird(k, ledger(k), day1.add(1), shamarly)!;
      expect(inShamarly.from, inMadina.from);
      expect(index.shamarly.pageEnds, contains(inShamarly.to));
      expect(
        (index.weightOf(inShamarly.from, inShamarly.to) - inShamarly.target)
            .abs(),
        lessThanOrEqualTo(0.2 * inShamarly.target + 1e-9),
      );
    });
  });

  group('fixed schedule', () {
    test('laid out once; behind days join today\'s portion', () {
      final k = month(unit: WirdUnit.juz, schedule: ScheduleMode.fixed);
      final sched = planner.fixedSchedule(k, ledger(k), madina);
      expect(sched.length, 30);
      for (var d = 0; d < 30; d++) {
        expect(k.order.idAt(sched[day1.add(d)]!), index.juzEnds[d]);
      }
      // Nothing read on day 1: day 2's portion is juz 1 and 2.
      final w = planner.wird(k, ledger(k), day1.add(1), madina)!;
      expect((w.from, w.to), (1, index.juzEnds[1]));
      expect(recovery.state(k, ledger(k), day1.add(1)).deficit, greaterThan(0));
      // Reading ahead does not move the schedule.
      read(IntervalSet.range(1, index.juzEnds[3]), day1.add(1));
      expect(planner.fixedSchedule(k, ledger(k), madina), sched);
      expect(planner.wird(k, ledger(k), day1.add(2), madina), isNull);
    });
  });

  group('upcoming portions', () {
    test('follow on from today, assuming each is read', () {
      final k = month();
      final up = planner.upcoming(k, ledger(k), day1, madina, count: 3);
      expect(
        [for (final w in up.values) wirdPages(w)],
        [(1, 20), (21, 40), (41, 60)],
      );
    });

    test('today read: the next days start after it', () {
      final k = month();
      readPages(1, 20, day1);
      final up = planner.upcoming(k, ledger(k), day1, madina, count: 2);
      expect(up.containsKey(day1), isFalse);
      expect(wirdPages(up[day1.add(1)]!), (21, 40));
    });
  });

  group('by daily amount, open-ended', () {
    test('the end date follows the amount', () {
      final k = month().copyWith(
        pacing: PacingMode.dailyAmount,
        dailyWeight: () => 10,
        targetDate: () => null,
      );
      expect(planner.projectedEnd(k, ledger(k), day1), day1.add(60));
      readWeight(k, 300, day1);
      expect(planner.projectedEnd(k, ledger(k), day1.add(1)), day1.add(31));
      expect(planner.target(k, ledger(k), day1.add(1)), 10);
    });
  });

  group('presets', () {
    test('each preset is a plan', () {
      for (final p in KhatmahPreset.values) {
        final k = p.plan(
          uuid: p.id,
          title: p.id,
          start: day1,
          totalWeight: index.totalWeight,
        );
        expect(k.presetId, p.id);
        expect(KhatmahPreset.byId(p.id), p);
        expect(k.dailyWeight, greaterThan(0));
      }
      final r = KhatmahPreset.ramadan30.plan(
        uuid: 'r',
        title: 'r',
        start: day1,
        totalWeight: 604,
      );
      expect(r.schedule, ScheduleMode.fixed);
      expect(r.targetDate, day1.add(29));
      expect(r.unit, WirdUnit.juz);
      final last10 = KhatmahPreset.beforeLastTen.plan(
        uuid: 'b',
        title: 'b',
        start: day1,
        totalWeight: 604,
      );
      expect(last10.targetDate, day1.add(19));
      final daily = KhatmahPreset.dailyJuz.plan(
        uuid: 'd',
        title: 'd',
        start: day1,
        totalWeight: 604,
      );
      expect(daily.autoRestart, isTrue);
      expect(daily.targetDate, isNull);
      expect(daily.pacing, PacingMode.openEnded);
      expect(daily.kind, KhatmahKind.dailyWird);
      final week = KhatmahPreset.weekly.plan(
        uuid: 'w',
        title: 'w',
        start: day1,
        totalWeight: 604,
      );
      expect(week.unit, WirdUnit.hizb);
      expect(week.targetDate, day1.add(6));
    });

    test('a daily juz runs on with no end', () {
      final k = KhatmahPreset.dailyJuz.plan(
        uuid: 'k',
        title: 'k',
        start: day1,
        totalWeight: 604,
      );
      final w = planner.wird(k, ledger(k), day1, madina)!;
      expect(w.to, index.juzEnds.first);
      expect(
        planner.target(k, ledger(k), day1.add(100)),
        closeTo(604 / 30, 1e-9),
      );
    });

    test('two khatmas in Ramadan: started again once only', () {
      final engine = KhatmahEngine(index);
      final k = KhatmahPreset.ramadanTwice.plan(
        uuid: 'r1',
        title: 'r',
        start: day1,
        totalWeight: 604,
      );
      final first = engine.complete(
        k,
        now: DateTime(2026, 10, 15),
        today: day1.add(15),
        newUuid: () => 'r2',
      );
      expect(first.next!.targetDate, day1.add(29));
      final second = engine.complete(
        first.next!,
        now: DateTime(2026, 10, 30),
        today: day1.add(30),
        newUuid: () => 'r3',
      );
      expect(second.next, isNull);
    });
  });
}
