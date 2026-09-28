import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/mushaf/presentation/index_screen.dart';

void main() {
  test('verse references in Latin and Arabic digits', () {
    expect(parseVerseRef('2:255'), (surah: 2, ayah: 255));
    expect(parseVerseRef(' 2 255 '), (surah: 2, ayah: 255));
    expect(parseVerseRef('٢:٢٥٥'), (surah: 2, ayah: 255));
    expect(parseVerseRef('البقرة'), isNull);
    expect(parseVerseRef('255'), isNull);
  });
}
