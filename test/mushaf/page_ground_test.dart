import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/hifz/hifz_providers.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/illuminated_frame.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/mushaf_page.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/page_interaction.dart';

import '../tasmee/tasmee_test_env.dart';

/// Recitation covers (the hifz test, the audio tasmee) are painted in the
/// colour the page lies on: the paper inside a frame, the screen's
/// background where no frame is drawn (elderly mode, plain themes). Paper
/// on the background showed as light boxes over every covered line.
void main() {
  late TasmeeTestData data;
  setUpAll(() => data = TasmeeTestData.open());
  tearDownAll(() => data.close());

  Future<Color> coverColour(
    WidgetTester tester, {
    required bool elderly,
    required ThemeModeId mode,
  }) async {
    final container = await tasmeeContainer(tester, data);
    final theme = tasmeeTheme(container, mode: mode, elderly: elderly);
    final t = theme.extension<TibyanTokens>()!.colors;
    final units = (await tester.runAsync(
      () => container.read(pageRevealUnitsProvider(3).future),
    ))!;
    final verses = units.keys.toList();
    final boundary = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(400, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      tasmeeApp(
        container,
        Scaffold(
          backgroundColor: t.bg,
          body: IlluminatedFrame(
            info: null,
            child: MushafPage(
              page: 3,
              interaction: PageInteraction(
                selection: const {},
                marks: const {},
                onTap: () {},
                onVerseLongPress: (_) {},
                onMarkerTap: (_) {},
                onHandleDrag: (_, _) {},
                hidden: verses.toSet(),
                hiddenWords: {
                  for (final v in verses)
                    v: [for (final piece in units[v]!.pieces) ...piece],
                },
              ),
            ),
          ),
        ),
        theme: theme,
        boundary: boundary,
      ),
    );
    await settle(tester);
    final object =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = (await tester.runAsync(() async {
      final image = await object.toImage();
      final d = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return d!;
    }))!;
    // The middle of the page: a covered line of al-Baqarah 6-16.
    final page = tester.getRect(find.byType(MushafPage));
    final x = page.center.dx.round(), y = page.center.dy.round();
    final i = (y * 400 + x) * 4;
    return Color.fromARGB(
      bytes.getUint8(i + 3),
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    );
  }

  void expectSame(Color a, Color b) {
    expect(
      (a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs(),
      lessThan(4 / 255),
      reason: '$a vs $b',
    );
  }

  for (final mode in [ThemeModeId.light, ThemeModeId.night]) {
    testWidgets('elderly mode (${mode.name}): covers are the background', (
      tester,
    ) async {
      final container = await tasmeeContainer(tester, data);
      final t = tasmeeTheme(
        container,
        mode: mode,
        elderly: true,
      ).extension<TibyanTokens>()!.colors;
      expect(t.bg, isNot(t.paper), reason: 'the case this guards');
      expectSame(await coverColour(tester, elderly: true, mode: mode), t.bg);
    });
  }

  testWidgets('inside the frame: covers are the paper', (tester) async {
    final container = await tasmeeContainer(tester, data);
    final t = tasmeeTheme(container).extension<TibyanTokens>()!.colors;
    expectSame(
      await coverColour(tester, elderly: false, mode: ThemeModeId.light),
      t.paper,
    );
  });
}
