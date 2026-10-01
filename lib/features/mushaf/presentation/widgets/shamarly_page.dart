import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../../core/db/content_database.dart';
import '../../mushaf_providers.dart';
import 'image_page.dart';
import 'page_interaction.dart';

/// The Shamarly page images: 886 x 1377 px. Pages 4..522 are black ink
/// (and coloured surah frames) on transparent paper; the cover (1) and the
/// two ornate opening pages (2, 3) are opaque scans.
const _image = Rect.fromLTRB(0, 0, 886, 1377);

/// The text of the two ornate opening pages (2 and 3), inside their printed
/// frame and surah panels: the app's own frame replaces those.
const _openingText = Rect.fromLTRB(95, 325, 791, 1060);

/// A line's centre sits this many pitches above its baseline, in the
/// middle of its letters.
const _lift = 0.2;

/// How far the ink of the first and last lines reaches beyond their
/// centres, over pages 4..522 (image px, measured on the page images'
/// alpha: 102.0 above on page 105, 88.2 below on page 499).
const _inkAbove = 103.0;
const _inkBelow = 89.0;

/// Room a Shamarly text page keeps above its first line and below its
/// last at [size], so the frame can put its banners on the same slots.
EdgeInsets shamarlyLinePadding(Size size) => stripPadding(
  size,
  ink: _image,
  lines: 15,
  inkAbove: _inkAbove,
  inkBelow: _inkBelow,
);

/// Line geometry of a Shamarly page from content.db (tools/build_shamarly.py).
/// Text pages have 15 line slots on a fitted baseline grid; a surah header
/// takes two slots and is centred between them. The margin marks lie at
/// the page edges, so the whole image width is kept.
PageGeometry shamarlyGeometry(
  ShamarlyPageRow page,
  List<ShamarlyLineRow> lines, {
  List<ShamarlyHeaderRow> headers = const [],
  Map<int, List<Rect>> overflow = const {},
}) {
  final top = page.gridTop, pitch = page.pitch;
  if (lines.isEmpty || top == null || pitch == null) {
    // The cover: no lines.
    return PageGeometry(
      ink: _image,
      whole: true,
      centres: [_image.center.dy],
      slots: const [0],
      bandTops: [_image.top],
      bandBottoms: [_image.bottom],
      boxHalfHeight: _image.height / 2,
    );
  }
  final firstOfHeader = {
    for (final h in headers)
      if (h.firstLine != null) h.firstLine!,
  };
  double slot(int j) => firstOfHeader.contains(j)
      ? j + 0.5
      : firstOfHeader.contains(j - 1)
      ? j - 0.5
      : j.toDouble();
  final n = lines.length;
  final opening = page.kind == 'ornate';
  return PageGeometry(
    ink: opening ? _openingText : _image,
    whole: page.kind != 'text',
    centres: [for (var j = 0; j < n; j++) top + (slot(j) - _lift) * pitch],
    slots: [for (var j = 0; j < n; j++) slot(j)],
    bandTops: [
      for (var j = 0; j < n; j++) j == 0 ? _image.top : lines[j].y0.toDouble(),
    ],
    bandBottoms: [
      for (var j = 0; j < n; j++)
        j == n - 1 ? _image.bottom : lines[j].y1.toDouble(),
    ],
    overflow: overflow,
    inkAbove: _inkAbove,
    inkBelow: _inkBelow,
    boxHalfHeight: pitch * 0.42,
  );
}

/// One page of the Shamarly (Egyptian) edition: the page image (unchanged),
/// coloured for the current mode, with the verses highlighted from their
/// boxes (one per verse per line).
class ShamarlyMushafPage extends StatelessWidget {
  const ShamarlyMushafPage({
    super.key,
    required this.page,
    required this.interaction,
  });

  final int page;
  final PageInteraction interaction;

  @override
  Widget build(BuildContext context) => ImageMushafPage(
    page: page,
    interaction: interaction,
    load: _loadShamarlyPage,
  );
}

Rect _rect(int x0, int y0, int x1, int y1) =>
    Rect.fromLTRB(x0.toDouble(), y0.toDouble(), x1.toDouble(), y1.toDouble());

Future<ImagePageData> _loadShamarlyPage(WidgetRef ref, int page) async {
  final dir = ref.read(pageInstallerProvider).dir;
  final file = File(p.join(dir.path, '${page.toString().padLeft(3, '0')}.png'));
  final repo = ref.read(mushafRepositoryProvider);
  // The page's image, its lines and its boxes come from different places
  // and none of them depends on another: asking for all of them together
  // leaves one wait instead of six, on every page opened.
  final decode = () async {
    final codec = await ui.instantiateImageCodec(await file.readAsBytes());
    return (await codec.getNextFrame()).image;
  }();
  final geometry = (
    repo.shamarlyPage(page),
    repo.shamarlyOverflow(page),
    repo.shamarlyVerseBoxes(page),
    repo.shamarlyLines(page),
    repo.shamarlyHeaders(page),
    repo.shamarlyMarkers(page),
  ).wait;
  final (image, (row, overflowRows, boxes, lines, headers, markerRows)) =
      await (decode, geometry).wait;
  if (row == null) throw StateError('No Shamarly page $page');
  final overflow = <int, List<Rect>>{};
  for (final o in overflowRows) {
    overflow.putIfAbsent(o.line, () => []).add(_rect(o.x0, o.y0, o.x1, o.y1));
  }
  return ImagePageData(
    image: image,
    geometry: shamarlyGeometry(
      row,
      lines,
      headers: headers,
      overflow: overflow,
    ),
    pieces: [
      for (final b in boxes)
        ((surah: b.surah, ayah: b.ayah), _rect(b.x0, b.y0, b.x1, b.y1)),
    ],
    pieceLines: [for (final b in boxes) b.line],
    markers: {
      for (final m in markerRows)
        (surah: m.surah, ayah: m.ayah): _rect(m.x0, m.y0, m.x1, m.y1),
    },
    alphaInk: row.kind == 'text',
  );
}
