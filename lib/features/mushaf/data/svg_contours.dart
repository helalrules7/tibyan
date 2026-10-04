import 'dart:typed_data';
import 'dart:ui';

/// One contour of a page's text as plain data: its drawing commands and
/// their points, already in page (viewBox) units. Built without dart:ui,
/// so a worker isolate can read a page's contours; [toPath] makes the
/// [Path] on the main isolate, which costs little next to reading the SVG.
class ContourGeometry {
  ContourGeometry(this.verbs, this.points);

  /// [moveVerb], [lineVerb], [quadVerb], [cubicVerb] or [closeVerb].
  final Uint8List verbs;

  /// The points of [verbs], x then y: one point for a move or a line, two
  /// for a quadratic curve, three for a cubic one, none for a close.
  final Float64List points;

  static const moveVerb = 0;
  static const lineVerb = 1;
  static const quadVerb = 2;
  static const cubicVerb = 3;
  static const closeVerb = 4;

  /// The bounds of all the points, control points included (what
  /// [Path.getBounds] gives for the same contour).
  Rect get bounds {
    if (points.isEmpty) return Rect.zero;
    var l = points[0], r = points[0], t = points[1], b = points[1];
    for (var i = 2; i < points.length; i += 2) {
      final x = points[i], y = points[i + 1];
      if (x < l) l = x;
      if (x > r) r = x;
      if (y < t) t = y;
      if (y > b) b = y;
    }
    return Rect.fromLTRB(l, t, r, b);
  }

  Path toPath() {
    final p = Path();
    var k = 0;
    for (final v in verbs) {
      switch (v) {
        case moveVerb:
          p.moveTo(points[k], points[k + 1]);
          k += 2;
        case lineVerb:
          p.lineTo(points[k], points[k + 1]);
          k += 2;
        case quadVerb:
          p.quadraticBezierTo(
            points[k],
            points[k + 1],
            points[k + 2],
            points[k + 3],
          );
          k += 4;
        case cubicVerb:
          p.cubicTo(
            points[k],
            points[k + 1],
            points[k + 2],
            points[k + 3],
            points[k + 4],
            points[k + 5],
          );
          k += 6;
        default:
          p.close();
      }
    }
    return p;
  }
}

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
Map<int, Path> pageContours(String svg, {Set<int>? wanted}) => {
  for (final MapEntry(:key, :value) in pageContourGeometry(
    svg,
    wanted: wanted,
  ).entries)
    key: value.toPath(),
};

/// [pageContours] as plain data, without dart:ui: what a worker isolate
/// can build.
Map<int, ContourGeometry> pageContourGeometry(String svg, {Set<int>? wanted}) {
  final out = <int, ContourGeometry>{};
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
          // Paths none of whose contours are wanted are only counted.
          final moves = _moves(d);
          if (wanted == null ||
              wanted.any((c) => c >= first && c < first + moves)) {
            for (final (k, g) in _subpathGeometry(
              d,
              wanted == null ? null : (k) => wanted.contains(first + k),
              matrix,
            )) {
              out[first + k] = g;
            }
          }
          next += moves;
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

/// Number of subpaths (movetos) in path data.
int _moves(String d) {
  var n = 0;
  for (var i = 0; i < d.length; i++) {
    final c = d.codeUnitAt(i);
    if (c == 0x4D || c == 0x6D) n++;
  }
  return n;
}

/// SVG path data split at each moveto: (subpath number, path) for each
/// subpath [keep] accepts (all when null).
List<(int, Path)> subpaths(String d, {bool Function(int)? keep}) => [
  for (final (n, g) in subpathGeometry(d, keep: keep)) (n, g.toPath()),
];

bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

/// The tokens of path data, as `[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?`
/// or one of the command letters reads them (anything else is skipped):
/// a command letter's code in [kinds], or 0 and the number in [values].
({List<int> kinds, List<double> values}) _tokens(String d) {
  final kinds = <int>[];
  final values = <double>[];
  final n = d.length;
  int at(int i) => i < n ? d.codeUnitAt(i) : -1;
  var i = 0;
  while (i < n) {
    final c = d.codeUnitAt(i);
    if (_commands.contains(c)) {
      kinds.add(c);
      values.add(0);
      i++;
      continue;
    }
    var j = i;
    if (c == 0x2B || c == 0x2D) j++; // + -
    if (_isDigit(at(j))) {
      while (_isDigit(at(j))) {
        j++;
      }
      if (at(j) == 0x2E) {
        j++;
        while (_isDigit(at(j))) {
          j++;
        }
      }
    } else if (at(j) == 0x2E && _isDigit(at(j + 1))) {
      j += 2;
      while (_isDigit(at(j))) {
        j++;
      }
    } else {
      i++;
      continue;
    }
    if (at(j) == 0x45 || at(j) == 0x65) {
      var k = j + 1;
      if (at(k) == 0x2B || at(k) == 0x2D) k++;
      if (_isDigit(at(k))) {
        while (_isDigit(at(k))) {
          k++;
        }
        j = k;
      }
    }
    kinds.add(0);
    values.add(double.parse(d.substring(i, j)));
    i = j;
  }
  return (kinds: kinds, values: values);
}

/// MmLlHhVvCcSsQqTtZz.
final _commands = {for (final c in 'MmLlHhVvCcSsQqTtZz'.codeUnits) c};

/// [subpaths] as plain data.
List<(int, ContourGeometry)> subpathGeometry(
  String d, {
  bool Function(int)? keep,
}) => _subpathGeometry(d, keep, _Matrix.identity);

/// [subpathGeometry], each point through [m].
List<(int, ContourGeometry)> _subpathGeometry(
  String d,
  bool Function(int)? keep,
  _Matrix m,
) {
  final (:kinds, :values) = _tokens(d);
  final out = <(int, ContourGeometry)>[];
  // The subpath being built, null when it is not kept.
  List<int>? verbs;
  List<double>? points;
  void finish() {
    if (verbs != null) {
      out.last = (
        out.last.$1,
        ContourGeometry(
          Uint8List.fromList(verbs),
          Float64List.fromList(points!),
        ),
      );
    }
  }

  void add(int verb, List<double> xy) {
    if (verbs == null) return;
    verbs.add(verb);
    for (var k = 0; k < xy.length; k += 2) {
      points!
        ..add(m.a * xy[k] + m.c * xy[k + 1] + m.e)
        ..add(m.b * xy[k] + m.d * xy[k + 1] + m.f);
    }
  }

  var n = -1;
  var i = 0;
  int? cmd;
  var x = 0.0, y = 0.0, sx = 0.0, sy = 0.0;
  // Last control point, for the smooth curve commands.
  var cx = 0.0, cy = 0.0;
  int? last;
  double num() {
    if (kinds[i] != 0) {
      throw FormatException('a number expected in path data', d);
    }
    return values[i++];
  }

  const z = 0x5A, bigM = 0x4D, bigL = 0x4C, bigH = 0x48, bigV = 0x56;
  const bigC = 0x43, bigS = 0x53, bigQ = 0x51, bigT = 0x54;
  while (i < kinds.length) {
    if (kinds[i] != 0) {
      cmd = kinds[i++];
      if (cmd == z || cmd == 0x7A) {
        add(ContourGeometry.closeVerb, const []);
        x = sx;
        y = sy;
        last = z;
        continue;
      }
    }
    if (cmd == null) break;
    // Lower case letters are 0x20 above their capitals.
    final rel = cmd >= 0x61;
    final c = rel ? cmd - 0x20 : cmd;
    double ax(double v) => rel ? x + v : v;
    double ay(double v) => rel ? y + v : v;
    switch (c) {
      case bigM:
        final nx = ax(num()), ny = ay(num());
        x = sx = nx;
        y = sy = ny;
        n++;
        finish();
        if (keep == null || keep(n)) {
          verbs = [];
          points = [];
          out.add((n, ContourGeometry(Uint8List(0), Float64List(0))));
          add(ContourGeometry.moveVerb, [x, y]);
        } else {
          verbs = null;
          points = null;
        }
        cmd = rel ? 0x6C : bigL;
      case bigL:
        final nx = ax(num()), ny = ay(num());
        x = nx;
        y = ny;
        add(ContourGeometry.lineVerb, [x, y]);
      case bigH:
        x = ax(num());
        add(ContourGeometry.lineVerb, [x, y]);
      case bigV:
        y = ay(num());
        add(ContourGeometry.lineVerb, [x, y]);
      case bigC:
        final x1 = ax(num()), y1 = ay(num());
        final x2 = ax(num()), y2 = ay(num());
        final nx = ax(num()), ny = ay(num());
        add(ContourGeometry.cubicVerb, [x1, y1, x2, y2, nx, ny]);
        cx = x2;
        cy = y2;
        x = nx;
        y = ny;
      case bigS:
        final smooth = last == bigC || last == bigS;
        final x1 = smooth ? 2 * x - cx : x, y1 = smooth ? 2 * y - cy : y;
        final x2 = ax(num()), y2 = ay(num());
        final nx = ax(num()), ny = ay(num());
        add(ContourGeometry.cubicVerb, [x1, y1, x2, y2, nx, ny]);
        cx = x2;
        cy = y2;
        x = nx;
        y = ny;
      case bigQ:
        final x1 = ax(num()), y1 = ay(num());
        final nx = ax(num()), ny = ay(num());
        add(ContourGeometry.quadVerb, [x1, y1, nx, ny]);
        cx = x1;
        cy = y1;
        x = nx;
        y = ny;
      case bigT:
        final smooth = last == bigQ || last == bigT;
        final x1 = smooth ? 2 * x - cx : x, y1 = smooth ? 2 * y - cy : y;
        final nx = ax(num()), ny = ay(num());
        add(ContourGeometry.quadVerb, [x1, y1, nx, ny]);
        cx = x1;
        cy = y1;
        x = nx;
        y = ny;
      default:
        i++;
    }
    last = c;
  }
  finish();
  return out;
}

/// A 2D affine transform (SVG `matrix(a b c d e f)`).
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
