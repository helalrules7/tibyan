import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/tasmee/domain/spectrum.dart';

Int16List _tone(double hz, {double amplitude = 0.5, int n = 512}) =>
    Int16List.fromList([
      for (var i = 0; i < n; i++)
        (amplitude * 32767 * math.sin(2 * math.pi * hz * i / 16000)).round(),
    ]);

void main() {
  test('silence stays flat', () {
    final a = SpectrumAnalyzer(clock: () => Duration.zero);
    final bands = a.add(Int16List(512))!;
    expect(bands, hasLength(18));
    expect(bands, everyElement(0));
  });

  test('a tone lifts its own band and leaves the far ones low', () {
    final a = SpectrumAnalyzer(clock: () => Duration.zero);
    final bands = a.add(_tone(1000))!;
    final peak = bands.indexOf(bands.reduce(math.max));
    // 1 kHz on a log scale from 250 Hz to 4.5 kHz.
    final expected = (math.log(1000 / 250) / math.log(4500 / 250) * 18).floor();
    expect((peak - expected).abs(), lessThanOrEqualTo(1));
    expect(bands[peak], greaterThan(0.8));
    expect(bands.last, lessThan(0.5));
  });

  test('no bands before a full window, and at most one per interval', () {
    var now = Duration.zero;
    final a = SpectrumAnalyzer(clock: () => now);
    expect(a.add(_tone(500, n: 256)), isNull);
    expect(a.add(_tone(500, n: 256)), isNotNull);
    now += const Duration(milliseconds: 10);
    expect(a.add(_tone(500, n: 160)), isNull);
    now += const Duration(milliseconds: 30);
    expect(a.add(_tone(500, n: 160)), isNotNull);
    a.reset();
    expect(a.add(_tone(500, n: 160)), isNull);
  });

  test('the FFT finds a pure bin', () {
    final re = Float64List(8), im = Float64List(8);
    for (var i = 0; i < 8; i++) {
      re[i] = math.cos(2 * math.pi * 2 * i / 8);
    }
    fft(re, im);
    expect(re[2], closeTo(4, 1e-9));
    expect(re[6], closeTo(4, 1e-9));
    expect(re[1].abs() + re[3].abs() + im[2].abs(), lessThan(1e-9));
  });
}
