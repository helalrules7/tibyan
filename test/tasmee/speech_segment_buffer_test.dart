import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/tasmee/domain/speech_segment_buffer.dart';

Int16List _samples(int n, [int value = 1]) =>
    Int16List.fromList(List.filled(n, value));

void main() {
  test('flush returns everything added, in order', () {
    final b = SpeechSegmentBuffer(sampleRate: 100, maxSeconds: 10);
    expect(b.add(Int16List.fromList(List.generate(60, (i) => i))), isEmpty);
    expect(
      b.add(Int16List.fromList(List.generate(40, (i) => 60 + i))),
      isEmpty,
    );
    final out = b.flush()!;
    expect(out, List.generate(100, (i) => i));
    expect(b.bufferedSamples, 0);
  });

  test('a segment shorter than the minimum is dropped', () {
    final b = SpeechSegmentBuffer(sampleRate: 100, minSeconds: 0.5);
    b.add(_samples(20));
    expect(b.flush(), isNull);
    expect(b.bufferedSamples, 0);
  });

  test('a segment is cut at the maximum length without losing samples', () {
    final b = SpeechSegmentBuffer(sampleRate: 100, maxSeconds: 2);
    final first = b.add(Int16List.fromList(List.generate(450, (i) => i)));
    expect(first.map((s) => s.length), [200, 200]);
    expect(first[0].first, 0);
    expect(first[1].first, 200);
    final rest = b.flush()!;
    expect(rest.length, 50);
    expect(rest.first, 400);
  });

  test('a chunk that ends exactly on the maximum is emitted once', () {
    final b = SpeechSegmentBuffer(sampleRate: 100, maxSeconds: 2);
    expect(b.add(_samples(200)).length, 1);
    expect(b.bufferedSamples, 0);
  });
}
