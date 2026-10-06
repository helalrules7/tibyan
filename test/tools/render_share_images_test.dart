import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:archive/archive_io.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';
import 'package:tibyan/features/mushaf/data/riwaya_data.dart';
import 'package:tibyan/features/share_image/share_document.dart';
import 'package:tibyan/features/share_image/share_source.dart';

/// Not a test: draws sample pictures of the «share as image» feature into
/// `$SHARE_IMAGES_OUT/<name>_<n>.png` (default build/share_images), with
/// an index.html. Runs only with RENDER_SHARE_IMAGES=1. The Warsh sample
/// needs tools/.cache/riwayat/UthmanicWarsh_v2-1.zip (the KFGQPC Warsh
/// text and font a Warsh pack carries).
void main() {
  final run = Platform.environment['RENDER_SHARE_IMAGES'] == '1';
  final outPath =
      Platform.environment['SHARE_IMAGES_OUT'] ?? 'build/share_images';

  testWidgets(
    'render share images',
    (tester) async {
      final db = ContentDatabase(
        NativeDatabase(
          File('assets/db/content.db'),
          setup: (raw) => raw.execute('PRAGMA query_only = ON'),
        ),
      );
      final repo = MushafRepository(db);
      final out = Directory(outPath)..createSync(recursive: true);
      final html = StringBuffer();

      await tester.runAsync(() async {
        final manifest = jsonDecode(
          await rootBundle.loadString('FontManifest.json'),
        ) as List<dynamic>;
        for (final f in manifest.cast<Map<String, dynamic>>()) {
          final loader = FontLoader(f['family'] as String);
          for (final a in (f['fonts'] as List).cast<Map<String, dynamic>>()) {
            loader.addFont(
              rootBundle.load(Uri.decodeFull(a['asset'] as String)),
            );
          }
          await loader.load();
        }
        final surahs = await repo.surahs();
        final logoBytes = File('assets/ornaments/share_logo.png')
            .readAsBytesSync();
        final codec = await ui.instantiateImageCodec(logoBytes);
        final logo = (await codec.getNextFrame()).image;

        ShareRange verses(int s, int a, int b) => [
          for (var i = a; i <= b; i++) (surah: s, ayah: i),
        ];
        ShareRange surah(int s) => verses(s, 1, surahs[s - 1].ayahCount);

        Future<void> draw(String name, String title, SharePassage p) async {
          final doc = ShareDocument.build(p, logo: logo);
          html.writeln('<h2>$title (${doc.pageCount})</h2><div class="row">');
          for (var i = 0; i < doc.pageCount; i++) {
            final file = '${name}_${i + 1}.png';
            File('${out.path}/$file').writeAsBytesSync(await doc.png(i));
            html.writeln(
              '<a href="$file"><img src="$file" loading="lazy"></a>',
            );
          }
          html.writeln('</div>');
          doc.dispose();
        }

        Future<SharePassage> hafs(
          ShareRange r, {
          ShareOptions options = const ShareOptions(divineNames: true),
        }) =>
            hafsPassage(repo: repo, range: r, surahs: surahs, options: options);

        await draw(
          'kursi',
          'آية الكرسي، البقرة ٢٥٥',
          await hafs(verses(2, 255, 255)),
        );
        await draw('baqarah_1_5', 'البقرة ١–٥', await hafs(verses(2, 1, 5)));
        await draw('ikhlas', 'سورة الإخلاص كاملة', await hafs(surah(112)));
        await draw('fatiha', 'سورة الفاتحة', await hafs(surah(1)));
        await draw('tawbah_1_3', 'التوبة ١–٣', await hafs(verses(9, 1, 3)));
        await draw(
          'anfal_65',
          'الأنفال ٦٥ (مثل التصميم المطلوب)',
          await hafs(verses(8, 65, 65)),
        );
        await draw(
          'baqarah_282_286',
          'مقطع طويل ينقسم: البقرة ٢٨٢–٢٨٦',
          await hafs(verses(2, 282, 286)),
        );
        await draw('kahf', 'سورة الكهف كاملة', await hafs(surah(18)));
        await draw(
          'kursi_tajweed',
          'آية الكرسي بألوان التجويد',
          await hafs(
            verses(2, 255, 255),
            options: const ShareOptions(tajweed: true, divineNames: true),
          ),
        );
        await draw(
          'mulk_1_5_tajweed',
          'الملك ١–٥ بألوان التجويد بلا تمييز لفظ الجلالة',
          await hafs(
            verses(67, 1, 5),
            options: const ShareOptions(tajweed: true),
          ),
        );

        final warshZip = File('tools/.cache/riwayat/UthmanicWarsh_v2-1.zip');
        if (warshZip.existsSync()) {
          final z = ZipDecoder().decodeBytes(warshZip.readAsBytesSync());
          final font = z.files.firstWhere((f) => f.name.endsWith('.ttf'));
          await (FontLoader(
            'KFGQPC_warsh',
          )..addFont(Future.value(ByteData.sublistView(font.content)))).load();
          final rows = jsonDecode(
            utf8.decode(
              z.files.firstWhere((f) => f.name.endsWith('.json')).content,
            ),
          ) as List<dynamic>;
          final data = RiwayaData(
            id: 'warsh',
            nameAr: 'ورش',
            nameEn: 'Warsh',
            pageCount: 0,
            firstLine: 0,
            pitch: 0,
            openingInk: const [],
            openingBody: const [],
            fontFile: '',
            surahCounts: const [],
            surahStartPages: const [],
            verses: [
              for (final r in rows.cast<Map<String, dynamic>>())
                RiwayaVerse(
                  surah: int.parse('${r['sura_no']}'),
                  ayah: int.parse('${r['aya_no']}'),
                  page: int.parse('${r['page']}'),
                  juz: int.parse('${r['jozz']}'),
                  hafsFrom: 0,
                  hafsTo: 0,
                  text: r['aya_text'] as String,
                ),
            ],
            polygonsByPage: const {},
            linesByPage: const {},
          );
          await draw(
            'warsh_fatiha',
            'ورش: الفاتحة بنص ورش وخطه (بلا سطر بسملة)',
            riwayaPassage(
              data: data,
              fontFamily: 'KFGQPC_warsh',
              range: surah(1).sublist(0, 7),
              surahs: surahs,
              options: const ShareOptions(divineNames: true),
            ),
          );
        }
        logo.dispose();
      });

      File('${out.path}/index.html').writeAsStringSync('''
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>تبيان: مشاركة الآيات صورة</title>
<style>
body{font-family:system-ui,sans-serif;background:#efe6d6;color:#1e1915;margin:16px}
h1{font-size:22px}h2{font-size:17px;margin:28px 0 8px}
.row{display:flex;gap:12px;overflow-x:auto;padding-bottom:8px}
.row img{height:420px;box-shadow:0 1px 6px #0003;border-radius:4px}
</style></head><body>
<h1>مشاركة الآيات صورة: عينات (1536×2048)</h1>
$html
</body></html>
''');
      await tester.runAsync(() => db.close());
    },
    skip: !run,
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
