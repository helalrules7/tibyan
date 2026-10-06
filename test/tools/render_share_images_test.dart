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
import 'package:tibyan/features/share_image/surah_statements.dart';

/// Not a test: draws sample pictures of the «share as image» feature into
/// `$SHARE_IMAGES_OUT/<name>_<n>.png` (default build/share_images), with
/// an index.html. Runs only with RENDER_SHARE_IMAGES=1. The Warsh sample
/// (pages 230-231 of the Warsh pack fixture, with its word boxes) needs
/// the KFGQPC Warsh font from tools/.cache/riwayat/UthmanicWarsh_v2-1.zip.
void main() {
  final run = Platform.environment['RENDER_SHARE_IMAGES'] == '1';
  final outPath =
      Platform.environment['SHARE_IMAGES_OUT'] ?? 'build/share_images';
  // SHARE_IMAGES_ONLY=types: only the surah headers with the 1342
  // statement of their type (the longest ones, and a few more).
  final onlyTypes = Platform.environment['SHARE_IMAGES_ONLY'] == 'types';

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
        final statements = SurahStatements.parse(
          File(SurahStatements.asset).readAsStringSync(),
        );
        final logoBytes = File('assets/ornaments/share_logo.png')
            .readAsBytesSync();
        final codec = await ui.instantiateImageCodec(logoBytes);
        final logo = (await codec.getNextFrame()).image;

        ShareRange verses(int s, int a, int b) => [
          for (var i = a; i <= b; i++) (surah: s, ayah: i),
        ];
        ShareRange surah(int s) => verses(s, 1, surahs[s - 1].ayahCount);

        Future<void> draw(
          String name,
          String title,
          SharePassage p, {
          List<int>? only,
        }) async {
          final doc = ShareDocument.build(p, logo: logo);
          final shown = only == null
              ? [for (var i = 0; i < doc.pageCount; i++) i]
              : [for (final i in only) i < 0 ? doc.pageCount + i : i];
          html.writeln(
            '<h2>$title (${doc.pageCount}'
            '${only == null ? '' : '، المعروض: ${shown.map((i) => i + 1).join('، ')}'})'
            '</h2><p class="m">${doc.byMushaf ? 'مقسمة على صفحات المصحف وسطوره' : 'سطور منسابة'}'
            ' · حجم الخط ${doc.fontSize}</p><div class="row">',
          );
          for (final i in shown) {
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
        }) => hafsPassage(
          repo: repo,
          range: r,
          surahs: surahs,
          statements: statements,
          options: options,
        );

        if (onlyTypes) {
          // The ten longest statements, then al-Fatiha, al-An'am, al-A'raf,
          // Yunus, Hud and at-Tawba: each surah's first verses.
          final longest = [for (var s = 1; s <= 114; s++) s]
            ..sort(
              (a, b) => statements[b]!.statement.length.compareTo(
                statements[a]!.statement.length,
              ),
            );
          final shown = <int>{...longest.take(10), 1, 6, 7, 10, 11, 9};
          for (final s in shown) {
            final n = surahs[s - 1].ayahCount;
            await draw(
              'type_${s.toString().padLeft(3, '0')}',
              'سورة ${surahs[s - 1].nameAr}: «${statements[s]!.statement}»',
              await hafs(verses(s, 1, n < 3 ? n : 3)),
            );
          }
          // A riwaya numbering the surah otherwise: the plain type.
          final warshZip = File('tools/.cache/riwayat/UthmanicWarsh_v2-1.zip');
          if (warshZip.existsSync()) {
            final z = ZipDecoder().decodeBytes(warshZip.readAsBytesSync());
            final font = z.files.firstWhere((f) => f.name.endsWith('.ttf'));
            await (FontLoader('KFGQPC_warsh')
                  ..addFont(Future.value(ByteData.sublistView(font.content))))
                .load();
            final data = RiwayaData.parse(
              File('test/fixtures/riwaya_warsh_sample.json').readAsStringSync(),
            );
            await draw(
              'type_warsh_hud',
              'ورش: هود ٧١–٧٣ (عد ورش لهود غير عد حفص: النوع وحده)',
              riwayaPassage(
                data: data,
                fontFamily: 'KFGQPC_warsh',
                range: verses(11, 71, 73),
                surahs: surahs,
                statements: statements,
                options: const ShareOptions(divineNames: true),
              ),
            );
          }
          logo.dispose();
          return;
        }

        await draw(
          'nisa',
          'سورة النساء كاملة: صفحات ٧٧–١٠٦',
          await hafs(surah(4)),
          only: [0, 1, 2, -1],
        );
        await draw('kahf', 'سورة الكهف كاملة', await hafs(surah(18)));
        await draw(
          'baqarah_282_286',
          'البقرة ٢٨٢–٢٨٦',
          await hafs(verses(2, 282, 286)),
        );
        await draw(
          'nisa_11_12',
          'تحديد على صفحتين: النساء ١١–١٢',
          await hafs(verses(4, 11, 12)),
        );
        await draw(
          'kursi',
          'آية الكرسي، البقرة ٢٥٥ (صورة واحدة كما كانت)',
          await hafs(verses(2, 255, 255)),
        );
        await draw(
          'kursi_tajweed',
          'آية الكرسي بألوان التجويد',
          await hafs(
            verses(2, 255, 255),
            options: const ShareOptions(tajweed: true, divineNames: true),
          ),
        );

        await draw('fatiha', 'سورة الفاتحة كاملة', await hafs(surah(1)));
        await draw(
          'alaq_1_5',
          'العلق ١–٥ (أول ما نزل: بلا «نزلت بعد»)',
          await hafs(verses(96, 1, 5)),
        );
        await draw(
          'mujadila_1',
          'المجادلة ١ (أطول سطر تحت اسم السورة)',
          await hafs(verses(58, 1, 1)),
        );

        final warshZip = File('tools/.cache/riwayat/UthmanicWarsh_v2-1.zip');
        if (warshZip.existsSync()) {
          final z = ZipDecoder().decodeBytes(warshZip.readAsBytesSync());
          final font = z.files.firstWhere((f) => f.name.endsWith('.ttf'));
          await (FontLoader(
            'KFGQPC_warsh',
          )..addFont(Future.value(ByteData.sublistView(font.content)))).load();
          // The Warsh pages 230-231 of the test fixture: the pack's own
          // verses, word boxes and line cuts.
          final data = RiwayaData.parse(
            File('test/fixtures/riwaya_warsh_sample.json').readAsStringSync(),
            File('test/fixtures/riwaya_warsh_words_sample.json')
                .readAsStringSync(),
          );
          await draw(
            'warsh_hud_71_88',
            'ورش: هود ٧١–٨٨ على صفحتي ورش ٢٣٠–٢٣١ وسطورهما',
            riwayaPassage(
              data: data,
              fontFamily: 'KFGQPC_warsh',
              range: verses(11, 71, 88),
              surahs: surahs,
              statements: statements,
              options: const ShareOptions(divineNames: true),
            ),
          );
        }
        logo.dispose();
      });

      File('${out.path}/index.html').writeAsStringSync('''
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${onlyTypes ? 'تبيان: نوع السورة في الصورة' : 'تبيان: مشاركة الآيات صورة'}</title>
<style>
body{font-family:system-ui,sans-serif;background:#efe6d6;color:#1e1915;margin:16px}
h1{font-size:22px}h2{font-size:17px;margin:28px 0 8px}
.row{display:flex;gap:12px;overflow-x:auto;padding-bottom:8px}
.m{margin:0 0 8px;color:#7a4a26}
.row img{height:420px;box-shadow:0 1px 6px #0003;border-radius:4px}
</style></head><body>
<h1>${onlyTypes ? 'رأس السورة في صورة المشاركة: بيان نوعها كما طُبع في مصحف ١٣٤٢هـ (مسودة نقل تنتظر المراجعة)' : 'مشاركة الآيات صورة: صورة لكل صفحة من مصحف المدينة (١٤٤١) بسطورها'}</h1>
$html
</body></html>
''');
      await tester.runAsync(() => db.close());
    },
    skip: !run,
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
