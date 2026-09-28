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
  String get defaultTag => 'Default';

  @override
  String pagesDownloadNote(String size) {
    return 'Mushaf pages download once (about $size MB), then work offline. You can read the continuous view right away.';
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
  String get readContinuousNow => 'Open the continuous view';

  @override
  String get readWhileDownloading => 'Read now while the download finishes';

  @override
  String get pagesCredit =>
      'Madina Mushaf pages by the King Fahd Glorious Quran Printing Complex.';

  @override
  String get pagesCreditOld =>
      'Old edition (1405H) pages by the King Fahd Glorious Quran Printing Complex, downloaded directly from quran.com.';

  @override
  String get editionLabel => 'Mushaf edition';

  @override
  String get viewPage => 'Page';

  @override
  String get viewContinuous => 'Continuous';

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
  String get quranFontSize => 'Quran text size in the continuous view';

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
}
