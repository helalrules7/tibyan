import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/theme_tokens.dart';

/// The six drawn frame designs (Abbasid, Umayyad, Andalusian, Ottoman,
/// Egyptian, Modern Islamic) are the owner's own SVG artwork, drawn as it
/// is. tools/slice_frame_svgs.py cuts each design's SVGs into these pieces
/// (`assets/ornaments/frame_<set>_<piece>.svg`) without redrawing them.
enum FramePiece {
  /// Top-left corner of the page frame, 46 units square; mirrored for the
  /// other corners.
  corner('corner'),

  /// One 24-unit repeat of the top band, 34 units deep.
  edgeH('edge_h'),

  /// One 24-unit repeat of the left band, 34 units deep.
  edgeV('edge_v'),

  /// The page frame's bottom medallion.
  medal('medal'),

  /// The surah divider, cropped to its drawing.
  divider('divider'),

  /// The splash / cover composition, with its background.
  splash('splash'),

  /// The al-Fatiha and al-Baqarah opening pages, with their background.
  openA('open_a'),
  openB('open_b');

  const FramePiece(this.file);
  final String file;
}

/// File-name part of a drawn design; null for Zakhrafa and plain.
String? frameArtSet(FrameDesign d) => switch (d) {
  FrameDesign.zakhrafa || FrameDesign.plain => null,
  FrameDesign.modernIslamic => 'modern_islamic',
  _ => d.name,
};

String frameArtAsset(String set, FramePiece p) =>
    'assets/ornaments/frame_${set}_${p.file}.svg';

/// Places on the opening pages, in the units of the open_a / open_b
/// pieces (650 × 900). The owner's _04 file draws them at text panel
/// x=115 y=175 520×665 and title box x=170 y=120 410×90 (+650 in x for
/// al-Baqarah); the pieces start at (50, 50) and (700, 50).
abstract final class OpeningPlaces {
  static const panel = Rect.fromLTWH(65, 125, 520, 665);

  /// The part of the panel the mushaf page takes: below the title box,
  /// which overlaps the panel's top by 35 units in the owner's drawing.
  static const page = Rect.fromLTRB(65, 164, 585, 790);
  static const title = Rect.fromLTWH(120, 70, 410, 90);

  /// Between the panel and the frame's bottom rules (at 870).
  static const foot = Rect.fromLTRB(65, 794, 585, 856);

  /// Centre of the frame's bottom band, where the page number sits.
  static const pageNumber = Offset(325, 875);
}

/// A design's own colours, read from its SVGs.
class FrameColours {
  const FrameColours({
    required this.ground,
    required this.ink,
    required this.gold,
  });

  /// The paper of the owner's drawings (the splash's background).
  final Color ground;

  /// The frame's outer rule: the design's ink.
  final Color ink;

  /// The frame's middle rule.
  final Color gold;

  /// The design is drawn on a dark ground (the Egyptian set).
  bool get dark => ground.computeLuminance() < 0.2;

  static Color _hex(String svg, String pattern) {
    final m = RegExp(pattern).firstMatch(svg);
    if (m == null) throw FormatException('No colour for $pattern');
    return parseHexColor(m[1]!);
  }

  factory FrameColours.read({required String splash, required String corner}) {
    const hex = r'(#[0-9A-Fa-f]{6})';
    return FrameColours(
      ground: _hex(
        splash,
        '<rect width="[\\d.]+" height="[\\d.]+" fill="$hex"',
      ),
      ink: _hex(corner, '<rect x="120" y="80"[^>]*stroke="$hex"'),
      gold: _hex(corner, '<rect x="125" y="85"[^>]*stroke="$hex"'),
    );
  }
}

/// The SVG text of every piece of one design, and its colours.
class FrameSources {
  FrameSources(this.set, this.svg)
    : colours = FrameColours.read(
        splash: svg[FramePiece.splash]!,
        corner: svg[FramePiece.corner]!,
      ),
      dividerPanel = _dividerPanel(svg[FramePiece.divider]!);

  final String set;
  final Map<FramePiece, String> svg;
  final FrameColours colours;

  /// Where text goes over the divider's central cartouche, as fractions of
  /// the divider piece.
  final Rect dividerPanel;

  /// The divider's cartouche is its six-point path
  /// `M tipL,y L shoulderL,top L shoulderR,top L tipR,y L shoulderR,bottom
  /// L shoulderL,bottom Z`; the text keeps inside it.
  static Rect _dividerPanel(String svg) {
    final view = RegExp(r'viewBox="([-\d.]+) ([-\d.]+) ([\d.]+) ([\d.]+)"')
        .firstMatch(svg)!;
    final v = [for (var i = 1; i <= 4; i++) double.parse(view[i]!)];
    const n = r'([\d.]+)';
    final m = RegExp('d="M $n $n L $n $n L $n $n L $n $n L $n $n L $n $n Z"')
        .firstMatch(svg)!;
    final p = [for (var i = 1; i <= 12; i++) double.parse(m[i]!)];
    final tipL = p[0], shoulderL = p[2], top = p[3], tipR = p[6];
    final bottom = p[9];
    // A little in from the top and bottom edges, and from the tips as far
    // as the slanted sides require at that height.
    final pad = (bottom - top) * 0.04;
    final slant = (shoulderL - tipL) * 0.6;
    return Rect.fromLTRB(
      (tipL + slant - v[0]) / v[2],
      (top + pad - v[1]) / v[3],
      (tipR - slant - v[0]) / v[2],
      (bottom - pad - v[1]) / v[3],
    );
  }
}

Future<FrameSources> loadFrameSources(String set, {AssetBundle? bundle}) async {
  final b = bundle ?? rootBundle;
  final svg = {
    for (final p in FramePiece.values)
      p: await b.loadString(frameArtAsset(set, p)),
  };
  return FrameSources(set, svg);
}

String _hexOf(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// [svg] with each colour of [swap] replaced, in one pass.
String recolourSvg(String svg, Map<Color, Color> swap) {
  final to = {for (final e in swap.entries) _hexOf(e.key): _hexOf(e.value)};
  return svg.replaceAllMapped(
    RegExp('#[0-9A-Fa-f]{6}\\b'),
    (m) => to[m[0]!.toUpperCase()] ?? m[0]!,
  );
}

/// The one colour rule for the dark modes.
///
/// In light mode every design is drawn exactly in the owner's colours. In
/// night and black modes a light design (all but the Egyptian) would put
/// a bright page around the dark paper, so its two base colours are
/// swapped for the theme's: its paper colour becomes the theme's paper and
/// its ink colour the theme's ink. Its gold and accent colours stay. The
/// Egyptian design is already drawn light-on-dark and stays as it is in
/// every mode, on its own navy ground (see [FrameArt.ownGround]).
///
/// Returns null when the art is drawn as it is.
({Color paper, Color ink})? darkModeSwap(
  FrameColours c,
  ThemeModeId mode,
  ModeTokens t,
) => mode == ThemeModeId.light || c.dark ? null : (paper: t.paper, ink: t.ink);

/// The pictures of one design, ready to draw.
class FrameArt {
  const FrameArt({
    required this.pictures,
    required this.ground,
    required this.ink,
    required this.gold,
    required this.ownGround,
    required this.dividerPanel,
  });

  final Map<FramePiece, PictureInfo> pictures;
  PictureInfo operator [](FramePiece p) => pictures[p]!;

  /// The art's paper and ink as drawn (the theme's in a dark mode).
  final Color ground;
  final Color ink;
  final Color gold;

  /// A dark design: its band and banners are drawn on its own ground, as
  /// in the owner's files, since its light lines vanish on a light paper.
  final bool ownGround;

  /// See [FrameSources.dividerPanel].
  final Rect dividerPanel;
}

typedef FrameArtKey = ({String set, Color? paper, Color? ink});

Future<FrameArt> buildFrameArt(
  FrameSources src, {
  Color? paper,
  Color? ink,
}) async {
  final c = src.colours;
  final swap = paper == null || ink == null
      ? const <Color, Color>{}
      : {c.ground: paper, c.ink: ink};
  final pictures = <FramePiece, PictureInfo>{};
  for (final p in FramePiece.values) {
    final svg = swap.isEmpty ? src.svg[p]! : recolourSvg(src.svg[p]!, swap);
    pictures[p] = await vg.loadPicture(SvgStringLoader(svg), null);
  }
  return FrameArt(
    pictures: pictures,
    ground: swap[c.ground] ?? c.ground,
    ink: swap[c.ink] ?? c.ink,
    gold: c.gold,
    ownGround: c.dark,
    dividerPanel: src.dividerPanel,
  );
}

final _sources = <String, FrameSources>{};
final _art = <FrameArtKey, FrameArt>{};

/// A design's SVG text and colours (read once).
final frameSourcesFamily = FutureProvider.family<FrameSources, String>(
  (ref, set) async => _sources[set] ??= await loadFrameSources(set),
);

/// A design's pictures, as drawn in light mode or recoloured for a dark
/// one (kept, so switching back is instant).
final frameArtFamily = FutureProvider.family<FrameArt, FrameArtKey>((
  ref,
  key,
) async {
  final src = await ref.watch(frameSourcesFamily(key.set).future);
  return _art[key] ??= await buildFrameArt(src, paper: key.paper, ink: key.ink);
});

// ── Drawing ─────────────────────────────────────────────────────────────

/// Draws the whole of [info] into [dst], mirrored if asked, clipped to
/// [clip] (default: [dst]).
void drawPiece(
  Canvas canvas,
  PictureInfo info,
  Rect dst, {
  bool flipX = false,
  bool flipY = false,
  Rect? clip,
}) {
  final s = info.size;
  canvas
    ..save()
    ..clipRect(clip ?? dst)
    ..translate(dst.center.dx, dst.center.dy)
    ..scale(
      (flipX ? -1 : 1) * dst.width / s.width,
      (flipY ? -1 : 1) * dst.height / s.height,
    )
    ..translate(-s.width / 2, -s.height / 2)
    ..drawPicture(info.picture)
    ..restore();
}

/// Where a picture of [picture] size lands in [box] with [fit], centred.
Rect fittedRect(Size picture, Rect box, BoxFit fit) => Alignment.center
    .inscribe(applyBoxFit(fit, picture, box.size).destination, box);

/// [r] in a picture's units, mapped into the picture's place [dst].
Rect mapRect(Rect r, Size picture, Rect dst) {
  final k = dst.width / picture.width;
  return Rect.fromLTWH(
    dst.left + r.left * k,
    dst.top + r.top * k,
    r.width * k,
    r.height * k,
  );
}

/// The page frame of a drawn design: the owner's corner mirrored into the
/// four corners and his band repeated between them, scaled so the corner
/// square equals the page's text inset and anchored at the outer edge.
class ArtBandPainter extends CustomPainter {
  ArtBandPainter({required this.art, required this.paper, this.inset = 36});

  final FrameArt art;

  /// The theme's paper, inside the band.
  final Color paper;

  /// Where the page's text starts: the corner square's side.
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final inner = Rect.fromLTRB(inset, inset, w - inset, h - inset);
    // The owner draws his frame on the page's own paper.
    canvas.drawRect(Offset.zero & size, Paint()..color = paper);
    if (art.ownGround) {
      canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Offset.zero & size)
          ..addRect(inner),
        Paint()..color = art.ground,
      );
    }
    final corner = art[FramePiece.corner];
    final edgeH = art[FramePiece.edgeH];
    final edgeV = art[FramePiece.edgeV];
    final k = inset / corner.size.width;
    final c = inset;

    // Whole repeats between the corners, stretched a little to fit. Each
    // clip reaches half a pixel into the next repeat so no seam shows.
    final depthH = edgeH.size.height * k;
    final spanX = w - 2 * c;
    final nx = (spanX / (edgeH.size.width * k)).round().clamp(1, 10000);
    final stepX = spanX / nx;
    for (var i = 0; i < nx; i++) {
      final top = Rect.fromLTWH(c + i * stepX, 0, stepX, depthH);
      final bottom = Rect.fromLTWH(c + i * stepX, h - depthH, stepX, depthH);
      drawPiece(canvas, edgeH, top, clip: _widen(top, true));
      drawPiece(canvas, edgeH, bottom, flipY: true, clip: _widen(bottom, true));
    }
    final depthV = edgeV.size.width * k;
    final spanY = h - 2 * c;
    final ny = (spanY / (edgeV.size.height * k)).round().clamp(1, 10000);
    final stepY = spanY / ny;
    for (var i = 0; i < ny; i++) {
      final left = Rect.fromLTWH(0, c + i * stepY, depthV, stepY);
      final right = Rect.fromLTWH(w - depthV, c + i * stepY, depthV, stepY);
      drawPiece(canvas, edgeV, left, clip: _widen(left, false));
      drawPiece(canvas, edgeV, right, flipX: true, clip: _widen(right, false));
    }

    drawPiece(canvas, corner, Rect.fromLTWH(0, 0, c, c));
    drawPiece(canvas, corner, Rect.fromLTWH(w - c, 0, c, c), flipX: true);
    drawPiece(canvas, corner, Rect.fromLTWH(0, h - c, c, c), flipY: true);
    drawPiece(
      canvas,
      corner,
      Rect.fromLTWH(w - c, h - c, c, c),
      flipX: true,
      flipY: true,
    );
  }

  static Rect _widen(Rect r, bool alongX) => alongX
      ? Rect.fromLTRB(r.left - 0.5, r.top, r.right + 0.5, r.bottom)
      : Rect.fromLTRB(r.left, r.top - 0.5, r.right, r.bottom + 0.5);

  @override
  bool shouldRepaint(ArtBandPainter old) =>
      old.art != art || old.paper != paper || old.inset != inset;
}

/// One piece fitted into the box, centred, over an optional [background].
class ArtPicturePainter extends CustomPainter {
  ArtPicturePainter(
    this.picture, {
    this.fit = BoxFit.contain,
    this.background,
    this.disc,
  });

  final PictureInfo picture;
  final BoxFit fit;

  /// Fills the whole box first (the letterbox, or an opaque ground).
  final Color? background;

  /// Fills a disc under the picture, [disc].$2 of the box's shorter side
  /// across (the medallion's paper, so band rules do not run through it).
  final (Color, double)? disc;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    if (background != null) canvas.drawRect(box, Paint()..color = background!);
    if (disc != null) {
      canvas.drawCircle(
        box.center,
        size.shortestSide * disc!.$2 / 2,
        Paint()..color = disc!.$1,
      );
    }
    final dst = fittedRect(picture.size, box, fit);
    drawPiece(canvas, picture, dst, clip: box);
  }

  @override
  bool shouldRepaint(ArtPicturePainter old) =>
      old.picture != picture ||
      old.fit != fit ||
      old.background != background ||
      old.disc != disc;
}
