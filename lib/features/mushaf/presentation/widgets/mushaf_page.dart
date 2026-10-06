import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/db/content_database.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/compiled_svg.dart';
import '../../data/tajweed.dart';
import '../../mushaf_providers.dart';
import 'image_page.dart';
import 'page_interaction.dart';

typedef _PageData = (
  PictureInfo,
  Rect,
  List<AyahPolygonRow>,
  SvgPageGeometry,
  Map<int, List<Path>>,
  PictureInfo?,

  /// The clip region of each line, built once per page by [pageLineClips].
  List<Path>,
);

/// Identifies a verse.
typedef VerseKey = ({int surah, int ayah});

/// 15 lines on every page. The line grid (first line centre and pitch)
/// and the opening pages' block are measured on each edition's pages; see
/// [SvgPageGeometry].
const _lineCount = 15;

/// The page-unit region that belongs to each line: its band, less the marks
/// of neighbouring lines that reach into it, plus its own marks that reach
/// out.
///
/// Built once per loaded page, never per build: each clip costs
/// [Path.combine] calls against the marks' outlines, which run to hundreds
/// of points, and the layout is made again on every build.
List<Path> pageLineClips(
  Rect viewBox,
  List<double> cuts,
  Map<int, List<Path>> overflow, {
  double firstLine = 26.2,
  double pitch = 35.75,
}) {
  final hasCuts = cuts.length == _lineCount - 1;
  double centre(int j) => firstLine + j * pitch;
  double bandTop(int j) =>
      j == 0 ? viewBox.top : (hasCuts ? cuts[j - 1] : centre(j) - pitch / 2);
  double bandBottom(int j) => j == _lineCount - 1
      ? viewBox.bottom
      : (hasCuts ? cuts[j] : centre(j) + pitch / 2);
  final marks = <(int, Path, Rect)>[
    for (final e in overflow.entries)
      for (final p in e.value) (e.key, p, p.getBounds()),
  ];
  return [
    for (var j = 0; j < _lineCount; j++)
      () {
        final band = Rect.fromLTRB(
          viewBox.left,
          bandTop(j),
          viewBox.right,
          bandBottom(j),
        );
        var clip = Path()..addRect(band);
        // Only the line's own marks and the neighbours that reach its band
        // can change it; the rest are skipped, and on these pages that is
        // most of them.
        var reached = band;
        for (final (line, path, bounds) in marks) {
          final own = line == j;
          if (!own && !bounds.overlaps(reached)) continue;
          clip = Path.combine(
            own ? PathOperation.union : PathOperation.difference,
            clip,
            path,
          );
          if (own && bounds.isFinite) reached = reached.expandToInclude(bounds);
        }
        return clip;
      }(),
  ];
}

/// The line grid of a page in the image editions' terms (page units), so a
/// touch finds its verse the same way: by the line drawn nearest it first
/// ([StripLayout.pieceAt]).
PageGeometry svgLineGeometry(
  Rect viewBox,
  SvgPageGeometry geometry, {
  required bool opening,
}) {
  final cuts = geometry.cuts, pitch = geometry.pitch;
  final hasCuts = cuts.length == _lineCount - 1;
  double centre(int j) => geometry.firstLine + j * pitch;
  return PageGeometry(
    ink: opening ? geometry.openingInk : viewBox,
    inkWithoutHeader: opening ? geometry.openingBody : null,
    whole: opening,
    centres: [for (var j = 0; j < _lineCount; j++) centre(j)],
    slots: [for (var j = 0; j < _lineCount; j++) j.toDouble()],
    bandTops: [
      for (var j = 0; j < _lineCount; j++)
        j == 0 ? viewBox.top : (hasCuts ? cuts[j - 1] : centre(j) - pitch / 2),
    ],
    bandBottoms: [
      for (var j = 0; j < _lineCount; j++)
        j == _lineCount - 1
            ? viewBox.bottom
            : (hasCuts ? cuts[j] : centre(j) + pitch / 2),
    ],
    inkAbove: _PageLayout._inkAbove,
    inkBelow: _PageLayout._inkBelow,
    boxHalfHeight: pitch * 0.42,
  );
}

/// A verse's outline rects (page units) cut at the lines: a rect can
/// cover several whole lines, and each line is highlighted and touched on
/// its own. A rect is on the lines whose centres it holds (its edges are a
/// little off the cuts); one that holds none is kept whole.
List<Rect> lineRects(List<Rect> rects, PageGeometry g) => [
  for (final r in rects)
    ...() {
      final on = [
        for (var j = 0; j < g.lines; j++)
          if (r.top <= g.centres[j] && g.centres[j] <= r.bottom)
            Rect.fromLTRB(
              r.left,
              math.max(r.top, g.bandTops[j]),
              r.right,
              math.min(r.bottom, g.bandBottoms[j]),
            ),
      ];
      return on.isEmpty ? [r] : on;
    }(),
];

/// Where the page is drawn on screen. Normal pages fill the width and their
/// 15 lines are spread evenly over the full height, without stretching the
/// calligraphy. Pages 1 and 2, and screens wider than the page, are scaled
/// as a whole instead.
class _PageLayout {
  _PageLayout(
    this.size,
    this.viewBox, {
    required bool opening,
    required this.clips,
    required this.firstLine,
    required this.pitch,
    required Rect openingInk,
    required Rect openingBody,
    this.cuts = const [],
    bool withoutHeader = false,
    PageFill? fill,
  }) : clip = opening && withoutHeader ? openingBody : null {
    final area = clip ?? (opening ? openingInk : viewBox);
    final byWidth = size.width / area.width;
    final byHeight = size.height / area.height;
    // Focus mode: a full stretch scales the page on both axes to the room;
    // a slight one widens a page fitted to the height by up to
    // [StripLayout.maxStretch]. The touch layout ([StripLayout]) does the
    // same with the same [fill], so touches land where the page is drawn.
    final full = fill == PageFill.full && !opening;
    scale = full || byWidth >= byHeight ? byHeight : byWidth;
    strips = !full && !opening && byWidth < byHeight;
    scaleX = full
        ? byWidth
        : fill == PageFill.stretch && !strips && !opening
        ? math.min(byWidth, scale * (1 + StripLayout.maxStretch))
        : scale;
    offset = Offset(
      (size.width - area.width * scaleX) / 2 - area.left * scaleX,
      (size.height - area.height * scale) / 2 - area.top * scale,
    );
  }

  final Size size;

  /// The line grid: first line centre and pitch (page units).
  final double firstLine;
  final double pitch;

  /// Page-unit area to keep (pages 1 and 2 without their header).
  final Rect? clip;

  /// The SVG's viewBox in user units (pages 1 and 2 have a shifted origin).
  final Rect viewBox;

  /// The 14 cuts between lines (page units), chosen where no mark or the
  /// fewest marks cross.
  final List<double> cuts;

  /// The clip region of each line, built once per loaded page by
  /// [pageLineClips]. It is not built here because this layout is made
  /// again on every build, and each clip costs [Path.combine] calls on the
  /// marks' outlines, which run to hundreds of points.
  final List<Path> clips;

  late final double scale;

  /// Page units to screen across: [scale], or wider when focus mode
  /// stretches a page that is not drawn in strips.
  late final double scaleX;
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
  double _centre(int j) => firstLine + j * pitch;
  bool get _hasCuts => cuts.length == _lineCount - 1;
  double _bandTop(int j) =>
      j == 0 ? viewBox.top : (_hasCuts ? cuts[j - 1] : _centre(j) - pitch / 2);
  double _bandBottom(int j) => j == _lineCount - 1
      ? viewBox.bottom
      : (_hasCuts ? cuts[j] : _centre(j) + pitch / 2);

  double _slotCentre(int j) => _padTop + (j + 0.5) * _slot;

  int _lineOf(double y) {
    if (!_hasCuts) {
      return ((y - firstLine + pitch / 2) / pitch).floor().clamp(
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
    if (!strips) {
      return Offset(p.dx * scaleX + offset.dx, p.dy * scale + offset.dy);
    }
    final j = line ?? _lineOf(p.dy);
    return Offset(
      p.dx * scale + offset.dx,
      _slotCentre(j) + (p.dy - _centre(j)) * scale,
    );
  }

  /// Runs [draw] in the page units of line [j]'s band, without clipping:
  /// what [paintBands] does for one band, for one element of that band.
  ///
  /// [paintBands] clips each band with a path that runs to hundreds of
  /// points, which Impeller turns into geometry on the raster thread: a
  /// frame that drew its marks through it paid that cost thirty times over.
  /// An element belongs to one line, so it is drawn once, at that line's
  /// transform, and nothing of a neighbour's can reach it.
  void atBand(Canvas canvas, int j, bool emphasis, void Function(Canvas) draw) {
    if (!strips) {
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.scale(scaleX, scale);
      draw(canvas);
      canvas.restore();
      return;
    }
    final dy = _slotCentre(j) - _centre(j) * scale;
    canvas.save();
    canvas.translate(offset.dx, dy);
    canvas.scale(scale);
    if (emphasis) {
      final cx = viewBox.center.dx;
      final cy = _centre(j);
      canvas.translate(cx, cy);
      canvas.scale(1.12);
      canvas.translate(-cx, -cy);
    }
    draw(canvas);
    canvas.restore();
  }

  /// Runs [draw] in page units once per line band, clipped to that band.
  /// [draw] is told the band's line, or -1 when the page is drawn whole
  /// (no bands), so a band can skip what belongs to the other lines:
  /// whatever it draws for them is clipped away here anyway.
  /// [emphasis] lines (the basmala) are drawn a little larger and bolder.
  void paintBands(
    Canvas canvas,
    void Function(Canvas, bool emphasis, int line) draw, {
    Set<int> emphasis = const {},
  }) {
    if (!strips) {
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.scale(scaleX, scale);
      if (clip != null) canvas.clipRect(clip!);
      draw(canvas, false, -1);
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
      canvas.clipPath(clips[j]);
      draw(canvas, big, j);
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

  /// The page's ink, drawn once at the screen's pixel size and blitted. See
  /// [_bakeArt].
  ui.Image? _art;
  ui.Image? _markerArt;

  /// What [_art] was drawn for, and which load it came from. A bake for
  /// anything else replaces it.
  String? _artKey;

  /// Bumped on every load, so a re-fetched page is drawn again.
  int _loadId = 0;

  /// Draws the page's ink once into an image, so that a frame only blits it.
  ///
  /// The pages carry thousands of paths (their printed frame alone is most
  /// of them) and Impeller turns paths into geometry on the raster thread,
  /// which is one core there: painting them once per line band, fifteen
  /// times a frame, held that thread at three quarters of a core on a
  /// phone. Baking them costs the same work once per page, off the frame.
  void _bakeArt(
    String key,
    _PageLayout layout,
    double dpr, {
    required void Function(Canvas, bool, int) ink,
    void Function(Canvas, bool, int)? markers,
    required Set<int> emphasis,
  }) {
    // The colouring is still being read: bake once, when it is in.
    if (_tajweedPending || _artKey == key) return;
    _artKey = key;
    final width = (layout.size.width * dpr).ceil();
    final height = (layout.size.height * dpr).ceil();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      Future<ui.Image> render(void Function(Canvas, bool, int) draw) async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder)..scale(dpr);
        layout.paintBands(
          canvas,
          emphasis: emphasis,
          (c, bold, line) => draw(c, bold, line),
        );
        final picture = recorder.endRecording();
        try {
          return await picture.toImage(width, height);
        } finally {
          picture.dispose();
        }
      }

      final art = await render(ink);
      final markerArt = markers == null ? null : await render(markers);
      if (!mounted || _artKey != key) {
        art.dispose();
        markerArt?.dispose();
        return;
      }
      final old = [_art, _markerArt];
      setState(() {
        _art = art;
        _markerArt = markerArt;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final i in old) {
          i?.dispose();
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  /// Tajweed colouring: each coloured piece of the page (page units), for
  /// [_tajweedKey] (page and data row).
  List<TajweedPiece> _tajweed = const [];
  (int, String)? _tajweedKey;

  /// The pieces for [_tajweedKey] are still being read. The page is not
  /// baked again until they are in: baking it without them and again with
  /// them drew it twice.
  bool _tajweedPending = false;

  /// [_tajweed] grouped by line and colour, for [_tajweedGroupsKey].
  Map<int, Map<Color, List<TajweedPiece>>> _tajweedGroups = const {};
  Object? _tajweedGroupsKey;

  /// Reads the contours the page's tajweed row points at, once per page,
  /// on a worker isolate ([loadTajweedPieces]).
  Future<void> _loadTajweed(String data, {String? svg}) async {
    final key = (widget.page, data);
    if (_tajweedKey == key) return;
    _tajweedKey = key;
    _tajweed = const [];
    _tajweedPending = data.isNotEmpty;
    if (data.isEmpty) return;
    final page = widget.page;
    try {
      final text = svg ?? await ref.read(pageStoreProvider).svg(page);
      final pieces = await loadTajweedPieces(page, text, data);
      if (!mounted || _tajweedKey != key) return;
      setState(() {
        _tajweed = pieces;
        _tajweedPending = false;
      });
    } catch (_) {
      // No colouring for this page; the page itself is still drawn.
      if (mounted && _tajweedKey == key) {
        setState(() => _tajweedPending = false);
      }
    }
  }

  /// Starts reading the page's tajweed pieces when the colouring is on. The
  /// row is the reader's ([PageInteraction.tajweed]) or, when that has not
  /// come in yet, read here from the same provider.
  Future<void> _preloadTajweed(String svg) async {
    final x = widget.interaction;
    if (x.tajweedColor == null) return;
    var row = x.tajweed;
    if (row.isEmpty) {
      try {
        row = await ref.read(tajweedPageProvider(widget.page).future);
      } catch (_) {
        return;
      }
    }
    if (!mounted || row.isEmpty) return;
    await _loadTajweed(row, svg: svg);
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
    _art?.dispose();
    _markerArt?.dispose();
    super.dispose();
  }

  Future<_PageData> _fetch() async {
    _loadId += 1;
    final svg = await ref.read(pageStoreProvider).svg(widget.page);
    // The tajweed pieces are read on a worker while the page compiles, and
    // the page is shown with them, so it is baked once, coloured.
    final tajweed = _preloadTajweed(svg);
    // Compiling these on the main isolate cost a few hundred milliseconds a
    // page; see [compiledSvgPicture]. The page and its markers do not depend
    // on each other, so both are asked for at once.
    final (info, markers) = await (
      compiledSvgPicture(
        _markersHidden ? withoutMarkers(svg) : svg,
        name: 'page ${widget.page}',
      ),
      // The printed markers alone, drawn again over the recitation covers.
      _markersHidden
          ? Future<PictureInfo?>.value(null)
          : compiledSvgPicture(
              markersOnly(svg),
              name: 'page ${widget.page} markers',
            ),
    ).wait;
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
    // Outlines, line cuts and grid: the new edition's from content.db, a
    // riwaya edition's from its pack.
    final geometry = await ref.read(
      svgPageGeometryProvider(widget.page).future,
    );
    final overflow = <int, List<Path>>{};
    for (final (line, path) in geometry.overflow) {
      overflow.putIfAbsent(line, () => []).add(parseOutline(path));
    }
    final viewBox = _viewBox(svg);
    await tajweed;
    return (
      info,
      viewBox,
      geometry.polygons,
      geometry,
      overflow,
      markers,
      pageLineClips(
        viewBox,
        geometry.cuts,
        overflow,
        firstLine: geometry.firstLine,
        pitch: geometry.pitch,
      ),
    );
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
          return Center(
            child: CircularProgressIndicator(
              semanticsLabel: AppLocalizations.of(context)
                  .loadingPage('${widget.page}'),
            ),
          );
        }
        final (
          picture,
          viewBox,
          polys,
          geometry,
          overflow,
          markerPicture,
          clips,
        ) = snap.data!;
        final cuts = geometry.cuts;
        // Touches find their verse by the line first, as on the image
        // editions ([StripLayout.pieceAt]).
        final lineGeometry = svgLineGeometry(
          viewBox,
          geometry,
          opening: widget.page <= 2,
        );
        final verses = [
          for (final p in polys)
            (
              key: (surah: p.surah, ayah: p.number),
              path: parseOutline(p.path),
              // Pages 1 and 2 have no line grid (see [openingRects]).
              rects: widget.page <= 2
                  ? outlineRects(p.path)
                  : lineRects(outlineRects(p.path), lineGeometry),
              marker: p.markerX == null ? null : Offset(p.markerX!, p.markerY!),
            ),
        ];
        final pieces = [
          for (final v in verses)
            for (final r in v.rects) (v.key, r),
        ];
        final pieceRects = [for (final (_, r) in pieces) r];

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
            final touch = StripLayout(
              box.biggest,
              lineGeometry,
              withoutHeader: x.ornateOpening,
              fill: x.fill,
            );
            VerseKey? verseAt(Offset local) {
              // Pages 1 and 2 have no line grid; their outlines tile the
              // text, and the page is scaled whole.
              if (widget.page <= 2) {
                final point = touch.toImage(local);
                for (final v in verses) {
                  if (v.path.contains(point)) return v.key;
                }
                return null;
              }
              final i = touch.pieceAt(
                local,
                pieceRects,
                // The word picker's slop, in page units.
                slop: 2,
              );
              return i == null ? null : pieces[i].$1;
            }

            final layout = _PageLayout(
              box.biggest,
              viewBox,
              opening: widget.page <= 2,
              cuts: cuts,
              clips: clips,
              firstLine: geometry.firstLine,
              pitch: geometry.pitch,
              openingInk: geometry.openingInk,
              openingBody: geometry.openingBody,
              withoutHeader: x.ornateOpening,
              fill: x.fill,
            );
            final selected = [
              for (final v in verses)
                if (x.selection.contains(v.key)) v,
            ];
            // Pages 1 and 2 keep their own layout. A verse's outline there
            // is one polygon over several lines, so its lines come from its
            // word boxes.
            final openingWords = widget.page <= 2
                ? ref.watch(pageWordBoxesProvider(widget.page)).value
                : null;
            List<Rect> openingRects(
              ({VerseKey key, List<Rect> rects, Path path, Offset? marker}) v,
            ) {
              final rows = openingWords == null
                  ? const <Rect>[]
                  : wordRows([
                      for (final MapEntry(key: (s, a, _), value: pieces)
                          in openingWords.entries)
                        if (s == v.key.surah && a == v.key.ayah) ...pieces,
                    ]);
              return [
                for (final r in rows.isEmpty ? v.rects : rows) r.inflate(1),
              ];
            }

            final boxes = widget.page <= 2
                ? [for (final v in selected) ...openingRects(v)]
                : lineBoxes(
                    [for (final v in selected) ...v.rects],
                    lineOf: (r) => layout._lineOf(r.center.dy),
                    centre: layout._centre,
                    halfHeight: layout.pitch * 0.42,
                    band: (j) => (layout._bandTop(j), layout._bandBottom(j)),
                  );
            final touchedBoxes = [
              for (final v in verses)
                if (v.key == x.touched)
                  ...widget.page <= 2
                      ? openingRects(v)
                      : lineBoxes(
                          v.rects,
                          lineOf: (r) => layout._lineOf(r.center.dy),
                          centre: layout._centre,
                          halfHeight: layout.pitch * 0.42,
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
                    halfHeight: layout.pitch * 0.42,
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
                final v = verseAt(ro.globalToLocal(global));
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
            // The divine names, grouped by the line each falls on, so a
            // line draws only its own: the others are clipped away here,
            // and drawing them redrew the whole page once per name per
            // line (up to sixteen names on a page, fifteen lines).
            final divineByLine = <int, List<Rect>>{};
            if (x.divineColor != null) {
              for (final r in x.divineNames) {
                (divineByLine[layout._lineOf(r.center.dy)] ??= []).add(r);
              }
            }
            // The ink is drawn once at the screen's pixel size; a frame
            // only blits it. Everything the drawing depends on is in the
            // key, so a change to any of it re-bakes.
            // Tajweed: the coloured pieces by line and colour, so a line band
            // draws only its own; grouped once per page, size and colours.
            final tajweedColor = x.tajweedColor;
            if (tajweedColor != null) _loadTajweed(x.tajweed);
            final tajweedSig = tajweedColor == null
                ? ''
                : '${_tajweed.length}:${[for (final r in TajweedRule.values) tajweedColor(r)?.toARGB32()].join(',')}';
            final groupsKey = (_tajweed, box.biggest, tajweedSig);
            if (_tajweedGroupsKey != groupsKey) {
              _tajweedGroupsKey = groupsKey;
              final groups = <int, Map<Color, List<TajweedPiece>>>{};
              if (tajweedColor != null) {
                for (final piece in _tajweed) {
                  final colour = tajweedColor(piece.rule);
                  if (colour == null) continue;
                  final j = layout._lineOf(piece.bounds.center.dy);
                  ((groups[j] ??= {})[colour] ??= []).add(piece);
                }
              }
              _tajweedGroups = groups;
            }
            final tajweedByLine = _tajweedGroups;
            final dpr = MediaQuery.devicePixelRatioOf(context);
            final emphasisLines = x.emphasisLines.toList()..sort();
            _bakeArt(
              '${widget.page}|${box.biggest.width}x${box.biggest.height}'
              '|$dpr|$ink|${x.divineColor}|${x.divineNames.length}'
              '|$_markersHidden|$_loadId|${emphasisLines.join(',')}'
              '|$tajweedSig|${x.fill}',
              layout,
              dpr,
              emphasis: x.emphasisLines,
              ink: (c, bold, line) => _paintInk(
                c,
                picture: picture.picture,
                viewBox: viewBox,
                ink: ink,
                bold: bold,
                line: line,
                divineColor: x.divineColor,
                divineNames: x.divineNames,
                divineByLine: divineByLine,
                tajweedByLine: tajweedByLine,
              ),
              markers: markerPicture == null
                  ? null
                  : (c, bold, line) => _paintMarkers(
                      c,
                      picture: markerPicture.picture,
                      viewBox: viewBox,
                      ink: ink,
                    ),
            );
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      final local = d.localPosition;
                      final point = touch.toImage(local);
                      if (x.onPick != null) {
                        return x.onPick!(point, verseAt(local));
                      }
                      if (x.hidden != null) {
                        final v = verseAt(local);
                        if (v != null) {
                          x.onHiddenTap?.call(v);
                          return;
                        }
                      }
                      final m = markerAt(point);
                      if (m != null) return x.onMarkerTap(m);
                      final v = x.onVerseTap == null ? null : verseAt(local);
                      v != null ? x.onVerseTap!(v, point) : x.onTap();
                    },
                    onLongPressStart: (d) {
                      final v = verseAt(d.localPosition);
                      if (v != null) x.onVerseLongPress(v);
                    },
                    child: Semantics(
                      label: l.pageOf('${widget.page}'),
                      image: true,
                      sortKey: const OrdinalSortKey(0),
                      child: CustomPaint(
                        size: box.biggest,
                        painter: _CallbackPainter((canvas) {
                          // Three passes, so the page's ink can be drawn in
                          // one blit (see [_bakeArt]): what lies under it,
                          // the ink, then what lies over it.
                          final art = _art;
                          final markerArt = _markerArt;
                          // Each element belongs to one line, so it is
                          // drawn once, at that line's band transform, and
                          // no clip path is built for it.
                          final underItems = <(int, void Function(Canvas))>[];
                          final overItems = <(int, void Function(Canvas))>[];
                          final coverItems = <(int, void Function(Canvas))>[];
                          Map<int, List<Rect>> byLine(List<Rect> rects) {
                            final out = <int, List<Rect>>{};
                            for (final r in rects) {
                              (out[layout._lineOf(r.center.dy)] ??= []).add(r);
                            }
                            return out;
                          }

                          void also(
                            List<(int, void Function(Canvas))> items,
                            int line,
                            void Function(Canvas) draw,
                          ) => items.add((line, draw));

                          // Under the ink: marker tints and the selection.
                          for (final v in verses) {
                            final m = v.marker;
                            if (m == null) continue;
                            final j = layout._lineOf(m.dy);
                            if (look != null) {
                              also(
                                underItems,
                                j,
                                (c) => look.paintUnder(c, m, markerR),
                              );
                              also(
                                overItems,
                                j,
                                (c) => look.paintOver(
                                  c,
                                  m,
                                  markerR,
                                  v.key.ayah,
                                  marked: x.marks[v.key],
                                ),
                              );
                            }
                            final colour = x.marks[v.key];
                            if (colour != null) {
                              also(underItems, j, (c) {
                                c.drawCircle(
                                  m,
                                  markerR,
                                  Paint()
                                    ..color = colour.withValues(alpha: 0.35),
                                );
                                c.drawCircle(
                                  m,
                                  markerR,
                                  Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = markerR * 0.22
                                    ..color = colour,
                                );
                              });
                            }
                          }
                          for (final e in byLine(boxes).entries) {
                            also(
                              underItems,
                              e.key,
                              (c) => paintVerseBoxes(
                                c,
                                e.value,
                                tokens.colors.highlight,
                                stroke: 0.7,
                                radius: 3,
                              ),
                            );
                          }
                          if (x.touchColor != null) {
                            for (final e in byLine(touchedBoxes).entries) {
                              also(
                                underItems,
                                e.key,
                                (c) => paintVerseBoxes(
                                  c,
                                  e.value,
                                  x.touchColor!,
                                  stroke: 0.7,
                                  radius: 3,
                                ),
                              );
                            }
                          }
                          if (wordBox != null) {
                            also(
                              underItems,
                              layout._lineOf(wordBox.center.dy),
                              (c) => paintVerseBoxes(
                                c,
                                [wordBox],
                                tokens.colors.highlight.withValues(
                                  alpha: tokens.colors.highlight.a * 2.4,
                                ),
                                stroke: 0.9,
                                radius: 3,
                              ),
                            );
                          }

                          // Recitation mode: the covered verses' lines,
                          // band high, from one verse marker to the next, so
                          // no mark of theirs is left.
                          final hidden = x.hidden;
                          if (hidden != null) {
                            final cover = Paint()..color = tokens.colors.paper;
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
                              final shown =
                                  x.revealedWords[v.key] ?? const <Rect>[];
                              if (shown.isNotEmpty &&
                                  words != null &&
                                  words.isNotEmpty &&
                                  widget.page <= 2) {
                                // A test on an opening page (no line grid):
                                // the words still covered, line by line.
                                for (final r in openingCovers(v.rects, words)) {
                                  also(
                                    coverItems,
                                    layout._lineOf(r.center.dy),
                                    (c) => c.drawRect(r, cover),
                                  );
                                }
                                continue;
                              }
                              if (words == null ||
                                  words.isEmpty ||
                                  widget.page <= 2) {
                                also(
                                  coverItems,
                                  layout._lineOf(v.path.getBounds().center.dy),
                                  (c) => c.drawPath(v.path, cover),
                                );
                                continue;
                              }
                              for (final b in lineBoxes(
                                words,
                                lineOf: (r) => layout._lineOf(r.center.dy),
                                centre: layout._centre,
                                halfHeight: layout.pitch * 0.5,
                              )) {
                                final j = layout._lineOf(b.center.dy);
                                final xs = markersOn[j] ?? const <double>[];
                                // The markers on either side of the words,
                                // or the text's edge.
                                final left = xs
                                    .where((m) => m < b.left)
                                    .fold(viewBox.left, math.max);
                                // In a word-by-word test, the words already
                                // shown on this line stay: the cover stops
                                // at them (right to left).
                                final right =
                                    [
                                      for (final r in shown)
                                        if (layout._lineOf(r.center.dy) == j)
                                          r.left - 0.5,
                                    ].fold(
                                      xs
                                          .where((m) => m > b.right)
                                          .fold(viewBox.right, math.min),
                                      math.min,
                                    );
                                final rect = Rect.fromLTRB(
                                  left,
                                  layout._bandTop(j),
                                  right,
                                  layout._bandBottom(j),
                                );
                                also(
                                  coverItems,
                                  j,
                                  (c) => c.drawRect(rect, cover),
                                );
                              }
                            }
                          }

                          void drawEach(
                            List<(int, void Function(Canvas))> items,
                          ) {
                            for (final (line, draw) in items) {
                              layout.atBand(
                                canvas,
                                line,
                                x.emphasisLines.contains(line),
                                draw,
                              );
                            }
                          }

                          drawEach(underItems);
                          if (art != null) {
                            canvas.drawImageRect(
                              art,
                              _imageRect(art),
                              Offset.zero & layout.size,
                              Paint(),
                            );
                          } else {
                            // Not baked yet: draw the picture itself, line
                            // band by line band.
                            layout.paintBands(
                              canvas,
                              emphasis: x.emphasisLines,
                              (c, bold, line) => _paintInk(
                                c,
                                picture: picture.picture,
                                viewBox: viewBox,
                                ink: ink,
                                bold: bold,
                                line: line,
                                divineColor: x.divineColor,
                                divineNames: x.divineNames,
                                divineByLine: divineByLine,
                                tajweedByLine: tajweedByLine,
                              ),
                            );
                          }
                          drawEach(coverItems);
                          if (hidden != null) {
                            // The printed markers again, on top.
                            if (markerArt != null) {
                              canvas.drawImageRect(
                                markerArt,
                                _imageRect(markerArt),
                                Offset.zero & layout.size,
                                Paint(),
                              );
                            } else if (markerPicture != null) {
                              layout.paintBands(
                                canvas,
                                emphasis: x.emphasisLines,
                                (c, bold, line) => _paintMarkers(
                                  c,
                                  picture: markerPicture.picture,
                                  viewBox: viewBox,
                                  ink: ink,
                                ),
                              );
                            }
                          }
                          drawEach(overItems);
                        }),
                      ),
                    ),
                  ),
                ),
                ...verseSemanticNodes(
                  x,
                  verseAreas([
                    for (final v in verses)
                      for (final r in v.rects)
                        (
                          v.key,
                          Rect.fromPoints(
                            layout.toScreen(
                              r.topLeft,
                              line: layout._lineOf(r.center.dy),
                            ),
                            layout.toScreen(
                              r.bottomRight,
                              line: layout._lineOf(r.center.dy),
                            ),
                          ),
                        ),
                  ]),
                  markAction: l.markThisVerse,
                  listenAction: l.listenFromVerse,
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

/// Boxes (words, glyphs or verse pieces) gathered into one box per line
/// of text, top to bottom. A box joins the row whose average centre is
/// within half the typical box height of its own.
List<Rect> wordRows(List<Rect> pieces) {
  if (pieces.isEmpty) return const [];
  final heights = [for (final r in pieces) r.height]..sort();
  final tolerance = heights[heights.length ~/ 2] * 0.5;
  final rows = <Rect>[];
  final centres = <double>[];
  final counts = <int>[];
  for (final r in [
    ...pieces,
  ]..sort((a, b) => a.center.dy.compareTo(b.center.dy))) {
    final i = centres.indexWhere((c) => (c - r.center.dy).abs() < tolerance);
    if (i < 0) {
      rows.add(r);
      centres.add(r.center.dy);
      counts.add(1);
    } else {
      rows[i] = rows[i].expandToInclude(r);
      centres[i] = (centres[i] * counts[i] + r.center.dy) / (counts[i] + 1);
      counts[i]++;
    }
  }
  return rows;
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

/// Recitation covers on the opening pages (1 and 2), which have no line
/// grid: [words] (page units) grouped into lines by their centres, each
/// group covered across its span, as tall as the verse's own line box
/// ([lineRects]) when one holds it, else as the words plus a margin.
List<Rect> openingCovers(List<Rect> lineRects, List<Rect> words) {
  if (words.isEmpty) return const [];
  final sorted = [...words]..sort((a, b) => a.center.dy.compareTo(b.center.dy));
  final heights = [for (final w in sorted) w.height]..sort();
  final gap = heights[heights.length ~/ 2] * 0.5;
  final groups = <Rect>[];
  for (final w in sorted) {
    if (groups.isNotEmpty &&
        (w.center.dy - groups.last.center.dy).abs() < gap) {
      groups.last = groups.last.expandToInclude(w);
    } else {
      groups.add(w);
    }
  }
  return [
    for (final g in groups)
      () {
        final line = lineRects
            .where(
              (r) =>
                  r.top <= g.center.dy &&
                  g.center.dy <= r.bottom &&
                  r.height < g.height * 2.2,
            )
            .firstOrNull;
        return Rect.fromLTRB(
          g.left - 1.5,
          line == null ? g.top - 2 : line.top - 1,
          g.right + 1.5,
          line == null ? g.bottom + 2 : line.bottom + 1,
        );
      }(),
  ];
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

/// The image's full extent: the source rect of a whole-image blit.
Rect _imageRect(ui.Image image) =>
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

/// The page's printed ink, coloured for the mode, drawn at one line band or
/// over the whole page (when [line] is -1). The page renders this once into
/// the image it blits; see [_MushafPageState._bakeArt].
void _paintInk(
  Canvas c, {
  required ui.Picture picture,
  required Rect viewBox,
  required Color? ink,
  required bool bold,
  required int line,
  required Color? divineColor,
  required List<Rect> divineNames,
  required Map<int, List<Rect>> divineByLine,
  Map<int, Map<Color, List<TajweedPiece>>> tajweedByLine = const {},
}) {
  // Tajweed: only the letters (and marks) a rule applies to. This line's,
  // or every line's when the page is drawn whole.
  final tajweed = line < 0
      ? [for (final m in tajweedByLine.values) ...m.entries]
      : (tajweedByLine[line] ?? const <Color, List<TajweedPiece>>{}).entries;
  // A layer of its own, holding only the ink, for the colours to land on.
  if (tajweed.isNotEmpty) c.saveLayer(null, Paint());
  // The page itself, recoloured outside light mode.
  if (ink != null) {
    c.saveLayer(
      null,
      Paint()..colorFilter = ColorFilter.mode(ink, BlendMode.srcIn),
    );
  }
  // The picture starts at the viewBox corner, not at the origin (pages 1
  // and 2 have a shifted one).
  void page() {
    c.save();
    c.translate(viewBox.left, viewBox.top);
    c.drawPicture(picture);
    c.restore();
  }

  if (bold) {
    // Faux bold: the same line drawn three times, a hair apart.
    for (final dx in const [-0.32, 0.32]) {
      c.save();
      c.translate(dx, 0);
      page();
      c.restore();
    }
  }
  page();
  if (ink != null) c.restore();
  // The divine names, recoloured in place. Only this line's, or all of them
  // when the page is not split into bands.
  if (divineColor != null) {
    final names = line < 0 ? divineNames : divineByLine[line] ?? const <Rect>[];
    for (final r in names) {
      c.save();
      c.clipRect(r);
      c.saveLayer(
        r,
        Paint()..colorFilter = ColorFilter.mode(divineColor, BlendMode.srcIn),
      );
      page();
      c.restore();
      c.restore();
    }
  }
  // Each piece filled with its colour only where ink already is (srcATop):
  // the letter is recoloured and its holes stay empty, without drawing the
  // page again (that was a whole page per colour per line).
  for (final MapEntry(key: colour, value: pieces) in tajweed) {
    final paint = Paint()
      ..color = colour
      ..blendMode = BlendMode.srcATop;
    final whole = Path();
    for (final p in pieces) {
      if (p.clip == null) {
        whole.addPath(p.path, Offset.zero);
      } else {
        c.save();
        c.clipRect(p.clip!);
        c.drawPath(p.path, paint);
        c.restore();
      }
    }
    c.drawPath(whole, paint);
  }
  if (tajweed.isNotEmpty) c.restore();
}

/// The printed verse markers alone, drawn again over the recitation covers.
void _paintMarkers(
  Canvas c, {
  required ui.Picture picture,
  required Rect viewBox,
  required Color? ink,
}) {
  if (ink != null) {
    c.saveLayer(
      null,
      Paint()..colorFilter = ColorFilter.mode(ink, BlendMode.srcIn),
    );
  }
  c.save();
  c.translate(viewBox.left, viewBox.top);
  c.drawPicture(picture);
  c.restore();
  if (ink != null) c.restore();
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
