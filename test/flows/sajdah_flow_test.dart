import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/native.dart';
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
import 'package:tibyan/features/sajdah/sajdah_card.dart';

/// Not listening.
class IdleRecitation extends RecitationController {
  @override
  RecitationState build() => const RecitationState();
}

/// The sajdah card on the page: touch reading on the verse after a verse
/// of prostration (al-Alaq 19, page 598) shows it; the timer off, nothing.
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
    root = Directory.systemTemp.createTempSync('sajdah_flow');
    final dir = Directory(p.join(root.path, 'packs', 'pages-hafs-1441-v1'))
      ..createSync(recursive: true);
    final zip = ZipDecoder().decodeBytes(
      File('assets/packs/pages-hafs-1441-v1.zip').readAsBytesSync(),
    );
    for (final name in ['597.svg.xz', '598.svg.xz']) {
      final entry = zip.findFile(name)!;
      File(p.join(dir.path, entry.name)).writeAsBytesSync(entry.content);
    }
    File(p.join(dir.path, '.installed')).writeAsStringSync('test');
  });
  tearDownAll(() => db.close());

  Future<ProviderContainer> start(
    WidgetTester tester, {
    required bool timer,
  }) async {
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
      'settings.sajdahTimer': timer,
      'settings.sajdahSeconds': 10,
      whatsNewSeenKey: whatsNewId,
    });
    final registry = (await tester.runAsync(
      () => ThemeRegistry.load(rootBundle),
    ))!;
    final flags = (await tester.runAsync(() => FeatureFlags.load(rootBundle)))!;
    final prefs = await SharedPreferences.getInstance();
    final user = UserDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(user.close));
    await tester.binding.setSurfaceSize(const Size(600, 1000));
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
        recitationProvider.overrideWith(IdleRecitation.new),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TibyanApp()),
    );
    await tester.pump(const Duration(seconds: 2));
    container.read(appRouterProvider).go('/mushaf?page=598');
    return container;
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

  /// The screen reader's node of verse [n] of [surah].
  Finder verse(String surah, int n) => find.bySemanticsLabel(
    RegExp(
      '$surah.*${n.toString().split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join()}',
    ),
  );

  final card = find.text('اضغط للاستكمال');

  testWidgets(
    'touching the verse after a verse of prostration shows the card',
    (tester) async {
      final handle = tester.ensureSemantics();
      final c = await start(tester, timer: true);
      await settle(tester, verse('القدر', 1));
      await settle(tester); // the page's words, for touches

      // The verse of prostration itself: no card.
      await tester.tapAt(tester.getRect(verse('العلق', 18).first).center);
      await tester.pump();
      expect(c.read(sajdahCardProvider), isNull);

      // The verse after it (al-Qadr 1): the card, for al-Alaq 19.
      await tester.tapAt(tester.getRect(verse('القدر', 1).first).center);
      await tester.pump();
      await tester.pump(SajdahCardLayer.fade);
      expect(c.read(sajdahCardProvider)?.verse, (surah: 96, ayah: 19));
      expect(c.read(sajdahCardProvider)?.from, SajdahFrom.reading);
      expect(card, findsOneWidget);
      // It counts down and fades out.
      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(SajdahCardLayer.fade);
      expect(c.read(sajdahCardProvider), isNull);
      expect(card, findsNothing);

      // Again, and a tap on the card closes it at once.
      await tester.tapAt(tester.getRect(verse('القدر', 1).first).center);
      await tester.pump();
      await tester.pump(SajdahCardLayer.fade);
      await tester.tap(card);
      await tester.pump();
      expect(c.read(sajdahCardProvider), isNull);
      await tester.pump(SajdahCardLayer.fade);
      handle.dispose();
    },
  );

  testWidgets('a card from the recitation shows over the page', (tester) async {
    final c = await start(tester, timer: true);
    await settle(tester);
    var resumed = 0;
    c
        .read(sajdahCardProvider.notifier)
        .show(
          (surah: 96, ayah: 19),
          SajdahFrom.listening,
          onClose: () => resumed++,
        );
    await tester.pump();
    await tester.pump(SajdahCardLayer.fade);
    expect(card, findsOneWidget);
    await tester.tap(card);
    await tester.pump();
    expect(resumed, 1);
    await tester.pump(SajdahCardLayer.fade);
  });

  testWidgets('the timer off: touching the verse after shows nothing', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final c = await start(tester, timer: false);
    await settle(tester, verse('القدر', 1));
    await settle(tester);
    await tester.tapAt(tester.getRect(verse('القدر', 1).first).center);
    await tester.pump();
    await tester.pump(SajdahCardLayer.fade);
    expect(c.read(sajdahCardProvider), isNull);
    expect(card, findsNothing);
    handle.dispose();
  });
}
