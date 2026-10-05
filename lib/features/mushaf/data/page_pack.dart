import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../core/settings/app_settings.dart';

/// How a pack's zip is laid out.
enum PackFormat {
  /// Our pack: `NNN.svg.xz` pages and a manifest with per-page SHA-256.
  svgXz,

  /// quran.com's `images_1024.zip`: `width_1024/pageNNN.png` and
  /// `databases/ayahinfo_1024.db` (glyph boxes).
  pngQuranCom,

  /// The Shamarly page images as archived: `001.png` … `522.png` at the
  /// zip root. Their geometry is in content.db.
  pngShamarly,

  /// The search-by-meaning pack (tools/build_semantic_pack.py): the text
  /// encoder, its vocabulary and the verse vectors, with a manifest
  /// listing each file's SHA-256.
  semantic,

  /// A reviewed book pack (tools/export_pack.py): one SQLite file, not a
  /// zip, installed as [bookPackFile].
  book,
}

/// The file a reviewed book pack is installed as, in its pack folder.
const bookPackFile = 'book.db';

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

  /// Shamarly (Egyptian) edition, Hafs: 522 PNG pages (886 x 1377) from
  /// archive.org (details/shamerly), stored unchanged in one zip on
  /// Tibyan's mirror.
  static const shamarly = PagePackSpec(
    id: 'pages-hafs-shamarly-v1',
    url: 'https://tibyan.ahmedhelal.dev/mirror/sources/shamarly/shamarly-pages-archive-org.zip',
    sha256: '03199bf95590458df94670d6d1ba5f17e56ec72413df51dd30087aa5beaa712d',
    bytes: 214988080,
    format: PackFormat.pngShamarly,
    // No fallback: archive.org serves the pages one by one, never as this
    // zip, so no other source has the same bytes and SHA-256.
    fallbacks: [],
  );

  /// The KFGQPC Madina mushaf of a riwaya other than Hafs: its 604 SVG
  /// pages (quran-ws, the Complex's artwork unchanged), the riwaya's
  /// verses, verse map and page geometry (`riwaya.json.xz`) and its KFGQPC
  /// font. Built by tools/build_riwaya_packs.py; on Tibyan's mirror only
  /// (no other host serves these bytes).
  static PagePackSpec _riwaya(String riwaya, String sha256, int bytes) =>
      PagePackSpec(
        id: 'pages-$riwaya-v1',
        url: 'https://tibyan.ahmedhelal.dev/mirror/packs/pages-$riwaya-v1.zip',
        sha256: sha256,
        bytes: bytes,
        format: PackFormat.svgXz,
      );

  static final warsh = _riwaya(
    'warsh',
    '826e9be1da8a7b6dcd60f542d88fafcd030382576296b475fe1569c793409e51',
    78608758,
  );
  static final qalun = _riwaya(
    'qalun',
    '611b716755f3b6150d99017bf9a46d8cad3012092acae4216d2b16435c16d852',
    82756503,
  );
  static final douri = _riwaya(
    'douri',
    '3c3beaf4e0f69e5f4efd1a09af301997e529285f51194e2b7a25c5def381fe7a',
    70224157,
  );
  static final shubah = _riwaya(
    'shubah',
    '9fe1042cb316df8a84d724facaada1ae916f02c3e9ab32eaeaa3890be091bcbd',
    72332382,
  );

  /// Search by meaning (optional): multilingual-e5-small (MIT) as int8
  /// weights run in Dart, and one vector per verse of each meaning text in
  /// content.db. Built by tools/build_semantic_pack.py; on Tibyan's mirror.
  static const semantic = PagePackSpec(
    id: 'semantic-e5-small-v1',
    url: 'https://tibyan.ahmedhelal.dev/mirror/packs/semantic-e5-small-v1.zip',
    sha256: '841c6f5accea68d111513da400fb83138be06b41275abebe8d4c29baabc19f34',
    bytes: 134489900,
    format: PackFormat.semantic,
  );

  /// Every pack the app can download.
  static const all = [madina1441, madina1405, shamarly, semantic];

  static PagePackSpec of(MushafEdition edition) => switch (edition) {
    MushafEdition.madina1441 => madina1441,
    MushafEdition.madina1405 => madina1405,
    MushafEdition.shamarly => shamarly,
    MushafEdition.warsh => warsh,
    MushafEdition.qalun => qalun,
    MushafEdition.douri => douri,
    MushafEdition.shubah => shubah,
  };
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
      await installFrom(_part);
      yield PackProgress(
        PackPhase.installed,
        received: spec.bytes,
        total: spec.bytes,
      );
    } catch (e) {
      yield PackProgress(PackPhase.failed, error: e.toString());
    }
  }

  /// Checks a downloaded zip against the pack's SHA-256, then installs its
  /// pages. The zip is deleted either way. Throws when it is damaged.
  Future<void> installFrom(File zip) async {
    final path = zip.path;
    // Hash in chunks so a 200 MB file never sits in memory at once.
    final digest = (await sha256.bind(File(path).openRead()).first).toString();
    if (digest != spec.sha256) {
      zip.deleteSync();
      throw const FormatException('The download is damaged. Please try again.');
    }
    final target = dir.path;
    final format = spec.format;
    await Isolate.run(
      () => switch (format) {
        PackFormat.svgXz => _extractAndVerify(path, target),
        PackFormat.pngQuranCom => _extractQuranCom(path, target),
        PackFormat.pngShamarly => _extractShamarly(path, target),
        PackFormat.semantic => _extractSemantic(path, target),
        PackFormat.book => _installBook(path, target),
      },
    );
    _done.writeAsStringSync(DateTime.now().toIso8601String());
    zip.deleteSync();
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

/// Keeps the 522 Shamarly page images as `NNN.png`. The whole zip was
/// already checked against its SHA-256.
void _extractShamarly(String zipPath, String targetDir) {
  final input = InputFileStream(zipPath);
  final archive = ZipDecoder().decodeStream(input);
  final pageName = RegExp(r'^(\d{3})\.png$');
  Directory(targetDir).createSync(recursive: true);
  final pages = <String>{};
  for (final entry in archive.files) {
    if (!entry.isFile || pageName.firstMatch(entry.name) == null) continue;
    File(p.join(targetDir, entry.name))
        .writeAsBytesSync(entry.content, flush: true);
    pages.add(entry.name);
  }
  input.closeSync();
  if (pages.length != shamarlyPageCount) {
    throw const FormatException('The page pack is incomplete.');
  }
}

/// Writes the search-by-meaning files one at a time, straight to disk, and
/// checks each against the manifest's SHA-256.
void _extractSemantic(String zipPath, String targetDir) {
  final input = InputFileStream(zipPath);
  final archive = ZipDecoder().decodeStream(input);
  final manifestFile = archive.findFile('manifest.json');
  if (manifestFile == null) throw const FormatException('Missing manifest');
  final manifest =
      jsonDecode(utf8.decode(manifestFile.content)) as Map<String, dynamic>;
  Directory(targetDir).createSync(recursive: true);
  for (final f in manifest['files'] as List) {
    final name = (f as Map)['file'] as String;
    final entry = archive.findFile(name);
    if (entry == null || name.contains('/') || name.contains('..')) {
      throw FormatException('Missing file: $name');
    }
    final out = p.join(targetDir, name);
    final sink = OutputFileStream(out);
    entry.writeContent(sink);
    sink.closeSync();
    if (_sha256File(out) != f['sha256']) {
      throw FormatException('File damaged: $name');
    }
  }
  File(p.join(targetDir, 'manifest.json'))
      .writeAsBytesSync(manifestFile.content, flush: true);
  input.closeSync();
}

/// Copies a book pack's SQLite file into its folder. The file was already
/// checked against its SHA-256.
void _installBook(String path, String targetDir) {
  Directory(targetDir).createSync(recursive: true);
  File(path).copySync(p.join(targetDir, bookPackFile));
}

/// SHA-256 of a file, read in 1 MB pieces.
String _sha256File(String path) {
  final out = _DigestSink();
  final input = sha256.startChunkedConversion(out);
  final file = File(path).openSync();
  final buffer = Uint8List(1 << 20);
  for (
    var n = file.readIntoSync(buffer);
    n > 0;
    n = file.readIntoSync(buffer)
  ) {
    input.add(Uint8List.sublistView(buffer, 0, n));
  }
  file.closeSync();
  input.close();
  return out.digest.toString();
}

class _DigestSink implements Sink<Digest> {
  late Digest digest;

  @override
  void add(Digest data) => digest = data;

  @override
  void close() {}
}

/// Pages in the Shamarly pack (page 1 is the cover).
const shamarlyPageCount = 522;

/// Reads one installed page as SVG text. Decompression runs off the UI
/// thread; recent pages are kept in memory for fast page turns.
class PageStore {
  PageStore(this.dir);

  final Directory dir;
  final _cache = <int, String>{};
  final _order = <int>[];

  /// Twelve pages: about 8 MB of text, and enough that turning back through
  /// a surah does not decompress again. The page's *picture* is not kept —
  /// that is the GPU's, and a caller disposes it — so a revisited page still
  /// compiles once more, which on a warm worker is 26 ms for 12 ms of it on
  /// the UI isolate.
  static const _capacity = 12;

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
