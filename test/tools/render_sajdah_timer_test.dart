import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:archive/archive_io.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/app.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/db/user_database.dart';
import 'package:tibyan/core/flags/feature_flags.dart';
import 'package:tibyan/core/router/app_router.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/features/home/whats_new.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/sajdah/sajdah_card.dart';

/// Not a test: draws the sajdah card over page 598 (al-Alaq 19, a verse of
/// prostration) at the phone and laptop sizes, in light and night, plain
/// and elderly; over «آية آية» sideways; and the listening settings with
/// the timer on, into `$SAJDAH_TIMER_OUT/<name>.png`. Runs only with
/// RENDER_SAJDAH_TIMER=1.
void main() {
  final run = Platform.environment['RENDER_SAJDAH_TIMER'] == '1';
  final outPath =
      Platform.environment['SAJDAH_TIMER_OUT'] ?? 'build/sajdah_timer_previews';
  // Logical size, and the safe area's top and bottom.
  const sizes = {
    'iphone61': (Size(393, 852), 59.0, 34.0),
    'iphone67': (Size(430, 932), 59.0, 34.0),
    'iphonese': (Size(375, 667), 20.0, 0.0),
    'android': (Size(412, 915), 24.0, 16.0),
    'laptop': (Size(1440, 900), 0.0, 0.0),
  };

  testWidgets(
    'render sajdah timer previews',
    (tester) async {
      for (final m in ['toggle', 'isEnabled']) {
        tester.binding.defaultBinaryMessenger.setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.$m',
          (_) async => const StandardMessageCodec().encodeMessage(<Object?>[
            m == 'isEnabled' ? false : null,
          ]),
        );
      }
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      );
      // Real shadows, as on a device.
      debugDisableShadows = false;
      final db = ContentDatabase(
        NativeDatabase(
          File('assets/db/content.db'),
          setup: (raw) => raw.execute('PRAGMA query_only = ON'),
        ),
      );
      await tester.runAsync(() async {
        final manifest = jsonDecode(
          await rootBundle.loadString('FontManifest.json'),
        ) as List<dynamic>;
        for (final f in manifest.cast<Map<String, dynamic>>()) {
          final loader = FontLoader(f['family'] as String);
          for (final a in (f['fonts'] as List).cast<Map<String, dynamic>>()) {
            loader.addFont(
              rootBundle.load(Uri.decodeFull(a['asset'] as String)),
            );
          }
          await loader.load();
        }
      });
      final registry = (await tester.runAsync(
        () => ThemeRegistry.load(rootBundle),
      ))!;
      final flags = (await tester.runAsync(
        () => FeatureFlags.load(rootBundle),
      ))!;
      final out = Directory(outPath)..createSync(recursive: true);
      final root = Directory.systemTemp.createTempSync('sajdah_previews');
      final dir = Directory(p.join(root.path, 'packs', 'pages-hafs-1441-v1'))
        ..createSync(recursive: true);
      final zip = ZipDecoder().decodeStream(
        InputFileStream('assets/packs/pages-hafs-1441-v1.zip'),
      );
      for (final name in ['597.svg.xz', '598.svg.xz']) {
        File(p.join(dir.path, name))
            .writeAsBytesSync(zip.findFile(name)!.content);
      }
      File(p.join(dir.path, '.installed')).writeAsStringSync('x');

      Future<void> shot(
        String name,
        String location,
        Size logical, {
        double top = 0,
        double bottom = 0,
        Map<String, Object> prefs = const {},
        bool card = true,
        Future<void> Function()? act,
      }) async {
        SharedPreferences.setMockInitialValues({
          'settings.onboardingDone': true,
          'settings.language': 'ar',
          'settings.style': 'zakhrafa',
          'settings.mode': 'light',
          'settings.sajdahTimer': true,
          whatsNewSeenKey: whatsNewId,
          ...prefs,
        });
        final shared = await SharedPreferences.getInstance();
        final user = UserDatabase(NativeDatabase.memory());
        // The view itself at this size, so the card measures the screen.
        tester.view.physicalSize = logical * 2;
        tester.view.devicePixelRatio = 2;
        tester.view.padding = FakeViewPadding(top: top * 2, bottom: bottom * 2);
        tester.view.viewPadding = FakeViewPadding(
          top: top * 2,
          bottom: bottom * 2,
        );
        final container = ProviderContainer(
          overrides: [
            themeRegistryProvider.overrideWithValue(registry),
            featureFlagsProvider.overrideWithValue(flags),
            sharedPreferencesProvider.overrideWithValue(shared),
            contentDatabaseProvider.overrideWithValue(db),
            userDatabaseProvider.overrideWithValue(user),
            packRootProvider.overrideWithValue(root),
            readingPositionProvider.overrideWith((ref) => Stream.value(null)),
          ],
        );
        final boundary = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: UncontrolledProviderScope(
              key: UniqueKey(),
              container: container,
              child: const TibyanApp(),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 2));
        container.read(appRouterProvider).go(location);
        Future<void> settle() async {
          for (var i = 0; i < 30; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 50)),
            );
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        await settle();
        if (act != null) {
          await act();
          await settle();
        }
        if (card) {
          container.read(sajdahCardProvider.notifier).show((
            surah: 96,
            ayah: 19,
          ), SajdahFrom.listening);
          // A few seconds into the countdown.
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(seconds: 3));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 300)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        final object =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final bytes = await tester.runAsync(() async {
          final image = await object.toImage(pixelRatio: 2);
          final d = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          return d!.buffer.asUint8List();
        });
        File('${out.path}/$name.png').writeAsBytesSync(bytes!);
        container.read(sajdahCardProvider.notifier).drop();
        await tester.pumpWidget(const SizedBox());
        container.dispose();
        tester.takeException();
      }

      for (final MapEntry(key: size, value: (logical, top, bottom))
          in sizes.entries) {
        for (final mode in ['light', 'night']) {
          for (final elderly in [false, true]) {
            await shot(
              'card_$mode${elderly ? '_elderly' : ''}_$size',
              '/mushaf?page=598',
              logical,
              top: top,
              bottom: bottom,
              prefs: {'settings.mode': mode, 'settings.elderlyMode': elderly},
            );
          }
        }
      }
      // «آية آية» sideways on a phone, plain and elderly.
      for (final elderly in [false, true]) {
        await shot(
          'one_verse${elderly ? '_elderly' : ''}_iphone61',
          '/verse?s=97&a=1',
          const Size(852, 393),
          prefs: {'settings.elderlyMode': elderly},
        );
      }
      // The listening settings with the timer on.
      await shot(
        'settings_iphone61',
        '/settings/player',
        const Size(393, 852),
        top: 59,
        bottom: 34,
        card: false,
        act: () => tester.scrollUntilVisible(
          find.text('مدة المؤقت'),
          300,
          scrollable: find.byType(Scrollable).first,
        ),
      );
      await tester.pump(const Duration(seconds: 30));
      await tester.runAsync(db.close);
      debugDisableShadows = true;
      tester.view.reset();
    },
    skip: !run,
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
