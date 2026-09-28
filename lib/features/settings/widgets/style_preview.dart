import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/theme_tokens.dart';

/// A small page drawn with a style's frame, header band and verse markers.
/// Grey bars stand in for text: Phase 0 shows no Quran text. The real
/// page preview arrives with the mushaf in Phase 1.
class StylePreview extends StatelessWidget {
  const StylePreview({
    super.key,
    required this.style,
    required this.mode,
    required this.headerLabel,
    required this.semanticLabel,
    this.width = 150,
  });

  final TibyanStyle style;
  final ThemeModeId mode;
  final String headerLabel;
  final String semanticLabel;
  final double width;

  @override
  Widget build(BuildContext context) {
    final t = style.modes[mode]!;
    final height = width * 1.45;
    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _PreviewPainter(style: style, colors: t),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              pad(style) + 6,
              pad(style) + 8,
              pad(style) + 6,
              pad(style) + 6,
            ),
            child: Column(
              children: [
                Container(
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.headBg,
                    borderRadius: BorderRadius.circular(
                      style.radii.surahHeader * 0.6,
                    ),
                    border: Border.all(color: t.frame, width: 1),
                  ),
                  child: Text(
                    headerLabel,
                    style: TextStyle(
                      fontFamily: style.surahHeaderFont,
                      color: t.headFg,
                      fontSize: 11,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < 7; i++) _Line(colors: t, index: i),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static double pad(TibyanStyle s) =>
      s.frame.outerWidth + s.frame.gap + s.frame.innerWidth;
}

class _Line extends StatelessWidget {
  const _Line({required this.colors, required this.index});

  final ModeTokens colors;
  final int index;

  @override
  Widget build(BuildContext context) {
    final withMarker = index == 2 || index == 5;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: colors.ink.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          if (withMarker) ...[
            const SizedBox(width: 4),
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.marker, width: 1.4),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 18,
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: colors.ink.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter({required this.style, required this.colors});

  final TibyanStyle style;
  final ModeTokens colors;

  @override
  void paint(Canvas canvas, Size size) {
    final f = style.frame;
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(f.radius),
    );
    canvas.drawRRect(outer, Paint()..color = colors.paper);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = colors.frame;

    if (f.outerStyle == 'double') {
      final w = f.outerWidth / 3;
      stroke.strokeWidth = w;
      canvas.drawRRect(outer.deflate(w / 2), stroke);
      canvas.drawRRect(outer.deflate(f.outerWidth - w / 2), stroke);
    } else {
      stroke.strokeWidth = f.outerWidth;
      canvas.drawRRect(outer.deflate(f.outerWidth / 2), stroke);
    }

    if (f.innerWidth > 0) {
      final inset = f.outerWidth + f.gap;
      final inner = RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(inset),
        Radius.circular(f.innerRadius),
      );
      stroke.strokeWidth = f.innerWidth;
      canvas.drawRRect(inner.deflate(f.innerWidth / 2), stroke);

      if (f.corner == 'star8') {
        final r = inner.outerRect;
        for (final c in [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]) {
          _star8(canvas, c, 6, colors);
        }
      }
    }
  }

  void _star8(Canvas canvas, Offset center, double half, ModeTokens c) {
    final fill = Paint()..color = c.paper;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = c.frame;
    for (final angle in [0.0, math.pi / 4]) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final square = Rect.fromCenter(
        center: Offset.zero,
        width: half * 2,
        height: half * 2,
      );
      canvas.drawRect(square, fill);
      canvas.drawRect(square, line);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.style != style || old.colors != colors;
}
