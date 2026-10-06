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
import 'package:tibyan/features/hifz/data/hifz_store.dart';
import 'package:tibyan/features/home/whats_new.dart';
import 'package:tibyan/features/khatma/data/khatma_repository.dart';
import 'package:tibyan/features/khatma/domain/day.dart';
import 'package:tibyan/features/khatma/domain/khatma_plan.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';

/// Not a test: draws the whole app, through its router, at phone, small
/// phone, Android and laptop sizes into `$READER_POLISH_OUT/<name>.png`:
/// the opening pages (the cover, al-Fatiha, the start of al-Baqarah; a
/// spread on the laptop) in the Zakhrafa and a heritage theme, a text page
/// with the reading bar under it, and the index's pages tab with a khatma
/// under way, memorized verses and marks. Runs only with
/// RENDER_READER_POLISH=1.
void main() {
  final run = Platform.environment['RENDER_READER_POLISH'] == '1';
  final outPath =
      Platform.environment['READER_POLISH_OUT'] ?? 'build/reader_polish';
  const sizes = {
    'iphone61': Size(393, 852),
    'iphone67': Size(430, 932),
    'iphonese': Size(375, 667),
    'android': Size(412, 915),
    'laptop': Size(1440, 900),
  };

  testWidgets(
    'render reader polish previews',
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
      final root = Directory.systemTemp.createTempSync('reader_polish');
      final dir = Directory(p.join(root.path, 'packs', 'pages-hafs-1441-v1'))
        ..createSync(recursive: true);
      final zip = ZipDecoder().decodeStream(
        InputFileStream('assets/packs/pages-hafs-1441-v1.zip'),
      );
      for (final pg in [1, 2, 3, 50, 51, 52]) {
        final e = zip.findFile('${pg.toString().padLeft(3, '0')}.svg.xz')!;
        File(p.join(dir.path, e.name)).writeAsBytesSync(e.content);
      }
      File(p.join(dir.path, '.installed')).writeAsStringSync('x');

      Future<void> shot(
        String name,
        String location,
        Size size, {
        String style = 'zakhrafa',
        bool seed = false,
      }) async {
        SharedPreferences.setMockInitialValues({
          'settings.onboardingDone': true,
          'settings.language': 'ar',
          'settings.style': style,
          'settings.mode': 'light',
          whatsNewSeenKey: whatsNewId,
        });
        final prefs = await SharedPreferences.getInstance();
        final user = UserDatabase(NativeDatabase.memory());
        if (seed) {
          await tester.runAsync(() async {
            // A khatma under way: the first 46 pages read.
            final khatmas = KhatmaRepository(user);
            final row = await khatmas.create(
              title: 'ختمة',
              edition: 'madina1441',
              unit: PortionUnit.juz,
              start: Day.today().add(-10),
              target: Day.today().add(20),
            );
            await khatmas.recordRead(row, {
              for (var i = 1; i <= 46; i++) i,
            }, Day.today());
            // Memorized: al-Fatiha strong, the start of al-Baqarah
            // weakening as it goes, and a passage of Al Imran.
            await user.setVerseStrengths({
              for (var a = 1; a <= 7; a++) '1:$a': 4,
              for (var a = 1; a <= 25; a++) '2:$a': 4,
              for (var a = 26; a <= 60; a++) '2:$a': 3,
              for (var a = 61; a <= 100; a++) '2:$a': 2,
              for (var a = 101; a <= 130; a++) '2:$a': 1,
              for (var a = 1; a <= 30; a++) '3:$a': 3,
            });
            await user.setMark(
              MarkKind.reading,
              name: 'الورد',
              surah: 2,
              ayah: 142,
              page: 22,
            );
            await user.setMark(
              MarkKind.hifz,
              name: 'الحفظ',
              surah: 2,
              ayah: 255,
              page: 42,
            );
          });
        }
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
        for (var i = 0; i < 40; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
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
        await tester.pumpWidget(const SizedBox());
        container.dispose();
        // The reader's session is saved as the screen closes, in the test's
        // clock: the in-memory database is left open rather than waited on.
      }

      for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
        for (final style in ['zakhrafa', 'seljuk']) {
          // The laptop shows al-Fatiha and al-Baqarah as one spread.
          for (final page in sizeName == 'laptop' ? [0, 1] : [0, 1, 2]) {
            await shot(
              'opening_${style}_${sizeName}_p$page',
              '/mushaf?page=$page',
              size,
              style: style,
            );
          }
        }
        await shot('reader_$sizeName', '/mushaf?page=50', size);
        await shot(
          'pages_map_$sizeName',
          '/mushaf/index?tab=pages&p=23',
          size,
          seed: true,
        );
      }
      // Let the app's last timers run out.
      await tester.pump(const Duration(seconds: 10));
      await tester.runAsync(db.close);
    },
    skip: !run,
    timeout: const Timeout(Duration(minutes: 40)),
  );
}
