import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/tasmee/domain/speech_activity_detector.dart';

Int16List _frame(int samples, int value) =>
    Int16List.fromList(List.filled(samples, value));

void main() {
  late SpeechActivityDetector detector;

  setUp(() {
    detector = SpeechActivityDetector(
      sampleRate: 1000,
      frameMilliseconds: 20,
      threshold: 0.01,
      preRollMilliseconds: 60,
      endSilenceMilliseconds: 60,
    );
  });

  test('buffers only a bounded pre-roll while idle', () {
    expect(detector.addFrame(_frame(20, 0)).audio, isEmpty);
    expect(detector.addFrame(_frame(20, 0)).audio, isEmpty);
    final voice = detector.addFrame(_frame(20, 2000));
    expect(voice.audio, hasLength(3));
    expect(voice.audio.last.first, 2000);
    expect(detector.inSpeech, isTrue);
  });

  test('ends speech after the configured quiet frames', () {
    detector.addFrame(_frame(20, 2000));
    expect(detector.addFrame(_frame(20, 0)).speechEnded, isFalse);
    expect(detector.addFrame(_frame(20, 0)).speechEnded, isFalse);
    final ended = detector.addFrame(_frame(20, 0));
    expect(ended.speechEnded, isTrue);
    expect(detector.inSpeech, isFalse);
  });

  test('returns every frame exactly once after speech begins', () {
    detector.addFrame(_frame(20, 0));
    final started = detector.addFrame(_frame(20, 2000));
    expect(started.audio.map((f) => f.first), [0, 2000]);
    final next = detector.addFrame(_frame(20, 2000));
    expect(next.audio.map((f) => f.first), [2000]);
  });

  test(
    'manual finish indicates whether speech was active and resets state',
    () {
      detector.addFrame(_frame(20, 2000));
      expect(detector.finish(), isTrue);
      expect(detector.inSpeech, isFalse);
      expect(detector.finish(), isFalse);
    },
  );

  test('rejects a frame with the wrong duration', () {
    expect(() => detector.addFrame(_frame(19, 1000)), throwsArgumentError);
  });
}
