import 'dart:io';
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
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/illuminated_frame.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/reading_bar.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/page_interaction.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/theme_art.dart';
import 'package:tibyan/l10n/app_localizations.dart';

const heritage = [
  'seljuk',
  'umayyad',
  'timurid',
  'hijazi',
  'fatimid',
  'andalusi',
  'mamluk',
  'abbasid',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeRegistry registry;
  setUpAll(() async => registry = await ThemeRegistry.load(rootBundle));

  group('theme files', () {
    test('Zakhrafa first and default, then the plain and heritage themes', () {
      expect(registry.defaultStyleId, 'zakhrafa');
      expect(registry.styles.map((s) => s.id), [
        'zakhrafa',
        'simple',
        ...heritage,
      ]);
    });

    test('every style has four modes; only the heritage themes have art', () {
      for (final style in registry.styles) {
        expect(style.modes.keys.toSet(), ThemeModeId.values.toSet());
        expect(style.name['ar'], isNotEmpty, reason: style.id);
        expect(style.name['en'], isNotEmpty, reason: style.id);
        expect(style.description['ar'], isNotEmpty, reason: style.id);
        if (style.frame.outerStyle != 'art') {
          // Zakhrafa keeps its own illuminated frame, the plain theme none.
          expect(style.art, isNull);
          continue;
        }
        final art = style.art!;
        expect(art.colours.keys.toSet(), ThemeModeId.values.toSet());
        expect(art.band, greaterThan(0));
        for (final f in [...art.frame.files, art.header, art.marker]) {
          expect(f, startsWith('${style.id}_'), reason: f);
        }
        // Bright white puts the art on pure white paper.
        expect(style.modes[ThemeModeId.white]!.paper, const Color(0xFFFFFFFF));
      }
    });

    for (final id in heritage) {
      test('$id: every piece loads in every mode, with its slots', () async {
        final art = registry.byId(id).art!;
        for (final mode in ThemeModeId.values) {
          final p = await loadThemeArt(art, mode, bundle: rootBundle);
          expect(p.header.slot, isNotNull, reason: '$id header');
          expect(p.marker.slot, isNotNull, reason: '$id marker');
          for (final (piece, slot) in [
            (p.header, p.header.slot!),
            (p.marker, p.marker.slot!),
          ]) {
            expect(
              (Offset.zero & piece.size).contains(slot.center),
              isTrue,
              reason: '$id $mode',
            );
          }
          if (art.frame.whole != null) {
            expect(p.whole!.slot, isNotNull);
          } else {
            expect(p.corner!.size.isEmpty, isFalse);
            expect(p.edgeH!.size.isEmpty, isFalse);
            expect(p.edgeV!.size.isEmpty, isFalse);
          }
        }
      });
    }
  });

  group('recolouring', () {
    const svg =
        '<svg viewBox="0 0 10 10"><g class="c1" fill="#ffffff"><path/></g>'
        '<g fill="#bea2ad" class="c2" data-part="c2"><path/></g>'
        '<g class="c3" fill="#123456"><path/></g>'
        '<g fill="none" stroke="#235b75" stroke-linecap="round" class="line">'
        '<path/></g></svg>';

    test('changes only the listed classes: fill, or stroke for lines', () {
      final out = recolourArt(svg, const {
        'c2': Color(0xFF0A0B0C),
        'line': Color(0xFFD8C79E),
      });
      expect(out, contains('fill="#0A0B0C" class="c2"'));
      expect(out, contains('stroke="#D8C79E"'));
      expect(out, contains('fill="none" stroke="#D8C79E"'));
      expect(out, contains('<g class="c1" fill="#ffffff">'));
      expect(out, contains('<g class="c3" fill="#123456">'));
      expect(out, contains('stroke-linecap="round"'));
    });

    test('reads data-slot', () {
      expect(
        svgSlot('<svg data-slot="16.6 37.5 52.7 24.6" viewBox="0 0 85 100">'),
        const Rect.fromLTWH(16.6, 37.5, 52.7, 24.6),
      );
      expect(svgSlot('<svg viewBox="0 0 1 1">'), isNull);
    });
  });

  group('frame from slices', () {
    // The Seljuk (Douri) slices' own sizes.
    const corner = Size(13.1291, 8.5886);
    const edgeH = Size(9.8468, 5.1422);
    const edgeV = Size(4.9234, 10.3392);
    const band = 20.0;
    const size = Size(370, 640);
    final k = band / edgeH.height;
    final layout = sliceFrameLayout(
      size,
      corner: corner,
      edgeH: edgeH,
      edgeV: edgeV,
      band: band,
    );
    List<ArtPlacement> of(ArtFramePiece p) =>
        layout.placements.where((x) => x.piece == p).toList();

    test('the corner is mirrored into all four corners', () {
      final c = of(ArtFramePiece.corner);
      final w = corner.width * k;
      final h = corner.height * k;
      expect(c.map((p) => p.rect), [
        Rect.fromLTWH(0, 0, w, h),
        Rect.fromLTWH(size.width - w, 0, w, h),
        Rect.fromLTWH(0, size.height - h, w, h),
        Rect.fromLTWH(size.width - w, size.height - h, w, h),
      ]);
      expect(c.map((p) => (p.flipX, p.flipY)), [
        (false, false),
        (true, false),
        (false, true),
        (true, true),
      ]);
      // Drawn last, over the ends of the edges.
      expect(layout.placements.last.piece, ArtFramePiece.corner);
    });

    test('whole repeats fill each edge between the corners exactly', () {
      final cw = corner.width * k;
      final ch = corner.height * k;
      final top = of(ArtFramePiece.edgeH).where((p) => !p.flipY).toList();
      final bottom = of(ArtFramePiece.edgeH).where((p) => p.flipY).toList();
      final nx = ((size.width - 2 * cw) / (edgeH.width * k)).round();
      expect(top, hasLength(nx));
      expect(bottom, hasLength(nx));
      expect(top.first.rect.left, closeTo(cw, 1e-9));
      expect(top.last.rect.right, closeTo(size.width - cw, 1e-9));
      for (var i = 1; i < top.length; i++) {
        expect(top[i].rect.left, closeTo(top[i - 1].rect.right, 1e-9));
      }
      // Stretched by less than half a repeat.
      final step = top.first.rect.width / (edgeH.width * k);
      expect(step, inInclusiveRange(0.66, 1.5));
      expect(top.first.rect.height, closeTo(band, 1e-9));
      expect(bottom.first.rect.bottom, closeTo(size.height, 1e-9));

      final left = of(ArtFramePiece.edgeV).where((p) => !p.flipX).toList();
      final right = of(ArtFramePiece.edgeV).where((p) => p.flipX).toList();
      final ny = ((size.height - 2 * ch) / (edgeV.height * k)).round();
      expect(left, hasLength(ny));
      expect(right, hasLength(ny));
      expect(left.first.rect.top, closeTo(ch, 1e-9));
      expect(left.last.rect.bottom, closeTo(size.height - ch, 1e-9));
      expect(left.first.rect.left, 0);
      expect(right.first.rect.right, closeTo(size.width, 1e-9));
      expect(left.first.rect.width, closeTo(edgeV.width * k, 1e-9));
    });

    test('the page starts at each edge\'s own depth', () {
      final dv = edgeV.width * k;
      expect(layout.insets.top, closeTo(band, 1e-9));
      expect(layout.insets.bottom, closeTo(band, 1e-9));
      expect(layout.insets.left, closeTo(dv, 1e-9));
      expect(layout.insets.right, closeTo(dv, 1e-9));
      expect(layout.inset, closeTo(band, 1e-9));
    });

    test('a narrow span still gets one repeat', () {
      final tiny = sliceFrameLayout(
        const Size(60, 60),
        corner: corner,
        edgeH: edgeH,
        edgeV: edgeV,
        band: band,
      );
      expect(
        tiny.placements.where((p) => p.piece == ArtFramePiece.edgeH),
        hasLength(2),
      );
    });
  });

  group('frame drawn whole', () {
    const view = Size(63.79, 100);
    const slot = Rect.fromLTWH(4.4504, 5.8665, 54.8887, 88.5367);

    test('on a phone: the width\'s scale, only the sides stretch', () {
      const size = Size(370, 640);
      final l = wholeFrameLayout(size, view: view, slot: slot, band: 24);
      expect(l.placements, hasLength(9));
      final k = size.width / view.width;
      final topLeft = l.placements.first;
      expect(topLeft.rect.width / topLeft.src!.width, closeTo(k, 1e-9));
      expect(topLeft.rect.height / topLeft.src!.height, closeTo(k, 1e-9));
      // The middle row is taller on screen than in the drawing.
      final middle = l.placements[3];
      expect(middle.rect.height / middle.src!.height, greaterThan(k));
      expect(l.inset, closeTo(slot.top * k, 1e-9));
      // The sides are thinner than the top: the page reaches each one.
      expect(l.insets.left, closeTo(slot.left * k, 1e-9));
      expect(l.insets.right, closeTo((view.width - slot.right) * k, 1e-9));
      expect(l.insets.top, closeTo(slot.top * k, 1e-9));
      expect(l.insets.bottom, closeTo((view.height - slot.bottom) * k, 1e-9));
      final union = l.placements
          .map((p) => p.rect)
          .reduce((a, b) => a.expandToInclude(b));
      expect(union, Offset.zero & size);
    });

    test('on a wide screen the band stays near its depth', () {
      final l = wholeFrameLayout(
        const Size(900, 1200),
        view: view,
        slot: slot,
        band: 24,
      );
      final k = l.placements.first.rect.width / l.placements.first.src!.width;
      expect(slot.left * k, lessThanOrEqualTo(24 * 1.2 + 1e-9));
    });
  });

  group('markers', () {
    test('the marker sits on the printed one, no wider than it', () {
      const c = Offset(100, 50);
      const r = 8.4;
      for (final art in const [
        Size(85.9, 100),
        Size(100, 100),
        Size(73, 100),
      ]) {
        final box = markerBox(c, r, art);
        expect(box.center.dx, closeTo(c.dx, 1e-9));
        expect(box.center.dy, closeTo(c.dy, 1e-9));
        expect(box.width, lessThanOrEqualTo(2.08 * r + 1e-9));
        expect(box.height, lessThanOrEqualTo(2.62 * r + 1e-9));
        expect(box.width / box.height, closeTo(art.width / art.height, 1e-9));
      }
    });

    test('the number box follows the marker\'s data-slot', () async {
      final art = registry.byId('seljuk').art!;
      final p = await loadThemeArt(art, ThemeModeId.light, bundle: rootBundle);
      // font-010-regular-bold: viewBox 85.9377 x 100, slot 16.6272 37.5525
      // 52.6833 24.5586.
      expect(p.marker.size.width, closeTo(85.9377, 1e-3));
      expect(p.marker.slot!.left, closeTo(16.6272, 1e-4));
      final dst = markerBox(const Offset(50, 50), 10, p.marker.size);
      final box = slotIn(p.marker.slot!, p.marker.size, dst);
      final k = dst.height / 100;
      expect(box.left, closeTo(dst.left + 16.6272 * k, 1e-6));
      expect(box.top, closeTo(dst.top + 37.5525 * k, 1e-6));
      expect(box.width, closeTo(52.6833 * k, 1e-6));
      expect(box.height, closeTo(24.5586 * k, 1e-6));
      expect(dst.contains(box.center), isTrue);
    });

    test('MarkerLook draws the theme marker over the printed one', () async {
      final art = registry.byId('fatimid').art!;
      final p = await loadThemeArt(art, ThemeModeId.light, bundle: rootBundle);
      final look = MarkerLook(
        style: MarkerStyle.theme,
        image: null,
        tint: null,
        paper: const Color(0xFFFEFCF5),
        ink: const Color(0xFF15261F),
        art: p.marker,
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      look.paintUnder(canvas, const Offset(50, 50), 20);
      look.paintOver(canvas, const Offset(50, 50), 20, 7);
      final image = await recorder.endRecording().toImage(100, 100);
      final bytes = (await image.toByteData())!;
      int alpha(int x, int y) => bytes.getUint8((y * 100 + x) * 4 + 3);
      // Something drawn on the marker, nothing far from it.
      expect(alpha(50, 50), 255);
      expect(alpha(2, 2), 0);
      expect(alpha(97, 50), 0);
    });
  });

  group('settings', () {
    Future<ProviderContainer> container(Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues(prefs);
      final c = ProviderContainer(
        overrides: [
          themeRegistryProvider.overrideWithValue(registry),
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('a heritage theme draws its own marker until one is chosen', () async {
      final c = await container({});
      expect(c.read(settingsProvider).markerStyle, MarkerStyle.rosette16);
      await c.read(settingsProvider.notifier).setStyle('mamluk');
      expect(c.read(settingsProvider).markerStyle, MarkerStyle.theme);
      await c.read(settingsProvider.notifier).setStyle('zakhrafa');
      expect(c.read(settingsProvider).markerStyle, MarkerStyle.rosette16);
    });

    test('a new theme replaces a chosen marker shape with its own', () async {
      final c = await container({'settings.markerStyle': 'rosette7'});
      await c.read(settingsProvider.notifier).setStyle('seljuk');
      expect(c.read(settingsProvider).markerStyle, MarkerStyle.theme);
    });

    test('a stored heritage theme starts with its marker', () async {
      final c = await container({'settings.style': 'abbasid'});
      expect(c.read(settingsProvider).markerStyle, MarkerStyle.theme);
    });
  });

  group('the page frame in a heritage theme', () {
    // The frame draws the catchword, which reads the reader's settings.
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Widget app(TibyanStyle style, Widget child) => ProviderScope(
      overrides: [
        themeRegistryProvider.overrideWithValue(registry),
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Nothing is installed here, so the edition falls back to the
        // bundled one and the catchword is drawn as text.
        packRootProvider.overrideWithValue(Directory.systemTemp),
      ],
      child: MaterialApp(
        theme: buildTheme(
          style: style,
          mode: ThemeModeId.night,
          uiFont: UiFont.changa,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ar'),
        home: Scaffold(body: child),
      ),
    );

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }
    }

    testWidgets('cartouche and page number above and below; all tappable', (
      tester,
    ) async {
      final taps = <String>[];
      await tester.pumpWidget(
        app(
          registry.byId('timurid'),
          IlluminatedFrame(
            info: const FrameInfo(
              page: 50,
              juz: 3,
              hizb: 5,
              surahName: 'آل عمران',
              catchword: 'كلمة',
              banners: [
                SurahBanner(
                  line: 0,
                  number: 3,
                  name: 'آل عمران',
                  meccan: false,
                  ayahCount: 200,
                  order: 89,
                  after: 'الأنفال',
                ),
              ],
            ),
            onJuzTap: () => taps.add('juz'),
            onHizbTap: () => taps.add('hizb'),
            onSurahTap: () => taps.add('surah'),
            onPageTap: () => taps.add('page'),
            child: const SizedBox.expand(),
          ),
        ),
      );
      await settle(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('الجزء ٣'));
      await tester.tap(find.text('الحزب ٥'));
      await tester.tap(find.text('آل عمران'));
      await tester.tap(find.bySemanticsLabel('الصفحة 50'));
      expect(taps, ['juz', 'hizb', 'surah', 'page']);
      // The catchword and the tools are the screen's reading bar's, not
      // the page's: they do not turn with it.
      expect(find.text('كلمة'), findsNothing);
      // The banner writes the surah in the header art.
      expect(find.textContaining('سورة آل عمران'), findsOneWidget);
      // The page number sits below the frame, the cartouche above it.
      final page = tester.getRect(find.bySemanticsLabel('الصفحة 50'));
      final juz = tester.getRect(find.text('الجزء ٣'));
      final screen = tester.getRect(find.byType(Scaffold));
      expect(juz.top, lessThan(screen.height * 0.1));
      expect(page.bottom, greaterThan(screen.height * 0.85));
    });

    testWidgets('the reading bar: quarter, tools, catchword; none in '
        'recitation mode', (tester) async {
      const info = FrameInfo(
        page: 51,
        juz: 3,
        hizb: 5,
        surahName: 'آل عمران',
        catchword: 'كلمة',
        quarters: [QuarterMark(line: 3, quarter: 18, surah: 3, ayah: 92)],
      );
      await tester.pumpWidget(
        app(
          registry.byId('seljuk'),
          Column(
            children: [
              ReadingBar.of(const [info], page: 51, tools: const Text('tools')),
              ReadingBar.of(
                const [info],
                page: 51,
                showCatchword: false,
                tools: const Text('hidden'),
              ),
            ],
          ),
        ),
      );
      await settle(tester);
      expect(find.text('كلمة'), findsOneWidget);
      expect(find.bySemanticsLabel('ربع الحزب ٥'), findsNWidgets(2));
      expect(find.text('tools'), findsOneWidget);
      // The quarter on the right, the catchword on the left.
      expect(
        tester.getCenter(find.bySemanticsLabel('ربع الحزب ٥').first).dx,
        greaterThan(tester.getCenter(find.text('كلمة')).dx),
      );
    });

    testWidgets('the opening page\'s surah name still opens the index', (
      tester,
    ) async {
      var opened = 0;
      await tester.pumpWidget(
        app(
          registry.byId('andalusi'),
          OrnateFrame(
            page: 1,
            top: GestureDetector(
              onTap: () => opened++,
              child: const Text('سورة الفاتحة'),
            ),
            bottom: const Text('ترتيبها في النزول ٥'),
            child: const SizedBox.expand(),
          ),
        ),
      );
      await settle(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('سورة الفاتحة'));
      expect(opened, 1);
      expect(find.bySemanticsLabel('الصفحة 1'), findsOneWidget);
    });
  });
}
