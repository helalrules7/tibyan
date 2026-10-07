import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// The live spectrum: calm mirrored bars, low frequencies in the middle.
/// Repaints from [bands] alone (about 30 times a second while listening),
/// never the screen around it.
class SpectrumBars extends StatelessWidget {
  const SpectrumBars({
    super.key,
    required this.bands,
    this.height = 40,
    this.active = true,
  });

  final ValueNotifier<List<double>> bands;
  final double height;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _BarsPainter(
              bands,
              active ? t.control : t.border,
              t.border,
              active,
            ),
          ),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.bands, this.color, this.rest, this.active)
    : super(repaint: bands);

  final ValueNotifier<List<double>> bands;
  final Color color;
  final Color rest;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final values = bands.value;
    if (values.isEmpty) return;
    final mirrored = [...values.reversed, ...values];
    const gap = 3.0;
    final w = (size.width - gap * (mirrored.length - 1)) / mirrored.length;
    final bar = math.max(1.0, math.min(w, 6.0));
    final total = bar * mirrored.length + gap * (mirrored.length - 1);
    var x = (size.width - total) / 2;
    final mid = size.height / 2;
    for (final v0 in mirrored) {
      final v = active ? v0 : 0.0;
      final h = math.max(bar, v * size.height);
      final paint = Paint()
        ..color = v < 0.08 ? rest : color.withValues(alpha: 0.35 + 0.65 * v);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x + bar / 2, mid),
            width: bar,
            height: h,
          ),
          Radius.circular(bar / 2),
        ),
        paint,
      );
      x += bar + gap;
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.bands != bands ||
      old.color != color ||
      old.rest != rest ||
      old.active != active;
}
