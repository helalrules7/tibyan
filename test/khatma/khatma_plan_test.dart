import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/khatma/domain/day.dart';
import 'package:tibyan/features/khatma/domain/khatma_plan.dart';

Set<int> pages(int from, int to) => {for (var p = from; p <= to; p++) p};

void main() {
  final start = Day(2026, 10, 1);

  group('Day', () {
    test('parses, formats and counts days across a month end', () {
      expect(Day.parse('2026-10-31').add(1).key, '2026-11-01');
      expect(Day(2027, 3, 1).difference(Day(2027, 2, 1)), 28);
      expect(Day(2026, 10, 2).isAfter(Day(2026, 10, 1)), isTrue);
    });

    test('a daylight-saving change does not shift days', () {
      // Clocks change in late March and October in many zones.
      expect(Day(2027, 3, 29).difference(Day(2027, 3, 27)), 2);
      expect(Day(2026, 10, 25).add(1), Day(2026, 10, 26));
    });
  });

  group('pages, 604 over 30 days (Madina)', () {
    final plan = KhatmaPlan(
      unitStarts: pageUnitStarts(1, 604),
      lastPage: 604,
      from: start,
      target: start.add(29),
    );

    test('spreads the pages evenly and ends on the target day', () {
      expect(plan.days, 30);
      expect(plan.expectedEnd(start), 21); // ceil(604 / 30)
      expect(plan.expectedEnd(start.add(1)), 41);
      expect(plan.expectedEnd(start.add(29)), 604);
      expect(plan.expectedEnd(start.add(40)), 604);
      expect(plan.expectedEnd(start.add(-1)), 0);
    });

    test("today's portion starts at the first unread page", () {
      final today = plan.todayPortion(start, {});
      expect(today!.range, (from: 1, to: 21));
      expect(today.pages, 21);

      final half = plan.todayPortion(start, pages(1, 10));
      expect(half!.range, (from: 11, to: 21));
      expect(half.pages, 11);
    });

    test('a portion read is done for the day; reading ahead counts', () {
      expect(plan.todayPortion(start, pages(1, 21)), isNull);
      expect(plan.todayPortion(start.add(1), pages(1, 30))!.range.from, 31);
    });

    test('pages behind are those due before today and not read', () {
      expect(plan.pagesBehind(start, {}), 0);
      expect(plan.pagesBehind(start.add(2), pages(1, 21)), 20);
      expect(plan.pagesBehind(start.add(2), pages(1, 41)), 0);
      // Behind days' pages are part of today's portion.
      expect(plan.todayPortion(start.add(2), pages(1, 21))!.pages, 40);
    });

    test('progress and completion', () {
      expect(plan.pagesDone(pages(1, 302)), 302);
      expect(plan.nextPage(pages(1, 604)), isNull);
      expect(plan.isComplete(pages(1, 604)), isTrue);
      expect(plan.isComplete(pages(2, 604)), isFalse);
    });
  });

  group('Shamarly (522 pages, text from page 2)', () {
    final plan = KhatmaPlan(
      unitStarts: pageUnitStarts(2, 522),
      lastPage: 522,
      from: start,
      target: start.add(9),
    );

    test('counts only text pages', () {
      expect(plan.totalPages, 521);
      expect(plan.todayPortion(start, {})!.range, (from: 2, to: 54));
      expect(plan.expectedEnd(start.add(9)), 522);
      expect(plan.isComplete(pages(2, 522)), isTrue);
    });
  });

  group('juz units', () {
    // A small mushaf of 4 juz starting on pages 1, 5, 9 and 14; 16 pages.
    final plan = KhatmaPlan(
      unitStarts: [1, 5, 9, 14],
      lastPage: 16,
      from: start,
      target: start.add(1),
    );

    test('a day ends on a whole juz', () {
      expect(plan.unitEnd(0), 4);
      expect(plan.unitEnd(3), 16);
      expect(plan.unitOf(13), 2);
      expect(plan.expectedUnits(start), 2);
      expect(plan.todayPortion(start, {})!.range, (from: 1, to: 8));
      expect(plan.todayPortion(start.add(1), pages(1, 8))!.range, (
        from: 9,
        to: 16,
      ));
    });
  });

  group('by daily amount', () {
    test('days needed round up', () {
      expect(KhatmaPlan.daysFor(30, 1), 30);
      expect(KhatmaPlan.daysFor(30, 2), 15);
      expect(KhatmaPlan.daysFor(604, 20), 31);
      expect(KhatmaPlan.daysFor(60, 0.5), 120);
    });
  });

  group('catch-up', () {
    final original = KhatmaPlan(
      unitStarts: pageUnitStarts(1, 604),
      lastPage: 604,
      from: start,
      target: start.add(29),
    );

    test('spreading the rest keeps the end date', () {
      // Read 21 pages on day 1, nothing on days 2 to 10.
      final read = pages(1, 21);
      final today = start.add(10);
      expect(original.pagesBehind(today, read), 181);
      final spread = KhatmaPlan(
        unitStarts: original.unitStarts,
        lastPage: 604,
        from: today,
        target: original.target,
        baseUnit: original.unitOf(original.nextPage(read)!),
      );
      expect(spread.pagesBehind(today, read), 0);
      // 583 pages over 20 days.
      expect(spread.todayPortion(today, read)!.range, (from: 22, to: 51));
      expect(spread.expectedEnd(original.target), 604);
    });

    test('moving the end date keeps the daily amount', () {
      final read = pages(1, 21);
      final today = start.add(10);
      final base = original.unitOf(original.nextPage(read)!);
      final days = KhatmaPlan.daysFor(
        original.unitCount - base,
        original.unitsPerDay,
      );
      final moved = KhatmaPlan(
        unitStarts: original.unitStarts,
        lastPage: 604,
        from: today,
        target: today.add(days - 1),
        baseUnit: base,
      );
      expect(moved.todayPortion(today, read)!.pages, 21);
      expect(moved.target, today.add(28));
    });
  });

  group('upcoming portions', () {
    final plan = KhatmaPlan(
      unitStarts: pageUnitStarts(1, 604),
      lastPage: 604,
      from: start,
      target: start.add(29),
    );

    test('follow on from today, assuming each is read', () {
      final up = plan.upcoming(start.add(1), pages(1, 21), count: 3);
      expect(up[start.add(1)], (from: 22, to: 41));
      expect(up[start.add(2)], (from: 42, to: 61));
      expect(up.length, 3);
    });

    test('today read ahead: the next days start after what is read', () {
      final up = plan.upcoming(start, pages(1, 50), count: 3);
      expect(up.containsKey(start), isFalse);
      expect(up[start.add(1)], isNull); // 41 already read
      expect(up[start.add(2)], (from: 51, to: 61));
    });

    test('stop at the target day', () {
      final up = plan.upcoming(start.add(28), pages(1, 581), count: 14);
      expect(up.keys, [start.add(28), start.add(29)]);
      expect(up[start.add(29)]!.to, 604);
    });
  });

  test('page runs merge consecutive pages', () {
    expect(pageRuns([5, 3, 4, 9, 10, 1]), [
      (from: 1, to: 1),
      (from: 3, to: 5),
      (from: 9, to: 10),
    ]);
  });
}
