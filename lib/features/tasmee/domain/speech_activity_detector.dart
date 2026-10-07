import 'dart:math' as math;
import 'dart:typed_data';

class SpeechActivityFrame {
  const SpeechActivityFrame({
    required this.level,
    required this.audio,
    required this.speechEnded,
  });

  final double level;
  final List<Int16List> audio;
  final bool speechEnded;
}

/// Small in-memory energy VAD. Keeps a short pre-roll so the first consonant
/// is not lost, and ends a speech segment after sustained quiet. It stores no
/// audio outside the bounded pre-roll buffer.
class SpeechActivityDetector {
  SpeechActivityDetector({
    this.sampleRate = 16000,
    this.frameMilliseconds = 20,
    this.threshold = 0.012,
    this.preRollMilliseconds = 300,
    this.endSilenceMilliseconds = 600,
  }) : assert(sampleRate > 0),
       assert(frameMilliseconds > 0),
       assert(threshold > 0),
       assert(preRollMilliseconds >= 0),
       assert(endSilenceMilliseconds >= frameMilliseconds);

  final int sampleRate;
  final int frameMilliseconds;
  final double threshold;
  final int preRollMilliseconds;
  final int endSilenceMilliseconds;

  int get frameSamples => sampleRate * frameMilliseconds ~/ 1000;
  int get _preRollFrames => preRollMilliseconds ~/ frameMilliseconds;
  int get _endSilenceFrames =>
      (endSilenceMilliseconds + frameMilliseconds - 1) ~/ frameMilliseconds;

  final List<Int16List> _preRoll = [];
  bool _inSpeech = false;
  int _quietFrames = 0;

  bool get inSpeech => _inSpeech;

  SpeechActivityFrame addFrame(Int16List frame) {
    if (frame.length != frameSamples) {
      throw ArgumentError.value(
        frame.length,
        'frame.length',
        'Expected $frameSamples PCM samples',
      );
    }
    final level = _rms(frame);
    if (!_inSpeech) {
      if (_preRollFrames > 0) {
        _preRoll.add(frame);
        if (_preRoll.length > _preRollFrames) _preRoll.removeAt(0);
      }
      if (level < threshold) {
        return SpeechActivityFrame(
          level: level,
          audio: const [],
          speechEnded: false,
        );
      }
      _inSpeech = true;
      _quietFrames = 0;
      final audio = [..._preRoll];
      if (_preRoll.isEmpty) audio.add(frame);
      _preRoll.clear();
      return SpeechActivityFrame(
        level: level,
        audio: audio,
        speechEnded: false,
      );
    }

    if (level < threshold) {
      _quietFrames++;
    } else {
      _quietFrames = 0;
    }
    final ended = _quietFrames >= _endSilenceFrames;
    if (ended) {
      _inSpeech = false;
      _quietFrames = 0;
      _preRoll.clear();
    }
    return SpeechActivityFrame(
      level: level,
      audio: [frame],
      speechEnded: ended,
    );
  }

  /// Ends the current stretch when the user presses stop.
  bool finish() {
    final wasInSpeech = _inSpeech;
    reset();
    return wasInSpeech;
  }

  void reset() {
    _preRoll.clear();
    _inSpeech = false;
    _quietFrames = 0;
  }

  double _rms(Int16List frame) {
    var sum = 0.0;
    for (final sample in frame) {
      final normalized = sample / 32768.0;
      sum += normalized * normalized;
    }
    return math.sqrt(sum / frame.length);
  }
}
