import 'package:drift/drift.dart';

import '../../../core/db/content_database.dart';

/// First verse of a juz, for the juz index.
class JuzStart {
  const JuzStart({required this.juz, required this.ayah});

  final int juz;
  final AyahRow ayah;
}

/// Read-only access to Quran text and layout. All queries are small
/// (one page or one surah) and run on the database's background isolate.
class MushafRepository {
  MushafRepository(this._db);

  final ContentDatabase _db;

  Future<List<SurahRow>> surahs() =>
      (_db.select(_db.surah)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  Future<SurahRow> surahById(int id) =>
      (_db.select(_db.surah)..where((t) => t.id.equals(id))).getSingle();

  /// Verses on a page of the new Madina edition (1441H).
  Future<List<AyahRow>> ayahsOnPage(int page) =>
      (_db.select(_db.ayah)
            ..where((t) => t.page.equals(page))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  Future<List<AyahRow>> ayahsOfSurah(int surah) =>
      (_db.select(_db.ayah)
            ..where((t) => t.surah.equals(surah))
            ..orderBy([(t) => OrderingTerm.asc(t.number)]))
          .get();

  Future<AyahRow> ayah(int surah, int number) => (_db.select(
    _db.ayah,
  )..where((t) => t.surah.equals(surah) & t.number.equals(number))).getSingle();

  /// Verse outlines on a page of the new edition, in the page's viewBox.
  Future<List<AyahPolygonRow>> polygons(int page) =>
      (_db.select(_db.ayahPolygon)..where((t) => t.page.equals(page))).get();

  Future<List<JuzStart>> juzStarts() async {
    final rows = await _db
        .customSelect(
          'SELECT MIN(id) AS id FROM ayah GROUP BY juz ORDER BY juz',
        )
        .get();
    final ids = rows.map((r) => r.read<int>('id')).toList();
    final ayahs = await (_db.select(
      _db.ayah,
    )..where((t) => t.id.isIn(ids))).get();
    ayahs.sort((a, b) => a.id.compareTo(b.id));
    return [for (final a in ayahs) JuzStart(juz: a.juz, ayah: a)];
  }

  /// Number of open questions awaiting a qualified reviewer.
  Future<int> reviewNoteCount() async {
    final row = await _db
        .customSelect('SELECT COUNT(*) AS n FROM review_note')
        .getSingle();
    return row.read<int>('n');
  }

  Future<List<SourceRow>> sources() =>
      (_db.select(_db.source)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
}

/// Text helpers that never change the stored text: they only choose
/// which part of the verbatim string to show.
extension AyahDisplay on AyahRow {
  /// The verse without the basmala that Tanzil's file places before
  /// verse 1 of 112 surahs (shown separately as a header).
  String get displayText => verseText.substring(basmalaPrefix);
}
