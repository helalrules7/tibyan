import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_background/just_audio_background.dart';

class _Browser extends MediaBrowserDelegate {
  @override
  Future<List<MediaItem>> children(String parentMediaId) async => [
    MediaItem(id: '$parentMediaId/1', title: 'x'),
  ];

  @override
  Future<void> play(String mediaId) async {}
}

/// Android Auto binds the audio service before the app has set its
/// browser (a car started the app without its screen).
void main() {
  setUp(JustAudioBackground.reset);
  tearDown(() => JustAudioBackground.browserWait = const Duration(seconds: 20));

  test('a request made before the browser is set waits for it', () async {
    final early = JustAudioBackground.carChildren('root');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    JustAudioBackground.browser = _Browser();
    expect((await early).single.id, 'root/1');
  });

  test('lists asked for early are reloaded once the browser is set', () async {
    final changes = <Map<String, dynamic>>[];
    JustAudioBackground.childrenChanged('root').listen(changes.add);
    JustAudioBackground.browser = _Browser();
    await Future<void>.delayed(Duration.zero);
    expect(changes, hasLength(1));
  });

  test(
    'no browser at all: an empty answer after the wait, not a hang',
    () async {
      JustAudioBackground.browserWait = const Duration(milliseconds: 20);
      expect(await JustAudioBackground.carChildren('root'), isEmpty);
    },
  );
}
