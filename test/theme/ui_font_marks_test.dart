import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/theme/app_theme.dart';

/// Arabic marks (tashkeel) take no room of their own: they sit on their
/// letter. So a word shaped with its marks is exactly as wide as the same
/// word without them. A wider word means a mark was drawn as a glyph of
/// its own between two letters, which cuts the word apart (Changa 3.003
/// did this with shadda followed by a haraka).
void main() {
  const fonts = {
    'Changa': ['assets/fonts/ofl/changa/Changa[wght].ttf'],
    'IBMPlexSansArabic': [
      'assets/fonts/ofl/ibmplexsansarabic/IBMPlexSansArabic-Regular.ttf',
      'assets/fonts/ofl/ibmplexsansarabic/IBMPlexSansArabic-Bold.ttf',
    ],
    'KFGQPCAN': [
      'assets/fonts/kfgqpc/KFGQPCAnRegular.ttf',
      'assets/fonts/kfgqpc/KFGQPCAnBold.ttf',
    ],
  };

  setUpAll(() async {
    for (final MapEntry(key: family, value: paths) in fonts.entries) {
      final loader = FontLoader(family);
      for (final p in paths) {
        loader.addFont(
          Future.value(ByteData.sublistView(File(p).readAsBytesSync())),
        );
      }
      await loader.load();
    }
  });

  test('every interface font is one the test loads', () {
    expect(UiFont.values.map((f) => f.family).toSet(), fonts.keys.toSet());
  });

  for (final font in UiFont.values) {
    group(font.family, () {
      for (final weight in [FontWeight.w400, FontWeight.w700]) {
        test('each mark keeps its word whole (weight ${weight.value})', () {
          for (final word in markSamples) {
            expectMarksTakeNoRoom(word, font.family, weight);
          }
        });
      }

      test('the Arabic interface strings keep their words whole', () {
        final arb = jsonDecode(
          File('lib/l10n/app_ar.arb').readAsStringSync(),
        ) as Map<String, dynamic>;
        final marked = [
          for (final MapEntry(:key, :value) in arb.entries)
            if (!key.startsWith('@') &&
                value is String &&
                value.contains(arabicMarks))
              value,
        ];
        expect(marked, isNotEmpty);
        for (final s in marked) {
          expectMarksTakeNoRoom(s, font.family, FontWeight.w400);
        }
      });
    });
  }
}

/// Every Arabic mark the interface shows, alone and stacked: fatha,
/// damma, kasra, sukun, shadda, shadda with each haraka (both orders),
/// tanween, superscript alef, maddah, hamza above and below.
const markSamples = [
  'كَتَبَ',
  'كُتُب',
  'كِتَاب',
  'بِسْمِ',
  'محمّد',
  'مُحَمَّد',
  'مُحَمُّد',
  'مُحَمِّد',
  'مُحَم\u064E\u0651د', // the haraka typed before the shadda
  'رَبٌّ',
  'رَبًّا',
  'رَبٍّ',
  'الرَّحْمٰن',
  'لِلّٰهِ',
  'كِتَابًا',
  'كِتَابٌ',
  'كِتَابٍ',
  'آمَنَ',
  'ا\u0653منوا', // maddah as a mark
  'سَأَلَ',
  'سا\u0654ل', // hamza above as a mark
  'إِنَّ',
  'ا\u0655نسان', // hamza below as a mark
  'يُعدَّل',
  'محدَّث',
  'نُزِّل',
];

final arabicMarks = RegExp('[ً-ٰٕ]');

/// Alef with a maddah or hamza typed as a mark may be drawn as the
/// letter that carries it (آ أ إ): the word is then as wide as that one.
String _composed(String s) =>
    s.replaceAll('آ', 'آ').replaceAll('أ', 'أ').replaceAll('إ', 'إ');

void expectMarksTakeNoRoom(String text, String family, FontWeight weight) {
  double width(String s) {
    final p = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontFamily: family, fontSize: 20, fontWeight: weight),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    final w = p.width;
    p.dispose();
    return w;
  }

  final shaped = width(text);
  final bare = {
    text.replaceAll(arabicMarks, ''),
    _composed(text).replaceAll(arabicMarks, ''),
  };
  expect(
    bare.any((b) => (width(b) - shaped).abs() <= 0.5),
    isTrue,
    reason:
        '«$text» in $family ${weight.value} is $shaped wide, '
        '«${bare.first}» ${width(bare.first)}',
  );
}
