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
import 'page_interaction.dart';

/// Ink area shared by all quran.com page images (1024 x 1656), and the
/// 15 line slots inside it.
/// The ink of every page from 3 to 604 lies inside this rectangle
/// (tools/measure_line_extents.py); cropping to it never cuts a mark.
const _ink = Rect.fromLTRB(19, 6, 1011, 1632);

/// Line grid of the page images: 15 lines from y = 8, 1594 px tall.
const _gridTop = 8.0;

/// Pages 1 and 2 only use the upper half of their images.
const _openingInk = Rect.fromLTRB(51, 6, 967, 814);

/// The same block without its printed surah header.
const _openingBody = Rect.fromLTRB(204, 204, 824, 816);
const _lineCount = 15;
const _pitch = 1594 / _lineCount;

/// Where the page image goes on screen. Normal pages fill the width, and
/// their 15 lines spread evenly over the full height, so the page fills
/// the screen without stretching the calligraphy. Pages 1 and 2 (drawn
/// inside a round ornament) and screens wider than the page are scaled
/// as a whole instead.
class _PageLayout {
  _PageLayout(
    this.size, {
    required bool opening,
    this.cuts = const [],
    this.overflow = const {},
    bool withoutHeader = false,
  }) : ink = opening ? (withoutHeader ? _openingBody : _openingInk) : _ink {
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

  /// The 14 cuts between lines (image px), at the rows with least ink, so
  /// marks above and below a line stay with it.
  final List<double> cuts;

  /// Ink crossing a cut (image px), by the line it belongs to.
  final Map<int, List<Rect>> overflow;

  /// Image region drawn by line [j]: its band, less neighbours' ink that
  /// reaches in, plus its own ink that reaches out.
  Path _region(int j) {
    var p = Path()
      ..addRect(
        Rect.fromLTRB(ink.left, _bandTop(j), ink.right, _bandBottom(j)),
      );
    for (final e in overflow.entries) {
      for (final r in e.value) {
        p = Path.combine(
          e.key == j ? PathOperation.union : PathOperation.difference,
          p,
          Path()..addRect(r),
        );
      }
    }
    return p;
  }

  late final double scale;
  late final bool strips;
  late final Offset offset;

  bool get _hasCuts => cuts.length == _lineCount - 1;

  /// How far the ink of the first and last lines reaches beyond their
  /// centres, over all 604 pages (image px; tools/measure_line_extents.py).
  static const _inkAbove = 55.1;
  static const _inkBelow = 83.1;

  /// Room kept above the first line and below the last, so no line is cut.
  late final double _padTop = _pad(_inkAbove);
  late final double _padBottom = _pad(_inkBelow);
  double _pad(double ink) {
    final s0 = size.height / _lineCount;
    final need = ink * scale - s0 / 2 + 3;
    return need > 0 ? need : 0;
  }

  double get _slot => (size.height - _padTop - _padBottom) / _lineCount;

  /// Line centre on the image, and where it lands on screen.
  double _centre(int j) => _gridTop + (j + 0.5) * _pitch;
  double _slotCentre(int j) => _padTop + (j + 0.5) * _slot;

  double _bandTop(int j) =>
      j == 0 ? ink.top : (_hasCuts ? cuts[j - 1] : _gridTop + j * _pitch);
  double _bandBottom(int j) => j == _lineCount - 1
      ? ink.bottom
      : (_hasCuts ? cuts[j] : _gridTop + (j + 1) * _pitch);

  int _lineOfImageY(double y) {
    if (!_hasCuts) {
      return ((y - _gridTop) / _pitch).floor().clamp(0, _lineCount - 1);
    }
    var j = 0;
    while (j < _lineCount - 1 && y > cuts[j]) {
      j++;
    }
    return j;
  }

  Offset toScreen(Offset p, {int? line}) {
    if (!strips) return (p - ink.topLeft) * scale + offset;
    final j = line ?? _lineOfImageY(p.dy);
    return Offset(
      (p.dx - ink.left) * scale,
      _slotCentre(j) + (p.dy - _centre(j)) * scale,
    );
  }

  Offset toImage(Offset p) {
    if (!strips) return (p - offset) / scale + ink.topLeft;
    final j = ((p.dy - _padTop) / _slot).floor().clamp(0, _lineCount - 1);
    return Offset(
      p.dx / scale + ink.left,
      _centre(j) + (p.dy - _slotCentre(j)) / scale,
    );
  }

  Rect toScreenRect(Rect r) {
    final line = _lineOfImageY(r.center.dy);
    return Rect.fromPoints(
      toScreen(r.topLeft, line: line),
      toScreen(r.bottomRight, line: line),
    );
  }

  /// [emphasis] lines (the basmala) are drawn a little larger and bolder.
  void paint(
    Canvas canvas,
    ui.Image image,
    Paint paint, {
    Set<int> emphasis = const {},
  }) {
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
      canvas.save();
      if (emphasis.contains(j)) {
        final c = Offset(size.width / 2, _slotCentre(j));
        canvas.translate(c.dx, c.dy);
        canvas.scale(1.12);
        canvas.translate(-c.dx, -c.dy);
      }
      // Image pixels to screen, for this line.
      canvas.translate(-ink.left * scale, _slotCentre(j) - _centre(j) * scale);
      canvas.scale(scale);
      canvas.clipPath(_region(j));
      if (emphasis.contains(j)) {
        for (final dx in const [-1.8, 1.8]) {
          canvas.drawImage(image, Offset(dx, 0), paint);
        }
      }
      canvas.drawImage(image, Offset.zero, paint);
      canvas.restore();
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
    required this.interaction,
  });

  final int page;
  final PageInteraction interaction;

  @override
  ConsumerState<OldMushafPage> createState() => _OldMushafPageState();
}

class _OldMushafPageState extends ConsumerState<OldMushafPage> {
  late Future<(ui.Image, List<GlyphRow>)> _load;
  ui.Image? _image;
  List<double> _cuts = const [];
  Map<int, List<Rect>> _overflow = {};

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
    final repo = ref.read(mushafRepositoryProvider);
    _cuts = await repo.lineCuts('madina1405', widget.page);
    _overflow = {};
    for (final o in await repo.oldLineOverflow(widget.page)) {
      _overflow
          .putIfAbsent(o.line, () => [])
          .add(
            Rect.fromLTRB(
              o.x0.toDouble(),
              o.y0.toDouble(),
              o.x1.toDouble(),
              o.y1.toDouble(),
            ),
          );
    }
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
        final x = widget.interaction;
        final l = AppLocalizations.of(context);
        // The verse-end marker is the last glyph of each verse on the page.
        final markers = <VerseKey, GlyphRow>{};
        for (final g in glyphs) {
          final k = (surah: g.suraNumber, ayah: g.ayahNumber);
          final m = markers[k];
          if (m == null || g.position > m.position) markers[k] = g;
        }
        return LayoutBuilder(
          builder: (context, box) {
            final layout = _PageLayout(
              box.biggest,
              opening: widget.page <= 2,
              cuts: _cuts,
              overflow: _overflow,
              withoutHeader: widget.interaction.ornateOpening,
            );
            VerseKey? verseAt(Offset local) {
              final point = layout.toImage(local);
              for (final g in glyphs) {
                if (_rect(g).inflate(6).contains(point)) {
                  return (surah: g.suraNumber, ayah: g.ayahNumber);
                }
              }
              return null;
            }

            VerseKey? markerAt(Offset local) {
              final point = layout.toImage(local);
              for (final e in markers.entries) {
                if (_rect(e.value).inflate(8).contains(point)) return e.key;
              }
              return null;
            }

            final selectedGlyphs = [
              for (final g in glyphs)
                if (x.selection.contains((
                  surah: g.suraNumber,
                  ayah: g.ayahNumber,
                )))
                  g,
            ]..sort((a, b) => a.glyphId.compareTo(b.glyphId));
            final handles = <Widget>[];
            if (selectedGlyphs.isNotEmpty && widget.interaction.showHandles) {
              final first = layout.toScreenRect(_rect(selectedGlyphs.first));
              final last = layout.toScreenRect(_rect(selectedGlyphs.last));
              void drag(bool start, Offset global) {
                final ro = context.findRenderObject();
                if (ro is! RenderBox) return;
                final v = verseAt(ro.globalToLocal(global));
                if (v != null) x.onHandleDrag(start, v);
              }

              handles
                ..add(
                  Positioned(
                    left: first.right - 22,
                    top: first.top - 34,
                    child: SelectionHandle(
                      start: true,
                      label: l.selectionStart,
                      onDrag: (g) => drag(true, g),
                    ),
                  ),
                )
                ..add(
                  Positioned(
                    left: last.left - 22,
                    top: last.bottom - 10,
                    child: SelectionHandle(
                      start: false,
                      label: l.selectionEnd,
                      onDrag: (g) => drag(false, g),
                    ),
                  ),
                );
            }
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      if (x.hidden != null) {
                        final v = verseAt(d.localPosition);
                        if (v != null && x.hidden!.contains(v)) {
                          x.onHiddenTap?.call(v);
                          return;
                        }
                      }
                      final m = markerAt(d.localPosition);
                      m != null ? x.onMarkerTap(m) : x.onTap();
                    },
                    onLongPressStart: (d) {
                      final v = verseAt(d.localPosition);
                      if (v != null) x.onVerseLongPress(v);
                    },
                    child: Semantics(
                      label: l.pageOf('${widget.page}'),
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
                            for (final g in selectedGlyphs)
                              layout.toScreenRect(_rect(g)),
                          ],
                          look: x.markerLook,
                          markers: [
                            for (final e in markers.entries)
                              (
                                layout.toScreenRect(_rect(e.value)),
                                e.key.ayah,
                                x.marks[e.key],
                              ),
                          ],
                          hidden: x.hidden == null
                              ? const []
                              : [
                                  for (final g in glyphs)
                                    if (x.hidden!.contains((
                                      surah: g.suraNumber,
                                      ayah: g.ayahNumber,
                                    )))
                                      layout.toScreenRect(_rect(g)),
                                ],
                          paper: tokens.colors.paper,
                          line: tokens.colors.border,
                          divineNames: x.divineNames,
                          divineColor: x.divineColor,
                          emphasis: x.emphasisLines,
                          rings: [
                            for (final e in markers.entries)
                              if (x.marks.containsKey(e.key))
                                (
                                  layout.toScreenRect(_rect(e.value)),
                                  x.marks[e.key]!,
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                ...handles,
              ],
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
    required this.rings,
    required this.look,
    required this.markers,
    required this.hidden,
    required this.paper,
    required this.line,
    this.divineNames = const [],
    this.divineColor,
    this.emphasis = const {},
  });

  /// Divine-name glyph boxes (image px) and their colour.
  final List<Rect> divineNames;
  final Color? divineColor;
  final Set<int> emphasis;

  final MarkerLook? look;

  /// Verse-end marker boxes on screen, with their verse numbers.
  final List<(Rect, int, Color?)> markers;

  /// Recitation mode: glyph boxes to cover.
  final List<Rect> hidden;
  final Color paper;
  final Color line;

  final ui.Image image;
  final _PageLayout layout;
  final Color? ink;
  final Color highlight;
  final List<Rect> selected;

  /// Marked verse-end markers and their mark colour.
  final List<(Rect, Color)> rings;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = highlight;
    for (final r in selected) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.inflate(1), const Radius.circular(4)),
        fill,
      );
    }
    for (final (r, color) in rings) {
      final radius = r.shortestSide / 2 + 2;
      canvas.drawCircle(
        r.center,
        radius,
        Paint()..color = color.withValues(alpha: 0.35),
      );
      canvas.drawCircle(
        r.center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color,
      );
    }
    for (final (r, _, _) in markers) {
      look?.paintUnder(canvas, r.center, r.shortestSide / 2);
    }
    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (ink != null) {
      paint.colorFilter = ColorFilter.mode(ink!, BlendMode.srcIn);
    }
    layout.paint(canvas, image, paint, emphasis: emphasis);
    final divine = divineColor;
    if (divine != null) {
      final tintPaint = Paint()
        ..filterQuality = FilterQuality.medium
        ..colorFilter = ColorFilter.mode(divine, BlendMode.srcIn);
      for (final r in divineNames) {
        canvas.drawImageRect(image, r, layout.toScreenRect(r), tintPaint);
      }
    }
    for (final (r, n, marked) in markers) {
      look?.paintOver(canvas, r.center, r.shortestSide / 2, n, marked: marked);
    }
    if (hidden.isNotEmpty) {
      final cover = Paint()..color = paper;
      final stroke = Paint()
        ..color = line
        ..strokeWidth = 1.2;
      for (final r in hidden) {
        canvas.drawRect(r.inflate(2), cover);
      }
      for (final r in hidden) {
        canvas.drawLine(
          Offset(r.left, r.center.dy),
          Offset(r.right, r.center.dy),
          stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_OldPagePainter old) =>
      old.image != image ||
      old.layout.size != layout.size ||
      old.ink != ink ||
      old.highlight != highlight ||
      old.selected.length != selected.length ||
      old.rings.length != rings.length ||
      old.hidden.length != hidden.length ||
      old.look != look ||
      (selected.isNotEmpty && old.selected.first != selected.first);
}
