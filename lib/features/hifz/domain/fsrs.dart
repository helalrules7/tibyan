import 'dart:math' as math;

/// How the reader judged a review, as in FSRS: 1 forgot, 2 hard, 3 good,
/// 4 easy.
enum Grade {
  again(1),
  hard(2),
  good(3),
  easy(4);

  const Grade(this.value);
  final int value;
}

/// The memory state of one review unit.
class MemoryState {
  const MemoryState({required this.stability, required this.difficulty});

  /// Days until the chance of recalling the unit falls to 90%.
  final double stability;

  /// 1 (easy to keep) to 10 (hard to keep).
  final double difficulty;
}

/// The outcome of a review: the new state and when to review next.
class Review {
  const Review({
    required this.state,
    required this.interval,
    required this.due,
  });

  final MemoryState state;

  /// Whole days until the next review (at least one).
  final int interval;
  final DateTime due;
}

/// Spaced review scheduling after FSRS 4.5 (Free Spaced Repetition
/// Scheduler, Jarrett Ye and the open-spaced-repetition project; the model
/// is public and this is our own implementation of its published formulas,
/// with its default weights).
///
/// The model keeps two numbers per unit:
/// - stability S: days after which recall has fallen to 90%;
/// - difficulty D: 1..10, how much each success grows S.
///
/// Recall after t days is R = (1 + F·t/S)^C, with C = -0.5 and F = 19/81, so
/// R(S) = 0.9. The next review is set for when R falls to
/// [desiredRetention]: interval = S/F · (r^(1/C) − 1), which is S itself at
/// r = 0.9.
///
/// First review with grade G: S = w[G−1], D = w4 − (G−3)·w5.
///
/// Later reviews, with R the recall at the moment of review:
/// - D′ = D − w6·(G−3), pulled back towards w4 by w7 (mean reversion),
///   kept within 1..10;
/// - recalled (G ≥ 2): S′ = S · (1 + e^w8 · (11−D) · S^−w9 · (e^(w10·(1−R)) − 1)
///   · (w15 if hard) · (w16 if easy));
/// - forgotten (G = 1): S′ = min(S, w11 · D^−w12 · ((S+1)^w13 − 1) · e^(w14·(1−R))),
///   and the unit counts a lapse.
///
/// Days are whole: a unit is due on a day, never sooner than tomorrow, as
/// a Quran review is planned day by day rather than within minutes.
class Fsrs {
  const Fsrs({this.desiredRetention = 0.9, this.maximumInterval = 36500});

  /// FSRS 4.5 default weights.
  static const w = [
    0.4872, 1.4003, 3.7145, 13.8206, 5.1618, 1.2298, 0.8975, 0.031, //
    1.6474, 0.1367, 1.0461, 2.1072, 0.0793, 0.3246, 1.587, 0.2272, 2.8755,
  ];
  static const decay = -0.5;
  static const factor = 19 / 81;

  final double desiredRetention;
  final int maximumInterval;

  /// Chance of recalling a unit of [stability] after [elapsedDays].
  static double retrievability(double elapsedDays, double stability) =>
      math.pow(1 + factor * elapsedDays / stability, decay).toDouble();

  static double _initialDifficulty(Grade g) =>
      (w[4] - (g.value - 3) * w[5]).clamp(1, 10).toDouble();

  MemoryState first(Grade g) =>
      MemoryState(stability: w[g.value - 1], difficulty: _initialDifficulty(g));

  MemoryState next(MemoryState s, Grade g, double elapsedDays) {
    final r = retrievability(math.max(0, elapsedDays), s.stability);
    final d0 = w[4];
    final dNext = s.difficulty - w[6] * (g.value - 3);
    final difficulty = (w[7] * d0 + (1 - w[7]) * dNext).clamp(1, 10).toDouble();
    final double stability;
    if (g == Grade.again) {
      final forget =
          w[11] *
          math.pow(s.difficulty, -w[12]) *
          (math.pow(s.stability + 1, w[13]) - 1) *
          math.exp(w[14] * (1 - r));
      stability = math.min(forget, s.stability);
    } else {
      final hard = g == Grade.hard ? w[15] : 1.0;
      final easy = g == Grade.easy ? w[16] : 1.0;
      stability =
          s.stability *
          (1 +
              math.exp(w[8]) *
                  (11 - s.difficulty) *
                  math.pow(s.stability, -w[9]) *
                  (math.exp(w[10] * (1 - r)) - 1) *
                  hard *
                  easy);
    }
    return MemoryState(stability: stability, difficulty: difficulty);
  }

  /// Whole days until recall falls to [desiredRetention].
  int interval(double stability) {
    final days =
        stability / factor * (math.pow(desiredRetention, 1 / decay) - 1);
    return days.round().clamp(1, maximumInterval);
  }

  /// Reviews a unit at [now]: [state] is null for a unit never reviewed,
  /// [lastReview] when it was last reviewed. The due date is the start of
  /// the local day [interval] days after [now].
  Review review({
    required MemoryState? state,
    required DateTime? lastReview,
    required Grade grade,
    required DateTime now,
  }) {
    final MemoryState next;
    if (state == null || lastReview == null) {
      next = first(grade);
    } else {
      final elapsed = now.difference(lastReview).inMinutes / (24 * 60);
      next = this.next(state, grade, elapsed);
    }
    final days = interval(next.stability);
    final today = DateTime(now.year, now.month, now.day);
    return Review(
      state: next,
      interval: days,
      due: DateTime(today.year, today.month, today.day + days),
    );
  }
}
