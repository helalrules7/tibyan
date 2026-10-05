import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:tibyan/features/audio/car_browser.dart';
import 'package:tibyan/features/audio/car_channel.dart';

/// A browser with a top and one reciter, recording what is asked and played.
class _Browser implements MediaBrowserDelegate {
  final played = <String>[];
  final asked = <String>[];

  @override
  Future<List<MediaItem>> children(String parentMediaId) async {
    asked.add(parentMediaId);
    return switch (parentMediaId) {
      CarBrowser.root => const [
        MediaItem(id: 'continue', title: 'تابع', playable: true),
        MediaItem(id: 'reciters', title: 'القراء', playable: false),
      ],
      'reciter/3' => const [
        MediaItem(id: 'play/3/1', title: '1. الفاتحة', artist: 'الحصري'),
        MediaItem(id: 'play/3/2', title: '2. البقرة', artist: 'الحصري'),
      ],
      _ => const [],
    };
  }

  @override
  Future<void> play(String mediaId) async => played.add(mediaId);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const codec = StandardMethodCodec();
  const channel = MethodChannel(CarChannel.name);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late _Browser browser;
  late List<String> toNative;

  setUp(() {
    browser = _Browser();
    toNative = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      toNative.add(call.method);
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  /// The raw reply the CarPlay scene receives when it calls [method].
  Future<ByteData?> send(String method, [Object? arguments]) =>
      messenger.handlePlatformMessage(
        CarChannel.name,
        codec.encodeMethodCall(MethodCall(method, arguments)),
        (_) {},
      );

  /// What the CarPlay scene receives when it calls [method].
  Future<Object?> fromCar(String method, [Object? arguments]) async =>
      codec.decodeEnvelope((await send(method, arguments))!);

  test('attaching tells the car side it is ready', () async {
    await CarChannel(browser).attach();
    expect(toNative, ['ready']);
  });

  test('attaching without a native side does not throw', () async {
    messenger.setMockMethodCallHandler(channel, null);
    await expectLater(CarChannel(browser).attach(), completes);
  });

  test("children: the browser's items as plain maps", () async {
    await CarChannel(browser).attach();

    expect(await fromCar('children', 'root'), [
      {'id': 'continue', 'title': 'تابع', 'playable': true},
      {'id': 'reciters', 'title': 'القراء', 'playable': false},
    ]);
    expect(await fromCar('children', 'reciter/3'), [
      {
        'id': 'play/3/1',
        'title': '1. الفاتحة',
        'subtitle': 'الحصري',
        'playable': true,
      },
      {
        'id': 'play/3/2',
        'title': '2. البقرة',
        'subtitle': 'الحصري',
        'playable': true,
      },
    ]);
    expect(await fromCar('children', 'nothing'), isEmpty);
    // No id means the top.
    await fromCar('children');
    expect(browser.asked, ['root', 'reciter/3', 'nothing', 'root']);
  });

  test('play: routed to the browser', () async {
    await CarChannel(browser).attach();
    expect(await fromCar('play', 'play/3/2'), isNull);
    expect(await fromCar('play', 'continue'), isNull);
    await fromCar('play'); // no id: ignored
    expect(browser.played, ['play/3/2', 'continue']);
  });

  test('an unknown call is not implemented', () async {
    await CarChannel(browser).attach();
    expect(await send('eject'), isNull);
  });

  test('the real CarBrowser through the channel', () async {
    final played = <String>[];
    final car = CarBrowser(
      reciters: () async => const [],
      surahs: () async => const [],
      position: () async => (surah: 18, ayah: 10),
      start: ({int? reciter, required int surah, int? ayah}) async =>
          played.add('$reciter/$surah/$ayah'),
      text: CarText(
        continueReading: 'تابع من موضع القراءة',
        reciters: 'القراء',
        surah: (n, name) => '$n. $name',
      ),
    );
    await CarChannel(car).attach();
    expect(await fromCar('children', 'root'), [
      {'id': 'continue', 'title': 'تابع من موضع القراءة', 'playable': true},
      {'id': 'reciters', 'title': 'القراء', 'playable': false},
    ]);
    await fromCar('play', 'play/7/36');
    await fromCar('play', 'continue');
    expect(played, ['7/36/null', 'null/18/10']);
  });
}
