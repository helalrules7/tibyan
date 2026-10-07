import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/mushaf/data/riwaya_data.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/sajdah/sajdah_positions.dart';

/// The verses of prostration found in each riwaya's KFGQPC text (the ۩
/// sign), as recorded in docs/DATA_SOURCES.md; numbered by the riwaya.
const riwayaSajdahs = <String, List<(int, int)>>{
  'warsh': [
    (7, 206),
    (13, 16),
    (16, 50),
    (17, 108),
    (19, 58),
    (22, 18),
    (25, 60),
    (27, 26),
    (32, 15),
    (38, 23),
    (41, 36),
    (53, 61),
    (84, 21),
    (96, 20),
  ],
  'qalun': [
    (7, 206),
    (13, 16),
    (16, 50),
    (17, 108),
    (19, 58),
    (22, 18),
    (25, 60),
    (27, 26),
    (32, 15),
    (38, 23),
    (41, 36),
    (53, 61),
  ],
  'douri': [
    (7, 206),
    (13, 16),
    (16, 50),
    (17, 108),
    (19, 57),
    (22, 18),
    (22, 75),
    (25, 60),
    (27, 26),
    (32, 15),
    (38, 23),
    (41, 37),
    (53, 61),
    (84, 21),
    (96, 20),
  ],
  'shubah': [
    (7, 206),
    (13, 15),
    (16, 50),
    (17, 109),
    (19, 58),
    (22, 18),
    (22, 77),
    (25, 60),
    (27, 26),
    (32, 15),
    (38, 24),
    (41, 38),
    (53, 62),
    (84, 21),
    (96, 19),
  ],
};

RiwayaVerse verse(int s, int a, String text) => RiwayaVerse(
  surah: s,
  ayah: a,
  page: 1,
  juz: 1,
  hafsFrom: a,
  hafsTo: a,
  text: text,
);

void main() {
  test(
    'Hafs: the 15 verses of the sajda column, and the verse after each',
    () async {
      final db = ContentDatabase(
        NativeDatabase(
          File('assets/db/content.db'),
          setup: (raw) => raw.execute('PRAGMA query_only = ON'),
        ),
      );
      addTearDown(db.close);
      final c = ProviderContainer(
        overrides: [contentDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(c.dispose);
      final hafs = await c.read(hafsSajdahPositionsProvider.future);
      expect(hafs.verses, {
        for (final (s, a) in const [
          (7, 206),
          (13, 15),
          (16, 50),
          (17, 109),
          (19, 58),
          (22, 18),
          (22, 77),
          (25, 60),
          (27, 26),
          (32, 15),
          (38, 24),
          (41, 38),
          (53, 62),
          (84, 21),
          (96, 19),
        ])
          (surah: s, ayah: a),
      });
      expect(hafs.isSajdah(32, 15), isTrue);
      expect(hafs.isSajdah(32, 16), isFalse);
      expect(hafs.before(13, 16), (surah: 13, ayah: 15));
      expect(hafs.before(13, 15), isNull);
      // A surah that ends with one: the next surah's first verse follows it.
      expect(hafs.before(8, 1), (surah: 7, ayah: 206));
      expect(hafs.before(54, 1), (surah: 53, ayah: 62));
      expect(hafs.before(97, 1), (surah: 96, ayah: 19));
      expect(hafs.before(1, 1), isNull);
    },
  );

  test('a riwaya: the verses whose text carries ۩, and only those', () {
    final r = SajdahPositions.ofRiwaya(
      [
        verse(7, 205, 'نص'),
        verse(7, 206, 'نص ۩ ﰀ'),
        verse(8, 1, 'نص'),
        verse(13, 16, 'نص ۩'),
      ],
      [7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43],
    );
    expect(r.verses, {(surah: 7, ayah: 206), (surah: 13, ayah: 16)});
    expect(r.before(8, 1), (surah: 7, ayah: 206));
    expect(r.before(13, 17), (surah: 13, ayah: 16));
    expect(r.before(7, 206), isNull);
    // No marks: no positions, never Hafs's.
    expect(
      SajdahPositions.ofRiwaya([verse(13, 15, 'نص')], const []).verses,
      isEmpty,
    );
    expect(SajdahPositions.none.before(8, 1), isNull);
  });

  // The KFGQPC riwaya files (tools/.cache/riwayat, fetched by the tools),
  // read as the pack builder reads them; skipped where they are not.
  final cache =
      Platform.environment['TIBYAN_RIWAYAT_CACHE'] ?? 'tools/.cache/riwayat';
  const files = {
    'warsh': ('UthmanicWarsh_v2-1.zip', 'warshData_v2-1.json'),
    'qalun': ('UthmanicQaloun_v2-1.zip', 'QalounData_v2-1.json'),
    'douri': ('UthmanicDouri_v2-0.zip', 'DouriData_v2-0.json'),
    'shubah': ('UthmanicShuba_v2-0.zip', 'shubaData_v2-0.json'),
  };
  for (final MapEntry(key: id, value: (zip, member)) in files.entries) {
    final path = p.join(cache, zip);
    test('$id: the ۩ verses of its KFGQPC text', () {
      final archive = ZipDecoder().decodeBytes(File(path).readAsBytesSync());
      final entry = archive.files.firstWhere((f) => f.name.endsWith(member));
      var text = utf8.decode(entry.content);
      if (text.startsWith('﻿')) text = text.substring(1);
      final rows = (jsonDecode(text) as List).cast<Map<String, dynamic>>();
      final found = SajdahPositions.ofRiwaya([
        for (final r in rows)
          verse(
            r['sura_no'] as int,
            r['aya_no'] as int,
            r['aya_text'] as String,
          ),
      ], const []);
      expect(found.verses, {
        for (final (s, a) in riwayaSajdahs[id]!) (surah: s, ayah: a),
      });
    }, skip: File(path).existsSync() ? false : 'no $path');
  }
}
