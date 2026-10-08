import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/khatma/domain/day.dart';
import 'package:tibyan/features/khatma/domain/interval_set.dart';
import 'package:tibyan/features/khatma/domain/khatmah.dart';
import 'package:tibyan/features/khatma/domain/khatma_stats.dart';

import 'support.dart';

void main() {
  test('period totals include logical days across a year boundary', () async {
    final index = await realIndex();
    final khatma = Khatmah(
      uuid: 'k',
      title: 'test',
      startDate: Day(2024, 12, 1),
    );
    final ledger = Ledger(
      khatma,
      [
        Credit(
          sessionUuid: 's1',
          khatmaUuid: khatma.uuid,
          ranges: IntervalSet.range(1, 1),
          newWeight: 0,
          decidedBy: DecidedBy.auto,
          day: Day(2024, 12, 31),
          at: DateTime(2024, 12, 31, 12),
        ),
        Credit(
          sessionUuid: 's2',
          khatmaUuid: khatma.uuid,
          ranges: IntervalSet.range(2, 2),
          newWeight: 0,
          decidedBy: DecidedBy.auto,
          day: Day(2025, 1, 1),
          at: DateTime(2025, 1, 1, 12),
        ),
      ],
      index,
      sessionSeconds: {'s1': 120, 's2': 60},
    );

    final stats = KhatmaPeriodStats.forDays(ledger, Day(2024, 12, 29), 7);

    expect(stats.readingDays, 2);
    expect(stats.sessions, 2);
    expect(stats.seconds, 180);
    expect(stats.weight, closeTo(index.weightOf(1, 2), 1e-9));
  });
}
