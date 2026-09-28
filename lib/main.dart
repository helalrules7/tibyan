import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/crash/crash_reporting.dart';
import 'core/flags/feature_flags.dart';
import 'core/settings/settings_controller.dart';
import 'core/theme/theme_registry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Crash reporting follows the user's choice, now and whenever it changes.
  await CrashReporting.apply(
    optIn: container.read(settingsProvider).crashReportsOptIn,
  );
  container.listen(
    settingsProvider.select((s) => s.crashReportsOptIn),
    (_, optIn) => CrashReporting.apply(optIn: optIn),
  );

  runApp(
    UncontrolledProviderScope(container: container, child: const TibyanApp()),
  );
}
