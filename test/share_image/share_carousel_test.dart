import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/share_image/share_carousel.dart';
import 'package:tibyan/l10n/app_localizations.dart';

/// The preview's carousel: buttons, keys, the wheel and a mouse drag turn
/// the pictures, in reading order; the buttons stop at the ends.
void main() {
  Future<List<int>> pump(
    WidgetTester tester, {
    int count = 3,
    String locale = 'en',
  }) async {
    final seen = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ShareCarousel(
            count: count,
            onPageChanged: seen.add,
            itemBuilder: (context, i) => Center(child: Text('picture $i')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return seen;
  }

  IconButton button(WidgetTester tester, String key) =>
      tester.widget<IconButton>(find.byKey(ValueKey(key)));

  testWidgets('the buttons turn the pictures and stop at the ends', (
    tester,
  ) async {
    final seen = await pump(tester);
    expect(find.text('picture 0'), findsOneWidget);
    expect(button(tester, 'share-previous').onPressed, isNull);
    expect(button(tester, 'share-next').onPressed, isNotNull);
    expect(find.byTooltip('Next picture'), findsOneWidget);
    expect(find.byTooltip('Previous picture'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('share-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('share-next')));
    await tester.pumpAndSettle();
    expect(find.text('picture 2'), findsOneWidget);
    expect(seen, [1, 2]);
    expect(button(tester, 'share-next').onPressed, isNull);
    expect(button(tester, 'share-previous').onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('share-previous')));
    await tester.pumpAndSettle();
    expect(find.text('picture 1'), findsOneWidget);
  });

  testWidgets('the next button is on the left, as the mushaf turns', (
    tester,
  ) async {
    await pump(tester);
    final next = tester.getCenter(find.byKey(const ValueKey('share-next')));
    final previous = tester.getCenter(
      find.byKey(const ValueKey('share-previous')),
    );
    expect(next.dx, lessThan(previous.dx));
  });

  testWidgets('arrow keys and Page Up/Down, in reading order', (tester) async {
    final seen = await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('picture 1'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(find.text('picture 2'), findsOneWidget);
    // At the end, forward does nothing.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('picture 2'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('picture 1'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.pumpAndSettle();
    expect(find.text('picture 0'), findsOneWidget);
    expect(seen, [1, 2, 1, 0]);
  });

  testWidgets('one wheel notch, one picture', (tester) async {
    await pump(tester);
    final at = tester.getCenter(find.text('picture 0'));
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(at));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 100)));
    await tester.pumpAndSettle();
    expect(find.text('picture 1'), findsOneWidget);
  });

  testWidgets('a mouse drags the pictures like a finger', (tester) async {
    await pump(tester);
    // The next picture lies to the left: dragging rightwards brings it.
    await tester.dragFrom(
      tester.getCenter(find.text('picture 0')),
      const Offset(500, 0),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(find.text('picture 1'), findsOneWidget);
  });

  testWidgets('Arabic labels', (tester) async {
    await pump(tester, locale: 'ar');
    expect(find.byTooltip('الصورة التالية'), findsOneWidget);
    expect(find.byTooltip('الصورة السابقة'), findsOneWidget);
  });

  testWidgets('one picture: no buttons', (tester) async {
    await pump(tester, count: 1);
    expect(find.byKey(const ValueKey('share-next')), findsNothing);
    expect(find.text('picture 0'), findsOneWidget);
  });
}
