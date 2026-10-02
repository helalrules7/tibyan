import 'dart:typed_data';

import 'package:sqlite3/common.dart';

import 'file_io_stub.dart' if (dart.library.js_interop) 'file_io_web.dart' as impl;

/// A file the person picked.
class PickedFile {
  const PickedFile(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

/// An open review database, ready to be saved back as a file.
abstract class OpenedDatabase {
  CommonDatabase get database;
  Uint8List export();
}

Future<PickedFile?> pickFile() => impl.pickFile();

/// Starts a download of [bytes] named [name].
void saveFile(String name, Uint8List bytes) => impl.saveFile(name, bytes);

/// Asks the browser to confirm leaving the page while [on].
void guardUnsaved(bool on) => impl.guardUnsaved(on);

/// Opens a database from bytes (in memory; nothing touches the disk).
Future<OpenedDatabase> openDatabase(Uint8List bytes) => impl.openDatabase(bytes);
