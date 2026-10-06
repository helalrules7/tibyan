import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerWith(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final registry = await ThemeRegistry.load(rootBundle);
    final sp = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [
        themeRegistryProvider.overrideWithValue(registry),
        sharedPreferencesProvider.overrideWithValue(sp),
      ],
    );
  }

  test('defaults: Arabic, Zakhrafa, Light, Changa, 16-point rosette, crash reports off', () async {
    final c = await containerWith({});
    final s = c.read(settingsProvider);
    expect(s.styleId, 'zakhrafa');
    expect(s.mode, ModeSetting.light);
    expect(s.uiFont, UiFont.changa);
    expect(s.markerStyle, MarkerStyle.rosette16);
    expect(s.markerTint, isNull);
    expect(s.crashReportsOptIn, isFalse);
    // Arabic whatever the device's language.
    expect(s.language, LanguageSetting.ar);
    expect(s.locale, const Locale('ar'));
  });

  test('changes are saved and restored', () async {
    final c = await containerWith({});
    final ctrl = c.read(settingsProvider.notifier);
    await ctrl.setStyle('zakhrafa');
    await ctrl.setMode(ModeSetting.white);
    await ctrl.setUiFont(UiFont.kfgqpcAn);
    await ctrl.setLanguage(LanguageSetting.en);

    final sp = await SharedPreferences.getInstance();
    final restored = await containerWith({
      for (final k in sp.getKeys()) k: sp.get(k)!,
    });
    final s = restored.read(settingsProvider);
    expect(s.styleId, 'zakhrafa');
    expect(s.mode, ModeSetting.white);
    expect(s.uiFont, UiFont.kfgqpcAn);
    expect(s.locale, const Locale('en'));
  });

  test(
    'a new theme brings its own marker shape over an earlier choice',
    () async {
      final c = await containerWith({});
      final ctrl = c.read(settingsProvider.notifier);
      await ctrl.setMarkerStyle(MarkerStyle.rosette7);
      await ctrl.setStyle('mamluk');
      expect(c.read(settingsProvider).markerStyle, MarkerStyle.theme);
      // The reader can still choose another shape afterwards, and keeps it.
      await ctrl.setMarkerStyle(MarkerStyle.traditional);
      await ctrl.setStyle('mamluk');
      expect(c.read(settingsProvider).markerStyle, MarkerStyle.traditional);
      // Back to Zakhrafa: its rosette, also after a restart.
      await ctrl.setStyle('zakhrafa');
      expect(c.read(settingsProvider).markerStyle, MarkerStyle.rosette16);
      final sp = await SharedPreferences.getInstance();
      final restored = await containerWith({
        for (final k in sp.getKeys()) k: sp.get(k)!,
      });
      expect(
        restored.read(settingsProvider).markerStyle,
        MarkerStyle.rosette16,
      );
    },
  );

  test('unknown stored style falls back to the default', () async {
    final c = await containerWith({'settings.style': 'removed-style'});
    expect(c.read(settingsProvider).styleId, 'zakhrafa');
  });

  test('a removed style and frame from an older version load safely', () async {
    final c = await containerWith({
      'settings.style': 'royal',
      'settings.frameDesign': 'ottoman',
      'settings.mode': 'no-such-mode',
    });
    final s = c.read(settingsProvider);
    expect(s.styleId, 'zakhrafa');
    expect(s.mode, ModeSetting.light);
    expect(c.read(themeRegistryProvider).byId('royal').id, 'zakhrafa');
  });

  test('bright white: resolves, counts as light, pure white', () async {
    const s = AppSettings(styleId: 'zakhrafa', mode: ModeSetting.white);
    final mode = s.resolveMode(Brightness.dark);
    expect(mode, ThemeModeId.white);
    expect(mode.isLight, isTrue);
    expect(ThemeModeId.light.isLight, isTrue);
    expect(ThemeModeId.night.isLight, isFalse);
    expect(ThemeModeId.black.isLight, isFalse);
    final c = await containerWith({});
    final style = c.read(themeRegistryProvider).byId('zakhrafa');
    final t = style.modes[ThemeModeId.white]!;
    expect(t.bg, const Color(0xFFFFFFFF));
    expect(t.paper, const Color(0xFFFFFFFF));
    final theme = buildTheme(style: style, mode: mode, uiFont: UiFont.plex);
    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, const Color(0xFFFFFFFF));
  });

  test('system mode: dark device gives Night, never Black', () {
    const s = AppSettings(styleId: 'zakhrafa', mode: ModeSetting.system);
    expect(s.resolveMode(Brightness.dark), ThemeModeId.night);
    expect(s.resolveMode(Brightness.light), ThemeModeId.light);
    expect(
      s.copyWith(mode: ModeSetting.black).resolveMode(Brightness.light),
      ThemeModeId.black,
    );
  });

  test(
    'focus mode and the player style: defaults, saved and restored',
    () async {
      final c = await containerWith({});
      final s = c.read(settingsProvider);
      expect(s.focusMode, isFalse);
      expect(s.focusTools, FocusTools.button);
      expect(s.pageFill, PageFill.lines);
      expect(s.playerStyle, PlayerStyle.auto);
      expect(s.playerPosition, isNull);
      // Automatic: the normal bar, and the pill in focus mode.
      expect(s.effectivePlayerStyle, PlayerStyle.normal);
      expect(
        s.copyWith(focusMode: true).effectivePlayerStyle,
        PlayerStyle.pill,
      );
      expect(
        s
            .copyWith(focusMode: true, playerStyle: PlayerStyle.normal)
            .effectivePlayerStyle,
        PlayerStyle.normal,
      );

      final ctrl = c.read(settingsProvider.notifier);
      await ctrl.setFocusMode(true);
      await ctrl.setFocusTools(FocusTools.menu);
      await ctrl.setPageFill(PageFill.full);
      await ctrl.setPlayerStyle(PlayerStyle.button);
      await ctrl.setPlayerPosition(const Offset(0.25, 1.4));
      await ctrl.setFocusToolsShown(true);
      await ctrl.setAutoScrollSpeed(12);
      final sp = await SharedPreferences.getInstance();
      final restored = await containerWith({
        for (final k in sp.getKeys()) k: sp.get(k)!,
      });
      final r = restored.read(settingsProvider);
      expect(r.focusMode, isTrue);
      expect(r.focusTools, FocusTools.menu);
      expect(r.pageFill, PageFill.full);
      expect(r.playerStyle, PlayerStyle.button);
      // Kept inside the screen.
      expect(r.playerPosition, const Offset(0.25, 1));
      expect(r.focusToolsShown, isTrue);
      // Kept within 1–10.
      expect(r.autoScrollSpeed, 10);
    },
  );
}
