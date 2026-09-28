import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../../core/db/ayahinfo_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../mushaf_providers.dart';
import 'mushaf_page.dart';

/// Size of the quran.com page images the glyph boxes are measured in.
const _imageSize = Size(1024, 1656);

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
  late Future<List<GlyphRow>> _glyphs;

  @override
  void initState() {
    super.initState();
    _glyphs = _fetch();
  }

  @override
  void didUpdateWidget(OldMushafPage old) {
    super.didUpdateWidget(old);
    if (old.page != widget.page) _glyphs = _fetch();
  }

  Future<List<GlyphRow>> _fetch() async =>
      await ref.read(ayahInfoDatabaseProvider)?.page(widget.page) ?? const [];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final dir = ref.watch(pageInstallerProvider).dir;
    final image = File(
      p.join(dir.path, 'p${widget.page.toString().padLeft(3, '0')}.png'),
    );
    return FutureBuilder(
      future: _glyphs,
      builder: (context, snap) {
        final glyphs = snap.data ?? const <GlyphRow>[];
        return Center(
          child: AspectRatio(
            aspectRatio: _imageSize.width / _imageSize.height,
            child: LayoutBuilder(
              builder: (context, box) {
                final scale = box.maxWidth / _imageSize.width;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) {
                    final point = d.localPosition / scale;
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Semantics(
                        label: AppLocalizations.of(context)
                            .pageOf('${widget.page}'),
                        image: true,
                        child: Image.file(
                          image,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          color: tokens.mode == ThemeModeId.light
                              ? null
                              : tokens.colors.ink,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                      if (widget.selected != null)
                        IgnorePointer(
                          child: CustomPaint(
                            painter: _GlyphHighlightPainter(
                              rects: [
                                for (final g in glyphs)
                                  if (g.suraNumber == widget.selected!.surah &&
                                      g.ayahNumber == widget.selected!.ayah)
                                    _rect(g),
                              ],
                              scale: scale,
                              color: tokens.colors.highlight,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
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

class _GlyphHighlightPainter extends CustomPainter {
  _GlyphHighlightPainter({
    required this.rects,
    required this.scale,
    required this.color,
  });

  final List<Rect> rects;
  final double scale;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.save();
    canvas.scale(scale);
    for (final r in rects) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.inflate(2), const Radius.circular(6)),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlyphHighlightPainter old) =>
      old.rects != rects || old.color != color || old.scale != scale;
}
