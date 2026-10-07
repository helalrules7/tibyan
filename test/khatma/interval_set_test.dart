import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/khatma/domain/interval_set.dart';

IntervalSet s(List<(int, int)> runs) =>
    IntervalSet([for (final (a, b) in runs) (from: a, to: b)]);

List<(int, int)> runs(IntervalSet set) => [
  for (final r in set.ranges) (r.from, r.to),
];

/// The same set as plain numbers, to check the runs against.
Set<int> plain(IntervalSet set) => {
  for (final r in set.ranges)
    for (var i = r.from; i <= r.to; i++) i,
};

void main() {
  group('building', () {
    test('runs are sorted and merged, touching ones too', () {
      expect(runs(s([(5, 7), (1, 2), (3, 4), (10, 12), (11, 15)])), [
        (1, 7),
        (10, 15),
      ]);
    });

    test('overlapping and nested runs merge into one', () {
      expect(runs(s([(1, 10), (3, 4), (8, 20), (20, 20)])), [(1, 20)]);
    });

    test('empty runs are dropped; nothing gives the empty set', () {
      expect(s([(5, 4)]).isEmpty, isTrue);
      expect(IntervalSet([]), IntervalSet.empty);
      expect(IntervalSet.range(3, 2).isEmpty, isTrue);
    });

    test('from single numbers', () {
      expect(runs(IntervalSet.of([9, 1, 2, 3, 7, 8])), [(1, 3), (7, 9)]);
      expect(IntervalSet.of([4, 4, 4]).count, 1);
    });
  });

  group('queries', () {
    final set = s([(1, 7), (10, 10), (20, 30)]);

    test('contains, count, first and last', () {
      expect(set.contains(1), isTrue);
      expect(set.contains(7), isTrue);
      expect(set.contains(8), isFalse);
      expect(set.contains(10), isTrue);
      expect(set.contains(0), isFalse);
      expect(set.contains(31), isFalse);
      expect(set.count, 7 + 1 + 11);
      expect(set.first, 1);
      expect(set.last, 30);
      expect(IntervalSet.empty.first, isNull);
    });

    test('contains a whole run only when nothing is missing', () {
      expect(set.containsRange(2, 7), isTrue);
      expect(set.containsRange(6, 10), isFalse);
      expect(set.containsRange(20, 30), isTrue);
      expect(set.containsRange(9, 8), isTrue); // empty run
      expect(set.containsAll(s([(1, 3), (25, 26)])), isTrue);
      expect(set.containsAll(s([(1, 3), (25, 31)])), isFalse);
    });

    test('the first gap from a verse', () {
      expect(set.firstGap(1, 100), 8);
      expect(set.firstGap(8, 100), 8);
      expect(set.firstGap(10, 100), 11);
      expect(set.firstGap(20, 30), isNull);
      expect(set.firstGap(25, 40), 31);
      expect(set.firstGap(5, 4), isNull);
      expect(IntervalSet.empty.firstGap(3, 9), 3);
    });

    test('weighs each run', () {
      expect(set.weigh((a, b) => (b - a + 1).toDouble()), 19);
    });
  });

  group('operations', () {
    test('union', () {
      expect(runs(s([(1, 3)]).union(s([(4, 6), (10, 11)]))), [
        (1, 6),
        (10, 11),
      ]);
      expect(s([(1, 3)]).union(IntervalSet.empty), s([(1, 3)]));
      expect(IntervalSet.empty.union(s([(2, 2)])), s([(2, 2)]));
      expect(runs(s([(1, 3)]).add(2, 9)), [(1, 9)]);
    });

    test('intersect', () {
      final a = s([(1, 10), (20, 30)]);
      expect(runs(a.intersect(s([(5, 25)]))), [(5, 10), (20, 25)]);
      expect(a.intersect(s([(11, 19)])).isEmpty, isTrue);
      expect(runs(a.intersect(s([(10, 20)]))), [(10, 10), (20, 20)]);
      expect(a.intersect(IntervalSet.empty).isEmpty, isTrue);
    });

    test('subtract: holes, ends, and runs taken whole', () {
      final a = s([(1, 10), (20, 30)]);
      expect(runs(a.subtract(s([(3, 4)]))), [(1, 2), (5, 10), (20, 30)]);
      expect(runs(a.subtract(s([(1, 1), (10, 20)]))), [(2, 9), (21, 30)]);
      expect(runs(a.subtract(s([(0, 100)]))), isEmpty);
      expect(runs(a.subtract(s([(5, 6), (8, 8), (25, 40)]))), [
        (1, 4),
        (7, 7),
        (9, 10),
        (20, 24),
      ]);
      expect(a.subtract(IntervalSet.empty), a);
      expect(IntervalSet.empty.subtract(a).isEmpty, isTrue);
    });

    test('agree with plain sets on random runs', () {
      final rnd = Random(7);
      IntervalSet random() => IntervalSet([
        for (var i = 0; i < rnd.nextInt(6); i++)
          if (rnd.nextInt(60) case final a) (from: a, to: a + rnd.nextInt(8)),
      ]);
      for (var i = 0; i < 400; i++) {
        final a = random(), b = random();
        expect(plain(a.union(b)), plain(a).union(plain(b)));
        expect(plain(a.intersect(b)), plain(a).intersection(plain(b)));
        expect(plain(a.subtract(b)), plain(a).difference(plain(b)));
        // Always merged: no two runs touch.
        for (final x in [a.union(b), a.intersect(b), a.subtract(b)]) {
          for (var k = 1; k < x.ranges.length; k++) {
            expect(x.ranges[k].from, greaterThan(x.ranges[k - 1].to + 1));
          }
        }
      }
    });
  });

  group('stored form', () {
    test('round trip', () {
      final a = s([(1, 7), (9, 9), (300, 6236)]);
      expect(a.toJson(), '[[1,7],[9,9],[300,6236]]');
      expect(IntervalSet.fromJson(a.toJson()), a);
    });

    test('empty or broken text is the empty set', () {
      expect(IntervalSet.fromJson(null), IntervalSet.empty);
      expect(IntervalSet.fromJson(''), IntervalSet.empty);
      expect(IntervalSet.fromJson('not json'), IntervalSet.empty);
      expect(IntervalSet.fromJson('{"a":1}'), IntervalSet.empty);
      expect(runs(IntervalSet.fromJson('[[3,4],["x",2],[1,2]]')), [(1, 4)]);
    });

    test('equality and printing', () {
      expect(s([(1, 2), (3, 4)]), s([(1, 4)]));
      expect(s([(1, 2)]).hashCode, s([(1, 2)]).hashCode);
      expect(s([(1, 2), (5, 5)]).toString(), '{1-2, 5}');
    });
  });
}
