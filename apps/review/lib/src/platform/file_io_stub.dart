import 'dart:typed_data';

import 'file_io.dart';

// The tool runs in the browser. Tests use SqliteReviewStore directly.

Future<PickedFile?> pickFile() => throw UnsupportedError('open the review tool in a browser');

void saveFile(String name, Uint8List bytes) => throw UnsupportedError('open the review tool in a browser');

void guardUnsaved(bool on) {}

Future<OpenedDatabase> openDatabase(Uint8List bytes) =>
    throw UnsupportedError('open the review tool in a browser');
