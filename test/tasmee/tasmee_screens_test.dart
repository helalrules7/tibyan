import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/mushaf/presentation/about_mushaf_screen.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/mushaf_page.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/page_interaction.dart';
import 'package:tibyan/features/tasmee/data/tasmee_backend.dart';
import 'package:tibyan/features/tasmee/data/tasmee_settings.dart';
import 'package:tibyan/features/tasmee/data/tasmee_words_repository.dart';
import 'package:tibyan/features/tasmee/domain/alignment_engine.dart';
import 'package:tibyan/features/tasmee/domain/recitation_range.dart';
import 'package:tibyan/features/tasmee/domain/tasmee_session_request.dart';
import 'package:tibyan/features/tasmee/presentation/tasmee_page.dart';
import 'package:tibyan/features/tasmee/presentation/tasmee_session_screen.dart';
import 'package:tibyan/features/tasmee/presentation/tasmee_settings_screen.dart';
import 'package:tibyan/features/tasmee/presentation/tasmee_setup_screen.dart';
import 'package:tibyan/l10n/app_localizations.dart';

import 'tasmee_fakes.dart';
import 'tasmee_test_env.dart';

void main() {
  late TasmeeTestData data;
  setUpAll(() => data = TasmeeTestData.open(pages: [604]));
  tearDownAll(() => data.close());

  const ikhlas = SurahRange(112);
  const seen = {'tasmee.firstUseSeen': true};

  Future<TasmeeSessionRequest> request(
    WidgetTester tester, {
    TasmeeMode mode = TasmeeMode.continuous,
    ErrorBehavior? onError,
  }) async {
    final words = (await tester.runAsync(
      () => TasmeeWordsRepository(data.db).expectedWords(ikhlas),
    ))!;
    return TasmeeSessionRequest(
      range: ikhlas,
      words: words,
      mode: mode,
      onError: onError,
    );
  }

  /// The app's router around [start], with the routes the tasmee uses.
  Future<(ProviderContainer, FakeBackend, GoRouter)> pumpScreen(
    WidgetTester tester,
    Widget Function(BuildContext context) start, {
    Map<String, Object> prefs = seen,
    FakeBackend? backend,
    Size size = const Size(400, 860),
    String lang = 'ar',
    bool elderly = false,
    ThemeModeId mode = ThemeModeId.light,
  }) async {
    final fake = backend ?? FakeBackend();
    final container = await tasmeeContainer(
      tester,
      data,
      prefs: prefs,
      overrides: [tasmeeBackendProvider.overrideWithValue(fake)],
    );
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Builder(builder: start),
          routes: [
            GoRoute(
              path: 'touch',
              builder: (_, _) => const Scaffold(body: Text('touch test')),
            ),
          ],
        ),
        GoRoute(
          path: '/tasmee/session',
          builder: (_, state) => TasmeeSessionScreen(
            request: state.extra! as TasmeeSessionRequest,
          ),
        ),
        GoRoute(
          path: '/mushaf',
          builder: (_, _) => const Scaffold(body: Text('mushaf')),
          routes: [
            GoRoute(
              path: 'about',
              builder: (_, _) => const AboutMushafScreen(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
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
        ),
      ),
    );
    await settle(tester, rounds: 6);
    return (container, fake, router);
  }

  Future<(ProviderContainer, FakeBackend, GoRouter)> pumpSession(
    WidgetTester tester, {
    TasmeeMode mode = TasmeeMode.continuous,
    ErrorBehavior? onError,
    Map<String, Object> prefs = seen,
    FakeBackend? backend,
    Size size = const Size(400, 860),
    String lang = 'ar',
    bool elderly = false,
  }) async {
    final r = await request(tester, mode: mode, onError: onError);
    final out = await pumpScreen(
      tester,
      (_) => const Scaffold(body: Text('home')),
      prefs: prefs,
      backend: backend,
      size: size,
      lang: lang,
      elderly: elderly,
    );
    out.$3.push('/tasmee/session', extra: r);
    await settle(tester, rounds: 8);
    return out;
  }

  Future<void> tapMain(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('tasmee-main')));
    await settle(tester, rounds: 4);
  }

  Future<void> say(WidgetTester tester, FakeBackend b, String text) async {
    b.recognizer0.say(text);
    await settle(tester, rounds: 4);
  }

  /// Lets the session settle its last words and show the summary.
  Future<void> finish(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await settle(tester, rounds: 4);
  }

  group('setup sheet', () {
    testWidgets('eight kinds, a live summary, defaults from the settings', (
      tester,
    ) async {
      TasmeeSessionRequest? started;
      await pumpScreen(
        tester,
        (_) => Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: TasmeeSetupSheet(
              onStart: (r) => started = r,
              onClose: () {},
            ),
          ),
        ),
        prefs: {
          ...seen,
          'tasmee.mode': 'verseByVerse',
          'tasmee.onError': 'stopToCorrect',
        },
      );
      for (final kind in [
        'سورة',
        'جزء',
        'حزب',
        'نصف حزب',
        'ربع حزب',
        '٣ أرباع حزب',
        'صفحات',
        'آيات',
      ]) {
        expect(find.text(kind), findsOneWidget, reason: kind);
      }
      // Al-Fatiha by default: 7 verses, 29 words, page 1.
      expect(find.textContaining('٧ آية · ٢٩ كلمة'), findsOneWidget);

      await tester.tap(find.text('جزء'));
      await settle(tester);
      expect(find.text('الجزء'), findsWidgets);
      expect(find.textContaining('آية ·'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('tasmee-start')));
      await tester.tap(find.byKey(const ValueKey('tasmee-start')));
      await tester.pump();
      expect(started, isNotNull);
      expect(started!.range, const JuzRange(1));
      expect(started!.mode, TasmeeMode.verseByVerse);
      expect(started!.onError, ErrorBehavior.stopToCorrect);
    });

    testWidgets('the last session can be continued from the next verse', (
      tester,
    ) async {
      TasmeeSessionRequest? started;
      await pumpScreen(
        tester,
        (_) => Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: TasmeeSetupSheet(
              onStart: (r) => started = r,
              onClose: () {},
            ),
          ),
        ),
        prefs: {
          ...seen,
          'tasmee.last':
              '{"from":[2,6],"to":[2,16],"reached":[2,9],"accuracy":96}',
        },
      );
      expect(find.textContaining('آخر تسميع: البقرة ٦–١٦ · ٩٦٪'), findsOne);
      await tester.tap(find.byKey(const ValueKey('tasmee-resume')));
      await settle(tester);
      expect(
        started!.range,
        const VerseRange(fromSurah: 2, fromAyah: 10, toSurah: 2, toAyah: 16),
      );
    });
  });

  group('session', () {
    testWidgets('the first-use notice says it checks memorisation only', (
      tester,
    ) async {
      final (container, _, _) = await pumpSession(tester, prefs: const {});
      expect(find.text('التسميع يختبر حفظك، لا تجويدك'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tasmee-notice-ok')));
      await settle(tester);
      expect(container.read(tasmeeSettingsProvider).firstUseSeen, isTrue);
      expect(find.text('التسميع يختبر حفظك، لا تجويدك'), findsNothing);
    });

    testWidgets('the page and the panel: the panel never covers the page', (
      tester,
    ) async {
      final (_, b, _) = await pumpSession(tester);
      final page = tester.getRect(find.byKey(const ValueKey('tasmee-page')));
      final panel = tester.getRect(find.byKey(const ValueKey('tasmee-panel')));
      expect(panel.top, greaterThanOrEqualTo(page.bottom - 0.5));
      expect(find.byType(MushafPage), findsOneWidget);
      expect(tester.widget<TasmeePage>(find.byType(TasmeePage)).page, 604);

      await tapMain(tester);
      expect(b.microphone0.running, isTrue);
      expect(find.text('أستمع إليك'), findsOneWidget);
      expect(find.text('إيقاف مؤقت'), findsOneWidget);
      final panel2 = tester.getRect(find.byKey(const ValueKey('tasmee-panel')));
      expect(panel2.top, greaterThanOrEqualTo(page.bottom - 0.5));
    });

    testWidgets('words shown as recited; pause, resume, end, summary', (
      tester,
    ) async {
      final (container, b, router) = await pumpSession(tester);
      await tapMain(tester);
      await say(tester, b, 'قل هو الله أحد');
      final page = tester.widget<TasmeePage>(find.byType(TasmeePage));
      expect(page.state.statusOf(0), WordStatus.correct);
      expect(page.state.statusOf(4), WordStatus.hidden);
      // Verse 1 is done: its result shows in the panel.
      expect(find.textContaining('الآية ١ · ١٠٠٪'), findsOneWidget);

      await tapMain(tester); // pause
      expect(b.microphone0.running, isFalse);
      expect(find.text('متابعة'), findsOneWidget);
      await tapMain(tester); // resume
      expect(b.microphone0.running, isTrue);

      await say(tester, b, 'الله الصمد لم يلد');
      await tester.tap(find.byKey(const ValueKey('tasmee-end')));
      await finish(tester);
      expect(find.text('انتهى التسميع'), findsWidgets);
      expect(find.text('آيات تحتاج مراجعة'), findsOneWidget);
      expect(find.byKey(const ValueKey('tasmee-summary-again')), findsOne);
      expect(b.recognizer0.disposed, isTrue);
      final last = container.read(tasmeeSettingsProvider).last!;
      expect((last.reachedSurah, last.reachedAyah), (112, 3));

      await tester.tap(find.byKey(const ValueKey('tasmee-summary-done')));
      await settle(tester);
      expect(router.state.uri.path, '/');
    });

    testWidgets('stop to correct: the wrong word waits, or is skipped', (
      tester,
    ) async {
      final (_, b, _) = await pumpSession(
        tester,
        onError: ErrorBehavior.stopToCorrect,
      );
      await tapMain(tester);
      await say(tester, b, 'قل هو الرحمن أحد');
      expect(find.text('أعد قراءة الكلمة المعلّمة بالأحمر'), findsOneWidget);
      var page = tester.widget<TasmeePage>(find.byType(TasmeePage));
      expect(page.state.waitingAt, 2);
      await tester.tap(find.text('تجاوزها'));
      await settle(tester);
      expect(find.text('أعد قراءة الكلمة المعلّمة بالأحمر'), findsNothing);
      page = tester.widget<TasmeePage>(find.byType(TasmeePage));
      expect(page.state.waitingAt, isNull);
      expect(page.state.statusOf(2), WordStatus.wrong);
    });

    testWidgets('the hint shows the next word, counted apart', (tester) async {
      final (_, b, _) = await pumpSession(tester);
      await tapMain(tester);
      await say(tester, b, 'قل هو');
      await tester.tap(find.byKey(const ValueKey('tasmee-hint')));
      await settle(tester);
      final page = tester.widget<TasmeePage>(find.byType(TasmeePage));
      expect(page.state.hinted, {2});
    });

    testWidgets('verse by verse: one verse, its result, then the next', (
      tester,
    ) async {
      final (_, b, _) = await pumpSession(
        tester,
        mode: TasmeeMode.verseByVerse,
        prefs: {...seen, 'tasmee.toastSeconds': 10},
      );
      expect(find.text('الآية ١ من ٤: اضغط وسمّعها'), findsOneWidget);
      await tapMain(tester);
      expect(find.text('الآية ١: أستمع إليك'), findsOneWidget);
      await say(tester, b, 'قل هو الله');
      await tester.tap(find.byKey(const ValueKey('tasmee-main'))); // done
      await finish(tester);
      // The verse's last word was not read: skipped.
      final page = tester.widget<TasmeePage>(find.byType(TasmeePage));
      expect(page.state.statusOf(3), WordStatus.skipped);
      expect(find.textContaining('الآية ١ ·'), findsOneWidget);
      expect(find.text('سمّع الآية'), findsOneWidget);
    });

    testWidgets('microphone refused: settings, or the test by touch', (
      tester,
    ) async {
      final (_, b, _) = await pumpSession(
        tester,
        backend: FakeBackend(micDenied: true),
      );
      await tapMain(tester);
      expect(find.byKey(const ValueKey('tasmee-mic-denied')), findsOneWidget);
      expect(find.text('الميكروفون غير مسموح'), findsOneWidget);
      await tester.tap(find.text('افتح إعدادات الجهاز'));
      await settle(tester);
      expect(b.settingsOpened, 1);
      expect(find.text('اختبر حفظك باللمس بدلا من ذلك'), findsOneWidget);
    });

    testWidgets('model consent: size and offline, no credit on the sheet', (
      tester,
    ) async {
      final backend = FakeBackend(installed: false);
      await pumpSession(tester, backend: backend);
      expect(find.text('نموذج التسميع'), findsOneWidget);
      expect(find.textContaining('١٢٦ م.ب'), findsWidgets);
      expect(find.text('يعمل بعدها بلا إنترنت'), findsOneWidget);
      expect(find.textContaining('Wi‑Fi'), findsOneWidget);
      expect(find.textContaining('NVIDIA'), findsNothing);
      expect(find.textContaining('CC BY'), findsNothing);
      expect(find.textContaining('عن المصحف'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('tasmee-model-download')));
      await settle(tester);
      expect(backend.installed, isTrue);
      expect(find.text('نموذج التسميع'), findsNothing);
      expect(find.text('اضغط للبدء واقرأ من حفظك'), findsOneWidget);
    });

    testWidgets('elderly mode: larger controls', (tester) async {
      await pumpSession(tester, elderly: true, size: const Size(480, 900));
      final main = tester.getSize(
        find.descendant(
          of: find.byKey(const ValueKey('tasmee-main')),
          matching: find.byType(Material),
        ),
      );
      expect(main.width, 72);
    });

    testWidgets('English: left to right, English labels', (tester) async {
      await pumpSession(tester, lang: 'en');
      expect(find.text('Tasmee · Al-Ikhlaas'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      final dir = Directionality.of(
        tester.element(find.byKey(const ValueKey('tasmee-panel'))),
      );
      expect(dir, TextDirection.ltr);
    });

    testWidgets('laptop: the panel beside the page', (tester) async {
      await pumpSession(tester, size: const Size(1440, 900));
      final page = tester.getRect(find.byKey(const ValueKey('tasmee-page')));
      final panel = tester.getRect(find.byKey(const ValueKey('tasmee-panel')));
      // Side by side (the page first, on the right in Arabic).
      expect(panel.right, lessThanOrEqualTo(page.left));
      expect(find.text('الآيات'), findsOneWidget);
    });
  });

  testWidgets('About › Sources credits the recognition model', (tester) async {
    await pumpScreen(tester, (_) => const AboutMushafScreen());
    final title = find.text(
      'نموذج التعرف على الكلام للتسميع (FastConformer العربي)',
    );
    await tester.scrollUntilVisible(title, 300);
    await tester.tap(title);
    await settle(tester);
    expect(find.textContaining('CC BY 4.0'), findsWidgets);
    expect(
      find.text(
        'https://huggingface.co/nvidia/stt_ar_fastconformer_hybrid_large_pcd_v1.0',
      ),
      findsOneWidget,
    );
  });

  testWidgets('settings: defaults, model and history', (tester) async {
    final (container, b, _) = await pumpScreen(
      tester,
      (_) => const TasmeeSettingsScreen(),
      prefs: {
        ...seen,
        'tasmee.last':
            '{"from":[112,1],"to":[112,4],"reached":[112,4],"accuracy":100}',
      },
    );
    await tester.tap(find.text('آية بآية'));
    await tester.pump();
    expect(
      container.read(tasmeeSettingsProvider).mode,
      TasmeeMode.verseByVerse,
    );
    await tester.tap(find.text('توقّف للتصحيح'));
    await tester.pump();
    expect(
      container.read(tasmeeSettingsProvider).onError,
      ErrorBehavior.stopToCorrect,
    );
    await tester.scrollUntilVisible(
      find.textContaining('المساحة المستخدمة'),
      200,
    );
    expect(find.textContaining('المساحة المستخدمة: ١٢٦ م.ب'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('حذف النموذج'), 200);
    await tester.ensureVisible(find.text('حذف النموذج'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف النموذج'));
    await settle(tester);
    await tester.tap(find.text('تأكيد'));
    await settle(tester);
    expect(b.deleted, 1);

    await tester.scrollUntilVisible(find.text('مسح سجل التسميع'), 200);
    await tester.ensureVisible(find.text('مسح سجل التسميع'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مسح سجل التسميع'));
    await settle(tester);
    await tester.tap(find.text('تأكيد'));
    await settle(tester);
    expect(container.read(tasmeeSettingsProvider).last, isNull);
  });

  testWidgets('elderly theme: the page lies on the background', (tester) async {
    final (container, _, _) = await pumpSession(
      tester,
      elderly: true,
      size: const Size(480, 900),
    );
    final t = tasmeeTheme(
      container,
      elderly: true,
    ).extension<TibyanTokens>()!.colors;
    expect(t.bg, isNot(t.paper));
    expect(PageGround.of(tester.element(find.byType(MushafPage))), t.bg);
  });
}
