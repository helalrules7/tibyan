import 'dart:ui';

/// Draws an image in two colours: each pixel's luminance placed between
/// [tint]'s dark and light colour, its alpha kept. For a theme's
/// [ModeTokens.artTint].
ColorFilter duotoneFilter((Color, Color) tint) {
  final (dark, light) = tint;
  // Rec. 709 luminance of the source pixel.
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  List<double> row(double d, double l) {
    final span = l - d;
    return [span * lr, span * lg, span * lb, 0, d * 255];
  }

  return ColorFilter.matrix([
    ...row(dark.r, light.r),
    ...row(dark.g, light.g),
    ...row(dark.b, light.b),
    0,
    0,
    0,
    1,
    0,
  ]);
}
