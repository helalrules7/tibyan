import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/theme_tokens.dart';

/// A real mushaf page (page 1, KFGQPC artwork, bundled) inside the chosen
/// style's frame and colours. Used on the first-launch style screen.
class RealPagePreview extends StatelessWidget {
  const RealPagePreview({
    super.key,
    required this.style,
    required this.mode,
    required this.semanticLabel,
    this.width = 240,
  });

  final TibyanStyle style;
  final ThemeModeId mode;
  final String semanticLabel;
  final double width;

  @override
  Widget build(BuildContext context) {
    final t = style.modes[mode]!;
    final f = style.frame;
    final inset = f.outerWidth + f.gap + f.innerWidth + 10;
    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        width: width,
        height: width * 1.3,
        child: CustomPaint(
          painter: _FramePainter(style: style, colors: t),
          child: Padding(
            padding: EdgeInsets.all(inset),
            child: SvgPicture.asset(
              'assets/themes/preview_page001.svg',
              fit: BoxFit.contain,
              colorFilter: mode.isLight
                  ? null
                  : ColorFilter.mode(t.ink, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter({required this.style, required this.colors});

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
    stroke.strokeWidth = f.outerWidth;
    canvas.drawRRect(outer.deflate(f.outerWidth / 2), stroke);
    if (f.innerWidth > 0) {
      final inner = RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(f.outerWidth + f.gap),
        Radius.circular(f.innerRadius),
      );
      stroke.strokeWidth = f.innerWidth;
      canvas.drawRRect(inner.deflate(f.innerWidth / 2), stroke);
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.style != style || old.colors != colors;
}
