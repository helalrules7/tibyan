import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/mushaf/data/divine_names.dart';

void main() {
  test('the divine name and its attached forms are recognised', () {
    for (final w in [
      'ٱللَّهِ',
      'لِلَّهِ',
      'بِٱللَّهِ',
      'وَٱللَّهُ',
      'فَٱللَّهُ',
      'تَٱللَّهِ',
      'ٱللَّهُمَّ',
      'رَبِّ',
      'رَبَّنَا',
      'وَرَبَّنَا',
    ]) {
      expect(isDivineName(w), isTrue, reason: w);
    }
  });

  test('other words are not', () {
    for (final w in [
      'لَهُۥ',
      'إِلَٰهَ',
      'رَبِّكَ',
      'أَرۡبَابٗا',
      'ٱلۡأَرۡضِ',
      'لَهُمۡ',
      // «My Lord» in the Warsh text, with yeh barree (Warsh 3:50).
      '\u0631\u064e\u0628\u0651\u0650\u06d2',
    ]) {
      expect(isDivineName(w), isFalse, reason: w);
    }
  });
}
