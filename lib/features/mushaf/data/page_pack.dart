import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// A downloadable set of mushaf pages.
class PagePackSpec {
  const PagePackSpec({
    required this.id,
    required this.url,
    required this.sha256,
    required this.bytes,
  });

  final String id;
  final String url;
  final String sha256;
  final int bytes;

  /// New Madina edition (1441H), Hafs: 604 SVG pages, each xz-compressed.
  /// Built by tools/build_page_pack.py; published as a GitHub release.
  static const madina1441 = PagePackSpec(
    id: 'pages-hafs-1441-v1',
    url: 'https://github.com/helalrules7/tibyan/releases/download/pages-hafs-1441-v1/pages-hafs-1441-v1.zip',
    sha256: '9013b4c47c96eb36b5c9b7ad2b25b43a5d09c939879d85f8976147fce9d4580e',
    bytes: 65649525,
  );
}

enum PackPhase { idle, downloading, verifying, installing, installed, failed }

class PackProgress {
  const PackProgress(
    this.phase, {
    this.received = 0,
    this.total = 0,
    this.error,
  });

  final PackPhase phase;
  final int received;
  final int total;
  final String? error;

  double get fraction => total == 0 ? 0 : received / total;
}

/// Downloads, verifies and installs a page pack under `root/<pack id>/`.
/// Downloads resume from where they stopped (HTTP Range). Nothing is
/// installed unless the whole file matches its SHA-256 and every page
/// matches the SHA-256 in the pack's manifest.
class PagePackInstaller {
  PagePackInstaller({
    required this.root,
    required this.spec,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final Directory root;
  final PagePackSpec spec;
  final http.Client _client;
  bool _cancelled = false;

  Directory get dir => Directory(p.join(root.path, spec.id));
  File get _part => File(p.join(root.path, '${spec.id}.zip.part'));
  File get _done => File(p.join(dir.path, '.installed'));

  bool get isInstalled => _done.existsSync();

  /// Stops the current download; the partial file is kept for resuming.
  void pause() => _cancelled = true;

  Stream<PackProgress> install() async* {
    _cancelled = false;
    if (isInstalled) {
      yield const PackProgress(PackPhase.installed);
      return;
    }
    root.createSync(recursive: true);
    try {
      var received = _part.existsSync() ? _part.lengthSync() : 0;
      if (received < spec.bytes) {
        final request = http.Request('GET', Uri.parse(spec.url));
        if (received > 0) request.headers['Range'] = 'bytes=$received-';
        final response = await _client.send(request);
        if (response.statusCode == 200) {
          received = 0; // server ignored Range: start over
        } else if (response.statusCode != 206) {
          throw HttpException('HTTP ${response.statusCode}');
        }
        final sink = _part.openWrite(
          mode: received == 0 ? FileMode.write : FileMode.append,
        );
        try {
          await for (final chunk in response.stream) {
            if (_cancelled) break;
            sink.add(chunk);
            received += chunk.length;
            yield PackProgress(
              PackPhase.downloading,
              received: received,
              total: spec.bytes,
            );
          }
        } finally {
          await sink.close();
        }
        if (_cancelled) {
          yield PackProgress(
            PackPhase.idle,
            received: received,
            total: spec.bytes,
          );
          return;
        }
      }

      yield PackProgress(
        PackPhase.verifying,
        received: received,
        total: spec.bytes,
      );
      final partPath = _part.path;
      // Hash in chunks so a 65 MB file never sits in memory at once.
      final digest = (await sha256.bind(File(partPath).openRead()).first)
          .toString();
      if (digest != spec.sha256) {
        _part.deleteSync();
        throw const FormatException(
          'The download is damaged. Please try again.',
        );
      }

      yield PackProgress(
        PackPhase.installing,
        received: received,
        total: spec.bytes,
      );
      final target = dir.path;
      await Isolate.run(() => _extractAndVerify(partPath, target));
      _done.writeAsStringSync(DateTime.now().toIso8601String());
      _part.deleteSync();
      yield PackProgress(
        PackPhase.installed,
        received: spec.bytes,
        total: spec.bytes,
      );
    } catch (e) {
      yield PackProgress(PackPhase.failed, error: e.toString());
    }
  }

  static void _extractAndVerify(String zipPath, String targetDir) {
    // Stream from disk: pages are read one at a time, not the whole zip.
    final input = InputFileStream(zipPath);
    final archive = ZipDecoder().decodeStream(input);
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) throw const FormatException('Missing manifest');
    final manifest =
        jsonDecode(utf8.decode(manifestFile.content)) as Map<String, dynamic>;
    final expected = {
      for (final f in manifest['files'] as List)
        (f as Map)['file'] as String: f['xz_sha256'] as String,
    };
    Directory(targetDir).createSync(recursive: true);
    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      final bytes = entry.content;
      if (entry.name != 'manifest.json' &&
          sha256.convert(bytes).toString() != expected[entry.name]) {
        throw FormatException('Page file damaged: ${entry.name}');
      }
      File(p.join(targetDir, entry.name)).writeAsBytesSync(bytes, flush: true);
    }
    input.closeSync();
  }
}

/// Reads one installed page as SVG text. Decompression runs off the UI
/// thread; recent pages are kept in memory for fast page turns.
class PageStore {
  PageStore(this.dir);

  final Directory dir;
  final _cache = <int, String>{};
  final _order = <int>[];
  static const _capacity = 6;

  Future<String> svg(int page) async {
    final hit = _cache[page];
    if (hit != null) return hit;
    final path = p.join(dir.path, '${page.toString().padLeft(3, '0')}.svg.xz');
    final text = await Isolate.run(
      () => utf8.decode(XZDecoder().decodeBytes(File(path).readAsBytesSync())),
    );
    _cache[page] = text;
    _order.add(page);
    if (_order.length > _capacity) _cache.remove(_order.removeAt(0));
    return text;
  }
}
