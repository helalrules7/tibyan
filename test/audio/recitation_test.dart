import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/audio/recitation.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';
import 'package:flutter/painting.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/page_interaction.dart';

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

  test(
    'word timings: most verses, words in order, the word at a time',
    () async {
      for (final reciter in [1, 2, 3]) {
        final words = await repo.wordTimings(reciter, 2);
        expect(words.length, greaterThan(6000), reason: 'reciter $reciter');
        for (var i = 1; i < words.length; i++) {
          expect(words[i].startMs, greaterThanOrEqualTo(words[i - 1].startMs));
        }
      }
      final w = await repo.wordTimings(1, 2);
      final third = w.firstWhere((r) => r.ayah == 7 && r.word == 3);
      expect(wordAt(w, third.startMs + 1), (7, 3));
      expect(wordAt(w, 0), isNull);
      // No word timing where the recitation has none.
      expect(await repo.wordTimings(4, 2), isEmpty);
    },
  );

  test('highlight boxes: one per line, clamped to the line band', () {
    final boxes = lineBoxes(
      [
        const Rect.fromLTRB(10, 12, 30, 18),
        const Rect.fromLTRB(40, 11, 60, 19),
        const Rect.fromLTRB(5, 42, 25, 48),
      ],
      lineOf: (r) => r.center.dy ~/ 30,
      centre: (j) => j * 30 + 15,
      halfHeight: 14,
      band: (j) => (j * 30 + 2.0, j * 30 + 28.0),
    );
    expect(boxes, [
      const Rect.fromLTRB(10, 3, 60, 27),
      const Rect.fromLTRB(5, 33, 25, 57),
    ]);
  });
}
