import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/db/user_database.dart';
import 'package:tibyan/core/sync/sync.dart';
import 'package:tibyan/features/khatma/data/activity_repository.dart';

/// A server kept in memory.
class FakeBackend implements SyncBackend {
  FakeBackend({this.user = 'u1'});

  String? user;
  final pushed = <OutboxRow>[];
  final remote = <RemoteChange>[];

  @override
  Future<String?> currentUser() async => user;

  @override
  Future<void> push(List<OutboxRow> changes) async => pushed.addAll(changes);

  @override
  Future<List<RemoteChange>> pull({DateTime? since}) async => [
    for (final c in remote)
      if (since == null || c.updatedAt.isAfter(since)) c,
  ];
}

void main() {
  late UserDatabase db;
  late SharedPreferences prefs;
  setUp(() async {
    db = UserDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });
  tearDown(() => db.close());

  test('last write wins; a tie keeps the local row', () {
    final t = DateTime(2026, 10, 1, 12);
    expect(remoteWins(null, t), isTrue);
    expect(remoteWins(t, t.add(const Duration(seconds: 1))), isTrue);
    expect(remoteWins(t, t), isFalse);
    expect(remoteWins(t, t.subtract(const Duration(hours: 1))), isFalse);
  });

  test('off by flag, and guests never send anything', () async {
    await ActivityRepository(db).addReflection(surah: 1, ayah: 1, text: 'a');
    final backend = FakeBackend();
    expect(
      await SyncEngine(db: db, backend: backend, enabled: false).syncOnce(),
      SyncOutcome.off,
    );
    backend.user = null;
    expect(
      await SyncEngine(db: db, backend: backend, enabled: true).syncOnce(),
      SyncOutcome.guest,
    );
    expect(backend.pushed, isEmpty);
    expect(await db.select(db.outbox).get(), hasLength(1));
    expect(
      await SyncEngine(
        db: db,
        backend: const LocalOnlyBackend(),
        enabled: true,
      ).syncOnce(),
      SyncOutcome.guest,
    );
  });

  test('signed in: the outbox is sent and emptied, newer rows merge', () async {
    final repo = ActivityRepository(db);
    final mine = await repo.addReflection(surah: 1, ayah: 1, text: 'local');
    final backend = FakeBackend();
    final later = DateTime.now().add(const Duration(hours: 1));
    final older = DateTime(2020);
    backend.remote.addAll([
      // A newer edit of my note from another device.
      RemoteChange(
        table: 'reflection',
        uuid: mine.uuid,
        updatedAt: later,
        row: {
          ...mine.toJson(),
          'body': 'from phone',
          'updatedAt': later.millisecondsSinceEpoch,
        },
      ),
      // A note only on the server.
      RemoteChange(
        table: 'reflection',
        uuid: 'remote-1',
        updatedAt: older,
        row: {
          ...mine.toJson(),
          'id': 99,
          'uuid': 'remote-1',
          'body': 'other',
          'updatedAt': older.millisecondsSinceEpoch,
        },
      ),
    ]);
    final engine = SyncEngine(
      db: db,
      backend: backend,
      enabled: true,
      prefs: prefs,
    );
    expect(await engine.syncOnce(), SyncOutcome.done);
    expect(backend.pushed.single.rowUuid, mine.uuid);
    expect(await db.select(db.outbox).get(), isEmpty);
    final notes = await repo.watchReflections().first;
    expect(notes.map((n) => n.body).toSet(), {'from phone', 'other'});

    // An older remote copy does not overwrite a newer local edit.
    await repo.editReflection(mine.uuid, 'edited here');
    final applied = await applyRemote(
      db,
      RemoteChange(
        table: 'reflection',
        uuid: mine.uuid,
        updatedAt: older,
        row: {...mine.toJson(), 'body': 'stale'},
      ),
    );
    expect(applied, isFalse);
    expect(
      (await repo.watchReflectionsOn(1, 1).first)
          .firstWhere((n) => n.uuid == mine.uuid)
          .body,
      'edited here',
    );
  });
}
