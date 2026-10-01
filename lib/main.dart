import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
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
import 'features/audio/recitation.dart';
import 'features/mushaf/data/background_packs.dart';
import 'features/mushaf/data/bundled_pack.dart';
import 'features/mushaf/mushaf_providers.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Per-frame timings, for profiling a build run with
  // `--dart-define=PROF=true`. Off, and free, in every other build.
  if (const bool.fromEnvironment('PROF')) {
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final t in timings) {
        // ignore: avoid_print
        print(
          'PROF ui=${t.buildDuration.inMilliseconds} '
          'raster=${t.rasterDuration.inMilliseconds}',
        );
      }
    });
  }
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

  // The new Madina edition ships with the app: install it on first launch.
  try {
    await installBundledPack(rootBundle, container.read(packsDirProvider));
  } catch (_) {
    // It can still be downloaded like the other editions.
  }

  // Pack downloads run in the background; finish any that ended while the
  // app was closed. Notifications speak the interface language.
  final l = lookupAppLocalizations(
    container.read(settingsProvider).locale ?? const Locale('ar'),
  );
  BackgroundPacks.texts = (
    running: l.notifDownloading,
    complete: l.notifComplete,
    error: l.notifFailed,
    paused: l.notifPaused,
  );
  unawaited(
    container
        .read(backgroundPacksProvider)
        .start()
        .then((_) => container.read(packInstallsProvider.notifier).changed()),
  );

  runApp(
    UncontrolledProviderScope(container: container, child: const TibyanApp()),
  );

  // Which audio host is faster for this reader, measured in the background.
  unawaited(measureAudioHosts(container));
}
