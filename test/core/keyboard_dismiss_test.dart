import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tibyan/core/router/keyboard_dismiss.dart';

/// The keyboard closes when the screen changes, when a tap lands outside
/// the field, and when the reader swipes to another tab.
void main() {
  Widget field({bool autofocus = false}) => Scaffold(
    body: Column(
      children: [
        TextField(key: const Key('field'), autofocus: autofocus),
        const SizedBox(height: 300, child: Text('outside')),
      ],
    ),
  );

  Future<GoRouter> app(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/search',
      observers: [KeyboardDismissObserver()],
      routes: [
        GoRoute(path: '/search', builder: (_, _) => field()),
        GoRoute(
          path: '/index',
          builder: (_, _) => const Scaffold(body: Text('no field here')),
        ),
        GoRoute(path: '/find', builder: (_, _) => field(autofocus: true)),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        actions: {...WidgetsApp.defaultActions, ...tapOutsideActions()},
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('leaving a screen with a field closes the keyboard', (
    tester,
  ) async {
    final router = await app(tester);
    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    router.push('/index');
    await tester.pumpAndSettle();
    expect(find.text('no field here'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('returning to a screen does not bring its keyboard back', (
    tester,
  ) async {
    final router = await app(tester);
    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();
    router.push('/index');
    await tester.pumpAndSettle();

    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('field')), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(
      FocusManager.instance.primaryFocus?.context?.widget,
      isNot(isA<EditableText>()),
    );
  });

  testWidgets('a screen that focuses its own field keeps it', (tester) async {
    final router = await app(tester);
    router.push('/find');
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('a tap outside the field closes it; a drag does not', (
    tester,
  ) async {
    await app(tester);
    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.drag(find.text('outside'), const Offset(0, -80));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.text('outside'), kind: PointerDeviceKind.touch);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('a swipe to another tab closes it', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: Scaffold(
            body: DismissKeyboardOnSwipe(
              child: TabBarView(
                children: [
                  Column(children: [TextField(key: const Key('field'))]),
                  const Text('pages'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.fling(find.byType(TabBarView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('pages'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);
  });
}
