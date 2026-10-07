import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/user_database.dart';
import 'package:tibyan/core/sync/sync.dart';
import 'package:tibyan/features/hifz/data/hifz_store.dart';

void main() {
  test(
    'a version 2 database gains the hifz tables and keeps its rows',
    () async {
      final db = UserDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            // The schema as version 2 left it.
            raw.execute(
              'CREATE TABLE bookmark_sets (id INTEGER NOT NULL PRIMARY KEY '
              'AUTOINCREMENT, name TEXT NOT NULL, color INTEGER NOT NULL, '
              'surah INTEGER NOT NULL, ayah INTEGER NOT NULL, page INTEGER NOT '
              'NULL, sort_order INTEGER NOT NULL DEFAULT 0, updated_at INTEGER '
              'NOT NULL, kind TEXT NULL)',
            );
            raw.execute(
              'CREATE TABLE reading_positions (id INTEGER NOT NULL DEFAULT 1, '
              'edition TEXT NOT NULL, view TEXT NOT NULL, surah INTEGER NOT '
              'NULL, ayah INTEGER NOT NULL, page INTEGER NOT NULL, updated_at '
              'INTEGER NOT NULL, PRIMARY KEY (id))',
            );
            raw.execute(
              "INSERT INTO bookmark_sets (name, color, surah, ayah, page, "
              "updated_at) VALUES ('x', 1, 2, 255, 42, 0)",
            );
            raw.execute('PRAGMA user_version = 2');
          },
        ),
      );
      addTearDown(db.close);
      expect((await db.watchBookmarkSets().first).single.ayah, 255);
      expect(await db.watchSrsItems().first, isEmpty);
      expect(await db.watchVerseStrengths().first, isEmpty);
      final v = await db.customSelect('PRAGMA user_version').getSingle();
      expect(v.data.values.single, 5); // v5: khatmah v1.1
    },
  );

  group('hifz tables', () {
    late UserDatabase db;
    setUp(() => db = UserDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<void> save(String from, String to, DateTime due) => db.saveSrsReview(
      unit: 'page',
      fromRef: from,
      toRef: to,
      stability: 3.7,
      difficulty: 5.2,
      dueAt: due,
      lapse: false,
      now: DateTime(2026, 10, 2),
    );

    test('units sort by due date; removing one keeps it for sync', () async {
      await save('2:6', '2:16', DateTime(2026, 10, 9));
      await save('2:1', '2:5', DateTime(2026, 10, 4));
      var items = await db.watchSrsItems().first;
      expect(items.map((i) => i.fromRef), ['2:1', '2:6']);
      expect(items.first.uuid, isNot(items.last.uuid));
      await db.deleteSrsItem(items.first.id);
      items = await db.watchSrsItems().first;
      expect(items.map((i) => i.fromRef), ['2:6']);
      final all = await db.select(db.srsItems).get();
      expect(all.where((i) => i.deletedAt != null), hasLength(1));
      // A deleted unit graded again starts afresh.
      await save('2:1', '2:5', DateTime(2026, 10, 5));
      expect((await db.srsItem('page', '2:1', '2:5'))!.reps, 1);
      final queued = await db.select(db.outbox).get();
      expect(queued.where((e) => e.entity == 'srs_item'), hasLength(2));
    });

    test('strengths are set once per verse and updated in place', () async {
      await db.setVerseStrengths({'2:255': 2});
      final first = await db.select(db.memorizations).getSingle();
      await db.setVerseStrengths({'2:255': 4, '2:256': 1});
      final rows = await db.select(db.memorizations).get();
      expect(rows, hasLength(2));
      final kept = rows.firstWhere((r) => r.ref == '2:255');
      expect(kept.uuid, first.uuid);
      expect(kept.strength, 4);
      expect(await db.verseStrengths(['2:256', '3:1']), {'2:256': 1});
      // The same verse gets the same uuid on every device.
      expect(kept.uuid, HifzStore.memoUuid('ayah', '2:255'));
      // Every change waits in the sync outbox, one entry per row.
      final queued = await db.select(db.outbox).get();
      expect(queued.map((e) => e.entity).toSet(), {'memorization'});
      expect(queued, hasLength(2));
    });
  });

  test('columns the sync plan needs', () {
    final db = UserDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    for (final table in <TableInfo>[db.srsItems, db.memorizations]) {
      final names = table.$columns.map((c) => c.name).toSet();
      expect(names, containsAll(['uuid', 'updated_at', 'deleted_at']));
    }
    expect(
      db.srsItems.$columns.map((c) => c.name),
      containsAll([
        'unit',
        'from_ref',
        'to_ref',
        'stability',
        'difficulty',
        'due_at',
        'reps',
        'lapses',
      ]),
    );
    expect(
      db.memorizations.$columns.map((c) => c.name),
      containsAll(['unit', 'ref', 'strength']),
    );
  });

  test('a newer review from another device replaces the local one', () async {
    final db = UserDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.saveSrsReview(
      unit: 'surah',
      fromRef: '67:1',
      toRef: '67:30',
      stability: 4,
      difficulty: 5,
      dueAt: DateTime(2026, 10, 6),
      lapse: false,
      now: DateTime(2026, 10, 2),
    );
    final local = (await db.srsItem('surah', '67:1', '67:30'))!;
    final remote = local.copyWith(
      stability: 20,
      reps: 2,
      updatedAt: DateTime(2026, 10, 3),
    );
    expect(
      await applyRemote(
        db,
        RemoteChange(
          table: 'srs_item',
          uuid: local.uuid,
          row: remote.toJson(),
          updatedAt: remote.updatedAt,
        ),
      ),
      isTrue,
    );
    final merged = (await db.srsItem('surah', '67:1', '67:30'))!;
    expect((merged.stability, merged.reps), (20.0, 2));
    expect(syncedTables, containsAll(['srs_item', 'memorization']));
  });
}
