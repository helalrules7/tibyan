import 'dart:async';
import 'dart:isolate';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../mushaf/data/page_pack.dart';
import '../../mushaf/mushaf_providers.dart';
import 'e5_searcher.dart';
import 'meaning_search.dart';

/// The search-by-meaning pack's installer (it lives with the page packs).
final semanticInstallerProvider = Provider<PagePackInstaller>(
  (ref) => PagePackInstaller(
    root: ref.watch(packsDirProvider),
    spec: PagePackSpec.semantic,
  ),
);

final semanticInstalledProvider = Provider<bool>((ref) {
  ref.watch(packInstallsProvider);
  return ref.watch(semanticInstallerProvider).isInstalled;
});

/// The searcher behind «بالمعنى»: the pack's model once it is on the
/// device, else keyword search over the same texts.
final meaningSearcherProvider = FutureProvider<MeaningSearcher>((ref) async {
  final repo = ref.watch(mushafRepositoryProvider);
  if (ref.watch(semanticInstalledProvider)) {
    try {
      final verses = [
        for (final r in await repo.searchRows()) (r.surah, r.number),
      ];
      final searcher = await E5Searcher.open(
        ref.read(semanticInstallerProvider).dir.path,
        verses,
      );
      ref.onDispose(searcher.dispose);
      return searcher;
    } catch (_) {
      // A pack that cannot be opened: keywords instead. The screen tells
      // the two apart by [MeaningSearcher.semantic].
    }
  }
  final editions = await repo.commentaryEditions();
  final rows = await repo.commentaryOf([for (final e in editions) e.sourceId]);
  final plain = [
    for (final r in rows)
      (sourceId: r.sourceId, surah: r.surah, ayah: r.ayah, text: r.body),
  ];
  // Indexing 18,000 entries takes a moment: off the UI isolate.
  return Isolate.run(() => KeywordMeaningIndex(plain));
});

/// Results for one query.
final meaningResultsProvider = FutureProvider.autoDispose
    .family<List<MeaningHit>, String>((ref, query) async {
      final searcher = await ref.watch(meaningSearcherProvider.future);
      return searcher.search(query, limit: 50);
    });

/// The search-by-meaning pack download, run by the system like the page
/// packs (it goes on when the reader leaves the app).
class SemanticDownloadController extends Notifier<PackProgress> {
  StreamSubscription<(String, PackProgress)>? _sub;

  static const spec = PagePackSpec.semantic;

  @override
  PackProgress build() {
    ref.onDispose(() => _sub?.cancel());
    final packs = ref.read(backgroundPacksProvider);
    _sub = packs.progress.listen((e) {
      if (e.$1 != spec.id) return;
      state = e.$2;
      if (e.$2.phase == PackPhase.installed) {
        ref.read(packInstallsProvider.notifier).changed();
      }
    });
    if (ref.read(semanticInstallerProvider).isInstalled) {
      return const PackProgress(PackPhase.installed);
    }
    unawaited(
      packs.stateOf(spec).then((s) => state = s).catchError((_) => state),
    );
    return const PackProgress(PackPhase.idle);
  }

  Future<void> start() async {
    final l = lookupAppLocalizations(
      ref.read(settingsProvider).locale ?? const Locale('ar'),
    );
    state = PackProgress(
      PackPhase.downloading,
      received: state.received,
      total: spec.bytes,
    );
    await ref.read(backgroundPacksProvider).enqueue(spec, l.semanticPackName);
  }
}

final semanticDownloadProvider =
    NotifierProvider<SemanticDownloadController, PackProgress>(
      SemanticDownloadController.new,
    );
