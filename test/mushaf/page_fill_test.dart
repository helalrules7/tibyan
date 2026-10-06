import 'dart:ui';

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/features/audio/floating_player.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/image_page.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/mushaf_page.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/old_mushaf_page.dart';

/// Focus mode's ways of filling the room ([PageFill]) on a text page of
/// the new Madina edition (page units, its 345 x 550 view box), at the
/// five sizes of the screen tests, and the floating player kept on screen.
void main() {
  const viewBox = Rect.fromLTWH(0, 0, 345, 550);
  final g = svgLineGeometry(
    viewBox,
    const SvgPageGeometry(
      firstLine: 26.2,
      pitch: 35.75,
      cuts: [],
      overflow: [],
      polygons: [],
    ),
    opening: false,
  );
  // The room a page has in focus mode, phones held upright and a laptop's
  // spread (half the screen each).
  const rooms = {
    'iPhone 6.1"': Size(381, 749),
    'iPhone 6.7"': Size(418, 829),
    'iPhone SE': Size(363, 599),
    'Android': Size(400, 843),
    'laptop spread page': Size(708, 860),
  };

  void roundTrips(StripLayout l) {
    for (final p in const [
      Offset(20, 60),
      Offset(172, 275),
      Offset(330, 520),
    ]) {
      final back = l.toImage(l.toScreen(p, line: l.lineOfImageY(p.dy)));
      expect(back.dx, closeTo(p.dx, 0.01));
      if (!l.strips) expect(back.dy, closeTo(p.dy, 0.01));
    }
  }

  for (final MapEntry(key: name, value: room) in rooms.entries) {
    final upright = room.width / viewBox.width < room.height / viewBox.height;

    test('$name: spread lines fill the width, or the height', () {
      final l = StripLayout(room, g, fill: PageFill.lines);
      expect(l.strips, upright);
      expect(l.scaleX, l.scale, reason: 'no stretch');
      final drawn = Rect.fromPoints(
        l.toScreen(viewBox.topLeft, line: 0),
        l.toScreen(viewBox.bottomRight, line: 14),
      );
      if (upright) {
        expect(drawn.width, closeTo(room.width, 0.01));
      } else {
        expect(drawn.height, closeTo(room.height, 0.01));
      }
      roundTrips(l);
    });

    test('$name: a slight stretch widens a page fitted to the height', () {
      final l = StripLayout(room, g, fill: PageFill.stretch);
      if (upright) {
        expect(l.scaleX, l.scale);
      } else {
        expect(l.scaleX, greaterThan(l.scale));
        expect(
          l.scaleX,
          lessThanOrEqualTo(l.scale * (1 + StripLayout.maxStretch) + 1e-9),
        );
        expect(viewBox.width * l.scaleX, lessThanOrEqualTo(room.width + 0.01));
      }
      roundTrips(l);
    });

    test('$name: a full stretch fills the room on both axes', () {
      final l = StripLayout(room, g, fill: PageFill.full);
      expect(l.strips, isFalse);
      final drawn = Rect.fromPoints(
        l.toScreen(viewBox.topLeft),
        l.toScreen(viewBox.bottomRight),
      );
      expect(drawn.left, closeTo(0, 0.01));
      expect(drawn.top, closeTo(0, 0.01));
      expect(drawn.right, closeTo(room.width, 0.01));
      expect(drawn.bottom, closeTo(room.height, 0.01));
      roundTrips(l);
    });
  }

  test('the image editions take the same fills', () {
    final old = oldEditionGeometry(
      opening: false,
      ownInk: const Rect.fromLTRB(40, 20, 990, 1610),
    );
    const upright = Size(381, 749);
    const wide = Size(708, 860);
    // Upright: in strips, as wide as the room, whatever the stretch.
    for (final fill in [PageFill.lines, PageFill.stretch]) {
      final l = StripLayout(upright, old, stretch: true, fill: fill);
      expect(l.strips, isTrue);
      expect(l.ink.width * l.scale, closeTo(upright.width, 0.01));
    }
    // Fitted to the height: no stretch, then up to 12% wider.
    final lines = StripLayout(wide, old, stretch: true, fill: PageFill.lines);
    expect(lines.scaleX, lines.scale);
    final more = StripLayout(wide, old, stretch: true, fill: PageFill.stretch);
    expect(more.scaleX, greaterThan(more.scale));
    // Full: the page's own ink over the whole room.
    for (final room in [upright, wide]) {
      final l = StripLayout(room, old, stretch: true, fill: PageFill.full);
      final drawn = Rect.fromPoints(
        l.toScreen(l.ink.topLeft),
        l.toScreen(l.ink.bottomRight),
      );
      expect(drawn.size.width, closeTo(room.width, 0.01));
      expect(drawn.size.height, closeTo(room.height, 0.01));
      roundTrips(l);
    }
  });

  test('outside focus mode a page keeps its own layout', () {
    const wide = Size(708, 860);
    expect(StripLayout(wide, g).scaleX, StripLayout(wide, g).scale);
    final images = StripLayout(wide, g, stretch: true);
    expect(images.scaleX, greaterThan(images.scale));
  });

  test('an opening page is scaled whole, whatever the fill', () {
    final opening = svgLineGeometry(
      viewBox,
      const SvgPageGeometry(
        firstLine: 26.2,
        pitch: 35.75,
        cuts: [],
        overflow: [],
        polygons: [],
      ),
      opening: true,
    );
    for (final fill in PageFill.values) {
      final l = StripLayout(const Size(381, 749), opening, fill: fill);
      expect(l.strips, isFalse);
      expect(l.scaleX, l.scale, reason: '$fill');
    }
  });

  group('the floating player', () {
    const pill = Size(148, 48);
    const padding = EdgeInsets.only(top: 59, bottom: 34);

    test('sits where it was left', () {
      final at = FloatingPlayer.place(
        const Offset(0.5, 0.5),
        const Size(393, 852),
        padding,
        pill,
      );
      expect(at.dx + pill.width / 2, closeTo(196.5, 0.01));
      expect(at.dy + pill.height / 2, closeTo(426, 0.01));
    });

    test('is kept inside the screen, out of the notch', () {
      for (final size in const [Size(393, 852), Size(375, 667)]) {
        for (final f in const [Offset(-1, -1), Offset(2, 2), Offset(1, 0)]) {
          final at = FloatingPlayer.place(f, size, padding, pill);
          expect(at.dx, greaterThanOrEqualTo(0));
          expect(at.dx + pill.width, lessThanOrEqualTo(size.width));
          expect(at.dy, greaterThanOrEqualTo(padding.top));
          expect(
            at.dy + pill.height,
            lessThanOrEqualTo(size.height - padding.bottom),
          );
        }
      }
    });

    test('a smaller screen keeps it on screen', () {
      // Left at the bottom right of a laptop, then shown on a small phone.
      const big = Size(1440, 900);
      final there = FloatingPlayer.place(
        const Offset(0.98, 0.98),
        big,
        EdgeInsets.zero,
        pill,
      );
      final frac = Offset(
        (there.dx + pill.width / 2) / big.width,
        (there.dy + pill.height / 2) / big.height,
      );
      final small = FloatingPlayer.place(
        frac,
        const Size(375, 667),
        EdgeInsets.zero,
        pill,
      );
      expect(small.dx + pill.width, lessThanOrEqualTo(375));
      expect(small.dy + pill.height, lessThanOrEqualTo(667));
    });
  });
}
