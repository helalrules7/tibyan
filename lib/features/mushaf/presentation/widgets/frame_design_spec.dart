import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/theme_tokens.dart';

/// The six drawn frame designs (Abbasid, Umayyad, Andalusian, Ottoman,
/// Egyptian, Modern Islamic): geometry from Ahmed's SVGs and the look of
/// his reference sheet, built by tools/build_frame_designs.py into
/// `assets/config/frame_<set>.json`. Coordinates are design units; the
/// painters scale them to the page.

/// Colour roles of a design's SVG palette.
enum DesignRole { bg, ink, gold, accent }

DesignRole? _role(Object? name) =>
    name == null ? null : DesignRole.values.byName(name as String);

List<double> _nums(Object? list) => [
  for (final v in list! as List) (v as num).toDouble(),
];

double _d(Map<String, dynamic> j, String k, [double or = 0]) =>
    (j[k] as num?)?.toDouble() ?? or;

/// One drawable shape from the SVGs, in design units.
class DesignShape {
  DesignShape(
    this.path, {
    this.fill,
    this.stroke,
    this.width = 1,
    this.opacity = 1,
  });

  final Path path;
  final DesignRole? fill;
  final DesignRole? stroke;
  final double width;
  final double opacity;

  factory DesignShape.fromJson(Map<String, dynamic> j) {
    final path = Path();
    switch (j['k']) {
      case 'poly':
        final p = _nums(j['p']);
        path.addPolygon([
          for (var i = 0; i < p.length; i += 2) Offset(p[i], p[i + 1]),
        ], true);
      case 'line':
        final p = _nums(j['p']);
        path
          ..moveTo(p[0], p[1])
          ..lineTo(p[2], p[3]);
      case 'circle':
        final c = _nums(j['c']);
        path.addOval(
          Rect.fromCircle(center: Offset(c[0], c[1]), radius: _d(j, 'r')),
        );
      case 'rect':
        final r = _nums(j['r']);
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(r[0], r[1], r[2], r[3]),
            Radius.circular(_d(j, 'rx')),
          ),
        );
      default:
        for (final c in j['d'] as List) {
          final v = _nums((c as List).sublist(1));
          switch (c[0]) {
            case 'M':
              path.moveTo(v[0], v[1]);
            case 'L':
              path.lineTo(v[0], v[1]);
            case 'Q':
              path.quadraticBezierTo(v[0], v[1], v[2], v[3]);
            case 'C':
              path.cubicTo(v[0], v[1], v[2], v[3], v[4], v[5]);
            case 'Z':
              path.close();
          }
        }
    }
    return DesignShape(
      path,
      fill: _role(j['fill']),
      stroke: _role(j['stroke']),
      width: _d(j, 'w', 1),
      opacity: _d(j, 'o', 1),
    );
  }

  /// Paints in the canvas's current (design-unit) space. Strokes are kept
  /// at least [minWidth] design units wide.
  void paint(
    Canvas canvas,
    Color Function(DesignRole) colour, {
    double minWidth = 0,
    double alpha = 1,
  }) {
    Color c(DesignRole r) {
      final base = colour(r);
      return base.withValues(alpha: base.a * opacity * alpha);
    }

    if (fill != null) canvas.drawPath(path, Paint()..color = c(fill!));
    if (stroke != null) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width < minWidth ? minWidth : width
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = c(stroke!),
      );
    }
  }
}

/// Shapes around one point, reaching [r] design units from it.
class ShapeGroup {
  const ShapeGroup(this.shapes, this.r);

  final List<DesignShape> shapes;
  final double r;

  factory ShapeGroup.fromJson(Map<String, dynamic> j, {double? r}) =>
      ShapeGroup([
        for (final s in j['shapes'] as List)
          DesignShape.fromJson(s as Map<String, dynamic>),
      ], r ?? _d(j, 'r', 1));

  /// Paints the group centred on [centre], [radius] pixels across its
  /// reach, strokes at least [minStroke] pixels wide.
  void paint(
    Canvas canvas,
    Offset centre,
    double radius,
    Color Function(DesignRole) colour, {
    double minStroke = 0.8,
    double alpha = 1,
  }) {
    final k = radius / r;
    canvas
      ..save()
      ..translate(centre.dx, centre.dy)
      ..scale(k);
    for (final s in shapes) {
      s.paint(canvas, colour, minWidth: minStroke / k, alpha: alpha);
    }
    canvas.restore();
  }
}

/// A rule of the page frame: a rectangle [inset] units inside the outer one.
class RuleSpec {
  const RuleSpec(this.inset, this.role, this.width, this.opacity);

  final double inset;
  final DesignRole role;
  final double width;
  final double opacity;

  factory RuleSpec.fromJson(Map<String, dynamic> j) => RuleSpec(
    _d(j, 'inset'),
    _role(j['stroke'])!,
    _d(j, 'w', 1),
    _d(j, 'o', 1),
  );
}

/// The pointed cartouche of the surah divider (tip, shoulder, half height).
class HexSpec {
  const HexSpec(this.half, this.point, this.inset, this.width);

  final double half;
  final double point;

  /// Inner outline only: how far its tip sits inside the outer tip.
  final double inset;
  final double width;

  factory HexSpec.fromJson(Map<String, dynamic> j) =>
      HexSpec(_d(j, 'half'), _d(j, 'point'), _d(j, 'inset'), _d(j, 'w', 1));
}

/// The look of the reference sheet, beyond the SVGs' line art.
class LookSpec {
  const LookSpec({
    required this.band,
    required this.tile,
    required this.rosette,
    required this.arch,
    required this.m1,
    required this.m2,
    this.lamp = false,
  });

  /// Ground of the band.
  final Color band;

  /// Tile repeated along the band: star8, lozenge, zellige, tulip, mosaic
  /// or lines.
  final String tile;

  /// Corner and margin rosette: star8, flower or quatrefoil.
  final String rosette;

  /// Arch over the opening pages: pointed, round, horseshoe or ogee.
  final String arch;

  /// The tile's two colours (the SVG palette's gold is the third).
  final Color m1;
  final Color m2;

  /// A hanging lamp under the cover's arch.
  final bool lamp;

  factory LookSpec.fromJson(Map<String, dynamic> j) => LookSpec(
    band: parseHexColor(j['band'] as String),
    tile: j['tile'] as String,
    rosette: j['rosette'] as String,
    arch: j['arch'] as String,
    m1: parseHexColor(j['m1'] as String),
    m2: parseHexColor(j['m2'] as String),
    lamp: j['lamp'] as bool? ?? false,
  );
}

/// The title cartouche and ornament of one opening page.
class OpeningSpec {
  const OpeningSpec({required this.title, required this.ornament});

  /// Title box in units of the design's page (width, height).
  final Size title;
  final ShapeGroup ornament;
}

class FrameDesignSpec {
  const FrameDesignSpec({
    required this.id,
    required this.palette,
    required this.dark,
    required this.rules,
    required this.rhythmSpacing,
    required this.corner,
    required this.cornerExtent,
    required this.medallion,
    required this.outer,
    required this.inner,
    required this.rosette,
    required this.cover,
    required this.coverRules,
    required this.coverSize,
    required this.openings,
    required this.signature,
    required this.look,
  });

  final String id;
  final Map<DesignRole, Color> palette;

  /// The design's own ground is dark (the Egyptian set).
  final bool dark;

  /// Rules of the page frame, outermost first.
  final List<RuleSpec> rules;

  /// Distance between repeats along the band.
  final double rhythmSpacing;

  /// The SVG corner ornament, from the frame's outer corner.
  final ShapeGroup corner;
  final double cornerExtent;

  /// Medallion at the foot of the page: the page number's rosettes.
  final ShapeGroup medallion;

  /// Surah-divider cartouche outlines and its end rosette.
  final HexSpec outer;
  final HexSpec inner;
  final ShapeGroup rosette;

  /// The splash's radial composition, around its centre, and its rules.
  final ShapeGroup cover;
  final List<RuleSpec> coverRules;
  final Size coverSize;

  /// Opening pages: 1 = al-Fatiha, 2 = al-Baqarah.
  final Map<int, OpeningSpec> openings;

  /// The signature ornament (two nested stars): the quarter marks.
  final ShapeGroup signature;
  final LookSpec look;

  Color operator [](DesignRole r) => palette[r]!;

  factory FrameDesignSpec.fromJson(Map<String, dynamic> j) {
    final page = j['page'] as Map<String, dynamic>;
    final div = j['divider'] as Map<String, dynamic>;
    final cartouche = div['cartouche'] as Map<String, dynamic>;
    final cover = j['cover'] as Map<String, dynamic>;
    final opening = j['opening'] as Map<String, dynamic>;
    final corner = page['corner'] as Map<String, dynamic>;
    final size = _nums(cover['size']);
    OpeningSpec open(String key) {
      final o = opening[key] as Map<String, dynamic>;
      final t = _nums((o['title'] as Map)['r']);
      return OpeningSpec(
        title: Size(t[2], t[3]),
        ornament: ShapeGroup.fromJson(o['ornament'] as Map<String, dynamic>),
      );
    }

    return FrameDesignSpec(
      id: j['id'] as String,
      palette: {
        for (final e in (j['palette'] as Map).entries)
          DesignRole.values.byName(e.key as String): parseHexColor(
            e.value as String,
          ),
      },
      dark: j['dark'] as bool,
      rules: [
        for (final r in page['rules'] as List)
          RuleSpec.fromJson(r as Map<String, dynamic>),
      ],
      rhythmSpacing: (((page['rhythm'] as List).first as Map)['spacing'] as num)
          .toDouble(),
      corner: ShapeGroup.fromJson(corner, r: _d(corner, 'extent')),
      cornerExtent: _d(corner, 'extent'),
      medallion: ShapeGroup.fromJson(page['medallion'] as Map<String, dynamic>),
      outer: HexSpec.fromJson(cartouche['outer'] as Map<String, dynamic>),
      inner: HexSpec.fromJson(cartouche['inner'] as Map<String, dynamic>),
      rosette: ShapeGroup.fromJson(div['rosette'] as Map<String, dynamic>),
      cover: ShapeGroup([
        for (final s in cover['motif'] as List)
          DesignShape.fromJson(s as Map<String, dynamic>),
      ], _d(cover, 'r')),
      coverRules: [
        for (final r in cover['rules'] as List)
          RuleSpec.fromJson(r as Map<String, dynamic>),
      ],
      coverSize: Size(size[0], size[1]),
      openings: {1: open('fatiha'), 2: open('baqarah')},
      signature: ShapeGroup.fromJson(j['signature'] as Map<String, dynamic>),
      look: LookSpec.fromJson(j['look'] as Map<String, dynamic>),
    );
  }
}

/// Asset of a drawn design; null for Zakhrafa and the plain frame.
String? frameSpecAsset(FrameDesign d) => switch (d) {
  FrameDesign.zakhrafa || FrameDesign.plain => null,
  FrameDesign.modernIslamic => 'assets/config/frame_modern_islamic.json',
  _ => 'assets/config/frame_${d.name}.json',
};

Future<FrameDesignSpec> loadFrameSpec(
  FrameDesign d, {
  AssetBundle? bundle,
}) async {
  final text = await (bundle ?? rootBundle).loadString(frameSpecAsset(d)!);
  return FrameDesignSpec.fromJson(jsonDecode(text) as Map<String, dynamic>);
}

/// Specs already read, so a design switch back is instant.
final _cache = <FrameDesign, FrameDesignSpec>{};

/// The spec of a drawn design (null for Zakhrafa and plain).
final frameSpecFamily = FutureProvider.family<FrameDesignSpec?, FrameDesign>((
  ref,
  design,
) async {
  if (frameSpecAsset(design) == null) return null;
  return _cache[design] ??= await loadFrameSpec(design);
});

// ── Colours in each mode ─────────────────────────────────────────────

double _lum(Color c) => c.computeLuminance();

double _contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

/// [c] moved toward white (on a dark ground) or black (on a light one)
/// until it stands out from [ground] by at least [min]:1.
Color legibleOn(Color c, Color ground, {double min = 2.2}) {
  final toward = _lum(ground) < 0.2
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF000000);
  var out = c;
  for (var i = 0; i < 8 && _contrast(out, ground) < min; i++) {
    out = Color.lerp(out, toward, 0.15)!;
  }
  return out;
}

/// A design's colours for one theme mode.
///
/// The rule: a band whose ground is dark (Abbasid green, Andalusian
/// cobalt, Egyptian navy) keeps it in every mode; a light band (Ottoman,
/// Umayyad, Modern Islamic) turns, in night and black modes, into a deep
/// tint of the design's own ink over the theme's paper. Tile colours keep
/// their hue and are lifted or deepened only as far as needed to stand
/// out from the band (2.2:1). Lines drawn on the page's paper use the
/// design's ink in light mode and swap to the design's light ground in
/// the dark modes (for the dark Egyptian design: the other way round), so
/// they read on the theme's paper. Black mode dims everything by a fifth.
class FramePalette {
  FramePalette._({
    required this.paper,
    required this.band,
    required this.m1,
    required this.m2,
    required this.gold,
    required this.ink,
    required this.accent,
  });

  /// The theme's paper: the page and the cartouches.
  final Color paper;
  final Color band;
  final Color m1;
  final Color m2;

  /// Rules and outlines (the design's gold).
  final Color gold;

  /// Lines on the paper.
  final Color ink;
  final Color accent;

  /// Colour of an SVG role drawn on the paper.
  Color onPaper(DesignRole r) => switch (r) {
    DesignRole.bg => paper,
    DesignRole.ink => ink,
    DesignRole.gold => gold,
    DesignRole.accent => accent,
  };

  /// Colour of an SVG role drawn on the band.
  Color onBand(DesignRole r) => switch (r) {
    DesignRole.bg => band,
    DesignRole.ink => m2,
    DesignRole.gold => gold,
    DesignRole.accent => m1,
  };

  factory FramePalette.resolve(
    FrameDesignSpec spec,
    ModeTokens t,
    ThemeModeId mode,
  ) {
    final darkMode = mode != ThemeModeId.light;
    final look = spec.look;
    final designInk = spec[DesignRole.ink];
    final designBg = spec[DesignRole.bg];
    var band = look.band;
    if (darkMode && _lum(band) > 0.3) {
      band = Color.lerp(t.paper, spec.dark ? designBg : designInk, 0.45)!;
    }
    // A dark band as dark as the paper would melt into it: deepen it.
    if (darkMode && _contrast(band, t.paper) < 1.25) {
      band = Color.lerp(band, const Color(0xFF000000), 0.4)!;
    }
    // Lines on the paper: the design's ink, or its ground when the page's
    // lightness is the other way round.
    var ink = darkMode == spec.dark ? designInk : designBg;
    ink = legibleOn(ink, t.paper, min: 3);
    var gold = legibleOn(spec[DesignRole.gold], band, min: 2);
    var accent = legibleOn(spec[DesignRole.accent], t.paper, min: 2);
    // m1 fills shapes outlined in gold: it keeps its colour, except on a
    // band that turned dark, where a dark fill would vanish.
    var m1 = band == look.band ? look.m1 : legibleOn(look.m1, band, min: 1.6);
    var m2 = legibleOn(look.m2, band);
    if (mode == ThemeModeId.black) {
      Color dim(Color c) => Color.lerp(c, const Color(0xFF000000), 0.2)!;
      band = dim(band);
      m1 = dim(m1);
      m2 = dim(m2);
      gold = dim(gold);
      ink = dim(ink);
      accent = dim(accent);
    }
    return FramePalette._(
      paper: t.paper,
      band: band,
      m1: m1,
      m2: m2,
      gold: gold,
      ink: ink,
      accent: accent,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FramePalette &&
      other.paper == paper &&
      other.band == band &&
      other.m1 == m1 &&
      other.m2 == m2 &&
      other.gold == gold &&
      other.ink == ink &&
      other.accent == accent;

  @override
  int get hashCode => Object.hash(paper, band, m1, m2, gold, ink, accent);
}
