import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../../core/db/ayahinfo_database.dart';
import '../../mushaf_providers.dart';
import 'image_page.dart';
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

/// How far the ink of the first and last lines reaches beyond their
/// centres, over all 604 pages (image px; tools/measure_line_extents.py).
const _inkAbove = 55.1;
const _inkBelow = 83.1;

/// The 15 lines of an old-edition page: centres on the regular grid,
/// bands between the [cuts] (the rows with least ink, so marks above and
/// below a line stay with it), or the grid when a page has none.
PageGeometry oldEditionGeometry({
  required bool opening,
  List<double> cuts = const [],
  Map<int, List<Rect>> overflow = const {},
}) {
  final ink = opening ? _openingInk : _ink;
  final hasCuts = cuts.length == _lineCount - 1;
  return PageGeometry(
    ink: ink,
    inkWithoutHeader: opening ? _openingBody : null,
    whole: opening,
    centres: [
      for (var j = 0; j < _lineCount; j++) _gridTop + (j + 0.5) * _pitch,
    ],
    slots: [for (var j = 0; j < _lineCount; j++) j.toDouble()],
    bandTops: [
      for (var j = 0; j < _lineCount; j++)
        j == 0 ? ink.top : (hasCuts ? cuts[j - 1] : _gridTop + j * _pitch),
    ],
    bandBottoms: [
      for (var j = 0; j < _lineCount; j++)
        j == _lineCount - 1
            ? ink.bottom
            : (hasCuts ? cuts[j] : _gridTop + (j + 1) * _pitch),
    ],
    overflow: overflow,
    inkAbove: _inkAbove,
    inkBelow: _inkBelow,
    boxHalfHeight: _pitch * 0.42,
  );
}

/// One page of the old Madina edition (1405H): the page image (unchanged),
/// coloured for the current mode, with the selected verse highlighted
/// from its glyph boxes.
class OldMushafPage extends StatelessWidget {
  const OldMushafPage({
    super.key,
    required this.page,
    required this.interaction,
  });

  final int page;
  final PageInteraction interaction;

  @override
  Widget build(BuildContext context) =>
      ImageMushafPage(page: page, interaction: interaction, load: _loadOldPage);
}

Future<ImagePageData> _loadOldPage(WidgetRef ref, int page) async {
  final dir = ref.read(pageInstallerProvider).dir;
  final file = File(
    p.join(dir.path, 'p${page.toString().padLeft(3, '0')}.png'),
  );
  final repo = ref.read(mushafRepositoryProvider);
  // The image, the glyph boxes and the cuts come from different places and
  // none depends on another: together, they cost one wait instead of four.
  final decode = () async {
    final codec = await ui.instantiateImageCodec(await file.readAsBytes());
    return (await codec.getNextFrame()).image;
  }();
  final geometry = (
    ref.read(ayahInfoDatabaseProvider)?.page(page) ??
        Future.value(const <GlyphRow>[]),
    repo.lineCuts('madina1405', page),
    repo.oldLineOverflow(page),
  ).wait;
  final (image, (glyphRows, cuts, overflowRows)) =
      await (decode, geometry).wait;
  final glyphs = [...glyphRows]..sort((a, b) => a.glyphId.compareTo(b.glyphId));
  final overflow = <int, List<Rect>>{};
  for (final o in overflowRows) {
    overflow
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
  Rect rect(GlyphRow g) => Rect.fromLTRB(
    g.minX.toDouble(),
    g.minY.toDouble(),
    g.maxX.toDouble(),
    g.maxY.toDouble(),
  );
  // The verse-end marker is the last glyph of each verse on the page.
  final markers = <VerseKey, GlyphRow>{};
  for (final g in glyphs) {
    final k = (surah: g.suraNumber, ayah: g.ayahNumber);
    final m = markers[k];
    if (m == null || g.position > m.position) markers[k] = g;
  }
  return ImagePageData(
    image: image,
    geometry: oldEditionGeometry(
      opening: page <= 2,
      cuts: cuts,
      overflow: overflow,
    ),
    pieces: [
      for (final g in glyphs)
        ((surah: g.suraNumber, ayah: g.ayahNumber), rect(g)),
    ],
    markers: {for (final e in markers.entries) e.key: rect(e.value)},
    hitSlop: 6,
    pieceLines: [for (final g in glyphs) g.lineNumber],
    rowReach: 0,
  );
}
