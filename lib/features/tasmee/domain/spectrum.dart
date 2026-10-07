import 'dart:math' as math;
import 'dart:typed_data';

/// The recording panel's live spectrum: log-spaced band levels of the
/// microphone's last [window] samples (16 kHz), Hann windowed, on a fixed
/// dBFS scale so silence stays flat and a louder voice rises. Pure Dart,
/// no audio is kept beyond the window.
class SpectrumAnalyzer {
  SpectrumAnalyzer({
    this.bands = 18,
    this.minInterval = const Duration(milliseconds: 33),
    Duration Function()? clock,
  }) : _clock = clock ?? _stopwatchClock();

  static const window = 512;
  static const sampleRate = 16000;
  static const lowHz = 250.0;
  static const highHz = 4500.0;

  /// Silent below this, full at [fullDb].
  static const floorDb = -70.0;
  static const fullDb = -15.0;

  final int bands;

  /// At most one set of bands per interval (about 30 a second).
  final Duration minInterval;
  final Duration Function() _clock;

  final _ring = Float64List(window);
  int _filled = 0;
  int _at = 0;
  Duration? _last;

  static Duration Function() _stopwatchClock() {
    final watch = Stopwatch()..start();
    return () => watch.elapsed;
  }

  /// Adds captured samples; returns new band levels (0 to 1) when a full
  /// window is in and [minInterval] has passed since the last ones, else
  /// null.
  List<double>? add(Int16List samples) {
    for (final s in samples) {
      _ring[_at] = s / 32768.0;
      _at = (_at + 1) % window;
      if (_filled < window) _filled++;
    }
    if (_filled < window) return null;
    final now = _clock();
    final last = _last;
    if (last != null && now - last < minInterval) return null;
    _last = now;
    return levels();
  }

  /// The band levels of the window as it stands.
  List<double> levels() {
    final re = Float64List(window), im = Float64List(window);
    for (var i = 0; i < window; i++) {
      final w = 0.5 - 0.5 * math.cos(2 * math.pi * i / (window - 1));
      re[i] = _ring[(_at + i) % window] * w;
    }
    fft(re, im);
    final out = List<double>.filled(bands, 0);
    for (var b = 0; b < bands; b++) {
      final f0 = lowHz * math.pow(highHz / lowHz, b / bands);
      final f1 = lowHz * math.pow(highHz / lowHz, (b + 1) / bands);
      final k0 = (f0 * window / sampleRate).floor().clamp(1, window ~/ 2 - 1);
      final k1 = math
          .max(k0 + 1, (f1 * window / sampleRate).ceil())
          .clamp(2, window ~/ 2);
      var peak = 0.0;
      for (var k = k0; k < k1; k++) {
        final mag = math.sqrt(re[k] * re[k] + im[k] * im[k]) / (window / 4);
        peak = math.max(peak, mag);
      }
      final db = 20 * math.log(peak + 1e-9) / math.ln10;
      out[b] = ((db - floorDb) / (fullDb - floorDb)).clamp(0.0, 1.0);
    }
    return out;
  }

  /// Forgets the window (the microphone stopped).
  void reset() {
    _ring.fillRange(0, window, 0);
    _filled = 0;
    _at = 0;
    _last = null;
  }
}

/// In-place iterative radix-2 FFT; the length must be a power of two.
void fft(Float64List re, Float64List im) {
  final n = re.length;
  for (var i = 1, j = 0; i < n; i++) {
    var bit = n >> 1;
    for (; j & bit != 0; bit >>= 1) {
      j ^= bit;
    }
    j ^= bit;
    if (i < j) {
      final tr = re[i];
      re[i] = re[j];
      re[j] = tr;
      final ti = im[i];
      im[i] = im[j];
      im[j] = ti;
    }
  }
  for (var len = 2; len <= n; len <<= 1) {
    final ang = -2 * math.pi / len;
    final wr = math.cos(ang), wi = math.sin(ang);
    final half = len ~/ 2;
    for (var i = 0; i < n; i += len) {
      var cr = 1.0, ci = 0.0;
      for (var k = 0; k < half; k++) {
        final a = i + k, b = a + half;
        final xr = re[b] * cr - im[b] * ci;
        final xi = re[b] * ci + im[b] * cr;
        re[b] = re[a] - xr;
        im[b] = im[a] - xi;
        re[a] += xr;
        im[a] += xi;
        final nr = cr * wr - ci * wi;
        ci = cr * wi + ci * wr;
        cr = nr;
      }
    }
  }
}
