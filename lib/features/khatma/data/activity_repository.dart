import 'package:drift/drift.dart';

import '../../../core/db/user_database.dart';
import '../../../core/sync/outbox_writer.dart';

/// Reading and listening sessions, recorded automatically, and the
/// reader's notes on verses (tadabbur journal).
class ActivityRepository {
  ActivityRepository(this._db);

  final UserDatabase _db;

  Future<void> addReadingSession({
    required DateTime start,
    required DateTime end,
    required int pages,
    required String edition,
  }) => _db.transaction(() async {
    final row = await _db
        .into(_db.readingSessions)
        .insertReturning(
          ReadingSessionsCompanion.insert(
            startedAt: start,
            endedAt: end,
            pages: pages,
            edition: Value(edition),
          ),
        );
    await enqueueChange(
      _db,
      table: 'reading_session',
      uuid: row.uuid,
      row: row.toJson(),
    );
  });

  Future<void> addListeningSession({
    required DateTime start,
    required int seconds,
    required int reciterId,
  }) => _db.transaction(() async {
    final row = await _db
        .into(_db.listeningSessions)
        .insertReturning(
          ListeningSessionsCompanion.insert(
            startedAt: start,
            seconds: seconds,
            reciterId: reciterId,
          ),
        );
    await enqueueChange(
      _db,
      table: 'listening_session',
      uuid: row.uuid,
      row: row.toJson(),
    );
  });

  Stream<List<ReadingSessionRow>> watchReadingSince(DateTime since) =>
      (_db.select(_db.readingSessions)..where(
            (t) =>
                t.startedAt.isBiggerOrEqualValue(since) & t.deletedAt.isNull(),
          ))
          .watch();

  Stream<List<ListeningSessionRow>> watchListeningSince(DateTime since) =>
      (_db.select(_db.listeningSessions)..where(
            (t) =>
                t.startedAt.isBiggerOrEqualValue(since) & t.deletedAt.isNull(),
          ))
          .watch();

  // Tadabbur journal.

  Future<ReflectionRow> addReflection({
    required int surah,
    required int ayah,
    required String text,
  }) => _db.transaction(() async {
    final row = await _db
        .into(_db.reflections)
        .insertReturning(
          ReflectionsCompanion.insert(surah: surah, ayah: ayah, body: text),
        );
    await enqueueChange(
      _db,
      table: 'reflection',
      uuid: row.uuid,
      row: row.toJson(),
    );
    return row;
  });

  Future<void> _updateReflection(String uuid, ReflectionsCompanion change) =>
      _db.transaction(() async {
        final rows =
            await (_db.update(
              _db.reflections,
            )..where((t) => t.uuid.equals(uuid))).writeReturning(
              change.copyWith(updatedAt: Value(DateTime.now())),
            );
        for (final row in rows) {
          await enqueueChange(
            _db,
            table: 'reflection',
            uuid: row.uuid,
            row: row.toJson(),
            deleted: row.deletedAt != null,
          );
        }
      });

  Future<void> editReflection(String uuid, String text) =>
      _updateReflection(uuid, ReflectionsCompanion(body: Value(text)));

  Future<void> deleteReflection(String uuid) => _updateReflection(
    uuid,
    ReflectionsCompanion(deletedAt: Value(DateTime.now())),
  );

  /// Notes, newest first; with [query], those whose text contains it.
  Stream<List<ReflectionRow>> watchReflections({String query = ''}) {
    final q = _db.select(_db.reflections)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final words = query.trim();
    if (words.isNotEmpty) {
      q.where((t) => t.body.like('%${_escape(words)}%', escapeChar: r'\'));
    }
    return q.watch();
  }

  /// Notes on one verse.
  Stream<List<ReflectionRow>> watchReflectionsOn(int surah, int ayah) =>
      (_db.select(_db.reflections)
            ..where(
              (t) =>
                  t.surah.equals(surah) &
                  t.ayah.equals(ayah) &
                  t.deletedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();
}

String _escape(String s) =>
    s.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');
