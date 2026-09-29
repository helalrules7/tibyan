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
}
