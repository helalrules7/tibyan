import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/route_settle.dart';

void main() {
  testWidgets('a neighbour waits for the route entrance, the page shown '
      'does not', (t) async {
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(MaterialApp(navigatorKey: nav, home: const SizedBox()));
    late BuildContext neighbour, shown;
    unawaited(
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => Column(
            children: [
              PageNeighbourScope(
                neighbour: true,
                child: Builder(
                  builder: (c) {
                    neighbour = c;
                    return const Text('n');
                  },
                ),
              ),
              PageNeighbourScope(
                neighbour: false,
                child: Builder(
                  builder: (c) {
                    shown = c;
                    return const Text('s');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await t.pump(); // route built, entrance starts
    var n = false, s = false;
    unawaited(neighbourSettled(neighbour).then((_) => n = true));
    unawaited(neighbourSettled(shown).then((_) => s = true));
    await t.pump(const Duration(milliseconds: 50));
    expect(s, isTrue);
    expect(n, isFalse);
    await t.pumpAndSettle();
    expect(n, isTrue);
  });

  testWidgets('outside a pager nothing waits', (t) async {
    late BuildContext ctx;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    var done = false;
    unawaited(neighbourSettled(ctx).then((_) => done = true));
    await t.pump();
    expect(done, isTrue);
  });
}
