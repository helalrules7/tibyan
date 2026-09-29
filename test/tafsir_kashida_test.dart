import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/tafsir/kashida_text.dart';

void main() {
  test('tatweels are only added: removing them gives the text back', () {
    const line = 'قل -أيها الرسول-: هو الله المتفرد بالألوهية والربوبية';
    for (final n in [1, 5, 12, 40]) {
      final out = insertKashidas(line, n);
      expect(out.replaceAll(tatweel, ''), line);
      expect(out.length - line.length, lessThanOrEqualTo(n));
    }
  });

  test('never inside brackets, never splitting lam-alef', () {
    const line = '(الرَّحْمَنِ) ذي الرحمة العامة ﴿قُلْ﴾ لا';
    final out = insertKashidas(line, 30);
    expect(out.substring(0, out.indexOf(')') + 1), '(الرَّحْمَنِ)');
    expect(out.contains('﴿قُلْ﴾'), isTrue);
    expect(out.endsWith(' لا'), isTrue);
    expect(out.contains('ل$tatweelا'), isFalse);
  });

  test('a tatweel follows the marks of its letter', () {
    final out = insertKashidas('بَيْنَهُمَا', 20);
    expect(out.replaceAll(tatweel, ''), 'بَيْنَهُمَا');
    // Never between a letter and its marks.
    expect(RegExp('$tatweel[\u064B-\u065F]').hasMatch(out), isFalse);
  });

  test('tatweels already in the source are kept and not stretched', () {
    const line = 'إلى الكعبة بـ «مكة» في الآخرة';
    final out = insertKashidas(line, 10);
    expect(out.contains('بـ «'), isTrue);
    expect(removeAddedKashidas(out, line), line);
  });

  test('every Muyassar entry survives the round trip', () async {
    final db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
    final rows = await db
        .customSelect('SELECT text FROM commentary WHERE source_id = 7')
        .get();
    expect(rows.length, 6236);
    for (final r in rows) {
      final text = r.read<String>('text');
      final out = insertKashidas(text, 60);
      expect(removeAddedKashidas(out, text), text);
      expect(
        tatweel.allMatches(out).length - tatweel.allMatches(text).length,
        out.length - text.length,
      );
    }
    await db.close();
  });
}
