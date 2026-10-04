import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// The smallest box (in pixels) that holds every pixel that differs between
/// two RGBA captures of the same size, or null when they are identical.
///
/// A verse's image is cut from the page the reader sees, so where the
/// verses lie is found without asking each edition's drawing code: the page
/// is captured with the selection and without it, and what changed is the
/// selection.
Rect? changedBounds(Uint8List a, Uint8List b, int width, int height) {
  assert(a.length == b.length && a.length == width * height * 4);
  var left = width, top = height, right = -1, bottom = -1;
  for (var y = 0; y < height; y++) {
    final row = y * width * 4;
    for (var x = 0; x < width; x++) {
      final i = row + x * 4;
      if (a[i] != b[i] ||
          a[i + 1] != b[i + 1] ||
          a[i + 2] != b[i + 2] ||
          a[i + 3] != b[i + 3]) {
        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
      }
    }
  }
  if (right < 0) return null;
  return Rect.fromLTRB(
    left.toDouble(),
    top.toDouble(),
    right + 1.0,
    bottom + 1.0,
  );
}

/// [clean] cut to [box] (pixels) plus [pad] on every side, drawn on [paper].
/// No footer, no frame: a piece of the mushaf page.
Future<ui.Image> cropOnPaper(
  ui.Image clean,
  Rect box,
  Color paper, {
  double pad = 16,
}) async {
  final src = Rect.fromLTRB(
    (box.left - pad).clamp(0, clean.width.toDouble()),
    (box.top - pad).clamp(0, clean.height.toDouble()),
    (box.right + pad).clamp(0, clean.width.toDouble()),
    (box.bottom + pad).clamp(0, clean.height.toDouble()),
  );
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final dst = Offset.zero & src.size;
  canvas
    ..drawRect(dst, Paint()..color = paper)
    ..drawImageRect(
      clean,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );
  return recorder.endRecording().toImage(src.width.round(), src.height.round());
}

/// Draws the page under [key] twice, once as it is and once after [clean]
/// has run (it clears the selection and waits for the frame), and returns
/// the page's picture cut to the selection, as a PNG file in the temporary
/// directory. Null when nothing was selected on the page.
Future<File?> captureSelectionImage({
  required GlobalKey key,
  required Color paper,
  required Future<void> Function() clean,
  required Future<void> Function() restore,
  double pixelRatio = 3,
  Directory? into,
}) async {
  RenderRepaintBoundary? boundary() =>
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

  Future<(ui.Image, Uint8List)?> grab() async {
    final b = boundary();
    if (b == null) return null;
    final image = await b.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytes == null) {
      image.dispose();
      return null;
    }
    return (image, bytes.buffer.asUint8List());
  }

  final withSelection = await grab();
  if (withSelection == null) return null;
  ui.Image? without;
  try {
    await clean();
    final g = await grab();
    if (g == null) return null;
    without = g.$1;
    final (selected, selectedBytes) = withSelection;
    if (selected.width != without.width || selected.height != without.height) {
      return null;
    }
    final box = changedBounds(
      selectedBytes,
      g.$2,
      selected.width,
      selected.height,
    );
    if (box == null) return null;
    final cut = await cropOnPaper(without, box, paper, pad: 4 * pixelRatio);
    final png = await cut.toByteData(format: ui.ImageByteFormat.png);
    cut.dispose();
    if (png == null) return null;
    final dir = into ?? await getTemporaryDirectory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}tibyan_verses_'
      '${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(png.buffer.asUint8List(), flush: true);
    return file;
  } finally {
    withSelection.$1.dispose();
    without?.dispose();
    await restore();
  }
}
