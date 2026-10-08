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
import 'package:tibyan/features/audio/recitation.dart';
import 'package:tibyan/features/home/whats_new.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';

/// A recitation under way, for the player styles' previews.
class _Listening extends RecitationController {
  @override
  RecitationState build() => const RecitationState(
    active: true,
    playing: true,
    surah: 2,
    ayah: 40,
    timed: true,
  );
}

/// Not a test: draws focus mode through the app's router at the phone,
/// small phone, Android and laptop sizes (with each device's notch and
/// home bar as safe-area padding) into `$FOCUS_MODE_OUT/<name>.png`: a text
/// page before (normal reading) and after (focus mode), in the three
/// editions drawn differently and with each way of filling the screen, the
/// opening pages, a spread, the tools, the «القائمة» window on a verse,
/// each player style, and elderly mode. The 1405 and Shamarly pages come
/// from the archives under `$FOCUS_MODE_CACHE` (tools/.cache by default)
/// and are left out without them. Runs only with RENDER_FOCUS_MODE=1;
/// FOCUS_MODE_ONLY limits it to names containing one of its
/// comma-separated words.
void main() {
  final run = Platform.environment['RENDER_FOCUS_MODE'] == '1';
  final outPath =
      Platform.environment['FOCUS_MODE_OUT'] ?? 'build/focus_mode_previews';
  final cache = Platform.environment['FOCUS_MODE_CACHE'] ?? 'tools/.cache';
  final only = Platform.environment['FOCUS_MODE_ONLY']?.split(',');
  // Logical size, and the safe area's top and bottom.
  const sizes = {
    'iphone61': (Size(393, 852), 59.0, 34.0),
    'iphone67': (Size(430, 932), 59.0, 34.0),
    'iphonese': (Size(375, 667), 20.0, 0.0),
    'android': (Size(412, 915), 24.0, 16.0),
    'laptop': (Size(1440, 900), 0.0, 0.0),
  };

  testWidgets(
    'render focus mode previews',
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
      final root = Directory.systemTemp.createTempSync('focus_mode');
      const madina = [1, 2, 3, 49, 50, 51, 52];
      const shamarly = [1, 2, 3, 4, 44, 45, 46];

      final newDir = Directory(p.join(root.path, 'packs', 'pages-hafs-1441-v1'))
        ..createSync(recursive: true);
      final newZip = ZipDecoder().decodeStream(
        InputFileStream('assets/packs/pages-hafs-1441-v1.zip'),
      );
      for (final pg in madina) {
        final e = newZip.findFile('${pg.toString().padLeft(3, '0')}.svg.xz')!;
        File(p.join(newDir.path, e.name)).writeAsBytesSync(e.content);
      }
      File(p.join(newDir.path, '.installed')).writeAsStringSync('x');

      final editions = ['madina1441'];
      final oldZipFile = File(p.join(cache, 'images_1024.zip'));
      if (oldZipFile.existsSync()) {
        final oldDir = Directory(
          p.join(root.path, 'packs', 'pages-hafs-1405-qurancom-1024'),
        )..createSync(recursive: true);
        final oldZip = ZipDecoder().decodeStream(
          InputFileStream(oldZipFile.path),
        );
        for (final pg in madina) {
          final e = oldZip.findFile(
            'width_1024/page${pg.toString().padLeft(3, '0')}.png',
          )!;
          File(p.join(oldDir.path, 'p${pg.toString().padLeft(3, '0')}.png'))
              .writeAsBytesSync(e.content);
        }
        File(p.join(oldDir.path, 'ayahinfo.db')).writeAsBytesSync(
          oldZip.findFile('databases/ayahinfo_1024.db')!.content,
        );
        File(p.join(oldDir.path, '.installed')).writeAsStringSync('x');
        editions.add('madina1405');
      }
      final shZipFile = File(
        p.join(cache, 'shamarly', 'shamarly-pages-archive-org.zip'),
      );
      if (shZipFile.existsSync()) {
        final shDir = Directory(
          p.join(root.path, 'packs', 'pages-hafs-shamarly-v1'),
        )..createSync(recursive: true);
        final shZip = ZipDecoder().decodeStream(
          InputFileStream(shZipFile.path),
        );
        for (final pg in shamarly) {
          final name = '${pg.toString().padLeft(3, '0')}.png';
          File(p.join(shDir.path, name))
              .writeAsBytesSync(shZip.findFile(name)!.content);
        }
        File(p.join(shDir.path, '.installed')).writeAsStringSync('x');
        editions.add('shamarly');
      }

      bool wanted(String name) =>
          only == null || only.any((w) => name.contains(w));

      Future<void> shot(
        String name,
        String location,
        String size, {
        Map<String, Object> prefs = const {},
        bool listening = false,
        Future<void> Function()? act,
      }) async {
        if (!wanted(name)) return;
        final (logical, top, bottom) = sizes[size]!;
        SharedPreferences.setMockInitialValues({
          'settings.onboardingDone': true,
          'settings.language': 'ar',
          'settings.style': 'zakhrafa',
          'settings.mode': 'light',
          whatsNewSeenKey: whatsNewId,
          ...prefs,
        });
        final shared = await SharedPreferences.getInstance();
        final user = UserDatabase(NativeDatabase.memory());
        await tester.binding.setSurfaceSize(logical);
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
            if (listening) recitationProvider.overrideWith(_Listening.new),
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
          for (var i = 0; i < 40; i++) {
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
        tester.takeException();
      }

      const focus = {'settings.focusMode': true};
      for (final size in sizes.keys) {
        await shot('page_before_$size', '/mushaf?page=50', size);
        for (final edition in editions) {
          final page = edition == 'shamarly' ? 44 : 50;
          for (final fill in ['lines', 'stretch', 'full']) {
            await shot(
              'page_after_${edition}_${fill}_$size',
              '/mushaf?page=$page',
              size,
              prefs: {
                ...focus,
                'settings.edition': edition,
                'settings.pageFill': fill,
              },
            );
          }
          final openings = edition == 'shamarly' ? [2, 3] : [1, 2];
          for (final page in size == 'laptop' ? [openings.first] : openings) {
            await shot(
              'opening_${edition}_p${page}_$size',
              '/mushaf?page=$page',
              size,
              prefs: {...focus, 'settings.edition': edition},
            );
          }
        }
      }
      for (final MapEntry(key: size, value: (logical, _, _)) in sizes.entries) {
        // The reading tools under the page, shown by the bar's button.
        await shot(
          'tools_$size',
          '/mushaf?page=50',
          size,
          prefs: focus,
          act: () async {
            await tester.tap(find.byTooltip('إظهار الأدوات'));
          },
        );
        // «القائمة»: a long press on a verse, and off any verse.
        await shot(
          'menu_verse_$size',
          '/mushaf?page=50',
          size,
          prefs: {...focus, 'settings.focusTools': 'menu'},
          act: () async {
            await tester.longPressAt(
              Offset(logical.width * 0.75, logical.height * 0.55),
            );
          },
        );
        await shot(
          'menu_page_$size',
          '/mushaf?page=50',
          size,
          prefs: {...focus, 'settings.focusTools': 'menu'},
          act: () async {
            await tester.longPressAt(
              Offset(logical.width * 0.75, logical.height * 0.17),
            );
          },
        );
      }
      for (final size in sizes.keys) {
        // Each player style, with focus mode off and on.
        for (final style in ['auto', 'normal', 'pill', 'button']) {
          for (final on in [false, true]) {
            await shot(
              'player_${style}_${on ? 'focus' : 'normal'}_$size',
              '/mushaf?page=50',
              size,
              listening: true,
              prefs: {'settings.focusMode': on, 'settings.playerStyle': style},
            );
          }
        }
        // The single button's menu, from a long press.
        await shot(
          'player_button_menu_$size',
          '/mushaf?page=50',
          size,
          listening: true,
          prefs: {...focus, 'settings.playerStyle': 'button'},
          act: () async {
            await tester.longPress(
              find.byKey(const ValueKey('floating-player')),
            );
          },
        );
        // Elderly mode: the larger bar with named buttons, the tools, and
        // the pill.
        const elderly = {...focus, 'settings.elderlyMode': true};
        await shot('elderly_$size', '/mushaf?page=50', size, prefs: elderly);
        await shot(
          'elderly_tools_$size',
          '/mushaf?page=50',
          size,
          prefs: elderly,
          act: () async {
            await tester.tap(find.text('إظهار الأدوات'));
          },
        );
        await shot(
          'elderly_menu_$size',
          '/mushaf?page=50',
          size,
          prefs: {...elderly, 'settings.focusTools': 'menu'},
          act: () async {
            final (logical, _, _) = sizes[size]!;
            await tester.longPressAt(
              Offset(logical.width * 0.75, logical.height * 0.6),
            );
          },
        );
        await shot(
          'elderly_pill_$size',
          '/mushaf?page=50',
          size,
          listening: true,
          prefs: elderly,
        );
        await shot(
          'elderly_button_$size',
          '/mushaf?page=50',
          size,
          listening: true,
          prefs: {...elderly, 'settings.playerStyle': 'button'},
        );
      }
      // Let the app's last timers run out.
      await tester.pump(const Duration(seconds: 10));
      await tester.runAsync(db.close);
    },
    skip: !run,
    timeout: const Timeout(Duration(minutes: 60)),
  );
}
