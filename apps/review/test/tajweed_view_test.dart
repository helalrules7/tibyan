import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan_review/src/model/model.dart';
import 'package:tibyan_review/src/ui/tajweed_view.dart';

void main() {
  test('reads the rule in brackets at the end of each line', () {
    final marks = TajweedMark.parse('ك3 ح2 «ٱللَّهِ» اللام الشمسية [lam_shamsiyyah 3:1:body]\n'
        'ك5 ح2 «كُلّٗا» الإدغام بغنة (الحركات) [idghaam_ghunnah 5:1:marks]\n'
        'a line without a rule');
    expect(marks.map((m) => (m.rule, m.word, m.letter, m.part)), [
      ('lam_shamsiyyah', 3, 1, 'body'),
      ('idghaam_ghunnah', 5, 1, 'marks'),
    ]);
  });

  test('a letter is a base character with the marks after it', () {
    expect(letterSpans('ٱللَّهِ'), [(0, 1), (1, 2), (2, 5), (5, 7)]);
  });

  testWidgets('colours the letter the data names, and lists the rule', (tester) async {
    const verse = Verse(1, 1, 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١', 1);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: TajweedVerseView(verse: verse, marks: [TajweedMark('lam_shamsiyyah', 3, 1, 'body')]),
      ),
    ));
    final rich = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
    final coloured = <String>[];
    rich.visitChildren((s) {
      if (s is TextSpan && s.style?.color == tajweedColours['lam_shamsiyyah']) coloured.add(s.text!);
      return true;
    });
    expect(coloured, ['ل']);
    expect(find.text('اللام الشمسية'), findsOneWidget);
  });
}
