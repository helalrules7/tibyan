import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../../core/db/ayahinfo_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../mushaf_providers.dart';
import 'mushaf_page.dart';

/// Ink area shared by all quran.com page images (1024 x 1656), and the
/// 15 line slots inside it.
const _ink = Rect.fromLTRB(51, 8, 983, 1602);

/// Pages 1 and 2 only use the upper half of their images.
const _openingInk = Rect.fromLTRB(51, 6, 967, 814);
const _lineCount = 15;
const _pitch = 1594 / _lineCount;

/// Where the page image goes on screen. Normal pages fill the width, and
/// their 15 lines spread evenly over the full height, so the page fills
/// the screen without stretching the calligraphy. Pages 1 and 2 (drawn
/// inside a round ornament) and screens wider than the page are scaled
/// as a whole instead.
class _PageLayout {
  _PageLayout(this.size, {required bool opening})
    : ink = opening ? _openingInk : _ink {
    final byWidth = size.width / ink.width;
    final byHeight = size.height / ink.height;
    scale = byWidth < byHeight ? byWidth : byHeight;
    strips = !opening && byWidth < byHeight;
    offset = Offset(
      (size.width - ink.width * scale) / 2,
      (size.height - ink.height * scale) / 2,
    );
  }

  final Size size;
  final Rect ink;
  late final double scale;
  late final bool strips;
  late final Offset offset;

  double get _slot => size.height / _lineCount;

  double _stripTop(int line) => line * _slot + (_slot - _pitch * scale) / 2;

  int _lineOfImageY(double y) =>
      ((y - ink.top) / _pitch).floor().clamp(0, _lineCount - 1);

  Offset toScreen(Offset p, {int? line}) {
    if (!strips) return (p - ink.topLeft) * scale + offset;
    final j = line ?? _lineOfImageY(p.dy);
    return Offset(
      (p.dx - ink.left) * scale,
      _stripTop(j) + (p.dy - ink.top - j * _pitch) * scale,
    );
  }

  Offset toImage(Offset p) {
    if (!strips) return (p - offset) / scale + ink.topLeft;
    final j = (p.dy / _slot).floor().clamp(0, _lineCount - 1);
    return Offset(
      p.dx / scale + ink.left,
      ink.top + j * _pitch + (p.dy - _stripTop(j)) / scale,
    );
  }

  Rect toScreenRect(Rect r) {
    final line = _lineOfImageY(r.center.dy);
    return Rect.fromPoints(
      toScreen(r.topLeft, line: line),
      toScreen(r.bottomRight, line: line),
    );
  }

  void paint(Canvas canvas, ui.Image image, Paint paint) {
    if (!strips) {
      canvas.drawImageRect(
        image,
        ink,
        Rect.fromLTWH(
          offset.dx,
          offset.dy,
          ink.width * scale,
          ink.height * scale,
        ),
        paint,
      );
      return;
    }
    for (var j = 0; j < _lineCount; j++) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(ink.left, ink.top + j * _pitch, ink.width, _pitch),
        Rect.fromLTWH(0, _stripTop(j), size.width, _pitch * scale),
        paint,
      );
    }
  }
}

/// One page of the old Madina edition (1405H): the page image (unchanged),
/// coloured for the current mode, with the selected verse highlighted
/// from its glyph boxes.
class OldMushafPage extends ConsumerStatefulWidget {
  const OldMushafPage({
    super.key,
    required this.page,
    required this.selected,
    required this.onVerseTap,
    required this.onBackgroundTap,
  });

  final int page;
  final VerseKey? selected;
  final ValueChanged<VerseKey> onVerseTap;
  final VoidCallback onBackgroundTap;

  @override
  ConsumerState<OldMushafPage> createState() => _OldMushafPageState();
}

class _OldMushafPageState extends ConsumerState<OldMushafPage> {
  late Future<(ui.Image, List<GlyphRow>)> _load;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  @override
  void didUpdateWidget(OldMushafPage old) {
    super.didUpdateWidget(old);
    if (old.page != widget.page) _load = _fetch();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<(ui.Image, List<GlyphRow>)> _fetch() async {
    final dir = ref.read(pageInstallerProvider).dir;
    final file = File(
      p.join(dir.path, 'p${widget.page.toString().padLeft(3, '0')}.png'),
    );
    final codec = await ui.instantiateImageCodec(await file.readAsBytes());
    final image = (await codec.getNextFrame()).image;
    _image?.dispose();
    _image = image;
    final glyphs =
        await ref.read(ayahInfoDatabaseProvider)?.page(widget.page) ??
        const <GlyphRow>[];
    return (image, glyphs);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return FutureBuilder(
      future: _load,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final (image, glyphs) = snap.data!;
        return LayoutBuilder(
          builder: (context, box) {
            final layout = _PageLayout(box.biggest, opening: widget.page <= 2);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) {
                final point = layout.toImage(d.localPosition);
                for (final g in glyphs) {
                  if (_rect(g).inflate(6).contains(point)) {
                    widget.onVerseTap((
                      surah: g.suraNumber,
                      ayah: g.ayahNumber,
                    ));
                    return;
                  }
                }
                widget.onBackgroundTap();
              },
              child: Semantics(
                label: AppLocalizations.of(context).pageOf('${widget.page}'),
                image: true,
                child: CustomPaint(
                  size: box.biggest,
                  painter: _OldPagePainter(
                    image: image,
                    layout: layout,
                    ink: tokens.mode == ThemeModeId.light
                        ? null
                        : tokens.colors.ink,
                    highlight: tokens.colors.highlight,
                    selected: [
                      if (widget.selected != null)
                        for (final g in glyphs)
                          if (g.suraNumber == widget.selected!.surah &&
                              g.ayahNumber == widget.selected!.ayah)
                            layout.toScreenRect(_rect(g)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Rect _rect(GlyphRow g) => Rect.fromLTRB(
    g.minX.toDouble(),
    g.minY.toDouble(),
    g.maxX.toDouble(),
    g.maxY.toDouble(),
  );
}

class _OldPagePainter extends CustomPainter {
  _OldPagePainter({
    required this.image,
    required this.layout,
    required this.ink,
    required this.highlight,
    required this.selected,
  });

  final ui.Image image;
  final _PageLayout layout;
  final Color? ink;
  final Color highlight;
  final List<Rect> selected;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = highlight;
    for (final r in selected) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.inflate(1), const Radius.circular(4)),
        fill,
      );
    }
    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (ink != null) {
      paint.colorFilter = ColorFilter.mode(ink!, BlendMode.srcIn);
    }
    layout.paint(canvas, image, paint);
  }

  @override
  bool shouldRepaint(_OldPagePainter old) =>
      old.image != image ||
      old.layout.size != layout.size ||
      old.ink != ink ||
      old.highlight != highlight ||
      old.selected.length != selected.length ||
      (selected.isNotEmpty && old.selected.first != selected.first);
}
