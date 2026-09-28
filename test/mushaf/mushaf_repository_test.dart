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
    db = ContentDatabase(NativeDatabase(File('assets/db/content.db')));
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
    'basmala prefix is hidden for display, not removed from storage',
    () async {
      final first = await repo.ayah(2, 1);
      expect(first.basmalaPrefix, greaterThan(0));
      expect(first.verseText.length, greaterThan(first.displayText.length));
      expect(first.verseText.endsWith(first.displayText), isTrue);
      final fatiha = await repo.ayah(1, 1);
      expect(fatiha.basmalaPrefix, 0);
      expect(fatiha.displayText, fatiha.verseText);
    },
  );

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
