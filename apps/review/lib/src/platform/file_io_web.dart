import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:sqlite3/wasm.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:web/web.dart' as web;

import 'file_io.dart';

const _path = '/review.db';

Future<PickedFile?> pickFile() {
  final done = Completer<PickedFile?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.db,.sqlite,.sqlite3';
  input.onchange = (web.Event _) {
    final file = input.files?.item(0);
    if (file == null) {
      done.complete(null);
      return;
    }
    file.arrayBuffer().toDart.then(
          (buffer) => done.complete(PickedFile(file.name, buffer.toDart.asUint8List())),
          onError: done.completeError,
        );
  }.toJS;
  input.click();
  return done.future;
}

void saveFile(String name, Uint8List bytes) {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'application/vnd.sqlite3'));
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = name
    ..click();
  Timer(const Duration(seconds: 5), () => web.URL.revokeObjectURL(url));
}

void guardUnsaved(bool on) {
  web.window.onbeforeunload = on
      ? (web.BeforeUnloadEvent e) {
          e.preventDefault();
        }.toJS
      : null;
}

WasmSqlite3? _sqlite;

Future<OpenedDatabase> openDatabase(Uint8List bytes) async {
  final sqlite = _sqlite ??= await WasmSqlite3.loadFromUrlString('sqlite3.wasm');
  final fs = InMemoryFileSystem(name: 'review-${DateTime.now().microsecondsSinceEpoch}');
  sqlite.registerVirtualFileSystem(fs, makeDefault: true);
  fs.fileData[_path] = Uint8Buffer()..addAll(bytes);
  return _WebDatabase(sqlite.open(_path, vfs: fs.name), fs);
}

class _WebDatabase implements OpenedDatabase {
  _WebDatabase(this.database, this._fs);

  @override
  final CommonDatabase database;
  final InMemoryFileSystem _fs;

  @override
  Uint8List export() => Uint8List.fromList(_fs.fileData[_path]!);
}
