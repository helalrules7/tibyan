import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../theme/theme_registry.dart';
import 'app_settings.dart';

/// Overridden in `main()` once assets and preferences are loaded.
final themeRegistryProvider = Provider<ThemeRegistry>(
  (ref) => throw UnimplementedError('themeRegistryProvider not overridden'),
);

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  static const _kStyle = 'settings.style';
  static const _kMode = 'settings.mode';
  static const _kUiFont = 'settings.uiFont';
  static const _kLanguage = 'settings.language';
  static const _kCrash = 'settings.crashReportsOptIn';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final registry = ref.read(themeRegistryProvider);
    final storedStyle = _prefs.getString(_kStyle);
    final styleIds = registry.styles.map((s) => s.id).toSet();
    return AppSettings(
      styleId: storedStyle != null && styleIds.contains(storedStyle)
          ? storedStyle
          : registry.defaultStyleId,
      mode:
          _enumByName(ModeSetting.values, _prefs.getString(_kMode)) ??
          ModeSetting.light,
      uiFont:
          _enumByName(UiFont.values, _prefs.getString(_kUiFont)) ??
          UiFont.kfgqpcAn,
      language:
          _enumByName(LanguageSetting.values, _prefs.getString(_kLanguage)) ??
          LanguageSetting.system,
      crashReportsOptIn: _prefs.getBool(_kCrash) ?? false,
    );
  }

  Future<void> setStyle(String styleId) async {
    state = state.copyWith(styleId: styleId);
    await _prefs.setString(_kStyle, styleId);
  }

  Future<void> setMode(ModeSetting mode) async {
    state = state.copyWith(mode: mode);
    await _prefs.setString(_kMode, mode.name);
  }

  Future<void> setUiFont(UiFont font) async {
    state = state.copyWith(uiFont: font);
    await _prefs.setString(_kUiFont, font.name);
  }

  Future<void> setLanguage(LanguageSetting language) async {
    state = state.copyWith(language: language);
    await _prefs.setString(_kLanguage, language.name);
  }

  Future<void> setCrashReportsOptIn(bool value) async {
    state = state.copyWith(crashReportsOptIn: value);
    await _prefs.setBool(_kCrash, value);
  }

  static T? _enumByName<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}
