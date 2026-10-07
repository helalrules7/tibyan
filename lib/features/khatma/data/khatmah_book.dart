import '../domain/day.dart';
import '../domain/interval_set.dart';
import '../domain/khatmah.dart';
import '../domain/khatmah_engine.dart';
import '../domain/planner.dart';
import '../domain/quran_index.dart';
import '../domain/reading_tracker.dart' show randomSessionId;
import '../domain/recovery.dart';
import 'khatmah_store.dart';

/// What happened to the khatmas after some reading was recorded.
class BookChange {
  const BookChange({this.completed = const [], this.started = const []});

  /// Khatmas completed by this reading, and khatmas started in their place
  /// (`autoRestart`).
  final List<Khatmah> completed;
  final List<Khatmah> started;
}

/// The khatmas at work: the engine, the planner and the store together.
/// Reading arrives as sessions; each session's verses are attributed to
/// the khatmas (at once for `auto`, after an answer for `ask`), the caches
/// are rebuilt, and a khatma whose last verse is read is completed (and
/// started again with `autoRestart`). No Flutter, no providers: the
/// service wraps it.
class KhatmahBook {
  KhatmahBook({
    required this.store,
    required this.index,
    this.dayStartHour = 3,
    DateTime Function()? clock,
    String Function()? newUuid,
  }) : engine = KhatmahEngine(index),
       planner = Planner(index),
       _now = clock ?? DateTime.now,
       _newUuid = newUuid ?? randomSessionId;

  final KhatmahStore store;
  final QuranIndex index;
  final KhatmahEngine engine;
  final Planner planner;
  final int dayStartHour;
  final DateTime Function() _now;
  final String Function() _newUuid;

  Recovery get recovery => Recovery(planner);

  /// The logical day of [t] (2.6).
  Day dayOf(DateTime t) => Day.logical(t, dayStartHour);
  Day get today => dayOf(_now());

  /// Run at start: the khatmas made before v5 are carried over (when
  /// their edition's pages are at hand), exactly one open khatma is
  /// primary, and the caches are rebuilt.
  Future<void> prepare(
    EditionPageMap? Function(String edition) pagesFor,
  ) async {
    await store.migrateLegacy(index, pagesFor);
    await _ensurePrimary();
    await store.rebuildAll(index);
  }

  Future<void> _ensurePrimary() async {
    for (final k in engine.ensurePrimary(await store.khatmahs())) {
      await store.save(k);
    }
  }

  Future<Khatmah?> primary() async {
    final open = await store.khatmahs(open: true);
    return open.where((k) => k.isPrimary).firstOrNull ?? open.firstOrNull;
  }

  Future<Ledger> ledger(Khatmah k) => store.ledger(k, index);

  // Reading.

  /// Adds [verses] to session [session] and counts them for the khatmas:
  /// `auto` ones now (a later read of the same session adds to its
  /// attribution); `ask` ones wait for an answer ([pending]).
  Future<BookChange> record({
    required String session,
    required IntervalSet verses,
    required DateTime at,
    SessionSource source = SessionSource.reader,
    EntryPoint entry = EntryPoint.other,
    String? edition,
    String mode = 'page',
  }) async {
    if (verses.isEmpty) return const BookChange();
    final had = await store.session(session);
    final start = had?.start ?? at;
    await store.putSession(
      SessionRecord(
        uuid: session,
        start: start,
        end: had == null || at.isAfter(had.end) ? at : had.end,
        ranges: (had?.ranges ?? IntervalSet.empty).union(verses),
        activeSeconds: had?.activeSeconds,
        pages: had?.pages ?? 0,
        source: had?.source ?? source,
        entryPoint: had?.entryPoint ?? entry,
        mode: had?.mode ?? mode,
        edition: had?.edition ?? edition,
      ),
    );
    final khatmahs = await store.khatmahs(open: true);
    final ledgers = {for (final k in khatmahs) k.uuid: await ledger(k)};
    final decisions = engine.attribute(
      verses,
      khatmahs,
      (k) => ledgers[k.uuid]!.covered,
    );
    final touched = <Khatmah>[];
    for (final d in decisions) {
      if (d.pending) continue;
      await _credit(session, d, start);
      touched.add(khatmahs.firstWhere((k) => k.uuid == d.khatmaUuid));
    }
    return _after(touched);
  }

  /// Writes (or adds to) the attribution of [session] to a khatma.
  Future<void> _credit(String session, Attribution d, DateTime start) async {
    final old = (await store.credits(khatmaUuid: d.khatmaUuid))
        .where((c) => c.sessionUuid == session)
        .firstOrNull;
    final counted = old != null && old.counts;
    await store.putCredit(
      Credit(
        sessionUuid: session,
        khatmaUuid: d.khatmaUuid,
        ranges: counted ? old.ranges.union(d.ranges) : d.ranges,
        newWeight: (counted ? old.newWeight : 0) + d.newWeight,
        decidedBy: d.decidedBy!,
        day: dayOf(start),
        at: start,
      ),
    );
  }

  /// A session ended: its times, active seconds and pages are written.
  Future<void> endSession(SessionRecord s) async {
    final had = await store.session(s.uuid);
    await store.putSession(
      SessionRecord(
        uuid: s.uuid,
        start: s.start,
        end: s.end,
        ranges: (had?.ranges ?? IntervalSet.empty).union(s.ranges),
        activeSeconds: s.activeSeconds,
        pages: s.pages,
        source: had?.source ?? s.source,
        entryPoint: had?.entryPoint ?? s.entryPoint,
        mode: s.mode,
        edition: s.edition ?? had?.edition,
      ),
    );
  }

  /// «تحديد كمقروء» for [k] (a page, a range, today's portion): a
  /// `manual` session counted for that khatma whatever its mode.
  Future<BookChange> markRead(Khatmah k, IntervalSet verses) async {
    final now = _now();
    final mark = engine.markRead(verses, k, (await ledger(k)).covered);
    if (mark == null) return const BookChange();
    final session = _newUuid();
    await store.putSession(
      SessionRecord(
        uuid: session,
        start: now,
        end: now,
        ranges: verses,
        activeSeconds: 0,
        source: SessionSource.manual,
      ),
    );
    await _credit(session, mark, now);
    return _after([k]);
  }

  /// Sessions waiting for «احتسب؟».
  Future<List<PendingCredit>> pending() async {
    final khatmahs = await store.khatmahs(open: true);
    final ask = [
      for (final k in khatmahs)
        if (k.isActive && k.counting == CountingMode.ask) k,
    ];
    if (ask.isEmpty) return const [];
    final since = ask
        .map((k) => k.createdAt ?? DateTime(2000))
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final ledgers = {for (final k in ask) k.uuid: await ledger(k)};
    return engine.pending(
      khatmahs: ask,
      sessions: [
        for (final s in await store.sessionsSince(since))
          (
            uuid: s.uuid,
            ranges: s.ranges,
            start: s.start,
            day: dayOf(s.start),
            manual: s.source == SessionSource.manual,
          ),
      ],
      credits: await store.credits(),
      coverage: (k) => ledgers[k.uuid]!.covered,
    );
  }

  /// «احتسب»: the pending reading counts for the khatma.
  Future<BookChange> accept(PendingCredit p) async {
    final k = await store.byUuid(p.khatmaUuid);
    if (k == null) return const BookChange();
    final fresh = p.ranges.subtract((await ledger(k)).covered);
    await store.putCredit(
      Credit(
        sessionUuid: p.sessionUuid,
        khatmaUuid: p.khatmaUuid,
        ranges: fresh,
        newWeight: fresh.weigh(index.weightOf),
        decidedBy: DecidedBy.userAccepted,
        day: p.day,
        at: p.at,
      ),
    );
    return _after([k]);
  }

  /// «لا»: not counted, and not asked again (it can still be counted from
  /// the khatma's details, [accept]).
  Future<void> decline(PendingCredit p) => store.putCredit(
    Credit(
      sessionUuid: p.sessionUuid,
      khatmaUuid: p.khatmaUuid,
      ranges: p.ranges,
      newWeight: 0,
      decidedBy: DecidedBy.declined,
      day: p.day,
      at: p.at,
    ),
  );

  /// «تراجع»: the attribution of [session] to [khatmaUuid] no longer
  /// counts; the caches are rebuilt.
  Future<void> undo(String session, String khatmaUuid) async {
    final c = (await store.credits(khatmaUuid: khatmaUuid))
        .where((c) => c.sessionUuid == session)
        .firstOrNull;
    final k = await store.byUuid(khatmaUuid);
    if (c == null || k == null) return;
    await store.putCredit(engine.undo(c));
    await store.rebuild(k, index);
  }

  /// Rebuilds the caches of [touched] and completes those read to the end.
  Future<BookChange> _after(List<Khatmah> touched) async {
    final completed = <Khatmah>[];
    final started = <Khatmah>[];
    for (final k in {for (final k in touched) k.uuid: k}.values) {
      final l = await store.rebuild(k, index);
      if (!l.complete || k.status != KhatmahStatus.active) continue;
      final c = engine.complete(
        k,
        now: _now(),
        today: today,
        newUuid: _newUuid,
      );
      await store.save(c.done);
      completed.add(c.done);
      if (c.next != null) {
        started.add(await store.insert(c.next!));
        await store.rebuild(c.next!, index);
      }
    }
    if (completed.isNotEmpty) await _ensurePrimary();
    return BookChange(completed: completed, started: started);
  }

  // The khatmas themselves.

  /// Adds [k]; as the primary one, the others step down.
  Future<Khatmah> create(Khatmah k) async {
    final made = await store.insert(k);
    if (k.isPrimary) {
      await setPrimary(made.uuid);
    } else {
      await _ensurePrimary();
    }
    await store.rebuild(made, index);
    return (await store.byUuid(made.uuid))!;
  }

  Future<void> setPrimary(String uuid) async {
    final all = await store.khatmahs();
    final updated = engine.setPrimary(all, uuid);
    for (var i = 0; i < all.length; i++) {
      final a = all[i], b = updated[i];
      if (a.isPrimary != b.isPrimary || a.counting != b.counting) {
        await store.save(b);
      }
    }
  }

  /// Deleted: cancelled, and the primary passes on.
  Future<void> cancel(String uuid) async {
    final k = await store.byUuid(uuid);
    if (k == null) return;
    await store.save(
      k.copyWith(status: KhatmahStatus.cancelled, isPrimary: false),
      deleted: true,
    );
    await _ensurePrimary();
  }

  Future<void> pause(String uuid) async {
    final k = await store.byUuid(uuid);
    if (k == null || k.status != KhatmahStatus.active) return;
    await store.save(engine.pause(k, today));
    await store.addPause(uuid, today);
  }

  Future<void> resume(String uuid) async {
    final k = await store.byUuid(uuid);
    if (k == null || k.status != KhatmahStatus.paused) return;
    final back = engine.resume(k, today);
    await store.save(back);
    final closed = back.pauses.where((p) => p.to != null).lastOrNull;
    if (closed != null && back.pauses.length == k.pauses.length) {
      await store.closePause(uuid, closed.to!);
    } else {
      // Paused and back the same day: the pause is dropped.
      await store.closePause(uuid, today.add(-1));
    }
  }

  /// A live edit (end date, unit, rest days, name, counting…): the plan
  /// changes at once; what was read stays.
  Future<void> edit(Khatmah k) => store.save(k);
}
