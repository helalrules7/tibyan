import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/mushaf/presentation/page_spreads.dart';

void main() {
  test('single pages: one page per index', () {
    const s = PageSpreads(first: 0, base: 1, pageCount: 604, spread: false);
    expect(s.indexOf(0), 0);
    expect(s.indexOf(604), 604);
    expect(s.pagesAt(5), [5]);
    expect(s.count, 605);
  });

  test('Madina: the cover alone, then 1–2, 3–4 … 603–604', () {
    const s = PageSpreads(first: 0, base: 1, pageCount: 604, spread: true);
    expect(s.pagesAt(0), [0]);
    expect(s.pagesAt(1), [1, 2]);
    expect(s.pagesAt(2), [3, 4]);
    expect(s.indexOf(2), 1);
    expect(s.indexOf(3), 2);
    expect(s.indexOf(604), 302);
    expect(s.pagesAt(302), [603, 604]);
    expect(s.count, 303);
  });

  test('Shamarly: its cover alone, then 2–3; an odd last page alone', () {
    const s = PageSpreads(first: 1, base: 2, pageCount: 523, spread: true);
    expect(s.pagesAt(0), [1]);
    expect(s.pagesAt(1), [2, 3]);
    expect(s.indexOf(523), s.count - 1);
    expect(s.pagesAt(s.count - 1), [522, 523]);
    const odd = PageSpreads(first: 1, base: 2, pageCount: 522, spread: true);
    expect(odd.pagesAt(odd.count - 1), [522]);
  });

  test('every page maps back to an index that shows it', () {
    const s = PageSpreads(first: 0, base: 1, pageCount: 604, spread: true);
    for (var p = 0; p <= 604; p++) {
      expect(s.pagesAt(s.indexOf(p)), contains(p));
    }
  });
}
