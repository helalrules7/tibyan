import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'user_database.g.dart';

/// Named bookmarks ("fawasil"). Each one moves to the last place read
/// with it and has its own colour.
@DataClassName('BookmarkSetRow')
class BookmarkSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// ARGB colour.
  IntColumn get color => integer()();
  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();
  IntColumn get page => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
}

/// The last reading position, saved automatically. One row.
@DataClassName('ReadingPositionRow')
class ReadingPositions extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get edition => text()();
  TextColumn get view => text()();
  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();
  IntColumn get page => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [BookmarkSets, ReadingPositions])
class UserDatabase extends _$UserDatabase {
  UserDatabase(super.executor);

  UserDatabase.open() : super(driftDatabase(name: 'user'));

  @override
  int get schemaVersion => 1;

  Stream<ReadingPositionRow?> watchPosition() => (select(
    readingPositions,
  )..where((t) => t.id.equals(1))).watchSingleOrNull();

  Future<ReadingPositionRow?> position() => (select(
    readingPositions,
  )..where((t) => t.id.equals(1))).getSingleOrNull();

  Future<void> savePosition({
    required String edition,
    required String view,
    required int surah,
    required int ayah,
    required int page,
  }) => into(readingPositions).insertOnConflictUpdate(
    ReadingPositionsCompanion.insert(
      id: const Value(1),
      edition: edition,
      view: view,
      surah: surah,
      ayah: ayah,
      page: page,
      updatedAt: DateTime.now(),
    ),
  );

  Stream<List<BookmarkSetRow>> watchBookmarkSets() =>
      (select(bookmarkSets)..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.id),
          ]))
          .watch();

  Future<int> addBookmarkSet({
    required String name,
    required int color,
    required int surah,
    required int ayah,
    required int page,
  }) => into(bookmarkSets).insert(
    BookmarkSetsCompanion.insert(
      name: name,
      color: color,
      surah: surah,
      ayah: ayah,
      page: page,
      updatedAt: DateTime.now(),
    ),
  );

  Future<void> moveBookmarkSet(
    int id, {
    required int surah,
    required int ayah,
    required int page,
  }) => (update(bookmarkSets)..where((t) => t.id.equals(id))).write(
    BookmarkSetsCompanion(
      surah: Value(surah),
      ayah: Value(ayah),
      page: Value(page),
      updatedAt: Value(DateTime.now()),
    ),
  );

  Future<void> deleteBookmarkSet(int id) =>
      (delete(bookmarkSets)..where((t) => t.id.equals(id))).go();
}
