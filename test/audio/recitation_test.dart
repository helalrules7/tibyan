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

  test(
    'eleven recitations, murattal only, each with a folder of files',
    () async {
      final all = await repo.reciters();
      final reciters = [
        for (final r in all)
          if (r.riwaya == 'hafs') r,
      ];
      expect(reciters.map((r) => r.id).toList()..sort(), [
        1,
        2,
        3,
        4,
        5,
        10,
        11,
        12,
        13,
        14,
        15,
      ]);
      // The riwaya recitations (Warsh, Qalun, al-Duri, Shu'bah): ids from
      // 101, each tagged with its riwaya.
      final others = all.where((r) => r.riwaya != 'hafs').toList();
      expect(others.map((r) => r.riwaya).toSet(), {
        'warsh',
        'qalun',
        'douri',
        'shubah',
      });
      expect(others.every((r) => r.id > 100 && r.style == 'murattal'), isTrue);
      // The mujawwad ones (ids 6 and 7) were removed, and their numbers are
      // never reused, so a reader who saved one cannot land on another.
      expect(reciters.every((r) => r.style == 'murattal'), isTrue);
      expect(reciters.every((r) => r.folderUrl.startsWith('https://')), isTrue);
      expect(reciters.every((r) => r.folderUrl.endsWith('/')), isTrue);
      expect(surahFile(2), '002.mp3');
      // The mirror first, then the source, with the same path.
      final dosari = reciters.firstWhere((r) => r.id == 10);
      expect(surahUrls(dosari, 2).map((u) => u.toString()), [
        'https://tibyan.ahmedhelal.dev/mirror/sources/recitations/quran/yasser_ad-dussary/002.mp3',
        'https://download.quranicaudio.com/quran/yasser_ad-dussary/002.mp3',
      ]);
      final muaiqly = reciters.firstWhere((r) => r.id == 15);
      expect(surahUrls(muaiqly, 2).map((u) => u.toString()), [
        'https://tibyan.ahmedhelal.dev/mirror/sources/recitations/quran/maher_almu3aiqly/year1440/002.mp3',
        'https://download.quranicaudio.com/quran/maher_almu3aiqly/year1440/002.mp3',
      ]);
    },
  );

  test('a folder may name the surah alone, as {surah}', () {
    const r = ReciterRow(
      id: 99,
      nameAr: 'x',
      nameEn: 'x',
      style: 'murattal',
      folderUrl: 'https://host/qdc/who/murattal/{surah}.mp3',
      sourceId: 16,
      riwaya: 'hafs',
    );
    expect(surahUrl(r, 7), 'https://host/qdc/who/murattal/7.mp3');
    // Downloads are named the same whatever the host calls its files.
    expect(surahFile(7), '007.mp3');
  });

  test('timings cover every verse, in order, where they exist', () async {
    final surahs = await repo.surahs();
    for (final reciter in [1, 2, 3, 4, 10, 11, 12, 13, 14, 15]) {
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
    // al-Banna murattal: verse timings derived from QuranLab's word
    // timings, except in the surahs that failed the checks.
    for (final s in [1, 2, 9, 114]) {
      expect(await repo.timings(4, s), isNotEmpty, reason: 'surah $s');
    }
    expect(await repo.timings(4, 55), isEmpty);
    // The four added from mp3quran: every verse of every surah is timed, so
    // the verse is highlighted throughout and no surah is left out.
    for (final reciter in [11, 12, 13, 14]) {
      for (final s in [1, 2, 9, 55, 114]) {
        expect(
          await repo.timings(reciter, s),
          isNotEmpty,
          reason: 'reciter $reciter, surah $s',
        );
      }
    }
    // al-Dosari: verse and word timing from quran.com, in every surah.
    for (final s in [1, 2, 9, 114]) {
      expect(await repo.timings(10, s), isNotEmpty, reason: 'surah $s');
      expect(await repo.wordTimings(10, s), isNotEmpty, reason: 'surah $s');
    }
    // al-Muaiqly: verse and word timing from Quranic Universal Library,
    // measured on the very files played, in every surah.
    for (final s in [1, 2, 9, 55, 114]) {
      expect(await repo.timings(15, s), isNotEmpty, reason: 'surah $s');
      expect(await repo.wordTimings(15, s), isNotEmpty, reason: 'surah $s');
    }
    // Mustafa Ismail murattal: verse timing only where everyayah publishes
    // the per-verse files of his recording, which is not the whole Quran;
    // the rest of it plays without highlighting.
    expect(await repo.timings(5, 1), isNotEmpty);
    expect(await repo.timings(5, 2), isEmpty);
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
      for (final reciter in [1, 2, 3, 4]) {
        final words = await repo.wordTimings(reciter, 2);
        final least = reciter == 4 ? 5500 : 6000;
        expect(words.length, greaterThan(least), reason: 'reciter $reciter');
        for (var i = 1; i < words.length; i++) {
          expect(words[i].startMs, greaterThanOrEqualTo(words[i - 1].startMs));
        }
      }
      final w = await repo.wordTimings(1, 2);
      final third = w.firstWhere((r) => r.ayah == 7 && r.word == 3);
      expect(wordAt(w, third.startMs + 1), (7, 3));
      expect(wordAt(w, 0), isNull);
      // Every al-Banna word lies inside its verse.
      final verses = await repo.timings(4, 2);
      final banna = await repo.wordTimings(4, 2);
      for (final r in banna) {
        final v = verses.firstWhere((t) => t.ayah == r.ayah);
        expect(r.startMs, greaterThanOrEqualTo(v.startMs));
        expect(r.endMs, lessThanOrEqualTo(v.endMs));
      }
      // Every al-Muaiqly word lies inside its verse, in order; QUL times
      // 6,225 of his 6,236 verses word by word (285 of al-Baqarah's 286).
      final muaiqlyVerses = await repo.timings(15, 2);
      final muaiqly = await repo.wordTimings(15, 2);
      expect(muaiqly.map((r) => r.ayah).toSet().length, 285);
      for (var i = 0; i < muaiqly.length; i++) {
        final r = muaiqly[i];
        final v = muaiqlyVerses.firstWhere((t) => t.ayah == r.ayah);
        expect(r.startMs, greaterThanOrEqualTo(v.startMs - 500));
        expect(r.endMs, lessThanOrEqualTo(v.endMs + 500));
        if (i > 0) {
          expect(r.startMs, greaterThanOrEqualTo(muaiqly[i - 1].startMs));
        }
      }
      // No word timing where the recitation has none.
      expect(await repo.wordTimings(5, 2), isEmpty);
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

  test('long pauses between verses are shortened to about the kept pause', () {
    // Verse 1 speaks 0..4000 ms, verse 2 from 7000 ms: a 3-second pause.
    final speech = {1: (0, 4000), 2: (7000, 9000)};
    // During verse 1's speech: nothing.
    expect(pauseJump(speech, 1, 3000, 500), isNull);
    // Past its speech by half the kept pause: to 250 ms before verse 2.
    expect(pauseJump(speech, 1, 4250, 500), 6750);
    // Off, or a pause already short enough: nothing.
    expect(pauseJump(speech, 1, 4250, 0), isNull);
    expect(pauseJump({1: (0, 4000), 2: (4600, 9000)}, 1, 4300, 500), isNull);
    // The last verse has no next one.
    expect(pauseJump(speech, 2, 9500, 500), isNull);
  });
}
