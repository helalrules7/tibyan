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
}
