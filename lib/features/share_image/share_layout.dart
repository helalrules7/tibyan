/// Line breaking, justification and the split into images of a passage
/// shared as pictures. Pure layout: the widths of the words come from the
/// caller (the font), and nothing here reads or changes a character.
library;

/// A verse as it is drawn: its text verbatim from the source (the KFGQPC
/// text, its verse-number glyph included).
class ShareVerse {
  const ShareVerse({
    required this.surah,
    required this.ayah,
    required this.text,
  });

  final int surah;
  final int ayah;

  /// Verbatim, never edited.
  final String text;
}

/// A piece of a verse between two breakable spaces: a word, or a word held
/// to its neighbour by a no-break space (the verse-number glyph, ۞).
class ShareToken {
  const ShareToken({
    required this.text,
    required this.verse,
    required this.endsVerse,
  });

  /// A slice of the verse's text, as it is.
  final String text;

  /// Index of its verse in the passage.
  final int verse;

  /// The verse's last token (the one carrying its number).
  final bool endsVerse;
}

/// The breakable space of the KFGQPC texts. No-break spaces keep ۞ and the
/// verse number with their word, so a line never starts with either.
const _space = ' ';

/// The tokens of [verses], in reading order. Joining their texts with one
/// space gives back the verses joined with one space, character for
/// character ([joinTokens]).
List<ShareToken> tokenize(List<ShareVerse> verses) {
  final out = <ShareToken>[];
  for (var v = 0; v < verses.length; v++) {
    final parts = verses[v].text.split(_space);
    for (var i = 0; i < parts.length; i++) {
      out.add(
        ShareToken(text: parts[i], verse: v, endsVerse: i == parts.length - 1),
      );
    }
  }
  return out;
}

/// The text the tokens stand for: the verses, each verbatim, joined by one
/// space.
String joinTokens(Iterable<ShareToken> tokens) =>
    tokens.map((t) => t.text).join(_space);

/// One line: tokens [from] to [to] (exclusive), right to left.
class ShareLine {
  const ShareLine(this.from, this.to, {required this.justified});

  final int from;
  final int to;

  /// Stretched to the full width (its spaces widened); otherwise set from
  /// the right with plain spaces.
  final bool justified;

  int get length => to - from;
}

/// Greedy line breaking of tokens [from]..[to) into lines no wider than
/// [width], [space] apart at least. A token wider than the line takes a
/// line of its own.
List<(int, int)> breakLines(
  List<double> widths,
  double width,
  double space, {
  int from = 0,
  int? to,
}) {
  final end = to ?? widths.length;
  final lines = <(int, int)>[];
  var start = from;
  while (start < end) {
    var used = widths[start];
    var i = start + 1;
    while (i < end && used + space + widths[i] <= width + 1e-6) {
      used += space + widths[i];
      i++;
    }
    lines.add((start, i));
    start = i;
  }
  return lines;
}

/// Where each token of a line is drawn: its right edge, from the line's
/// right edge (0) leftwards. A justified line of more than one token shares
/// the free room equally between its spaces; the others use [space].
List<double> placeLine(
  List<double> widths,
  ShareLine line,
  double width,
  double space,
) {
  final n = line.length;
  var gap = space;
  if (line.justified && n > 1) {
    var used = 0.0;
    for (var i = line.from; i < line.to; i++) {
      used += widths[i];
    }
    gap = (width - used) / (n - 1);
    if (gap < space) gap = space;
  }
  final out = <double>[];
  var x = 0.0;
  for (var i = line.from; i < line.to; i++) {
    out.add(x);
    x += widths[i] + gap;
  }
  return out;
}

/// One image of the passage: its lines, and whether it is the first image
/// of its surah's part of the passage (the basmala goes there).
class SharePageLayout {
  const SharePageLayout({
    required this.surah,
    required this.lines,
    required this.firstOfSurah,
  });

  final int surah;
  final List<ShareLine> lines;
  final bool firstOfSurah;

  int get from => lines.first.from;
  int get to => lines.last.to;
}

/// How many lines an image holds: [first] when it opens its surah's part
/// with the basmala line, [rest] otherwise.
typedef ShareCapacity = int Function({required bool withBasmala});

/// The passage split into images. Each surah of the passage starts a new
/// image (its own header). An image ends at a verse end when one fits;
/// only a verse longer than a whole image is cut, at a line break. Lines
/// are justified, except the last line of an image that ends at a verse
/// end (the end of the passage, or of the image's part of it), which is
/// set from the right.
List<SharePageLayout> paginate({
  required List<ShareToken> tokens,
  required List<ShareVerse> verses,
  required List<double> widths,
  required double width,
  required double space,
  required ShareCapacity capacity,
  required bool Function(int surah) hasBasmala,
}) {
  assert(tokens.length == widths.length);
  final pages = <SharePageLayout>[];
  var start = 0;
  while (start < tokens.length) {
    final surah = verses[tokens[start].verse].surah;
    var end = start;
    while (end < tokens.length && verses[tokens[end].verse].surah == surah) {
      end++;
    }
    var first = true;
    while (start < end) {
      final withBasmala = first && hasBasmala(surah);
      final cap = capacity(withBasmala: withBasmala);
      assert(cap > 0);
      final lines = breakLines(widths, width, space, from: start, to: end);
      int stop;
      int lineCount;
      if (lines.length <= cap) {
        stop = end;
        lineCount = lines.length;
      } else {
        // The last verse end within the first [cap] lines.
        stop = -1;
        lineCount = 0;
        for (var l = 0; l < cap; l++) {
          for (var i = lines[l].$1; i < lines[l].$2; i++) {
            if (tokens[i].endsVerse) {
              stop = i + 1;
              lineCount = l + 1;
            }
          }
        }
        if (stop < 0) {
          // A verse longer than the image: cut it after [cap] full lines.
          stop = lines[cap - 1].$2;
          lineCount = cap;
        }
      }
      final endsAtVerse = tokens[stop - 1].endsVerse;
      final page = <ShareLine>[];
      for (var l = 0; l < lineCount; l++) {
        final (a, b) = lines[l];
        final to = b > stop ? stop : b;
        final last = l == lineCount - 1;
        page.add(ShareLine(a, to, justified: !(last && endsAtVerse)));
      }
      pages.add(
        SharePageLayout(surah: surah, lines: page, firstOfSurah: first),
      );
      first = false;
      start = stop;
    }
  }
  return pages;
}
