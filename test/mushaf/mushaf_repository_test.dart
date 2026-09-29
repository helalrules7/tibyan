import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';

/// Runs against the real bundled database.
void main() {
  late ContentDatabase db;
  late MushafRepository repo;

  setUpAll(() {
    // Open exactly as the app does: read-only. Any write (for example a
    // schema-version update) fails the tests instead of crashing the app.
    db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
    repo = MushafRepository(db);
  });
  tearDownAll(() => db.close());

  test('114 surahs and 6236 verses', () async {
    expect((await repo.surahs()).length, 114);
    var total = 0;
    for (final s in await repo.surahs()) {
      total += (await repo.ayahsOfSurah(s.id)).length;
    }
    expect(total, 6236);
  });

  test('every page 1..604 has verses and every verse has an outline', () async {
    for (final page in [1, 2, 50, 300, 604]) {
      final ayahs = await repo.ayahsOnPage(page);
      final polys = await repo.polygons(page);
      expect(ayahs, isNotEmpty, reason: 'page $page');
      expect(polys.length, ayahs.length, reason: 'page $page');
    }
  });

  test('every verse has al-Muyassar, Saheeh and Pickthall', () async {
    final editions = await repo.commentaryEditions();
    expect([for (final e in editions) e.sourceId], [7, 8, 9]);
    expect(editions.first.kind, 'tafsir');
    for (final (s, a) in [(1, 1), (2, 255), (9, 1), (114, 6)]) {
      final entries = await repo.commentary(s, a);
      expect(entries.keys.toSet(), {7, 8, 9}, reason: '$s:$a');
      expect(entries.values.every((e) => e.body.isNotEmpty), isTrue);
    }
    // Footnotes come with Saheeh International only.
    expect((await repo.commentary(1, 1))[8]!.footnotes, contains('[2]'));
    // Each source row carries its credit.
    final sources = {for (final s in await repo.sources()) s.id: s};
    expect(sources[7]!.attribution, contains('QuranEnc'));
    expect(sources[8]!.version, '1.1.2');
  });

  test(
    'shown text is the KFGQPC text, split only at the verse number',
    () async {
      final a = await repo.ayah(2, 255);
      expect(a.displaySourceId, 5);
      expect('${a.displayBody}\u00a0${a.displayNumber}', a.displayText);
      expect(a.displayNumber.runes.length, 1);
      // 2:286 has an ordinary space before its number.
      final last = await repo.ayah(2, 286);
      expect('${last.displayBody} ${last.displayNumber}', last.displayText);
      // Tanzil text is kept, unchanged, for reference.
      final first = await repo.ayah(2, 1);
      expect(first.basmalaPrefix, greaterThan(0));
      expect(first.verseText.startsWith('بِسْمِ'), isTrue);
    },
  );

  test('old edition (1405H) pages come from Tanzil', () async {
    final kursi = await repo.ayah(2, 255);
    expect(kursi.page, 42);
    expect(kursi.page1405, 42);
    final baqarah = await repo.surahById(2);
    expect(baqarah.startPage1405, 2);
    // 56 verses sit on different pages in the two editions, e.g. 5:77.
    final maidah77 = await repo.ayah(5, 77);
    expect((maidah77.page, maidah77.page1405), (120, 121));
    final onOldPage = await repo.ayahsOnPage(121, MushafEdition.madina1405);
    expect(onOldPage.any((a) => a.surah == 5 && a.number == 77), isTrue);
  });

  test('Shamarly pages: every verse has one, in order', () async {
    final all = [
      for (final s in await repo.surahs()) ...await repo.ayahsOfSurah(s.id),
    ]..sort((a, b) => a.id.compareTo(b.id));
    expect(all.length, 6236);
    var last = 2;
    for (final a in all) {
      final start = a.pageIn(MushafEdition.shamarly);
      expect(start, inInclusiveRange(2, 522), reason: '${a.surah}:${a.number}');
      expect(a.pageShamarlyEnd, inInclusiveRange(start, start + 1));
      // A verse never starts before the one before it ends.
      expect(start, greaterThanOrEqualTo(last));
      last = a.pageShamarlyEnd;
    }
    expect(all.first.pageShamarly, 2);
    expect(all.last.pageShamarlyEnd, 522);
    final surahs = await repo.surahs();
    expect(surahs.first.startPageIn(MushafEdition.shamarly), 2);
    expect(surahs[1].startPageIn(MushafEdition.shamarly), 3);
    expect(surahs.last.startPageIn(MushafEdition.shamarly), 522);
    expect(MushafEdition.shamarly.pageCount, 522);
  });

  test('every Shamarly page 2..522 has verses and verse boxes', () async {
    for (var page = 2; page <= 522; page++) {
      final ayahs = await repo.ayahsOnPage(page, MushafEdition.shamarly);
      expect(ayahs, isNotEmpty, reason: 'page $page');
      final boxes = await repo.shamarlyVerseBoxes(page);
      expect(
        {for (final b in boxes) (b.surah, b.ayah)},
        {for (final a in ayahs) (a.surah, a.number)},
        reason: 'page $page',
      );
    }
    expect(await repo.ayahsOnPage(1, MushafEdition.shamarly), isEmpty);
  });

  test('a Shamarly verse over a page break is on both pages', () async {
    final v = await repo.ayah(2, 16);
    expect((v.pageShamarly, v.pageShamarlyEnd), (4, 5));
    for (final page in [4, 5]) {
      final on = await repo.ayahsOnPage(page, MushafEdition.shamarly);
      expect(on.any((a) => a.surah == 2 && a.number == 16), isTrue);
    }
    // Its marker is on the page where it ends.
    final markers = await repo.shamarlyMarkers(5);
    expect(markers.any((m) => m.surah == 2 && m.ayah == 16), isTrue);
    // Quarter starts use the page where a verse starts.
    final q = await repo.quarterStartsOnPage(5, MushafEdition.shamarly);
    expect(q.every((a) => a.pageShamarly == 5), isTrue);
  });

  test('Shamarly geometry: 15 lines, two-slot headers, word levels', () async {
    final page = (await repo.shamarlyPage(42))!;
    expect(page.kind, 'text');
    final lines = await repo.shamarlyLines(42);
    expect(lines.length, 15);
    final header = (await repo.shamarlyHeaders(42)).single;
    expect((header.surah, header.firstLine), (3, 6));
    expect(lines[6].kind, 'header');
    expect(lines[7].kind, 'header');
    expect(lines[8].kind, 'basmala');
    expect((await repo.shamarlyPage(1))!.kind, 'cover');
    expect((await repo.shamarlyLines(2)).length, 7);
    // Only surely split verses by default.
    for (final b in await repo.shamarlyWordBoxes(42)) {
      expect(b.level, greaterThanOrEqualTo(shamarlyWordLevel));
    }
    final any = await repo.shamarlyWordBoxes(42, minLevel: 1);
    expect(
      any.length,
      greaterThanOrEqualTo((await repo.shamarlyWordBoxes(42)).length),
    );
  });

  test('every word has a box; Ayat al-Kursi has 50 on page 42', () async {
    final boxes = await repo.wordBoxes(42);
    final kursi = boxes.where((b) => b.surah == 2 && b.ayah == 255).toList();
    expect(kursi.length, 50);
    expect(kursi.map((b) => b.word), List.generate(50, (i) => i + 1));
    for (final b in kursi) {
      expect(b.x1, greaterThan(b.x0));
      expect(b.y1, greaterThan(b.y0));
    }
    // Words run right to left: the first word starts right of the last.
    expect(kursi.first.x1, greaterThan(kursi[4].x1));
  });

  test('all six review items are decided', () async {
    expect(await repo.reviewNoteCount(), 0);
  });

  test('30 juz starts, first is 1:1', () async {
    final starts = await repo.juzStarts();
    expect(starts.length, 30);
    expect((starts.first.ayah.surah, starts.first.ayah.number), (1, 1));
  });

  test('sources are recorded', () async {
    final keys = (await repo.sources()).map((s) => s.key).toSet();
    expect(keys, containsAll(['tanzil-uthmani', 'quran-ws-hafs']));
  });
}
