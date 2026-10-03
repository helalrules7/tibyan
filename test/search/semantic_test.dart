import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/search/semantic/e5_model.dart';
import 'package:tibyan/features/search/semantic/e5_searcher.dart';
import 'package:tibyan/features/search/semantic/meaning_search.dart';
import 'package:tibyan/features/search/semantic/sentencepiece.dart';
import 'package:tibyan/features/search/semantic/tensor_file.dart';

/// The installed pack, when a developer has one: tools/build_semantic_pack.py
/// writes tools/out/semantic-e5-small-v1.zip; unzip it here (or point
/// TIBYAN_SEMANTIC_PACK at it) to check the Dart port against the real
/// model. Skipped otherwise.
final _packDir =
    Platform.environment['TIBYAN_SEMANTIC_PACK'] ??
    'tools/out/semantic-e5-small-v1';

double _cos(List<double> a, List<double> b) {
  var d = 0.0, na = 0.0, nb = 0.0;
  for (var i = 0; i < a.length; i++) {
    d += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  return d / math.sqrt(na * nb);
}

void main() {
  group('SentencePiece', () {
    // ids: 0 <s>, 1 <pad>, 2 </s>, 3 <unk>, then pieces.
    const vocab =
        '3\n0.0\t<s>\n0.0\t<pad>\n0.0\t</s>\n0.0\t<unk>\n'
        '-1.0\t▁\n-2.0\t▁he\n-2.5\tllo\n-1.5\t▁hello\n-3.0\th\n-3.0\te\n'
        '-3.0\tl\n-3.0\to\n-2.0\t▁wor\n-2.0\tld\n';
    final sp = SentencePiece.parse(vocab);

    test('prefers the highest-scoring split', () {
      // ▁hello (-1.5) beats ▁he + llo (-4.5).
      expect(sp.encode('hello'), [0, 7, 2]);
    });

    test('splits at spaces and collapses repeated spaces', () {
      expect(sp.encode('  hello   world '), [0, 7, 12, 13, 2]);
    });

    test('unknown characters become one <unk>', () {
      expect(sp.encode('hello zz'), [0, 7, 4, 3, 2]);
    });

    test('cuts long input to the limit, keeping </s>', () {
      final ids = sp.encode(List.filled(20, 'hello').join(' '), maxTokens: 5);
      expect(ids, [0, 7, 7, 7, 2]);
    });
  });

  group('E5Model', () {
    test('matches the numpy forward pass on a tiny model', () {
      final f = jsonDecode(
        File('test/fixtures/semantic/tiny_model.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final model = E5Model(
        TensorFile.bytes(base64Decode(f['model'] as String)),
      );
      final v = model.embed((f['ids'] as List).cast<int>());
      final expected = (f['vector'] as List).cast<num>();
      for (var i = 0; i < v.length; i++) {
        expect(v[i], closeTo(expected[i].toDouble(), 2e-4));
      }
    });

    test('erf is accurate', () {
      expect(erf(0), closeTo(0, 1e-7));
      expect(erf(0.5), closeTo(0.5204998778, 1e-6));
      expect(erf(-1.5), closeTo(-0.9661051465, 1e-6));
      expect(erf(3), closeTo(0.9999779095, 1e-6));
    });
  });

  group('EmbeddingRanker', () {
    test('ranks by cosine and reports the text that matched', () {
      // Two texts (sources 7 and 8) over three verses, 2-d vectors.
      final r = EmbeddingRanker(
        vectors: Int8List.fromList([
          127, 0, 0, 127, 90, 90, // source 7
          0, 127, 127, 0, -90, 90, // source 8
        ]),
        scales: Float32List.fromList(List.filled(6, 1 / 127)),
        dim: 2,
        sourceIds: [7, 8],
        verses: [(1, 1), (1, 2), (1, 3)],
      );
      final hits = r.rank(Float32List.fromList([1, 0]), limit: 3);
      expect(hits.map((h) => (h.surah, h.ayah, h.sourceId)).toList(), [
        (1, 1, 7),
        (1, 2, 8),
        (1, 3, 7),
      ]);
      expect(hits.first.score, closeTo(1, 1e-6));
    });
  });

  group('KeywordMeaningIndex', () {
    final index = KeywordMeaningIndex([
      (
        sourceId: 7,
        surah: 2,
        ayah: 153,
        text: 'يا أيها المؤمنون استعينوا بالصبر والصلاة',
      ),
      (
        sourceId: 8,
        surah: 2,
        ayah: 153,
        text: 'O you who believe, seek help through patience and prayer.',
      ),
      (sourceId: 7, surah: 2, ayah: 43, text: 'وأقيموا الصلاة وأدُّوا الزكاة'),
      (sourceId: 8, surah: 112, ayah: 1, text: 'Say, He is Allah, the One.'),
    ]);

    test('finds a word inside the meaning texts, folded', () {
      final hits = index.searchSync('الزكاه');
      expect(hits.single.ayah, 43);
      expect(hits.single.sourceId, 7);
    });

    test('matches word beginnings in English', () {
      final hits = index.searchSync('patien');
      expect((hits.single.surah, hits.single.ayah), (2, 153));
      expect(hits.single.sourceId, 8);
    });

    test('one result per verse, best text first', () {
      final hits = index.searchSync('الصلاة');
      expect(hits.map((h) => h.ayah).toSet(), {153, 43});
    });

    test('stop words alone find nothing', () {
      expect(index.searchSync('the and of'), isEmpty);
    });
  });

  group('the real pack', () {
    final dir = Directory(_packDir);
    final present = File('${dir.path}/model.bin').existsSync();
    final ref = jsonDecode(
      File('test/fixtures/semantic/e5_reference.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    test('tokenizes like Hugging Face tokenizers', () {
      final sp = SentencePiece.parse(
        File('${dir.path}/vocab.tsv').readAsStringSync(),
      );
      for (final s in (ref['sentences'] as List).cast<Map>()) {
        expect(sp.encode(s['text'] as String), s['ids'], reason: s['text']);
      }
    }, skip: present ? false : 'pack not unpacked in $_packDir');

    test('embeds like the original model', () {
      final model = E5Model.open('${dir.path}/model.bin');
      for (final s in (ref['sentences'] as List).cast<Map>()) {
        final v = model.embed((s['ids'] as List).cast<int>());
        final c = _cos(
          v,
          (s['vector'] as List).cast<num>().map((x) => x.toDouble()).toList(),
        );
        expect(c, greaterThan(0.995), reason: s['text']);
      }
      model.close();
    }, skip: present ? false : 'pack not unpacked in $_packDir');

    test('searches in a worker isolate', () async {
      final verses = [for (var i = 0; i < 6236; i++) (i, i)];
      final data = SemanticPackData.load(dir.path, verses);
      final watch = Stopwatch()..start();
      final hits = data.searchSync('patience in hardship', 10);
      // ignore: avoid_print
      print('query in ${watch.elapsedMilliseconds} ms');
      expect(hits, hasLength(10));
      // The fixture's top passages for the same query.
      final top = (ref['sentences'] as List).cast<Map>().firstWhere(
        (s) => s['text'] == 'query: patience in hardship',
      )['top'];
      if (top != null) {
        final rows = (top as List).cast<int>().map((r) => r % 6236).toSet();
        expect(hits.take(5).where((h) => rows.contains(h.ayah)), isNotEmpty);
      }
    }, skip: present ? false : 'pack not unpacked in $_packDir');
  });
}
