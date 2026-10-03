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

/// The coloured letters of a new-edition page as one clip path per rule
/// (page units), from the page's SVG text and its `tajweed_page` row.
Map<TajweedRule, Path> tajweedPaths(String svg, List<TajweedContour> entries) {
  final out = <TajweedRule, Path>{};
  for (final (rule, p) in tajweedPieces(svg, entries)) {
    (out[rule] ??= Path()).addPath(p, Offset.zero);
  }
  return out;
}

/// Each coloured piece of a new-edition page (page units): a contour of
/// the page text, or the part of it inside its letter's clip.
List<(TajweedRule, Path)> tajweedPieces(
  String svg,
  List<TajweedContour> entries,
) {
  final contours = pageContours(
    svg,
    wanted: {for (final e in entries) e.contour},
  );
  final out = <(TajweedRule, Path)>[];
  for (final e in entries) {
    var p = contours[e.contour];
    if (p == null) continue;
    if (e.x0 != null && e.x1 != null) {
      final b = p.getBounds();
      p = Path.combine(
        PathOperation.intersect,
        p,
        Path()..addRect(Rect.fromLTRB(e.x0!, b.top - 1, e.x1!, b.bottom + 1)),
      );
    }
    out.add((e.rule, p));
  }
  return out;
}
