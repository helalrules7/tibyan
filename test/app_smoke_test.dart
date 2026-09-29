import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/app.dart';
import 'package:tibyan/core/flags/feature_flags.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';

void main() {
  testWidgets('app starts in Arabic, right-to-left, and opens settings', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'settings.language': 'ar',
      'settings.onboardingDone': true,
    });
    final registry = await ThemeRegistry.load(rootBundle);
    final flags = await FeatureFlags.load(rootBundle);
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeRegistryProvider.overrideWithValue(registry),
          featureFlagsProvider.overrideWithValue(flags),
          sharedPreferencesProvider.overrideWithValue(prefs),
          packRootProvider.overrideWithValue(
            Directory.systemTemp.createTempSync('packs'),
          ),
        ],
        child: const TibyanApp(),
      ),
    );
    // Past the splash screen.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('تبيان'), findsOneWidget);
    final dir = Directionality.of(tester.element(find.text('تبيان')));
    expect(dir, TextDirection.rtl);

    await tester.tap(find.byTooltip('فتح الإعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('الإعدادات'), findsOneWidget);
  });
}
