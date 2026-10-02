import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/user_database.dart';

/// One row as the server holds it.
class RemoteChange {
  const RemoteChange({
    required this.table,
    required this.uuid,
    required this.row,
    required this.updatedAt,
  });

  /// SQL table name, one of [syncedTables].
  final String table;
  final String uuid;

  /// The row as JSON, in the shape of the local data class's `toJson()`.
  final Map<String, dynamic> row;
  final DateTime updatedAt;
}

/// Where synced rows go. The app talks to the server only through this,
/// so the server can change without touching the rest of the app.
///
/// See `docs/SYNC.md` for the Supabase backend that will implement it.
abstract interface class SyncBackend {
  /// The signed-in account, or null for a guest. Guests' data never leaves
  /// the device.
  Future<String?> currentUser();

  /// Sends local changes. Each entry's payload is the whole row.
  Future<void> push(List<OutboxRow> changes);

  /// Rows changed on the server after [since] (all rows when null).
  Future<List<RemoteChange>> pull({DateTime? since});
}

/// The backend until accounts are switched on: nobody is signed in, so
/// nothing is sent or received.
class LocalOnlyBackend implements SyncBackend {
  const LocalOnlyBackend();

  @override
  Future<String?> currentUser() async => null;

  @override
  Future<void> push(List<OutboxRow> changes) async {}

  @override
  Future<List<RemoteChange>> pull({DateTime? since}) async => const [];
}

/// Last write wins, per row: the remote row replaces the local one only
/// when it changed later. A tie keeps the local row.
bool remoteWins(DateTime? localUpdatedAt, DateTime remoteUpdatedAt) =>
    localUpdatedAt == null || remoteUpdatedAt.isAfter(localUpdatedAt);

enum SyncOutcome { off, guest, done }

/// Sends the outbox and merges newer rows from the server.
class SyncEngine {
  SyncEngine({
    required this.db,
    required this.backend,
    required this.enabled,
    this.prefs,
  });

  final UserDatabase db;
  final SyncBackend backend;

  /// The `accounts_sync` flag.
  final bool enabled;
  final SharedPreferences? prefs;

  static const _lastPullKey = 'sync.lastPull';

  Future<SyncOutcome> syncOnce() async {
    if (!enabled) return SyncOutcome.off;
    if (await backend.currentUser() == null) return SyncOutcome.guest;

    final pending = await (db.select(
      db.outbox,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    if (pending.isNotEmpty) {
      await backend.push(pending);
      // Only what was sent: a change made meanwhile stays queued.
      await db.transaction(() async {
        for (final e in pending) {
          await (db.delete(db.outbox)
                ..where((t) => t.id.equals(e.id) & t.payload.equals(e.payload)))
              .go();
        }
      });
    }

    final last = prefs?.getInt(_lastPullKey);
    final changes = await backend.pull(
      since: last == null ? null : DateTime.fromMillisecondsSinceEpoch(last),
    );
    var newest = last ?? 0;
    for (final c in changes) {
      await applyRemote(db, c);
      newest = c.updatedAt.millisecondsSinceEpoch > newest
          ? c.updatedAt.millisecondsSinceEpoch
          : newest;
    }
    await prefs?.setInt(_lastPullKey, newest);
    return SyncOutcome.done;
  }
}

/// Writes a server row locally if it is newer (last write wins). Applied
/// rows are not queued in the outbox: they came from the server.
Future<bool> applyRemote(UserDatabase db, RemoteChange c) async {
  final json = c.row;
  Future<bool> merge<T extends Table, R extends DataClass>(
    TableInfo<T, R> table,
    GeneratedColumn<String> uuid,
    R Function(Map<String, dynamic>) fromJson,
    Insertable<R> Function(R) companion,
  ) async {
    final local = await (db.select(
      table,
    )..where((_) => uuid.equals(c.uuid))).getSingleOrNull();
    final stamp = local?.toJson()['updatedAt'] as int?;
    final localUpdated = stamp == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(stamp);
    if (!remoteWins(localUpdated, c.updatedAt)) return false;
    final remote = fromJson(json);
    if (local == null) {
      await db.into(table).insert(companion(remote));
    } else {
      await (db.update(
        table,
      )..where((_) => uuid.equals(c.uuid))).write(companion(remote));
    }
    return true;
  }

  // Local row ids differ between devices: rows are matched by uuid and the
  // remote id is never written.
  Map<String, dynamic> noId(Map<String, dynamic> j) => {...j, 'id': 0};
  return switch (c.table) {
    'khatma' => merge(
      db.khatmas,
      db.khatmas.uuid,
      (j) => KhatmaRow.fromJson(noId(j)),
      (r) => r.toCompanion(true).copyWith(id: const Value.absent()),
    ),
    'khatma_log' => merge(
      db.khatmaLogs,
      db.khatmaLogs.uuid,
      (j) => KhatmaLogRow.fromJson(noId(j)),
      (r) => r.toCompanion(true).copyWith(id: const Value.absent()),
    ),
    'reading_session' => merge(
      db.readingSessions,
      db.readingSessions.uuid,
      (j) => ReadingSessionRow.fromJson(noId(j)),
      (r) => r.toCompanion(true).copyWith(id: const Value.absent()),
    ),
    'listening_session' => merge(
      db.listeningSessions,
      db.listeningSessions.uuid,
      (j) => ListeningSessionRow.fromJson(noId(j)),
      (r) => r.toCompanion(true).copyWith(id: const Value.absent()),
    ),
    'reflection' => merge(
      db.reflections,
      db.reflections.uuid,
      (j) => ReflectionRow.fromJson(noId(j)),
      (r) => r.toCompanion(true).copyWith(id: const Value.absent()),
    ),
    _ => Future.value(false),
  };
}

/// The payload of an outbox entry, decoded.
Map<String, dynamic> outboxPayload(OutboxRow e) =>
    jsonDecode(e.payload) as Map<String, dynamic>;

/// The sync backend. Overridden with the Supabase backend once a project
/// exists (docs/SYNC.md); until then nothing leaves the device.
final syncBackendProvider = Provider<SyncBackend>(
  (ref) => const LocalOnlyBackend(),
);
