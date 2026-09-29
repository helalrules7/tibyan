import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Ornament images for the Zakhrafa frame (built by tools/build_ornaments.py).
class FrameImages {
  const FrameImages({
    required this.corner,
    required this.edgeH,
    required this.edgeV,
    required this.rosette,
    required this.margin,
  });

  /// Top-right corner; mirrored for the other corners.
  final ui.Image corner;

  /// One repeat of the top edge; mirrored for the bottom.
  final ui.Image edgeH;

  /// One repeat of the right edge; mirrored for the left.
  final ui.Image edgeV;
  final ui.Image rosette;
  final ui.Image margin;
}

Future<ui.Image> _load(String name) async {
  final data = await rootBundle.load('assets/ornaments/$name');
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  return (await codec.getNextFrame()).image;
}

final frameImagesProvider = FutureProvider<FrameImages>((ref) async {
  final images = await Future.wait([
    _load('frame_corner.png'),
    _load('frame_edge_h.png'),
    _load('frame_edge_v.png'),
    _load('rosette_cartouche.png'),
    _load('rosette_margin.png'),
  ]);
  return FrameImages(
    corner: images[0],
    edgeH: images[1],
    edgeV: images[2],
    rosette: images[3],
    margin: images[4],
  );
});

/// What the frame shows around one page.
class FrameInfo {
  const FrameInfo({
    required this.page,
    required this.juz,
    required this.hizb,
    required this.surahName,
    this.catchword,
  });

  final int page;
  final int juz;
  final int hizb;
  final String surahName;

  /// First word of the next page, shown under the frame.
  final String? catchword;
}

/// The illuminated page frame: an ornamental band, a cartouche with the
/// juz, hizb and surah on the top band, the page number centred on the
/// bottom band, and the next page's first word under the frame.
class IlluminatedFrame extends ConsumerWidget {
  const IlluminatedFrame({
    super.key,
    required this.info,
    required this.child,
    this.onJuzTap,
    this.onHizbTap,
    this.onSurahTap,
    this.onPageTap,
  });

  static const band = 30.0;
  static const catchwordSpace = 26.0;

  final FrameInfo? info;
  final Widget child;
  final VoidCallback? onJuzTap;
  final VoidCallback? onHizbTap;
  final VoidCallback? onSurahTap;
  final VoidCallback? onPageTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(frameImagesProvider).value;
    final tokens = context.tokens;
    final t = tokens.colors;
    final l = AppLocalizations.of(context);
    final digits = NumberFormatter(Localizations.localeOf(context));
    final cartoucheFill = t.paper;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              if (images != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FramePainter(
                      images: images,
                      rule: t.marker,
                      paper: t.paper,
                    ),
                  ),
                ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(band + 6),
                  child: child,
                ),
              ),
              if (info != null) ...[
                Positioned(
                  top: band / 2 - 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _Cartouche(
                      width: 234,
                      height: 32,
                      fill: cartoucheFill,
                      rosette: images?.rosette,
                      child: DefaultTextStyle.merge(
                        style: TextStyle(
                          fontFamily: 'KFGQPCAN',
                          fontSize: 13,
                          color: t.ink,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Tap(
                              label: l.juzLabel(digits(info!.juz)),
                              onTap: onJuzTap,
                            ),
                            _Star(color: t.marker),
                            _Tap(
                              label: l.hizbLabel(digits(info!.hizb)),
                              onTap: onHizbTap,
                            ),
                            _Star(color: t.marker),
                            _Tap(
                              label: info!.surahName,
                              bold: true,
                              onTap: onSurahTap,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  // Centred on the bottom band (the catchword row is outside this stack).
                  bottom: band / 2 - 15,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _Cartouche(
                      width: 74,
                      height: 30,
                      fill: cartoucheFill,
                      rosette: images?.margin,
                      child: _Tap(
                        label: digits(info!.page),
                        bold: true,
                        semanticLabel: l.pageOf('${info!.page}'),
                        onTap: onPageTap,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: catchwordSpace,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: info?.catchword == null
                  ? null
                  : Text(
                      info!.catchword!,
                      semanticsLabel: l.catchwordLabel(info!.catchword!),
                      style: TextStyle(
                        fontFamily: 'UthmanicHafs',
                        fontSize: 15,
                        height: 1.4,
                        color: t.muted,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Arabic-Indic digits in Arabic, Western digits otherwise.
class NumberFormatter {
  NumberFormatter(Locale locale) : _arabic = locale.languageCode == 'ar';

  final bool _arabic;

  String call(int n) => _arabic
      ? n
            .toString()
            .split('')
            .map((d) => String.fromCharCode(0x0660 + int.parse(d)))
            .join()
      : '$n';
}

class _Star extends StatelessWidget {
  const _Star({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text('✦', style: TextStyle(color: color, fontSize: 10)),
    ),
  );
}

class _Tap extends StatelessWidget {
  const _Tap({
    required this.label,
    this.onTap,
    this.bold = false,
    this.semanticLabel,
    this.fontSize,
  });

  final String label;
  final VoidCallback? onTap;
  final bool bold;
  final String? semanticLabel;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                  fontSize: fontSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A rounded capsule with a rosette on each end.
class _Cartouche extends StatelessWidget {
  const _Cartouche({
    required this.width,
    required this.height,
    required this.fill,
    required this.rosette,
    required this.child,
  });

  final double width;
  final double height;
  final Color fill;
  final ui.Image? rosette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    final r = height * 0.9;
    return SizedBox(
      width: width + r * 1.2,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(height / 2),
              border: Border.all(color: t.frame, width: 2.4),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              border: Border.all(color: t.marker, width: 1),
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: t.ink),
              child: Center(child: child),
            ),
          ),
          if (rosette != null) ...[
            Positioned(
              left: 0,
              child: RawImage(image: rosette, width: r, height: r),
            ),
            Positioned(
              right: 0,
              child: RawImage(image: rosette, width: r, height: r),
            ),
          ],
        ],
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter({
    required this.images,
    required this.rule,
    required this.paper,
  });

  final FrameImages images;
  final Color rule;
  final Color paper;

  static const band = IlluminatedFrame.band;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..filterQuality = FilterQuality.medium;
    final c = band * images.corner.width / images.edgeH.height;

    // Paper inside the band, and two fine rules along its inner edge.
    canvas.drawRect(
      Rect.fromLTRB(band, band, w - band, h - band),
      Paint()..color = paper,
    );
    final inner = Rect.fromLTRB(band - 3, band - 3, w - band + 3, h - band + 3);
    canvas.drawRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = rule,
    );

    void draw(
      ui.Image img,
      Rect dst, {
      bool flipX = false,
      bool flipY = false,
    }) {
      canvas.save();
      canvas.translate(dst.center.dx, dst.center.dy);
      canvas.scale(flipX ? -1 : 1, flipY ? -1 : 1);
      final src = Rect.fromLTWH(
        0,
        0,
        img.width.toDouble(),
        img.height.toDouble(),
      );
      canvas.drawImageRect(
        img,
        src,
        Rect.fromCenter(
          center: Offset.zero,
          width: dst.width,
          height: dst.height,
        ),
        paint,
      );
      canvas.restore();
    }

    // Edges: whole repeats, stretched a little so they fit exactly.
    final spanX = w - 2 * c;
    final tileW = band * images.edgeH.width / images.edgeH.height;
    final nx = (spanX / tileW).round().clamp(1, 1000);
    final stepX = spanX / nx;
    for (var i = 0; i < nx; i++) {
      final x = c + i * stepX;
      draw(images.edgeH, Rect.fromLTWH(x, 0, stepX + 0.5, band));
      draw(
        images.edgeH,
        Rect.fromLTWH(x, h - band, stepX + 0.5, band),
        flipY: true,
      );
    }
    final spanY = h - 2 * c;
    final tileH = band * images.edgeV.height / images.edgeV.width;
    final ny = (spanY / tileH).round().clamp(1, 1000);
    final stepY = spanY / ny;
    for (var i = 0; i < ny; i++) {
      final y = c + i * stepY;
      draw(images.edgeV, Rect.fromLTWH(w - band, y, band, stepY + 0.5));
      draw(images.edgeV, Rect.fromLTWH(0, y, band, stepY + 0.5), flipX: true);
    }

    // Corners.
    draw(images.corner, Rect.fromLTWH(w - c, 0, c, c));
    draw(images.corner, Rect.fromLTWH(0, 0, c, c), flipX: true);
    draw(images.corner, Rect.fromLTWH(w - c, h - c, c, c), flipY: true);
    draw(
      images.corner,
      Rect.fromLTWH(0, h - c, c, c),
      flipX: true,
      flipY: true,
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.images != images || old.rule != rule || old.paper != paper;
}
