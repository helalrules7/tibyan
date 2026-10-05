import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/mushaf/presentation/navigation.dart';

void main() {
  test('a verse link round-trips', () {
    final link = verseLink(2, 255);
    expect(link.toString(), 'tibyan://verse?s=2&a=255');
    expect(verseOfLink(link), (surah: 2, ayah: 255));
  });

  test('other links and bad numbers are not verses', () {
    expect(verseOfLink(Uri.parse('tibyan://khatma?page=3')), isNull);
    expect(verseOfLink(Uri.parse('https://verse?s=2&a=1')), isNull);
    expect(verseOfLink(Uri.parse('tibyan://verse?s=115&a=1')), isNull);
    expect(verseOfLink(Uri.parse('tibyan://verse?s=2')), isNull);
    expect(verseOfLink(null), isNull);
  });
}
