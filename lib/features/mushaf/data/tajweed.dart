import 'dart:isolate';
import 'dart:ui';

import '../../../core/settings/app_settings.dart';
import 'svg_contours.dart';

/// The tajweed rules of the cpfair/quran-tajweed data (CC BY 4.0), in the
/// order tools/build_tajweed.py numbers them (`RULES`). The rules and where
/// they apply come from the data; the app only colours them.
enum TajweedRule {
  hamzatWasl('hamzat_wasl'),
  lamShamsiyyah('lam_shamsiyyah'),
  silent('silent'),
  madd2('madd_2'),
  madd246('madd_246'),
  maddMuttasil('madd_muttasil'),
  maddMunfasil('madd_munfasil'),
  madd6('madd_6'),
  ghunnah('ghunnah'),
  ikhfa('ikhfa'),
  ikhfaShafawi('ikhfa_shafawi'),
  iqlab('iqlab'),
  idghaamGhunnah('idghaam_ghunnah'),
  idghaamNoGhunnah('idghaam_no_ghunnah'),
  idghaamShafawi('idghaam_shafawi'),
  idghaamMutajanisayn('idghaam_mutajanisayn'),
  idghaamMutaqaribayn('idghaam_mutaqaribayn'),
  qalqalah('qalqalah');

  const TajweedRule(this.key);

  /// The rule's key in the data.
  final String key;

  static TajweedRule? byKey(String key) {
    for (final r in values) {
      if (r.key == key) return r;
    }
    return null;
  }
}

/// A colour a reader can give a rule. Each has a shade for light paper and
/// one for dark paper, both at least 3:1 against every style's paper
/// (test/tajweed_test.dart checks this).
enum TajweedHue {
  crimson(Color(0xFF8E1B1B), Color(0xFFFFAAAA)),
  red(Color(0xFFD32F2F), Color(0xFFFF5C5C)),
  orange(Color(0xFFB85A00), Color(0xFFFFD27A)),
  gold(Color(0xFF8A6D00), Color(0xFFE6C84A)),
  green(Color(0xFF1B5E20), Color(0xFF4CBB50)),
  lightGreen(Color(0xFF2E7D32), Color(0xFF8CE08F)),
  teal(Color(0xFF00796B), Color(0xFF4DD0C4)),
  blue(Color(0xFF1565C0), Color(0xFF7FB2FF)),
  purple(Color(0xFF7B1FA2), Color(0xFFD59BF0)),
  pink(Color(0xFFC2185B), Color(0xFFFF8AB8)),
  grey(Color(0xFF7A7A7A), Color(0xFFD0D0D0)),
  violet(Color(0xFF7E3FBF), Color(0xFFB98AE8)),
  amber(Color(0xFFB07D00), Color(0xFFF0C75E));

  const TajweedHue(this.light, this.dark);

  final Color light;
  final Color dark;

  Color on({required bool darkPaper}) => darkPaper ? dark : light;

  static TajweedHue? byName(String? name) {
    for (final h in values) {
      if (h.name == name) return h;
    }
    return null;
  }
}

/// The colours a rule starts with. The groups follow the colour key of
/// alquran.cloud's tajweed guide (a copy on Tibyan's mirror,
/// alquran-cloud-quran-tajweed/; docs/features/tajweed_colors.md): the letters that are not pronounced
/// (hamzat al-wasl, the solar lam, silent letters, and the two idghaam of
/// close letters) share one colour; every madd has a colour, the plain
/// 2-count madd a lighter one; idghaam without ghunnah sits with the other
/// idghaam. Where that key uses grey, a violet is used instead: grey on
/// black ink (or on light ink at night) cannot be told from the ink.
const defaultTajweedHues = <TajweedRule, TajweedHue?>{
  TajweedRule.hamzatWasl: TajweedHue.violet,
  TajweedRule.lamShamsiyyah: TajweedHue.violet,
  TajweedRule.silent: TajweedHue.violet,
  TajweedRule.madd2: TajweedHue.amber,
  TajweedRule.madd246: TajweedHue.orange,
  TajweedRule.maddMuttasil: TajweedHue.red,
  TajweedRule.maddMunfasil: TajweedHue.red,
  TajweedRule.madd6: TajweedHue.crimson,
  TajweedRule.ghunnah: TajweedHue.green,
  TajweedRule.ikhfa: TajweedHue.green,
  TajweedRule.ikhfaShafawi: TajweedHue.green,
  TajweedRule.iqlab: TajweedHue.green,
  TajweedRule.idghaamGhunnah: TajweedHue.green,
  TajweedRule.idghaamNoGhunnah: TajweedHue.green,
  TajweedRule.idghaamShafawi: TajweedHue.green,
  TajweedRule.idghaamMutajanisayn: TajweedHue.violet,
  TajweedRule.idghaamMutaqaribayn: TajweedHue.violet,
  TajweedRule.qalqalah: TajweedHue.blue,
};

/// Whether [edition] has tajweed data. The riwaya editions have none: no
/// reviewed source annotates Warsh, Qalun, al-Duri or Shu'bah, and no rule
/// is made up for a riwaya (docs/MISSING_DATA.md, gap 10).
bool editionHasTajweed(MushafEdition edition) => !edition.isRiwaya;

/// A rule's colour: the reader's choice when there is one ([choices] maps
/// a rule's key to a hue name, or to '' for no colour), else the default.
TajweedHue? tajweedHueOf(TajweedRule rule, Map<String, String> choices) {
  final chosen = choices[rule.key];
  if (chosen == null) return defaultTajweedHues[rule];
  return TajweedHue.byName(chosen);
}

/// One coloured piece of a new-edition page: a contour of the page text
/// (its index in document order), clipped to [x0]..[x1] (page units) when
/// only part of it is the letter.
typedef TajweedContour = ({
  TajweedRule rule,
  int contour,
  double? x0,
  double? x1,
});

/// Parses a `madina1441` row of `tajweed_page`: "rule,contour[,x0,x1];...".
List<TajweedContour> parseTajweedContours(String data) => [
  for (final e in data.split(';'))
    if (e.isNotEmpty)
      if (e.split(',') case [final r, final c, ...final x])
        (
          rule: TajweedRule.values[int.parse(r)],
          contour: int.parse(c),
          x0: x.length == 2 ? double.parse(x[0]) : null,
          x1: x.length == 2 ? double.parse(x[1]) : null,
        ),
];

/// Parses a page-image row of `tajweed_page`: "rule,x0,y0,x1,y1;..." (px).
List<(TajweedRule, Rect)> parseTajweedRects(String data) => [
  for (final e in data.split(';'))
    if (e.isNotEmpty)
      if (e.split(',').map(int.parse).toList() case [
        final r,
        final x0,
        final y0,
        final x1,
        final y1,
      ])
        (
          TajweedRule.values[r],
          Rect.fromLTRB(
            x0.toDouble(),
            y0.toDouble(),
            x1.toDouble(),
            y1.toDouble(),
          ),
        ),
];

/// One coloured piece of a new-edition page (page units): a contour of the
/// page text, or the part of it inside [clip] when only part of it is the
/// letter.
class TajweedPiece {
  TajweedPiece(this.rule, this.path, this.clip, this.bounds);

  final TajweedRule rule;

  /// The whole contour.
  final Path path;

  /// The letter's span, as wide as the letter and as tall as the contour
  /// (and a unit more): what of [path] is coloured. Null for the whole
  /// contour.
  final Rect? clip;

  /// The bounds of the coloured part: the line it is drawn with is the one
  /// its centre falls on.
  final Rect bounds;
}

/// A [TajweedPiece] as plain data, which a worker isolate can build.
typedef TajweedPieceGeometry = ({
  TajweedRule rule,
  ContourGeometry contour,
  Rect? clip,
  Rect bounds,
});

/// Each coloured piece of a new-edition page, from the page's SVG text and
/// its `tajweed_page` row. Reading the SVG is most of the work (the whole
/// page text is read to count its contours); see [loadTajweedPieces],
/// which does it off the main isolate.
List<TajweedPiece> tajweedPieces(String svg, List<TajweedContour> entries) =>
    _toPieces(tajweedPieceGeometry(svg, entries));

List<TajweedPiece> _toPieces(List<TajweedPieceGeometry> geometry) => [
  for (final g in geometry)
    TajweedPiece(g.rule, g.contour.toPath(), g.clip, g.bounds),
];

/// [tajweedPieces] as plain data, without dart:ui: run on a worker isolate.
List<TajweedPieceGeometry> tajweedPieceGeometry(
  String svg,
  List<TajweedContour> entries,
) {
  final contours = pageContourGeometry(
    svg,
    wanted: {for (final e in entries) e.contour},
  );
  return [
    for (final e in entries)
      if (contours[e.contour] case final c?)
        // A span that runs backwards (x1 before x0) holds nothing: it was
        // never coloured (its clip, built by Path.combine, was empty), and
        // is still not.
        if (e.x0 != null && e.x1 != null && e.x1! <= e.x0!)
          ...const <TajweedPieceGeometry>[]
        else if (e.x0 != null && e.x1 != null)
          () {
            final b = c.bounds;
            final clip = Rect.fromLTRB(e.x0!, b.top - 1, e.x1!, b.bottom + 1);
            return (
              rule: e.rule,
              contour: c,
              clip: clip,
              bounds: _clippedBounds(c, clip) ?? b.intersect(clip),
            );
          }()
        else
          (rule: e.rule, contour: c, clip: null, bounds: c.bounds),
  ];
}

/// The bounds of the part of [c] inside [clip]'s x span, from its outline
/// followed in short steps; null when none of it is inside.
Rect? _clippedBounds(ContourGeometry c, Rect clip) {
  final x0 = clip.left, x1 = clip.right;
  double? l, t, r, b;
  void take(double x, double y) {
    if (x < x0 - 1e-9 || x > x1 + 1e-9) return;
    l = l == null || x < l! ? x : l;
    r = r == null || x > r! ? x : r;
    t = t == null || y < t! ? y : t;
    b = b == null || y > b! ? y : b;
  }

  var px = 0.0, py = 0.0, sx = 0.0, sy = 0.0;
  // A step of the outline from (px, py) to (x, y): its ends, and where it
  // crosses either edge of the span.
  void step(double x, double y) {
    take(x, y);
    for (final edge in [x0, x1]) {
      if ((px - edge) * (x - edge) < 0) {
        take(edge, py + (y - py) * (edge - px) / (x - px));
      }
    }
    px = x;
    py = y;
  }

  const steps = 16;
  final p = c.points;
  var k = 0;
  for (final v in c.verbs) {
    switch (v) {
      case ContourGeometry.moveVerb:
        px = sx = p[k];
        py = sy = p[k + 1];
        take(px, py);
        k += 2;
      case ContourGeometry.lineVerb:
        step(p[k], p[k + 1]);
        k += 2;
      case ContourGeometry.quadVerb:
        final (ax, ay) = (px, py);
        for (var i = 1; i <= steps; i++) {
          final s = i / steps, u = 1 - s;
          step(
            u * u * ax + 2 * u * s * p[k] + s * s * p[k + 2],
            u * u * ay + 2 * u * s * p[k + 1] + s * s * p[k + 3],
          );
        }
        k += 4;
      case ContourGeometry.cubicVerb:
        final (ax, ay) = (px, py);
        for (var i = 1; i <= steps; i++) {
          final s = i / steps, u = 1 - s;
          step(
            u * u * u * ax +
                3 * u * u * s * p[k] +
                3 * u * s * s * p[k + 2] +
                s * s * s * p[k + 4],
            u * u * u * ay +
                3 * u * u * s * p[k + 1] +
                3 * u * s * s * p[k + 3] +
                s * s * s * p[k + 5],
          );
        }
        k += 6;
      default:
        step(sx, sy);
    }
  }
  if (l == null) return null;
  return Rect.fromLTRB(l!, t!, r!, b!);
}

/// The coloured pieces of page [page] for its `tajweed_page` row [data],
/// with [svg] its text. The SVG is read on a worker isolate, so the main
/// isolate only builds the pieces' few paths; the pages read last are kept,
/// so a page turned back to, or built again, costs nothing.
Future<List<TajweedPiece>> loadTajweedPieces(
  int page,
  String svg,
  String data,
) {
  final key = (page, svg.length, data);
  final hit = _piecesCache.remove(key);
  if (hit != null) return _piecesCache[key] = hit;
  final load = _readOffMain(
    svg,
    parseTajweedContours(data),
    page,
  ).then(_toPieces);
  _piecesCache[key] = load;
  if (_piecesCache.length > _piecesCacheSize) {
    _piecesCache.remove(_piecesCache.keys.first);
  }
  // A failed read is not kept.
  load.catchError((Object _) {
    if (identical(_piecesCache[key], load)) _piecesCache.remove(key);
    return const <TajweedPiece>[];
  });
  return load;
}

/// [tajweedPieceGeometry] on a worker isolate. A function of its own, so
/// the closure sent to the worker holds nothing but its arguments.
Future<List<TajweedPieceGeometry>> _readOffMain(
  String svg,
  List<TajweedContour> entries,
  int page,
) => Isolate.run(
  () => tajweedPieceGeometry(svg, entries),
  debugName: 'tajweed $page',
);

/// The page, its SVG's length and the row; most recently used last.
final _piecesCache = <(int, int, String), Future<List<TajweedPiece>>>{};

/// The page on screen, its neighbours, and a few turned back to.
const _piecesCacheSize = 6;

/// The parsed rows of [parseTajweedRects], by row: an image page is built
/// again on every touch and every recitation step, and a row runs to
/// thousands of numbers.
List<(TajweedRule, Rect)> tajweedRectsOf(String data) {
  final hit = _rectsCache.remove(data);
  if (hit != null) return _rectsCache[data] = hit;
  final rects = parseTajweedRects(data);
  _rectsCache[data] = rects;
  if (_rectsCache.length > _piecesCacheSize) {
    _rectsCache.remove(_rectsCache.keys.first);
  }
  return rects;
}

final _rectsCache = <String, List<(TajweedRule, Rect)>>{};
