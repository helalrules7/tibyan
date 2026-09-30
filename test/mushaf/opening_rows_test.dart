import 'dart:io';
import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/mushaf_page.dart';

/// On pages 1 and 2 a verse's outline is one polygon over several lines;
/// its shading is built from its word boxes, one box per line.
void main() {
  test('Al-Fatiha verses shade line by line', () async {
    final db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
    addTearDown(db.close);
    Future<List<Rect>> rows(int ayah) async => wordRows([
      for (final r in await db
          .customSelect(
            'SELECT x0, y0, x1, y1 FROM word_box '
            'WHERE page = 1 AND surah = 1 AND ayah = $ayah',
          )
          .get())
        Rect.fromLTRB(
          r.read<int>('x0') / 10,
          r.read<int>('y0') / 10,
          r.read<int>('x1') / 10,
          r.read<int>('y1') / 10,
        ),
    ]);

    expect((await rows(5)).length, 1);
    final six = await rows(6);
    expect(six.length, 2);
    // Two separate lines, the first above the second.
    expect(six[0].bottom, lessThan(six[1].center.dy));
    final seven = await rows(7);
    expect(seven.length, greaterThanOrEqualTo(2));
  });
}
