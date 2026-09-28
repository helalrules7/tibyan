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
  IntColumn get startPage => integer()();
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

  /// Tanzil Uthmani text, verbatim (may start with the basmala).
  TextColumn get verseText => text().named('text')();

  /// Characters of the basmala before verse 1 in the Tanzil file.
  IntColumn get basmalaPrefix => integer()();
  TextColumn get textSearch => text()();
  IntColumn get searchBasmalaPrefix => integer()();
  IntColumn get juz => integer()();
  IntColumn get hizbQuarter => integer()();
  IntColumn get manzil => integer()();
  IntColumn get page => integer()();
  TextColumn get sajda => text().nullable()();
  IntColumn get textSourceId => integer()();
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

@DriftDatabase(tables: [Surah, Ayah, AyahPolygon, Source])
class ContentDatabase extends _$ContentDatabase {
  ContentDatabase(super.executor);

  /// Must match `SCHEMA_VERSION` in tools/build_content_db.py.
  @override
  int get schemaVersion => 1;

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
