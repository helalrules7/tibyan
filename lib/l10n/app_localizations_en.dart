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
  String get aboutTitle => 'About';

  @override
  String get aboutBody =>
      'Tibyan is a free, non-profit app with no ads and no purchases, and its code is open. Every text in it comes from a verified source, shown next to it.';

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
  String get multiSelectHint =>
      'Drag the handles, or turn the page and tap a verse to extend the selection to it';

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
    return 'Download all editions ($size MB)';
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
  String searchCount(String count, String verses) {
    return '$count matches in $verses verses';
  }

  @override
  String searchMore(String count) {
    return 'and $count more verses; narrow the search to see them';
  }

  @override
  String get searchHistory => 'Recent searches';

  @override
  String get searchClearHistory => 'Clear';

  @override
  String get continueReading => 'Continue reading';

  @override
  String continueReadingAt(String surah, String ayah, String page) {
    return '$surah · verse $ayah · page $page';
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
  String get downloadAllTitle => 'Download all editions';

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
  String khatmaAboutPerDay(String count) {
    return 'About $count pages a day';
  }

  @override
  String khatmaDuration(String count, String date) {
    return '$count days, finishing on $date';
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
  String khatmaProgress(String done, String total) {
    return '$done of $total pages';
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
      'They are added to today\'s portion. You can spread them over the days left, or move the end date.';

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
  String streakReadToday(String count) {
    return 'You read today. Days in a row: $count';
  }

  @override
  String streakContinue(String count) {
    return 'Days in a row until yesterday: $count. A page today continues it.';
  }

  @override
  String get streakWelcome => 'Welcome back. Pick up where you left off.';

  @override
  String get streakNotesToggle => 'Streak notes';

  @override
  String get streakNotesHint =>
      'Shows days in a row only; missed days are never shown.';

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
    return '$surah · verse $ayah';
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
  String searchMeaningCount(String count) {
    return '$count verses';
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
  String get shareVerseCredit =>
      'Quran text: Tanzil Project (tanzil.net) · Tibyan app';

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
  String get oneVerse => 'Verse by verse';

  @override
  String get oneVerseHint =>
      'One verse a screen in large print, the phone sideways';

  @override
  String get oneVerseAutoOff => 'Auto-turn is off. Tap to turn it on';

  @override
  String oneVerseAutoOn(String seconds) {
    return 'Turns to the next verse every $seconds seconds. Tap to change';
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
      'Copy a verse, or share it as text or as a picture of the mushaf page, even over a page break.';

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
}
