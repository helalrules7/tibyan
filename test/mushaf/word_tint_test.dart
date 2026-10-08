import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/mushaf_page.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/page_interaction.dart';

import '../tasmee/tasmee_test_env.dart';

/// A word's own letters drawn in another colour (the audio tasmee's word
/// states), and marks drawn over a word where it lands on screen.
void main() {
  late TasmeeTestData data;
  setUpAll(() => data = TasmeeTestData.open());
  tearDownAll(() => data.close());

  testWidgets('a tinted word is drawn in its colour, only inside its box', (
    tester,
  ) async {
    final container = await tasmeeContainer(tester, data);
    final boxes = (await tester.runAsync(
      () => container.read(pageWordBoxesProvider(3).future),
    ))!;
    const red = Color(0xFFFF0000);
    final word = boxes[(2, 6, 1)]!;
    Rect? onScreen;
    final boundary = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(400, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      tasmeeApp(
        container,
        MushafPage(
          page: 3,
          interaction: PageInteraction(
            selection: const {},
            marks: const {},
            onTap: () {},
            onVerseLongPress: (_) {},
            onMarkerTap: (_) {},
            onHandleDrag: (_, _) {},
            wordTints: {red: word},
            wordOverlay: (canvas, toScreen) => onScreen = toScreen(word.first),
          ),
        ),
        theme: tasmeeTheme(container, mode: ThemeModeId.light),
        boundary: boundary,
      ),
    );
    await settle(tester);
    expect(onScreen, isNotNull);
    final object =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = (await tester.runAsync(() async {
      final image = await object.toImage();
      final d = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return d!;
    }))!;
    bool redAt(int x, int y) {
      final i = (y * 400 + x) * 4;
      return bytes.getUint8(i) > 200 &&
          bytes.getUint8(i + 1) < 90 &&
          bytes.getUint8(i + 2) < 90;
    }

    var inside = 0, outside = 0;
    final r = onScreen!;
    for (var y = 0; y < 700; y++) {
      for (var x = 0; x < 400; x++) {
        if (!redAt(x, y)) continue;
        r.inflate(1).contains(Offset(x + 0.5, y + 0.5)) ? inside++ : outside++;
      }
    }
    expect(inside, greaterThan(20), reason: 'the word is red');
    expect(outside, 0, reason: 'nothing else is');
  });
}
