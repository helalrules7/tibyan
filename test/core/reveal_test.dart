import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/theme/reveal.dart';

/// The bars that come and go on a tap: a short fade and slide, or none
/// when less motion is asked for.
void main() {
  Widget host(bool visible, {bool reduce = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduce),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: Reveal(
            visible: visible,
            from: const Offset(0, -0.25),
            child: visible
                ? const SizedBox(height: 80, child: Text('menus'))
                : null,
          ),
        ),
      ),
    ),
  );

  double opacity(WidgetTester tester) => tester
      .widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('menus'),
              matching: find.byType(FadeTransition),
            )
            .first,
      )
      .opacity
      .value;

  testWidgets('fades and slides in, then out, in 200 ms', (tester) async {
    await tester.pumpWidget(host(false));
    expect(find.text('menus'), findsNothing);

    await tester.pumpWidget(host(true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(opacity(tester), inExclusiveRange(0.0, 1.0));
    // Still sliding down from above its place.
    expect(tester.getTopLeft(find.text('menus')).dy, lessThan(0));
    await tester.pump(const Duration(milliseconds: 120));
    expect(opacity(tester), 1.0);
    expect(tester.getTopLeft(find.text('menus')).dy, 0);

    // Hidden: the last bar shown fades out, out of reach of taps and of
    // screen readers, and is gone once it has.
    await tester.pumpWidget(host(false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('menus'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('menus'),
        matching: find.byWidgetPredicate(
          (w) => w is IgnorePointer && w.ignoring,
        ),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('menus'), findsNothing);
  });

  testWidgets('less motion: at once, both ways', (tester) async {
    await tester.pumpWidget(host(false, reduce: true));
    await tester.pumpWidget(host(true, reduce: true));
    await tester.pump();
    expect(opacity(tester), 1.0);
    expect(tester.getTopLeft(find.text('menus')).dy, 0);
    await tester.pumpWidget(host(false, reduce: true));
    await tester.pump();
    expect(find.text('menus'), findsNothing);
  });
}
