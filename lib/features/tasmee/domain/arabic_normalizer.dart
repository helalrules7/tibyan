/// Arabic normalization for matching a recitation against the Quran text.
///
/// The golden rule: this is for comparing only. The text shown to the reader
/// is never passed through it; [normalizeArabic] makes a matching key that
/// the Uthmani script of the mushaf (KFGQPC Hafs, Tanzil Uthmani) and the
/// common (imla'i) spelling a speech recogniser writes agree on.
///
/// Checked against the whole Quran: the KFGQPC words and Tanzil's Simple
/// Clean words (imla'i) of the 5,870 verses whose words line up agree on
/// 99.78% of the words (tools note in docs/recitation/phase0-exploration.md);
/// what is left (أرأيت، يبدأ، الأيكة …) is a letter or two apart, which the
/// matcher's edit distance absorbs.
library;

/// One Uthmani spelling and its common form, applied to each word after
/// the vowel marks are gone and while the dagger alif (U+0670) is still
/// there, so a rule can tell a written alif from a dagger one.
class SpellingRule {
  const SpellingRule(this.pattern, this.replacement, this.example);

  /// Matched within one word: `^` and `$` are the word's ends.
  final String pattern;
  final String replacement;

  /// An Uthmani word and its common spelling, for the reader of this table.
  final String example;
}

const _dagger = '\u0670';

/// The Uthmani spellings that differ from the common ones in more than
/// vowel marks. Extend it here; [normalizeArabic] takes another list too.
const uthmaniSpellingRules = <SpellingRule>[
  // A waw (with a dagger alif) written for a long a before ta marbuta:
  // الصلوة، الزكوة، الحيوة، مشكوة، النجوة، منوة، الغدوة.
  SpellingRule('و$_dagger(?=ة)', 'ا', 'ٱلصَّلَوٰةَ → الصلاة'),
  SpellingRule('ربو$_daggerا', 'ربا', 'ٱلرِّبَوٰاْ → الربا'),
  // Elsewhere the waw is a consonant: السموات → السماوات.
  SpellingRule('و$_dagger', 'وا', 'ٱلسَّمَٰوَٰتِ → السماوات'),
  // Words whose dagger alif the common spelling keeps unwritten.
  SpellingRule('ه$_dagger(?=ذ|ؤ)', 'ه', 'هَٰذَا → هذا، هَٰٓؤُلَآءِ → هؤلاء'),
  SpellingRule('ذ$_daggerلك', 'ذلك', 'ذَٰلِكَ → ذلك'),
  SpellingRule('ل$_daggerكن', 'لكن', 'وَلَٰكِنَّ → ولكن'),
  SpellingRule('ل$_daggerه', 'له', 'إِلَٰهَ → إله'),
  SpellingRule('رحم$_daggerن', 'رحمن', 'ٱلرَّحۡمَٰنِ → الرحمن'),
  SpellingRule(
    'أول$_dagger(?=ئ)',
    'أول',
    'أُوْلَٰٓئِكَ → أولئك (not أَوۡلَٰدَ)',
  ),
  // One lam where the common spelling writes two.
  SpellingRule('ٱل(?=يل)', 'ٱلل', 'ٱلَّيۡلَ → الليل'),
  SpellingRule('ٱل$_dagger(?=ت|ئ)', 'ٱللا', 'ٱلَّٰتِي → اللاتي'),
  // An alif maqsura with a dagger alif is a long a: inside a word it is
  // written ا (ءَاتَىٰهُمُ → آتاهم), at its end ى (عَلَىٰ → على).
  SpellingRule('ى$_dagger\$', 'ى', 'عَلَىٰ → على'),
  SpellingRule('ى$_dagger', 'ا', 'ٱلتَّوۡرَىٰةَ → التوراة'),
  // A verb ending in a yeh written once where the common spelling writes
  // it twice: يُحۡيِ → يحيي، يَسۡتَحۡيِۦٓ → يستحيي (not ٱلۡحَيُّ).
  SpellingRule('(?<=^[وفل]{0,2}(?:يست|[يتنأم]))حي\$', 'حيي', 'يُحۡيِ → يحيي'),
  // رَءَا is رأى.
  SpellingRule('رأا\$', 'رأى', 'رَءَا → رأى'),
];

/// Marks dropped before the spelling rules: vowels, tanween (also the
/// KFGQPC open forms), shadda, sukun, maddah, tatweel, the small high and
/// low letters that are signs (waqf, iqlab, silent letters), the rub el
/// hizb, sajdah and verse-end signs.
final _marks = RegExp(
  '[\u0610-\u061A\u064B-\u0653\u0656-\u065F\u0640\u06D6-\u06E4'
  '\u06E9-\u06ED\u08F0-\u08F3\u06DD\u06DE]',
);

/// A hamza on a tatweel (or alone) with a fatha is written on an alif in
/// the common spelling (يسـٔلونك → يسألونك، أرءيت → أرأيت); any other
/// hamza on a tatweel sits on a yeh (شيـٔا → شيئا).
final _hamzaFatha = RegExp(
  '\u0640\u0654\u064E|\u0640\u064E\u0654|\u0621\u0654?\u064E',
);
final _hamzaOnTatweel = RegExp('\u0640\u0654');

/// After a yeh the hamza with a fatha sits on a yeh in the common
/// spelling (خَطِيٓـَٔتُهُۥ → خطيئته).
final _hamzaFathaAfterYeh = RegExp(
  '(?<=\u064A[\u064B-\u0653]*)\u0640(?:\u0654\u064E|\u064E\u0654)',
);

/// A sad with a small high seen is read as a seen in Hafs (وَيَبۡصُۜطُ →
/// ويبسط، بَصۜۡطَةٗ → بسطة).
final _sadReadAsSeen = RegExp('\u0635(?=[\u064B-\u0653]*\u06DC)');

final _whitespace = RegExp('[\\s\u00A0\u200C\u200D\u200E\u200F]+');
final _nonLetter = RegExp('[^\u0621-\u064A]');
final _alifRun = RegExp('\u0627+');
final _silentSmallLetter = RegExp('\u0647[\u06E5\u06E6]');

final _compiledRules = Expando<List<(RegExp, String)>>();

List<(RegExp, String)> _compile(List<SpellingRule> rules) =>
    _compiledRules[rules] ??= [
      for (final r in rules) (RegExp(r.pattern), r.replacement),
    ];

/// The matching key of one word: no marks, one form for each family of
/// letters, Uthmani spellings in their common form. Empty when the word
/// has no letters (a verse number, a waqf sign).
String normalizeArabicWord(
  String word, {
  List<SpellingRule> rules = uthmaniSpellingRules,
}) {
  var w = word
      .replaceAll(_sadReadAsSeen, 'س')
      .replaceAll(_hamzaFathaAfterYeh, 'ئ')
      .replaceAll(_hamzaFatha, 'أ')
      .replaceAll(_hamzaOnTatweel, 'ئ')
      .replaceAll(_marks, '');
  for (final (pattern, replacement) in _compile(rules)) {
    w = w.replaceAll(pattern, replacement);
  }
  w = w
      // The small waw and yeh after a pronoun's ha are its long vowel,
      // unwritten in the common spelling (لَهُۥ → له، بِهِۦ → به); elsewhere
      // they are letters (دَاوُۥدُ → داوود، يُحۡيِۦ → يحيي).
      .replaceAll(_silentSmallLetter, 'ه')
      .replaceAll('\u06E5', 'و')
      .replaceAll('\u06E6', 'ي')
      .replaceAll('\u06E7', 'ي')
      .replaceAll('\u06E8', 'ن')
      .replaceAll(_dagger, 'ا');
  final out = StringBuffer();
  for (final rune in w.runes) {
    out.write(switch (rune) {
      0x0671 || 0x0623 || 0x0625 || 0x0622 => 'ا', // ٱ أ إ آ
      0x0624 => 'و', // ؤ
      0x0626 || 0x0621 || 0x0654 || 0x0655 => '', // ئ ء and hamza marks
      0x0649 || 0x06CC || 0x06D2 => 'ي', // ى، Persian and Urdu yeh
      0x0629 || 0x06C1 || 0x06C0 || 0x06D5 => 'ه', // ة and heh forms
      0x06A9 => 'ك', // Persian kaf
      _ => String.fromCharCode(rune),
    });
  }
  var key = out.toString().replaceAll(_nonLetter, '');
  key = key.replaceAll(_alifRun, 'ا');
  // An alif after a final waw is not pronounced, and Uthmani writes it
  // where the common spelling may not (يَدۡعُواْ / يدعو، أُوْلُواْ / أولو).
  if (key.length > 2 && key.endsWith('وا')) {
    key = key.substring(0, key.length - 1);
  }
  return key;
}

/// One key for words a recogniser and the mushaf divide differently: the
/// vocative يَٰٓأَيُّهَا is one word in the mushaf and يا أيها two in the
/// common spelling. The keys are joined as one word would be normalized.
String joinKeys(Iterable<String> keys) => keys.join().replaceAll(_alifRun, 'ا');

/// The matching keys of the words of [text], in order, without empty ones.
List<String> matchingWords(
  String text, {
  List<SpellingRule> rules = uthmaniSpellingRules,
}) => [
  for (final w in text.split(_whitespace))
    if (normalizeArabicWord(w, rules: rules) case final k when k.isNotEmpty) k,
];

/// [text]'s matching keys joined by single spaces: what the expected text
/// and the recogniser's output are both compared as.
String normalizeArabic(
  String text, {
  List<SpellingRule> rules = uthmaniSpellingRules,
}) => matchingWords(text, rules: rules).join(' ');
