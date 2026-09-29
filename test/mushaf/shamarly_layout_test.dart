import 'dart:io';
import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/image_page.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/shamarly_page.dart';

/// Layout math of the Shamarly pages, against the bundled geometry.
void main() {
  late ContentDatabase db;
  late MushafRepository repo;

  setUpAll(() {
    db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
    repo = MushafRepository(db);
  });
  tearDownAll(() => db.close());

  Future<PageGeometry> geometry(int page) async {
    final overflow = <int, List<Rect>>{};
    for (final o in await repo.shamarlyOverflow(page)) {
      overflow
          .putIfAbsent(o.line, () => [])
          .add(
            Rect.fromLTRB(
              o.x0.toDouble(),
              o.y0.toDouble(),
              o.x1.toDouble(),
              o.y1.toDouble(),
            ),
          );
    }
    return shamarlyGeometry(
      (await repo.shamarlyPage(page))!,
      await repo.shamarlyLines(page),
      headers: await repo.shamarlyHeaders(page),
      overflow: overflow,
    );
  }

  const phone = Size(360, 700);

  test('text pages are drawn in strips; screen and image agree', () async {
    final g = await geometry(42);
    final layout = StripLayout(phone, g);
    expect(layout.strips, isTrue);
    expect(layout.scale, closeTo(360 / 886, 1e-9));
    for (final b in await repo.shamarlyVerseBoxes(42)) {
      final c = Rect.fromLTRB(
        b.x0.toDouble(),
        b.y0.toDouble(),
        b.x1.toDouble(),
        b.y1.toDouble(),
      ).center;
      expect(layout.lineOfImageY(c.dy), b.line);
      final back = layout.toImage(layout.toScreen(c));
      expect(back.dx, closeTo(c.dx, 1e-6));
      expect(back.dy, closeTo(c.dy, 1e-6));
    }
  });

  test('a surah header is centred across its two slots', () async {
    final g = await geometry(42); // 3 (Al Imran): header on lines 6 and 7
    expect(g.slots[6], 6.5);
    expect(g.slots[7], 6.5);
    expect(g.slots[8], 8);
    expect(g.centres[6], g.centres[7]);
    final pad = shamarlyLinePadding(phone);
    final slot = (phone.height - pad.vertical) / 15;
    final layout = StripLayout(phone, g);
    // Its centre lands on the boundary between the two slots, where the
    // frame's banner (two slots high) is centred too.
    final y = layout.toScreen(Offset(443, g.centres[6]), line: 6).dy;
    expect(y, closeTo(pad.top + 7 * slot, 1e-6));
    // Ordinary lines sit in the middle of their slot.
    final y9 = layout.toScreen(Offset(443, g.centres[9]), line: 9).dy;
    expect(y9, closeTo(pad.top + 9.5 * slot, 1e-6));
  });

  test('no page puts ink off the screen', () async {
    for (final size in const [phone, Size(412, 915), Size(320, 480)]) {
      for (var page = 4; page <= 522; page++) {
        final g = await geometry(page);
        final lines = await repo.shamarlyLines(page);
        final headers = {
          for (final h in await repo.shamarlyHeaders(page))
            if (h.firstLine != null) h.firstLine!: h,
        };
        final layout = StripLayout(size, g);
        if (!layout.strips) continue;
        // Ink top of the first line and bottom of the last (a header's
        // frame when the page opens or ends with one).
        final top = headers[0]?.y0 ?? lines.first.y0;
        final bottom = headers[13]?.y1 ?? lines.last.y1;
        final last = lines.length - 1;
        expect(
          layout.toScreen(Offset(0, top.toDouble()), line: 0).dy,
          greaterThanOrEqualTo(-0.5),
          reason: 'page $page top at $size',
        );
        expect(
          layout.toScreen(Offset(0, bottom.toDouble()), line: last).dy,
          lessThanOrEqualTo(size.height + 0.5),
          reason: 'page $page bottom at $size',
        );
      }
    }
  });

  test('highlight: one framed box per line of a verse', () async {
    final g = await geometry(36); // Ayat al-Kursi
    final layout = StripLayout(phone, g);
    final boxes = await repo.shamarlyVerseBoxes(36);
    final lines = {
      for (final b in boxes)
        if (b.surah == 2 && b.ayah == 255) b.line,
    };
    final frames = layout.frames([
      for (final b in boxes)
        if (b.surah == 2 && b.ayah == 255)
          Rect.fromLTRB(
            b.x0.toDouble(),
            b.y0.toDouble(),
            b.x1.toDouble(),
            b.y1.toDouble(),
          ),
    ]);
    expect(lines.length, greaterThan(1));
    expect(frames.length, lines.length);
    for (final f in frames) {
      expect(f.height, greaterThan(0));
    }
  });

  test('cover and opening pages are scaled whole', () async {
    for (final page in [1, 2, 3]) {
      final layout = StripLayout(phone, await geometry(page));
      expect(layout.strips, isFalse, reason: 'page $page');
      final p = layout.toScreen(const Offset(443, 700));
      final back = layout.toImage(p);
      expect(back.dx, closeTo(443, 1e-6));
      expect(back.dy, closeTo(700, 1e-6));
    }
  });
}
