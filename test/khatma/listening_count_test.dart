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
import 'package:tibyan/features/khatma/khatma_providers.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';

import '../audio/player_test.dart' show FakeAudio, FakeRepo;

/// The recitation's verses heard to their end, as the khatma gets them.
class _Heard extends KhatmaService {
  _Heard(super.ref);

  final heard = <(int, int)>[];
  final playing = <bool>[];

  @override
  Future<void> verseRecited(int surah, int ayah) async =>
      heard.add((surah, ayah));

  @override
  void recitationPlaying(bool on) => playing.add(on);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ThemeRegistry registry;
  setUpAll(() async => registry = await ThemeRegistry.load(rootBundle));

  Future<(ProviderContainer, FakeAudio, _Heard)> setUpRecitation() async {
    SharedPreferences.setMockInitialValues({'settings.versePause': 0});
    final sp = await SharedPreferences.getInstance();
    final audio = FakeAudio();
    late _Heard service;
    final c = ProviderContainer(
      overrides: [
        themeRegistryProvider.overrideWithValue(registry),
        sharedPreferencesProvider.overrideWithValue(sp),
        mushafRepositoryProvider.overrideWithValue(FakeRepo()),
        packRootProvider.overrideWithValue(
          Directory.systemTemp.createTempSync('audio'),
        ),
        recitationAudioProvider.overrideWithValue(() => audio),
        audioHttpClientProvider.overrideWithValue(
          MockClient((_) async => http.Response('', 404)),
        ),
        khatmaServiceProvider.overrideWith((ref) => service = _Heard(ref)),
      ],
    );
    addTearDown(c.dispose);
    c.read(khatmaServiceProvider);
    return (c, audio, service);
  }

  testWidgets('scenario 9: verses heard to their end count; a verse stepped '
      'or jumped over does not', (tester) async {
    final (c, audio, service) = await setUpRecitation();
    final ctrl = c.read(recitationProvider.notifier);
    await ctrl.play(2, from: 1);
    await tester.pump();
    expect(service.playing.last, isTrue);
    audio.at(5000);
    audio.at(10500); // verse 1 ended by itself
    expect(service.heard, [(2, 1)]);
    // The reader steps from verse 2 to 3: verse 2 is skipped.
    await ctrl.step(1);
    audio.at(20500);
    expect(c.read(recitationProvider).ayah, 3);
    expect(service.heard, [(2, 1)]);
    // Verse 3 plays to its end.
    audio.at(30500);
    expect(service.heard, [(2, 1), (2, 3)]);
    // A tap on verse 5 jumps over verse 4.
    await ctrl.jumpTo(2, 5);
    audio.at(40500);
    expect(service.heard, [(2, 1), (2, 3)]);
    // The surah's last verse ends with the file.
    audio.at(49900);
    audio.complete();
    await tester.pump();
    expect(service.heard, [(2, 1), (2, 3), (2, 5)]);
  });
}
