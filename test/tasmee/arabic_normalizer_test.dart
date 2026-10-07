import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tibyan/features/tasmee/domain/arabic_normalizer.dart';

/// The Uthmani word (as stored in content.db `display_text`, KFGQPC Hafs)
/// and the same word as a recogniser writes it (the common spelling).
const _pairs = <(String, String)>[
  // Dagger alif.
  ('ٱلرَّحۡمَٰنِ', 'الرحمن'),
  ('مَٰلِكِ', 'مالك'),
  ('ٱلۡعَٰلَمِينَ', 'العالمين'),
  ('ٱلۡكِتَٰبُ', 'الكتاب'),
  ('رَزَقۡنَٰهُمۡ', 'رزقناهم'),
  ('سُبۡحَٰنَ', 'سبحان'),
  // Dagger alif the common spelling leaves unwritten.
  ('ذَٰلِكَ', 'ذلك'),
  ('هَٰٓؤُلَآءِ', 'هؤلاء'),
  ('وَلَٰكِنَّ', 'ولكن'),
  ('أُوْلَٰٓئِكَ', 'أولئك'),
  ('وَأُوْلَٰٓئِكَ', 'وأولئك'),
  ('أَوۡلَٰدَهُنَّ', 'أولادهن'),
  // Waw for a long a (الصلوة).
  ('ٱلصَّلَوٰةَ', 'الصلاة'),
  ('ٱلزَّكَوٰةَ', 'الزكاة'),
  ('ٱلۡحَيَوٰةِ', 'الحياة'),
  ('حَيَوٰةٖ', 'حياة'),
  ('ٱلرِّبَوٰاْ', 'الربا'),
  ('مَوَٰقِيتُ', 'مواقيت'),
  // Alif maqsura with a dagger alif.
  ('عَلَىٰ', 'على'),
  ('إِلَىٰٓ', 'إلى'),
  ('ٱتَّقَىٰۗ', 'اتقى'),
  ('وَٱلتَّوۡرَىٰةَ', 'والتوراة'),
  ('وَءَاتَىٰهُ', 'وآتاه'),
  ('أَتَىٰكُمۡ', 'أتاكم'),
  ('مَوۡلَىٰنَا', 'مولانا'),
  ('وَيَنۡهَىٰهُمۡ', 'وينهاهم'),
  // Hamza seats.
  ('يَسۡـَٔلُونَكَ', 'يسألونك'),
  ('أَرَءَيۡتَكُمۡ', 'أرأيتكم'),
  ('مُتَّكِـُٔونَ', 'متكئون'),
  ('ٱلۡأَرَآئِكِ', 'الأرائك'),
  ('يُؤۡمِنُونَ', 'يؤمنون'),
  ('ءَالَآءِ', 'آلاء'),
  ('بَرَآءَةٞ', 'براءة'),
  ('تَسَآءَلُونَ', 'تساءلون'),
  ('إِسۡرَٰٓءِيلَ', 'إسرائيل'),
  ('ٱلۡقُرۡءَانُ', 'القرآن'),
  ('خَطِيٓـَٔتُهُۥ', 'خطيئته'),
  // A sad with a small seen above, read as seen.
  ('وَيَبۡصُۜطُ', 'ويبسط'),
  // Small waw and yeh.
  ('لَهُۥ', 'له'),
  ('بِهِۦ', 'به'),
  ('وَعَلَّمَهُۥ', 'وعلمه'),
  ('دَاوُۥدُ', 'داوود'),
  ('إِبۡرَٰهِـۧمَ', 'إبراهيم'),
  ('يُحۡيِۦ', 'يحيي'),
  ('يُحۡيِ', 'يحيي'),
  ('وَأُحۡيِ', 'وأحيي'),
  ('لَمُحۡيِ', 'لمحيي'),
  ('ٱلۡحَيُّ', 'الحي'),
  // One lam for two.
  ('ٱلَّيۡلَ', 'الليل'),
  // Waqf signs and tanween forms of the KFGQPC text.
  ('رَيۡبَۛ', 'ريب'),
  ('هُدٗى', 'هدى'),
  ('بِبَعۡضٖ', 'ببعض'),
  ('جَاعِلٞ', 'جاعل'),
  ('رَّبِّهِمۡۖ', 'ربهم'),
  ('بَصِيرُۢ', 'بصير'),
  // Silent alif after waw.
  ('قَالُوٓاْ', 'قالوا'),
  ('وَأَقِيمُواْ', 'وأقيموا'),
];

void main() {
  group('normalizeArabicWord', () {
    for (final (uthmani, common) in _pairs) {
      test('$uthmani = $common', () {
        final key = normalizeArabicWord(uthmani);
        expect(key, isNotEmpty);
        expect(key, normalizeArabicWord(common));
      });
    }

    test('removes vowels, shadda, sukun and tatweel', () {
      expect(normalizeArabicWord('بِسْمِ'), 'بسم');
      expect(normalizeArabicWord('اللَّهِ'), 'الله');
      expect(normalizeArabicWord('الـرحـيـم'), 'الرحيم');
    });

    test('one form for alifs, hamzas, ta marbuta and alif maqsura', () {
      expect(normalizeArabicWord('أإآٱا'), 'ا');
      expect(normalizeArabicWord('مؤمن'), 'مومن');
      expect(normalizeArabicWord('شيئا'), 'شيا');
      expect(normalizeArabicWord('رحمة'), normalizeArabicWord('رحمه'));
      expect(normalizeArabicWord('هدى'), normalizeArabicWord('هدي'));
    });

    test('a verse number or a lone sign is no word', () {
      expect(normalizeArabicWord('ﰀ'), isEmpty);
      expect(normalizeArabicWord('۞'), isEmpty);
      expect(normalizeArabicWord('ۖ'), isEmpty);
      expect(normalizeArabicWord('12'), isEmpty);
    });

    test('keeps words that differ by a letter apart', () {
      expect(
        normalizeArabicWord('يَعۡمَلُونَ'),
        isNot(normalizeArabicWord('تَعۡمَلُونَ')),
      );
      expect(normalizeArabicWord('قَالَ'), isNot(normalizeArabicWord('قُلۡ')));
    });

    test('Persian letter forms a recogniser may write', () {
      expect(normalizeArabicWord('یوم'), normalizeArabicWord('يوم'));
      expect(normalizeArabicWord('کتاب'), normalizeArabicWord('كتاب'));
    });

    test('the vocative written as one word joins the two common ones', () {
      expect(
        normalizeArabicWord('يَٰٓأَيُّهَا'),
        joinKeys(matchingWords('يا أيها')),
      );
      expect(
        normalizeArabicWord('يَٰبَنِيٓ'),
        joinKeys(matchingWords('يا بني')),
      );
    });

    test('takes another rule table', () {
      const rules = [SpellingRule('^الم\$', 'الف لام ميم', 'test')];
      expect(normalizeArabicWord('الم', rules: rules), 'الفلامميم');
    });
  });

  group('normalizeArabic', () {
    test('a whole verse, from KFGQPC and from plain text', () {
      const display =
          'ٱلَّذِينَ يُؤۡمِنُونَ بِٱلۡغَيۡبِ وَيُقِيمُونَ ٱلصَّلَوٰةَ '
          'وَمِمَّا رَزَقۡنَٰهُمۡ يُنفِقُونَ\u00A0ﰂ';
      const plain = 'الذين يؤمنون بالغيب ويقيمون الصلاة ومما رزقناهم ينفقون';
      expect(normalizeArabic(display), normalizeArabic(plain));
      expect(matchingWords(display), hasLength(8));
    });

    test('a hizb sign and a verse number are not words', () {
      expect(matchingWords('۞\u00A0يَسۡـَٔلُونَكَ عَنِ\u00A0ﰀ'), [
        'يسالونك',
        'عن',
      ]);
    });

    test('recogniser output with punctuation and Latin', () {
      expect(
        normalizeArabic(' بِسْمِ اللَّهِ، الرَّحْمَنِ  (1) the '),
        'بسم الله الرحمن',
      );
    });
  });

  // The whole Quran: KFGQPC words against Tanzil's Simple Clean words (the
  // common spelling, verbatim) wherever a verse has as many of each.
  test('agrees with the common spelling on 99.7% of the Quran', () {
    final file = File('assets/db/content.db');
    final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
    addTearDown(db.close);
    final letters = RegExp('[ء-يٱ-ۓ]');
    var words = 0, agree = 0;
    for (final row in db.select(
      'SELECT display_text, text_search, search_basmala_prefix FROM ayah',
    )) {
      final display = [
        for (final w in (row['display_text'] as String).split(
          RegExp(r'[\s\u00A0]+'),
        ))
          if (letters.hasMatch(w)) w,
      ];
      final search = (row['text_search'] as String)
          .substring(row['search_basmala_prefix'] as int)
          .trim()
          .split(' ');
      if (display.length != search.length) continue;
      for (var i = 0; i < display.length; i++) {
        words++;
        if (normalizeArabicWord(display[i]) == normalizeArabicWord(search[i])) {
          agree++;
        }
      }
    }
    expect(words, greaterThan(70000));
    expect(agree / words, greaterThan(0.997));
  });
}
