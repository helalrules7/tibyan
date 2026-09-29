import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/app.dart';
import 'package:tibyan/core/flags/feature_flags.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';

void main() {
  testWidgets(
    'first launch: language, then style and colours, then the edition',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final registry = await ThemeRegistry.load(rootBundle);
      final flags = await FeatureFlags.load(rootBundle);
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          themeRegistryProvider.overrideWithValue(registry),
          featureFlagsProvider.overrideWithValue(flags),
          sharedPreferencesProvider.overrideWithValue(prefs),
          // No edition is on this fresh device.
          packRootProvider.overrideWithValue(
            Directory.systemTemp.createTempSync('packs'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TibyanApp(),
        ),
      );
      // Past the splash screen.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Defaults: Calm style, Light mode, new edition.
      final settings = container.read(settingsProvider);
      expect(settings.styleId, 'zakhrafa');
      expect(settings.mode, ModeSetting.light);
      expect(settings.edition, MushafEdition.madina1441);

      // Screen 1: language, titled in both languages.
      expect(find.textContaining('Choose your language'), findsOneWidget);
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).language, LanguageSetting.en);
      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();

      // Screen 2: style and colours.
      final next = find.text('متابعة');
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();

      // Screen 2 offers both Madina editions.
      final old = find.text('مصحف المدينة: الطبعة القديمة');
      await tester.ensureVisible(old);
      await tester.pumpAndSettle();
      await tester.tap(old);
      await tester.pumpAndSettle();
      expect(
        container.read(settingsProvider).edition,
        MushafEdition.madina1405,
      );
      expect(container.read(settingsProvider).onboardingDone, isFalse);
    },
  );
}
