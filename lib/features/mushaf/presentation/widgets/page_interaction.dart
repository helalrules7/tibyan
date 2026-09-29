import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'mushaf_page.dart';

/// What the reader can do on a page; shared by both editions.
class PageInteraction {
  const PageInteraction({
    required this.selection,
    required this.marks,
    required this.onTap,
    required this.onVerseLongPress,
    required this.onMarkerTap,
    required this.onHandleDrag,
  });

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
