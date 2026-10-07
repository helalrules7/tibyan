import 'arabic_normalizer.dart';

/// Turns a streaming recogniser's changing hypotheses into words that are
/// settled, so the alignment only ever sees words that will not change.
///
/// A streaming recogniser transcribes the current stretch of speech again
/// and again as audio arrives, and the last words of each hypothesis often
/// change (a word cut in half, then completed). A word is settled once it
/// has stayed the same, at the same place, in [agreement] hypotheses in a
/// row, and every word before it is settled; or when the stretch ends
/// ([finish]). Words are compared by their matching keys, so a change in
/// vowel marks alone does not unsettle a word.
class TranscriptStabilizer {
  TranscriptStabilizer({this.agreement = 2}) : assert(agreement >= 1);

  final int agreement;

  List<String> _words = const [];
  List<String> _keys = const [];
  List<int> _runs = const [];
  int _settled = 0;

  /// Words of the current hypothesis that are not settled yet.
  List<String> get tentative =>
      _words.sublist(_settled.clamp(0, _words.length));

  /// The whole hypothesis for the current stretch of speech so far; returns
  /// the words that became settled with it, in order.
  List<String> update(String hypothesis) {
    final words = hypothesis.split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    final keys = [for (final w in words) normalizeArabicWord(w)];
    final runs = [
      for (var i = 0; i < words.length; i++)
        i < _keys.length && _keys[i] == keys[i] ? _runs[i] + 1 : 1,
    ];
    _words = words;
    _keys = keys;
    _runs = runs;
    var stable = 0;
    while (stable < runs.length && runs[stable] >= agreement) {
      stable++;
    }
    if (stable <= _settled) return const [];
    final out = words.sublist(_settled, stable);
    _settled = stable;
    return out;
  }

  /// The stretch of speech ended with [finalText] (the recogniser's final
  /// result for it, or the last hypothesis when null): returns its words
  /// not settled yet, and starts afresh for the next stretch.
  List<String> finish([String? finalText]) {
    final words = finalText == null
        ? _words
        : (finalText.split(RegExp(r'\s+'))..removeWhere((w) => w.isEmpty));
    final out = _settled < words.length
        ? words.sublist(_settled)
        : const <String>[];
    _words = const [];
    _keys = const [];
    _runs = const [];
    _settled = 0;
    return out;
  }
}
