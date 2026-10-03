import 'dart:math' as math;
import 'dart:ui';

/// WCAG 2.x relative luminance of an opaque colour.
double relativeLuminance(Color color) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG contrast ratio between two opaque colours (1 to 21).
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// [color] moved toward [target], in steps of 5%, until it reaches [ratio]
/// against every colour in [against]; [target] itself when no step does.
Color towardContrast(
  Color color,
  Color target,
  List<Color> against,
  double ratio,
) {
  for (var i = 0; i <= 20; i++) {
    final c = Color.lerp(color, target, i / 20)!;
    if (against.every((b) => contrastRatio(c, b) >= ratio)) return c;
  }
  return target;
}

/// Black or white, whichever stands out more against [background].
Color extremeAgainst(Color background) =>
    contrastRatio(const Color(0xFF000000), background) >=
        contrastRatio(const Color(0xFFFFFFFF), background)
    ? const Color(0xFF000000)
    : const Color(0xFFFFFFFF);

/// A surface and what is drawn on it, reaching [ratio]: the foreground
/// moves toward black or white first, then, when that is not enough (a
/// mid-tone surface), the surface darkens or lightens away from it.
(Color, Color) strongPair(Color surface, Color foreground, double ratio) {
  final fg = towardContrast(foreground, extremeAgainst(surface), [
    surface,
  ], ratio);
  if (contrastRatio(fg, surface) >= ratio) return (surface, fg);
  final bg = towardContrast(surface, extremeAgainst(fg), [fg], ratio);
  return (bg, fg);
}
