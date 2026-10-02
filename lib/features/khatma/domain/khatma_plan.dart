import 'dart:math';

import 'day.dart';

/// What a day's portion is made of.
enum PortionUnit { page, juz, hizb }

/// A run of pages, both ends included.
typedef PageRange = ({int from, int to});

/// The arithmetic of a khatma, in one edition's pages.
///
/// The mushaf is cut into units (every page, every juz or every hizb) by
/// [unitStarts], the first page of each. The plan expects whole units to be
/// finished each day, spread evenly from [from] to [target]: by the end of
/// day `i` (0-based) `ceil(R * (i + 1) / D)` of the `R` units remaining
/// at [from] are read, `D` being the days from [from] to [target].
///
/// After a catch-up the plan is counted again from the day of the catch-up
/// ([from]) and the unit the reader had reached then ([baseUnit]).
class KhatmaPlan {
  KhatmaPlan({
    required List<int> unitStarts,
    required this.lastPage,
    required this.from,
    required this.target,
    this.baseUnit = 0,
  }) : unitStarts = List.unmodifiable(unitStarts),
       assert(unitStarts.isNotEmpty),
       assert(!target.isBefore(from));

  /// First page of each unit, ascending; the first is the first page of
  /// text.
  final List<int> unitStarts;
  final int lastPage;
  final Day from;
  final Day target;
  final int baseUnit;

  int get firstPage => unitStarts.first;
  int get totalPages => lastPage - firstPage + 1;
  int get unitCount => unitStarts.length;

  /// Days from [from] to [target], both included.
  int get days => target.difference(from) + 1;

  /// Last page of unit [k].
  int unitEnd(int k) =>
      k + 1 < unitStarts.length ? unitStarts[k + 1] - 1 : lastPage;

  /// The unit [page] falls in.
  int unitOf(int page) {
    var k = 0;
    while (k + 1 < unitStarts.length && unitStarts[k + 1] <= page) {
      k++;
    }
    return k;
  }

  /// Units the plan expects finished by the end of [day].
  int expectedUnits(Day day) {
    final i = day.difference(from);
    if (i < 0) return baseUnit;
    if (i >= days - 1) return unitCount;
    final remaining = unitCount - baseUnit;
    return min(unitCount, baseUnit + (remaining * (i + 1) / days).ceil());
  }

  /// Last page the plan expects read by the end of [day]; `firstPage - 1`
  /// when nothing is due yet.
  int expectedEnd(Day day) {
    final u = expectedUnits(day);
    return u == 0 ? firstPage - 1 : unitEnd(u - 1);
  }

  /// The units a day comes to on average, from [from] on.
  double get unitsPerDay => (unitCount - baseUnit) / days;

  /// Pages of the plan in [read].
  int pagesDone(Set<int> read) =>
      read.where((p) => p >= firstPage && p <= lastPage).length;

  /// First page not read yet, or null when the whole mushaf is read.
  int? nextPage(Set<int> read) {
    for (var p = firstPage; p <= lastPage; p++) {
      if (!read.contains(p)) return p;
    }
    return null;
  }

  bool isComplete(Set<int> read) => nextPage(read) == null;

  int _unreadUpTo(int end, Set<int> read) {
    var n = 0;
    for (var p = firstPage; p <= end; p++) {
      if (!read.contains(p)) n++;
    }
    return n;
  }

  /// Pages that were due before [today] and are not read yet. Zero means
  /// the reader is on track.
  int pagesBehind(Day today, Set<int> read) =>
      _unreadUpTo(expectedEnd(today.add(-1)), read);

  /// Today's portion: from the first unread page to the end of what is due
  /// today, and how many unread pages that is. Null when today's portion
  /// is done (or the khatma is complete).
  ({PageRange range, int pages})? todayPortion(Day today, Set<int> read) {
    final start = nextPage(read);
    if (start == null) return null;
    final end = expectedEnd(today);
    if (end < start) return null;
    return (range: (from: start, to: end), pages: _unreadUpTo(end, read));
  }

  /// The portion of each day from [today] for [count] days, assuming each
  /// day's portion is read: for reminders and the home screen widget.
  /// Days with nothing due are left out.
  Map<Day, PageRange> upcoming(Day today, Set<int> read, {int count = 14}) {
    final out = <Day, PageRange>{};
    final first = todayPortion(today, read);
    if (first != null) out[today] = first.range;
    var after = max(first?.range.to ?? 0, (nextPage(read) ?? lastPage + 1) - 1);
    for (var i = 1; i < count; i++) {
      final d = today.add(i);
      if (d.isAfter(target) || after >= lastPage) break;
      final end = expectedEnd(d);
      if (end <= after) continue;
      out[d] = (from: after + 1, to: end);
      after = end;
    }
    return out;
  }

  /// Days a plan of [perDay] units a day takes for [units] units.
  static int daysFor(int units, double perDay) =>
      max(1, (units / perDay).ceil());
}

/// Pages per unit for each edition: the first page of every unit.
List<int> pageUnitStarts(int firstPage, int lastPage) => [
  for (var p = firstPage; p <= lastPage; p++) p,
];

/// Merges pages into runs, for the khatma log.
List<PageRange> pageRuns(Iterable<int> pages) {
  final sorted = pages.toSet().toList()..sort();
  final out = <PageRange>[];
  for (final p in sorted) {
    if (out.isNotEmpty && out.last.to == p - 1) {
      out[out.length - 1] = (from: out.last.from, to: p);
    } else {
      out.add((from: p, to: p));
    }
  }
  return out;
}
