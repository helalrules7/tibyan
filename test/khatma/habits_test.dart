import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/user_database.dart';
import 'package:tibyan/features/khatma/data/activity_repository.dart';
import 'package:tibyan/features/khatma/data/khatma_repository.dart';
import 'package:tibyan/features/khatma/domain/day.dart';
import 'package:tibyan/features/khatma/domain/khatma_plan.dart';
import 'package:tibyan/features/khatma/domain/reading_stats.dart';
import 'package:tibyan/features/khatma/domain/reading_tracker.dart';
import 'package:tibyan/features/khatma/domain/reminder_plan.dart';

void main() {
  final today = Day(2026, 10, 10);

  group('streaks', () {
    test('count back from today, or from yesterday while today is open', () {
      final days = {today, today.add(-1), today.add(-2), today.add(-4)};
      expect(currentStreak(days, today), 3);
      expect(currentStreak(days.difference({today}), today), 2);
      expect(currentStreak({today.add(-3)}, today), 0);
      expect(currentStreak({}, today), 0);
    });

    test('a missed day is never a failure: the note invites back', () {
      expect(streakNote({}, today), StreakNote.none);
      expect(streakNote({today}, today), StreakNote.readToday);
      expect(streakNote({today.add(-1)}, today), StreakNote.continueToday);
      expect(streakNote({today.add(-5)}, today), StreakNote.welcomeBack);
    });
  });

  group('report', () {
    test('sums sessions per day and counts active days', () {
      final t = today.start.add(const Duration(hours: 9));
      final report = buildReport(
        today: today,
        count: 7,
        reading: [
          (t, t.add(const Duration(minutes: 10)), 5),
          (t, t.add(const Duration(minutes: 5)), 2),
          (t.subtract(const Duration(days: 2)), t, 0), // long, no pages
          (t.subtract(const Duration(days: 30)), t, 9), // out of range
        ],
        listening: [(t.subtract(const Duration(days: 1)), 30)],
      );
      expect(report.days.length, 7);
      expect(report.days.last.day, today);
      expect(report.days.last.pages, 7);
      expect(report.pages, 7);
      // 15 minutes today, plus a two-day session counted as at most a day.
      expect(report.readingMinutes, 15 + 24 * 60);
      // 30 seconds of listening is not an active day on its own.
      expect(report.activeDays, 2);
    });
  });

  group('reading tracker', () {
    late DateTime now;
    late List<PageRead> reads;
    late List<ReadingSpan> spans;
    late ReadingTracker tracker;

    setUp(() {
      now = DateTime(2026, 10, 10, 8);
      reads = [];
      spans = [];
      tracker = ReadingTracker(
        onPageRead: reads.add,
        onSessionEnd: spans.add,
        clock: () => now,
      );
    });

    void wait(int seconds) => now = now.add(Duration(seconds: seconds));

    test('a page counts after it stays on screen long enough', () {
      tracker.show(10, 'madina1441');
      wait(20);
      tracker.show(11, 'madina1441'); // 10 read
      wait(3);
      tracker.show(12, 'madina1441'); // 11 flipped past
      wait(40);
      tracker.end(); // 12 read
      expect(reads.map((r) => r.page), [10, 12]);
      expect(spans.single.pages, 2);
      expect(spans.single.end.difference(spans.single.start).inSeconds, 63);
    });

    test('a page read twice in a session counts once', () {
      tracker.show(10, 'madina1441');
      wait(20);
      tracker.show(11, 'madina1441');
      tracker.show(10, 'madina1441');
      wait(20);
      tracker.end();
      expect(reads.length, 1);
      expect(spans.single.pages, 1);
    });

    test('a cover between pages does not count as reading time', () {
      tracker.show(10, 'madina1441');
      wait(20);
      tracker.leavePage(); // 10 read
      wait(60);
      tracker.show(11, 'madina1441');
      wait(5);
      tracker.end();
      expect(reads.map((r) => r.page), [10]);
    });

    test('a brief look leaves no session', () {
      tracker.show(10, 'madina1441');
      wait(5);
      tracker.end();
      tracker.end();
      expect(spans, isEmpty);
    });

    test('changing the edition starts a new session', () {
      tracker.show(10, 'madina1441');
      wait(30);
      tracker.show(10, 'shamarly');
      wait(30);
      tracker.end();
      expect(spans.map((s) => s.edition), ['madina1441', 'shamarly']);
    });
  });

  group('reminders', () {
    final start = Day(2026, 10, 1);
    final plan = KhatmaPlan(
      unitStarts: pageUnitStarts(1, 604),
      lastPage: 604,
      from: start,
      target: start.add(29),
    );
    Set<int> pages(int to) => {for (var p = 1; p <= to; p++) p};

    test('one a day at the chosen time, with the day\'s portion', () {
      final r = planReminders(
        now: DateTime(2026, 10, 1, 7),
        minutes: 8 * 60 + 30,
        plan: plan,
        read: {},
      );
      expect(r.length, reminderDaysAhead);
      expect(r.first.at, DateTime(2026, 10, 1, 8, 30));
      expect(r.first.range, (from: 1, to: 21));
      expect(r[1].range, (from: 22, to: 41));
      expect(r.map((e) => e.id).toSet().length, r.length);
      expect(r.every((e) => e.id >= reminderIdBase), isTrue);
    });

    test('stays under the iOS limit of 64 pending notifications', () {
      expect(reminderDaysAhead, lessThan(64));
    });

    test("today is skipped once its time has passed or it is read", () {
      final late = planReminders(
        now: DateTime(2026, 10, 1, 21),
        minutes: 8 * 60,
        plan: plan,
        read: {},
      );
      expect(late.first.day, start.add(1));

      final done = planReminders(
        now: DateTime(2026, 10, 1, 7),
        minutes: 8 * 60,
        plan: plan,
        read: pages(21),
      );
      expect(done.first.day, start.add(1));
    });

    test('none after the end date or once complete', () {
      final r = planReminders(
        now: DateTime(2026, 10, 29, 7),
        minutes: 8 * 60,
        plan: plan,
        read: pages(560),
      );
      expect(r.map((e) => e.day), [start.add(28), start.add(29)]);
      expect(
        planReminders(
          now: DateTime(2026, 10, 1, 7),
          minutes: 480,
          plan: plan,
          read: pages(604),
        ),
        isEmpty,
      );
    });
  });

  test('upgrading a version 2 database adds the new tables', () async {
    final db = UserDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(
            'CREATE TABLE bookmark_sets (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'name TEXT NOT NULL, color INTEGER NOT NULL, surah INTEGER NOT NULL, '
            'ayah INTEGER NOT NULL, page INTEGER NOT NULL, '
            'sort_order INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL, '
            'kind TEXT)',
          );
          raw.execute(
            'CREATE TABLE reading_positions (id INTEGER NOT NULL DEFAULT 1, '
            'edition TEXT NOT NULL, view TEXT NOT NULL, surah INTEGER NOT NULL, '
            'ayah INTEGER NOT NULL, page INTEGER NOT NULL, '
            'updated_at INTEGER NOT NULL, PRIMARY KEY (id))',
          );
          raw.userVersion = 2;
        },
      ),
    );
    addTearDown(db.close);
    await ActivityRepository(db).addReflection(surah: 1, ayah: 1, text: 'n');
    expect(await db.select(db.khatmas).get(), isEmpty);
    expect(await db.select(db.outbox).get(), hasLength(1));
  });

  group('database', () {
    late UserDatabase db;
    setUp(() => db = UserDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('khatma log: runs extend today and skip pages already read', () async {
      final repo = KhatmaRepository(db);
      final k = await repo.create(
        title: 'K',
        edition: 'madina1441',
        unit: PortionUnit.page,
        start: today,
        target: today.add(29),
      );
      expect(k.uuid, hasLength(36));
      expect(await repo.recordRead(k, {1, 2}, today), {1, 2});
      expect(await repo.recordRead(k, {2, 3, 4}, today), {3, 4});
      await repo.recordRead(k, {10}, today);
      await repo.recordRead(k, {5}, today.add(1));
      final logs = await repo.logs(k.uuid);
      expect(
        [for (final l in logs) (l.date, l.fromPage, l.toPage)],
        [(today.key, 1, 4), (today.key, 10, 10), (today.add(1).key, 5, 5)],
      );
      expect(readPages(logs), {1, 2, 3, 4, 5, 10});
      expect(readPagesBefore(logs, today.add(1)), {1, 2, 3, 4, 10});
    });

    test('one active khatma; completed and deleted ones step aside', () async {
      final repo = KhatmaRepository(db);
      final a = await repo.create(
        title: 'A',
        edition: 'shamarly',
        unit: PortionUnit.juz,
        start: today,
        target: today.add(9),
        dailyPortion: 3,
        reminderTime: 480,
      );
      expect((await repo.active())!.uuid, a.uuid);
      await repo.complete(a.uuid);
      expect(await repo.active(), isNull);
      expect((await repo.watchCompleted().first).single.title, 'A');
      final b = await repo.create(
        title: 'B',
        edition: 'madina1441',
        unit: PortionUnit.page,
        start: today,
        target: today.add(9),
      );
      await repo.delete(b.uuid);
      expect(await repo.active(), isNull);
    });

    test('every change is queued once per row in the outbox', () async {
      final repo = KhatmaRepository(db);
      final k = await repo.create(
        title: 'K',
        edition: 'madina1441',
        unit: PortionUnit.page,
        start: today,
        target: today.add(29),
      );
      await repo.setReminder(k.uuid, 600);
      await repo.recordRead(k, {1}, today);
      final activity = ActivityRepository(db);
      final note = await activity.addReflection(surah: 2, ayah: 255, text: 'x');
      await activity.deleteReflection(note.uuid);
      final out = await db.select(db.outbox).get();
      expect(out.map((e) => (e.entity, e.op)).toList(), [
        ('khatma', 'upsert'),
        ('khatma_log', 'upsert'),
        ('reflection', 'delete'),
      ]);
      expect(out.first.payload, contains('"reminderTime":600'));
    });

    test('journal: search, edit and delete notes', () async {
      final repo = ActivityRepository(db);
      final a = await repo.addReflection(surah: 1, ayah: 5, text: 'first note');
      await repo.addReflection(surah: 2, ayah: 2, text: '100% sure_');
      expect((await repo.watchReflections().first).length, 2);
      expect(
        (await repo.watchReflections(query: 'first').first).single.uuid,
        a.uuid,
      );
      expect((await repo.watchReflections(query: '%').first).length, 1);
      await repo.editReflection(a.uuid, 'changed');
      expect(
        (await repo.watchReflectionsOn(1, 5).first).single.body,
        'changed',
      );
      await repo.deleteReflection(a.uuid);
      expect(await repo.watchReflectionsOn(1, 5).first, isEmpty);
    });

    test('sessions are kept for the reports', () async {
      final repo = ActivityRepository(db);
      final t = DateTime(2026, 10, 10, 9);
      await repo.addReadingSession(
        start: t,
        end: t.add(const Duration(minutes: 3)),
        pages: 2,
        edition: 'madina1441',
      );
      await repo.addListeningSession(start: t, seconds: 120, reciterId: 1);
      expect(
        (await repo
                .watchReadingSince(t.subtract(const Duration(days: 1)))
                .first)
            .single
            .pages,
        2,
      );
      expect(
        (await repo.watchListeningSince(DateTime(2026)).first).single.seconds,
        120,
      );
    });
  });
}
