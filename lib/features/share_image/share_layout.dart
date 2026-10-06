/// Line breaking, justification and the split into images of a passage
/// shared as pictures. Pure layout: the widths of the words come from the
/// caller (the font), and nothing here reads or changes a character.
library;

import 'share_text_runs.dart';

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

/// Where a word stands in a printed mushaf: its page, and its line on that
/// page (from 0, top to bottom).
typedef MushafPlace = ({int page, int line});

/// A word's box on a mushaf page (page units): word [word] of verse
/// [surah]:[ayah], numbered from 1 as the KFGQPC text's words (۞ and the
/// verse number not counted).
typedef MushafWordBox = ({
  int surah,
  int ayah,
  int word,
  int page,
  double left,
  double top,
  double right,
  double bottom,
});

/// The page and line of each word of [boxes], from the word boxes and the
/// line cuts the page view itself splits a page with ([cuts]: the y of the
/// cuts between its lines, top to bottom; empty for the two opening pages).
///
/// A word is on the line whose band holds the middle of its box. A box
/// taller than a line and a third (a mark of the line above or below was
/// joined to it) is on the line of the word before it when it stands to
/// that word's left, else on the line of the word after it when it stands
/// to that one's right: words follow each other right to left. On a page
/// without cuts, the lines are the rows of box middles, rows more than
/// [pitch] × 0.4 apart.
Map<(int, int, int), MushafPlace> mushafPlaces(
  Iterable<MushafWordBox> boxes, {
  required List<double> Function(int page) cuts,
  required double pitch,
}) {
  final sorted = boxes.toList()
    ..sort((a, b) {
      final s = a.surah.compareTo(b.surah);
      if (s != 0) return s;
      final v = a.ayah.compareTo(b.ayah);
      return v != 0 ? v : a.word.compareTo(b.word);
    });
  double mid(MushafWordBox b) => (b.top + b.bottom) / 2;
  double midX(MushafWordBox b) => (b.left + b.right) / 2;

  // Pages without cuts: rows of box middles.
  final rows = <int, List<double>>{};
  for (final b in sorted) {
    if (cuts(b.page).isEmpty) (rows[b.page] ??= []).add(mid(b));
  }
  final rowStarts = <int, List<double>>{};
  for (final MapEntry(key: page, value: ys) in rows.entries) {
    ys.sort();
    final starts = <double>[ys.first];
    for (var i = 1; i < ys.length; i++) {
      if (ys[i] - ys[i - 1] > pitch * 0.4) starts.add(ys[i]);
    }
    rowStarts[page] = starts;
  }

  int lineAt(int page, double y) {
    final c = cuts(page);
    if (c.isNotEmpty) return c.where((cut) => cut < y).length;
    return rowStarts[page]!.where((s) => s <= y).length - 1;
  }

  final lines = [for (final b in sorted) lineAt(b.page, mid(b))];
  for (var i = 0; i < sorted.length; i++) {
    final b = sorted[i];
    final c = cuts(b.page);
    if (c.isEmpty || b.bottom - b.top <= pitch * 4 / 3) continue;
    // The lines the box reaches.
    final reach = <int>{
      for (var l = 0; l <= c.length; l++)
        if ((l == 0 || b.bottom > c[l - 1]) && (l == c.length || b.top < c[l]))
          l,
    };
    final before = i > 0 && sorted[i - 1].page == b.page ? i - 1 : null;
    final after = i + 1 < sorted.length && sorted[i + 1].page == b.page
        ? i + 1
        : null;
    if (before != null &&
        reach.contains(lines[before]) &&
        midX(b) < midX(sorted[before])) {
      lines[i] = lines[before];
    } else if (after != null &&
        reach.contains(lines[after]) &&
        midX(b) > midX(sorted[after])) {
      lines[i] = lines[after];
    }
  }
  return {
    for (var i = 0; i < sorted.length; i++)
      (sorted[i].surah, sorted[i].ayah, sorted[i].word): (
        page: sorted[i].page,
        line: lines[i],
      ),
  };
}

/// The number, in its verse, of each token's first word (from 1; ۞ and the
/// verse number are not words). A token without a word (a verse number
/// standing alone) gets the number its next word would have.
List<int> tokenFirstWords(List<ShareToken> tokens) {
  final out = <int>[];
  var word = 1;
  for (var i = 0; i < tokens.length; i++) {
    if (i > 0 && tokens[i].verse != tokens[i - 1].verse) word = 1;
    out.add(word);
    word += wordsInToken(tokens[i].text, endsVerse: tokens[i].endsVerse);
  }
  return out;
}

/// The passage split as a printed mushaf splits it: one image for each
/// page of the mushaf (and each surah on it), holding that page's words
/// of the passage, one line of the image for each line of the page, the
/// line's words exactly. [placeOf] gives the place of word (surah, ayah,
/// word). Null when a word of the passage has no place (its boxes are
/// missing), so the caller lays the passage out otherwise.
List<SharePageLayout>? paginateByMushaf({
  required List<ShareToken> tokens,
  required List<ShareVerse> verses,
  required MushafPlace? Function(int surah, int ayah, int word) placeOf,
}) {
  if (tokens.isEmpty) return null;
  final firstWords = tokenFirstWords(tokens);
  final places = List<MushafPlace?>.filled(tokens.length, null);
  for (var i = 0; i < tokens.length; i++) {
    final t = tokens[i];
    if (wordsInToken(t.text, endsVerse: t.endsVerse) == 0) continue;
    final v = verses[t.verse];
    final place = placeOf(v.surah, v.ayah, firstWords[i]);
    if (place == null) return null;
    places[i] = place;
  }
  // A token without a word stays with the word before it (or after it).
  for (var i = 0; i < tokens.length; i++) {
    places[i] ??= i > 0 ? places[i - 1] : null;
  }
  for (var i = tokens.length - 1; i >= 0; i--) {
    places[i] ??= i + 1 < tokens.length ? places[i + 1] : null;
  }
  if (places.any((p) => p == null)) return null;

  final pages = <SharePageLayout>[];
  final seen = <int>{};
  var lines = <ShareLine>[];
  var start = 0;
  var lineStart = 0;
  void closeLine(int end) {
    if (end > lineStart) lines.add(ShareLine(lineStart, end, justified: false));
    lineStart = end;
  }

  void closePage(int end) {
    closeLine(end);
    if (lines.isEmpty) return;
    final surah = verses[tokens[start].verse].surah;
    pages.add(
      SharePageLayout(
        surah: surah,
        lines: lines,
        firstOfSurah: seen.add(surah),
      ),
    );
    lines = <ShareLine>[];
    start = end;
  }

  for (var i = 1; i < tokens.length; i++) {
    final a = places[i - 1]!, b = places[i]!;
    final newSurah =
        verses[tokens[i].verse].surah != verses[tokens[i - 1].verse].surah;
    if (newSurah || a.page != b.page) {
      closePage(i);
    } else if (a.line != b.line) {
      closeLine(i);
    }
  }
  closePage(tokens.length);
  return pages;
}
