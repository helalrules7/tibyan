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
      await browser.play('play/3/999'); // ignored
      await browser.play('nonsense'); // ignored
      expect(played, ['3/36/null', 'null/18/10']);
    },
  );
}
