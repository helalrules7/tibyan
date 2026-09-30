import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'frame_design_spec.dart';

/// Painters of the six drawn frame designs (see frame_design_spec.dart):
/// the band with its tiles and corner pieces, the cartouches, the surah
/// banner, the margin marks and the arched ornate pages.

Paint _fill(Color c) => Paint()..color = c;

Paint _line(Color c, double w) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round
  ..color = c;

/// Runs [draw] in a local frame whose x runs along [along] and y along
/// [across] from [origin] (unit vectors; reflections allowed).
void _local(
  Canvas canvas,
  Offset origin,
  Offset along,
  Offset across,
  void Function() draw,
) {
  canvas
    ..save()
    ..transform(
      Float64List.fromList([
        along.dx, along.dy, 0, 0, //
        across.dx, across.dy, 0, 0, //
        0, 0, 1, 0, //
        origin.dx, origin.dy, 0, 1,
      ]),
    );
  draw();
  canvas.restore();
}

/// A star of [points] points: radii alternate between [r] and [inner].
Path starPath(Offset c, double r, double inner, int points, {double turn = 0}) {
  final path = Path();
  for (var i = 0; i < points * 2; i++) {
    final a = turn + i * math.pi / points - math.pi / 2;
    final rr = i.isEven ? r : inner;
    final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

/// The eight-point star of two squares.
Path star8(Offset c, double r) => starPath(c, r, r * 0.7654, 8);

Path _diamond(Offset c, double hx, double hy) => Path()
  ..moveTo(c.dx, c.dy - hy)
  ..lineTo(c.dx + hx, c.dy)
  ..lineTo(c.dx, c.dy + hy)
  ..lineTo(c.dx - hx, c.dy)
  ..close();

// ── Tiles and rosettes ─────────────────────────────────────────────────

/// One repeat of the band's tile in the cell [0, len] × [0, depth], the
/// outer edge at y = 0. [index] alternates motifs.
void paintTile(
  Canvas canvas,
  String kind,
  double len,
  double depth,
  int index,
  FramePalette p,
) {
  final c = Offset(len / 2, depth / 2);
  final gold = _line(p.gold, 0.9);
  switch (kind) {
    case 'star8':
      // Strapwork: two gold zigzags crossing under a star in each cell.
      canvas
        ..drawPath(
          Path()
            ..moveTo(0, depth * 0.18)
            ..lineTo(len / 2, depth * 0.82)
            ..lineTo(len, depth * 0.18)
            ..moveTo(0, depth * 0.82)
            ..lineTo(len / 2, depth * 0.18)
            ..lineTo(len, depth * 0.82),
          gold,
        )
        ..drawPath(star8(c, depth * 0.36), _fill(p.m1))
        ..drawPath(star8(c, depth * 0.36), gold)
        ..drawCircle(c, depth * 0.09, _fill(p.m2))
        ..drawPath(
          _diamond(Offset(0, depth / 2), depth * 0.1, depth * 0.16),
          _fill(p.m2),
        );
    case 'zellige':
      canvas
        ..drawPath(star8(c, depth * 0.4), _fill(p.m1))
        ..drawPath(star8(c, depth * 0.4), gold)
        ..drawCircle(c, depth * 0.12, _fill(p.m2))
        ..drawCircle(c, depth * 0.12, _line(p.gold, 0.6))
        ..drawPath(
          starPath(Offset(0, depth / 2), depth * 0.2, depth * 0.07, 4),
          _fill(p.m2),
        )
        ..drawPath(
          starPath(Offset(0, depth / 2), depth * 0.2, depth * 0.07, 4),
          _line(p.gold, 0.6),
        );
    case 'mosaic':
      final d = _diamond(c, len * 0.4, depth * 0.38);
      canvas
        ..drawPath(d, _fill(p.m1))
        ..drawPath(d, gold)
        ..drawPath(starPath(c, depth * 0.16, depth * 0.05, 4), _fill(p.m2))
        ..drawPath(
          _diamond(Offset(0, depth / 2), depth * 0.09, depth * 0.09),
          _fill(p.gold),
        )
        ..drawCircle(Offset(len / 2, depth * 0.08), depth * 0.04, _fill(p.gold))
        ..drawCircle(
          Offset(len / 2, depth * 0.92),
          depth * 0.04,
          _fill(p.gold),
        );
    case 'lozenge':
      final line = _line(p.m1, 0.7);
      canvas
        ..drawLine(Offset(0, depth * 0.13), Offset(len, depth * 0.13), line)
        ..drawLine(Offset(0, depth * 0.87), Offset(len, depth * 0.87), line)
        ..drawPath(_diamond(c, len * 0.3, depth * 0.3), _fill(p.m1))
        ..drawPath(_diamond(c, len * 0.15, depth * 0.15), _fill(p.band))
        ..drawCircle(c, depth * 0.05, _fill(p.m2))
        ..drawCircle(Offset(0, depth / 2), depth * 0.08, _fill(p.m2));
    case 'tulip':
      // A gold vine through every cell, tulips and rosettes in turn.
      canvas.drawPath(
        Path()
          ..moveTo(0, depth / 2)
          ..cubicTo(
            len / 3,
            depth * 0.15,
            len * 2 / 3,
            depth * 0.85,
            len,
            depth / 2,
          ),
        _line(p.gold, 0.8),
      );
      if (index.isEven) {
        _tulip(canvas, c, depth * 0.36, p);
      } else {
        _flower(canvas, c, depth * 0.24, 5, p.m2, p.gold);
      }
    default: // lines
      canvas
        ..drawLine(
          Offset(0, depth / 2),
          Offset(len, depth / 2),
          _line(p.m1, 0.6),
        )
        ..drawPath(_diamond(c, len * 0.16, depth * 0.24), _fill(p.band))
        ..drawPath(_diamond(c, len * 0.16, depth * 0.24), _line(p.m1, 0.8))
        ..drawCircle(c, depth * 0.05, _fill(p.m2))
        ..drawCircle(Offset(0, depth / 2), depth * 0.06, _fill(p.m2));
  }
}

void _tulip(Canvas canvas, Offset c, double r, FramePalette p) {
  // Stem and two leaves in gold, three petals in red, tip toward the page.
  final base = c.translate(0, -r * 0.9);
  canvas.drawLine(base, c.translate(0, r * 0.1), _line(p.gold, 0.8));
  final petals = Path()
    ..moveTo(c.dx - r * 0.55, c.dy - r * 0.1)
    ..quadraticBezierTo(
      c.dx - r * 0.7,
      c.dy + r * 0.55,
      c.dx - r * 0.3,
      c.dy + r * 0.95,
    )
    ..quadraticBezierTo(c.dx - r * 0.1, c.dy + r * 0.45, c.dx, c.dy + r * 1.0)
    ..quadraticBezierTo(
      c.dx + r * 0.1,
      c.dy + r * 0.45,
      c.dx + r * 0.3,
      c.dy + r * 0.95,
    )
    ..quadraticBezierTo(
      c.dx + r * 0.7,
      c.dy + r * 0.55,
      c.dx + r * 0.55,
      c.dy - r * 0.1,
    )
    ..quadraticBezierTo(c.dx, c.dy - r * 0.35, c.dx - r * 0.55, c.dy - r * 0.1)
    ..close();
  canvas
    ..drawPath(petals, _fill(p.m1))
    ..drawPath(petals, _line(p.gold, 0.5));
}

void _flower(
  Canvas canvas,
  Offset c,
  double r,
  int petals,
  Color colour,
  Color heart,
) {
  for (var i = 0; i < petals; i++) {
    final a = i * 2 * math.pi / petals - math.pi / 2;
    canvas.drawCircle(
      c + Offset(math.cos(a), math.sin(a)) * r * 0.55,
      r * 0.45,
      _fill(colour),
    );
  }
  canvas.drawCircle(c, r * 0.3, _fill(heart));
}

/// The design's rosette (corner pieces, cartouche ends, margin marks):
/// a disc of the band's colour, a gold ring, and the rosette, or [group]
/// (an SVG ornament) when given.
void paintRosette(
  Canvas canvas,
  Offset c,
  double radius,
  FrameDesignSpec spec,
  FramePalette p, {
  ShapeGroup? group,
}) {
  canvas
    ..drawCircle(c, radius, _fill(p.band))
    ..drawCircle(c, radius - 0.6, _line(p.gold, 1));
  final r = radius * 0.78;
  if (group != null) {
    group.paint(canvas, c, r, p.onBand, minStroke: 0.9);
    return;
  }
  switch (spec.look.rosette) {
    case 'flower':
      _flower(canvas, c, r, 6, p.m1, p.m2);
      canvas.drawCircle(c, r * 0.14, _fill(p.gold));
    case 'quatrefoil':
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 2;
        canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * r * 0.42,
          r * 0.42,
          _line(p.m1, 1),
        );
      }
      canvas.drawCircle(c, r * 0.16, _fill(p.gold));
    default:
      canvas
        ..drawPath(star8(c, r), _fill(p.m1))
        ..drawPath(star8(c, r), _line(p.gold, 0.9))
        ..drawCircle(c, r * 0.25, _fill(p.m2));
  }
}

// ── The band ─────────────────────────────────────────────────────────

/// The ornamental band inside [outer], [band] pixels deep: gold rules, a
/// filled ground with whole repeats of the tile along each edge, a square
/// corner piece at each corner, and a fine rule on the paper side.
void paintDesignBand(
  Canvas canvas,
  Rect outer,
  double band,
  FrameDesignSpec spec,
  FramePalette p, {
  bool tiles = true,
}) {
  const g0 = 0.75;
  final g1 = band - 1;
  final o = outer.deflate(g0);
  final i = outer.deflate(g1);
  canvas.drawPath(
    Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(o)
      ..addRect(i),
    _fill(p.band),
  );
  final depth = g1 - g0;
  if (tiles && depth > 6) {
    final t = outer.deflate(g0 + 1.2);
    final d = depth - 2.4;
    // Cells about as long as the SVG rhythm's spacing at the band's scale,
    // stretched a little so every edge holds a whole number of them.
    final target = d * spec.rhythmSpacing / spec.cornerExtent;
    void edge(Offset origin, Offset along, Offset across, double span) {
      final n = math.max(1, (span / target).round());
      final step = span / n;
      for (var k = 0; k < n; k++) {
        _local(
          canvas,
          origin + along * (k * step),
          along,
          across,
          () => paintTile(canvas, spec.look.tile, step, d, k, p),
        );
      }
    }

    canvas
      ..save()
      ..clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(o)
          ..addRect(i),
      );
    final spanX = t.width - 2 * d;
    final spanY = t.height - 2 * d;
    edge(
      t.topLeft.translate(d, 0),
      const Offset(1, 0),
      const Offset(0, 1),
      spanX,
    );
    edge(
      t.bottomLeft.translate(d, 0),
      const Offset(1, 0),
      const Offset(0, -1),
      spanX,
    );
    edge(
      t.topLeft.translate(0, d),
      const Offset(0, 1),
      const Offset(1, 0),
      spanY,
    );
    edge(
      t.topRight.translate(0, d),
      const Offset(0, 1),
      const Offset(-1, 0),
      spanY,
    );
    canvas.restore();
  }
  // Rules: gold on both sides of the ground, fine ink on the paper side.
  canvas
    ..drawRect(o, _line(p.gold, 1.4))
    ..drawRect(i, _line(p.gold, 1))
    ..drawRect(i.deflate(2.2), _line(p.ink.withValues(alpha: 0.7), 0.6));
  // Corner pieces.
  for (final c in [o.topLeft, o.topRight, o.bottomLeft, o.bottomRight]) {
    final sq = Rect.fromLTWH(
      c.dx == o.left ? o.left : o.right - depth,
      c.dy == o.top ? o.top : o.bottom - depth,
      depth,
      depth,
    );
    canvas
      ..drawRect(sq, _fill(p.band))
      ..drawRect(sq, _line(p.gold, 1));
    if (depth > 6) {
      paintRosette(canvas, sq.center, depth * 0.42, spec, p);
    }
  }
}

class DesignFramePainter extends CustomPainter {
  DesignFramePainter({
    required this.spec,
    required this.palette,
    this.band = 30,
    this.fillPaper = true,
  });

  final FrameDesignSpec spec;
  final FramePalette palette;
  final double band;
  final bool fillPaper;

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPaper) {
      canvas.drawRect(
        (Offset.zero & size).deflate(band - 1),
        _fill(palette.paper),
      );
    }
    paintDesignBand(canvas, Offset.zero & size, band, spec, palette);
  }

  @override
  bool shouldRepaint(DesignFramePainter old) =>
      old.spec != spec ||
      old.palette != palette ||
      old.band != band ||
      old.fillPaper != fillPaper;
}

// ── Cartouches ───────────────────────────────────────────────────────

/// The pointed cartouche of the surah divider between [left] and [right]
/// on the line [cy], [half] pixels high each way.
Path cartouchePath(
  double left,
  double right,
  double cy,
  double half,
  double point,
) => Path()
  ..moveTo(left, cy)
  ..lineTo(left + point, cy - half)
  ..lineTo(right - point, cy - half)
  ..lineTo(right, cy)
  ..lineTo(right - point, cy + half)
  ..lineTo(left + point, cy + half)
  ..close();

/// Paints the cartouche body: paper, a gold outline and, inside it, the
/// design's second outline in ink.
void paintCartoucheBody(
  Canvas canvas,
  Rect r,
  FrameDesignSpec spec,
  FramePalette p,
) {
  final half = r.height / 2 - 1;
  final point = half * spec.outer.point / spec.outer.half;
  final outer = cartouchePath(r.left, r.right, r.center.dy, half, point);
  const gap = 3.0;
  final inner = cartouchePath(
    r.left + gap * 1.5,
    r.right - gap * 1.5,
    r.center.dy,
    half - gap,
    point - gap * 0.5,
  );
  canvas
    ..drawPath(outer, _fill(p.paper))
    ..drawPath(outer, _line(p.gold, 1.6))
    ..drawPath(inner, _line(p.ink.withValues(alpha: 0.75), 0.7));
}

/// A page cartouche (juz, hizb and surah on top; the page number below):
/// the pointed body [bodyWidth] wide, centred, and a rosette on each end.
class DesignCartouchePainter extends CustomPainter {
  DesignCartouchePainter({
    required this.spec,
    required this.palette,
    required this.bodyWidth,
    required this.rosette,
    this.group,
  });

  final FrameDesignSpec spec;
  final FramePalette palette;
  final double bodyWidth;

  /// Rosette diameter.
  final double rosette;

  /// SVG ornament in the rosettes (the medallion), else the design's own.
  final ShapeGroup? group;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: bodyWidth,
      height: size.height,
    );
    paintCartoucheBody(canvas, body, spec, palette);
    for (final x in [rosette / 2, size.width - rosette / 2]) {
      paintRosette(
        canvas,
        Offset(x, size.height / 2),
        rosette / 2,
        spec,
        palette,
        group: group,
      );
    }
  }

  @override
  bool shouldRepaint(DesignCartouchePainter old) =>
      old.spec != spec ||
      old.palette != palette ||
      old.bodyWidth != bodyWidth ||
      old.rosette != rosette ||
      old.group != group;
}

/// A rosette on its own: the quarter marks in the margin.
class DesignRosettePainter extends CustomPainter {
  DesignRosettePainter({required this.spec, required this.palette, this.group});

  final FrameDesignSpec spec;
  final FramePalette palette;
  final ShapeGroup? group;

  @override
  void paint(Canvas canvas, Size size) => paintRosette(
    canvas,
    size.center(Offset.zero),
    size.shortestSide / 2,
    spec,
    palette,
    group: group,
  );

  @override
  bool shouldRepaint(DesignRosettePainter old) =>
      old.spec != spec || old.palette != palette || old.group != group;
}

// ── Surah banner ─────────────────────────────────────────────────────

/// Where the banner's cartouche starts, from each end, for a banner of
/// [size]; the text sits inside [bannerTextInset].
double bannerTip(Size size) =>
    math.max(size.width * 0.12, size.height * 0.4 * 2.1);

double bannerTextInset(Size size) => bannerTip(size) + size.height * 0.36;

/// The surah divider: a filled bar between gold rules, the pointed
/// cartouche across it, a rosette on each tip and tiles out to the ends.
class DesignBannerPainter extends CustomPainter {
  DesignBannerPainter({required this.spec, required this.palette});

  final FrameDesignSpec spec;
  final FramePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final p = palette;
    final r = Offset.zero & size;
    // Opaque first: the printed header underneath must not show.
    canvas.drawRect(r, _fill(p.paper));
    final bar = r.deflate(1);
    canvas.drawRect(bar, _fill(p.band));
    final tip = bannerTip(size);
    final rr = size.height * 0.4;
    final rc = tip - rr * 0.3;
    // Tiles from each end to the rosette.
    final room = rc - rr - bar.left;
    final d = bar.height - 5;
    if (room > d * 0.6) {
      final n = math.max(1, (room / d).round());
      final step = room / n;
      for (var k = 0; k < n; k++) {
        _local(
          canvas,
          Offset(bar.left + k * step, bar.top + 2.5),
          const Offset(1, 0),
          const Offset(0, 1),
          () => paintTile(canvas, spec.look.tile, step, d, k, p),
        );
        _local(
          canvas,
          Offset(bar.right - k * step, bar.top + 2.5),
          const Offset(-1, 0),
          const Offset(0, 1),
          () => paintTile(canvas, spec.look.tile, step, d, k, p),
        );
      }
    }
    canvas
      ..drawLine(
        bar.topLeft.translate(0, 1.2),
        bar.topRight.translate(0, 1.2),
        _line(p.gold, 1.2),
      )
      ..drawLine(
        bar.bottomLeft.translate(0, -1.2),
        bar.bottomRight.translate(0, -1.2),
        _line(p.gold, 1.2),
      );
    paintCartoucheBody(
      canvas,
      Rect.fromLTRB(tip, bar.top + 3, size.width - tip, bar.bottom - 3),
      spec,
      p,
    );
    for (final x in [rc, size.width - rc]) {
      paintRosette(
        canvas,
        Offset(x, size.height / 2),
        rr,
        spec,
        p,
        group: spec.rosette,
      );
    }
  }

  @override
  bool shouldRepaint(DesignBannerPainter old) =>
      old.spec != spec || old.palette != palette;
}

// ── Ornate pages: cover, splash and the two opening pages ────────────

/// The arch over the ornate pages, closed along its springing line
/// [spring], rising to [apex], between [left] and [right].
Path archPath(
  String kind,
  double left,
  double right,
  double spring,
  double apex,
) {
  final cx = (left + right) / 2;
  final hw = (right - left) / 2;
  final rise = spring - apex;
  final path = Path()..moveTo(left, spring);
  switch (kind) {
    case 'round':
    case 'horseshoe':
      // A segment of a circle through both springs and the apex; the
      // horseshoe steps in at its springs.
      final step = kind == 'horseshoe' ? hw * 0.06 : 0.0;
      final w = hw - step;
      final rad = (w * w + rise * rise) / (2 * rise);
      if (step > 0) path.lineTo(left + step, spring - rise * 0.08);
      path.arcToPoint(Offset(cx, apex), radius: Radius.circular(rad));
      path.arcToPoint(
        Offset(right - step, spring - (step > 0 ? rise * 0.08 : 0)),
        radius: Radius.circular(rad),
      );
      if (step > 0) path.lineTo(right, spring);
    case 'ogee':
      path
        ..cubicTo(
          left,
          spring - rise * 0.9,
          cx - hw * 0.3,
          apex + rise * 0.45,
          cx,
          apex,
        )
        ..cubicTo(
          cx + hw * 0.3,
          apex + rise * 0.45,
          right,
          spring - rise * 0.9,
          right,
          spring,
        );
    default: // pointed: two curves rising steeply and meeting in a point
      path
        ..cubicTo(
          left,
          spring - rise * 0.6,
          cx - hw * 0.5,
          apex + rise * 0.18,
          cx,
          apex,
        )
        ..cubicTo(
          cx + hw * 0.5,
          apex + rise * 0.18,
          right,
          spring - rise * 0.6,
          right,
          spring,
        );
  }
  return path..close();
}

/// Half the arch's width at height [y] (sampled from its outline); 0
/// above the apex.
double archHalfWidth(Path arch, double cx, double y) {
  var best = 0.0;
  for (final m in arch.computeMetrics()) {
    for (var s = 0.0; s <= m.length; s += 1) {
      final t = m.getTangentForOffset(s);
      if (t != null && (t.position.dy - y).abs() < 1) {
        best = math.max(best, (t.position.dx - cx).abs());
      }
    }
  }
  return best;
}

/// Geometry shared by the ornate painter and the widget that lays out the
/// cartouches over it.
class OrnateLayout {
  OrnateLayout(this.size, this.panel, this.band, this.kind);

  final Size size;

  /// Where the page (or the title) sits.
  final Rect panel;
  final double band;
  final String kind;

  double get cx => size.width / 2;
  double get spring => panel.top - 4;
  double get apex => band + 3;
  Path get arch => archPath(kind, band, size.width - band, spring, apex);

  /// The strip under the page, above the lower cartouche.
  Rect get foot => Rect.fromLTRB(
    band,
    panel.bottom + 4,
    size.width - band,
    panel.bottom + 16,
  );

  /// Widest cartouche of [height] centred at [centreY] that stays inside
  /// the arch, keeping [margin] from it.
  double fitWidth(double centreY, double height, {double margin = 8}) =>
      2 * (archHalfWidth(arch, cx, centreY - height / 2) - margin);
}

class DesignOrnatePainter extends CustomPainter {
  DesignOrnatePainter({
    required this.spec,
    required this.palette,
    required this.layout,
    this.cover = false,
  });

  final FrameDesignSpec spec;
  final FramePalette palette;
  final OrnateLayout layout;

  /// The cover or splash: the SVG splash's radial motif under the title.
  final bool cover;

  @override
  void paint(Canvas canvas, Size size) {
    final p = palette;
    final l = layout;
    final all = Offset.zero & size;
    canvas.drawRect(all, _fill(p.paper));
    final inner = all.deflate(l.band - 1);
    final arch = l.arch;

    if (cover) {
      // The splash's rules and radial motif, scaled so its inner frame
      // meets the band, inside the arch and the page.
      final reach = spec.coverSize.width / 2 - 60;
      final c = math.min(inner.width / 2, l.panel.height / 2) / reach;
      canvas
        ..save()
        ..clipPath(
          Path()
            ..addPath(arch, Offset.zero)
            ..addRect(
              Rect.fromLTRB(inner.left, l.spring - 1, inner.right, l.foot.top),
            ),
        );
      final centre = l.panel.center;
      spec.cover.paint(
        canvas,
        centre,
        spec.cover.r * c,
        p.onPaper,
        minStroke: 0.7,
        alpha: 0.55,
      );
      canvas.restore();
    }

    // Spandrels: the band's ground and tiles above the arch.
    final spandrel = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTRB(inner.left, inner.top, inner.right, l.spring))
      ..addPath(arch, Offset.zero);
    canvas
      ..save()
      ..clipPath(spandrel)
      ..drawRect(inner, _fill(p.band));
    final d = math.max(14.0, (l.spring - inner.top) / 4);
    final n = math.max(1, (inner.width / d).round());
    final step = inner.width / n;
    for (var row = 0; row * d < l.spring - inner.top; row++) {
      for (var k = -1; k < n + 1; k++) {
        final x = inner.left + k * step + (row.isOdd ? step / 2 : 0);
        _local(
          canvas,
          Offset(x, inner.top + row * d),
          const Offset(1, 0),
          const Offset(0, 1),
          () => paintTile(canvas, spec.look.tile, step, d, k + row, p),
        );
      }
    }
    canvas.restore();

    // The arch's outline: gold, and fine ink inside it.
    final inside = archPath(
      l.kind,
      l.band + 4,
      size.width - l.band - 4,
      l.spring,
      l.apex + 4,
    );
    canvas
      ..drawPath(arch, _line(p.gold, 1.6))
      ..drawPath(inside, _line(p.ink.withValues(alpha: 0.6), 0.6));

    // The strip under the page.
    final foot = l.foot;
    canvas
      ..drawRect(foot, _fill(p.band))
      ..drawLine(foot.topLeft, foot.topRight, _line(p.gold, 1.2))
      ..drawLine(foot.bottomLeft, foot.bottomRight, _line(p.gold, 1.2));
    final fd = foot.height - 3;
    final fn = math.max(1, (foot.width / (fd * 1.2)).round());
    final fs = foot.width / fn;
    canvas
      ..save()
      ..clipRect(foot);
    for (var k = 0; k < fn; k++) {
      _local(
        canvas,
        Offset(foot.left + k * fs, foot.top + 1.5),
        const Offset(1, 0),
        const Offset(0, 1),
        () => paintTile(canvas, spec.look.tile, fs, fd, k, p),
      );
    }
    canvas.restore();

    paintDesignBand(canvas, all, l.band, spec, p);
  }

  @override
  bool shouldRepaint(DesignOrnatePainter old) =>
      old.spec != spec ||
      old.palette != palette ||
      old.layout.size != layout.size ||
      old.layout.panel != layout.panel ||
      old.cover != cover;
}

/// The title cartouche of the ornate pages (from the opening-page design):
/// a rounded box with a gold rule, and the page's ornament at each end.
class DesignTitlePainter extends CustomPainter {
  DesignTitlePainter({
    required this.spec,
    required this.palette,
    this.ornament,
  });

  final FrameDesignSpec spec;
  final FramePalette palette;
  final ShapeGroup? ornament;

  @override
  void paint(Canvas canvas, Size size) {
    final p = palette;
    final r = (Offset.zero & size).deflate(1);
    final open = spec.openings[1]!.title;
    final radius = Radius.circular(size.height * 10 / open.height);
    final box = RRect.fromRectAndRadius(r, radius);
    canvas
      ..drawRRect(box, _fill(p.paper))
      ..drawRRect(box, _line(p.gold, 1.5))
      ..drawRRect(
        RRect.fromRectAndRadius(r.deflate(3), radius),
        _line(p.ink.withValues(alpha: 0.5), 0.6),
      );
    final o = ornament;
    if (o != null) {
      final rad = size.height * 0.3;
      for (final x in [rad + 8, size.width - rad - 8]) {
        o.paint(
          canvas,
          Offset(x, size.height / 2),
          rad,
          p.onPaper,
          minStroke: 0.9,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DesignTitlePainter old) =>
      old.spec != spec || old.palette != palette || old.ornament != ornament;
}
