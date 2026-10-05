import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/backup/backup.dart';
import 'package:tibyan/core/db/user_database.dart';

UserDatabase _db() => UserDatabase(NativeDatabase.memory());

void main() {
  late UserDatabase a;
  late UserDatabase b;
  setUp(() {
    a = _db();
    b = _db();
  });
  tearDown(() async {
    await a.close();
    await b.close();
  });

  Future<void> fill(UserDatabase db) async {
    await db.savePosition(
      edition: 'madina1441',
      view: 'page',
      surah: 2,
      ayah: 255,
      page: 42,
    );
    await db.setMark(MarkKind.hifz, name: 'حفظ', surah: 67, ayah: 1, page: 562);
    await db.addBookmarkSet(
      name: 'ورد',
      color: 0xFF2F6B4F,
      surah: 18,
      ayah: 10,
      page: 294,
    );
    await db
        .into(db.reflections)
        .insert(ReflectionsCompanion.insert(surah: 1, ayah: 2, body: 'تدبر'));
  }

  test('a backup restores on an empty device', () async {
    await fill(a);
    final text = await Backup(a).export();
    final r = await Backup(b).import(text);
    expect(r.added, greaterThanOrEqualTo(4));
    expect((await b.position())!.page, 42);
    final sets = await b.watchBookmarkSets().first;
    expect(sets.map((s) => s.name), containsAll(['حفظ', 'ورد']));
    final notes = await b.select(b.reflections).get();
    expect(notes.single.body, 'تدبر');
  });

  test('restoring twice adds nothing the second time', () async {
    await fill(a);
    final text = await Backup(a).export();
    await Backup(b).import(text);
    final again = await Backup(b).import(text);
    expect(again.added, 0);
    expect((await b.select(b.reflections).get()), hasLength(1));
    expect((await b.watchBookmarkSets().first), hasLength(2));
  });

  test(
    'a newer copy of a note replaces the older one, an older one does not',
    () async {
      await fill(a);
      final note = (await a.select(a.reflections).get()).single;
      // The device has an older edit of the same note.
      await Backup(b).import(await Backup(a).export());
      await (b.update(
        b.reflections,
      )..where((t) => t.uuid.equals(note.uuid))).write(
        ReflectionsCompanion(
          body: const Value('قديم'),
          updatedAt: Value(note.updatedAt.subtract(const Duration(days: 1))),
        ),
      );
      await Backup(b).import(await Backup(a).export());
      expect((await b.select(b.reflections).get()).single.body, 'تدبر');

      // The device's own newer edit stays.
      await (b.update(
        b.reflections,
      )..where((t) => t.uuid.equals(note.uuid))).write(
        ReflectionsCompanion(
          body: const Value('أحدث'),
          updatedAt: Value(note.updatedAt.add(const Duration(days: 1))),
        ),
      );
      await Backup(b).import(await Backup(a).export());
      expect((await b.select(b.reflections).get()).single.body, 'أحدث');
    },
  );

  test('files that are not backups are refused', () async {
    expect(Backup(b).import('hello'), throwsA(isA<BackupException>()));
    expect(
      Backup(b).import('{"app":"other","tables":{}}'),
      throwsA(isA<BackupException>()),
    );
    expect(
      Backup(b).import('{"app":"tibyan","format":99,"tables":{}}'),
      throwsA(isA<BackupException>()),
    );
  });
}
