import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/user_database.dart';

void main() {
  late UserDatabase db;
  setUp(() => db = UserDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('last position is saved and replaced', () async {
    expect(await db.position(), isNull);
    await db.savePosition(
      edition: 'madina1441',
      view: 'page',
      surah: 2,
      ayah: 255,
      page: 42,
    );
    await db.savePosition(
      edition: 'madina1441',
      view: 'page',
      surah: 3,
      ayah: 1,
      page: 50,
    );
    final p = await db.position();
    expect((p!.surah, p.ayah, p.page), (3, 1, 50));
  });

  test('bookmark sets: add, move, delete', () async {
    final id = await db.addBookmarkSet(
      name: 'Hifz',
      color: 0xFF2F6B4F,
      surah: 1,
      ayah: 1,
      page: 1,
    );
    await db.moveBookmarkSet(id, surah: 67, ayah: 1, page: 562);
    var sets = await db.watchBookmarkSets().first;
    expect((sets.single.surah, sets.single.page), (67, 562));
    await db.deleteBookmarkSet(id);
    sets = await db.watchBookmarkSets().first;
    expect(sets, isEmpty);
  });
}
