import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/crash/crash_reporting.dart';
import 'core/db/content_database.dart';
import 'core/db/user_database.dart';
import 'core/flags/feature_flags.dart';
import 'core/router/app_router.dart';
import 'core/settings/settings_controller.dart';
import 'core/theme/theme_registry.dart';
import 'features/audio/car_browser.dart';
import 'features/audio/car_channel.dart';
import 'features/audio/recitation.dart';
import 'features/audio/timing_updates.dart';
import 'features/khatma/khatma_providers.dart';
import 'features/khatma/services/home_widget_sync.dart';
import 'features/khatma/services/reminder_scheduler.dart';
import 'features/mushaf/data/background_packs.dart';
import 'features/mushaf/data/bundled_pack.dart';
import 'features/mushaf/mushaf_providers.dart';
import 'features/mushaf/presentation/navigation.dart';
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
  switch (defaultTargetPlatform) {
    case TargetPlatform.windows || TargetPlatform.linux:
      // No system media session package for these: just_audio plays
      // through libmpv (just_audio_media_kit).
      JustAudioMediaKit.ensureInitialized(linux: true, windows: true);
    default:
      // Recitation keeps playing with the screen off, with lock-screen
      // controls.
      await JustAudioBackground.init(
        androidNotificationChannelId: 'app.tibyan.recitation',
        androidNotificationChannelName: 'التلاوة',
        androidNotificationOngoing: true,
      );
  }

  final registry = await ThemeRegistry.load(rootBundle);
  final flags = await FeatureFlags.load(rootBundle);
  final prefs = await SharedPreferences.getInstance();
  final content = await ContentDatabase.openBundled(rootBundle);
  final packRoot = await getApplicationSupportDirectory();
  final timing = TimingUpdates(Directory(p.join(packRoot.path, 'timing')));

  final container = ProviderContainer(
    overrides: [
      themeRegistryProvider.overrideWithValue(registry),
      featureFlagsProvider.overrideWithValue(flags),
      sharedPreferencesProvider.overrideWithValue(prefs),
      contentDatabaseProvider.overrideWithValue(content),
      userDatabaseProvider.overrideWithValue(UserDatabase.open()),
      packRootProvider.overrideWithValue(packRoot),
      timingOverridesProvider.overrideWithValue(timing),
      reminderSchedulerProvider.overrideWithValue(LocalReminderScheduler()),
      homeWidgetSyncProvider.overrideWithValue(
        defaultTargetPlatform == TargetPlatform.macOS
            ? MacHomeWidgetSync()
            : PluginHomeWidgetSync(),
      ),
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
  unawaited(_refreshTimings(container, timing));
  _startCarBrowsing(container);
  _startKhatma(container);
}

/// Corrected recitation timings: what content.db was built with, then
/// any newer pack on our server (checked at most twice a day). Offline or
/// failing, content.db's timings stay.
Future<void> _refreshTimings(
  ProviderContainer container,
  TimingUpdates timing,
) async {
  try {
    final repo = container.read(mushafRepositoryProvider);
    timing
      ..folders = {for (final r in await repo.reciters()) r.id: r.folderUrl}
      ..bundled = await repo.timingVersions();
    await timing.refresh();
  } catch (_) {
    // Nothing to do: the bundled timings are used.
  }
}

/// Keeps the khatma's reminders (rolling) and the home screen widget up to
/// date, and opens the page a reminder or the widget points to.
void _startKhatma(ProviderContainer container) {
  final service = container.read(khatmaServiceProvider);
  final widget = container.read(homeWidgetSyncProvider);
  // Queued widget buttons first (the day's portion marked read), then the
  // reminders and the widget's own entries are rewritten.
  Future<void> refresh() async {
    try {
      for (final a in await widget.takePending()) {
        if (a == WidgetAction.portionDone) await service.markTodayRead();
      }
      await service.refresh();
    } catch (_) {}
  }

  unawaited(refresh());
  AppLifecycleListener(onResume: refresh);

  Future<void> open(Uri? uri) async {
    if (uri == null) return;
    final action = widgetActionOf(uri);
    final verse = verseOfLink(uri);
    final khatmaLink = const {
      'khatma',
      'khatmah',
      'khatmat',
      'reader',
    }.contains(uri.host);
    if (!khatmaLink && action == null && verse == null) return;
    final route =
        action?.route ??
        (verse != null
            ? mushafLocation(
                await container.read(
                  versePageProvider((verse.surah, verse.ayah)).future,
                ),
                surah: verse.surah,
                ayah: verse.ayah,
              )
            : await service.routeFor(uri));
    // After the splash screen (or the first-run setup) has handed over,
    // so its own navigation does not replace the link's. A link of a
    // running app goes at once: the signal is already given.
    await container.read(appRouterReadyProvider).future;
    container.read(appRouterProvider).go(route);
  }

  final reminders = container.read(reminderSchedulerProvider);
  reminders.onTap = (payload) => open(Uri.tryParse(payload));
  unawaited(
    reminders
        .launchPayload()
        .then((p) => open(p == null ? null : Uri.tryParse(p)))
        .catchError((_) {}),
  );
  unawaited(widget.launchUri().then(open).catchError((_) {}));
  widget.taps.listen(open, onError: (_) {});

  // Other `tibyan://` links (a verse link from a message or another app).
  // The widgets' own links carry `homeWidget` and arrive above; on macOS
  // every link comes through the app's channel (MacHomeWidgetSync).
  if (defaultTargetPlatform != TargetPlatform.macOS) {
    bool mine(Uri? u) =>
        u != null && !u.queryParameters.containsKey('homeWidget');
    final links = AppLinks();
    unawaited(
      links
          .getInitialLink()
          .then((u) => mine(u) ? open(u) : null)
          .catchError((_) {}),
    );
    links.uriLinkStream.listen((u) {
      if (mine(u)) open(u);
    }, onError: (_) {});
  }
}

/// Android Auto and CarPlay: the reciters and surahs to choose from in the
/// car, and «continue» from the reading position
/// (lib/features/audio/car_browser.dart). Android Auto asks through the
/// audio service; CarPlay through `app.tibyan/car` (car_channel.dart).
void _startCarBrowsing(ProviderContainer container) {
  final android = defaultTargetPlatform == TargetPlatform.android;
  if (!android && defaultTargetPlatform != TargetPlatform.iOS) return;
  final text = lookupAppLocalizations(
    container.read(settingsProvider).locale ?? const Locale('ar'),
  );
  final browser = CarBrowser(
    reciters: () => container.read(recitersProvider.future),
    surahs: () => container.read(surahsProvider.future),
    position: () async {
      final p = await container.read(userDatabaseProvider).position();
      return p == null ? null : (surah: p.surah, ayah: p.ayah);
    },
    start: ({int? reciter, required int surah, int? ayah}) async {
      final c = container.read(recitationProvider.notifier);
      if (reciter != null) await c.changeReciter(reciter);
      await c.play(surah, from: ayah);
    },
    text: CarText(
      continueReading: text.carContinue,
      reciters: text.carReciters,
      surah: (n, name) => '$n. ${text.surahWord(name)}',
    ),
  );
  if (android) {
    JustAudioBackground.browser = browser;
  } else {
    unawaited(CarChannel(browser).attach());
  }
}
