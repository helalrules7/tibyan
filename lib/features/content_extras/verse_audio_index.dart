import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../core/flags/feature_flags.dart';
import '../mushaf/mushaf_providers.dart';

/// What an index holds; matches `kind` in tools/audio_index.py.
abstract final class VerseAudioKind {
  /// A tafsir read aloud (Nuqayah): «استمع للتفسير».
  static const tafsir = 'tafsir_audio';

  /// A translation read after each verse (QuranEnc's english_rwwad).
  static const translation = 'translation_audio';

  /// The flag that shows an index of [kind]; null for a kind this version
  /// does not know (never shown).
  static Feature? feature(String kind) => switch (kind) {
    tafsir => Feature.tafsirAudio,
    translation => Feature.translationAudio,
    _ => null,
  };
}

/// Where one verse's audio is: a file of its own, or a stretch of its
/// surah's file ([start]..[end]). [wholeSurah]: the surah's file has no
/// verse offsets, so it plays whole (the tafsir of the surah).
class VerseAudioClip {
  const VerseAudioClip(
    this.uri, {
    this.start = Duration.zero,
    this.end,
    this.wholeSurah = false,
  });

  final Uri uri;
  final Duration start;
  final Duration? end;
  final bool wholeSurah;

  @override
  bool operator ==(Object other) =>
      other is VerseAudioClip &&
      other.uri == uri &&
      other.start == start &&
      other.end == end &&
      other.wholeSurah == wholeSurah;

  @override
  int get hashCode => Object.hash(uri, start, end, wholeSurah);

  @override
  String toString() =>
      'VerseAudioClip($uri, $start..$end${wholeSurah ? ', whole surah' : ''})';
}

/// A verse audio index (format 1, written by tools/audio_index.py): links
/// only, the audio is streamed from its publisher and never bundled.
/// docs/features/audio_content.md describes the format.
class VerseAudioIndex {
  VerseAudioIndex({
    required this.id,
    required this.kind,
    required this.source,
    required this.titleAr,
    required this.titleEn,
    this.verses = const {},
    this.surahs = const {},
    this.offsets = const {},
  });

  /// Reads an index; refuses another format, a kind with no URLs, a URL
  /// that is not https and offsets without their surah file.
  factory VerseAudioIndex.parse(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      throw const FormatException('Not a verse audio index');
    }
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Not a verse audio index');
    }
    final Map<String, Object?> j = decoded;
    if (j['format'] != supportedFormat) {
      throw const FormatException('Unknown verse audio index format');
    }
    Uri url(Object? v) {
      final u = v is String ? Uri.tryParse(v) : null;
      if (u == null || u.scheme != 'https' || u.host.isEmpty) {
        throw FormatException('Not an https URL: $v');
      }
      return u;
    }

    int n(Object? v) =>
        v is int ? v : throw FormatException('Not a number: $v');
    final verses = <(int, int), Uri>{};
    for (final row in (j['verses'] as List?) ?? const []) {
      final r = row as List;
      verses[(n(r[0]), n(r[1]))] = url(r[2]);
    }
    final surahs = <int, Uri>{};
    for (final row in (j['surahs'] as List?) ?? const []) {
      final r = row as List;
      surahs[n(r[0])] = url(r[1]);
    }
    final offsets = <(int, int), (int, int)>{};
    for (final row in (j['offsets'] as List?) ?? const []) {
      final r = row as List;
      final s = n(r[0]);
      final start = n(r[2]);
      final end = n(r[3]);
      if (!surahs.containsKey(s) || start < 0 || end <= start) {
        throw FormatException('Bad offsets: $r');
      }
      offsets[(s, n(r[1]))] = (start, end);
    }
    if (verses.isEmpty && surahs.isEmpty) {
      throw const FormatException('Empty verse audio index');
    }
    String text(String key) => switch (j[key]) {
      final String s when s.isNotEmpty => s,
      _ => throw FormatException('Missing $key'),
    };
    return VerseAudioIndex(
      id: text('id'),
      kind: text('kind'),
      source: text('source'),
      titleAr: (j['title_ar'] as String?) ?? text('id'),
      titleEn: (j['title_en'] as String?) ?? text('id'),
      verses: verses,
      surahs: surahs,
      offsets: offsets,
    );
  }

  static const supportedFormat = 1;

  final String id;

  /// [VerseAudioKind].
  final String kind;

  /// The credit key (credits.dart).
  final String source;
  final String titleAr;
  final String titleEn;
  final Map<(int, int), Uri> verses;
  final Map<int, Uri> surahs;
  final Map<(int, int), (int, int)> offsets;

  String title(String languageCode) => languageCode == 'ar' ? titleAr : titleEn;

  /// Where the audio of [surah]:[ayah] is, or null when the index has
  /// none: the verse's own file, else its stretch of the surah's file,
  /// else (with [wholeSurahs]) the surah's whole file.
  VerseAudioClip? clipFor(int surah, int ayah, {bool wholeSurahs = true}) {
    final own = verses[(surah, ayah)];
    if (own != null) return VerseAudioClip(own);
    final file = surahs[surah];
    if (file == null) return null;
    final span = offsets[(surah, ayah)];
    if (span != null) {
      return VerseAudioClip(
        file,
        start: Duration(milliseconds: span.$1),
        end: Duration(milliseconds: span.$2),
      );
    }
    return wholeSurahs ? VerseAudioClip(file, wholeSurah: true) : null;
  }
}

/// A published index on Tibyan's mirror: fetched once, checked against
/// its SHA-256 and kept on the device. The audio it links to is streamed.
class AudioIndexSpec {
  const AudioIndexSpec({
    required this.id,
    required this.kind,
    required this.url,
    required this.sha256,
  });

  final String id;

  /// [VerseAudioKind]: which flag shows it.
  final String kind;

  /// `…/mirror/audio-index/<id>.json`.
  final String url;
  final String sha256;

  /// Every index the app may fetch. Empty until the permission arrives
  /// and the index is published (docs/features/audio_content.md).
  static const all = <AudioIndexSpec>[];
}

/// Fetches and keeps the indexes, under `<app support>/audio-index/` (not
/// a pack: the storage screen does not list them, they are tiny).
class AudioIndexStore {
  AudioIndexStore(this.root, this.client);

  final Directory root;
  final http.Client client;

  /// The kept copy is named after its hash: a new index is fetched anew.
  File file(AudioIndexSpec spec) => File(
    p.join(
      root.path,
      'audio-index',
      '${spec.id}-${spec.sha256.substring(0, 12)}.json',
    ),
  );

  /// The index of [spec]: the kept copy when it still matches its hash,
  /// else fetched and checked. Throws when the download does not match.
  Future<VerseAudioIndex> load(AudioIndexSpec spec) async {
    final f = file(spec);
    if (f.existsSync()) {
      final bytes = await f.readAsBytes();
      if (sha256.convert(bytes).toString() == spec.sha256) {
        return VerseAudioIndex.parse(utf8.decode(bytes));
      }
      f.deleteSync();
    }
    final r = await client.get(Uri.parse(spec.url));
    if (r.statusCode != 200) throw HttpException('HTTP ${r.statusCode}');
    if (sha256.convert(r.bodyBytes).toString() != spec.sha256) {
      throw const FormatException('The audio index does not match its hash');
    }
    final index = VerseAudioIndex.parse(utf8.decode(r.bodyBytes));
    f.parent.createSync(recursive: true);
    await f.writeAsBytes(r.bodyBytes, flush: true);
    return index;
  }
}

/// The indexes the app knows (overridden in tests).
final audioIndexSpecsProvider = Provider<List<AudioIndexSpec>>(
  (ref) => AudioIndexSpec.all,
);

final audioIndexStoreProvider = Provider<AudioIndexStore>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return AudioIndexStore(ref.watch(packRootProvider), client);
});

/// Every index whose flag is on, fetched or read from the device. One that
/// cannot be had (offline, damaged) is left out and tried again next time.
final verseAudioIndexesProvider = FutureProvider<List<VerseAudioIndex>>((
  ref,
) async {
  final flags = ref.watch(featureFlagsProvider);
  final specs = [
    for (final s in ref.watch(audioIndexSpecsProvider))
      if (VerseAudioKind.feature(s.kind) case final f? when flags.isOn(f)) s,
  ];
  if (specs.isEmpty) return const [];
  final store = ref.watch(audioIndexStoreProvider);
  final out = <VerseAudioIndex>[];
  for (final s in specs) {
    try {
      out.add(await store.load(s));
    } on Object {
      // Not this time.
    }
  }
  return out;
});

/// The indexes of [kind] whose flag is on; empty otherwise. The flag is
/// checked here too, so nothing shows while it is off whatever the
/// indexes are.
final verseAudioOfKindProvider =
    FutureProvider.family<List<VerseAudioIndex>, String>((ref, kind) async {
      final feature = VerseAudioKind.feature(kind);
      if (feature == null || !ref.watch(featureFlagsProvider).isOn(feature)) {
        return const [];
      }
      return [
        for (final i in await ref.watch(verseAudioIndexesProvider.future))
          if (i.kind == kind) i,
      ];
    });

/// The tafsir recordings that have [surah]:[ayah] (per verse, or the
/// verse's stretch of a surah file, or the surah's whole file).
final tafsirAudioForVerseProvider = FutureProvider.autoDispose
    .family<List<(VerseAudioIndex, VerseAudioClip)>, ({int surah, int ayah})>((
      ref,
      v,
    ) async {
      final indexes = await ref.watch(
        verseAudioOfKindProvider(VerseAudioKind.tafsir).future,
      );
      return [
        for (final i in indexes)
          if (i.clipFor(v.surah, v.ayah) case final clip?) (i, clip),
      ];
    });

/// The translation read after each verse, when its flag is on and an
/// index is available; null otherwise.
final translationAudioIndexProvider = FutureProvider<VerseAudioIndex?>((
  ref,
) async {
  final indexes = await ref.watch(
    verseAudioOfKindProvider(VerseAudioKind.translation).future,
  );
  return indexes.firstOrNull;
});
