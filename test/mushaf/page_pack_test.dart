import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tibyan/features/mushaf/data/page_pack.dart';

/// Builds a tiny pack in the same format as tools/build_page_pack.py.
List<int> buildPack({bool corruptPage = false}) {
  final svg = utf8.encode('<svg viewBox="0 0 345 550"></svg>');
  final xz = XZEncoder().encode(svg);
  final manifest = {
    'files': [
      {
        'page': 1,
        'file': '001.svg.xz',
        'xz_sha256': sha256.convert(xz).toString(),
      },
    ],
  };
  final archive = Archive()
    ..addFile(ArchiveFile.bytes('001.svg.xz', corruptPage ? [1, 2, 3] : xz))
    ..addFile(ArchiveFile.string('manifest.json', jsonEncode(manifest)));
  return ZipEncoder().encode(archive);
}

/// Builds a zip laid out like quran.com's images_1024.zip.
List<int> buildQuranComPack({int pages = 604, bool withGlyphs = true}) {
  final archive = Archive()..addFile(ArchiveFile.string('width_1024/.v8', ''));
  for (var i = 1; i <= pages; i++) {
    final name = 'width_1024/page${i.toString().padLeft(3, '0')}.png';
    archive.addFile(ArchiveFile.bytes(name, [i % 256]));
  }
  if (withGlyphs) {
    archive.addFile(ArchiveFile.bytes('databases/ayahinfo_1024.db', [0]));
  }
  archive.addFile(ArchiveFile.bytes('databases/quran.ar.db', [0]));
  return ZipEncoder().encode(archive);
}

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('tibyan_pack'));
  tearDown(() => tmp.deleteSync(recursive: true));

  PagePackInstaller installerFor(
    List<int> zip, {
    String? sha,
    PackFormat format = PackFormat.svgXz,
  }) => PagePackInstaller(
    root: tmp,
    spec: PagePackSpec(
      id: 'test-pack',
      url: 'https://example.invalid/pack.zip',
      sha256: sha ?? sha256.convert(zip).toString(),
      bytes: zip.length,
      format: format,
    ),
    client: MockClient((request) async => http.Response.bytes(zip, 200)),
  );

  test('installs a valid pack and reads a page', () async {
    final zip = buildPack();
    final installer = installerFor(zip);
    final phases = await installer.install().map((p) => p.phase).toList();
    expect(phases.last, PackPhase.installed);
    expect(installer.isInstalled, isTrue);
    final svg = await PageStore(installer.dir).svg(1);
    expect(svg, contains('viewBox'));
  });

  test('rejects a download whose checksum does not match', () async {
    final installer = installerFor(buildPack(), sha: 'ff' * 32);
    final last = await installer.install().last;
    expect(last.phase, PackPhase.failed);
    expect(installer.isInstalled, isFalse);
  });

  test('rejects a pack with a damaged page', () async {
    final installer = installerFor(buildPack(corruptPage: true));
    final last = await installer.install().last;
    expect(last.phase, PackPhase.failed);
    expect(installer.isInstalled, isFalse);
  });

  test('installs the old edition from a quran.com-style zip', () async {
    final installer = installerFor(
      buildQuranComPack(),
      format: PackFormat.pngQuranCom,
    );
    expect((await installer.install().last).phase, PackPhase.installed);
    expect(File('${installer.dir.path}/p001.png').existsSync(), isTrue);
    expect(File('${installer.dir.path}/p604.png').existsSync(), isTrue);
    expect(File('${installer.dir.path}/ayahinfo.db').existsSync(), isTrue);
    // Other files in quran.com's zip are not kept.
    expect(File('${installer.dir.path}/quran.ar.db').existsSync(), isFalse);
  });

  test('rejects a quran.com-style zip with missing pages or glyphs', () async {
    for (final zip in [
      buildQuranComPack(pages: 603),
      buildQuranComPack(withGlyphs: false),
    ]) {
      final installer = installerFor(zip, format: PackFormat.pngQuranCom);
      expect((await installer.install().last).phase, PackPhase.failed);
      expect(installer.isInstalled, isFalse);
    }
  });

  test('falls back to a mirror when the source fails', () async {
    final zip = buildPack();
    final installer = PagePackInstaller(
      root: tmp,
      spec: PagePackSpec(
        id: 'mirror-pack',
        url: 'https://source.invalid/pack.zip',
        mirrors: const ['https://mirror.invalid/pack.zip'],
        sha256: sha256.convert(zip).toString(),
        bytes: zip.length,
        format: PackFormat.svgXz,
      ),
      client: MockClient(
        (request) async => request.url.host == 'mirror.invalid'
            ? http.Response.bytes(zip, 200)
            : http.Response('down', 503),
      ),
    );
    expect((await installer.install().last).phase, PackPhase.installed);
  });
}
