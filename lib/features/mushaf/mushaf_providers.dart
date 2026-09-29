import 'dart:async';
import 'dart:io';
import 'dart:ui' show Locale, Rect;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/db/ayahinfo_database.dart';
import '../../core/db/content_database.dart';
import '../../core/settings/app_settings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/db/user_database.dart';
import '../../l10n/app_localizations.dart';
import 'data/background_packs.dart';
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

/// Where page packs are installed.
final packsDirProvider = Provider<Directory>(
  (ref) => Directory(p.join(ref.watch(packRootProvider).path, 'packs')),
);

/// Bumped whenever a pack is installed, so what depends on the packs on
/// the device is worked out again.
class PackInstalls extends Notifier<int> {
  @override
  int build() => 0;

  void changed() => state++;
}

final packInstallsProvider = NotifierProvider<PackInstalls, int>(
  PackInstalls.new,
);

/// Editions whose pages are on this device.
final installedEditionsProvider = Provider<Set<MushafEdition>>((ref) {
  ref.watch(packInstallsProvider);
  final root = ref.watch(packsDirProvider);
  return {
    for (final e in MushafEdition.values)
      if (PagePackInstaller(root: root, spec: PagePackSpec.of(e)).isInstalled)
        e,
  };
});

/// The mushaf edition the reader chose (it may still be downloading).
final chosenEditionProvider = Provider<MushafEdition>(
  (ref) => ref.watch(settingsProvider.select((s) => s.edition)),
);

/// The edition the pages are read in: the chosen one once its pages are
/// on the device, until then the new Madina edition, which ships with the
/// app.
final editionProvider = Provider<MushafEdition>((ref) {
  final chosen = ref.watch(chosenEditionProvider);
  return ref.watch(installedEditionsProvider).contains(chosen)
      ? chosen
      : MushafEdition.madina1441;
});

final pageInstallerProvider = Provider<PagePackInstaller>(
  (ref) => PagePackInstaller(
    root: ref.watch(packsDirProvider),
    spec: PagePackSpec.of(ref.watch(editionProvider)),
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

/// Whether the pages being read are on this device.
final pagesInstalledProvider = Provider<bool>((ref) {
  ref.watch(packInstallsProvider);
  return ref.watch(pageInstallerProvider).isInstalled;
});

/// System-managed pack downloads (they go on in the background).
final backgroundPacksProvider = Provider<BackgroundPacks>(
  (ref) => BackgroundPacks(root: ref.watch(packsDirProvider)),
);

/// An edition's name in the interface language, for notifications.
String editionName(AppLocalizations l, MushafEdition e) => switch (e) {
  MushafEdition.madina1441 => l.editionNew,
  MushafEdition.madina1405 => l.editionOld,
  MushafEdition.shamarly => l.editionShamarly,
};

/// The current edition's page download. The system runs it, so it goes on
/// when the reader leaves the screen or the app; this follows its progress.
class PageDownloadController extends Notifier<PackProgress> {
  StreamSubscription<(String, PackProgress)>? _sub;

  @override
  PackProgress build() {
    ref.onDispose(() => _sub?.cancel());
    // Watched, not read: choosing another edition follows that edition's
    // pack (a download of the old one goes on by itself).
    final chosen = ref.watch(chosenEditionProvider);
    final spec = PagePackSpec.of(chosen);
    final packs = ref.read(backgroundPacksProvider);
    _sub = packs.progress.listen((e) {
      // Any pack that lands changes what is on the device.
      if (e.$2.phase == PackPhase.installed) {
        ref.read(packInstallsProvider.notifier).changed();
      }
      if (e.$1 == spec.id) state = e.$2;
    });
    if (ref.read(installedEditionsProvider).contains(chosen)) {
      return const PackProgress(PackPhase.installed);
    }
    // Pick up a download that was already running or paused.
    unawaited(
      packs.stateOf(spec).then((s) => state = s).catchError((_) => state),
    );
    return const PackProgress(PackPhase.idle);
  }

  AppLocalizations get _l => lookupAppLocalizations(
    ref.read(settingsProvider).locale ?? const Locale('ar'),
  );

  Future<void> start() async {
    final edition = ref.read(chosenEditionProvider);
    state = PackProgress(
      PackPhase.downloading,
      received: state.received,
      total: state.total,
    );
    await ref
        .read(backgroundPacksProvider)
        .enqueue(PagePackSpec.of(edition), editionName(_l, edition));
  }

  /// Queues every edition that is not on the device yet.
  Future<void> startAll() async {
    final packs = ref.read(backgroundPacksProvider);
    for (final e in MushafEdition.values) {
      await packs.enqueue(PagePackSpec.of(e), editionName(_l, e));
    }
  }

  Future<void> pause() async {
    await ref
        .read(backgroundPacksProvider)
        .pause(PagePackSpec.of(ref.read(chosenEditionProvider)));
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

/// Page of a verse in the chosen edition (where it starts).
final versePageProvider = FutureProvider.family<int, (int, int)>(
  (ref, v) async => (await ref.watch(mushafRepositoryProvider).ayah(v.$1, v.$2))
      .pageIn(ref.watch(editionProvider)),
);

SurahBanner _banner(List<SurahRow> surahs, int surah, int line, int slots) {
  final s = surahs[surah - 1];
  final before = surahs
      .where((x) => x.revelationOrder == s.revelationOrder - 1)
      .firstOrNull;
  return SurahBanner(
    line: line,
    slots: slots,
    number: s.id,
    name: s.nameAr,
    meccan: s.revelation == 'meccan',
    ayahCount: s.ayahCount,
    order: s.revelationOrder,
    after: before?.nameAr,
  );
}

/// Frame details of a Shamarly page, from its printed headers, line slots
/// and verse boxes.
Future<FrameInfo?> _shamarlyFrameInfo(Ref ref, int page) async {
  final repo = ref.watch(mushafRepositoryProvider);
  const edition = MushafEdition.shamarly;
  final ayahs = await repo.ayahsOnPage(page, edition);
  if (ayahs.isEmpty) return null;
  final surahs = await ref.watch(surahsProvider.future);
  final first = ayahs.first;
  final lines = await repo.shamarlyLines(page);

  // Line where each verse starts on this page.
  final lineOf = <(int, int), int>{};
  for (final b in await repo.shamarlyVerseBoxes(page)) {
    lineOf.putIfAbsent((b.surah, b.ayah), () => b.line);
  }
  // Pages 1-3 are the cover and the ornate opening pages.
  final text = page > 3;
  final banners = [
    if (text)
      for (final h in await repo.shamarlyHeaders(page))
        if (h.firstLine != null) _banner(surahs, h.surah, h.firstLine!, 2),
  ];
  final quarters = <QuarterMark>[
    if (text)
      for (final a in await repo.quarterStartsOnPage(page, edition))
        if (lineOf[(a.surah, a.number)] case final line?)
          QuarterMark(
            line: line,
            quarter: a.hizbQuarter,
            surah: a.surah,
            ayah: a.number,
          ),
  ];

  String? catchword;
  if (page < edition.pageCount) {
    final next = (await repo.ayahsOnPage(page + 1, edition)).firstOrNull;
    if (next != null && next.pageShamarly <= page) {
      // The verse runs over the page: its first word there, when the
      // verse's words are placed surely enough; otherwise none.
      final pages = await repo.shamarlyWordPages(next.surah, next.number);
      final words = _words(next);
      int? n;
      for (final e in pages.entries) {
        if (e.value == page + 1 && (n == null || e.key < n)) n = e.key;
      }
      if (n != null && n <= words.length) catchword = words[n - 1];
    } else if (next != null) {
      final opensWith = (await repo.shamarlyLines(page + 1)).firstOrNull?.kind;
      catchword =
          (opensWith == 'basmala' || opensWith == 'header') && next.surah != 9
          ? (await ref.watch(basmalaProvider.future))
                .split(' ')
                .take(2)
                .join(' ')
          : _words(next).firstOrNull;
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
    basmalaLines: {
      for (final l in lines)
        if (l.kind == 'basmala') l.line,
    },
    outerRight: page.isOdd,
  );
}

/// Words of a verse as numbered in the word boxes (the hizb sign is not
/// a word).
List<String> _words(AyahRow a) => [
  for (final w in a.displayBody.split(RegExp('[\u00a0 ]')))
    if (w.isNotEmpty && w != '۞') w,
];

/// Juz, hizb, surah and catchword for the frame around a page.
final frameInfoProvider = FutureProvider.family<FrameInfo?, int>((
  ref,
  page,
) async {
  final edition = ref.watch(editionProvider);
  if (edition == MushafEdition.shamarly) return _shamarlyFrameInfo(ref, page);
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
      banners.add(_banner(surahs, a.surah, header, 1));
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
        banners.add(_banner(surahs, next.surah, header, 1));
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
    basmalaLines: {
      for (final b in banners)
        if (b.number != 9) b.line + 1,
    },
    outerRight: page.isOdd,
  );
});

final hizbStartsProvider = FutureProvider<List<AyahRow>>(
  (ref) => ref.watch(mushafRepositoryProvider).hizbStarts(),
);

/// Words of each verse on a page, as numbered in the word boxes: the
/// words of the KFGQPC text, without the hizb sign.
Future<Map<(int, int), List<String>>> _pageWords(Ref ref, int page) async {
  final edition = ref.watch(editionProvider);
  final ayahs = await ref
      .watch(mushafRepositoryProvider)
      .ayahsOnPage(page, edition);
  return {for (final a in ayahs) (a.surah, a.number): _words(a)};
}

/// The boxes of every word on a page, keyed by (surah, verse, word): one
/// box in page units in the new edition (tools/build_word_boxes.py); the
/// word's glyph boxes in image pixels in the old one (quran.com's glyph
/// boxes matched to the words); one box in image pixels in the Shamarly
/// edition, for verses split surely enough (`shamarlyWordLevel`).
final pageWordBoxesProvider =
    FutureProvider.family<Map<(int, int, int), List<Rect>>, int>((
      ref,
      page,
    ) async {
      final edition = ref.watch(editionProvider);
      final out = <(int, int, int), List<Rect>>{};
      if (edition == MushafEdition.madina1441) {
        for (final b
            in await ref.watch(mushafRepositoryProvider).wordBoxes(page)) {
          out[(b.surah, b.ayah, b.word)] = [
            Rect.fromLTRB(b.x0 / 10, b.y0 / 10, b.x1 / 10, b.y1 / 10),
          ];
        }
        return out;
      }
      if (edition == MushafEdition.shamarly) {
        final repo = ref.watch(mushafRepositoryProvider);
        for (final b in await repo.shamarlyWordBoxes(page)) {
          out[(b.surah, b.ayah, b.word)] = [
            Rect.fromLTRB(
              b.x0.toDouble(),
              b.y0.toDouble(),
              b.x1.toDouble(),
              b.y1.toDouble(),
            ),
          ];
        }
        return out;
      }
      final words = await _pageWords(ref, page);
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
        // matches the words exactly (6017 of 6236); others get no word
        // boxes rather than risk marking the wrong word.
        double width(int p) =>
            e.value[p]!.fold(0.0, (s, g) => s + g.maxX - g.minX);
        final kept = [
          for (final p in positions)
            if (width(p) >= 20) p,
        ];
        if (kept.length != w.length) continue;
        for (var i = 0; i < kept.length; i++) {
          out[(e.key.$1, e.key.$2, i + 1)] = [
            for (final g in e.value[kept[i]]!)
              Rect.fromLTRB(
                g.minX.toDouble(),
                g.minY.toDouble(),
                g.maxX.toDouble(),
                g.maxY.toDouble(),
              ),
          ];
        }
      }
      return out;
    });

/// Boxes of the divine names on a page, in the units of
/// [pageWordBoxesProvider].
final divineNameBoxesProvider = FutureProvider.family<List<Rect>, int>((
  ref,
  page,
) async {
  final words = await _pageWords(ref, page);
  final boxes = await ref.watch(pageWordBoxesProvider(page).future);
  return [
    for (final MapEntry(key: (s, a, n), value: pieces) in boxes.entries)
      if (words[(s, a)] case final w?
          when n <= w.length && isDivineName(w[n - 1]))
        ...pieces,
  ];
});
