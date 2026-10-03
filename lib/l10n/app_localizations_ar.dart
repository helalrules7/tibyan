// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تبيان';

  @override
  String get appTagline => 'تفسير وتلاوة وحفظ القرآن';

  @override
  String get homeComingTitle => 'قيد البناء';

  @override
  String get homeComingBody =>
      'هذه أول نسخة من تبيان: فيها الأشكال والإعدادات فقط. المصحف والتفسير والاستماع تأتي في المراحل القادمة إن شاء الله.';

  @override
  String get sectionMushaf => 'المصحف';

  @override
  String get sectionTafsir => 'التفسير';

  @override
  String get sectionListen => 'الاستماع';

  @override
  String get sectionHifz => 'الحفظ';

  @override
  String get sectionKhatma => 'الختمة';

  @override
  String get sectionSearch => 'البحث';

  @override
  String get comingSoon => 'قريبا';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get appearanceTitle => 'شكل المصحف';

  @override
  String get modeLabel => 'وضع الإضاءة';

  @override
  String get modeSystem => 'تلقائي';

  @override
  String get modeSystemHint => 'يتبع إعداد الجهاز';

  @override
  String get modeLight => 'فاتح';

  @override
  String get modeWhite => 'أبيض زاهي';

  @override
  String get modeNight => 'ليلي';

  @override
  String get modeBlack => 'أسود';

  @override
  String get uiFontLabel => 'خط الواجهة';

  @override
  String get uiFontPlex => 'آي بي إم بلكس عربي';

  @override
  String get uiFontKfgqpcAn => 'خط المجمع (AN)';

  @override
  String get uiFontChanga => 'Changa';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get languageSystem => 'لغة الجهاز';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get privacyTitle => 'الخصوصية';

  @override
  String get crashReportsLabel => 'إرسال تقارير الأعطال';

  @override
  String get crashReportsHint =>
      'يرسل تفاصيل تقنية عن الأعطال فقط، بلا أي بيانات شخصية. متوقف حتى توافق.';

  @override
  String get aboutTitle => 'عن التطبيق';

  @override
  String get aboutBody =>
      'تبيان تطبيق مجاني غير ربحي، بلا إعلانات ولا مشتريات، وشيفرته مفتوحة. كل نص فيه من مصدر موثق مذكور بجانبه.';

  @override
  String versionLabel(String version) {
    return 'الإصدار $version';
  }

  @override
  String get selected => 'محدد';

  @override
  String get onbLanguageTitle => 'اختر اللغة\nChoose your language';

  @override
  String get onbStyleTitle => 'اختر الشكل الذي يريح عينك';

  @override
  String get onbStyleHint => 'يمكنك تغييره في أي وقت من الإعدادات';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get skipLabel => 'تخطي';

  @override
  String get onbEditionTitle => 'اختر طبعة المصحف';

  @override
  String get editionNew => 'مصحف المدينة: الطبعة الحديثة';

  @override
  String get editionNewDesc =>
      'طبعة 1441هـ من مجمع الملك فهد، مع تظليل الآية أثناء التلاوة.';

  @override
  String get editionOld => 'مصحف المدينة: الطبعة القديمة';

  @override
  String get editionOldDesc =>
      'طبعة 1405هـ المشهورة في التطبيقات القديمة، مع تظليل الكلمة.';

  @override
  String get editionShamarly => 'مصحف الشمرلي (الطبعة المصرية)';

  @override
  String get editionShamarlyDesc =>
      'طبعة الشمرلي المصرية المعروفة، 522 صفحة، مع تظليل الآية وتظليل الكلمة في كثير من الآيات.';

  @override
  String get defaultTag => 'الافتراضية';

  @override
  String pagesDownloadNote(String size) {
    return 'صفحات هذا المصحف تُحمّل مرة واحدة (نحو $size ميجا)، ثم تعمل دون اتصال. وحتى يكتمل التحميل تقرأ في مصحف المدينة (الطبعة الحديثة) المدمج في التطبيق.';
  }

  @override
  String get downloadTitle => 'تحميل صفحات المصحف';

  @override
  String get downloadStart => 'ابدأ التحميل';

  @override
  String get downloadPause => 'إيقاف مؤقت';

  @override
  String get downloadResume => 'متابعة التحميل';

  @override
  String get downloadRetry => 'إعادة المحاولة';

  @override
  String get downloadVerifying => 'جارٍ التحقق من سلامة الملفات…';

  @override
  String get downloadInstalling => 'جارٍ تجهيز الصفحات…';

  @override
  String get downloadDone => 'اكتمل التحميل';

  @override
  String downloadFailed(String error) {
    return 'تعذّر التحميل: $error';
  }

  @override
  String downloadProgress(String received, String total) {
    return '$received من $total ميجا';
  }

  @override
  String get downloadWifiHint =>
      'يكمل التحميل من حيث توقف إذا انقطع الاتصال. يُفضّل الاتصال بشبكة Wi-Fi.';

  @override
  String get pagesCredit =>
      'صفحات مصحف المدينة من مجمع الملك فهد لطباعة المصحف الشريف.';

  @override
  String get pagesCreditOld =>
      'صفحات الطبعة القديمة (1405هـ) من مجمع الملك فهد لطباعة المصحف الشريف، ومصدرها موقع quran.com، وتُحمّل من خادم تبيان.';

  @override
  String get pagesCreditShamarly =>
      'مصحف الشمرلي بخط محمد سعد إبراهيم الشهير بحداد، والصفحات من أرشيف الإنترنت (archive.org)، وتُحمّل من خادم تبيان.';

  @override
  String get editionLabel => 'طبعة المصحف';

  @override
  String get viewPage => 'الصفحة';

  @override
  String get viewModeLabel => 'طريقة العرض';

  @override
  String get indexTitle => 'الفهرس';

  @override
  String get fawasilTitle => 'الفواصل';

  @override
  String get aboutMushafTitle => 'عن هذا المصحف';

  @override
  String juzPage(String juz, String page) {
    return 'الجزء $juz · الصفحة $page';
  }

  @override
  String surahWord(String name) {
    return 'سورة $name';
  }

  @override
  String verseSelected(String number) {
    return 'الآية $number محددة';
  }

  @override
  String get tapVerseHint => 'اضغط أي آية لتحديدها';

  @override
  String pageOf(String page) {
    return 'الصفحة $page';
  }

  @override
  String get indexSearchHint => 'اسم السورة، أو رقم صفحة، أو ٢:٢٥٥';

  @override
  String get tabSurahs => 'السور';

  @override
  String get tabJuz => 'الأجزاء';

  @override
  String get tabPages => 'الصفحات';

  @override
  String get meccan => 'مكية';

  @override
  String get medinan => 'مدنية';

  @override
  String ayahCount(String count) {
    return '$count آية';
  }

  @override
  String juzLabel(String number) {
    return 'الجزء $number';
  }

  @override
  String juzStartsAt(String surah, String ayah) {
    return 'يبدأ من $surah $ayah';
  }

  @override
  String pageShort(String page) {
    return 'ص $page';
  }

  @override
  String get lastPosition => 'آخر موضع قراءة، يُحفظ تلقائيا';

  @override
  String get yourFawasil => 'فواصلك';

  @override
  String get fasilNew => 'فاصل جديد';

  @override
  String get fasilName => 'اسم الفاصل';

  @override
  String get fasilSaveHere => 'احفظ الموضع الحالي في فاصل';

  @override
  String fasilLastAt(String surah, String ayah, String page) {
    return 'آخر موضع: $surah $ayah · الصفحة $page';
  }

  @override
  String get fasilHint => 'لكل فاصل لون واسم، ويتحرك إلى آخر موضع قرأت عنده.';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get noFawasil => 'لا توجد فواصل بعد';

  @override
  String get readingTitle => 'القراءة';

  @override
  String get keepScreenOn => 'إبقاء الشاشة مضاءة أثناء القراءة';

  @override
  String get aboutMushafIntro =>
      'كل نص في تبيان منقول من مصدر موثق، ولا يُعدَّل بأيدينا. وهذه مصادر المصحف في التطبيق:';

  @override
  String licenseLabel(String license) {
    return 'الرخصة: $license';
  }

  @override
  String versionShort(String version) {
    return 'الإصدار: $version';
  }

  @override
  String get reviewNotesTitle => 'مسائل معروضة على المراجعة';

  @override
  String reviewNotesBody(String count) {
    return '$count مواضع يختلف فيها مصدرا النص (حدود جزأين، وأربعة مواضع في الرسم) معروضة على مراجع متخصص، ويتبع التطبيق نص تنزيل حتى يصدر القرار.';
  }

  @override
  String get mushafOpen => 'افتح المصحف';

  @override
  String get loadingLabel => 'جارٍ التحميل…';

  @override
  String hizbLabel(String number) {
    return 'الحزب $number';
  }

  @override
  String catchwordLabel(String word) {
    return 'الكلمة الأولى في الصفحة التالية: $word';
  }

  @override
  String get catchwordImageLabel => 'الكلمة الأولى في الصفحة التالية';

  @override
  String get tabHizb => 'الأحزاب';

  @override
  String get goToPage => 'انتقال إلى صفحة';

  @override
  String goToPageHint(String max) {
    return 'رقم الصفحة من ١ إلى $max';
  }

  @override
  String get goLabel => 'انتقال';

  @override
  String hizbStartsAt(String surah, String ayah) {
    return 'يبدأ من $surah $ayah';
  }

  @override
  String get selectionStart => 'بداية التحديد';

  @override
  String get selectionEnd => 'نهاية التحديد';

  @override
  String get servicesTitle => 'خدمات الآيات';

  @override
  String get markReading => 'قراءة';

  @override
  String get markReview => 'مراجعة';

  @override
  String get markHifz => 'حفظ';

  @override
  String get markTadabbur => 'تدبر';

  @override
  String autoFasil(String surah, String ayah) {
    return 'فاصل تلقائي عند $surah $ayah';
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
    return '$count آيات';
  }

  @override
  String get twoVerses => 'آيتان';

  @override
  String get markerStyleLabel => 'شكل فواصل الآيات';

  @override
  String get markerTraditional => 'الفاصل التقليدي';

  @override
  String get markerRosette => 'وردة';

  @override
  String get markerTheme => 'حسب الثيم';

  @override
  String get markerThemeHint =>
      '«حسب الثيم» يرسم فاصل الثيم نفسه، وفي «تبيان» وردتها.';

  @override
  String get themeLabel => 'الثيم';

  @override
  String get markerTintLabel => 'لون الفواصل';

  @override
  String get markerTintNone => 'بلا لون';

  @override
  String get reciteMode => 'وضع التسميع';

  @override
  String get autoScroll => 'التمرير التلقائي';

  @override
  String get resume => 'متابعة';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get slower => 'أبطأ';

  @override
  String get faster => 'أسرع';

  @override
  String get stopAutoScroll => 'إيقاف التمرير';

  @override
  String speedLabel(String speed) {
    return 'السرعة $speed';
  }

  @override
  String surahBannerTitle(String number, String name, String type) {
    return '($number) سورة $name · $type';
  }

  @override
  String surahBannerInfo(String count, String order, String after) {
    return 'آياتها $count · ترتيبها في النزول $order · نزلت بعد $after';
  }

  @override
  String surahBannerInfoFirst(String count, String order) {
    return 'آياتها $count · ترتيبها في النزول $order';
  }

  @override
  String quarterHizb(String number) {
    return 'ربع الحزب $number';
  }

  @override
  String halfHizb(String number) {
    return 'نصف الحزب $number';
  }

  @override
  String threeQuartersHizb(String number) {
    return 'ثلاثة أرباع الحزب $number';
  }

  @override
  String get coverTitle => 'القرآن الكريم';

  @override
  String get coverSubtitle => 'بالرسم العثماني';

  @override
  String get riwayaHafs => 'رواية حفص عن عاصم';

  @override
  String openingInfo(String type, String count, String number) {
    return '$type · آياتها $count · ترتيبها $number';
  }

  @override
  String revealedOrder(String order) {
    return 'ترتيبها في النزول $order';
  }

  @override
  String revealedAfter(String after) {
    return 'نزلت بعد $after';
  }

  @override
  String get multiSelect => 'تحديد عدة آيات';

  @override
  String get multiSelectHint => 'اسحب المقبضين لتحديد الآيات';

  @override
  String get doneLabel => 'تم';

  @override
  String get markRemoved => 'أُزيل الفاصل';

  @override
  String get tabMarks => 'فواصل القراءة';

  @override
  String get noMarks => 'لا توجد فواصل بعد. اضغط على فاصل أي آية لتعليمها.';

  @override
  String get highlightDivineNames => 'تمييز لفظ الجلالة';

  @override
  String get highlightDivineNamesHint =>
      'تلوين «الله» و«رب» و«ربنا» في صفحات المصحف';

  @override
  String get tafsirTitle => 'التفسير والترجمة';

  @override
  String get tafsirSettings => 'إعدادات التفسير';

  @override
  String get tafsirFontLabel => 'خط التفسير';

  @override
  String get tafsirFontNaskh => 'نسخ عثمان طه';

  @override
  String get tafsirFontInterface => 'خط الواجهة';

  @override
  String get tafsirTextSize => 'حجم النص';

  @override
  String get tafsirShown => 'النصوص المعروضة';

  @override
  String get tafsirNoneShown => 'كل النصوص مخفية. اختر نصا من إعدادات التفسير.';

  @override
  String get tafsirFootnotes => 'الحواشي';

  @override
  String get previousVerse => 'الآية السابقة';

  @override
  String get nextVerse => 'الآية التالية';

  @override
  String sourceVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String sourceRetrieved(String date) {
    return 'نسخة $date';
  }

  @override
  String get tafsirKashida => 'الشد بالكشيدة (تجربة)';

  @override
  String get tafsirKashidaHint =>
      'ضبط سطور التفسير بمدّ الحروف بدل توسيع المسافات. لا يمس الكلمات القرآنية بين الأقواس، والنسخ يأخذ النص الأصلي';

  @override
  String get copyText => 'نسخ النص';

  @override
  String get copied => 'تم النسخ';

  @override
  String get listen => 'استماع';

  @override
  String get reciterLabel => 'القارئ';

  @override
  String get murattal => 'مرتل';

  @override
  String get repeatLabel => 'عدد مرات التكرار';

  @override
  String get repeatForever => 'بلا توقف';

  @override
  String repeatTimes(String n) {
    return '×$n';
  }

  @override
  String get silenceLabel => 'سكوت بين كل تكرار والتالي (للترديد خلف القارئ)';

  @override
  String get silenceNone => 'بلا';

  @override
  String seconds(String n) {
    return '$n ث';
  }

  @override
  String get repeatVerse => 'كرر هذه الآية';

  @override
  String get playToEnd => 'أكمل السورة';

  @override
  String get sleepLabel => 'مؤقت النوم';

  @override
  String get sleepOff => 'إيقاف';

  @override
  String minutes(String n) {
    return '$n د';
  }

  @override
  String get sleepSurahEnd => 'نهاية السورة';

  @override
  String get followRecitation => 'تقليب الصفحات مع التلاوة';

  @override
  String get audioDownloads => 'تحميل التلاوات';

  @override
  String get downloadAll => 'تحميل الكل';

  @override
  String get audioDownloaded => 'محملة على الجهاز';

  @override
  String get noTiming =>
      'هذه التلاوة بلا توقيت للآيات في هذه السورة: تُسمع كاملة بلا تظليل ولا تكرار آية';

  @override
  String get playerError =>
      'تعذر تشغيل التلاوة. تأكد من الاتصال بالإنترنت أو حمّل السورة.';

  @override
  String get playerSettings => 'إعدادات الاستماع';

  @override
  String get stopListening => 'إيقاف الاستماع';

  @override
  String repeatProgress(String done, String total) {
    return 'التكرار $done من $total';
  }

  @override
  String get audioCredit => 'التلاوات وتوقيت الآيات: mp3quran.net';

  @override
  String get touchReading => 'القراءة اللمسية';

  @override
  String get touchReadingOn => 'القراءة اللمسية: المس الآية التي تقرؤها';

  @override
  String get editionOnDevice => 'على الجهاز';

  @override
  String editionNotDownloaded(String size) {
    return 'غير محمّل · $size ميجا';
  }

  @override
  String downloadAllEditions(String size) {
    return 'تحميل كل المصاحف ($size ميجا)';
  }

  @override
  String get downloadInBackgroundNote =>
      'يمكنك الخروج من التطبيق: التحميل يكمل في الخلفية، ويصلك إشعار عند انتهائه.';

  @override
  String get notifDownloading => 'تحميل صفحات المصحف';

  @override
  String get notifComplete => 'اكتمل تحميل المصحف';

  @override
  String get notifFailed => 'تعذّر تحميل المصحف';

  @override
  String get notifPaused => 'التحميل متوقف مؤقتا';

  @override
  String get readInMadinaWhileDownloading =>
      'اقرأ في مصحف المدينة (الطبعة الحديثة) حتى يكتمل التحميل';

  @override
  String downloadingBanner(String name, String percent) {
    return 'يُحمَّل $name: $percent٪. تقرأ الآن في مصحف المدينة (الطبعة الحديثة)';
  }

  @override
  String get versePauseLabel => 'السكتة بين الآيات';

  @override
  String get versePauseAsRecorded => 'كما سُجّلت';

  @override
  String get versePauseSecond => 'ثانية';

  @override
  String get versePauseHalf => 'نصف ثانية';

  @override
  String get versePauseHint =>
      'يقصّر السكتات الطويلة بين الآيات دون المساس بالتلاوة نفسها';

  @override
  String get listenFromPage => 'استمع من أول الصفحة';

  @override
  String get repeatHint =>
      'إن لم تحدد مقطعًا تتكرر كل آية بهذا العدد ثم تليها التالية';

  @override
  String get homeTitle => 'الرئيسية';

  @override
  String get searchHint => 'ابحث في القرآن، أو اكتب «البقرة ٢٥٥»';

  @override
  String get searchIntro =>
      'اكتب كلمة أو أكثر من القرآن، بتشكيل أو دونه، أو اكتب موضعا مثل «٢:٢٥٥» أو «البقرة ٢٥٥».';

  @override
  String get searchGoTo => 'اذهب إلى الموضع';

  @override
  String get searchNothing => 'لا نتائج';

  @override
  String searchCount(String count, String verses) {
    return '$count موضعا في $verses آية';
  }

  @override
  String searchMore(String count) {
    return 'و$count آية أخرى، ضيّق البحث لرؤيتها';
  }

  @override
  String get searchHistory => 'عمليات البحث السابقة';

  @override
  String get searchClearHistory => 'مسح';

  @override
  String get continueReading => 'متابعة القراءة';

  @override
  String continueReadingAt(String surah, String ayah, String page) {
    return '$surah · الآية $ayah · صفحة $page';
  }

  @override
  String get openLabel => 'افتح';

  @override
  String get wordStudy => 'دراسة الكلمة';

  @override
  String get wordMeanings => 'معاني الكلمات';

  @override
  String get wordPickHint => 'اضغط على الكلمة التي تريد دراستها';

  @override
  String get wordStudyChoose => 'اختر كلمة من كلمات الآية';

  @override
  String get wordMeaningTitle => 'المعنى';

  @override
  String get wordNoMeaning => 'لا شرح لهذه الكلمة في «الميسر في غريب القرآن».';

  @override
  String get wordRootTitle => 'الجذر';

  @override
  String get wordLemma => 'المدخل المعجمي';

  @override
  String get wordNoRoot => 'لا جذر لهذه الكلمة في المدونة القرآنية.';

  @override
  String get wordNoCorpusData => 'لا بيانات لهذه الكلمة في المدونة القرآنية.';

  @override
  String get rootOccurrencesTitle => 'مواضع الجذر';

  @override
  String rootOccurrencesCount(String words, String verses) {
    return 'الكلمات: $words، الآيات: $verses';
  }

  @override
  String get verseNoMeanings =>
      'لا شرح لكلمات هذه الآية في «الميسر في غريب القرآن».';

  @override
  String wordStudyVerse(String surah, String ayah) {
    return '$surah، الآية $ayah';
  }

  @override
  String get downloadAllTitle => 'تحميل كل المصاحف';

  @override
  String downloadAllCount(String done, String total) {
    return 'اكتمل $done من $total';
  }

  @override
  String get themeArtCredit =>
      'الزخارف: مشروع quran-assets من Quran.ws، تطوير Abdullah Ibeid (github.com/quran-ws/quran-assets). المنقول منها من المصاحف برخصة المشاع الإبداعي غير التجارية CC BY-NC-SA 4.0، وتصميمه لمجمع الملك فهد وناشرين آخرين.';

  @override
  String get khatmaTitle => 'الختمة';

  @override
  String get khatmaNew => 'ختمة جديدة';

  @override
  String get khatmaEmptyTitle => 'لا ختمة الآن';

  @override
  String get khatmaEmptyBody =>
      'ضع خطة لختم المصحف: حدد موعد الختم أو مقدار الورد اليومي. والصفحات التي تقرؤها في المصحف تُحسب تلقائيا.';

  @override
  String get khatmaDefaultName => 'ختمتي';

  @override
  String get khatmaNameLabel => 'الاسم';

  @override
  String get khatmaByDate => 'حسب موعد الختم';

  @override
  String get khatmaByAmount => 'حسب الورد اليومي';

  @override
  String get khatmaEndDateLabel => 'موعد الختم';

  @override
  String get khatmaAmountLabel => 'المقدار في اليوم';

  @override
  String get khatmaUnitPage => 'صفحة';

  @override
  String get khatmaUnitJuz => 'جزء';

  @override
  String get khatmaUnitHizb => 'حزب';

  @override
  String khatmaAboutPerDay(String count) {
    return 'نحو $count صفحة في اليوم';
  }

  @override
  String khatmaDuration(String count, String date) {
    return 'المدة: $count يوم، والختم يوم $date';
  }

  @override
  String khatmaEditionNote(String edition) {
    return 'بصفحات $edition';
  }

  @override
  String get khatmaReminder => 'تذكير يومي';

  @override
  String get khatmaReminderOff => 'بلا تذكير';

  @override
  String get khatmaStart => 'ابدأ الختمة';

  @override
  String get khatmaReplaceTitle => 'ختمة مفتوحة';

  @override
  String get khatmaReplaceBody =>
      'تُحذف الختمة الحالية وسجلها عند بدء ختمة جديدة.';

  @override
  String get khatmaToday => 'ورد اليوم';

  @override
  String khatmaPagesRange(String from, String to) {
    return 'من صفحة $from إلى صفحة $to';
  }

  @override
  String khatmaPagesCount(String count) {
    return 'عدد الصفحات: $count';
  }

  @override
  String get khatmaReadNow => 'اقرأ الآن';

  @override
  String get khatmaMarkRead => 'قرأته في مصحف آخر';

  @override
  String get khatmaTodayDone => 'ورد اليوم مقروء';

  @override
  String get khatmaContinue => 'تابع القراءة';

  @override
  String khatmaProgress(String done, String total) {
    return '$done من $total صفحة';
  }

  @override
  String khatmaDaysLeft(String count) {
    return 'الأيام الباقية: $count';
  }

  @override
  String khatmaEnds(String date) {
    return 'الختم يوم $date';
  }

  @override
  String khatmaBehindTitle(String count) {
    return 'صفحات من الأيام الماضية: $count';
  }

  @override
  String get khatmaBehindBody =>
      'أُضيفت إلى ورد اليوم. يمكنك توزيعها على الأيام الباقية، أو تأخير موعد الختم.';

  @override
  String get khatmaSpread => 'وزّعها على الأيام الباقية';

  @override
  String get khatmaExtend => 'أخّر موعد الختم';

  @override
  String get khatmaComplete => 'اكتملت الختمة';

  @override
  String khatmaCompletedOn(String date) {
    return 'اكتملت يوم $date';
  }

  @override
  String get khatmaPast => 'ختمات سابقة';

  @override
  String get khatmaDelete => 'حذف الختمة';

  @override
  String get khatmaDeleteBody => 'يُحذف سجل هذه الختمة.';

  @override
  String get khatmaTileStart => 'ابدأ';

  @override
  String khatmaTilePages(String count) {
    return 'ورد اليوم: $count';
  }

  @override
  String get khatmaReminderTitle => 'ورد الختمة';

  @override
  String khatmaReminderBody(String from, String to) {
    return 'ورد اليوم: من صفحة $from إلى صفحة $to';
  }

  @override
  String get khatmaReminderChannel => 'تذكير الختمة';

  @override
  String get homeTodayTitle => 'اليوم';

  @override
  String get widgetNoKhatma => 'ابدأ ختمة في تبيان';

  @override
  String get reportsTitle => 'تقارير القراءة';

  @override
  String get reportsWeek => 'آخر ٧ أيام';

  @override
  String get reportsMonth => 'آخر ٣٠ يوما';

  @override
  String get reportsDays => 'أيام القراءة';

  @override
  String get reportsPages => 'الصفحات';

  @override
  String get reportsReadingMinutes => 'دقائق القراءة';

  @override
  String get reportsListeningMinutes => 'دقائق الاستماع';

  @override
  String get reportsEmpty => 'تظهر هنا قراءتك واستماعك تلقائيا.';

  @override
  String get reportsDayRead => 'يوم فيه قراءة أو استماع';

  @override
  String streakReadToday(String count) {
    return 'قرأت اليوم. الأيام المتتالية: $count';
  }

  @override
  String streakContinue(String count) {
    return 'الأيام المتتالية حتى أمس: $count. صفحة اليوم تصلها.';
  }

  @override
  String get streakWelcome => 'مرحبا بعودتك. تابع من حيث وقفت.';

  @override
  String get streakNotesToggle => 'رسائل الاستمرار';

  @override
  String get streakNotesHint =>
      'تعرض الأيام المتتالية فقط، ولا تعرض الأيام الفائتة.';

  @override
  String get journalTitle => 'دفتر التدبر';

  @override
  String get journalSearch => 'ابحث في ملاحظاتك';

  @override
  String get journalEmpty =>
      'لا ملاحظات بعد. اضغط مطولا على آية في المصحف واختر «ملاحظة تدبر».';

  @override
  String get journalNoMatch => 'لا ملاحظات فيها هذه الكلمات.';

  @override
  String get journalAdd => 'ملاحظة تدبر';

  @override
  String get journalHint => 'اكتب ملاحظتك على الآية';

  @override
  String get journalEdit => 'تعديل';

  @override
  String get journalOpenVerse => 'افتح الآية';

  @override
  String journalVerseRef(String surah, String ayah) {
    return 'سورة $surah · آية $ayah';
  }

  @override
  String get journalSaved => 'حُفظت الملاحظة';

  @override
  String get journalEarlier => 'ملاحظاتك على هذه الآية';

  @override
  String get elderlyMode => 'وضع كبار السن';

  @override
  String get elderlyModeHint =>
      'خط أكبر، وأزرار أكبر بأسمائها، وألوان أوضح، وصفحة رئيسية فيها المهم فقط، وصفحة المصحف بأكبر حجم، وانتقالات أهدأ';

  @override
  String get searchModeWords => 'بالكلمات';

  @override
  String get searchModeMeaning => 'بالمعنى';

  @override
  String get searchMeaningHint => 'اكتب فكرة أو سؤالا بكلماتك';

  @override
  String get searchMeaningIntro =>
      'اكتب فكرة بكلماتك، بالعربية أو بالإنجليزية، مثل «الصبر على البلاء» أو «بر الوالدين»، فتظهر الآيات التي يتناولها معناها في التفسير الميسر والترجمتين. تظهر كل آية بنصها، ومعها النص الذي طابق كما هو من مصدره.';

  @override
  String searchMatchedIn(String source) {
    return 'طابق في: $source';
  }

  @override
  String searchMeaningCount(String count) {
    return '$count آية';
  }

  @override
  String get semanticPackName => 'حزمة البحث بالمعنى';

  @override
  String semanticPackOffer(String size) {
    return 'البحث الآن بالكلمات داخل نصوص المعاني. نزّل حزمة البحث بالمعنى (نحو $size ميجا) ليجد البحث الآيات بمعناها وإن اختلفت الكلمات، دون اتصال.';
  }

  @override
  String get semanticPackDownload => 'تنزيل الحزمة';

  @override
  String semanticPackDownloading(String percent) {
    return 'يُنزَّل: $percent٪';
  }

  @override
  String get semanticPackVerifying => 'يُتحقَّق من الحزمة ويُثبَّت…';

  @override
  String get semanticPackFailed => 'تعذّر التنزيل. حاول مرة أخرى.';

  @override
  String get semanticPackLoading => 'يُجهَّز البحث بالمعنى…';

  @override
  String get semanticPackError =>
      'تعذّر فتح حزمة البحث بالمعنى، فالبحث الآن بالكلمات.';

  @override
  String get semanticResultsNote =>
      'نتائج تقريبية مرتبة بقرب المعنى. راجع الآية في موضعها وفي تفسيرها.';

  @override
  String verseLabel(String surah, String ayah) {
    return 'سورة $surah، الآية $ayah';
  }

  @override
  String pageLabelFull(String page, String surah) {
    return 'الصفحة $page، $surah';
  }

  @override
  String get markThisVerse => 'ضع علامة القراءة عند هذه الآية أو أزلها';

  @override
  String loadingPage(String page) {
    return 'تُحمَّل الصفحة $page';
  }

  @override
  String get clearSearch => 'مسح البحث';

  @override
  String get previousPageNumber => 'الصفحة السابقة';

  @override
  String get nextPageNumber => 'الصفحة التالية';

  @override
  String get showMenus => 'إظهار القوائم';

  @override
  String get hideMenus => 'إخفاء القوائم';

  @override
  String downloadSurah(String surah) {
    return 'تنزيل سورة $surah';
  }

  @override
  String retryDownloadSurah(String surah) {
    return 'أعد تنزيل سورة $surah';
  }

  @override
  String deleteSurahDownload(String surah) {
    return 'سورة $surah منزّلة. احذفها';
  }

  @override
  String downloadingSurah(String surah) {
    return 'تُنزَّل سورة $surah';
  }

  @override
  String verseCounter(String current, String total) {
    return 'الآية $current من $total';
  }

  @override
  String downloadPercentSpoken(String percent) {
    return 'اكتمل $percent٪ من التحميل';
  }

  @override
  String get hifzTitle => 'الحفظ';

  @override
  String get hifzTileNote => 'المراجعة والتسميع';

  @override
  String get hifzToday => 'مراجعة اليوم';

  @override
  String get hifzNothingDue => 'لا مراجعة مستحقة اليوم.';

  @override
  String get hifzNothingDueHint =>
      'سمّع صفحة أو ربعا أو سورة ثم قيّم تسميعك، فتدخل المراجعة المتباعدة.';

  @override
  String get hifzStartTest => 'ابدأ تسميعا';

  @override
  String get hifzMap => 'خريطة الحفظ';

  @override
  String get hifzMapHint =>
      'كل صفحة ملوّنة بقوة حفظها، ومعها علامة تقرأ دون ألوان.';

  @override
  String get hifzAllUnits => 'كل وحدات المراجعة';

  @override
  String get hifzDueToday => 'مستحقة اليوم';

  @override
  String hifzDueOn(String date) {
    return 'موعدها $date';
  }

  @override
  String hifzQuarter(String number) {
    return 'الربع $number';
  }

  @override
  String get hifzUnitPage => 'صفحة';

  @override
  String get hifzUnitQuarter => 'ربع';

  @override
  String get hifzUnitSurah => 'سورة';

  @override
  String get hifzChooseUnit => 'ماذا تسمّع؟';

  @override
  String hifzNumberRange(String max) {
    return 'الرقم، من ١ إلى $max';
  }

  @override
  String get hifzBegin => 'ابدأ';

  @override
  String get hifzRemove => 'احذف من المراجعة';

  @override
  String get revealNextWord => 'الكلمة التالية';

  @override
  String get revealNextVerse => 'الآية التالية';

  @override
  String get revealAll => 'الكل';

  @override
  String get endRecite => 'إنهاء التسميع';

  @override
  String get verseRemembered => 'حفظت';

  @override
  String get verseMissed => 'أخطأت';

  @override
  String testCounts(String remembered, String missed) {
    return 'حفظت $remembered · أخطأت $missed';
  }

  @override
  String get revealByLine =>
      'لا مواضع لكلمات هذه الآية في هذه الطبعة، فتُكشف سطرا سطرا.';

  @override
  String get gradeUnit => 'قيّم';

  @override
  String get gradeTitle => 'كيف كان تسميعك؟';

  @override
  String get gradeSuggested => 'الاختيار المقترح من نتائج الآيات';

  @override
  String get gradeAgain => 'أعِدها';

  @override
  String get gradeHard => 'صعبة';

  @override
  String get gradeGood => 'جيدة';

  @override
  String get gradeEasy => 'سهلة';

  @override
  String gradeSaved(String date) {
    return 'المراجعة القادمة: $date';
  }

  @override
  String get similarVerses => 'المتشابهات';

  @override
  String similarCount(String count) {
    return 'متشابهات ($count)';
  }

  @override
  String get similarThisVerse => 'الآية';

  @override
  String get similarFollowing => 'والآية بعدها';

  @override
  String get strengthNone => 'لم يُحفظ';

  @override
  String get strengthWeak => 'ضعيف';

  @override
  String get strengthFair => 'متوسط';

  @override
  String get strengthGood => 'جيد';

  @override
  String get strengthStrong => 'متقن';

  @override
  String get mapPages => 'الصفحات';

  @override
  String get mapSurahs => 'السور';

  @override
  String get mapZoomIn => 'تكبير';

  @override
  String get mapZoomOut => 'تصغير';

  @override
  String mapCell(String name, String strength) {
    return '$name: $strength';
  }

  @override
  String get tajweedColors => 'تلوين أحكام التجويد';

  @override
  String get tajweedColorsHint =>
      'تلوين الحروف التي يقع عليها الحكم فقط، بالألوان التي تختارها';

  @override
  String get tajweedLegend => 'مفتاح ألوان التجويد';

  @override
  String get tajweedRuleColors => 'لون كل حكم';

  @override
  String get tajweedNoColor => 'بلا لون';

  @override
  String get tajweedReset => 'إعادة الألوان الافتراضية';

  @override
  String tajweedPickColor(String rule) {
    return 'لون «$rule»';
  }

  @override
  String get tajweedSourceNote =>
      'مواضع الأحكام من بيانات quran-tajweed (Collin Fair، رخصة CC BY 4.0)، وهي مولّدة آليا ولم يراجعها متخصص بعد. وموضع الحرف داخل الكلمة تقديري، وفي الشمرلي حدود بعض الكلمات تقديرية أيضا.';

  @override
  String get tajweedLegendHint =>
      'اضغط مطولا على زر التلوين في الصفحة لعرض هذا المفتاح.';

  @override
  String get tajweedHueCrimson => 'أحمر داكن';

  @override
  String get tajweedHueRed => 'أحمر';

  @override
  String get tajweedHueOrange => 'برتقالي';

  @override
  String get tajweedHueGold => 'ذهبي';

  @override
  String get tajweedHueGreen => 'أخضر';

  @override
  String get tajweedHueLightGreen => 'أخضر فاتح';

  @override
  String get tajweedHueTeal => 'فيروزي';

  @override
  String get tajweedHueBlue => 'أزرق';

  @override
  String get tajweedHuePurple => 'بنفسجي';

  @override
  String get tajweedHuePink => 'وردي';

  @override
  String get tajweedHueGrey => 'رمادي';

  @override
  String get tajweedHueViolet => 'ليلكي';

  @override
  String get tajweedHueAmber => 'كهرماني';

  @override
  String get tajweedNoDataRiwaya =>
      'لا تلوين للتجويد في مصاحف الروايات (ورش وقالون والدوري وشعبة): لا توجد بعد بيانات أحكام موثوقة لهذه الروايات، ولا نضع أحكاما بلا مصدر. التلوين يعمل في مصاحف حفص.';

  @override
  String get tajweedHamzatWasl => 'همزة الوصل';

  @override
  String get tajweedLamShamsiyyah => 'اللام الشمسية';

  @override
  String get tajweedSilent => 'الحروف التي لا تُنطق';

  @override
  String get tajweedMadd2 => 'المد الطبيعي (حركتان)';

  @override
  String get tajweedMadd246 => 'المد العارض واللين (2 أو 4 أو 6 حركات)';

  @override
  String get tajweedMaddMuttasil => 'المد المتصل (4 أو 5 حركات)';

  @override
  String get tajweedMaddMunfasil => 'المد المنفصل (4 أو 5 حركات)';

  @override
  String get tajweedMadd6 => 'المد اللازم (6 حركات)';

  @override
  String get tajweedGhunnah => 'الغنة';

  @override
  String get tajweedIkhfa => 'الإخفاء';

  @override
  String get tajweedIkhfaShafawi => 'الإخفاء الشفوي';

  @override
  String get tajweedIqlab => 'الإقلاب';

  @override
  String get tajweedIdghaamGhunnah => 'الإدغام بغنة';

  @override
  String get tajweedIdghaamNoGhunnah => 'الإدغام بلا غنة';

  @override
  String get tajweedIdghaamShafawi => 'الإدغام الشفوي';

  @override
  String get tajweedIdghaamMutajanisayn => 'إدغام المتجانسين';

  @override
  String get tajweedIdghaamMutaqaribayn => 'إدغام المتقاربين';

  @override
  String get tajweedQalqalah => 'القلقلة';

  @override
  String get editionWarsh => 'مصحف المدينة برواية ورش عن نافع';

  @override
  String get editionQalun => 'مصحف المدينة برواية قالون عن نافع';

  @override
  String get editionDouri => 'مصحف المدينة برواية الدوري عن أبي عمرو';

  @override
  String get editionShubah => 'مصحف المدينة برواية شعبة عن عاصم';

  @override
  String get riwayaWarsh => 'رواية ورش عن نافع';

  @override
  String get riwayaQalun => 'رواية قالون عن نافع';

  @override
  String get riwayaDouri => 'رواية الدوري عن أبي عمرو';

  @override
  String get riwayaShubah => 'رواية شعبة عن عاصم';

  @override
  String get riwayatTitle => 'مصاحف الروايات';

  @override
  String get riwayaEditionDesc =>
      'صفحات مصحف المدينة لهذه الرواية من مجمع الملك فهد، بعدّ آياتها وترقيمها. التفسير والترجمة والفواصل تُربط بالآيات المقابلة في عدّ حفص.';

  @override
  String get riwayaGaps =>
      'في مصاحف الروايات: لا تظليل للكلمة أثناء التلاوة ولا تلوين للفظ الجلالة، ولا يظهر الحزب وأرباعه في الإطار (الصفحة نفسها تحمل علاماتها المطبوعة).';

  @override
  String riwayaTafsirNote(
    String ayah,
    String surah,
    String riwaya,
    String hafs,
  ) {
    return 'الآية $ayah من سورة $surah في $riwaya يقابلها في عدّ حفص: $hafs. التفسير والترجمة ونص الآية أدناه بعدّ حفص وروايته.';
  }

  @override
  String get riwayaNoHafs => 'لا تقابلها آية في عدّ حفص';

  @override
  String hafsVerseOne(String number) {
    return 'الآية $number';
  }

  @override
  String hafsVerseRange(String from, String to) {
    return 'الآيات $from إلى $to';
  }

  @override
  String riwayaVerseText(String riwaya) {
    return 'نص الآية في $riwaya';
  }

  @override
  String riwayaRecitersNote(String riwaya) {
    return 'تلاوات $riwaya';
  }
}
