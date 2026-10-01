import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/settings/settings_controller.dart';
import '../../../../core/theme/theme_tokens.dart';
import '../../data/compiled_svg.dart';

/// The heritage themes' art (frame, surah header, verse marker): SVG files
/// from quran-assets in `assets/themes/`, drawn as they are, with each
/// class of the drawing coloured for the mode (see [ThemeArt]).

String _hexOf(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// [svg] with the fill of each `class="cN"` group and the stroke of the
/// `class="line"` group set from [colours]; other classes and every path
/// are left as drawn.
String recolourArt(String svg, Map<String, Color> colours) {
  if (colours.isEmpty) return svg;
  return svg.replaceAllMapped(RegExp(r'<g\s[^>]*class="([\w-]+)"[^>]*>'), (m) {
    final tag = m[0]!;
    final colour = colours[m[1]!];
    if (colour == null) return tag;
    final attr = m[1] == 'line' ? 'stroke' : 'fill';
    return tag.replaceFirst(
      RegExp('\\b$attr="[^"]*"'),
      '$attr="${_hexOf(colour)}"',
    );
  });
}

/// The `data-slot` box of an asset (x y w h, in its viewBox units): a
/// header's name box, a marker's number box, a whole frame's text area.
Rect? svgSlot(String svg) {
  final m = RegExp(r'data-slot="([^"]+)"').firstMatch(svg);
  if (m == null) return null;
  final v = m[1]!.trim().split(RegExp(r'\s+')).map(double.parse).toList();
  return Rect.fromLTWH(v[0], v[1], v[2], v[3]);
}

/// One piece of art, ready to draw, with its slot if it has one.
class ArtPiece {
  const ArtPiece(this.picture, [this.slot]);

  final PictureInfo picture;
  final Rect? slot;

  Size get size => picture.size;
}

/// All the art of one theme in one mode.
class ThemeArtPictures {
  const ThemeArtPictures({
    required this.band,
    required this.header,
    required this.marker,
    this.corner,
    this.edgeH,
    this.edgeV,
    this.whole,
  });

  final double band;
  final ArtPiece? corner;
  final ArtPiece? edgeH;
  final ArtPiece? edgeV;

  /// A frame with no slices, and its text area in [ArtPiece.slot].
  final ArtPiece? whole;
  final ArtPiece header;
  final ArtPiece marker;

  /// How the frame is laid out at [size].
  ArtFrameLayout layout(Size size) => whole != null
      ? wholeFrameLayout(
          size,
          view: whole!.size,
          slot: whole!.slot ?? Rect.zero,
          band: band,
        )
      : sliceFrameLayout(
          size,
          corner: corner!.size,
          edgeH: edgeH!.size,
          edgeV: edgeV!.size,
          band: band,
        );

  ArtPiece pieceOf(ArtFramePiece p) => switch (p) {
    ArtFramePiece.corner => corner!,
    ArtFramePiece.edgeH => edgeH!,
    ArtFramePiece.edgeV => edgeV!,
    ArtFramePiece.whole => whole!,
  };
}

final _svg = <String, String>{};
final _built = <(String, ThemeModeId), ThemeArtPictures>{};

Future<ArtPiece> _piece(
  AssetBundle bundle,
  String file,
  Map<String, Color> colours,
) async {
  final svg = _svg[file] ??= await bundle.loadString('assets/themes/$file');
  // The provenance block stays in the file; the renderer does not read it.
  final drawing = svg.replaceFirst(
    RegExp(r'<metadata>.*?</metadata>', dotAll: true),
    '',
  );
  final picture = await compiledSvgPicture(
    recolourArt(drawing, colours),
    name: file,
  );
  return ArtPiece(picture, svgSlot(svg));
}

/// A frame piece the theme may not have.
Future<ArtPiece?> _maybe(
  AssetBundle bundle,
  String? file,
  Map<String, Color> colours,
) => file == null
    ? Future<ArtPiece?>.value(null)
    : _piece(bundle, file, colours);

/// Loads and colours a theme's art for [mode].
///
/// The pieces do not depend on each other, so they are all asked for at once
/// and compiled in parallel; one after another cost a theme 400-600 ms on a
/// phone, which is most of what the theme picker spent on showing a theme.
Future<ThemeArtPictures> loadThemeArt(
  ThemeArt art,
  ThemeModeId mode, {
  AssetBundle? bundle,
}) async {
  final b = bundle ?? rootBundle;
  final c = art.colours[mode]!;
  final f = art.frame;
  final (header, marker, corner, edgeH, edgeV, whole) = await (
    _piece(b, art.header, c.header),
    _piece(b, art.marker, c.marker),
    _maybe(b, f.corner, c.frame),
    _maybe(b, f.edgeH, c.frame),
    _maybe(b, f.edgeV, c.frame),
    _maybe(b, f.whole, c.frame),
  ).wait;
  return ThemeArtPictures(
    band: art.band,
    header: header,
    marker: marker,
    corner: corner,
    edgeH: edgeH,
    edgeV: edgeV,
    whole: whole,
  );
}

typedef ThemeArtKey = ({String style, ThemeModeId mode});

/// A theme's art in one mode, or null for a style without art (Zakhrafa).
/// Kept once built, so turning pages or switching back is instant.
final themeArtProvider = FutureProvider.family<ThemeArtPictures?, ThemeArtKey>((
  ref,
  key,
) async {
  final art = ref.watch(themeRegistryProvider).byId(key.style).art;
  if (art == null) return null;
  final id = (key.style, key.mode);
  return _built[id] ??= await loadThemeArt(art, key.mode);
});

// ── Frame layout ────────────────────────────────────────────────────────

enum ArtFramePiece { corner, edgeH, edgeV, whole }

/// One piece of the frame on screen: [src] of the piece (its units; null =
/// all of it) drawn into [rect], mirrored if asked.
class ArtPlacement {
  const ArtPlacement(
    this.piece,
    this.rect, {
    this.src,
    this.flipX = false,
    this.flipY = false,
  });

  final ArtFramePiece piece;
  final Rect rect;
  final Rect? src;
  final bool flipX;
  final bool flipY;

  @override
  String toString() =>
      '$piece $rect${flipX ? ' flipX' : ''}'
      '${flipY ? ' flipY' : ''}';
}

class ArtFrameLayout {
  const ArtFrameLayout(this.placements, this.inset);

  final List<ArtPlacement> placements;

  /// Depth of the frame on every side: the page's paper starts here.
  final double inset;
}

/// A frame from its slices at [size]: the top-left corner mirrored into
/// the other three, and a whole number of edge repeats between the corners
/// on each side, stretched a little to fit exactly. [band] is the edges'
/// depth on screen.
ArtFrameLayout sliceFrameLayout(
  Size size, {
  required Size corner,
  required Size edgeH,
  required Size edgeV,
  required double band,
}) {
  final w = size.width;
  final h = size.height;
  final k = band / edgeH.height;
  final cw = corner.width * k;
  final ch = corner.height * k;
  final dh = edgeH.height * k;
  final dv = edgeV.width * k;
  final out = <ArtPlacement>[];

  final spanX = w - 2 * cw;
  final nx = math.max(1, (spanX / (edgeH.width * k)).round());
  final stepX = spanX / nx;
  for (var i = 0; i < nx; i++) {
    final x = cw + i * stepX;
    out
      ..add(ArtPlacement(ArtFramePiece.edgeH, Rect.fromLTWH(x, 0, stepX, dh)))
      ..add(
        ArtPlacement(
          ArtFramePiece.edgeH,
          Rect.fromLTWH(x, h - dh, stepX, dh),
          flipY: true,
        ),
      );
  }
  final spanY = h - 2 * ch;
  final ny = math.max(1, (spanY / (edgeV.height * k)).round());
  final stepY = spanY / ny;
  for (var i = 0; i < ny; i++) {
    final y = ch + i * stepY;
    out
      ..add(ArtPlacement(ArtFramePiece.edgeV, Rect.fromLTWH(0, y, dv, stepY)))
      ..add(
        ArtPlacement(
          ArtFramePiece.edgeV,
          Rect.fromLTWH(w - dv, y, dv, stepY),
          flipX: true,
        ),
      );
  }
  out.addAll([
    ArtPlacement(ArtFramePiece.corner, Rect.fromLTWH(0, 0, cw, ch)),
    ArtPlacement(
      ArtFramePiece.corner,
      Rect.fromLTWH(w - cw, 0, cw, ch),
      flipX: true,
    ),
    ArtPlacement(
      ArtFramePiece.corner,
      Rect.fromLTWH(0, h - ch, cw, ch),
      flipY: true,
    ),
    ArtPlacement(
      ArtFramePiece.corner,
      Rect.fromLTWH(w - cw, h - ch, cw, ch),
      flipX: true,
      flipY: true,
    ),
  ]);
  return ArtFrameLayout(out, math.max(dh, dv));
}

/// A frame with no slices at [size]: the whole drawing at one scale (the
/// width's, on a phone; on a wide screen no deeper than a little over
/// [band]), cut in three by three so the corners keep their proportions
/// and only the middle of each side stretches.
ArtFrameLayout wholeFrameLayout(
  Size size, {
  required Size view,
  required Rect slot,
  required double band,
}) {
  final w = size.width;
  final h = size.height;
  final margin = slot.left > 0 ? slot.left : 1.0;
  final k = math.min(
    math.min(w / view.width, h / view.height),
    1.2 * band / margin,
  );
  final cx = math.min(view.width / 2 - 1, view.width * 0.3);
  final cy = math.min(view.height / 2 - 1, view.width * 0.3);
  final srcX = [0.0, cx, view.width - cx, view.width];
  final srcY = [0.0, cy, view.height - cy, view.height];
  final dstX = [0.0, cx * k, w - cx * k, w];
  final dstY = [0.0, cy * k, h - cy * k, h];
  return ArtFrameLayout([
    for (var j = 0; j < 3; j++)
      for (var i = 0; i < 3; i++)
        ArtPlacement(
          ArtFramePiece.whole,
          Rect.fromLTRB(dstX[i], dstY[j], dstX[i + 1], dstY[j + 1]),
          src: Rect.fromLTRB(srcX[i], srcY[j], srcX[i + 1], srcY[j + 1]),
        ),
  ], math.max(slot.left, slot.top) * k);
}

/// Draws [src] of [picture] (all of it by default) into [dst], mirrored if
/// asked, clipped to [clip] (default: [dst]).
void drawArt(
  Canvas canvas,
  PictureInfo picture,
  Rect dst, {
  Rect? src,
  bool flipX = false,
  bool flipY = false,
  Rect? clip,
}) {
  final s = src ?? Offset.zero & picture.size;
  canvas
    ..save()
    ..clipRect(clip ?? dst)
    ..translate(dst.center.dx, dst.center.dy)
    ..scale(
      (flipX ? -1 : 1) * dst.width / s.width,
      (flipY ? -1 : 1) * dst.height / s.height,
    )
    ..translate(-s.center.dx, -s.center.dy)
    ..drawPicture(picture.picture)
    ..restore();
}

/// The theme's frame around the page, on the page's [paper].
class ArtFramePainter extends CustomPainter {
  ArtFramePainter({required this.art, required this.paper});

  /// Null while the art loads: only the paper shows meanwhile.
  final ThemeArtPictures? art;
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    final art = this.art;
    final layout = art?.layout(size);
    final inset = layout?.inset ?? 20;
    canvas.drawRect(
      (Offset.zero & size).deflate(math.max(0, inset - 1)),
      Paint()..color = paper,
    );
    if (art == null) return;
    for (final p in layout!.placements) {
      // Edges reach half a pixel into the next repeat so no seam shows.
      final clip = p.piece == ArtFramePiece.edgeH
          ? Rect.fromLTRB(
              p.rect.left - 0.5,
              p.rect.top,
              p.rect.right + 0.5,
              p.rect.bottom,
            )
          : p.piece == ArtFramePiece.edgeV
          ? Rect.fromLTRB(
              p.rect.left,
              p.rect.top - 0.5,
              p.rect.right,
              p.rect.bottom + 0.5,
            )
          : p.piece == ArtFramePiece.whole
          ? p.rect.inflate(0.5)
          : null;
      drawArt(
        canvas,
        art.pieceOf(p.piece).picture,
        p.rect,
        src: p.src,
        flipX: p.flipX,
        flipY: p.flipY,
        clip: clip,
      );
    }
  }

  @override
  bool shouldRepaint(ArtFramePainter old) =>
      old.art != art || old.paper != paper;
}

// ── Markers and headers ─────────────────────────────────────────────────

/// Where a verse marker of [art] size goes over a printed marker of
/// radius [r] at [c]: centred, at most 2.6 r high and 2.1 r wide, so a
/// wide marker never reaches the words beside it.
Rect markerBox(Offset c, double r, Size art) {
  final k = math.min(2.08 * r / art.width, 2.62 * r / art.height);
  return Rect.fromCenter(
    center: c,
    width: art.width * k,
    height: art.height * k,
  );
}

/// [slot] (in the art's units) where the art of [art] size lands in [dst].
Rect slotIn(Rect slot, Size art, Rect dst) {
  final kx = dst.width / art.width;
  final ky = dst.height / art.height;
  return Rect.fromLTWH(
    dst.left + slot.left * kx,
    dst.top + slot.top * ky,
    slot.width * kx,
    slot.height * ky,
  );
}

/// Arabic-Indic digits of [n].
String arabicDigits(int n) => n
    .toString()
    .split('')
    .map((d) => String.fromCharCode(0x0660 + int.parse(d)))
    .join();

/// [number] centred in [box] (a marker's number box): half as tall again
/// as the box, which the designs keep small, and no wider than it allows
/// (so three digits still fit).
void paintNumberIn(Canvas canvas, Rect box, int number, Color color) {
  TextPainter layout(double size) => TextPainter(
    text: TextSpan(
      text: arabicDigits(number),
      style: TextStyle(
        fontFamily: 'UthmanTahaNaskh',
        fontWeight: FontWeight.w700,
        fontSize: size,
        height: 1,
        color: color,
      ),
    ),
    textDirection: TextDirection.rtl,
  )..layout();
  var fontSize = box.height * 1.6;
  var tp = layout(fontSize);
  if (tp.width > box.width * 1.1) {
    fontSize *= box.width * 1.1 / tp.width;
    tp = layout(fontSize);
  }
  // Uthman Taha Naskh digits rise 0.515 em above the baseline and do not
  // descend: centre that ink box, not the line box.
  final baseline = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  tp.paint(
    canvas,
    Offset(
      box.center.dx - tp.width / 2,
      box.center.dy - baseline + 0.2575 * fontSize,
    ),
  );
}

/// The theme's marker in [dst] with [number] in its number box; [fill]
/// (a mark's or the chosen tint) fills a disc behind a white number.
void paintArtMarker(
  Canvas canvas,
  ArtPiece marker,
  Rect dst, {
  int? number,
  required Color digits,
  Color? fill,
}) {
  drawArt(canvas, marker.picture, dst, clip: dst.inflate(1));
  final slot = marker.slot;
  if (slot == null || number == null) return;
  final box = slotIn(slot, marker.size, dst);
  if (fill != null) {
    canvas.drawCircle(
      box.center,
      math.min(box.width, box.height * 1.6) * 0.55,
      Paint()..color = fill,
    );
  }
  paintNumberIn(canvas, box, number, fill == null ? digits : Colors.white);
}

/// The theme's marker with a number in it, as a widget (the page number).
class ArtMarkerPainter extends CustomPainter {
  ArtMarkerPainter({
    required this.marker,
    required this.number,
    required this.digits,
  });

  final ArtPiece marker;
  final int? number;
  final Color digits;

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Alignment.center.inscribe(
      applyBoxFit(BoxFit.contain, marker.size, size).destination,
      Offset.zero & size,
    );
    paintArtMarker(canvas, marker, dst, number: number, digits: digits);
  }

  @override
  bool shouldRepaint(ArtMarkerPainter old) =>
      old.marker != marker || old.number != number || old.digits != digits;
}

/// A piece fitted into the box, centred, over an optional [background].
class ArtPicturePainter extends CustomPainter {
  ArtPicturePainter(this.piece, {this.background});

  final ArtPiece piece;
  final Color? background;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    if (background != null) canvas.drawRect(box, Paint()..color = background!);
    drawArt(canvas, piece.picture, fittedArt(piece.size, box));
  }

  @override
  bool shouldRepaint(ArtPicturePainter old) =>
      old.piece != piece || old.background != background;
}

/// Where art of [art] size lands in [box], contained and centred.
Rect fittedArt(Size art, Rect box) => Alignment.center.inscribe(
  applyBoxFit(BoxFit.contain, art, box.size).destination,
  box,
);
