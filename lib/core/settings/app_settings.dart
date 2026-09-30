import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import '../theme/theme_tokens.dart';

/// How the colour mode is chosen: by the device, or fixed by the user.
enum ModeSetting { system, light, night, black }

/// Interface language: follow the device, or fixed by the user.
enum LanguageSetting { system, ar, en }

/// Mushaf edition shown in the page view: the two Madina prints and the
/// Shamarly (Egyptian) print.
enum MushafEdition { madina1441, madina1405, shamarly }

extension MushafEditionPages on MushafEdition {
  /// Pages of the printed mushaf, numbered from 1. Shamarly: page 1 is the
  /// cover and the text runs from page 2 to 522.
  int get pageCount => this == MushafEdition.shamarly ? 522 : 604;
}

/// Shape of the verse-end markers in the page view: the mushaf's own
/// (default) or one of three rosettes drawn over it.
enum MarkerStyle { traditional, rosette7, rosette9, rosette16 }

/// The page frame's design. Every style frames its pages; this chooses
/// the ornament: the Zakhrafa images, the plain rules, or one of the six
/// drawn designs (`assets/config/frame_<name>.json`).
enum FrameDesign {
  zakhrafa,
  plain,
  abbasid,
  umayyad,
  andalusian,
  ottoman,
  egyptian,
  modernIslamic,
}

/// Each style's own frame: Zakhrafa's illuminated frame, and a drawn
/// design for the others (the plain frame for a style not listed).
FrameDesign defaultFrameFor(String styleId) => switch (styleId) {
  'zakhrafa' => FrameDesign.zakhrafa,
  'royal' => FrameDesign.abbasid,
  'classic' => FrameDesign.ottoman,
  'manuscript' => FrameDesign.andalusian,
  'calm' => FrameDesign.modernIslamic,
  _ => FrameDesign.plain,
};

/// Font of tafsir and translation texts.
enum TafsirFont { naskh, interface }

/// Colours offered for tinting verse-end markers (ARGB); null = none.
const markerTints = <int>[
  0xFF1FA79B,
  0xFFE6784A,
  0xFF4F79B7,
  0xFF1C2F45,
  0xFFC9A45C,
];

@immutable
class AppSettings {
  const AppSettings({
    required this.styleId,
    this.mode = ModeSetting.light,
    this.uiFont = UiFont.kfgqpcAn,
    this.language = LanguageSetting.ar,
    this.crashReportsOptIn = false,
    this.onboardingDone = false,
    this.edition = MushafEdition.madina1441,
    this.keepScreenOn = true,
    this.markerStyle = MarkerStyle.traditional,
    this.markerTint,
    this.highlightDivineNames = true,
    this.tafsirFont = TafsirFont.naskh,
    this.tafsirFontScale = 1.0,
    this.hiddenCommentaries = const {},
    this.tafsirKashida = false,
    this.reciterId = 1,
    this.followRecitation = true,
    this.versePause = 0,
    this.frameDesign,
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

  final MarkerStyle markerStyle;

  /// ARGB tint behind verse-end markers; null leaves them as printed.
  final int? markerTint;

  /// Colour «الله» and «رب» / «ربنا» on the page (on by default).
  final bool highlightDivineNames;

  final TafsirFont tafsirFont;

  /// Size of tafsir and translation texts (1.0 = default).
  final double tafsirFontScale;

  /// Source ids of tafsirs and translations the reader turned off.
  final Set<int> hiddenCommentaries;

  /// Trial: justify Arabic tafsir with tatweel instead of wider spaces.
  final bool tafsirKashida;

  /// Recitation chosen in the player (content.db `reciter.id`).
  final int reciterId;

  /// Turn pages to follow the verse being recited.
  final bool followRecitation;

  /// Longest pause kept between verses while listening, in ms; 0 plays
  /// the recording as it is.
  final int versePause;

  /// The frame chosen by the reader; null uses the style's own.
  final FrameDesign? frameDesign;

  AppSettings copyWith({
    String? styleId,
    ModeSetting? mode,
    UiFont? uiFont,
    LanguageSetting? language,
    bool? crashReportsOptIn,
    bool? onboardingDone,
    MushafEdition? edition,
    bool? keepScreenOn,
    MarkerStyle? markerStyle,
    int? Function()? markerTint,
    bool? highlightDivineNames,
    TafsirFont? tafsirFont,
    double? tafsirFontScale,
    Set<int>? hiddenCommentaries,
    bool? tafsirKashida,
    int? reciterId,
    bool? followRecitation,
    int? versePause,
    FrameDesign? Function()? frameDesign,
  }) => AppSettings(
    styleId: styleId ?? this.styleId,
    mode: mode ?? this.mode,
    uiFont: uiFont ?? this.uiFont,
    language: language ?? this.language,
    crashReportsOptIn: crashReportsOptIn ?? this.crashReportsOptIn,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    edition: edition ?? this.edition,
    keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    markerStyle: markerStyle ?? this.markerStyle,
    markerTint: markerTint == null ? this.markerTint : markerTint(),
    highlightDivineNames: highlightDivineNames ?? this.highlightDivineNames,
    tafsirFont: tafsirFont ?? this.tafsirFont,
    tafsirFontScale: tafsirFontScale ?? this.tafsirFontScale,
    hiddenCommentaries: hiddenCommentaries ?? this.hiddenCommentaries,
    tafsirKashida: tafsirKashida ?? this.tafsirKashida,
    reciterId: reciterId ?? this.reciterId,
    followRecitation: followRecitation ?? this.followRecitation,
    versePause: versePause ?? this.versePause,
    frameDesign: frameDesign == null ? this.frameDesign : frameDesign(),
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
