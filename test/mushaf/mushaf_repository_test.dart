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
