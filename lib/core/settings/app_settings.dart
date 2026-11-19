import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import '../theme/interface_style.dart';
import '../theme/theme_tokens.dart';
import '../../features/khatma/domain/khatmah.dart' show CountingMode;

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

/// «تأثير قلب الصفحة»: how the mushaf turns a page. [normal] (the default): the page
/// slides; [curl]: the page folds over in 3D like paper;
/// [bend]: the page wraps round a cylinder that follows the finger, its
/// print bending with it and its back showing (a fragment shader);
/// [fold]: a lighter bend, the edge folded back flat along a line;
/// [fade]: the next page fades in over the last.
enum PageTurn { normal, curl, bend, fold, fade }

/// A phone held sideways: [width] shows the page as wide as the screen,
/// read by scrolling down (the default); [page] fits the whole page to the
/// screen's height.
enum LandscapeFit { width, page }

/// «شكل الفاصلة»: how a named fasil shows on its page. [tint]: its verse
/// tinted in its colour (the first look, kept by readers who already had
/// fawasil); [ribbon]: a fabric ribbon laid over the page; [tab]: a die-cut
/// card slipped into the book, its ornamented dome hanging down.
enum FasilStyle { tint, ribbon, tab }

/// Where a ribbon or a tab sits on a phone's single page: [top], at the
/// top edge on the page's outer side, as in a printed mushaf; [side],
/// along the outer edge.
enum FasilPlace { top, side }

/// The ribbon's cloth.
enum FasilMaterial { silk, linen, velvet }

/// «شكل المشغل»: the player over the mushaf. [auto]: the normal bar, and
/// the pill in focus mode; [normal]: the bar everywhere; [pill]: the small
/// floating pill everywhere; [button]: one small round button everywhere.
enum PlayerStyle { auto, normal, pill, button }

/// «مؤقت سجدات التلاوة»: the lengths offered for the pause at a verse of
/// prostration, in seconds.
const sajdahTimerLengths = <int>[10, 15, 20, 30, 45, 60];

/// «سرعة القراءة» of the khatmas: how long a whole page must stay on
/// screen to count as read.
enum ReadingSpeed {
  slow(30),
  medium(20),
  fast(12);

  const ReadingSpeed(this.secondsPerPage);
  final int secondsPerPage;
}

bool commentaryDefaultShown({
  required String kind,
  required String contentLanguageCode,
  required String languageCode,
}) {
  if (contentLanguageCode.isEmpty) return false;
  if (kind == 'tafsir' && contentLanguageCode == 'ar') return true;
  return languageCode == contentLanguageCode;
}

bool defaultTranslationAudioEnabled(
  LanguageSetting language, {
  required String systemLanguageCode,
}) {
  final code = switch (language) {
    LanguageSetting.system => systemLanguageCode,
    LanguageSetting.ar => 'ar',
    LanguageSetting.en => 'en',
  };
  return code == 'en';
}

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
    this.shownCommentaries = const {},
    this.hiddenBookTafsirs = const {},
    this.englishTafsirVisibilityOverride,
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
    this.landscapeFit = LandscapeFit.width,
    this.oneVerseAutoSeconds = 0,
    this.elderlyMode = false,
    this.forceReduceMotion = false,
    this.announceVerseNumber = true,
    this.weeklyReminder = false,
    this.kahfReminder = true,
    this.weeklyReminderWeekday = DateTime.friday,
    this.weeklyReminderMinutes = 20 * 60,
    this.tajweedColors = false,
    this.tajweedHues = const {},
    this.focusMode = false,
    this.focusTools = FocusTools.button,
    this.focusToolsShown = false,
    this.autoScrollSpeed = 3,
    this.pageFill = PageFill.lines,
    this.pageTurn = PageTurn.normal,
    this.playerStyle = PlayerStyle.auto,
    this.playerPosition,
    this.sajdahTimer = false,
    this.sajdahSeconds = 20,
    this.dayStartHour = 3,
    this.readingSpeed = ReadingSpeed.medium,
    this.countListening = true,
    this.showWirdIndicator = true,
    this.khatmaCountingMode = CountingMode.wirdConfirm,
    this.interfaceStyle = defaultInterfaceStyle,
    this.fasilStyle,
    this.fasilPlace = FasilPlace.top,
    this.fasilMaterial = FasilMaterial.silk,
    this.fasilTassel = true,
    this.cellularDownloads = false,
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

  /// Source ids the reader explicitly turned on, even when they do not
  /// match the interface language.
  final Set<int> shownCommentaries;

  /// Keys of the book tafsirs (reviewed packs) the reader turned off.
  final Set<String> hiddenBookTafsirs;

  /// Explicit English-tafsir visibility choice; null follows the interface
  /// language (English shown, Arabic hidden).
  final bool? englishTafsirVisibilityOverride;

  bool isCommentaryShown(int sourceId, {required bool defaultShown}) {
    if (hiddenCommentaries.contains(sourceId)) return false;
    if (shownCommentaries.contains(sourceId)) return true;
    return defaultShown;
  }

  bool isEnglishTafsirShown(String languageCode) =>
      englishTafsirVisibilityOverride ?? languageCode != 'ar';

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

  /// A phone held sideways: the page fitted to the width or to the height.
  final LandscapeFit landscapeFit;

  /// «آية آية»: seconds before the next verse turns by itself; 0 for off.
  final int oneVerseAutoSeconds;

  /// «وضع كبار السن»: larger text and touch targets, stronger contrast, a
  /// home with only the main tasks, the page as large as it can be, and
  /// slower transitions.
  final bool elderlyMode;

  /// «تقليل الحركة»: less motion even when the device does not ask for it
  /// (off: follow the device).
  final bool forceReduceMotion;

  /// Screen readers: read a mushaf verse's surah and number before its
  /// text (on by default).
  final bool announceVerseNumber;

  /// «تذكير أسبوعي بالتقرير»: a local notification once a week (off by
  /// default) on [weeklyReminderWeekday] (`DateTime.monday` … `sunday`) at
  /// [weeklyReminderMinutes] after midnight.
  final bool weeklyReminder;

  /// A neutral reminder each Friday morning that opens Surah Al-Kahf in
  /// the edition being read (on by default; the reader may turn it off).
  final bool kahfReminder;
  final int weeklyReminderWeekday;
  final int weeklyReminderMinutes;

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

  /// Auto-scroll's speed, 1 (slowest) to 10, as the reader last left it.
  final int autoScrollSpeed;

  /// How the page fills the screen in focus mode.
  final PageFill pageFill;

  /// How a page turn looks.
  final PageTurn pageTurn;

  /// How the player over the mushaf looks.
  final PlayerStyle playerStyle;

  /// Where the floating player (the pill or the single button) was left:
  /// its centre as a fraction of the screen's width and height, so it is
  /// kept on screen whatever its size; null for the default place.
  final Offset? playerPosition;

  /// «مؤقت سجدات التلاوة»: at a verse of prostration the recitation pauses
  /// and a card with the sajdah's supplications counts down (off by
  /// default).
  final bool sajdahTimer;

  /// The card's countdown, one of [sajdahTimerLengths] (20 by default).
  final int sajdahSeconds;

  /// Khatmas: the hour the day starts (0–23, 3 by default): reading at
  /// 1:30 at night counts for the day before.
  final int dayStartHour;

  /// Khatmas: how long a page must stay on screen to count as read.
  final ReadingSpeed readingSpeed;

  /// Khatmas: verses heard to their end count as read (on by default).
  final bool countListening;

  /// Khatmas: today's portion shown in the reader («ورد اليوم · 18 / 20»).
  final bool showWirdIndicator;

  /// Khatmas: default counting mode («طريقة احتساب القراءة»).
  final CountingMode khatmaCountingMode;

  /// «شكل الواجهة»: the look of home, index, settings and the app's
  /// dialogs and sheets («هندسي» by default).
  final InterfaceStyle interfaceStyle;

  /// «شكل الفاصلة» as chosen; null until the reader chooses (asked as the
  /// first fasil is made). See [effectiveFasilStyle].
  final FasilStyle? fasilStyle;

  /// The look in use: a reader who never chose keeps the tinted verse.
  FasilStyle get effectiveFasilStyle => fasilStyle ?? FasilStyle.tint;

  /// Where ribbons and tabs sit on a phone's page.
  final FasilPlace fasilPlace;

  /// The ribbon's cloth.
  final FasilMaterial fasilMaterial;

  /// A tassel at the ribbon's end.
  final bool fasilTassel;

  /// Downloads may use mobile data without asking. Off: they wait for
  /// Wi‑Fi and the reader is asked first (phones only).
  final bool cellularDownloads;

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
    Set<int>? shownCommentaries,
    Set<String>? hiddenBookTafsirs,
    bool? englishTafsirVisibilityOverride,
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
    LandscapeFit? landscapeFit,
    int? oneVerseAutoSeconds,
    bool? elderlyMode,
    bool? forceReduceMotion,
    bool? announceVerseNumber,
    bool? weeklyReminder,
    bool? kahfReminder,
    int? weeklyReminderWeekday,
    int? weeklyReminderMinutes,
    bool? tajweedColors,
    Map<String, String>? tajweedHues,
    bool? focusMode,
    FocusTools? focusTools,
    bool? focusToolsShown,
    int? autoScrollSpeed,
    PageFill? pageFill,
    PageTurn? pageTurn,
    PlayerStyle? playerStyle,
    Offset? Function()? playerPosition,
    bool? sajdahTimer,
    int? sajdahSeconds,
    int? dayStartHour,
    ReadingSpeed? readingSpeed,
    bool? countListening,
    bool? showWirdIndicator,
    CountingMode? khatmaCountingMode,
    InterfaceStyle? interfaceStyle,
    FasilStyle? fasilStyle,
    FasilPlace? fasilPlace,
    FasilMaterial? fasilMaterial,
    bool? fasilTassel,
    bool? cellularDownloads,
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
    shownCommentaries: shownCommentaries ?? this.shownCommentaries,
    hiddenBookTafsirs: hiddenBookTafsirs ?? this.hiddenBookTafsirs,
    englishTafsirVisibilityOverride:
        englishTafsirVisibilityOverride ?? this.englishTafsirVisibilityOverride,
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
    landscapeFit: landscapeFit ?? this.landscapeFit,
    oneVerseAutoSeconds: oneVerseAutoSeconds ?? this.oneVerseAutoSeconds,
    elderlyMode: elderlyMode ?? this.elderlyMode,
    forceReduceMotion: forceReduceMotion ?? this.forceReduceMotion,
    announceVerseNumber: announceVerseNumber ?? this.announceVerseNumber,
    weeklyReminder: weeklyReminder ?? this.weeklyReminder,
    kahfReminder: kahfReminder ?? this.kahfReminder,
    weeklyReminderWeekday: weeklyReminderWeekday ?? this.weeklyReminderWeekday,
    weeklyReminderMinutes: weeklyReminderMinutes ?? this.weeklyReminderMinutes,
    tajweedColors: tajweedColors ?? this.tajweedColors,
    tajweedHues: tajweedHues ?? this.tajweedHues,
    focusMode: focusMode ?? this.focusMode,
    focusTools: focusTools ?? this.focusTools,
    focusToolsShown: focusToolsShown ?? this.focusToolsShown,
    autoScrollSpeed: autoScrollSpeed ?? this.autoScrollSpeed,
    pageFill: pageFill ?? this.pageFill,
    pageTurn: pageTurn ?? this.pageTurn,
    playerStyle: playerStyle ?? this.playerStyle,
    playerPosition: playerPosition == null
        ? this.playerPosition
        : playerPosition(),
    sajdahTimer: sajdahTimer ?? this.sajdahTimer,
    sajdahSeconds: sajdahSeconds ?? this.sajdahSeconds,
    dayStartHour: dayStartHour ?? this.dayStartHour,
    readingSpeed: readingSpeed ?? this.readingSpeed,
    countListening: countListening ?? this.countListening,
    showWirdIndicator: showWirdIndicator ?? this.showWirdIndicator,
    khatmaCountingMode: khatmaCountingMode ?? this.khatmaCountingMode,
    interfaceStyle: interfaceStyle ?? this.interfaceStyle,
    fasilStyle: fasilStyle ?? this.fasilStyle,
    fasilPlace: fasilPlace ?? this.fasilPlace,
    fasilMaterial: fasilMaterial ?? this.fasilMaterial,
    fasilTassel: fasilTassel ?? this.fasilTassel,
    cellularDownloads: cellularDownloads ?? this.cellularDownloads,
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
