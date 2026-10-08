import 'package:drift/drift.dart';

import '../../../core/db/user_database.dart';
import '../../../core/sync/outbox_writer.dart';
import '../domain/day.dart';
import '../domain/interval_set.dart';
import '../domain/khatmah.dart';
import '../domain/quran_index.dart';

/// A reading session as stored (`reading_session`).
class SessionRecord {
  const SessionRecord({
    required this.uuid,
    required this.start,
    required this.end,
    required this.ranges,
    this.activeSeconds,
    this.pages = 0,
    this.source = SessionSource.reader,
    this.entryPoint = EntryPoint.other,
    this.mode = 'page',
    this.edition,
  });

  final String uuid;
  final DateTime start;
  final DateTime end;
  final IntervalSet ranges;
  final int? activeSeconds;

  /// Pages that counted as read (for the reading reports).
  final int pages;
  final SessionSource source;
  final EntryPoint entryPoint;

  /// `page`, `scroll`, `verse` or `continuous`.
  final String mode;
  final String? edition;

  /// Seconds counted for statistics: the active time when known.
  int get seconds =>
      activeSeconds ?? end.difference(start).inSeconds.clamp(0, 86400);

  static SessionRecord of(ReadingSessionRow r) => SessionRecord(
    uuid: r.uuid,
    start: r.startedAt,
    end: r.endedAt,
    ranges: IntervalSet.fromJson(r.ranges),
    activeSeconds: r.activeSeconds,
    pages: r.pages,
    source: enumNamed(SessionSource.values, r.source) ?? SessionSource.reader,
    entryPoint: enumNamed(EntryPoint.values, r.entryPoint) ?? EntryPoint.other,
    mode: r.mode,
    edition: r.edition,
  );
}

/// The khatmas (v1.1) and their record: sessions and the attributions of
/// sessions to khatmas are the truth; khatma_coverage and daily_stat are a
/// cache rebuilt from them ([rebuildAll]). Every synced write also goes to
/// the outbox.
class KhatmahStore {
  KhatmahStore(this._db);

  final UserDatabase _db;

  /// Fires after any change to the khatmas or their record.
  Stream<void> changes() => _db
      .tableUpdates(
        TableUpdateQuery.onAllTables([
          _db.khatmas,
          _db.khatmaPauses,
          _db.sessionAttributions,
          _db.khatmaCoverages,
        ]),
      )
      .map((_) {});

  // Khatmas.

  static Khatmah toKhatmah(KhatmaRow r, Iterable<KhatmaPauseRow> pauses) {
    final status =
        enumNamed(KhatmahStatus.values, r.status) ??
        (r.deletedAt != null
            ? KhatmahStatus.cancelled
            : r.completedAt != null
            ? KhatmahStatus.completed
            : KhatmahStatus.active);
    final start = Day.parse(r.startDate);
    final pacing =
        enumNamed(PacingMode.values, r.pacingMode) ?? PacingMode.endDate;
    return Khatmah(
      uuid: r.uuid,
      title: r.title,
      kind: enumNamed(KhatmahKind.values, r.kind) ?? KhatmahKind.fullQuran,
      rangeStart: r.rangeStart ?? 1,
      rangeEnd: r.rangeEnd ?? 6236,
      startAt: r.startAt,
      pacing: pacing,
      schedule:
          enumNamed(ScheduleMode.values, r.scheduleMode) ??
          ScheduleMode.adaptive,
      dailyWeight: r.dailyWeight,
      startDate: start,
      targetDate: pacing == PacingMode.openEnded
          ? null
          : Day.parse(r.targetDate),
      planFrom: r.rebasedOn == null ? null : Day.parse(r.rebasedOn!),
      unit: enumNamed(WirdUnit.values, r.unit) ?? WirdUnit.page,
      restWeekdays: parseWeekdays(r.restWeekdays),
      counting:
          enumNamed(CountingMode.values, r.countingMode) ?? CountingMode.auto,
      isPrimary: r.isPrimary,
      status: status,
      autoRestart: r.autoRestart,
      presetId: r.presetId,
      aheadChoice: enumNamed(AheadChoice.values, r.aheadChoice),
      recovery: RecoveryChoice.fromJson(r.recovery),
      edition: r.edition,
      reminderTime: r.reminderTime,
      pauses: [
        for (final p in pauses)
          if (p.deletedAt == null && p.khatmaUuid == r.uuid)
            PausePeriod(
              Day.parse(p.fromDay),
              p.toDay == null ? null : Day.parse(p.toDay!),
            ),
      ],
      createdAt: r.createdAt,
      completedAt: r.completedAt,
    );
  }

  KhatmasCompanion _columns(Khatmah k) => KhatmasCompanion(
    title: Value(k.title),
    edition: Value(k.edition),
    unit: Value(k.unit.name),
    startDate: Value(k.startDate.key),
    // The old column is required: an open-ended khatma keeps its start.
    targetDate: Value((k.targetDate ?? k.startDate).key),
    dailyPortion: const Value.absent(),
    reminderTime: Value(k.reminderTime),
    rebasedOn: Value(k.planFrom?.key),
    completedAt: Value(k.completedAt),
    kind: Value(k.kind.name),
    rangeStart: Value(k.rangeStart),
    rangeEnd: Value(k.rangeEnd),
    startAt: Value(k.startAt),
    pacingMode: Value(k.pacing.name),
    scheduleMode: Value(k.schedule.name),
    dailyWeight: Value(k.dailyWeight),
    restWeekdays: Value(weekdaysText(k.restWeekdays)),
    countingMode: Value(k.counting.name),
    isPrimary: Value(k.isPrimary),
    status: Value(k.status.name),
    autoRestart: Value(k.autoRestart),
    presetId: Value(k.presetId),
    aheadChoice: Value(k.aheadChoice?.name),
    recovery: Value(k.recovery?.toJson()),
  );

  Future<void> _queueKhatma(KhatmaRow row) => enqueueChange(
    _db,
    table: 'khatma',
    uuid: row.uuid,
    row: row.toJson(),
    deleted: row.deletedAt != null,
  );

  /// Khatmas not deleted, oldest first; with [open] only active and paused
  /// ones.
  Future<List<Khatmah>> khatmahs({bool open = false}) async {
    final rows =
        await (_db.select(_db.khatmas)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([
                (t) => OrderingTerm.asc(t.createdAt),
                (t) => OrderingTerm.asc(t.id),
              ]))
            .get();
    final pauses = await _db.select(_db.khatmaPauses).get();
    final out = [for (final r in rows) toKhatmah(r, pauses)];
    return open
        ? [
            for (final k in out)
              if (k.isOpen) k,
          ]
        : out;
  }

  Future<KhatmaRow?> row(String uuid) => (_db.select(
    _db.khatmas,
  )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();

  Future<Khatmah?> byUuid(String uuid) async {
    final r = await (_db.select(
      _db.khatmas,
    )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
    if (r == null) return null;
    final pauses = await (_db.select(
      _db.khatmaPauses,
    )..where((t) => t.khatmaUuid.equals(uuid))).get();
    return toKhatmah(r, pauses);
  }

  /// Adds [k] (its uuid is kept).
  Future<Khatmah> insert(Khatmah k) => _db.transaction(() async {
    final row = await _db
        .into(_db.khatmas)
        .insertReturning(
          _columns(k).copyWith(
            uuid: Value(k.uuid),
            createdAt: Value(k.createdAt ?? DateTime.now()),
          ),
        );
    await _queueKhatma(row);
    return toKhatmah(row, const []);
  });

  /// Writes [k]'s plan over its row (pauses are written on their own).
  Future<void> save(Khatmah k, {bool deleted = false}) => _db.transaction(
    () async {
      final rows =
          await (_db.update(
            _db.khatmas,
          )..where((t) => t.uuid.equals(k.uuid))).writeReturning(
            _columns(k).copyWith(
              updatedAt: Value(DateTime.now()),
              deletedAt: deleted ? Value(DateTime.now()) : const Value.absent(),
            ),
          );
      for (final r in rows) {
        await _queueKhatma(r);
      }
    },
  );

  Future<void> addPause(String khatmaUuid, Day from) =>
      _db.transaction(() async {
        final row = await _db
            .into(_db.khatmaPauses)
            .insertReturning(
              KhatmaPausesCompanion.insert(
                khatmaUuid: khatmaUuid,
                fromDay: from.key,
              ),
            );
        await enqueueChange(
          _db,
          table: 'khatma_pause',
          uuid: row.uuid,
          row: row.toJson(),
        );
      });

  /// Ends the open pause of [khatmaUuid] on [to] (its last paused day).
  Future<void> closePause(String khatmaUuid, Day to) =>
      _db.transaction(() async {
        final rows =
            await (_db.update(_db.khatmaPauses)..where(
                  (t) => t.khatmaUuid.equals(khatmaUuid) & t.toDay.isNull(),
                ))
                .writeReturning(
                  KhatmaPausesCompanion(
                    toDay: Value(to.key),
                    updatedAt: Value(DateTime.now()),
                  ),
                );
        for (final r in rows) {
          await enqueueChange(
            _db,
            table: 'khatma_pause',
            uuid: r.uuid,
            row: r.toJson(),
          );
        }
      });

  // Sessions.

  /// Writes a session, adding it or replacing the row with its uuid.
  Future<void> putSession(SessionRecord s) => _db.transaction(() async {
    final values = ReadingSessionsCompanion(
      startedAt: Value(s.start),
      endedAt: Value(s.end),
      pages: Value(s.pages),
      mode: Value(s.mode),
      edition: Value(s.edition),
      source: Value(s.source.name),
      entryPoint: Value(s.entryPoint.name),
      activeSeconds: Value(s.activeSeconds),
      ranges: Value(s.ranges.toJson()),
      updatedAt: Value(DateTime.now()),
    );
    final had = await (_db.select(
      _db.readingSessions,
    )..where((t) => t.uuid.equals(s.uuid))).getSingleOrNull();
    final ReadingSessionRow row;
    if (had == null) {
      row = await _db
          .into(_db.readingSessions)
          .insertReturning(values.copyWith(uuid: Value(s.uuid)));
    } else {
      row = (await (_db.update(
        _db.readingSessions,
      )..where((t) => t.uuid.equals(s.uuid))).writeReturning(values)).single;
    }
    await enqueueChange(
      _db,
      table: 'reading_session',
      uuid: row.uuid,
      row: row.toJson(),
    );
  });

  Future<SessionRecord?> session(String uuid) async {
    final r = await (_db.select(
      _db.readingSessions,
    )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
    return r == null ? null : SessionRecord.of(r);
  }

  /// Sessions started at or after [since] (not deleted), oldest first.
  Future<List<SessionRecord>> sessionsSince(DateTime since) async {
    final rows =
        await (_db.select(_db.readingSessions)
              ..where(
                (t) =>
                    t.startedAt.isBiggerOrEqualValue(since) &
                    t.deletedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
            .get();
    return [for (final r in rows) SessionRecord.of(r)];
  }

  Future<Map<String, int>> _sessionSeconds() async {
    final rows = await _db.select(_db.readingSessions).get();
    return {for (final r in rows) r.uuid: SessionRecord.of(r).seconds};
  }

  // Attributions.

  static Credit _credit(SessionAttributionRow r) => Credit(
    sessionUuid: r.sessionUuid,
    khatmaUuid: r.khatmaUuid,
    ranges: IntervalSet.fromJson(r.ranges),
    newWeight: r.newWeight,
    decidedBy: enumNamed(DecidedBy.values, r.decidedBy) ?? DecidedBy.auto,
    undone: r.undone,
    day: Day.parse(r.day),
    at: r.at,
  );

  /// Attributions (not deleted), of one khatma or of all.
  Future<List<Credit>> credits({String? khatmaUuid}) async {
    final q = _db.select(_db.sessionAttributions)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.at), (t) => OrderingTerm.asc(t.id)]);
    if (khatmaUuid != null) q.where((t) => t.khatmaUuid.equals(khatmaUuid));
    return [for (final r in await q.get()) _credit(r)];
  }

  /// Writes the attribution of a session to a khatma, one per pair.
  Future<void> putCredit(Credit c) => _db.transaction(() async {
    final values = SessionAttributionsCompanion(
      sessionUuid: Value(c.sessionUuid),
      khatmaUuid: Value(c.khatmaUuid),
      ranges: Value(c.ranges.toJson()),
      newWeight: Value(c.newWeight),
      decidedBy: Value(c.decidedBy.name),
      undone: Value(c.undone),
      day: Value(c.day.key),
      at: Value(c.at),
      updatedAt: Value(DateTime.now()),
    );
    final where =
        _db.sessionAttributions.sessionUuid.equals(c.sessionUuid) &
        _db.sessionAttributions.khatmaUuid.equals(c.khatmaUuid);
    final had = await (_db.select(
      _db.sessionAttributions,
    )..where((_) => where)).getSingleOrNull();
    final SessionAttributionRow row;
    if (had == null) {
      row = await _db.into(_db.sessionAttributions).insertReturning(values);
    } else {
      row = (await (_db.update(
        _db.sessionAttributions,
      )..where((_) => where)).writeReturning(values)).single;
    }
    await enqueueChange(
      _db,
      table: 'session_attribution',
      uuid: row.uuid,
      row: row.toJson(),
    );
  });

  // The cache.

  /// Writes [ledger] as the cache of its khatma, replacing what was there.
  Future<void> writeCache(Ledger ledger) => _db.transaction(() async {
    final uuid = ledger.khatmah.uuid;
    await _db
        .into(_db.khatmaCoverages)
        .insertOnConflictUpdate(
          KhatmaCoveragesCompanion.insert(
            khatmaUuid: uuid,
            ranges: ledger.covered.toJson(),
            coveredWeight: ledger.coveredWeight,
            frontier: Value(ledger.frontier),
            updatedAt: Value(DateTime.now()),
          ),
        );
    await (_db.delete(
      _db.dailyStats,
    )..where((t) => t.khatmaUuid.equals(uuid))).go();
    for (final MapEntry(key: day, value: w) in ledger.dailyWeight.entries) {
      await _db
          .into(_db.dailyStats)
          .insert(
            DailyStatsCompanion.insert(
              khatmaUuid: uuid,
              day: day.key,
              weightRead: w,
              sessions: ledger.dailySessions[day] ?? 0,
              seconds: ledger.dailySeconds[day] ?? 0,
            ),
          );
    }
  });

  /// The ledger of [k] from its attributions.
  Future<Ledger> ledger(Khatmah k, QuranIndex index) async => Ledger(
    k,
    await credits(khatmaUuid: k.uuid),
    index,
    sessionSeconds: await _sessionSeconds(),
  );

  /// Rebuilds [k]'s cache and returns its ledger.
  Future<Ledger> rebuild(Khatmah k, QuranIndex index) async {
    final l = await ledger(k, index);
    await writeCache(l);
    return l;
  }

  /// Drops the whole cache and builds it again from the attributions.
  Future<void> rebuildAll(QuranIndex index) => _db.transaction(() async {
    await _db.delete(_db.khatmaCoverages).go();
    await _db.delete(_db.dailyStats).go();
    final all = await credits();
    final seconds = await _sessionSeconds();
    for (final k in await khatmahs()) {
      await writeCache(Ledger(k, all, index, sessionSeconds: seconds));
    }
  });

  Future<KhatmaCoverageRow?> cachedCoverage(String khatmaUuid) => (_db.select(
    _db.khatmaCoverages,
  )..where((t) => t.khatmaUuid.equals(khatmaUuid))).getSingleOrNull();

  Future<List<DailyStatRow>> dailyStats(String khatmaUuid) =>
      (_db.select(_db.dailyStats)
            ..where((t) => t.khatmaUuid.equals(khatmaUuid))
            ..orderBy([(t) => OrderingTerm.asc(t.day)]))
          .get();

  // From v4.

  /// Carries khatmas made before v5 (their rows have no verse range yet)
  /// over to the new record: the pages of each day of the old log, in the
  /// khatma's edition ([pagesFor]), become that day's verses (a verse
  /// counts once the page it ends on is read), as one `manual` session a
  /// day with an `auto` attribution. The old log is left as it was.
  ///
  /// A khatma whose edition's pages are not at hand (a riwaya pack not on
  /// the device) waits for the next run. Returns how many were carried.
  Future<int> migrateLegacy(
    QuranIndex index,
    EditionPageMap? Function(String edition) pagesFor,
  ) async {
    final rows = await (_db.select(
      _db.khatmas,
    )..where((t) => t.rangeStart.isNull())).get();
    var done = 0;
    for (final row in rows) {
      final pages = pagesFor(row.edition);
      if (pages == null) continue;
      await _db.transaction(() => _migrateOne(row, pages, index));
      done++;
    }
    return done;
  }

  Future<void> _migrateOne(
    KhatmaRow row,
    EditionPageMap pages,
    QuranIndex index,
  ) async {
    final logs =
        await (_db.select(_db.khatmaLogs)
              ..where(
                (t) => t.khatmaUuid.equals(row.uuid) & t.deletedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    // The day each page was first logged, and the pages of each day.
    final dayOfPage = <int, Day>{};
    final pagesOfDay = <Day, int>{};
    for (final l in logs) {
      final day = Day.parse(l.date);
      for (var p = l.fromPage; p <= l.toPage; p++) {
        final had = dayOfPage[p];
        if (had == null || day.isBefore(had)) dayOfPage[p] = day;
      }
    }
    for (final d in dayOfPage.values) {
      pagesOfDay[d] = (pagesOfDay[d] ?? 0) + 1;
    }
    // Each verse on the day the page it ends on was read.
    final versesOfDay = <Day, List<int>>{};
    for (var id = 1; id <= index.ayahCount; id++) {
      final d = dayOfPage[pages.lastPageOf(id)];
      if (d != null) (versesOfDay[d] ??= []).add(id);
    }
    final days = versesOfDay.keys.toList()..sort();
    var coveredBeforePlan = 0.0;
    final planFrom = row.rebasedOn == null ? null : Day.parse(row.rebasedOn!);
    for (final day in days) {
      final ranges = IntervalSet.of(versesOfDay[day]!);
      final weight = ranges.weigh(index.weightOf);
      if (planFrom != null && day.isBefore(planFrom)) {
        coveredBeforePlan += weight;
      }
      final at = day.start.add(const Duration(hours: 12));
      final session = newUuid();
      await putSession(
        SessionRecord(
          uuid: session,
          start: at,
          end: at,
          ranges: ranges,
          activeSeconds: 0,
          pages: pagesOfDay[day] ?? 0,
          source: SessionSource.manual,
          edition: row.edition,
        ),
      );
      await putCredit(
        Credit(
          sessionUuid: session,
          khatmaUuid: row.uuid,
          ranges: ranges,
          newWeight: weight,
          decidedBy: DecidedBy.auto,
          day: day,
          at: at,
        ),
      );
    }
    // The plan's pace in Madina pages.
    final start = Day.parse(row.startDate);
    final target = Day.parse(row.targetDate);
    final double daily;
    if (row.dailyPortion case final portion?) {
      final perUnit = switch (row.unit) {
        'juz' => 604 / 30,
        'hizb' => 604 / 60,
        _ => 604 / pages.textPages.length,
      };
      daily = portion * perUnit;
    } else {
      final from = planFrom ?? start;
      final span = target.difference(from) + 1;
      daily = (604 - coveredBeforePlan) / (span < 1 ? 1 : span);
    }
    final updated =
        await (_db.update(
          _db.khatmas,
        )..where((t) => t.uuid.equals(row.uuid))).writeReturning(
          KhatmasCompanion(
            kind: const Value('fullQuran'),
            rangeStart: const Value(1),
            rangeEnd: Value(index.ayahCount),
            startAt: const Value(1),
            scheduleMode: const Value('adaptive'),
            dailyWeight: Value(daily),
            countingMode: const Value('auto'),
            updatedAt: Value(DateTime.now()),
          ),
        );
    for (final r in updated) {
      await _queueKhatma(r);
    }
    final k = toKhatmah(updated.single, const []);
    await writeCache(await ledger(k, index));
  }
}
