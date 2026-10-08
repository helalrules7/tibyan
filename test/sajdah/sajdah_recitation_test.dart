import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/features/audio/recitation.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/sajdah/sajdah_card.dart';
import 'package:tibyan/features/sajdah/sajdah_positions.dart';

import '../audio/player_test.dart' show FakeAudio, FakeRepo;

late ThemeRegistry registry;

/// A recitation of the fake five-verse surahs (verses of 10 s), with
/// verses of prostration at 2:2 and 2:5 (the surah's last).
Future<(ProviderContainer, FakeAudio)> recitation({
  bool on = true,
  int repeat = 1,
}) async {
  SharedPreferences.setMockInitialValues({
    'settings.versePause': 0,
    'settings.sajdahTimer': on,
    'settings.sajdahSeconds': 10,
    'settings.repeat': repeat,
  });
  final sp = await SharedPreferences.getInstance();
  final audio = FakeAudio();
  final c = ProviderContainer(
    overrides: [
      themeRegistryProvider.overrideWithValue(registry),
      sharedPreferencesProvider.overrideWithValue(sp),
      mushafRepositoryProvider.overrideWithValue(FakeRepo()),
      packRootProvider.overrideWithValue(
        Directory.systemTemp.createTempSync('sajdah_recitation'),
      ),
      recitationAudioProvider.overrideWithValue(() => audio),
      audioHttpClientProvider.overrideWithValue(
        MockClient((_) async => http.Response('', 404)),
      ),
      sajdahPositionsProvider.overrideWith(
        (ref) async => SajdahPositions(const [
          (surah: 2, ayah: 2),
          (surah: 2, ayah: 5),
        ], List.filled(114, FakeRepo.verses)),
      ),
    ],
  );
  addTearDown(c.dispose);
  return (c, audio);
}

String file(FakeAudio audio) => audio.loads.last.$1.pathSegments.last;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => registry = await ThemeRegistry.load(rootBundle));

  testWidgets(
    'the end of a verse of prostration pauses; the countdown resumes',
    (tester) async {
      final (c, audio) = await recitation();
      await c.read(recitationProvider.notifier).play(2, from: 1);
      audio.at(15000);
      expect(c.read(recitationProvider).ayah, 2);
      expect(c.read(sajdahCardProvider), isNull);
      // Verse 2 ends: paused, with its card.
      audio.at(20100);
      await tester.pump();
      expect(audio.playing, isFalse);
      expect(c.read(sajdahCardProvider)?.verse, (surah: 2, ayah: 2));
      expect(c.read(sajdahCardProvider)?.from, SajdahFrom.listening);
      expect(c.read(recitationProvider).ayah, 2, reason: 'still on verse 2');
      // Positions while it waits change nothing.
      audio.at(20200);
      expect(c.read(recitationProvider).ayah, 2);
      // The countdown ends: on from verse 3's start.
      await tester.pump(const Duration(seconds: 10));
      expect(c.read(sajdahCardProvider), isNull);
      expect(audio.seeks.last, const Duration(milliseconds: 20000));
      expect(audio.playing, isTrue);
      audio.at(20100);
      expect(c.read(recitationProvider).ayah, 3);
      // Once only: verse 4 plays on.
      audio.at(30100);
      await tester.pump();
      expect(c.read(sajdahCardProvider), isNull);
      expect(audio.playing, isTrue);
    },
  );

  testWidgets('a tap on the card resumes at once', (tester) async {
    final (c, audio) = await recitation();
    await c.read(recitationProvider.notifier).play(2, from: 2);
    audio.at(15000);
    audio.at(20100);
    await tester.pump();
    expect(c.read(sajdahCardProvider), isNotNull);
    c.read(sajdahCardProvider.notifier).close();
    await tester.pump();
    expect(audio.playing, isTrue);
    audio.at(20100);
    expect(c.read(recitationProvider).ayah, 3);
    // Its countdown does not resume a second time later.
    final seeks = audio.seeks.length;
    await tester.pump(const Duration(seconds: 10));
    expect(audio.seeks.length, seeks);
  });

  testWidgets('a repeated verse: the card after its last repetition only', (
    tester,
  ) async {
    final (c, audio) = await recitation(repeat: 2);
    await c.read(recitationProvider.notifier).play(2, from: 2);
    audio.at(15000);
    // First time through: it plays again, no card.
    audio.at(19980);
    await tester.pump();
    expect(c.read(sajdahCardProvider), isNull);
    expect(audio.seeks.last, const Duration(milliseconds: 10000));
    // Second time: done, on into verse 3, and there the card.
    audio.at(15000);
    audio.at(19980);
    await tester.pump();
    expect(c.read(sajdahCardProvider), isNull);
    audio.at(20100);
    await tester.pump();
    expect(c.read(sajdahCardProvider)?.verse, (surah: 2, ayah: 2));
    expect(audio.playing, isFalse);
    await tester.pump(const Duration(seconds: 10));
    expect(audio.playing, isTrue);
  });

  testWidgets('a surah that ends with one: the card, then the next surah', (
    tester,
  ) async {
    final (c, audio) = await recitation();
    await c.read(recitationProvider.notifier).play(2, from: 5);
    audio.at(45000);
    audio.complete();
    await tester.pump();
    expect(c.read(sajdahCardProvider)?.verse, (surah: 2, ayah: 5));
    expect(file(audio), '002.mp3', reason: 'the next surah waits');
    await tester.pump(const Duration(seconds: 10));
    expect(file(audio), '003.mp3');
    expect(c.read(recitationProvider).surah, 3);
  });

  testWidgets('playing during the card goes on and takes the card away', (
    tester,
  ) async {
    final (c, audio) = await recitation();
    final ctrl = c.read(recitationProvider.notifier);
    await ctrl.play(2, from: 2);
    audio.at(15000);
    audio.at(20100);
    await tester.pump();
    expect(c.read(sajdahCardProvider), isNotNull);
    await ctrl.toggle();
    await tester.pump();
    expect(c.read(sajdahCardProvider), isNull);
    expect(audio.playing, isTrue);
    expect(audio.seeks.last, const Duration(milliseconds: 20000));
    // Stopping during a card takes it away too.
    await ctrl.play(2, from: 2);
    audio.at(15000);
    audio.at(20100);
    await tester.pump();
    expect(c.read(sajdahCardProvider), isNotNull);
    await ctrl.stop();
    expect(c.read(sajdahCardProvider), isNull);
  });

  testWidgets('with the timer off, or in a hifz test, nothing happens', (
    tester,
  ) async {
    final (c, audio) = await recitation(on: false);
    await c.read(recitationProvider.notifier).play(2, from: 2);
    audio.at(15000);
    audio.at(20100);
    await tester.pump();
    expect(c.read(sajdahCardProvider), isNull);
    expect(audio.playing, isTrue);
    expect(c.read(recitationProvider).ayah, 3);

    final (t, testAudio) = await recitation();
    t.read(sajdahMutedProvider.notifier).set(true);
    await t.read(recitationProvider.notifier).play(2, from: 2);
    testAudio.at(15000);
    testAudio.at(20100);
    await tester.pump();
    expect(t.read(sajdahCardProvider), isNull);
    expect(t.read(recitationProvider).ayah, 3);
  });
}
