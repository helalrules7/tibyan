import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';
import 'package:tibyan/features/mushaf/data/riwaya_data.dart';
import 'package:tibyan/features/share_image/share_document.dart';
import 'package:tibyan/features/share_image/share_source.dart';
import 'package:tibyan/features/share_image/share_text_runs.dart';
import 'package:tibyan/features/share_image/surah_statements.dart';

/// The ink of [p] laid out, drawn at [at]: the box of its painted pixels.
Future<Rect> inkOf(ui.Paragraph p, Offset at) async {
  const pad = 60;
  final w = p.width.ceil() + 2 * pad, h = p.height.ceil() + 2 * pad;
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawParagraph(p, const Offset(pad + 0.0, pad + 0.0));
  final picture = recorder.endRecording();
  final img = await picture.toImage(w, h);
  final bytes = (await img.toByteData())!;
  picture.dispose();
  img.dispose();
  var (l, t, r, b) = (w, h, -1, -1);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (bytes.getUint8((y * w + x) * 4 + 3) == 0) continue;
      if (x < l) l = x;
      if (x > r) r = x;
      if (y < t) t = y;
      if (y > b) b = y;
    }
  }
  return Rect.fromLTRB(
    at.dx + l - pad,
    at.dy + t - pad,
    at.dx + r + 1 - pad,
    at.dy + b + 1 - pad,
  );
}

/// The header and footer labels of the shared pictures: their digits in
/// the mushaf's font, their words in Changa, and the surah's info line.
void main() {
  group('labelRuns', () {
    const changa = 'Changa', hafs = 'UthmanicHafs';
    List<(String, String)> runs(String t) =>
        labelRuns(t, words: changa, digits: hafs);

    test('the digits in the mushaf font, the words in Changa', () {
      expect(runs('النساء ١–١٧٦'), [
        ('النساء ', changa),
        ('١', hafs),
        ('–', changa),
        ('١٧٦', hafs),
      ]);
      expect(runs('١ من ٣٠'), [('١', hafs), (' من ', changa), ('٣٠', hafs)]);
      expect(runs('مدنية · ترتيبها في النزول ٩٢ · نزلت بعد الممتحنة'), [
        ('مدنية · ترتيبها في النزول ', changa),
        ('٩٢', hafs),
        (' · نزلت بعد الممتحنة', changa),
      ]);
    });

    test('a label without digits is one Changa run, and none is lost', () {
      expect(runs('سورة الفاتحة'), [('سورة الفاتحة', changa)]);
      expect(runs(''), isEmpty);
      for (final t in ['البقرة ٢٥٥', '١٢ من ١٢', 'هود ٧١ – يوسف ٣']) {
        expect(runs(t).map((r) => r.$1).join(), t);
      }
    });
  });

  group('the surah header', () {
    late ContentDatabase db;
    late List<SurahRow> surahs;
    final statements = SurahStatements.parse(
      File(SurahStatements.asset).readAsStringSync(),
    );
    ShareSurahHeader header(int s, {bool plainType = false}) =>
        shareSurahHeader(
          s,
          surahs,
          statements: statements,
          plainType: plainType,
        );
    setUpAll(() async {
      db = ContentDatabase(
        NativeDatabase(
          File('assets/db/content.db'),
          setup: (raw) => raw.execute('PRAGMA query_only = ON'),
        ),
      );
      surahs = await MushafRepository(db).surahs();
      for (final (family, path) in [
        ('Changa', 'assets/fonts/ofl/changa/Changa[wght].ttf'),
        ('UthmanicHafs', 'assets/fonts/kfgqpc/uthmanic_hafs_v20.ttf'),
        ('UthmanTahaNaskh', 'assets/fonts/kfgqpc/UthmanTN_v2-0.ttf'),
      ]) {
        final bytes = File(path).readAsBytesSync();
        await (FontLoader(
          family,
        )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      }
    });
    tearDownAll(() => db.close());

    test('the 1342 statement, the order of revelation and the surah '
        'revealed before', () {
      expect(header(4).title, 'سورة النساء');
      expect(
        header(4).info,
        'مدنية · ترتيبها في النزول ٩٢ · نزلت بعد الممتحنة',
      );
      expect(header(1).info, 'مكية · ترتيبها في النزول ٥ · نزلت بعد المدثر');
      expect(
        header(6).info,
        'مكية إلا الآيات ٢٠ و٢٣ و٩١ و٩٣ و١١٤ و١٤١ و١٥١ و١٥٢ و١٥٣ فمدنية'
        ' · ترتيبها في النزول ٥٥ · نزلت بعد الحجر',
      );
      expect(
        header(7).info,
        'مكية إلا من آية ١٦٣ إلى غاية آية ١٧٠ فمدنية'
        ' · ترتيبها في النزول ٣٩ · نزلت بعد ص',
      );
      expect(
        header(2).info,
        'مدنية إلا آية ٢٨١ فنزلت بمنى فى حجة الوداع'
        ' · ترتيبها في النزول ٨٧ · نزلت بعد المطففين',
      );
      expect(
        header(9).info,
        'مدنية إلا الآيتين الأخيرتين فمكيتان'
        ' · ترتيبها في النزول ١١٣ · نزلت بعد المائدة',
      );
    });

    test('every header starts with its surah\'s statement, as printed', () {
      for (var s = 1; s <= 114; s++) {
        final info = header(s).info;
        expect(
          info.startsWith('${statements[s]!.statement} · '),
          isTrue,
          reason: 'surah $s',
        );
      }
    });

    test('al-Alaq, the first revealed, has no «نزلت بعد»', () {
      expect(header(96).info, 'مكية · ترتيبها في النزول ١');
      for (var s = 1; s <= 114; s++) {
        expect(
          header(s).info.contains('نزلت بعد'),
          s != 96,
          reason: 'surah $s',
        );
      }
    });

    test('a text numbered otherwise: the plain type of a statement that '
        'names verses', () {
      expect(
        header(6, plainType: true).info,
        'مكية · ترتيبها في النزول ٥٥ · نزلت بعد الحجر',
      );
      // No verse named: the statement holds whatever the count.
      expect(
        header(48, plainType: true).info,
        startsWith('مدنية نزلت فى الطريق عند الانصراف من الحديبية · '),
      );
      for (var s = 1; s <= 114; s++) {
        final type = header(s, plainType: true).info.split(' · ').first;
        if (statements[s]!.numbered) {
          expect(type, anyOf('مكية', 'مدنية'), reason: 'surah $s');
        }
      }
    });

    test('a riwaya numbering a surah as Hafs keeps the statement; one '
        'numbering it otherwise gets the plain type', () {
      final data = RiwayaData.parse(
        File('test/fixtures/riwaya_warsh_sample.json').readAsStringSync(),
      );
      // Hud: 121 verses in Warsh's count, 123 in Hafs's.
      expect(riwayaNumbersAsHafs(data, 11, 123), isFalse);
      final p = riwayaPassage(
        data: data,
        fontFamily: 'UthmanicHafs',
        range: [for (var a = 71; a <= 88; a++) (surah: 11, ayah: a)],
        surahs: surahs,
        statements: statements,
      );
      expect(
        p.headers[11]!.info,
        'مكية · ترتيبها في النزول ٥٢ · نزلت بعد يونس',
      );
    });

    // Ahmed's rule: the header's text never runs past the cartouche.
    test(
      'every header fits its cartouche: all 114, statement or plain',
      () async {
        final grown = <int, int>{};
        for (final plain in [false, true]) {
          for (var s = 1; s <= 114; s++) {
            final h = ShareDocument.layoutHeader(
              header(s, plainType: plain),
              digits: 'UthmanicHafs',
            );
            final why =
                'surah $s${plain ? ' (plain)' : ''}: ${h.infoSize}, '
                '${h.infoLineCount} lines';
            final m = Medallion.of(h.rect);
            // The room is inside the medallion's flat top and bottom, and
            // under the title.
            expect(
              h.infoRoom.left,
              greaterThanOrEqualTo(m.flatLeft),
              reason: why,
            );
            expect(
              h.infoRoom.right,
              lessThanOrEqualTo(m.flatRight),
              reason: why,
            );
            expect(
              h.infoRoom.bottom,
              lessThanOrEqualTo(m.innerBottom),
              reason: why,
            );
            expect(
              h.infoRoom.top,
              greaterThan(h.titleOffset.dy + h.title.alphabeticBaseline),
              reason: why,
            );
            // The info paragraph, laid out: in its room, never cut.
            expect(h.info.didExceedMaxLines, isFalse, reason: why);
            expect(
              h.info.longestLine,
              lessThanOrEqualTo(ShareDocument.infoWidth),
              reason: why,
            );
            expect(
              h.infoBox.left,
              greaterThanOrEqualTo(h.infoRoom.left - 1e-6),
              reason: why,
            );
            expect(
              h.infoBox.right,
              lessThanOrEqualTo(h.infoRoom.right + 1e-6),
              reason: why,
            );
            expect(
              h.infoBox.top,
              greaterThanOrEqualTo(h.infoRoom.top - 1e-6),
              reason: why,
            );
            expect(
              h.infoBox.bottom,
              lessThanOrEqualTo(h.infoRoom.bottom + 1e-6),
              reason: why,
            );
            expect(h.infoLineCount, lessThanOrEqualTo(3), reason: why);
            // The title within the medallion's width.
            expect(
              h.title.longestLine,
              lessThanOrEqualTo(m.flatRight - m.flatLeft),
              reason: why,
            );
            // The ink itself, drawn: the info's inside its room, below the
            // title's, both inside the medallion.
            final info = await inkOf(h.info, h.infoOffset);
            final title = await inkOf(h.title, h.titleOffset);
            expect(
              info.left,
              greaterThanOrEqualTo(h.infoRoom.left),
              reason: why,
            );
            expect(
              info.right,
              lessThanOrEqualTo(h.infoRoom.right),
              reason: why,
            );
            expect(info.top, greaterThanOrEqualTo(h.infoRoom.top), reason: why);
            expect(
              info.bottom,
              lessThanOrEqualTo(h.infoRoom.bottom),
              reason: why,
            );
            expect(title.bottom, lessThan(info.top - 4), reason: why);
            expect(title.top, greaterThan(m.innerTop), reason: why);
            expect(title.left, greaterThan(m.flatLeft), reason: why);
            expect(title.right, lessThan(m.flatRight), reason: why);
            if (h.rect.height > ShareDocument.headerHeight) {
              // Grown only for a wrapped line at the least size.
              expect(h.infoLineCount, greaterThan(1), reason: why);
              expect(h.infoSize, ShareDocument.infoLeastSize, reason: why);
              if (!plain) grown[s] = h.rect.height.round();
            } else {
              expect(h.infoLineCount, lessThanOrEqualTo(2), reason: why);
            }
            h.dispose();
          }
        }
        // The statements on two lines take a cartouche a little taller;
        // none needs three lines.
        // ignore: avoid_print
        print('taller cartouches (surah: height): $grown');
        expect(
          grown.values.every((h) => h <= ShareDocument.headerHeight + 24),
          isTrue,
        );
      },
    );

    test('an info line too long for two lines: the cartouche grows, the '
        'pictures with it', () async {
      // Not a surah's: a label long enough to need three lines.
      final long = ShareSurahHeader(
        title: 'سورة النساء',
        info: List.filled(6, 'ترتيبها في النزول ٩٢').join(' · '),
      );
      final h = ShareDocument.layoutHeader(long, digits: 'UthmanicHafs');
      addTearDown(h.dispose);
      expect(h.infoLineCount, 3);
      expect(h.info.didExceedMaxLines, isFalse);
      expect(h.rect.height, greaterThan(ShareDocument.headerHeight));
      expect(h.infoBox.bottom, lessThanOrEqualTo(h.infoRoom.bottom + 1e-6));
      expect(
        h.infoRoom.bottom,
        lessThanOrEqualTo(Medallion.of(h.rect).innerBottom),
      );

      final p = await hafsPassage(
        repo: MushafRepository(db),
        range: [for (var a = 1; a <= 3; a++) (surah: 4, ayah: a)],
        surahs: surahs,
        statements: statements,
      );
      SharePassage withHeader(ShareSurahHeader header) => SharePassage(
        verses: p.verses,
        headers: {4: header},
        fontFamily: p.fontFamily,
        basmala: p.basmala,
        reference: p.reference,
        pageLabel: p.pageLabel,
      );
      final usual = ShareDocument.build(withHeader(p.headers[4]!));
      final taller = ShareDocument.build(withHeader(long));
      addTearDown(usual.dispose);
      addTearDown(taller.dispose);
      expect(usual.headerHeightOf(4), ShareDocument.headerHeight);
      expect(taller.headerHeightOf(4), h.rect.height);
      // One picture, trimmed to its text: taller by what the header grew.
      expect(usual.pageCount, 1);
      expect(taller.pageCount, 1);
      expect(
        taller.sizeOf(0).height - usual.sizeOf(0).height,
        closeTo(h.rect.height - ShareDocument.headerHeight, 1),
      );
    });
  });
}
