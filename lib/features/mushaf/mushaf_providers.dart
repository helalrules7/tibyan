import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/db/ayahinfo_database.dart';
import '../../core/db/content_database.dart';
import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/db/user_database.dart';
import 'data/mushaf_repository.dart';
import 'data/page_pack.dart';

/// Overridden in `main()` once the bundled database is copied and opened.
final contentDatabaseProvider = Provider<ContentDatabase>(
  (ref) => throw UnimplementedError('contentDatabaseProvider not overridden'),
);

final userDatabaseProvider = Provider<UserDatabase>(
  (ref) => throw UnimplementedError('userDatabaseProvider not overridden'),
);

/// App storage root for downloaded packs; overridden in `main()`.
final packRootProvider = Provider<Directory>(
  (ref) => throw UnimplementedError('packRootProvider not overridden'),
);

final mushafRepositoryProvider = Provider<MushafRepository>(
  (ref) => MushafRepository(ref.watch(contentDatabaseProvider)),
);

final surahsProvider = FutureProvider<List<SurahRow>>(
  (ref) => ref.watch(mushafRepositoryProvider).surahs(),
);

/// The Madina edition the reader chose.
final editionProvider = Provider<MushafEdition>(
  (ref) => ref.watch(settingsProvider.select((s) => s.edition)),
);

final pageInstallerProvider = Provider<PagePackInstaller>(
  (ref) => PagePackInstaller(
    root: Directory(p.join(ref.watch(packRootProvider).path, 'packs')),
    spec: ref.watch(editionProvider) == MushafEdition.madina1405
        ? PagePackSpec.madina1405
        : PagePackSpec.madina1441,
  ),
);

/// Glyph boxes of the old edition, once its pack is installed.
final ayahInfoDatabaseProvider = Provider<AyahInfoDatabase?>((ref) {
  final installer = ref.watch(pageInstallerProvider);
  if (installer.spec.format != PackFormat.pngQuranCom ||
      !ref.watch(pagesInstalledProvider)) {
    return null;
  }
  final db = AyahInfoDatabase.open(
    File(p.join(installer.dir.path, 'ayahinfo.db')),
  );
  ref.onDispose(db.close);
  return db;
});

final pageStoreProvider = Provider<PageStore>(
  (ref) => PageStore(ref.watch(pageInstallerProvider).dir),
);

final readingPositionProvider = StreamProvider<ReadingPositionRow?>(
  (ref) => ref.watch(userDatabaseProvider).watchPosition(),
);

final bookmarkSetsProvider = StreamProvider<List<BookmarkSetRow>>(
  (ref) => ref.watch(userDatabaseProvider).watchBookmarkSets(),
);

final juzStartsProvider = FutureProvider<List<JuzStart>>(
  (ref) => ref.watch(mushafRepositoryProvider).juzStarts(),
);

final sourcesProvider = FutureProvider<List<SourceRow>>(
  (ref) => ref.watch(mushafRepositoryProvider).sources(),
);

/// Whether the page pack is on this device. Invalidate after installing.
final pagesInstalledProvider = Provider<bool>(
  (ref) => ref.watch(pageInstallerProvider).isInstalled,
);

/// The page pack download. Lives in a provider so it keeps running while
/// the reader uses the continuous view.
class PageDownloadController extends Notifier<PackProgress> {
  StreamSubscription<PackProgress>? _sub;

  @override
  PackProgress build() {
    ref.onDispose(() => _sub?.cancel());
    return ref.read(pageInstallerProvider).isInstalled
        ? const PackProgress(PackPhase.installed)
        : const PackProgress(PackPhase.idle);
  }

  void start() {
    _sub?.cancel();
    _sub = ref.read(pageInstallerProvider).install().listen((p) {
      state = p;
      if (p.phase == PackPhase.installed) {
        ref.invalidate(pagesInstalledProvider);
      }
    });
  }

  void pause() {
    ref.read(pageInstallerProvider).pause();
    _sub?.cancel();
    state = PackProgress(
      PackPhase.idle,
      received: state.received,
      total: state.total,
    );
  }
}

final pageDownloadProvider =
    NotifierProvider<PageDownloadController, PackProgress>(
      PageDownloadController.new,
    );

final pageAyahsProvider = FutureProvider.family<List<AyahRow>, int>(
  (ref, page) => ref
      .watch(mushafRepositoryProvider)
      .ayahsOnPage(page, ref.watch(editionProvider)),
);

final surahAyahsProvider = FutureProvider.family<List<AyahRow>, int>(
  (ref, surah) => ref.watch(mushafRepositoryProvider).ayahsOfSurah(surah),
);

final reviewNoteCountProvider = FutureProvider<int>(
  (ref) => ref.watch(mushafRepositoryProvider).reviewNoteCount(),
);

/// The basmala shown above surahs 2–114 (except 9): verse 1:1 of the
/// KFGQPC text without its number.
final basmalaProvider = FutureProvider<String>(
  (ref) async =>
      (await ref.watch(mushafRepositoryProvider).ayah(1, 1)).displayBody,
);
