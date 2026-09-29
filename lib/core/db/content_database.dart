import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'content_database.g.dart';

/// Tables of the bundled, read-only `assets/db/content.db`, built by
/// `tools/build_content_db.py`. The app never writes to it.
@DataClassName('SurahRow')
class Surah extends Table {
  @override
  String get tableName => 'surah';

  IntColumn get id => integer()();
  TextColumn get nameAr => text()();
  TextColumn get nameEn => text()();
  TextColumn get meaningEn => text()();
  TextColumn get revelation => text()();
  IntColumn get revelationOrder => integer()();
  IntColumn get ayahCount => integer()();

  /// First page in the new edition (1441H).
  IntColumn get startPage => integer()();

  /// First page in the old edition (1405H).
  IntColumn get startPage1405 => integer().named('start_page_1405')();
  IntColumn get sourceId => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AyahRow')
class Ayah extends Table {
  @override
  String get tableName => 'ayah';

  IntColumn get id => integer()();
  IntColumn get surah => integer()();
  IntColumn get number => integer()();

  /// Tanzil Uthmani text, verbatim (may start with the basmala). Kept for
  /// reference and comparison; not shown.
  TextColumn get verseText => text().named('text')();

  /// KFGQPC Hafs 2.0 text, verbatim, for the KFGQPC Hafs font. Shown in the
  /// continuous view. Ends with a space and the verse-number glyph.
  TextColumn get displayText => text()();

  /// Characters of the basmala before verse 1 in the Tanzil file.
  IntColumn get basmalaPrefix => integer()();
  TextColumn get textSearch => text()();
  IntColumn get searchBasmalaPrefix => integer()();
  IntColumn get juz => integer()();
  IntColumn get hizbQuarter => integer()();
  IntColumn get manzil => integer()();

  /// Page in the new edition (1441H).
  IntColumn get page => integer()();

  /// Page in the old edition (1405H).
  IntColumn get page1405 => integer().named('page_1405')();
  TextColumn get sajda => text().nullable()();
  IntColumn get textSourceId => integer()();
  IntColumn get displaySourceId => integer()();
  IntColumn get pageSourceId => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AyahPolygonRow')
class AyahPolygon extends Table {
  @override
  String get tableName => 'ayah_polygon';

  IntColumn get page => integer()();
  IntColumn get surah => integer()();
  IntColumn get number => integer()();
  TextColumn get path => text()();
  RealColumn get markerX => real().nullable()();
  RealColumn get markerY => real().nullable()();

  @override
  Set<Column> get primaryKey => {page, surah, number};
}

@DataClassName('SourceRow')
class Source extends Table {
  @override
  String get tableName => 'source';

  IntColumn get id => integer()();
  TextColumn get key => text()();
  TextColumn get title => text()();
  TextColumn get publisher => text()();
  TextColumn get version => text().nullable()();
  TextColumn get license => text()();
  TextColumn get url => text()();
  TextColumn get attribution => text()();
  TextColumn get notice => text().nullable()();
  TextColumn get sha256 => text()();
  TextColumn get retrievedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A word's box on a page of the new edition, in tenths of the page's
/// viewBox units. Derived from the page geometry by
/// tools/build_word_boxes.py.
@DataClassName('WordBoxRow')
class WordBox extends Table {
  @override
  String get tableName => 'word_box';

  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();

  /// 1-based among the words of the KFGQPC text.
  IntColumn get word => integer()();
  IntColumn get page => integer()();
  IntColumn get x0 => integer()();
  IntColumn get y0 => integer()();
  IntColumn get x1 => integer()();
  IntColumn get y1 => integer()();

  /// 1 when every word of the verse matched its predicted letter groups.
  IntColumn get exact => integer()();

  @override
  Set<Column> get primaryKey => {surah, ayah, word};

  @override
  bool get withoutRowId => true;
}

/// Where to split a page into its 15 lines (see tools/build_line_cuts.py).
@DataClassName('LineCutRow')
class LineCut extends Table {
  @override
  String get tableName => 'line_cut';

  TextColumn get edition => text()();
  IntColumn get page => integer()();

  /// 0..13: the gap below line [gap].
  IntColumn get gap => integer()();

  /// Page units (1441) or image pixels (1405).
  RealColumn get y => real()();

  @override
  Set<Column> get primaryKey => {edition, page, gap};

  @override
  bool get withoutRowId => true;
}

/// New-edition marks that cross a cut, with the line they belong to.
@DataClassName('LineOverflowRow')
class LineOverflow extends Table {
  @override
  String get tableName => 'line_overflow';

  IntColumn get page => integer()();
  IntColumn get line => integer()();
  TextColumn get path => text()();

  @override
  Set<Column> get primaryKey => {page, line, path};
}

@DriftDatabase(
  tables: [Surah, Ayah, AyahPolygon, Source, WordBox, LineCut, LineOverflow],
)
class ContentDatabase extends _$ContentDatabase {
  ContentDatabase(super.executor);

  /// Must match `SCHEMA_VERSION` in tools/build_content_db.py.
  @override
  int get schemaVersion => 5;

  /// The file is built ahead of time; never create or migrate it here.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {},
    onUpgrade: (m, from, to) async {},
  );

  /// Copies the bundled database to app storage when missing or when the
  /// bundled copy changed, then opens it read-only in a background isolate.
  static Future<ContentDatabase> openBundled(AssetBundle bundle) async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'content.db'));
    final stamp = File(p.join(dir.path, 'content.db.stamp'));
    final data = await bundle.load('assets/db/content.db');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final fingerprint = sha256.convert(bytes).toString();
    if (!file.existsSync() ||
        !stamp.existsSync() ||
        stamp.readAsStringSync() != fingerprint) {
      await file.writeAsBytes(bytes, flush: true);
      await stamp.writeAsString(fingerprint);
    }
    return ContentDatabase(
      NativeDatabase.createInBackground(
        file,
        setup: (db) => db.execute('PRAGMA query_only = ON'),
      ),
    );
  }
}
