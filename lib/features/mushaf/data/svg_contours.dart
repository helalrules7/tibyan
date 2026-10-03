import 'dart:typed_data';
import 'dart:ui';

/// The contours of a new-edition page's text: one [Path] per moveto of the
/// text paths inside `<g id="content">` (verse outlines left out), in
/// document order and in page (viewBox) units. The same order as
/// tools/build_word_boxes.py `read_page`, so the contour numbers in
/// content.db (`tajweed_page`) point at the same shapes.
///
/// The artwork is only read: nothing here changes or redraws the page.
///
/// [wanted] limits the paths built to those contour numbers (all others
/// are still read, to keep the numbering).
Map<int, Path> pageContours(String svg, {Set<int>? wanted}) {
  final out = <int, Path>{};
  var next = 0;
  final stack = <(_Matrix, bool)>[(_Matrix.identity, false)];
  for (final m in _tag.allMatches(svg)) {
    final closing = m[1] == '/';
    final name = m[2]!;
    final attrs = m[3]!;
    final selfClosing = m[4] == '/';
    if (closing) {
      if (name == 'g' && stack.length > 1) stack.removeLast();
      continue;
    }
    final (parent, parentInContent) = stack.last;
    final matrix = parent.times(_parseTransform(_attr(attrs, 'transform')));
    final inContent = parentInContent || _attr(attrs, 'id') == 'content';
    if (name == 'path') {
      if (inContent && _attr(attrs, 'class') != 'ayahPolygon') {
        final d = _attr(attrs, 'd');
        if (d != null) {
          final first = next;
          final paths = subpaths(
            d,
            keep: wanted == null ? null : (k) => wanted.contains(first + k),
          );
          for (final (k, p) in paths) {
            out[first + k] = p.transform(matrix.storage);
          }
          next += _moves(d);
        }
      }
      if (!selfClosing) stack.add((matrix, inContent));
    } else if (name == 'g' && !selfClosing) {
      stack.add((matrix, inContent));
    }
  }
  return out;
}

final _tag = RegExp(r'<(/?)(g|path)\b([^>]*?)(/?)>');

String? _attr(String attrs, String name) =>
    RegExp('(?:^|\\s)$name="([^"]*)"').firstMatch(attrs)?[1];

final _num = r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?';
final _token = RegExp('[MmLlHhVvCcSsQqTtZz]|$_num');

/// Number of subpaths (movetos) in path data.
int _moves(String d) => RegExp('[Mm]').allMatches(d).length;

/// SVG path data split at each moveto: (subpath number, path) for each
/// subpath [keep] accepts (all when null).
List<(int, Path)> subpaths(String d, {bool Function(int)? keep}) {
  final toks = [for (final m in _token.allMatches(d)) m[0]!];
  final out = <(int, Path)>[];
  Path? cur;
  var n = -1;
  var i = 0;
  String? cmd;
  var x = 0.0, y = 0.0, sx = 0.0, sy = 0.0;
  // Last control point, for the smooth curve commands.
  var cx = 0.0, cy = 0.0;
  String? last;
  double num() => double.parse(toks[i++]);
  bool isCommand(String t) => RegExp('^[A-Za-z]\$').hasMatch(t);

  while (i < toks.length) {
    if (isCommand(toks[i])) {
      cmd = toks[i++];
      if (cmd == 'Z' || cmd == 'z') {
        cur?.close();
        x = sx;
        y = sy;
        last = 'Z';
        continue;
      }
    }
    if (cmd == null) break;
    final rel = cmd == cmd.toLowerCase();
    final c = cmd.toUpperCase();
    double ax(double v) => rel ? x + v : v;
    double ay(double v) => rel ? y + v : v;
    switch (c) {
      case 'M':
        final nx = ax(num()), ny = ay(num());
        x = sx = nx;
        y = sy = ny;
        n++;
        if (keep == null || keep(n)) {
          cur = Path()..moveTo(x, y);
          out.add((n, cur));
        } else {
          cur = null;
        }
        cmd = rel ? 'l' : 'L';
      case 'L':
        final nx = ax(num()), ny = ay(num());
        x = nx;
        y = ny;
        cur?.lineTo(x, y);
      case 'H':
        x = ax(num());
        cur?.lineTo(x, y);
      case 'V':
        y = ay(num());
        cur?.lineTo(x, y);
      case 'C':
        final x1 = ax(num()), y1 = ay(num());
        final x2 = ax(num()), y2 = ay(num());
        final nx = ax(num()), ny = ay(num());
        cur?.cubicTo(x1, y1, x2, y2, nx, ny);
        cx = x2;
        cy = y2;
        x = nx;
        y = ny;
      case 'S':
        final smooth = last == 'C' || last == 'S';
        final x1 = smooth ? 2 * x - cx : x, y1 = smooth ? 2 * y - cy : y;
        final x2 = ax(num()), y2 = ay(num());
        final nx = ax(num()), ny = ay(num());
        cur?.cubicTo(x1, y1, x2, y2, nx, ny);
        cx = x2;
        cy = y2;
        x = nx;
        y = ny;
      case 'Q':
        final x1 = ax(num()), y1 = ay(num());
        final nx = ax(num()), ny = ay(num());
        cur?.quadraticBezierTo(x1, y1, nx, ny);
        cx = x1;
        cy = y1;
        x = nx;
        y = ny;
      case 'T':
        final smooth = last == 'Q' || last == 'T';
        final x1 = smooth ? 2 * x - cx : x, y1 = smooth ? 2 * y - cy : y;
        final nx = ax(num()), ny = ay(num());
        cur?.quadraticBezierTo(x1, y1, nx, ny);
        cx = x1;
        cy = y1;
        x = nx;
        y = ny;
      default:
        i++;
    }
    last = c;
  }
  return out;
}

class _Matrix {
  const _Matrix(this.a, this.b, this.c, this.d, this.e, this.f);

  static const identity = _Matrix(1, 0, 0, 1, 0, 0);

  final double a, b, c, d, e, f;

  _Matrix times(_Matrix n) => _Matrix(
    a * n.a + c * n.b,
    b * n.a + d * n.b,
    a * n.c + c * n.d,
    b * n.c + d * n.d,
    a * n.e + c * n.f + e,
    b * n.e + d * n.f + f,
  );

  Float64List get storage =>
      Float64List.fromList([a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, e, f, 0, 1]);
}

_Matrix _parseTransform(String? text) {
  var m = _Matrix.identity;
  if (text == null) return m;
  for (final t in RegExp(r'(\w+)\(([^)]*)\)').allMatches(text)) {
    final v = [
      for (final n in RegExp(_num).allMatches(t[2]!)) double.parse(n[0]!),
    ];
    final n = switch (t[1]) {
      'matrix' => _Matrix(v[0], v[1], v[2], v[3], v[4], v[5]),
      'translate' => _Matrix(1, 0, 0, 1, v[0], v.length > 1 ? v[1] : 0),
      'scale' => _Matrix(v[0], 0, 0, v.length > 1 ? v[1] : v[0], 0, 0),
      _ => _Matrix.identity,
    };
    m = m.times(n);
  }
  return m;
}
