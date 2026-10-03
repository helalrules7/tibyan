import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/features/audio/recitation.dart';
import 'package:tibyan/features/mushaf/data/page_pack.dart';
import 'package:tibyan/features/mushaf/data/riwaya_data.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';

/// Pages 1-3 and 230-231 of the Warsh pack's `riwaya.json`, as built by
/// tools/build_riwaya_packs.py (verses, verse map, outlines, line cuts).
String _sample() =>
    File('test/fixtures/riwaya_warsh_sample.json').readAsStringSync();

ReciterRow _reciter(int id, String riwaya) => ReciterRow(
  id: id,
  nameAr: 'قارئ $id',
  nameEn: 'Reciter $id',
  style: 'murattal',
  folderUrl: 'https://server.mp3quran.net/r$id/',
  sourceId: 10,
  riwaya: riwaya,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('verse map between Warsh and Hafs', () {
    final data = RiwayaData.parse(_sample());

    test('verses keep the riwaya\'s own numbers and pages', () {
      expect(data.id, 'warsh');
      expect(data.surahCounts[0], 7);
      expect(data.surahCounts[1], 285); // Hafs counts 286
      expect(data.surahCounts[10], 121); // Hud: Hafs counts 123
      expect(data.surahStartPages.take(2), [1, 2]);
      expect(data.versesOnPage(1).map((v) => v.ayah), [1, 2, 3, 4, 5, 6, 7]);
      expect(data.ayahsOnPage(1).first.number, 1);
      expect(data.pageOf(11, 82), 231);
    });

    test('al-Fatiha: the basmala is Hafs 1:1 and not a Warsh verse', () {
      expect(data.toHafs(1, 1), [(surah: 1, ayah: 2)]);
      // Hafs 1:7 is split in two in Warsh (1:6 and 1:7).
      expect(data.toHafs(1, 6), [(surah: 1, ayah: 7)]);
      expect(data.toHafs(1, 7), [(surah: 1, ayah: 7)]);
      expect(data.fromHafs(1, 7), (surah: 1, ayah: 6));
      // A Hafs verse the riwaya does not count opens the next one.
      expect(data.fromHafs(1, 1), (surah: 1, ayah: 1));
      expect(data.firstHafs(1, 1), (surah: 1, ayah: 2));
    });

    test('al-Baqarah: alif lam mim is part of the first Warsh verse', () {
      expect(data.toHafs(2, 1), [(surah: 2, ayah: 1), (surah: 2, ayah: 2)]);
      expect(data.fromHafs(2, 2), (surah: 2, ayah: 1));
      expect(data.fromHafs(2, 3), (surah: 2, ayah: 2));
    });

    test('Hud 82: a Warsh verse that covers the end of one Hafs verse and '
        'the next (KFGQPC texts and Quranpedia agree)', () {
      expect(data.toHafs(11, 81), [(surah: 11, ayah: 82)]);
      expect(data.toHafs(11, 82), [
        (surah: 11, ayah: 82),
        (surah: 11, ayah: 83),
      ]);
      expect(data.fromHafs(11, 83), (surah: 11, ayah: 82));
      expect(data.fromHafs(11, 84), (surah: 11, ayah: 83));
    });

    test('outlines, line cuts and the measured grid', () {
      expect(data.polygons(1).length, 7);
      expect(data.lines(3).cuts.length, 14);
      expect(data.pitch, closeTo(35.2, 0.5));
      expect(data.fontFile, endsWith('.ttf'));
    });
  });

  group('riwaya editions', () {
    test('four riwayat, each its own pack on the mirror', () {
      final riwayat = [
        for (final e in MushafEdition.values)
          if (e.isRiwaya) e,
      ];
      expect(riwayat.map((e) => e.riwaya.name), [
        'warsh',
        'qalun',
        'douri',
        'shubah',
      ]);
      for (final e in riwayat) {
        final spec = PagePackSpec.of(e);
        expect(spec.id, 'pages-${e.riwaya.name}-v1');
        expect(spec.url, startsWith('https://tibyan.ahmedhelal.dev/mirror/'));
        expect(spec.sha256, hasLength(64));
        expect(spec.format, PackFormat.svgXz);
        expect(e.pageCount, 604);
        expect(e.isSvg, isTrue);
      }
      expect(MushafEdition.madina1405.isRiwaya, isFalse);
    });

    test(
      'switching to Warsh reads its pages, numbers and recitations',
      () async {
        SharedPreferences.setMockInitialValues({
          'settings.edition': 'madina1441',
        });
        final root = Directory.systemTemp.createTempSync('packs');
        void install(PagePackSpec spec, [void Function(Directory)? fill]) {
          final dir = Directory(p.join(root.path, 'packs', spec.id))
            ..createSync(recursive: true);
          fill?.call(dir);
          File(p.join(dir.path, '.installed')).writeAsStringSync('x');
        }

        install(PagePackSpec.madina1441);
        final db = ContentDatabase(
          NativeDatabase(
            File('assets/db/content.db'),
            setup: (raw) => raw.execute('PRAGMA query_only = ON'),
          ),
        );
        addTearDown(db.close);
        final container = ProviderContainer(
          overrides: [
            contentDatabaseProvider.overrideWithValue(db),
            themeRegistryProvider.overrideWithValue(
              await ThemeRegistry.load(rootBundle),
            ),
            sharedPreferencesProvider.overrideWithValue(
              await SharedPreferences.getInstance(),
            ),
            packRootProvider.overrideWithValue(root),
            allRecitersProvider.overrideWith(
              (ref) async => [
                _reciter(1, 'hafs'),
                _reciter(2, 'hafs'),
                _reciter(101, 'warsh'),
                _reciter(102, 'warsh'),
                _reciter(111, 'qalun'),
              ],
            ),
          ],
        );
        addTearDown(container.dispose);

        expect(await container.read(riwayaDataProvider.future), isNull);
        expect(
          (await container.read(recitersProvider.future)).map((r) => r.id),
          [1, 2],
        );

        await container
            .read(settingsProvider.notifier)
            .setEdition(MushafEdition.warsh);
        // Not on the device yet: the new Madina edition is read meanwhile.
        expect(container.read(editionProvider), MushafEdition.madina1441);

        install(PagePackSpec.warsh, (dir) {
          final json = utf8.encode(_sample());
          File(p.join(dir.path, 'riwaya.json.xz'))
              .writeAsBytesSync(XZEncoder().encode(json));
        });
        container.read(packInstallsProvider.notifier).changed();
        expect(container.read(editionProvider), MushafEdition.warsh);

        final data = await container.read(riwayaDataProvider.future);
        expect(data?.id, 'warsh');
        final page1 = await container.read(pageAyahsProvider(1).future);
        expect(page1.length, 7);
        expect(page1.first.displayText, startsWith('اِ۬لْحَمْدُ'));
        // A Hafs verse (bookmark, search result) opens the Warsh page.
        expect(await container.read(versePageProvider((11, 83)).future), 231);
        expect(editionKeyOf(data, 11, 83), (surah: 11, ayah: 82));
        expect(hafsKeyOf(data, (surah: 2, ayah: 1)), (surah: 2, ayah: 1));
        expect(await container.read(surahAyahCountProvider(2).future), 285);

        // Only Warsh's recitations; the Hafs choice is kept apart.
        expect(
          (await container.read(recitersProvider.future)).map((r) => r.id),
          [101, 102],
        );
        expect((await container.read(currentReciterProvider.future))?.id, 101);
        await container
            .read(settingsProvider.notifier)
            .setReciter(102, riwaya: Riwaya.warsh);
        expect((await container.read(currentReciterProvider.future))?.id, 102);
        expect(container.read(settingsProvider).reciterId, 1);

        // The frame shows the riwaya's juz and no hizb.
        final frame = await container.read(frameInfoProvider(3).future);
        expect(frame?.juz, 1);
        expect(frame?.hizb, isNull);
      },
    );
  });
}
