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
  String get settingsTitle => 'Settings';

  @override
  String get openSettings => 'Open settings';

  @override
  String get appearanceTitle => 'Mushaf look';

  @override
  String get modeLabel => 'Mode';

  @override
  String get modeSystem => 'Automatic';

  @override
  String get modeSystemHint => 'Follows the device setting';

  @override
  String get modeLight => 'Light';

  @override
  String get modeWhite => 'Bright white';

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
  String get crashConsentTitle => 'Help us improve Tibyan';

  @override
  String get crashConsentBody =>
      'If the app crashes, it can send us an anonymous technical report describing where it failed, the device model and the system version, so we can fix it quickly. The report never includes your name, email, IP address, or anything you read or record. Reports are kept only on Tibyan\'s own server, and you can change your choice any time in Settings.';

  @override
  String get crashConsentAgree => 'I agree';

  @override
  String get crashConsentDecline => 'No, thanks';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutBody =>
      'Tibyan is an app for reading and reflecting on the Quran, and its code is open. Every text in it comes from a verified source, shown next to it.';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

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
  String ayahCount(int n, String count) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$count verses',
      one: '$count verse',
    );
    return '$_temp0';
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
  String reviewNotesBody(int n, String count) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$count places',
      one: '$count place',
    );
    return '$_temp0 where the two text sources differ (two juz boundaries and four spellings) are with a qualified reviewer. The app follows the Tanzil text until a decision is made.';
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
  String get catchwordImageLabel => 'The first word of the next page';

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
  String versesCount(int n, String count) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$count verses',
      one: '$count verse',
    );
    return '$_temp0';
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
  String get markerTheme => 'Follows the theme';

  @override
  String get markerThemeHint =>
      '“Follows the theme” draws the theme\'s own marker; in Tibyan, its rosette.';

  @override
  String get themeLabel => 'Theme';

  @override
  String get markerTintLabel => 'Marker colour';

  @override
  String get markerTintNone => 'No colour';

  @override
  String get reciteMode => 'Recitation mode';

  @override
  String get autoScroll => 'Auto-scroll';

  @override
  String get resume => 'Resume';

  @override
  String get downloadsSectionMushaf => 'Mushafs';

  @override
  String get downloadsSectionRecitations => 'Recitations';

  @override
  String get downloadsSectionResources => 'Resources';

  @override
  String downloadsOnDevice(String size) {
    return 'On the device · $size MB';
  }

  @override
  String downloadsAvailable(String size) {
    return 'Available · $size MB';
  }

  @override
  String downloadsReciterOnDevice(String done, String total, String size) {
    return 'On the device: $done / $total · $size MB';
  }

  @override
  String get downloadsAvailableShort => 'Available';

  @override
  String get downloadsGoesOn => 'The download goes on in the background';

  @override
  String get pause => 'Pause';

  @override
  String get downloadsOpen => 'Downloads Center';

  @override
  String get downloadsOpenHint =>
      'Mushafs, recitations and resources: on the device, downloading and available';

  @override
  String get audioDownloadResume => 'Resume';

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
  String get multiSelectHint =>
      'Drag the handles, or turn the page and tap a verse to extend the selection to it';

  @override
  String get doneLabel => 'Done';

  @override
  String get markRemoved => 'Mark removed';

  @override
  String get shareAsMushafPages => 'The mushaf\'s own pages';

  @override
  String get shareAsMushafPagesHint =>
      'Each picture is a page of your mushaf as you read it, instead of the verses set again';

  @override
  String get shareBrandColours => 'Tibyan\'s original colours';

  @override
  String get shareBrandColoursHint =>
      'Instead of the current interface and mushaf colours';

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
  String get englishTafsirVisibilityLabel => 'English tafsir';

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
  String get sajdahTimer => 'Sajdah timer';

  @override
  String get sajdahTimerHint =>
      'At a verse of prostration the reciter pauses and a card with the supplications of prostration counts down, then the recitation goes on';

  @override
  String get sajdahTimerLength => 'Timer length';

  @override
  String get sajdahCardLabel => 'Prostration of recitation';

  @override
  String get sajdahTapToContinue => 'Tap to continue';

  @override
  String get sajdahContinue => 'Continue';

  @override
  String sajdahSecondsLeft(int seconds, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$n seconds left',
      one: '$n second left',
    );
    return '$_temp0';
  }

  @override
  String get tapJumpLabel => 'Tapping a verse while listening';

  @override
  String get tapJumpHint =>
      'A tap on a verse on the page moves the reciter there';

  @override
  String get tapJumpVerseStart => 'From the verse\'s start';

  @override
  String get tapJumpFromWord => 'From the word tapped';

  @override
  String get tapJumpNoTiming => 'This recitation can\'t jump to a verse';

  @override
  String get listenFromVerse => 'Listen from this verse';

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
  String get tafsirAudioListen => 'Listen to the tafsir';

  @override
  String get tafsirAudioListenSurah => 'Listen to the surah\'s tafsir';

  @override
  String get translationAudioAfterVerse => 'Translation audio after each verse';

  @override
  String get translationAudioHint =>
      'Each verse\'s translation is heard after it is recited, when verses play on without repeating';

  @override
  String clipTranslationOf(String ayah) {
    return 'Translation of verse $ayah';
  }

  @override
  String englishTafsirOffer(String title) {
    return 'Download the English tafsir: $title';
  }

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
    return 'Downloads Center ($size MB available)';
  }

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
  String get listenFromPage => 'Listen from the top of the page';

  @override
  String get repeatHint =>
      'With no stretch chosen, each verse repeats this many times before the next';

  @override
  String get homeTitle => 'Home';

  @override
  String get searchHint => 'Search the Quran, or type “2:255”';

  @override
  String get searchIntro =>
      'Type one or more words of the Quran, with or without diacritics, or a place such as “2:255” or “al-Baqara 255”.';

  @override
  String get searchGoTo => 'Go to this place';

  @override
  String get searchNothing => 'No results';

  @override
  String searchCount(int total, String count, int verseTotal, String verses) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$count matches',
      one: '$count match',
    );
    String _temp1 = intl.Intl.pluralLogic(
      verseTotal,
      locale: localeName,
      other: '$verses verses',
      one: '$verses verse',
    );
    return '$_temp0 in $_temp1';
  }

  @override
  String searchMore(int n, String count) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'and $count more verses',
      one: 'and $count more verse',
    );
    return '$_temp0; narrow the search to see them';
  }

  @override
  String get searchHistory => 'Recent searches';

  @override
  String get searchClearHistory => 'Clear';

  @override
  String get continueReading => 'Continue reading';

  @override
  String continueReadingAt(String surah, String ayah, String page) {
    return '$surah | verse $ayah · page $page';
  }

  @override
  String get openLabel => 'Open';

  @override
  String get wordStudy => 'Word study';

  @override
  String get wordMeanings => 'Word meanings';

  @override
  String get wordPickHint => 'Tap the word you want to study';

  @override
  String get wordStudyChoose => 'Choose one of the verse\'s words';

  @override
  String get wordMeaningTitle => 'Meaning';

  @override
  String get wordNoMeaning =>
      'Al-Muyassar fi Gharib al-Quran has no entry for this word.';

  @override
  String get wordRootTitle => 'Root';

  @override
  String get wordLemma => 'Lemma';

  @override
  String get wordNoRoot =>
      'The Quranic Arabic Corpus gives no root for this word.';

  @override
  String get wordNoCorpusData =>
      'The Quranic Arabic Corpus has no data for this word.';

  @override
  String get rootOccurrencesTitle => 'Where the root occurs';

  @override
  String rootOccurrencesCount(String words, String verses) {
    return 'Words: $words, verses: $verses';
  }

  @override
  String get verseNoMeanings =>
      'Al-Muyassar fi Gharib al-Quran has no entries for this verse.';

  @override
  String wordStudyVerse(String surah, String ayah) {
    return '$surah, verse $ayah';
  }

  @override
  String get downloadAllTitle => 'Downloads Center';

  @override
  String downloadAllCount(String done, String total) {
    return '$done of $total done';
  }

  @override
  String get themeArtCredit =>
      'Ornaments: quran-assets by Quran.ws, developed by Abdullah Ibeid (github.com/quran-ws/quran-assets). Those traced from mushafs are under CC BY-NC-SA 4.0; the designs belong to the King Fahd Complex and other publishers.';

  @override
  String get khatmaTitle => 'Khatma';

  @override
  String get khatmaPrimaryLabel => 'Primary khatma';

  @override
  String get khatmaOtherPlans => 'Other khatmas';

  @override
  String get khatmaSetPrimary => 'Set as primary';

  @override
  String get khatmaPause => 'Pause';

  @override
  String get khatmaResume => 'Resume';

  @override
  String get khatmaPaused => 'Paused';

  @override
  String get khatmaStepPlan => 'Plan';

  @override
  String get khatmaStepSchedule => 'Schedule';

  @override
  String get khatmaStepReview => 'Review';

  @override
  String khatmaLoadFailed(String error) {
    return 'Couldn\'t load khatma setup data: $error';
  }

  @override
  String khatmaCreateFailed(String error) {
    return 'Couldn\'t create the khatma: $error';
  }

  @override
  String get khatmaKindLabel => 'Plan type';

  @override
  String get khatmaSettings => 'Khatma settings';

  @override
  String get khatmaTabPlan => 'Plan';

  @override
  String get khatmaTabStats => 'Statistics';

  @override
  String get khatmaStatsPageEquivalents => 'Page equivalents';

  @override
  String get khatmaStatsSessions => 'Reading sessions';

  @override
  String get khatmaStatsMinutes => 'Reading minutes';

  @override
  String get khatmaStatsNoActivity =>
      'No khatma reading recorded in this period.';

  @override
  String get khatmaStatsWeek => 'Week';

  @override
  String get khatmaStatsMonth => 'Month';

  @override
  String get khatmaStatsYear => 'Year';

  @override
  String get khatmaStatsPreviousPeriod => 'Previous period';

  @override
  String get khatmaStatsNextPeriod => 'Next period';

  @override
  String khatmaReminderForPlan(String plan) {
    return 'Khatma: $plan';
  }

  @override
  String khatmaReminderMissedTitle(String plan) {
    return 'Still time for $plan';
  }

  @override
  String khatmaReminderMissedBody(String from, String to) {
    return 'Today\'s portion: pages $from to $to.';
  }

  @override
  String khatmaReminderRecoveryTitle(String plan) {
    return 'A catch-up plan for $plan';
  }

  @override
  String khatmaReminderRecoveryBody(String from, String to) {
    return 'Today\'s portion is pages $from to $to. Open the plan to review gentle catch-up options.';
  }

  @override
  String khatmaReminderTargetTitle(String plan) {
    return 'One day until $plan is due';
  }

  @override
  String get khatmaReminderTargetBody =>
      'Review your progress and plan before the target date.';

  @override
  String khatmaReminderCompletedTitle(String plan) {
    return 'Khatma completed: $plan';
  }

  @override
  String get khatmaReminderCompletedBody =>
      'You completed the khatma. May Allah accept it from you.';

  @override
  String get khatmaReminderPlanLimit =>
      'Reminders can be enabled for up to 20 open khatmas.';

  @override
  String get khatmaSaveSettings => 'Save settings';

  @override
  String khatmaSaveFailed(String error) {
    return 'Couldn\'t save khatma settings: $error';
  }

  @override
  String get khatmaAutoRestart => 'Start this plan again when it finishes';

  @override
  String get khatmaReplan => 'Adjust the plan';

  @override
  String get khatmaCatchUpToday => 'Finish the missed portion today';

  @override
  String get khatmaCatchUpGradually => 'Catch up gradually';

  @override
  String get khatmaCompletionBody =>
      'You completed this khatma. May Allah accept it from you.';

  @override
  String get khatmaReusePlan => 'Use this plan again';

  @override
  String get khatmaKindFull => 'Full Quran';

  @override
  String get khatmaKindPartial => 'Selected range';

  @override
  String get khatmaKindDaily => 'Daily wird';

  @override
  String get khatmaKindCustom => 'Custom range';

  @override
  String get khatmaPresetLabel => 'Template';

  @override
  String get khatmaPresetCustom => 'Custom plan';

  @override
  String get khatmaPresetMonth => 'One month';

  @override
  String khatmaPresetRamadan30(int n, String days) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$days days',
      one: '$days day',
    );
    return 'Ramadan: $_temp0';
  }

  @override
  String get khatmaPresetRamadanTwice => 'Two khatmas in Ramadan';

  @override
  String get khatmaPresetBeforeLastTen => 'Before the last ten nights';

  @override
  String get khatmaPresetWeekly => 'One week';

  @override
  String get khatmaPresetDailyJuz => 'A juz a day';

  @override
  String get khatmaFromSurah => 'From surah';

  @override
  String get khatmaToSurah => 'To surah';

  @override
  String get khatmaFromAyah => 'From verse';

  @override
  String get khatmaToAyah => 'To verse';

  @override
  String get khatmaRangeError => 'Choose a start verse before the end verse.';

  @override
  String get khatmaScheduleMode => 'Schedule';

  @override
  String get khatmaScheduleAdaptive => 'Adaptive';

  @override
  String get khatmaScheduleFixed => 'Fixed';

  @override
  String get khatmaRestDays => 'Rest days (optional)';

  @override
  String get khatmaAtLeastOneReadingDay =>
      'Keep at least one reading day each week.';

  @override
  String get khatmaCountingMode => 'How reading counts';

  @override
  String get khatmaCountWirdConfirm => 'Confirm Wird (Recommended)';

  @override
  String get khatmaCountWirdConfirmSubtitle =>
      'Today\'s wird counts only once you confirm you finished it';

  @override
  String get wirdConfirmDone => 'Confirm wird completion';

  @override
  String get wirdCompletedCelebration =>
      'Congratulations! Today\'s wird is marked complete';

  @override
  String get wirdEndOfPortion => 'End of today\'s wird reached';

  @override
  String get wirdEndOfPortionQuestion => 'Have you completed today\'s wird?';

  @override
  String get wirdCompletedToday => 'Today\'s wird completed';

  @override
  String get wirdLater => 'Later';

  @override
  String get khatmaCountAuto => 'Count automatically';

  @override
  String get khatmaCountAsk => 'Ask each time';

  @override
  String get khatmaCountManual => 'Only when I mark it';

  @override
  String get khatmaMakePrimary => 'Make this the primary khatma';

  @override
  String get khatmaUnitRub => 'Quarter hizb';

  @override
  String khatmaReviewRange(String from, String to) {
    return 'Range: $from–$to';
  }

  @override
  String get khatmaNew => 'New khatma';

  @override
  String get khatmaEmptyTitle => 'No khatma yet';

  @override
  String get khatmaEmptyBody =>
      'Plan a full reading of the mushaf: choose an end date or a daily amount. Pages you read in the mushaf are counted automatically.';

  @override
  String get khatmaDefaultName => 'My khatma';

  @override
  String get khatmaNameLabel => 'Name';

  @override
  String get khatmaByDate => 'By end date';

  @override
  String get khatmaByAmount => 'By daily amount';

  @override
  String get khatmaEndDateLabel => 'End date';

  @override
  String get khatmaAmountLabel => 'Amount a day';

  @override
  String get khatmaUnitPage => 'Pages';

  @override
  String get khatmaUnitJuz => 'Juz';

  @override
  String get khatmaUnitHizb => 'Hizb';

  @override
  String khatmaAboutPerDay(int n, String count) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$count pages',
      one: '$count page',
    );
    return 'About $_temp0 a day';
  }

  @override
  String khatmaDuration(int n, String count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0, finishing on $date';
  }

  @override
  String khatmaEditionNote(String edition) {
    return 'In the pages of $edition';
  }

  @override
  String get khatmaReminder => 'Daily reminder';

  @override
  String get khatmaReminderOff => 'No reminder';

  @override
  String get khatmaStart => 'Start the khatma';

  @override
  String get khatmaReplaceTitle => 'A khatma is open';

  @override
  String get khatmaReplaceBody =>
      'The current khatma and its log are removed when a new one starts.';

  @override
  String get khatmaToday => 'Today\'s portion';

  @override
  String khatmaPagesRange(String from, String to) {
    return 'Pages $from to $to';
  }

  @override
  String khatmaPagesCount(String count) {
    return '$count pages';
  }

  @override
  String get khatmaReadNow => 'Read now';

  @override
  String get khatmaMarkRead => 'I read it elsewhere';

  @override
  String get khatmaTodayDone => 'Today\'s portion is read';

  @override
  String get khatmaContinue => 'Keep reading';

  @override
  String khatmaProgress(String done, int n, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$total pages',
      one: '$total page',
    );
    return '$done of $_temp0';
  }

  @override
  String khatmaDaysLeft(String count) {
    return 'Days left: $count';
  }

  @override
  String khatmaEnds(String date) {
    return 'Ends on $date';
  }

  @override
  String khatmaBehindTitle(String count) {
    return 'Pages from earlier days: $count';
  }

  @override
  String get khatmaBehindBody =>
      'They join today\'s portion. Choose whether to finish them today, catch up gradually, spread the remaining amount, or move the end date.';

  @override
  String get khatmaSpread => 'Spread over the days left';

  @override
  String get khatmaExtend => 'Move the end date';

  @override
  String get khatmaComplete => 'Khatma complete';

  @override
  String khatmaCompletedOn(String date) {
    return 'Completed on $date';
  }

  @override
  String get khatmaPast => 'Past khatmas';

  @override
  String get khatmaDelete => 'Delete the khatma';

  @override
  String get khatmaDeleteBody => 'This khatma\'s log is removed.';

  @override
  String get khatmaTileStart => 'Start';

  @override
  String khatmaTilePages(String count) {
    return 'Today: $count';
  }

  @override
  String get khatmaReminderTitle => 'Khatma portion';

  @override
  String khatmaReminderBody(String from, String to) {
    return 'Today: pages $from to $to';
  }

  @override
  String get khatmaReminderChannel => 'Khatma reminders';

  @override
  String get homeTodayTitle => 'Today';

  @override
  String get widgetNoKhatma => 'Start a khatma in Tibyan';

  @override
  String get reportsTitle => 'Reading reports';

  @override
  String get reportsWeek => 'Last 7 days';

  @override
  String get reportsMonth => 'Last 30 days';

  @override
  String get reportsDays => 'Reading days';

  @override
  String get reportsPages => 'Pages';

  @override
  String get reportsReadingMinutes => 'Reading minutes';

  @override
  String get reportsListeningMinutes => 'Listening minutes';

  @override
  String get reportsEmpty =>
      'Your reading and listening appear here automatically.';

  @override
  String get reportsDayRead => 'A day with reading or listening';

  @override
  String get streakReadToday => 'You read today.';

  @override
  String get streakWelcome => 'Welcome back. Pick up where you left off.';

  @override
  String readDaysOfLast(String read, int n, String days) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$days days',
      one: 'day',
    );
    return 'You read on $read of the last $_temp0';
  }

  @override
  String get streakNotesToggle => 'Gentle notes';

  @override
  String get streakNotesHint =>
      'Calm notes on your reading; they never count days in a row or show missed days.';

  @override
  String get journalTitle => 'Tadabbur journal';

  @override
  String get journalSearch => 'Search your notes';

  @override
  String get journalEmpty =>
      'No notes yet. Long-press a verse in the mushaf and choose “Reflection note”.';

  @override
  String get journalNoMatch => 'No notes contain these words.';

  @override
  String get journalAdd => 'Reflection note';

  @override
  String get journalHint => 'Write your note on the verse';

  @override
  String get journalEdit => 'Edit';

  @override
  String get journalOpenVerse => 'Open the verse';

  @override
  String journalVerseRef(String surah, String ayah) {
    return '$surah | verse $ayah';
  }

  @override
  String get journalSaved => 'Note saved';

  @override
  String get journalEarlier => 'Your notes on this verse';

  @override
  String get elderlyMode => 'Elderly mode';

  @override
  String get elderlyModeHint =>
      'Larger text, larger buttons with their names, clearer colours, a home with only the essentials, the mushaf page as large as possible, and calmer transitions';

  @override
  String get searchModeWords => 'By words';

  @override
  String get searchModeMeaning => 'By meaning';

  @override
  String get searchMeaningHint => 'Describe an idea in your own words';

  @override
  String get searchMeaningIntro =>
      'Describe an idea in your own words, in Arabic or English, such as “patience in hardship” or “kindness to parents”, and the verses whose meaning in al-Tafsir al-Muyassar and the translations is closest appear. Each verse is shown with its text, and the text that matched exactly as its source has it.';

  @override
  String searchMatchedIn(String source) {
    return 'Matched in: $source';
  }

  @override
  String searchMeaningCount(int n, String count) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$count verses',
      one: '$count verse',
    );
    return '$_temp0';
  }

  @override
  String get semanticPackName => 'Search-by-meaning pack';

  @override
  String semanticPackOffer(String size) {
    return 'This searches the words of the meaning texts for now. Download the search-by-meaning pack (about $size MB) to find verses by their meaning even in other words, offline.';
  }

  @override
  String get semanticPackDownload => 'Download the pack';

  @override
  String semanticPackDownloading(String percent) {
    return 'Downloading: $percent%';
  }

  @override
  String get semanticPackVerifying => 'Checking and installing the pack…';

  @override
  String get semanticPackFailed => 'The download failed. Please try again.';

  @override
  String get semanticPackLoading => 'Preparing search by meaning…';

  @override
  String get semanticPackError =>
      'The search-by-meaning pack could not be opened; searching by words instead.';

  @override
  String get semanticResultsNote =>
      'Approximate results, closest meaning first. Read each verse in its place and in its tafsir.';

  @override
  String verseLabel(String surah, String ayah) {
    return 'Surah $surah, verse $ayah';
  }

  @override
  String pageLabelFull(String page, String surah) {
    return 'Page $page, $surah';
  }

  @override
  String get markThisVerse => 'Set or remove the reading mark at this verse';

  @override
  String loadingPage(String page) {
    return 'Loading page $page';
  }

  @override
  String get clearSearch => 'Clear the search';

  @override
  String get previousPageNumber => 'Previous page';

  @override
  String get nextPageNumber => 'Next page';

  @override
  String get showMenus => 'Show the menus';

  @override
  String get hideMenus => 'Hide the menus';

  @override
  String downloadSurah(String surah) {
    return 'Download surah $surah';
  }

  @override
  String retryDownloadSurah(String surah) {
    return 'Retry downloading surah $surah';
  }

  @override
  String deleteSurahDownload(String surah) {
    return 'Surah $surah is downloaded. Delete it';
  }

  @override
  String deleteSurahDownloadTitle(String surah) {
    return 'Delete the download of surah $surah?';
  }

  @override
  String get deleteSurahDownloadBody =>
      'The downloaded recitation of this surah will be removed from this device. You can download it again any time.';

  @override
  String downloadingSurah(String surah) {
    return 'Downloading surah $surah';
  }

  @override
  String verseCounter(String current, String total) {
    return 'Verse $current of $total';
  }

  @override
  String downloadPercentSpoken(String percent) {
    return '$percent% downloaded';
  }

  @override
  String get hifzTitle => 'Memorization';

  @override
  String get hifzTileNote => 'Review and recite';

  @override
  String get hifzToday => 'Today\'s review';

  @override
  String get hifzNothingDue => 'Nothing is due today.';

  @override
  String get hifzNothingDueHint =>
      'Recite a page, a quarter or a surah and grade it; it then joins spaced review.';

  @override
  String get hifzStartTest => 'Start a test';

  @override
  String get hifzMap => 'Hifz map';

  @override
  String get hifzMapHint =>
      'Each page is coloured by how firmly it is memorized, with a mark that reads without colour.';

  @override
  String get hifzAllUnits => 'All review units';

  @override
  String get hifzDueToday => 'Due today';

  @override
  String hifzDueOn(String date) {
    return 'Due $date';
  }

  @override
  String hifzQuarter(String number) {
    return 'Quarter $number';
  }

  @override
  String get hifzUnitPage => 'Page';

  @override
  String get hifzUnitQuarter => 'Quarter';

  @override
  String get hifzUnitSurah => 'Surah';

  @override
  String get hifzChooseUnit => 'What will you recite?';

  @override
  String hifzNumberRange(String max) {
    return 'Number, 1 to $max';
  }

  @override
  String get hifzBegin => 'Begin';

  @override
  String get hifzRemove => 'Remove from review';

  @override
  String get revealNextWord => 'Next word';

  @override
  String get revealNextVerse => 'Next verse';

  @override
  String get revealAll => 'All';

  @override
  String get endRecite => 'End the test';

  @override
  String get verseRemembered => 'Remembered';

  @override
  String get verseMissed => 'Missed';

  @override
  String testCounts(String remembered, String missed) {
    return 'Remembered $remembered · Missed $missed';
  }

  @override
  String get revealByLine =>
      'This edition has no word positions for this verse, so it is revealed line by line.';

  @override
  String get gradeUnit => 'Grade';

  @override
  String get gradeTitle => 'How did it go?';

  @override
  String get gradeSuggested => 'Suggested from the verse results';

  @override
  String get gradeAgain => 'Again';

  @override
  String get gradeHard => 'Hard';

  @override
  String get gradeGood => 'Good';

  @override
  String get gradeEasy => 'Easy';

  @override
  String gradeSaved(String date) {
    return 'Next review: $date';
  }

  @override
  String get similarVerses => 'Similar verses';

  @override
  String similarCount(String count) {
    return 'Similar ($count)';
  }

  @override
  String get similarThisVerse => 'This verse';

  @override
  String get similarFollowing => 'and the verse after it';

  @override
  String get strengthNone => 'Not memorized';

  @override
  String get strengthWeak => 'Weak';

  @override
  String get strengthFair => 'Fair';

  @override
  String get strengthGood => 'Good';

  @override
  String get strengthStrong => 'Strong';

  @override
  String get mapPages => 'Pages';

  @override
  String get mapSurahs => 'Surahs';

  @override
  String get mapZoomIn => 'Zoom in';

  @override
  String get mapZoomOut => 'Zoom out';

  @override
  String mapCell(String name, String strength) {
    return '$name: $strength';
  }

  @override
  String get tajweedColors => 'Tajweed colours';

  @override
  String get tajweedColorsHint =>
      'Colours only the letters a rule applies to, in the colours you choose';

  @override
  String get tajweedLegend => 'Tajweed colour key';

  @override
  String get tajweedRuleColors => 'Colour of each rule';

  @override
  String get tajweedNoColor => 'No colour';

  @override
  String get tajweedReset => 'Restore the default colours';

  @override
  String tajweedPickColor(String rule) {
    return 'Colour of “$rule”';
  }

  @override
  String get tajweedSourceNote =>
      'Where each rule applies comes from the quran-tajweed data (Collin Fair, CC BY 4.0). It is machine-generated and not yet reviewed by a qualified reader. A letter’s place inside its word is estimated, and in the Shamarly edition some word bounds are estimated too.';

  @override
  String get tajweedLegendHint =>
      'Long-press the colouring button on the page to show this key.';

  @override
  String get tajweedHueCrimson => 'Dark red';

  @override
  String get tajweedHueRed => 'Red';

  @override
  String get tajweedHueOrange => 'Orange';

  @override
  String get tajweedHueGold => 'Gold';

  @override
  String get tajweedHueGreen => 'Green';

  @override
  String get tajweedHueLightGreen => 'Light green';

  @override
  String get tajweedHueTeal => 'Teal';

  @override
  String get tajweedHueBlue => 'Blue';

  @override
  String get tajweedHuePurple => 'Purple';

  @override
  String get tajweedHuePink => 'Pink';

  @override
  String get tajweedHueGrey => 'Grey';

  @override
  String get tajweedHueViolet => 'Violet';

  @override
  String get tajweedHueAmber => 'Amber';

  @override
  String get tajweedNoDataRiwaya =>
      'No tajweed colouring in the riwaya mushafs (Warsh, Qalun, al-Duri, Shu‘bah): there is no reliable rule data for these riwayat yet, and we add no rule without a source. The colouring works in the Hafs mushafs.';

  @override
  String get tajweedHamzatWasl => 'Hamzat al-Wasl';

  @override
  String get tajweedLamShamsiyyah => 'Lam al-Shamsiyyah';

  @override
  String get tajweedSilent => 'Silent';

  @override
  String get tajweedMadd2 => 'Madd, regular (2 harakat)';

  @override
  String get tajweedMadd246 => 'Madd al-Aarid / al-Leen (2, 4, 6 harakat)';

  @override
  String get tajweedMaddMuttasil => 'Madd al-Muttasil (4, 5 harakat)';

  @override
  String get tajweedMaddMunfasil => 'Madd al-Munfasil (4, 5 harakat)';

  @override
  String get tajweedMadd6 => 'Madd Laazim (6 harakat)';

  @override
  String get tajweedGhunnah => 'Ghunnah';

  @override
  String get tajweedIkhfa => 'Ikhfa';

  @override
  String get tajweedIkhfaShafawi => 'Ikhfa Shafawi';

  @override
  String get tajweedIqlab => 'Iqlab';

  @override
  String get tajweedIdghaamGhunnah => 'Idghaam with Ghunnah';

  @override
  String get tajweedIdghaamNoGhunnah => 'Idghaam without Ghunnah';

  @override
  String get tajweedIdghaamShafawi => 'Idghaam Shafawi';

  @override
  String get tajweedIdghaamMutajanisayn => 'Idghaam Mutajaanisain';

  @override
  String get tajweedIdghaamMutaqaribayn => 'Idghaam Mutaqaaribain';

  @override
  String get tajweedQalqalah => 'Qalqalah';

  @override
  String get editionWarsh => 'Madina Mushaf: Warsh from Nafi';

  @override
  String get editionQalun => 'Madina Mushaf: Qalun from Nafi';

  @override
  String get editionDouri => 'Madina Mushaf: al-Duri from Abu Amr';

  @override
  String get editionShubah => 'Madina Mushaf: Shu\'bah from Asim';

  @override
  String get riwayaWarsh => 'Warsh from Nafi';

  @override
  String get riwayaQalun => 'Qalun from Nafi';

  @override
  String get riwayaDouri => 'al-Duri from Abu Amr';

  @override
  String get riwayaShubah => 'Shu\'bah from Asim';

  @override
  String get riwayatTitle => 'Other riwayat';

  @override
  String get riwayaEditionDesc =>
      'The King Fahd Complex\'s Madina mushaf in this riwaya, with its own verse count and numbers. Tafsir, translation and bookmarks link to the matching verses in Hafs\'s count.';

  @override
  String get riwayaGaps =>
      'In the riwaya editions: no word highlighting while listening (their recitations are timed by verse only), and no hizb or quarter in the frame (the page carries its own printed signs).';

  @override
  String get riwayaNoWordBoxes =>
      'This riwaya\'s downloaded pages carry no word boxes, so the divine names are not coloured and words cannot be picked. The newer page pack carries them.';

  @override
  String get riwayaWordNoStudy =>
      'No word study for this word here: word study is built on the words of Hafs, and opens for a riwaya\'s word only when it is the same word, letter for letter, in the same verse of Hafs.';

  @override
  String riwayaTafsirNote(
    String ayah,
    String surah,
    String riwaya,
    String hafs,
  ) {
    return 'Verse $ayah of surah $surah in $riwaya matches, in the count of Hafs: $hafs. The tafsir, translation and verse text below follow Hafs.';
  }

  @override
  String get riwayaNoHafs => 'no verse in the count of Hafs';

  @override
  String hafsVerseOne(String number) {
    return 'verse $number';
  }

  @override
  String hafsVerseRange(String from, String to) {
    return 'verses $from to $to';
  }

  @override
  String riwayaVerseText(String riwaya) {
    return 'The verse in $riwaya';
  }

  @override
  String riwayaRecitersNote(String riwaya) {
    return 'Recitations in $riwaya';
  }

  @override
  String get reciterPhotosTitle => 'Reciter photos';

  @override
  String get reciterPhotosNote =>
      'From Wikimedia Commons, resized and cropped by Tibyan.';

  @override
  String reciterPhotoCredit(String author, String license) {
    return '$author, $license';
  }

  @override
  String get unknownAuthor => 'Unknown author';

  @override
  String get reciterPhotoWithPermission => 'Creative Commons–licensed photos';

  @override
  String get otherRiwayaReciters => 'Reciters of other riwayat';

  @override
  String get otherRiwayaHint =>
      'Chosen from the mushaf of their riwaya, whose verses are numbered differently.';

  @override
  String reciterOfRiwaya(String riwaya) {
    return 'Riwaya of $riwaya';
  }

  @override
  String get copyVerses => 'Copy';

  @override
  String get shareVerseText => 'Share as text';

  @override
  String get shareVerseImage => 'Share as image';

  @override
  String get sharePreparing => 'Preparing the image…';

  @override
  String get shareImageFailed => 'Could not prepare the image';

  @override
  String get shareSurahImage => 'Share the surah as images';

  @override
  String get shareImageTitle => 'Share as image';

  @override
  String shareImageOf(String n, String total) {
    return '$n of $total';
  }

  @override
  String get sharePreviousImage => 'Previous picture';

  @override
  String get shareNextImage => 'Next picture';

  @override
  String get shareButton => 'Share';

  @override
  String get saveToPhotos => 'Save to Photos';

  @override
  String get savedToPhotos => 'Saved to Photos';

  @override
  String savedToFolder(String folder) {
    return 'Saved in $folder';
  }

  @override
  String get saveToPhotosFailed => 'Could not save to Photos';

  @override
  String get shareImageRiwayaUnavailable =>
      'This riwaya\'s text and font are not on this device yet, so its verses cannot be shared as images. Download its pages first.';

  @override
  String get backupTitle => 'Backup';

  @override
  String get backupExport => 'Save a backup';

  @override
  String get backupExportHint =>
      'One file with your bookmarks, marks, reading position, khatma, reports, tadabbur notes and hifz progress, and your settings. Keep it, or send it to yourself.';

  @override
  String get backupImport => 'Restore from a backup';

  @override
  String get backupImportHint =>
      'Merges the backup with what is on this device: nothing is deleted, the newer copy wins where they differ, and the settings come back as they were in the backup.';

  @override
  String backupDone(String added, String updated) {
    return 'Restored: $added new, $updated updated';
  }

  @override
  String get backupInvalid => 'This file is not a Tibyan backup';

  @override
  String get backupFailed => 'That did not work';

  @override
  String get playbackSpeedLabel => 'Recitation speed';

  @override
  String playbackSpeedValue(String value) {
    return '×$value';
  }

  @override
  String get storageTitle => 'Storage and downloads';

  @override
  String get storageOpen => 'Storage and downloads';

  @override
  String get storageOpenHint =>
      'What is downloaded on this device and how big it is; delete what you do not need';

  @override
  String get storageIntro =>
      'Everything the app downloaded to this device. You can delete any of it and download it again later. Your own data (bookmarks, khatma, notes) is not listed here and is never touched.';

  @override
  String storageTotal(String size) {
    return 'Total: $size';
  }

  @override
  String get storageBundled => 'Comes with the app';

  @override
  String storageSize(String mb) {
    return '$mb MB';
  }

  @override
  String storageAudioOf(String name) {
    return '$name\'s recitations';
  }

  @override
  String get storageSemantic => 'Search-by-meaning pack';

  @override
  String get storageTiming => 'Recitation timing updates';

  @override
  String get storagePartial => 'Unfinished downloads';

  @override
  String get storagePartialHint =>
      'What is left of downloads that stopped; safe to delete';

  @override
  String get storageClean => 'Clean up';

  @override
  String storageDeleteAsk(String name, String size) {
    return 'Delete $name ($size)?';
  }

  @override
  String storageFreed(String size) {
    return 'Freed $size';
  }

  @override
  String get storageEmpty =>
      'Nothing is downloaded beyond what comes with the app';

  @override
  String get storageUnknown => 'Other files';

  @override
  String get asbabTitle => 'Occasions of revelation';

  @override
  String asbabCount(String count) {
    return 'Occasions of revelation ($count)';
  }

  @override
  String bookCitationTahqiq(String name) {
    return 'ed. $name';
  }

  @override
  String bookCitationVolume(String volume) {
    return 'vol. $volume';
  }

  @override
  String bookCitationPage(String page) {
    return 'p. $page';
  }

  @override
  String bookCitationPages(String from, String to) {
    return 'pp. $from–$to';
  }

  @override
  String storageBook(String title) {
    return 'Book: $title';
  }

  @override
  String get storageBooksAvailable => 'Books you can download';

  @override
  String get bookPackDownload => 'Download';

  @override
  String get munasabatTitle => 'Connections between verses';

  @override
  String munasabatCount(String count) {
    return 'Connections between verses ($count)';
  }

  @override
  String get wujuhTitle => 'Senses of the word in the Quran';

  @override
  String get bookKindTafsir => 'Tafsir';

  @override
  String bookEntryVerses(String from, String to) {
    return 'Verses $from–$to';
  }

  @override
  String get continuousView => 'Continuous view';

  @override
  String get underVerseTitle => 'Under each verse';

  @override
  String get underArabicOnly => 'Arabic only';

  @override
  String get underTranslation => 'Arabic with a translation';

  @override
  String get underTranslationHint => 'Choose one or two';

  @override
  String get underMuyassar => 'Arabic with al-Tafsir al-Muyassar';

  @override
  String get splitTranslationLabel => 'Beside the page on wide screens';

  @override
  String get splitTranslationHint =>
      'The page as printed, with your choice for its verses beside it';

  @override
  String get nextSurah => 'Next surah';

  @override
  String get previousSurah => 'Previous surah';

  @override
  String get hafsTextNote => 'The text here is in the Hafs riwaya';

  @override
  String get twoPageSpread => 'Two facing pages';

  @override
  String get twoPageSpreadHint =>
      'On wide screens held sideways, like an open mushaf';

  @override
  String get landscapeFitLabel => 'Page in landscape';

  @override
  String get landscapeFitWidth => 'Fit to width';

  @override
  String get landscapeFitWidthHint =>
      'The page as wide as the screen, read by scrolling down';

  @override
  String get landscapeFitPage => 'Whole page';

  @override
  String get landscapeFitPageHint =>
      'The whole page fitted to the screen height';

  @override
  String get oneVerse => 'Verse by verse';

  @override
  String get oneVerseHint =>
      'One verse a screen in large print, the phone sideways';

  @override
  String get oneVerseAutoOff => 'Auto-turn is off. Tap to turn it on';

  @override
  String oneVerseAutoOn(int n, String seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$seconds seconds',
      one: 'second',
    );
    return 'Turns to the next verse every $_temp0. Tap to change';
  }

  @override
  String get oneVerseAutoShort => 'Auto';

  @override
  String secondsShort(String n) {
    return '$n s';
  }

  @override
  String get searchScopeAll => 'The whole mushaf';

  @override
  String get searchScopeJuz => 'In a juz';

  @override
  String get searchScopeSurah => 'In a surah';

  @override
  String get whatsNewTitle => 'What\'s new';

  @override
  String get whatsNewDone => 'OK';

  @override
  String get newOneVerse => 'Verse by verse';

  @override
  String get newOneVerseBody =>
      'A button under the page turns the phone sideways and shows one verse in large print, with an optional auto-turn.';

  @override
  String get newUnderVerse => 'Translation under the verse';

  @override
  String get newUnderVerseBody =>
      'The continuous view, from the page\'s tools: one or two translations, or al-Muyassar, under each verse.';

  @override
  String get newShare => 'Copy and share';

  @override
  String get newShareBody =>
      'Copy a verse, or share it as text or as a picture in Tibyan\'s design, even over a page break. Long-press the surah\'s name above the page to share the whole surah as pictures.';

  @override
  String get newSpread => 'Two facing pages';

  @override
  String get newSpreadBody =>
      'On a tablet or a wide screen held sideways, the mushaf opens like a printed copy.';

  @override
  String get newWidgets => 'Widgets';

  @override
  String get newWidgetsBody =>
      'Today\'s khatma portion and reading shortcuts on the home screen, and a Listen tile in Quick Settings.';

  @override
  String get newBackup => 'Backup';

  @override
  String get newBackupBody =>
      'Save your bookmarks, khatma, notes and settings in one file, and restore them on any device.';

  @override
  String get carContinue => 'Continue where you stopped reading';

  @override
  String get carReciters => 'Reciters';

  @override
  String get pagesMapCurrent => 'Current page';

  @override
  String get pagesMapRead => 'Read in the khatma';

  @override
  String get pagesMapMarked => 'Has a bookmark';

  @override
  String pagesRange(String first, String last) {
    return 'p. $first–$last';
  }

  @override
  String pagesMapJuzRead(String read, String total) {
    return '$read of $total read';
  }

  @override
  String get focusModeTitle => 'Focus mode';

  @override
  String get focusModeHint =>
      'The page alone, with no frame and nothing under it, and a thin bar at the top';

  @override
  String get focusToolsLabel => 'Showing the tools';

  @override
  String get focusToolsButton => 'Simple buttons';

  @override
  String get focusToolsButtonHint => 'Three small buttons in the top bar';

  @override
  String get focusToolsMenu => 'Menu';

  @override
  String get focusToolsMenuHint =>
      'A long press on the page opens a window with every tool';

  @override
  String get pageTurnLabel => 'Page turn effect';

  @override
  String get pageTurnNormal => 'Normal';

  @override
  String get pageTurnNormalHint => 'The page slides aside';

  @override
  String get pageTurnCurl => '3D page flip';

  @override
  String get pageTurnCurlHint => 'The page turns over like paper';

  @override
  String get pageTurnBend => 'Paper curl';

  @override
  String get pageTurnBendHint =>
      'The page curls round with your finger like paper, its back showing';

  @override
  String get pageTurnFold => 'Light curl';

  @override
  String get pageTurnFoldHint =>
      'The page\'s edge folds back with your finger, lighter on the device';

  @override
  String get pageTurnFade => 'Fade';

  @override
  String get pageTurnFadeHint => 'The next page fades in over the last';

  @override
  String get pageFillLabel => 'Filling the screen';

  @override
  String get pageFillLines => 'Spread the lines';

  @override
  String get pageFillLinesHint =>
      'Each line as wide as the screen, the lines spread over its height';

  @override
  String get pageFillStretch => 'Spread + slight stretch';

  @override
  String get pageFillStretchHint =>
      'Plus up to 12% wider where the page fills the height';

  @override
  String get pageFillFull => 'Full stretch';

  @override
  String get pageFillFullHint =>
      'The page fills the screen both ways, which changes the letters\' shape';

  @override
  String get playerStyleLabel => 'Player style';

  @override
  String get playerStyleAuto => 'Automatic';

  @override
  String get playerStyleAutoHint =>
      'The normal player when reading, the focus player in focus mode';

  @override
  String get playerStyleNormal => 'Normal';

  @override
  String get playerStylePill => 'Focus';

  @override
  String get playerStylePillHint =>
      'Small and see-through, with play, settings and close';

  @override
  String get playerStyleButton => 'Single button';

  @override
  String get playerStyleButtonHint =>
      'A small button: tap to play or pause, long press for the menu';

  @override
  String get focusExit => 'Exit focus';

  @override
  String get focusTools => 'Tools';

  @override
  String get focusShowTools => 'Show the tools';

  @override
  String get focusHideTools => 'Hide the tools';

  @override
  String get focusMenus => 'Menus';

  @override
  String get focusPageTools => 'Page tools';

  @override
  String get playerFull => 'Full player';

  @override
  String get tajweedMarksSubtitle => 'Tajweed rules: colours and places';

  @override
  String get tajweedMarksHint =>
      'Each rule in the colour the mushaf pages give it, and every place it falls in the mushaf. Tap a rule to see its places, and a place to open its page.';

  @override
  String tajweedRuleCount(String verses, String letters) {
    return 'Verses: $verses · Coloured letters: $letters';
  }

  @override
  String tajweedPlaceAt(String surah, String ayah, String page) {
    return '$surah $ayah · page $page';
  }

  @override
  String get tajweedIndexColorNote =>
      'Colours as the pages draw them now: your choice, or the default. Change them in Mushaf look.';

  @override
  String get tajweedIndexLoadError =>
      'The places of this rule could not be read.';

  @override
  String get tajweedMarksInkNote =>
      'Where a rule falls on a mark alone (like the small meem), the mark stays in the text colour here: the font cannot colour a mark without part of its letter. The mushaf page shows it in colour.';

  @override
  String get assistantTitle => 'Assistant';

  @override
  String get assistantIntro => 'Help with using the app and the mushaf';

  @override
  String get tajweedMarksTitle => 'Tajweed marks';

  @override
  String get moreLabel => 'More';

  @override
  String wirdIndicator(String read, String total) {
    return 'Today\'s portion: $read of $total';
  }

  @override
  String get khatmaContinueMine => 'Continue my khatma';

  @override
  String askCreditLine(String plan) {
    return 'Your last reading is part of “$plan”. Count it?';
  }

  @override
  String get askCreditCount => 'Count it';

  @override
  String get askCreditNo => 'No';

  @override
  String get khatmaPendingTitle => 'Readings waiting to be counted';

  @override
  String khatmaPendingOn(String date) {
    return 'Reading on $date';
  }

  @override
  String get tasmeeTileLabel => 'Recitation';

  @override
  String get tasmeeTitle => 'Recitation practice';

  @override
  String get tasmeeDescription =>
      'Recite from memory. Tibyan listens on this device, reveals words, and marks possible mistakes. Audio is not sent anywhere; tajweed is not graded.';

  @override
  String get tasmeeSelectRange => 'Choose a practice range';

  @override
  String get tasmeeSurah => 'Surah';

  @override
  String get tasmeeJuz => 'Juz';

  @override
  String get tasmeeHizb => 'Hizb';

  @override
  String get tasmeeFirstHalf => 'First';

  @override
  String get tasmeeSecondHalf => 'Second';

  @override
  String get tasmeeFromSecondQuarter => 'Start from the second quarter';

  @override
  String get tasmeeMode => 'Practice mode';

  @override
  String get tasmeeContinuous => 'Continuous';

  @override
  String get tasmeeVerseByVerse => 'Verse by verse';

  @override
  String get tasmeeInvalidRange => 'Check the selected range numbers.';

  @override
  String get tasmeeDownloadModel => 'Download recitation model';

  @override
  String get tasmeeListening => 'Listening';

  @override
  String get tasmeeNotListening => 'Tap to start and recite from memory';

  @override
  String get tasmeeModelLoad => 'Preparing model';

  @override
  String get tasmeeWordWrong => 'Mistake';

  @override
  String get tasmeeWordSkipped => 'Skipped';

  @override
  String get tasmeeSessionComplete => 'Recitation complete';

  @override
  String tasmeeSessionDoubtful(int n, String count) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$count unsure words, not counted in the accuracy',
      one: '$count unsure word, not counted in the accuracy',
    );
    return '$_temp0';
  }

  @override
  String get tasmeeAccuracy => 'Accuracy';

  @override
  String get tasmeeAccuracyShort => 'accuracy';

  @override
  String tasmeeAcrossSurahs(
    String fromSurah,
    String fromAyah,
    String toSurah,
    String toAyah,
    String mode,
  ) {
    return '$fromSurah $fromAyah – $toSurah $toAyah · $mode';
  }

  @override
  String get tasmeeAyah => 'Verse';

  @override
  String get tasmeeCancelDownload => 'Cancel download';

  @override
  String get tasmeeClearHistory => 'Clear the tasmee history';

  @override
  String get tasmeeClearHistoryBody =>
      'What the app keeps of your past sessions (the last tasmee) is removed. No audio is ever kept.';

  @override
  String get tasmeeClearHistoryHint => 'The last tasmee and its result';

  @override
  String get tasmeeTrainTitle =>
      'Help us improve and train the model with your recordings';

  @override
  String get tasmeeTrainBody =>
      'On the «Tasmee training» platform you recite verses from memory and donate your recording, so the tasmee model learns and gets more accurate. Taking part is entirely optional.';

  @override
  String get tasmeeTrainHowTitle => 'How to take part?';

  @override
  String get tasmeeTrainStep1 =>
      'Create an account with your email and accept the participation terms.';

  @override
  String get tasmeeTrainStep2 =>
      'Pick a surah and a range of verses, and recite them from memory into the microphone. Each recording can be up to two minutes.';

  @override
  String get tasmeeTrainStep3 =>
      'Record in a quiet place, close to the microphone, clearly and at a comfortable pace. Both correct recitations and deliberate mistakes are needed for training.';

  @override
  String get tasmeeTrainStep4 =>
      'Volunteers review your recording before it joins the training data.';

  @override
  String get tasmeeTrainPrivacy =>
      'Privacy: we ask only for your email and birth year; anyone under 18 needs parental consent. Accepted recordings are shared under CC BY 4.0, raw files are never public, and you can delete your recordings at any time.';

  @override
  String get tasmeeTrainOpen => 'Open the training platform';

  @override
  String get tasmeeTrainOpenFailed =>
      'Couldn\'t open the browser. Open train.altibyan.app manually.';

  @override
  String get tasmeeClose => 'Close';

  @override
  String get tasmeeConfirm => 'Confirm';

  @override
  String get tasmeeContinueLast => 'Continue';

  @override
  String get tasmeeContinuousHint =>
      'Read on; each word appears in place as you read it';

  @override
  String get tasmeeDefaultsNote => 'Defaults come from Settings › Tasmee';

  @override
  String get tasmeeDeleteModel => 'Delete the model';

  @override
  String get tasmeeDeleteModelBody =>
      'The tasmee model is removed from this device. You will need to download it again before the next tasmee.';

  @override
  String get tasmeeDone => 'Done';

  @override
  String get tasmeeDownloadShort => 'Get model';

  @override
  String tasmeeDownloadSize(String size) {
    return 'Download ($size MB)';
  }

  @override
  String tasmeeDurationWords(
    String minutes,
    String seconds,
    int n,
    String words,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$words words',
      one: '$words word',
    );
    return '$minutes min $seconds s · $_temp0';
  }

  @override
  String get tasmeeElapsed => 'Time';

  @override
  String get tasmeeEnd => 'Finish';

  @override
  String get tasmeeFeedback => 'While reciting';

  @override
  String get tasmeeFinishing => 'Finishing…';

  @override
  String get tasmeeFromPage => 'From page';

  @override
  String get tasmeeFromSurah => 'From surah';

  @override
  String get tasmeeHelp => 'Help';

  @override
  String get tasmeeHint => 'Hint';

  @override
  String get tasmeeHistory => 'History';

  @override
  String get tasmeeKindHalfHizb => 'Half hizb';

  @override
  String get tasmeeKindHizb => 'Hizb';

  @override
  String get tasmeeKindJuz => 'Juz';

  @override
  String get tasmeeKindPages => 'Pages';

  @override
  String get tasmeeKindQuarter => 'Quarter';

  @override
  String get tasmeeKindSurah => 'Surah';

  @override
  String get tasmeeKindThreeQuarters => '¾ hizb';

  @override
  String get tasmeeKindVerses => 'Verses';

  @override
  String tasmeeLastSession(String range, String accuracy) {
    return 'Last tasmee: $range · $accuracy';
  }

  @override
  String get tasmeeLenient => 'Lenient';

  @override
  String get tasmeeLenientHint => 'Accepts a word heard less exactly';

  @override
  String get tasmeeLess => 'Less';

  @override
  String tasmeeListeningVerse(String ayah) {
    return 'Verse $ayah: listening';
  }

  @override
  String get tasmeeMarkAndGoOn => 'Mark and go on';

  @override
  String get tasmeeMedium => 'Medium';

  @override
  String get tasmeeMediumHint => 'Forgives one letter in a long word';

  @override
  String get tasmeeMicOff => 'Microphone access is off';

  @override
  String get tasmeeMicPrivacy =>
      'Tasmee listens on this device only. Nothing is sent or kept.';

  @override
  String tasmeeMistakes(String count) {
    return '$count mistakes';
  }

  @override
  String get tasmeeModelChecking => 'Checking the size…';

  @override
  String get tasmeeModelDetails =>
      'Source and licence in About this mushaf › Sources';

  @override
  String get tasmeeModelFailed =>
      'Could not connect. Check the internet and try again.';

  @override
  String tasmeeModelInstalled(String version) {
    return 'Model installed (version $version)';
  }

  @override
  String get tasmeeModelMissing => 'The tasmee model is not downloaded';

  @override
  String get tasmeeModelOffline => 'Works offline afterwards';

  @override
  String tasmeeModelProgress(String done, String total) {
    return '$done of $total MB';
  }

  @override
  String get tasmeeModelRemove => 'Remove it any time in Settings › Tasmee';

  @override
  String tasmeeModelSize(String size) {
    return '$size MB · one time';
  }

  @override
  String get tasmeeModelSizeUnknown => 'One time';

  @override
  String tasmeeModelSpace(String size) {
    return 'Space used: $size MB';
  }

  @override
  String get tasmeeModelTitle => 'Tasmee model';

  @override
  String get tasmeeModelUpdate => 'Update';

  @override
  String tasmeeModelUpdateAvailable(String size) {
    return 'Model update available ($size MB)';
  }

  @override
  String get tasmeeModelUpdateKeeps =>
      'The current model keeps working until the new one is fully downloaded, then it is removed';

  @override
  String get tasmeeModelUpdateTitle => 'Update the tasmee model';

  @override
  String get tasmeeModelVoiceStays =>
      'Your voice stays on this device, never sent or kept';

  @override
  String get tasmeeModelWifiNote => 'Best on Wi‑Fi; mobile data may be charged';

  @override
  String get tasmeeMore => 'More';

  @override
  String get tasmeeNew => 'New tasmee';

  @override
  String get tasmeeNoAudioKept =>
      'The last tasmee is kept so you can continue. No audio is kept.';

  @override
  String get tasmeeNoMistakes => 'no mistakes';

  @override
  String get tasmeeNotNow => 'Not now';

  @override
  String get tasmeeNothingToReview => 'Well done: no verse needs review.';

  @override
  String get tasmeeNoticeDeviceBody =>
      'Your voice is never sent anywhere or kept.';

  @override
  String get tasmeeNoticeDeviceTitle => 'It runs on your device';

  @override
  String get tasmeeNoticeMishearBody =>
      'A word it is unsure of gets a dotted line and does not count against you.';

  @override
  String get tasmeeNoticeMishearTitle => 'It can mishear';

  @override
  String get tasmeeNoticeOk => 'Got it';

  @override
  String get tasmeeNoticeStart => 'Got it, start';

  @override
  String get tasmeeNoticeTajweedBody =>
      'Nor makharij, madd, or where you stop and start.';

  @override
  String get tasmeeNoticeTajweedTitle => 'It does not judge tajweed';

  @override
  String get tasmeeNoticeTitle =>
      'Tasmee checks your memorisation, not your tajweed';

  @override
  String get tasmeeNoticeWordsBody =>
      'Did you read what is in the mushaf, word by word?';

  @override
  String get tasmeeNoticeWordsTitle => 'It checks the words and their order';

  @override
  String get tasmeeOnError => 'On a mistake';

  @override
  String get tasmeeOneMistake => 'one mistake';

  @override
  String tasmeeOneTo(String max) {
    return '1 to $max';
  }

  @override
  String get tasmeeOpenDeviceSettings => 'Open device settings';

  @override
  String get tasmeeOtherEdition =>
      'Tasmee follows the pages of the new Madina mushaf (1441); with your edition the words appear here in order.';

  @override
  String get tasmeePause => 'Pause';

  @override
  String get tasmeePaused => 'Paused';

  @override
  String get tasmeeProgress => 'Range recited';

  @override
  String get tasmeeQuarterOfHizb => 'Quarter';

  @override
  String get tasmeeRange => 'Range';

  @override
  String tasmeeRangeSummary(
    String from,
    String to,
    int verseTotal,
    String verses,
    int wordTotal,
    String words,
    String pages,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      verseTotal,
      locale: localeName,
      other: '$verses verses',
      one: '$verses verse',
    );
    String _temp1 = intl.Intl.pluralLogic(
      wordTotal,
      locale: localeName,
      other: '$words words',
      one: '$words word',
    );
    return 'From $from to $to · $_temp0 · $_temp1 · p. $pages';
  }

  @override
  String get tasmeeReReadWord => 'Re-read the word marked in red';

  @override
  String get tasmeeReciteAgain => 'Recite these again';

  @override
  String get tasmeeReciteVerse => 'Recite verse';

  @override
  String get tasmeeRedownload => 'Download the model again';

  @override
  String get tasmeeRedownloadBody =>
      'The current model is removed and downloaded again.';

  @override
  String get tasmeeRepeat => 'Again';

  @override
  String get tasmeeResume => 'Resume';

  @override
  String get tasmeeRetry => 'Try again';

  @override
  String tasmeeReviewRow(String ayah, String accuracy) {
    return 'Verse $ayah, accuracy $accuracy';
  }

  @override
  String tasmeeRingSemantics(String title, String note, String value) {
    return '$title, $note: $value';
  }

  @override
  String tasmeeSeconds(String count) {
    return '$count s';
  }

  @override
  String tasmeeSessionTitle(String surah) {
    return 'Tasmee · $surah';
  }

  @override
  String get tasmeeSettingsNote => 'Mode, mistakes, the model';

  @override
  String get tasmeeSkipWord => 'Skip it';

  @override
  String get tasmeeStart => 'Start';

  @override
  String get tasmeeStartReciting => 'Start reciting';

  @override
  String get tasmeeStopToCorrect => 'Stop to correct';

  @override
  String get tasmeeStopToCorrectHint => 'Waits until you read the right word';

  @override
  String get tasmeeStrict => 'Strict';

  @override
  String get tasmeeStrictHint => 'The word letter for letter';

  @override
  String get tasmeeStrictness => 'Matching';

  @override
  String get tasmeeSummary => 'Summary';

  @override
  String get tasmeeTestByTouch => 'Test yourself by tapping instead';

  @override
  String get tasmeeThisVerse => 'this verse';

  @override
  String get tasmeeToPage => 'To page';

  @override
  String get tasmeeToReview => 'Verses to review';

  @override
  String get tasmeeToSurah => 'To surah';

  @override
  String get tasmeeToastDuration => 'How long a verse result shows';

  @override
  String get tasmeeVerseByVerseHint =>
      'Tap, recite one verse, then see it whole with its result';

  @override
  String get tasmeeVerseDone => 'Verse done';

  @override
  String tasmeeVerseNumber(String ayah) {
    return 'Verse $ayah';
  }

  @override
  String tasmeeVerseOf(String n, String count) {
    return 'Verse $n of $count: tap and recite it';
  }

  @override
  String tasmeeVerseResult(String ayah, String accuracy, String detail) {
    return 'Verse $ayah · $accuracy · $detail';
  }

  @override
  String get tasmeeVersesHeading => 'Verses';

  @override
  String tasmeeVersesLine(String from, String to, String mode) {
    return 'Verses $from–$to · $mode';
  }

  @override
  String get tasmeeVibration => 'Vibrate on a mistake';

  @override
  String get tasmeeVibrationHint =>
      'A light buzz when a word is marked wrong or skipped';

  @override
  String get tasmeeWholeSession => 'whole tasmee';

  @override
  String get tasmeeWordCorrectedShort => 'Corrected';

  @override
  String get tasmeeWordHinted => 'Hinted';

  @override
  String get tasmeeAllowMicHint =>
      'Open the device settings and allow Tibyan to use the microphone.';

  @override
  String get tasmeeAutoUpdateModel => 'Update the model automatically on Wi‑Fi';

  @override
  String get tasmeeAutoUpdateModelHint =>
      'The newer version downloads in the background; the current one keeps working until it is complete';

  @override
  String tasmeeModelUpdated(String version) {
    return 'The tasmee model was updated to version $version';
  }

  @override
  String sourceInstalledVersion(String version) {
    return 'Installed version: $version';
  }

  @override
  String sourceAlsoCredited(String names) {
    return 'Also credited: $names';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navGroupReading => 'Reading';

  @override
  String get navGroupListening => 'Listening';

  @override
  String get navGroupWird => 'Wird & memorization';

  @override
  String get navCollapse => 'Collapse sidebar';

  @override
  String get navExpand => 'Expand sidebar';

  @override
  String get homeSections => 'Sections';

  @override
  String get homeContinueHint => 'Continue where you stopped';

  @override
  String get interfaceStyleTitle => 'Interface style';

  @override
  String get interfaceStyleHint =>
      'The look of home, the index, settings and dialogs; the mushaf page keeps its own style';

  @override
  String get interfaceStyleMakhtuta => 'Manuscript';

  @override
  String get interfaceStyleHandasi => 'Geometric';

  @override
  String get interfaceStyleLayli => 'Night gold';

  @override
  String get settingsGroupAppearance => 'Appearance';

  @override
  String get settingsGroupListening => 'Listening and recitation';

  @override
  String get settingsGroupData => 'Data and privacy';

  @override
  String get progressSaved => 'Result saved';

  @override
  String progressNewlyMastered(String count) {
    return 'Newly mastered verses: $count';
  }

  @override
  String progressStillMastered(String count) {
    return 'Mastered: $count';
  }

  @override
  String progressToReview(String count) {
    return 'To review: $count';
  }

  @override
  String get hifzTabToday => 'Today';

  @override
  String get hifzTabProgress => 'Progress';

  @override
  String get hifzTabHistory => 'History';

  @override
  String get hifzTabHardWords => 'Hard words';

  @override
  String get hifzTabGoals => 'Goals';

  @override
  String get hifzJourney => 'Hifz journey';

  @override
  String hifzJourneyLine(int n, String memorized, String mastered) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$memorized verses memorized',
      one: '$memorized verse memorized',
    );
    return '$_temp0, $mastered mastered';
  }

  @override
  String get hifzJourneyEmpty =>
      'Recite what you know and your progress is kept here.';

  @override
  String get progressOverall => 'Overall';

  @override
  String get progressJuzCount => 'Juz';

  @override
  String get progressPagesCount => 'Pages';

  @override
  String get progressVersesCount => 'Verses';

  @override
  String get progressMemorized => 'Memorized';

  @override
  String get progressMastered => 'Mastered';

  @override
  String get progressNeedsReview => 'Needs review';

  @override
  String get progressAccuracy30 => 'Average accuracy, last 30 days';

  @override
  String get progressBySurah => 'By surah';

  @override
  String get progressByJuz => 'By juz';

  @override
  String progressLastRecited(String date) {
    return 'Last recited $date';
  }

  @override
  String get progressNotRecited => 'Not recited yet';

  @override
  String progressShares(String memorized, String mastered) {
    return 'Memorized $memorized · mastered $mastered';
  }

  @override
  String progressAccuracy(String value) {
    return 'Accuracy $value';
  }

  @override
  String progressSuggestRecite(String count) {
    return 'Memorized verses not recited yet: $count. Recite them to master them.';
  }

  @override
  String get progressMasteryRule =>
      'A verse becomes “mastered” when you recite it at 90% accuracy or more.';

  @override
  String get progressEmpty =>
      'Nothing memorized yet. Mark what you know on the map, or recite.';

  @override
  String get progressOpenMap => 'Open the map';

  @override
  String get historyEmpty =>
      'No recitation saved yet. Every session is saved here on its own: its result only, never audio.';

  @override
  String get recitationVoice => 'By voice';

  @override
  String get recitationTouch => 'By touch';

  @override
  String get recitationTest => 'Hifz test';

  @override
  String historyVerses(int n, String count) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$count verses',
      one: '$count verse',
    );
    return '$_temp0';
  }

  @override
  String get sessionSummary => 'Session summary';

  @override
  String get sessionDelete => 'Remove from history';

  @override
  String sessionSensitivity(String level) {
    return 'Matching: $level';
  }

  @override
  String get sessionSlips => 'Slips';

  @override
  String get hardWordsEmpty =>
      'No hard words yet. A word you miss or skip more than once shows here.';

  @override
  String hardWordsCount(int n, String count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$count times',
      one: '$count time',
    );
    return '$_temp0 · last $date';
  }

  @override
  String get hardWordsHint => 'These words\' verses come first in review.';

  @override
  String get goalsEmpty => 'No goals yet. Pick a ready goal or make your own.';

  @override
  String get goalNew => 'New goal';

  @override
  String get goalTemplateAmma => 'Juz Amma in two months';

  @override
  String get goalTemplatePageDaily => 'A page a day';

  @override
  String get goalTemplateHizbWeekly => 'Review a hizb a week';

  @override
  String get goalTemplateFixSurah => 'Fix a surah';

  @override
  String get goalOpen => 'Open goal';

  @override
  String get goalOpenHint => 'Choose the range, length and unit';

  @override
  String get goalFromSurah => 'From surah';

  @override
  String get goalToSurah => 'To surah';

  @override
  String get goalSurah => 'Surah';

  @override
  String get goalHizb => 'Hizb';

  @override
  String goalDays(int n, String days) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$days days',
      one: '$days day',
    );
    return 'Length: $_temp0';
  }

  @override
  String get goalUnit => 'Unit';

  @override
  String get goalCreate => 'Create the goal';

  @override
  String get goalTodayWird => 'Today’s portion';

  @override
  String get goalMemorize => 'Memorize';

  @override
  String get goalReview => 'Review';

  @override
  String goalReviewDue(String count) {
    return 'Units due for review: $count';
  }

  @override
  String goalReviewHard(String count) {
    return 'Verses with hard words: $count';
  }

  @override
  String get goalNothingToday => 'No portion today.';

  @override
  String goalMasteredShare(String value) {
    return 'Mastered $value';
  }

  @override
  String goalLeft(int n, String pages) {
    return 'Pages left: $pages';
  }

  @override
  String goalUntil(String date) {
    return 'Until $date';
  }

  @override
  String goalBehind(int n, String pages) {
    return 'Pages left from past days: $pages';
  }

  @override
  String get goalCatchUp => 'Catch up over days';

  @override
  String get goalExtend => 'Move the end date';

  @override
  String get goalPause => 'Pause';

  @override
  String get goalResume => 'Resume';

  @override
  String get goalDelete => 'Delete the goal';

  @override
  String get goalReminder => 'Daily reminder';

  @override
  String goalReminderAt(String time) {
    return 'Reminder $time';
  }

  @override
  String get goalReminderOff => 'Turn the reminder off';

  @override
  String get goalPaused => 'Paused';

  @override
  String get goalComplete => 'Goal complete, may Allah bless you.';

  @override
  String get goalCountedByMastery =>
      'Progress counts mastered recitation, not marking by hand.';

  @override
  String get goalReminderTitle => 'Hifz portion';

  @override
  String goalReminderBody(String from, String to) {
    return 'Memorize: pages $from–$to';
  }

  @override
  String get goalRecite => 'Recite';

  @override
  String get hifzMapShowMastery => 'Mastery';

  @override
  String get hifzMapShowStrength => 'Strength';

  @override
  String get whatsNewHifzProgress => 'Hifz journey';

  @override
  String onbStepOf(String step, String total) {
    return 'Step $step of $total';
  }

  @override
  String get onbSkipAll => 'Skip all';

  @override
  String get onbSkip => 'Skip';

  @override
  String get onbInterfaceTitle => 'Choose the interface style and its light';

  @override
  String get onbPageTurnTitle => 'Choose how the mushaf turns its pages';

  @override
  String get onbPageTitle => 'Choose how the mushaf page looks';

  @override
  String get onbReciterTitle => 'Listen to the mushaf in a voice you love';

  @override
  String onbReciterSuggest(String name) {
    return 'Download the whole mushaf recited by $name';
  }

  @override
  String onbReciterSize(String size) {
    return 'About $size MB · carries on in the background';
  }

  @override
  String get onbReciterOther => 'Choose another reciter';

  @override
  String get onbReciterOnline =>
      'You can listen to any reciter online without downloading';

  @override
  String onbDownloadingBg(String done, String total) {
    return 'Downloading in the background: $done of $total';
  }

  @override
  String get onbTasmeeTitle => 'Recite and be checked';

  @override
  String get onbTasmeeBody =>
      'Tibyan listens as you recite and marks slips, on your device and offline. It needs a speech model, downloaded once.';

  @override
  String get onbTasmeeDownload => 'Download the model';

  @override
  String onbTasmeeDownloading(String percent) {
    return 'Downloading the model in the background: $percent%';
  }

  @override
  String get onbTasmeeReady => 'The recitation model is ready';

  @override
  String get onbTasmeeFailed =>
      'The download failed. You can get it later in Settings › Memorization.';

  @override
  String get onbStart => 'Start reading';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionAppearanceHint => 'Style, light, language, font';

  @override
  String get settingsSectionMushaf => 'Mushaf';

  @override
  String get settingsSectionMushafHint => 'Edition, page look, tajweed, focus';

  @override
  String get settingsSectionListening => 'Listening';

  @override
  String get settingsSectionListeningHint => 'Reciters, player, sajdah timer';

  @override
  String get settingsSectionHifz => 'Memorization';

  @override
  String get settingsSectionHifzHint => 'Hifz, recitation check, model';

  @override
  String get settingsSectionKhatma => 'Khatma & reminders';

  @override
  String get settingsSectionKhatmaHint => 'Plans, reminders, daily portion';

  @override
  String get settingsSectionStorage => 'Storage & backup';

  @override
  String get settingsSectionStorageHint => 'Space, backup, restore';

  @override
  String get settingsSectionAssistant => 'Assistant';

  @override
  String get settingsSectionAssistantHint =>
      'Help with using the app and the mushaf';

  @override
  String get settingsSectionAbout => 'About Tibyan';

  @override
  String get settingsSectionAboutHint => 'What’s new, sources, version';

  @override
  String get settingsSearchHint => 'Search settings';

  @override
  String get settingsSearchEmpty => 'No setting matches. Try another word.';

  @override
  String get settingsKhatmaPlans => 'Khatma plans and reminders';

  @override
  String get settingsWirdIndicator => 'Daily portion indicator on the mushaf';

  @override
  String get settingsCountListening =>
      'Count listening toward the daily portion';

  @override
  String get emptyOpenMushaf => 'Open the mushaf where you stopped';

  @override
  String get journalAddNote => 'Add a note';

  @override
  String get tasbihStart => 'Start counting';

  @override
  String get zeroLabel => 'zero';

  @override
  String get settingsHifzOpen => 'Open memorization';

  @override
  String get tasmeeSettingsTitle => 'Recitation practice settings';

  @override
  String get settingsHifzGoals => 'Memorization goals and reminders';

  @override
  String get digitsFontTitle => 'Interface digits font (Tibyan Digits)';

  @override
  String get digitsFontNote =>
      'Every interface digit uses one clear font: a digits-only subset of IBM Plex Sans Arabic (© 2017 IBM Corp.), renamed because \"Plex\" is a Reserved Font Name. Licence: SIL Open Font License 1.1, which permits subsetting and modification under a new name and the same licence.';

  @override
  String get reportProblemTitle => 'Report a problem';

  @override
  String get reportProblemHint => 'Send us a bug, a problem or a suggestion';

  @override
  String get reportType => 'Report type';

  @override
  String get reportTypeBug => 'Bug';

  @override
  String get reportTypeProblem => 'Problem';

  @override
  String get reportTypeSuggestion => 'Suggested improvement';

  @override
  String get reportTypeOther => 'Other';

  @override
  String get reportDescription => 'Description';

  @override
  String get reportDescriptionHint =>
      'What happened, where, and what you expected';

  @override
  String get reportDescriptionShort => 'Write at least five characters';

  @override
  String get reportPhone => 'Phone (optional)';

  @override
  String get reportPhoneInvalid => 'Invalid phone number';

  @override
  String get reportEmail => 'Email (optional)';

  @override
  String get reportEmailInvalid => 'Invalid email address';

  @override
  String get reportContactNote =>
      'Phone and email are optional. We use them only to reply to you, and they are deleted from your device once the report is sent.';

  @override
  String get reportDeviceTitle => 'Attached to the report';

  @override
  String reportDeviceVersion(String version) {
    return 'App version: $version';
  }

  @override
  String reportDeviceSystem(String platform, String os) {
    return 'System: $platform $os';
  }

  @override
  String get reportSend => 'Send report';

  @override
  String get reportSent => 'Your report arrived, thank you.';

  @override
  String get reportQueued =>
      'You\'re offline. The report is saved and will be sent when you\'re back online.';

  @override
  String get reportFailed =>
      'The report couldn\'t be sent. Check what you wrote and try again.';

  @override
  String get reportRateLimited =>
      'You\'ve just sent several reports. Try again shortly.';

  @override
  String reportPendingCount(int n) {
    return 'Reports waiting to be sent: $n';
  }

  @override
  String get helpGroupUsage => 'Using the app';

  @override
  String get helpGroupMarks => 'Tajweed and dabt';

  @override
  String get helpGroupFaq => 'FAQ and troubleshooting';

  @override
  String get onbTasmeeChecking => 'Checking the model\'s size…';

  @override
  String get onbTasmeeManifestFailed =>
      'Couldn\'t fetch the model\'s details. Check your connection and try again.';

  @override
  String get onbTasmeeUnsupported =>
      'Recitation checking isn\'t available on this device yet. You can carry on with the rest of the app.';

  @override
  String get menuGo => 'Go';

  @override
  String get menuPlayback => 'Playback';

  @override
  String get menuView => 'View';

  @override
  String get menuWindow => 'Window';

  @override
  String get menuHelp => 'Help';

  @override
  String get aboutApp => 'About Tibyan';

  @override
  String get playPause => 'Play or pause';

  @override
  String get verseOfDayTitle => 'Verse of the Day';

  @override
  String get widgetsTitle => 'Widgets';

  @override
  String get widgetVerseHint =>
      'A verse of the Quran every day; a tap opens it in the mushaf';

  @override
  String get widgetKhatmaHint =>
      'Today\'s khatma portion and the verse it starts at';

  @override
  String get widgetActionsTitle => 'Tibyan: shortcuts';

  @override
  String get widgetActionsHint =>
      'Continue reading, listen, search, mark today\'s portion read';

  @override
  String get widgetAdd => 'Add';

  @override
  String get widgetHowToIos =>
      'To add one: touch and hold the Home Screen, tap «+», and search for «Tibyan».';

  @override
  String get widgetHowToMac =>
      'To add one: Control-click the desktop, choose «Edit Widgets», and search for «Tibyan».';

  @override
  String get widgetHowToAndroid =>
      'To add one: touch and hold the home screen, choose «Widgets», and pick «Tibyan».';

  @override
  String get widgetRefresh => 'Refresh widgets now';

  @override
  String get widgetRefreshed => 'Widgets refreshed';

  @override
  String playSurahNamed(String surah) {
    return 'Listen to surah $surah';
  }

  @override
  String get listenNowPlaying => 'Now playing';

  @override
  String get listenChooseReciter => 'Choose a reciter';

  @override
  String get listenSurahs => 'Surahs';

  @override
  String get listenOtherRiwayaNote =>
      'The open mushaf does not follow these (their verses are numbered differently), and they count toward no khatma.';

  @override
  String get sectionTasbih => 'Tasbih';

  @override
  String get tasbihTitle => 'Tasbih';

  @override
  String tasbihTileToday(String count) {
    return 'Today $count';
  }

  @override
  String get tasbihTileStart => 'Start counting';

  @override
  String get tasbihCountAction => 'Count';

  @override
  String tasbihCountOf(String count, String target) {
    return '$count of $target';
  }

  @override
  String tasbihRounds(int n, String count) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$count rounds',
      one: '$count round',
      zero: 'No rounds',
    );
    return '$_temp0';
  }

  @override
  String tasbihRoundLabel(String count) {
    return 'Round $count';
  }

  @override
  String tasbihRoundClosed(String count) {
    return 'Round $count complete';
  }

  @override
  String tasbihTimes(int n, String count) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$count times',
      one: '$count time',
    );
    return '$_temp0';
  }

  @override
  String get tasbihTarget => 'Target';

  @override
  String get tasbihNoTarget => 'No target';

  @override
  String get tasbihTargetMore => 'Raise the target';

  @override
  String get tasbihTargetLess => 'Lower the target';

  @override
  String get tasbihReset => 'Start the round again';

  @override
  String get tasbihChooseDhikr => 'Choose a dhikr';

  @override
  String get tasbihAppAdhkar => 'From the source';

  @override
  String get tasbihMyAdhkar => 'My adhkar';

  @override
  String get tasbihMine => 'Added by you';

  @override
  String get tasbihAddDhikr => 'Add your own dhikr';

  @override
  String get tasbihEditDhikr => 'Edit dhikr';

  @override
  String get tasbihDeleteDhikr => 'Delete dhikr';

  @override
  String get tasbihDhikrText => 'Text';

  @override
  String get tasbihDhikrTextHint => 'Write the dhikr as you want to see it';

  @override
  String get tasbihDhikrReference => 'Reference (optional)';

  @override
  String get tasbihMineNote =>
      'Shown as “Added by you” and not attributed to any source.';

  @override
  String get tasbihSave => 'Save dhikr';

  @override
  String tasbihSourceLine(String source, String license) {
    return 'Source: $source, $license licence';
  }

  @override
  String get tasbihEmpty => 'No adhkar yet. Add your own to start.';

  @override
  String get tasbihLog => 'Daily log';

  @override
  String get tasbihLogHint =>
      'Each dhikr\'s total for its day, for the last thirty days.';

  @override
  String get tasbihLogEmpty => 'Nothing counted yet.';

  @override
  String get tasbihToday => 'Today';

  @override
  String get tasbihYesterday => 'Yesterday';

  @override
  String get tasbihDeletedDhikr => 'Deleted dhikr';

  @override
  String get tasbihDragHint => 'Pull a bead down, or tap';

  @override
  String get tasbihScreenHint => 'Tap anywhere to count; swipe down to leave';

  @override
  String get tasbihLcdHint => 'Long-press R to reset the round';

  @override
  String get settingsSectionTasbih => 'Tasbih';

  @override
  String get settingsSectionTasbihHint => 'Style, beads, vibration, sound';

  @override
  String get tasbihStyle => 'Style';

  @override
  String get tasbihStyleMisbaha => '3D misbaha';

  @override
  String get tasbihStyleButton => 'Big button';

  @override
  String get tasbihStyleLcd => 'Electronic counter';

  @override
  String get tasbihStyleScreen => 'Whole screen';

  @override
  String get tasbihSuggestedElderly => 'Suggested for elderly mode';

  @override
  String get tasbihRender => 'Bead rendering';

  @override
  String get tasbihRenderSuggested => 'Suggested 3D';

  @override
  String get tasbihRenderSuggestedHint => 'Shaded beads, light on every device';

  @override
  String get tasbihRenderReal => 'True 3D';

  @override
  String get tasbihRenderRealHint =>
      'Spheres in 3D space with perspective and lighting';

  @override
  String get tasbihMaterial => 'Bead material';

  @override
  String get tasbihMaterialAmber => 'Amber';

  @override
  String get tasbihMaterialWood => 'Wood';

  @override
  String get tasbihMaterialPearl => 'Pearl';

  @override
  String get tasbihHaptics => 'Light vibration with each count';

  @override
  String get tasbihHapticsHint => 'And a stronger one when a round completes';

  @override
  String get tasbihSound => 'Bead click sound';

  @override
  String get tasbihKeepScreenOn => 'Keep the screen on in the misbaha';

  @override
  String get tasbihVolumeKeys => 'Count with the volume buttons';

  @override
  String get tasbihVolumeKeysHint =>
      'While the misbaha is open, each press counts and the volume stays';

  @override
  String get tasbihSourcesTitle => 'Misbaha adhkar source';

  @override
  String get tasbihOpen => 'Open the misbaha';

  @override
  String get tasbihClickNote =>
      'The bead click is synthesized within the project and released under CC0.';

  @override
  String tasbihStageLine(String stage, String stages, String count, String of) {
    return '$stage/$stages · $count/$of';
  }

  @override
  String tasbihStageAnnounce(String stage, String stages) {
    return 'Stage $stage of $stages';
  }

  @override
  String get tasbihStagesFixed => 'The target comes from the dhikr\'s stages';

  @override
  String get fasilStyleLabel => 'Bookmark look';

  @override
  String get fasilStyleHint => 'How your named bookmarks show on the page';

  @override
  String get fasilStyleTint => 'Tinted verse';

  @override
  String get fasilStyleTintHint =>
      'The verse takes the bookmark\'s colour; the lightest look';

  @override
  String get fasilStyleRibbon => 'Fabric ribbon';

  @override
  String get fasilStyleRibbonHint =>
      'A ribbon hangs over the page, as in a printed mushaf';

  @override
  String get fasilStyleTab => 'Card tab';

  @override
  String get fasilStyleTabHint =>
      'A card with an ornamented dome rises over the page';

  @override
  String get fasilChooserTitle => 'Choose how your bookmarks look';

  @override
  String get fasilChooserHint =>
      'You can change it any time in Settings › Mushaf';

  @override
  String get fasilPlaceLabel => 'Position on the page';

  @override
  String get fasilPlaceTop => 'Top edge';

  @override
  String get fasilPlaceSide => 'Side edge';

  @override
  String get fasilMaterialLabel => 'Cloth';

  @override
  String get fasilSilk => 'Silk';

  @override
  String get fasilLinen => 'Linen';

  @override
  String get fasilVelvet => 'Velvet';

  @override
  String get fasilTassel => 'Tassel at the ribbon\'s end';

  @override
  String get fasilSuggestHifz => 'Memorize';

  @override
  String get fasilSuggestTilawa => 'Recitation';

  @override
  String get fasilSuggestReview => 'Review';

  @override
  String get fasilRename => 'Rename';

  @override
  String get fasilColor => 'Colour';

  @override
  String get fasilMoveHere => 'Move to this page';

  @override
  String get fasilDeleted => 'Bookmark deleted';

  @override
  String get fasilUndo => 'Undo';

  @override
  String get fasilPreview => 'Preview';

  @override
  String fasilDeleteConfirm(String name) {
    return 'Delete the bookmark “$name”?';
  }

  @override
  String fasilOnPage(String name, String page) {
    return 'Bookmark $name, page $page';
  }

  @override
  String get memorizeMode => 'Memorize';

  @override
  String get memorizeVerses => 'Memorize these verses';

  @override
  String get memorizeStart => 'Memorize with hidden words';

  @override
  String get memorizeStyleTitle => 'Hiding style';

  @override
  String get memorizeStyleAll => 'Hide all words';

  @override
  String get memorizeStyleFirstLetter => 'Show the first letter of each verse';

  @override
  String get memorizeStyleFirstWord => 'Show the first word of each verse';

  @override
  String get memorizeStyleAlternate => 'Hide every other word';

  @override
  String get memorizeStyleProgressive => 'Hide more with each repetition';

  @override
  String get memorizeRevealVerse => 'Reveal verse';

  @override
  String get memorizeRevealAll => 'Reveal all';

  @override
  String get memorizeHideAll => 'Hide all';

  @override
  String get memorizeRepeat => 'Repeat';

  @override
  String get memorizeMastered => 'Mastered';

  @override
  String get memorizeMissed => 'Missed';

  @override
  String get memorizeClose => 'End memorizing';

  @override
  String get memorizeHint =>
      'Tap a word to reveal it, or long-press and drag to reveal several.';

  @override
  String get memorizeProgressiveHint =>
      'Read the page, then tap Repeat to hide more.';

  @override
  String memorizeLevel(String level, String total) {
    return 'Step $level of $total';
  }

  @override
  String get memorizeByVoice => 'Reveal by reciting';

  @override
  String get memorizeByVoiceHint => 'Words appear as you recite them aloud.';

  @override
  String get memorizeVoiceNeedsModel =>
      'Download the tasmee model in tasmee settings to reveal words by reciting.';

  @override
  String get memorizeVoiceEdition =>
      'Reveal by reciting works in the Hafs editions.';

  @override
  String get memorizeListening => 'Listening…';

  @override
  String get memorizeNoWords =>
      'This edition has no word positions on this page, so verses are hidden whole and revealed verse by verse.';

  @override
  String get memorizeSomeVerses =>
      'Some verses have no word positions in this edition, so they are hidden whole.';

  @override
  String get memorizeOutOfScope => 'The chosen verses are not on this page.';

  @override
  String get gkTitle => 'Group khatma';

  @override
  String get gkSubtitle =>
      'Share the parts with family and friends by a link, no account.';

  @override
  String get gkCreate => 'Create a group khatma';

  @override
  String get gkJoin => 'Join by link';

  @override
  String get gkMine => 'My group khatmas';

  @override
  String get gkNone => 'You haven\'t joined a group khatma yet.';

  @override
  String get gkKhatmaName => 'Khatma name (optional)';

  @override
  String get gkOrganizerName => 'Your name as organizer (optional)';

  @override
  String get gkUnitJuz => '30 juz';

  @override
  String get gkUnitHizb => '60 hizb';

  @override
  String get gkTargetDate => 'Target date (optional)';

  @override
  String get gkNoDate => 'No date';

  @override
  String get gkCreateAction => 'Create';

  @override
  String get gkLinkHint => 'Paste the khatma link';

  @override
  String get gkLinkInvalid => 'That isn\'t a group khatma link.';

  @override
  String get gkOpen => 'Open';

  @override
  String gkProgress(int taken, int done, int total) {
    return '$taken of $total taken · $done done';
  }

  @override
  String gkJuzN(int n) {
    return 'Juz $n';
  }

  @override
  String gkHizbN(int n) {
    return 'Hizb $n';
  }

  @override
  String get gkOpenPart => 'Open';

  @override
  String get gkTakenPart => 'Taken';

  @override
  String get gkDonePart => 'Done';

  @override
  String get gkClaim => 'Claim';

  @override
  String get gkYourName => 'Your name, as others will see it';

  @override
  String get gkMarkDone => 'Mark done';

  @override
  String get gkUndoDone => 'Not done yet';

  @override
  String get gkRelease => 'Release';

  @override
  String get gkReleaseOther => 'Free this part';

  @override
  String get gkShare => 'Share link';

  @override
  String gkShareText(String title, String link) {
    return 'Join «$title»: pick a part and type your name.\n$link';
  }

  @override
  String get gkRename => 'Rename';

  @override
  String get gkDelete => 'Delete khatma';

  @override
  String get gkDeleteConfirm => 'The khatma will be deleted for everyone.';

  @override
  String get gkForget => 'Remove from my list';

  @override
  String get gkCancel => 'Cancel';

  @override
  String get gkSave => 'Save';

  @override
  String get gkOfflineCached => 'No connection. This is the last saved state.';

  @override
  String get gkErrOffline => 'Couldn\'t connect. Try again.';

  @override
  String get gkErrNotFound =>
      'This khatma doesn\'t exist; it may have been deleted.';

  @override
  String get gkErrTaken => 'Someone took this part first.';

  @override
  String get gkErrForbidden => 'You can\'t change this part from this device.';

  @override
  String get gkErrBusy => 'Too many tries. Please wait a little.';

  @override
  String get gkErrInvalid => 'Check what you typed.';

  @override
  String gkOrganizer(String name) {
    return 'Organized by $name';
  }

  @override
  String gkTarget(String date) {
    return 'Target $date';
  }

  @override
  String get gkYou => 'You';

  @override
  String get gkCompleted => 'The khatma is complete.';

  @override
  String get gkRemind => 'Remind me of my part';

  @override
  String gkReminderSet(String date) {
    return 'Reminder: $date';
  }

  @override
  String get gkReminderCancel => 'Cancel reminder';

  @override
  String gkReminderBody(String part) {
    return 'Time to read $part for the group khatma.';
  }

  @override
  String get gkPrivacyNote =>
      'Tibyan\'s server keeps only the khatma name, the typed names and part states, and deletes them automatically after the khatma ends.';

  @override
  String get settingsSectionAccessibility => 'Accessibility';

  @override
  String get settingsSectionAccessibilityHint => 'Reduce motion, screen reader';

  @override
  String get reduceMotionLabel => 'Reduce motion';

  @override
  String get reduceMotionHint =>
      'Follows the device by default; turn it on here to always use fewer animations and no sliding transitions';

  @override
  String get announceVerseNumberLabel => 'Read the verse number with its text';

  @override
  String get announceVerseNumberHint =>
      'With a screen reader: the surah name and verse number before the verse text';

  @override
  String get systemAccessibilitySettings => 'Device accessibility settings';

  @override
  String get systemAccessibilitySettingsHint =>
      'Text size, screen reader and reduce motion for the whole device';

  @override
  String get systemSettingsUnavailable => 'Couldn’t open the device settings';

  @override
  String get weeklyReportTitle => 'Weekly report';

  @override
  String get weeklyReportHint =>
      'A calm summary of your reading and memorisation over seven days';

  @override
  String weeklyRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get weeklyThisWeek => 'The last seven days';

  @override
  String get weeklyPrevious => 'Previous week';

  @override
  String get weeklyNext => 'Next week';

  @override
  String get weeklyNoteFresh =>
      'A new week, a fresh start. One page is enough to begin.';

  @override
  String get weeklyNoteSome =>
      'May your time be blessed. Every page you read is good.';

  @override
  String weeklyMissedDays(int n, String count) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$count days without reading this week',
      one: '$count day without reading this week',
    );
    return '$_temp0';
  }

  @override
  String get weeklyNoteMost =>
      'Masha’Allah, the Quran was with you on most days this week.';

  @override
  String get weeklyDailyChart => 'Minutes of reading and listening each day';

  @override
  String weeklyDayMinutes(String day, String minutes) {
    return '$day: $minutes min';
  }

  @override
  String get weeklyActiveDays => 'Days with reading or dhikr';

  @override
  String get weeklyRecitations => 'Recitation sessions';

  @override
  String get weeklyVersesRecited => 'Verses recited';

  @override
  String get weeklyTasbih => 'Tasbih count';

  @override
  String get weeklyKhatmas => 'Khatmas';

  @override
  String weeklyKhatmaProgress(String percent) {
    return '$percent% of the khatma';
  }

  @override
  String weeklyKhatmaGained(String percent) {
    return '$percent% of it read this week';
  }

  @override
  String get weeklyEmptyBody =>
      'Nothing was recorded on these days, and that is fine. Your reading, listening and recitation appear here automatically.';

  @override
  String get weeklyReminderToggle => 'Weekly report reminder';

  @override
  String get weeklyReminderHint =>
      'A notification on this device on the day and time you choose';

  @override
  String get weeklyReminderWhen => 'Reminder day and time';

  @override
  String get weeklyReminderTitle => 'Your weekly report is ready';

  @override
  String get weeklyReminderBody =>
      'Take a calm look at your week with the Quran.';

  @override
  String get weeklyReminderChannel => 'Weekly report';

  @override
  String get kahfReminderToggle => 'Friday reminder: Surah Al-Kahf';

  @override
  String get kahfReminderHint =>
      'A notification on this device every Friday morning that opens Surah Al-Kahf';

  @override
  String get kahfReminderTitle => 'Reminder: Surah Al-Kahf';

  @override
  String get kahfReminderBody => 'Tap to open the surah.';

  @override
  String get kahfReminderChannel => 'Friday reminder';

  @override
  String liveActivityVerse(String number) {
    return 'Verse $number';
  }

  @override
  String get liveActivityPlay => 'Play';

  @override
  String get liveActivityPreviousVerse => 'Previous verse';

  @override
  String get liveActivityNextVerse => 'Next verse';

  @override
  String get syncTitle => 'Sync';

  @override
  String get syncHint =>
      'Between your devices via iCloud or Google Drive, with no Tibyan account';

  @override
  String get syncSwitch => 'Sync between my devices';

  @override
  String get syncViaICloud => 'Through your own iCloud account';

  @override
  String get syncViaDrive =>
      'Through your own Google Drive, in a private app folder hidden from your files';

  @override
  String get syncWhat =>
      'Synced: bookmarks and marks, khatmas and their progress, the misbaha, the hifz record, and look, page turn and reciter settings. Downloads and device settings are not synced.';

  @override
  String get syncPrivacy =>
      'The data stays in your own account; Tibyan has no access to it. It works offline and syncs when you are back online.';

  @override
  String get syncNow => 'Sync now';

  @override
  String syncLast(String time) {
    return 'Last synced: $time';
  }

  @override
  String get syncNever => 'Not synced yet';

  @override
  String get syncRunning => 'Syncing…';

  @override
  String get syncFailed => 'Sync failed; it will try again automatically.';

  @override
  String get syncNotInBuild => 'Not available in this version';

  @override
  String get syncNoAccountICloud =>
      'Sign in to iCloud in the device settings and turn on iCloud Drive for this app.';

  @override
  String get syncNoAccountDrive => 'Choose a Google account to turn on sync.';

  @override
  String get syncUnsupported => 'Sync is not available on this device.';

  @override
  String get syncNoGoogleServices =>
      'Google Drive sync needs Google Play services, which this device does not have. To move your data, use Backup in Settings.';

  @override
  String get syncDeleteCloud => 'Stop sync and delete cloud data';

  @override
  String get syncDeleteConfirmTitle => 'Delete sync data from the cloud?';

  @override
  String get syncDeleteConfirmBody =>
      'Sync stops and what your devices uploaded is deleted from the cloud. Your data on this device stays as it is. A device that still has sync on will upload its data again.';

  @override
  String get syncDeleted => 'Sync data deleted from the cloud.';

  @override
  String get syncDeleteFailed =>
      'Could not reach the cloud, so nothing was deleted.';

  @override
  String get shareVerseVideo => 'Share as video';

  @override
  String get shareVideoTitle => 'Recitation video';

  @override
  String get shareVideoFrom => 'From verse';

  @override
  String get shareVideoTo => 'To verse';

  @override
  String get shareVideoReciter => 'Reciter';

  @override
  String shareVideoLength(String seconds) {
    return 'About $seconds seconds long';
  }

  @override
  String shareVideoTooLong(String max) {
    return 'Longer than $max seconds; choose fewer verses.';
  }

  @override
  String get shareVideoWordsNote => 'Each recited word lights up in turn.';

  @override
  String get shareVideoAyahNote =>
      'No word timings for this reciter, so the whole verse lights up.';

  @override
  String get shareVideoNoTimings =>
      'This reciter has no verse timings for this surah, so no video can be made with it.';

  @override
  String get shareVideoRiwaya =>
      'Videos are available for the Hafs riwaya only for now.';

  @override
  String get shareVideoMake => 'Make the video';

  @override
  String get shareVideoAudio => 'Downloading the recitation…';

  @override
  String shareVideoRendering(String percent) {
    return 'Making the video… $percent%';
  }

  @override
  String get shareVideoSaving => 'Saving the video…';

  @override
  String get shareVideoReady => 'The video is ready';

  @override
  String get shareVideoShare => 'Share the video';

  @override
  String get shareVideoFailed => 'Could not make the video';

  @override
  String get shareVideoOffline =>
      'The recitation is not on this device and there is no connection.';

  @override
  String get shareVideoUnsupported =>
      'Making videos is not available on this device.';

  @override
  String get reelHeading => 'From the Noble Quran';

  @override
  String reelVoice(String name) {
    return 'Recited by Sheikh $name';
  }

  @override
  String reelCredit(String name, String source) {
    return 'Recitation of Sheikh $name · $source';
  }

  @override
  String get reelJoin => 'Get the app now';

  @override
  String reelVerse(String n) {
    return 'Verse $n';
  }

  @override
  String reelVerses(String from, String to) {
    return 'Verses $from to $to';
  }

  @override
  String get tabFawasil => 'Bookmarks';

  @override
  String get fasilMoveTo => 'Move to…';

  @override
  String fasilMoveTitle(String name) {
    return 'Move «$name» to';
  }

  @override
  String get fasilMoveBySurah => 'Surah and verse';

  @override
  String get fasilMoveByPage => 'Page number';

  @override
  String get fasilMoveCurrent => 'Where you are reading';

  @override
  String get fasilSurah => 'Surah';

  @override
  String get fasilAyah => 'Verse';

  @override
  String get fasilPage => 'Page';

  @override
  String get fasilMove => 'Move';

  @override
  String get fasilMoved => 'Bookmark moved';

  @override
  String get fasilRenameAction => 'Rename';

  @override
  String get fasilChangeStyle => 'Change look, cloth and colour';

  @override
  String fasilStyleTitle(String name) {
    return 'Look of «$name»';
  }

  @override
  String get fasilFollowDefault => 'Follow the default';

  @override
  String get fasilDefaultOption => 'Default';

  @override
  String fasilLimitTitle(int max) {
    return 'You have reached the limit of $max bookmarks, fixed marks included';
  }

  @override
  String get fasilLimitHint =>
      'Fixed marks you have placed (reading, review, memorizing, reflection) count toward the limit. Move one of your bookmarks here, or delete one to add a new bookmark.';

  @override
  String fasilLimitOver(int count, int keep) {
    return 'You have $count bookmarks from before the limit, and all are kept. To add a new one, delete until $keep or fewer remain.';
  }

  @override
  String get fasilMoveHereShort => 'Move here';

  @override
  String get fasilReorderHint =>
      'Drag a bookmark to order it as it appears on the page edge.';

  @override
  String fasilItemLabel(String name, String surah, String ayah, String page) {
    return 'Bookmark $name, $surah verse $ayah, page $page';
  }

  @override
  String get fasilInvalidPlace => 'Not a valid place';

  @override
  String fasilCount(int count, int max) {
    return '$count of $max';
  }

  @override
  String get fasilMoveUp => 'Move earlier';

  @override
  String get fasilMoveDown => 'Move later';

  @override
  String whatsNewBuild(String build) {
    return 'Build $build';
  }

  @override
  String get whatsNewIntro =>
      'What we added and improved in the latest updates.';

  @override
  String get wn42Fawasil => 'Fawasil your way';

  @override
  String get wn42FawasilBody =>
      'Each fasil keeps its own look, cloth and colour, up to eight in all; adding a ninth offers to move or delete one.';

  @override
  String get wn42Index => 'Fawasil in the Index';

  @override
  String get wn42IndexBody =>
      'Move any fasil to a surah and verse or a page, rename or reorder it, and delete it with undo.';

  @override
  String get wn42Ribbons => 'Ribbons in the margin';

  @override
  String get wn42RibbonsBody =>
      'Ribbons hang in the page margin beside the text, like a mushaf\'s ribbon, never over a line.';

  @override
  String get wn42Speed => 'Smoother page turns';

  @override
  String get wn42SpeedBody =>
      'Pages turn lighter and faster, and a page opens at once from the Index or the home screen.';

  @override
  String get wn42Crash => 'Anonymous crash reports';

  @override
  String get wn42CrashBody =>
      'Only if you agree: reports without your name, device or anything you type help us fix errors faster. Change it any time in Settings.';

  @override
  String get wn41Hifz => 'Memorization mode';

  @override
  String get wn41HifzBody =>
      'The mushaf hides words for you to recite from memory, in five styles; a word shows with a tap or as you recite.';

  @override
  String get wn41Group => 'Group khatma';

  @override
  String get wn41GroupBody =>
      'Create a khatma and share its link; each person claims a part under their name. No account, no e-mail.';

  @override
  String get wn41Report => 'Weekly report';

  @override
  String get wn41ReportBody =>
      'Your reading and listening minutes, pages and khatma progress for the week, with calm notes that never compare weeks.';

  @override
  String get wn41Sync => 'Sync across your devices';

  @override
  String get wn41SyncBody =>
      'Your fawasil, khatmas, misbaha and settings move between your devices through your own iCloud or Google Drive, with no Tibyan server.';

  @override
  String get wn41Watch => 'Watch';

  @override
  String get wn41WatchBody =>
      'Today\'s portion and the misbaha on Apple Watch and Wear OS, with watch face complications.';

  @override
  String get wn41Video => 'Share as video';

  @override
  String get wn41VideoBody =>
      'Share verses in your chosen reciter\'s recitation as a vertical clip made on your device, with no music or sound effects.';

  @override
  String get wn41A11y => 'Accessibility';

  @override
  String get wn41A11yBody =>
      'Reduce motion, verse numbers read by screen readers, and text up to twice the size without overlaps.';

  @override
  String get wn40Tasbih => 'Misbaha';

  @override
  String get wn40TasbihBody =>
      'The reset button and long press respond as they should, and every preset dhikr has a short description.';

  @override
  String get khatmaPlansLoadFailed =>
      'The khatmas could not be loaded. Try again shortly.';

  @override
  String fasilColorOption(int n, int count) {
    return 'Colour $n of $count';
  }

  @override
  String get wn42Night => 'Distinct night and black';

  @override
  String get wn42NightBody =>
      'Night and black modes now look clearly different, and black is true black for OLED screens.';

  @override
  String get wn42Kahf => 'Surah al-Kahf reminder';

  @override
  String get wn42KahfBody =>
      'A Friday reminder to read Surah al-Kahf, on by default; turn it off in Settings.';

  @override
  String get wn42Voice => 'Siri and Google Assistant';

  @override
  String get wn42VoiceBody =>
      'Open the mushaf, today\'s portion or the misbaha with your voice.';

  @override
  String get wn42Live => 'Recitation on the lock screen';

  @override
  String get wn42LiveBody =>
      'A Live Activity and Dynamic Island on iPhone show the recitation and the surah\'s progress, with previous and next verse.';

  @override
  String get wn42Desktop => 'Tibyan on Windows and Linux';

  @override
  String get wn42DesktopBody =>
      'Desktop apps, downloaded from the Tibyan website.';

  @override
  String get widgetListen => 'Listen';

  @override
  String get widgetTodayWird => 'Today\'s portion';

  @override
  String get widgetStartWird => 'Start reading';

  @override
  String widgetDayOf(String n, String m) {
    return 'Day $n of $m';
  }

  @override
  String get widgetTileContinue => 'Continue';

  @override
  String get widgetTileListen => 'Listen';

  @override
  String get widgetTileSearch => 'Search';

  @override
  String get widgetTileRead => 'Portion read';

  @override
  String get widgetTileDone => 'Done';

  @override
  String get updateCheckTitle => 'Check for updates';

  @override
  String get updateChecking => 'Checking for updates…';

  @override
  String get updateUpToDate => 'You have the latest version.';

  @override
  String updateDownloading(String version, String percent) {
    return 'Downloading version $version $percent';
  }

  @override
  String updateReady(String version) {
    return 'Version $version is ready to install.';
  }

  @override
  String get updateRestart => 'Restart to update';

  @override
  String get updateFailed => 'Couldn\'t check for updates. Try again later.';

  @override
  String get storePrivacyTitle => 'Privacy policy';

  @override
  String get storePrivacyBody =>
      'Tibyan needs no account, collects no personal data, and keeps your data on your device. Please read the privacy policy before you continue.';

  @override
  String get storePrivacyRead => 'Read the privacy policy';

  @override
  String get storePrivacyAccept => 'OK';

  @override
  String get storePrivacyExit => 'Exit';

  @override
  String get cellularDownloadsToggle => 'Download over mobile data';

  @override
  String get cellularDownloadsHint =>
      'When off, downloads wait for Wi‑Fi and the app asks before using mobile data';

  @override
  String get cellularPausedTitle => 'Downloads paused: you\'re on mobile data';

  @override
  String cellularPausedBody(String size) {
    return 'About $size MB left. They continue on their own once you\'re on Wi‑Fi.';
  }

  @override
  String get cellularPausedBodyNoSize =>
      'They continue on their own once you\'re on Wi‑Fi.';

  @override
  String get cellularContinue => 'Continue on mobile data';

  @override
  String get cellularWait => 'Wait for Wi‑Fi';
}
