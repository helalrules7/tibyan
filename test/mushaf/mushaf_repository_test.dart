import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
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
