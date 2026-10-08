import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' show Database, OpenMode, sqlite3;

import '../../core/flags/feature_flags.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/data/page_pack.dart';
import '../mushaf/mushaf_providers.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import 'credits.dart';
import '../../core/testing/test_packs.dart';

/// A tafsir text pack on Tibyan's mirror: one SQLite file written by
/// `tools/fetch_quranenc_extra.py pack` (the English «المختصر في تفسير
/// القرآن الكريم», QuranEnc's english_mokhtasar), its text exactly as
/// QuranEnc serves it. Downloaded, checked against its SHA-256 and
/// installed like a book pack (`packs/<id>/book.db`).
class TafsirTextPackSpec {
  const TafsirTextPackSpec({
    required this.id,
    required this.url,
    required this.sha256,
    required this.bytes,
    required this.title,
    this.fallbacks = const [],
  });

  final String id;

  /// `…/mirror/books/<id>.pack.db`.
  final String url;
  final List<String> fallbacks;

  /// `pack_sha256` and `bytes` of the pack's `.index.json`.
  final String sha256;
  final int bytes;
  final String title;

  PagePackSpec get pack => PagePackSpec(
    id: id,
    url: url,
    sha256: sha256,
    bytes: bytes,
    format: PackFormat.book,
    fallbacks: fallbacks,
  );

  /// The English tafsir packs the app can download. Empty until QuranEnc
  /// answers (letter 12) and the pack is published
  /// (docs/features/audio_content.md), apart from the closed-test pack
  /// ([testEnglishTafsirPacks], removed before a public release).
  static const english = <TafsirTextPackSpec>[...testEnglishTafsirPacks];
}

/// One verse of a tafsir text pack.
class TafsirTextEntry {
  const TafsirTextEntry(this.text, this.footnotes);
  final String text;
  final String? footnotes;
}

/// An opened tafsir text pack (read-only).
class TafsirTextPack {
  /// Reads [db] as a pack: refuses a file that is not one, or one of a
  /// format this version does not know.
  TafsirTextPack(this._db) {
    final tables = {
      for (final r in _db.select(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      ))
        r['name'] as String,
    };
    if (!tables.containsAll(const ['pack_index', 'verse'])) {
      throw const FormatException('Not a tafsir text pack');
    }
    for (final r in _db.select('SELECT key, value FROM pack_index')) {
      meta[r['key'] as String] = r['value'] as String;
    }
    if (meta['format'] != supportedFormat || meta['kind'] != kind) {
      throw const FormatException('Unknown tafsir text pack format');
    }
  }

  factory TafsirTextPack.open(File file) {
    final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
    try {
      return TafsirTextPack(db);
    } catch (_) {
      db.close();
      rethrow;
    }
  }

  static const supportedFormat = '1';
  static const kind = 'tafsir_text';

  final Database _db;
  final Map<String, String> meta = {};

  /// The credit key (credits.dart).
  String get source => meta['source'] ?? ContentSources.quranEncMokhtasar;
  String? get version => meta['version'];
  String get title => meta['title'] ?? '';
  bool get rtl => meta['direction'] == 'rtl';

  TafsirTextEntry? entry(int surah, int ayah) {
    final rows = _db.select(
      'SELECT text, footnotes FROM verse WHERE surah = ? AND ayah = ?',
      [surah, ayah],
    );
    if (rows.isEmpty) return null;
    final notes = rows.first['footnotes'];
    return TafsirTextEntry(
      rows.first['text'] as String,
      notes is String && notes.trim().isNotEmpty ? notes : null,
    );
  }

  void close() => _db.close();
}

/// The English tafsir packs the app knows (overridden in tests).
final englishTafsirSpecsProvider = Provider<List<TafsirTextPackSpec>>(
  (ref) => TafsirTextPackSpec.english,
);

PagePackInstaller tafsirTextInstaller(Directory root, TafsirTextPackSpec s) =>
    PagePackInstaller(root: root, spec: s.pack);

/// The installed English tafsir pack, opened, while [Feature.englishTafsir]
/// is on; null otherwise. Only packs from [englishTafsirSpecsProvider]
/// count: each was checked against its SHA-256 when it was installed.
final englishTafsirPackProvider = Provider<TafsirTextPack?>((ref) {
  if (!ref.watch(featureFlagsProvider).isOn(Feature.englishTafsir)) {
    return null;
  }
  ref.watch(packInstallsProvider);
  final root = ref.watch(packsDirProvider);
  for (final spec in ref.watch(englishTafsirSpecsProvider)) {
    final installer = tafsirTextInstaller(root, spec);
    if (!installer.isInstalled) continue;
    try {
      final pack = TafsirTextPack.open(
        File(p.join(installer.dir.path, bookPackFile)),
      );
      ref.onDispose(pack.close);
      return pack;
    } on Object {
      // Damaged or of a newer format: not shown.
    }
  }
  return null;
});

/// Downloads of the English tafsir packs, by pack id, run by the system
/// like the page packs.
class EnglishTafsirDownloads extends Notifier<Map<String, PackProgress>> {
  StreamSubscription<(String, PackProgress)>? _sub;

  @override
  Map<String, PackProgress> build() {
    ref.onDispose(() => _sub?.cancel());
    final ids = {for (final s in ref.watch(englishTafsirSpecsProvider)) s.id};
    if (ids.isEmpty) return const {};
    _sub = ref.read(backgroundPacksProvider).progress.listen((e) {
      if (!ids.contains(e.$1)) return;
      state = {...state, e.$1: e.$2};
      if (e.$2.phase == PackPhase.installed) {
        ref.read(packInstallsProvider.notifier).changed();
      }
    });
    return const {};
  }

  Future<void> start(TafsirTextPackSpec spec, String notification) async {
    state = {
      ...state,
      spec.id: PackProgress(PackPhase.downloading, total: spec.bytes),
    };
    await ref.read(backgroundPacksProvider).enqueue(spec.pack, notification);
  }
}

final englishTafsirDownloadsProvider =
    NotifierProvider<EnglishTafsirDownloads, Map<String, PackProgress>>(
      EnglishTafsirDownloads.new,
    );

/// The English tafsir of a (Hafs) verse in the English interface: the
/// pack's text exactly as stored, then its credit line; or, while no pack
/// is installed, the offer to download one. Nothing in the Arabic
/// interface, while [Feature.englishTafsir] is off, or with no pack
/// published.
class EnglishTafsirSection extends ConsumerWidget {
  const EnglishTafsirSection({
    super.key,
    required this.surah,
    required this.ayah,
  });

  final int surah;
  final int ayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final settings = ref.watch(settingsProvider);
    if (!settings.isEnglishTafsirShown(languageCode)) {
      return const SizedBox.shrink();
    }
    if (!ref.watch(featureFlagsProvider).isOn(Feature.englishTafsir)) {
      return const SizedBox.shrink();
    }
    final pack = ref.watch(englishTafsirPackProvider);
    if (pack == null) return const _EnglishTafsirOffer();
    final entry = pack.entry(surah, ayah);
    if (entry == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final scale = settings.tafsirFontScale;
    final dir = pack.rtl ? TextDirection.rtl : TextDirection.ltr;
    final credit = contentCredit(pack.source, 'en', version: pack.version);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    pack.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: t.ink,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: l.copyText,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.copy, size: 18, color: t.muted),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: '${entry.text}\n\n$credit'),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l.copied)));
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            entry.text,
            textDirection: dir,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: 16 * scale,
              height: 1.6,
              color: t.ink,
            ),
          ),
          if (entry.footnotes != null) ...[
            const SizedBox(height: 10),
            Text(
              l.tafsirFootnotes,
              style: TextStyle(fontSize: 12, color: t.muted),
            ),
            const SizedBox(height: 4),
            Text(
              entry.footnotes!,
              textDirection: dir,
              style: TextStyle(
                fontSize: 13 * scale,
                height: 1.5,
                color: t.muted,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            credit,
            textDirection: dir,
            style: TextStyle(fontSize: 11, color: t.muted),
          ),
        ],
      ),
    );
  }
}

/// A published English tafsir pack that is not on the device yet.
class _EnglishTafsirOffer extends ConsumerWidget {
  const _EnglishTafsirOffer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specs = ref.watch(englishTafsirSpecsProvider);
    if (specs.isEmpty) return const SizedBox.shrink();
    final spec = specs.first;
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final digits = NumberFormatter(Localizations.localeOf(context));
    final progress = ref.watch(englishTafsirDownloadsProvider)[spec.id];
    final phase = progress?.phase ?? PackPhase.idle;
    final busy =
        phase == PackPhase.downloading ||
        phase == PackPhase.verifying ||
        phase == PackPhase.installing;
    final status = switch (phase) {
      PackPhase.downloading => l.semanticPackDownloading(
        digits((progress!.fraction * 100).round()),
      ),
      PackPhase.verifying || PackPhase.installing => l.semanticPackVerifying,
      PackPhase.failed => l.semanticPackFailed,
      _ => l.storageSize(
        digits.decimal(
          (spec.bytes / 1e6).toStringAsFixed(spec.bytes < 1e7 ? 1 : 0),
        ),
      ),
    };
    return Card(
      child: ListTile(
        title: Text(l.englishTafsirOffer(spec.title)),
        subtitle: Semantics(
          liveRegion: busy,
          child: Text(
            '$status\n${contentCredit(ContentSources.quranEncMokhtasar, 'en')}',
            style: TextStyle(color: t.muted),
          ),
        ),
        isThreeLine: true,
        trailing: busy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : TextButton(
                onPressed: () => ref
                    .read(englishTafsirDownloadsProvider.notifier)
                    .start(spec, l.englishTafsirOffer(spec.title)),
                child: Text(l.bookPackDownload),
              ),
      ),
    );
  }
}
