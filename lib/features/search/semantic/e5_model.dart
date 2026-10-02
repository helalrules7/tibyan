import 'dart:math' as math;
import 'dart:typed_data';

import 'tensor_file.dart';

/// multilingual-e5-small (a 12-layer BERT encoder, 384 wide) run in plain
/// Dart from the pack's `model.bin`: linear weights and word embeddings are
/// int8 with one scale per output row; everything else is float32. The
/// word-embedding table (96 MB) stays on disk and only the query's rows are
/// read. Output: the mean of the last layer over the tokens, normalised,
/// as sentence-transformers computes it.
class E5Model {
  E5Model(this._file)
    : hidden = _file.header['hidden'] as int,
      heads = _file.header['heads'] as int,
      eps = (_file.header['eps'] as num).toDouble(),
      maxPositions = _file.header['max_positions'] as int,
      _position = _file.f32('embeddings.position'),
      _type = _file.f32('embeddings.type'),
      _wordScale = _file.f32('embeddings.word.scale'),
      _embNorm = _Norm(_file, 'embeddings.norm'),
      _layers = [
        for (var i = 0; i < (_file.header['layers'] as int); i++)
          _Layer(_file, i),
      ];

  /// Opens `model.bin`, leaving the word embeddings on disk.
  factory E5Model.open(String path) =>
      E5Model(TensorFile.open(path, lazy: {'embeddings.word'}));

  final TensorFile _file;
  final int hidden;
  final int heads;
  final double eps;
  final int maxPositions;
  final Float32List _position;
  final Float32List _type;
  final Float32List _wordScale;
  final _Norm _embNorm;
  final List<_Layer> _layers;

  void close() => _file.close();

  /// The normalised sentence vector of the token ids [ids].
  Float32List embed(List<int> ids) {
    final n = ids.length;
    final d = hidden;
    final words = _file.rowsInt8('embeddings.word', ids);
    var h = Float32List(n * d);
    for (var t = 0; t < n; t++) {
      final scale = _wordScale[ids[t]];
      final po = t * d;
      for (var i = 0; i < d; i++) {
        h[po + i] = words[po + i] * scale + _position[po + i] + _type[i];
      }
    }
    _embNorm.apply(h, n, eps);
    for (final layer in _layers) {
      h = layer.apply(h, n, heads, eps);
    }
    final out = Float32List(d);
    for (var t = 0; t < n; t++) {
      for (var i = 0; i < d; i++) {
        out[i] += h[t * d + i];
      }
    }
    var norm = 0.0;
    for (var i = 0; i < d; i++) {
      norm += out[i] * out[i];
    }
    norm = math.sqrt(norm);
    for (var i = 0; i < d; i++) {
      out[i] /= norm;
    }
    return out;
  }
}

class _Linear {
  _Linear(TensorFile f, String name)
    : w = f.i8(name),
      scale = f.f32('$name.scale'),
      bias = f.f32('$name.bias'),
      outs = f.shape(name)[0],
      ins = f.shape(name)[1];

  final Int8List w;
  final Float32List scale;
  final Float32List bias;
  final int outs;
  final int ins;

  /// x: [n, ins] → [n, outs]. Four tokens share each pass over a weight
  /// row, so the weights are read a quarter as often.
  Float32List apply(Float32List x, int n) {
    final y = Float32List(n * outs);
    var t = 0;
    for (; t + 3 < n; t += 4) {
      final x0 = t * ins, x1 = x0 + ins, x2 = x1 + ins, x3 = x2 + ins;
      for (var o = 0; o < outs; o++) {
        final wo = o * ins;
        var a0 = 0.0, a1 = 0.0, a2 = 0.0, a3 = 0.0;
        for (var i = 0; i < ins; i++) {
          final wi = w[wo + i];
          a0 += wi * x[x0 + i];
          a1 += wi * x[x1 + i];
          a2 += wi * x[x2 + i];
          a3 += wi * x[x3 + i];
        }
        final s = scale[o], b = bias[o];
        y[t * outs + o] = a0 * s + b;
        y[(t + 1) * outs + o] = a1 * s + b;
        y[(t + 2) * outs + o] = a2 * s + b;
        y[(t + 3) * outs + o] = a3 * s + b;
      }
    }
    for (; t < n; t++) {
      final xo = t * ins;
      for (var o = 0; o < outs; o++) {
        final wo = o * ins;
        var a = 0.0;
        for (var i = 0; i < ins; i++) {
          a += w[wo + i] * x[xo + i];
        }
        y[t * outs + o] = a * scale[o] + bias[o];
      }
    }
    return y;
  }
}

class _Norm {
  _Norm(TensorFile f, String name)
    : weight = f.f32('$name.weight'),
      bias = f.f32('$name.bias');

  final Float32List weight;
  final Float32List bias;

  /// In place, per token.
  void apply(Float32List h, int n, double eps) {
    final d = weight.length;
    for (var t = 0; t < n; t++) {
      final o = t * d;
      var mean = 0.0;
      for (var i = 0; i < d; i++) {
        mean += h[o + i];
      }
      mean /= d;
      var v = 0.0;
      for (var i = 0; i < d; i++) {
        final x = h[o + i] - mean;
        v += x * x;
      }
      final inv = 1 / math.sqrt(v / d + eps);
      for (var i = 0; i < d; i++) {
        h[o + i] = (h[o + i] - mean) * inv * weight[i] + bias[i];
      }
    }
  }
}

class _Layer {
  _Layer(TensorFile f, int i)
    : q = _Linear(f, 'layer.$i.q'),
      k = _Linear(f, 'layer.$i.k'),
      v = _Linear(f, 'layer.$i.v'),
      o = _Linear(f, 'layer.$i.o'),
      ffnIn = _Linear(f, 'layer.$i.ffn_in'),
      ffnOut = _Linear(f, 'layer.$i.ffn_out'),
      norm1 = _Norm(f, 'layer.$i.norm1'),
      norm2 = _Norm(f, 'layer.$i.norm2');

  final _Linear q, k, v, o, ffnIn, ffnOut;
  final _Norm norm1, norm2;

  Float32List apply(Float32List h, int n, int heads, double eps) {
    final d = q.outs;
    final hd = d ~/ heads;
    final qs = q.apply(h, n), ks = k.apply(h, n), vs = v.apply(h, n);
    final att = Float32List(n * d);
    final scores = Float64List(n);
    final inv = 1 / math.sqrt(hd);
    for (var head = 0; head < heads; head++) {
      final c = head * hd;
      for (var a = 0; a < n; a++) {
        var max = double.negativeInfinity;
        for (var b = 0; b < n; b++) {
          var s = 0.0;
          for (var i = 0; i < hd; i++) {
            s += qs[a * d + c + i] * ks[b * d + c + i];
          }
          s *= inv;
          scores[b] = s;
          if (s > max) max = s;
        }
        var sum = 0.0;
        for (var b = 0; b < n; b++) {
          scores[b] = math.exp(scores[b] - max);
          sum += scores[b];
        }
        for (var b = 0; b < n; b++) {
          final p = scores[b] / sum;
          for (var i = 0; i < hd; i++) {
            att[a * d + c + i] += p * vs[b * d + c + i];
          }
        }
      }
    }
    final h1 = o.apply(att, n);
    for (var i = 0; i < h1.length; i++) {
      h1[i] += h[i];
    }
    norm1.apply(h1, n, eps);
    final f = ffnIn.apply(h1, n);
    for (var i = 0; i < f.length; i++) {
      final x = f[i];
      f[i] = 0.5 * x * (1 + erf(x / math.sqrt2));
    }
    final h2 = ffnOut.apply(f, n);
    for (var i = 0; i < h2.length; i++) {
      h2[i] += h1[i];
    }
    norm2.apply(h2, n, eps);
    return h2;
  }
}

/// The error function, from Numerical Recipes' Chebyshev fit of erfc
/// (fractional error under 1.2e-7): enough for GELU in float32.
double erf(double x) {
  final z = x.abs();
  final t = 1 / (1 + 0.5 * z);
  final r =
      t *
      math.exp(
        -z * z -
            1.26551223 +
            t *
                (1.00002368 +
                    t *
                        (0.37409196 +
                            t *
                                (0.09678418 +
                                    t *
                                        (-0.18628806 +
                                            t *
                                                (0.27886807 +
                                                    t *
                                                        (-1.13520398 +
                                                            t *
                                                                (1.48851587 +
                                                                    t *
                                                                        (-0.82215223 +
                                                                            t * 0.17087277)))))))),
      );
  return x >= 0 ? 1 - r : r - 1;
}
