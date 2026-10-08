import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/user_database.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/features/khatma/data/khatmah_book.dart';
import 'package:tibyan/features/khatma/data/khatmah_store.dart';
import 'package:tibyan/features/khatma/domain/day.dart';
import 'package:tibyan/features/khatma/domain/interval_set.dart';
import 'package:tibyan/features/khatma/domain/khatmah.dart';
import 'package:tibyan/features/khatma/domain/quran_index.dart';
import 'package:tibyan/features/khatma/khatma_providers.dart';

import 'support.dart';

/// The khatmas at work on a real (in-memory) user.db and the real verse
/// index: sessions in, attributions, caches and the screens' status out.
void main() {
  late QuranIndex index;
  late UserDatabase db;
  late KhatmahStore store;
  late KhatmahBook book;
  late DateTime now;
  var ids = 0;
  final day1 = Day(2026, 10, 1);

  setUpAll(() async => index = await realIndex());
  setUp(() {
    db = UserDatabase(NativeDatabase.memory());
    store = KhatmahStore(db);
    now = DateTime(2026, 10, 1, 9);
    book = KhatmahBook(
      store: store,
      index: index,
      clock: () => now,
      newUuid: () => 'id${++ids}',
    );
  });
  tearDown(() => db.close());

  EditionPageMap pages() => index.madina1441;

  IntervalSet pagesRead(int from, int to) =>
      pages().versesReadOn([for (var p = from; p <= to; p++) p]);

  Future<Khatmah> month({
    String uuid = 'k',
    bool primary = true,
    bool autoRestart = false,
  }) => book.create(
    Khatmah(
      uuid: uuid,
      title: uuid,
      startDate: day1,
      targetDate: day1.add(29),
      dailyWeight: 604 / 30,
      isPrimary: primary,
      counting: primary ? CountingMode.auto : CountingMode.ask,
      autoRestart: autoRestart,
      createdAt: DateTime(2026, 9, 30),
    ),
  );

  Future<KhatmaStatus> status([Day? today]) async => (await statusOf(
    book,
    today ?? book.today,
    MushafEdition.madina1441,
    pages(),
  ))!;

  test('scenario 1 through the store: the status the screens show', () async {
    await month();
    var s = await status();
    expect(s.todayPortion!.range, (from: 1, to: 20));
    expect(s.todayPortion!.pages, 20);
    for (var d = 0; d < 3; d++) {
      now = day1.add(d).start.add(const Duration(hours: 20));
      await book.record(
        session: 'day$d',
        verses: pagesRead(d * 20 + 1, d * 20 + 20),
        at: now,
      );
      s = await status(day1.add(d));
      expect(s.todayPortion, isNull, reason: 'day ${d + 1} read');
    }
    expect(s.done, 60);
    expect(s.total, 604);
    expect(s.fraction, closeTo(60 / 604, 1e-9));
    expect(s.nextPage, 61);
    expect(s.behind, 0);
    final stats = await store.dailyStats('k');
    expect(stats.length, 3);
    for (final d in stats) {
      expect(d.weightRead, closeTo(20, 1e-9));
    }
    // The next day's portion follows on.
    expect((await status(day1.add(3))).todayPortion!.range.from, 61);
  });

  test('a session growing page by page: one attribution', () async {
    await month();
    await book.record(session: 's', verses: pagesRead(1, 1), at: now);
    await book.record(session: 's', verses: pagesRead(2, 2), at: now);
    final credits = await store.credits(khatmaUuid: 'k');
    expect(credits.single.ranges, pagesRead(1, 2));
    expect(credits.single.newWeight, closeTo(2, 1e-9));
    expect((await store.session('s'))!.ranges, pagesRead(1, 2));
  });

  test(
    'scenario 6: a session at 1:30 at night counts for the day before',
    () async {
      await month();
      now = DateTime(2026, 10, 3, 1, 30);
      await book.record(session: 'night', verses: pagesRead(1, 5), at: now);
      final c = (await store.credits(khatmaUuid: 'k')).single;
      expect(c.day, Day(2026, 10, 2));
      expect(book.today, Day(2026, 10, 2));
    },
  );

  test(
    'scenario 7: the second khatma asks; accepted, declined, undone',
    () async {
      await month(uuid: 'all');
      await book.create(
        Khatmah(
          uuid: 'amma',
          title: 'عم',
          kind: KhatmahKind.partial,
          rangeStart: index.idOf(78, 1),
          rangeEnd: 6236,
          startDate: day1,
          targetDate: day1.add(6),
          counting: CountingMode.ask,
          createdAt: DateTime(2026, 9, 30),
        ),
      );
      final naba = IntervalSet.range(index.idOf(78, 1), index.idOf(78, 40));
      await book.record(session: 'n', verses: naba, at: now);
      expect((await store.cachedCoverage('all'))!.ranges, naba.toJson());
      final waiting = await book.pending();
      expect(waiting.single.khatmaUuid, 'amma');
      await book.accept(waiting.single);
      expect(await book.pending(), isEmpty);
      expect((await store.cachedCoverage('amma'))!.ranges, naba.toJson());
      // «تراجع»: back as it was.
      await book.undo('n', 'amma');
      expect((await store.cachedCoverage('amma'))!.coveredWeight, 0);
      // A «no» is not asked again.
      await book.record(
        session: 'n2',
        verses: IntervalSet.range(index.idOf(79, 1), index.idOf(79, 10)),
        at: now,
      );
      final p = (await book.pending()).single;
      await book.decline(p);
      expect(await book.pending(), isEmpty);
      expect((await store.cachedCoverage('amma'))!.coveredWeight, 0);
    },
  );

  test('scenario 12: undo gives back the status as it was', () async {
    await month();
    await book.record(session: 'a', verses: pagesRead(1, 20), at: now);
    final before = await status();
    await book.record(session: 'b', verses: pagesRead(21, 40), at: now);
    await book.undo('b', 'k');
    final after = await status();
    expect(after.done, before.done);
    expect(after.fraction, before.fraction);
    expect(after.nextPage, before.nextPage);
    expect((await store.dailyStats('k')).single.weightRead, closeTo(20, 1e-9));
  });

  test('marked read by hand: a manual session for that khatma', () async {
    await month();
    await book.markRead((await store.byUuid('k'))!, pagesRead(1, 20));
    final sessions = await store.sessionsSince(DateTime(2026));
    expect(sessions.single.source, SessionSource.manual);
    expect(
      (await store.credits(khatmaUuid: 'k')).single.decidedBy,
      DecidedBy.manual,
    );
    expect((await status()).todayPortion, isNull);
  });

  test('scenario 16: completion; autoRestart takes over as primary', () async {
    await month(autoRestart: true);
    final change = await book.record(
      session: 'all',
      verses: IntervalSet.range(1, 6236),
      at: now,
    );
    expect(change.completed.single.uuid, 'k');
    final next = change.started.single;
    final done = (await store.byUuid('k'))!;
    expect(done.status, KhatmahStatus.completed);
    expect(done.completedAt, now);
    expect(done.isPrimary, isFalse);
    final fresh = (await store.byUuid(next.uuid))!;
    expect(fresh.isPrimary, isTrue);
    expect(fresh.status, KhatmahStatus.active);
    expect((await book.primary())!.uuid, next.uuid);
    expect((await status()).fraction, 0);
  });

  test(
    'without autoRestart, the primary passes to the next open khatma',
    () async {
      await month();
      await month(uuid: 'other', primary: false);
      await book.record(
        session: 'all',
        verses: IntervalSet.range(1, 6236),
        at: now,
      );
      final other = (await store.byUuid('other'))!;
      expect(other.isPrimary, isTrue);
      expect(other.counting, CountingMode.auto);
    },
  );

  test('scenario 10: paused 5 days; back, the end moved', () async {
    await month();
    now = DateTime(2026, 10, 4, 9);
    await book.pause('k');
    expect((await status()).wird, isNull);
    now = DateTime(2026, 10, 9, 9);
    await book.resume('k');
    final k = (await store.byUuid('k'))!;
    expect(k.status, KhatmahStatus.active);
    expect(k.targetDate, day1.add(34));
    expect(k.pauses.single.from, Day(2026, 10, 4));
    expect(k.pauses.single.to, Day(2026, 10, 8));
    // Reading days left are the same as before the pause.
    expect(book.planner.readingDays(k, Day(2026, 10, 9), k.targetDate!), 27);
  });

  test('deleting the primary passes it on', () async {
    await month();
    await month(uuid: 'b', primary: false);
    await book.cancel('k');
    expect((await book.primary())!.uuid, 'b');
    expect((await store.khatmahs()).map((k) => k.uuid), ['b']);
  });

  test('catching up through the status: «spread the rest» resets the '
      'pace', () async {
    await month();
    await book.record(session: 'a', verses: pagesRead(1, 5), at: now);
    var s = await status(day1.add(3));
    expect(s.behind, greaterThan(0));
    final k = (await store.byUuid('k'))!;
    await book.edit(
      book.recovery.spreadRest(k, await book.ledger(k), day1.add(3)),
    );
    s = await status(day1.add(3));
    expect(s.behind, 0);
    // The new pace ends on the planned day.
    expect(s.extendedTarget(), day1.add(29));
  });
}
