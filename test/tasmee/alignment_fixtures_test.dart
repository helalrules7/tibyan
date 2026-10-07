import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/tasmee/data/tasmee_words_repository.dart';
import 'package:tibyan/features/tasmee/domain/alignment_engine.dart';
import 'package:tibyan/features/tasmee/domain/expected_words.dart';
import 'package:tibyan/features/tasmee/domain/recitation_range.dart';
import 'package:tibyan/features/tasmee/domain/word_match.dart';

/// Runs every scenario in test/tasmee/fixtures/alignment/ on the real
/// words of content.db.
///
/// A fixture: `range` (`{"surah": 1}`, `{"verses": [s, a, s, a]}`),
/// `options` (`strictness`, `onError`), `steps` (`{"say": "…"}` words the
/// recogniser settled, as it writes them; `{"finish": true}`;
/// `{"finishVerse": "s:a"}`), and what to expect: `statuses` (by
/// `s:a:w`, `s:a:w1-w2`, or `*` for the rest), `extras`, `heard` (what a
/// wrong word was heard as), `ignored` (counts by reason), `accuracy` (by
/// `s:a`), `corrected` (by `s:a`), `completed` (verses, in order).
void main() {
  late ContentDatabase db;
  late TasmeeWordsRepository repo;
  setUpAll(() {
    db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
    repo = TasmeeWordsRepository(db);
  });
  tearDownAll(() => db.close());

  final files =
      Directory('test/tasmee/fixtures/alignment')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final fixture = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    test(fixture['name'] as String, () async {
      final words = await repo.expectedWords(_range(fixture['range']));
      final engine = TasmeeEngine(words, options: _options(fixture['options']));
      final events = <TasmeeEvent>[];
      for (final step in fixture['steps'] as List) {
        final s = step as Map<String, dynamic>;
        if (s['say'] case final String text) {
          events.addAll(engine.addWords([text]));
        } else if (s['finish'] == true) {
          events.addAll(engine.finish());
        } else if (s['finishVerse'] case final String ref) {
          final [surah, ayah] = ref.split(':').map(int.parse).toList();
          final verse = words.firstWhere(
            (w) => w.surah == surah && w.ayah == ayah,
          );
          events.addAll(engine.finishVerse(verse.verseId));
        }
      }
      _expectStatuses(fixture, words, engine);
      if (fixture['extras'] case final List extras) {
        expect([for (final e in engine.extraWords) e.heard], extras);
      }
      if (fixture['heard'] case final Map heard) {
        for (final MapEntry(:key, :value) in heard.entries) {
          expect(engine.heardFor(_index(words, key as String)), value);
        }
      }
      if (fixture['ignored'] case final Map ignored) {
        final counts = <String, int>{};
        for (final e in events.whereType<IgnoredWord>()) {
          counts[e.reason.name] = (counts[e.reason.name] ?? 0) + 1;
        }
        expect(counts, ignored);
      }
      if (fixture['accuracy'] case final Map accuracy) {
        for (final MapEntry(:key, :value) in accuracy.entries) {
          expect(
            _score(engine, words, key as String).accuracy,
            closeTo((value as num).toDouble(), 0.005),
            reason: 'accuracy of $key',
          );
        }
      }
      if (fixture['corrected'] case final Map corrected) {
        for (final MapEntry(:key, :value) in corrected.entries) {
          expect(_score(engine, words, key as String).corrected, value);
        }
      }
      if (fixture['completed'] case final List completed) {
        expect([
          for (final e in events.whereType<VerseCompleted>())
            '${e.score.surah}:${e.score.ayah}',
        ], completed);
      }
      if (fixture['waitingAt'] case final String ref) {
        expect(engine.waitingAt, _index(words, ref));
      }
    });
  }
}

RecitationRange _range(dynamic json) {
  final m = json as Map<String, dynamic>;
  if (m['surah'] case final int s) return SurahRange(s);
  final [fs, fa, ts, ta] = (m['verses'] as List).cast<int>();
  return VerseRange(fromSurah: fs, fromAyah: fa, toSurah: ts, toAyah: ta);
}

TasmeeEngineOptions _options(dynamic json) {
  final m = (json ?? const <String, dynamic>{}) as Map<String, dynamic>;
  return TasmeeEngineOptions(
    strictness: MatchStrictness.values.byName(
      m['strictness'] as String? ?? 'medium',
    ),
    onError: ErrorBehavior.values.byName(
      m['onError'] as String? ?? 'continueReading',
    ),
  );
}

int _index(List<ExpectedWord> words, String ref) {
  final [s, a, w] = ref.split(':').map(int.parse).toList();
  return words.indexWhere((x) => x.surah == s && x.ayah == a && x.word == w);
}

VerseScore _score(TasmeeEngine engine, List<ExpectedWord> words, String ref) {
  final [s, a] = ref.split(':').map(int.parse).toList();
  return engine.scoreOf(
    words.firstWhere((x) => x.surah == s && x.ayah == a).verseId,
  );
}

void _expectStatuses(
  Map<String, dynamic> fixture,
  List<ExpectedWord> words,
  TasmeeEngine engine,
) {
  final spec = (fixture['statuses'] as Map<String, dynamic>?) ?? const {};
  final want = List<String?>.filled(words.length, null);
  for (final MapEntry(:key, :value) in spec.entries) {
    if (key == '*') continue;
    final [s, a, w] = key.split(':');
    final [from, to] = w.contains('-')
        ? w.split('-').map(int.parse).toList()
        : [int.parse(w), int.parse(w)];
    for (var n = from; n <= to; n++) {
      final i = _index(words, '$s:$a:$n');
      expect(i, isNot(-1), reason: 'no word $s:$a:$n');
      want[i] = value as String;
    }
  }
  final rest = spec['*'] as String?;
  final got = [for (final s in engine.statuses) s.name];
  final expected = [
    for (var i = 0; i < words.length; i++) want[i] ?? rest ?? got[i],
  ];
  final diff = [
    for (var i = 0; i < words.length; i++)
      if (got[i] != expected[i])
        '${words[i].surah}:${words[i].ayah}:${words[i].word} '
            '${words[i].display}: ${got[i]} (want ${expected[i]})',
  ];
  expect(diff, isEmpty);
}
