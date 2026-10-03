import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/word_study/word_pick.dart';

void main() {
  // Two words of 1:1 side by side (right to left) and one of 1:2 below.
  final boxes = <(int, int, int), List<Rect>>{
    (1, 1, 1): [const Rect.fromLTRB(80, 0, 100, 10)],
    (1, 1, 2): [const Rect.fromLTRB(58, 0, 78, 10)],
    (1, 2, 1): [
      const Rect.fromLTRB(80, 12, 90, 22),
      const Rect.fromLTRB(91, 12, 100, 22),
    ],
  };

  test('the box under the point', () {
    expect(wordUnder(boxes, const Offset(90, 5)), (1, 1, 1));
    expect(wordUnder(boxes, const Offset(60, 5)), (1, 1, 2));
    // A word drawn as several pieces.
    expect(wordUnder(boxes, const Offset(95, 15)), (1, 2, 1));
  });

  test('the gap between words needs slop, and the nearest centre wins', () {
    expect(wordUnder(boxes, const Offset(79, 5)), isNull);
    expect(wordUnder(boxes, const Offset(79.4, 5), slop: 2), (1, 1, 1));
    expect(wordUnder(boxes, const Offset(20, 5), slop: 2), isNull);
  });

  test('a known verse limits the choice to its words', () {
    expect(
      wordUnder(
        boxes,
        const Offset(85, 11),
        verse: (surah: 1, ayah: 2),
        slop: 2,
      ),
      (1, 2, 1),
    );
    expect(
      wordUnder(
        boxes,
        const Offset(85, 11),
        verse: (surah: 1, ayah: 1),
        slop: 2,
      ),
      (1, 1, 1),
    );
  });
}
