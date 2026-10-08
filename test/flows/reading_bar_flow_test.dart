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
import 'package:tibyan/features/home/whats_new.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/reading_bar.dart';

/// The reading bar under the pages: one for the screen, outside the pager,
/// and it takes the page turned to once the turn has come to rest.
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
    // The new Madina edition's last pages, as an installed pack.
    root = Directory.systemTemp.createTempSync('flows');
    final dir = Directory(p.join(root.path, 'packs', 'pages-hafs-1441-v1'))
      ..createSync(recursive: true);
    final zip = ZipDecoder().decodeBytes(
      File('assets/packs/pages-hafs-1441-v1.zip').readAsBytesSync(),
    );
    for (final name in ['602.svg.xz', '603.svg.xz', '604.svg.xz']) {
      final entry = zip.findFile(name)!;
      File(p.join(dir.path, entry.name)).writeAsBytesSync(entry.content);
    }
    File(p.join(dir.path, '.installed')).writeAsStringSync('test');
  });
  tearDownAll(() => db.close());

  Future<(ProviderContainer, UserDatabase)> start(WidgetTester tester) async {
    // The screen stays on while reading: answer the wakelock plugin.
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
    });
    final registry = (await tester.runAsync(
      () => ThemeRegistry.load(rootBundle),
    ))!;
    final flags = (await tester.runAsync(() => FeatureFlags.load(rootBundle)))!;
    final prefs = await SharedPreferences.getInstance();
    final user = UserDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(user.close));
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: [
        themeRegistryProvider.overrideWithValue(registry),
        featureFlagsProvider.overrideWithValue(flags),
        sharedPreferencesProvider.overrideWithValue(prefs),
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
    return (container, user);
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

  ReadingBar bar(WidgetTester tester) =>
      tester.widget<ReadingBar>(find.byType(ReadingBar));

  testWidgets('one bar, outside the pages; it follows a turn once it settles', (
    tester,
  ) async {
    final (container, _) = await start(tester);
    container.read(appRouterProvider).go('/mushaf?page=603');
    await settle(tester, find.byType(PageView));
    await settle(tester);

    // A single bar for the screen, not one per page, and not inside the
    // pager: it does not slide with the page.
    expect(find.byType(ReadingBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PageView),
        matching: find.byType(ReadingBar),
      ),
      findsNothing,
    );
    expect(bar(tester).page, 603);
    // Page 603's catchword: the first word of page 604.
    expect(bar(tester).catchword, isNotNull);
    // The reading tools are in it (not elderly mode).
    expect(
      find.descendant(
        of: find.byType(ReadingBar),
        matching: find.bySemanticsLabel('القراءة اللمسية'),
      ),
      findsOneWidget,
    );
    final top = tester.getTopLeft(find.byType(ReadingBar));

    // Turn to the next page (on the left: the finger moves right), and
    // hold it past the middle: the pager has changed page, the bar not.
    final pager = tester.getRect(find.byType(PageView));
    double index() =>
        tester.widget<PageView>(find.byType(PageView)).controller!.page!;
    final before = index().round();
    final gesture = await tester.startGesture(pager.center);
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(Offset(pager.width * 0.11, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump();
    expect(index().round(), isNot(before));
    expect(bar(tester).page, 603);
    expect(tester.getTopLeft(find.byType(ReadingBar)), top);

    // Let go: once the page has settled, the bar shows its strip.
    await gesture.up();
    await settle(tester);
    expect(bar(tester).page, 604);
    // The last page has no next page's word.
    expect(bar(tester).catchword, isNull);
    expect(find.byType(ReadingBar), findsOneWidget);
    expect(tester.getTopLeft(find.byType(ReadingBar)), top);
  });
}
