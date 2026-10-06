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
import 'package:tibyan/l10n/app_localizations.dart';

/// «آية آية»: one verse a screen, sideways, as large as it fits.
void main() {
  test('a short verse is set larger than a long one', () {
    const box = Size(700, 300);
    final short = fitFontSize('مُدۡهَآمَّتَانِ', box);
    final long = fitFontSize(
      List.filled(40, 'وَٱلَّذِينَ ءَامَنُواْ').join(' '),
      box,
    );
    expect(short, greaterThan(long));
    expect(long, 28); // the smallest: the verse scrolls
    expect(short, lessThanOrEqualTo(120));
  });

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

  Future<void> pumpScreen(
    WidgetTester tester,
    List<Object?> orientations, {
    Map<String, Object> prefs = const {},
  }) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          orientations.add(call.arguments);
        }
        return null;
      },
    );
    final registry = (await tester.runAsync(
      () => ThemeRegistry.load(rootBundle),
    ))!;
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    final user = UserDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(user.close));
    await tester.binding.setSurfaceSize(const Size(900, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentDatabaseProvider.overrideWithValue(db),
          userDatabaseProvider.overrideWithValue(user),
          themeRegistryProvider.overrideWithValue(registry),
          sharedPreferencesProvider.overrideWithValue(sp),
          packRootProvider.overrideWithValue(
            Directory.systemTemp.createTempSync('one_verse'),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTheme(
            style: registry.byId(registry.defaultStyleId),
            mode: ThemeModeId.light,
            uiFont: UiFont.changa,
          ),
          home: const OneVerseScreen(surah: 1, ayah: 2),
        ),
      ),
    );
  }

  testWidgets('turns the phone sideways and steps verse by verse', (
    tester,
  ) async {
    final orientations = <Object?>[];
    await pumpScreen(tester, orientations);
    Future<void> settle() async {
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await settle();
    expect(orientations.first, [
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);
    expect(find.text('سورة الفاتحة | ٢'), findsOneWidget);

    await tester.tap(find.byTooltip('الآية التالية'));
    await settle();
    expect(find.text('سورة الفاتحة | ٣'), findsOneWidget);
  });

  testWidgets('auto-turn moves on by itself after the chosen seconds', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      [],
      prefs: const {'settings.oneVerseAutoSeconds': 10},
    );
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('سورة الفاتحة | ٢'), findsOneWidget);
    await tester.pump(const Duration(seconds: 11));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('سورة الفاتحة | ٣'), findsOneWidget);
  });
}
