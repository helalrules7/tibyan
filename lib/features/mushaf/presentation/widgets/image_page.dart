import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import 'mushaf_page.dart';
import 'page_interaction.dart';

/// The lines of one page image, in image pixels. Shared by the editions
/// drawn from page images (Madina 1405H and Shamarly).
class PageGeometry {
  const PageGeometry({
    required this.ink,
    required this.centres,
    required this.slots,
    required this.bandTops,
    required this.bandBottoms,
    required this.boxHalfHeight,
    this.overflow = const {},
    this.inkAbove = 0,
    this.inkBelow = 0,
    this.whole = false,
    this.inkWithoutHeader,
  });

  /// The part of the image drawn; cropping to it never cuts a mark.
  final Rect ink;

  /// Same, when the ornate frame names the surah and the printed header is
  /// left out (opening pages).
  final Rect? inkWithoutHeader;

  /// Image y of each line's centre, and the line slot (0-based, may be
  /// fractional: a two-slot surah header sits between its slots) where
  /// that centre lands on screen.
  final List<double> centres;
  final List<double> slots;

  /// Image rows drawn by each line (between the cuts to its neighbours).
  final List<double> bandTops;
  final List<double> bandBottoms;

  /// Ink crossing a cut, by the line it belongs to.
  final Map<int, List<Rect>> overflow;

  /// How far the ink of the first and last lines reaches beyond their
  /// centres, over all pages of the edition.
  final double inkAbove;
  final double inkBelow;

  /// Half the height of a highlight box around a line's centre.
  final double boxHalfHeight;

  /// Scale the page as a whole instead of spreading its lines.
  final bool whole;

  int get lines => centres.length;
}

/// Room a page spread in strips keeps above its first line and below its
/// last, so no ink is cut: the lines' own reach ([inkAbove], [inkBelow],
/// image px) beyond half a slot. Zero when the page is scaled as a whole.
EdgeInsets stripPadding(
  Size size, {
  required Rect ink,
  required int lines,
  required double inkAbove,
  required double inkBelow,
}) {
  final byWidth = size.width / ink.width;
  if (byWidth >= size.height / ink.height) return EdgeInsets.zero;
  double pad(double reach) {
    final need = reach * byWidth - size.height / lines / 2 + 3;
    return need > 0 ? need : 0;
  }

  return EdgeInsets.only(top: pad(inkAbove), bottom: pad(inkBelow));
}

/// Where a page image goes on screen. Normal pages fill the width, and
/// their lines spread evenly over the full height, so the page fills the
/// screen without stretching the calligraphy. Opening pages and screens
/// wider than the page are scaled as a whole instead.
class StripLayout {
  StripLayout(this.size, this.g, {bool withoutHeader = false})
    : ink = withoutHeader ? (g.inkWithoutHeader ?? g.ink) : g.ink {
    final byWidth = size.width / ink.width;
    final byHeight = size.height / ink.height;
    scale = byWidth < byHeight ? byWidth : byHeight;
    strips = !g.whole && byWidth < byHeight;
    offset = Offset(
      (size.width - ink.width * scale) / 2,
      (size.height - ink.height * scale) / 2,
    );
  }

  final Size size;
  final PageGeometry g;
  final Rect ink;
  late final double scale;
  late final bool strips;
  late final Offset offset;

  int get _lines => g.lines;

  /// Image region drawn by line [j]: its band, less neighbours' ink that
  /// reaches in, plus its own ink that reaches out.
  Path _region(int j) {
    var p = Path()
      ..addRect(
        Rect.fromLTRB(ink.left, g.bandTops[j], ink.right, g.bandBottoms[j]),
      );
    for (final e in g.overflow.entries) {
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

  /// Room kept above the first line and below the last, so no line is cut.
  late final EdgeInsets _pads = stripPadding(
    size,
    ink: ink,
    lines: _lines,
    inkAbove: g.inkAbove,
    inkBelow: g.inkBelow,
  );
  double get _padTop => _pads.top;
  double get _padBottom => _pads.bottom;

  double get _slot => (size.height - _padTop - _padBottom) / _lines;

  double _slotCentre(double pos) => _padTop + (pos + 0.5) * _slot;

  /// Line centre on the image.
  double centre(int j) => g.centres[j];

  (double, double) band(int j) => (g.bandTops[j], g.bandBottoms[j]);

  int lineOfImageY(double y) {
    var j = 0;
    while (j < _lines - 1 && y > g.bandBottoms[j]) {
      j++;
    }
    return j;
  }

  Offset toScreen(Offset p, {int? line}) {
    if (!strips) return (p - ink.topLeft) * scale + offset;
    final j = line ?? lineOfImageY(p.dy);
    return Offset(
      (p.dx - ink.left) * scale,
      _slotCentre(g.slots[j]) + (p.dy - g.centres[j]) * scale,
    );
  }

  Offset toImage(Offset p) {
    if (!strips) return (p - offset) / scale + ink.topLeft;
    final j = ((p.dy - _padTop) / _slot).floor().clamp(0, _lines - 1);
    return Offset(
      p.dx / scale + ink.left,
      g.centres[j] + (p.dy - _slotCentre(g.slots[j])) / scale,
    );
  }

  Rect toScreenRect(Rect r) {
    final line = lineOfImageY(r.center.dy);
    return Rect.fromPoints(
      toScreen(r.topLeft, line: line),
      toScreen(r.bottomRight, line: line),
    );
  }

  /// One framed box per line around [pieces] (image px), on screen.
  List<Rect> frames(Iterable<Rect> pieces) => [
    for (final b in lineBoxes(
      pieces,
      lineOf: (r) => lineOfImageY(r.center.dy),
      centre: centre,
      halfHeight: g.boxHalfHeight,
      band: band,
    ))
      toScreenRect(b),
  ];

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
    for (var j = 0; j < _lines; j++) {
      final at = _slotCentre(g.slots[j]);
      canvas.save();
      if (emphasis.contains(j)) {
        final c = Offset(size.width / 2, at);
        canvas.translate(c.dx, c.dy);
        canvas.scale(1.12);
        canvas.translate(-c.dx, -c.dy);
      }
      // Image pixels to screen, for this line.
      canvas.translate(-ink.left * scale, at - g.centres[j] * scale);
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

/// What an edition supplies to draw one page image.
class ImagePageData {
  const ImagePageData({
    required this.image,
    required this.geometry,
    required this.pieces,
    required this.markers,
    this.hitSlop = 0,
    this.rowReach = 0,
    this.pieceLines = const [],
    this.alphaInk = true,
  });

  final ui.Image image;
  final PageGeometry geometry;

  /// Boxes of the verses on the page (image px), in reading order.
  final List<(VerseKey, Rect)> pieces;

  /// Verse-end marker boxes (image px).
  final Map<VerseKey, Rect> markers;

  /// How far around a piece a touch still selects its verse.
  final double hitSlop;

  /// The printed line of each piece, in the order of [pieces]; empty
  /// when unknown (lines are then found from the boxes' positions).
  final List<int> pieceLines;

  /// Recitation mode: how far a cover reaches above the first row of text
  /// and below the last, as a share of the row's height. Boxes that are
  /// single glyphs need it for the marks around them; boxes as tall as
  /// the line do not (and reaching up would cover the basmala).
  final double rowReach;

  /// The ink is the image's alpha (transparent paper). False for opaque
  /// scans, whose ink is taken from their darkness instead.
  final bool alphaInk;
}

/// A colour filter that draws the page's ink in [color].
ColorFilter inkFilter(Color color, {required bool alphaInk}) => alphaInk
    ? ColorFilter.mode(color, BlendMode.srcIn)
    // Opaque scan: dark = ink, light = paper (transparent). The ramp is
    // steepened so the scan's tinted paper drops out completely.
    : ColorFilter.matrix([
        0, 0, 0, 0, color.r * 255, //
        0, 0, 0, 0, color.g * 255,
        0, 0, 0, 0, color.b * 255,
        -0.299 * 1.5, -0.587 * 1.5, -0.114 * 1.5, 0, 255 * 1.5 - 25,
      ]);

/// One page drawn from a page image (unchanged), coloured for the current
/// mode, with the verses highlighted from their boxes.
class ImageMushafPage extends ConsumerStatefulWidget {
  const ImageMushafPage({
    super.key,
    required this.page,
    required this.interaction,
    required this.load,
  });

  final int page;
  final PageInteraction interaction;
  final Future<ImagePageData> Function(WidgetRef ref, int page) load;

  @override
  ConsumerState<ImageMushafPage> createState() => _ImageMushafPageState();
}

class _ImageMushafPageState extends ConsumerState<ImageMushafPage> {
  late Future<ImagePageData> _load;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  @override
  void didUpdateWidget(ImageMushafPage old) {
    super.didUpdateWidget(old);
    if (old.page != widget.page) _load = _fetch();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<ImagePageData> _fetch() async {
    final data = await widget.load(ref, widget.page);
    _image?.dispose();
    _image = data.image;
    return data;
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
        final data = snap.data!;
        final x = widget.interaction;
        final l = AppLocalizations.of(context);
        final markers = data.markers;
        return LayoutBuilder(
          builder: (context, box) {
            final layout = StripLayout(
              box.biggest,
              data.geometry,
              withoutHeader: x.ornateOpening,
            );
            VerseKey? verseAt(Offset local) {
              final point = layout.toImage(local);
              for (final (k, r) in data.pieces) {
                if (r.inflate(data.hitSlop).contains(point)) return k;
              }
              return null;
            }

            VerseKey? markerAt(Offset local) {
              final point = layout.toImage(local);
              for (final e in markers.entries) {
                if (e.value.inflate(8).contains(point)) return e.key;
              }
              return null;
            }

            // Recitation mode: the page's rows of text, and its column.
            // By the printed line where it is known: small glyphs (a dot, a
            // sign) would otherwise make rows of their own.
            final known = data.pieceLines.length == data.pieces.length;
            final byLine = <int, Rect>{};
            if (known) {
              for (final (i, (_, r)) in data.pieces.indexed) {
                final l = data.pieceLines[i];
                byLine[l] = byLine[l]?.expandToInclude(r) ?? r;
              }
            }
            final rows =
                (known
                      ? byLine.values.toList()
                      : wordRows([for (final (_, r) in data.pieces) r]))
                  ..sort((a, b) => a.top.compareTo(b.top));
            // Across the whole drawn image: marks can reach past the boxes.
            final column = layout.ink;
            int rowOf(Rect r) {
              var best = 0;
              for (var i = 1; i < rows.length; i++) {
                if ((rows[i].center.dy - r.center.dy).abs() <
                    (rows[best].center.dy - r.center.dy).abs()) {
                  best = i;
                }
              }
              return best;
            }

            (double, double) rowSpan(int i) {
              final r = rows[i];
              final pad = r.height * data.rowReach;
              var top = i == 0 ? r.top - pad : (rows[i - 1].bottom + r.top) / 2;
              var bottom = i == rows.length - 1
                  ? r.bottom + pad
                  : (r.bottom + rows[i + 1].top) / 2;
              if (!data.geometry.whole) {
                // Lines drawn one by one, each spread to its own slot: the
                // line's band is exactly what it draws (its overflow is
                // covered on its own), and the neighbours are elsewhere.
                return layout.band(layout.lineOfImageY(r.center.dy));
              }
              return (top, bottom);
            }

            Iterable<Rect> piecesOf(bool Function(VerseKey) test) => [
              for (final (k, r) in data.pieces)
                if (test(k)) r,
            ];

            /// Recitation mode: each row of the verse, across from the
            /// verse marker on one side to the next on the other (or the
            /// text's edge), and from halfway to the row above to halfway
            /// to the row below, so no mark of it is left. The markers are
            /// drawn again on top. Rows come from the boxes themselves, not
            /// the line grid, which the opening pages do not follow.
            Iterable<Rect> coverOf(VerseKey v) {
              final own = markers[v];
              final mine = [
                for (final (k, r) in data.pieces)
                  if (k == v && r != own) r,
              ];
              if (mine.isEmpty) {
                final words = x.hiddenWords[v];
                return words == null ? const [] : layout.frames(words);
              }
              final others = [
                for (final e in markers.entries)
                  if (e.key != v) e.value,
              ];
              // The verse's boxes, one per row of the page.
              final spans = <int, Rect>{};
              for (final (j, (k, r)) in data.pieces.indexed) {
                if (k != v || r == own) continue;
                final i = known
                    ? rows.indexOf(byLine[data.pieceLines[j]]!)
                    : rowOf(r);
                spans[i] = spans[i]?.expandToInclude(r) ?? r;
              }
              return [
                for (final MapEntry(key: i, value: span) in spans.entries)
                  () {
                    final (top, bottom) = rowSpan(i);
                    bool inRow(Rect m) => rowOf(m) == i;
                    // Past the verse's own marker only when another verse
                    // follows it on the row; else on to the text's edge,
                    // where the ink of the rows around may hang.
                    bool followed(Rect m) => data.pieces.any(
                      (p) =>
                          p.$1 != v &&
                          inRow(p.$2) &&
                          p.$2.center.dx < m.center.dx,
                    );
                    final left = own != null && inRow(own)
                        ? (followed(own) ? own.center.dx : column.left)
                        : others
                              .where((m) => inRow(m) && m.center.dx < span.left)
                              .fold(
                                column.left,
                                (a, m) => math.max(a, m.center.dx),
                              );
                    final right = others
                        .where((m) => inRow(m) && m.center.dx > span.right)
                        .fold(column.right, (a, m) => math.min(a, m.center.dx));
                    final line = layout.lineOfImageY(rows[i].center.dy);
                    Rect screen(Rect r) => Rect.fromPoints(
                      layout.toScreen(r.topLeft, line: line),
                      layout.toScreen(r.bottomRight, line: line),
                    );
                    final box = Rect.fromLTRB(left, top, right, bottom);
                    return [
                      screen(box),
                      // Ink of this line that crosses into a neighbour's
                      // band is drawn with this line: cover it the same way.
                      if (!data.geometry.whole)
                        for (final o
                            in data.geometry.overflow[line] ?? const <Rect>[])
                          if (o.right > left && o.left < right)
                            screen(
                              Rect.fromLTRB(
                                math.max(o.left, left),
                                o.top,
                                math.min(o.right, right),
                                o.bottom,
                              ),
                            ),
                    ];
                  }(),
              ].expand((e) => e);
            }

            final selected = piecesOf(x.selection.contains).toList();
            final handles = <Widget>[];
            if (selected.isNotEmpty && x.showHandles) {
              final first = layout.toScreenRect(selected.first);
              final last = layout.toScreenRect(selected.last);
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
                      if (x.onPick != null) {
                        return x.onPick!(
                          layout.toImage(d.localPosition),
                          verseAt(d.localPosition),
                        );
                      }
                      if (x.hidden != null) {
                        final v = verseAt(d.localPosition);
                        if (v != null) {
                          x.onHiddenTap?.call(v);
                          return;
                        }
                      }
                      final m = markerAt(d.localPosition);
                      if (m != null) return x.onMarkerTap(m);
                      final v = x.onVerseTap == null
                          ? null
                          : verseAt(d.localPosition);
                      v != null ? x.onVerseTap!(v) : x.onTap();
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
                        painter: _ImagePagePainter(
                          image: data.image,
                          alphaInk: data.alphaInk,
                          layout: layout,
                          // Opaque scans are always recoloured, so their
                          // tinted paper never shows on ours.
                          ink: tokens.mode.isLight && data.alphaInk
                              ? null
                              : tokens.colors.ink,
                          highlight: tokens.colors.highlight,
                          touchColor: x.touchColor,
                          touched: x.touched == null
                              ? const []
                              : layout.frames(piecesOf((k) => k == x.touched)),
                          word: x.activeWord == null
                              ? null
                              : layout.frames([x.activeWord!]).first.widen(2),
                          selected: layout.frames(selected),
                          look: x.markerLook,
                          markers: [
                            for (final e in markers.entries)
                              (
                                layout.toScreenRect(e.value),
                                e.key.ayah,
                                x.marks[e.key],
                              ),
                          ],
                          hidden: x.hidden == null
                              ? const []
                              : [for (final v in x.hidden!) ...coverOf(v)],
                          markerPixels: x.hidden == null
                              ? const []
                              : [
                                  for (final e in markers.entries)
                                    (e.value, layout.toScreenRect(e.value)),
                                ],
                          paper: tokens.colors.paper,
                          line: tokens.colors.border,
                          divineNames: x.divineNames,
                          divineColor: x.divineColor,
                          emphasis: x.emphasisLines,
                          rings: [
                            for (final e in markers.entries)
                              if (x.marks.containsKey(e.key))
                                (layout.toScreenRect(e.value), x.marks[e.key]!),
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
}

class _ImagePagePainter extends CustomPainter {
  _ImagePagePainter({
    required this.image,
    required this.alphaInk,
    required this.layout,
    required this.ink,
    required this.highlight,
    required this.word,
    required this.touched,
    required this.touchColor,
    required this.selected,
    required this.rings,
    required this.look,
    required this.markers,
    required this.hidden,
    this.markerPixels = const [],
    required this.paper,
    required this.line,
    this.divineNames = const [],
    this.divineColor,
    this.emphasis = const {},
  });

  /// Divine-name boxes (image px) and their colour.
  final List<Rect> divineNames;
  final Color? divineColor;
  final Set<int> emphasis;

  final MarkerLook? look;

  /// Verse-end marker boxes on screen, with their verse numbers.
  final List<(Rect, int, Color?)> markers;

  /// Recitation mode: boxes to cover (screen px).
  final List<Rect> hidden;

  /// Recitation mode: each marker's image box and screen box, drawn again
  /// over the covers so verse numbers stay visible.
  final List<(Rect, Rect)> markerPixels;
  final Color paper;
  final Color line;

  final ui.Image image;
  final bool alphaInk;
  final StripLayout layout;
  final Color? ink;
  final Color highlight;
  final List<Rect> selected;

  /// The word being recited (screen pixels).
  final Rect? word;

  /// Touch reading: the shaded verse's line boxes (screen pixels).
  final List<Rect> touched;
  final Color? touchColor;

  /// Marked verse-end markers and their mark colour.
  final List<(Rect, Color)> rings;

  @override
  void paint(Canvas canvas, Size size) {
    paintVerseBoxes(canvas, selected, highlight, stroke: 1.2, radius: 5);
    if (touchColor != null) {
      paintVerseBoxes(canvas, touched, touchColor!, stroke: 1.2, radius: 5);
    }
    if (word != null) {
      paintVerseBoxes(
        canvas,
        [word!],
        highlight.withValues(alpha: highlight.a * 2.4),
        stroke: 1.5,
        radius: 5,
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
      paint.colorFilter = inkFilter(ink!, alphaInk: alphaInk);
    }
    layout.paint(canvas, image, paint, emphasis: emphasis);
    final divine = divineColor;
    if (divine != null) {
      final tintPaint = Paint()
        ..filterQuality = FilterQuality.medium
        ..colorFilter = inkFilter(divine, alphaInk: alphaInk);
      for (final r in divineNames) {
        canvas.drawImageRect(image, r, layout.toScreenRect(r), tintPaint);
      }
    }
    for (final (r, n, marked) in markers) {
      look?.paintOver(canvas, r.center, r.shortestSide / 2, n, marked: marked);
    }
    if (hidden.isNotEmpty) {
      final cover = Paint()..color = paper;
      for (final r in hidden) {
        canvas.drawRect(r.inflate(2), cover);
      }
      for (final (src, dst) in markerPixels) {
        // Just the round marker: its square box would bring back the
        // neighbours' ink in its corners.
        canvas
          ..save()
          ..clipPath(Path()..addOval(dst.inflate(layout.scale)))
          ..drawImageRect(
            image,
            src.inflate(1),
            dst.inflate(layout.scale),
            paint,
          )
          ..restore();
      }
      for (final (r, n, marked) in markers) {
        look?.paintOver(
          canvas,
          r.center,
          r.shortestSide / 2,
          n,
          marked: marked,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ImagePagePainter old) =>
      old.image != image ||
      old.layout.size != layout.size ||
      old.ink != ink ||
      old.highlight != highlight ||
      old.word != word ||
      old.touched != touched ||
      old.selected.length != selected.length ||
      old.rings.length != rings.length ||
      old.hidden.length != hidden.length ||
      old.look != look ||
      (selected.isNotEmpty && old.selected.first != selected.first);
}
