import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/app.dart';
import 'package:tibyan/core/flags/feature_flags.dart';
import 'package:tibyan/core/router/app_router.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';

void main() {
  testWidgets('settings show the version the app was built with', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'settings.onboardingDone': true});
    PackageInfo.setMockInitialValues(
      appName: 'tibyan',
      packageName: 'app.tibyan.tibyan',
      version: '9.8.7',
      buildNumber: '42',
      buildSignature: '',
    );
    final registry = await ThemeRegistry.load(rootBundle);
    final flags = await FeatureFlags.load(rootBundle);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        themeRegistryProvider.overrideWithValue(registry),
        featureFlagsProvider.overrideWithValue(flags),
        sharedPreferencesProvider.overrideWithValue(prefs),
        packRootProvider.overrideWithValue(
          Directory.systemTemp.createTempSync('settings_version'),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TibyanApp()),
    );
    await tester.pump(const Duration(seconds: 2));
    container.read(appRouterProvider).go('/settings');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.scrollUntilVisible(
      find.textContaining('9.8.7 (42)'),
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 20,
    );
    expect(find.textContaining('9.8.7 (42)'), findsOneWidget);
  });
}
