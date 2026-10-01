import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Draws a frame once into an image, then blits it.
///
/// A frame is the same around every page: its ornament pieces are vector
/// pictures and its band is dozens of image tiles, and the raster thread
/// pays for all of that again on every frame of a page turn — three pages
/// are alive in the view, so a turn redrew the whole ornament six times a
/// frame. It is drawn once per size, theme and mode here, and every page
/// blits the one image.
class RasterFrame extends StatefulWidget {
  const RasterFrame({super.key, required this.painter, required this.cache});

  /// The frame's painter, with the art it needs.
  final CustomPainter painter;

  /// Everything the drawing depends on, as a string: a change redraws.
  final String cache;

  @override
  State<RasterFrame> createState() => _RasterFrameState();
}

class _RasterFrameState extends State<RasterFrame> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        if (size.isEmpty) return const SizedBox.shrink();
        final key =
            '${widget.cache}|${size.width.round()}x${size.height.round()}'
            '|${MediaQuery.devicePixelRatioOf(context)}';
        final image = _drawn[key];
        if (image != null) return CustomPaint(painter: _Blit(image));
        _draw(key, size, MediaQuery.devicePixelRatioOf(context));
        // Drawn the slow way until the image is ready.
        return CustomPaint(painter: widget.painter);
      },
    );
  }

  void _draw(String key, Size size, double dpr) {
    if (_pending.contains(key)) return;
    _pending.add(key);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final recorder = ui.PictureRecorder();
      widget.painter.paint(Canvas(recorder)..scale(dpr), size);
      final picture = recorder.endRecording();
      ui.Image? image;
      try {
        image = await picture.toImage(
          (size.width * dpr).ceil(),
          (size.height * dpr).ceil(),
        );
      } finally {
        picture.dispose();
      }
      _pending.remove(key);
      if (!mounted) {
        image.dispose();
        return;
      }
      // Two frames of ornament are enough to turn between.
      while (_order.length >= _keep) {
        final gone = _order.removeAt(0);
        _drawn.remove(gone)?.dispose();
      }
      _drawn[key] = image;
      _order.add(key);
      setState(() {});
    });
  }

  /// How many drawn frames to keep.
  static const _keep = 2;
  static final _drawn = <String, ui.Image>{};
  static final _order = <String>[];
  static final _pending = <String>{};
}

class _Blit extends CustomPainter {
  _Blit(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(_Blit old) => old.image != image;
}
