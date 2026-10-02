import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/hifz/domain/recitation_test.dart';
import 'package:tibyan/features/hifz/domain/strength.dart';

void main() {
  const a = (surah: 2, ayah: 1);
  const b = (surah: 2, ayah: 2);
  const c = (surah: 2, ayah: 3);
  Rect r(double x) => Rect.fromLTWH(x, 0, 10, 10);
  final units = {
    a: RevealUnits([
      [r(0)],
    ], byWord: true),
    b: RevealUnits([
      [r(10)],
      [r(20), r(21)],
      [r(30)],
    ], byWord: true),
    // No word boxes: two lines.
    c: RevealUnits([
      [r(40)],
      [r(50)],
    ], byWord: false),
  };
  final order = [a, b, c];

  test('next word walks the page in reading order', () {
    final t = RecitationTest();
    expect(t.covers(order, units).hidden, {a, b, c});
    expect(t.revealNext(order, units), a);
    expect(t.covers(order, units).hidden, {b, c});
    expect(t.revealNext(order, units), b);
    var covers = t.covers(order, units);
    // The second word's two glyph boxes and the third word stay covered.
    expect(covers.pieces[b], [r(20), r(21), r(30)]);
    t.revealNext(order, units);
    t.revealNext(order, units);
    expect(t.isRevealed(b, units[b]), isTrue);
    expect(t.current, b);
    // Then line by line.
    t.revealNext(order, units);
    covers = t.covers(order, units);
    expect(covers.pieces[c], [r(50)]);
    t.revealNext(order, units);
    expect(t.revealNext(order, units), isNull);
    expect(t.covers(order, units).hidden, isEmpty);
  });

  test('tapping a covered verse reveals its next piece', () {
    final t = RecitationTest();
    t.revealPiece(c, units[c]);
    expect(t.current, c);
    expect(t.shown(c), 1);
    expect(t.covers(order, units).hidden, {a, b, c});
  });

  test('a verse without known pieces is one piece', () {
    final t = RecitationTest();
    const d = (surah: 2, ayah: 4);
    expect(t.covers([d], const {}).hidden, {d});
    expect(t.covers([d], const {}).pieces, isEmpty);
    t.revealNext([d], const {});
    expect(t.covers([d], const {}).hidden, isEmpty);
  });

  test('judging a verse reveals it and moves on; results survive pages', () {
    final t = RecitationTest();
    t.revealNext(order, units);
    t.grade(b, VerseResult.missed, order, units);
    expect(t.isRevealed(b, units[b]), isTrue);
    expect(t.current, c);
    t.grade(c, VerseResult.remembered, order, units);
    expect(t.current, isNull);
    t.newPage();
    expect(t.shown(b), 0);
    expect(t.results, {b: VerseResult.missed, c: VerseResult.remembered});
  });

  test('next verse and all', () {
    final t = RecitationTest();
    t.revealNext(order, units); // a fully
    expect(t.revealNextVerse(order, units), b);
    expect(t.covers(order, units).hidden, {c});
    t.revealAll(order, units);
    expect(t.covers(order, units).hidden, isEmpty);
  });
}
