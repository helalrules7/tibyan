import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Saves pictures where the system keeps photos, without a package: the
/// Photos library on iOS (PHPhotoLibrary, AppDelegate.swift), Pictures/
/// Tibyan through MediaStore on Android (MainActivity.kt), and
/// ~/Pictures/Tibyan on macOS (its sandbox may write there).
abstract final class PhotoSaver {
  static const _channel = MethodChannel('app.tibyan/photos');

  /// Saves [files] (PNG). Returns the folder they went to when it is a
  /// folder (macOS and the other desktops), or null for the Photos
  /// library. Throws when they could not be saved.
  static Future<String?> save(List<File> files) async {
    if (Platform.isIOS || Platform.isAndroid) {
      final ok = await _channel.invokeMethod<bool>('saveImages', {
        'paths': [for (final f in files) f.path],
      });
      if (ok != true) throw const FileSystemException('not saved');
      return null;
    }
    final Directory base;
    if (Platform.isMacOS) {
      // In the sandbox HOME is the app's container, whose Pictures is the
      // user's own (com.apple.security.assets.pictures.read-write).
      base = Directory(p.join(Platform.environment['HOME'] ?? '', 'Pictures'));
    } else {
      base =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
    }
    final dir = Directory(p.join(base.path, 'Tibyan'))
      ..createSync(recursive: true);
    for (final f in files) {
      await f.copy(p.join(dir.path, p.basename(f.path)));
    }
    return dir.path;
  }
}
