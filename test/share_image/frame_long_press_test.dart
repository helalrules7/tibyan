import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/illuminated_frame.dart';

void main() {
  testWidgets('a tap on the surah name opens the index, a long press shares', (
    tester,
  ) async {
    var taps = 0, longPresses = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: FrameTap(
              label: 'البقرة',
              onTap: () => taps++,
              onLongPress: () => longPresses++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('البقرة'));
    await tester.pump();
    expect((taps, longPresses), (1, 0));
    await tester.longPress(find.text('البقرة'));
    await tester.pump();
    expect((taps, longPresses), (1, 1));
  });
}
