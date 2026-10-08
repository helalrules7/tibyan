import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/features/mushaf/data/verse_share.dart';

AyahRow _ayah(int surah, int number, String text, {int basmala = 0}) => AyahRow(
  id: surah * 1000 + number,
  surah: surah,
  number: number,
  verseText: text,
  displayText: text,
  basmalaPrefix: basmala,
  textSearch: text,
  searchBasmalaPrefix: 0,
  juz: 1,
  hizbQuarter: 1,
  manzil: 1,
  page: 1,
  page1405: 1,
  textSourceId: 1,
  displaySourceId: 1,
  pageSourceId: 1,
  pageShamarly: 1,
  pageShamarlyEnd: 1,
);

String _compose(List<AyahRow> v) => composeVerseText(
  verses: v,
  surahLabel: (s) => 'S$s',
  digits: (n) => '$n',
  range: (s, a, b) => '$s $a-$b',
);

void main() {
  test('one verse: text, number in brackets, reference', () {
    expect(_compose([_ayah(2, 255, 'اللَّهُ')]), 'اللَّهُ ﴿255﴾\n[S2 255]');
  });

  test('a range of verses joins them under one reference', () {
    expect(
      _compose([_ayah(2, 1, 'a'), _ayah(2, 2, 'b')]),
      'a ﴿1﴾ b ﴿2﴾\n[S2 1-2]',
    );
  });

  test('the basmala at the start of verse 1 is left out', () {
    final out = _compose([_ayah(2, 1, 'BASM الم', basmala: 5)]);
    expect(out, startsWith('الم ﴿1﴾'));
    expect(out, isNot(contains('BASM')));
  });

  test('a stretch over two surahs gets a reference for each', () {
    final out = _compose([_ayah(1, 7, 'x'), _ayah(2, 1, 'y')]);
    expect(out, contains('[S1 7]'));
    expect(out, contains('[S2 1]'));
  });

  test('the shared text: verses and reference only, no credit, no link', () {
    final out = composeVerseText(
      verses: [_ayah(4, 123, 'لَّيْسَ')],
      surahLabel: (s) => 'سورة النساء',
      digits: (n) => '$n',
      range: (s, a, b) => '$s $a–$b',
    );
    expect(out, 'لَّيْسَ ﴿123﴾\n[سورة النساء 123]');
    expect(out, isNot(contains('tibyan://')));
    expect(out, isNot(contains('tanzil')));
  });
}
