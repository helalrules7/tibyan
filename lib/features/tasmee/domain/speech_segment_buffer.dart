import 'dart:typed_data';

/// Collects the audio of one stretch of speech until it is handed to a
/// recogniser that works on whole segments. Pure and in memory: nothing is
/// written anywhere.
///
/// The reader's pauses end a segment ([flush]). When the reader goes on
/// without a pause the voice activity detector can hear, the segment is cut
/// anyway once it reaches [maxSeconds]: long segments come back garbled from
/// the CTC model. The cut is placed at the quietest moment of the last
/// [searchSeconds] (a gap between words, never the middle of a loud
/// syllable). If that stretch has no real dip, the buffer waits for one up to
/// [hardMaxSeconds], then cuts at the quietest moment it has.
///
/// The next segment starts [overlapSeconds] before the cut, so a word that
/// begins right at the cut keeps its onset. A word heard twice there is read
/// by the engine as a restart, which is not an error.
class SpeechSegmentBuffer {
  SpeechSegmentBuffer({
    this.sampleRate = 16000,
    this.maxSeconds = 8,
    this.searchSeconds = 3,
    double? hardMaxSeconds,
    this.overlapSeconds = 0.2,
    this.minSeconds = 0.3,
    this.frameMilliseconds = 20,
    this.dipRatio = 0.35,
  }) : hardMaxSeconds = hardMaxSeconds ?? maxSeconds + searchSeconds,
       assert(maxSeconds > 0),
       assert(searchSeconds > 0 && searchSeconds < maxSeconds),
       assert(overlapSeconds >= 0 && overlapSeconds < searchSeconds),
       assert(dipRatio > 0 && dipRatio <= 1);

  final int sampleRate;

  /// A segment this long is cut even if the reader has not paused.
  final double maxSeconds;

  /// How far back from [maxSeconds] the cut may be placed.
  final double searchSeconds;

  /// No segment is ever longer than this, dip or not.
  final double hardMaxSeconds;

  /// Audio before the cut that is also given to the next segment.
  final double overlapSeconds;

  /// A shorter segment is a click or a breath, not speech: dropped.
  final double minSeconds;

  /// The energy is measured over frames this long.
  final int frameMilliseconds;

  /// A frame is a dip when its (smoothed) energy is at most this share of the
  /// median energy of the search stretch.
  final double dipRatio;

  final _chunks = <Int16List>[];
  int _samples = 0;

  int get bufferedSamples => _samples;

  int get _frame => sampleRate * frameMilliseconds ~/ 1000;
  int get _maxSamples => (maxSeconds * sampleRate).round();
  int get _hardMaxSamples => (hardMaxSeconds * sampleRate).round();
  int get _searchSamples => (searchSeconds * sampleRate).round();
  int get _overlapSamples => (overlapSeconds * sampleRate).round();

  /// Adds [pcm]; returns the segments that are complete because they reached
  /// the maximum length (usually none).
  List<Int16List> add(Int16List pcm) {
    final out = <Int16List>[];
    var offset = 0;
    while (offset < pcm.length) {
      // Never hold more than the hard maximum, so a cut is always possible.
      final take = (_hardMaxSamples - _samples).clamp(0, pcm.length - offset);
      if (take > 0) {
        _chunks.add(Int16List.sublistView(pcm, offset, offset + take));
        _samples += take;
        offset += take;
      }
      while (_samples >= _maxSamples) {
        final segment = _cutIfReady();
        if (segment == null) break;
        out.add(segment);
      }
    }
    return out;
  }

  /// The reader paused: the segment so far, or null when it is too short.
  Int16List? flush() {
    if (_samples < minSeconds * sampleRate) {
      clear();
      return null;
    }
    final out = Int16List.fromList(_joined());
    clear();
    return out;
  }

  void clear() {
    _chunks.clear();
    _samples = 0;
  }

  /// Cuts at the quietest frame from `max - search` to what is buffered, if
  /// it is a real dip or the hard maximum is reached; null to wait for more.
  Int16List? _cutIfReady() {
    final all = _joined();
    final frame = _frame;
    final from = ((_maxSamples - _searchSamples) ~/ frame) * frame;
    final frames = (all.length - from) ~/ frame;
    if (frames < 1) return null;

    final energy = List<double>.generate(frames, (f) {
      var sum = 0.0;
      final start = from + f * frame;
      for (var i = start; i < start + frame; i++) {
        final s = all[i] / 32768.0;
        sum += s * s;
      }
      return sum / frame;
    });
    // Smooth over three frames so one quiet frame inside a vowel is no dip.
    final smooth = List<double>.generate(frames, (f) {
      var sum = 0.0;
      var n = 0;
      for (var k = f - 1; k <= f + 1; k++) {
        if (k < 0 || k >= frames) continue;
        sum += energy[k];
        n++;
      }
      return sum / n;
    });

    var best = 0;
    for (var f = 1; f < frames; f++) {
      if (smooth[f] <= smooth[best]) best = f;
    }
    final sorted = [...smooth]..sort();
    final median = sorted[sorted.length ~/ 2];
    final isDip = smooth[best] <= dipRatio * median;
    if (!isDip && all.length < _hardMaxSamples) return null;

    final cut = from + best * frame + frame ~/ 2;
    final segment = Int16List.sublistView(all, 0, cut);
    final keepFrom = (cut - _overlapSamples).clamp(0, cut);
    final rest = Int16List.sublistView(all, keepFrom);
    _chunks
      ..clear()
      ..add(rest);
    _samples = rest.length;
    return Int16List.fromList(segment);
  }

  Int16List _joined() {
    if (_chunks.length == 1) return _chunks.single;
    final out = Int16List(_samples);
    var at = 0;
    for (final c in _chunks) {
      out.setRange(at, at + c.length, c);
      at += c.length;
    }
    _chunks
      ..clear()
      ..add(out);
    return out;
  }
}
