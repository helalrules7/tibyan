import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../core/db/content_database.dart';

/// Where corrected timings are published: our server first, as everything
/// else the app downloads. Built by `.github/workflows/timing-deploy.yml`
/// from `data/timing/` once a correction is merged (docs/TIMING.md).
const timingBaseUrl = 'https://tibyan.ahmedhelal.dev/timing/';

/// Packs above this size are refused (al-Sudais, every word: ~1 MB).
const _maxPackBytes = 20 * 1024 * 1024;

final _fileName = RegExp(r'^timing-[a-z0-9-]+-v[0-9]+\.json\.gz$');
final _sha = RegExp(r'^[0-9a-f]{64}$');

/// One verse of a pack: number, start, end and its words (number, start, end).
typedef _Verse = (int, int, int, List<(int, int, int)>);

/// One reciter's entry in `manifest.json`.
@immutable
class TimingManifestEntry {
  const TimingManifestEntry({
    required this.slug,
    required this.reciterId,
    required this.version,
    required this.file,
    required this.bytes,
    required this.sha256,
  });

  final String slug;
  final int reciterId;
  final int version;
  final String file;
  final int bytes;
  final String sha256;
}

/// The entries of a `manifest.json`; malformed ones are left out, and a
/// manifest that is not one at all gives none.
List<TimingManifestEntry> parseTimingManifest(String text) {
  final out = <TimingManifestEntry>[];
  try {
    final doc = jsonDecode(text);
    if (doc is! Map || doc['format'] != 1 || doc['reciters'] is! List) {
      return out;
    }
    for (final e in doc['reciters'] as List) {
      if (e is! Map) continue;
      final slug = e['slug'];
      final id = e['reciter_id'];
      final version = e['version'];
      final file = e['file'];
      final bytes = e['bytes'];
      final sha = e['sha256'];
      if (slug is! String ||
          id is! int ||
          version is! int ||
          file is! String ||
          bytes is! int ||
          sha is! String ||
          !_fileName.hasMatch(file) ||
          !_sha.hasMatch(sha) ||
          bytes <= 0 ||
          bytes > _maxPackBytes) {
        continue;
      }
      out.add(
        TimingManifestEntry(
          slug: slug,
          reciterId: id,
          version: version,
          file: file,
          bytes: bytes,
          sha256: sha,
        ),
      );
    }
  } on FormatException {
    return const [];
  }
  return out;
}

/// One reciter's timings, as in `data/timing/<slug>/NNN.json`: per surah,
/// `[verse, start, end, [[word, start, end], ...]]` in ms.
class TimingPack {
  TimingPack._(
    this.slug,
    this.reciterId,
    this.version,
    this.folderUrl,
    this._surahs,
  );

  final String slug;
  final int reciterId;
  final int version;
  final String folderUrl;
  final Map<int, List<_Verse>> _surahs;

  Iterable<int> get surahs => _surahs.keys;

  /// Reads a pack from its gzip bytes. Throws [FormatException] when it is
  /// not a well-formed pack: every number a whole number, verses in order,
  /// every span forward.
  static TimingPack decode(List<int> gz) {
    final doc = jsonDecode(utf8.decode(gzip.decode(gz)));
    if (doc is! Map || doc['format'] != 1) {
      throw const FormatException('not a timing pack');
    }
    final slug = doc['slug'];
    final id = doc['reciter_id'];
    final version = doc['version'];
    final folder = doc['folder_url'];
    final surahs = doc['surahs'];
    if (slug is! String ||
        id is! int ||
        version is! int ||
        folder is! String ||
        surahs is! Map) {
      throw const FormatException('timing pack header');
    }
    final out = <int, List<(int, int, int, List<(int, int, int)>)>>{};
    for (final MapEntry(:key, :value) in surahs.entries) {
      final surah = int.tryParse('$key');
      if (surah == null || surah < 1 || surah > 114 || value is! List) {
        throw FormatException('surah $key');
      }
      final verses = <_Verse>[];
      var last = -1;
      for (final v in value) {
        if (v is! List || v.length != 4 || v[3] is! List) {
          throw FormatException('verse in $surah');
        }
        final [a, s, e, ws] = v;
        if (a is! int || s is! int || e is! int || a <= last || e <= s) {
          throw FormatException('verse $a in $surah');
        }
        last = a;
        final words = <(int, int, int)>[];
        for (final w in ws as List) {
          if (w is! List || w.length != 3) {
            throw FormatException('word in $surah:$a');
          }
          final [k, ws0, we] = w;
          if (k is! int || ws0 is! int || we is! int || we <= ws0) {
            throw FormatException('word $k in $surah:$a');
          }
          words.add((k, ws0, we));
        }
        verses.add((a, s, e, words));
      }
      out[surah] = verses;
    }
    return TimingPack._(slug, id, version, folder, out);
  }

  bool has(int surah) => _surahs.containsKey(surah);

  /// Verse timings of [surah] as content.db rows, in verse order.
  List<AyahTimingRow> ayahRows(int surah) => [
    for (final (a, s, e, _) in _surahs[surah] ?? const <_Verse>[])
      AyahTimingRow(
        reciter: reciterId,
        surah: surah,
        ayah: a,
        startMs: s,
        endMs: e,
      ),
  ];

  /// Word timings of [surah] as content.db rows, in order of time.
  List<WordTimingRow> wordRows(int surah) => [
    for (final (a, _, _, words) in _surahs[surah] ?? const <_Verse>[])
      for (final (k, s, e) in words)
        WordTimingRow(
          reciter: reciterId,
          surah: surah,
          ayah: a,
          word: k,
          startMs: s,
          endMs: e,
        ),
  ]..sort((x, y) => x.startMs.compareTo(y.startMs));
}

/// Timings that take the place of content.db's for some reciters.
abstract interface class TimingOverrides {
  /// The pack in use for [reciter] if it holds [surah], else null (then
  /// content.db's rows are used).
  Future<TimingPack?> packFor(int reciter, int surah);
}

class NoTimingOverrides implements TimingOverrides {
  const NoTimingOverrides();

  @override
  Future<TimingPack?> packFor(int reciter, int surah) async => null;
}

/// Corrected timings downloaded from [timingBaseUrl], kept under [dir]
/// (`<app support>/timing/`): `<reciter>.json.gz`, the pack's bytes as
/// verified, and `state.json` naming each one's version and SHA-256.
///
/// A pack is used for a reciter only when it is newer than the timings
/// content.db was built with ([bundled], from content.db's `meta`), and
/// was made for the same audio files ([folders]). Anything missing,
/// corrupt or offline leaves content.db's timings in place.
class TimingUpdates implements TimingOverrides {
  TimingUpdates(this.dir, {this.client, Uri? base})
    : _base = base ?? Uri.parse(timingBaseUrl);

  final Directory dir;

  /// The HTTP client to use; a fresh one per refresh when null.
  final http.Client? client;
  final Uri _base;

  /// The reciters' folder URLs in content.db, by id.
  Map<int, String> folders = const {};

  /// The timing version content.db carries for each reciter, by slug.
  Map<String, int> bundled = const {};

  final _loaded = <int, Future<TimingPack?>>{};

  /// How often the manifest is asked for at most.
  static const checkEvery = Duration(hours: 12);

  File get _stateFile => File(p.join(dir.path, 'state.json'));

  File packFile(int reciter) => File(p.join(dir.path, '$reciter.json.gz'));

  Map<String, dynamic> _state() {
    try {
      final s = jsonDecode(_stateFile.readAsStringSync());
      if (s is Map<String, dynamic>) return s;
    } on Object {
      // none yet, or unreadable: start again
    }
    return {'packs': <String, dynamic>{}};
  }

  void _writeState(Map<String, dynamic> state) {
    dir.createSync(recursive: true);
    final tmp = File('${_stateFile.path}.tmp')
      ..writeAsStringSync(jsonEncode(state));
    tmp.renameSync(_stateFile.path);
  }

  @override
  Future<TimingPack?> packFor(int reciter, int surah) async {
    final pack = await (_loaded[reciter] ??= _load(reciter));
    if (pack == null || !pack.has(surah) || !_usable(pack)) return null;
    return pack;
  }

  Future<TimingPack?> _load(int reciter) async {
    try {
      final entry = (_state()['packs'] as Map?)?['$reciter'];
      if (entry is! Map) return null;
      final file = packFile(reciter);
      if (!file.existsSync()) return null;
      final sha = entry['sha256'];
      final pack = await Isolate.run(() {
        final bytes = file.readAsBytesSync();
        if (sha256.convert(bytes).toString() != sha) {
          throw const FormatException('changed on disk');
        }
        return TimingPack.decode(bytes);
      });
      return pack;
    } on Object {
      return null;
    }
  }

  bool _usable(TimingPack pack) =>
      folders[pack.reciterId] == pack.folderUrl &&
      pack.version > (bundled[pack.slug] ?? 0);

  /// Asks the server for newer packs and installs those that verify.
  /// Returns how many were installed. Never throws.
  Future<int> refresh({DateTime? now, bool force = false}) async {
    final c = client ?? http.Client();
    var installed = 0;
    try {
      final state = _state();
      final time = now ?? DateTime.now();
      final last = DateTime.tryParse('${state['checked_at']}');
      if (!force && last != null && time.difference(last) < checkEvery) {
        return 0;
      }
      final r = await c
          .get(_base.resolve('manifest.json'))
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) return 0;
      final packs = (state['packs'] as Map?)?.cast<String, dynamic>() ?? {};
      for (final e in parseTimingManifest(utf8.decode(r.bodyBytes))) {
        final have = packs['${e.reciterId}'];
        if (have is Map && have['version'] == e.version) continue;
        if (!folders.containsKey(e.reciterId)) continue;
        if (e.version <= (bundled[e.slug] ?? 0)) continue;
        try {
          final res = await c
              .get(_base.resolve(e.file))
              .timeout(const Duration(seconds: 60));
          final bytes = res.bodyBytes;
          if (res.statusCode != 200 || bytes.length != e.bytes) continue;
          if (sha256.convert(bytes).toString() != e.sha256) continue;
          final pack = await Isolate.run(() => TimingPack.decode(bytes));
          if (pack.reciterId != e.reciterId ||
              pack.version != e.version ||
              pack.slug != e.slug ||
              !_usable(pack)) {
            continue;
          }
          dir.createSync(recursive: true);
          final file = packFile(e.reciterId);
          final tmp = File('${file.path}.part')..writeAsBytesSync(bytes);
          tmp.renameSync(file.path);
          packs['${e.reciterId}'] = {
            'slug': e.slug,
            'version': e.version,
            'sha256': e.sha256,
          };
          _loaded[e.reciterId] = Future.value(pack);
          installed++;
        } on Object {
          // this one failed; the rest may still install
        }
      }
      state['packs'] = packs;
      state['checked_at'] = time.toIso8601String();
      _writeState(state);
    } on Object {
      // offline, or the server is down: content.db's timings stay
    } finally {
      if (client == null) c.close();
    }
    return installed;
  }
}
