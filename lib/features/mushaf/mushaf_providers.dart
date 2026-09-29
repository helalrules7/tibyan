import 'dart:async';
import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/db/ayahinfo_database.dart';
import '../../core/db/content_database.dart';
import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/db/user_database.dart';
import 'data/divine_names.dart';
import 'data/mushaf_repository.dart';
import 'data/page_pack.dart';
import 'presentation/widgets/illuminated_frame.dart';
import 'presentation/widgets/mushaf_page.dart' show outlineRects;

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

/// Juz, hizb, surah and catchword for the frame around a page.
final frameInfoProvider = FutureProvider.family<FrameInfo?, int>((
  ref,
  page,
) async {
  final edition = ref.watch(editionProvider);
  final repo = ref.watch(mushafRepositoryProvider);
  final ayahs = await repo.ayahsOnPage(page, edition);
  if (ayahs.isEmpty) return null;
  final surahs = await ref.watch(surahsProvider.future);
  final first = ayahs.first;

  // Line slot (0..14) where each verse starts, per edition.
  final lineOf = <(int, int), int>{};
  if (edition == MushafEdition.madina1405) {
    final glyphs =
        await ref.watch(ayahInfoDatabaseProvider)?.page(page) ?? const [];
    for (final g in glyphs) {
      final k = (g.suraNumber, g.ayahNumber);
      final line = g.lineNumber - 1;
      if (!lineOf.containsKey(k) || line < lineOf[k]!) lineOf[k] = line;
    }
  } else {
    for (final p in await repo.polygons(page)) {
      final top = outlineRects(p.path).first.top;
      lineOf[(p.surah, p.number)] = ((top - 8.3) / 35.75).round().clamp(0, 14);
    }
  }

  final banners = <SurahBanner>[];
  if (page > 2) {
    for (final a in ayahs.where((a) => a.number == 1)) {
      final line = lineOf[(a.surah, 1)];
      if (line == null) continue;
      // The header, then the basmala line (none before at-Tawba).
      final header = line - (a.surah == 9 ? 1 : 2);
      if (header < 0) continue;
      final s = surahs[a.surah - 1];
      final before = surahs
          .where((x) => x.revelationOrder == s.revelationOrder - 1)
          .firstOrNull;
      banners.add(
        SurahBanner(
          line: header,
          number: s.id,
          name: s.nameAr,
          meccan: s.revelation == 'meccan',
          ayahCount: s.ayahCount,
          order: s.revelationOrder,
          after: before?.nameAr,
        ),
      );
    }
  }

  // A surah whose first verse opens the next page may have its header (and
  // basmala) at the end of this page.
  if (page > 2 && page < 604) {
    final next = (await repo.ayahsOnPage(page + 1, edition)).firstOrNull;
    if (next != null && next.number == 1) {
      int? lineOnNext;
      if (edition == MushafEdition.madina1405) {
        final glyphs =
            await ref.watch(ayahInfoDatabaseProvider)?.page(page + 1) ??
            const [];
        for (final g in glyphs) {
          if (g.suraNumber == next.surah && g.ayahNumber == 1) {
            final l = g.lineNumber - 1;
            if (lineOnNext == null || l < lineOnNext) lineOnNext = l;
          }
        }
      } else {
        for (final p in await repo.polygons(page + 1)) {
          if (p.surah == next.surah && p.number == 1) {
            lineOnNext = ((outlineRects(p.path).first.top - 8.3) / 35.75)
                .round()
                .clamp(0, 14);
          }
        }
      }
      // Header and basmala need two lines (one for at-Tawba); those that do
      // not fit on the next page are the last lines of this one.
      final needed = next.surah == 9 ? 1 : 2;
      if (lineOnNext != null && lineOnNext < needed) {
        final header = 15 - (needed - lineOnNext);
        final s = surahs[next.surah - 1];
        final before = surahs
            .where((x) => x.revelationOrder == s.revelationOrder - 1)
            .firstOrNull;
        banners.add(
          SurahBanner(
            line: header,
            number: s.id,
            name: s.nameAr,
            meccan: s.revelation == 'meccan',
            ayahCount: s.ayahCount,
            order: s.revelationOrder,
            after: before?.nameAr,
          ),
        );
      }
    }
  }

  final quarters = <QuarterMark>[
    if (page > 2)
      for (final a in await repo.quarterStartsOnPage(page, edition))
        if (lineOf[(a.surah, a.number)] != null)
          QuarterMark(
            line: lineOf[(a.surah, a.number)]!,
            quarter: a.hizbQuarter,
            surah: a.surah,
            ayah: a.number,
          ),
  ];

  String? catchword;
  if (page < 604) {
    final next = (await repo.ayahsOnPage(page + 1, edition)).firstOrNull;
    if (next != null) {
      if (next.number == 1 && next.surah != 1 && next.surah != 9) {
        // A new surah starts: its basmala comes first.
        final basmala = await ref.watch(basmalaProvider.future);
        catchword = basmala.split(' ').take(2).join(' ');
      } else {
        catchword = next.displayBody
            .split(' ')
            .firstWhere((w) => w != '۞', orElse: () => '');
      }
    }
  }
  return FrameInfo(
    page: page,
    juz: first.juz,
    hizb: (first.hizbQuarter - 1) ~/ 4 + 1,
    surahName: surahs[first.surah - 1].nameAr,
    catchword: catchword,
    banners: banners,
    quarters: quarters,
    outerRight: page.isOdd,
  );
});

final hizbStartsProvider = FutureProvider<List<AyahRow>>(
  (ref) => ref.watch(mushafRepositoryProvider).hizbStarts(),
);

/// Boxes of the divine names on a page: page units (1441) or image pixels
/// (1405). New-edition boxes come from tools/build_word_boxes.py; old-edition
/// ones from quran.com's glyph boxes, matched to the words of each verse.
final divineNameBoxesProvider = FutureProvider.family<List<Rect>, int>((
  ref,
  page,
) async {
  final edition = ref.watch(editionProvider);
  final repo = ref.watch(mushafRepositoryProvider);
  final ayahs = await repo.ayahsOnPage(page, edition);
  final words = <(int, int), List<String>>{
    for (final a in ayahs)
      (a.surah, a.number): [
        for (final w in a.displayBody.split(RegExp('[  ]')))
          if (w.isNotEmpty && w != '۞') w,
      ],
  };
  final out = <Rect>[];
  if (edition == MushafEdition.madina1405) {
    final glyphs =
        await ref.watch(ayahInfoDatabaseProvider)?.page(page) ?? const [];
    final byVerse = <(int, int), Map<int, List<GlyphRow>>>{};
    for (final g in glyphs) {
      byVerse
          .putIfAbsent((g.suraNumber, g.ayahNumber), () => {})
          .putIfAbsent(g.position, () => [])
          .add(g);
    }
    for (final e in byVerse.entries) {
      final w = words[e.key];
      if (w == null) continue;
      final positions = e.value.keys.toList()..sort();
      positions.removeLast(); // the verse-end marker
      // Pause signs are separate, very narrow (even negative-width)
      // positions. Keep the rest, and only use verses whose count then
      // matches the words exactly (6017 of 6236); others stay uncoloured
      // rather than risk colouring the wrong word.
      double width(int p) =>
          e.value[p]!.fold(0.0, (s, g) => s + g.maxX - g.minX);
      final kept = [
        for (final p in positions)
          if (width(p) >= 20) p,
      ];
      if (kept.length != w.length) continue;
      for (var i = 0; i < kept.length; i++) {
        if (!isDivineName(w[i])) continue;
        for (final g in e.value[kept[i]]!) {
          out.add(
            Rect.fromLTRB(
              g.minX.toDouble(),
              g.minY.toDouble(),
              g.maxX.toDouble(),
              g.maxY.toDouble(),
            ),
          );
        }
      }
    }
  } else {
    for (final b in await repo.wordBoxes(page)) {
      final w = words[(b.surah, b.ayah)];
      if (w == null || b.word > w.length || !isDivineName(w[b.word - 1])) {
        continue;
      }
      out.add(Rect.fromLTRB(b.x0 / 10, b.y0 / 10, b.x1 / 10, b.y1 / 10));
    }
  }
  return out;
});
