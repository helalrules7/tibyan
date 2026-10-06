import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/duotone.dart';
import '../../../../core/theme/theme_tokens.dart';

/// Where things sit in the opening-page frames (docs/design/fateha-themes,
/// each a recolour of one 1200×1457 drawing): the transparent panel for
/// the page, and the two cream cartouches above and below it.
abstract final class OpeningArtLayout {
  static const size = Size(1200, 1457);
  static const panel = Rect.fromLTRB(339, 407, 860, 1049);
  static const top = Rect.fromLTRB(455, 225, 745, 380);
  static const bottom = Rect.fromLTRB(454, 1077, 745, 1231);

  /// The width the drawing is scaled to fit: all of it. Its side ornaments
  /// used to be cropped off to give the page inside more of the screen, but
  /// the frame then ran off both edges of a phone; the whole frame is shown
  /// now, scaled down to the room it has.
  static const visibleWidth = 1200.0;

  /// One period of the side borders, between the two cartouche rows: the
  /// rows 493 and 750 match across the whole width (the same in every
  /// recolour), so copies of this band continue the ornament seamlessly.
  static const bandTop = 493.0;
  static const bandHeight = 257.0;

  /// The band's copies may be stretched this much to fill the height;
  /// what is left over stays as margin.
  static const maxStretch = 0.08;
}

/// The opening frame fitted inside [room], never cropped: the whole drawing
/// as wide as the room (or, in a room too short for that, as tall, centred
/// across it), and made taller by repeating the side borders'
/// [OpeningArtLayout.bandTop] ([repeats] extra copies, each [stretch] times
/// its height), so the art is never distorted beyond a slight stretch of that
/// band.
@immutable
class OpeningArtGeometry {
  factory OpeningArtGeometry.fit(Size room) {
    const art = OpeningArtLayout.size;
    var k = room.width / OpeningArtLayout.visibleWidth;
    var repeats = 0;
    var stretch = 1.0;
    if (art.height * k >= room.height) {
      // Too tall already: fit the height, unchanged.
      k = room.height / art.height;
    } else {
      final extra = room.height / k - art.height;
      // The band region (the band and its copies) takes up `extra`: of
      // the copy counts whose (limited) stretch keeps it inside the room,
      // the one that fills most.
      const h = OpeningArtLayout.bandHeight;
      final m = (extra / h).floor();
      var best = -1.0;
      for (final n in [m, m + 1]) {
        final f = ((extra + h) / ((n + 1) * h)).clamp(
          1 - OpeningArtLayout.maxStretch,
          1 + OpeningArtLayout.maxStretch,
        );
        final added = (n + 1) * h * f - h;
        if (added <= extra + 1e-9 && added > best) {
          best = added;
          repeats = n;
          stretch = f;
        }
      }
    }
    final added =
        (repeats + 1) * OpeningArtLayout.bandHeight * stretch -
        OpeningArtLayout.bandHeight;
    final height = (art.height + added) * k;
    return OpeningArtGeometry._(
      scale: k,
      repeats: repeats,
      stretch: stretch,
      frame: Rect.fromLTWH(
        (room.width - art.width * k) / 2,
        (room.height - height) / 2,
        art.width * k,
        height,
      ),
    );
  }

  const OpeningArtGeometry._({
    required this.scale,
    required this.repeats,
    required this.stretch,
    required this.frame,
  });

  /// Screen px per art px (horizontally, and outside the band).
  final double scale;

  /// Copies of the band added.
  final int repeats;

  /// Height of every band copy (the original too) over the band's own.
  final double stretch;

  /// Where the whole, extended frame is drawn.
  final Rect frame;

  static const _b0 = OpeningArtLayout.bandTop;
  static const _b1 = _b0 + OpeningArtLayout.bandHeight;

  double get _added =>
      (repeats + 1) * OpeningArtLayout.bandHeight * stretch -
      OpeningArtLayout.bandHeight;

  /// Screen y of art row [y] above or below the band region.
  double y(double y) {
    assert(y <= _b0 || y >= _b1, 'row $y lies in the repeated band');
    return frame.top + (y < _b1 ? y : y + _added) * scale;
  }

  /// A rectangle of the art (above, below or around the band) on screen.
  Rect place(Rect r) => Rect.fromLTRB(
    frame.left + r.left * scale,
    y(r.top),
    frame.left + r.right * scale,
    y(r.bottom),
  );

  /// The art cut into (source, destination) slices: the part above the
  /// band, the band and its copies, the part below.
  List<(Rect, Rect)> slices() {
    const art = OpeningArtLayout.size;
    final bandH = OpeningArtLayout.bandHeight * stretch * scale;
    Rect dst(double top, double h) =>
        Rect.fromLTWH(frame.left, top, frame.width, h);
    return [
      (const Rect.fromLTRB(0, 0, 1200, _b0), dst(frame.top, _b0 * scale)),
      for (var i = 0; i <= repeats; i++)
        (
          const Rect.fromLTRB(0, _b0, 1200, _b1),
          dst(frame.top + _b0 * scale + i * bandH, bandH),
        ),
      (
        Rect.fromLTRB(0, _b1, art.width, art.height),
        dst(y(_b1), (art.height - _b1) * scale),
      ),
    ];
  }
}

/// The opening pages (al-Fatiha, the start of al-Baqarah) and the cover in
/// the theme's opening frame: the picture as wide as the room, made taller
/// by repeating its side borders ([OpeningArtGeometry]), [child] in its
/// panel, [top] and [bottom] in its cartouches, and [pageNumber] (when
/// given) just under it.
class OpeningArtBody extends StatelessWidget {
  const OpeningArtBody({
    super.key,
    required this.asset,
    required this.top,
    required this.bottom,
    required this.child,
    this.pageNumber,
  });

  static const numberSpace = 38.0;

  final String asset;
  final Widget top;
  final Widget bottom;
  final Widget child;
  final Widget? pageNumber;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return LayoutBuilder(
      builder: (context, box) {
        final room = Size(
          box.maxWidth,
          box.maxHeight - (pageNumber == null ? 0 : numberSpace),
        );
        final g = OpeningArtGeometry.fit(room);
        final frame = g.frame;
        final panel = g.place(OpeningArtLayout.panel);
        return Stack(
          children: [
            // The page's paper shows through the panel.
            Positioned.fromRect(
              rect: panel,
              child: ColoredBox(color: tokens.colors.paper),
            ),
            Positioned.fill(
              child: _SlicedArt(asset: asset, geometry: g),
            ),
            Positioned.fromRect(
              rect: panel.deflate(panel.width * 0.02),
              child: child,
            ),
            for (final c in [
              (OpeningArtLayout.top, top),
              (OpeningArtLayout.bottom, bottom),
            ])
              Positioned.fromRect(
                // The cartouche's ends are notched: keep the text inside.
                rect: () {
                  final r = g.place(c.$1);
                  return Rect.fromLTRB(
                    r.left + r.width * 0.16,
                    r.top + r.height * 0.14,
                    r.right - r.width * 0.16,
                    r.bottom - r.height * 0.14,
                  );
                }(),
                child: _OnCream(
                  child: FittedBox(fit: BoxFit.scaleDown, child: c.$2),
                ),
              ),
            if (pageNumber != null)
              Positioned(
                left: 0,
                right: 0,
                top: frame.bottom + 2,
                height: numberSpace - 2,
                child: Center(child: pageNumber),
              ),
          ],
        );
      },
    );
  }
}

/// The opening art drawn slice by slice ([OpeningArtGeometry.slices]).
class _SlicedArt extends StatefulWidget {
  const _SlicedArt({required this.asset, required this.geometry});

  final String asset;
  final OpeningArtGeometry geometry;

  @override
  State<_SlicedArt> createState() => _SlicedArtState();
}

class _SlicedArtState extends State<_SlicedArt> {
  ImageStream? _stream;
  ImageInfo? _info;
  late final _listener = ImageStreamListener((info, _) {
    if (!mounted) return;
    setState(() {
      _info?.dispose();
      _info = info;
    });
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(_SlicedArt old) {
    super.didUpdateWidget(old);
    if (old.asset != widget.asset) _resolve();
  }

  void _resolve() {
    final stream = AssetImage(widget.asset)
        .resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = stream..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _SlicedArtPainter(
      _info?.image,
      widget.geometry,
      context.tokens.colors.artTint,
    ),
  );
}

class _SlicedArtPainter extends CustomPainter {
  _SlicedArtPainter(this.image, this.geometry, this.tint);

  final ui.Image? image;
  final OpeningArtGeometry geometry;

  /// The mode's [ModeTokens.artTint]: the drawing recoloured to match the
  /// page frame, or its own colours when null.
  final (Color, Color)? tint;

  @override
  void paint(Canvas canvas, Size size) {
    final image = this.image;
    if (image == null) return;
    // The webp may be stored at another size than the layout's.
    final sx = image.width / OpeningArtLayout.size.width;
    final sy = image.height / OpeningArtLayout.size.height;
    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (tint case final t?) paint.colorFilter = duotoneFilter(t);
    final slices = geometry.slices();
    for (var i = 0; i < slices.length; i++) {
      final (src, dst) = slices[i];
      canvas.drawImageRect(
        image,
        Rect.fromLTRB(
          src.left * sx,
          src.top * sy,
          src.right * sx,
          src.bottom * sy,
        ),
        // Overlap the next slice by half a pixel: no hairline between.
        i == slices.length - 1 ? dst : dst.inflate(0.25).translate(0, 0.25),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SlicedArtPainter old) =>
      old.image != image ||
      old.tint != tint ||
      old.geometry.frame != geometry.frame ||
      old.geometry.repeats != geometry.repeats;
}

/// The cartouches are cream in every mode: what they hold is drawn in the
/// light mode's colours.
class _OnCream extends StatelessWidget {
  const _OnCream({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final light = tokens.style.modes[ThemeModeId.light]!;
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        extensions: [tokens.copyWith(mode: ThemeModeId.light, colors: light)],
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: light.ink),
        child: child,
      ),
    );
  }
}
