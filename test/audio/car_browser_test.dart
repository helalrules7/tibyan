import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/audio/car_browser.dart';

void main() {
  final played = <String>[];
  final browser = CarBrowser(
    reciters: () async => const [
      ReciterRow(
        id: 3,
        nameAr: 'الحصري',
        nameEn: 'al-Husary',
        style: 'murattal',
        folderUrl: '',
        sourceId: 1,
        riwaya: 'hafs',
      ),
    ],
    surahs: () async => [
      for (var i = 1; i <= 114; i++)
        SurahRow(
          id: i,
          nameAr: 'س$i',
          nameEn: 'S$i',
          meaningEn: '',
          revelation: 'meccan',
          revelationOrder: i,
          ayahCount: 7,
          startPage: i,
          startPage1405: i,
          sourceId: 1,
          startPageShamarly: i,
        ),
    ],
    position: () async => (surah: 18, ayah: 10),
    start: ({int? reciter, required int surah, int? ayah}) async =>
        played.add('$reciter/$surah/$ayah'),
    text: CarText(
      continueReading: 'تابع',
      reciters: 'القراء',
      surah: (n, name) => '$n. $name',
      unavailable: 'تعذر',
      playbackError: 'تعذر التشغيل',
    ),
  );

  setUp(played.clear);

  test('the top: continue, and the reciters', () async {
    final top = await browser.children(CarBrowser.root);
    expect(top.map((i) => (i.id, i.playable)), [
      ('continue', true),
      ('reciters', false),
    ]);
  });

  test('a reciter lists the 114 surahs, each playable', () async {
    expect((await browser.children('reciters')).single.id, 'reciter/3');
    final surahs = await browser.children('reciter/3');
    expect(surahs, hasLength(114));
    expect(surahs.first.id, 'play/3/1');
    expect(surahs.first.title, '1. س1');
    expect(surahs.first.playable, isTrue);
  });

  test(
    'playing: a surah by its reciter, or continue from the position',
    () async {
      await browser.play('play/3/36');
      await browser.play('continue');
      await expectLater(browser.play('play/3/999'), throwsArgumentError);
      await expectLater(browser.play('nonsense'), throwsArgumentError);
      expect(played, ['3/36/null', 'null/18/10']);
    },
  );

  CarBrowser broken({
    Future<List<ReciterRow>> Function()? reciters,
    Future<({int surah, int ayah})?> Function()? position,
  }) => CarBrowser(
    reciters: reciters ?? () async => const [],
    surahs: () async => const [],
    position: position ?? () async => null,
    start: ({int? reciter, required int surah, int? ayah}) async =>
        played.add('$reciter/$surah/$ayah'),
    text: browser.text,
  );

  test('no reciters: one message item, never an empty list', () async {
    final items = await broken().children('reciters');
    expect(items.single.id, CarBrowser.unavailableId);
    expect(items.single.title, 'تعذر');
    expect(items.single.playable, isFalse);
  });

  test('a list that fails to load shows the message', () async {
    final b = broken(reciters: () async => throw StateError('db'));
    expect((await b.children('reciters')).single.id, CarBrowser.unavailableId);
    expect((await b.children('reciter/3')).single.id, CarBrowser.unavailableId);
    // The top never depends on the content.
    expect(await b.children(CarBrowser.root), hasLength(2));
  });

  test('an unknown reciter shows the message', () async {
    expect(
      (await browser.children('reciter/77')).single.id,
      CarBrowser.unavailableId,
    );
  });

  test('continue with no reading position yet starts Al-Fatiha', () async {
    await broken().play('continue');
    await broken(position: () async => throw StateError('x')).play('continue');
    expect(played, ['null/1/null', 'null/1/null']);
  });

  test('the playback error text comes from CarText', () {
    expect(browser.playbackError, 'تعذر التشغيل');
  });
}
