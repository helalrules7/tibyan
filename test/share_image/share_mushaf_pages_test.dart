import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';
import 'package:tibyan/features/share_image/share_document.dart';
import 'package:tibyan/features/share_image/share_layout.dart';
import 'package:tibyan/features/share_image/share_source.dart';
import 'package:tibyan/features/share_image/share_text_runs.dart';

/// A passage on several pictures is split as the new Madina mushaf (1441H):
/// one picture a page, one line a line of the page, its words exactly.
void main() {
  late ContentDatabase db;
  late MushafRepository repo;
  late List<SurahRow> surahs;
  setUpAll(() async {
    db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
    repo = MushafRepository(db);
    surahs = await repo.surahs();
    // The verses' own font, so that the widths are the real ones.
    final font = File('assets/fonts/kfgqpc/uthmanic_hafs_v20.ttf');
    await (FontLoader('UthmanicHafs')
          ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync()))))
        .load();
  });
  tearDownAll(() => db.close());

  Future<Map<(int, int, int), MushafPlace>> hafsPassageMushaf(int s, int a) =>
      hafsMushafPlaces(repo, [(surah: s, ayah: a)]);

  ShareRange verses(int s, int a, int b) => [
    for (var i = a; i <= b; i++) (surah: s, ayah: i),
  ];
  ShareRange surah(int s) => verses(s, 1, surahs[s - 1].ayahCount);

  /// The words of [surah] on each line of the mushaf's pages, from the word
  /// boxes and line cuts, read here on their own: by page, then line.
  Future<Map<int, Map<int, List<(int, int)>>>> mushafLines(
    int surah,
    int from,
    int to,
  ) async {
    final rows = await repo.wordBoxesOfVerses(surah, from, to);
    final pages = rows.map((r) => r.page).toSet();
    final out = <int, Map<int, List<(int, int)>>>{};
    for (final page in pages) {
      final cuts = await repo.lineCuts('madina1441', page);
      for (final r in rows.where((r) => r.page == page)) {
        final y = (r.y0 + r.y1) / 20;
        final line = cuts.where((c) => c < y).length;
        ((out[page] ??= {})[line] ??= []).add((r.ayah, r.word));
      }
    }
    return out;
  }

  /// Each picture's lines as (verse, word) of their first and last words.
  List<List<((int, int), (int, int))>> pictureLines(SharePassage p) {
    final tokens = tokenize(p.verses);
    final firstWords = tokenFirstWords(tokens);
    final pages = paginateByMushaf(
      tokens: tokens,
      verses: p.verses,
      placeOf: (s, a, w) => p.mushaf![(s, a, w)],
    )!;
    (int, int) wordAt(int i, {required bool last}) {
      final t = tokens[i];
      final n = wordsInToken(t.text, endsVerse: t.endsVerse);
      return (p.verses[t.verse].ayah, firstWords[i] + (last ? n - 1 : 0));
    }

    return [
      for (final page in pages)
        [
          for (final l in page.lines)
            (wordAt(l.from, last: false), wordAt(l.to - 1, last: true)),
        ],
    ];
  }

  test('an-Nisa\' is thirty pictures, pages 77 to 106, line by line', () async {
    final p = await hafsPassage(repo: repo, range: surah(4), surahs: surahs);
    final pictures = pictureLines(p);
    expect(pictures, hasLength(30));
    final lines = await mushafLines(4, 1, 176);
    expect(lines.keys.toList()..sort(), [for (var i = 77; i <= 106; i++) i]);
    for (var i = 0; i < 30; i++) {
      final page = lines[77 + i]!;
      final expected = [
        for (final l in page.keys.toList()..sort())
          (page[l]!.first, page[l]!.last),
      ];
      expect(pictures[i], expected, reason: 'page ${77 + i}');
    }
    // The first page, as printed: under the surah's header and basmala,
    // thirteen lines; 4:1 on lines 3 to 5, «وَٱلۡأَرۡحَامَ» opening line 5.
    expect(pictures.first, hasLength(13));
    expect(pictures.first[0], ((1, 1), (1, 11)));
    expect(pictures.first[1], ((1, 12), (1, 22)));
    expect(pictures.first[2], ((1, 23), (2, 5)));
    expect(pictures.first[6], ((3, 25), (4, 6)));
    // The last page holds 4:176 on its first five lines.
    expect(pictures.last.first.$1, (176, 1));
    expect(pictures.last, hasLength(5));
  });

  ShareDocument build(SharePassage p) => ShareDocument.build(p);

  /// The pictures' texts joined are the passage's verses joined: nothing
  /// is dropped, doubled or changed.
  void expectWholeText(ShareDocument doc, SharePassage p) {
    expect(
      [for (var i = 0; i < doc.pageCount; i++) doc.textOf(i)].join(' '),
      p.verses.map((v) => v.text).join(' '),
    );
  }

  test('an-Nisa\' on pictures: one size, every line fits', () async {
    final p = await hafsPassage(repo: repo, range: surah(4), surahs: surahs);
    final doc = build(p);
    addTearDown(doc.dispose);
    expect(doc.byMushaf, isTrue);
    expect(doc.pageCount, 30);
    expectWholeText(doc, p);
    expect(doc.widestLine, lessThanOrEqualTo(ShareDocument.textWidth));
    expect(doc.fontSize, lessThanOrEqualTo(ShareDocument.fontSizes.first));
    for (var i = 0; i < doc.pageCount; i++) {
      expect(doc.sizeOf(i), ShareDocument.size);
    }
    // The basmala on the first picture only.
    expect(doc.pages.first.firstOfSurah, isTrue);
    expect(doc.pages.skip(1).where((x) => x.firstOfSurah), isEmpty);
  });

  test(
    'al-Kahf: pages 293 to 304, its first page from its own lines',
    () async {
      final p = await hafsPassage(repo: repo, range: surah(18), surahs: surahs);
      final pictures = pictureLines(p);
      expect(pictures, hasLength(12));
      final lines = await mushafLines(18, 1, 110);
      expect(lines.keys.toList()..sort(), [for (var i = 293; i <= 304; i++) i]);
      for (var i = 0; i < 12; i++) {
        final page = lines[293 + i]!;
        expect(pictures[i], [
          for (final l in page.keys.toList()..sort())
            (page[l]!.first, page[l]!.last),
        ]);
      }
      // Al-Kahf opens on line 12 of page 293 (the KFGQPC Hafs data): only
      // its own four lines are on the first picture, none of al-Isra's.
      expect(pictures.first, hasLength(4));
      expect(pictures.first.first.$1, (1, 1));
      expectWholeText(build(p)..dispose(), p);
    },
  );

  test('al-Baqarah 282-286: page 48 whole, then page 49', () async {
    final p = await hafsPassage(
      repo: repo,
      range: verses(2, 282, 286),
      surahs: surahs,
    );
    final pictures = pictureLines(p);
    expect(pictures, hasLength(2));
    // 2:282 fills page 48, its fifteen lines; 283-286 fill page 49.
    expect(pictures[0], hasLength(15));
    expect(pictures[0].first.$1, (282, 1));
    expect(pictures[0].last.$2.$1, 282);
    expect(pictures[1], hasLength(15));
    expect(pictures[1].first.$1, (283, 1));
    expect(pictures[1].last.$2.$1, 286);
    final doc = build(p);
    addTearDown(doc.dispose);
    expect(doc.pageCount, 2);
    expectWholeText(doc, p);
    expect(doc.widestLine, lessThanOrEqualTo(ShareDocument.textWidth));
  });

  test('a selection over two pages: only its own lines of each', () async {
    // 4:11 is on lines 8-15 of page 78, 4:12 on lines 1-11 of page 79.
    final p = await hafsPassage(
      repo: repo,
      range: verses(4, 11, 12),
      surahs: surahs,
    );
    final pictures = pictureLines(p);
    expect(pictures.map((x) => x.length), [8, 11]);
    expect(pictures[0].first.$1, (11, 1));
    expect(pictures[1].first.$1, (12, 1));
    final lines = await mushafLines(4, 11, 12);
    expect(pictures[0], [
      for (final l in lines[78]!.keys.toList()..sort())
        (lines[78]![l]!.first, lines[78]![l]!.last),
    ]);
    final doc = build(p);
    addTearDown(doc.dispose);
    expect(doc.byMushaf, isTrue);
    expectWholeText(doc, p);
  });

  test('a verse that runs over a page runs over to the next picture', () {
    // Every page of the 1441 mushaf ends at a verse end; a mushaf whose
    // pages do not (here, made up): verse 2 runs from page 5 onto page 6.
    final vs = [
      const ShareVerse(surah: 3, ayah: 1, text: 'a b ﰀ'),
      const ShareVerse(surah: 3, ayah: 2, text: 'c d e f ﰁ'),
    ];
    final tokens = tokenize(vs);
    final pages = paginateByMushaf(
      tokens: tokens,
      verses: vs,
      placeOf: (s, a, w) => switch ((a, w)) {
        (1, _) => (page: 5, line: 13),
        (2, 1) => (page: 5, line: 14),
        (2, 2) => (page: 5, line: 14),
        _ => (page: 6, line: 0),
      },
    )!;
    expect(pages, hasLength(2));
    expect(
      pages[0].lines.map((l) => joinTokens(tokens.sublist(l.from, l.to))),
      ['a b ﰀ', 'c d'],
    );
    expect(
      pages[1].lines.map((l) => joinTokens(tokens.sublist(l.from, l.to))),
      ['e f ﰁ'],
    );
    expect(pages[1].firstOfSurah, isFalse);
  });

  test('a place missing: no mushaf split', () {
    final vs = [const ShareVerse(surah: 3, ayah: 1, text: 'a b ﰀ')];
    expect(
      paginateByMushaf(
        tokens: tokenize(vs),
        verses: vs,
        placeOf: (s, a, w) => w == 1 ? (page: 5, line: 1) : null,
      ),
      isNull,
    );
  });

  group('a passage on one picture keeps its flowed lines', () {
    test('ayat al-Kursi', () async {
      final p = await hafsPassage(
        repo: repo,
        range: verses(2, 255, 255),
        surahs: surahs,
      );
      final doc = build(p);
      addTearDown(doc.dispose);
      expect(doc.byMushaf, isFalse);
      expect(doc.pageCount, 1);
      expect(ShareDocument.fontSizes, contains(doc.fontSize));
      expect(doc.sizeOf(0).height, lessThan(ShareDocument.height));
    });

    test('al-Baqarah 5-6, over pages 2 and 3, is still one picture', () async {
      final p = await hafsPassage(
        repo: repo,
        range: verses(2, 5, 6),
        surahs: surahs,
      );
      final doc = build(p);
      addTearDown(doc.dispose);
      expect(doc.byMushaf, isFalse);
      expect(doc.pageCount, 1);
    });
  });

  group('word places', () {
    MushafWordBox box(int word, double l, double t, double r, double b) => (
      surah: 2,
      ayah: 1,
      word: word,
      page: 10,
      left: l,
      top: t,
      right: r,
      bottom: b,
    );

    test('a box taller than a line goes with its neighbours', () {
      // Lines cut at 50 and 100. Word 2 reaches from line 0 into line 1
      // (a mark of the line below joined to it), its middle on line 1; it
      // stands left of word 1, so it ends line 0.
      final places = mushafPlaces(
        [
          box(1, 200, 10, 300, 40),
          box(2, 20, 15, 150, 90),
          box(3, 200, 60, 300, 90),
        ],
        cuts: (_) => const [50.0, 100.0],
        pitch: 50,
      );
      expect(places[(2, 1, 1)], (page: 10, line: 0));
      expect(places[(2, 1, 2)], (page: 10, line: 0));
      expect(places[(2, 1, 3)], (page: 10, line: 1));
    });

    test('pages without cuts: rows of box middles', () {
      final places = mushafPlaces(
        [
          box(1, 200, 10, 300, 40),
          box(2, 20, 12, 150, 44),
          box(3, 200, 60, 300, 90),
        ],
        cuts: (_) => const [],
        pitch: 35,
      );
      expect(places[(2, 1, 1)]!.line, places[(2, 1, 2)]!.line);
      expect(places[(2, 1, 3)]!.line, places[(2, 1, 1)]!.line + 1);
    });

    test('the tall words of the 1441 pages', () async {
      // 6:97 word 6 (page 140) reaches over three lines: it ends the line
      // of the word before it.
      final places = await hafsPassageMushaf(6, 97);
      expect(places[(6, 97, 6)]!.line, places[(6, 97, 5)]!.line);
      expect(places[(6, 97, 7)]!.line, places[(6, 97, 6)]!.line + 1);
    });
  });
}
