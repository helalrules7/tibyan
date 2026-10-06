import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import '../theme/theme_tokens.dart';

/// How the colour mode is chosen: by the device, or fixed by the user.
enum ModeSetting { system, light, white, night, black }

/// Interface language: follow the device, or fixed by the user.
enum LanguageSetting { system, ar, en }

/// Mushaf edition shown in the page view: the two Madina prints and the
/// Shamarly (Egyptian) print in the riwaya of Hafs, and the KFGQPC Madina
/// mushafs of four other riwayat.
enum MushafEdition {
  madina1441,
  madina1405,
  shamarly,
  warsh,
  qalun,
  douri,
  shubah,
}

/// The riwaya an edition is printed in. Verse numbers follow the riwaya's
/// own count; tafsir, translation and bookmarks use Hafs numbers, reached
/// through each riwaya's verse map.
enum Riwaya { hafs, warsh, qalun, douri, shubah }

extension MushafEditionPages on MushafEdition {
  /// Pages of the printed mushaf, numbered from 1. Shamarly: page 1 is the
  /// cover and the text runs from page 2 to 522.
  int get pageCount => this == MushafEdition.shamarly ? 522 : 604;

  Riwaya get riwaya => switch (this) {
    MushafEdition.warsh => Riwaya.warsh,
    MushafEdition.qalun => Riwaya.qalun,
    MushafEdition.douri => Riwaya.douri,
    MushafEdition.shubah => Riwaya.shubah,
    _ => Riwaya.hafs,
  };

  /// A riwaya other than Hafs, numbered by its own count.
  bool get isRiwaya => riwaya != Riwaya.hafs;

  /// Drawn from KFGQPC's SVG page artwork (the new Madina edition and the
  /// riwaya editions).
  bool get isSvg => this == MushafEdition.madina1441 || isRiwaya;
}

/// Shape of the verse-end markers in the page view: the theme's own marker
/// (the default in the heritage themes; Zakhrafa's own is the 16-point
/// rosette), the mushaf's printed marker, or one of three rosettes drawn
/// over it.
enum MarkerStyle { theme, traditional, rosette7, rosette9, rosette16 }

/// Font of tafsir and translation texts.
enum TafsirFont { naskh, interface }

/// Focus mode: how the reading tools are reached. [button]: the top bar's
/// three buttons; [menu]: a long press on the page opens a dialog with
/// every tool, and the top bar keeps only the exit.
enum FocusTools { button, menu }

/// Focus mode: how the page fills the screen. [lines]: each line fills
/// the width and the lines are spread over the height (the strip layouts);
/// [stretch]: the same, plus up to 12% across where the page is fitted to
/// the height (the image pages' `StripLayout.maxStretch`); [full]: the page is scaled on both
/// axes to the room, which changes the letters' shape.
enum PageFill { lines, stretch, full }

/// «شكل المشغل»: the player over the mushaf. [auto]: the normal bar, and
/// the pill in focus mode; [normal]: the bar everywhere; [pill]: the small
/// floating pill everywhere; [button]: one small round button everywhere.
enum PlayerStyle { auto, normal, pill, button }

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
    this.uiFont = UiFont.changa,
    this.language = LanguageSetting.ar,
    this.crashReportsOptIn = false,
    this.onboardingDone = false,
    this.edition = MushafEdition.madina1441,
    this.keepScreenOn = true,
    this.markerStyle = MarkerStyle.rosette16,
    this.markerTint,
    this.highlightDivineNames = true,
    this.tafsirFont = TafsirFont.naskh,
    this.tafsirFontScale = 1.0,
    this.hiddenCommentaries = const {},
    this.hiddenBookTafsirs = const {},
    this.tafsirKashida = false,
    this.reciterId = 1,
    this.riwayaReciters = const {},
    this.followRecitation = true,
    this.touchReading = true,
    this.versePause = 500,
    this.tapJumpFromWord = false,
    this.repeat = 1,
    this.repeatSilence = 0,
    this.playbackSpeed = 1.0,
    this.underVerse = const [],
    this.splitTranslation = false,
    this.twoPageSpread = true,
    this.oneVerseAutoSeconds = 0,
    this.elderlyMode = false,
    this.tajweedColors = false,
    this.tajweedHues = const {},
    this.focusMode = false,
    this.focusTools = FocusTools.button,
    this.focusToolsShown = false,
    this.pageFill = PageFill.lines,
    this.playerStyle = PlayerStyle.auto,
    this.playerPosition,
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

  /// Keys of the book tafsirs (reviewed packs) the reader turned off.
  final Set<String> hiddenBookTafsirs;

  /// Trial: justify Arabic tafsir with tatweel instead of wider spaces.
  final bool tafsirKashida;

  /// Recitation chosen in the player (content.db `reciter.id`).
  final int reciterId;

  /// Recitation chosen for each riwaya other than Hafs ([reciterId] is
  /// Hafs's); a riwaya not listed plays its first recitation.
  final Map<Riwaya, int> riwayaReciters;

  /// The recitation chosen for [riwaya], or null for its first one.
  int? reciterFor(Riwaya riwaya) =>
      riwaya == Riwaya.hafs ? reciterId : riwayaReciters[riwaya];

  /// Turn pages to follow the verse being recited.
  final bool followRecitation;

  /// Touch reading: tapping a verse shades it. Kept for the whole mushaf.
  final bool touchReading;

  /// Longest pause kept between verses while listening, in ms; 0 plays
  /// the recording as it is.
  final int versePause;

  /// A tap on a verse while listening moves the reciter to the word tapped
  /// (when it has a word timing) rather than to the verse's start.
  final bool tapJumpFromWord;

  /// Times the player plays each verse, or the chosen stretch; 0 repeats
  /// until stopped.
  final int repeat;

  /// Seconds of silence between repetitions, to repeat after the reciter.
  final int repeatSilence;

  /// Recitation speed (1.0 as recorded).
  final double playbackSpeed;

  /// What is shown under each verse in the continuous view and beside the
  /// page: the source ids of up to two translations, or of al-Muyassar;
  /// empty for the Arabic only (docs/features/translation_under_ayah.md).
  final List<int> underVerse;

  /// Wide screens: the page with the texts of [underVerse] beside it.
  final bool splitTranslation;

  /// Wide screens held sideways: two pages side by side.
  final bool twoPageSpread;

  /// «آية آية»: seconds before the next verse turns by itself; 0 for off.
  final int oneVerseAutoSeconds;

  /// «وضع كبار السن»: larger text and touch targets, stronger contrast, a
  /// home with only the main tasks, the page as large as it can be, and
  /// slower transitions.
  final bool elderlyMode;

  /// Colour the letters that tajweed rules apply to (off by default).
  final bool tajweedColors;

  /// The reader's colour for a rule, by the rule's data key: a hue name
  /// (TajweedHue), or '' for no colour. Rules not listed use their default.
  final Map<String, String> tajweedHues;

  /// «وضع التركيز»: the reading screen with nothing around the page.
  final bool focusMode;

  /// How focus mode's tools are reached.
  final FocusTools focusTools;

  /// Focus mode's reading tools were left shown under the page (by the top
  /// bar's tools button); kept until the reader hides them.
  final bool focusToolsShown;

  /// How the page fills the screen in focus mode.
  final PageFill pageFill;

  /// How the player over the mushaf looks.
  final PlayerStyle playerStyle;

  /// Where the floating player (the pill or the single button) was left:
  /// its centre as a fraction of the screen's width and height, so it is
  /// kept on screen whatever its size; null for the default place.
  final Offset? playerPosition;

  /// The player style in effect: [PlayerStyle.auto] is the normal bar, or
  /// the pill while focus mode is on.
  PlayerStyle get effectivePlayerStyle => playerStyle != PlayerStyle.auto
      ? playerStyle
      : focusMode
      ? PlayerStyle.pill
      : PlayerStyle.normal;

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
    Set<String>? hiddenBookTafsirs,
    bool? tafsirKashida,
    int? reciterId,
    Map<Riwaya, int>? riwayaReciters,
    bool? followRecitation,
    bool? touchReading,
    int? versePause,
    bool? tapJumpFromWord,
    int? repeat,
    int? repeatSilence,
    double? playbackSpeed,
    List<int>? underVerse,
    bool? splitTranslation,
    bool? twoPageSpread,
    int? oneVerseAutoSeconds,
    bool? elderlyMode,
    bool? tajweedColors,
    Map<String, String>? tajweedHues,
    bool? focusMode,
    FocusTools? focusTools,
    bool? focusToolsShown,
    PageFill? pageFill,
    PlayerStyle? playerStyle,
    Offset? Function()? playerPosition,
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
    hiddenBookTafsirs: hiddenBookTafsirs ?? this.hiddenBookTafsirs,
    tafsirKashida: tafsirKashida ?? this.tafsirKashida,
    reciterId: reciterId ?? this.reciterId,
    riwayaReciters: riwayaReciters ?? this.riwayaReciters,
    followRecitation: followRecitation ?? this.followRecitation,
    touchReading: touchReading ?? this.touchReading,
    versePause: versePause ?? this.versePause,
    tapJumpFromWord: tapJumpFromWord ?? this.tapJumpFromWord,
    repeat: repeat ?? this.repeat,
    repeatSilence: repeatSilence ?? this.repeatSilence,
    playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    underVerse: underVerse ?? this.underVerse,
    splitTranslation: splitTranslation ?? this.splitTranslation,
    twoPageSpread: twoPageSpread ?? this.twoPageSpread,
    oneVerseAutoSeconds: oneVerseAutoSeconds ?? this.oneVerseAutoSeconds,
    elderlyMode: elderlyMode ?? this.elderlyMode,
    tajweedColors: tajweedColors ?? this.tajweedColors,
    tajweedHues: tajweedHues ?? this.tajweedHues,
    focusMode: focusMode ?? this.focusMode,
    focusTools: focusTools ?? this.focusTools,
    focusToolsShown: focusToolsShown ?? this.focusToolsShown,
    pageFill: pageFill ?? this.pageFill,
    playerStyle: playerStyle ?? this.playerStyle,
    playerPosition: playerPosition == null
        ? this.playerPosition
        : playerPosition(),
  );

  /// Resolves the colour mode. A dark device maps to Night (never pure
  /// white text); Bright white and Black are only used when the user picks
  /// them.
  ThemeModeId resolveMode(Brightness platformBrightness) => switch (mode) {
    ModeSetting.light => ThemeModeId.light,
    ModeSetting.white => ThemeModeId.white,
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
