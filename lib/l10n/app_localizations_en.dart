// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tibyan';

  @override
  String get appTagline => 'Tafsir, recitation and memorization of the Quran';

  @override
  String get homeComingTitle => 'Under construction';

  @override
  String get homeComingBody =>
      'This is the first build of Tibyan: it has the styles and settings only. The mushaf, tafsir and recitation arrive in the next phases, in sha Allah.';

  @override
  String get sectionMushaf => 'Mushaf';

  @override
  String get sectionTafsir => 'Tafsir';

  @override
  String get sectionListen => 'Listen';

  @override
  String get sectionHifz => 'Memorize';

  @override
  String get sectionKhatma => 'Khatma';

  @override
  String get sectionSearch => 'Search';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get openSettings => 'Open settings';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get styleLabel => 'Style';

  @override
  String get modeLabel => 'Mode';

  @override
  String get modeSystem => 'Automatic';

  @override
  String get modeSystemHint => 'Follows the device setting';

  @override
  String get modeLight => 'Light';

  @override
  String get modeNight => 'Night';

  @override
  String get modeBlack => 'Black';

  @override
  String get uiFontLabel => 'Interface font';

  @override
  String get uiFontPlex => 'IBM Plex Sans Arabic';

  @override
  String get uiFontKfgqpcAn => 'KFGQPC font (AN)';

  @override
  String get uiFontChanga => 'Changa';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'Device language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get crashReportsLabel => 'Send crash reports';

  @override
  String get crashReportsHint =>
      'Sends technical crash details only, with no personal data. Off until you agree.';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutBody =>
      'Tibyan is a free, non-profit app with no ads and no purchases, and its code is open. Every text in it comes from a verified source, shown next to it.';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get previewLabel => 'Preview';

  @override
  String get selected => 'Selected';

  @override
  String get onbLanguageTitle => 'اختر اللغة\nChoose your language';

  @override
  String get onbStyleTitle => 'Choose the look that is easy on your eyes';

  @override
  String get onbStyleHint => 'You can change it anytime in Settings';

  @override
  String get continueLabel => 'Continue';

  @override
  String get skipLabel => 'Skip';

  @override
  String get onbEditionTitle => 'Choose the mushaf edition';

  @override
  String get editionNew => 'Madina Mushaf: new edition';

  @override
  String get editionNewDesc =>
      'The 1441H print of the King Fahd Complex, with verse highlighting during recitation.';

  @override
  String get editionOld => 'Madina Mushaf: classic edition';

  @override
  String get editionOldDesc =>
      'The well-known 1405H print used by older apps, with word highlighting.';

  @override
  String get editionShamarly => 'Shamarly (Egyptian edition)';

  @override
  String get editionShamarlyDesc =>
      'The well-known Egyptian Shamarly print, 522 pages, with verse highlighting and word highlighting in many verses.';

  @override
  String get defaultTag => 'Default';

  @override
  String pagesDownloadNote(String size) {
    return 'This edition\'s pages download once (about $size MB), then work offline. Until then you read the new Madina edition, which comes with the app.';
  }

  @override
  String get downloadTitle => 'Download mushaf pages';

  @override
  String get downloadStart => 'Start download';

  @override
  String get downloadPause => 'Pause';

  @override
  String get downloadResume => 'Resume download';

  @override
  String get downloadRetry => 'Try again';

  @override
  String get downloadVerifying => 'Checking the files…';

  @override
  String get downloadInstalling => 'Preparing the pages…';

  @override
  String get downloadDone => 'Download complete';

  @override
  String downloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String downloadProgress(String received, String total) {
    return '$received of $total MB';
  }

  @override
  String get downloadWifiHint =>
      'The download continues where it stopped if the connection drops. Wi-Fi is recommended.';

  @override
  String get pagesCredit =>
      'Madina Mushaf pages by the King Fahd Glorious Quran Printing Complex.';

  @override
  String get pagesCreditOld =>
      'Old edition (1405H) pages by the King Fahd Glorious Quran Printing Complex, sourced from quran.com and downloaded from Tibyan\'s server.';

  @override
  String get pagesCreditShamarly =>
      'Shamarly mushaf, calligraphy by Mohamed Saad Ibrahim (Haddad); pages from the Internet Archive (archive.org), downloaded from Tibyan\'s server.';

  @override
  String get editionLabel => 'Mushaf edition';

  @override
  String get viewPage => 'Page';

  @override
  String get viewModeLabel => 'View';

  @override
  String get indexTitle => 'Index';

  @override
  String get fawasilTitle => 'Bookmarks';

  @override
  String get aboutMushafTitle => 'About this mushaf';

  @override
  String juzPage(String juz, String page) {
    return 'Juz $juz · Page $page';
  }

  @override
  String surahWord(String name) {
    return 'Surah $name';
  }

  @override
  String verseSelected(String number) {
    return 'Verse $number selected';
  }

  @override
  String get tapVerseHint => 'Tap a verse to select it';

  @override
  String pageOf(String page) {
    return 'Page $page';
  }

  @override
  String get indexSearchHint => 'Surah name, page number, or 2:255';

  @override
  String get tabSurahs => 'Surahs';

  @override
  String get tabJuz => 'Juz';

  @override
  String get tabPages => 'Pages';

  @override
  String get meccan => 'Meccan';

  @override
  String get medinan => 'Medinan';

  @override
  String ayahCount(String count) {
    return '$count verses';
  }

  @override
  String juzLabel(String number) {
    return 'Juz $number';
  }

  @override
  String juzStartsAt(String surah, String ayah) {
    return 'Starts at $surah $ayah';
  }

  @override
  String pageShort(String page) {
    return 'p. $page';
  }

  @override
  String get lastPosition => 'Last reading position, saved automatically';

  @override
  String get yourFawasil => 'Your bookmarks';

  @override
  String get fasilNew => 'New bookmark';

  @override
  String get fasilName => 'Bookmark name';

  @override
  String get fasilSaveHere => 'Save the current place to a bookmark';

  @override
  String fasilLastAt(String surah, String ayah, String page) {
    return 'Last at: $surah $ayah · page $page';
  }

  @override
  String get fasilHint =>
      'Each bookmark has a name and colour, and moves to where you last read with it.';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get saved => 'Saved';

  @override
  String get noFawasil => 'No bookmarks yet';

  @override
  String get readingTitle => 'Reading';

  @override
  String get keepScreenOn => 'Keep the screen on while reading';

  @override
  String get aboutMushafIntro =>
      'Every text in Tibyan comes from a verified source and is never edited by us. These are the mushaf\'s sources:';

  @override
  String licenseLabel(String license) {
    return 'License: $license';
  }

  @override
  String versionShort(String version) {
    return 'Version: $version';
  }

  @override
  String get reviewNotesTitle => 'Questions under review';

  @override
  String reviewNotesBody(String count) {
    return '$count places where the two text sources differ (two juz boundaries and four spellings) are with a qualified reviewer. The app follows the Tanzil text until a decision is made.';
  }

  @override
  String get mushafOpen => 'Open the mushaf';

  @override
  String get loadingLabel => 'Loading…';

  @override
  String hizbLabel(String number) {
    return 'Hizb $number';
  }

  @override
  String catchwordLabel(String word) {
    return 'First word of the next page: $word';
  }

  @override
  String get tabHizb => 'Hizbs';

  @override
  String get goToPage => 'Go to page';

  @override
  String goToPageHint(String max) {
    return 'Page number, 1 to $max';
  }

  @override
  String get goLabel => 'Go';

  @override
  String hizbStartsAt(String surah, String ayah) {
    return 'Starts at $surah $ayah';
  }

  @override
  String get selectionStart => 'Start of selection';

  @override
  String get selectionEnd => 'End of selection';

  @override
  String get servicesTitle => 'Verse services';

  @override
  String get markReading => 'Reading';

  @override
  String get markReview => 'Review';

  @override
  String get markHifz => 'Memorizing';

  @override
  String get markTadabbur => 'Reflection';

  @override
  String autoFasil(String surah, String ayah) {
    return 'Reading mark set at $surah $ayah';
  }

  @override
  String markMoved(String mark, String surah, String ayah) {
    return '$mark: $surah $ayah';
  }

  @override
  String verseRange(String surah, String from, String to) {
    return '$surah $from–$to';
  }

  @override
  String versesCount(String count) {
    return '$count verses';
  }

  @override
  String get twoVerses => '2 verses';

  @override
  String get markerStyleLabel => 'Verse marker shape';

  @override
  String get markerTraditional => 'Traditional marker';

  @override
  String get markerRosette => 'Rosette';

  @override
  String get markerTintLabel => 'Marker colour';

  @override
  String get markerTintNone => 'No colour';

  @override
  String get reciteMode => 'Recitation mode';

  @override
  String get revealNextVerse => 'Next verse';

  @override
  String get revealAll => 'All';

  @override
  String get endRecite => 'End recitation';

  @override
  String get autoScroll => 'Auto-scroll';

  @override
  String get resume => 'Resume';

  @override
  String get pause => 'Pause';

  @override
  String get slower => 'Slower';

  @override
  String get faster => 'Faster';

  @override
  String get stopAutoScroll => 'Stop scrolling';

  @override
  String speedLabel(String speed) {
    return 'Speed $speed';
  }

  @override
  String surahBannerTitle(String number, String name, String type) {
    return '($number) Surah $name · $type';
  }

  @override
  String surahBannerInfo(String count, String order, String after) {
    return '$count verses · revealed ${order}th · after $after';
  }

  @override
  String surahBannerInfoFirst(String count, String order) {
    return '$count verses · revealed ${order}th';
  }

  @override
  String quarterHizb(String number) {
    return 'Quarter of hizb $number';
  }

  @override
  String halfHizb(String number) {
    return 'Half of hizb $number';
  }

  @override
  String threeQuartersHizb(String number) {
    return 'Three quarters of hizb $number';
  }

  @override
  String get coverTitle => 'The Noble Quran';

  @override
  String get coverSubtitle => 'In the Uthmani script';

  @override
  String get riwayaHafs => 'Hafs from Asim';

  @override
  String openingInfo(String type, String count, String number) {
    return '$type · $count verses · surah $number';
  }

  @override
  String revealedOrder(String order) {
    return 'Revealed ${order}th';
  }

  @override
  String revealedAfter(String after) {
    return 'After $after';
  }

  @override
  String get multiSelect => 'Select several verses';

  @override
  String get multiSelectHint => 'Drag the handles to select verses';

  @override
  String get doneLabel => 'Done';

  @override
  String get markRemoved => 'Mark removed';

  @override
  String get tabMarks => 'Reading marks';

  @override
  String get noMarks => 'No marks yet. Tap a verse marker to mark it.';

  @override
  String get highlightDivineNames => 'Highlight the divine name';

  @override
  String get highlightDivineNamesHint =>
      'Colour «Allah», «Rabb» and «Rabbana» on the pages';

  @override
  String get tafsirTitle => 'Tafsir and translation';

  @override
  String get tafsirSettings => 'Tafsir settings';

  @override
  String get tafsirFontLabel => 'Tafsir font';

  @override
  String get tafsirFontNaskh => 'Uthman Taha Naskh';

  @override
  String get tafsirFontInterface => 'Interface font';

  @override
  String get tafsirTextSize => 'Text size';

  @override
  String get tafsirShown => 'Texts shown';

  @override
  String get tafsirNoneShown =>
      'All texts are hidden. Choose one in the tafsir settings.';

  @override
  String get tafsirFootnotes => 'Footnotes';

  @override
  String get previousVerse => 'Previous verse';

  @override
  String get nextVerse => 'Next verse';

  @override
  String sourceVersion(String version) {
    return 'Version $version';
  }

  @override
  String sourceRetrieved(String date) {
    return 'Copy of $date';
  }

  @override
  String get tafsirKashida => 'Kashida justification (trial)';

  @override
  String get tafsirKashidaHint =>
      'Justify tafsir lines by stretching letters instead of widening spaces. Quran words in brackets are never stretched, and copying gives the original text';

  @override
  String get copyText => 'Copy text';

  @override
  String get copied => 'Copied';

  @override
  String get listen => 'Listen';

  @override
  String get reciterLabel => 'Reciter';

  @override
  String get murattal => 'Murattal';

  @override
  String get mujawwad => 'Mujawwad';

  @override
  String get repeatLabel => 'Times to repeat';

  @override
  String get repeatForever => 'Until stopped';

  @override
  String repeatTimes(String n) {
    return '×$n';
  }

  @override
  String get silenceLabel =>
      'Silence between repeats (to recite after the reciter)';

  @override
  String get silenceNone => 'None';

  @override
  String seconds(String n) {
    return '$n s';
  }

  @override
  String get repeatVerse => 'Repeat this verse';

  @override
  String get playToEnd => 'Play to the end';

  @override
  String get sleepLabel => 'Sleep timer';

  @override
  String get sleepOff => 'Off';

  @override
  String minutes(String n) {
    return '$n min';
  }

  @override
  String get sleepSurahEnd => 'End of surah';

  @override
  String get followRecitation => 'Turn pages with the recitation';

  @override
  String get audioDownloads => 'Download recitations';

  @override
  String get downloadAll => 'Download all';

  @override
  String get audioDownloaded => 'On this device';

  @override
  String get noTiming =>
      'This recitation has no verse timing for this surah: it plays whole, without highlighting or verse repeat';

  @override
  String get playerError =>
      'The recitation could not play. Check the connection or download the surah.';

  @override
  String get playerSettings => 'Listening settings';

  @override
  String get stopListening => 'Stop listening';

  @override
  String repeatProgress(String done, String total) {
    return 'Repeat $done of $total';
  }

  @override
  String get audioCredit => 'Recitations and verse timings: mp3quran.net';

  @override
  String get touchReading => 'Touch reading';

  @override
  String get touchReadingOn => 'Touch reading: tap the verse you are reading';

  @override
  String get editionOnDevice => 'On this device';

  @override
  String editionNotDownloaded(String size) {
    return 'Not downloaded · $size MB';
  }

  @override
  String downloadAllEditions(String size) {
    return 'Download all editions ($size MB)';
  }

  @override
  String get allEditionsQueued =>
      'All editions are downloading. You can keep reading or leave the app.';

  @override
  String get downloadInBackgroundNote =>
      'You can leave the app: the download goes on in the background, and a notification tells you when it is done.';

  @override
  String get notifDownloading => 'Downloading mushaf pages';

  @override
  String get notifComplete => 'Mushaf download complete';

  @override
  String get notifFailed => 'Mushaf download failed';

  @override
  String get notifPaused => 'Download paused';

  @override
  String get readInMadinaWhileDownloading =>
      'Read the new Madina edition until the download finishes';

  @override
  String downloadingBanner(String name, String percent) {
    return 'Downloading $name: $percent%. Reading the new Madina edition meanwhile';
  }

  @override
  String get versePauseLabel => 'Pause between verses';

  @override
  String get versePauseAsRecorded => 'As recorded';

  @override
  String get versePauseSecond => '1 second';

  @override
  String get versePauseHalf => 'Half a second';

  @override
  String get versePauseHint =>
      'Shortens the long silences between verses without touching the recitation itself';

  @override
  String get homeTitle => 'Home';
}
