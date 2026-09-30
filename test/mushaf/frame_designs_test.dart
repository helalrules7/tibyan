import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/frame_design_painters.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/frame_design_spec.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/illuminated_frame.dart';

const drawn = [
  FrameDesign.abbasid,
  FrameDesign.umayyad,
  FrameDesign.andalusian,
  FrameDesign.ottoman,
  FrameDesign.egyptian,
  FrameDesign.modernIslamic,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Zakhrafa and plain have no spec; the six drawn designs do', () {
    expect(frameSpecAsset(FrameDesign.zakhrafa), isNull);
    expect(frameSpecAsset(FrameDesign.plain), isNull);
    expect(
      frameSpecAsset(FrameDesign.modernIslamic),
      'assets/config/frame_modern_islamic.json',
    );
  });

  for (final d in drawn) {
    test('spec of ${d.name} loads with every part', () async {
      final spec = await loadFrameSpec(d, bundle: rootBundle);
      expect(spec.palette.keys, containsAll(DesignRole.values));
      expect(spec.rules, hasLength(3));
      expect(spec.rhythmSpacing, greaterThan(0));
      expect(spec.corner.shapes, isNotEmpty);
      expect(spec.cornerExtent, greaterThan(0));
      expect(spec.medallion.shapes, isNotEmpty);
      expect(spec.rosette.shapes, isNotEmpty);
      expect(spec.outer.half, greaterThan(spec.inner.half));
      expect(spec.cover.shapes, isNotEmpty);
      expect(spec.coverRules, isNotEmpty);
      expect(spec.openings.keys, [1, 2]);
      expect(spec.openings[1]!.ornament.shapes, isNotEmpty);
      expect(spec.signature.shapes, isNotEmpty);
      expect(spec.dark, d == FrameDesign.egyptian);
    });
  }

  group('frameDesignProvider', () {
    Future<ProviderContainer> containerWith(Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues(prefs);
      final registry = await ThemeRegistry.load(rootBundle);
      final sp = await SharedPreferences.getInstance();
      return ProviderContainer(
        overrides: [
          themeRegistryProvider.overrideWithValue(registry),
          sharedPreferencesProvider.overrideWithValue(sp),
        ],
      );
    }

    const defaults = {
      'zakhrafa': FrameDesign.zakhrafa,
      'royal': FrameDesign.abbasid,
      'classic': FrameDesign.ottoman,
      'manuscript': FrameDesign.andalusian,
      'calm': FrameDesign.modernIslamic,
    };
    for (final e in defaults.entries) {
      test('style ${e.key} frames with ${e.value.name}', () async {
        final c = await containerWith({'settings.style': e.key});
        expect(c.read(frameDesignProvider), e.value);
      });
    }

    test('the reader\'s choice wins over the style\'s own', () async {
      final c = await containerWith({'settings.style': 'royal'});
      await c
          .read(settingsProvider.notifier)
          .setFrameDesign(FrameDesign.egyptian);
      expect(c.read(frameDesignProvider), FrameDesign.egyptian);
      await c.read(settingsProvider.notifier).setFrameDesign(null);
      expect(c.read(frameDesignProvider), FrameDesign.abbasid);
    });
  });

  test('painters draw every design, mode and size without throwing', () async {
    final registry = await ThemeRegistry.load(rootBundle);
    const sizes = [Size(320, 560), Size(392, 780), Size(800, 1150)];
    for (final d in drawn) {
      final spec = await loadFrameSpec(d, bundle: rootBundle);
      for (final style in registry.styles) {
        for (final mode in ThemeModeId.values) {
          final p = FramePalette.resolve(spec, style.modes[mode]!, mode);
          for (final size in sizes) {
            final canvas = Canvas(PictureRecorder());
            final panel = Rect.fromLTRB(
              26,
              size.height * 0.215,
              size.width - 26,
              size.height * 0.785,
            );
            final layout = OrnateLayout(size, panel, 30, spec.look.arch);
            DesignFramePainter(spec: spec, palette: p).paint(canvas, size);
            DesignOrnatePainter(
              spec: spec,
              palette: p,
              layout: layout,
              cover: true,
            ).paint(canvas, size);
            DesignOrnatePainter(
              spec: spec,
              palette: p,
              layout: layout,
            ).paint(canvas, size);
            DesignBannerPainter(
              spec: spec,
              palette: p,
            ).paint(canvas, Size(size.width - 64, size.height / 17));
            DesignCartouchePainter(
              spec: spec,
              palette: p,
              bodyWidth: 190,
              rosette: 27,
              group: spec.medallion,
            ).paint(canvas, const Size(266, 30));
            DesignRosettePainter(
              spec: spec,
              palette: p,
              group: spec.signature,
            ).paint(canvas, const Size(34, 34));
            DesignTitlePainter(
              spec: spec,
              palette: p,
              ornament: spec.openings[2]!.ornament,
            ).paint(canvas, const Size(240, 60));
            expect(layout.fitWidth(80, 56), greaterThan(0));
          }
        }
      }
    }
  });
}
