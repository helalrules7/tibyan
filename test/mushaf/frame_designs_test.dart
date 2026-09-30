import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/frame_art.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/illuminated_frame.dart';
import 'package:tibyan/l10n/app_localizations.dart';

const drawn = {
  FrameDesign.abbasid: 'abbasid',
  FrameDesign.umayyad: 'umayyad',
  FrameDesign.andalusian: 'andalusian',
  FrameDesign.ottoman: 'ottoman',
  FrameDesign.egyptian: 'egyptian',
  FrameDesign.modernIslamic: 'modern_islamic',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Zakhrafa and plain have no art; the six drawn designs do', () {
    expect(frameArtSet(FrameDesign.zakhrafa), isNull);
    expect(frameArtSet(FrameDesign.plain), isNull);
    for (final e in drawn.entries) {
      expect(frameArtSet(e.key), e.value);
    }
  });

  group('the owner\'s pieces', () {
    final sources = <String, FrameSources>{};
    final art = <String, FrameArt>{};
    setUpAll(() async {
      for (final set in drawn.values) {
        sources[set] = await loadFrameSources(set, bundle: rootBundle);
        art[set] = await buildFrameArt(sources[set]!);
      }
    });

    for (final set in drawn.values) {
      test('$set: every piece loads at its size', () {
        final a = art[set]!;
        expect(a.pictures.keys, FramePiece.values);
        expect(a[FramePiece.corner].size, const Size(46, 46));
        expect(a[FramePiece.edgeH].size, const Size(24, 34));
        expect(a[FramePiece.edgeV].size, const Size(34, 24));
        expect(a[FramePiece.medal].size, const Size(60, 60));
        expect(a[FramePiece.splash].size, const Size(1080, 1920));
        expect(a[FramePiece.openA].size, const Size(650, 900));
        expect(a[FramePiece.openB].size, const Size(650, 900));
        final d = a[FramePiece.divider].size;
        expect(d.width / d.height, greaterThan(4));
      });

      test(
        '$set: colours and the divider\'s text panel come from the SVGs',
        () {
          final src = sources[set]!;
          expect(src.colours.dark, set == 'egyptian');
          expect(src.colours.ink, isNot(src.colours.ground));
          final p = src.dividerPanel;
          expect(p.left, greaterThan(0.1));
          expect(p.right, lessThan(0.9));
          expect(p.left + p.right, closeTo(1, 0.02));
          expect(p.top, greaterThan(0));
          expect(p.bottom, lessThan(1));
        },
      );

      test('$set: the opening pages have the panel and title box assumed', () {
        for (final (piece, dx) in [
          (FramePiece.openA, 50),
          (FramePiece.openB, 700),
        ]) {
          final svg = sources[set]!.svg[piece]!;
          expect(svg, contains('viewBox="$dx 50 650 900"'));
          final shift = Offset(dx.toDouble(), 50);
          final panel = OpeningPlaces.panel.shift(shift);
          final title = OpeningPlaces.title.shift(shift);
          String rect(Rect r) =>
              '<rect x="${r.left.round()}" y="${r.top.round()}" '
              'width="${r.width.round()}" height="${r.height.round()}"';
          expect(svg, contains(rect(panel)));
          expect(svg, contains(rect(title)));
          // The page sits in the panel, clear of the title box.
          expect(
            OpeningPlaces.panel.contains(OpeningPlaces.page.topLeft),
            isTrue,
          );
          expect(
            OpeningPlaces.page.top,
            greaterThanOrEqualTo(OpeningPlaces.title.bottom),
          );
          expect(OpeningPlaces.page.bottom, OpeningPlaces.panel.bottom);
        }
      });
    }

    test(
      'the band paints at several sizes: art at the edges, paper inside',
      () async {
        for (final set in drawn.values) {
          final a = art[set]!;
          for (final size in const [
            Size(320, 560),
            Size(392, 740),
            Size(800, 1150),
          ]) {
            final recorder = ui.PictureRecorder();
            const paper = Color(0xFFFFFFFF);
            ArtBandPainter(art: a, paper: paper).paint(Canvas(recorder), size);
            final image = await recorder.endRecording().toImage(
              size.width.round(),
              size.height.round(),
            );
            final bytes = (await image.toByteData())!;
            Color at(double x, double y) {
              final i = (y.round() * image.width + x.round()) * 4;
              return Color.fromARGB(
                bytes.getUint8(i + 3),
                bytes.getUint8(i),
                bytes.getUint8(i + 1),
                bytes.getUint8(i + 2),
              );
            }

            // The outer rule runs 4 units (about 3 px) in from each edge.
            for (final p in [
              Offset(size.width / 2, 3.1),
              Offset(size.width / 2, size.height - 3.1),
              Offset(3.1, size.height / 2),
              Offset(size.width - 3.1, size.height / 2),
            ]) {
              expect(at(p.dx, p.dy), isNot(paper), reason: '$set $size $p');
            }
            expect(at(size.width / 2, size.height / 2), paper);
          }
        }
      },
    );
  });

  test('dark modes: light designs take the theme\'s paper and ink', () {
    const light = FrameColours(
      ground: Color(0xFFF4EBD0),
      ink: Color(0xFF173F3A),
      gold: Color(0xFFB08A3E),
    );
    const navy = FrameColours(
      ground: Color(0xFF0E2434),
      ink: Color(0xFFE9D7A2),
      gold: Color(0xFFC59A42),
    );
    const t = ModeTokens(
      bg: Color(0xFF000000),
      paper: Color(0xFF103428),
      ink: Color(0xFFE9E1CC),
      muted: Color(0xFF888888),
      border: Color(0xFF888888),
      frame: Color(0xFF888888),
      marker: Color(0xFF888888),
      goldText: Color(0xFF888888),
      headBg: Color(0xFF888888),
      headFg: Color(0xFF888888),
      accent: Color(0xFF888888),
      accentFg: Color(0xFF888888),
      player: Color(0xFF888888),
      playerFg: Color(0xFF888888),
      highlight: Color(0xFF888888),
      control: Color(0xFF888888),
      onControl: Color(0xFF888888),
    );
    expect(darkModeSwap(light, ThemeModeId.light, t), isNull);
    expect(darkModeSwap(navy, ThemeModeId.night, t), isNull);
    expect(darkModeSwap(light, ThemeModeId.black, t), (
      paper: t.paper,
      ink: t.ink,
    ));
    expect(
      recolourSvg('<a fill="#f4ebd0" stroke="#173F3A" x="#B08A3E"/>', {
        light.ground: t.paper,
        light.ink: t.ink,
      }),
      '<a fill="#103428" stroke="#E9E1CC" x="#B08A3E"/>',
    );
  });

  testWidgets('an opening page puts the mushaf page inside the text panel', (
    tester,
  ) async {
    final registry = await ThemeRegistry.load(rootBundle);
    final style = registry.byId('royal');
    late FrameSources src;
    late FrameArt art;
    await tester.runAsync(() async {
      src = await loadFrameSources('ottoman', bundle: rootBundle);
      art = await buildFrameArt(src);
    });
    for (final size in const [
      Size(360, 640),
      Size(392, 780),
      Size(800, 1100),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final page = GlobalKey();
      final box = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            frameDesignProvider.overrideWithValue(FrameDesign.ottoman),
            frameSourcesFamily.overrideWith((ref, s) async => src),
            frameArtFamily.overrideWith((ref, k) async => art),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildTheme(
              style: style,
              mode: ThemeModeId.light,
              uiFont: UiFont.plex,
            ),
            home: Material(
              child: OrnateFrame(
                key: box,
                openingSurah: 1,
                page: 1,
                top: const Text('top'),
                bottom: const Text('bottom'),
                child: SizedBox.expand(key: page),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      final frame = tester.getRect(find.byKey(box));
      final body = Rect.fromLTWH(
        frame.left,
        frame.top,
        frame.width,
        frame.height - IlluminatedFrame.catchwordSpace,
      );
      final picture = fittedRect(const Size(650, 900), body, BoxFit.contain);
      final panel = mapRect(OpeningPlaces.panel, const Size(650, 900), picture);
      final child = tester.getRect(find.byKey(page));
      expect(
        panel.inflate(0.01).contains(child.topLeft),
        isTrue,
        reason: '$size',
      );
      expect(
        panel.inflate(0.01).contains(child.bottomRight),
        isTrue,
        reason: '$size',
      );
      expect(child.width, closeTo(panel.width, 0.01));
    }
    addTearDown(tester.view.reset);
  });

  group('frameDesignProvider', () {
    Future<ProviderContainer> containerWith(Map<String, Object> prefs) async {
      // The bundle caches loads made under the widget test's clock.
      rootBundle.clear();
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
}
