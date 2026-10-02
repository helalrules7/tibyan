import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'habit_tables.dart';

export 'habit_tables.dart';

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

  /// One of [MarkKind] for the four fixed marks; null for the reader's
  /// own named fawasil.
  TextColumn get kind => text().nullable()();
}

/// The four fixed marks, set with one tap.
enum MarkKind {
  reading(0xFF2F6FD0),
  review(0xFFD0453B),
  hifz(0xFF2E9A53),
  tadabbur(0xFFC98A12);

  const MarkKind(this.color);

  /// ARGB colour.
  final int color;
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

@DriftDatabase(
  tables: [
    BookmarkSets,
    ReadingPositions,
    Khatmas,
    KhatmaLogs,
    ReadingSessions,
    ListeningSessions,
    Reflections,
    Outbox,
  ],
)
class UserDatabase extends _$UserDatabase {
  UserDatabase(super.executor);

  UserDatabase.open() : super(driftDatabase(name: 'user'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(bookmarkSets, bookmarkSets.kind);
      }
      if (from < 3) {
        // Khatma, reading reports, tadabbur journal and the sync outbox.
        // Tables are created only if missing, so this step is safe to run
        // after or before other branches' steps.
        await _createHabitTables(m);
      }
    },
  );

  Future<void> _createHabitTables(Migrator m) async {
    await m.createTable(khatmas);
    await m.createTable(khatmaLogs);
    await m.createTable(readingSessions);
    await m.createTable(listeningSessions);
    await m.createTable(reflections);
    await m.createTable(outbox);
  }

  /// Moves a fixed mark to a verse, creating it the first time.
  Future<void> setMark(
    MarkKind kind, {
    required String name,
    required int surah,
    required int ayah,
    required int page,
  }) async {
    final existing = await (select(
      bookmarkSets,
    )..where((t) => t.kind.equals(kind.name))).getSingleOrNull();
    if (existing != null) {
      await moveBookmarkSet(existing.id, surah: surah, ayah: ayah, page: page);
      return;
    }
    await into(bookmarkSets).insert(
      BookmarkSetsCompanion.insert(
        name: name,
        color: kind.color,
        surah: surah,
        ayah: ayah,
        page: page,
        sortOrder: Value(-10 + kind.index),
        kind: Value(kind.name),
        updatedAt: DateTime.now(),
      ),
    );
  }

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
