import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Saves pictures without a package: into a «Tibyan» album of the Photos
/// library on iOS (PHPhotoLibrary, AppDelegate.swift), Pictures/Tibyan
/// through MediaStore on Android (MainActivity.kt), and on macOS where the
/// reader chooses in the system's save panel (AppDelegate.swift).
abstract final class PhotoSaver {
  static const _channel = MethodChannel('app.tibyan/photos');

  /// Saves [files] (PNG). [saved] is false when the reader cancelled (the
  /// macOS panel); [folder] is the folder they went to, or null for the
  /// Photos library. Throws when they could not be saved.
  static Future<({bool saved, String? folder})> save(List<File> files) async {
    if (Platform.isIOS || Platform.isAndroid) {
      final ok = await _channel.invokeMethod<bool>('saveImages', {
        'paths': [for (final f in files) f.path],
      });
      if (ok != true) throw const FileSystemException('not saved');
      return (saved: true, folder: null);
    }
    if (Platform.isMacOS) {
      final folder = await _channel.invokeMethod<String>('saveImages', {
        'paths': [for (final f in files) f.path],
      });
      return (saved: folder != null, folder: folder);
    }
    final base =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'Tibyan'))
      ..createSync(recursive: true);
    for (final f in files) {
      await f.copy(p.join(dir.path, p.basename(f.path)));
    }
    return (saved: true, folder: dir.path);
  }
}
