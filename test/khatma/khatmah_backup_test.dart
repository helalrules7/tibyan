import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/backup/backup.dart';
import 'package:tibyan/core/db/user_database.dart';
import 'package:tibyan/features/khatma/data/khatmah_store.dart';
import 'package:tibyan/features/khatma/domain/day.dart';
import 'package:tibyan/features/khatma/domain/interval_set.dart';
import 'package:tibyan/features/khatma/domain/khatmah.dart';
import 'package:tibyan/features/khatma/domain/quran_index.dart';

import 'support.dart';

void main() {
  late QuranIndex index;
  setUpAll(() async => index = await realIndex());

  test('a backup carries khatmas, pauses, sessions and attributions; not '
      'the cache, which is rebuilt', () async {
    final a = UserDatabase(NativeDatabase.memory());
    final b = UserDatabase(NativeDatabase.memory());
    addTearDown(a.close);
    addTearDown(b.close);
    final store = KhatmahStore(a);
    final day = Day(2026, 10, 7);
    final k = await store.insert(
      Khatmah(
        uuid: 'k1',
        title: 'رمضان',
        startDate: day,
        targetDate: day.add(29),
        dailyWeight: 604 / 30,
        isPrimary: true,
        restWeekdays: const {5},
        presetId: 'ramadan_30',
      ),
    );
    await store.addPause('k1', day.add(2));
    final at = day.start.add(const Duration(hours: 8));
    await store.putSession(
      SessionRecord(
        uuid: 's1',
        start: at,
        end: at.add(const Duration(minutes: 20)),
        ranges: IntervalSet.range(1, 148),
        pages: 21,
        entryPoint: EntryPoint.home,
      ),
    );
    await store.putCredit(
      Credit(
        sessionUuid: 's1',
        khatmaUuid: 'k1',
        ranges: IntervalSet.range(1, 148),
        newWeight: index.weightOf(1, 148),
        decidedBy: DecidedBy.auto,
        day: day,
        at: at,
      ),
    );
    await store.rebuild(k, index);

    final text = await Backup(a).export();
    final tables = (jsonDecode(text) as Map)['tables'] as Map;
    expect(tables.keys, containsAll(['khatma_pause', 'session_attribution']));
    expect(tables.keys, isNot(contains('khatma_coverage')));
    expect(tables.keys, isNot(contains('daily_stat')));

    await Backup(b).import(text);
    final restored = KhatmahStore(b);
    final k2 = (await restored.byUuid('k1'))!;
    expect(k2.restWeekdays, {5});
    expect(k2.presetId, 'ramadan_30');
    expect(k2.isPrimary, isTrue);
    expect(k2.pauses.single.from, day.add(2));
    expect((await restored.session('s1'))!.entryPoint, EntryPoint.home);
    expect(await restored.cachedCoverage('k1'), isNull);
    await restored.rebuildAll(index);
    expect(
      (await restored.cachedCoverage('k1'))!.coveredWeight,
      closeTo(index.weightOf(1, 148), 1e-9),
    );
  });
}
