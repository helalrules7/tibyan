import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/onboarding/page_preview.dart';

/// Not a test: draws every style's preview in every mode, live, into
/// `build/theme_previews/<style>_<mode>.png`, for
/// tools/render_theme_previews.sh to turn into the images the theme picker
/// shows. Runs only with RENDER_THEME_PREVIEWS=1.
void main() {
  final run = Platform.environment['RENDER_THEME_PREVIEWS'] == '1';

  testWidgets('render theme previews', (tester) async {
    final registry = await tester.runAsync(
      () => ThemeRegistry.load(rootBundle),
    );
    final out = Directory('build/theme_previews')..createSync(recursive: true);
    await tester.binding.setSurfaceSize(const Size(300, 380));
    for (final style in registry!.styles) {
      for (final mode in ThemeModeId.values) {
        final boundary = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [themeRegistryProvider.overrideWithValue(registry)],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Center(
                child: RepaintBoundary(
                  key: boundary,
                  child: RealPagePreview(
                    style: style,
                    mode: mode,
                    semanticLabel: style.id,
                    prebuilt: false,
                  ),
                ),
              ),
            ),
          ),
        );
        // The page and the theme's art are compiled on worker isolates.
        for (var i = 0; i < 60; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
        }
        final object =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final bytes = await tester.runAsync(() async {
          final image = await object.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          return data!.buffer.asUint8List();
        });
        File('${out.path}/${style.id}_${mode.name}.png').writeAsBytesSync(
          bytes!,
        );
      }
    }
  }, skip: !run);
}
