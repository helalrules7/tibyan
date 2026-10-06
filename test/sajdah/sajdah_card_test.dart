import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/sajdah/sajdah_card.dart';
import 'package:tibyan/l10n/app_localizations.dart';

/// The sizes of opening_fit_test.
const sizes = {
  'iPhone 6.1"': Size(393, 852),
  'iPhone 6.7"': Size(430, 932),
  'iPhone SE': Size(375, 667),
  'Android': Size(412, 915),
  'laptop': Size(1440, 900),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(ProviderContainer, ThemeRegistry)> setUpContainer(
    WidgetTester? tester, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final registry = tester == null
        ? await ThemeRegistry.load(rootBundle)
        : (await tester.runAsync(() => ThemeRegistry.load(rootBundle)))!;
    final sp = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        themeRegistryProvider.overrideWithValue(registry),
        sharedPreferencesProvider.overrideWithValue(sp),
      ],
    );
    addTearDown(c.dispose);
    return (c, registry);
  }

  testWidgets('the countdown closes the card and runs its close', (
    tester,
  ) async {
    final (c, _) = await setUpContainer(
      tester,
      prefs: {'settings.sajdahSeconds': 10},
    );
    var closed = 0;
    c
        .read(sajdahCardProvider.notifier)
        .show(
          (surah: 32, ayah: 15),
          SajdahFrom.listening,
          onClose: () => closed++,
        );
    final card = c.read(sajdahCardProvider)!;
    expect(card.seconds, 10);
    expect(card.verse, (surah: 32, ayah: 15));
    await tester.pump(const Duration(seconds: 9));
    expect(c.read(sajdahCardProvider), isNotNull);
    await tester.pump(const Duration(seconds: 1));
    expect(c.read(sajdahCardProvider), isNull);
    expect(closed, 1);
    // Closing again does nothing.
    c.read(sajdahCardProvider.notifier).close();
    expect(closed, 1);
  });

  testWidgets('a dropped card does not run its close', (tester) async {
    final (c, _) = await setUpContainer(tester);
    var closed = 0;
    c
        .read(sajdahCardProvider.notifier)
        .show(
          (surah: 32, ayah: 15),
          SajdahFrom.reading,
          onClose: () => closed++,
        );
    c.read(sajdahCardProvider.notifier).drop();
    expect(c.read(sajdahCardProvider), isNull);
    await tester.pump(const Duration(seconds: 30));
    expect(closed, 0);
  });

  Future<void> pumpLayer(
    WidgetTester tester,
    ProviderContainer c,
    ThemeRegistry registry, {
    ThemeModeId mode = ThemeModeId.light,
    bool elderly = false,
  }) => tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(
          style: registry.byId(registry.defaultStyleId),
          mode: mode,
          uiFont: UiFont.changa,
          elderly: elderly,
        ),
        home: const Scaffold(body: Stack(children: [SajdahCardLayer()])),
      ),
    ),
  );

  testWidgets('a tap on the card closes it at once', (tester) async {
    final handle = tester.ensureSemantics();
    final (c, registry) = await setUpContainer(tester);
    await pumpLayer(tester, c, registry);
    var closed = 0;
    c
        .read(sajdahCardProvider.notifier)
        .show(
          (surah: 7, ayah: 206),
          SajdahFrom.listening,
          onClose: () => closed++,
        );
    await tester.pump();
    await tester.pump(SajdahCardLayer.fade);
    expect(find.text('اضغط للاستكمال'), findsOneWidget);
    expect(find.text('٢٠'), findsOneWidget, reason: 'the countdown');
    // Screen readers: the card is announced, and its button resumes.
    expect(find.bySemanticsLabel(RegExp('سجدة تلاوة')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('استكمال')), findsOneWidget);
    await tester.tap(find.text('اضغط للاستكمال'));
    await tester.pump();
    expect(closed, 1);
    // It fades out (the fade starts on the next frame).
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(SajdahCardLayer.fade);
    expect(find.text('اضغط للاستكمال'), findsNothing);
    handle.dispose();
  });

  for (final elderly in [false, true]) {
    for (final mode in [ThemeModeId.light, ThemeModeId.night]) {
      for (final MapEntry(key: name, value: size) in sizes.entries) {
        testWidgets(
          'within 40% of the screen: $name, ${mode.name}${elderly ? ', elderly' : ''}',
          (tester) async {
            tester.view
              ..physicalSize = size
              ..devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final (c, registry) = await setUpContainer(tester);
            await pumpLayer(tester, c, registry, mode: mode, elderly: elderly);
            c.read(sajdahCardProvider.notifier).show((
              surah: 32,
              ayah: 15,
            ), SajdahFrom.listening);
            await tester.pump();
            await tester.pump(SajdahCardLayer.fade);
            final box = tester.getRect(find.byType(SajdahCardView));
            expect(box.height, lessThanOrEqualTo(size.height * 0.4 + 0.01));
            expect(box.width, lessThanOrEqualTo(420));
            expect(box.width, lessThanOrEqualTo(size.width * 0.85 + 0.01));
            expect(box.center.dx, closeTo(size.width / 2, 1));
            expect(box.center.dy, closeTo(size.height / 2, 1));
            expect(tester.takeException(), isNull);
            c.read(sajdahCardProvider.notifier).drop();
          },
        );
      }
    }
  }
}
