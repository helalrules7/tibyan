import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import '../theme/theme_tokens.dart';

/// How the colour mode is chosen: by the device, or fixed by the user.
enum ModeSetting { system, light, night, black }

/// Interface language: follow the device, or fixed by the user.
enum LanguageSetting { system, ar, en }

/// Madina mushaf edition shown in the page view.
enum MushafEdition { madina1441, madina1405 }

@immutable
class AppSettings {
  const AppSettings({
    required this.styleId,
    this.mode = ModeSetting.light,
    this.uiFont = UiFont.kfgqpcAn,
    this.language = LanguageSetting.system,
    this.crashReportsOptIn = false,
    this.onboardingDone = false,
    this.edition = MushafEdition.madina1441,
    this.keepScreenOn = true,
    this.quranFontScale = 1.0,
  });

  final String styleId;
  final ModeSetting mode;
  final UiFont uiFont;
  final LanguageSetting language;

  /// Crash reports are sent only after the user turns this on.
  final bool crashReportsOptIn;

  /// The first-launch screens (style, then edition) were completed or skipped.
  final bool onboardingDone;
  final MushafEdition edition;

  /// Keep the screen awake while the mushaf is open.
  final bool keepScreenOn;

  /// Quran text size in the continuous view (1.0 = default).
  final double quranFontScale;

  AppSettings copyWith({
    String? styleId,
    ModeSetting? mode,
    UiFont? uiFont,
    LanguageSetting? language,
    bool? crashReportsOptIn,
    bool? onboardingDone,
    MushafEdition? edition,
    bool? keepScreenOn,
    double? quranFontScale,
  }) => AppSettings(
    styleId: styleId ?? this.styleId,
    mode: mode ?? this.mode,
    uiFont: uiFont ?? this.uiFont,
    language: language ?? this.language,
    crashReportsOptIn: crashReportsOptIn ?? this.crashReportsOptIn,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    edition: edition ?? this.edition,
    keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    quranFontScale: quranFontScale ?? this.quranFontScale,
  );

  /// Resolves the colour mode. A dark device maps to Night (never pure
  /// white text); Black is only used when the user picks it.
  ThemeModeId resolveMode(Brightness platformBrightness) => switch (mode) {
    ModeSetting.light => ThemeModeId.light,
    ModeSetting.night => ThemeModeId.night,
    ModeSetting.black => ThemeModeId.black,
    ModeSetting.system =>
      platformBrightness == Brightness.dark
          ? ThemeModeId.night
          : ThemeModeId.light,
  };

  /// `null` means: follow the device language.
  Locale? get locale => switch (language) {
    LanguageSetting.system => null,
    LanguageSetting.ar => const Locale('ar'),
    LanguageSetting.en => const Locale('en'),
  };
}
