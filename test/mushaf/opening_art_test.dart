import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/opening_art.dart';

void main() {
  group('the opening frame made taller', () {
    for (final room in const [
      Size(382, 700), // phone
      Size(352, 520), // small phone
      Size(812, 1050), // tablet, portrait
    ]) {
      test('$room: inside the room, taller, the art undistorted', () {
        final g = OpeningArtGeometry.fit(room);
        // The whole frame is inside the room — nothing runs off an edge —
        // and as wide as it.
        expect(g.frame.width, closeTo(room.width, 0.01));
        expect(g.frame.left, closeTo(0, 0.01));
        expect(g.frame.height, lessThanOrEqualTo(room.height + 0.01));
        expect(g.frame.top, greaterThanOrEqualTo(-0.01));
        // The band copies are stretched by 8% at most.
        expect((g.stretch - 1).abs(), lessThanOrEqualTo(0.08 + 1e-9));
        // Slices follow one another with no gap and no overlap, and the
        // art's two ends keep their own scale (width / height as drawn).
        final slices = g.slices();
        expect(slices.first.$2.top, closeTo(g.frame.top, 0.01));
        expect(slices.last.$2.bottom, closeTo(g.frame.bottom, 0.01));
        for (var i = 1; i < slices.length; i++) {
          expect(slices[i].$2.top, closeTo(slices[i - 1].$2.bottom, 0.01));
        }
        for (final s in [slices.first, slices.last]) {
          expect(
            s.$2.width / s.$2.height,
            closeTo(s.$1.width / s.$1.height, 1e-6),
          );
        }
        // Every middle slice is the one repeated band.
        for (final s in slices.sublist(1, slices.length - 1)) {
          expect(s.$1, const Rect.fromLTRB(0, 493, 1200, 750));
        }
        expect(slices.length, g.repeats + 3);
      });
    }

    test('a phone gets more of its height than the plain picture gave', () {
      const room = Size(382, 700);
      final plain = 1457 * room.width / 1200;
      final g = OpeningArtGeometry.fit(room);
      expect(g.frame.height, greaterThan(plain + 100));
      // What is left over is less than one band.
      expect(room.height - g.frame.height, lessThan(257 * g.scale));
    });

    test('nothing is cropped: the whole drawing, its panel in proportion', () {
      for (final room in const [
        Size(385, 760), // iPhone 6.1"
        Size(422, 840), // iPhone 6.7"
        Size(367, 575), // iPhone SE
        Size(404, 823), // Android
        Size(712, 808), // laptop, one page of a spread
        Size(1432, 808), // laptop, a single page
      ]) {
        final g = OpeningArtGeometry.fit(room);
        expect(g.frame.left, greaterThanOrEqualTo(-0.01), reason: '$room');
        expect(g.frame.right, lessThanOrEqualTo(room.width + 0.01));
        expect(g.frame.top, greaterThanOrEqualTo(-0.01));
        expect(g.frame.bottom, lessThanOrEqualTo(room.height + 0.01));
        // All of the drawing's width is drawn, at one scale.
        expect(g.frame.width / g.scale, closeTo(1200, 0.01));
        final panel = g.place(OpeningArtLayout.panel);
        expect(
          panel.width,
          closeTo(OpeningArtLayout.panel.width * g.scale, 1e-6),
        );
        // The cartouches and the panel are on screen.
        for (final r in [
          OpeningArtLayout.top,
          OpeningArtLayout.bottom,
          OpeningArtLayout.panel,
        ]) {
          final placed = g.place(r);
          expect(placed.left, greaterThanOrEqualTo(-0.01));
          expect(placed.right, lessThanOrEqualTo(room.width + 0.01));
          expect(placed.top, greaterThanOrEqualTo(-0.01));
          expect(placed.bottom, lessThanOrEqualTo(room.height + 0.01));
        }
      }
    });

    test(
      'the panel and the lower cartouche move down with the extra height',
      () {
        final g = OpeningArtGeometry.fit(const Size(382, 700));
        final panel = g.place(OpeningArtLayout.panel);
        final bottom = g.place(OpeningArtLayout.bottom);
        final top = g.place(OpeningArtLayout.top);
        expect(
          top.height,
          closeTo(OpeningArtLayout.top.height * g.scale, 1e-6),
        );
        expect(
          bottom.height,
          closeTo(OpeningArtLayout.bottom.height * g.scale, 1e-6),
        );
        expect(
          panel.width,
          closeTo(OpeningArtLayout.panel.width * g.scale, 1e-6),
        );
        expect(
          panel.height,
          greaterThan(OpeningArtLayout.panel.height * g.scale),
        );
        expect(bottom.top, greaterThan(panel.bottom));
      },
    );

    test('a wide room fits the height, unchanged', () {
      final g = OpeningArtGeometry.fit(const Size(1000, 600));
      expect(g.repeats, 0);
      expect(g.stretch, 1);
      expect(g.frame.height, closeTo(600, 0.01));
      expect(g.frame.width, closeTo(600 * 1200 / 1457, 0.01));
    });
  });
}
