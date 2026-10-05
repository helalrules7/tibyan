import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../theme/theme_registry.dart';
import '../../features/home/whats_new.dart' show whatsNewId, whatsNewSeenKey;
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
  static const _kTouchReading = 'settings.touchReading';
  static const _kVersePause = 'settings.versePause';
  static const _kRepeat = 'settings.repeat';
  static const _kRepeatSilence = 'settings.repeatSilence';
  static const _kPlaybackSpeed = 'settings.playbackSpeed';
  static const _kUnderVerse = 'settings.underVerse';
  static const _kSplitTranslation = 'settings.splitTranslation';
  static const _kTwoPageSpread = 'settings.twoPageSpread';
  static const _kOneVerseAuto = 'settings.oneVerseAutoSeconds';
  static const _kElderly = 'settings.elderlyMode';
  static const _kTajweed = 'settings.tajweedColors';
  static const _kTajweedHues = 'settings.tajweedHues';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final registry = ref.read(themeRegistryProvider);
    final storedStyle = _prefs.getString(_kStyle);
    final styleIds = registry.styles.map((s) => s.id).toSet();
    final styleId = storedStyle != null && styleIds.contains(storedStyle)
        ? storedStyle
        : registry.defaultStyleId;
    return AppSettings(
      styleId: styleId,
      mode:
          _enumByName(ModeSetting.values, _prefs.getString(_kMode)) ??
          ModeSetting.light,
      uiFont:
          _enumByName(UiFont.values, _prefs.getString(_kUiFont)) ??
          UiFont.changa,
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
          _defaultMarker(styleId),
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
      riwayaReciters: {
        for (final r in Riwaya.values)
          if (r != Riwaya.hafs && _prefs.getInt('$_kReciter.${r.name}') != null)
            r: _prefs.getInt('$_kReciter.${r.name}')!,
      },
      followRecitation: _prefs.getBool(_kFollow) ?? true,
      touchReading: _prefs.getBool(_kTouchReading) ?? true,
      versePause: _prefs.getInt(_kVersePause) ?? 500,
      repeat: _prefs.getInt(_kRepeat) ?? 1,
      repeatSilence: _prefs.getInt(_kRepeatSilence) ?? 0,
      playbackSpeed: _prefs.getDouble(_kPlaybackSpeed) ?? 1.0,
      underVerse: [
        for (final id in _prefs.getStringList(_kUnderVerse) ?? const <String>[])
          ?int.tryParse(id),
      ],
      splitTranslation: _prefs.getBool(_kSplitTranslation) ?? false,
      twoPageSpread: _prefs.getBool(_kTwoPageSpread) ?? true,
      oneVerseAutoSeconds: _prefs.getInt(_kOneVerseAuto) ?? 0,
      elderlyMode: _prefs.getBool(_kElderly) ?? false,
      tajweedColors: _prefs.getBool(_kTajweed) ?? false,
      tajweedHues: {
        for (final e in _prefs.getStringList(_kTajweedHues) ?? const <String>[])
          if (e.indexOf('=') case final i when i > 0)
            e.substring(0, i): e.substring(i + 1),
      },
    );
  }

  /// Until the reader picks a marker shape, a heritage theme draws its own
  /// marker and Zakhrafa its 16-point rosette.
  MarkerStyle _defaultMarker(String styleId) =>
      ref.read(themeRegistryProvider).byId(styleId).art != null
      ? MarkerStyle.theme
      : MarkerStyle.rosette16;

  /// A new theme brings its own marker shape, over any shape chosen
  /// before; the reader can pick another one afterwards.
  Future<void> setStyle(String styleId) async {
    final changed = styleId != state.styleId;
    state = state.copyWith(
      styleId: styleId,
      markerStyle: changed ? _defaultMarker(styleId) : null,
    );
    await _prefs.setString(_kStyle, styleId);
    if (changed) await _prefs.remove(_kMarkerStyle);
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
    // A new reader meets everything at once: no «what's new» for them.
    await _prefs.setString(whatsNewSeenKey, whatsNewId);
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

  /// Chooses the recitation for [riwaya] (Hafs unless given).
  Future<void> setReciter(int id, {Riwaya riwaya = Riwaya.hafs}) async {
    if (riwaya == Riwaya.hafs) {
      state = state.copyWith(reciterId: id);
      await _prefs.setInt(_kReciter, id);
      return;
    }
    state = state.copyWith(
      riwayaReciters: {...state.riwayaReciters, riwaya: id},
    );
    await _prefs.setInt('$_kReciter.${riwaya.name}', id);
  }

  Future<void> setFollowRecitation(bool value) async {
    state = state.copyWith(followRecitation: value);
    await _prefs.setBool(_kFollow, value);
  }

  Future<void> setTouchReading(bool value) async {
    state = state.copyWith(touchReading: value);
    await _prefs.setBool(_kTouchReading, value);
  }

  Future<void> setVersePause(int ms) async {
    state = state.copyWith(versePause: ms);
    await _prefs.setInt(_kVersePause, ms);
  }

  Future<void> setRepeat(int times) async {
    state = state.copyWith(repeat: times);
    await _prefs.setInt(_kRepeat, times);
  }

  /// What shows under each verse: up to two source ids (see
  /// [AppSettings.underVerse]).
  Future<void> setUnderVerse(List<int> sourceIds) async {
    final ids = sourceIds.take(2).toList();
    state = state.copyWith(underVerse: ids);
    await _prefs.setStringList(_kUnderVerse, [for (final i in ids) '$i']);
  }

  Future<void> setOneVerseAutoSeconds(int seconds) async {
    state = state.copyWith(oneVerseAutoSeconds: seconds);
    await _prefs.setInt(_kOneVerseAuto, seconds);
  }

  Future<void> setTwoPageSpread(bool on) async {
    state = state.copyWith(twoPageSpread: on);
    await _prefs.setBool(_kTwoPageSpread, on);
  }

  Future<void> setSplitTranslation(bool on) async {
    state = state.copyWith(splitTranslation: on);
    await _prefs.setBool(_kSplitTranslation, on);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    state = state.copyWith(playbackSpeed: speed);
    await _prefs.setDouble(_kPlaybackSpeed, speed);
  }

  Future<void> setRepeatSilence(int seconds) async {
    state = state.copyWith(repeatSilence: seconds);
    await _prefs.setInt(_kRepeatSilence, seconds);
  }

  Future<void> setElderlyMode(bool value) async {
    state = state.copyWith(elderlyMode: value);
    await _prefs.setBool(_kElderly, value);
  }

  Future<void> setTajweedColors(bool value) async {
    state = state.copyWith(tajweedColors: value);
    await _prefs.setBool(_kTajweed, value);
  }

  /// [hue] is a TajweedHue name, '' for no colour, or null to go back to
  /// the rule's default.
  Future<void> setTajweedHue(String ruleKey, String? hue) async {
    final hues = {...state.tajweedHues};
    hue == null ? hues.remove(ruleKey) : hues[ruleKey] = hue;
    await _saveTajweedHues(hues);
  }

  /// Every rule back to its default colour.
  Future<void> resetTajweedHues() => _saveTajweedHues(const {});

  Future<void> _saveTajweedHues(Map<String, String> hues) async {
    state = state.copyWith(tajweedHues: hues);
    await _prefs.setStringList(_kTajweedHues, [
      for (final e in hues.entries) '${e.key}=${e.value}',
    ]);
  }

  static T? _enumByName<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}
