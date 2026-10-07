import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show OpenMode, sqlite3;
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/tasmee/data/tasmee_words_repository.dart';
import 'package:tibyan/features/tasmee/domain/alignment_engine.dart';
import 'package:tibyan/features/tasmee/domain/expected_words.dart';
import 'package:tibyan/features/tasmee/domain/recitation_range.dart';
import 'package:tibyan/features/tasmee/domain/transcript_stabilizer.dart';
import 'package:tibyan/features/tasmee/domain/word_match.dart';

void main() {
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

  group('word match', () {
    test('edit distance and similarity', () {
      expect(editDistance('كتاب', 'كتاب'), 0);
      expect(editDistance('يعلمون', 'تعلمون'), 1);
      expect(editDistance('', 'من'), 2);
      expect(editDistance('الرحمن', 'الرحيم'), 2);
      expect(wordSimilarity('يعلمون', 'تعلمون'), closeTo(5 / 6, 1e-9));
      expect(wordSimilarity('من', 'في'), 0);
    });

    test('the three presets', () {
      bool ok(MatchStrictness m, String a, String b) =>
          wordSimilarity(a, b) >= m.threshold;
      expect(ok(MatchStrictness.strict, 'القيوم', 'القيون'), isFalse);
      expect(ok(MatchStrictness.medium, 'القيوم', 'القيون'), isTrue);
      // Short words must be exact unless lenient.
      expect(ok(MatchStrictness.medium, 'قال', 'قل'), isFalse);
      expect(ok(MatchStrictness.lenient, 'قال', 'قل'), isTrue);
      expect(ok(MatchStrictness.lenient, 'من', 'في'), isFalse);
    });
  });

  group('TasmeeEngine', () {
    test('a word read as written is settled the moment it is heard', () async {
      final words = await repo.expectedWords(const SurahRange(112));
      final engine = TasmeeEngine(words);
      expect(
        engine.addWords(['بسم', 'الله']),
        everyElement(isA<IgnoredWord>()),
      );
      final events = engine.addWords(['قل']);
      expect(events.whereType<WordSettled>().single.index, 0);
      expect(engine.statusOf(0), WordStatus.correct);
      expect(engine.cursor, 1);
    });

    test('an error waits for the next word to confirm it', () async {
      final words = await repo.expectedWords(
        const VerseRange(fromSurah: 2, fromAyah: 2, toSurah: 2, toAyah: 2),
      );
      final engine = TasmeeEngine(words);
      engine.addWords(['ذلك الكتاب لا شك']);
      expect(engine.statusOf(3), WordStatus.hidden);
      expect(engine.pending, 1);
      engine.addWords(['فيه']);
      expect(engine.statusOf(3), WordStatus.wrong);
      expect(engine.heardFor(3), 'شك');
      expect(engine.statusOf(4), WordStatus.correct);
    });

    test('finish settles what is still unsure', () async {
      final words = await repo.expectedWords(
        const VerseRange(fromSurah: 2, fromAyah: 2, toSurah: 2, toAyah: 2),
      );
      final engine = TasmeeEngine(words);
      engine.addWords(['ذلك الكتاب لا شك']);
      final events = engine.finish();
      expect(events.whereType<WordSettled>().single.status, WordStatus.wrong);
      expect(engine.pending, 0);
      expect(engine.statusOf(4), WordStatus.hidden);
    });

    test('too many unsure words: the first is settled anyway', () async {
      final words = await repo.expectedWords(const SurahRange(1));
      final engine = TasmeeEngine(words);
      engine.addWords(['بسم الله الرحمن الرحيم']);
      engine.addWords(['واحد اثنان ثلاثة اربعة خمسة ستة سبعة']);
      expect(engine.pending, lessThanOrEqualTo(6));
      expect(
        engine.statuses.where((s) => s.isError).length +
            engine.extraWords.length,
        greaterThan(0),
      );
    });

    test('words heard after the last expected word are extra', () async {
      final words = await repo.expectedWords(
        const VerseRange(fromSurah: 1, fromAyah: 4, toSurah: 1, toAyah: 4),
      );
      final engine = TasmeeEngine(words);
      engine.addWords(['مالك يوم الدين صدق الله العظيم']);
      engine.finish();
      expect(engine.isComplete, isTrue);
      expect(engine.statuses, everyElement(WordStatus.correct));
      expect(engine.extraWords.map((e) => e.heard), ['صدق', 'الله', 'العظيم']);
    });

    test('verse scores', () async {
      final words = await repo.expectedWords(const SurahRange(1));
      final engine = TasmeeEngine(words);
      engine.addWords([
        'بسم الله الرحمن الرحيم الحمد لله رب العالمين الرحمن الرحيم',
        'ملك يوم الدين اياك نعبد',
      ]);
      engine.finish();
      final scores = {
        for (final s in engine.verseScores) '${s.surah}:${s.ayah}': s,
      };
      expect(scores['1:2']!.accuracy, 1);
      expect(scores['1:4']!.wrong, 1);
      expect(scores['1:4']!.accuracy, closeTo(2 / 3, 1e-9));
      expect(scores.containsKey('1:6'), isFalse);
    });

    test('a long range read cleanly, word by word, quickly', () async {
      final words = await repo.expectedWords(const SurahRange(2));
      final heard = _plainWords(words);
      final engine = TasmeeEngine(words);
      final watch = Stopwatch()..start();
      for (final w in heard) {
        engine.addWords([w]);
      }
      engine.finish();
      watch.stop();
      final wrong = [
        for (var i = 0; i < words.length; i++)
          if (engine.statusOf(i) != WordStatus.correct)
            '${words[i]} ${engine.statusOf(i).name} near ${heard.sublist(max(0, i - 3), min(heard.length, i + 3))}',
      ];
      expect(wrong, isEmpty);
      expect(engine.extraWords, isEmpty);
      // About 6,100 words; each heard word costs well under a millisecond.
      expect(watch.elapsedMilliseconds, lessThan(6000));
    });

    // Simulated recitations of juz 30 with random errors of every kind the
    // plan lists; the engine must find the errors and nothing else.
    test('simulated recitations with random errors', () async {
      final words = await repo.expectedWords(const JuzRange(30));
      final plain = _plainWords(words);
      var right = 0, total = 0, errors = 0, found = 0, falseErrors = 0;
      for (var seed = 1; seed <= 6; seed++) {
        final sim = _simulate(words, plain, Random(seed));
        final engine = TasmeeEngine(words);
        for (final chunk in sim.chunks) {
          engine.addWords(chunk);
        }
        engine.finish();
        for (var i = 0; i < words.length; i++) {
          final got = engine.statusOf(i);
          final want = sim.truth[i];
          total++;
          if (got == want) right++;
          if (want.isError) {
            errors++;
            if (got.isError || got == WordStatus.correctedAfterError) found++;
          } else if (got.isError) {
            falseErrors++;
          }
        }
      }
      final agreement = right / total;
      final recall = found / errors;
      final falseRate = falseErrors / (total - errors);
      // ignore: avoid_print
      print(
        'simulation: ${(agreement * 100).toStringAsFixed(2)}% statuses right, '
        '${(recall * 100).toStringAsFixed(1)}% of $errors errors found, '
        '${(falseRate * 100).toStringAsFixed(2)}% of correct words marked as errors',
      );
      expect(agreement, greaterThan(0.97));
      expect(recall, greaterThan(0.85));
      expect(falseRate, lessThan(0.01));
    });
  });

  group('TranscriptStabilizer', () {
    test('a word settles once two hypotheses agree on it', () {
      final s = TranscriptStabilizer();
      expect(s.update('الحمد'), isEmpty);
      expect(s.update('الحمد لل'), ['الحمد']);
      expect(s.update('الحمد لله رب'), isEmpty);
      expect(s.update('الحمد لله رب العا'), ['لله', 'رب']);
      expect(s.tentative, ['العا']);
      expect(s.finish('الحمد لله رب العالمين'), ['العالمين']);
      expect(s.update('الرحمن'), isEmpty);
    });

    test('a changed last word is not settled; vowel marks do not count', () {
      final s = TranscriptStabilizer();
      s.update('قل هو');
      expect(s.update('قُلْ هُوَ اللَّهُ'), ['قُلْ', 'هُوَ']);
      expect(s.update('قل هو الله احد'), ['الله']);
      expect(s.update('قل هو الله الصمد'), isEmpty);
      expect(s.finish(), ['الصمد']);
    });

    test('three agreeing hypotheses when asked', () {
      final s = TranscriptStabilizer(agreement: 3);
      s.update('مالك');
      expect(s.update('مالك يوم'), isEmpty);
      expect(s.update('مالك يوم الدين'), ['مالك']);
    });
  });
}

/// The words of the range as a recogniser would write them: Tanzil's
/// Simple Clean words where a verse has as many as the mushaf, else the
/// mushaf's words.
List<String> _plainWords(List<ExpectedWord> words) {
  final db = sqlite3.open('assets/db/content.db', mode: OpenMode.readOnly);
  try {
    final byVerse = <int, List<String>>{};
    for (final w in words) {
      byVerse.putIfAbsent(w.verseId, () {
        final row = db.select(
          'SELECT text_search, search_basmala_prefix FROM ayah WHERE id = ?',
          [w.verseId],
        ).single;
        return (row['text_search'] as String)
            .substring(row['search_basmala_prefix'] as int)
            .trim()
            .split(' ');
      });
    }
    final count = <int, int>{};
    for (final w in words) {
      count[w.verseId] = (count[w.verseId] ?? 0) + 1;
    }
    return [
      for (final w in words)
        byVerse[w.verseId]!.length == count[w.verseId]
            ? byVerse[w.verseId]![w.word - 1]
            : w.display,
    ];
  } finally {
    db.close();
  }
}

class _Simulation {
  _Simulation(this.chunks, this.truth);
  final List<List<String>> chunks;
  final List<WordStatus> truth;
}

const _strangers = ['دائما', 'كذلك', 'سبحان', 'يقول', 'نعم', 'قالت', 'بيت'];

_Simulation _simulate(List<ExpectedWord> words, List<String> plain, Random r) {
  final truth = List.filled(words.length, WordStatus.correct);
  final heard = <String>[];
  var i = 0;
  while (i < words.length) {
    final roll = r.nextDouble();
    if (roll < 0.004 && i > 0 && i + 12 < words.length) {
      // A line passed over.
      final n = 8 + r.nextInt(5);
      for (var x = 0; x < n; x++) {
        truth[i + x] = WordStatus.skipped;
      }
      i += n;
      continue;
    }
    if (roll < 0.02 && i > 0) {
      truth[i] = WordStatus.skipped;
      i++;
      continue;
    }
    if (roll < 0.035 && i > 0) {
      truth[i] = WordStatus.wrong;
      heard.add(_strangers[r.nextInt(_strangers.length)]);
      i++;
      continue;
    }
    if (roll < 0.045) {
      heard.add(_strangers[r.nextInt(_strangers.length)]);
    } else if (roll < 0.075 && i > 3) {
      // Back a few words at a pause.
      final back = 1 + r.nextInt(3);
      for (var x = i - back; x < i; x++) {
        if (truth[x] == WordStatus.correct) heard.add(plain[x]);
      }
    }
    heard.add(plain[i]);
    i++;
  }
  final chunks = <List<String>>[];
  for (var x = 0; x < heard.length; x += 3) {
    chunks.add(heard.sublist(x, min(x + 3, heard.length)));
  }
  return _Simulation(chunks, truth);
}
