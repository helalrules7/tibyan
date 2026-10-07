import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/mushaf/presentation/about_mushaf_screen.dart';
import 'package:tibyan/features/mushaf/presentation/mushaf_screen.dart';
import 'package:tibyan/features/tasmee/data/tasmee_backend.dart';
import 'package:tibyan/features/tasmee/data/tasmee_words_repository.dart';
import 'package:tibyan/features/tasmee/domain/alignment_engine.dart';
import 'package:tibyan/features/tasmee/domain/expected_words.dart';
import 'package:tibyan/features/tasmee/domain/recitation_range.dart';
import 'package:tibyan/features/tasmee/domain/tasmee_session_request.dart';
import 'package:tibyan/features/tasmee/presentation/tasmee_session_screen.dart';
import 'package:tibyan/features/tasmee/presentation/tasmee_settings_screen.dart';
import 'package:tibyan/features/tasmee/presentation/tasmee_setup_screen.dart';
import 'package:tibyan/l10n/app_localizations.dart';

import '../tasmee/tasmee_fakes.dart';
import '../tasmee/tasmee_test_env.dart';

/// A deterministic voiced sound for the spectrum: harmonics of [f0]
/// shaped by [formants] (not speech, and nothing is recorded).
Int16List _voice({
  double f0 = 150,
  List<double> formants = const [650, 1150, 2600],
  int seed = 7,
}) {
  const n = 1024, rate = 16000;
  final rng = math.Random(seed);
  final phases = List.generate(40, (_) => rng.nextDouble() * 2 * math.pi);
  final out = Int16List(n);
  for (var i = 0; i < n; i++) {
    final t = i / rate;
    var v = 0.0;
    for (var k = 1; k * f0 < 5200; k++) {
      final f = k * f0;
      var env = 0.0;
      for (final (j, fm) in formants.indexed) {
        final bw = 90.0 + 60 * j;
        env += math.exp(-math.pow(f - fm, 2) / (2 * bw * bw)) / (1 + j * 0.8);
      }
      v += 0.16 * (env + 0.02) * math.sin(2 * math.pi * f * t + phases[k % 40]);
    }
    out[i] = (v.clamp(-1.0, 1.0) * 32767).round();
  }
  return out;
}

/// Not a test: draws the audio tasmee's real screens (driven through a
/// fake recogniser and microphone) into `$TASMEE_UI_OUT/<name>.png`, on
/// the real 1441 page 3 (al-Baqarah 6-16) with the real words of
/// content.db. Runs only with RENDER_TASMEE_UI=1; TASMEE_UI_ONLY limits it
/// to names containing one of its comma-separated words.
void main() {
  final run = Platform.environment['RENDER_TASMEE_UI'] == '1';
  final outPath = Platform.environment['TASMEE_UI_OUT'] ?? 'build/tasmee_ui';
  final only = Platform.environment['TASMEE_UI_ONLY']?.split(',');
  const phone = Size(393, 852);
  const laptop = Size(1440, 900);
  bool wanted(String name) => only == null || only.any((w) => name.contains(w));

  late TasmeeTestData data;
  setUpAll(() => data = TasmeeTestData.open(pages: [1, 2, 3, 4]));
  tearDownAll(() => data.close());

  testWidgets(
    'render the tasmee screens',
    (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => Directory.systemTemp.createTempSync('support').path,
      );
      for (final m in ['toggle', 'isEnabled']) {
        tester.binding.defaultBinaryMessenger.setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.$m',
          (_) async => const StandardMessageCodec().encodeMessage(<Object?>[
            m == 'isEnabled' ? false : null,
          ]),
        );
      }
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
      final out = Directory(outPath)..createSync(recursive: true);
      final repo = TasmeeWordsRepository(data.db);
      const range = VerseRange(
        fromSurah: 2,
        fromAyah: 6,
        toSurah: 2,
        toAyah: 16,
      );
      final words = (await tester.runAsync(() => repo.expectedWords(range)))!;
      List<ExpectedWord> ayah(int a) => [
        for (final w in words)
          if (w.ayah == a) w,
      ];

      /// What the fake recogniser «hears»: the words' matching keys, so
      /// the engine decides each word's state exactly as it would.
      String heard(Iterable<ExpectedWord> ws) =>
          ws.map((w) => w.matching).join(' ');
      String slip(ExpectedWord w) {
        final k = w.matching;
        final last = k.substring(k.length - 1);
        return k.substring(0, k.length - 1) + (last == 'ن' ? 'م' : 'ن');
      }

      Future<void> settleLong([int rounds = 24]) async {
        for (var i = 0; i < rounds; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 30)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      Future<void> save(String name, GlobalKey boundary) async {
        await settleLong();
        final object =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final bytes = await tester.runAsync(() async {
          final image = await object.toImage(pixelRatio: 2);
          final d = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          return d!.buffer.asUint8List();
        });
        File('${out.path}/$name.png').writeAsBytesSync(bytes!);
        debugPrint('wrote $name');
      }

      /// The screens under a router like the app's, in [size], [mode],
      /// [lang] and elderly or not.
      Future<(GlobalKey, GoRouter, FakeBackend, ProviderContainer)> app({
        required Size size,
        ThemeModeId mode = ThemeModeId.light,
        String lang = 'ar',
        bool elderly = false,
        Map<String, Object> prefs = const {'tasmee.firstUseSeen': true},
        FakeBackend? backend,
        Widget Function(BuildContext context)? home,
      }) async {
        final fake = backend ?? FakeBackend();
        final container = await tasmeeContainer(
          tester,
          data,
          prefs: {'settings.language': lang, ...prefs},
          overrides: [tasmeeBackendProvider.overrideWithValue(fake)],
        );
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        final phoneLike = size.width < 600;
        tester.view.padding = FakeViewPadding(
          top: phoneLike ? 59 * 2 : 0,
          bottom: phoneLike ? 34 * 2 : 0,
        );
        tester.view.viewPadding = tester.view.padding;
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => home == null
                  ? Scaffold(
                      backgroundColor: context.tokens.colors.bg,
                      body: const SizedBox.expand(),
                    )
                  : Builder(builder: home),
            ),
            GoRoute(
              path: '/tasmee/session',
              builder: (_, state) => TasmeeSessionScreen(
                request: state.extra! as TasmeeSessionRequest,
              ),
            ),
          ],
        );
        final boundary = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                routerConfig: router,
                locale: Locale(lang),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                theme: tasmeeTheme(container, mode: mode, elderly: elderly),
                builder: elderly
                    ? (context, child) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: const TextScaler.linear(elderlyTextScale),
                        ),
                        child: child!,
                      )
                    : null,
              ),
            ),
          ),
        );
        await settleLong(8);
        return (boundary, router, fake, container);
      }

      Future<void> tap(Finder f) async {
        await tester.tap(f, warnIfMissed: false);
        await settleLong(6);
      }

      Future<void> say(FakeBackend b, String text) async {
        b.recognizer0.say(text);
        await settleLong(4);
      }

      void sound(FakeBackend b, {int seed = 7, double f0 = 150}) =>
          b.microphone0.onFrame?.call(_voice(seed: seed, f0: f0));

      final main = find.byKey(const ValueKey('tasmee-main'));

      /// A session on 2:6-16, the reader at verse 8: a word corrected in
      /// verse 6, a wrong and an unsure word in 7, a skipped word in 8.
      Future<(GlobalKey, FakeBackend)> listening({
        required Size size,
        ThemeModeId mode = ThemeModeId.light,
        String lang = 'ar',
        bool elderly = false,
        ErrorBehavior onError = ErrorBehavior.continueReading,
      }) async {
        final (key, router, b, _) = await app(
          size: size,
          mode: mode,
          lang: lang,
          elderly: elderly,
        );
        router.push(
          '/tasmee/session',
          extra: TasmeeSessionRequest(
            range: range,
            words: words,
            mode: TasmeeMode.continuous,
            onError: onError,
          ),
        );
        await settleLong(8);
        await tap(main);
        final v6 = ayah(6), v7 = ayah(7), v8 = ayah(8);
        await say(b, '${heard(v6.take(4))} قالوا ${heard(v6.skip(4))}');
        final unsure = v7.skip(5).firstWhere((w) => w.matching.length >= 5);
        await say(
          b,
          [
            heard(v7.take(3)),
            'كتاب',
            heard(v7.skip(4).takeWhile((w) => w != unsure)),
            slip(unsure),
            heard(v7.skip(v7.indexOf(unsure) + 1)),
          ].join(' '),
        );
        await say(b, '${heard(v8.take(2))} ${heard(v8.skip(3).take(2))}');
        sound(b);
        return (key, b);
      }

      // ---- the session --------------------------------------------------
      for (final (mode, tag) in [
        (ThemeModeId.light, 'light'),
        (ThemeModeId.night, 'night'),
      ]) {
        final name = 'session_$tag';
        if (wanted(name)) {
          final (key, _) = await listening(size: phone, mode: mode);
          await save(name, key);
        }
      }
      if (wanted('stop_to_correct')) {
        final (key, router, b, _) = await app(size: phone);
        router.push(
          '/tasmee/session',
          extra: TasmeeSessionRequest(
            range: range,
            words: words,
            mode: TasmeeMode.continuous,
            onError: ErrorBehavior.stopToCorrect,
          ),
        );
        await settleLong(8);
        await tap(main);
        final v6 = ayah(6), v7 = ayah(7);
        // A wrong word, waited on, then read right: corrected (green).
        await say(b, '${heard(v6.take(4))} قالوا ${v6[5].matching}');
        await say(b, heard(v6.skip(4)));
        await say(b, '${heard(v7.take(3))} كتاب ${heard(v7.skip(4).take(1))}');
        sound(b, seed: 3, f0: 128);
        await save('stop_to_correct_light', key);
      }
      if (wanted('verse_by_verse')) {
        final (key, router, b, _) = await app(
          size: phone,
          mode: ThemeModeId.night,
        );
        router.push(
          '/tasmee/session',
          extra: TasmeeSessionRequest(
            range: range,
            words: words,
            mode: TasmeeMode.verseByVerse,
          ),
        );
        await settleLong(8);
        for (final a in [6, 7]) {
          await tap(main);
          final v = ayah(a);
          await say(
            b,
            a == 7 ? '${heard(v.take(3))} كتاب ${heard(v.skip(4))}' : heard(v),
          );
          for (var i = 0; i < 12; i++) {
            await tester.pump(const Duration(milliseconds: 500));
          }
        }
        await save('verse_by_verse_night', key);
      }
      if (wanted('hint')) {
        final (key, b) = await listening(size: phone);
        await tap(find.byKey(const ValueKey('tasmee-hint')));
        await tap(main); // pause
        await save('hint_paused_light', key);
        b.microphone0.onFrame = null;
      }

      // ---- the end ------------------------------------------------------
      for (final (mode, tag) in [
        (ThemeModeId.light, 'light'),
        (ThemeModeId.night, 'night'),
      ]) {
        final name = 'summary_$tag';
        if (!wanted(name)) continue;
        final (key, _) = await listening(size: phone, mode: mode);
        await tap(find.byKey(const ValueKey('tasmee-end')));
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        await save(name, key);
      }

      // ---- before the session -------------------------------------------
      Future<void> before(
        String name, {
        FakeBackend? backend,
        Map<String, Object> prefs = const {'tasmee.firstUseSeen': true},
        ThemeModeId mode = ThemeModeId.light,
        Future<void> Function()? then,
      }) async {
        if (!wanted(name)) return;
        final (key, router, _, _) = await app(
          size: phone,
          backend: backend,
          prefs: prefs,
          mode: mode,
        );
        router.push(
          '/tasmee/session',
          extra: TasmeeSessionRequest(
            range: range,
            words: words,
            mode: TasmeeMode.continuous,
          ),
        );
        await settleLong(10);
        await then?.call();
        await save(name, key);
      }

      await before('first_use_light', prefs: const {});
      await before('ready_light');
      await before(
        'mic_denied_light',
        backend: FakeBackend(micDenied: true),
        then: () => tap(main),
      );
      await before(
        'model_consent_light',
        backend: FakeBackend(installed: false),
      );
      final gate = Completer<void>();
      await before(
        'model_downloading_night',
        mode: ThemeModeId.night,
        backend: FakeBackend(installed: false)..downloadGate = gate,
        then: () => tap(find.byKey(const ValueKey('tasmee-model-download'))),
      );
      gate.complete();

      // ---- the setup sheet ----------------------------------------------
      for (final (mode, tag, kind) in [
        (ThemeModeId.light, 'light', 'آيات'),
        (ThemeModeId.night, 'night', 'ربع حزب'),
      ]) {
        final name = 'setup_$tag';
        if (!wanted(name)) continue;
        final (key, _, _, _) = await app(
          size: phone,
          mode: mode,
          prefs: const {
            'tasmee.firstUseSeen': true,
            'tasmee.last':
                '{"from":[2,1],"to":[2,5],"reached":[2,5],"accuracy":96}',
          },
          home: (context) => Scaffold(
            backgroundColor: context.tokens.colors.bg,
            body: Center(
              child: FilledButton(
                onPressed: () => showTasmeeSetup(context),
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tap(find.text('open'));
        await tap(find.text(kind));
        await save(name, key);
      }

      // ---- elderly, English, laptop -------------------------------------
      if (wanted('elderly')) {
        final (key, _) = await listening(size: phone, elderly: true);
        await save('elderly_light', key);
      }
      if (wanted('english')) {
        final (key, _) = await listening(size: phone, lang: 'en');
        await save('english_light', key);
      }
      if (wanted('laptop')) {
        final (key, _) = await listening(size: laptop);
        await save('laptop_light', key);
      }

      // ---- settings and sources -----------------------------------------
      if (wanted('settings')) {
        final (key, _, _, _) = await app(
          size: phone,
          home: (_) => const TasmeeSettingsScreen(),
        );
        await save('settings_light', key);
      }
      if (wanted('about_sources')) {
        final (key, _, _, _) = await app(
          size: phone,
          home: (_) => const AboutMushafScreen(),
        );
        final title = find.text(
          'نموذج التعرف على الكلام للتسميع (FastConformer العربي)',
        );
        await tester.scrollUntilVisible(title, 300);
        await tap(title);
        await tester.drag(find.byType(ListView), const Offset(0, -260));
        await save('about_sources_light', key);
      }

      // ---- the hifz test in elderly mode (the cover fix) ----------------
      if (wanted('hifz_elderly')) {
        final (key, _, _, _) = await app(
          size: phone,
          elderly: true,
          prefs: const {
            'settings.elderlyMode': true,
            'tasmee.firstUseSeen': true,
          },
          home: (_) => const MushafScreen(
            initialPage: 3,
            hifzUnit: 'page',
            hifzFrom: '2:6',
            hifzTo: '2:16',
          ),
        );
        await settleLong(16);
        await save('hifz_test_elderly_light', key);
      }

      await tester.pumpWidget(const SizedBox());
      tester.view.reset();
    },
    skip: !run,
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
