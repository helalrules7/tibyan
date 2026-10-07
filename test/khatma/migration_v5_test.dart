import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:tibyan/core/db/user_database.dart';
import 'package:tibyan/features/khatma/data/activity_repository.dart';
import 'package:tibyan/features/khatma/data/khatma_repository.dart';
import 'package:tibyan/features/khatma/data/khatmah_store.dart';
import 'package:tibyan/features/khatma/domain/day.dart';
import 'package:tibyan/features/khatma/domain/khatma_plan.dart';
import 'package:tibyan/features/khatma/domain/khatmah.dart';
import 'package:tibyan/features/khatma/domain/quran_index.dart';

import 'support.dart';

int _secs(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

/// A user.db as version 4 wrote it: three khatmas (one being read, one
/// completed in the Shamarly edition, one deleted), their logs, and a
/// reading session for the reports.
void _v4(Database raw) {
  for (final sql in userDbV4Schema()) {
    raw.execute(sql);
  }
  final t = _secs(DateTime(2026, 10, 1, 9));
  void khatma(
    int id,
    String uuid,
    String edition,
    String start,
    String target, {
    int? completed,
    int? deleted,
    double? portion,
    String unit = 'page',
  }) => raw.execute(
    'INSERT INTO khatma (uuid, updated_at, deleted_at, id, title, edition, '
    'unit, start_date, target_date, daily_portion, reminder_time, '
    'rebased_on, completed_at, created_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 480, NULL, ?, ?)',
    [
      uuid,
      t,
      deleted,
      id,
      'ختمة $id',
      edition,
      unit,
      start,
      target,
      portion,
      completed,
      t + id,
    ],
  );
  var log = 0;
  void read(String khatma, String date, int from, int to) => raw.execute(
    'INSERT INTO khatma_log (uuid, updated_at, khatma_uuid, date, from_page, '
    'to_page) VALUES (?, ?, ?, ?, ?, ?)',
    ['log-${++log}', t, khatma, date, from, to],
  );

  khatma(
    2,
    'shamarly-done',
    'shamarly',
    '2026-09-01',
    '2026-09-30',
    completed: t,
    portion: 1,
    unit: 'juz',
  );
  read('shamarly-done', '2026-09-01', 2, 20);
  read('shamarly-done', '2026-09-02', 21, 41);
  read('shamarly-done', '2026-09-03', 100, 100);
  khatma(3, 'deleted', 'madina1441', '2026-09-10', '2026-10-10', deleted: t);
  khatma(4, 'reading', 'madina1441', '2026-10-01', '2026-10-30');
  read('reading', '2026-10-01', 1, 20);
  read('reading', '2026-10-02', 21, 35);
  read('reading', '2026-10-03', 36, 38);
  read('reading', '2026-10-03', 50, 51);
  raw.execute(
    'INSERT INTO reading_session (uuid, updated_at, started_at, ended_at, '
    "pages, mode, edition) VALUES ('s-old', ?, ?, ?, 5, 'page', 'madina1441')",
    [t, t, t + 600],
  );
  raw.userVersion = 4;
}

void main() {
  late QuranIndex index;
  late UserDatabase db;
  late KhatmahStore store;

  setUpAll(() async => index = await realIndex());
  setUp(() {
    db = UserDatabase(NativeDatabase.memory(setup: _v4));
    store = KhatmahStore(db);
  });
  tearDown(() => db.close());

  Future<int> migrate() =>
      store.migrateLegacy(index, (e) => index.hafsPages(e));

  test('opening a v4 database adds the v5 columns and tables', () async {
    final k = await store.khatmahs();
    expect(k.map((e) => e.uuid), ['shamarly-done', 'reading']);
    final rows = {for (final r in await db.select(db.khatmas).get()) r.uuid: r};
    expect(rows['reading']!.status, 'active');
    expect(rows['reading']!.isPrimary, isTrue);
    expect(rows['reading']!.pacingMode, 'endDate');
    expect(rows['shamarly-done']!.status, 'completed');
    expect(rows['shamarly-done']!.isPrimary, isFalse);
    expect(rows['shamarly-done']!.pacingMode, 'dailyAmount');
    expect(rows['deleted']!.status, 'cancelled');
    // Not carried over yet: no verse range.
    expect(rows['reading']!.rangeStart, isNull);
    expect(await db.select(db.sessionAttributions).get(), isEmpty);
    // The old session is a reader session for the reports.
    final s = await db.select(db.readingSessions).get();
    expect(s.single.source, 'reader');
    expect(s.single.ranges, '');
  });

  test('scenario 17: the same pages read, the same share, the same next '
      'page', () async {
    // What version 4 showed.
    final oldLogs = await KhatmaRepository(db).logs('reading');
    final oldRead = readPages(oldLogs);
    final oldPlan = KhatmaPlan(
      unitStarts: pageUnitStarts(1, 604),
      lastPage: 604,
      from: Day(2026, 10, 1),
      target: Day(2026, 10, 30),
    );
    expect(oldPlan.pagesDone(oldRead), 40);
    expect(oldPlan.nextPage(oldRead), 39);

    expect(await migrate(), 3);
    final k = (await store.byUuid('reading'))!;
    expect(k.rangeStart, 1);
    expect(k.rangeEnd, 6236);
    expect(k.startAt, 1);
    expect(k.kind, KhatmahKind.fullQuran);
    expect(k.schedule, ScheduleMode.adaptive);
    expect(k.isPrimary, isTrue);
    expect(k.counting, CountingMode.auto);
    expect(k.reminderTime, 480);
    expect(k.dailyWeight, closeTo(604 / 30, 1e-9));

    final ledger = await store.ledger(k, index);
    final pages = index.madina1441;
    expect(pages.readPages(ledger.covered), oldRead);
    expect(
      ledger.coveredWeight / index.totalWeight,
      closeTo(oldPlan.pagesDone(oldRead) / oldPlan.totalPages, 1e-9),
    );
    expect(pages.pageOf(ledger.frontier!), oldPlan.nextPage(oldRead));
    expect(ledger.weightOn(Day(2026, 10, 1)), closeTo(20, 1e-9));
    expect(ledger.weightOn(Day(2026, 10, 3)), closeTo(5, 1e-9));

    // The cache was written, and agrees.
    final cached = (await store.cachedCoverage('reading'))!;
    expect(cached.coveredWeight, closeTo(40, 1e-9));
    expect(cached.frontier, ledger.frontier);
    expect((await store.dailyStats('reading')).map((d) => d.day), [
      '2026-10-01',
      '2026-10-02',
      '2026-10-03',
    ]);
  });

  test('a Shamarly khatma keeps its pages, verses running over a page '
      'included', () async {
    final oldRead = readPages(await KhatmaRepository(db).logs('shamarly-done'));
    await migrate();
    final k = (await store.byUuid('shamarly-done'))!;
    expect(k.status, KhatmahStatus.completed);
    // A juz a day, in Madina pages.
    expect(k.dailyWeight, closeTo(604 / 30, 1e-9));
    final ledger = await store.ledger(k, index);
    expect(index.shamarly.readPages(ledger.covered), oldRead);
  });

  test('sessions are manual, one a day; the old log stays; the reports '
      'do not count them', () async {
    await migrate();
    final sessions = await store.sessionsSince(DateTime(2026));
    final carried = [
      for (final s in sessions)
        if (s.source == SessionSource.manual) s,
    ];
    expect(carried.length, 3 + 3);
    expect(carried.every((s) => s.entryPoint == EntryPoint.other), isTrue);
    final credits = await store.credits(khatmaUuid: 'reading');
    expect(credits.length, 3);
    expect(credits.every((c) => c.decidedBy == DecidedBy.auto), isTrue);
    expect(await db.select(db.khatmaLogs).get(), hasLength(7));
    final reports = await ActivityRepository(db)
        .watchReadingSince(DateTime(2026))
        .first;
    expect(reports.single.uuid, 's-old');
    // Queued for sync like every other change.
    final out = await db.select(db.outbox).get();
    expect(out.where((o) => o.entity == 'session_attribution'), hasLength(6));
  });

  test('running it again carries nothing twice', () async {
    expect(await migrate(), 3);
    expect(await migrate(), 0);
    expect(await store.credits(), hasLength(6));
  });

  test('a khatma whose edition pages are not at hand waits', () async {
    expect(
      await store.migrateLegacy(
        index,
        (e) => e == 'shamarly' ? null : index.hafsPages(e),
      ),
      2,
    );
    expect((await store.byUuid('shamarly-done'))!.rangeStart, 1);
    final row = await (db.select(
      db.khatmas,
    )..where((t) => t.uuid.equals('shamarly-done'))).getSingle();
    expect(row.rangeStart, isNull);
    expect(await migrate(), 1);
  });

  test('scenario 13: the cache dropped and rebuilt gives the same '
      'numbers', () async {
    await migrate();
    final before = await store.cachedCoverage('reading');
    final stats = await store.dailyStats('reading');
    await db.delete(db.khatmaCoverages).go();
    await db.delete(db.dailyStats).go();
    await store.rebuildAll(index);
    final after = await store.cachedCoverage('reading');
    expect(after!.ranges, before!.ranges);
    expect(after.coveredWeight, before.coveredWeight);
    expect(after.frontier, before.frontier);
    expect(
      [
        for (final d in await store.dailyStats('reading'))
          (d.day, d.weightRead, d.sessions),
      ],
      [for (final d in stats) (d.day, d.weightRead, d.sessions)],
    );
  });
}
