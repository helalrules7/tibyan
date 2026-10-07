import 'alignment_engine.dart';
import 'expected_words.dart';

/// One verse of a session's report.
class VerseReport {
  const VerseReport({
    required this.verseId,
    required this.surah,
    required this.ayah,
    required this.words,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.corrected,
    required this.doubtful,
    required this.hinted,
    required this.reached,
  });

  final int verseId;
  final int surah;
  final int ayah;

  /// Words of the verse in the session.
  final int words;

  /// Read as written, from memory (a word shown by a hint is not).
  final int correct;
  final int wrong;
  final int skipped;
  final int corrected;

  /// Unsure words: neither correct nor an error, left out of the accuracy.
  final int doubtful;

  /// Words shown by the hint button.
  final int hinted;

  /// Words settled or shown (the rest were not reached).
  final int reached;

  int get judged => words - doubtful;

  /// Correct words over the words judged, 0..1; null with nothing judged.
  double? get accuracy => judged <= 0 ? null : correct / judged;

  /// Anything the reader should look at again.
  bool get needsReview =>
      wrong + skipped + corrected + hinted > 0 || reached < words;
}

/// What a session (or the part of it done so far) amounts to: verse by
/// verse and in all. The engine's extra words (bits the recogniser heard
/// twice where speech segments overlap, or words that match nothing) are
/// left out: they stay in the engine's own record for debugging.
class TasmeeReport {
  TasmeeReport._(this.verses);

  /// [hinted]: indices of words shown by the hint button.
  factory TasmeeReport.of(TasmeeEngine engine, Set<int> hinted) {
    final byVerse = <int, List<ExpectedWord>>{};
    for (final w in engine.words) {
      (byVerse[w.verseId] ??= []).add(w);
    }
    final verses = <VerseReport>[];
    for (final ws in byVerse.values) {
      var correct = 0, wrong = 0, skipped = 0, corrected = 0, doubtful = 0;
      var hints = 0, reached = 0;
      for (final w in ws) {
        final s = engine.statusOf(w.index);
        final hint = hinted.contains(w.index);
        if (s.isSettled || hint) reached++;
        if (hint) {
          hints++;
          continue;
        }
        switch (s) {
          case WordStatus.correct:
            correct++;
          case WordStatus.wrong:
            wrong++;
          case WordStatus.skipped:
            skipped++;
          case WordStatus.correctedAfterError:
            corrected++;
          case WordStatus.doubtful:
            doubtful++;
          case WordStatus.hidden:
            break;
        }
      }
      if (reached == 0) continue;
      final first = ws.first;
      verses.add(
        VerseReport(
          verseId: first.verseId,
          surah: first.surah,
          ayah: first.ayah,
          words: ws.length,
          correct: correct,
          wrong: wrong,
          skipped: skipped,
          corrected: corrected,
          doubtful: doubtful,
          hinted: hints,
          reached: reached,
        ),
      );
    }
    return TasmeeReport._(verses);
  }

  /// The verses reached, in order.
  final List<VerseReport> verses;

  int _sum(int Function(VerseReport v) f) => verses.fold(0, (s, v) => s + f(v));

  int get words => _sum((v) => v.words);
  int get correct => _sum((v) => v.correct);
  int get wrong => _sum((v) => v.wrong);
  int get skipped => _sum((v) => v.skipped);
  int get corrected => _sum((v) => v.corrected);
  int get doubtful => _sum((v) => v.doubtful);
  int get hinted => _sum((v) => v.hinted);

  /// Correct words over every word judged in the verses reached.
  double? get accuracy {
    final judged = words - doubtful;
    return judged <= 0 ? null : correct / judged;
  }

  List<VerseReport> get toReview => [
    for (final v in verses)
      if (v.needsReview) v,
  ];

  VerseReport? verse(int verseId) {
    for (final v in verses) {
      if (v.verseId == verseId) return v;
    }
    return null;
  }
}

/// Words of [words] in the verses [verseIds] only, numbered again from 0,
/// for «recite these verses again».
List<ExpectedWord> wordsOfVerses(List<ExpectedWord> words, Set<int> verseIds) {
  final out = <ExpectedWord>[];
  for (final w in words) {
    if (!verseIds.contains(w.verseId)) continue;
    out.add(
      ExpectedWord(
        index: out.length,
        verseId: w.verseId,
        surah: w.surah,
        ayah: w.ayah,
        word: w.word,
        page: w.page,
        display: w.display,
        matching: w.matching,
        alternatives: w.alternatives,
        isLastInVerse: w.isLastInVerse,
        opensSurah: w.opensSurah,
      ),
    );
  }
  return out;
}
