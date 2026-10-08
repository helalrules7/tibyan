import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
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
import 'package:tibyan/features/reading/continuous_screen.dart';
import 'package:tibyan/l10n/app_localizations.dart';

/// The continuous view (docs/features/translation_under_ayah.md): verses
/// one after another, with the reader's choice under each.
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
    root = Directory.systemTemp.createTempSync('continuous');
  });
  tearDownAll(() => db.close());

  Future<void> settle(WidgetTester tester, Finder until) async {
    for (var i = 0; i < 30 && until.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
  }

  Future<void> open(
    WidgetTester tester, {
    required Map<String, Object> prefs,
    int surah = 1,
    int ayah = 1,
  }) async {
    final registry = (await tester.runAsync(
      () => ThemeRegistry.load(rootBundle),
    ))!;
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    final user = UserDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(user.close));
    await tester.binding.setSurfaceSize(const Size(420, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentDatabaseProvider.overrideWithValue(db),
          userDatabaseProvider.overrideWithValue(user),
          themeRegistryProvider.overrideWithValue(registry),
          sharedPreferencesProvider.overrideWithValue(sp),
          packRootProvider.overrideWithValue(root),
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
          home: ContinuousScreen(surah: surah, ayah: ayah),
        ),
      ),
    );
  }

  testWidgets('Arabic only: the verses and nothing under them', (tester) async {
    await open(tester, prefs: const {});
    await settle(tester, find.textContaining('سورة الفاتحة'));
    expect(find.textContaining('سورة الفاتحة'), findsWidgets);
    expect(find.textContaining('Especially Merciful'), findsNothing);
  });

  testWidgets('with Saheeh International under each verse', (tester) async {
    // Source 8: Saheeh International (content.db commentary_edition).
    await open(
      tester,
      prefs: const {
        'settings.underVerse': ['8'],
      },
    );
    final english = find.textContaining('Especially Merciful');
    await settle(tester, english);
    expect(english, findsWidgets);
  });

  testWidgets('opens at the verse asked for', (tester) async {
    await open(tester, prefs: const {}, surah: 2, ayah: 255);
    final kursi = (await tester.runAsync(
      () => (db.select(
        db.ayah,
      )..where((t) => t.surah.equals(2) & t.number.equals(255))).getSingle(),
    ))!.displayText.substring(0, 20);
    final verses = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().startsWith(kursi),
    );
    await settle(tester, verses);
    // Ayat al-Kursi is the first verse on screen: the view opened there.
    final first = tester
        .widgetList<RichText>(find.byType(RichText))
        .first
        .text
        .toPlainText();
    expect(first, startsWith(kursi));
  });
}
