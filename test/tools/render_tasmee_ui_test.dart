import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:archive/archive_io.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/db/user_database.dart';
import 'package:tibyan/core/flags/feature_flags.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/hifz/domain/recitation_test.dart';
import 'package:tibyan/features/hifz/hifz_providers.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/illuminated_frame.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/mushaf_page.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/page_interaction.dart';
import 'package:tibyan/features/tasmee/data/tasmee_words_repository.dart';
import 'package:tibyan/features/tasmee/domain/expected_words.dart';
import 'package:tibyan/features/tasmee/domain/recitation_range.dart';
import 'package:tibyan/features/tasmee/domain/tasmee_session_request.dart';
import 'package:tibyan/features/tasmee/presentation/tasmee_session_screen.dart';
import 'package:tibyan/features/tasmee/presentation/tasmee_setup_screen.dart';
import 'package:tibyan/l10n/app_localizations.dart';

import 'tasmee_ui_mockups.dart';

typedef _Word = (int, int, int);

/// What the page shows: words shown per verse (absent: covered whole), the
/// words recoloured by state, and the words marks are drawn over.
class _PageSpec {
  const _PageSpec({
    this.shown = const {},
    this.colors = const {},
    this.marks = const {},
    this.cover = true,
  });

  final Map<int, int> shown;
  final Map<Color, List<_Word>> colors;
  final Map<_Word, WordMarkKind> marks;
  final bool cover;
}

class _Env {
  const _Env(this.mode, {this.lang = 'ar', this.elderly = false});

  final ThemeModeId mode;
  final String lang;
  final bool elderly;
}

/// Not a test: draws the tasmee UI proposal (test/tools/tasmee_ui_mockups.dart)
/// and the current screens into `$TASMEE_UI_OUT/<name>.png`, with the real
/// 1441 mushaf page 3 (al-Baqarah 6-16) and real words from content.db.
/// Runs only with RENDER_TASMEE_UI=1; TASMEE_UI_ONLY limits it to names
/// containing one of its comma-separated words.
void main() {
  final run = Platform.environment['RENDER_TASMEE_UI'] == '1';
  final outPath = Platform.environment['TASMEE_UI_OUT'] ?? 'build/tasmee_ui';
  final only = Platform.environment['TASMEE_UI_ONLY']?.split(',');
  const phone = Size(393, 852);
  const laptop = Size(1440, 900);
  const page = 3;

  testWidgets(
    'render tasmee ui mockups',
    (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => Directory.systemTemp.createTempSync('support').path,
      );
      final db = ContentDatabase(
        NativeDatabase(
          File('assets/db/content.db'),
          setup: (raw) => raw.execute('PRAGMA query_only = ON'),
        ),
      );
      await tester.runAsync(() async {
        final manifest = jsonDecode(
          await rootBundle.loadString('FontManifest.json'),
        ) as List<dynamic>;
        for (final f in manifest.cast<Map<String, dynamic>>()) {
          final loader = FontLoader(f['family'] as String);
          for (final a in (f['fonts'] as List).cast<Map<String, dynamic>>()) {
            loader.addFont(
              rootBundle.load(Uri.decodeFull(a['asset'] as String)),
            );
          }
          await loader.load();
        }
      });
      final registry = (await tester.runAsync(
        () => ThemeRegistry.load(rootBundle),
      ))!;
      final flags = (await tester.runAsync(
        () => FeatureFlags.load(rootBundle),
      ))!;
      final out = Directory(outPath)..createSync(recursive: true);
      final root = Directory.systemTemp.createTempSync('tasmee_ui');
      final newDir = Directory(p.join(root.path, 'packs', 'pages-hafs-1441-v1'))
        ..createSync(recursive: true);
      final newZip = ZipDecoder().decodeStream(
        InputFileStream('assets/packs/pages-hafs-1441-v1.zip'),
      );
      final e = newZip.findFile('${page.toString().padLeft(3, '0')}.svg.xz')!;
      File(p.join(newDir.path, e.name)).writeAsBytesSync(e.content);
      File(p.join(newDir.path, '.installed')).writeAsStringSync('x');

      SharedPreferences.setMockInitialValues({
        'settings.onboardingDone': true,
        'settings.language': 'ar',
      });
      final shared = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          themeRegistryProvider.overrideWithValue(registry),
          featureFlagsProvider.overrideWithValue(flags),
          sharedPreferencesProvider.overrideWithValue(shared),
          contentDatabaseProvider.overrideWithValue(db),
          userDatabaseProvider.overrideWithValue(
            UserDatabase(NativeDatabase.memory()),
          ),
          packRootProvider.overrideWithValue(root),
          readingPositionProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );
      Future<T> load<T>(Future<T> Function() f) async =>
          (await tester.runAsync(f)) as T;
      final boxes = await load(
        () => container.read(pageWordBoxesProvider(page).future),
      );
      final units = await load(
        () => container.read(pageRevealUnitsProvider(page).future),
      );
      final info = await load(
        () => container.read(frameInfoProvider(page).future),
      );
      final surahs = await load(() => container.read(surahsProvider.future));
      final repo = TasmeeWordsRepository(db);
      final range = const VerseRange(
        fromSurah: 2,
        fromAyah: 6,
        toSurah: 2,
        toAyah: 16,
      );
      final words = await load(() => repo.expectedWords(range));
      final quarter = HizbPartRange.quarter(2);
      final quarterWords = await load(() => repo.expectedWords(quarter));
      final verses = units.keys.toList()
        ..sort((a, b) => a.ayah.compareTo(b.ayah));
      int len(int ayah) => units[(surah: 2, ayah: ayah)]!.length;

      bool wanted(String name) =>
          only == null || only.any((w) => name.contains(w));

      ThemeData theme(_Env env) => buildTheme(
        style: registry.byId('zakhrafa'),
        mode: env.mode,
        uiFont: UiFont.plex,
        elderly: env.elderly,
      );

      Future<GlobalKey> pump(Widget home, Size size, _Env env) async {
        await tester.binding.setSurfaceSize(size);
        tester.view.devicePixelRatio = 2;
        final phoneLike = size.width < 600;
        tester.view.padding = FakeViewPadding(
          top: phoneLike ? 59 * 2 : 0,
          bottom: phoneLike ? 34 * 2 : 0,
        );
        tester.view.viewPadding = tester.view.padding;
        final boundary = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: Locale(env.lang),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                theme: theme(env),
                builder: env.elderly
                    ? (context, child) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: const TextScaler.linear(elderlyTextScale),
                        ),
                        child: child!,
                      )
                    : null,
                home: home,
              ),
            ),
          ),
        );
        for (var i = 0; i < 24; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 30)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        return boundary;
      }

      Future<ui.Image> capture(GlobalKey boundary) async {
        final object =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        return (await tester.runAsync(() => object.toImage(pixelRatio: 2)))!;
      }

      Future<Uint8List> rgba(ui.Image image) async {
        final d = await tester.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
        );
        return d!.buffer.asUint8List();
      }

      Future<void> save(String name, GlobalKey boundary) async {
        final image = await capture(boundary);
        final bytes = await tester.runAsync(() async {
          final d = await image.toByteData(format: ui.ImageByteFormat.png);
          return d!.buffer.asUint8List();
        });
        image.dispose();
        File('${out.path}/$name.png').writeAsBytesSync(bytes!);
        debugPrint('wrote $name');
      }

      PageInteraction interaction(
        _PageSpec spec, {
        List<Rect> tint = const [],
        Color? color,
        bool cover = true,
      }) {
        final test = RecitationTest();
        for (final v in verses) {
          final n = spec.shown[v.ayah] ?? 0;
          for (var i = 0; i < n && i < units[v]!.length; i++) {
            test.revealPiece(v, units[v]);
          }
        }
        final covers = test.covers(verses, units);
        final on = cover && spec.cover;
        return PageInteraction(
          selection: const {},
          marks: const {},
          onTap: () {},
          onVerseLongPress: (_) {},
          onMarkerTap: (_) {},
          onHandleDrag: (_, _) {},
          hidden: on ? covers.hidden : null,
          hiddenWords: on ? covers.pieces : const {},
          revealedWords: on ? test.shownPieces(verses, units) : const {},
          divineNames: tint,
          divineColor: color,
        );
      }

      Widget pageWidget(PageInteraction x, ModeTokens t) => Scaffold(
        backgroundColor: t.bg,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
          child: IlluminatedFrame(
            info: info,
            child: MushafPage(page: page, interaction: x),
          ),
        ),
      );

      /// The real page at [slot], recoloured word by word (each colour drawn
      /// on its own, then merged pixel by pixel), and where each marked
      /// word lands (a magenta probe, diffed against the plain page).
      Future<(ui.Image, List<WordMark>)> pageShot(
        _PageSpec spec,
        Size slot,
        _Env env,
      ) async {
        final t = theme(env).extension<TibyanTokens>()!.colors;
        final noPad = FakeViewPadding.zero;
        Future<Uint8List> raw(PageInteraction x) async {
          final key = await pump(pageWidget(x, t), slot, env);
          tester.view.padding = noPad;
          final image = await capture(key);
          final bytes = await rgba(image);
          image.dispose();
          return bytes;
        }

        final base = await raw(interaction(spec));
        final merged = Uint8List.fromList(base);
        for (final MapEntry(key: color, value: ws) in spec.colors.entries) {
          final v = await raw(
            interaction(
              spec,
              tint: [for (final w in ws) ...boxes[w]!],
              color: color,
            ),
          );
          for (var i = 0; i < v.length; i += 4) {
            if ((v[i] - base[i]).abs() +
                    (v[i + 1] - base[i + 1]).abs() +
                    (v[i + 2] - base[i + 2]).abs() >
                24) {
              merged.setRange(i, i + 4, v.sublist(i, i + 4));
            }
          }
        }
        final marks = <WordMark>[];
        if (spec.marks.isNotEmpty) {
          final plain = await raw(interaction(spec, cover: false));
          final w = (slot.width * 2).round();
          for (final MapEntry(key: word, value: kind) in spec.marks.entries) {
            final v = await raw(
              interaction(
                spec,
                cover: false,
                tint: boxes[word]!,
                color: const Color(0xFFFF00FF),
              ),
            );
            var l = 1 << 30, tp = 1 << 30, r = -1, b = -1;
            for (var i = 0; i < v.length; i += 4) {
              if ((v[i] - plain[i]).abs() +
                      (v[i + 1] - plain[i + 1]).abs() +
                      (v[i + 2] - plain[i + 2]).abs() >
                  60) {
                final px = (i ~/ 4) % w, py = (i ~/ 4) ~/ w;
                if (px < l) l = px;
                if (px > r) r = px;
                if (py < tp) tp = py;
                if (py > b) b = py;
              }
            }
            if (r >= 0) {
              marks.add(
                WordMark(
                  Rect.fromLTRB(l / 2, tp / 2, (r + 1) / 2, (b + 1) / 2),
                  kind,
                ),
              );
            }
          }
        }
        final h = (slot.height * 2).round(), w = (slot.width * 2).round();
        final image = (await tester.runAsync(() {
          final c = Completer<ui.Image>();
          ui.decodeImageFromPixels(
            merged,
            w,
            h,
            ui.PixelFormat.rgba8888,
            c.complete,
          );
          return c.future;
        }))!;
        return (image, marks);
      }

      /// Measures the page slot of [screen], draws the page for it, then
      /// draws the screen with that page.
      Future<void> scene(
        String name,
        Size size,
        _Env env,
        _PageSpec spec,
        Widget Function(Widget page) screen,
      ) async {
        if (!wanted(name)) return;
        var slot = Size.zero;
        await pump(screen(PageSlot(onSize: (s) => slot = s)), size, env);
        final (image, marks) = await pageShot(spec, slot, env);
        final key = await pump(
          screen(PageSlot(image: image, marks: marks)),
          size,
          env,
        );
        await save(name, key);
        image.dispose();
      }

      // ---- the session's states -------------------------------------------
      final light = const _Env(ThemeModeId.light);
      final night = const _Env(ThemeModeId.night);
      String surahName(_Env env) =>
          env.lang == 'ar' ? surahs[1].nameAr : surahs[1].nameEn;
      final c = TasmeeStateColors.of(
        ThemeModeId.light,
        registry.byId('zakhrafa').modes[ThemeModeId.light]!,
      );
      final cn = TasmeeStateColors.of(
        ThemeModeId.night,
        registry.byId('zakhrafa').modes[ThemeModeId.night]!,
      );
      Map<Color, List<_Word>> colours(
        TasmeeStateColors k, {
        required List<_Word> wrong,
        List<_Word> skipped = const [],
        List<_Word> corrected = const [],
        List<_Word> doubtful = const [],
        List<_Word> hint = const [],
      }) => {
        if (wrong.isNotEmpty) k.wrong: wrong,
        if (skipped.isNotEmpty) k.skipped: skipped,
        if (corrected.isNotEmpty) k.corrected: corrected,
        if (doubtful.isNotEmpty) k.doubtful: doubtful,
        if (hint.isNotEmpty) k.hint: hint,
      };
      int acc(int correct, int judged) => (100 * correct / judged).round();
      final bandsA = spectrumBands(syntheticVoice());
      final bandsB = spectrumBands(
        syntheticVoice(
          f0: 128,
          formants: const [520, 900, 2400],
          gain: 0.8,
          seed: 3,
        ),
      );
      final bandsC = spectrumBands(
        syntheticVoice(
          f0: 170,
          formants: const [380, 2100, 2900],
          gain: 0.6,
          seed: 11,
        ),
      );

      final listeningInfo = SessionInfo(
        surahName: surahs[1].nameAr,
        fromAyah: 6,
        toAyah: 16,
        progress: (len(6) + len(7) + 5) / words.length,
        elapsed: const Duration(minutes: 1, seconds: 47),
        currentAyah: 8,
        currentAccuracy: acc(4, 5),
        toastAyah: 7,
        toastAccuracy: acc(len(7) - 2, len(7) - 1),
        toastErrors: 1,
      );
      _PageSpec listening(TasmeeStateColors k) => _PageSpec(
        shown: {6: len(6), 7: len(7), 8: 5},
        colors: colours(
          k,
          wrong: [(2, 7, 4)],
          skipped: [(2, 8, 3)],
          corrected: [(2, 6, 5)],
          doubtful: [(2, 7, 9)],
        ),
        marks: {
          (2, 8, 3): WordMarkKind.skippedFrame,
          (2, 7, 9): WordMarkKind.doubtfulUnderline,
          (2, 8, 6): WordMarkKind.cursor,
        },
      );

      for (final (env, k, tag) in [(light, c, 'light'), (night, cn, 'night')]) {
        await scene(
          'session_proposed_$tag',
          phone,
          env,
          listening(k),
          (pg) => SessionScreenMock(
            page: pg,
            state: PanelState.listening,
            info: listeningInfo,
            bands: bandsA,
          ),
        );
      }

      await scene(
        'stop_to_correct_light',
        phone,
        light,
        _PageSpec(
          shown: {6: len(6), 7: 4},
          colors: colours(c, wrong: [(2, 7, 4)]),
          marks: {(2, 7, 4): WordMarkKind.wrongRing},
        ),
        (pg) => SessionScreenMock(
          page: pg,
          state: PanelState.stopToCorrect,
          info: SessionInfo(
            surahName: surahs[1].nameAr,
            fromAyah: 6,
            toAyah: 16,
            progress: (len(6) + 4) / words.length,
            elapsed: const Duration(seconds: 58),
            currentAyah: 7,
            currentAccuracy: acc(3, 4),
          ),
          bands: bandsB,
        ),
      );

      await scene(
        'verse_by_verse_night',
        phone,
        night,
        _PageSpec(
          shown: {6: len(6), 7: len(7), 8: len(8)},
          colors: colours(cn, wrong: [(2, 7, 4)], corrected: [(2, 8, 7)]),
          marks: {(2, 9, 1): WordMarkKind.cursor},
        ),
        (pg) => SessionScreenMock(
          page: pg,
          state: PanelState.verseByVerse,
          info: SessionInfo(
            surahName: surahs[1].nameAr,
            fromAyah: 6,
            toAyah: 16,
            progress: (len(6) + len(7) + len(8)) / words.length,
            elapsed: const Duration(minutes: 2, seconds: 31),
            currentAyah: 9,
            currentAccuracy: acc(len(8) - 1, len(8)),
            verseByVerse: true,
          ),
          bands: bandsC,
        ),
      );

      await scene(
        'hint_light',
        phone,
        light,
        _PageSpec(
          shown: {6: len(6), 7: len(7), 8: 6},
          colors: colours(
            c,
            wrong: [(2, 7, 4)],
            skipped: [(2, 8, 3)],
            corrected: [(2, 6, 5)],
            doubtful: [(2, 7, 9)],
            hint: [(2, 8, 6)],
          ),
          marks: {
            (2, 8, 3): WordMarkKind.skippedFrame,
            (2, 7, 9): WordMarkKind.doubtfulUnderline,
            (2, 8, 6): WordMarkKind.hintBadge,
            (2, 8, 7): WordMarkKind.cursor,
          },
        ),
        (pg) => SessionScreenMock(
          page: pg,
          state: PanelState.paused,
          info: SessionInfo(
            surahName: surahs[1].nameAr,
            fromAyah: 6,
            toAyah: 16,
            progress: (len(6) + len(7) + 6) / words.length,
            elapsed: const Duration(minutes: 2, seconds: 4),
            currentAyah: 8,
            currentAccuracy: acc(4, 6),
          ),
          bands: bandsA,
        ),
      );

      // ---- end of session -------------------------------------------------
      final byAyah = <int, List<ExpectedWord>>{};
      for (final w in words) {
        (byAyah[w.ayah] ??= []).add(w);
      }
      String excerpt(int ayah) =>
          byAyah[ayah]!.take(4).map((w) => w.display).join(' ');
      final all = {for (final v in verses) v.ayah: len(v.ayah)};
      for (final (env, k, tag) in [(light, c, 'light'), (night, cn, 'night')]) {
        await scene(
          'summary_$tag',
          phone,
          env,
          _PageSpec(
            shown: all,
            colors: colours(
              k,
              wrong: [(2, 7, 4), (2, 12, 3)],
              skipped: [(2, 8, 3)],
              corrected: [(2, 6, 5)],
              doubtful: [(2, 7, 9), (2, 14, 5)],
              hint: [(2, 10, 2)],
            ),
          ),
          (pg) => SessionScreenMock(
            page: pg,
            state: PanelState.paused,
            info: listeningInfo,
            bands: bandsA,
            sheet: SummarySheetMock(
              title: '${surahs[1].nameAr} ٦–١٦',
              duration:
                  'المدة ٨ د ١٢ ث · ${NumberFormatter(const Locale('ar'))(words.length)} كلمة',
              accuracy: acc(words.length - 5, words.length - 2),
              counts: (2, 1, 1, 2, 1),
              rows: [
                SummaryRow(7, acc(len(7) - 2, len(7) - 1), excerpt(7), (
                  1,
                  0,
                  0,
                  1,
                  0,
                )),
                SummaryRow(8, acc(len(8) - 1, len(8)), excerpt(8), (
                  0,
                  1,
                  0,
                  0,
                  0,
                )),
                SummaryRow(10, acc(len(10) - 1, len(10)), excerpt(10), (
                  0,
                  0,
                  0,
                  0,
                  1,
                )),
                SummaryRow(12, acc(len(12) - 1, len(12)), excerpt(12), (
                  1,
                  0,
                  0,
                  0,
                  0,
                )),
              ],
            ),
          ),
        );
      }

      // ---- before the session -----------------------------------------------
      final hiddenAll = const _PageSpec();
      final idleInfo = SessionInfo(
        surahName: surahs[1].nameAr,
        fromAyah: 6,
        toAyah: 16,
        progress: 0,
        elapsed: Duration.zero,
        currentAyah: 6,
        currentAccuracy: 0,
      );
      await scene(
        'first_use_light',
        phone,
        light,
        hiddenAll,
        (pg) => SessionScreenMock(
          page: pg,
          state: PanelState.paused,
          info: idleInfo,
          bands: bandsA,
          sheet: const FirstUseSheetMock(),
        ),
      );
      await scene(
        'mic_denied_light',
        phone,
        light,
        hiddenAll,
        (pg) => SessionScreenMock(
          page: pg,
          state: PanelState.micDenied,
          info: idleInfo,
          bands: bandsA,
        ),
      );
      final attribution = lookupAppLocalizations(const Locale('ar'))
          .tasmeeModelAttribution;
      await scene(
        'model_consent_light',
        phone,
        light,
        hiddenAll,
        (pg) => SessionScreenMock(
          page: pg,
          state: PanelState.paused,
          info: idleInfo,
          bands: bandsA,
          sheet: ModelSheetMock(attribution: attribution),
        ),
      );
      await scene(
        'model_downloading_night',
        phone,
        night,
        hiddenAll,
        (pg) => SessionScreenMock(
          page: pg,
          state: PanelState.paused,
          info: idleInfo,
          bands: bandsA,
          sheet: ModelSheetMock(attribution: attribution, progress: 0.46),
        ),
      );

      final ar = NumberFormatter(const Locale('ar'));
      final pages = words.map((w) => w.page).toSet();
      final qFirst = quarterWords.first, qLast = quarterWords.last;
      final qPages = quarterWords.map((w) => w.page).toSet();
      for (final (env, tag, kind, fields, summary) in [
        (
          light,
          'light',
          7,
          [
            [('من سورة', surahs[1].nameAr, false), ('آية', ar(6), true)],
            [('إلى سورة', surahs[1].nameAr, false), ('آية', ar(16), true)],
          ],
          '${ar(11)} آية · ${ar(words.length)} كلمة · صفحة ${ar(pages.first)}',
        ),
        (
          night,
          'night',
          4,
          [
            [('الحزب', ar(1), true), ('الربع', ar(2), true)],
          ],
          'من ${surahs[1].nameAr} ${ar(qFirst.ayah)} إلى ${ar(qLast.ayah)} · ${ar(quarterWords.length)} كلمة · ص ${ar(qPages.reduce((a, b) => a < b ? a : b))}–${ar(qPages.reduce((a, b) => a > b ? a : b))}',
        ),
      ]) {
        await scene(
          'setup_proposed_$tag',
          phone,
          env,
          const _PageSpec(cover: false),
          (pg) => Stack(
            children: [
              Scaffold(
                backgroundColor: theme(env)
                    .extension<TibyanTokens>()!
                    .colors
                    .bg,
                body: SafeArea(child: pg),
              ),
              Positioned.fill(
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.38)),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SetupSheetMock(
                  kind: kind,
                  fields: fields,
                  summary: summary,
                  resume: 'آخر تسميع: ${surahs[1].nameAr} ١–٥ · ٩٦٪',
                ),
              ),
            ],
          ),
        );
      }

      // ---- elderly, English, laptop -----------------------------------------
      await scene(
        'elderly_light',
        phone,
        const _Env(ThemeModeId.light, elderly: true),
        listening(c),
        (pg) => SessionScreenMock(
          page: pg,
          state: PanelState.listening,
          info: listeningInfo,
          bands: bandsA,
        ),
      );
      const english = _Env(ThemeModeId.light, lang: 'en');
      await scene(
        'english_light',
        phone,
        english,
        listening(c),
        (pg) => SessionScreenMock(
          page: pg,
          state: PanelState.listening,
          info: SessionInfo(
            surahName: surahName(english),
            fromAyah: 6,
            toAyah: 16,
            progress: listeningInfo.progress,
            elapsed: listeningInfo.elapsed,
            currentAyah: 8,
            currentAccuracy: listeningInfo.currentAccuracy,
            toastAyah: 7,
            toastAccuracy: listeningInfo.toastAccuracy,
            toastErrors: 1,
          ),
          bands: bandsA,
        ),
      );
      await scene(
        'laptop_light',
        laptop,
        light,
        listening(c),
        (pg) => LaptopSessionMock(
          page: pg,
          info: SessionInfo(
            surahName: surahs[1].nameAr,
            fromAyah: 6,
            toAyah: 16,
            progress: listeningInfo.progress,
            elapsed: listeningInfo.elapsed,
            currentAyah: 8,
            currentAccuracy: listeningInfo.currentAccuracy,
            toastAyah: 7,
            toastAccuracy: listeningInfo.toastAccuracy,
            toastErrors: 1,
            verseRows: [
              (6, 100),
              (7, listeningInfo.toastAccuracy),
              (8, listeningInfo.currentAccuracy),
              for (var a = 9; a <= 16; a++) (a, null),
            ],
          ),
          bands: bandsA,
        ),
      );

      // ---- the state colours in each mode -----------------------------------
      if (wanted('state_colours')) {
        final sample = byAyah[7]!.first.display;
        final key = await pump(
          Builder(
            builder: (context) => Scaffold(
              backgroundColor: const Color(0xFFE9DFCF),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    for (final (m, label) in [
                      (ThemeModeId.light, 'فاتح'),
                      (ThemeModeId.white, 'أبيض'),
                      (ThemeModeId.night, 'ليلي'),
                      (ThemeModeId.black, 'أسود'),
                    ])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Theme(
                            data: theme(_Env(m)),
                            child: PaletteCard(title: label, sample: sample),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const Size(1000, 360),
          light,
        );
        await save('state_colours', key);
      }

      // ---- the current screens, for comparison ------------------------------
      if (wanted('setup_current')) {
        await save(
          'setup_current_light',
          await pump(const TasmeeSetupScreen(), phone, light),
        );
      }
      if (wanted('session_current')) {
        await save(
          'session_current_light',
          await pump(
            TasmeeSessionScreen(
              request: TasmeeSessionRequest(
                range: range,
                words: words,
                mode: TasmeeMode.continuous,
              ),
            ),
            phone,
            light,
          ),
        );
      }

      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.runAsync(db.close);
    },
    skip: !run,
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
