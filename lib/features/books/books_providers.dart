import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/flags/feature_flags.dart';
import '../../core/settings/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/data/page_pack.dart';
import '../mushaf/mushaf_providers.dart';
import 'data/book_pack.dart';

/// The reviewed book packs the app knows (overridden in tests).
final bookPackSpecsProvider = Provider<List<BookPackSpec>>(
  (ref) => BookPackSpec.all,
);

PagePackInstaller bookInstaller(Directory root, BookPackSpec spec) =>
    PagePackInstaller(root: root, spec: spec.pack);

/// The reviewed book packs on this device, opened read-only. Only packs
/// from [bookPackSpecsProvider] count: each was checked against its
/// SHA-256 when it was installed. A pack that cannot be opened is left
/// out (the storage screen still lists it, so it can be deleted).
final installedBookPacksProvider = Provider<List<BookPack>>((ref) {
  ref.watch(packInstallsProvider);
  final root = ref.watch(packsDirProvider);
  final packs = <BookPack>[];
  for (final spec in ref.watch(bookPackSpecsProvider)) {
    final installer = bookInstaller(root, spec);
    if (!installer.isInstalled) continue;
    try {
      packs.add(
        BookPack.open(
          File(p.join(installer.dir.path, bookPackFile)),
          spec: spec,
        ),
      );
    } on Object {
      // Damaged or of a newer format: not shown.
    }
  }
  ref.onDispose(() {
    for (final pack in packs) {
      pack.close();
    }
  });
  return packs;
});

/// The occasions of revelation of a (Hafs) verse from the installed
/// reviewed packs; empty unless [Feature.asbabNuzul] is on.
final asbabProvider = Provider.autoDispose
    .family<List<BookEntry>, ({int surah, int ayah})>((ref, v) {
      if (!ref.watch(featureFlagsProvider).isOn(Feature.asbabNuzul)) {
        return const [];
      }
      return [
        for (final pack in ref.watch(installedBookPacksProvider))
          ...pack.entriesFor(v.surah, v.ayah, kind: BookKind.asbabNuzul),
      ];
    });

/// Downloads of the book packs, by pack id, run by the system like the
/// page packs.
class BookDownloads extends Notifier<Map<String, PackProgress>> {
  StreamSubscription<(String, PackProgress)>? _sub;

  @override
  Map<String, PackProgress> build() {
    ref.onDispose(() => _sub?.cancel());
    final specs = ref.watch(bookPackSpecsProvider);
    final ids = {for (final s in specs) s.id};
    final packs = ref.read(backgroundPacksProvider);
    _sub = packs.progress.listen((e) {
      if (!ids.contains(e.$1)) return;
      state = {...state, e.$1: e.$2};
      if (e.$2.phase == PackPhase.installed) {
        ref.read(packInstallsProvider.notifier).changed();
      }
    });
    for (final s in specs) {
      unawaited(
        packs
            .stateOf(s.pack)
            .then((p) => state = {...state, s.id: p})
            .catchError((_) => state),
      );
    }
    return const {};
  }

  Future<void> start(BookPackSpec spec) async {
    final l = lookupAppLocalizations(
      ref.read(settingsProvider).locale ?? const Locale('ar'),
    );
    state = {
      ...state,
      spec.id: PackProgress(PackPhase.downloading, total: spec.bytes),
    };
    await ref
        .read(backgroundPacksProvider)
        .enqueue(spec.pack, l.storageBook(spec.title));
  }
}

final bookDownloadsProvider =
    NotifierProvider<BookDownloads, Map<String, PackProgress>>(
      BookDownloads.new,
    );
