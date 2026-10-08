import 'arabic_normalizer.dart';
import 'recitation_range.dart';

/// One word the reader is expected to say, in the order of the mushaf.
///
/// [display] is the KFGQPC word exactly as stored (never altered, and the
/// only form ever shown); [matching] is its key for comparing with what was
/// heard ([normalizeArabicWord]).
class ExpectedWord {
  const ExpectedWord({
    required this.index,
    required this.verseId,
    required this.surah,
    required this.ayah,
    required this.word,
    required this.page,
    required this.display,
    required this.matching,
    this.alternatives = const [],
    required this.isLastInVerse,
    this.opensSurah = false,
  });

  /// Position in the session's sequence, from 0.
  final int index;

  /// content.db `ayah.id`, 1..6236.
  final int verseId;
  final int surah;
  final int ayah;

  /// 1-based number of the word in its verse: the KFGQPC words without
  /// verse numbers and hizb signs, as numbered in `word_box.word` (its box
  /// on the page) and in the recitation timings.
  final int word;

  /// The page of the new edition (1441H) the word is printed on.
  final int page;

  final String display;
  final String matching;

  /// Other keys the word may be heard as: the separate letters at the
  /// opening of a surah are recited by their names (الٓمٓ: «ألف لام ميم»).
  final List<String> alternatives;

  /// The last word of its verse in the mushaf.
  final bool isLastInVerse;

  /// The first word of verse 1 of a surah that is read with a basmala
  /// before it (every surah but al-Fatiha, whose basmala is its verse 1,
  /// and at-Tawbah): a basmala heard before it is not an extra word.
  final bool opensSurah;

  /// Every key the word may be heard as.
  Iterable<String> get keys sync* {
    yield matching;
    yield* alternatives;
  }

  @override
  String toString() => 'ExpectedWord($surah:$ayah:$word $display)';
}

/// A verse of the range with what [buildExpectedWords] needs of it.
class VerseSource {
  const VerseSource(this.entry, this.displayText, this.wordPages);

  final VerseIndexEntry entry;

  /// content.db `ayah.display_text` (KFGQPC Hafs), verbatim.
  final String displayText;

  /// The page of each word, in order (content.db `word_box.page`).
  final List<int> wordPages;
}

final _wordBreak = RegExp('[\\s\u00A0]+');
final _letter = RegExp('[\u0621-\u064A\u0671-\u06D3]');

/// The words of a verse's KFGQPC text as numbered in `word_box`: without
/// the verse number and the hizb sign (۞). The words are not changed.
List<String> displayWords(String displayText) => [
  for (final w in displayText.trim().split(_wordBreak))
    if (_letter.hasMatch(w)) w,
];

/// Surahs read without a basmala of their own before verse 1.
const _noBasmala = {1, 9};

/// The names of the letters recited at the opening of 29 surahs.
const _letterNames = {
  'ا': 'الف',
  'ل': 'لام',
  'م': 'ميم',
  'ص': 'صاد',
  'ر': 'را',
  'ك': 'كاف',
  'ه': 'ها',
  'ي': 'يا',
  'ع': 'عين',
  'ط': 'طا',
  'س': 'سين',
  'ح': 'حا',
  'ق': 'قاف',
  'ن': 'نون',
};

/// The keys of the opening letters (الم، كهيعص، طه، حم، عسق، ن …).
const _openingLetters = {
  'الم', 'المص', 'الر', 'المر', 'كهيعص', 'طه', 'طسم', 'طس', 'يس', 'ص', //
  'حم', 'عسق', 'ق', 'ن',
};

/// The letters' names as heard («ألف لام ميم»), for the first word of
/// the first or second verse when it is one of the opening letters.
List<String> _spelledLetters(String key, int ayah, int word) {
  if (word != 1 || ayah > 2 || !_openingLetters.contains(key)) return const [];
  return [
    joinKeys([for (final c in key.split('')) _letterNames[c]!]),
  ];
}

/// The words of [range] in mushaf order, from its [verses] in mushaf order
/// (the verses [RecitationRange.versesIn] gives, with their text and word
/// pages). Verse numbers and hizb signs are not words; waqf signs stay
/// part of their word's [ExpectedWord.display] and are dropped from its key.
List<ExpectedWord> buildExpectedWords(
  RecitationRange range,
  List<VerseSource> verses, {
  List<SpellingRule> rules = uthmaniSpellingRules,
}) {
  final out = <ExpectedWord>[];
  for (final v in verses) {
    final e = v.entry;
    if (!range.containsVerse(e)) continue;
    final words = displayWords(v.displayText);
    if (words.length != v.wordPages.length) {
      throw StateError(
        '${e.surah}:${e.ayah} has ${words.length} words '
        'and ${v.wordPages.length} word pages',
      );
    }
    for (var i = 0; i < words.length; i++) {
      final page = v.wordPages[i];
      if (!range.containsWord(e, page)) continue;
      final key = normalizeArabicWord(words[i], rules: rules);
      out.add(
        ExpectedWord(
          index: out.length,
          verseId: e.id,
          surah: e.surah,
          ayah: e.ayah,
          word: i + 1,
          page: page,
          display: words[i],
          matching: key,
          alternatives: _spelledLetters(key, e.ayah, i + 1),
          isLastInVerse: i == words.length - 1,
          opensSurah: e.ayah == 1 && i == 0 && !_noBasmala.contains(e.surah),
        ),
      );
    }
  }
  return out;
}
