/// The SentencePiece unigram tokenizer of multilingual-e5-small (the
/// XLM-RoBERTa vocabulary), as Hugging Face's `tokenizers` runs it:
/// spaces become «▁», each word (from one «▁» to the next) is split into
/// the pieces with the highest total score (Viterbi), and a character no
/// piece covers becomes `<unk>` (consecutive ones fused).
///
/// Not reproduced: the model's NFKC character map, which only changes
/// compatibility characters (full-width Latin, Arabic presentation forms,
/// ligatures). Queries typed on a keyboard do not contain them.
library;

import 'dart:typed_data';

class SentencePiece {
  SentencePiece._(
    this._ids,
    this._scores,
    this.unkId,
    this._unkScore,
    this._longest,
  );

  /// Reads `vocab.tsv` from the pack: the unknown piece's id on the first
  /// line, then one `score<TAB>piece` line per id from 0.
  factory SentencePiece.parse(String tsv) {
    final lines = tsv.split('\n');
    final unk = int.parse(lines.first.trim());
    final ids = <String, int>{};
    final scores = Float64List(lines.length);
    var min = double.infinity;
    var longest = 1;
    var id = 0;
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) continue;
      final tab = line.indexOf('\t');
      final score = double.parse(line.substring(0, tab));
      final piece = line.substring(tab + 1);
      // Special tokens are never matched inside text.
      if (!_special.contains(piece)) {
        ids[piece] = id;
        scores[id] = score;
        if (score < min) min = score;
        final n = piece.runes.length;
        if (n > longest) longest = n;
      }
      id++;
    }
    // tokenizers: an unknown character costs the lowest score minus 10.
    return SentencePiece._(ids, scores, unk, min - 10, longest);
  }

  static const _special = {'<s>', '</s>', '<pad>', '<unk>', '<mask>'};

  final Map<String, int> _ids;
  final Float64List _scores;
  final int unkId;
  final double _unkScore;
  final int _longest;

  static const bos = 0;
  static const eos = 2;
  static const space = 0x2581; // ▁

  /// Token ids of [text] between `<s>` and `</s>`, at most [maxTokens] in
  /// all (the rest is cut, as the model was trained).
  List<int> encode(String text, {int maxTokens = 512}) {
    final clean = text.trim().replaceAll(RegExp(r' {2,}'), ' ');
    final ids = <int>[bos];
    if (clean.isNotEmpty) {
      final runes = [space, ...clean.runes.map((r) => r == 0x20 ? space : r)];
      // Each word starts at a ▁.
      var start = 0;
      for (var i = 1; i <= runes.length; i++) {
        if (i == runes.length || runes[i] == space) {
          ids.addAll(_viterbi(runes.sublist(start, i)));
          start = i;
        }
      }
    }
    if (ids.length > maxTokens - 1) ids.length = maxTokens - 1;
    ids.add(eos);
    return ids;
  }

  List<int> _viterbi(List<int> runes) {
    final n = runes.length;
    final best = List<double>.filled(n + 1, double.negativeInfinity);
    final from = List<int>.filled(n + 1, -1);
    final piece = List<int>.filled(n + 1, -1);
    best[0] = 0;
    for (var i = 0; i < n; i++) {
      if (best[i] == double.negativeInfinity) continue;
      var single = false;
      final last = i + _longest < n ? i + _longest : n;
      for (var j = i + 1; j <= last; j++) {
        final id = _ids[String.fromCharCodes(runes, i, j)];
        if (id == null) continue;
        if (j == i + 1) single = true;
        final s = best[i] + _scores[id];
        if (s > best[j]) {
          best[j] = s;
          from[j] = i;
          piece[j] = id;
        }
      }
      if (!single) {
        final s = best[i] + _unkScore;
        if (s > best[i + 1]) {
          best[i + 1] = s;
          from[i + 1] = i;
          piece[i + 1] = unkId;
        }
      }
    }
    final out = <int>[];
    for (var at = n; at > 0; at = from[at]) {
      out.add(piece[at]);
    }
    // Consecutive unknown characters are one <unk>.
    final fused = <int>[];
    for (final id in out.reversed) {
      if (id == unkId && fused.isNotEmpty && fused.last == unkId) continue;
      fused.add(id);
    }
    return fused;
  }
}
