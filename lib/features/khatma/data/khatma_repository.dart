import 'package:drift/drift.dart';

import '../../../core/db/user_database.dart';
import '../../../core/sync/outbox_writer.dart';
import '../domain/day.dart';
import '../domain/khatma_plan.dart';

/// Khatma plans and the pages read in them. Every write also goes to the
/// sync outbox.
class KhatmaRepository {
  KhatmaRepository(this._db);

  final UserDatabase _db;

  Future<KhatmaRow> _put(KhatmaRow row) async {
    await enqueueChange(
      _db,
      table: 'khatma',
      uuid: row.uuid,
      row: row.toJson(),
      deleted: row.deletedAt != null,
    );
    return row;
  }

  /// The khatma being read: the newest one not finished or deleted.
  Stream<KhatmaRow?> watchActive() =>
      (_db.select(_db.khatmas)
            ..where((t) => t.deletedAt.isNull() & t.completedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .watchSingleOrNull();

  Future<KhatmaRow?> active() => watchActive().first;

  /// Finished khatmas, newest first.
  Stream<List<KhatmaRow>> watchCompleted() =>
      (_db.select(_db.khatmas)
            ..where((t) => t.deletedAt.isNull() & t.completedAt.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
          .watch();

  /// Starts a khatma. One is read at a time: a khatma still open is set
  /// aside (deleted) by the screen before, after asking.
  Future<KhatmaRow> create({
    required String title,
    required String edition,
    required PortionUnit unit,
    required Day start,
    required Day target,
    double? dailyPortion,
    int? reminderTime,
  }) => _db.transaction(() async {
    final row = await _db
        .into(_db.khatmas)
        .insertReturning(
          KhatmasCompanion.insert(
            title: title,
            edition: edition,
            unit: Value(unit.name),
            startDate: start.key,
            targetDate: target.key,
            dailyPortion: Value(dailyPortion),
            reminderTime: Value(reminderTime),
          ),
        );
    return _put(row);
  });

  Future<KhatmaRow> _update(String uuid, KhatmasCompanion change) =>
      _db.transaction(() async {
        final rows =
            await (_db.update(
              _db.khatmas,
            )..where((t) => t.uuid.equals(uuid))).writeReturning(
              change.copyWith(updatedAt: Value(DateTime.now())),
            );
        return _put(rows.single);
      });

  Future<KhatmaRow> setReminder(String uuid, int? minutes) =>
      _update(uuid, KhatmasCompanion(reminderTime: Value(minutes)));

  /// Catch-up: the rest is spread over the days left, from [today].
  Future<KhatmaRow> spreadRest(String uuid, Day today) =>
      _update(uuid, KhatmasCompanion(rebasedOn: Value(today.key)));

  /// Catch-up: the daily amount stays, and the end date moves.
  Future<KhatmaRow> moveTarget(String uuid, Day today, Day target) => _update(
    uuid,
    KhatmasCompanion(
      rebasedOn: Value(today.key),
      targetDate: Value(target.key),
    ),
  );

  Future<KhatmaRow> delete(String uuid) =>
      _update(uuid, KhatmasCompanion(deletedAt: Value(DateTime.now())));

  Future<KhatmaRow> complete(String uuid) =>
      _update(uuid, KhatmasCompanion(completedAt: Value(DateTime.now())));

  Stream<List<KhatmaLogRow>> watchLogs(String khatmaUuid) =>
      (_db.select(_db.khatmaLogs)
            ..where(
              (t) => t.khatmaUuid.equals(khatmaUuid) & t.deletedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .watch();

  Future<List<KhatmaLogRow>> logs(String khatmaUuid) =>
      watchLogs(khatmaUuid).first;

  /// Records [pages] (in the khatma's edition) as read on [day]. Pages
  /// already read are skipped; a run that continues one logged today
  /// extends it. Returns the pages newly read.
  Future<Set<int>> recordRead(KhatmaRow khatma, Set<int> pages, Day day) =>
      _db.transaction(() async {
        final existing = await logs(khatma.uuid);
        final read = readPages(existing);
        final fresh = pages.difference(read);
        if (fresh.isEmpty) return fresh;
        final todays = [
          for (final l in existing)
            if (l.date == day.key) l,
        ];
        for (final run in pageRuns(fresh)) {
          final before = todays
              .where((l) => l.toPage == run.from - 1)
              .firstOrNull;
          KhatmaLogRow row;
          if (before != null) {
            row =
                (await (_db.update(
                      _db.khatmaLogs,
                    )..where((t) => t.id.equals(before.id))).writeReturning(
                      KhatmaLogsCompanion(
                        toPage: Value(run.to),
                        updatedAt: Value(DateTime.now()),
                      ),
                    ))
                    .single;
            todays.remove(before);
          } else {
            row = await _db
                .into(_db.khatmaLogs)
                .insertReturning(
                  KhatmaLogsCompanion.insert(
                    khatmaUuid: khatma.uuid,
                    date: day.key,
                    fromPage: run.from,
                    toPage: run.to,
                  ),
                );
          }
          todays.add(row);
          await enqueueChange(
            _db,
            table: 'khatma_log',
            uuid: row.uuid,
            row: row.toJson(),
          );
        }
        return fresh;
      });
}

/// Every page covered by [logs].
Set<int> readPages(Iterable<KhatmaLogRow> logs) => {
  for (final l in logs)
    for (var p = l.fromPage; p <= l.toPage; p++) p,
};

/// Pages read before [day].
Set<int> readPagesBefore(Iterable<KhatmaLogRow> logs, Day day) =>
    readPages(logs.where((l) => Day.parse(l.date).isBefore(day)));
