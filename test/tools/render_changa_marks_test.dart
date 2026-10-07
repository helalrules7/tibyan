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
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/home/whats_new.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';

import '../theme/ui_font_marks_test.dart' show markSamples;

/// Not a test: draws Arabic words with every mark in each interface font
/// (weights 300, 400, 700; sizes 14, 18, 24; light and night), and real
/// screens whose text carries a shadda with a haraka, into
/// `$CHANGA_MARKS_OUT/<CHANGA_TAG>_<name>.png`. CHANGA_FONT draws Changa
/// from another file (the shipped one before the fix, for comparison).
/// Runs only with RENDER_CHANGA_MARKS=1.
void main() {
  final env = Platform.environment;
  final run = env['RENDER_CHANGA_MARKS'] == '1';
  final outPath = env['CHANGA_MARKS_OUT'] ?? 'build/changa_marks';
  final tag = env['CHANGA_TAG'] ?? 'after';
  final changaFile = env['CHANGA_FONT'];

  testWidgets(
    'render Changa marks previews',
    (tester) async {
      for (final m in ['toggle', 'isEnabled']) {
        tester.binding.defaultBinaryMessenger.setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.$m',
          (_) async => const StandardMessageCodec().encodeMessage(<Object?>[
            m == 'isEnabled' ? false : null,
          ]),
        );
      }
      await tester.runAsync(() async {
        final manifest = jsonDecode(
          await rootBundle.loadString('FontManifest.json'),
        ) as List<dynamic>;
        for (final f in manifest.cast<Map<String, dynamic>>()) {
          final family = f['family'] as String;
          final loader = FontLoader(family);
          if (family == 'Changa' && changaFile != null) {
            loader.addFont(
              Future.value(
                ByteData.sublistView(File(changaFile).readAsBytesSync()),
              ),
            );
          } else {
            for (final a in (f['fonts'] as List).cast<Map<String, dynamic>>()) {
              loader.addFont(
                rootBundle.load(Uri.decodeFull(a['asset'] as String)),
              );
            }
          }
          await loader.load();
        }
      });
      final registry = (await tester.runAsync(
        () => ThemeRegistry.load(rootBundle),
      ))!;
      final out = Directory(outPath)..createSync(recursive: true);
      tester.view.devicePixelRatio = 2;

      Future<void> capture(GlobalKey boundary, String name) async {
        final object =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final bytes = await tester.runAsync(() async {
          final image = await object.toImage(pixelRatio: 2);
          final d = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          return d!.buffer.asUint8List();
        });
        File('${out.path}/${tag}_$name.png').writeAsBytesSync(bytes!);
      }

      // 1. Specimens: every mark, every interface font.
      final style = registry.byId('zakhrafa');
      for (final font in UiFont.values) {
        for (final mode in [ThemeModeId.light, ThemeModeId.night]) {
          await tester.binding.setSurfaceSize(const Size(560, 640));
          final boundary = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              // A new app each time: no animation from the last theme.
              key: UniqueKey(),
              debugShowCheckedModeBanner: false,
              theme: buildTheme(style: style, mode: mode, uiFont: font),
              home: RepaintBoundary(
                key: boundary,
                child: Scaffold(
                  body: _Specimen(font: font, tag: tag),
                ),
              ),
            ),
          );
          await tester.pump();
          await capture(boundary, 'specimen_${font.name}_${mode.name}');
        }
      }
      await tester.pumpWidget(const SizedBox());

      // 2. Real screens whose words carry a shadda with a haraka.
      final db = ContentDatabase(
        NativeDatabase(
          File('assets/db/content.db'),
          setup: (raw) => raw.execute('PRAGMA query_only = ON'),
        ),
      );
      final flags = (await tester.runAsync(
        () => FeatureFlags.load(rootBundle),
      ))!;
      final root = Directory.systemTemp.createTempSync('changa_marks');

      Future<void> shot(
        String name,
        String location, {
        String mode = 'light',
        bool tafsirInUiFont = false,
      }) async {
        SharedPreferences.setMockInitialValues({
          'settings.onboardingDone': true,
          'settings.language': 'ar',
          'settings.style': 'zakhrafa',
          'settings.mode': mode,
          'settings.uiFont': 'changa',
          if (tafsirInUiFont) 'settings.tafsirFont': 'interface',
          whatsNewSeenKey: whatsNewId,
        });
        final prefs = await SharedPreferences.getInstance();
        final user = UserDatabase(NativeDatabase.memory());
        await tester.binding.setSurfaceSize(const Size(393, 852));
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
        await capture(boundary, name);
        await tester.pumpWidget(const SizedBox());
        container.dispose();
      }

      for (final mode in ['light', 'night']) {
        await shot('about_$mode', '/mushaf/about', mode: mode);
        await shot('storage_$mode', '/settings/storage', mode: mode);
        await shot(
          'tafsir_ui_font_$mode',
          '/mushaf/tafsir?s=2&a=255',
          mode: mode,
          tafsirInUiFont: true,
        );
      }
      await tester.pump(const Duration(seconds: 10));
      await tester.runAsync(db.close);
    },
    skip: !run,
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

/// What the picture shows: the samples big, then at each size and weight.
class _Specimen extends StatelessWidget {
  const _Specimen({required this.font, required this.tag});

  final UiFont font;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    TextStyle s(double size, FontWeight w) =>
        TextStyle(fontSize: size, fontWeight: w, color: ink, height: 1.6);
    final short = markSamples.take(12).join('  ');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${font.family} · $tag',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontFamily: 'IBMPlexSans',
                fontSize: 13,
                color: muted,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 18,
              children: [
                for (final w in markSamples)
                  Text(w, style: s(26, FontWeight.w400)),
              ],
            ),
            const Divider(),
            Text(
              'محمّد  مُحَمَّد  رَبِّ  إِنَّ  نُزِّل',
              style: s(46, FontWeight.w400),
            ),
            const Divider(),
            for (final size in [14.0, 18.0, 24.0])
              for (final w in [
                FontWeight.w300,
                FontWeight.w400,
                FontWeight.w700,
              ])
                Text(
                  '$short  ${size.toInt()}/${w.value}',
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: s(size, w),
                ),
          ],
        ),
      ),
    );
  }
}
