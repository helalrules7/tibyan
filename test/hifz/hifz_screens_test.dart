import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/db/user_database.dart';
import 'package:tibyan/features/hifz/data/hifz_store.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/hifz/domain/strength.dart';
import 'package:tibyan/features/hifz/presentation/hifz_map_screen.dart';
import 'package:tibyan/features/hifz/presentation/hifz_screen.dart';
import 'package:tibyan/features/hifz/presentation/similar_sheet.dart';
import 'package:tibyan/features/hifz/presentation/strength_style.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/l10n/app_localizations.dart';

void main() {
  late ContentDatabase content;
  late UserDatabase user;
  late ThemeRegistry registry;

  setUpAll(() async {
    content = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
    registry = await ThemeRegistry.load(rootBundle);
  });
  tearDownAll(() => content.close());
  setUp(() => user = UserDatabase(NativeDatabase.memory()));
  tearDown(() => user.close());

  Widget app(Widget home, {ThemeModeId mode = ThemeModeId.light}) =>
      ProviderScope(
        overrides: [
          contentDatabaseProvider.overrideWithValue(content),
          userDatabaseProvider.overrideWithValue(user),
          editionProvider.overrideWithValue(MushafEdition.madina1441),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTheme(
            style: registry.byId(registry.defaultStyleId),
            mode: mode,
            uiFont: UiFont.plex,
          ),
          home: home,
        ),
      );

  /// Unmounts the screen and lets drift close its query streams (which
  /// schedule a zero-length timer each).
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  }

  /// Lets the database streams and futures (on real isolates) settle.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await tester.pump();
    }
  }

  testWidgets('nothing due: the screen says so and offers a test', (
    tester,
  ) async {
    await tester.pumpWidget(app(const HifzScreen()));
    await settle(tester);
    expect(find.text('مراجعة اليوم'), findsOneWidget);
    expect(find.text('لا مراجعة مستحقة اليوم.'), findsOneWidget);
    expect(find.text('ابدأ تسميعا'), findsOneWidget);
    expect(find.text('خريطة الحفظ'), findsOneWidget);

    await tester.tap(find.text('ابدأ تسميعا'));
    await settle(tester);
    expect(find.text('ماذا تسمّع؟'), findsOneWidget);
    expect(find.text('ربع'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('a due unit is listed with its range and strength', (
    tester,
  ) async {
    final today = DateTime.now();
    await tester.runAsync(() async {
      await user.saveSrsReview(
        unit: 'page',
        fromRef: '2:1',
        toRef: '2:5',
        stability: 3.7,
        difficulty: 5,
        dueAt: DateTime(today.year, today.month, today.day),
        lapse: false,
        now: today.subtract(const Duration(days: 4)),
      );
      await user.saveSrsReview(
        unit: 'surah',
        fromRef: '67:1',
        toRef: '67:30',
        stability: 40,
        difficulty: 5,
        dueAt: today.add(const Duration(days: 30)),
        lapse: false,
        now: today,
      );
    });
    await tester.pumpWidget(app(const HifzScreen()));
    await settle(tester);
    expect(find.text('لا مراجعة مستحقة اليوم.'), findsNothing);
    expect(find.text('الصفحة ٢'), findsOneWidget);
    expect(find.textContaining('البقرة ١–٥'), findsOneWidget);
    expect(find.textContaining('مستحقة اليوم · متوسط'), findsOneWidget);
    // Later units are listed under all units.
    await tester.scrollUntilVisible(find.text('سورة الملك'), 200);
    expect(find.text('كل وحدات المراجعة'), findsOneWidget);
    expect(find.textContaining('جيد'), findsWidgets);
    await finish(tester);
  });

  testWidgets('the map colours pages by their weakest verse, with labels', (
    tester,
  ) async {
    await tester.runAsync(
      () => user.setVerseStrengths({'2:1': 4, '2:2': 4, '2:6': 1, '1:1': 3}),
    );
    await tester.pumpWidget(app(const HifzMapScreen()));
    await settle(tester);
    expect(find.bySemanticsLabel('الصفحة ٢: متقن'), findsOneWidget);
    expect(find.bySemanticsLabel('الصفحة ٣: ضعيف'), findsOneWidget);
    expect(find.bySemanticsLabel('الصفحة ١: جيد'), findsOneWidget);
    expect(find.bySemanticsLabel('الصفحة ٤: لم يُحفظ'), findsOneWidget);

    await tester.tap(find.text('السور'));
    await settle(tester);
    expect(find.bySemanticsLabel('سورة البقرة: ضعيف'), findsOneWidget);
    expect(find.bySemanticsLabel('سورة الفاتحة: جيد'), findsOneWidget);

    // Zoom buttons change the cell size.
    await tester.tap(find.byTooltip('تكبير'));
    await tester.pump();
    await finish(tester);
  });

  testWidgets('similar verses show the verses themselves and the credit', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const Scaffold(body: SimilarVersesView(surah: 2, ayah: 3))),
    );
    await settle(tester);
    expect(find.text('المتشابهات'), findsOneWidget);
    expect(find.textContaining('الآية · البقرة ٣'), findsOneWidget);
    expect(find.text('الأنفال ٣'), findsOneWidget);
    expect(find.text('النمل ٣'), findsOneWidget);
    expect(find.text('لقمان ٤'), findsOneWidget);
    expect(find.textContaining('Quran_Mutashabihat_Data'), findsOneWidget);
    await finish(tester);
  });

  test('the four strength colours step in lightness in every mode', () {
    for (final mode in ThemeModeId.values) {
      final l = [
        for (final s in Strength.values.skip(1))
          strengthFill(s, mode).computeLuminance(),
      ];
      for (var i = 1; i < l.length; i++) {
        expect((l[i] - l[i - 1]).abs(), greaterThan(0.04), reason: '$mode $i');
      }
      final rising = mode == ThemeModeId.light;
      for (var i = 1; i < l.length; i++) {
        expect(rising ? l[i] < l[i - 1] : l[i] > l[i - 1], isTrue);
      }
    }
  });
}
