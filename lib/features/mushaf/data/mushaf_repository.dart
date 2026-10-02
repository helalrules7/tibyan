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

  /// Verses on a page of the given edition, in order. In the Shamarly
  /// edition this includes a verse that started on the page before.
  Future<List<AyahRow>> ayahsOnPage(
    int page, [
    MushafEdition edition = MushafEdition.madina1441,
  ]) =>
      (_db.select(_db.ayah)
            ..where(
              (t) => switch (edition) {
                MushafEdition.madina1441 => t.page.equals(page),
                MushafEdition.madina1405 => t.page1405.equals(page),
                MushafEdition.shamarly =>
                  t.pageShamarly.isSmallerOrEqualValue(page) &
                      t.pageShamarlyEnd.isBiggerOrEqualValue(page),
              },
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
    final col = edition.pageColumn;
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

  /// Shamarly page geometry: the page, its line slots and the ink that
  /// crosses a band edge.
  Future<ShamarlyPageRow?> shamarlyPage(int page) => (_db.select(
    _db.shamarlyPage,
  )..where((t) => t.page.equals(page))).getSingleOrNull();

  Future<List<ShamarlyLineRow>> shamarlyLines(int page) =>
      (_db.select(_db.shamarlyLine)
            ..where((t) => t.page.equals(page))
            ..orderBy([(t) => OrderingTerm.asc(t.line)]))
          .get();

  Future<List<ShamarlyOverflowRow>> shamarlyOverflow(int page) => (_db.select(
    _db.shamarlyLineOverflow,
  )..where((t) => t.page.equals(page))).get();

  /// Printed surah headers on a Shamarly page.
  Future<List<ShamarlyHeaderRow>> shamarlyHeaders(int page) =>
      (_db.select(_db.shamarlyHeader)..where((t) => t.page.equals(page))).get();

  Future<List<ShamarlyMarkerRow>> shamarlyMarkers(int page) =>
      (_db.select(_db.shamarlyMarker)..where((t) => t.page.equals(page))).get();

  /// The Shamarly catchword of [page]: its box on the next page's image.
  Future<ShamarlyCatchwordRow?> shamarlyCatchword(int page) => (_db.select(
    _db.shamarlyCatchword,
  )..where((t) => t.page.equals(page))).getSingleOrNull();

  /// One box per verse per line on a Shamarly page, in reading order.
  Future<List<ShamarlyVerseBoxRow>> shamarlyVerseBoxes(int page) =>
      (_db.select(_db.shamarlyVerseBox)
            ..where((t) => t.page.equals(page))
            ..orderBy([
              (t) => OrderingTerm.asc(t.surah),
              (t) => OrderingTerm.asc(t.ayah),
              (t) => OrderingTerm.asc(t.part),
            ]))
          .get();

  /// Shamarly word boxes on a page whose split is at least [minLevel]
  /// sure (see [shamarlyWordLevel]).
  Future<List<ShamarlyWordBoxRow>> shamarlyWordBoxes(
    int page, {
    int minLevel = shamarlyWordLevel,
  }) =>
      (_db.select(_db.shamarlyWordBox)..where(
            (t) => t.page.equals(page) & t.level.isBiggerOrEqualValue(minLevel),
          ))
          .get();

  /// Page of each word of a verse in the Shamarly edition, for words
  /// with boxes of at least [shamarlyWordLevel].
  Future<Map<int, int>> shamarlyWordPages(int surah, int ayah) async {
    final rows =
        await (_db.select(_db.shamarlyWordBox)..where(
              (t) =>
                  t.surah.equals(surah) &
                  t.ayah.equals(ayah) &
                  t.level.isBiggerOrEqualValue(shamarlyWordLevel),
            ))
            .get();
    return {for (final r in rows) r.word: r.page};
  }

  Future<List<OldOverflowRow>> oldLineOverflow(int page) => (_db.select(
    _db.lineOverflow1405,
  )..where((t) => t.page.equals(page))).get();

  /// Tafsir and translation texts in the content database, in display order.
  Future<List<CommentaryEditionRow>> commentaryEditions() => (_db.select(
    _db.commentaryEdition,
  )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();

  /// Every shipped entry for one verse, keyed by source id.
  Future<Map<int, CommentaryRow>> commentary(int surah, int ayah) async {
    final rows = await (_db.select(
      _db.commentary,
    )..where((t) => t.surah.equals(surah) & t.ayah.equals(ayah))).get();
    return {for (final r in rows) r.sourceId: r};
  }

  /// Every entry of the given texts, for searching by meaning.
  Future<List<CommentaryRow>> commentaryOf(List<int> sourceIds) => (_db.select(
    _db.commentary,
  )..where((t) => t.sourceId.isIn(sourceIds))).get();

  Future<List<ReciterRow>> reciters() =>
      (_db.select(_db.reciter)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  /// Verse timings of one surah file, in order; empty when the source has
  /// none for this reciter or surah.
  Future<List<AyahTimingRow>> timings(int reciter, int surah) =>
      (_db.select(_db.ayahTiming)
            ..where((t) => t.reciter.equals(reciter) & t.surah.equals(surah))
            ..orderBy([(t) => OrderingTerm.asc(t.ayah)]))
          .get();

  /// Speech spans of one surah file's verses, in order.
  Future<List<AyahSpeechRow>> speech(int reciter, int surah) =>
      (_db.select(_db.ayahSpeech)
            ..where((t) => t.reciter.equals(reciter) & t.surah.equals(surah))
            ..orderBy([(t) => OrderingTerm.asc(t.ayah)]))
          .get();

  /// Word timings of one surah file, in order of time.
  Future<List<WordTimingRow>> wordTimings(int reciter, int surah) =>
      (_db.select(_db.wordTiming)
            ..where((t) => t.reciter.equals(reciter) & t.surah.equals(surah))
            ..orderBy([(t) => OrderingTerm.asc(t.startMs)]))
          .get();

  /// Every verse in mushaf order, for search.
  Future<List<AyahRow>> searchRows() =>
      (_db.select(_db.ayah)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

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

/// Shamarly word boxes are shown only for verses whose split into words
/// is at least this sure: 2 = the four splits of tools/build_shamarly.py
/// agree; 1 = not yet reviewed. Verses below it are highlighted whole.
const shamarlyWordLevel = 2;

/// Page numbers differ between the editions. In the Shamarly edition this
/// is the page where the verse starts.
extension EditionPages on AyahRow {
  int pageIn(MushafEdition edition) => switch (edition) {
    MushafEdition.madina1441 => page,
    MushafEdition.madina1405 => page1405,
    MushafEdition.shamarly => pageShamarly,
  };
}

extension EditionStartPages on SurahRow {
  int startPageIn(MushafEdition edition) => switch (edition) {
    MushafEdition.madina1441 => startPage,
    MushafEdition.madina1405 => startPage1405,
    MushafEdition.shamarly => startPageShamarly,
  };
}

extension on MushafEdition {
  /// The `ayah` column holding the (start) page in this edition.
  String get pageColumn => switch (this) {
    MushafEdition.madina1441 => 'page',
    MushafEdition.madina1405 => 'page_1405',
    MushafEdition.shamarly => 'page_shamarly',
  };
}
