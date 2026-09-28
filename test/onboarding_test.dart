import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/app.dart';
import 'package:tibyan/core/flags/feature_flags.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/theme_registry.dart';

void main() {
  testWidgets('first launch shows style and colours, then the edition', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'settings.language': 'ar'});
    final registry = await ThemeRegistry.load(rootBundle);
    final flags = await FeatureFlags.load(rootBundle);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        themeRegistryProvider.overrideWithValue(registry),
        featureFlagsProvider.overrideWithValue(flags),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TibyanApp()),
    );
    await tester.pumpAndSettle();

    // Defaults: Calm style, Light mode, new edition.
    final settings = container.read(settingsProvider);
    expect(settings.styleId, 'calm');
    expect(settings.mode, ModeSetting.light);
    expect(settings.edition, MushafEdition.madina1441);

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
    expect(container.read(settingsProvider).edition, MushafEdition.madina1405);
    expect(container.read(settingsProvider).onboardingDone, isFalse);
  });
}
