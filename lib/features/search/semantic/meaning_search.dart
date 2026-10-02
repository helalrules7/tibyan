/// Search by meaning: verses found through the meaning texts shipped in
/// content.db (al-Tafsir al-Muyassar, Saheeh International, Pickthall).
/// The texts are only read and compared; results show them as stored.
///
/// Two searchers share one interface: [EmbeddingRanker] (the optional
/// pack: multilingual-e5-small vectors, any wording of the idea) and
/// [KeywordMeaningIndex] (no download: BM25 over the words of the texts).
library;

import 'dart:math' as math;
import 'dart:typed_data';

import '../search_engine.dart' show normalize;

/// A verse found by meaning, and the text that matched it best.
class MeaningHit {
  const MeaningHit(this.surah, this.ayah, this.sourceId, this.score);

  final int surah;
  final int ayah;

  /// content.db source id of the meaning text that matched.
  final int sourceId;
  final double score;
}

/// One verse's entry in a meaning text.
typedef MeaningRow = ({int sourceId, int surah, int ayah, String text});

/// Finds verses for a query.
abstract interface class MeaningSearcher {
  /// True when this searcher understands meaning (the embedding pack),
  /// false for the keyword fallback.
  bool get semantic;

  Future<List<MeaningHit>> search(String query, {int limit = 50});
}

/// Keeps the best-scoring row of each verse, best first.
List<MeaningHit> bestPerVerse(Iterable<MeaningHit> hits, int limit) {
  final best = <(int, int), MeaningHit>{};
  for (final h in hits) {
    final k = (h.surah, h.ayah);
    final b = best[k];
    if (b == null || h.score > b.score) best[k] = h;
  }
  final out = best.values.toList()..sort((a, b) => b.score.compareTo(a.score));
  return out.length > limit ? out.sublist(0, limit) : out;
}

/// Cosine ranking over the pack's int8 passage vectors (each row is
/// `q * scale`, normalised before quantising, so the dot product with a
/// normalised query is the cosine).
class EmbeddingRanker {
  EmbeddingRanker({
    required this.vectors,
    required this.scales,
    required this.dim,
    required this.sourceIds,
    required this.verses,
  }) : assert(vectors.length == scales.length * dim);

  final Int8List vectors;
  final Float32List scales;
  final int dim;

  /// Source id of each block of [verses].length rows, in pack order.
  final List<int> sourceIds;

  /// (surah, ayah) of each row within a block, in mushaf order.
  final List<(int, int)> verses;

  int get rows => scales.length;

  /// The [limit] verses closest to [query] (a normalised vector).
  List<MeaningHit> rank(Float32List query, {int limit = 50}) {
    final scores = Float32List(rows);
    for (var r = 0; r < rows; r++) {
      final o = r * dim;
      var s = 0.0;
      for (var i = 0; i < dim; i++) {
        s += vectors[o + i] * query[i];
      }
      scores[r] = s * scales[r];
    }
    // Keep a few candidates per verse slot, then fold to one per verse.
    final order = List<int>.generate(rows, (i) => i)
      ..sort((a, b) => scores[b].compareTo(scores[a]));
    final n = verses.length;
    return bestPerVerse([
      for (final r in order.take(limit * sourceIds.length))
        MeaningHit(
          verses[r % n].$1,
          verses[r % n].$2,
          sourceIds[r ~/ n],
          scores[r],
        ),
    ], limit);
  }
}

/// Words of a meaning text or query, folded for comparison: Arabic as
/// [normalize] folds it (no diacritics, one alif, …) and Latin lower-cased;
/// punctuation and digits dropped.
List<String> meaningTerms(String text) {
  final folded = normalize(text.toLowerCase());
  return [
    for (final w in folded.split(RegExp(r'[^\p{L}]+', unicode: true)))
      if (w.length > 1 && !_stop.contains(w)) w,
  ];
}

/// Words too common to tell verses apart.
const _stop = {
  // Arabic
  'في', 'من', 'على', 'الى', 'عن', 'ان', 'او', 'ما', 'لا', 'لم', 'لن',
  'هو', 'هي', 'هم', 'ذلك', 'هذا', 'هذه', 'التي', 'الذي', 'الذين', 'كان',
  'قد', 'ثم', 'كل', 'به', 'بها', 'لهم', 'له', 'منه', 'منهم', 'اي', 'يا',
  'ولا', 'وما', 'ومن', 'وهو', 'فان', 'انه', 'انهم', 'عليه', 'عليهم',
  // English
  'the', 'and', 'of', 'to', 'in', 'is', 'are', 'was', 'were', 'that',
  'this', 'it', 'he', 'they', 'them', 'his', 'their', 'for', 'with', 'be',
  'not', 'on', 'as', 'by', 'who', 'which', 'what', 'from', 'or', 'an',
  'but', 'have', 'has', 'had', 'will', 'shall', 'unto', 'ye', 'you',
  'your', 'we', 'our', 'us', 'him', 'her', 'she', 'at', 'so', 'if', 'do',
};

/// A word, then the word without the Arabic conjunction (و ف), the
/// preposition (ب ل ك) and the article (ال) in front of it, when what is
/// left still has three letters. Only used to compare words.
List<String> arabicStems(String word) {
  final out = [word];
  var w = word;
  String? strip(String prefix) =>
      w.startsWith(prefix) && w.length - prefix.length >= 3
      ? w.substring(prefix.length)
      : null;
  for (final group in const [
    ['و', 'ف'],
    ['ب', 'ل', 'ك'],
    ['ال'],
  ]) {
    for (final prefix in group) {
      final s = strip(prefix);
      if (s != null) {
        w = s;
        out.add(w);
        break;
      }
    }
  }
  return out;
}

/// BM25 over the meaning texts: the fallback before the pack is on the
/// device. A query word matches a text word that starts with it, so
/// «صبر» finds «الصبر» only through folding and «patien» finds «patience».
class KeywordMeaningIndex implements MeaningSearcher {
  KeywordMeaningIndex(List<MeaningRow> rows) {
    for (final r in rows) {
      final terms = meaningTerms(r.text);
      final tf = <int, int>{};
      for (final t in terms) {
        final id = _termIds.putIfAbsent(t, () => _termIds.length);
        tf[id] = (tf[id] ?? 0) + 1;
      }
      for (final id in tf.keys) {
        while (_postings.length <= id) {
          _postings.add(<int>[]);
        }
        _postings[id].add(_docs.length);
      }
      _docs.add((r.sourceId, r.surah, r.ayah));
      _tf.add(tf);
      _len.add(terms.length);
      _total += terms.length;
    }
    _stems = [for (final t in _termIds.keys) arabicStems(t)];
  }

  final _termIds = <String, int>{};
  late final List<List<String>> _stems;
  final _postings = <List<int>>[];
  final _docs = <(int, int, int)>[];
  final _tf = <Map<int, int>>[];
  final _len = <int>[];
  var _total = 0;

  static const _k1 = 1.2;
  static const _b = 0.75;

  @override
  bool get semantic => false;

  @override
  Future<List<MeaningHit>> search(String query, {int limit = 50}) async =>
      searchSync(query, limit: limit);

  List<MeaningHit> searchSync(String query, {int limit = 50}) {
    final words = meaningTerms(query).toSet();
    if (words.isEmpty || _docs.isEmpty) return const [];
    final avg = _total / _docs.length;
    final scores = <int, double>{};
    for (final w in words) {
      // Every vocabulary word that begins with the query word once the
      // Arabic prefixes are set aside: «الصلاة» finds «والصلاة», «صلاة».
      final core = arabicStems(w).last;
      final ids = <int>[
        for (final (i, stems) in _stems.indexed)
          if (stems.any((t) => t.startsWith(core))) i,
      ];
      for (final id in ids) {
        final docs = _postings[id];
        final idf = math.log(
          1 + (_docs.length - docs.length + 0.5) / (docs.length + 0.5),
        );
        for (final d in docs) {
          final f = _tf[d][id]!;
          final norm =
              f * (_k1 + 1) / (f + _k1 * (1 - _b + _b * _len[d] / avg));
          scores[d] = (scores[d] ?? 0) + idf * norm;
        }
      }
    }
    return bestPerVerse([
      for (final e in scores.entries)
        MeaningHit(_docs[e.key].$2, _docs[e.key].$3, _docs[e.key].$1, e.value),
    ], limit);
  }
}
