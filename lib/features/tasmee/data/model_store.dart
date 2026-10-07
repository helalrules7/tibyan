import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'model_manifest.dart';

/// A model that is fully on disk and was checked when it was installed.
class InstalledModel {
  const InstalledModel({required this.manifest, required this.directory});

  final ModelManifest manifest;
  final Directory directory;

  File file(String name) => File(p.join(directory.path, name));
}

/// Where recognition models live: `<root>/<id>/<version>/`. A model counts
/// as installed only when `installed.json` is there, and that is written
/// last, after every file passed its checksum, so a download that was
/// killed half way is never mistaken for a usable model.
class ModelStore {
  ModelStore(this.root);

  /// The app's persistent folder (not the cache, which the system may clear).
  static Future<ModelStore> inAppSupport() async {
    final base = await getApplicationSupportDirectory();
    return ModelStore(Directory(p.join(base.path, 'recitation_models')));
  }

  final Directory root;

  static const markerName = 'installed.json';

  Directory directoryFor(ModelManifest m) =>
      Directory(p.join(root.path, m.id, m.version));

  /// The usable installed version of [id], or null.
  Future<InstalledModel?> installed(String id) async {
    final idDir = Directory(p.join(root.path, id));
    if (!await idDir.exists()) return null;
    final versions = [
      await for (final e in idDir.list())
        if (e is Directory) e,
    ]..sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
    for (final dir in versions) {
      final model = await _readValid(dir);
      if (model != null && model.manifest.id == id) return model;
    }
    return null;
  }

  /// The installed copy of exactly [m] (same version and checksums), or null.
  Future<InstalledModel?> installedFor(ModelManifest m) async {
    final model = await _readValid(directoryFor(m));
    if (model == null) return null;
    final a = model.manifest;
    if (a.id != m.id || a.version != m.version) return null;
    if (a.files.length != m.files.length) return null;
    for (var i = 0; i < m.files.length; i++) {
      if (a.files[i].name != m.files[i].name ||
          a.files[i].sha256 != m.files[i].sha256) {
        return null;
      }
    }
    return model;
  }

  /// Marks [m] installed (all of its files must already be in place), then
  /// removes every other version of the same model.
  Future<InstalledModel> markInstalled(ModelManifest m) async {
    final dir = directoryFor(m);
    final tmp = File(p.join(dir.path, 'installed.json.tmp'));
    await tmp.writeAsString(jsonEncode(m.toJson()), flush: true);
    await tmp.rename(p.join(dir.path, markerName));
    final idDir = Directory(p.join(root.path, m.id));
    await for (final e in idDir.list()) {
      if (e is Directory && p.basename(e.path) != m.version) {
        await e.delete(recursive: true);
      }
    }
    return InstalledModel(manifest: m, directory: dir);
  }

  /// Deletes every version of [id], including unfinished downloads.
  Future<void> delete(String id) async {
    final idDir = Directory(p.join(root.path, id));
    if (await idDir.exists()) await idDir.delete(recursive: true);
  }

  /// Disk space used by all models and unfinished downloads, in bytes.
  Future<int> usedBytes() async {
    if (!await root.exists()) return 0;
    var total = 0;
    await for (final e in root.list(recursive: true)) {
      if (e is File) total += await e.length();
    }
    return total;
  }

  Future<InstalledModel?> _readValid(Directory dir) async {
    final marker = File(p.join(dir.path, markerName));
    try {
      if (!await marker.exists()) return null;
      final json = jsonDecode(await marker.readAsString());
      if (json is! Map<String, dynamic>) return null;
      final manifest = ModelManifest.fromJson(json);
      if (manifest.version != p.basename(dir.path)) return null;
      for (final f in manifest.files) {
        final file = File(p.join(dir.path, f.name));
        if (!await file.exists() || await file.length() != f.bytes) {
          return null;
        }
      }
      return InstalledModel(manifest: manifest, directory: dir);
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }
}
