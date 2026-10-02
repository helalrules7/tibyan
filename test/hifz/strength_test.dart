import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/hifz/domain/fsrs.dart';
import 'package:tibyan/features/hifz/domain/strength.dart';

void main() {
  test('strength from stability', () {
    expect(Strength.fromStability(0.49), Strength.weak);
    expect(Strength.fromStability(3.71), Strength.fair);
    expect(Strength.fromStability(13.8), Strength.fair);
    expect(Strength.fromStability(30), Strength.good);
    expect(Strength.fromStability(400), Strength.strong);
    expect(Strength.of(null), Strength.none);
    expect(Strength.of(3), Strength.good);
  });

  test('a verse result updates its strength', () {
    expect(afterVerseTest(Strength.strong, VerseResult.missed), Strength.weak);
    expect(
      afterVerseTest(Strength.none, VerseResult.remembered),
      Strength.fair,
    );
    expect(
      afterVerseTest(Strength.weak, VerseResult.remembered),
      Strength.fair,
    );
    expect(
      afterVerseTest(Strength.good, VerseResult.remembered),
      Strength.good,
    );
  });

  test('the suggested grade follows the share of missed verses', () {
    const r = VerseResult.remembered;
    const m = VerseResult.missed;
    expect(suggestGrade([]), Grade.good);
    expect(suggestGrade([r, r, r]), Grade.good);
    expect(suggestGrade([r, r, r, m]), Grade.hard);
    expect(suggestGrade([r, m]), Grade.again);
  });

  test('a cell takes its weakest memorized verse', () {
    final pages = {
      '1:1': [1],
      '1:2': [1],
      '2:1': [2],
      '2:2': [2, 3], // runs over a page break
      '2:3': [3],
    };
    final cells = cellStrengths({
      '1:1': 4,
      '1:2': 2,
      '2:2': 3,
      '2:3': 1,
    }, (r) => pages[r]!);
    expect(cells, {1: Strength.fair, 2: Strength.good, 3: Strength.weak});
    expect(cellStrengths({}, (r) => pages[r]!), isEmpty);
  });

  test('verse references', () {
    expect(verseRef(2, 255), '2:255');
    expect(parseVerseRef('114:6'), (114, 6));
  });
}
