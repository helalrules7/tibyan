import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tibyan/features/mushaf/data/page_pack.dart';

/// The search-by-meaning pack installs like the page packs: the whole zip
/// against its SHA-256, then each file against the manifest.
void main() {
  File zipOf(Map<String, List<int>> files, {Map<String, String>? hashes}) {
    final manifest = {
      'id': 'semantic-test',
      'files': [
        for (final e in files.entries)
          {
            'file': e.key,
            'sha256': hashes?[e.key] ?? sha256.convert(e.value).toString(),
          },
      ],
    };
    final archive = Archive();
    for (final e in files.entries) {
      archive.addFile(ArchiveFile.bytes(e.key, e.value));
    }
    archive.addFile(ArchiveFile.string('manifest.json', jsonEncode(manifest)));
    final dir = Directory.systemTemp.createTempSync('sem');
    return File(p.join(dir.path, 'pack.zip'))
      ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));
  }

  PagePackInstaller installer(File zip) => PagePackInstaller(
    root: Directory.systemTemp.createTempSync('root'),
    spec: PagePackSpec(
      id: 'semantic-test',
      url: 'https://example.invalid/x.zip',
      sha256: sha256.convert(zip.readAsBytesSync()).toString(),
      bytes: zip.lengthSync(),
      format: PackFormat.semantic,
    ),
  );

  test('installs every listed file, checked', () async {
    final zip = zipOf({
      'model.bin': List.filled(1000, 7),
      'vocab.tsv': utf8.encode('3\n0.0\t<s>\n'),
      'embeddings.bin': List.filled(64, 1),
    });
    final i = installer(zip);
    await i.installFrom(zip);
    expect(i.isInstalled, isTrue);
    for (final f in [
      'model.bin',
      'vocab.tsv',
      'embeddings.bin',
      'manifest.json',
    ]) {
      expect(File(p.join(i.dir.path, f)).existsSync(), isTrue, reason: f);
    }
    expect(File(p.join(i.dir.path, 'model.bin')).lengthSync(), 1000);
  });

  test('a file that does not match the manifest stops the install', () async {
    final zip = zipOf(
      {'model.bin': List.filled(10, 1)},
      hashes: {'model.bin': '0' * 64},
    );
    final i = installer(zip);
    await expectLater(i.installFrom(zip), throwsA(isA<FormatException>()));
    expect(i.isInstalled, isFalse);
  });

  test('the shipped spec points at the mirror and is in the list', () {
    expect(PagePackSpec.semantic.url, contains('tibyan.ahmedhelal.dev'));
    expect(PagePackSpec.semantic.sha256, hasLength(64));
    expect(PagePackSpec.all, contains(PagePackSpec.semantic));
  });
}
