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
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/features/assistant/assistant_screen.dart';
import 'package:tibyan/features/assistant/tajweed_marks_screen.dart';
import 'package:tibyan/features/home/whats_new.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/mushaf_page.dart';

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
    final zip = ZipDecoder().decodeBytes(
      File('assets/packs/pages-hafs-1441-v1.zip').readAsBytesSync(),
    );
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
    await tester.tap(find.text('علامات التجويد'));
    await settle(tester, marks);
    expect(marks, findsOneWidget);
    expect(find.text('أحكام التجويد: ألوانها ومواضعها'), findsOneWidget);
    await settle(tester, find.text('الإقلاب'));
    await tester.tap(find.text('الإقلاب'));
    await settle(tester, find.byType(TajweedRuleScreen));
    expect(find.byType(TajweedRuleScreen), findsOneWidget);
  });

  testWidgets('«About this mushaf» no longer holds the tajweed card', (
    tester,
  ) async {
    await start(tester, '/mushaf/about');
    await settle(tester);
    expect(find.text('أحكام التجويد: ألوانها ومواضعها'), findsNothing);
  });

  testWidgets('home: the seventh section, as wide as the grid, opens it', (
    tester,
  ) async {
    await start(tester, '/');
    await settle(tester, find.text('المساعد'));
    // The six tiles keep their 3×2 grid; the Assistant spans its width.
    final grid = tester.getRect(find.byType(GridView));
    final tile = tester.getRect(
      find.ancestor(of: find.text('المساعد'), matching: find.byType(Card)),
    );
    expect(tile.width, closeTo(grid.width, 12));
    expect(tile.top, greaterThan(grid.bottom));
    await tester.tap(find.text('المساعد'));
    await settle(tester, hub);
    expect(hub, findsOneWidget);
  });

  testWidgets('elderly home keeps its three actions, without the Assistant', (
    tester,
  ) async {
    await start(tester, '/', prefs: {'settings.elderlyMode': true});
    await settle(tester);
    expect(find.text('المساعد'), findsNothing);
  });

  for (final elderly in [false, true]) {
    testWidgets(
      'the reader\'s top menu opens it${elderly ? ' (elderly)' : ''}',
      (tester) async {
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
        await tester.tap(find.text('المساعد'));
        await settle(tester, hub);
        expect(hub, findsOneWidget);
      },
    );
  }

  testWidgets('focus mode\'s «القائمة» opens it from its header', (
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
    await tester.tap(find.descendant(of: menu, matching: find.text('المساعد')));
    await settle(tester, hub);
    expect(menu, findsNothing);
    expect(hub, findsOneWidget);
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
