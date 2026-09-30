import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../core/settings/settings_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import 'frame_art.dart';

/// Ornament images for the Zakhrafa frame (built by tools/build_ornaments.py).
class FrameImages {
  const FrameImages({
    required this.corner,
    required this.edgeH,
    required this.edgeV,
    required this.rosette,
    required this.margin,
    required this.mosaic,
  });

  /// Top-right corner; mirrored for the other corners.
  final ui.Image corner;

  /// One repeat of the top edge; mirrored for the bottom.
  final ui.Image edgeH;

  /// One repeat of the right edge; mirrored for the left.
  final ui.Image edgeV;
  final ui.Image rosette;
  final ui.Image margin;

  /// Seamless mosaic tile, rendered at 3x.
  final ui.Image mosaic;

  /// Paint that fills with the mosaic at its natural size.
  Paint mosaicPaint() => Paint()
    ..shader = ui.ImageShader(
      mosaic,
      TileMode.repeated,
      TileMode.repeated,
      Matrix4.diagonal3Values(1 / 3, 1 / 3, 1).storage,
    );
}

Future<ui.Image> _load(String name) async {
  final data = await rootBundle.load('assets/ornaments/$name');
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  return (await codec.getNextFrame()).image;
}

/// The frame in use: the reader's choice, else the style's own (see
/// [defaultFrameFor]).
final frameDesignProvider = Provider<FrameDesign>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.frameDesign ?? defaultFrameFor(settings.styleId);
});

/// The Zakhrafa frame's ornament images; null for every other frame.
final frameImagesProvider = FutureProvider<FrameImages?>((ref) async {
  if (ref.watch(frameDesignProvider) != FrameDesign.zakhrafa) return null;
  final images = await Future.wait([
    _load('frame_corner.png'),
    _load('frame_edge_h.png'),
    _load('frame_edge_v.png'),
    _load('rosette_cartouche.png'),
    _load('rosette_margin.png'),
    _load('mosaic_tile.png'),
  ]);
  return FrameImages(
    corner: images[0],
    edgeH: images[1],
    edgeV: images[2],
    rosette: images[3],
    margin: images[4],
    mosaic: images[5],
  );
});

/// A drawn design's pictures for the current theme mode, and the theme's
/// paper. Null for Zakhrafa and plain, and while the pictures load (the
/// plain frame shows meanwhile).
class FrameLook {
  const FrameLook(this.art, this.paper);

  final FrameArt art;
  final Color paper;

  /// Text drawn over the art: the art's own ink.
  Color get ink => art.ink;
  Color get gold => art.gold;

  /// Opaque ground under a banner (it hides the printed header).
  Color get ground => art.ownGround ? art.ground : paper;

  static FrameLook? of(BuildContext context, WidgetRef ref) {
    final set = frameArtSet(ref.watch(frameDesignProvider));
    if (set == null) return null;
    final src = ref.watch(frameSourcesFamily(set)).value;
    if (src == null) return null;
    final tokens = context.tokens;
    final swap = darkModeSwap(src.colours, tokens.mode, tokens.colors);
    final art = ref
        .watch(frameArtFamily((set: set, paper: swap?.paper, ink: swap?.ink)))
        .value;
    return art == null ? null : FrameLook(art, tokens.colors.paper);
  }
}

/// What the frame shows around one page.
class FrameInfo {
  const FrameInfo({
    required this.page,
    required this.juz,
    required this.hizb,
    required this.surahName,
    this.catchword,
    this.banners = const [],
    this.quarters = const [],
    this.basmalaLines = const {},
    this.outerRight = true,
  });

  /// Line slots of the basmala under a surah header, drawn a little larger.
  final Set<int> basmalaLines;

  /// Surahs that start on this page, drawn over their printed header line.
  final List<SurahBanner> banners;

  /// Hizb quarters that start on this page, marked in the margin.
  final List<QuarterMark> quarters;

  /// Margin marks go on the outer edge: right for odd pages.
  final bool outerRight;

  final int page;
  final int juz;
  final int hizb;
  final String surahName;

  /// First word of the next page, shown under the frame.
  final String? catchword;
}

/// A surah header in the frame's own design.
class SurahBanner {
  const SurahBanner({
    required this.line,
    this.slots = 1,
    required this.number,
    required this.name,
    required this.meccan,
    required this.ayahCount,
    required this.order,
    this.after,
  });

  /// Line slot (0..14) of the printed header, and how many slots it takes
  /// (two in the Shamarly edition).
  final int line;
  final int slots;
  final int number;
  final String name;
  final bool meccan;
  final int ayahCount;

  /// Place in the order of revelation, and the surah revealed just before.
  final int order;
  final String? after;
}

/// The start of a hizb quarter.
class QuarterMark {
  const QuarterMark({
    required this.line,
    required this.quarter,
    required this.surah,
    required this.ayah,
  });

  final int line;

  /// 1..240 over the whole mushaf.
  final int quarter;
  final int surah;
  final int ayah;
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
    this.onQuarterTap,
    this.tools,
    this.linePadding,
  });

  /// Room the page keeps above its first line and below its last, for a
  /// page of the given size; the banners and margin marks follow it.
  final EdgeInsets Function(Size page)? linePadding;

  static const band = 30.0;
  static const lines = 15;
  static const catchwordSpace = 26.0;

  final FrameInfo? info;
  final Widget child;
  final VoidCallback? onJuzTap;
  final VoidCallback? onHizbTap;
  final VoidCallback? onSurahTap;
  final VoidCallback? onPageTap;
  final ValueChanged<QuarterMark>? onQuarterTap;

  /// Small reading tools shown just under the page number.
  final Widget? tools;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(frameImagesProvider).value;
    final look = FrameLook.of(context, ref);
    final overlays = LayoutBuilder(
      builder: (context, box) {
        const inset = band + 6;
        final pad =
            linePadding?.call(
              Size(box.maxWidth - 2 * inset, box.maxHeight - 2 * inset),
            ) ??
            EdgeInsets.zero;
        final slot = (box.maxHeight - 2 * inset - pad.vertical) / lines;
        final top = inset + pad.top;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final b in info?.banners ?? const <SurahBanner>[])
              Positioned(
                top: top + b.line * slot,
                left: inset - 4,
                right: inset - 4,
                height: slot * b.slots,
                child: SurahBannerView(banner: b, images: images, look: look),
              ),
            for (final q in info?.quarters ?? const <QuarterMark>[])
              Positioned(
                top: top + (q.line + 0.5) * slot - 17,
                left: (info!.outerRight) ? null : band / 2 - 17,
                right: (info!.outerRight) ? band / 2 - 17 : null,
                child: _QuarterRosette(
                  mark: q,
                  image: images?.margin,
                  look: look,
                  onTap: onQuarterTap,
                ),
              ),
          ],
        );
      },
    );
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
              Positioned.fill(
                child: CustomPaint(
                  painter: look != null
                      ? ArtBandPainter(art: look.art, paper: t.paper)
                      : _FramePainter(
                          images: images,
                          rule: t.marker,
                          paper: t.paper,
                          ink: t.frame,
                        ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(band + 6),
                  child: child,
                ),
              ),
              Positioned.fill(child: overlays),
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
                      look: look,
                      child: DefaultTextStyle.merge(
                        style: TextStyle(
                          fontFamily: 'UthmanTahaNaskh',
                          fontSize: 15,
                          color: look?.ink ?? t.ink,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Tap(
                              label: l.juzLabel(digits(info!.juz)),
                              onTap: onJuzTap,
                            ),
                            _Star(color: look?.gold ?? t.marker),
                            _Tap(
                              label: l.hizbLabel(digits(info!.hizb)),
                              onTap: onHizbTap,
                            ),
                            _Star(color: look?.gold ?? t.marker),
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
                      look: look,
                      medallion: true,
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
          child: Stack(
            children: [
              if (tools != null) Center(child: tools),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // Start side (right in Arabic): the quarter that begins on
                    // this page, so the reader notices it.
                    if (info != null && info!.quarters.isNotEmpty)
                      _QuarterLabel(
                        text: quarterName(
                          l,
                          digits,
                          info!.quarters.last.quarter,
                        ),
                        color: t.muted,
                      ),
                    const Spacer(),
                    if (info?.catchword != null)
                      Text(
                        info!.catchword!,
                        semanticsLabel: l.catchwordLabel(info!.catchword!),
                        style: TextStyle(
                          fontFamily: 'UthmanicHafs',
                          fontSize: 15,
                          height: 1.4,
                          color: t.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A small picture of the frame in use (settings): the band, corners and
/// cartouches drawn on a page of 300 × 440 and scaled down.
class FramePreview extends ConsumerWidget {
  const FramePreview({super.key, this.width = 84});

  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(frameImagesProvider).value;
    final look = FrameLook.of(context, ref);
    final t = context.tokens.colors;
    const band = IlluminatedFrame.band;
    return Semantics(
      image: true,
      label: AppLocalizations.of(context).framePreviewLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: width * 440 / 300,
          child: FittedBox(
            child: SizedBox(
              width: 300,
              height: 440,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: look != null
                          ? ArtBandPainter(art: look.art, paper: t.paper)
                          : _FramePainter(
                              images: images,
                              rule: t.marker,
                              paper: t.paper,
                              ink: t.frame,
                            ),
                    ),
                  ),
                  for (final top in [true, false])
                    Positioned(
                      top: top ? band / 2 - 15 : null,
                      bottom: top ? null : band / 2 - 15,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _Cartouche(
                          width: top ? 150 : 60,
                          height: 30,
                          fill: t.paper,
                          rosette: top ? images?.rosette : images?.margin,
                          look: look,
                          medallion: !top,
                          child: const SizedBox.shrink(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
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
                  fontFamily: 'UthmanTahaNaskh',
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

/// A rounded capsule with a rosette on each end; in a drawn design, the
/// owner's surah divider (or, for the page number, his medallion).
class _Cartouche extends StatelessWidget {
  const _Cartouche({
    required this.width,
    required this.height,
    required this.fill,
    required this.rosette,
    required this.child,
    this.look,
    this.medallion = false,
  });

  final double width;
  final double height;
  final Color fill;
  final ui.Image? rosette;
  final Widget child;
  final FrameLook? look;

  /// Rosettes from the design's medallion (the page number's).
  final bool medallion;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    final r = height * 0.9;
    final look = this.look;
    if (look != null) {
      return medallion
          ? ArtMedal(look: look, size: IlluminatedFrame.band + 6, child: child)
          : _ArtCartouche(look: look, height: height, child: child);
    }
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

/// The owner's surah divider at [height] (or narrower, to stay between the
/// corners), with [child] over its central cartouche.
class _ArtCartouche extends StatelessWidget {
  const _ArtCartouche({
    required this.look,
    required this.height,
    required this.child,
  });

  final FrameLook look;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final divider = look.art[FramePiece.divider];
    final aspect = divider.size.width / divider.size.height;
    return LayoutBuilder(
      builder: (context, box) {
        const inset = IlluminatedFrame.band + 6;
        final w = math.min(aspect * height, box.maxWidth - 2 * inset);
        final h = w / aspect;
        final panel = look.art.dividerPanel;
        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: ArtPicturePainter(divider)),
              ),
              // The whole height (the tap targets are 32 high); the text
              // itself stays inside the cartouche.
              Positioned(
                left: panel.left * w,
                width: panel.width * w,
                top: 0,
                bottom: 0,
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: look.ink),
                  child: FittedBox(fit: BoxFit.scaleDown, child: child),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The owner's medallion, [size] square, with [child] (the page number)
/// over it. A disc of paper under it keeps the band's rules out of the
/// number's way.
class ArtMedal extends StatelessWidget {
  const ArtMedal({
    super.key,
    required this.look,
    required this.size,
    this.child,
    this.ground,
  });

  final FrameLook look;
  final double size;
  final Widget? child;

  /// The disc's colour (default: the page's ground).
  final Color? ground;

  @override
  Widget build(BuildContext context) {
    final disc = ground ?? look.ground;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: ArtPicturePainter(
          look.art[FramePiece.medal],
          disc: (disc, 0.8),
        ),
        child: child == null
            ? null
            : DefaultTextStyle.merge(
                // A halo of the disc's colour lifts the number off the
                // medallion's lines.
                style: TextStyle(
                  color: look.ink,
                  shadows: [
                    for (final o in const [
                      Offset(1, 0),
                      Offset(-1, 0),
                      Offset(0, 1),
                      Offset(0, -1),
                    ])
                      Shadow(color: disc, offset: o, blurRadius: 1.5),
                  ],
                ),
                child: Center(
                  child: FittedBox(fit: BoxFit.scaleDown, child: child),
                ),
              ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter({
    required this.images,
    required this.rule,
    required this.paper,
    required this.ink,
    this.band = IlluminatedFrame.band,
    this.fillPaper = true,
  });

  /// Null for the plain frame, drawn with rules in the style's colours.
  final FrameImages? images;
  final Color rule;
  final Color paper;

  /// The style's frame colour (the plain frame's band).
  final Color ink;
  final double band;

  /// Paint the paper inside the band (off for the ornate pages, whose
  /// mosaic shows through).
  final bool fillPaper;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final images = this.images;
    if (images == null) return _paintPlain(canvas, size);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    final c = band * images.corner.width / images.edgeH.height;

    // Paper inside the band, and two fine rules along its inner edge.
    if (fillPaper) {
      canvas.drawRect(
        Rect.fromLTRB(band, band, w - band, h - band),
        Paint()..color = paper,
      );
    }
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

    // Everything below stays inside the band: the corner pieces are larger
    // than the band and would otherwise show as squares inside the page.
    canvas.save();
    canvas.clipPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRect(Rect.fromLTRB(band, band, w - band, h - band)),
    );
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
    canvas.restore();
  }

  /// The plain frame: a tinted band between a strong outer rule and a fine
  /// inner one, with a small lozenge at each corner.
  void _paintPlain(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final outer = Offset.zero & size;
    final inner = Rect.fromLTRB(band, band, w - band, h - band);
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(outer)
        ..addRect(inner),
      Paint()..color = ink.withValues(alpha: 0.2),
    );
    if (fillPaper) canvas.drawRect(inner, Paint()..color = paper);
    final strong = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..color = ink;
    final fine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = rule;
    canvas
      ..drawRect(outer.deflate(3), strong)
      ..drawRect(outer.deflate(7), fine)
      ..drawRect(inner.inflate(3), fine)
      ..drawRect(inner, strong..strokeWidth = 1.4);
    final d = band * 0.32;
    for (final c in [
      Offset(band / 2, band / 2),
      Offset(w - band / 2, band / 2),
      Offset(band / 2, h - band / 2),
      Offset(w - band / 2, h - band / 2),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - d)
          ..lineTo(c.dx + d, c.dy)
          ..lineTo(c.dx, c.dy + d)
          ..lineTo(c.dx - d, c.dy)
          ..close(),
        Paint()..color = rule,
      );
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.ink != ink ||
      old.images != images ||
      old.rule != rule ||
      old.paper != paper ||
      old.band != band ||
      old.fillPaper != fillPaper;
}

/// A surah header over the page: the mosaic band, a cartouche with the
/// surah's number, name and type, its verse count and place in revelation.
class SurahBannerView extends StatelessWidget {
  const SurahBannerView({
    super.key,
    required this.banner,
    required this.images,
    this.look,
  });

  final SurahBanner banner;
  final FrameImages? images;

  /// A drawn design: the owner's surah divider instead.
  final FrameLook? look;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final b = banner;
    final type = b.meccan ? l.meccan : l.medinan;
    final info = b.after == null
        ? l.surahBannerInfoFirst(digits(b.ayahCount), digits(b.order))
        : l.surahBannerInfo(digits(b.ayahCount), digits(b.order), b.after!);
    final look = this.look;
    final ink = look?.ink ?? t.ink;
    final text = FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: look != null ? 2 : 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.surahBannerTitle(digits(b.number), b.name, type),
              style: TextStyle(
                fontFamily: 'UthmanTahaNaskh',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                height: look != null ? 1.05 : 1.2,
                color: ink,
              ),
            ),
            Text(
              info,
              style: TextStyle(
                fontFamily: 'KFGQPCAN',
                fontSize: 10.5,
                height: look != null ? 1.1 : 1.3,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
    if (look != null) {
      final divider = look.art[FramePiece.divider];
      return Semantics(
        header: true,
        label: '${l.surahBannerTitle(digits(b.number), b.name, type)}. $info',
        excludeSemantics: true,
        child: CustomPaint(
          // Opaque first: the printed header underneath must not show.
          painter: ArtPicturePainter(divider, background: look.ground),
          child: LayoutBuilder(
            builder: (context, box) {
              final at = fittedRect(
                divider.size,
                Offset.zero & box.biggest,
                BoxFit.contain,
              );
              final p = look.art.dividerPanel;
              return Stack(
                children: [
                  Positioned(
                    left: at.left + p.left * at.width,
                    top: at.top + p.top * at.height,
                    width: p.width * at.width,
                    height: p.height * at.height,
                    child: text,
                  ),
                ],
              );
            },
          ),
        ),
      );
    }
    return Semantics(
      header: true,
      label: '${l.surahBannerTitle(digits(b.number), b.name, type)}. $info',
      excludeSemantics: true,
      child: CustomPaint(
        painter: _BannerPainter(
          images: images,
          paper: t.paper,
          navy: t.frame,
          rule: t.marker,
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final h = box.maxHeight;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: h * 0.95,
                vertical: h * 0.1,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: t.paper,
                  borderRadius: BorderRadius.circular(h),
                  border: Border.all(color: t.frame, width: 2),
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(h),
                  border: Border.all(color: t.marker, width: 0.8),
                ),
                child: text,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BannerPainter extends CustomPainter {
  _BannerPainter({
    required this.images,
    required this.paper,
    required this.navy,
    required this.rule,
  });

  final FrameImages? images;
  final Color paper;
  final Color navy;
  final Color rule;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    // Opaque first: the printed header underneath must not show.
    canvas.drawRect(r, Paint()..color = paper);
    final img = images;
    if (img != null) canvas.drawRect(r, img.mosaicPaint());
    canvas.drawRect(
      r.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = navy,
    );
    canvas.drawRect(
      r.deflate(4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = rule,
    );
    if (img != null) {
      final d = size.height * 0.8;
      final src = Rect.fromLTWH(
        0,
        0,
        img.rosette.width.toDouble(),
        img.rosette.height.toDouble(),
      );
      for (final cx in [size.height * 0.5, size.width - size.height * 0.5]) {
        canvas.drawImageRect(
          img.rosette,
          src,
          Rect.fromCenter(
            center: Offset(cx, size.height / 2),
            width: d,
            height: d,
          ),
          Paint(),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BannerPainter old) =>
      old.images != images || old.paper != paper;
}

/// A hizb quarter mark in the margin; tapping it sets the reading mark.
class _QuarterRosette extends StatelessWidget {
  const _QuarterRosette({
    required this.mark,
    required this.image,
    required this.onTap,
    this.look,
  });

  final QuarterMark mark;
  final ui.Image? image;

  /// A drawn design: the owner's medallion.
  final FrameLook? look;
  final ValueChanged<QuarterMark>? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final digits = NumberFormatter(Localizations.localeOf(context));
    final label = quarterName(l, digits, mark.quarter);
    return Semantics(
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap == null ? null : () => onTap!(mark),
        child: SizedBox(
          width: 34,
          height: 34,
          child: look != null
              ? ArtMedal(look: look!, size: 34)
              : image == null
              ? null
              : RawImage(image: image, width: 34, height: 34),
        ),
      ),
    );
  }
}

/// The fully illuminated page used for the cover, al-Fatiha, the opening
/// of al-Baqarah and the splash: mosaic ground, outer frame, a framed
/// central panel, and a cartouche above and below it.
class OrnateFrame extends ConsumerWidget {
  const OrnateFrame({
    super.key,
    required this.top,
    required this.bottom,
    required this.child,
    this.page,
    this.onPageTap,
    this.catchword,
    this.catchwordSpace = true,
    this.tools,
    this.openingSurah,
  });

  /// Small reading tools shown just under the page number.
  final Widget? tools;

  /// The opening page of this surah (1 or 2); null for the cover and the
  /// splash. Drawn designs put the surah's ornament in its title.
  final int? openingSurah;
  final Widget top;
  final Widget bottom;
  final Widget child;
  final int? page;
  final VoidCallback? onPageTap;
  final String? catchword;
  final bool catchwordSpace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(frameImagesProvider).value;
    final look = FrameLook.of(context, ref);
    final t = context.tokens.colors;
    final l = AppLocalizations.of(context);
    final digits = NumberFormatter(Localizations.localeOf(context));
    const band = IlluminatedFrame.band;

    Widget pageCartouche() => Positioned(
      bottom: band / 2 - 15,
      left: 0,
      right: 0,
      child: Center(
        child: _Cartouche(
          width: 74,
          height: 30,
          fill: t.paper,
          rosette: images?.margin,
          look: look,
          medallion: true,
          child: _Tap(
            label: digits(page!),
            bold: true,
            semanticLabel: l.pageOf('$page'),
            onTap: onPageTap,
            fontSize: 15,
          ),
        ),
      ),
    );

    final body = LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final panel = Rect.fromLTRB(26, h * 0.215, w - 26, h * 0.785);
        const inner = 12.0;
        final cartW = (w - 150).clamp(160.0, 320.0);
        final cartH = (h * 0.085).clamp(52.0, 76.0);
        if (look != null) {
          return _artBody(look, Size(w, h), panel, cartW, cartH, l, digits);
        }
        Widget cartouche(double centreY, Widget c) => Positioned(
          top: centreY - cartH / 2,
          left: 0,
          right: 0,
          child: Center(
            child: _Cartouche(
              width: cartW,
              height: cartH,
              fill: t.paper,
              rosette: images?.rosette,
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  fontFamily: 'KFGQPCAN',
                  color: t.ink,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                child: c,
              ),
            ),
          ),
        );
        return Stack(
          children: [
            if (images != null)
              Positioned.fill(
                child: CustomPaint(painter: _MosaicPainter(images)),
              ),
            Positioned.fill(
              child: CustomPaint(
                painter: _FramePainter(
                  images: images,
                  rule: t.marker,
                  paper: t.paper,
                  ink: t.frame,
                  fillPaper: images == null,
                ),
              ),
            ),
            Positioned.fromRect(
              rect: panel.inflate(inner),
              child: CustomPaint(
                painter: _FramePainter(
                  images: images,
                  rule: t.marker,
                  paper: t.paper,
                  ink: t.frame,
                  band: inner,
                ),
              ),
            ),
            Positioned.fromRect(rect: panel.deflate(4), child: child),
            cartouche((band + panel.top - inner) / 2, top),
            cartouche((panel.bottom + inner + h - band) / 2, bottom),
            if (page != null) pageCartouche(),
          ],
        );
      },
    );
    if (!catchwordSpace) return body;
    return Column(
      children: [
        Expanded(child: body),
        SizedBox(
          height: IlluminatedFrame.catchwordSpace,
          child: Stack(
            children: [
              if (tools != null) Center(child: tools),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: catchword == null
                      ? null
                      : Text(
                          catchword!,
                          semanticsLabel: l.catchwordLabel(catchword!),
                          style: TextStyle(
                            fontFamily: 'UthmanicHafs',
                            fontSize: 15,
                            height: 1.4,
                            color: t.muted,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

extension on OrnateFrame {
  /// A drawn design's ornate page. The cover and the splash: the owner's
  /// splash behind the titles. An opening page: the owner's opening page
  /// fitted into the box, the mushaf page in its text panel, the surah's
  /// details in its title box and under the panel, and the page number on
  /// its bottom band.
  Widget _artBody(
    FrameLook look,
    Size size,
    Rect panel,
    double cartW,
    double cartH,
    AppLocalizations l,
    NumberFormatter digits,
  ) {
    const band = IlluminatedFrame.band;
    Widget text(Widget c) => FittedBox(
      fit: BoxFit.scaleDown,
      child: DefaultTextStyle.merge(
        style: TextStyle(fontFamily: 'KFGQPCAN', color: look.ink, height: 1.3),
        textAlign: TextAlign.center,
        child: c,
      ),
    );
    final surah = openingSurah;
    if (surah == null) {
      Widget title(double centreY, Widget c) => Positioned(
        top: centreY - cartH / 2,
        height: cartH,
        left: (size.width - cartW) / 2,
        width: cartW,
        child: Center(child: text(c)),
      );
      return Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: ArtPicturePainter(
                look.art[FramePiece.splash],
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fromRect(
            rect: panel.deflate(4),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: look.ink),
              child: child,
            ),
          ),
          title((band + panel.top) / 2, top),
          title((panel.bottom + size.height - band) / 2, bottom),
        ],
      );
    }
    final picture = look.art[surah == 1 ? FramePiece.openA : FramePiece.openB];
    final at = fittedRect(picture.size, Offset.zero & size, BoxFit.contain);
    Rect place(Rect r) => mapRect(r, picture.size, at);
    final pageRect = place(OpeningPlaces.page);
    final k = at.width / picture.size.width;
    final medal = 60 * k;
    final centre = at.topLeft + OpeningPlaces.pageNumber * k;
    // The mushaf's ink follows the theme: on a ground of the other
    // lightness (the Egyptian design in light mode) its panel takes the
    // theme's paper.
    bool darkColour(Color c) => c.computeLuminance() < 0.2;
    final panelPaper = darkColour(look.art.ground) != darkColour(look.paper);
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: ArtPicturePainter(picture, background: look.art.ground),
          ),
        ),
        if (panelPaper)
          Positioned.fromRect(
            rect: pageRect,
            child: ColoredBox(color: look.paper),
          ),
        Positioned.fromRect(rect: pageRect, child: child),
        Positioned.fromRect(
          rect: place(OpeningPlaces.title).deflate(4 * k),
          child: Center(child: text(top)),
        ),
        Positioned.fromRect(
          rect: place(OpeningPlaces.foot),
          child: Center(child: text(bottom)),
        ),
        if (page != null)
          Positioned(
            left: centre.dx - medal / 2,
            top: centre.dy - medal / 2,
            child: ArtMedal(
              look: look,
              size: medal,
              ground: look.art.ground,
              child: _Tap(
                label: digits(page!),
                bold: true,
                semanticLabel: l.pageOf('$page'),
                onTap: onPageTap,
                fontSize: 15,
              ),
            ),
          ),
      ],
    );
  }
}

class _MosaicPainter extends CustomPainter {
  _MosaicPainter(this.images);

  final FrameImages images;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, images.mosaicPaint());
  }

  @override
  bool shouldRepaint(_MosaicPainter old) => old.images != images;
}

/// "Hizb 5", "Quarter of hizb 5", "Half of hizb 5" or "Three quarters of
/// hizb 5" for a quarter numbered 1..240.
String quarterName(AppLocalizations l, NumberFormatter digits, int quarter) {
  final hizb = digits((quarter - 1) ~/ 4 + 1);
  return switch ((quarter - 1) % 4) {
    0 => l.hizbLabel(hizb),
    1 => l.quarterHizb(hizb),
    2 => l.halfHizb(hizb),
    _ => l.threeQuartersHizb(hizb),
  };
}

/// The quarter's name in the catchword's font, size and colour. Its words
/// use the Quran font; its number the mushaf's Naskh, because the Quran
/// font draws digits as verse-end markers.
class _QuarterLabel extends StatelessWidget {
  const _QuarterLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontFamily: 'UthmanicHafs',
      fontSize: 15,
      height: 1.4,
      color: color,
    );
    final digits = RegExp('[\u0660-\u0669]+');
    final spans = <TextSpan>[];
    var i = 0;
    for (final m in digits.allMatches(text)) {
      if (m.start > i) spans.add(TextSpan(text: text.substring(i, m.start)));
      spans.add(
        TextSpan(
          text: m[0],
          style: const TextStyle(fontFamily: 'UthmanTahaNaskh'),
        ),
      );
      i = m.end;
    }
    if (i < text.length) spans.add(TextSpan(text: text.substring(i)));
    return Text.rich(
      TextSpan(style: base, children: spans),
      semanticsLabel: text,
    );
  }
}
