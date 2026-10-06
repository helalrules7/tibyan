import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/mushaf/data/mushaf_repository.dart';
import 'package:tibyan/features/share_image/share_document.dart';
import 'package:tibyan/features/share_image/share_source.dart';
import 'package:tibyan/features/share_image/share_text_runs.dart';

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
      ]) {
        final bytes = File(path).readAsBytesSync();
        await (FontLoader(
          family,
        )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      }
    });
    tearDownAll(() => db.close());

    test('type, order of revelation and the surah revealed before', () {
      expect(shareSurahHeader(4, surahs).title, 'سورة النساء');
      expect(
        shareSurahHeader(4, surahs).info,
        'مدنية · ترتيبها في النزول ٩٢ · نزلت بعد الممتحنة',
      );
      expect(
        shareSurahHeader(1, surahs).info,
        'مكية · ترتيبها في النزول ٥ · نزلت بعد المدثر',
      );
      expect(
        shareSurahHeader(2, surahs).info,
        'مدنية · ترتيبها في النزول ٨٧ · نزلت بعد المطففين',
      );
    });

    test('al-Alaq, the first revealed, has no «نزلت بعد»', () {
      expect(shareSurahHeader(96, surahs).info, 'مكية · ترتيبها في النزول ١');
      for (var s = 1; s <= 114; s++) {
        final info = shareSurahHeader(s, surahs).info;
        expect(info.contains('نزلت بعد'), s != 96, reason: 'surah $s');
      }
    });

    test('the plain type: no excepted verses without a documented source', () {
      for (var s = 1; s <= 114; s++) {
        final type = shareSurahHeader(s, surahs).info.split(' · ').first;
        expect(type, anyOf('مكية', 'مدنية'), reason: 'surah $s');
        expect(shareSurahHeader(s, surahs).info, isNot(contains('إلا')));
      }
    });

    test('every surah\'s info line fits the medallion', () {
      for (var s = 1; s <= 114; s++) {
        final p = ShareDocument.infoLine(
          shareSurahHeader(s, surahs).info,
          digits: 'UthmanicHafs',
        );
        expect(p.didExceedMaxLines, isFalse, reason: 'surah $s');
        expect(
          p.longestLine,
          lessThanOrEqualTo(ShareDocument.infoWidth),
          reason: 'surah $s',
        );
        p.dispose();
      }
    });
  });
}
