import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/tasmee/data/tasmee_words_repository.dart';
import 'package:tibyan/features/tasmee/domain/alignment_engine.dart';
import 'package:tibyan/features/tasmee/domain/recitation_range.dart';
import 'package:tibyan/features/tasmee/domain/tasmee_report.dart';

void main() {
  late ContentDatabase db;
  setUpAll(() {
    db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
  });
  tearDownAll(() => db.close());

  test(
    'per verse and in all; hints apart; words not reached left out',
    () async {
      final words = await TasmeeWordsRepository(db)
          .expectedWords(const SurahRange(112));
      final engine = TasmeeEngine(words)
        ..addWords(['قل هو الله أحد الله الصمد'])
        ..addWords(['لم'])
        ..finish();
      // The reader was shown «يلد» (verse 3, word 2) by the hint.
      final report = TasmeeReport.of(engine, {7});
      expect(report.verses.map((v) => v.ayah), [1, 2, 3]);
      final v3 = report.verses.last;
      expect((v3.words, v3.reached, v3.correct, v3.hinted), (4, 2, 1, 1));
      expect(v3.accuracy, 0.5);
      expect(v3.needsReview, isTrue);
      expect(report.verse(words.first.verseId)!.accuracy, 1);
      expect(report.accuracy, 7 / 8);
      expect(report.toReview.map((v) => v.ayah), [3]);
    },
  );

  test('the verses to recite again, numbered from 0', () async {
    final words = await TasmeeWordsRepository(db)
        .expectedWords(const SurahRange(112));
    final again = wordsOfVerses(words, {words.last.verseId});
    expect(again.map((w) => w.index), [0, 1, 2, 3, 4]);
    expect(again.every((w) => w.ayah == 4), isTrue);
    expect(again.map((w) => w.display), [
      for (final w in words)
        if (w.ayah == 4) w.display,
    ]);
  });
}
