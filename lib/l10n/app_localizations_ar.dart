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
  String get appearanceTitle => 'الشكل';

  @override
  String get styleLabel => 'الشكل';

  @override
  String get modeLabel => 'وضع الإضاءة';

  @override
  String get modeSystem => 'تلقائي';

  @override
  String get modeSystemHint => 'يتبع إعداد الجهاز';

  @override
  String get modeLight => 'فاتح';

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
  String get previewLabel => 'معاينة';

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
  String get markerTintLabel => 'لون الفواصل';

  @override
  String get markerTintNone => 'بلا لون';

  @override
  String get reciteMode => 'وضع التسميع';

  @override
  String get revealNextVerse => 'الآية التالية';

  @override
  String get revealAll => 'الكل';

  @override
  String get endRecite => 'إنهاء التسميع';

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
  String get mujawwad => 'مجود';

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
  String get allEditionsQueued =>
      'بدأ تحميل كل المصاحف. يمكنك متابعة القراءة أو الخروج من التطبيق.';

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
  String get homeTitle => 'الرئيسية';

  @override
  String get frameDesignLabel => 'إطار الصفحة';

  @override
  String get frameByStyle => 'حسب الشكل';

  @override
  String get frameZakhrafa => 'زخرفة';

  @override
  String get framePlain => 'بسيط';
}
