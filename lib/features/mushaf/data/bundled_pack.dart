import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'page_pack.dart';

/// The new Madina edition ships inside the app, so the mushaf opens on
/// first launch without a download. The asset is the same zip as the
/// published pack and passes the same SHA-256 check.
const bundledPackAsset = 'assets/packs/pages-hafs-1441-v1.zip';

/// Installs the bundled pack under [root] unless it is there already.
Future<void> installBundledPack(AssetBundle bundle, Directory root) async {
  final installer = PagePackInstaller(
    root: root,
    spec: PagePackSpec.madina1441,
  );
  if (installer.isInstalled) return;
  root.createSync(recursive: true);
  final data = await bundle.load(bundledPackAsset);
  final zip = File(
    p.join(root.path, 'bundled-${PagePackSpec.madina1441.id}.zip'),
  );
  await zip.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    flush: true,
  );
  await installer.installFrom(zip);
}
