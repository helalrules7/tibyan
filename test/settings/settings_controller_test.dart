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

  test(
    'defaults: Arabic, Zakhrafa, Light, KFGQPC AN, crash reports off',
    () async {
      final c = await containerWith({});
      final s = c.read(settingsProvider);
      expect(s.styleId, 'zakhrafa');
      expect(s.mode, ModeSetting.light);
      expect(s.uiFont, UiFont.kfgqpcAn);
      expect(s.crashReportsOptIn, isFalse);
      // Arabic whatever the device's language.
      expect(s.language, LanguageSetting.ar);
      expect(s.locale, const Locale('ar'));
    },
  );

  test('changes are saved and restored', () async {
    final c = await containerWith({});
    final ctrl = c.read(settingsProvider.notifier);
    await ctrl.setStyle('royal');
    await ctrl.setMode(ModeSetting.black);
    await ctrl.setUiFont(UiFont.kfgqpcAn);
    await ctrl.setLanguage(LanguageSetting.en);

    final sp = await SharedPreferences.getInstance();
    final restored = await containerWith({
      for (final k in sp.getKeys()) k: sp.get(k)!,
    });
    final s = restored.read(settingsProvider);
    expect(s.styleId, 'royal');
    expect(s.mode, ModeSetting.black);
    expect(s.uiFont, UiFont.kfgqpcAn);
    expect(s.locale, const Locale('en'));
  });

  test('unknown stored style falls back to the default', () async {
    final c = await containerWith({'settings.style': 'removed-style'});
    expect(c.read(settingsProvider).styleId, 'zakhrafa');
  });

  test('system mode: dark device gives Night, never Black', () {
    const s = AppSettings(styleId: 'classic', mode: ModeSetting.system);
    expect(s.resolveMode(Brightness.dark), ThemeModeId.night);
    expect(s.resolveMode(Brightness.light), ThemeModeId.light);
    expect(
      s.copyWith(mode: ModeSetting.black).resolveMode(Brightness.light),
      ThemeModeId.black,
    );
  });
}
