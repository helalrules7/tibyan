/// A local calendar day, free of time zones and daylight-saving shifts.
/// Stored as `yyyy-MM-dd`.
class Day implements Comparable<Day> {
  const Day(this.year, this.month, this.day);

  factory Day.of(DateTime t) => Day(t.year, t.month, t.day);

  factory Day.parse(String key) {
    final p = key.split('-').map(int.parse).toList();
    return Day(p[0], p[1], p[2]);
  }

  static Day today() => Day.of(DateTime.now());

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// Local midnight at the start of this day.
  DateTime get start => DateTime(year, month, day);

  Day add(int days) => Day.of(_utc.add(Duration(days: days)));

  /// Whole days from [other] to this day (positive when this is later).
  int difference(Day other) => _utc.difference(other._utc).inDays;

  String get key =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  bool isBefore(Day o) => compareTo(o) < 0;
  bool isAfter(Day o) => compareTo(o) > 0;

  @override
  int compareTo(Day o) => _utc.compareTo(o._utc);

  @override
  bool operator ==(Object other) =>
      other is Day &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => key;
}
