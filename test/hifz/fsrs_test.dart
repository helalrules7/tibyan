import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/hifz/domain/fsrs.dart';

void main() {
  const fsrs = Fsrs();
  final now = DateTime(2026, 10, 2, 21, 30);

  test('recall is 90% after exactly S days', () {
    for (final s in [0.5, 3.7, 40.0]) {
      expect(Fsrs.retrievability(s, s), closeTo(0.9, 1e-9));
    }
    expect(Fsrs.retrievability(0, 5), 1);
  });

  test('a first review starts from the default weights', () {
    final good = fsrs.review(
      state: null,
      lastReview: null,
      grade: Grade.good,
      now: now,
    );
    expect(good.state.stability, closeTo(3.7145, 1e-9));
    expect(good.state.difficulty, closeTo(5.1618, 1e-9));
    // At 90% retention the interval is S itself, rounded to days.
    expect(good.interval, 4);
    expect(good.due, DateTime(2026, 10, 6));

    final again = fsrs.review(
      state: null,
      lastReview: null,
      grade: Grade.again,
      now: now,
    );
    expect(again.state.stability, closeTo(0.4872, 1e-9));
    expect(again.state.difficulty, closeTo(5.1618 + 2 * 1.2298, 1e-9));
    // Never sooner than tomorrow: reviews are planned by the day.
    expect(again.interval, 1);
    expect(again.due, DateTime(2026, 10, 3));

    final easy = fsrs.first(Grade.easy);
    expect(easy.stability, closeTo(13.8206, 1e-9));
    expect(easy.difficulty, closeTo(5.1618 - 1.2298, 1e-9));
  });

  test('success on time grows stability; hard < good < easy', () {
    const s = MemoryState(stability: 4, difficulty: 5);
    final hard = fsrs.next(s, Grade.hard, 4);
    final good = fsrs.next(s, Grade.good, 4);
    final easy = fsrs.next(s, Grade.easy, 4);
    expect(hard.stability, greaterThan(4));
    expect(good.stability, greaterThan(hard.stability));
    expect(easy.stability, greaterThan(good.stability));
    // Good on time, by the formula:
    // 4 * (1 + e^1.6474 * 6 * 4^-0.1367 * (e^(1.0461*0.1) - 1)).
    expect(good.stability, closeTo(15.3724, 1e-3));
    // Difficulty moves with the grade and is pulled back towards w4.
    expect(hard.difficulty, greaterThan(5));
    expect(easy.difficulty, lessThan(5));
  });

  test('a later review grows stability more than an early one', () {
    const s = MemoryState(stability: 10, difficulty: 5);
    final early = fsrs.next(s, Grade.good, 1);
    final late = fsrs.next(s, Grade.good, 20);
    expect(late.stability, greaterThan(early.stability));
    // Reviewing again the same day changes nothing.
    expect(fsrs.next(s, Grade.good, 0).stability, closeTo(10, 1e-9));
  });

  test('forgetting never raises stability and counts against it', () {
    const s = MemoryState(stability: 30, difficulty: 6);
    final forgot = fsrs.next(s, Grade.again, 30);
    expect(forgot.stability, lessThan(30));
    expect(forgot.difficulty, greaterThan(6));
    const tiny = MemoryState(stability: 0.3, difficulty: 9);
    expect(fsrs.next(tiny, Grade.again, 1).stability, lessThanOrEqualTo(0.3));
  });

  test('difficulty stays within 1..10', () {
    var s = const MemoryState(stability: 5, difficulty: 9.9);
    for (var i = 0; i < 20; i++) {
      s = fsrs.next(s, Grade.again, 1);
    }
    expect(s.difficulty, lessThanOrEqualTo(10));
    s = const MemoryState(stability: 5, difficulty: 1.1);
    for (var i = 0; i < 20; i++) {
      s = fsrs.next(s, Grade.easy, 5);
    }
    expect(s.difficulty, greaterThanOrEqualTo(1));
  });

  test('a lower desired retention spaces reviews further', () {
    expect(const Fsrs(desiredRetention: 0.8).interval(10), greaterThan(10));
    expect(const Fsrs(desiredRetention: 0.95).interval(10), lessThan(10));
    expect(const Fsrs(maximumInterval: 30).interval(1000), 30);
  });

  test('a review uses the time since the last one', () {
    final last = DateTime(2026, 9, 22, 8);
    final r = fsrs.review(
      state: const MemoryState(stability: 10, difficulty: 5),
      lastReview: last,
      grade: Grade.good,
      now: DateTime(2026, 10, 2, 8),
    );
    final direct = fsrs.next(
      const MemoryState(stability: 10, difficulty: 5),
      Grade.good,
      10,
    );
    expect(r.state.stability, closeTo(direct.stability, 1e-9));
    expect(r.interval, fsrs.interval(direct.stability));
  });
}
