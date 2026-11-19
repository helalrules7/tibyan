import 'dart:io';

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
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/features/assistant/assistant_screen.dart';
import 'package:tibyan/features/assistant/tajweed_marks_screen.dart';
import 'package:tibyan/features/home/whats_new.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/mushaf_page.dart';

import '../testing/bundled_pages.dart';

/// «المساعد»: the hub of helpers, its tajweed marks, and every way in:
/// the home grid, the reader's menus (focus mode's window too, and in
/// elderly mode), and «المزيد» in the tajweed colour key.
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
    root = Directory.systemTemp.createTempSync('assistant');
    final dir = Directory(p.join(root.path, 'packs', 'pages-hafs-1441-v1'))
      ..createSync(recursive: true);
    final zip = bundledPagesArchive();
    for (final name in ['049.svg.xz', '050.svg.xz', '051.svg.xz']) {
      final entry = zip.findFile(name)!;
      File(p.join(dir.path, entry.name)).writeAsBytesSync(entry.content);
    }
    File(p.join(dir.path, '.installed')).writeAsStringSync('test');
  });
  tearDownAll(() => db.close());

  Future<ProviderContainer> start(
    WidgetTester tester,
    String location, {
    Map<String, Object> prefs = const {},
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
    await tester.binding.setSurfaceSize(const Size(430, 932));
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
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TibyanApp()),
    );
    await tester.pump(const Duration(seconds: 2));
    container.read(appRouterProvider).go(location);
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

  final hub = find.byType(AssistantScreen);
  final marks = find.byType(TajweedMarksScreen);

  testWidgets('the hub\'s first card opens the tajweed marks, and a rule '
      'its places', (tester) async {
    await start(tester, assistantLocation);
    await settle(tester, hub);
    expect(find.text('المساعد'), findsOneWidget);
    // One way to the marks, not two.
    expect(find.text('علامات التجويد'), findsNothing);
    expect(find.text('علامات التجويد والضبط'), findsOneWidget);
    await tester.tap(find.text('علامات التجويد والضبط'));
    await settle(tester, marks);
    expect(marks, findsOneWidget);
    expect(find.text('أحكام التجويد: ألوانها ومواضعها'), findsOneWidget);
    await settle(tester, find.text('الإقلاب'));
    await tester.tap(find.text('الإقلاب'));
    await settle(tester, find.byType(TajweedRuleScreen));
    expect(find.byType(TajweedRuleScreen), findsOneWidget);
  });

  testWidgets('the hub lists the three kinds of help, and a topic opens '
      'its steps', (tester) async {
    final container = await start(tester, assistantLocation);
    await settle(tester, hub);
    await tester.tap(find.byKey(const ValueKey('help-topic.bookmarks')));
    await settle(tester, find.byType(HelpTopicScreen));
    expect(find.text('الفواصل والعلامات'), findsOneWidget);
    expect(find.textContaining('فاصل جديد'), findsOneWidget);
    container.read(appRouterProvider).go(assistantLocation);
    await settle(tester, hub);
    for (final g in [
      'استخدام التطبيق',
      'التجويد والضبط',
      'أسئلة شائعة وحلول',
    ]) {
      await tester.scrollUntilVisible(find.text(g), 200);
      expect(find.text(g), findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('help-topic.faq-model')),
      200,
    );
  });

  testWidgets('«About this mushaf» no longer holds the tajweed card', (
    tester,
  ) async {
    await start(tester, '/mushaf/about');
    await settle(tester);
    expect(find.text('أحكام التجويد: ألوانها ومواضعها'), findsNothing);
  });

  testWidgets('home has no Assistant tile; Settings keeps it', (tester) async {
    await start(tester, '/');
    await settle(tester, find.text('الأقسام'));
    expect(find.text('الأقسام'), findsOneWidget);
    expect(find.text('المساعد'), findsNothing);
  });

  testWidgets('elderly home keeps its three actions, without the Assistant', (
    tester,
  ) async {
    await start(tester, '/', prefs: {'settings.elderlyMode': true});
    await settle(tester);
    expect(find.text('المساعد'), findsNothing);
  });

  for (final elderly in [false, true]) {
    testWidgets('the reader\'s top menu has «الاستماع» in its place'
        '${elderly ? ' (elderly)' : ''}', (tester) async {
      await start(
        tester,
        '/mushaf?page=50',
        prefs: {'settings.elderlyMode': elderly},
      );
      await settle(tester, find.byType(MushafPage));
      await settle(tester);
      final page = tester.getRect(find.byType(MushafPage));
      await tester.tapAt(Offset(page.center.dx, page.top + 30));
      await settle(tester);
      // The test font is wider than the app's: the reader's bottom tools
      // (and in elderly mode the frame's header) overflow here only.
      tester.takeException();
      expect(find.text('المساعد'), findsNothing);
      expect(find.text('الاستماع'), findsOneWidget);
    });
  }

  testWidgets('focus mode\'s «القائمة» has «الاستماع» in its header', (
    tester,
  ) async {
    await start(
      tester,
      '/mushaf?page=50',
      prefs: {'settings.focusMode': true, 'settings.focusTools': 'menu'},
    );
    await settle(tester, find.byType(MushafPage));
    await settle(tester);
    final page = tester.getRect(find.byType(MushafPage));
    await tester.longPressAt(Offset(page.center.dx, page.top + 30));
    await settle(tester);
    final menu = find.byKey(const ValueKey('focus-menu'));
    expect(menu, findsOneWidget);
    expect(
      find.descendant(of: menu, matching: find.text('المساعد')),
      findsNothing,
    );
    expect(
      find.descendant(of: menu, matching: find.text('الاستماع')),
      findsOneWidget,
    );
  });

  testWidgets('focus mode, touch reading off: a tap opens «القائمة»', (
    tester,
  ) async {
    await start(
      tester,
      '/mushaf?page=50',
      prefs: {'settings.focusMode': true, 'settings.touchReading': false},
    );
    await settle(tester, find.byType(MushafPage));
    await settle(tester);
    final page = tester.getRect(find.byType(MushafPage));
    await tester.tapAt(page.center);
    await settle(tester);
    expect(find.byKey(const ValueKey('focus-menu')), findsOneWidget);
  });

  testWidgets('«المزيد» in the colour key opens the tajweed marks', (
    tester,
  ) async {
    await start(tester, '/mushaf?page=50');
    await settle(tester, find.byType(MushafPage));
    await settle(tester);
    await tester.longPress(find.byTooltip('تلوين أحكام التجويد'));
    await settle(tester);
    expect(find.text('مفتاح ألوان التجويد'), findsOneWidget);
    await tester.tap(find.text('المزيد'));
    await settle(tester, marks);
    expect(marks, findsOneWidget);
    expect(find.text('مفتاح ألوان التجويد'), findsNothing);
  });
}
