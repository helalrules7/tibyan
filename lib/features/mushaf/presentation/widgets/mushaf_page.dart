import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/db/content_database.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../mushaf_providers.dart';
import 'page_interaction.dart';

typedef _PageData = (
  PictureInfo,
  Rect,
  List<AyahPolygonRow>,
  List<double>,
  Map<int, List<Path>>,
  PictureInfo?,
);

/// Identifies a verse.
typedef VerseKey = ({int surah, int ayah});

/// Line grid of the new edition's pages (user units): 15 lines, first
/// line centred at [_firstLine], [_pitch] apart. Measured on the pages.
const _lineCount = 15;
const _firstLine = 26.2;
const _pitch = 35.75;

/// Pages 1 and 2 draw a small centred block; this is its ink area.
const _openingInk = Rect.fromLTRB(5, -68, 232, 236);

/// The same block without its printed surah header.
const _openingBody = Rect.fromLTRB(10, 15, 228, 217);

/// Where the page is drawn on screen. Normal pages fill the width and their
/// 15 lines are spread evenly over the full height, without stretching the
/// calligraphy. Pages 1 and 2, and screens wider than the page, are scaled
/// as a whole instead.
class _PageLayout {
  _PageLayout(
    this.size,
    this.viewBox, {
    required bool opening,
    this.cuts = const [],
    this.overflow = const {},
    bool withoutHeader = false,
  }) : clip = opening && withoutHeader ? _openingBody : null {
    final area = clip ?? (opening ? _openingInk : viewBox);
    final byWidth = size.width / area.width;
    final byHeight = size.height / area.height;
    scale = byWidth < byHeight ? byWidth : byHeight;
    strips = !opening && byWidth < byHeight;
    offset = Offset(
      (size.width - area.width * scale) / 2 - area.left * scale,
      (size.height - area.height * scale) / 2 - area.top * scale,
    );
  }

  final Size size;

  /// Page-unit area to keep (pages 1 and 2 without their header).
  final Rect? clip;

  /// The SVG's viewBox in user units (pages 1 and 2 have a shifted origin).
  final Rect viewBox;

  /// The 14 cuts between lines (page units), chosen where no mark or the
  /// fewest marks cross.
  final List<double> cuts;

  /// Marks crossing a cut, by the line they belong to.
  final Map<int, List<Path>> overflow;
  late final double scale;
  late final bool strips;
  late final Offset offset;

  /// How far the ink of the first and last lines reaches beyond their
  /// centres, over all 604 pages (page units; tools/measure_line_extents.py).
  static const _inkAbove = 22.2;
  static const _inkBelow = 21.4;

  /// Room kept above the first line and below the last, so no line is cut.
  late final double _padTop = _pad(_inkAbove);
  late final double _padBottom = _pad(_inkBelow);
  double _pad(double ink) {
    final s0 = size.height / _lineCount;
    final need = ink * scale - s0 / 2 + 3;
    return need > 0 ? need : 0;
  }

  double get _slot => (size.height - _padTop - _padBottom) / _lineCount;
  double _centre(int j) => _firstLine + j * _pitch;
  bool get _hasCuts => cuts.length == _lineCount - 1;
  double _bandTop(int j) =>
      j == 0 ? viewBox.top : (_hasCuts ? cuts[j - 1] : _centre(j) - _pitch / 2);
  double _bandBottom(int j) => j == _lineCount - 1
      ? viewBox.bottom
      : (_hasCuts ? cuts[j] : _centre(j) + _pitch / 2);

  /// Page-unit region that belongs to line [j]: its band, minus marks of
  /// neighbouring lines that reach into it, plus its own marks that reach out.
  late final List<Path> _clips = [
    for (var j = 0; j < _lineCount; j++) _bandClip(j),
  ];

  Path _bandClip(int j) {
    var clip = Path()
      ..addRect(
        Rect.fromLTRB(viewBox.left, _bandTop(j), viewBox.right, _bandBottom(j)),
      );
    for (final e in overflow.entries) {
      for (final p in e.value) {
        clip = Path.combine(
          e.key == j ? PathOperation.union : PathOperation.difference,
          clip,
          p,
        );
      }
    }
    return clip;
  }

  double _slotCentre(int j) => _padTop + (j + 0.5) * _slot;

  int _lineOf(double y) {
    if (!_hasCuts) {
      return ((y - _firstLine + _pitch / 2) / _pitch).floor().clamp(
        0,
        _lineCount - 1,
      );
    }
    var j = 0;
    while (j < _lineCount - 1 && y > cuts[j]) {
      j++;
    }
    return j;
  }

  /// Page units to screen pixels.
  Offset toScreen(Offset p, {int? line}) {
    if (!strips) return p * scale + offset;
    final j = line ?? _lineOf(p.dy);
    return Offset(
      p.dx * scale + offset.dx,
      _slotCentre(j) + (p.dy - _centre(j)) * scale,
    );
  }

  /// Screen pixels to page units.
  Offset toPage(Offset local) {
    if (!strips) return (local - offset) / scale;
    final j = ((local.dy - _padTop) / _slot).floor().clamp(0, _lineCount - 1);
    return Offset(
      (local.dx - offset.dx) / scale,
      _centre(j) + (local.dy - _slotCentre(j)) / scale,
    );
  }

  /// Runs [draw] in page units once per line band, clipped to that band.
  /// [emphasis] lines (the basmala) are drawn a little larger and bolder.
  void paintBands(
    Canvas canvas,
    void Function(Canvas, bool emphasis) draw, {
    Set<int> emphasis = const {},
  }) {
    if (!strips) {
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.scale(scale);
      if (clip != null) canvas.clipRect(clip!);
      draw(canvas, false);
      canvas.restore();
      return;
    }
    for (var j = 0; j < _lineCount; j++) {
      final dy = _slotCentre(j) - _centre(j) * scale;
      canvas.save();
      canvas.translate(offset.dx, dy);
      canvas.scale(scale);
      final big = emphasis.contains(j);
      if (big) {
        // The basmala line, 12% larger around its centre; its own region is
        // scaled with it, so none of its marks is cut.
        final cx = viewBox.center.dx;
        final cy = _centre(j);
        canvas.translate(cx, cy);
        canvas.scale(1.12);
        canvas.translate(-cx, -cy);
      }
      canvas.clipPath(_clips[j]);
      draw(canvas, big);
      canvas.restore();
    }
  }
}

/// One page of the new Madina edition: the KFGQPC page artwork (unchanged),
/// coloured for the current mode, with the selection, marked verse
/// markers and selection handles drawn over it.
class MushafPage extends ConsumerStatefulWidget {
  const MushafPage({super.key, required this.page, required this.interaction});

  final int page;
  final PageInteraction interaction;

  @override
  ConsumerState<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends ConsumerState<MushafPage> {
  late Future<_PageData> _load;
  PictureInfo? _picture;
  PictureInfo? _markerPicture;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  /// A rosette replaces the printed marker, so the printed one is removed.
  bool get _hideMarkers {
    final style = widget.interaction.markerLook?.style;
    return style != null && style != MarkerStyle.traditional;
  }

  late bool _markersHidden = _hideMarkers;

  @override
  void didUpdateWidget(MushafPage old) {
    super.didUpdateWidget(old);
    if (old.page != widget.page || _markersHidden != _hideMarkers) {
      _markersHidden = _hideMarkers;
      _load = _fetch();
    }
  }

  @override
  void dispose() {
    _picture?.picture.dispose();
    _markerPicture?.picture.dispose();
    super.dispose();
  }

  Future<_PageData> _fetch() async {
    final svg = await ref.read(pageStoreProvider).svg(widget.page);
    final info = await vg.loadPicture(
      SvgStringLoader(_markersHidden ? withoutMarkers(svg) : svg),
      null,
    );
    // The printed markers alone, drawn again over the recitation covers.
    final markers = _markersHidden
        ? null
        : await vg.loadPicture(SvgStringLoader(markersOnly(svg)), null);
    // The old pictures are still on screen until the new ones are built:
    // they go after the next frame, not now.
    final old = [_picture, _markerPicture];
    _picture = info;
    _markerPicture = markers;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final p in old) {
        p?.picture.dispose();
      }
    });
    final repo = ref.read(mushafRepositoryProvider);
    final polys = await repo.polygons(widget.page);
    final cuts = await repo.lineCuts('madina1441', widget.page);
    final overflow = <int, List<Path>>{};
    for (final o in await repo.lineOverflow(widget.page)) {
      overflow.putIfAbsent(o.line, () => []).add(parseOutline(o.path));
    }
    return (info, _viewBox(svg), polys, cuts, overflow, markers);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final x = widget.interaction;
    final l = AppLocalizations.of(context);
    return FutureBuilder(
      future: _load,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final (picture, viewBox, polys, cuts, overflow, markerPicture) =
            snap.data!;
        final verses = [
          for (final p in polys)
            (
              key: (surah: p.surah, ayah: p.number),
              path: parseOutline(p.path),
              rects: outlineRects(p.path),
              marker: p.markerX == null ? null : Offset(p.markerX!, p.markerY!),
            ),
        ];
        VerseKey? verseAt(Offset point) {
          for (final v in verses) {
            if (v.path.contains(point)) return v.key;
          }
          return null;
        }

        VerseKey? markerAt(Offset point) {
          for (final v in verses) {
            final m = v.marker;
            if (m != null && (m - point).distance <= markerR + 3) {
              return v.key;
            }
          }
          return null;
        }

        return LayoutBuilder(
          builder: (context, box) {
            final layout = _PageLayout(
              box.biggest,
              viewBox,
              opening: widget.page <= 2,
              cuts: cuts,
              overflow: overflow,
              withoutHeader: x.ornateOpening,
            );
            final selected = [
              for (final v in verses)
                if (x.selection.contains(v.key)) v,
            ];
            // Pages 1 and 2 keep their own layout; their verses are drawn
            // as whole outlines there.
            final boxes = widget.page <= 2
                ? [
                    for (final v in selected)
                      for (final r in v.rects) r.inflate(1),
                  ]
                : lineBoxes(
                    [for (final v in selected) ...v.rects],
                    lineOf: (r) => layout._lineOf(r.center.dy),
                    centre: layout._centre,
                    halfHeight: _pitch * 0.42,
                    band: (j) => (layout._bandTop(j), layout._bandBottom(j)),
                  );
            final touchedBoxes = [
              for (final v in verses)
                if (v.key == x.touched)
                  ...widget.page <= 2
                      ? [for (final r in v.rects) r.inflate(1)]
                      : lineBoxes(
                          v.rects,
                          lineOf: (r) => layout._lineOf(r.center.dy),
                          centre: layout._centre,
                          halfHeight: _pitch * 0.42,
                          band: (j) =>
                              (layout._bandTop(j), layout._bandBottom(j)),
                        ),
            ];
            final active = x.activeWord;
            final wordBox = active == null || widget.page <= 2
                ? active?.inflate(0.6)
                : lineBoxes(
                    [active],
                    lineOf: (r) => layout._lineOf(r.center.dy),
                    centre: layout._centre,
                    halfHeight: _pitch * 0.42,
                    band: (j) => (layout._bandTop(j), layout._bandBottom(j)),
                  ).first.widen(0.6);
            final handles = <Widget>[];
            if (selected.isNotEmpty && x.showHandles) {
              // Right-to-left: the selection starts at the top right of its
              // first verse and ends at the bottom left of its last.
              final first = selected.first.rects.first;
              final last = selected.last.rects.last;
              final a = layout.toScreen(
                first.topRight,
                line: layout._lineOf(first.center.dy),
              );
              final b = layout.toScreen(
                last.bottomLeft,
                line: layout._lineOf(last.center.dy),
              );
              void drag(bool start, Offset global) {
                final ro = context.findRenderObject();
                if (ro is! RenderBox) return;
                final v = verseAt(layout.toPage(ro.globalToLocal(global)));
                if (v != null) x.onHandleDrag(start, v);
              }

              handles
                ..add(
                  Positioned(
                    left: a.dx - 22,
                    top: a.dy - 34,
                    child: SelectionHandle(
                      start: true,
                      label: l.selectionStart,
                      onDrag: (g) => drag(true, g),
                    ),
                  ),
                )
                ..add(
                  Positioned(
                    left: b.dx - 22,
                    top: b.dy - 10,
                    child: SelectionHandle(
                      start: false,
                      label: l.selectionEnd,
                      onDrag: (g) => drag(false, g),
                    ),
                  ),
                );
            }
            final look = x.markerLook;
            final ink = tokens.mode.isLight ? null : tokens.colors.ink;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      final point = layout.toPage(d.localPosition);
                      if (x.onPick != null) {
                        return x.onPick!(point, verseAt(point));
                      }
                      if (x.hidden != null) {
                        final v = verseAt(point);
                        if (v != null) {
                          x.onHiddenTap?.call(v);
                          return;
                        }
                      }
                      final m = markerAt(point);
                      if (m != null) return x.onMarkerTap(m);
                      final v = x.onVerseTap == null ? null : verseAt(point);
                      v != null ? x.onVerseTap!(v) : x.onTap();
                    },
                    onLongPressStart: (d) {
                      final v = verseAt(layout.toPage(d.localPosition));
                      if (v != null) x.onVerseLongPress(v);
                    },
                    child: Semantics(
                      label: l.pageOf('${widget.page}'),
                      image: true,
                      child: CustomPaint(
                        size: box.biggest,
                        painter: _CallbackPainter((canvas) {
                          layout.paintBands(canvas, emphasis: x.emphasisLines, (
                            c,
                            bold,
                          ) {
                            // Under the ink: marker tints and the selection.
                            if (look != null) {
                              for (final v in verses) {
                                if (v.marker != null) {
                                  look.paintUnder(c, v.marker!, markerR);
                                }
                              }
                            }
                            paintVerseBoxes(
                              c,
                              boxes,
                              tokens.colors.highlight,
                              stroke: 0.7,
                              radius: 3,
                            );
                            if (x.touchColor != null) {
                              paintVerseBoxes(
                                c,
                                touchedBoxes,
                                x.touchColor!,
                                stroke: 0.7,
                                radius: 3,
                              );
                            }
                            if (wordBox != null) {
                              paintVerseBoxes(
                                c,
                                [wordBox],
                                tokens.colors.highlight.withValues(
                                  alpha: tokens.colors.highlight.a * 2.4,
                                ),
                                stroke: 0.9,
                                radius: 3,
                              );
                            }
                            for (final v in verses) {
                              final colour = x.marks[v.key];
                              if (v.marker == null || colour == null) continue;
                              c.drawCircle(
                                v.marker!,
                                markerR,
                                Paint()..color = colour.withValues(alpha: 0.35),
                              );
                              c.drawCircle(
                                v.marker!,
                                markerR,
                                Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = markerR * 0.22
                                  ..color = colour,
                              );
                            }
                            // The page itself, recoloured outside light mode.
                            if (ink != null) {
                              c.saveLayer(
                                null,
                                Paint()
                                  ..colorFilter = ColorFilter.mode(
                                    ink,
                                    BlendMode.srcIn,
                                  ),
                              );
                            }
                            // The picture starts at the viewBox corner, not at
                            // the origin (pages 1 and 2 have a shifted one).
                            void page() {
                              c.save();
                              c.translate(viewBox.left, viewBox.top);
                              c.drawPicture(picture.picture);
                              c.restore();
                            }

                            if (bold) {
                              // Faux bold: the same line drawn three times,
                              // a hair apart.
                              for (final dx in const [-0.32, 0.32]) {
                                c.save();
                                c.translate(dx, 0);
                                page();
                                c.restore();
                              }
                            }
                            page();
                            if (ink != null) c.restore();
                            // The divine names, recoloured in place.
                            final divine = x.divineColor;
                            if (divine != null) {
                              for (final r in x.divineNames) {
                                c.save();
                                c.clipRect(r);
                                c.saveLayer(
                                  r,
                                  Paint()
                                    ..colorFilter = ColorFilter.mode(
                                      divine,
                                      BlendMode.srcIn,
                                    ),
                                );
                                page();
                                c.restore();
                                c.restore();
                              }
                            }
                            // Recitation mode: the covered verses' lines,
                            // band high, from one verse marker to the
                            // next, so no mark of theirs is left; then the
                            // markers are drawn again on top.
                            final hidden = x.hidden;
                            if (hidden != null) {
                              final cover = Paint()
                                ..color = tokens.colors.paper;
                              final markersOn = <int, List<double>>{};
                              for (final v in verses) {
                                final m = v.marker;
                                if (m == null) continue;
                                (markersOn[layout._lineOf(m.dy)] ??= []).add(
                                  m.dx,
                                );
                              }
                              for (final v in verses) {
                                if (!hidden.contains(v.key)) continue;
                                final words = x.hiddenWords[v.key];
                                if (words == null ||
                                    words.isEmpty ||
                                    widget.page <= 2) {
                                  c.drawPath(v.path, cover);
                                  continue;
                                }
                                for (final b in lineBoxes(
                                  words,
                                  lineOf: (r) => layout._lineOf(r.center.dy),
                                  centre: layout._centre,
                                  halfHeight: _pitch * 0.5,
                                )) {
                                  final j = layout._lineOf(b.center.dy);
                                  final xs = markersOn[j] ?? const <double>[];
                                  // The markers on either side of the words,
                                  // or the text's edge.
                                  final left = xs
                                      .where((m) => m < b.left)
                                      .fold(viewBox.left, math.max);
                                  final right = xs
                                      .where((m) => m > b.right)
                                      .fold(viewBox.right, math.min);
                                  c.drawRect(
                                    Rect.fromLTRB(
                                      left,
                                      layout._bandTop(j),
                                      right,
                                      layout._bandBottom(j),
                                    ),
                                    cover,
                                  );
                                }
                              }
                              if (markerPicture != null) {
                                if (ink != null) {
                                  c.saveLayer(
                                    null,
                                    Paint()
                                      ..colorFilter = ColorFilter.mode(
                                        ink,
                                        BlendMode.srcIn,
                                      ),
                                  );
                                }
                                c.save();
                                c.translate(viewBox.left, viewBox.top);
                                c.drawPicture(markerPicture.picture);
                                c.restore();
                                if (ink != null) c.restore();
                              }
                            }
                            // Over the ink: the chosen rosettes.
                            if (look != null) {
                              for (final v in verses) {
                                if (v.marker != null) {
                                  look.paintOver(
                                    c,
                                    v.marker!,
                                    markerR,
                                    v.key.ayah,
                                    marked: x.marks[v.key],
                                  );
                                }
                              }
                            }
                          });
                        }),
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

  /// Verse-end marker radius in page units (smaller on pages 1 and 2).
  double get markerR => widget.page <= 2 ? 6.6 : 8.4;

  static Rect _viewBox(String svg) {
    final m = RegExp(r'viewBox="([\d.\s-]+)"').firstMatch(svg);
    if (m == null) return const Rect.fromLTWH(0, 0, 345, 550);
    final v = m
        .group(1)!
        .trim()
        .split(RegExp(r'\s+'))
        .map(double.parse)
        .toList();
    return Rect.fromLTWH(v[0], v[1], v[2], v[3]);
  }
}

/// The page without its printed verse-end markers. In these files the
/// markers are one group that sits just before the page text.
String withoutMarkers(String svg) {
  final start = svg.indexOf('<g id="ayah_markers"');
  final end = svg.indexOf('<g id="content"');
  if (start < 0 || end < start) return svg;
  return svg.substring(0, start) + svg.substring(end);
}

/// Only the page's printed verse-end markers (the group before the text).
String markersOnly(String svg) {
  final end = svg.indexOf('<g id="content"');
  if (end < 0) return svg;
  return '${svg.substring(0, end)}</svg>';
}

/// Parses the outline format of the verse polygons: "M x y L x y ... Z",
/// possibly several sub-paths.
Path parseOutline(String d) {
  final pairs = _pointPairs(d);
  if (pairs != null) return Path()..addPolygon(pairs, true);
  final path = Path();
  final tokens = d.trim().split(RegExp(r'\s+'));
  var i = 0;
  while (i < tokens.length) {
    final t = tokens[i];
    if (t == 'M' || t == 'L') {
      final x = double.parse(tokens[i + 1]);
      final y = double.parse(tokens[i + 2]);
      t == 'M' ? path.moveTo(x, y) : path.lineTo(x, y);
      i += 3;
    } else if (t == 'Z') {
      path.close();
      i += 1;
    } else {
      i += 1;
    }
  }
  return path;
}

/// Bounds of each sub-path of a verse outline, in reading order.
List<Rect> outlineRects(String d) {
  final pairs = _pointPairs(d);
  if (pairs != null) {
    // Point lists are single polygons; use their bounds.
    return [(Path()..addPolygon(pairs, true)).getBounds()];
  }
  final rects = <Rect>[];
  final tokens = d.trim().split(RegExp(r'\s+'));
  var xs = <double>[];
  var ys = <double>[];
  var i = 0;
  while (i < tokens.length) {
    final t = tokens[i];
    if (t == 'M' || t == 'L') {
      xs.add(double.parse(tokens[i + 1]));
      ys.add(double.parse(tokens[i + 2]));
      i += 3;
    } else {
      if (t == 'Z' && xs.isNotEmpty) {
        rects.add(
          Rect.fromLTRB(
            xs.reduce((a, b) => a < b ? a : b),
            ys.reduce((a, b) => a < b ? a : b),
            xs.reduce((a, b) => a > b ? a : b),
            ys.reduce((a, b) => a > b ? a : b),
          ),
        );
        xs = [];
        ys = [];
      }
      i += 1;
    }
  }
  // Some outlines (pages 1 and 2) do not end with Z.
  if (xs.isNotEmpty) {
    rects.add(
      Rect.fromLTRB(
        xs.reduce((a, b) => a < b ? a : b),
        ys.reduce((a, b) => a < b ? a : b),
        xs.reduce((a, b) => a > b ? a : b),
        ys.reduce((a, b) => a > b ? a : b),
      ),
    );
  }
  rects.sort(
    (a, b) =>
        a.top != b.top ? a.top.compareTo(b.top) : b.right.compareTo(a.right),
  );
  return rects;
}

class _CallbackPainter extends CustomPainter {
  _CallbackPainter(this.draw);

  final void Function(Canvas canvas) draw;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CallbackPainter old) => true;
}

/// Pages 1 and 2 store their outlines as "x,y x,y ..." point lists.
List<Offset>? _pointPairs(String d) {
  final t = d.trim();
  if (!t.contains(',') || t.startsWith('M')) return null;
  final pts = <Offset>[];
  for (final pair in t.split(RegExp(r'\s+'))) {
    final xy = pair.split(',');
    if (xy.length != 2) return null;
    pts.add(Offset(double.parse(xy[0]), double.parse(xy[1])));
  }
  return pts.isEmpty ? null : pts;
}
