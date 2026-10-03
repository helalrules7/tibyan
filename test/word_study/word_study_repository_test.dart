import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';
import 'package:tibyan/features/word_study/data/word_study_repository.dart';

/// Runs against the real bundled database.
void main() {
  late ContentDatabase db;
  late WordStudyRepository repo;
  late MushafRepository mushaf;

  setUpAll(() {
    db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
    repo = WordStudyRepository(db);
    mushaf = MushafRepository(db);
  });
  tearDownAll(() => db.close());

  Future<int> count(String sql) async =>
      (await db.customSelect(sql).getSingle()).read<int>('n');

  group('corpus mapping', () {
    test('every verse but 7 is mapped; words match our numbering', () async {
      // 6,229 verses agree in word count; 20 of them are only disjoined
      // letters (الٓمٓ ...), which carry no root or lemma.
      expect(
        await count(
          'SELECT COUNT(DISTINCT surah * 1000 + ayah) AS n FROM word_root',
        ),
        6209,
      );
      expect(await count('SELECT COUNT(*) AS n FROM word_root'), 74052);
      expect(
        await count(
          'SELECT COUNT(*) AS n FROM word_root WHERE root IS NOT NULL',
        ),
        49926,
      );
      // Every row points at a word the page view can draw.
      expect(
        await count(
          'SELECT COUNT(*) AS n FROM word_root w LEFT JOIN word_box b '
          'USING (surah, ayah, word) WHERE b.page IS NULL',
        ),
        0,
      );
      // Verses whose word count differs from the corpus get no rows.
      for (final (s, a) in [(2, 181), (15, 7), (37, 130)]) {
        expect(await repo.wordRoot(s, a, 1), isNull, reason: '$s:$a');
      }
    });

    test('known roots', () async {
      // بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ
      expect((await repo.wordRoot(1, 1, 1))!.root, 'س م و');
      expect((await repo.wordRoot(1, 1, 2))!.root, 'أ ل ه');
      final rahman = (await repo.wordRoot(1, 1, 3))!;
      expect(rahman.root, 'ر ح م');
      // r~aHoma`n in the corpus's transliteration, letter for letter.
      expect(
        rahman.lemma,
        '\u0631\u0651\u064e\u062d\u0652\u0645\u064e\u0670\u0646',
      );
      expect((await repo.wordRoot(1, 1, 4))!.root, 'ر ح م');
      // ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ
      expect((await repo.wordRoot(1, 2, 1))!.root, 'ح م د');
      expect((await repo.wordRoot(1, 2, 3))!.root, 'ر ب ب');
      expect((await repo.wordRoot(1, 2, 4))!.root, 'ع ل م');
      // ذَٰلِكَ ٱلۡكِتَٰبُ
      expect((await repo.wordRoot(2, 2, 2))!.root, 'ك ت ب');
      // قُلۡ هُوَ ٱللَّهُ أَحَدٌ
      expect((await repo.wordRoot(112, 1, 1))!.root, 'ق و ل');
      expect((await repo.wordRoot(112, 1, 4))!.root, 'أ ح د');
      // A pronoun has neither root nor lemma in the corpus: no row.
      expect(await repo.wordRoot(112, 1, 2), isNull);
      // A preposition has a lemma but no root (عَلَيۡهِمۡ in 1:7).
      final alayhim = (await repo.wordRoot(1, 7, 4))!;
      expect(alayhim.root, isNull);
      expect(alayhim.pos, 'P');
      expect(alayhim.lemma, isNotNull);
    });

    test('verseWords numbers words as the word boxes do', () async {
      for (final (s, a) in [(1, 1), (2, 282), (18, 18), (114, 6)]) {
        final row = await mushaf.ayah(s, a);
        final boxes = await count(
          'SELECT COUNT(*) AS n FROM word_box WHERE surah = $s AND ayah = $a',
        );
        expect(verseWords(row).length, boxes, reason: '$s:$a');
      }
      // 2:283 begins with the hizb sign, which is not a word.
      expect(bare(verseWords(await mushaf.ayah(2, 283)).first), 'وإن');
    });
  });

  group('al-Muyassar fi Gharib', () {
    test('entries are verbatim and tied to words where certain', () async {
      expect(await count('SELECT COUNT(*) AS n FROM gharib'), 11362);
      expect(
        await count('SELECT COUNT(*) AS n FROM gharib WHERE word_from IS NULL'),
        129,
      );
      final fatiha = await repo.gharibOfVerse(1, 1);
      expect(bare(fatiha.first.phrase), 'بسم ٱلله');
      expect(bare(fatiha.first.body), 'أبتدئ القراءة مستعينا بالله.');
      expect((fatiha.first.wordFrom, fatiha.first.wordTo), (1, 2));
      final rahman = meaningsOfWord(fatiha, 3);
      expect([for (final g in rahman) bare(g.phrase)], ['ٱلرحمن']);
      expect(meaningsOfWord(fatiha, 2).single, fatiha.first);
      // A quote without the joined wa: وَٱلۡفُرۡقَانَ in 2:53.
      final furqan = (await repo.gharibOfVerse(
        2,
        53,
      )).firstWhere((g) => bare(g.phrase) == 'ٱلفرقان');
      final words = verseWords(await mushaf.ayah(2, 53));
      expect(bare(words[furqan.wordFrom! - 1]), 'وٱلفرقان');
    });

    test('words the verse repeats stay on the verse', () async {
      // كُرۡهٗا occurs twice in 46:15.
      final entry = (await repo.gharibOfVerse(
        46,
        15,
      )).firstWhere((g) => bare(g.phrase) == 'كرها');
      expect(entry.wordFrom, isNull);
      expect(meaningsOfWord([entry], 5), isEmpty);
    });
  });

  test('root occurrences list every mapped verse in order', () async {
    final found = await repo.rootOccurrences('ر ح م');
    expect(found.verses.first.ayah.surah, 1);
    expect(found.verses.first.words, [3, 4]);
    // The corpus counts 339 words of this root; all fall in mapped verses.
    expect(found.wordCount, 339);
    final ids = [for (final v in found.verses) v.ayah.id];
    expect(ids, [...ids]..sort());
    expect(
      found.wordCount,
      found.verses.fold<int>(0, (n, v) => n + v.words.length),
    );
  });

  test('both sources carry their credit', () async {
    final sources = {for (final s in await mushaf.sources()) s.key: s};
    final corpus = sources['quranic-corpus']!;
    expect(corpus.version, '0.4');
    expect(corpus.attribution, contains('corpus.quran.com'));
    expect(corpus.notice, contains('CHANGING IT IS NOT ALLOWED'));
    final gharib = sources['nuqayah-almuyassar-gharib']!;
    expect(gharib.title, 'الميسر في غريب القرآن');
    expect(gharib.attribution, contains('نقاية'));
  });
}

/// Letters only: the marks (harakat, tanween, small signs) dropped, so the
/// tests do not depend on the order in which marks are stored.
String bare(String s) => s.replaceAll(
  RegExp('[\u064B-\u065F\u0670\u06D6-\u06ED\u08F0-\u08FF\u0640]'),
  '',
);
