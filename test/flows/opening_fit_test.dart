import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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
import 'package:tibyan/features/mushaf/presentation/widgets/opening_art.dart';

/// The opening pages (the cover, al-Fatiha, the start of al-Baqarah) fit
/// the screen whole at phone, small phone, Android and laptop sizes: their
/// frame is never cropped and nothing overflows.
void main() {
  late ContentDatabase db;
  late Directory root;
  setUpAll(() {
    db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
    // The new Madina edition's last pages, as an installed pack.
    root = Directory.systemTemp.createTempSync('flows');
    final dir = Directory(p.join(root.path, 'packs', 'pages-hafs-1441-v1'))
      ..createSync(recursive: true);
    final zip = ZipDecoder().decodeBytes(
      File('assets/packs/pages-hafs-1441-v1.zip').readAsBytesSync(),
    );
    for (final name in ['001.svg.xz', '002.svg.xz']) {
      final entry = zip.findFile(name)!;
      File(p.join(dir.path, entry.name)).writeAsBytesSync(entry.content);
    }
    File(p.join(dir.path, '.installed')).writeAsStringSync('test');
  });
  tearDownAll(() => db.close());

  Future<(ProviderContainer, UserDatabase)> start(
    WidgetTester tester, {
    Size size = const Size(430, 900),
    String style = 'zakhrafa',
  }) async {
    // The screen stays on while reading: answer the wakelock plugin.
    for (final m in ['toggle', 'isEnabled']) {
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.$m',
        (_) async => const StandardMessageCodec().encodeMessage(<Object?>[
          m == 'isEnabled' ? false : null,
        ]),
      );
    }
    SharedPreferences.setMockInitialValues({
      'settings.onboardingDone': true,
      'settings.language': 'ar',
      'settings.style': style,
      whatsNewSeenKey: whatsNewId,
    });
    final registry = (await tester.runAsync(
      () => ThemeRegistry.load(rootBundle),
    ))!;
    final flags = (await tester.runAsync(() => FeatureFlags.load(rootBundle)))!;
    final prefs = await SharedPreferences.getInstance();
    final user = UserDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(user.close));
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TibyanApp()),
    );
    await tester.pump(const Duration(seconds: 2));
    return (container, user);
  }

  Future<void> settle(WidgetTester tester, [Finder? until]) async {
    for (var i = 0; i < 40; i++) {
      if (until != null && until.evaluate().isNotEmpty) return;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  const sizes = {
    'iPhone 6.1"': Size(393, 852),
    'iPhone 6.7"': Size(430, 932),
    'iPhone SE': Size(375, 667),
    'Android': Size(412, 915),
    'laptop': Size(1440, 900),
  };

  for (final style in ['zakhrafa', 'seljuk']) {
    for (final MapEntry(key: name, value: size) in sizes.entries) {
      testWidgets('$style, $name: the opening pages fit whole', (tester) async {
        final (container, _) = await start(tester, size: size, style: style);
        // The app opens on the home screen, which is not under test here:
        // its tiles' labels may not fit the test font on a small phone.
        tester.takeException();
        final screen = Offset.zero & size;
        for (final page in [0, 1, 2]) {
          container.read(appRouterProvider).go('/mushaf?page=$page');
          await settle(tester, find.byType(OpeningArtBody));
          await settle(tester);
          expect(tester.takeException(), isNull, reason: 'page $page');
          final bodies = find.byType(OpeningArtBody);
          // The laptop shows al-Fatiha and al-Baqarah side by side.
          expect(bodies, findsWidgets);
          for (final body in bodies.evaluate()) {
            final box = tester.getRect(find.byWidget(body.widget));
            if (!box.overlaps(screen)) continue; // a page off screen
            expect(box.left, greaterThanOrEqualTo(-0.01), reason: '$page');
            expect(box.right, lessThanOrEqualTo(size.width + 0.01));
            expect(box.top, greaterThanOrEqualTo(-0.01));
            expect(box.bottom, lessThanOrEqualTo(size.height + 0.01));
            final number = (body.widget as OpeningArtBody).pageNumber == null
                ? 0.0
                : OpeningArtBody.numberSpace;
            final g = OpeningArtGeometry.fit(
              Size(box.width, box.height - number),
            );
            final frame = g.frame.shift(box.topLeft);
            // The whole drawing, inside its room and on the screen.
            expect(g.frame.width / g.scale, closeTo(1200, 0.01));
            expect(frame.left, greaterThanOrEqualTo(box.left - 0.01));
            expect(frame.right, lessThanOrEqualTo(box.right + 0.01));
            expect(frame.top, greaterThanOrEqualTo(box.top - 0.01));
            expect(frame.bottom, lessThanOrEqualTo(box.bottom + 0.01));
            // The page inside stays a readable size.
            final panel = g.place(OpeningArtLayout.panel);
            expect(panel.width, greaterThan(150), reason: '$page $size');
          }
        }
      });
    }
  }
}
