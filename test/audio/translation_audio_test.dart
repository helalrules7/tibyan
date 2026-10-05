import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/flags/feature_flags.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/audio/player_bar.dart';
import 'package:tibyan/features/audio/recitation.dart';
import 'package:tibyan/features/audio/verse_queue.dart';
import 'package:tibyan/features/content_extras/credits.dart';
import 'package:tibyan/features/content_extras/verse_audio_index.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/settings/player_settings_screen.dart';
import 'package:tibyan/l10n/app_localizations.dart';

import 'player_test.dart' show FakeAudio, FakeRepo;

VerseAudioIndex fixture(String name) => VerseAudioIndex.parse(
  File('test/fixtures/audio_content/$name.json').readAsStringSync(),
);

/// A player whose loads of [failing] hosts fail, like an unreachable clip.
class FlakyAudio extends FakeAudio {
  FlakyAudio(this.failing);
  final String failing;

  @override
  Future<void> load(Uri uri, MediaItem tag, Duration initial) async {
    if (uri.host == failing) throw const SocketException('unreachable');
    return super.load(uri, tag, initial);
  }
}

late ThemeRegistry registry;

/// A recitation wired to fakes, with the English translation index of the
/// fixture available. [flag]: `translation_audio`; [chosen]: the reader's
/// «الترجمة المسموعة بعد كل آية».
Future<(ProviderContainer, FakeAudio)> recitation({
  bool flag = true,
  bool chosen = true,
  FakeAudio? player,
}) async {
  SharedPreferences.setMockInitialValues({
    'settings.versePause': 0,
    TranslationAudioChoice.key: chosen,
  });
  final sp = await SharedPreferences.getInstance();
  final audio = player ?? FakeAudio();
  final c = ProviderContainer(
    overrides: [
      themeRegistryProvider.overrideWithValue(registry),
      sharedPreferencesProvider.overrideWithValue(sp),
      mushafRepositoryProvider.overrideWithValue(FakeRepo()),
      packRootProvider.overrideWithValue(
        Directory.systemTemp.createTempSync('translation_audio'),
      ),
      recitationAudioProvider.overrideWithValue(() => audio),
      audioHttpClientProvider.overrideWithValue(
        MockClient((_) async => http.Response('', 404)),
      ),
      featureFlagsProvider.overrideWithValue(
        FeatureFlags({
          Feature.translationAudio.key: flag,
          Feature.tafsirAudio.key: true,
        }),
      ),
      verseAudioIndexesProvider.overrideWith(
        (ref) async => [
          fixture('rwwad_translation_sample'),
          fixture('nuqayah_per_verse_sample'),
          fixture('nuqayah_per_surah_sample'),
        ],
      ),
    ],
  );
  addTearDown(c.dispose);
  return (c, audio);
}

String file(FakeAudio audio) => audio.loads.last.$1.pathSegments.last;
Duration at(FakeAudio audio) => audio.loads.last.$2;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => registry = await ThemeRegistry.load(rootBundle));

  group('the queue', () {
    final index = fixture('rwwad_translation_sample');

    test('each verse is followed by its translation when the index has it', () {
      final q = buildVerseQueue(surah: 2, from: 1, to: 5, after: index);
      expect(
        [
          for (final i in q)
            i is ClipItem
                ? 'T${i.ayah}:${i.clip.uri.pathSegments.last}'
                : 'V${i.ayah}',
        ],
        [
          'V1', 'T1:002001.mp3', 'V2', 'T2:002002.mp3', 'V3', //
          'T3:002003.mp3', 'V4', 'V5', 'T5:002005.mp3',
        ],
      );
      final after = clipsAfterVerses(q);
      expect(after.keys, [1, 2, 3, 5]);
      expect(after[4], isNull, reason: 'the index has no 2:4');
    });

    test('without an index, only the verses', () {
      expect(buildVerseQueue(surah: 2, from: 2, to: 3), [
        const VerseItem(2, 2),
        const VerseItem(2, 3),
      ]);
      expect(clipsAfterVerses(buildVerseQueue(surah: 2, from: 1, to: 5)), {});
    });

    test('a per-surah file is a clip only with verse offsets', () {
      final saadi = fixture('nuqayah_per_surah_sample');
      final q = buildVerseQueue(surah: 2, from: 1, to: 3, after: saadi);
      final clips = [
        for (final i in q)
          if (i is ClipItem) i,
      ];
      expect([for (final c in clips) c.ayah], [1, 2]);
      expect(clips[1].clip.start, const Duration(milliseconds: 42000));
      expect(clips[1].clip.end, const Duration(milliseconds: 90500));
      // Surah 3 has a file but no offsets: no verse clips there.
      expect(buildVerseQueue(surah: 3, from: 1, to: 2, after: saadi), [
        const VerseItem(3, 1),
        const VerseItem(3, 2),
      ]);
    });
  });

  group('translation after each verse', () {
    testWidgets('plays between the verses, then the next surah', (
      tester,
    ) async {
      final (c, audio) = await recitation();
      final ctrl = c.read(recitationProvider.notifier);
      await ctrl.play(2, from: 1);
      expect(file(audio), '002.mp3');
      audio.at(5000);
      expect(c.read(recitationProvider).ayah, 1);
      // Verse 2 begins: verse 1's translation plays first.
      audio.at(10100);
      await tester.pump();
      expect(file(audio), '002001.mp3');
      expect(audio.loads.last.$1.host, 'd.quranenc.com');
      var s = c.read(recitationProvider);
      expect(s.clip?.kind, VerseAudioKind.translation);
      expect(s.clip?.ayah, 1);
      expect(s.clip?.source, ContentSources.quranEncRwwadAudio);
      expect(s.ayah, 1, reason: 'the verse stays marked during it');
      expect(audio.playing, isTrue);
      // Positions of the clip are not the surah's.
      audio.at(30000);
      expect(c.read(recitationProvider).ayah, 1);
      // It ends: the recitation goes on from verse 2.
      audio.complete();
      await tester.pump();
      expect(file(audio), '002.mp3');
      expect(at(audio), const Duration(milliseconds: 10000));
      s = c.read(recitationProvider);
      expect(s.clip, isNull);
      expect(s.ayah, 2);

      // 2 and 3 have translations, 4 has none: 4 runs into 5.
      for (final v in [2, 3]) {
        audio.at(v * 10000 + 100);
        await tester.pump();
        expect(file(audio), '00200$v.mp3');
        audio.complete();
        await tester.pump();
        expect(at(audio), Duration(milliseconds: v * 10000));
      }
      final loads = audio.loads.length;
      audio.at(40100);
      await tester.pump();
      expect(audio.loads.length, loads);
      expect(c.read(recitationProvider).ayah, 5);
      // The surah ends: the last verse's translation, then surah 3.
      audio.at(45000);
      audio.complete();
      await tester.pump();
      expect(file(audio), '002005.mp3');
      audio.complete();
      await tester.pump();
      expect(file(audio), '003.mp3');
      expect(c.read(recitationProvider).surah, 3);
      expect(c.read(recitationProvider).clip, isNull);
    });

    testWidgets('nothing between the verses while the flag is off', (
      tester,
    ) async {
      final (c, audio) = await recitation(flag: false);
      await c.read(recitationProvider.notifier).play(2, from: 1);
      audio.at(10100);
      await tester.pump();
      expect(audio.loads.length, 1);
      expect(c.read(recitationProvider).ayah, 2);
      expect(c.read(recitationProvider).clip, isNull);
    });

    testWidgets('nor until the reader chooses it; chosen, from now on', (
      tester,
    ) async {
      final (c, audio) = await recitation(chosen: false);
      final ctrl = c.read(recitationProvider.notifier);
      await ctrl.play(2, from: 1);
      audio.at(10100);
      await tester.pump();
      expect(audio.loads.length, 1);
      await ctrl.setTranslationAfterVerses(true);
      expect(c.read(translationAudioChoiceProvider), isTrue);
      audio.at(20100);
      await tester.pump();
      expect(file(audio), '002002.mp3');
    });

    testWidgets('nor while a verse or a stretch repeats', (tester) async {
      final (c, audio) = await recitation();
      final ctrl = c.read(recitationProvider.notifier);
      await ctrl.play(2, from: 1, to: 3);
      audio.at(10100);
      await tester.pump();
      expect(audio.loads.length, 1);
    });

    testWidgets('next and previous during it', (tester) async {
      final (c, audio) = await recitation();
      final ctrl = c.read(recitationProvider.notifier);
      await ctrl.play(2, from: 1);
      audio.at(10100);
      await tester.pump();
      expect(file(audio), '002001.mp3');
      await ctrl.step(-1);
      expect(file(audio), '002.mp3');
      expect(at(audio), Duration.zero, reason: 'verse 1 again');
      audio.at(10100);
      await tester.pump();
      await ctrl.step(1);
      expect(at(audio), const Duration(milliseconds: 10000));
      expect(c.read(recitationProvider).clip, isNull);
    });

    testWidgets('a clip that cannot be loaded is skipped', (tester) async {
      final (c, audio) = await recitation(player: FlakyAudio('d.quranenc.com'));
      await c.read(recitationProvider.notifier).play(2, from: 1);
      audio.at(10100);
      await tester.pump();
      expect(file(audio), '002.mp3');
      expect(at(audio), const Duration(milliseconds: 10000));
      expect(c.read(recitationProvider).error, isNull);
      expect(c.read(recitationProvider).clip, isNull);
    });
  });

  group('the option', () {
    Future<void> settingsPage(WidgetTester tester, ProviderContainer c) async {
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
              style: registry.byId(registry.defaultStyleId),
              mode: ThemeModeId.light,
              uiFont: UiFont.plex,
            ),
            home: const PlayerSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('offered with its source while the flag is on', (tester) async {
      final (c, _) = await recitation(chosen: false);
      await settingsPage(tester, c);
      expect(find.text('الترجمة المسموعة بعد كل آية'), findsOneWidget);
      expect(find.textContaining('مركز رواد الترجمة'), findsOneWidget);
      await tester.tap(find.text('الترجمة المسموعة بعد كل آية'));
      await tester.pump();
      expect(c.read(translationAudioChoiceProvider), isTrue);
    });

    testWidgets('not offered while the flag is off', (tester) async {
      final (c, _) = await recitation(flag: false);
      await settingsPage(tester, c);
      expect(find.text('الترجمة المسموعة بعد كل آية'), findsNothing);
    });
  });

  group('tafsir audio', () {
    testWidgets('a verse file plays on its own, then waits', (tester) async {
      final (c, audio) = await recitation();
      final ctrl = c.read(recitationProvider.notifier);
      await ctrl.playTafsir(fixture('nuqayah_per_verse_sample'), 2, 2);
      expect(file(audio), '002002.mp3');
      final s = c.read(recitationProvider);
      expect(s.active, isTrue);
      expect(s.timed, isFalse, reason: 'no verses to step through');
      expect(s.clip?.standalone, isTrue);
      expect(s.clip?.source, ContentSources.nuqayahTafsirAudio);
      audio.complete();
      await tester.pump();
      expect(audio.playing, isFalse);
      expect(audio.seeks.last, Duration.zero);
      expect(audio.loads.length, 1, reason: 'nothing follows a tafsir');
    });

    testWidgets('a verse in a surah file plays between its offsets', (
      tester,
    ) async {
      final (c, audio) = await recitation();
      final ctrl = c.read(recitationProvider.notifier);
      await ctrl.playTafsir(fixture('nuqayah_per_surah_sample'), 2, 2);
      expect(file(audio), '002.mp3');
      expect(audio.loads.last.$1.host, 'audio.example.org');
      expect(at(audio), const Duration(milliseconds: 42000));
      audio.at(60000);
      expect(audio.playing, isTrue);
      audio.at(90500);
      await tester.pump();
      expect(audio.playing, isFalse);
      expect(audio.seeks.last, const Duration(milliseconds: 42000));
      // Played again from its start.
      await ctrl.toggle();
      expect(audio.playing, isTrue);
    });

    testWidgets('a surah file without offsets plays whole', (tester) async {
      final (c, audio) = await recitation();
      await c
          .read(recitationProvider.notifier)
          .playTafsir(fixture('nuqayah_per_surah_sample'), 3, 4);
      expect(file(audio), '003.mp3');
      expect(at(audio), Duration.zero);
      expect(c.read(recitationProvider).clip?.wholeSurah, isTrue);
    });

    testWidgets('the player bar names it and shows its source', (tester) async {
      final (c, _) = await recitation();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildTheme(
              style: registry.byId(registry.defaultStyleId),
              mode: ThemeModeId.light,
              uiFont: UiFont.plex,
            ),
            home: const Scaffold(body: PlayerBar()),
          ),
        ),
      );
      await c
          .read(recitationProvider.notifier)
          .playTafsir(fixture('nuqayah_per_verse_sample'), 2, 1);
      await tester.pumpAndSettle();
      expect(find.textContaining('التفسير الميسر'), findsOneWidget);
      expect(
        find.text(contentCredit(ContentSources.nuqayahTafsirAudio, 'ar')),
        findsOneWidget,
      );
      expect(find.textContaining('بلا إعلانات ولا ربح'), findsOneWidget);
    });

    testWidgets('the player bar shows the translation\'s source', (
      tester,
    ) async {
      final (c, audio) = await recitation();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildTheme(
              style: registry.byId(registry.defaultStyleId),
              mode: ThemeModeId.light,
              uiFont: UiFont.plex,
            ),
            home: const Scaffold(body: PlayerBar()),
          ),
        ),
      );
      await c.read(recitationProvider.notifier).play(2, from: 1);
      audio.at(10100);
      await tester.pumpAndSettle();
      expect(find.textContaining('ترجمة الآية'), findsOneWidget);
      expect(find.textContaining('QuranEnc.com'), findsOneWidget);
    });
  });
}
