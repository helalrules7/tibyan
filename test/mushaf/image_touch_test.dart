import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/ayahinfo_database.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/image_page.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/mushaf_page.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/old_mushaf_page.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/shamarly_page.dart';

/// A tall phone, whose pages are spread in strips, and a tablet, whose
/// pages are scaled whole.
const _sizes = [Size(393, 760), Size(820, 1180)];

/// Touch reading on the editions drawn from page images, against the real
/// geometry of every page: a touch anywhere over a line of text selects a
/// verse of that line, and a verse is highlighted on each of its lines.
///
/// [lineOf] is each piece's printed line (0-based, the geometry's line on
/// pages that follow the grid); [pieceLines] is what the page passes on.
List<String> _checkPage(
  StripLayout layout,
  List<(VerseKey, Rect)> pieces, {
  required List<int> lineOf,
  required List<int> pieceLines,
  required double slop,
}) {
  final failures = <String>[];
  final g = layout.g;
  final rects = [for (final (_, r) in pieces) r];
  final screen = [for (final r in rects) layout.toScreenRect(r)];
  int? at(Offset p) => layout.pieceAt(p, rects, lines: pieceLines, slop: slop);

  // 1. The centre of every box selects its own verse.
  for (final (i, (k, _)) in pieces.indexed) {
    final hit = at(screen[i].center);
    if (hit == null || pieces[hit].$1 != k) {
      failures.add(
        'box ${i + 1} ($k, line ${lineOf[i]}) at ${screen[i].center}: '
        '${hit == null ? null : pieces[hit].$1}',
      );
    }
  }

  // 2. A grid of touches: each lands on the nearest line drawn (by its
  // band on screen, or the rows of its boxes on a page scaled whole).
  final extents = <int, (double, double)>{};
  if (g.whole) {
    for (final (i, j) in lineOf.indexed) {
      final (t, b) = extents[j] ?? (screen[i].top, screen[i].bottom);
      extents[j] = (
        t < screen[i].top ? t : screen[i].top,
        b > screen[i].bottom ? b : screen[i].bottom,
      );
    }
  } else {
    for (var j = 0; j < g.lines; j++) {
      extents[j] = (
        layout.toScreen(Offset(0, g.bandTops[j]), line: j).dy,
        layout.toScreen(Offset(0, g.bandBottoms[j]), line: j).dy,
      );
    }
  }
  final first = extents.values.map((e) => e.$1).reduce((a, b) => a < b ? a : b);
  final last = extents.values.map((e) => e.$2).reduce((a, b) => a > b ? a : b);
  final reach = slop * layout.scale;
  for (var y = 0.0; y <= layout.size.height; y += 6) {
    if (!layout.strips) {
      final iy = layout.toImage(Offset(0, y)).dy;
      if (iy < layout.ink.top || iy > layout.ink.bottom) continue;
    }
    if (g.whole && (y < first - reach - 1 || y > last + reach + 1)) {
      // Above the first row of text, or below the last (the ornate
      // header, the basmala): nothing.
      final hit = at(Offset(layout.size.width / 2, y));
      if (hit != null) failures.add('off the text at y $y: ${pieces[hit].$1}');
      continue;
    }
    if (g.whole && (y < first || y > last)) continue;
    double distance((double, double) e) =>
        y < e.$1 ? e.$1 - y : (y > e.$2 ? y - e.$2 : 0);
    final ranked = extents.entries.toList()
      ..sort((a, b) => distance(a.value).compareTo(distance(b.value)));
    if (ranked.length > 1 &&
        distance(ranked[1].value) - distance(ranked[0].value) < 0.5) {
      continue; // On a cut between two lines.
    }
    final line = ranked.first.key;
    final on = [
      for (var i = 0; i < pieces.length; i++)
        if (lineOf[i] == line) i,
    ];
    if (on.isEmpty) {
      // A surah header or the basmala.
      final hit = at(Offset(layout.size.width / 2, y));
      if (hit != null) {
        failures.add('line $line has no text, y $y: ${pieces[hit].$1}');
      }
      continue;
    }
    final left = on.map((i) => screen[i].left).reduce((a, b) => a < b ? a : b);
    final right = on
        .map((i) => screen[i].right)
        .reduce((a, b) => a > b ? a : b);
    for (var x = left; x <= right; x += 20) {
      final hit = at(Offset(x, y));
      if (hit == null) {
        failures.add('missed line $line at ($x, $y)');
      } else if (!on.any((i) => pieces[i].$1 == pieces[hit].$1)) {
        failures.add(
          'line $line at ($x, $y): ${pieces[hit].$1}, not on that line',
        );
      }
    }
  }

  // 3. A verse's highlight: each box on the line it is printed on, and
  // its lines in order down the screen.
  final verses = {for (final (k, _) in pieces) k};
  for (final v in verses) {
    final centres = <int, double>{};
    for (final (i, (k, _)) in pieces.indexed) {
      if (k != v) continue;
      final y = screen[i].center.dy;
      if (!g.whole && layout.lineAt(y) != lineOf[i]) {
        failures.add(
          '$v: box ${i + 1} of line ${lineOf[i]} drawn on '
          '${layout.lineAt(y)}',
        );
      }
      centres[lineOf[i]] ??= y;
    }
    final lines = centres.keys.toList()..sort();
    for (var n = 1; n < lines.length; n++) {
      if (centres[lines[n]]! <= centres[lines[n - 1]]!) {
        failures.add('$v: line ${lines[n]} not below ${lines[n - 1]}');
      }
    }
  }
  return failures;
}

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

  Rect rect(int x0, int y0, int x1, int y1) =>
      Rect.fromLTRB(x0.toDouble(), y0.toDouble(), x1.toDouble(), y1.toDouble());

  test('Shamarly: every touch over a line of text selects its verse', () async {
    var checked = 0;
    final failures = <String>[];
    for (var page = 2; page <= 522; page++) {
      final row = (await repo.shamarlyPage(page))!;
      if (row.kind != 'text' && row.kind != 'ornate') continue;
      final overflow = <int, List<Rect>>{};
      for (final o in await repo.shamarlyOverflow(page)) {
        overflow
            .putIfAbsent(o.line, () => [])
            .add(rect(o.x0, o.y0, o.x1, o.y1));
      }
      final g = shamarlyGeometry(
        row,
        await repo.shamarlyLines(page),
        headers: await repo.shamarlyHeaders(page),
        overflow: overflow,
      );
      final boxes = await repo.shamarlyVerseBoxes(page);
      final pieces = [
        for (final b in boxes)
          ((surah: b.surah, ayah: b.ayah), rect(b.x0, b.y0, b.x1, b.y1)),
      ];
      final lines = [for (final b in boxes) b.line];
      for (final size in _sizes) {
        final layout = StripLayout(size, g);
        failures.addAll([
          for (final f in _checkPage(
            layout,
            pieces,
            lineOf: lines,
            pieceLines: lines,
            slop: 6,
          ))
            'page $page at $size: $f',
        ]);
        checked++;
      }
    }
    expect(checked, (2 + 519) * _sizes.length);
    expect(failures.take(20), isEmpty, reason: '${failures.length} failures');
  }, timeout: const Timeout(Duration(minutes: 5)));

  // The glyph boxes of the 1405 edition arrive with its page pack; a copy
  // of quran.com's file is used where it is on disk (not in CI).
  final glyphs = File(
    Platform.environment['AYAHINFO_DB'] ?? 'tools/.cache/ayahinfo_1024.db',
  );
  test(
    'Madina 1405: every touch over a line of text selects its verse',
    () async {
      final info = AyahInfoDatabase(NativeDatabase(glyphs));
      var checked = 0;
      final failures = <String>[];
      for (var page = 1; page <= 604; page++) {
        final overflow = <int, List<Rect>>{};
        for (final o in await repo.oldLineOverflow(page)) {
          overflow
              .putIfAbsent(o.line, () => [])
              .add(rect(o.x0, o.y0, o.x1, o.y1));
        }
        final g = oldEditionGeometry(
          opening: page <= 2,
          cuts: await repo.lineCuts('madina1405', page),
          overflow: overflow,
        );
        final rows = [...await info.page(page)]
          ..sort((a, b) => a.glyphId.compareTo(b.glyphId));
        final pieces = [
          for (final r in rows)
            (
              (surah: r.suraNumber, ayah: r.ayahNumber),
              rect(r.minX, r.minY, r.maxX, r.maxY),
            ),
        ];
        for (final size in _sizes) {
          final layout = StripLayout(size, g, withoutHeader: page <= 2);
          failures.addAll([
            for (final f in _checkPage(
              layout,
              pieces,
              lineOf: [for (final r in rows) r.lineNumber - 1],
              pieceLines: [for (final r in rows) r.lineNumber],
              slop: 6,
            ))
              'page $page at $size: $f',
          ]);
          checked++;
        }
      }
      await info.close();
      expect(checked, 604 * _sizes.length);
      expect(failures.take(20), isEmpty, reason: '${failures.length} failures');
    },
    skip: !glyphs.existsSync(),
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'Madina 1441: every touch over a line of text selects its verse',
    () async {
      final pack = ZipDecoder().decodeBytes(
        File('assets/packs/pages-hafs-1441-v1.zip').readAsBytesSync(),
      );
      var checked = 0;
      final failures = <String>[];
      for (var page = 1; page <= 604; page++) {
        final svg = utf8.decode(
          XZDecoder().decodeBytes(
            pack.findFile('${page.toString().padLeft(3, '0')}.svg.xz')!.content,
          ),
        );
        final v = [
          for (final n in RegExp(
            r'viewBox="([^"]+)"',
          ).firstMatch(svg)!.group(1)!.trim().split(RegExp(r'[\s,]+')))
            double.parse(n),
        ];
        final polys = await repo.polygons(page);
        final g = svgLineGeometry(
          Rect.fromLTWH(v[0], v[1], v[2], v[3]),
          SvgPageGeometry(
            polygons: polys,
            cuts: await repo.lineCuts('madina1441', page),
            overflow: const [],
          ),
          opening: page <= 2,
        );
        if (page <= 2) continue; // No line grid: hit by the outlines alone.
        final pieces = [
          for (final p in polys)
            for (final r in lineRects(outlineRects(p.path), g))
              ((surah: p.surah, ayah: p.number), r),
        ];
        // A verse has a piece on every line its outline crosses.
        for (final p in polys) {
          final outline = parseOutline(p.path);
          final mine = {
            for (final (k, r) in pieces)
              if (k == (surah: p.surah, ayah: p.number))
                StripLayout(_sizes.first, g).lineOfImageY(r.center.dy),
          };
          for (var j = 0; j < g.lines; j++) {
            final crossed = [
              for (var x = g.ink.left + 1; x < g.ink.right; x += 4)
                Offset(x, g.centres[j]),
            ].any(outline.contains);
            if (crossed && !mine.contains(j)) {
              failures.add('page $page: ${p.surah}:${p.number} not on line $j');
            }
          }
        }
        for (final size in _sizes) {
          final layout = StripLayout(size, g);
          final lines = [
            for (final (_, r) in pieces) layout.lineOfImageY(r.center.dy),
          ];
          failures.addAll([
            for (final f in _checkPage(
              layout,
              pieces,
              lineOf: lines,
              pieceLines: lines,
              slop: 2,
            ))
              'page $page at $size: $f',
          ]);
          checked++;
        }
      }
      expect(checked, 602 * _sizes.length);
      expect(failures.take(20), isEmpty, reason: '${failures.length} failures');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
