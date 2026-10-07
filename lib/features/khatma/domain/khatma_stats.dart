import 'day.dart';
import 'khatmah.dart';

/// Reading totals for a consecutive range of logical days.
class KhatmaPeriodStats {
  const KhatmaPeriodStats({
    required this.weight,
    required this.readingDays,
    required this.sessions,
    required this.seconds,
  });

  factory KhatmaPeriodStats.forDays(Ledger ledger, Day first, int count) {
    var weight = 0.0;
    var readingDays = 0;
    var sessions = 0;
    var seconds = 0;
    for (var i = 0; i < count; i++) {
      final day = first.add(i);
      final dailyWeight = ledger.weightOn(day);
      weight += dailyWeight;
      if (dailyWeight > 0) readingDays++;
      sessions += ledger.dailySessions[day] ?? 0;
      seconds += ledger.dailySeconds[day] ?? 0;
    }
    return KhatmaPeriodStats(
      weight: weight,
      readingDays: readingDays,
      sessions: sessions,
      seconds: seconds,
    );
  }

  final double weight;
  final int readingDays;
  final int sessions;
  final int seconds;
}
