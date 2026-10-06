import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// The draft transcription of the surah headers of the 1924 Cairo mushaf
/// (assets/config/surah_type_1342.json, built by
/// tools/surah_type_1342/build.py): its fields, and its numbers against the
/// app's own data. Kept for the scholarly review; not shown in the app.
const _asset = 'assets/config/surah_type_1342.json';

void main() {
  final raw =
      jsonDecode(File(_asset).readAsStringSync()) as Map<String, dynamic>;
  final entries = (raw['surahs'] as List).cast<Map<String, dynamic>>();
  const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
  int arabic(String s) => int.parse(
    s.split('').map((c) => arabicDigits.indexOf(c).toString()).join(),
  );
  List<int> numbersIn(String s) => [
    for (final m in RegExp('[٠-٩]+').allMatches(s)) arabic(m[0]!),
  ];

  test('a draft, with its source, until a reviewer approves it', () {
    expect(raw['status'], 'draft-transcription');
    expect((raw['review'] as Map)['approved'], isFalse);
    final source = raw['source'] as Map<String, dynamic>;
    expect(source['edition'], contains('١٣٤٢'));
    expect(source['scan_sha256'], hasLength(64));
    expect(source['headers'], startsWith('https://'));
  });

  test('114 surahs, in order, each with valid fields', () {
    expect(entries.map((e) => e['surah']), [for (var s = 1; s <= 114; s++) s]);
    var page = 0;
    for (final e in entries) {
      final why = 'surah ${e['surah']}';
      expect(e['page'] as int, greaterThanOrEqualTo(page), reason: why);
      expect(e['page'] as int, inInclusiveRange(2, 827), reason: why);
      page = e['page'] as int;
      expect(e['type'], anyOf('meccan', 'medinan', 'mixed'), reason: why);
      final statement = e['statement'] as String;
      expect(statement.trim(), statement, reason: why);
      expect(statement, isNot(contains('  ')), reason: why);
      // No Western digits: the print's own.
      expect(statement, isNot(matches(RegExp('[0-9]'))), reason: why);
      expect(e['header_text'] as String, startsWith(statement), reason: why);
      // The type the statement opens with is the entry's.
      final first = statement.split(' ').first;
      if (first == 'مكية' && e['type'] != 'mixed') {
        expect(e['type'], 'meccan', reason: why);
      }
      if (first == 'مدنية') expect(e['type'], 'medinan', reason: why);
      // Every number in the statement is a verse of the structure, and the
      // structure has no other.
      final structured = <int>[
        for (final x
            in (e['exceptions'] as List).cast<Map<String, dynamic>>()) ...[
          ...((x['verses'] as List?) ?? const []).cast<int>(),
          if (x['from'] != null) x['from'] as int,
          if (x['to'] != null) x['to'] as int,
        ],
      ];
      expect(numbersIn(statement)..sort(), structured..sort(), reason: why);
      for (final x in (e['exceptions'] as List).cast<Map<String, dynamic>>()) {
        expect(x['type'], anyOf('meccan', 'medinan', isNull), reason: why);
        if (x['type'] == null) {
          expect(statement, contains(x['note'] as String), reason: why);
        }
      }
    }
  });

  test('the verse counts are the KFGQPC Hafs counts of content.db; the '
      'excepted verses exist', () {
    final db = sqlite3.open('assets/db/content.db', mode: OpenMode.readOnly);
    addTearDown(db.close);
    final counts = {
      for (final r in db.select(
        'select surah, count(*) as n from ayah group by surah',
      ))
        r['surah'] as int: r['n'] as int,
    };
    for (final e in entries) {
      final s = e['surah'] as int;
      expect(e['verse_count'], counts[s], reason: 'surah $s');
      for (final x in (e['exceptions'] as List).cast<Map<String, dynamic>>()) {
        for (final v in [
          ...((x['verses'] as List?) ?? const []).cast<int>(),
          if (x['from'] != null) x['from'] as int,
          if (x['to'] != null) x['to'] as int,
        ]) {
          expect(v, inInclusiveRange(1, counts[s]!), reason: 'surah $s');
        }
      }
    }
  });

  test('the type agrees with Tanzil\'s for every surah but al-Ma\'un, '
      'printed in two parts', () {
    final db = sqlite3.open('assets/db/content.db', mode: OpenMode.readOnly);
    addTearDown(db.close);
    final tanzil = {
      for (final r in db.select('select id, revelation from surah'))
        r['id'] as int: r['revelation'] as String,
    };
    for (final e in entries) {
      final s = e['surah'] as int;
      if (s == 107) {
        expect(e['type'], 'mixed');
        continue;
      }
      expect(e['type'], tanzil[s], reason: 'surah $s');
    }
  });
}
