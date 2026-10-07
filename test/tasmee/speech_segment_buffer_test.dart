import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/tasmee/domain/speech_segment_buffer.dart';

const _rate = 1000; // 20 samples a 20 ms frame keeps the arithmetic readable.

/// Synthetic speech: a loud tone, except [quiet] stretches (in seconds,
/// start to end) where it drops to [quietAmplitude].
Int16List _speech(
  double seconds, {
  List<(double, double)> quiet = const [],
  int loud = 12000,
  int quietAmplitude = 300,
}) {
  final n = (seconds * _rate).round();
  return Int16List.fromList(
    List.generate(n, (i) {
      final t = i / _rate;
      final amp = quiet.any((q) => t >= q.$1 && t < q.$2)
          ? quietAmplitude
          : loud;
      return (amp * math.sin(2 * math.pi * 97 * t)).round();
    }),
  );
}

SpeechSegmentBuffer _buffer({double overlap = 0}) => SpeechSegmentBuffer(
  sampleRate: _rate,
  maxSeconds: 8,
  searchSeconds: 2,
  overlapSeconds: overlap,
);

/// Feeds [pcm] in 20 ms frames, like the capture does.
List<Int16List> _feed(SpeechSegmentBuffer b, Int16List pcm) => [
  for (var i = 0; i < pcm.length; i += 20)
    ...b.add(Int16List.sublistView(pcm, i, math.min(i + 20, pcm.length))),
];

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
    b.add(Int16List(20));
    expect(b.flush(), isNull);
    expect(b.bufferedSamples, 0);
  });

  test('speech shorter than the maximum is never cut', () {
    final b = _buffer();
    expect(_feed(b, _speech(7.9)), isEmpty);
    expect(b.flush()!.length, 7900);
  });

  test('without a pause, the cut is at the quiet gap before the maximum', () {
    final b = _buffer();
    final pcm = _speech(12, quiet: [(6.6, 6.75)]);
    final out = _feed(b, pcm);
    expect(out, hasLength(1));
    // Somewhere inside the gap, not in the loud audio around it.
    expect(out.single.length, inInclusiveRange(6600, 6750));
    final rest = b.flush()!;
    expect(out.single.length + rest.length, pcm.length);
    expect(rest.first, pcm[out.single.length]);
  });

  test('the deepest of several gaps wins', () {
    final b = _buffer();
    final pcm = _speech(
      10,
      quiet: [(6.2, 6.3), (7.1, 7.25)],
      quietAmplitude: 2000,
    )..setRange(7100, 7250, Int16List(150));
    final out = _feed(b, pcm);
    expect(out.single.length, inInclusiveRange(7100, 7250));
  });

  test('loud audio with no dip waits for one, then cuts in it', () {
    final b = _buffer();
    // No gap before 8 s; the reader breathes at 9.0 to 9.15 s.
    final pcm = _speech(12, quiet: [(9.0, 9.15)]);
    final out = _feed(b, pcm);
    expect(out.single.length, inInclusiveRange(9000, 9150));
  });

  test('never longer than the hard maximum, even with no dip at all', () {
    final b = _buffer();
    final out = _feed(b, _speech(25));
    expect(out, isNotEmpty);
    for (final s in out) {
      expect(s.length, lessThanOrEqualTo(10000));
      expect(s.length, greaterThanOrEqualTo(6000));
    }
    final total = out.fold<int>(0, (n, s) => n + s.length) + b.flush()!.length;
    expect(total, 25000);
  });

  test('the next segment repeats the overlap before the cut', () {
    final b = _buffer(overlap: 0.2);
    final pcm = _speech(12, quiet: [(6.6, 6.75)]);
    final first = _feed(b, pcm).single;
    final rest = b.flush()!;
    expect(rest.length, pcm.length - first.length + 200);
    expect(rest.sublist(0, 200), first.sublist(first.length - 200));
  });

  test('a single large chunk is cut the same way', () {
    final b = _buffer();
    final pcm = _speech(30, quiet: [(6.6, 6.75), (13.0, 13.1), (20.5, 20.6)]);
    final out = b.add(pcm);
    expect(out, hasLength(3));
    var at = 0;
    final cuts = [for (final s in out) at += s.length];
    expect(cuts[0], inInclusiveRange(6600, 6750));
    expect(cuts[1], inInclusiveRange(13000, 13100));
    expect(cuts[2], inInclusiveRange(20500, 20600));
  });

  test('defaults: 8 s cap, 3 s search, 0.2 s overlap at 16 kHz', () {
    final b = SpeechSegmentBuffer();
    expect(b.maxSeconds, 8);
    expect(b.searchSeconds, 3);
    expect(b.hardMaxSeconds, 11);
    expect(b.overlapSeconds, 0.2);
  });
}
