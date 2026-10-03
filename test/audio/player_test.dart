import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/contrast.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/audio/player_bar.dart';
import 'package:tibyan/features/audio/recitation.dart';
import 'package:tibyan/features/settings/player_settings_screen.dart';
import 'package:tibyan/l10n/app_localizations.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';

/// Stands in for just_audio: records loads and seeks, and reports the
/// positions and states a test gives it.
class FakeAudio implements RecitationAudio {
  final _positions = StreamController<Duration>.broadcast(sync: true);
  final _states = StreamController<PlayerState>.broadcast();
  bool playing = false;
  @override
  ProcessingState processingState = ProcessingState.idle;
  final loads = <(Uri, Duration)>[];
  final seeks = <Duration>[];

  /// Positions reported while a file loads: the old file's, then the
  /// new one's start, as a real player may.
  List<int> whileLoading = const [];

  void _emit() => _states.add(PlayerState(playing, processingState));

  /// Playback reaches [ms].
  void at(int ms) => _positions.add(Duration(milliseconds: ms));

  /// The file plays to its end.
  void complete() {
    processingState = ProcessingState.completed;
    _emit();
  }

  @override
  Stream<Duration> get positions => _positions.stream;
  @override
  Stream<PlayerState> get states => _states.stream;

  @override
  Future<void> load(Uri uri, MediaItem tag, Duration initial) async {
    loads.add((uri, initial));
    processingState = ProcessingState.loading;
    _emit();
    for (final ms in whileLoading) {
      at(ms);
    }
    processingState = ProcessingState.ready;
    _emit();
  }

  @override
  Future<void> play() async {
    playing = true;
    _emit();
  }

  @override
  Future<void> pause() async {
    playing = false;
    _emit();
  }

  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
    if (processingState == ProcessingState.completed) {
      processingState = ProcessingState.ready;
      _emit();
    }
  }

  @override
  Future<void> stop() async {
    playing = false;
    processingState = ProcessingState.idle;
    _emit();
  }

  @override
  Future<void> dispose() async {}
}

/// Three recitations of a five-verse surah 2: 1 with verses of 10 s
/// (speech from 1 s in, ending 3 s before the next verse), 2 with verses
/// of 12 s and no timing row before verse 1 (like al-Banna), 3 untimed.
class FakeRepo extends Fake implements MushafRepository {
  static const verses = 5;

  static int len(int reciter) => reciter == 2 ? 12000 : 10000;

  @override
  Future<List<ReciterRow>> reciters() async => [
    for (final id in [1, 2, 3])
      ReciterRow(
        id: id,
        nameAr: 'قارئ $id',
        nameEn: 'Reciter $id',
        style: 'murattal',
        folderUrl: 'https://server$id.mp3quran.net/r$id/',
        sourceId: 10,
        riwaya: 'hafs',
      ),
    // Another riwaya's recitation: listed, but not offered with Hafs.
    ReciterRow(
      id: 101,
      nameAr: 'قارئ ورش',
      nameEn: 'Warsh reciter',
      style: 'murattal',
      folderUrl: 'https://server101.mp3quran.net/w/',
      sourceId: 40,
      riwaya: 'warsh',
    ),
  ];

  @override
  Future<List<SurahRow>> surahs() async => [
    for (var i = 1; i <= 114; i++)
      SurahRow(
        id: i,
        nameAr: 'سورة $i',
        nameEn: 'Surah $i',
        meaningEn: '',
        revelation: 'meccan',
        revelationOrder: i,
        ayahCount: verses,
        startPage: i,
        startPage1405: i,
        sourceId: 1,
        startPageShamarly: i,
      ),
  ];

  @override
  Future<List<AyahTimingRow>> timings(int reciter, int surah) async => [
    if (reciter != 3)
      for (var a = 1; a <= verses; a++)
        AyahTimingRow(
          reciter: reciter,
          surah: surah,
          ayah: a,
          startMs: (a - 1) * len(reciter),
          endMs: a * len(reciter),
        ),
  ];

  @override
  Future<List<AyahSpeechRow>> speech(int reciter, int surah) async => [
    if (reciter != 3)
      for (var a = 1; a <= verses; a++)
        AyahSpeechRow(
          reciter: reciter,
          surah: surah,
          ayah: a,
          startMs: (a - 1) * len(reciter) + 1000,
          endMs: a * len(reciter) - 3000,
        ),
  ];

  @override
  Future<List<WordTimingRow>> wordTimings(int reciter, int surah) async =>
      const [];
}

late ThemeRegistry registry;

/// A recitation wired to fakes. Streams fail at once unless [client] says
/// otherwise; [prefs] are the saved settings.
Future<(ProviderContainer, FakeAudio)> recitation({
  Map<String, Object> prefs = const {'settings.versePause': 0},
  http.Client? client,
  Directory? root,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final audio = FakeAudio();
  final c = ProviderContainer(
    overrides: [
      themeRegistryProvider.overrideWithValue(registry),
      sharedPreferencesProvider.overrideWithValue(sp),
      mushafRepositoryProvider.overrideWithValue(FakeRepo()),
      packRootProvider.overrideWithValue(
        root ?? Directory.systemTemp.createTempSync('audio'),
      ),
      recitationAudioProvider.overrideWithValue(() => audio),
      audioHttpClientProvider.overrideWithValue(
        client ?? MockClient((_) async => http.Response('', 404)),
      ),
    ],
  );
  addTearDown(c.dispose);
  return (c, audio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => registry = await ThemeRegistry.load(rootBundle));

  group('repeat', () {
    testWidgets('each verse plays as many times as set, then the next', (
      tester,
    ) async {
      final (c, audio) = await recitation();
      final ctrl = c.read(recitationProvider.notifier);
      ctrl.setRepeat(3);
      await ctrl.play(2, from: 2);
      expect(audio.loads.single.$2, const Duration(milliseconds: 10000));
      for (var round = 1; round <= 2; round++) {
        audio.at(15000);
        audio.at(19970); // the end of verse 2
        await tester.pump();
        expect(c.read(recitationProvider).repeatDone, round);
        expect(audio.seeks.last, const Duration(milliseconds: 10000));
        expect(audio.playing, isTrue);
      }
      // The third time, it plays on into verse 3.
      final seeks = audio.seeks.length;
      audio.at(19970);
      await tester.pump();
      expect(audio.seeks.length, seeks);
      audio.at(20500);
      expect(c.read(recitationProvider).ayah, 3);
      expect(c.read(recitationProvider).repeatDone, 0);
    });

    testWidgets('with shorter pauses, the verse repeats before the jump', (
      tester,
    ) async {
      final (c, audio) = await recitation(prefs: {'settings.repeat': 2});
      final ctrl = c.read(recitationProvider.notifier);
      await ctrl.play(2, from: 2);
      // Speech of verse 2 ends at 17 s; half a second is kept after it.
      audio.at(17300);
      expect(audio.seeks, isEmpty, reason: 'no jump over the pause');
      audio.at(17470);
      await tester.pump();
      expect(c.read(recitationProvider).repeatDone, 1);
      // Again from just before its speech (11 s), not the pause before it.
      expect(audio.seeks.last, const Duration(milliseconds: 10750));
      // The second time done, the pause is shortened as usual.
      audio.at(17470);
      await tester.pump();
      audio.at(17300);
      expect(audio.seeks.last, const Duration(milliseconds: 20750));
    });

    testWidgets('a stretch repeats, then stops; play starts it again', (
      tester,
    ) async {
      final (c, audio) = await recitation();
      final ctrl = c.read(recitationProvider.notifier);
      await ctrl.play(2, from: 2, to: 3, repeat: 2);
      audio.at(29970);
      await tester.pump();
      expect(c.read(recitationProvider).repeatDone, 1);
      expect(audio.seeks.last, const Duration(milliseconds: 10000));
      expect(audio.playing, isTrue);
      audio.at(29970);
      await tester.pump();
      expect(c.read(recitationProvider).repeatDone, 2);
      expect(audio.playing, isFalse);
      // Further positions change nothing.
      audio.at(30000);
      await tester.pump();
      expect(c.read(recitationProvider).repeatDone, 2);
      await ctrl.toggle();
      expect(c.read(recitationProvider).repeatDone, 0);
      expect(audio.seeks.last, const Duration(milliseconds: 10000));
      expect(audio.playing, isTrue);
    });

    testWidgets('the last verse repeats even when the file ends first', (
      tester,
    ) async {
      final (c, audio) = await recitation();
      final ctrl = c.read(recitationProvider.notifier);
      await ctrl.play(2, from: 5, to: 5, repeat: 2);
      audio.at(45000);
      audio.complete();
      await tester.pump();
      expect(c.read(recitationProvider).repeatDone, 1);
      expect(audio.seeks.last, const Duration(milliseconds: 40000));
      expect(audio.playing, isTrue);
      expect(c.read(recitationProvider).surah, 2);
    });

    testWidgets('silence between repetitions, and a pause during it', (
      tester,
    ) async {
      final (c, audio) = await recitation();
      final ctrl = c.read(recitationProvider.notifier);
      ctrl.setSilence(const Duration(seconds: 5));
      await ctrl.play(2, from: 1, to: 1, repeat: 3);
      audio.at(9970);
      await tester.pump();
      expect(audio.playing, isFalse);
      expect(c.read(recitationProvider).playing, isTrue);
      await tester.pump(const Duration(seconds: 5));
      expect(audio.playing, isTrue);
      expect(audio.seeks.last, Duration.zero);
      // Paused in the second silence: it waits, then plays on from the
      // start of the stretch.
      audio.at(9970);
      await tester.pump(const Duration(seconds: 1));
      await ctrl.toggle();
      await tester.pump(const Duration(seconds: 10));
      expect(audio.playing, isFalse);
      expect(c.read(recitationProvider).playing, isFalse);
      await ctrl.toggle();
      expect(audio.playing, isTrue);
      expect(audio.seeks.last, Duration.zero);
    });

    testWidgets('repeat this verse, set to once, repeats until stopped', (
      tester,
    ) async {
      final (c, audio) = await recitation();
      final ctrl = c.read(recitationProvider.notifier);
      await ctrl.play(2, from: 2);
      audio.at(12000);
      ctrl.repeatCurrentVerse();
      for (var i = 0; i < 4; i++) {
        audio.at(19970);
        await tester.pump();
      }
      expect(c.read(recitationProvider).repeatDone, 4);
      expect(audio.playing, isTrue);
    });
  });

  group('sleep timer', () {
    testWidgets('after the minutes set, playback pauses', (tester) async {
      final (c, audio) = await recitation();
      final ctrl = c.read(recitationProvider.notifier);
      await ctrl.play(2);
      ctrl.setSleep(const SleepAfter(Duration(minutes: 15)));
      await tester.pump(const Duration(minutes: 14));
      expect(audio.playing, isTrue);
      await tester.pump(const Duration(minutes: 1));
      expect(audio.playing, isFalse);
      expect(c.read(recitationProvider).sleep, isNull);
      expect(c.read(recitationProvider).playing, isFalse);
    });

    testWidgets('a silence between repetitions does not wake it', (
      tester,
    ) async {
      final (c, audio) = await recitation();
      final ctrl = c.read(recitationProvider.notifier);
      ctrl.setSilence(const Duration(seconds: 20));
      await ctrl.play(2, from: 1, to: 1, repeat: 0);
      ctrl.setSleep(const SleepAfter(Duration(minutes: 15)));
      await tester.pump(const Duration(minutes: 14, seconds: 50));
      audio.at(9970);
      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 30));
      expect(audio.playing, isFalse);
      expect(c.read(recitationProvider).playing, isFalse);
    });

    testWidgets('turned off or replaced, it does not fire', (tester) async {
      final (c, audio) = await recitation();
      final ctrl = c.read(recitationProvider.notifier);
      await ctrl.play(2);
      ctrl.setSleep(const SleepAfter(Duration(minutes: 15)));
      ctrl.setSleep(const SleepAfter(Duration(minutes: 30)));
      await tester.pump(const Duration(minutes: 20));
      expect(audio.playing, isTrue);
      ctrl.setSleep(null);
      await tester.pump(const Duration(minutes: 20));
      expect(audio.playing, isTrue);
    });

    testWidgets('at the end of the surah: stops there, once', (tester) async {
      final (c, audio) = await recitation();
      final ctrl = c.read(recitationProvider.notifier);
      await ctrl.play(2, from: 5);
      ctrl.setSleep(const SleepAtSurahEnd());
      audio.complete();
      await tester.pump();
      expect(audio.playing, isFalse);
      expect(audio.loads.length, 1, reason: 'no next surah');
      expect(c.read(recitationProvider).sleep, isNull);
      // Without it, the next surah follows.
      await ctrl.toggle();
      audio.complete();
      await tester.pump();
      expect(audio.loads.length, 2);
      expect(c.read(recitationProvider).surah, 3);
    });
  });

  group('changing the reciter', () {
    testWidgets('the verse never moves while the new file loads', (
      tester,
    ) async {
      final (c, audio) = await recitation();
      final ctrl = c.read(recitationProvider.notifier);
      final seen = <int?>[];
      c.listen(recitationProvider.select((s) => s.ayah), (_, a) => seen.add(a));
      await ctrl.play(2, from: 4);
      audio.at(35000);
      seen.clear();
      // The loading player reports the old position, then zero.
      audio.whileLoading = [35100, 0];
      await ctrl.changeReciter(2);
      audio.at(0); // late
      audio.at(36000);
      expect(seen.where((a) => a != 4), isEmpty);
      // Reciter 2 has timings: it resumes at verse 4 (36 s into its file).
      expect(audio.loads.last.$2, const Duration(milliseconds: 36000));
      expect(c.read(recitationProvider).ayah, 4);
      expect(audio.playing, isTrue);
    });

    testWidgets('without timings, from the start of the surah', (tester) async {
      final (c, audio) = await recitation();
      final ctrl = c.read(recitationProvider.notifier);
      await ctrl.play(2, from: 4);
      audio.whileLoading = [0];
      await ctrl.changeReciter(3);
      expect(audio.loads.last.$2, Duration.zero);
      expect(c.read(recitationProvider).ayah, isNull);
      expect(c.read(recitationProvider).timed, isFalse);
      expect(c.read(settingsProvider).reciterId, 3);
    });

    testWidgets('paused, it stays paused', (tester) async {
      final (c, audio) = await recitation();
      final ctrl = c.read(recitationProvider.notifier);
      await ctrl.play(2, from: 3);
      await tester.pump();
      await ctrl.toggle();
      await tester.pump();
      await ctrl.changeReciter(2);
      expect(audio.playing, isFalse);
      expect(audio.loads.last.$2, const Duration(milliseconds: 24000));
    });
  });

  group('hosts', () {
    final mirror = Uri.parse('https://mirror.example/a/001.mp3');
    final source = Uri.parse('https://source.example/a/001.mp3');
    MockClient client(Duration mirrorTakes, Duration sourceTakes) =>
        MockClient((r) async {
          expect(r.headers['Range'], 'bytes=0-32767');
          await Future<void>.delayed(
            r.url.host == mirror.host ? mirrorTakes : sourceTakes,
          );
          return http.Response.bytes(List.filled(32768, 0), 206);
        });

    test('the host that answers first wins', () async {
      const fast = Duration(milliseconds: 5);
      const slow = Duration(milliseconds: 150);
      expect(
        await fasterHost(client(slow, fast), mirror: mirror, source: source),
        AudioHost.source,
      );
      expect(
        await fasterHost(client(fast, slow), mirror: mirror, source: source),
        AudioHost.mirror,
      );
    });

    test(
      'a failing host loses; both failing, or too slow: no answer',
      () async {
        final halfDown = MockClient(
          (r) async => r.url.host == mirror.host
              ? http.Response('', 503)
              : http.Response.bytes(List.filled(32768, 0), 206),
        );
        expect(
          await fasterHost(halfDown, mirror: mirror, source: source),
          AudioHost.source,
        );
        final down = MockClient((_) async => throw const SocketException('x'));
        expect(await fasterHost(down, mirror: mirror, source: source), isNull);
        const long = Duration(milliseconds: 300);
        expect(
          await fasterHost(
            client(long, long),
            mirror: mirror,
            source: source,
            timeout: const Duration(milliseconds: 30),
          ),
          isNull,
        );
      },
    );

    test('playback goes to the faster host, the other kept after it', () async {
      final (c, _) = await recitation(
        client: MockClient((r) async {
          await Future<void>.delayed(
            Duration(milliseconds: r.url.host.startsWith('tibyan') ? 100 : 5),
          );
          return http.Response.bytes(List.filled(32768, 0), 206);
        }),
      );
      final reciter = (await FakeRepo().reciters()).first;
      final hosts = c.read(audioHostsProvider.notifier);
      // Not measured yet: the mirror first, as before.
      expect(hosts.urls(reciter, 2).first.host, 'tibyan.ahmedhelal.dev');
      await hosts.measure(reciter);
      expect(c.read(audioHostsProvider), {
        'server1.mp3quran.net': AudioHost.source,
      });
      expect(hosts.urls(reciter, 2).map((u) => u.host), [
        'server1.mp3quran.net',
        'tibyan.ahmedhelal.dev',
      ]);
    });
  });

  group('saving while listening', () {
    test('a streamed surah is saved, then plays from the device', () async {
      final root = Directory.systemTemp.createTempSync('audio');
      final bytes = List.filled(5000, 7);
      final (c, audio) = await recitation(
        root: root,
        client: MockClient((r) async {
          // The host test asks for a range; the download for the file.
          if (r.headers['Range'] != null) return http.Response('', 404);
          return http.Response.bytes(bytes, 200);
        }),
      );
      final ctrl = c.read(recitationProvider.notifier);
      await ctrl.play(2);
      expect(audio.loads.last.$1.scheme, 'https');
      final files = c.read(audioFilesProvider);
      while (files.downloading(1, 2)) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(files.file(1, 2).readAsBytesSync(), bytes);
      expect(files.downloaded(1), {2});
      expect(File('${files.file(1, 2).path}.part').existsSync(), isFalse);
      await ctrl.play(2);
      expect(audio.loads.last.$1, files.file(1, 2).uri);
    });

    test(
      'a cut-off stream leaves only a partial file, resumed later',
      () async {
        final root = Directory.systemTemp.createTempSync('audio');
        var calls = 0;
        final client = MockClient.streaming((r, _) async {
          calls++;
          if (calls == 1) {
            // Promises 10 bytes, sends 4.
            return http.StreamedResponse(
              Stream.value([1, 2, 3, 4]),
              200,
              contentLength: 10,
            );
          }
          expect(r.headers['Range'], 'bytes=4-');
          return http.StreamedResponse(
            Stream.value([5, 6, 7, 8, 9, 10]),
            206,
            contentLength: 6,
          );
        });
        final files = AudioFiles(root);
        final reciter = (await FakeRepo().reciters()).first;
        await expectLater(
          files.download(reciter, 2, client: client),
          throwsA(isA<HttpException>()),
        );
        expect(files.has(1, 2), isFalse);
        expect(files.downloaded(1), isEmpty);
        // Two at once share one download.
        await Future.wait([
          files.download(reciter, 2, client: client),
          files.download(reciter, 2, client: client),
        ]);
        expect(calls, 2);
        expect(files.file(1, 2).readAsBytesSync(), [
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
        ]);
      },
    );
  });

  group('kept for the next time', () {
    test('repeat, silence and the rest come back after a restart', () async {
      final (c, _) = await recitation(prefs: const {});
      // Half a second between verses unless the reader changes it.
      expect(c.read(settingsProvider).versePause, 500);
      final ctrl = c.read(recitationProvider.notifier);
      expect(c.read(recitationProvider).repeat, 1);
      ctrl.setRepeat(5);
      ctrl.setSilence(const Duration(seconds: 10));
      await ctrl.changeReciter(3);
      await c.read(settingsProvider.notifier).setVersePause(1000);
      await c.read(settingsProvider.notifier).setFollowRecitation(false);
      await ctrl.stop();
      expect(c.read(recitationProvider).repeat, 5);

      final sp = await SharedPreferences.getInstance();
      final (again, _) = await recitation(
        prefs: {for (final k in sp.getKeys()) k: sp.get(k)!},
      );
      final s = again.read(settingsProvider);
      expect(s.reciterId, 3);
      expect(s.repeat, 5);
      expect(s.repeatSilence, 10);
      expect(s.versePause, 1000);
      expect(s.followRecitation, isFalse);
      final r = again.read(recitationProvider);
      expect(r.repeat, 5);
      expect(r.silence, const Duration(seconds: 10));
    });

    testWidgets('a verse listened to alone keeps the repeat set', (
      tester,
    ) async {
      final (c, _) = await recitation(prefs: {'settings.repeat': 3});
      await c.read(recitationProvider.notifier).play(2, from: 2);
      expect(c.read(recitationProvider).repeat, 3);
    });
  });

  test('the player sheet wears the player colours, readable everywhere', () {
    final failures = <String>[];
    for (final style in registry.styles) {
      for (final MapEntry(key: mode, value: t) in style.modes.entries) {
        final theme = playerPanelTheme(
          buildTheme(style: style, mode: mode, uiFont: UiFont.changa),
          t,
        );
        expect(theme.colorScheme.surface, t.player);
        expect(theme.colorScheme.onSurface, t.playerFg);
        expect(theme.colorScheme.primary, t.playerFg);
        for (final (name, fg, min) in [
          ('text', t.playerFg, 4.5),
          ('secondary text', playerPanelMuted(t), 4.5),
          ('selected chip label', t.player, 4.5),
        ]) {
          final bg = name == 'selected chip label' ? t.playerFg : t.player;
          final ratio = contrastRatio(fg, bg);
          if (ratio < min) {
            failures.add('${style.id}/${mode.name} $name: $ratio');
          }
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  testWidgets('the sheet and the settings page show the options', (
    tester,
  ) async {
    final (c, audio) = await recitation();
    final style = registry.byId('mamluk');
    // Tall enough for the whole sheet.
    tester.view.physicalSize = const Size(1200, 4000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTheme(
            style: style,
            mode: ThemeModeId.night,
            uiFont: UiFont.changa,
          ),
          home: const PlayerSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Settings: what is kept, not the sleep timer.
    expect(find.text('عدد مرات التكرار'), findsOneWidget);
    expect(find.text('مؤقت النوم'), findsNothing);
    await tester.tap(find.text('×٣'));
    await tester.pump();
    expect(c.read(settingsProvider).repeat, 3);

    await c.read(recitationProvider.notifier).play(2, from: 2);
    final context = tester.element(find.byType(PlayerSettingsScreen));
    unawaited(showPlayerSheet(context));
    await tester.pumpAndSettle();
    expect(find.text('مؤقت النوم'), findsOneWidget);
    expect(find.text('كرر هذه الآية'), findsOneWidget);
    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.backgroundColor, style.modes[ThemeModeId.night]!.player);
  });

  testWidgets('another riwaya\'s reciters are shown greyed out', (
    tester,
  ) async {
    final (c, _) = await recitation();
    tester.view.physicalSize = const Size(1200, 4000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTheme(
            style: registry.byId('mamluk'),
            mode: ThemeModeId.light,
            uiFont: UiFont.changa,
          ),
          home: const PlayerSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('قرّاء الروايات الأخرى'), findsOneWidget);
    RadioListTile<int> tile(String name) => tester.widget(
      find.ancestor(
        of: find.textContaining(name),
        matching: find.byType(RadioListTile<int>),
      ),
    );
    expect(tile('قارئ 1').enabled, isNot(false));
    expect(tile('قارئ ورش').enabled, isFalse);
    await tester.tap(find.textContaining('قارئ ورش'), warnIfMissed: false);
    await tester.pump();
    expect(c.read(settingsProvider).reciterId, isNot(101));
  });
}
