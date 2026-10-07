import 'dart:convert';
import 'dart:math';

/// A run of verse numbers, both ends included.
typedef AyahRange = ({int from, int to});

/// A set of verse numbers kept as runs: sorted, merged (no two runs touch
/// or overlap) and immutable. The coverage of a khatma, the verses read in
/// a session, and a khatma's range are all interval sets.
class IntervalSet {
  /// The runs of [ranges], merged; empty runs (to < from) are dropped.
  factory IntervalSet(Iterable<AyahRange> ranges) {
    final list = [
      for (final r in ranges)
        if (r.to >= r.from) r,
    ]..sort((a, b) => a.from.compareTo(b.from));
    final out = <AyahRange>[];
    for (final r in list) {
      if (out.isNotEmpty && r.from <= out.last.to + 1) {
        final last = out.removeLast();
        out.add((from: last.from, to: max(last.to, r.to)));
      } else {
        out.add(r);
      }
    }
    return IntervalSet._(List.unmodifiable(out));
  }

  const IntervalSet._(this.ranges);

  static const empty = IntervalSet._([]);

  /// One run.
  factory IntervalSet.range(int from, int to) => to < from
      ? empty
      : IntervalSet._(List.unmodifiable([(from: from, to: to)]));

  /// Runs of the given verse numbers.
  factory IntervalSet.of(Iterable<int> ids) =>
      IntervalSet([for (final i in ids) (from: i, to: i)]);

  /// The runs, in order.
  final List<AyahRange> ranges;

  bool get isEmpty => ranges.isEmpty;
  bool get isNotEmpty => ranges.isNotEmpty;

  /// How many verse numbers it holds.
  int get count => ranges.fold(0, (n, r) => n + r.to - r.from + 1);

  int? get first => ranges.isEmpty ? null : ranges.first.from;
  int? get last => ranges.isEmpty ? null : ranges.last.to;

  /// The run holding [id], or the index where it would go, as
  /// (index, found).
  (int, bool) _find(int id) {
    var lo = 0, hi = ranges.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      final r = ranges[mid];
      if (id < r.from) {
        hi = mid;
      } else if (id > r.to) {
        lo = mid + 1;
      } else {
        return (mid, true);
      }
    }
    return (lo, false);
  }

  bool contains(int id) => _find(id).$2;

  /// Whether every verse of [from] … [to] is in the set.
  bool containsRange(int from, int to) {
    if (to < from) return true;
    final (i, found) = _find(from);
    return found && ranges[i].to >= to;
  }

  /// Whether every verse of [other] is in the set.
  bool containsAll(IntervalSet other) =>
      other.ranges.every((r) => containsRange(r.from, r.to));

  IntervalSet union(IntervalSet other) {
    if (other.isEmpty) return this;
    if (isEmpty) return other;
    return IntervalSet([...ranges, ...other.ranges]);
  }

  IntervalSet add(int from, int to) => union(IntervalSet.range(from, to));

  /// The verses in both.
  IntervalSet intersect(IntervalSet other) {
    final out = <AyahRange>[];
    var i = 0, j = 0;
    while (i < ranges.length && j < other.ranges.length) {
      final a = ranges[i], b = other.ranges[j];
      final from = max(a.from, b.from);
      final to = min(a.to, b.to);
      if (from <= to) out.add((from: from, to: to));
      if (a.to < b.to) {
        i++;
      } else {
        j++;
      }
    }
    return IntervalSet._(List.unmodifiable(out));
  }

  /// The verses of this set that are not in [other].
  IntervalSet subtract(IntervalSet other) {
    if (isEmpty || other.isEmpty) return this;
    final out = <AyahRange>[];
    var j = 0;
    for (final r in ranges) {
      var from = r.from;
      while (j < other.ranges.length && other.ranges[j].to < from) {
        j++;
      }
      var k = j;
      while (k < other.ranges.length && other.ranges[k].from <= r.to) {
        final o = other.ranges[k];
        if (o.from > from) out.add((from: from, to: o.from - 1));
        from = max(from, o.to + 1);
        if (from > r.to) break;
        k++;
      }
      if (from <= r.to) out.add((from: from, to: r.to));
    }
    return IntervalSet._(List.unmodifiable(out));
  }

  /// The first verse at or after [from], up to [to], that is not in the
  /// set; null when all of [from] … [to] is.
  int? firstGap(int from, int to) {
    if (to < from) return null;
    final (i, found) = _find(from);
    if (!found) return from;
    final next = ranges[i].to + 1;
    return next <= to ? next : null;
  }

  /// Sums [weight] over each run (e.g. `QuranIndex.weightOf`).
  double weigh(double Function(int from, int to) weight) =>
      ranges.fold(0.0, (s, r) => s + weight(r.from, r.to));

  /// `[[from, to], …]`, the form kept in the database.
  String toJson() => jsonEncode([
    for (final r in ranges) [r.from, r.to],
  ]);

  /// Reads [toJson]'s form; an empty, null or broken text is the empty set.
  static IntervalSet fromJson(String? text) {
    if (text == null || text.isEmpty) return empty;
    try {
      final raw = jsonDecode(text);
      if (raw is! List) return empty;
      return IntervalSet([
        for (final r in raw)
          if (r is List && r.length == 2 && r[0] is int && r[1] is int)
            (from: r[0] as int, to: r[1] as int),
      ]);
    } on FormatException {
      return empty;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is! IntervalSet || other.ranges.length != ranges.length) {
      return false;
    }
    for (var i = 0; i < ranges.length; i++) {
      if (ranges[i] != other.ranges[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(ranges);

  @override
  String toString() =>
      '{${ranges.map((r) => r.from == r.to ? '${r.from}' : '${r.from}-${r.to}').join(', ')}}';
}
