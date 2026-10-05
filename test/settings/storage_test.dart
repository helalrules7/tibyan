import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tibyan/features/settings/storage.dart';

void write(String root, String rel, int bytes) {
  final f = File(p.join(root, rel))..createSync(recursive: true);
  f.writeAsBytesSync(List.filled(bytes, 1));
}

void main() {
  late Directory root;
  setUp(() => root = Directory.systemTemp.createTempSync('tibyan_storage'));
  tearDown(() => root.deleteSync(recursive: true));

  test('packs, audio, timing and unfinished downloads are listed', () async {
    write(root.path, 'packs/pages-a/001.svg', 100);
    write(root.path, 'packs/pages-a/002.svg', 50);
    write(root.path, 'packs/pages-b.zip.part', 30);
    write(root.path, 'audio/3/001.mp3', 200);
    write(root.path, 'audio/3/002.mp3', 300);
    write(root.path, 'audio/3/003.mp3.part', 10);
    write(root.path, 'timing/x.json', 7);
    write(root.path, 'user.db', 999); // not listed

    final list = await scanStorage(root.path);
    int size(StorageKind k, [String? id]) => list
        .where((e) => e.kind == k && (id == null || e.id == id))
        .single
        .bytes;
    expect(size(StorageKind.pack, 'pages-a'), 150);
    expect(size(StorageKind.audio, '3'), 500);
    expect(size(StorageKind.timing), 7);
    expect(size(StorageKind.partial), 40);
    expect(list.any((e) => e.paths.any((x) => x.endsWith('user.db'))), isFalse);
  });

  test('deleting an entry removes its files and reports the bytes', () async {
    write(root.path, 'audio/3/001.mp3', 200);
    write(root.path, 'audio/3/002.mp3', 300);
    final audio = (await scanStorage(root.path)).single;
    expect(deleteEntry(audio), 500);
    expect(File(p.join(root.path, 'audio/3/001.mp3')).existsSync(), isFalse);
    expect(await scanStorage(root.path), isEmpty);
  });
}
