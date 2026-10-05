import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/flags/feature_flags.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/books/books_providers.dart';
import 'package:tibyan/features/books/data/book_pack.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/tafsir/tafsir_screen.dart';
import 'package:tibyan/l10n/app_localizations.dart';

import '../books/fake_pack.dart';

/// Book tafsirs from reviewed packs beside the bundled ones, on the real
/// bundled database.
void main() {
  late ContentDatabase db;
  late BookPack pack;

  setUpAll(() {
    db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
  });
  tearDownAll(() => db.close());
  setUp(() => pack = BookPack(fakeBooksPackDb()));
  tearDown(() => pack.close());

  Future<void> settle(WidgetTester tester) async {
    // The queries run on the database's own isolate, off the test clock.
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
  }

  Future<void> pump(
    WidgetTester tester, {
    List<BookPack>? packs,
    Map<String, bool> flags = const {},
    int ayah = 1,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    final registry = (await tester.runAsync(
      () => ThemeRegistry.load(rootBundle),
    ))!;
    await tester.binding.setSurfaceSize(const Size(420, 4000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentDatabaseProvider.overrideWithValue(db),
          themeRegistryProvider.overrideWithValue(registry),
          sharedPreferencesProvider.overrideWithValue(prefs!),
          featureFlagsProvider.overrideWithValue(FeatureFlags(flags)),
          installedBookPacksProvider.overrideWithValue(packs ?? [pack]),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTheme(
            style: registry.byId(registry.defaultStyleId),
            mode: ThemeModeId.light,
            uiFont: UiFont.plex,
          ),
          home: TafsirScreen(surah: 2, ayah: ayah),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('each installed book tafsir is one more choice', (tester) async {
    await pump(tester);
    expect(find.text('تفسير تجريبي أول'), findsOneWidget);
    expect(find.text('تفسير تجريبي ثان'), findsOneWidget);
    expect(find.text(fakeTafsirText, findRichText: true), findsOneWidget);
    expect(find.text(fakeOtherTafsirText, findRichText: true), findsOneWidget);
    expect(find.text('الآيات ١–٥'), findsOneWidget);

    // The settings sheet lists them; turning one off hides it.
    await tester.tap(find.byIcon(Icons.text_fields));
    await tester.pumpAndSettle();
    final sw = find.widgetWithText(SwitchListTile, 'تفسير تجريبي ثان');
    expect(sw, findsOneWidget);
    await tester.ensureVisible(sw);
    await tester.tap(sw);
    await tester.pumpAndSettle();
    Navigator.of(tester.element(sw)).pop();
    await tester.pumpAndSettle();
    expect(find.text(fakeOtherTafsirText, findRichText: true), findsNothing);
    expect(find.text(fakeTafsirText, findRichText: true), findsOneWidget);
  });

  testWidgets('none without a reviewed pack', (tester) async {
    await pump(tester, packs: []);
    expect(find.text('تفسير تجريبي أول'), findsNothing);
  });

  testWidgets('munasabat under the tafsirs only when the flag is on', (
    tester,
  ) async {
    await pump(tester, ayah: 2);
    expect(find.text('المناسبات'), findsNothing);
    await pump(tester, ayah: 2, flags: {Feature.munasabat.key: true});
    expect(find.text('المناسبات'), findsOneWidget);
    expect(find.text(fakeMunasabaText, findRichText: true), findsOneWidget);
  });
}
