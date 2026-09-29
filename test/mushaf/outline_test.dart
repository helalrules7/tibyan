import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/mushaf_page.dart';

void main() {
  test('parses a two-part verse outline and hit-tests it', () {
    final path = parseOutline(
      'M 0.0 74.75 L 114.88 74.75 L 114.88 112.75 L 0.0 112.75 Z '
      'M 25.88 112.75 L 342.5 112.75 L 342.5 149.75 L 25.88 149.75 Z',
    );
    expect(path.contains(const Offset(50, 90)), isTrue);
    expect(path.contains(const Offset(300, 130)), isTrue);
    expect(path.contains(const Offset(300, 90)), isFalse);
  });

  test('printed verse markers can be removed from a page', () {
    const svg =
        '<svg><g><g id="ayah_markers"><g class="ayah-mark"><path d="M0 0"/></g></g>'
        '<g id="content"><path d="M1 1"/></g></g></svg>';
    final out = withoutMarkers(svg);
    expect(out.contains('ayah_markers'), isFalse);
    expect(out.contains('<g id="content"><path d="M1 1"/></g>'), isTrue);
    expect(withoutMarkers('<svg></svg>'), '<svg></svg>');
  });

  test('outlines stored as point lists (pages 1 and 2) are read', () {
    const d = '181.08,18.31 57.54,18.31 57.54,48.94 181.08,48.94';
    final path = parseOutline(d);
    expect(path.contains(const Offset(100, 30)), isTrue);
    expect(path.contains(const Offset(200, 30)), isFalse);
    final rects = outlineRects(d);
    final r = rects.single;
    expect(r.left, closeTo(57.54, 0.01));
    expect(r.top, closeTo(18.31, 0.01));
    expect(r.right, closeTo(181.08, 0.01));
    expect(r.bottom, closeTo(48.94, 0.01));
  });
}
