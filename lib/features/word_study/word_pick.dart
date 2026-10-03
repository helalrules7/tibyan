import 'dart:ui';

/// The word under [point] on a page, from the page's word boxes keyed by
/// (surah, verse, word) in the same units as [point]. A box counts when
/// [point] lies within [slop] of it; of several, the one whose centre is
/// nearest wins. When [verse] is known (the verse under the point), only
/// its words are considered. Null when no box is close enough.
(int, int, int)? wordUnder(
  Map<(int, int, int), List<Rect>> boxes,
  Offset point, {
  ({int surah, int ayah})? verse,
  double slop = 0,
}) {
  (int, int, int)? best;
  var bestDistance = double.infinity;
  for (final MapEntry(key: key, value: pieces) in boxes.entries) {
    if (verse != null && (key.$1 != verse.surah || key.$2 != verse.ayah)) {
      continue;
    }
    for (final r in pieces) {
      if (!r.inflate(slop).contains(point)) continue;
      final d = (r.center - point).distance;
      if (d < bestDistance) {
        bestDistance = d;
        best = key;
      }
    }
  }
  return best;
}
