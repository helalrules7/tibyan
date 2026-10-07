import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

/// Not a test: draws the tajweed index of «About this mushaf» (the rules
/// with their colours, and a rule's places) through the app's router, in
/// light and night modes, elderly mode and English, into
/// `$TAJWEED_INDEX_OUT/<name>.png`. Runs only with RENDER_TAJWEED_INDEX=1.
void main() {
  final run = Platform.environment['RENDER_TAJWEED_INDEX'] == '1';
  final outPath =
      Platform.environment['TAJWEED_INDEX_OUT'] ?? 'build/tajweed_index';

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

      Future<void> shot(
        String name,
        String location, {
        String mode = 'light',
        String language = 'ar',
        bool elderly = false,
        String? expand,
      }) async {
        SharedPreferences.setMockInitialValues({
          'settings.onboardingDone': true,
          'settings.language': language,
          'settings.style': 'zakhrafa',
          'settings.mode': mode,
          'settings.elderlyMode': elderly,
          whatsNewSeenKey: whatsNewId,
        });
        final prefs = await SharedPreferences.getInstance();
        final user = UserDatabase(NativeDatabase.memory());
        await tester.binding.setSurfaceSize(const Size(393, 852));
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
        Future<void> settle() async {
          for (var i = 0; i < 30; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 50)),
            );
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        await settle();
        if (expand != null) {
          await tester.tap(find.text(expand));
          await settle();
          // The card's title near the top, its rules under it.
          await tester.ensureVisible(find.text(expand));
          final top = tester.getTopLeft(find.text(expand)).dy;
          await tester.drag(
            find.byType(Scrollable).first,
            Offset(0, -(top - 110)),
          );
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
      }

      const ar = 'أحكام التجويد: ألوانها ومواضعها';
      const en = 'Tajweed rules: colours and places';
      await shot('about_light', '/mushaf/about', expand: ar);
      await shot('about_night', '/mushaf/about', mode: 'night', expand: ar);
      await shot('about_en', '/mushaf/about', language: 'en', expand: en);
      for (final rule in ['madd_6', 'ikhfa', 'qalqalah']) {
        await shot('rule_${rule}_light', '/mushaf/about/tajweed?rule=$rule');
      }
      await shot(
        'rule_ghunnah_night',
        '/mushaf/about/tajweed?rule=ghunnah',
        mode: 'night',
      );
      await shot(
        'rule_iqlab_elderly',
        '/mushaf/about/tajweed?rule=iqlab',
        elderly: true,
      );
      await shot(
        'rule_madd_muttasil_en',
        '/mushaf/about/tajweed?rule=madd_muttasil',
        language: 'en',
      );
      await tester.pump(const Duration(seconds: 10));
      await tester.runAsync(db.close);
    },
    skip: !run,
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
