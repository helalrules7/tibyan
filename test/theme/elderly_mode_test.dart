import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/contrast.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/home/home_screen.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeRegistry registry;
  setUpAll(() async => registry = await ThemeRegistry.load(rootBundle));

  test('elderly colours reach the stronger contrast in every theme and mode', () {
    final failures = <String>[];
    for (final style in registry.styles) {
      for (final MapEntry(key: mode, value: base) in style.modes.entries) {
        final t = elderlyTokens(base);
        void need(String what, Color fg, Color bg, double min) {
          final r = contrastRatio(fg, bg);
          if (r < min) {
            failures.add(
              '${style.id}/${mode.name}: $what ${r.toStringAsFixed(2)} < $min',
            );
          }
        }

        for (final (ground, name) in [(t.paper, 'paper'), (t.bg, 'bg')]) {
          need('ink on $name', t.ink, ground, 7);
          need('muted on $name', t.muted, ground, 7);
          need('gold on $name', t.goldText, ground, 7);
          need('border on $name', t.border, ground, 3);
          need('control on $name', t.control, ground, 4.5);
        }
        need('on control', t.onControl, t.control, 7);
        need('player', t.playerFg, t.player, 7);
        need('surah header', t.headFg, t.headBg, 7);
        need('marker', t.marker, t.paper, 4.5);
        // Never weaker than the theme itself.
        expect(
          contrastRatio(t.muted, t.paper),
          greaterThanOrEqualTo(contrastRatio(base.muted, base.paper) - 1e-9),
        );
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('elderly theme: 56 px targets and a slower plain transition', () {
    final style = registry.byId(registry.defaultStyleId);
    final theme = buildTheme(
      style: style,
      mode: ThemeModeId.light,
      uiFont: UiFont.changa,
      elderly: true,
    );
    expect(theme.extension<TibyanTokens>()!.elderly, isTrue);
    expect(
      theme.iconButtonTheme.style!.minimumSize!.resolve({}),
      const Size(elderlyTarget, elderlyTarget),
    );
    expect(
      theme.filledButtonTheme.style!.minimumSize!.resolve({})!.height,
      elderlyTarget,
    );
    expect(theme.listTileTheme.minTileHeight, greaterThanOrEqualTo(56));
    final builder =
        theme.pageTransitionsTheme.builders[TargetPlatform.android]!;
    expect(builder, isA<ElderlyPageTransitionsBuilder>());
    expect(
      builder.transitionDuration,
      greaterThan(const Duration(milliseconds: 300)),
    );
    final normal = buildTheme(
      style: style,
      mode: ThemeModeId.light,
      uiFont: UiFont.changa,
    );
    expect(normal.extension<TibyanTokens>()!.elderly, isFalse);
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    required String style,
    required ThemeModeId mode,
  }) async {
    SharedPreferences.setMockInitialValues({'settings.elderlyMode': true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeRegistryProvider.overrideWithValue(registry),
          sharedPreferencesProvider.overrideWithValue(prefs),
          packRootProvider.overrideWithValue(
            Directory.systemTemp.createTempSync('packs'),
          ),
          readingPositionProvider.overrideWith((ref) => Stream.value(null)),
          surahsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: buildTheme(
            style: registry.byId(style),
            mode: mode,
            uiFont: UiFont.changa,
            elderly: true,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('elderly home: three main tasks and settings, each labelled', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpHome(
      tester,
      style: registry.defaultStyleId,
      mode: ThemeModeId.light,
    );
    expect(find.text('متابعة القراءة'), findsOneWidget);
    expect(find.text('الاستماع'), findsOneWidget);
    expect(find.text('البحث'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
    // Nothing else from the full home.
    expect(find.text('التفسير'), findsNothing);
    expect(find.text('قريبا'), findsNothing);

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    // Every button is at least 56 px high.
    for (final e in find.byType(InkWell).evaluate()) {
      expect(
        tester.getSize(find.byWidget(e.widget)).height,
        greaterThanOrEqualTo(elderlyTarget),
      );
    }
    handle.dispose();
  });

  testWidgets('elderly home reads in every theme in the dark modes too', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    for (final style in registry.styles) {
      for (final mode in ThemeModeId.values) {
        await pumpHome(tester, style: style.id, mode: mode);
        await expectLater(
          tester,
          meetsGuideline(textContrastGuideline),
          reason: '${style.id}/${mode.name}',
        );
      }
    }
    handle.dispose();
  });

  test('the setting is kept', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        themeRegistryProvider.overrideWithValue(registry),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    expect(c.read(settingsProvider).elderlyMode, isFalse);
    await c.read(settingsProvider.notifier).setElderlyMode(true);
    expect(prefs.getBool('settings.elderlyMode'), isTrue);
    final again = ProviderContainer(
      overrides: [
        themeRegistryProvider.overrideWithValue(registry),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    expect(again.read(settingsProvider).elderlyMode, isTrue);
    expect(const AppSettings(styleId: 'x').elderlyMode, isFalse);
  });
}
