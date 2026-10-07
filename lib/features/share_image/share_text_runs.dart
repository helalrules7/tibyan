import 'dart:ui' show Color;

import '../mushaf/data/divine_names.dart';

/// A letter a tajweed rule applies to (a `tajweed_letter` row): word
/// [word] of the verse (from 1, ۞ not counted), letter [letter] of the word
/// (from 0: a base character and the marks after it), the letter itself or
/// only its marks ([marksOnly]), in [color].
class ShareTajweedLetter {
  const ShareTajweedLetter({
    required this.word,
    required this.letter,
    required this.marksOnly,
    required this.color,
  });

  final int word;
  final int letter;
  final bool marksOnly;
  final Color color;
}

/// The no-break space of the KFGQPC texts (۞ and the verse number are held
/// to their word by it).
const nbsp = ' ';

/// A base character, as tools/build_tajweed.py counts letters (Unicode
/// category L: the letters, tatweel, small waw and small yeh); everything
/// else in the texts is a mark or a sign.
bool isBaseChar(int c) =>
    (c >= 0x0621 && c <= 0x063A) ||
    (c >= 0x0640 && c <= 0x064A) ||
    (c >= 0x066E && c <= 0x066F) ||
    (c >= 0x0671 && c <= 0x06D3) ||
    c == 0x06D5 ||
    c == 0x06E5 ||
    c == 0x06E6 ||
    c == 0x06EE ||
    c == 0x06EF ||
    (c >= 0x06FA && c <= 0x06FC) ||
    c == 0x06FF;

/// The letters of [word] as (start, end) code-unit spans: each base
/// character with the marks after it (as tools/build_tajweed.py `letters`).
List<(int, int)> letterSpans(String word) {
  final out = <(int, int)>[];
  final units = word.codeUnits;
  for (var i = 0; i < units.length; i++) {
    if (isBaseChar(units[i]) || out.isEmpty) {
      out.add((i, i + 1));
    } else {
      out[out.length - 1] = (out.last.$1, i + 1);
    }
  }
  return out;
}

final _numberGlyphs = RegExp('^[ﰀ-﷿٠-٩]+\$');

/// Whether a no-break-space piece of a token is a word (word study and
/// tajweed count it): not ۞, and not the verse number at the end of a
/// verse.
bool _isWord(String piece, {required bool verseNumber}) =>
    piece.isNotEmpty &&
    piece != '۞' &&
    !(verseNumber && _numberGlyphs.hasMatch(piece));

/// How many words a token holds.
int wordsInToken(String text, {required bool endsVerse}) {
  final pieces = text.split(nbsp);
  var n = 0;
  for (var i = 0; i < pieces.length; i++) {
    if (_isWord(pieces[i], verseNumber: endsVerse && i == pieces.length - 1)) {
      n++;
    }
  }
  return n;
}

/// The token [text] as runs of one colour each (null: the ink), in order.
/// The runs' texts joined give back [text] exactly: only colours are
/// chosen here, never characters.
///
/// [firstWord] is the number of the token's first word in its verse;
/// [letters] the verse's tajweed letters (empty when tajweed is off). A
/// letter whose rule covers only its marks ([ShareTajweedLetter.marksOnly],
/// like the small meem of «مُحِيطُۢ») is left in ink: the text engine colours
/// a letter and its marks as one cluster, cut in vertical slices by their
/// place in the text, so a mark cannot be coloured without part of the
/// letter under it, and shaping the mark apart detaches it. The pages draw
/// these marks in colour from their own shapes. A
/// divine name is coloured [divine] when given (its tajweed letters keep
/// their colours); the verse number is coloured [number].
List<(String, Color?)> tokenRuns(
  String text, {
  required int firstWord,
  required bool endsVerse,
  List<ShareTajweedLetter> letters = const [],
  Color? divine,
  Color? number,
}) {
  if (text.isEmpty) return const [];
  final colors = List<Color?>.filled(text.length, null);
  final pieces = text.split(nbsp);
  var offset = 0;
  var word = firstWord;
  for (var i = 0; i < pieces.length; i++) {
    final piece = pieces[i];
    final last = endsVerse && i == pieces.length - 1;
    if (_isWord(piece, verseNumber: last)) {
      if (divine != null && isDivineName(piece)) {
        for (var k = 0; k < piece.length; k++) {
          colors[offset + k] = divine;
        }
      }
      final spans = letterSpans(piece);
      for (final l in letters) {
        // A rule on the marks only stays in ink: see [tokenRuns].
        if (l.marksOnly || l.word != word || l.letter >= spans.length) {
          continue;
        }
        final (s, e) = spans[l.letter];
        for (var k = s; k < e; k++) {
          colors[offset + k] = l.color;
        }
      }
      word++;
    } else if (last && number != null) {
      for (var k = 0; k < piece.length; k++) {
        colors[offset + k] = number;
      }
    }
    offset += piece.length + 1;
  }
  final runs = <(String, Color?)>[];
  var start = 0;
  for (var k = 1; k <= text.length; k++) {
    if (k == text.length || colors[k] != colors[start]) {
      runs.add((text.substring(start, k), colors[start]));
      start = k;
    }
  }
  return runs;
}

final _digitRun = RegExp('[٠-٩0-9]+');

/// A label of the pictures ([text]) as runs in order, each with its font:
/// the digits in [digits] (the mushaf's font, as its verse-end markers
/// are), everything else in [words] (the labels' font). The runs' texts
/// joined give back [text] exactly.
List<(String, String)> labelRuns(
  String text, {
  required String words,
  required String digits,
}) {
  final runs = <(String, String)>[];
  var at = 0;
  for (final m in _digitRun.allMatches(text)) {
    if (m.start > at) runs.add((text.substring(at, m.start), words));
    runs.add((m[0]!, digits));
    at = m.end;
  }
  if (at < text.length) runs.add((text.substring(at), words));
  return runs;
}
