import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/app.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/db/user_database.dart';
import 'package:tibyan/core/flags/feature_flags.dart';
import 'package:tibyan/core/router/app_router.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/features/audio/player_bar.dart';
import 'package:tibyan/features/audio/recitation.dart';
import 'package:tibyan/features/home/whats_new.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/illuminated_frame.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/mushaf_page.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/ornate_pages.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/reading_bar.dart';

/// Listening to al-Baqarah, playing; [toggle] and [stop] change only the
/// state, and are counted.
class _Listening extends RecitationController {
  int toggles = 0;
  int stops = 0;

  @override
  RecitationState build() => const RecitationState(
    active: true,
    playing: true,
    surah: 2,
    ayah: 40,
    timed: true,
  );

  @override
  Future<void> toggle() async {
    toggles++;
    state = state.copyWith(playing: !state.playing);
  }

  @override
  Future<void> stop() async {
    stops++;
    state = const RecitationState();
  }
}

/// Focus mode: the page alone under a thin bar, at the sizes of the
/// opening pages' test, its tools and its menu, and the player's styles.
void main() {
  late ContentDatabase db;
  late Directory root;
  setUpAll(() {
    db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
    root = Directory.systemTemp.createTempSync('focus');
    final dir = Directory(p.join(root.path, 'packs', 'pages-hafs-1441-v1'))
      ..createSync(recursive: true);
    final zip = ZipDecoder().decodeBytes(
      File('assets/packs/pages-hafs-1441-v1.zip').readAsBytesSync(),
    );
    for (final name in [
      '001.svg.xz',
      '002.svg.xz',
      '049.svg.xz',
      '050.svg.xz',
      '051.svg.xz',
    ]) {
      final entry = zip.findFile(name)!;
      File(p.join(dir.path, entry.name)).writeAsBytesSync(entry.content);
    }
    File(p.join(dir.path, '.installed')).writeAsStringSync('test');
  });
  tearDownAll(() => db.close());

  Future<ProviderContainer> start(
    WidgetTester tester, {
    Size size = const Size(430, 932),
    Map<String, Object> prefs = const {'settings.focusMode': true},
    RecitationController? recitation,
    int page = 50,
  }) async {
    for (final m in ['toggle', 'isEnabled']) {
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.$m',
        (_) async => const StandardMessageCodec().encodeMessage(<Object?>[
          m == 'isEnabled' ? false : null,
        ]),
      );
    }
    SharedPreferences.setMockInitialValues({
      'settings.onboardingDone': true,
      'settings.language': 'ar',
      whatsNewSeenKey: whatsNewId,
      ...prefs,
    });
    final registry = (await tester.runAsync(
      () => ThemeRegistry.load(rootBundle),
    ))!;
    final flags = (await tester.runAsync(() => FeatureFlags.load(rootBundle)))!;
    final shared = await SharedPreferences.getInstance();
    final user = UserDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(user.close));
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: [
        themeRegistryProvider.overrideWithValue(registry),
        featureFlagsProvider.overrideWithValue(flags),
        sharedPreferencesProvider.overrideWithValue(shared),
        contentDatabaseProvider.overrideWithValue(db),
        userDatabaseProvider.overrideWithValue(user),
        packRootProvider.overrideWithValue(root),
        readingPositionProvider.overrideWith((ref) => Stream.value(null)),
        if (recitation != null)
          recitationProvider.overrideWith(() => recitation),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TibyanApp()),
    );
    await tester.pump(const Duration(seconds: 2));
    // The home screen is not under test: its labels may not fit the test
    // font on a small phone.
    tester.takeException();
    container.read(appRouterProvider).go('/mushaf?page=$page');
    return container;
  }

  Future<void> settle(WidgetTester tester, [Finder? until]) async {
    for (var i = 0; i < 40; i++) {
      if (until != null && until.evaluate().isNotEmpty) return;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  final bar = find.byKey(const ValueKey('focus-bar'));
  final menu = find.byKey(const ValueKey('focus-menu'));
  final floating = find.byKey(const ValueKey('floating-player'));
  Finder button(String label) => find.byTooltip(label);

  testWidgets('the bar names the page; nothing is around or below it', (
    tester,
  ) async {
    await start(tester);
    await settle(tester, find.byType(MushafPage));
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(bar, findsOneWidget);
    Finder inBar(Finder f) => find.descendant(of: bar, matching: f);
    expect(inBar(find.text('آل عمران')), findsOneWidget);
    expect(inBar(find.text('٥٠')), findsOneWidget);
    expect(inBar(find.text('الجزء ٣')), findsOneWidget);
    expect(inBar(find.text('¾ الحزب ٥')), findsOneWidget);
    for (final label in ['إنهاء التركيز', 'إظهار الأدوات', 'إظهار القوائم']) {
      expect(inBar(button(label)), findsOneWidget, reason: label);
    }
    // No frame, no reading bar, no page number under the page.
    expect(find.byType(IlluminatedFrame), findsNothing);
    expect(find.byType(PlainFrame), findsNothing);
    expect(find.byType(ReadingBar), findsNothing);
    // Nothing between the page and the screen's bottom edge.
    final page = tester.getRect(find.byType(MushafPage).first);
    expect(page.bottom, closeTo(932 - 4, 0.5));
    expect(page.top, closeTo(tester.getRect(bar).bottom + 4, 0.5));
  });

  const sizes = {
    'iPhone 6.1"': Size(393, 852),
    'iPhone 6.7"': Size(430, 932),
    'iPhone SE': Size(375, 667),
    'Android': Size(412, 915),
    'laptop': Size(1440, 900),
  };
  for (final MapEntry(key: name, value: size) in sizes.entries) {
    for (final fill in PageFill.values) {
      testWidgets('$name, ${fill.name}: the page fills the room', (
        tester,
      ) async {
        final container = await start(
          tester,
          size: size,
          prefs: {'settings.focusMode': true, 'settings.pageFill': fill.name},
        );
        await settle(tester, find.byType(MushafPage));
        await settle(tester);
        expect(tester.takeException(), isNull);
        expect(container.read(settingsProvider).pageFill, fill);
        final pages = find.byType(MushafPage);
        final top = tester.getRect(bar).bottom;
        // The laptop shows a spread: two pages, each half the screen.
        final expected = size.width > size.height ? 2 : 1;
        expect(pages, findsNWidgets(expected));
        for (final e in pages.evaluate()) {
          final r = tester.getRect(find.byWidget(e.widget));
          expect(r.width, closeTo(size.width / expected - 12, 0.5));
          expect(r.top, closeTo(top + 4, 0.5));
          expect(r.bottom, closeTo(size.height - 4, 0.5));
        }
      });
    }
  }

  testWidgets('a spread has one bar, naming both pages', (tester) async {
    await start(tester, size: const Size(1440, 900));
    await settle(tester, find.byType(MushafPage));
    await settle(tester);
    expect(bar, findsOneWidget);
    expect(
      find.descendant(of: bar, matching: find.text('٤٩ – ٥٠')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bar, matching: find.text('البقرة · آل عمران')),
      findsOneWidget,
    );
  });

  for (final page in [1, 2]) {
    testWidgets('opening page $page: its text alone, centred', (tester) async {
      await start(tester, size: const Size(393, 852), page: page);
      await settle(tester, find.byType(MushafPage));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(OpeningPage), findsNothing);
      expect(find.byType(OrnateFrame), findsNothing);
      final r = tester.getRect(find.byType(MushafPage));
      expect(r.width, closeTo(393 - 12, 0.5));
      expect(
        find.descendant(
          of: bar,
          matching: find.text(page == 1 ? 'الفاتحة' : 'البقرة'),
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('the cover stays as it is', (tester) async {
    await start(tester, page: 0);
    await settle(tester, find.byType(CoverPage));
    expect(find.byType(CoverPage), findsOneWidget);
    expect(find.byType(OrnateFrame), findsOneWidget);
  });

  testWidgets('the bar\'s buttons: tools, menus, exit; a tap hides', (
    tester,
  ) async {
    // Wide enough for today's bottom controls in the test font.
    final container = await start(tester, size: const Size(600, 1000));
    await settle(tester, find.byType(MushafPage));
    await settle(tester);

    // A tap on the page with nothing shown does nothing.
    final page = tester.getRect(find.byType(MushafPage).first);
    await tester.tapAt(page.topLeft + const Offset(2, 2));
    await settle(tester);
    expect(find.byIcon(Icons.list_alt), findsNothing);
    expect(find.byType(ReadingBar), findsNothing);

    // The tools: today's reading bar, in its own room under the page (the
    // page closes up above it), with the focus-mode button; a tap hides it.
    await tester.tap(button('إظهار الأدوات'));
    await settle(tester);
    expect(find.byType(ReadingBar), findsOneWidget);
    for (final label in ['القراءة اللمسية', 'إنهاء التركيز']) {
      expect(
        find.descendant(
          of: find.byType(ReadingBar),
          matching: find.bySemanticsLabel(label),
        ),
        findsOneWidget,
        reason: label,
      );
    }
    final closedUp = tester.getRect(find.byType(MushafPage).first);
    expect(closedUp.top, closeTo(page.top, 0.5));
    expect(closedUp.bottom, lessThan(page.bottom - 20));
    expect(
      closedUp.bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(ReadingBar)).top + 0.5),
    );
    await tester.tapAt(page.topLeft + const Offset(2, 2));
    await settle(tester);
    expect(find.byType(ReadingBar), findsNothing);
    expect(
      tester.getRect(find.byType(MushafPage).first).bottom,
      closeTo(page.bottom, 0.5),
    );

    // The menus: as a tap on the frame opens them today.
    await tester.tap(button('إظهار القوائم'));
    await settle(tester);
    expect(find.byIcon(Icons.list_alt), findsOneWidget);
    await tester.tapAt(page.center);
    await settle(tester);
    expect(find.byIcon(Icons.list_alt), findsNothing);

    // Exit: back to the normal page, with its frame and reading bar.
    await tester.tap(button('إنهاء التركيز'));
    await settle(tester);
    expect(container.read(settingsProvider).focusMode, isFalse);
    expect(bar, findsNothing);
    expect(find.byType(ReadingBar), findsOneWidget);

    // The reading bar's own button enters focus mode again.
    await tester.tap(
      find.descendant(
        of: find.byType(ReadingBar),
        matching: find.bySemanticsLabel('وضع التركيز'),
      ),
    );
    await settle(tester);
    expect(container.read(settingsProvider).focusMode, isTrue);
    expect(bar, findsOneWidget);
  });

  testWidgets('the tools left shown are kept: saved, and shown on the next '
      'opening, in focus mode turned off and on again', (tester) async {
    final container = await start(tester, size: const Size(600, 1000));
    await settle(tester, find.byType(MushafPage));
    await settle(tester);
    await tester.tap(button('إظهار الأدوات'));
    await settle(tester);
    expect(container.read(settingsProvider).focusToolsShown, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('settings.focusToolsShown'), isTrue);
    // Out of focus mode and back: still shown.
    await container.read(settingsProvider.notifier).setFocusMode(false);
    await settle(tester);
    await container.read(settingsProvider.notifier).setFocusMode(true);
    await settle(tester);
    expect(find.byKey(const ValueKey('focus-tools')), findsOneWidget);
    // A tap on the page hides them, and that is kept too.
    final page = tester.getRect(find.byType(MushafPage).first);
    await tester.tapAt(page.topLeft + const Offset(2, 2));
    await settle(tester);
    expect(prefs.getBool('settings.focusToolsShown'), isFalse);
  });

  testWidgets('the app opens with the tools as they were left', (tester) async {
    await start(
      tester,
      size: const Size(600, 1000),
      prefs: {'settings.focusMode': true, 'settings.focusToolsShown': true},
    );
    await settle(tester, find.byType(MushafPage));
    await settle(tester);
    expect(find.byKey(const ValueKey('focus-tools')), findsOneWidget);
    expect(find.byType(ReadingBar), findsOneWidget);
  });

  testWidgets('a long press on a verse still opens its services', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await start(tester);
    final verse = find.bySemanticsLabel(RegExp('آل عمران.*٣'));
    await settle(tester, verse);
    await settle(tester);
    await tester.longPressAt(tester.getRect(verse.first).center);
    await settle(tester);
    expect(find.text('خدمات الآيات'), findsOneWidget);
    expect(menu, findsNothing);
    handle.dispose();
  });

  testWidgets('a tap on a verse, or anywhere on the page, closes the '
      'services', (tester) async {
    final handle = tester.ensureSemantics();
    await start(tester, prefs: const {});
    final verse = find.bySemanticsLabel(RegExp('آل عمران.*٣'));
    await settle(tester, verse);
    await settle(tester);
    for (final tapOn in ['verse', 'page']) {
      await tester.longPressAt(tester.getRect(verse.first).center);
      await settle(tester);
      expect(find.text('خدمات الآيات'), findsOneWidget, reason: tapOn);
      if (tapOn == 'verse') {
        // Touch reading is on: before, this shaded the verse instead.
        await tester.tapAt(tester.getRect(verse.first).center);
      } else {
        final page = tester.getRect(find.byType(MushafPage).first);
        await tester.tapAt(page.topLeft + const Offset(2, 2));
      }
      await settle(tester);
      expect(find.text('خدمات الآيات'), findsNothing, reason: tapOn);
    }
    handle.dispose();
  });

  group('«القائمة»', () {
    const prefs = {'settings.focusMode': true, 'settings.focusTools': 'menu'};

    testWidgets('the bar keeps only the exit', (tester) async {
      await start(tester, prefs: prefs);
      await settle(tester, find.byType(MushafPage));
      expect(button('إنهاء التركيز'), findsOneWidget);
      expect(button('إظهار الأدوات'), findsNothing);
      expect(button('إظهار القوائم'), findsNothing);
    });

    testWidgets('a long press on a verse: the window with its services', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final container = await start(tester, prefs: prefs);
      final verse = find.bySemanticsLabel(RegExp('آل عمران.*١'));
      await settle(tester, verse);
      await settle(tester);
      await tester.longPressAt(tester.getRect(verse.first).center);
      await settle(tester);
      expect(menu, findsOneWidget);
      Finder inMenu(Finder f) => find.descendant(of: menu, matching: f);
      // The verse part, for the verse pressed.
      expect(inMenu(find.text('خدمات الآيات')), findsOneWidget);
      expect(inMenu(find.textContaining('الآية ١')), findsOneWidget);
      // Header, body and footer.
      for (final label in ['الفهرس', 'البحث', 'إنهاء التركيز']) {
        expect(inMenu(find.text(label)), findsOneWidget, reason: label);
      }
      for (final label in ['انتقال إلى صفحة', 'الفواصل', 'آية آية']) {
        expect(inMenu(find.text(label)), findsOneWidget, reason: label);
      }
      expect(inMenu(find.bySemanticsLabel('القراءة اللمسية')), findsOneWidget);
      expect(inMenu(find.text('٥٠')), findsOneWidget);
      // The verse services panel under the page stays away.
      expect(
        find.text('خدمات الآيات').evaluate().length,
        1,
        reason: 'only in the window',
      );

      // A mark from the window marks the verse, as the panel does.
      await tester.tap(inMenu(find.text('قراءة')));
      await settle(tester);
      expect(menu, findsNothing);
      final marks = await tester.runAsync(
        () => container.read(userDatabaseProvider).watchBookmarkSets().first,
      );
      expect(marks!.single.surah, 3);
      expect(marks.single.ayah, 1);
      handle.dispose();
    });

    testWidgets('off a verse: no verse part; a tap outside closes it', (
      tester,
    ) async {
      await start(tester, prefs: prefs);
      await settle(tester, find.byType(MushafPage));
      await settle(tester);
      // The surah's header line, at the top of page 50.
      final page = tester.getRect(find.byType(MushafPage));
      await tester.longPressAt(Offset(page.center.dx, page.top + 30));
      await settle(tester);
      expect(menu, findsOneWidget);
      expect(find.text('خدمات الآيات'), findsNothing);
      expect(find.text('أدوات الصفحة'), findsOneWidget);
      // A tap outside the window.
      await tester.tapAt(const Offset(10, 900));
      await settle(tester);
      expect(menu, findsNothing);
    });

    testWidgets('its buttons do what today\'s do', (tester) async {
      final container = await start(tester, prefs: prefs);
      await settle(tester, find.byType(MushafPage));
      await settle(tester);
      final page = tester.getRect(find.byType(MushafPage));
      Future<void> open() async {
        await tester.longPressAt(Offset(page.center.dx, page.top + 30));
        await settle(tester);
      }

      // Go to a page: the same dialog as today's.
      await open();
      await tester.tap(find.text('انتقال إلى صفحة'));
      await settle(tester);
      expect(menu, findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await settle(tester);

      // The reading tools: touch reading off and on again.
      final before = container.read(settingsProvider).touchReading;
      await open();
      await tester.tap(
        find.descendant(
          of: menu,
          matching: find.bySemanticsLabel('القراءة اللمسية'),
        ),
      );
      await settle(tester);
      expect(container.read(settingsProvider).touchReading, !before);

      // The header's exit.
      await open();
      await tester.tap(
        find.descendant(of: menu, matching: find.text('إنهاء التركيز')),
      );
      await settle(tester);
      expect(container.read(settingsProvider).focusMode, isFalse);
    });
  });

  group('«شكل المشغل»', () {
    for (final style in PlayerStyle.values) {
      for (final focus in [false, true]) {
        testWidgets('${style.name}, focus mode ${focus ? 'on' : 'off'}', (
          tester,
        ) async {
          await start(
            tester,
            recitation: _Listening(),
            prefs: {
              'settings.focusMode': focus,
              'settings.playerStyle': style.name,
            },
          );
          await settle(tester, find.byType(MushafPage));
          await settle(tester);
          final shown = switch (style) {
            PlayerStyle.auto => focus ? PlayerStyle.pill : PlayerStyle.normal,
            final s => s,
          };
          expect(
            find.byType(PlayerBar),
            shown == PlayerStyle.normal ? findsOneWidget : findsNothing,
          );
          expect(
            floating,
            shown == PlayerStyle.normal ? findsNothing : findsOneWidget,
          );
          if (shown == PlayerStyle.pill) {
            expect(
              find.descendant(of: floating, matching: button('إيقاف مؤقت')),
              findsOneWidget,
            );
          }
        });
      }
    }

    testWidgets('only while a recitation is active', (tester) async {
      await start(tester, prefs: {'settings.playerStyle': 'pill'});
      await settle(tester, find.byType(MushafPage));
      expect(floating, findsNothing);
      expect(find.byType(PlayerBar), findsNothing);
    });

    testWidgets('the pill: play or pause, settings, and × stops', (
      tester,
    ) async {
      final r = _Listening();
      await start(tester, recitation: r);
      await settle(tester, floating);
      await tester.tap(button('إيقاف مؤقت'));
      await tester.pump();
      expect(r.toggles, 1);
      await tester.tap(button('إعدادات الاستماع'));
      await settle(tester);
      expect(find.byType(PlayerOptions), findsOneWidget);
      Navigator.of(tester.element(find.byType(PlayerOptions))).pop();
      await settle(tester);
      await tester.tap(button('إيقاف الاستماع'));
      await settle(tester);
      expect(r.stops, 1);
      expect(floating, findsNothing);
    });

    testWidgets('the single button: a tap plays or pauses, a long press '
        'opens its menu', (tester) async {
      final r = _Listening();
      await start(
        tester,
        recitation: r,
        prefs: {'settings.playerStyle': 'button'},
      );
      await settle(tester, floating);
      await tester.tap(floating);
      await tester.pump();
      expect(r.toggles, 1);
      await tester.longPress(floating);
      await settle(tester);
      for (final item in [
        'إعدادات الاستماع',
        'المشغل كاملًا',
        'إيقاف الاستماع',
      ]) {
        expect(find.text(item), findsOneWidget, reason: item);
      }
      await tester.tap(find.text('المشغل كاملًا'));
      await settle(tester);
      expect(find.byType(PlayerBar), findsOneWidget);
      // Stop, from the full player: it closes, and so does the button.
      await tester.tap(button('إيقاف الاستماع'));
      await settle(tester);
      expect(r.stops, 1);
      expect(find.byType(PlayerBar), findsNothing);
      expect(floating, findsNothing);
    });

    testWidgets('dragged anywhere, kept on screen, and remembered', (
      tester,
    ) async {
      final container = await start(tester, recitation: _Listening());
      await settle(tester, floating);
      final before = tester.getCenter(floating);
      await tester.drag(floating, const Offset(-60, -300));
      await settle(tester);
      final after = tester.getCenter(floating);
      // Less the touch slop, taken before the drag starts.
      expect(after.dx, closeTo(before.dx - 60, 20));
      expect(after.dy, closeTo(before.dy - 300, 20));
      final saved = container.read(settingsProvider).playerPosition!;
      expect(saved.dx * 430, closeTo(after.dx, 1));
      expect(saved.dy * 932, closeTo(after.dy, 1));
      expect(
        container.read(sharedPreferencesProvider).getDouble('settings.playerY'),
        saved.dy,
      );

      // Far past the edge: it stops inside the screen.
      await tester.drag(floating, const Offset(2000, 2000));
      await settle(tester);
      final kept = tester.getRect(floating);
      expect(kept.right, lessThanOrEqualTo(430));
      expect(kept.bottom, lessThanOrEqualTo(932));
      expect(kept.left, greaterThanOrEqualTo(0));
    });

    testWidgets('a smaller screen keeps it inside', (tester) async {
      await start(
        tester,
        size: const Size(375, 667),
        recitation: _Listening(),
        prefs: {
          'settings.focusMode': true,
          'settings.playerX': 1.0,
          'settings.playerY': 1.0,
        },
      );
      await settle(tester, floating);
      final r = tester.getRect(floating);
      expect(r.right, lessThanOrEqualTo(375));
      expect(r.bottom, lessThanOrEqualTo(667));
    });
  });
}
