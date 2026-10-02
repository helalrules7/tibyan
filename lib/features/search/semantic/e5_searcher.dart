import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'e5_model.dart';
import 'meaning_search.dart';
import 'sentencepiece.dart';
import 'tensor_file.dart';

/// Embeds a query for search by meaning. The pack's model runs in Dart
/// ([E5Searcher]); another runtime (ONNX Runtime, say) can stand in by
/// implementing this.
abstract interface class QueryEmbedder {
  Future<Float32List> embed(String query);
}

/// Everything the installed pack holds, loaded in one isolate: tokenizer,
/// model and verse vectors.
class SemanticPackData implements QueryEmbedder {
  SemanticPackData._(this.tokenizer, this.model, this.ranker, this.prefix);

  /// Loads the pack in [dir] (synchronous: run it off the UI isolate).
  /// [verses] are the (surah, ayah) of each vector row, in mushaf order.
  factory SemanticPackData.load(String dir, List<(int, int)> verses) {
    final manifest = jsonDecode(
      File(p.join(dir, 'manifest.json')).readAsStringSync(),
    ) as Map<String, dynamic>;
    final sources = [
      for (final s in manifest['sources'] as List)
        (s as Map)['source_id'] as int,
    ];
    for (final s in manifest['sources'] as List) {
      if ((s as Map)['rows'] != verses.length) {
        throw const FormatException('The pack does not match the verses');
      }
    }
    final emb = TensorFile.bytes(
      File(p.join(dir, 'embeddings.bin')).readAsBytesSync(),
    );
    final ranker = EmbeddingRanker(
      vectors: emb.i8('passages'),
      scales: emb.f32('passages.scale'),
      dim: emb.header['dim'] as int,
      sourceIds: sources,
      verses: verses,
    );
    return SemanticPackData._(
      SentencePiece.parse(File(p.join(dir, 'vocab.tsv')).readAsStringSync()),
      E5Model.open(p.join(dir, 'model.bin')),
      ranker,
      ((manifest['model'] as Map)['query_prefix'] as String?) ?? 'query: ',
    );
  }

  final SentencePiece tokenizer;
  final E5Model model;
  final EmbeddingRanker ranker;
  final String prefix;

  Float32List embedSync(String query) =>
      model.embed(tokenizer.encode('$prefix$query', maxTokens: 64));

  @override
  Future<Float32List> embed(String query) async => embedSync(query);

  List<MeaningHit> searchSync(String query, int limit) =>
      ranker.rank(embedSync(query), limit: limit);
}

/// Search by meaning with the pack, in a worker isolate that keeps the
/// model loaded (about 25 MB; the word table stays on disk).
class E5Searcher implements MeaningSearcher {
  E5Searcher._(this._isolate, this._send, this._replies);

  static Future<E5Searcher> open(String dir, List<(int, int)> verses) async {
    final replies = ReceivePort();
    final isolate = await Isolate.spawn(_worker, (
      replies.sendPort,
      dir,
      verses,
    ));
    final events = replies.asBroadcastStream();
    final first = await events.first;
    if (first is String) {
      replies.close();
      isolate.kill();
      throw StateError(first);
    }
    return E5Searcher._(isolate, first as SendPort, events);
  }

  final Isolate _isolate;
  final SendPort _send;
  final Stream<dynamic> _replies;
  var _next = 0;

  @override
  bool get semantic => true;

  @override
  Future<List<MeaningHit>> search(String query, {int limit = 50}) async {
    final id = _next++;
    final reply = _replies.firstWhere((m) => m is List && m.first == id);
    _send.send((id, query, limit));
    final m = await reply as List;
    return [
      for (final h in (m[1] as List).cast<List>())
        MeaningHit(h[0] as int, h[1] as int, h[2] as int, h[3] as double),
    ];
  }

  void dispose() => _isolate.kill(priority: Isolate.immediate);

  static void _worker((SendPort, String, List<(int, int)>) args) {
    final (out, dir, verses) = args;
    final SemanticPackData data;
    try {
      data = SemanticPackData.load(dir, verses);
    } catch (e) {
      out.send('$e');
      return;
    }
    final inbox = ReceivePort();
    out.send(inbox.sendPort);
    inbox.listen((m) {
      final (id, query, limit) = m as (int, String, int);
      final hits = query.trim().isEmpty
          ? const <MeaningHit>[]
          : data.searchSync(query, limit);
      out.send([
        id,
        [
          for (final h in hits) [h.surah, h.ayah, h.sourceId, h.score],
        ],
      ]);
    });
  }
}
