import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/db/user_database.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/reading/one_verse_screen.dart';
import 'package:tibyan/features/sajdah/sajdah_card.dart';
import 'package:tibyan/l10n/app_localizations.dart';

/// «آية آية» and the sajdah card: moving to the verse after a verse of
/// prostration (al-Alaq 19, then al-Qadr 1) shows it, and the auto-turn
/// waits for it.
void main() {
  late ContentDatabase db;
  setUpAll(() {
    db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
  });
  tearDownAll(() => db.close());

  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required int ayah,
    bool timer = true,
    int auto = 0,
  }) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    final registry = (await tester.runAsync(
      () => ThemeRegistry.load(rootBundle),
    ))!;
    SharedPreferences.setMockInitialValues({
      'settings.sajdahTimer': timer,
      'settings.sajdahSeconds': 15,
      'settings.oneVerseAutoSeconds': auto,
    });
    final sp = await SharedPreferences.getInstance();
    final user = UserDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(user.close));
    await tester.binding.setSurfaceSize(const Size(900, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = ProviderContainer(
      overrides: [
        contentDatabaseProvider.overrideWithValue(db),
        userDatabaseProvider.overrideWithValue(user),
        themeRegistryProvider.overrideWithValue(registry),
        sharedPreferencesProvider.overrideWithValue(sp),
        packRootProvider.overrideWithValue(
          Directory.systemTemp.createTempSync('sajdah_one_verse'),
        ),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTheme(
            style: registry.byId(registry.defaultStyleId),
            mode: ThemeModeId.light,
            uiFont: UiFont.changa,
            elderly: true,
          ),
          home: OneVerseScreen(surah: 96, ayah: ayah),
        ),
      ),
    );
    return c;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  final card = find.text('اضغط للاستكمال');
  Finder shown(String text) => find.text(text);

  testWidgets(
    'moving to the verse after a verse of prostration shows the card',
    (tester) async {
      final c = await pumpScreen(tester, ayah: 18);
      await settle(tester);
      expect(shown('سورة العلق | ١٨'), findsOneWidget);
      // On to al-Alaq 19, the verse of prostration itself: no card.
      await tester.tap(find.byTooltip('الآية التالية'));
      await settle(tester);
      expect(shown('سورة العلق | ١٩'), findsOneWidget);
      expect(c.read(sajdahCardProvider), isNull);
      // On to al-Qadr 1: the card, for al-Alaq 19.
      await tester.tap(find.byTooltip('الآية التالية'));
      await settle(tester);
      expect(shown('سورة القدر | ١'), findsOneWidget);
      expect(c.read(sajdahCardProvider)?.verse, (surah: 96, ayah: 19));
      expect(card, findsOneWidget);
      // A tap closes it.
      await tester.tap(card);
      await tester.pump();
      expect(c.read(sajdahCardProvider), isNull);
      await settle(tester);
      expect(card, findsNothing);
    },
  );

  testWidgets('the auto-turn waits for the card', (tester) async {
    final c = await pumpScreen(tester, ayah: 19, auto: 10);
    await settle(tester);
    expect(shown('سورة العلق | ١٩'), findsOneWidget);
    // The auto-turn goes on to al-Qadr 1: the card shows.
    await tester.pump(const Duration(seconds: 10));
    await settle(tester);
    expect(shown('سورة القدر | ١'), findsOneWidget);
    expect(c.read(sajdahCardProvider), isNotNull);
    // Ten more seconds: the card (15 s) is still up, and the verse stays.
    await tester.pump(const Duration(seconds: 10));
    await settle(tester);
    expect(shown('سورة القدر | ١'), findsOneWidget);
    expect(c.read(sajdahCardProvider), isNotNull);
    // The card closes; the auto-turn starts again from there.
    await tester.pump(const Duration(seconds: 4));
    await settle(tester);
    expect(c.read(sajdahCardProvider), isNull);
    await tester.pump(const Duration(seconds: 5));
    await settle(tester);
    expect(shown('سورة القدر | ١'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await settle(tester);
    expect(shown('سورة القدر | ٢'), findsOneWidget);
    // Stop the auto-turn before the test ends.
    await tester.tap(find.bySemanticsLabel(RegExp('١٠')).first);
    await settle(tester);
  });

  testWidgets('the timer off: moving on shows nothing', (tester) async {
    final c = await pumpScreen(tester, ayah: 19, timer: false);
    await settle(tester);
    await tester.tap(find.byTooltip('الآية التالية'));
    await settle(tester);
    expect(shown('سورة القدر | ١'), findsOneWidget);
    expect(c.read(sajdahCardProvider), isNull);
    expect(card, findsNothing);
  });
}
