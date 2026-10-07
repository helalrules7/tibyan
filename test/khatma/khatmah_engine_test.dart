import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/khatma/data/quran_index_loader.dart';
import 'package:tibyan/features/khatma/domain/day.dart';
import 'package:tibyan/features/khatma/domain/interval_set.dart';
import 'package:tibyan/features/khatma/domain/khatmah.dart';
import 'package:tibyan/features/khatma/domain/khatmah_engine.dart';
import 'package:tibyan/features/khatma/domain/quran_index.dart';
import 'package:tibyan/features/mushaf/data/riwaya_data.dart';

import 'support.dart';

final day1 = Day(2026, 10, 1);

/// A khatma's record kept in memory: what the store keeps, for the engine.
class Book {
  Book(this.engine);

  final KhatmahEngine engine;
  final khatmahs = <String, Khatmah>{};
  final credits = <Credit>[];
  var _session = 0;

  QuranIndex get index => engine.index;

  Khatmah add(Khatmah k) => khatmahs[k.uuid] = k;

  Ledger ledger(String uuid) => Ledger(khatmahs[uuid]!, credits, index);

  IntervalSet coverage(Khatmah k) => ledger(k.uuid).covered;

  /// A session reads [verses] on [day]: each khatma gets what the engine
  /// decides; pending ones are returned.
  List<Attribution> read(IntervalSet verses, Day day) {
    final session = 's${++_session}';
    final at = day.start.add(Duration(hours: 8, minutes: _session));
    final decisions = engine.attribute(verses, khatmahs.values, coverage);
    for (final d in decisions) {
      if (d.pending) continue;
      credits.add(
        Credit(
          sessionUuid: session,
          khatmaUuid: d.khatmaUuid,
          ranges: d.ranges,
          newWeight: d.newWeight,
          decidedBy: d.decidedBy!,
          day: day,
          at: at,
        ),
      );
    }
    return decisions;
  }

  /// Reads pages [from] … [to] of the 1441 edition on [day].
  List<Attribution> readPages(int from, int to, Day day) {
    final p = index.madina1441;
    return read(p.versesReadOn([for (var i = from; i <= to; i++) i]), day);
  }
}

void main() {
  late QuranIndex index;
  late KhatmahEngine engine;
  late Book book;

  setUpAll(() async {
    index = await realIndex();
    engine = KhatmahEngine(index);
  });
  setUp(() => book = Book(engine));

  int pageOf(int id) => index.madina1441.pageOf(id);
  int firstOn(int page) => index.madina1441.ayahsOn(page)!.from;

  Khatmah whole({
    String uuid = 'k',
    int? startAt,
    bool primary = true,
    CountingMode counting = CountingMode.auto,
  }) => Khatmah(
    uuid: uuid,
    title: uuid,
    startAt: startAt,
    startDate: day1,
    targetDate: day1.add(29),
    dailyWeight: 604 / 30,
    isPrimary: primary,
    counting: counting,
  );

  test('scenario 1: 20 pages a day for 3 days', () {
    book.add(whole());
    for (var d = 0; d < 3; d++) {
      book.readPages(d * 20 + 1, d * 20 + 20, day1.add(d));
    }
    final l = book.ledger('k');
    expect(engine.progress(l), closeTo(60 / 604, 1e-9));
    expect(pageOf(engine.frontier(l)!), 61);
    for (var d = 0; d < 3; d++) {
      expect(l.weightOn(day1.add(d)), closeTo(20, 1e-9));
    }
  });

  test('scenario 2: al-Kahf read out of order counts; continue stays at '
      '280, then jumps past al-Kahf', () {
    book.add(whole());
    book.readPages(1, 279, day1);
    final before = engine.progress(book.ledger('k'));
    final kahf = IntervalSet.range(index.idOf(18, 1), index.idOf(18, 110));
    book.read(kahf, day1.add(1));
    var l = book.ledger('k');
    expect(engine.progress(l), greaterThan(before));
    expect(pageOf(engine.resolveContinue(l)), 280);
    // 280 up to the verse before al-Kahf.
    book.read(
      IntervalSet.range(firstOn(280), index.idOf(18, 1) - 1),
      day1.add(2),
    );
    l = book.ledger('k');
    expect(engine.frontier(l), index.idOf(19, 1));
    expect(pageOf(engine.frontier(l)!), 305);
  });

  test('scenario 3: a khatma from page 300 runs to 604, then 1 to 299, '
      'and completes after 299', () {
    final k = book.add(whole(startAt: firstOn(300)));
    final order = k.order;
    expect(order.idAt(0), firstOn(300));
    expect(order.idAt(order.length - 1), firstOn(300) - 1);
    expect(order.segments.first.to, 6236);
    book.readPages(300, 604, day1);
    var l = book.ledger('k');
    expect(engine.frontier(l), 1);
    book.readPages(1, 298, day1.add(1));
    l = book.ledger('k');
    expect(pageOf(engine.frontier(l)!), 299);
    expect(l.complete, isFalse);
    book.readPages(299, 299, day1.add(2));
    l = book.ledger('k');
    expect(l.complete, isTrue);
    expect(engine.frontier(l), isNull);
    expect(engine.resolveContinue(l), firstOn(300));
  });

  test('scenario 7: the whole Quran and Juz Amma; reading an-Naba counts '
      'for the primary at once and asks for the other', () {
    book.add(whole(uuid: 'all'));
    final amma = Khatmah(
      uuid: 'amma',
      title: 'جزء عم',
      kind: KhatmahKind.partial,
      rangeStart: index.idOf(78, 1),
      rangeEnd: 6236,
      startDate: day1,
      targetDate: day1.add(6),
      counting: KhatmahEngine.defaultCounting(primary: false),
    );
    book.add(amma);
    expect(amma.counting, CountingMode.ask);
    final naba = IntervalSet.range(index.idOf(78, 1), index.idOf(78, 40));
    final decisions = book.read(naba, day1);
    expect(decisions.map((d) => (d.khatmaUuid, d.pending)), [
      ('all', false),
      ('amma', true),
    ]);
    expect(book.ledger('all').covered, naba);
    expect(book.ledger('amma').covered.isEmpty, isTrue);
    // The answer «احتسب» counts it for Juz Amma too: the same reading for
    // two khatmas.
    final ask = decisions.last;
    book.credits.add(
      Credit(
        sessionUuid: 's1',
        khatmaUuid: 'amma',
        ranges: ask.ranges,
        newWeight: ask.newWeight,
        decidedBy: DecidedBy.userAccepted,
        day: day1,
        at: day1.start,
      ),
    );
    expect(book.ledger('amma').covered, naba);
  });

  test('pending answers: asked once per session; a no is an answer', () {
    final k = book.add(
      whole(
        uuid: 'second',
        primary: false,
        counting: CountingMode.ask,
      ).copyWith(createdAt: () => DateTime(2026)),
    );
    final sessions = [
      (
        uuid: 'a',
        ranges: IntervalSet.range(1, 7),
        start: DateTime(2026, 10, 1, 8),
        day: day1,
        manual: false,
      ),
      (
        uuid: 'b',
        ranges: IntervalSet.range(8, 20),
        start: DateTime(2026, 10, 1, 9),
        day: day1,
        manual: false,
      ),
      (
        uuid: 'c',
        ranges: IntervalSet.range(21, 30),
        start: DateTime(2026, 10, 1, 10),
        day: day1,
        manual: true,
      ),
    ];
    final declined = Credit(
      sessionUuid: 'a',
      khatmaUuid: 'second',
      ranges: IntervalSet.range(1, 7),
      newWeight: 1,
      decidedBy: DecidedBy.declined,
      day: day1,
      at: DateTime(2026, 10, 1, 8),
    );
    final p = engine.pending(
      khatmahs: [k],
      sessions: sessions,
      credits: [declined],
      coverage: book.coverage,
    );
    expect(p.map((e) => e.sessionUuid), ['b']);
    expect(p.single.ranges, IntervalSet.range(8, 20));
    // A declined attribution counts for nothing.
    book.credits.add(declined);
    expect(book.ledger('second').covered.isEmpty, isTrue);
  });

  test('a manual khatma counts only what is marked by hand', () {
    final k = book.add(whole(counting: CountingMode.manual));
    expect(book.readPages(1, 5, day1), isEmpty);
    final mark = engine.markRead(
      index.madina1441.versesReadOn([1, 2]),
      k,
      book.coverage(k),
    )!;
    expect(mark.decidedBy, DecidedBy.manual);
    expect(mark.newWeight, closeTo(2, 1e-9));
  });

  test('scenario 12: undoing an attribution gives every number back', () {
    book.add(whole());
    book.readPages(1, 20, day1);
    final before = book.ledger('k');
    book.readPages(15, 40, day1.add(1));
    final i = book.credits.length - 1;
    expect(book.ledger('k').coveredWeight, closeTo(40, 1e-9));
    book.credits[i] = engine.undo(book.credits[i]);
    final after = book.ledger('k');
    expect(after.covered, before.covered);
    expect(after.coveredWeight, before.coveredWeight);
    expect(after.frontier, before.frontier);
    expect(after.dailyWeight, before.dailyWeight);
    expect(engine.progress(after), engine.progress(before));
  });

  test('undoing an earlier attribution moves the verses to the later one '
      'that read them again', () {
    book.add(whole());
    book.readPages(1, 10, day1);
    book.read(IntervalSet.range(1, firstOn(21) - 1), day1.add(1));
    // The second session only had pages 11-20 new.
    expect(book.ledger('k').weightOn(day1.add(1)), closeTo(10, 1e-9));
    book.credits[0] = engine.undo(book.credits[0]);
    // Its ranges were only the new verses: pages 1-10 are unread again.
    expect(book.ledger('k').weightOn(day1.add(1)), closeTo(10, 1e-9));
    expect(pageOf(book.ledger('k').frontier!), 1);
  });

  group('scenario 16: completion', () {
    test('completed; the primary stays until another takes over', () {
      final k = whole();
      final c = engine.complete(
        k,
        now: DateTime(2026, 10, 30, 21),
        today: day1.add(29),
        newUuid: () => 'next',
      );
      expect(c.done.status, KhatmahStatus.completed);
      expect(c.done.completedAt, DateTime(2026, 10, 30, 21));
      expect(c.next, isNull);
      final other = whole(
        uuid: 'o',
        primary: false,
        counting: CountingMode.ask,
      );
      final changed = engine.ensurePrimary([c.done, other]);
      expect(changed.map((e) => (e.uuid, e.isPrimary, e.counting)), [
        ('k', false, CountingMode.auto),
        ('o', true, CountingMode.auto),
      ]);
    });

    test('autoRestart starts the same plan again from the range start', () {
      final k = Khatmah(
        uuid: 'wird',
        title: 'ورد',
        kind: KhatmahKind.dailyWird,
        pacing: PacingMode.openEnded,
        dailyWeight: 604 / 30,
        startDate: day1,
        startAt: 3000,
        autoRestart: true,
        isPrimary: true,
        presetId: 'daily_juz',
        aheadChoice: AheadChoice.lighter,
      );
      final c = engine.complete(
        k,
        now: DateTime(2026, 11, 1, 6),
        today: Day(2026, 11, 1),
        newUuid: () => 'wird2',
      );
      expect(c.done.isPrimary, isFalse);
      final n = c.next!;
      expect(n.uuid, 'wird2');
      expect(n.status, KhatmahStatus.active);
      expect(n.isPrimary, isTrue);
      expect(n.startAt, 1);
      expect(n.startDate, Day(2026, 11, 1));
      expect(n.targetDate, isNull);
      expect(n.presetId, 'daily_juz');
      expect(n.aheadChoice, isNull);
      expect(n.completedAt, isNull);
    });

    test('a dated plan started again keeps its length', () {
      final c = engine.complete(
        whole().copyWith(autoRestart: true),
        now: DateTime(2026, 10, 20),
        today: Day(2026, 10, 20),
        newUuid: () => 'n',
      );
      expect(c.next!.targetDate, Day(2026, 10, 20).add(29));
    });
  });

  test('scenario 10 (engine): a 5-day pause moves the end date by 5 days', () {
    final k = whole();
    final paused = engine.pause(k, day1.add(3));
    expect(paused.status, KhatmahStatus.paused);
    expect(paused.pausedOn(day1.add(3)), isTrue);
    // Paused khatmas get nothing.
    expect(
      engine.attribute(IntervalSet.range(1, 7), [
        paused,
      ], (_) => IntervalSet.empty),
      isEmpty,
    );
    final back = engine.resume(paused, day1.add(8));
    expect(back.status, KhatmahStatus.active);
    expect(back.pauses.single.to, day1.add(7));
    expect(back.pausedOn(day1.add(7)), isTrue);
    expect(back.pausedOn(day1.add(8)), isFalse);
    expect(back.targetDate, k.targetDate!.add(5));
    // Paused and back the same day: nothing to keep.
    final same = engine.resume(engine.pause(k, day1), day1);
    expect(same.pauses, isEmpty);
    expect(same.targetDate, k.targetDate);
  });

  test('one primary khatma; the new primary counts at once', () {
    final a = whole(uuid: 'a');
    final b = whole(uuid: 'b', primary: false, counting: CountingMode.ask);
    final all = engine.setPrimary([a, b], 'b');
    expect(all.map((k) => (k.uuid, k.isPrimary, k.counting)), [
      ('a', false, CountingMode.ask),
      ('b', true, CountingMode.auto),
    ]);
    expect(engine.ensurePrimary(all), isEmpty);
    final two = [a, whole(uuid: 'c')];
    expect(engine.ensurePrimary(two).single.uuid, 'c');
  });

  test('live edits keep the coverage', () {
    book.add(whole());
    book.readPages(1, 30, day1);
    final before = book.ledger('k').covered;
    book.add(
      book.khatmahs['k']!.copyWith(
        targetDate: () => day1.add(59),
        unit: WirdUnit.juz,
        restWeekdays: {5},
      ),
    );
    expect(book.ledger('k').covered, before);
  });

  test('scenario 18: a khatma read in the Warsh edition counts', () {
    final data = RiwayaData.parse(
      File('test/fixtures/riwaya_warsh_sample.json').readAsStringSync(),
    );
    final warsh = riwayaPages('warsh', data, index);
    book.add(whole());
    // Warsh page 1 (al-Fatiha) read in the page view.
    book.read(warsh.versesReadOn([1]), day1);
    expect(book.ledger('k').covered, IntervalSet.range(1, 7));
    // Warsh 1:1 heard to its end: Hafs 1:1 (the basmala) and 1:2.
    expect(riwayaVerseInHafs(data, index, 1, 1), IntervalSet.range(1, 2));
    expect(riwayaVerseInHafs(data, index, 2, 1), IntervalSet.range(8, 9));
    // Read as pages of the 1441 edition, the same verses are page 1.
    expect(index.madina1441.readPages(book.ledger('k').covered), {1});
  });

  test('scenario 22: a Shamarly khatma weighs 604; shown in its own '
      'pages', () {
    book.add(whole());
    final s = index.shamarly;
    book.read(s.versesReadOn([for (var p = 2; p <= 522; p++) p]), day1);
    final l = book.ledger('k');
    expect(l.coveredWeight, closeTo(604, 1e-9));
    expect(l.complete, isTrue);
    book.credits.clear();
    book.read(s.versesReadOn([for (var p = 2; p <= 41; p++) p]), day1);
    expect(s.readPages(book.ledger('k').covered), {
      for (var p = 2; p <= 41; p++) p,
    });
    // The first unread verse is the one ending on page 42 (it may start
    // at the foot of page 41).
    expect(s.lastPageOf(book.ledger('k').frontier!), 42);
  });
}
