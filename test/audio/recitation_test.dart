import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/audio/recitation.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';

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

  test('seven recitations, each with a folder of surah files', () async {
    final reciters = await repo.reciters();
    expect(reciters.length, 7);
    expect(reciters.every((r) => r.folderUrl.startsWith('https://')), isTrue);
    expect(reciters.every((r) => r.folderUrl.endsWith('/')), isTrue);
    expect(surahFile(2), '002.mp3');
  });

  test('timings cover every verse, in order, where they exist', () async {
    final surahs = await repo.surahs();
    for (final reciter in [1, 2, 3, 6, 7]) {
      for (final s in [1, 2, 9, 114]) {
        final t = await repo.timings(reciter, s);
        if (t.isEmpty) continue;
        final verses = [
          for (final r in t)
            if (r.ayah > 0) r.ayah,
        ];
        expect(verses, List.generate(surahs[s - 1].ayahCount, (i) => i + 1));
        for (var i = 1; i < t.length; i++) {
          expect(t[i].startMs, greaterThanOrEqualTo(t[i - 1].startMs));
        }
      }
    }
    // The two surahs with a verse missing in the source have no timing.
    expect(await repo.timings(1, 9), isEmpty);
    expect(await repo.timings(2, 1), isEmpty);
    // al-Banna and Mustafa Ismail murattal: no published timing.
    expect(await repo.timings(4, 1), isEmpty);
    expect(await repo.timings(5, 1), isEmpty);
  });

  test('the verse at a position', () async {
    final t = await repo.timings(1, 1);
    expect(ayahAt(t, 0), 0);
    final third = t.firstWhere((r) => r.ayah == 3);
    expect(ayahAt(t, third.startMs), 3);
    expect(ayahAt(t, third.endMs - 1), 3);
    expect(ayahAt(t, 1 << 30), 7);
  });
}
