import 'package:drift/drift.dart';

import '../../../core/db/content_database.dart';
import '../../../core/settings/app_settings.dart';
import '../../audio/timing_updates.dart';
import 'riwaya_data.dart';
import 'tajweed_index.dart';

/// First verse of a juz, for the juz index.
class JuzStart {
  const JuzStart({required this.juz, required this.ayah});

  final int juz;
  final AyahRow ayah;
}

/// Read-only access to Quran text and layout. All queries are small
/// (one page or one surah) and run on the database's background isolate.
class MushafRepository {
  MushafRepository(this._db, [this._timing = const NoTimingOverrides()]);

  final ContentDatabase _db;

  /// Corrected timings downloaded since this content.db was built; they
  /// win over its rows for the reciters and surahs they hold.
  final TimingOverrides _timing;

  Future<List<SurahRow>> surahs() =>
      (_db.select(_db.surah)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  Future<SurahRow> surahById(int id) =>
      (_db.select(_db.surah)..where((t) => t.id.equals(id))).getSingle();

  /// Verses on a page of the given edition, in order. In the Shamarly
  /// edition this includes a verse that started on the page before.
  ///
  /// A riwaya edition's pages are in its pack: with [riwaya] (that
  /// edition's data), the Hafs verses its page holds; without it, none.
  Future<List<AyahRow>> ayahsOnPage(
    int page, [
    MushafEdition edition = MushafEdition.madina1441,
    RiwayaData? riwaya,
  ]) async {
    if (edition.isRiwaya) {
      if (riwaya == null) return const [];
      final on = riwaya.versesTouching(page);
      if (on.isEmpty) return const [];
      final surahs = {for (final k in on) k.surah};
      final rows =
          await (_db.select(_db.ayah)
                ..where((t) => t.surah.isIn(surahs))
                ..orderBy([(t) => OrderingTerm.asc(t.id)]))
              .get();
      return [
        for (final r in rows)
          if (riwaya.hafsOnPage(r.surah, r.number, page)) r,
      ];
    }
    return _hafsAyahsOnPage(page, edition);
  }

  Future<List<AyahRow>> _hafsAyahsOnPage(int page, MushafEdition edition) =>
      (_db.select(_db.ayah)
            ..where(
              (t) => switch (edition) {
                MushafEdition.madina1441 => t.page.equals(page),
                MushafEdition.madina1405 => t.page1405.equals(page),
                MushafEdition.shamarly =>
                  t.pageShamarly.isSmallerOrEqualValue(page) &
                      t.pageShamarlyEnd.isBiggerOrEqualValue(page),
                // Riwaya pages and verses are in their pack (RiwayaData),
                // numbered by the riwaya, never in this Hafs table.
                _ => const Constant(false),
              },
            )
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  Future<List<AyahRow>> ayahsOfSurah(int surah) =>
      (_db.select(_db.ayah)
            ..where((t) => t.surah.equals(surah))
            ..orderBy([(t) => OrderingTerm.asc(t.number)]))
          .get();

  /// A verse by its row id (1 … 6236, in mushaf order).
  Future<AyahRow> ayahById(int id) =>
      (_db.select(_db.ayah)..where((t) => t.id.equals(id))).getSingle();

  /// The verses of prostration (the `sajda` column, from Tanzil's
  /// metadata), in mushaf order.
  Future<List<AyahRow>> sajdaVerses() =>
      (_db.select(_db.ayah)
            ..where((t) => t.sajda.isNotNull())
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
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

  /// Word boxes of verses [from] to [to] of [surah] on the new edition's
  /// pages (1441H), in reading order.
  Future<List<WordBoxRow>> wordBoxesOfVerses(int surah, int from, int to) =>
      (_db.select(_db.wordBox)
            ..where(
              (t) => t.surah.equals(surah) & t.ayah.isBetweenValues(from, to),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.ayah),
              (t) => OrderingTerm.asc(t.word),
            ]))
          .get();

  /// The cuts between the lines of pages [from] to [to] of [edition], by
  /// page (as [lineCuts]; pages 1 and 2 have none).
  Future<Map<int, List<double>>> lineCutsOfPages(
    String edition,
    int from,
    int to,
  ) async {
    final rows =
        await (_db.select(_db.lineCut)
              ..where(
                (t) =>
                    t.edition.equals(edition) &
                    t.page.isBetweenValues(from, to),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.page),
                (t) => OrderingTerm.asc(t.gap),
              ]))
            .get();
    final out = <int, List<double>>{};
    for (final r in rows) {
      (out[r.page] ??= []).add(r.y);
    }
    return out;
  }

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

  /// Tajweed colouring of a page (tools/build_tajweed.py), in the format of
  /// [edition]'s `tajweed_page` rows; empty when the page has none.
  Future<String> tajweedPage(MushafEdition edition, int page) async {
    final row = await _db
        .customSelect(
          'SELECT data FROM tajweed_page WHERE edition = ? AND page = ?',
          variables: [
            Variable.withString(edition.name),
            Variable.withInt(page),
          ],
        )
        .getSingleOrNull();
    return row?.read<String>('data') ?? '';
  }

  /// The Hafs tajweed letters of verses [from]..[to] of [surah]
  /// (`tajweed_letter`): (verse, word, letter, marks only, rule key).
  Future<List<(int, int, int, bool, String)>> tajweedLetters(
    int surah,
    int from,
    int to,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT ayah, word, letter, part, rule FROM tajweed_letter '
          "WHERE riwaya = 'hafs' AND surah = ? AND ayah BETWEEN ? AND ? "
          'ORDER BY ayah, word, letter',
          variables: [
            Variable.withInt(surah),
            Variable.withInt(from),
            Variable.withInt(to),
          ],
        )
        .get();
    return [
      for (final r in rows)
        (
          r.read<int>('ayah'),
          r.read<int>('word'),
          r.read<int>('letter'),
          r.read<String>('part') == 'marks',
          r.read<String>('rule'),
        ),
    ];
  }

  /// For each tajweed rule key of the Hafs data (`tajweed_letter`): the
  /// verses it falls in and the letters it colours.
  Future<Map<String, TajweedRuleCount>> tajweedRuleCounts() async {
    final rows = await _db
        .customSelect(
          'SELECT rule, COUNT(*) AS letters, '
          'COUNT(DISTINCT surah * 1000 + ayah) AS verses FROM tajweed_letter '
          "WHERE riwaya = 'hafs' GROUP BY rule",
        )
        .get();
    return {
      for (final r in rows)
        r.read<String>('rule'): (
          verses: r.read<int>('verses'),
          letters: r.read<int>('letters'),
        ),
    };
  }

  /// The verses the Hafs tajweed rule [ruleKey] falls in, in mushaf order,
  /// each with its letters of the rule, its text and its pages.
  Future<List<TajweedPlace>> tajweedPlaces(String ruleKey) async {
    final rows = await _db
        .customSelect(
          'SELECT t.surah AS surah, t.ayah AS ayah, a.display_text AS text, '
          'a.page AS p1441, a.page_1405 AS p1405, a.page_shamarly AS psh, '
          "group_concat(t.word || ':' || t.letter || ':' || t.part, ' ') "
          'AS letters '
          'FROM tajweed_letter t '
          'JOIN ayah a ON a.surah = t.surah AND a.number = t.ayah '
          "WHERE t.riwaya = 'hafs' AND t.rule = ? "
          'GROUP BY t.surah, t.ayah ORDER BY a.id',
          variables: [Variable.withString(ruleKey)],
        )
        .get();
    return [
      for (final r in rows)
        TajweedPlace(
          surah: r.read<int>('surah'),
          ayah: r.read<int>('ayah'),
          text: r.read<String>('text'),
          letters: TajweedPlace.parseLetters(r.read<String>('letters')),
          page1441: r.read<int>('p1441'),
          page1405: r.read<int>('p1405'),
          pageShamarly: r.read<int>('psh'),
        ),
    ];
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

  /// The entries of [sourceIds] for every verse of [surah], keyed by
  /// (source id, verse).
  Future<Map<(int, int), CommentaryRow>> commentaryOfSurah(
    int surah,
    List<int> sourceIds,
  ) async {
    if (sourceIds.isEmpty) return const {};
    final rows = await (_db.select(
      _db.commentary,
    )..where((t) => t.surah.equals(surah) & t.sourceId.isIn(sourceIds))).get();
    return {for (final r in rows) (r.sourceId, r.ayah): r};
  }

  /// Every entry of the given texts, for searching by meaning.
  Future<List<CommentaryRow>> commentaryOf(List<int> sourceIds) => (_db.select(
    _db.commentary,
  )..where((t) => t.sourceId.isIn(sourceIds))).get();

  Future<List<ReciterRow>> reciters() =>
      (_db.select(_db.reciter)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  /// Verse timings of one surah file, in order; empty when the source has
  /// none for this reciter or surah.
  Future<List<AyahTimingRow>> timings(int reciter, int surah) async {
    final pack = await _timing.packFor(reciter, surah);
    if (pack != null) return pack.ayahRows(surah);
    return (_db.select(_db.ayahTiming)
          ..where((t) => t.reciter.equals(reciter) & t.surah.equals(surah))
          ..orderBy([(t) => OrderingTerm.asc(t.ayah)]))
        .get();
  }

  /// Speech spans of one surah file's verses, in order.
  Future<List<AyahSpeechRow>> speech(int reciter, int surah) =>
      (_db.select(_db.ayahSpeech)
            ..where((t) => t.reciter.equals(reciter) & t.surah.equals(surah))
            ..orderBy([(t) => OrderingTerm.asc(t.ayah)]))
          .get();

  /// Word timings of one surah file, in order of time.
  Future<List<WordTimingRow>> wordTimings(int reciter, int surah) async {
    final pack = await _timing.packFor(reciter, surah);
    if (pack != null) return pack.wordRows(surah);
    return (_db.select(_db.wordTiming)
          ..where((t) => t.reciter.equals(reciter) & t.surah.equals(surah))
          ..orderBy([(t) => OrderingTerm.asc(t.startMs)]))
        .get();
  }

  /// The timing version content.db was built with for each reciter whose
  /// timings come from `data/timing` (`meta` keys `timing_version:<slug>`).
  /// Empty for a content.db built before those existed.
  Future<Map<String, int>> timingVersions() async {
    final rows = await _db
        .customSelect(
          "SELECT key, value FROM meta WHERE key LIKE 'timing_version:%'",
        )
        .get();
    return {
      for (final r in rows)
        r.read<String>('key').substring('timing_version:'.length):
            int.tryParse(r.read<String>('value')) ?? 0,
    };
  }

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
    MushafEdition.madina1405 => page1405,
    MushafEdition.shamarly => pageShamarly,
    // The riwaya editions' pages come from their packs
    // (`versePageProvider`); this falls back to the new Madina edition's.
    _ => page,
  };
}

extension EditionStartPages on SurahRow {
  int startPageIn(MushafEdition edition) => switch (edition) {
    MushafEdition.madina1405 => startPage1405,
    MushafEdition.shamarly => startPageShamarly,
    // Riwaya editions: `surahStartPageProvider`.
    _ => startPage,
  };
}

extension on MushafEdition {
  /// The `ayah` column holding the (start) page in this edition.
  String get pageColumn => switch (this) {
    MushafEdition.madina1405 => 'page_1405',
    MushafEdition.shamarly => 'page_shamarly',
    _ => 'page',
  };
}
