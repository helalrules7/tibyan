import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/crash/crash_reporting.dart';
import 'core/db/content_database.dart';
import 'core/db/user_database.dart';
import 'core/flags/feature_flags.dart';
import 'core/settings/settings_controller.dart';
import 'core/theme/theme_registry.dart';
import 'features/mushaf/mushaf_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Recitation keeps playing with the screen off, with lock-screen controls.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'app.tibyan.recitation',
    androidNotificationChannelName: 'التلاوة',
    androidNotificationOngoing: true,
  );

  final registry = await ThemeRegistry.load(rootBundle);
  final flags = await FeatureFlags.load(rootBundle);
  final prefs = await SharedPreferences.getInstance();
  final content = await ContentDatabase.openBundled(rootBundle);
  final packRoot = await getApplicationSupportDirectory();

  final container = ProviderContainer(
    overrides: [
      themeRegistryProvider.overrideWithValue(registry),
      featureFlagsProvider.overrideWithValue(flags),
      sharedPreferencesProvider.overrideWithValue(prefs),
      contentDatabaseProvider.overrideWithValue(content),
      userDatabaseProvider.overrideWithValue(UserDatabase.open()),
      packRootProvider.overrideWithValue(packRoot),
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
