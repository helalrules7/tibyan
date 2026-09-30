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
  static const _kMarkerStyle = 'settings.markerStyle';
  static const _kMarkerTint = 'settings.markerTint';
  static const _kDivine = 'settings.highlightDivineNames';
  static const _kTafsirFont = 'settings.tafsirFont';
  static const _kTafsirScale = 'settings.tafsirFontScale';
  static const _kHiddenCommentaries = 'settings.hiddenCommentaries';
  static const _kKashida = 'settings.tafsirKashida';
  static const _kReciter = 'settings.reciterId';
  static const _kFollow = 'settings.followRecitation';
  static const _kVersePause = 'settings.versePause';
  static const _kFrame = 'settings.frameDesign';

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
          // Arabic unless the reader chooses otherwise, whatever the device.
          LanguageSetting.ar,
      crashReportsOptIn: _prefs.getBool(_kCrash) ?? false,
      onboardingDone: _prefs.getBool(_kOnboarding) ?? false,
      edition:
          _enumByName(MushafEdition.values, _prefs.getString(_kEdition)) ??
          MushafEdition.madina1441,
      keepScreenOn: _prefs.getBool(_kKeepOn) ?? true,
      markerStyle:
          _enumByName(MarkerStyle.values, _prefs.getString(_kMarkerStyle)) ??
          MarkerStyle.traditional,
      markerTint: _prefs.getInt(_kMarkerTint),
      highlightDivineNames: _prefs.getBool(_kDivine) ?? true,
      tafsirFont:
          _enumByName(TafsirFont.values, _prefs.getString(_kTafsirFont)) ??
          TafsirFont.naskh,
      tafsirFontScale: _prefs.getDouble(_kTafsirScale) ?? 1.0,
      hiddenCommentaries: {
        for (final id in _prefs.getStringList(_kHiddenCommentaries) ?? [])
          ?int.tryParse(id),
      },
      tafsirKashida: _prefs.getBool(_kKashida) ?? false,
      reciterId: _prefs.getInt(_kReciter) ?? 1,
      followRecitation: _prefs.getBool(_kFollow) ?? true,
      versePause: _prefs.getInt(_kVersePause) ?? 0,
      frameDesign: _enumByName(FrameDesign.values, _prefs.getString(_kFrame)),
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

  Future<void> setTafsirFont(TafsirFont font) async {
    state = state.copyWith(tafsirFont: font);
    await _prefs.setString(_kTafsirFont, font.name);
  }

  Future<void> setTafsirFontScale(double value) async {
    final clamped = value.clamp(0.8, 1.8).toDouble();
    state = state.copyWith(tafsirFontScale: clamped);
    await _prefs.setDouble(_kTafsirScale, clamped);
  }

  Future<void> setCommentaryShown(int sourceId, bool shown) async {
    final hidden = {...state.hiddenCommentaries};
    shown ? hidden.remove(sourceId) : hidden.add(sourceId);
    state = state.copyWith(hiddenCommentaries: hidden);
    await _prefs.setStringList(_kHiddenCommentaries, [
      for (final id in hidden) '$id',
    ]);
  }

  Future<void> setTafsirKashida(bool value) async {
    state = state.copyWith(tafsirKashida: value);
    await _prefs.setBool(_kKashida, value);
  }

  Future<void> setReciter(int id) async {
    state = state.copyWith(reciterId: id);
    await _prefs.setInt(_kReciter, id);
  }

  Future<void> setFollowRecitation(bool value) async {
    state = state.copyWith(followRecitation: value);
    await _prefs.setBool(_kFollow, value);
  }

  Future<void> setVersePause(int ms) async {
    state = state.copyWith(versePause: ms);
    await _prefs.setInt(_kVersePause, ms);
  }

  /// Null goes back to the style's own frame.
  Future<void> setFrameDesign(FrameDesign? design) async {
    state = state.copyWith(frameDesign: () => design);
    if (design == null) {
      await _prefs.remove(_kFrame);
    } else {
      await _prefs.setString(_kFrame, design.name);
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
