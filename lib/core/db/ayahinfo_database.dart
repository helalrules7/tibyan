import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'ayahinfo_database.g.dart';

/// Glyph boxes of the old Madina edition (1405H), from quran.com's
/// `ayahinfo_1024.db`, in pixels of the 1024-wide page images.
@DataClassName('GlyphRow')
class Glyphs extends Table {
  IntColumn get glyphId => integer()();
  IntColumn get pageNumber => integer()();
  IntColumn get lineNumber => integer()();
  IntColumn get suraNumber => integer()();
  IntColumn get ayahNumber => integer()();
  IntColumn get position => integer()();
  IntColumn get minX => integer()();
  IntColumn get maxX => integer()();
  IntColumn get minY => integer()();
  IntColumn get maxY => integer()();

  @override
  Set<Column> get primaryKey => {glyphId};
}

@DriftDatabase(tables: [Glyphs])
class AyahInfoDatabase extends _$AyahInfoDatabase {
  AyahInfoDatabase(super.executor);

  AyahInfoDatabase.open(File file)
    : super(NativeDatabase.createInBackground(file));

  @override
  int get schemaVersion => 1;

  /// The file arrives with its tables; drift only stamps the version.
  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (_) async {});

  Future<List<GlyphRow>> page(int page) =>
      (select(glyphs)..where((t) => t.pageNumber.equals(page))).get();
}
