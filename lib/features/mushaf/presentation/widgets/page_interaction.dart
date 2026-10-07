import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/duotone.dart';
import '../../data/tajweed.dart';
import 'mushaf_page.dart';
import 'theme_art.dart';

/// The colour a page is drawn on. Recitation covers are painted in it, so
/// a covered line is the page's own background and nothing more. The
/// framed layouts lay the page on the theme's paper (the default); where
/// no frame is drawn (the plain frame of plain themes and elderly mode,
/// focus mode) the page lies on the screen's background, and the layout
/// says so here.
class PageGround extends InheritedWidget {
  const PageGround({super.key, required this.color, required super.child});

  final Color color;

  static Color of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PageGround>()?.color ??
      context.tokens.colors.paper;

  @override
  bool updateShouldNotify(PageGround oldWidget) => oldWidget.color != color;
}

/// What the reader can do on a page; shared by both editions.
class PageInteraction {
  const PageInteraction({
    required this.selection,
    required this.marks,
    required this.onTap,
    required this.onVerseLongPress,
    required this.onMarkerTap,
    required this.onHandleDrag,
    this.markerLook,
    this.hidden,
    this.hiddenWords = const {},
    this.revealedWords = const {},
    this.onHiddenTap,
    this.ornateOpening = false,
    this.showHandles = false,
    this.divineNames = const [],
    this.divineColor,
    this.emphasisLines = const {},
    this.activeWord,
    this.onVerseTap,
    this.onListenFrom,
    this.touched,
    this.touchColor,
    this.onPick,
    this.verseLabel,
    this.verseText,
    this.tajweedColor,
    this.tajweed = '',
    this.fill,
    this.onPageLongPress,
  });

  /// A long press on the page off any verse; null: it does nothing.
  final VoidCallback? onPageLongPress;

  /// Focus mode: how the page fills the room it is given; null outside
  /// focus mode, where each edition keeps its own layout.
  final PageFill? fill;

  /// Screen readers: a verse's name («سورة البقرة، الآية ٥») and its text
  /// as stored (read after the name). Without [verseLabel] the page has no
  /// verse nodes.
  final String Function(VerseKey verse)? verseLabel;
  final String? Function(VerseKey verse)? verseText;

  /// Tajweed colouring: each rule's colour on this page's paper (null for
  /// a rule left uncoloured); null when the colouring is off.
  final Color? Function(TajweedRule rule)? tajweedColor;

  /// This page's row of `tajweed_page` (tools/build_tajweed.py), in the
  /// edition's format.
  final String tajweed;

  /// Word picking («دراسة الكلمة»): while set, a tap goes here instead,
  /// with the point in edition units (page units in the new edition, image
  /// px in the others) and the verse under it, if any.
  final void Function(Offset point, VerseKey? verse)? onPick;

  /// A tap on a verse (not its marker), with the point in edition units
  /// as for [onPick]: touch reading shades it, multi-verse selection
  /// extends to it, listening moves the recitation there. While null, a
  /// tap on a verse is a tap on the page ([onTap]).
  final void Function(VerseKey verse, Offset point)? onVerseTap;

  /// While listening: screen readers' action that moves the recitation to
  /// a verse.
  final ValueChanged<VerseKey>? onListenFrom;
  final VerseKey? touched;
  final Color? touchColor;

  /// The word being recited (new edition, page units); drawn over the
  /// verse highlight.
  final Rect? activeWord;

  /// Boxes of the divine names to colour (edition units), and the colour.
  final List<Rect> divineNames;
  final Color? divineColor;

  /// Line slots drawn larger and bolder (the basmala lines).
  final Set<int> emphasisLines;

  /// Multi-verse selection is on: show the two drag handles.
  final bool showHandles;

  /// Pages 1 and 2 inside the ornate frame: the printed surah header is
  /// left out, since the frame's cartouche names the surah.
  final bool ornateOpening;

  /// How verse-end markers are drawn; null = as printed.
  final MarkerLook? markerLook;

  /// Recitation mode: verses covered on this page; null = mode off.
  final Set<VerseKey>? hidden;

  /// Recitation mode: the word boxes of each covered verse, where known
  /// (edition units), which place its lines. A covered verse is hidden
  /// line by line, band high, from marker to marker, with every mark it
  /// has; only the verse-end markers and their numbers stay.
  final Map<VerseKey, List<Rect>> hiddenWords;

  /// Recitation test (word by word): the words of a covered verse already
  /// shown, in reading order (edition units). Then [hiddenWords] holds only
  /// the words still covered: lines with none of them stay uncovered, and
  /// on the line where the two meet the cover stops at the shown words.
  final Map<VerseKey, List<Rect>> revealedWords;

  /// Recitation mode: a verse was tapped (to show or cover it).
  final ValueChanged<VerseKey>? onHiddenTap;

  /// Verses highlighted on this page (the current selection).
  final Set<VerseKey> selection;

  /// Verse markers painted in a mark's colour.
  final Map<VerseKey, Color> marks;

  /// A short tap anywhere that is not a verse marker.
  final VoidCallback onTap;
  final ValueChanged<VerseKey> onVerseLongPress;
  final ValueChanged<VerseKey> onMarkerTap;

  /// A selection handle was dragged over [VerseKey]; `start` is true for
  /// the handle at the beginning of the selection.
  final void Function(bool start, VerseKey verse) onHandleDrag;
}

/// Screen-reader nodes for a page's verses, one per verse over the area
/// it covers ([areas], screen coordinates, in reading order). A double tap
/// selects the verse (or, in recitation mode, shows or covers it; while
/// picking a word, studies the verse), a long press does what it does on
/// the page, and a custom action sets or removes the reading mark; while
/// listening another ([listenAction]) moves the recitation to the verse.
/// The nodes take no touches: the page under them still answers every
/// gesture.
List<Widget> verseSemanticNodes(
  PageInteraction x,
  List<(VerseKey, Rect)> areas, {
  required String markAction,
  String? listenAction,
}) {
  final listen = x.onListenFrom;
  final label = x.verseLabel;
  if (label == null) return const [];
  return [
    for (final (i, (v, rect)) in areas.indexed)
      Positioned.fromRect(
        rect: rect,
        child: Semantics(
          container: true,
          sortKey: OrdinalSortKey(i + 1.0),
          label: label(v),
          value: x.verseText?.call(v),
          selected: x.selection.contains(v),
          onTap: () {
            if (x.onPick != null) return x.onPick!(rect.center, v);
            if (x.hidden != null) return x.onHiddenTap?.call(v);
            x.onVerseLongPress(v);
          },
          onLongPress: () => x.onVerseLongPress(v),
          customSemanticsActions: {
            CustomSemanticsAction(label: markAction): () => x.onMarkerTap(v),
            if (listen != null && listenAction != null)
              CustomSemanticsAction(label: listenAction): () => listen(v),
          },
          child: const SizedBox.expand(),
        ),
      ),
  ];
}

/// The union of each verse's rectangles, in the order the verses first
/// appear (reading order).
List<(VerseKey, Rect)> verseAreas(Iterable<(VerseKey, Rect)> pieces) {
  final out = <VerseKey, Rect>{};
  for (final (v, r) in pieces) {
    out[v] = out[v]?.expandToInclude(r) ?? r;
  }
  return [for (final e in out.entries) (e.key, e.value)];
}

/// One box per line of the highlighted verses: the width the verses take
/// on that line, and a fixed height around the line's centre, so the
/// highlight reads as a tidy frame rather than following every letter.
List<Rect> lineBoxes(
  Iterable<Rect> pieces, {
  required int Function(Rect piece) lineOf,
  required double Function(int line) centre,
  required double halfHeight,
  (double, double) Function(int line)? band,
}) {
  final spans = <int, (double, double)>{};
  for (final r in pieces) {
    final j = lineOf(r);
    final s = spans[j];
    spans[j] = s == null
        ? (r.left, r.right)
        : (s.$1 < r.left ? s.$1 : r.left, s.$2 > r.right ? s.$2 : r.right);
  }
  return [
    for (final MapEntry(key: j, value: (l, r)) in spans.entries)
      Rect.fromLTRB(
        l,
        // Stay inside the line's own band: a frame edge past it would show
        // up as a stray line in the next band.
        math.max(centre(j) - halfHeight, (band?.call(j).$1 ?? -1e9) + 1),
        r,
        math.min(centre(j) + halfHeight, (band?.call(j).$2 ?? 1e9) - 1),
      ),
  ];
}

extension Widen on Rect {
  /// Grows sideways only, so a box clamped to its line stays inside it.
  Rect widen(double d) => Rect.fromLTRB(left - d, top, right + d, bottom);
}

/// Draws [boxes] as the verse highlight: a light frame over a faint fill.
void paintVerseBoxes(
  Canvas canvas,
  Iterable<Rect> boxes,
  Color highlight, {
  required double stroke,
  required double radius,
}) {
  final fill = Paint()..color = highlight.withValues(alpha: highlight.a * 0.6);
  final edge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..color = highlight.withValues(alpha: (highlight.a * 3.2).clamp(0, 0.85));
  for (final b in boxes) {
    final r = RRect.fromRectAndRadius(b, Radius.circular(radius));
    canvas
      ..drawRRect(r, fill)
      ..drawRRect(r, edge);
  }
}

/// A round drag handle, like a text selection handle.
class SelectionHandle extends StatelessWidget {
  const SelectionHandle({
    super.key,
    required this.start,
    required this.onDrag,
    required this.label,
  });

  static const size = 26.0;

  final bool start;
  final ValueChanged<Offset> onDrag;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    return Semantics(
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => onDrag(d.globalPosition),
        child: SizedBox(
          width: size + 18,
          height: size + 18,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: t.control,
                shape: BoxShape.circle,
                border: Border.all(color: t.onControl, width: 3),
                boxShadow: const [
                  BoxShadow(blurRadius: 4, color: Color(0x44000000)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints highlight rectangles/paths and coloured rings on marked markers.
class SelectionPainter extends CustomPainter {
  SelectionPainter({
    required this.paths,
    required this.rings,
    required this.highlight,
    required this.transform,
  });

  final List<Path> paths;

  /// Marker centre and radius (page units) with the mark colour.
  final List<(Offset, double, Color)> rings;
  final Color highlight;

  /// From page units to widget pixels.
  final Matrix4 transform;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.transform(transform.storage);
    final fill = Paint()..color = highlight;
    for (final p in paths) {
      canvas.drawPath(p, fill);
    }
    for (final (c, r, color) in rings) {
      canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: 0.35));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.22
          ..color = color,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SelectionPainter old) => true;
}

/// Rosette images for the optional marker shapes.
final markerImagesProvider = FutureProvider<Map<MarkerStyle, ui.Image>>((
  ref,
) async {
  Future<ui.Image> load(String name) async {
    final data = await rootBundle.load('assets/ornaments/$name');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }

  return {
    MarkerStyle.rosette7: await load('marker_7.png'),
    MarkerStyle.rosette9: await load('marker_9.png'),
    MarkerStyle.rosette16: await load('marker_16.png'),
  };
});

/// How verse-end markers are drawn on a page.
class MarkerLook {
  const MarkerLook({
    required this.style,
    required this.image,
    required this.tint,
    required this.paper,
    required this.ink,
    this.art,
    this.artTint,
  });

  /// The shape drawn: [MarkerStyle.theme] only with [art].
  final MarkerStyle style;

  /// The rosette for [style]; null for the traditional marker.
  final ui.Image? image;

  /// The theme's marker, coloured for the mode (style [MarkerStyle.theme]).
  final ArtPiece? art;
  final Color? tint;
  final Color paper;
  final Color ink;

  /// The theme's [ModeTokens.artTint]: the rosettes recoloured to match its
  /// frame, or their own colours when null.
  final (Color, Color)? artTint;

  /// Paper over the printed marker at [c] (radius [r]: half its box's
  /// shorter side). The printed marker reaches its box's sides (the 1405
  /// marker's side ornaments, the Shamarly ring), so where its box is
  /// wider than tall (a page stretched across) a circle leaves their ends
  /// showing beside the new marker: the box's own oval, kept inside the
  /// box so the words around keep their ink, covers them.
  void _cover(Canvas canvas, Offset c, double r, Rect? printed) {
    final paint = Paint()..color = paper;
    canvas.drawCircle(c, r * 1.12, paint);
    if (printed == null) return;
    canvas
      ..save()
      ..clipRect(printed.inflate(printed.shortestSide * 0.04))
      ..drawOval(
        Rect.fromCenter(
          center: printed.center,
          width: printed.width * 1.12,
          height: printed.height * 1.12,
        ),
        paint,
      )
      ..restore();
  }

  /// Under the page ink: a tint that shows inside the printed marker.
  void paintUnder(Canvas canvas, Offset c, double r) {
    if (tint == null || image != null || art != null) return;
    canvas.drawCircle(
      c,
      r * 0.95,
      Paint()..color = tint!.withValues(alpha: 0.45),
    );
  }

  /// Over the page ink: a rosette with the verse number, covering the
  /// printed marker.
  /// [marked] fills the centre with a mark's colour. [printed] is the
  /// printed marker's box on screen, where the page image has one.
  void paintOver(
    Canvas canvas,
    Offset c,
    double r,
    int number, {
    Color? marked,
    Rect? printed,
  }) {
    final art = this.art;
    if (art != null) {
      // The printed marker goes under the paper (the new edition leaves it
      // out; the page images have it), then the theme's marker with the
      // number in its number box.
      _cover(canvas, c, r, printed);
      paintArtMarker(
        canvas,
        art,
        markerBox(c, r, art.size),
        number: number,
        digits: ink,
        fill: marked ?? tint,
      );
      return;
    }
    final img = image;
    if (img == null) return;
    _cover(canvas, c, r, printed);
    final size = r * 2.7;
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromCenter(center: c, width: size, height: size),
      Paint()
        ..filterQuality = FilterQuality.medium
        ..colorFilter = artTint == null ? null : duotoneFilter(artTint!),
    );
    final fill = marked ?? tint;
    canvas.drawCircle(c, r * 0.86, Paint()..color = fill ?? paper);
    canvas.drawCircle(
      c,
      r * 0.86,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.1
        ..color = artTint?.$1 ?? const Color(0xFF1C2F45),
    );
    final digits = number
        .toString()
        .split('')
        .map((d) => String.fromCharCode(0x0660 + int.parse(d)))
        .join();
    final fontSize =
        r *
        (number < 10
            ? 1.15
            : number < 100
            ? 1.0
            : 0.78);
    final tp = TextPainter(
      text: TextSpan(
        text: digits,
        style: TextStyle(
          fontFamily: 'UthmanTahaNaskh',
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          height: 1,
          color: fill == null ? ink : const Color(0xFFFFFFFF),
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    // Uthman Taha Naskh digits rise 0.515 em above the baseline and do not
    // descend: centre that ink box, not the line box.
    final baseline = tp.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    tp.paint(
      canvas,
      Offset(c.dx - tp.width / 2, c.dy - baseline + 0.2575 * fontSize),
    );
  }
}
