import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// A tensor file of the search-by-meaning pack, as written by
/// `tools/build_semantic_pack.py`: `TBE5`, a version and a header length
/// (u32 little-endian), a JSON header, then 16-byte aligned tensors at the
/// header's offsets, counted from the start of the data section.
class TensorFile {
  TensorFile._(this.header, this._data, this._base, this.dataStart, this._file);

  /// A file already in memory.
  factory TensorFile.bytes(Uint8List bytes) {
    final (header, start) = _header(bytes);
    return TensorFile._(header, bytes, 0, start, null);
  }

  /// Reads the header and every tensor except the [lazy] ones, which stay
  /// on disk and are read row by row with [rowsInt8].
  factory TensorFile.open(String path, {Set<String> lazy = const {}}) {
    final file = File(path).openSync();
    final fixed = file.readSync(12);
    if (fixed.length < 12) throw const FormatException('Truncated file');
    final length = ByteData.sublistView(fixed).getUint32(8, Endian.little);
    file.setPositionSync(0);
    final (header, start) = _header(file.readSync(12 + length));
    final tensors = (header['tensors'] as Map).cast<String, dynamic>();
    int? from;
    var end = 0;
    for (final e in tensors.entries) {
      if (lazy.contains(e.key)) continue;
      final t = e.value as Map;
      final o = t['offset'] as int;
      if (from == null || o < from) from = o;
      if (o + _size(t) > end) end = o + _size(t);
    }
    from ??= 0;
    // Only the span of the tensors kept in memory is read.
    file.setPositionSync(start + from);
    final data = Uint8List(end - from);
    file.readIntoSync(data);
    return TensorFile._(header, data, start + from, start, file);
  }

  final Map<String, dynamic> header;
  final Uint8List _data;

  /// File offset of `_data[0]`.
  final int _base;
  final int dataStart;
  final RandomAccessFile? _file;

  Map<String, dynamic> _t(String name) {
    final t = (header['tensors'] as Map)[name];
    if (t == null) throw FormatException('Missing tensor $name');
    return (t as Map).cast<String, dynamic>();
  }

  List<int> shape(String name) => (_t(name)['shape'] as List).cast<int>();

  int _at(Map t) => dataStart + (t['offset'] as int) - _base;

  Float32List f32(String name) {
    final t = _t(name);
    if (t['dtype'] != 'f32') throw FormatException('$name is not f32');
    final n = _count(t);
    final at = _at(t);
    if ((_data.offsetInBytes + at) % 4 == 0) {
      return _data.buffer.asFloat32List(_data.offsetInBytes + at, n);
    }
    return Uint8List.fromList(_data.sublist(at, at + n * 4)).buffer
        .asFloat32List();
  }

  Int8List i8(String name) {
    final t = _t(name);
    if (t['dtype'] != 'i8') throw FormatException('$name is not i8');
    return _data.buffer.asInt8List(_data.offsetInBytes + _at(t), _count(t));
  }

  /// Rows [rows] of a 2-D int8 tensor left on disk.
  Int8List rowsInt8(String name, List<int> rows) {
    final t = _t(name);
    final width = (t['shape'] as List)[1] as int;
    final out = Uint8List(rows.length * width);
    final file = _file;
    if (file == null) {
      final all = i8(name);
      for (final (i, r) in rows.indexed) {
        out.buffer.asInt8List().setRange(
          i * width,
          (i + 1) * width,
          all,
          r * width,
        );
      }
      return out.buffer.asInt8List();
    }
    for (final (i, r) in rows.indexed) {
      file.setPositionSync(dataStart + (t['offset'] as int) + r * width);
      file.readIntoSync(out, i * width, (i + 1) * width);
    }
    return out.buffer.asInt8List();
  }

  void close() => _file?.closeSync();

  static int _count(Map t) =>
      (t['shape'] as List).fold<int>(1, (n, d) => n * (d as int));

  static int _size(Map t) => _count(t) * (t['dtype'] == 'f32' ? 4 : 1);

  static (Map<String, dynamic>, int) _header(Uint8List bytes) {
    if (bytes.length < 12 ||
        String.fromCharCodes(bytes.sublist(0, 4)) != 'TBE5') {
      throw const FormatException('Not a Tibyan tensor file');
    }
    final b = ByteData.sublistView(bytes);
    final version = b.getUint32(4, Endian.little);
    if (version != 1) throw FormatException('Unknown version $version');
    final length = b.getUint32(8, Endian.little);
    final header = jsonDecode(
      utf8.decode(bytes.sublist(12, 12 + length)),
    ) as Map<String, dynamic>;
    final start = 12 + length + ((16 - (12 + length) % 16) % 16);
    return (header, start);
  }
}
