import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

/// What the app keeps in its folder, for the storage screen: each mushaf
/// pack, each reciter's downloaded surahs, the search-by-meaning pack, the
/// timing updates, and the downloads that did not finish. Databases and the
/// reader's own data are not listed and never touched.
enum StorageKind { pack, audio, timing, partial }

class StorageEntry {
  const StorageEntry({
    required this.kind,
    required this.id,
    required this.bytes,
    required this.paths,
  });

  final StorageKind kind;

  /// The pack's id, the reciter's id, or a fixed word.
  final String id;
  final int bytes;

  /// What deleting it removes.
  final List<String> paths;
}

/// Size of a file or of everything under a folder; 0 when missing.
int sizeOf(String path) {
  final type = FileSystemEntity.typeSync(path, followLinks: false);
  if (type == FileSystemEntityType.file) return File(path).lengthSync();
  if (type != FileSystemEntityType.directory) return 0;
  var total = 0;
  for (final e in Directory(
    path,
  ).listSync(recursive: true, followLinks: false)) {
    if (e is File) {
      try {
        total += e.lengthSync();
      } on FileSystemException {
        // Gone while counting.
      }
    }
  }
  return total;
}

/// Lists [root]'s packs (`packs/<id>`), audio (`audio/<reciter>`), timing
/// updates (`timing`) and unfinished downloads (`*.part`), with sizes.
Future<List<StorageEntry>> scanStorage(String root) =>
    Isolate.run(() => _scan(root));

List<StorageEntry> _scan(String root) {
  final out = <StorageEntry>[];
  final packs = Directory(p.join(root, 'packs'));
  final partial = <String>[];
  if (packs.existsSync()) {
    for (final e in packs.listSync(followLinks: false)) {
      final name = p.basename(e.path);
      if (e is Directory) {
        out.add(
          StorageEntry(
            kind: StorageKind.pack,
            id: name,
            bytes: sizeOf(e.path),
            paths: [e.path],
          ),
        );
      } else if (name.endsWith('.part')) {
        partial.add(e.path);
      }
    }
  }
  final audio = Directory(p.join(root, 'audio'));
  if (audio.existsSync()) {
    for (final e in audio.listSync(followLinks: false)) {
      if (e is! Directory) continue;
      final files = e.listSync(followLinks: false);
      final done = [
        for (final f in files)
          if (f is File && !f.path.endsWith('.part')) f.path,
      ];
      partial.addAll([
        for (final f in files)
          if (f is File && f.path.endsWith('.part')) f.path,
      ]);
      if (done.isEmpty) continue;
      out.add(
        StorageEntry(
          kind: StorageKind.audio,
          id: p.basename(e.path),
          bytes: done.fold(0, (s, f) => s + File(f).lengthSync()),
          paths: done,
        ),
      );
    }
  }
  final timing = p.join(root, 'timing');
  if (Directory(timing).existsSync()) {
    final bytes = sizeOf(timing);
    if (bytes > 0) {
      out.add(
        StorageEntry(
          kind: StorageKind.timing,
          id: 'timing',
          bytes: bytes,
          paths: [timing],
        ),
      );
    }
  }
  if (partial.isNotEmpty) {
    out.add(
      StorageEntry(
        kind: StorageKind.partial,
        id: 'partial',
        bytes: partial.fold(0, (s, f) => s + sizeOf(f)),
        paths: partial,
      ),
    );
  }
  return out;
}

/// Removes what [entry] lists. Returns the bytes freed.
int deleteEntry(StorageEntry entry) {
  var freed = 0;
  for (final path in entry.paths) {
    final type = FileSystemEntity.typeSync(path, followLinks: false);
    if (type == FileSystemEntityType.notFound) continue;
    freed += sizeOf(path);
    if (type == FileSystemEntityType.directory) {
      Directory(path).deleteSync(recursive: true);
    } else {
      File(path).deleteSync();
    }
  }
  return freed;
}
