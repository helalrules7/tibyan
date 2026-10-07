import 'dart:typed_data';

/// Collects the audio of one stretch of speech until it is handed to a
/// recogniser that works on whole segments (Whisper takes at most 30
/// seconds at a time). Pure and in memory: nothing is written anywhere.
class SpeechSegmentBuffer {
  SpeechSegmentBuffer({
    this.sampleRate = 16000,
    this.maxSeconds = 25,
    this.minSeconds = 0.3,
  });

  final int sampleRate;

  /// A segment this long is cut here, even if the reader has not paused.
  final int maxSeconds;

  /// A shorter segment is a click or a breath, not speech: dropped.
  final double minSeconds;

  final _chunks = <Int16List>[];
  int _samples = 0;

  int get bufferedSamples => _samples;

  /// Adds [pcm]; returns the segments that are complete because they reached
  /// [maxSeconds] (usually none).
  List<Int16List> add(Int16List pcm) {
    final out = <Int16List>[];
    final limit = maxSeconds * sampleRate;
    var offset = 0;
    while (offset < pcm.length) {
      final take = (limit - _samples).clamp(0, pcm.length - offset);
      if (take > 0) {
        _chunks.add(Int16List.sublistView(pcm, offset, offset + take));
        _samples += take;
        offset += take;
      }
      if (_samples >= limit) out.add(_drain());
    }
    return out;
  }

  /// The reader paused: the segment so far, or null when it is too short.
  Int16List? flush() {
    if (_samples < minSeconds * sampleRate) {
      _chunks.clear();
      _samples = 0;
      return null;
    }
    return _drain();
  }

  void clear() {
    _chunks.clear();
    _samples = 0;
  }

  Int16List _drain() {
    final out = Int16List(_samples);
    var at = 0;
    for (final c in _chunks) {
      out.setRange(at, at + c.length, c);
      at += c.length;
    }
    clear();
    return out;
  }
}
