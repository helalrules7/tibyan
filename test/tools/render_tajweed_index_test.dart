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
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/features/home/whats_new.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/mushaf_page.dart';

/// Not a test: draws «المساعد» and its tajweed marks through the app's
/// router: the home grid with the Assistant tile (phone and laptop), the
/// Assistant, the tajweed marks, rules' places (al-Baqarah 19's small meem
/// among the iqlab's), the colour key with «المزيد», the reader's top menu,
/// in light and night modes, elderly mode and English, into
/// `$TAJWEED_INDEX_OUT/<name>.png`. Runs only with RENDER_TAJWEED_INDEX=1.
/// `RENDER_TAJWEED_ONLY=name` draws only the shots whose name starts with it.
void main() {
  final run = Platform.environment['RENDER_TAJWEED_INDEX'] == '1';
  final outPath =
      Platform.environment['TAJWEED_INDEX_OUT'] ?? 'build/tajweed_index';
  final only = Platform.environment['RENDER_TAJWEED_ONLY'] ?? '';

  testWidgets(
    'render tajweed index previews',
    (tester) async {
      for (final m in ['toggle', 'isEnabled']) {
        tester.binding.defaultBinaryMessenger.setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.$m',
          (_) async => const StandardMessageCodec().encodeMessage(<Object?>[
            m == 'isEnabled' ? false : null,
          ]),
        );
      }
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
      final root = Directory.systemTemp.createTempSync('tajweed_index');
      // Page 50 of the 1441 pages, for the reader's shots.
      final pack = Directory(p.join(root.path, 'packs', 'pages-hafs-1441-v1'))
        ..createSync(recursive: true);
      final zip = ZipDecoder().decodeBytes(
        File('assets/packs/pages-hafs-1441-v1.zip').readAsBytesSync(),
      );
      for (final name in ['049.svg.xz', '050.svg.xz', '051.svg.xz']) {
        final entry = zip.findFile(name)!;
        File(p.join(pack.path, entry.name)).writeAsBytesSync(entry.content);
      }
      File(p.join(pack.path, '.installed')).writeAsStringSync('test');

      Future<void> settle() async {
        for (var i = 0; i < 30; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      Future<void> shot(
        String name,
        String location, {
        String mode = 'light',
        String language = 'ar',
        bool elderly = false,
        Size size = const Size(393, 852),
        bool focus = false,
        String? edition,
        Future<void> Function()? then,
      }) async {
        if (!name.startsWith(only)) return;
        SharedPreferences.setMockInitialValues({
          'settings.onboardingDone': true,
          'settings.language': language,
          'settings.style': 'zakhrafa',
          'settings.mode': mode,
          'settings.elderlyMode': elderly,
          if (focus) 'settings.focusMode': true,
          if (focus) 'settings.focusTools': 'menu',
          whatsNewSeenKey: whatsNewId,
        });
        final prefs = await SharedPreferences.getInstance();
        final user = UserDatabase(NativeDatabase.memory());
        await tester.binding.setSurfaceSize(size);
        tester.view.devicePixelRatio = 2;
        final container = ProviderContainer(
          overrides: [
            themeRegistryProvider.overrideWithValue(registry),
            featureFlagsProvider.overrideWithValue(flags),
            sharedPreferencesProvider.overrideWithValue(prefs),
            contentDatabaseProvider.overrideWithValue(db),
            userDatabaseProvider.overrideWithValue(user),
            packRootProvider.overrideWithValue(root),
            readingPositionProvider.overrideWith((ref) => Stream.value(null)),
            // A riwaya edition, as if its pages were installed.
            if (edition != null)
              editionProvider.overrideWithValue(
                MushafEdition.values.byName(edition),
              ),
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
        await settle();
        if (then != null) {
          await then();
          await settle();
        }
        // The test binding's own overflow checks are not under test here.
        tester.takeException();
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
        await tester.pumpWidget(const SizedBox());
        container.dispose();
      }

      const laptop = Size(1280, 800);
      for (final mode in ['light', 'night']) {
        await shot('home_phone_$mode', '/', mode: mode);
        await shot('home_laptop_$mode', '/', mode: mode, size: laptop);
        await shot('assistant_$mode', '/assistant', mode: mode);
        await shot('marks_$mode', '/assistant/tajweed', mode: mode);
        await shot(
          'rule_iqlab_$mode',
          '/assistant/tajweed/rule?rule=iqlab',
          mode: mode,
        );
        await shot(
          'legend_$mode',
          '/mushaf?page=50',
          mode: mode,
          then: () async {
            await tester.longPress(find.byTooltip('تلوين أحكام التجويد'));
          },
        );
        await shot(
          'reader_menu_$mode',
          '/mushaf?page=50',
          mode: mode,
          then: () async {
            final page = tester.getRect(find.byType(MushafPage));
            await tester.tapAt(Offset(page.center.dx, page.top + 30));
          },
        );
      }
      await shot('home_phone_en', '/', language: 'en');
      await shot('assistant_en', '/assistant', language: 'en');
      await shot('marks_en', '/assistant/tajweed', language: 'en');
      await shot('assistant_elderly', '/assistant', elderly: true);
      await shot('home_phone_elderly', '/', elderly: true);
      await shot(
        'reader_menu_elderly',
        '/mushaf?page=50',
        elderly: true,
        then: () async {
          final page = tester.getRect(find.byType(MushafPage));
          await tester.tapAt(Offset(page.center.dx, page.top + 30));
        },
      );
      await shot(
        'reader_menu_en',
        '/mushaf?page=50',
        language: 'en',
        then: () async {
          final page = tester.getRect(find.byType(MushafPage));
          await tester.tapAt(Offset(page.center.dx, page.top + 30));
        },
      );
      await shot(
        'focus_menu_light',
        '/mushaf?page=50',
        focus: true,
        then: () async {
          final page = tester.getRect(find.byType(MushafPage));
          await tester.longPressAt(Offset(page.center.dx, page.top + 30));
        },
      );
      await shot('rule_madd_2_light', '/assistant/tajweed/rule?rule=madd_2');
      await shot('marks_warsh', '/assistant/tajweed', edition: 'warsh');
      await tester.pump(const Duration(seconds: 10));
      await tester.runAsync(db.close);
    },
    skip: !run,
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
