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
  static const _kOnboarding = 'settings.onboardingDone';
  static const _kEdition = 'settings.edition';
  static const _kKeepOn = 'settings.keepScreenOn';
  static const _kFontScale = 'settings.quranFontScale';
  static const _kMarkerStyle = 'settings.markerStyle';
  static const _kMarkerTint = 'settings.markerTint';
  static const _kDivine = 'settings.highlightDivineNames';

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
      onboardingDone: _prefs.getBool(_kOnboarding) ?? false,
      edition:
          _enumByName(MushafEdition.values, _prefs.getString(_kEdition)) ??
          MushafEdition.madina1441,
      keepScreenOn: _prefs.getBool(_kKeepOn) ?? true,
      quranFontScale: _prefs.getDouble(_kFontScale) ?? 1.0,
      markerStyle:
          _enumByName(MarkerStyle.values, _prefs.getString(_kMarkerStyle)) ??
          MarkerStyle.traditional,
      markerTint: _prefs.getInt(_kMarkerTint),
      highlightDivineNames: _prefs.getBool(_kDivine) ?? true,
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

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingDone: true);
    await _prefs.setBool(_kOnboarding, true);
  }

  Future<void> setEdition(MushafEdition edition) async {
    state = state.copyWith(edition: edition);
    await _prefs.setString(_kEdition, edition.name);
  }

  Future<void> setKeepScreenOn(bool value) async {
    state = state.copyWith(keepScreenOn: value);
    await _prefs.setBool(_kKeepOn, value);
  }

  Future<void> setQuranFontScale(double value) async {
    final clamped = value.clamp(0.8, 2.0).toDouble();
    state = state.copyWith(quranFontScale: clamped);
    await _prefs.setDouble(_kFontScale, clamped);
  }

  Future<void> setMarkerStyle(MarkerStyle style) async {
    state = state.copyWith(markerStyle: style);
    await _prefs.setString(_kMarkerStyle, style.name);
  }

  Future<void> setHighlightDivineNames(bool value) async {
    state = state.copyWith(highlightDivineNames: value);
    await _prefs.setBool(_kDivine, value);
  }

  Future<void> setMarkerTint(int? argb) async {
    state = state.copyWith(markerTint: () => argb);
    if (argb == null) {
      await _prefs.remove(_kMarkerTint);
    } else {
      await _prefs.setInt(_kMarkerTint, argb);
    }
  }

  static T? _enumByName<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}
