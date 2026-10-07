import 'dart:math' as math;

import 'arabic_normalizer.dart';
import 'expected_words.dart';
import 'word_match.dart';

/// What the reader did with an expected word.
enum WordStatus {
  /// Not reached yet: still covered on the page.
  hidden,

  /// Read as written.
  correct,

  /// Another word was read in its place.
  wrong,

  /// Passed over.
  skipped,

  /// Read wrongly or passed over, then read correctly.
  correctedAfterError,

  /// Neither confirmed nor an error: the word matched only through the
  /// tolerance of the medium or lenient setting (not letter for letter),
  /// or it is the opening basmala of al-Fatiha that the recogniser did not
  /// write (see [TasmeeEngine]). Counted apart: not correct, not an error.
  doubtful;

  bool get isSettled => this != hidden;
  bool get isError => this == wrong || this == skipped;
}

/// What happens when the reader errs (the reader's setting).
enum ErrorBehavior {
  /// The word is marked and the recitation goes on.
  continueReading,

  /// The engine waits on the word until it is read correctly; what is
  /// read meanwhile is not matched further on.
  stopToCorrect,
}

class TasmeeEngineOptions {
  const TasmeeEngineOptions({
    this.strictness = MatchStrictness.medium,
    this.onError = ErrorBehavior.continueReading,
    this.lookAhead = 5,
    this.maxJump = 40,
    this.farConfirm = 3,
    this.lookBack = 20,
    this.maxPending = 6,
    this.ignorePreamble = true,
    this.forgiveFatihaOpening = true,
  });

  final MatchStrictness strictness;
  final ErrorBehavior onError;

  /// Words a skip may pass over and be settled on the strength of one more
  /// word read after it.
  final int lookAhead;

  /// The longest skip looked for (a line or a short verse): a skip longer
  /// than [lookAhead] is settled once [farConfirm] words after it match.
  final int maxJump;
  final int farConfirm;

  /// How far back a restart may begin: the reader goes back up to this
  /// many words and reads again, in order, the words just before the one
  /// expected (or, for a word marked wrong or skipped, corrects it). A word
  /// that only matches some earlier word, out of that order, is not a
  /// repetition.
  final int lookBack;

  /// Heard words held while their reading is unsure; past this many the
  /// first is settled anyway.
  final int maxPending;

  /// The isti'adha and the basmala heard at the start of the session or of
  /// a surah are not extra words.
  final bool ignorePreamble;

  /// A session that opens on al-Fatiha 1:1: basmala words the recogniser
  /// did not write before the reading is heard are doubtful, not skipped.
  final bool forgiveFatihaOpening;
}

/// The words of one verse in the session, and how they were read.
class VerseScore {
  const VerseScore({
    required this.verseId,
    required this.surah,
    required this.ayah,
    required this.words,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.corrected,
    this.doubtful = 0,
  });

  final int verseId;
  final int surah;
  final int ayah;

  /// Words of the verse in the session (all of them, unless a page range
  /// cuts the verse).
  final int words;
  final int correct;
  final int wrong;
  final int skipped;

  /// Words read wrongly or passed over and then corrected: not counted as
  /// correct, reported apart.
  final int corrected;

  /// Words the engine is not sure of ([WordStatus.doubtful]): neither
  /// correct nor an error, reported apart.
  final int doubtful;

  /// Words judged: all but the doubtful ones.
  int get judged => words - doubtful;

  /// Correct words over the words judged, 0..1; null when every word of
  /// the verse is doubtful (nothing to judge).
  double? get accuracy => judged <= 0 ? null : correct / judged;

  @override
  String toString() =>
      'VerseScore($surah:$ayah $correct/$words, wrong $wrong, '
      'skipped $skipped, corrected $corrected, doubtful $doubtful)';
}

sealed class TasmeeEvent {
  const TasmeeEvent();
}

/// An expected word got [status] (a word can change once more: from
/// wrong or skipped to correctedAfterError).
final class WordSettled extends TasmeeEvent {
  const WordSettled(this.index, this.status, {this.heard});
  final int index;
  final WordStatus status;

  /// What was heard in its place, for a wrong word.
  final String? heard;

  @override
  String toString() => 'WordSettled($index, ${status.name}, $heard)';
}

/// A heard word that matches nothing expected: logged, never shown on the
/// page.
final class ExtraWord extends TasmeeEvent {
  const ExtraWord(this.heard, this.beforeIndex);
  final String heard;

  /// The expected word it came before.
  final int beforeIndex;

  @override
  String toString() => 'ExtraWord($heard, before $beforeIndex)';
}

enum IgnoredReason {
  /// The isti'adha or the basmala.
  preamble,

  /// A word read again (at a pause, starting again a little before).
  repetition,

  /// Read while the engine waited on a wrong word (stop to correct).
  whileStopped,
}

/// A heard word that is neither an error nor an expected word.
final class IgnoredWord extends TasmeeEvent {
  const IgnoredWord(this.heard, this.reason);
  final String heard;
  final IgnoredReason reason;

  @override
  String toString() => 'IgnoredWord($heard, ${reason.name})';
}

/// Every word of a verse is settled: its score, for the accuracy toast.
/// Sent again with the new score if a word of it is corrected later.
final class VerseCompleted extends TasmeeEvent {
  const VerseCompleted(this.score);
  final VerseScore score;

  @override
  String toString() => 'VerseCompleted($score)';
}

/// Matches what the reader says, word by word as the recogniser settles
/// them, against the words expected, and decides each word's
/// [WordStatus].
///
/// Pure Dart: no UI and no recogniser. Each heard word joins a short queue
/// of unsure words, which is aligned with the expected words from the
/// cursor (an edit distance alignment that also knows skips of several
/// words, restarts that read again the words just before, and words the recogniser
/// splits or joins differently from the mushaf). A word read as expected
/// is settled at once; an error is settled when the words after it confirm
/// it, so a word is never marked wrong on the strength of one unsure word.
class TasmeeEngine {
  TasmeeEngine(this.words, {this.options = const TasmeeEngineOptions()})
    : _status = List.filled(words.length, WordStatus.hidden),
      _heard = List.filled(words.length, null) {
    for (final w in words) {
      (_verseIndices[w.verseId] ??= []).add(w.index);
    }
  }

  final List<ExpectedWord> words;
  final TasmeeEngineOptions options;

  final List<WordStatus> _status;
  final List<String?> _heard;
  final _verseIndices = <int, List<int>>{};
  final _buffer = <_Heard>[];
  final _extras = <ExtraWord>[];

  int _cursor = 0;
  int? _waitingAt;
  _Heard? _lastWhileWaiting;
  bool _preambleOpen = true;
  List<String>? _phrase;
  int _phraseAt = 0;

  /// The isti'adha and the basmala, as heard.
  static final _preambles = [
    matchingWords('أعوذ بالله من الشيطان الرجيم'),
    matchingWords('بسم الله الرحمن الرحيم'),
  ];

  double get _threshold => options.strictness.threshold;

  List<WordStatus> get statuses => List.unmodifiable(_status);
  WordStatus statusOf(int index) => _status[index];

  /// What was heard in place of a wrong word.
  String? heardFor(int index) => _heard[index];

  /// The first expected word not settled yet.
  int get cursor => _cursor;

  /// Stop to correct: the wrong word the engine waits on.
  int? get waitingAt => _waitingAt;

  List<ExtraWord> get extraWords => List.unmodifiable(_extras);

  /// Every expected word is settled.
  bool get isComplete => _cursor >= words.length && _waitingAt == null;

  /// Heard words not settled yet.
  int get pending => _buffer.length;

  /// Words the recogniser has settled ([TranscriptStabilizer]), in order;
  /// each may hold several words.
  List<TasmeeEvent> addWords(Iterable<String> heard) {
    final events = <TasmeeEvent>[];
    for (final text in heard) {
      for (final raw in text.split(RegExp(r'\s+'))) {
        final key = normalizeArabicWord(raw);
        if (key.isEmpty) continue;
        _take(_Heard(raw, key), events);
      }
    }
    return events;
  }

  /// The session (or a stretch of it) is over: settles every heard word
  /// still unsure. Words not reached stay hidden.
  List<TasmeeEvent> finish() {
    final events = <TasmeeEvent>[];
    _settle(events, force: true);
    return events;
  }

  /// Verse by verse: the reader is done with the verse [verseId]. Settles
  /// what was heard; its words not reached are skipped, and the cursor
  /// moves to the next verse.
  List<TasmeeEvent> finishVerse(int verseId) {
    final events = <TasmeeEvent>[];
    _settle(events, force: true);
    final indices = _verseIndices[verseId] ?? const <int>[];
    final skipped = [
      for (final i in indices)
        if (_status[i] == WordStatus.hidden) i,
    ];
    for (final i in skipped) {
      _set(i, WordStatus.skipped, events);
    }
    if (indices.isNotEmpty && _cursor <= indices.last) {
      if (_waitingAt != null && _waitingAt! <= indices.last) _waitingAt = null;
      _moveTo(indices.last + 1);
    }
    _completeVerses(skipped, events);
    return events;
  }

  /// Stop to correct: the reader gives up on the word the engine waits on.
  /// It stays wrong, and the recitation goes on from the word after it.
  List<TasmeeEvent> skipWaiting() {
    final events = <TasmeeEvent>[];
    final at = _waitingAt;
    if (at == null) return events;
    _waitingAt = null;
    _lastWhileWaiting = null;
    _moveTo(at + 1);
    _completeVerses([at], events);
    return events;
  }

  /// The score of each verse with a word settled, in order.
  List<VerseScore> get verseScores => [
    for (final e in _verseIndices.entries)
      if (e.value.any((i) => _status[i].isSettled)) _score(e.key),
  ];

  VerseScore scoreOf(int verseId) => _score(verseId);

  // ---------------------------------------------------------------------

  /// Nothing has been settled yet: the reading proper has not started.
  bool get _atSessionStart => _cursor == 0 && !_anySettled;
  bool _anySettled = false;

  void _take(_Heard h, List<TasmeeEvent> events) {
    if (_waitingAt != null) return _whileWaiting(h, events);
    // At the very start a word the recogniser garbled does not end the
    // preamble: it stays open until a word matches the words ahead.
    final start = _atSessionStart;
    if (options.ignorePreamble && _preambleOpen && (_buffer.isEmpty || start)) {
      if (_isPreamble(h.key)) {
        events.add(IgnoredWord(h.raw, IgnoredReason.preamble));
        return;
      }
      if (!start || _matchesAhead(h.key)) _preambleOpen = false;
    }
    _buffer.add(h);
    _settle(events, force: false);
  }

  /// Whether [key] goes on (or starts) the isti'adha or the basmala before
  /// the expected word at the cursor. The expected word wins, except in
  /// the middle of one of them (a range opening with «ٱللَّهُ» after a
  /// basmala).
  bool _isPreamble(String key) {
    // Inside a phrase already begun, and for the first word of a phrase
    // before the reading starts, the isti'adha and basmala are matched
    // leniently: they are never judged, so a recogniser's slip in them
    // must not turn them into errors.
    final loose = math.min(_threshold, MatchStrictness.lenient.threshold);
    final start = _atSessionStart;
    bool same(String a, String b) => wordSimilarity(a, b) >= _threshold;
    bool goesOn(String a, String b) => wordSimilarity(a, b) >= loose;
    final phrase = _phrase;
    if (phrase != null && _phraseAt < phrase.length) {
      if (goesOn(key, phrase[_phraseAt])) {
        _phraseAt++;
        if (_phraseAt == phrase.length) _phrase = null;
        return true;
      }
      _phrase = null;
    }
    if (_cursor < words.length && _matches(key, _cursor)) return false;
    // Before the reading starts, a word of the range just ahead is the
    // reading (al-Fatiha whose basmala the recogniser did not write).
    if (start && _matchesAhead(key)) return false;
    for (final p in _preambles) {
      if (start ? goesOn(key, p.first) : same(key, p.first)) {
        _phrase = p;
        _phraseAt = 1;
        return true;
      }
    }
    return _preambles.any((p) => p.any((w) => same(key, w)));
  }

  void _whileWaiting(_Heard h, List<TasmeeEvent> events) {
    final at = _waitingAt!;
    final previous = _lastWhileWaiting;
    final joined = previous == null ? null : joinKeys([previous.key, h.key]);
    if (_matches(h.key, at) ||
        (joined != null && _similarity(joined, at) >= _threshold)) {
      _waitingAt = null;
      _lastWhileWaiting = null;
      _set(at, WordStatus.correctedAfterError, events);
      _moveTo(at + 1);
      _completeVerses([at], events);
      return;
    }
    _lastWhileWaiting = h;
    final back = _repeatTarget(h.key, from: at - options.lookBack, to: at);
    events.add(
      back != null
          ? IgnoredWord(h.raw, IgnoredReason.repetition)
          : IgnoredWord(h.raw, IgnoredReason.whileStopped),
    );
  }

  double _similarity(String key, int index) {
    var best = 0.0;
    for (final k in words[index].keys) {
      best = math.max(best, wordSimilarity(key, k));
    }
    return best;
  }

  bool _matches(String key, int index) => _similarity(key, index) >= _threshold;

  /// The latest word in [from]..[to] (exclusive) that [key] matches,
  /// preferring one marked wrong or skipped (a correction).
  int? _repeatTarget(String key, {required int from, required int to}) {
    int? latest;
    for (var i = to - 1; i >= math.max(0, from); i--) {
      if (i >= words.length || !_matches(key, i)) continue;
      if (_status[i].isError) return i;
      latest ??= i;
    }
    return latest;
  }

  /// The heard words [ops] k consumes, from the queue.
  List<_Heard> _heardOf(List<_Op> ops, int k) {
    final from = _tokensBefore(ops, k);
    return _buffer.sublist(from, from + ops[k].tokens);
  }

  int _tokensBefore(List<_Op> ops, int k) {
    var n = 0;
    for (var x = 0; x < k; x++) {
      n += ops[x].tokens;
    }
    return n;
  }

  /// Whether [key] matches a word from the cursor on, within a skip.
  bool _matchesAhead(String key) {
    final end = math.min(words.length, _cursor + options.maxJump + 1);
    for (var i = _cursor; i < end; i++) {
      if (_matches(key, i)) return true;
    }
    return false;
  }

  double _skipCost(int length) =>
      (length <= options.lookAhead ? 0.9 : 1.4) + 0.05 * (length - 1);

  /// The cheapest reading of the queue against the words from the cursor.
  List<_Op> _bestPath() {
    final c = _cursor;
    final n = _buffer.length;
    final m = math.min(words.length - c, options.maxJump + n + 2);
    final width = m + 1;
    final cost = List<double>.filled((n + 1) * width, double.infinity);
    final back = List<_Op?>.filled((n + 1) * width, null);
    final from = List<int>.filled((n + 1) * width, -1);
    final sims = <int, double>{};
    double sim(int i, int j) =>
        sims[i * width + j] ??= _similarity(_buffer[i].key, c + j);
    final matched = <int, bool>{};
    bool heardIs(int i, int k) =>
        matched[i * (words.length + 1) + k] ??= _matches(_buffer[i].key, k);
    bool readsFrom(int i, int start, int length) {
      for (var x = 0; x < length; x++) {
        if (!heardIs(i + x, start + x)) return false;
      }
      return true;
    }

    void relax(int i, int j, double value, int source, _Op op) {
      final at = i * width + j;
      if (value < cost[at] - 1e-9) {
        cost[at] = value;
        back[at] = op;
        from[at] = source;
      }
    }

    cost[0] = 0;
    for (var i = 0; i <= n; i++) {
      for (var j = 0; j <= m; j++) {
        final here = i * width + j;
        final d = cost[here];
        if (d == double.infinity || i == n) continue;
        if (j < m) {
          final s = sim(i, j);
          s >= _threshold
              ? relax(i + 1, j + 1, d + (1 - s) * 0.2, here, _Op.match)
              : relax(i + 1, j + 1, d + 1 - 0.5 * s, here, _Op.sub);
          for (var t = 2; t <= 4 && i + t <= n; t++) {
            final joined = joinKeys([
              for (var x = i; x < i + t; x++) _buffer[x].key,
            ]);
            if (_similarity(joined, c + j) >= _threshold) {
              relax(i + t, j + 1, d + 0.05, here, _Op.merge(t));
            }
          }
          if (j + 1 < m && s < _threshold) {
            final pair = joinKeys([
              words[c + j].matching,
              words[c + j + 1].matching,
            ]);
            if (wordSimilarity(_buffer[i].key, pair) >= _threshold) {
              relax(i + 1, j + 2, d + 0.05, here, _Op.split);
            }
          }
        }
        relax(i + 1, j, d + 1.05, here, _Op.insert);
        // A restart (at a waqf): the reader goes back and reads again, in
        // order, the words just before the one expected, up to it. At the
        // end of the queue it may still be under way (only its first words
        // heard yet); it is then never settled until the rest is heard.
        final at = c + j;
        final earliest = math.max(0, at - options.lookBack);
        for (var length = 1; i + length <= n; length++) {
          final whole = at - length;
          if (whole < earliest) break;
          final open = i + length == n;
          for (var start = open ? earliest : whole; start <= whole; start++) {
            if (readsFrom(i, start, length)) {
              relax(
                i + length,
                j,
                d + 0.3 * length,
                here,
                _Op.repeat(start, length),
              );
            }
          }
        }
        for (var l = 1; l <= options.maxJump && j + l <= m; l++) {
          relax(i, j + l, d + _skipCost(l), here, _Op.skip(l));
        }
      }
    }
    var end = n * width;
    for (var j = 1; j <= m; j++) {
      if (cost[n * width + j] < cost[end] - 1e-9) end = n * width + j;
    }
    final ops = <_Op>[];
    for (var at = end; at > 0; at = from[at]) {
      ops.add(back[at]!);
    }
    return ops.reversed.toList();
  }

  /// How much of [ops] is sure enough to settle.
  int _committable(List<_Op> ops) {
    // A word read correctly confirms an error before it; a short word
    // (من، في، لا) half as much.
    double weight(_Op op, int wordAt) {
      if (op.kind == _OpKind.repeat) return 0;
      final key = words[math.min(wordAt, words.length - 1)].matching;
      return key.length >= 3 ? 1 : 0.5;
    }

    var k = 0;
    var wordAt = _cursor;
    final errorWords = <int>{};
    while (k < ops.length) {
      final op = ops[k];
      if (op.kind == _OpKind.repeat) {
        final last = k == ops.length - 1;
        // A restart still under way waits for the rest of it.
        if (op.target + op.tokens < wordAt) break;
        // A word read again that is also a word further on waits for a
        // word read correctly after it to tell which it was (a skipped line
        // may land on it).
        if ((last || ops[k + 1].isError) &&
            _matchesAhead(_buffer[_tokensBefore(ops, k)].key)) {
          break;
        }
        // So does a correction: the word after it tells a word read wrongly
        // and then rightly from two words read in each other's place.
        final corrects = [for (var x = 0; x < op.tokens; x++) op.target + x]
            .any((t) => _status[t].isError || errorWords.contains(t));
        if (corrects && (last || !ops[k + 1].isMatch)) break;
      }
      if (!op.isError) {
        // A match only through the setting's tolerance (doubtful) may be
        // a word read again that the queue has not shown yet: it waits for
        // a word matched after it.
        if (op.kind != _OpKind.repeat &&
            _matchSimilarity(op, _heardOf(ops, k), wordAt) < 1 &&
            (k == ops.length - 1 || !ops[k + 1].isMatch)) {
          break;
        }
        wordAt += op.words;
        k++;
        continue;
      }
      final need = switch (op.kind) {
        _OpKind.skip when op.words > options.lookAhead =>
          options.farConfirm.toDouble(),
        _OpKind.skip => 2.0,
        _ => 1.0,
      };
      if (op.kind != _OpKind.insert) {
        for (var x = 0; x < op.words; x++) {
          errorWords.add(wordAt + x);
        }
      }
      var got = 0.0;
      var at = wordAt + op.words;
      for (final next in ops.skip(k + 1)) {
        if (next.isError) break;
        if (next.kind == _OpKind.repeat) {
          // Reading the erring word again confirms it was an error.
          for (var x = 0; x < next.tokens; x++) {
            if (errorWords.contains(next.target + x)) got += 1;
          }
        } else {
          got += weight(next, at);
        }
        at += next.words;
      }
      if (got < need) break;
      wordAt += op.words;
      k++;
    }
    return k;
  }

  void _settle(List<TasmeeEvent> events, {required bool force}) {
    while (_buffer.isNotEmpty && _waitingAt == null) {
      final ops = _bestPath();
      var k = force ? ops.length : _committable(ops);
      if (k == 0 && _buffer.length > options.maxPending) k = 1;
      if (k == 0) break;
      _apply(ops.sublist(0, k), events);
      if (!force) break;
    }
    if (_waitingAt != null) {
      for (final h in _buffer) {
        events.add(IgnoredWord(h.raw, IgnoredReason.whileStopped));
      }
      _buffer.clear();
    }
  }

  void _apply(List<_Op> ops, List<TasmeeEvent> events) {
    final touched = <int>[];
    for (final op in ops) {
      final heard = _buffer.sublist(0, op.tokens);
      _buffer.removeRange(0, op.tokens);
      final c = _cursor;
      switch (op.kind) {
        case _OpKind.match || _OpKind.merge || _OpKind.split:
          final status = _matchSimilarity(op, heard, c) >= 1
              ? WordStatus.correct
              : WordStatus.doubtful;
          for (var x = 0; x < op.words; x++) {
            _set(c + x, status, events);
            touched.add(c + x);
          }
          _moveTo(c + op.words);
        case _OpKind.sub:
          _heard[c] = heard.single.raw;
          _set(c, WordStatus.wrong, events, heard: heard.single.raw);
          touched.add(c);
          if (options.onError == ErrorBehavior.stopToCorrect) {
            _waitingAt = c;
            break;
          }
          _moveTo(c + 1);
        case _OpKind.skip:
          if (_isFatihaOpeningGap(c, op.words)) {
            for (var x = 0; x < op.words; x++) {
              _set(c + x, WordStatus.doubtful, events);
              touched.add(c + x);
            }
            _moveTo(c + op.words);
            break;
          }
          final stop = options.onError == ErrorBehavior.stopToCorrect;
          for (var x = 0; x < (stop ? 1 : op.words); x++) {
            _set(c + x, WordStatus.skipped, events);
            touched.add(c + x);
          }
          if (stop) {
            _waitingAt = c;
            break;
          }
          _moveTo(c + op.words);
        case _OpKind.insert:
          final extra = ExtraWord(heard.single.raw, c);
          _extras.add(extra);
          events.add(extra);
        case _OpKind.repeat:
          // A restart: each word read again is ignored, or corrects the
          // word it reads if that one was marked wrong or skipped.
          for (var x = 0; x < op.tokens; x++) {
            final target = op.target + x;
            if (target < c && _status[target].isError) {
              _set(target, WordStatus.correctedAfterError, events);
              touched.add(target);
            } else {
              events.add(IgnoredWord(heard[x].raw, IgnoredReason.repetition));
            }
          }
      }
      if (_waitingAt != null) break;
    }
    _completeVerses(touched, events);
  }

  /// How close the heard word(s) of a match, merge or split are to the
  /// expected word(s): 1 when letter for letter.
  double _matchSimilarity(_Op op, List<_Heard> heard, int at) =>
      switch (op.kind) {
        _OpKind.match => _similarity(heard.single.key, at),
        _OpKind.merge => _similarity(
          joinKeys([for (final h in heard) h.key]),
          at,
        ),
        _ => wordSimilarity(
          heard.single.key,
          joinKeys([words[at].matching, words[at + 1].matching]),
        ),
      };

  /// The opening of al-Fatiha: a skip of [length] words from [at] at the
  /// very start of a session that opens on 1:1, lying wholly in 1:1. The
  /// recogniser often drops the basmala at the head of a long stretch; the
  /// words after the skip (verse 2 on) have already confirmed it, so the
  /// basmala was most likely read and not written. A skip reaching into
  /// 1:2 is a real skip.
  bool _isFatihaOpeningGap(int at, int length) {
    if (!options.forgiveFatihaOpening || at != 0 || !_atSessionStart) {
      return false;
    }
    final first = words.first;
    if (first.surah != 1 || first.ayah != 1 || first.word != 1) return false;
    final last = at + length - 1;
    return last < words.length &&
        words[last].surah == 1 &&
        words[last].ayah == 1;
  }

  void _set(
    int index,
    WordStatus status,
    List<TasmeeEvent> events, {
    String? heard,
  }) {
    if (status != WordStatus.hidden) _anySettled = true;
    _status[index] = status;
    events.add(WordSettled(index, status, heard: heard));
  }

  void _moveTo(int index) {
    _cursor = math.min(index, words.length);
    _preambleOpen = _cursor < words.length && words[_cursor].opensSurah;
    _phrase = null;
  }

  void _completeVerses(Iterable<int> indices, List<TasmeeEvent> events) {
    final verses = {for (final i in indices) words[i].verseId};
    for (final v in verses) {
      final all = _verseIndices[v]!;
      if (all.every((i) => _status[i].isSettled)) {
        events.add(VerseCompleted(_score(v)));
      }
    }
  }

  VerseScore _score(int verseId) {
    final all = _verseIndices[verseId]!;
    int count(WordStatus s) => all.where((i) => _status[i] == s).length;
    final first = words[all.first];
    return VerseScore(
      verseId: verseId,
      surah: first.surah,
      ayah: first.ayah,
      words: all.length,
      correct: count(WordStatus.correct),
      wrong: count(WordStatus.wrong),
      skipped: count(WordStatus.skipped),
      corrected: count(WordStatus.correctedAfterError),
      doubtful: count(WordStatus.doubtful),
    );
  }
}

class _Heard {
  const _Heard(this.raw, this.key);
  final String raw;
  final String key;
}

enum _OpKind { match, merge, split, sub, insert, repeat, skip }

/// One step of an alignment: heard words consumed ([tokens]) and expected
/// words consumed ([words]).
class _Op {
  const _Op._(this.kind, this.tokens, this.words, [this.target = -1]);

  static const match = _Op._(_OpKind.match, 1, 1);
  static const sub = _Op._(_OpKind.sub, 1, 1);
  static const insert = _Op._(_OpKind.insert, 1, 0);
  static const split = _Op._(_OpKind.split, 1, 2);
  factory _Op.merge(int tokens) => _Op._(_OpKind.merge, tokens, 1);

  /// [length] words read again, from the expected word [start] on.
  factory _Op.repeat(int start, int length) =>
      _Op._(_OpKind.repeat, length, 0, start);
  factory _Op.skip(int length) => _Op._(_OpKind.skip, 0, length);

  final _OpKind kind;
  final int tokens;
  final int words;

  /// The first earlier word a restart reads again.
  final int target;

  bool get isError =>
      kind == _OpKind.sub || kind == _OpKind.insert || kind == _OpKind.skip;

  bool get isMatch =>
      kind == _OpKind.match || kind == _OpKind.merge || kind == _OpKind.split;

  @override
  String toString() => '${kind.name}($tokens/$words)';
}
