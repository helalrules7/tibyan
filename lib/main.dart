import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:audio_session/audio_session.dart';

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
import 'features/group_khatma/data/group_khatma_api.dart';
import 'features/settings/report/problem_report.dart';
import 'core/crash/crash_reporting.dart';
import 'core/crash/native_diagnostics.dart';
import 'core/db/content_database.dart';
import 'core/db/user_database.dart';
import 'core/downloads/background_downloads.dart';
import 'core/flags/feature_flags.dart';
import 'core/platform/app_shortcuts.dart';
import 'core/perf/startup_marks.dart';
import 'core/review/review_prompt.dart';
import 'core/router/app_router.dart';
import 'core/ui/desktop_window.dart';
import 'core/update/windows_updater.dart';
import 'core/settings/settings_controller.dart';
import 'core/theme/theme_registry.dart';
import 'features/audio/background_recitations.dart';
import 'features/audio/car_browser.dart';
import 'features/audio/car_channel.dart';
import 'features/audio/live_activity.dart';
import 'features/audio/recitation.dart';
import 'features/audio/timing_updates.dart';
import 'features/audio/word_timing_packs.dart';
import 'features/khatma/khatma_providers.dart';
import 'features/khatma/domain/day.dart';
import 'features/khatma/services/home_widget_sync.dart';
import 'features/khatma/services/verse_of_day.dart';
import 'features/khatma/services/reminder_scheduler.dart';
import 'features/khatma/services/kahf_reminder.dart';
import 'features/khatma/services/weekly_reminder.dart';
import 'features/mushaf/data/background_packs.dart';
import 'features/mushaf/data/bundled_pack.dart';
import 'features/mushaf/mushaf_providers.dart';
import 'features/mushaf/presentation/navigation.dart';
import 'features/mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import 'features/tasmee/data/background_model_download.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  startupMark('binding');
  if (const bool.fromEnvironment('PROF')) {
    unawaited(
      WidgetsBinding.instance.waitUntilFirstFrameRasterized.then(
        (_) => startupMark('first-frame'),
      ),
    );
  }
  // Per-frame timings, for profiling a build run with
  // `--dart-define=PROF=true`. Off, and free, in every other build.
  if (const bool.fromEnvironment('PROF')) {
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final t in timings) {
        // ignore: avoid_print
        print(
          'PROF ui=${t.buildDuration.inMicroseconds} '
          'raster=${t.rasterDuration.inMicroseconds} '
          'total=${t.totalSpan.inMicroseconds}',
        );
      }
    });
  }
  await _initAudio();
  startupMark('audio');
  final registry = await ThemeRegistry.load(rootBundle);
  startupMark('theme');
  final flags = await FeatureFlags.load(rootBundle);
  startupMark('theme+flags');
  final prefs = await SharedPreferences.getInstance();
  // On the desktop: the window's size and place, as last left.
  await DesktopWindow.init(prefs, title: 'Tibyan');
  startupMark('prefs+window');
  final content = await ContentDatabase.openBundled(rootBundle);
  final packRoot = await getApplicationSupportDirectory();
  final timing = TimingUpdates(Directory(p.join(packRoot.path, 'timing')));
  final words = WordTimingPacks(
    Directory(p.join(packRoot.path, 'word-timing')),
  );

  startupMark('content-db+dirs');
  final container = ProviderContainer(
    overrides: [
      themeRegistryProvider.overrideWithValue(registry),
      featureFlagsProvider.overrideWithValue(flags),
      sharedPreferencesProvider.overrideWithValue(prefs),
      contentDatabaseProvider.overrideWithValue(content),
      userDatabaseProvider.overrideWithValue(UserDatabase.open()),
      packRootProvider.overrideWithValue(packRoot),
      timingOverridesProvider.overrideWithValue(timing),
      wordTimingPacksProvider.overrideWithValue(words),
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
  // The system's crash reports from earlier runs (iOS MetricKit): sent only
  // with the reader's agreement, dropped otherwise.
  unawaited(forwardNativeDiagnostics(send: CrashReporting.isRunning));

  startupMark('crash');
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
  BackgroundModelDownload.displayName = l.tasmeeModelTitle;
  BackgroundRecitations.title = l.audioDownloads;
  // Every kind of download registers before the start, so one that ended
  // while the app was closed reaches its handler.
  container
    ..read(backgroundModelDownloadProvider)
    ..read(backgroundRecitationsProvider);
  unawaited(
    container
        .read(backgroundPacksProvider)
        .start()
        .then((_) => container.read(packInstallsProvider.notifier).changed()),
  );

  // Reports queued while offline go out on the next start.
  unawaited(container.read(reportServiceProvider).flush());
  startupMark('pre-runApp');
  runApp(
    UncontrolledProviderScope(container: container, child: const TibyanApp()),
  );

  // Which audio host is faster for this reader, measured in the background.
  unawaited(measureAudioHosts(container));
  unawaited(_refreshTimings(container, timing));
  unawaited(_tidyStorage(container));
  _startCarBrowsing(container);
  _startLiveActivity(container);
  _startKhatma(container);
  // Windows installer builds: check for a new Setup.exe (no-op elsewhere).
  windowsUpdater.start();
  startupMark('main-done');
}

/// The recitation's background service and the audio session, before
/// anything can play.
Future<void> _initAudio() async {
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
        // A white silhouette, not the full-colour launcher icon (which
        // Android draws as a blank blob in the status bar).
        androidNotificationIcon: 'drawable/ic_stat_tibyan',
        notificationColor: const Color(0xFF0F6660),
      );
      // The session is set for playback before anything plays, so
      // iOS keeps the recitation going in the background (the .playback
      // category) whichever sound starts first (the misbaha's click, a
      // recording).
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
  }
}

/// After the first frame: storage an older build used that this one no
/// longer needs (the extracted copy of the bundled pages), and the word
/// timings of reciters whose audio is already on the device, now that
/// they are no longer inside the app (fetched quietly; offline, the next
/// launch tries again).
Future<void> _tidyStorage(ProviderContainer container) async {
  try {
    await WidgetsBinding.instance.endOfFrame;
    final packs = container.read(packsDirProvider);
    if (await removeExtractedBundledPack(rootBundle, packs)) {
      container.read(packInstallsProvider.notifier).changed();
    }
  } catch (_) {
    // Left for the next launch.
  }
  final words = container.read(wordTimingPacksProvider);
  if (words == null) return;
  final files = container.read(audioFilesProvider);
  await words.ensureAll([
    for (final r in words.specs.keys)
      if (!words.has(r) && files.downloaded(r).isNotEmpty) r,
  ]);
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
    } catch (e) {
      debugPrint('widget actions/khatma refresh failed: $e');
    }
    // The weekly report reminder, a few weeks ahead (off by default).
    try {
      await syncWeeklyReminder(
        container.read(reminderSchedulerProvider),
        container.read(settingsProvider),
      );
    } catch (e) {
      debugPrint('weekly reminder sync failed: $e');
    }
    // The Friday Surah Al-Kahf reminder (on by default, scheduled only
    // when notifying is already allowed).
    try {
      await syncKahfReminder(
        container.read(reminderSchedulerProvider),
        container.read(settingsProvider),
      );
    } catch (e) {
      debugPrint('Kahf reminder sync failed: $e');
    }
    // «آية اليوم»: a month ahead, whether or not there is a khatma. After
    // the first frame (it is ~30 lookups), and only when what the widgets
    // hold runs short or is in another language.
    try {
      await WidgetsBinding.instance.endOfFrame;
      final settings = container.read(settingsProvider);
      final l = lookupAppLocalizations(settings.locale ?? const Locale('ar'));
      final prefs = container.read(sharedPreferencesProvider);
      final today = Day.today();
      if (!verseOfDayStale(
        prefs.getString(verseOfDayStampKey),
        lang: l.localeName,
        today: today,
      )) {
        return;
      }
      await widget.writeVerses(
        await verseOfDayEntries(
          ayahById: container.read(mushafRepositoryProvider).ayahById,
          surahs: await container.read(surahsProvider.future),
          l: l,
          from: today,
        ),
      );
      await prefs.setString(
        verseOfDayStampKey,
        verseOfDayStamp(l.localeName, today),
      );
    } catch (e) {
      debugPrint('verse of the day scheduling failed: $e');
    }
  }

  unawaited(refresh());
  unawaited(container.read(reviewPromptProvider).noteLaunch());
  AppLifecycleListener(
    onResume: refresh,
    // Listening with the screen off: the decoded pages and pictures kept
    // for quick turns are let go, so the app holds less memory while iOS
    // keeps it running in the background for the recitation. They are
    // decoded again when needed.
    onHide: () => PaintingBinding.instance.imageCache.clear(),
  );

  Future<void> open(Uri? link) async {
    if (link == null) return;
    // Google Assistant's «open app feature»: the shortcut's own link.
    final uri = assistantFeatureLink(link) ?? link;
    if (uri.toString() == weeklyReportLink) {
      container.read(launchTargetProvider).value = true;
      await container.read(appRouterReadyProvider).future;
      unawaited(container.read(appRouterProvider).push(weeklyReportLocation));
      return;
    }
    // A group khatma link: https://altibyan.app/k/<id> (universal / app
    // link) or tibyan://group?id=<id> (the web page's button, reminders).
    final groupId = groupKhatmaIdOf(uri.toString());
    if (groupId != null) {
      if (!container.read(featureFlagsProvider).isOn(Feature.groupKhatma)) {
        return;
      }
      container.read(launchTargetProvider).value = true;
      await container.read(appRouterReadyProvider).future;
      unawaited(
        container.read(appRouterProvider).push('/khatma/group/$groupId'),
      );
      return;
    }
    final action = widgetActionOf(uri);
    final verse = verseOfLink(uri);
    final khatmaLink = const {
      'khatma',
      'khatmah',
      'khatmat',
      'reader',
      'hifz',
    }.contains(uri.host);
    if (!khatmaLink && action == null && verse == null) return;
    final route =
        action?.route ??
        (verse != null
            ? await verseLinkLocation(
                container,
                verse.surah,
                verse.ayah,
                listen: verseLinkListens(uri),
              )
            : await service.routeFor(uri));
    // After the splash screen (or the first-run setup) has handed over,
    // so its own navigation does not replace the link's. A link of a
    // running app goes at once: the signal is already given.
    container.read(launchTargetProvider).value = true;
    await container.read(appRouterReadyProvider).future;
    container.read(appRouterProvider).go(route);
  }

  // A download's notification opens the Downloads screen, which only
  // shows them: it never queues anything.
  container.read(backgroundDownloadsProvider).onNotificationTap = () async {
    container.read(launchTargetProvider).value = true;
    await container.read(appRouterReadyProvider).future;
    unawaited(container.read(appRouterProvider).push('/downloads'));
  };

  final reminders = container.read(reminderSchedulerProvider);
  // A permission granted for any reminder also schedules the Friday one.
  reminders.onGranted = () => unawaited(
    syncKahfReminder(
      reminders,
      container.read(settingsProvider),
    ).catchError((_) {}),
  );
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

  // Siri / Spotlight App Shortcuts (iOS 16+): «وردي اليومي», «متابعة
  // القراءة» and «افتح سورة …», with the surah names from the content data.
  if (AppShortcutsChannel.supported) {
    unawaited(
      AppShortcutsChannel()
          .attach(
            open: open,
            surahs: () async => [
              for (final s in await container.read(surahsProvider.future))
                (s.id, s.nameAr, s.nameEn),
            ],
          )
          .catchError((_) {}),
    );
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

/// iOS: the recitation's Live Activity on the lock screen and in the
/// Dynamic Island (reciter, surah, verse number; play/pause on iOS 17+).
/// It follows the recitation's state and never drives the player, except
/// for its own play/pause button.
void _startLiveActivity(ProviderContainer container) {
  if (!RecitationActivitySync.supported) return;
  final host = ChannelRecitationActivity();
  final sync = RecitationActivitySync(host);
  // Its buttons: the player's own play/pause and previous/next verse.
  host.onCommand = (command) {
    final player = container.read(recitationProvider.notifier);
    unawaited(switch (command) {
      RecitationCommand.toggle => player.toggle(),
      RecitationCommand.previous => player.step(-1),
      RecitationCommand.next => player.step(1),
    });
  };
  unawaited(sync.start());
  // The system Now Playing card is the recitation's only lock-screen card.
  if (!RecitationActivitySync.showsRecitation) return;
  Future<RecitationActivityContent?> contentOf(RecitationState s) async {
    if (!s.active) return null;
    final l = lookupAppLocalizations(
      container.read(settingsProvider).locale ?? const Locale('ar'),
    );
    final ar = l.localeName == 'ar';
    String? surah, reciter;
    var ayahCount = 0;
    try {
      final surahs = await container.read(surahsProvider.future);
      final row = surahs.where((r) => r.id == s.surah).firstOrNull;
      if (row != null) {
        surah = l.surahWord(ar ? row.nameAr : row.nameEn);
        ayahCount = row.ayahCount;
      }
      final reciters = await container.read(recitersProvider.future);
      final r = reciters.where((r) => r.id == s.reciterId).firstOrNull;
      if (r != null) reciter = ar ? r.nameAr : r.nameEn;
    } catch (_) {
      // Labels only: fall back to the defaults above.
    }
    final digits = NumberFormatter(Locale(l.localeName));
    return RecitationActivityContent(
      reciter: reciter ?? '',
      surah: surah ?? digits(s.surah),
      verse: s.ayah == null ? '' : l.liveActivityVerse(digits(s.ayah!)),
      playing: s.playing,
      playLabel: l.liveActivityPlay,
      pauseLabel: l.pause,
      rtl: ar,
      ayah: s.ayah ?? 0,
      ayahCount: ayahCount,
      previousLabel: l.liveActivityPreviousVerse,
      nextLabel: l.liveActivityNextVerse,
    );
  }

  container.listen<RecitationState>(recitationProvider, (before, s) async {
    // Only what the activity shows: not each word, not the loading flag.
    if (before != null &&
        before.active == s.active &&
        before.playing == s.playing &&
        before.surah == s.surah &&
        before.ayah == s.ayah &&
        before.reciterId == s.reciterId) {
      return;
    }
    final content = await contentOf(s);
    // A newer state may have arrived meanwhile: show only the latest.
    if (!identical(container.read(recitationProvider), s)) return;
    await sync.show(content);
  });
}
