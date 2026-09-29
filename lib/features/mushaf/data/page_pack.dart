import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// How a pack's zip is laid out.
enum PackFormat {
  /// Our pack: `NNN.svg.xz` pages and a manifest with per-page SHA-256.
  svgXz,

  /// quran.com's `images_1024.zip`: `width_1024/pageNNN.png` and
  /// `databases/ayahinfo_1024.db` (glyph boxes).
  pngQuranCom,
}

/// A downloadable set of mushaf pages.
class PagePackSpec {
  const PagePackSpec({
    required this.id,
    required this.url,
    required this.sha256,
    required this.bytes,
    required this.format,
    this.fallbacks = const [],
  });

  final String id;

  /// Tried first: Tibyan's mirror, which is the fastest.
  final String url;

  /// The original sources, tried in order when [url] fails (same bytes,
  /// same SHA-256).
  final List<String> fallbacks;
  final String sha256;
  final int bytes;
  final PackFormat format;

  /// New Madina edition (1441H), Hafs: 604 SVG pages, each xz-compressed.
  /// Built by tools/build_page_pack.py; on Tibyan's mirror and as a GitHub
  /// release.
  static const madina1441 = PagePackSpec(
    id: 'pages-hafs-1441-v1',
    url: 'https://tibyan.ahmedhelal.dev/mirror/packs/pages-hafs-1441-v1.zip',
    sha256: '9013b4c47c96eb36b5c9b7ad2b25b43a5d09c939879d85f8976147fce9d4580e',
    bytes: 65649525,
    format: PackFormat.svgXz,
    fallbacks: [
      'https://github.com/helalrules7/tibyan/releases/download/pages-hafs-1441-v1/pages-hafs-1441-v1.zip',
    ],
  );

  /// Old Madina edition (1405H), Hafs: 604 PNG pages and glyph boxes,
  /// from Tibyan's mirror, with quran.com as the fallback.
  static const madina1405 = PagePackSpec(
    id: 'pages-hafs-1405-qurancom-1024',
    url: 'https://tibyan.ahmedhelal.dev/mirror/packs/pages-hafs-1405-qurancom-1024.zip',
    sha256: '401b432deb2c7415818116d9b36db34c31e405f652b0206926da851943286b85',
    bytes: 63441877,
    format: PackFormat.pngQuranCom,
    fallbacks: ['https://files.quran.app/hafs/madani/zips/images_1024.zip'],
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
        // Tibyan's mirror first, then each original source, until one
        // answers.
        http.StreamedResponse? response;
        Object? lastError;
        for (final url in [spec.url, ...spec.fallbacks]) {
          try {
            final request = http.Request('GET', Uri.parse(url));
            if (received > 0) request.headers['Range'] = 'bytes=$received-';
            final r = await _client.send(request);
            if (r.statusCode == 200 || r.statusCode == 206) {
              response = r;
              break;
            }
            lastError = HttpException('HTTP ${r.statusCode}');
          } on Exception catch (e) {
            lastError = e;
          }
        }
        if (response == null) {
          throw lastError ?? const HttpException('No source');
        }
        if (response.statusCode == 200) {
          received = 0; // server ignored Range: start over
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
      final format = spec.format;
      await Isolate.run(
        () => format == PackFormat.svgXz
            ? _extractAndVerify(partPath, target)
            : _extractQuranCom(partPath, target),
      );
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

/// Keeps the 604 page images and the glyph database. The whole zip was
/// already checked against its SHA-256.
void _extractQuranCom(String zipPath, String targetDir) {
  final input = InputFileStream(zipPath);
  final archive = ZipDecoder().decodeStream(input);
  final pageName = RegExp(r'^width_1024/page(\d{3})\.png$');
  Directory(targetDir).createSync(recursive: true);
  var pages = 0;
  var glyphs = false;
  for (final entry in archive.files) {
    if (!entry.isFile) continue;
    final m = pageName.firstMatch(entry.name);
    final String out;
    if (m != null) {
      out = 'p${m[1]}.png';
      pages++;
    } else if (entry.name == 'databases/ayahinfo_1024.db') {
      out = 'ayahinfo.db';
      glyphs = true;
    } else {
      continue;
    }
    File(p.join(targetDir, out)).writeAsBytesSync(entry.content, flush: true);
  }
  input.closeSync();
  if (pages != 604 || !glyphs) {
    throw const FormatException('The page pack is incomplete.');
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
