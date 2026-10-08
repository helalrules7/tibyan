import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/features/khatma/data/quran_index_loader.dart';
import 'package:tibyan/features/khatma/domain/quran_index.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';
import 'package:tibyan/features/mushaf/data/riwaya_data.dart';

/// Runs against the real bundled content.db: the weights, conversions and
/// boundaries the khatma engine stands on.
void main() {
  late ContentDatabase db;
  late QuranIndex index;

  setUpAll(() async {
    db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
    index = await loadQuranIndex(db);
  });
  tearDownAll(() => db.close());

  test('letters: no spaces, no basmala before the verse', () {
    expect(lettersOf('بسم الله الرحمن الرحيم الم', 23), 3);
    expect(lettersOf('بسم الله الرحمن الرحيم', 0), 19);
    expect(lettersOf('ذلك  الكتاب', 0), 9);
  });

  group('weights', () {
    test('the whole Quran weighs 604 Madina pages', () {
      expect(index.ayahCount, 6236);
      expect(index.totalWeight, closeTo(604, 1e-9));
    });

    test('every page of the 1441 edition weighs 1, the first two too', () {
      final pages = index.madina1441;
      expect(pages.textPages.length, 604);
      for (final p in pages.textPages) {
        final r = pages.ayahsOn(p)!;
        expect(index.weightOf(r.from, r.to), closeTo(1, 1e-9), reason: '$p');
      }
      expect(pages.weightOfPage(1, index), closeTo(1, 1e-9));
      expect(pages.weightOfPage(2, index), closeTo(1, 1e-9));
    });

    test('al-Kahf weighs about as many pages as it fills (293-304)', () {
      final from = index.idOf(18, 1);
      final to = index.idOf(18, 110);
      expect(index.madina1441.pageOf(from), 293);
      expect(index.madina1441.pageOf(to), 304);
      final w = index.weightOf(from, to);
      expect(w, greaterThan(11));
      expect(w, lessThan(12));
    });

    test('the weight offset finds the verse a page ends in', () {
      // Page 1 is al-Fatiha: one page from its first verse ends at 1:7.
      expect(index.ayahAtWeightOffset(1, 1), 7);
      expect(index.ayahAtWeightOffset(1, 0.0001), 1);
      // Twenty pages from the start end on the last verse of page 20.
      final end20 = index.madina1441.ayahsOn(20)!.to;
      expect(index.ayahAtWeightOffset(1, 20), end20);
      expect(index.ayahAtWeightOffset(6000, 1000), 6236);
    });
  });

  group('conversions', () {
    test('(surah, verse) and back, for every verse', () {
      for (var id = 1; id <= index.ayahCount; id++) {
        final k = index.keyOf(id);
        expect(index.idOf(k.surah, k.ayah), id);
      }
      expect(index.idOf(2, 255), 262);
      expect(index.ayahCountOf(2), 286);
      expect(() => index.idOf(1, 8), throwsRangeError);
    });

    test('juz, hizb and quarter, and their boundaries', () {
      expect(index.surahEnds.length, 114);
      expect(index.juzEnds.length, 30);
      expect(index.hizbEnds.length, 60);
      expect(index.quarterEnds.length, 240);
      expect(index.juzEnds.last, 6236);
      // Juz 2 begins at al-Baqarah 142.
      expect(index.juzEnds.first + 1, index.idOf(2, 142));
      expect(index.juzOf(index.idOf(2, 142)), 2);
      expect(index.hizbOf(index.idOf(2, 142)), 3);
      expect(index.quarterOf(6236), 240);
      // Each juz ends on a hizb end, each hizb on a quarter end.
      expect(index.hizbEnds.toSet().containsAll(index.juzEnds), isTrue);
      expect(index.quarterEnds.toSet().containsAll(index.hizbEnds), isTrue);
    });

    test('the start of each juz is on the page the index shows', () async {
      final repo = MushafRepository(db);
      for (final j in await repo.juzStarts()) {
        for (final e in [
          MushafEdition.madina1441,
          MushafEdition.madina1405,
          MushafEdition.shamarly,
        ]) {
          expect(index.hafsPages(e.name)!.pageOf(j.ayah.id), j.ayah.pageIn(e));
        }
      }
    });
  });

  group('editions', () {
    test('Shamarly: 522 pages, text from page 2, still 604 in weight', () {
      final s = index.shamarly;
      expect(s.firstPage, 2);
      expect(s.lastPage, 522);
      expect(s.textPages.length, 521);
      expect(index.weightOf(1, 6236), closeTo(604, 1e-9));
      // A verse running over a page is on both.
      final crossing = [
        for (var id = 1; id <= 6236; id++)
          if (s.pageOf(id) != s.lastPageOf(id)) id,
      ];
      expect(crossing.length, 368);
      final c = crossing.first;
      expect(s.ayahsOn(s.pageOf(c))!.to, greaterThanOrEqualTo(c));
      expect(s.ayahsOn(s.lastPageOf(c))!.from, c);
      // A page ends at the last verse ending on it.
      expect(s.pageEnds.contains(c), isFalse);
      expect(s.pageEnds.last, 6236);
    });

    test('a page boundary list per edition, in order', () {
      for (final e in [index.madina1441, index.madina1405, index.shamarly]) {
        final ends = e.pageEnds;
        for (var i = 1; i < ends.length; i++) {
          expect(ends[i], greaterThan(ends[i - 1]));
        }
        expect(ends.last, 6236);
      }
      expect(index.madina1441.pageEnds.length, 604);
    });

    test('pages of a stretch of verses, in another edition', () {
      // Page 42 of the 1441 edition (Ayat al-Kursi) in the Shamarly.
      final r = index.madina1441.ayahsOn(42)!;
      final pages = index.shamarly.pagesOf(r.from, r.to);
      expect(pages, contains(index.shamarly.pageOf(262)));
      expect(pages.length, lessThanOrEqualTo(2));
    });
  });

  group('riwaya pages from the pack (Warsh sample)', () {
    final data = RiwayaData.parse(
      File('test/fixtures/riwaya_warsh_sample.json').readAsStringSync(),
    );

    test('al-Fatiha: page 1 holds Hafs 1:1-7, the basmala included', () {
      final pages = riwayaPages('warsh', data, index);
      expect(pages.ayahsOn(1), (from: 1, to: 7));
      // Al-Baqarah starts on page 2.
      expect(pages.pageOf(index.idOf(2, 1)), 2);
      expect(pages.pageOf(index.idOf(11, 83)), data.pageOf(11, 82));
    });

    test('the repository finds the Hafs verses of a riwaya page', () async {
      final repo = MushafRepository(db);
      expect(await repo.ayahsOnPage(1, MushafEdition.warsh), isEmpty);
      final onPage = await repo.ayahsOnPage(1, MushafEdition.warsh, data);
      expect(onPage.map((a) => (a.surah, a.number)), [
        for (var a = 1; a <= 7; a++) (1, a),
      ]);
      final hud = await repo.ayahsOnPage(231, MushafEdition.warsh, data);
      expect(hud.map((a) => (a.surah, a.number)), contains((11, 83)));
    });
  });
}
