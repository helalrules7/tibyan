import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/tasmee/data/tasmee_words_repository.dart';
import 'package:tibyan/features/tasmee/domain/expected_words.dart';
import 'package:tibyan/features/tasmee/domain/recitation_range.dart';

VerseIndexEntry _v(int id, int surah, int ayah, {int page = 1}) =>
    VerseIndexEntry(
      id: id,
      surah: surah,
      ayah: ayah,
      juz: 1,
      hizbQuarter: 1,
      page: page,
    );

void main() {
  group('displayWords', () {
    test('drops the verse number and the hizb sign, keeps waqf signs', () {
      expect(
        displayWords(
          '۞\u00A0ذَٰلِكَ ٱلۡكِتَٰبُ لَا رَيۡبَۛ فِيهِۛ هُدٗى لِّلۡمُتَّقِينَ\u00A0ﰁ',
        ),
        [
          'ذَٰلِكَ',
          'ٱلۡكِتَٰبُ',
          'لَا',
          'رَيۡبَۛ',
          'فِيهِۛ',
          'هُدٗى',
          'لِّلۡمُتَّقِينَ',
        ],
      );
    });

    test('a verse number without a no-break space before it', () {
      expect(displayWords('ٱلۡقَوۡمِ ٱلۡكَٰفِرِينَ ﴝ'), [
        'ٱلۡقَوۡمِ',
        'ٱلۡكَٰفِرِينَ',
      ]);
    });
  });

  group('buildExpectedWords (fixtures)', () {
    final verses = [
      VerseSource(
        _v(1, 1, 1),
        'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ\u00A0ﰀ',
        const [1, 1, 1, 1],
      ),
      VerseSource(
        _v(2, 1, 2),
        'ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ\u00A0ﰁ',
        const [1, 1, 1, 1],
      ),
      VerseSource(_v(8, 2, 1, page: 2), 'الٓمٓ\u00A0ﰀ', const [2]),
      VerseSource(
        _v(9, 2, 2, page: 2),
        'ذَٰلِكَ ٱلۡكِتَٰبُ لَا رَيۡبَۛ فِيهِۛ هُدٗى لِّلۡمُتَّقِينَ\u00A0ﰁ',
        const [2, 2, 2, 2, 2, 3, 3],
      ),
    ];

    test('in order, numbered, with display text verbatim', () {
      final words = buildExpectedWords(
        const VerseRange(fromSurah: 1, fromAyah: 1, toSurah: 2, toAyah: 2),
        verses,
      );
      expect(words, hasLength(16));
      expect([for (final w in words) w.index], List.generate(16, (i) => i));
      expect(words.first.display, 'بِسۡمِ');
      expect(words.first.matching, 'بسم');
      expect(words[2].display, 'ٱلرَّحۡمَٰنِ');
      expect(words[2].matching, 'الرحمن');
      // The waqf sign stays in what is shown and is not in the key.
      expect(words[12].display, 'رَيۡبَۛ');
      expect(words[12].matching, 'ريب');
      expect(words.where((w) => w.isLastInVerse).map((w) => w.word), [
        4,
        4,
        1,
        7,
      ]);
    });

    test('al-Fatiha has no basmala before it: its verse 1 is the basmala', () {
      final words = buildExpectedWords(const SurahRange(1), verses);
      expect(words.any((w) => w.opensSurah), isFalse);
      final baqara = buildExpectedWords(const SurahRange(2), verses);
      expect(baqara.first.opensSurah, isTrue);
      expect(baqara.skip(1).any((w) => w.opensSurah), isFalse);
    });

    test('the opening letters may be heard by their names', () {
      final alm = buildExpectedWords(const SurahRange(2), verses).first;
      expect(alm.matching, 'الم');
      expect(alm.alternatives, ['الفلامميم']);
      expect(alm.keys, ['الم', 'الفلامميم']);
    });

    test('a page range cuts a verse word by word', () {
      final words = buildExpectedWords(const PageRange(3), verses);
      expect([for (final w in words) w.display], ['هُدٗى', 'لِّلۡمُتَّقِينَ']);
      expect(words.first.index, 0);
      expect(words.last.isLastInVerse, isTrue);
    });

    test('word pages that do not match the words are an error', () {
      expect(
        () => buildExpectedWords(const SurahRange(1), [
          VerseSource(_v(1, 1, 1), 'بِسۡمِ ٱللَّهِ\u00A0ﰀ', const [1]),
        ]),
        throwsStateError,
      );
    });
  });

  group('RecitationRange', () {
    test('the eight kinds', () {
      expect({
        const SurahRange(1).kind,
        const JuzRange(1).kind,
        const HizbPartRange.hizb(1).kind,
        HizbPartRange.quarter(1).kind,
        HizbPartRange.half(1, 1).kind,
        const HizbPartRange.threeQuarters(1).kind,
        const PageRange(1, 2).kind,
        const VerseRange(fromSurah: 1, fromAyah: 1, toSurah: 1, toAyah: 2).kind,
      }, RecitationRangeKind.values.toSet());
    });

    test('quarters of a hizb', () {
      final q = HizbPartRange.quarter(7);
      expect((q.hizb, q.fromQuarter, q.toQuarter), (2, 3, 3));
      expect((q.firstQuarter, q.lastQuarter), (7, 7));
      final half = HizbPartRange.half(2, 2);
      expect((half.firstQuarter, half.lastQuarter), (7, 8));
      const three = HizbPartRange.threeQuarters(2, fromSecond: true);
      expect((three.firstQuarter, three.lastQuarter), (6, 8));
      const hizb = HizbPartRange.hizb(60);
      expect((hizb.firstQuarter, hizb.lastQuarter), (237, 240));
    });

    test('ranges outside the mushaf are refused', () {
      for (final r in <RecitationRange>[
        const SurahRange(115),
        const JuzRange(0),
        const HizbPartRange.hizb(61),
        HizbPartRange.quarter(241),
        const PageRange(605),
        const PageRange(10, 9),
        const VerseRange(fromSurah: 2, fromAyah: 5, toSurah: 2, toAyah: 4),
      ]) {
        expect(r.validate, throwsRangeError, reason: '$r');
      }
    });
  });

  group('TasmeeWordsRepository on content.db', () {
    late ContentDatabase db;
    late TasmeeWordsRepository repo;
    setUpAll(() {
      db = ContentDatabase(
        NativeDatabase(
          File('assets/db/content.db'),
          setup: (raw) => raw.execute('PRAGMA query_only = ON'),
        ),
      );
      repo = TasmeeWordsRepository(db);
    });
    tearDownAll(() => db.close());

    Future<List<ExpectedWord>> words(RecitationRange r) =>
        repo.expectedWords(r);
    String first(List<ExpectedWord> w) =>
        '${w.first.surah}:${w.first.ayah}:${w.first.word}';
    String last(List<ExpectedWord> w) =>
        '${w.last.surah}:${w.last.ayah}:${w.last.word}';

    test('surah al-Fatiha: 29 words, the basmala first', () async {
      final w = await words(const SurahRange(1));
      expect(w, hasLength(29));
      expect(w.first.matching, 'بسم');
      expect(last(w), '1:7:9');
      expect(w.every((x) => x.page == 1), isTrue);
    });

    test('juz 30: from an-Naba 1 to an-Nas 6', () async {
      final w = await words(const JuzRange(30));
      expect(first(w), '78:1:1');
      expect(w.last.surah, 114);
      expect(w.last.ayah, 6);
      expect(w.last.isLastInVerse, isTrue);
      // Every surah but at-Tawbah opens with a basmala before it.
      expect(w.where((x) => x.opensSurah).length, 37);
    });

    test('hizb 1 and its quarters, halves and three quarters', () async {
      final hizb = await words(const HizbPartRange.hizb(1));
      final q2 = await words(HizbPartRange.quarter(2));
      final half2 = await words(HizbPartRange.half(1, 2));
      final three = await words(const HizbPartRange.threeQuarters(1));
      expect(first(hizb), '1:1:1');
      expect(last(hizb), '2:74:${hizb.last.word}');
      expect(first(q2), '2:26:1');
      expect(half2.first.ayah, isNot(26));
      expect(
        hizb.length,
        (await words(HizbPartRange.half(1, 1))).length + half2.length,
      );
      expect(
        three.length + (await words(HizbPartRange.quarter(4))).length,
        hizb.length,
      );
    });

    test(
      'a page range: pages 582 and 583 are an-Naba 1 to an-Naziat 16',
      () async {
        final w = await words(const PageRange(582, 583));
        expect(w, hasLength(224));
        expect(first(w), '78:1:1');
        expect(w.last.surah, 79);
        expect(w.last.ayah, 16);
        expect(w.every((x) => x.page == 582 || x.page == 583), isTrue);
      },
    );

    test('a verse range across surahs', () async {
      final w = await words(
        const VerseRange(fromSurah: 1, fromAyah: 7, toSurah: 2, toAyah: 2),
      );
      expect(first(w), '1:7:1');
      expect(last(w), '2:2:7');
      expect(w.firstWhere((x) => x.surah == 2).alternatives, ['الفلامميم']);
      expect(w.firstWhere((x) => x.surah == 2).opensSurah, isTrue);
    });

    test('a verse that does not exist is refused', () async {
      await expectLater(
        words(
          const VerseRange(fromSurah: 1, fromAyah: 1, toSurah: 1, toAyah: 8),
        ),
        throwsRangeError,
      );
    });

    test('every verse of the Quran has a word page for each word', () async {
      final w = await words(
        const VerseRange(fromSurah: 1, fromAyah: 1, toSurah: 114, toAyah: 6),
      );
      expect(w, hasLength(77430));
      expect(w.every((x) => x.matching.isNotEmpty), isTrue);
    });
  });
}
