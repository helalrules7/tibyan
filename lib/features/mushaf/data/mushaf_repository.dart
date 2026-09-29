import 'package:drift/drift.dart';

import '../../../core/db/content_database.dart';
import '../../../core/settings/app_settings.dart';

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

  /// Verses on a page of the given Madina edition.
  Future<List<AyahRow>> ayahsOnPage(
    int page, [
    MushafEdition edition = MushafEdition.madina1441,
  ]) =>
      (_db.select(_db.ayah)
            ..where(
              (t) => edition == MushafEdition.madina1405
                  ? t.page1405.equals(page)
                  : t.page.equals(page),
            )
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

  /// First verse of each of the 60 hizbs.
  Future<List<AyahRow>> hizbStarts() async {
    final rows = await _db
        .customSelect(
          'SELECT MIN(id) AS id FROM ayah GROUP BY (hizb_quarter - 1) / 4 ORDER BY 1',
        )
        .get();
    final ids = rows.map((r) => r.read<int>('id')).toList();
    final ayahs = await (_db.select(
      _db.ayah,
    )..where((t) => t.id.isIn(ids))).get();
    ayahs.sort((a, b) => a.id.compareTo(b.id));
    return ayahs;
  }

  /// Number of open questions awaiting a qualified reviewer.
  Future<int> reviewNoteCount() async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS n FROM review_note WHERE decision IS NULL',
        )
        .getSingle();
    return row.read<int>('n');
  }

  /// Word boxes on a page of the new edition (1441H).
  Future<List<WordBoxRow>> wordBoxes(int page) =>
      (_db.select(_db.wordBox)
            ..where((t) => t.page.equals(page))
            ..orderBy([
              (t) => OrderingTerm.asc(t.surah),
              (t) => OrderingTerm.asc(t.ayah),
              (t) => OrderingTerm.asc(t.word),
            ]))
          .get();

  /// The 14 cuts between the lines of a page, top to bottom; empty for
  /// pages 1 and 2.
  Future<List<double>> lineCuts(String edition, int page) async {
    final rows =
        await (_db.select(_db.lineCut)
              ..where((t) => t.edition.equals(edition) & t.page.equals(page))
              ..orderBy([(t) => OrderingTerm.asc(t.gap)]))
            .get();
    return [for (final r in rows) r.y];
  }

  Future<List<LineOverflowRow>> lineOverflow(int page) =>
      (_db.select(_db.lineOverflow)..where((t) => t.page.equals(page))).get();

  /// Verses on a page that start a new hizb quarter.
  Future<List<AyahRow>> quarterStartsOnPage(
    int page,
    MushafEdition edition,
  ) async {
    final col = edition == MushafEdition.madina1405 ? 'page_1405' : 'page';
    final rows = await _db
        .customSelect(
          'SELECT a.id AS id FROM ayah a LEFT JOIN ayah b ON b.id = a.id - 1 '
          'WHERE a.$col = ? AND (b.id IS NULL OR b.hizb_quarter <> a.hizb_quarter)',
          variables: [Variable.withInt(page)],
        )
        .get();
    final ids = [for (final r in rows) r.read<int>('id')];
    if (ids.isEmpty) return const [];
    return (_db.select(_db.ayah)..where((t) => t.id.isIn(ids))).get();
  }

  Future<List<SourceRow>> sources() =>
      (_db.select(_db.source)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
}

/// Text helpers that never change the stored text: they only choose
/// which part of the verbatim string to show.
extension AyahDisplay on AyahRow {
  int get _numberSplit => displayText.lastIndexOf(RegExp('[\u00a0 ]'));

  /// The verse without its number glyph.
  String get displayBody => displayText.substring(0, _numberSplit);

  /// The verse-number glyph of the KFGQPC font.
  String get displayNumber => displayText.substring(_numberSplit + 1);
}

/// Page numbers differ between the two Madina editions.
extension EditionPages on AyahRow {
  int pageIn(MushafEdition edition) =>
      edition == MushafEdition.madina1405 ? page1405 : page;
}

extension EditionStartPages on SurahRow {
  int startPageIn(MushafEdition edition) =>
      edition == MushafEdition.madina1405 ? startPage1405 : startPage;
}
