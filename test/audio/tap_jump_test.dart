import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/audio/recitation.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/settings/player_settings_screen.dart';
import 'package:tibyan/l10n/app_localizations.dart';

import 'player_test.dart' show FakeAudio, FakeRepo;

/// [FakeRepo] with word timings for reciter 1: words 1 to 3 of each verse,
/// 2 s apart from the verse's speech (1 s in); later words are untimed.
class WordRepo extends FakeRepo {
  @override
  Future<List<WordTimingRow>> wordTimings(int reciter, int surah) async => [
    if (reciter == 1)
      for (var a = 1; a <= FakeRepo.verses; a++)
        for (var w = 1; w <= 3; w++)
          WordTimingRow(
            reciter: reciter,
            surah: surah,
            ayah: a,
            word: w,
            startMs: (a - 1) * 10000 + 1000 + (w - 1) * 2000,
            endMs: (a - 1) * 10000 + 2800 + (w - 1) * 2000,
          ),
  ];
}

late ThemeRegistry registry;

Future<(ProviderContainer, FakeAudio)> recitation({
  Map<String, Object> prefs = const {},
  MushafRepository? repo,
}) async {
  SharedPreferences.setMockInitialValues({'settings.versePause': 0, ...prefs});
  final sp = await SharedPreferences.getInstance();
  final audio = FakeAudio();
  final c = ProviderContainer(
    overrides: [
      themeRegistryProvider.overrideWithValue(registry),
      sharedPreferencesProvider.overrideWithValue(sp),
      mushafRepositoryProvider.overrideWithValue(repo ?? FakeRepo()),
      packRootProvider.overrideWithValue(
        Directory.systemTemp.createTempSync('audio'),
      ),
      recitationAudioProvider.overrideWithValue(() => audio),
      audioHttpClientProvider.overrideWithValue(
        MockClient((_) async => http.Response('', 404)),
      ),
    ],
  );
  addTearDown(c.dispose);
  return (c, audio);
}

/// A tap on a verse while listening ([RecitationController.jumpTo]).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => registry = await ThemeRegistry.load(rootBundle));

  testWidgets('a verse of the surah playing: seeks there and plays on', (
    tester,
  ) async {
    final (c, audio) = await recitation();
    final ctrl = c.read(recitationProvider.notifier);
    await ctrl.play(2, from: 1);
    audio.at(3000);
    expect(await ctrl.jumpTo(2, 4), VerseJump.jumped);
    expect(audio.seeks.last, const Duration(milliseconds: 30000));
    expect(audio.loads, hasLength(1), reason: 'the same file');
    expect(c.read(recitationProvider).ayah, 4);
    expect(audio.playing, isTrue);
    // The highlight follows the recitation from there.
    audio.at(41000);
    expect(c.read(recitationProvider).ayah, 5);
  });

  testWidgets('paused, the recitation plays from the verse tapped', (
    tester,
  ) async {
    final (c, audio) = await recitation();
    final ctrl = c.read(recitationProvider.notifier);
    await ctrl.play(2, from: 1);
    await tester.pump();
    await ctrl.toggle();
    await tester.pump();
    expect(audio.playing, isFalse);
    expect(c.read(recitationProvider).playing, isFalse);
    expect(await ctrl.jumpTo(2, 3), VerseJump.jumped);
    expect(audio.seeks.last, const Duration(milliseconds: 20000));
    expect(audio.playing, isTrue);
    await tester.pump();
    expect(c.read(recitationProvider).playing, isTrue);
  });

  testWidgets('a verse of another surah loads that surah at the verse', (
    tester,
  ) async {
    final (c, audio) = await recitation();
    final ctrl = c.read(recitationProvider.notifier);
    await ctrl.play(2, from: 4);
    expect(await ctrl.jumpTo(3, 2), VerseJump.jumped);
    expect(audio.loads, hasLength(2));
    expect(audio.loads.last.$1.path, endsWith('003.mp3'));
    expect(audio.loads.last.$2, const Duration(milliseconds: 10000));
    final s = c.read(recitationProvider);
    expect((s.surah, s.ayah), (3, 2));
    expect(audio.playing, isTrue);
  });

  testWidgets('inside the stretch repeated: it jumps and keeps the stretch', (
    tester,
  ) async {
    final (c, audio) = await recitation();
    final ctrl = c.read(recitationProvider.notifier);
    await ctrl.play(2, from: 2, to: 4, repeat: 3);
    expect(await ctrl.jumpTo(2, 3), VerseJump.jumped);
    var s = c.read(recitationProvider);
    expect((s.rangeFrom, s.rangeTo, s.repeat), (2, 4, 3));
    expect(audio.seeks.last, const Duration(milliseconds: 20000));
    // At the stretch's end it starts again from its first verse.
    audio.at(39970);
    await tester.pump();
    s = c.read(recitationProvider);
    expect(s.repeatDone, 1);
    expect(audio.seeks.last, const Duration(milliseconds: 10000));
  });

  testWidgets('outside the stretch: it is dropped, each verse as set', (
    tester,
  ) async {
    final (c, audio) = await recitation(prefs: {'settings.repeat': 2});
    final ctrl = c.read(recitationProvider.notifier);
    await ctrl.play(2, from: 2, to: 3, repeat: 5);
    expect(await ctrl.jumpTo(2, 5), VerseJump.jumped);
    final s = c.read(recitationProvider);
    expect((s.rangeFrom, s.rangeTo), (null, null));
    expect(s.repeat, 2, reason: 'the reader\'s repeat count, not the range\'s');
    expect(s.repeatDone, 0);
    expect(audio.seeks.last, const Duration(milliseconds: 40000));
  });

  testWidgets('a stretch of another surah is dropped too', (tester) async {
    final (c, audio) = await recitation();
    final ctrl = c.read(recitationProvider.notifier);
    await ctrl.play(2, from: 2, to: 3, repeat: 0);
    expect(await ctrl.jumpTo(5, 1), VerseJump.jumped);
    final s = c.read(recitationProvider);
    expect((s.surah, s.ayah, s.rangeTo, s.repeat), (5, 1, null, 1));
    expect(audio.loads.last.$2, Duration.zero);
  });

  testWidgets('repeating each verse goes on applying after the jump', (
    tester,
  ) async {
    final (c, audio) = await recitation(prefs: {'settings.repeat': 2});
    final ctrl = c.read(recitationProvider.notifier);
    await ctrl.play(2, from: 1);
    audio.at(9970);
    await tester.pump();
    expect(c.read(recitationProvider).repeatDone, 1);
    expect(await ctrl.jumpTo(2, 3), VerseJump.jumped);
    expect(c.read(recitationProvider).repeatDone, 0);
    audio.at(25000);
    audio.at(29970); // the end of verse 3
    await tester.pump();
    expect(c.read(recitationProvider).repeatDone, 1);
    expect(audio.seeks.last, const Duration(milliseconds: 20000));
  });

  testWidgets('a stretch played to its end starts again from the tap', (
    tester,
  ) async {
    final (c, audio) = await recitation();
    final ctrl = c.read(recitationProvider.notifier);
    await ctrl.play(2, from: 2, to: 3, repeat: 1);
    audio.at(29970);
    await tester.pump();
    expect(audio.playing, isFalse, reason: 'the stretch is done');
    expect(await ctrl.jumpTo(2, 2), VerseJump.jumped);
    expect(c.read(recitationProvider).repeatDone, 0);
    expect(audio.playing, isTrue);
    expect(audio.seeks.last, const Duration(milliseconds: 10000));
  });

  testWidgets('no verse timings: nothing moves, the recitation plays on', (
    tester,
  ) async {
    final (c, audio) = await recitation(prefs: {'settings.reciterId': 3});
    final ctrl = c.read(recitationProvider.notifier);
    await ctrl.play(2);
    expect(c.read(recitationProvider).timed, isFalse);
    expect(await ctrl.jumpTo(2, 3), VerseJump.noTiming);
    expect(await ctrl.jumpTo(4, 1), VerseJump.noTiming);
    expect(audio.seeks, isEmpty);
    expect(audio.loads, hasLength(1));
    expect(c.read(recitationProvider).surah, 2);
    expect(audio.playing, isTrue);
  });

  testWidgets('from the word: its timing when it has one, else the verse', (
    tester,
  ) async {
    final (c, audio) = await recitation(repo: WordRepo());
    final ctrl = c.read(recitationProvider.notifier);
    await ctrl.play(2, from: 1);
    expect(await ctrl.jumpTo(2, 3, word: 2), VerseJump.jumped);
    expect(audio.seeks.last, const Duration(milliseconds: 23000));
    // Word 7 has no timing: the verse's start.
    expect(await ctrl.jumpTo(2, 4, word: 7), VerseJump.jumped);
    expect(audio.seeks.last, const Duration(milliseconds: 30000));
    // Another surah: loaded at the word.
    expect(await ctrl.jumpTo(4, 2, word: 3), VerseJump.jumped);
    expect(audio.loads.last.$2, const Duration(milliseconds: 15000));
    expect(c.read(recitationProvider).ayah, 2);
  });

  testWidgets('a reciter without word timings starts at the verse', (
    tester,
  ) async {
    final (c, audio) = await recitation();
    final ctrl = c.read(recitationProvider.notifier);
    await ctrl.play(2, from: 1);
    expect(await ctrl.jumpTo(2, 3, word: 2), VerseJump.jumped);
    expect(audio.seeks.last, const Duration(milliseconds: 20000));
  });

  testWidgets('not listening: a tap is not a jump', (tester) async {
    final (c, audio) = await recitation();
    final ctrl = c.read(recitationProvider.notifier);
    expect(await ctrl.jumpTo(2, 3), VerseJump.ignored);
    expect(audio.loads, isEmpty);
    expect(c.read(recitationProvider).active, isFalse);
  });

  test('where the tap starts is kept for the next time', () async {
    final (c, _) = await recitation();
    expect(c.read(settingsProvider).tapJumpFromWord, isFalse);
    await c.read(settingsProvider.notifier).setTapJumpFromWord(true);
    final sp = await SharedPreferences.getInstance();
    final (again, _) = await recitation(
      prefs: {for (final k in sp.getKeys()) k: sp.get(k)!},
    );
    expect(again.read(settingsProvider).tapJumpFromWord, isTrue);
  });

  testWidgets('the listening settings offer where a tap starts', (
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
    expect(find.text('عند لمس آية أثناء الاستماع'), findsOneWidget);
    ChoiceChip chip(String label) => tester.widget(
      find.ancestor(of: find.text(label), matching: find.byType(ChoiceChip)),
    );
    expect(chip('من أول الآية').selected, isTrue);
    await tester.tap(find.text('من الكلمة الملموسة'));
    await tester.pump();
    expect(c.read(settingsProvider).tapJumpFromWord, isTrue);
    expect(chip('من الكلمة الملموسة').selected, isTrue);
  });
}
