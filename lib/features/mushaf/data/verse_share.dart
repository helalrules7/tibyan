import '../../../core/db/content_database.dart';

/// The text that leaves the app when verses are copied or shared.
///
/// It is Tanzil's Uthmani text, verbatim (its licence forbids changing
/// it), the verse numbers in ornate brackets, a reference line per surah
/// and Tanzil's credit as one short line (its licence asks for the source
/// with a link to tanzil.net), written once, as given. Where a verse opens with the basmala in the file
/// (every surah but al-Fatiha and at-Tawba), the basmala is left out: it is
/// not part of the verse.
String composeVerseText({
  required List<AyahRow> verses,
  required String Function(int surah) surahLabel,
  required String Function(int n) digits,
  required String Function(String surah, String from, String to) range,
  required String credit,
}) {
  final out = StringBuffer();
  var i = 0;
  while (i < verses.length) {
    final surah = verses[i].surah;
    var j = i;
    while (j < verses.length && verses[j].surah == surah) {
      j++;
    }
    final group = verses.sublist(i, j);
    if (out.isNotEmpty) out.write('\n\n');
    out.write(
      [for (final v in group) '${_bare(v)} ﴿${digits(v.number)}﴾'].join(' '),
    );
    final first = group.first.number;
    final last = group.last.number;
    out.write('\n');
    out.write(
      first == last
          ? '[${surahLabel(surah)} ${digits(first)}]'
          : '[${range(surahLabel(surah), digits(first), digits(last))}]',
    );
    i = j;
  }
  out
    ..write('\n\n')
    ..write(credit);
  return out.toString();
}

/// The verse as Tanzil spells it, without the basmala it may open with.
String _bare(AyahRow v) {
  final text = v.verseText;
  final cut = v.number == 1 ? v.basmalaPrefix : 0;
  return (cut > 0 && cut < text.length ? text.substring(cut) : text).trim();
}
