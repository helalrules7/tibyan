import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/app.dart';
import 'package:tibyan/core/flags/feature_flags.dart';
import 'package:tibyan/core/router/app_router.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/features/audio/recitation.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';

void main() {
  testWidgets('the storage screen lists downloads and deletes one', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'settings.onboardingDone': true});
    final registry = await ThemeRegistry.load(rootBundle);
    final flags = await FeatureFlags.load(rootBundle);
    final prefs = await SharedPreferences.getInstance();
    final root = Directory.systemTemp.createTempSync('storage_screen');
    File(p.join(root.path, 'audio', '3', '001.mp3'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(List.filled(3000000, 1));
    final container = ProviderContainer(
      overrides: [
        themeRegistryProvider.overrideWithValue(registry),
        featureFlagsProvider.overrideWithValue(flags),
        sharedPreferencesProvider.overrideWithValue(prefs),
        packRootProvider.overrideWithValue(root),
        allRecitersProvider.overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TibyanApp()),
    );
    await tester.pump(const Duration(seconds: 2));
    container.read(appRouterProvider).go('/settings/storage');
    await tester.pump();
    // The scan runs in an isolate: real time passes for it.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('التخزين والتنزيلات'), findsWidgets);
    expect(find.textContaining('٣٫٠ ميجا'), findsWidgets);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('حذف').last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      File(p.join(root.path, 'audio', '3', '001.mp3')).existsSync(),
      isFalse,
    );
  });
}
