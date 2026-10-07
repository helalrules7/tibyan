import '../../../core/settings/app_settings.dart';
import '../../share_image/share_text_runs.dart';

/// How far a tajweed rule reaches in the Hafs data (`tajweed_letter`):
/// the verses it falls in and the letters it colours.
typedef TajweedRuleCount = ({int verses, int letters});

/// A letter of a verse a rule applies to: word [word] of the verse (from
/// 1, ۞ not counted), letter [letter] of the word (from 0), the letter
/// itself or only its marks ([marksOnly]).
typedef TajweedPlaceLetter = ({int word, int letter, bool marksOnly});

/// A verse a tajweed rule falls in (Hafs numbers), with the letters it
/// colours there, the verse's KFGQPC text and its page in each Hafs
/// edition. Nothing here is made: the letters are `tajweed_letter` rows,
/// the text is `ayah.display_text` as stored.
class TajweedPlace {
  const TajweedPlace({
    required this.surah,
    required this.ayah,
    required this.text,
    required this.letters,
    required this.page1441,
    required this.page1405,
    required this.pageShamarly,
  });

  final int surah;
  final int ayah;

  /// The verse as shown (KFGQPC text, verbatim), its number at the end.
  final String text;

  final List<TajweedPlaceLetter> letters;
  final int page1441;
  final int page1405;

  /// The Shamarly page the verse starts on.
  final int pageShamarly;

  /// The verse's page in a Hafs [edition] (where it starts). The riwaya
  /// editions have no tajweed data, so this is never asked for them.
  int pageIn(MushafEdition edition) => switch (edition) {
    MushafEdition.madina1405 => page1405,
    MushafEdition.shamarly => pageShamarly,
    _ => page1441,
  };

  /// Parses the `group_concat` of "word:letter:part" the index query gives.
  static List<TajweedPlaceLetter> parseLetters(String joined) => [
    for (final e in joined.split(' '))
      if (e.split(':') case [final w, final l, final part])
        (word: int.parse(w), letter: int.parse(l), marksOnly: part == 'marks'),
  ];
}

/// A space-separated piece of a verse's text that holds a word the rule
/// falls on: [text] exactly as stored, [firstWord] the number of its first
/// word in the verse, [endsVerse] whether it is the verse's last piece
/// (which carries the verse number).
typedef TajweedToken = ({String text, int firstWord, bool endsVerse});

/// The pieces of [place]'s text that hold the words its letters are on,
/// in order. Only whole pieces of the stored text are returned; nothing is
/// cut, joined or changed.
List<TajweedToken> tajweedTokens(TajweedPlace place) {
  final words = {for (final l in place.letters) l.word};
  final tokens = place.text.split(' ');
  final out = <TajweedToken>[];
  var word = 1;
  for (var i = 0; i < tokens.length; i++) {
    final endsVerse = i == tokens.length - 1;
    final n = wordsInToken(tokens[i], endsVerse: endsVerse);
    if (n > 0 && words.any((w) => w >= word && w < word + n)) {
      out.add((text: tokens[i], firstWord: word, endsVerse: endsVerse));
    }
    word += n;
  }
  return out;
}
