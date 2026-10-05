import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'تبيان'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In ar, this message translates to:
  /// **'تفسير وتلاوة وحفظ القرآن'**
  String get appTagline;

  /// No description provided for @homeComingTitle.
  ///
  /// In ar, this message translates to:
  /// **'قيد البناء'**
  String get homeComingTitle;

  /// No description provided for @homeComingBody.
  ///
  /// In ar, this message translates to:
  /// **'هذه أول نسخة من تبيان: فيها الأشكال والإعدادات فقط. المصحف والتفسير والاستماع تأتي في المراحل القادمة إن شاء الله.'**
  String get homeComingBody;

  /// No description provided for @sectionMushaf.
  ///
  /// In ar, this message translates to:
  /// **'المصحف'**
  String get sectionMushaf;

  /// No description provided for @sectionTafsir.
  ///
  /// In ar, this message translates to:
  /// **'التفسير'**
  String get sectionTafsir;

  /// No description provided for @sectionListen.
  ///
  /// In ar, this message translates to:
  /// **'الاستماع'**
  String get sectionListen;

  /// No description provided for @sectionHifz.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ'**
  String get sectionHifz;

  /// No description provided for @sectionKhatma.
  ///
  /// In ar, this message translates to:
  /// **'الختمة'**
  String get sectionKhatma;

  /// No description provided for @sectionSearch.
  ///
  /// In ar, this message translates to:
  /// **'البحث'**
  String get sectionSearch;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @openSettings.
  ///
  /// In ar, this message translates to:
  /// **'فتح الإعدادات'**
  String get openSettings;

  /// No description provided for @appearanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'شكل المصحف'**
  String get appearanceTitle;

  /// No description provided for @modeLabel.
  ///
  /// In ar, this message translates to:
  /// **'وضع الإضاءة'**
  String get modeLabel;

  /// No description provided for @modeSystem.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get modeSystem;

  /// No description provided for @modeSystemHint.
  ///
  /// In ar, this message translates to:
  /// **'يتبع إعداد الجهاز'**
  String get modeSystemHint;

  /// No description provided for @modeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get modeLight;

  /// No description provided for @modeWhite.
  ///
  /// In ar, this message translates to:
  /// **'أبيض زاهي'**
  String get modeWhite;

  /// No description provided for @modeNight.
  ///
  /// In ar, this message translates to:
  /// **'ليلي'**
  String get modeNight;

  /// No description provided for @modeBlack.
  ///
  /// In ar, this message translates to:
  /// **'أسود'**
  String get modeBlack;

  /// No description provided for @uiFontLabel.
  ///
  /// In ar, this message translates to:
  /// **'خط الواجهة'**
  String get uiFontLabel;

  /// No description provided for @uiFontPlex.
  ///
  /// In ar, this message translates to:
  /// **'آي بي إم بلكس عربي'**
  String get uiFontPlex;

  /// No description provided for @uiFontKfgqpcAn.
  ///
  /// In ar, this message translates to:
  /// **'خط المجمع (AN)'**
  String get uiFontKfgqpcAn;

  /// No description provided for @uiFontChanga.
  ///
  /// In ar, this message translates to:
  /// **'Changa'**
  String get uiFontChanga;

  /// No description provided for @languageLabel.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get languageLabel;

  /// No description provided for @languageSystem.
  ///
  /// In ar, this message translates to:
  /// **'لغة الجهاز'**
  String get languageSystem;

  /// No description provided for @languageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @privacyTitle.
  ///
  /// In ar, this message translates to:
  /// **'الخصوصية'**
  String get privacyTitle;

  /// No description provided for @crashReportsLabel.
  ///
  /// In ar, this message translates to:
  /// **'إرسال تقارير الأعطال'**
  String get crashReportsLabel;

  /// No description provided for @crashReportsHint.
  ///
  /// In ar, this message translates to:
  /// **'يرسل تفاصيل تقنية عن الأعطال فقط، بلا أي بيانات شخصية. متوقف حتى توافق.'**
  String get crashReportsHint;

  /// No description provided for @aboutTitle.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In ar, this message translates to:
  /// **'تبيان تطبيق مجاني غير ربحي، بلا إعلانات ولا مشتريات، وشيفرته مفتوحة. كل نص فيه من مصدر موثق مذكور بجانبه.'**
  String get aboutBody;

  /// No description provided for @versionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {version}'**
  String versionLabel(String version);

  /// No description provided for @selected.
  ///
  /// In ar, this message translates to:
  /// **'محدد'**
  String get selected;

  /// No description provided for @onbLanguageTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر اللغة\nChoose your language'**
  String get onbLanguageTitle;

  /// No description provided for @onbStyleTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر الشكل الذي يريح عينك'**
  String get onbStyleTitle;

  /// No description provided for @onbStyleHint.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك تغييره في أي وقت من الإعدادات'**
  String get onbStyleHint;

  /// No description provided for @continueLabel.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get continueLabel;

  /// No description provided for @skipLabel.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get skipLabel;

  /// No description provided for @onbEditionTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر طبعة المصحف'**
  String get onbEditionTitle;

  /// No description provided for @editionNew.
  ///
  /// In ar, this message translates to:
  /// **'مصحف المدينة: الطبعة الحديثة'**
  String get editionNew;

  /// No description provided for @editionNewDesc.
  ///
  /// In ar, this message translates to:
  /// **'طبعة 1441هـ من مجمع الملك فهد، مع تظليل الآية أثناء التلاوة.'**
  String get editionNewDesc;

  /// No description provided for @editionOld.
  ///
  /// In ar, this message translates to:
  /// **'مصحف المدينة: الطبعة القديمة'**
  String get editionOld;

  /// No description provided for @editionOldDesc.
  ///
  /// In ar, this message translates to:
  /// **'طبعة 1405هـ المشهورة في التطبيقات القديمة، مع تظليل الكلمة.'**
  String get editionOldDesc;

  /// No description provided for @editionShamarly.
  ///
  /// In ar, this message translates to:
  /// **'مصحف الشمرلي (الطبعة المصرية)'**
  String get editionShamarly;

  /// No description provided for @editionShamarlyDesc.
  ///
  /// In ar, this message translates to:
  /// **'طبعة الشمرلي المصرية المعروفة، 522 صفحة، مع تظليل الآية وتظليل الكلمة في كثير من الآيات.'**
  String get editionShamarlyDesc;

  /// No description provided for @defaultTag.
  ///
  /// In ar, this message translates to:
  /// **'الافتراضية'**
  String get defaultTag;

  /// No description provided for @pagesDownloadNote.
  ///
  /// In ar, this message translates to:
  /// **'صفحات هذا المصحف تُحمّل مرة واحدة (نحو {size} ميجا)، ثم تعمل دون اتصال. وحتى يكتمل التحميل تقرأ في مصحف المدينة (الطبعة الحديثة) المدمج في التطبيق.'**
  String pagesDownloadNote(String size);

  /// No description provided for @downloadTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحميل صفحات المصحف'**
  String get downloadTitle;

  /// No description provided for @downloadStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ التحميل'**
  String get downloadStart;

  /// No description provided for @downloadPause.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get downloadPause;

  /// No description provided for @downloadResume.
  ///
  /// In ar, this message translates to:
  /// **'متابعة التحميل'**
  String get downloadResume;

  /// No description provided for @downloadRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get downloadRetry;

  /// No description provided for @downloadVerifying.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحقق من سلامة الملفات…'**
  String get downloadVerifying;

  /// No description provided for @downloadInstalling.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تجهيز الصفحات…'**
  String get downloadInstalling;

  /// No description provided for @downloadDone.
  ///
  /// In ar, this message translates to:
  /// **'اكتمل التحميل'**
  String get downloadDone;

  /// No description provided for @downloadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التحميل: {error}'**
  String downloadFailed(String error);

  /// No description provided for @downloadProgress.
  ///
  /// In ar, this message translates to:
  /// **'{received} من {total} ميجا'**
  String downloadProgress(String received, String total);

  /// No description provided for @downloadWifiHint.
  ///
  /// In ar, this message translates to:
  /// **'يكمل التحميل من حيث توقف إذا انقطع الاتصال. يُفضّل الاتصال بشبكة Wi-Fi.'**
  String get downloadWifiHint;

  /// No description provided for @pagesCredit.
  ///
  /// In ar, this message translates to:
  /// **'صفحات مصحف المدينة من مجمع الملك فهد لطباعة المصحف الشريف.'**
  String get pagesCredit;

  /// No description provided for @pagesCreditOld.
  ///
  /// In ar, this message translates to:
  /// **'صفحات الطبعة القديمة (1405هـ) من مجمع الملك فهد لطباعة المصحف الشريف، ومصدرها موقع quran.com، وتُحمّل من خادم تبيان.'**
  String get pagesCreditOld;

  /// No description provided for @pagesCreditShamarly.
  ///
  /// In ar, this message translates to:
  /// **'مصحف الشمرلي بخط محمد سعد إبراهيم الشهير بحداد، والصفحات من أرشيف الإنترنت (archive.org)، وتُحمّل من خادم تبيان.'**
  String get pagesCreditShamarly;

  /// No description provided for @editionLabel.
  ///
  /// In ar, this message translates to:
  /// **'طبعة المصحف'**
  String get editionLabel;

  /// No description provided for @viewPage.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة'**
  String get viewPage;

  /// No description provided for @viewModeLabel.
  ///
  /// In ar, this message translates to:
  /// **'طريقة العرض'**
  String get viewModeLabel;

  /// No description provided for @indexTitle.
  ///
  /// In ar, this message translates to:
  /// **'الفهرس'**
  String get indexTitle;

  /// No description provided for @fawasilTitle.
  ///
  /// In ar, this message translates to:
  /// **'الفواصل'**
  String get fawasilTitle;

  /// No description provided for @aboutMushafTitle.
  ///
  /// In ar, this message translates to:
  /// **'عن هذا المصحف'**
  String get aboutMushafTitle;

  /// No description provided for @juzPage.
  ///
  /// In ar, this message translates to:
  /// **'الجزء {juz} · الصفحة {page}'**
  String juzPage(String juz, String page);

  /// No description provided for @surahWord.
  ///
  /// In ar, this message translates to:
  /// **'سورة {name}'**
  String surahWord(String name);

  /// No description provided for @verseSelected.
  ///
  /// In ar, this message translates to:
  /// **'الآية {number} محددة'**
  String verseSelected(String number);

  /// No description provided for @tapVerseHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط أي آية لتحديدها'**
  String get tapVerseHint;

  /// No description provided for @pageOf.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة {page}'**
  String pageOf(String page);

  /// No description provided for @indexSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'اسم السورة، أو رقم صفحة، أو ٢:٢٥٥'**
  String get indexSearchHint;

  /// No description provided for @tabSurahs.
  ///
  /// In ar, this message translates to:
  /// **'السور'**
  String get tabSurahs;

  /// No description provided for @tabJuz.
  ///
  /// In ar, this message translates to:
  /// **'الأجزاء'**
  String get tabJuz;

  /// No description provided for @tabPages.
  ///
  /// In ar, this message translates to:
  /// **'الصفحات'**
  String get tabPages;

  /// No description provided for @meccan.
  ///
  /// In ar, this message translates to:
  /// **'مكية'**
  String get meccan;

  /// No description provided for @medinan.
  ///
  /// In ar, this message translates to:
  /// **'مدنية'**
  String get medinan;

  /// No description provided for @ayahCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} آية'**
  String ayahCount(String count);

  /// No description provided for @juzLabel.
  ///
  /// In ar, this message translates to:
  /// **'الجزء {number}'**
  String juzLabel(String number);

  /// No description provided for @juzStartsAt.
  ///
  /// In ar, this message translates to:
  /// **'يبدأ من {surah} {ayah}'**
  String juzStartsAt(String surah, String ayah);

  /// No description provided for @pageShort.
  ///
  /// In ar, this message translates to:
  /// **'ص {page}'**
  String pageShort(String page);

  /// No description provided for @lastPosition.
  ///
  /// In ar, this message translates to:
  /// **'آخر موضع قراءة، يُحفظ تلقائيا'**
  String get lastPosition;

  /// No description provided for @yourFawasil.
  ///
  /// In ar, this message translates to:
  /// **'فواصلك'**
  String get yourFawasil;

  /// No description provided for @fasilNew.
  ///
  /// In ar, this message translates to:
  /// **'فاصل جديد'**
  String get fasilNew;

  /// No description provided for @fasilName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الفاصل'**
  String get fasilName;

  /// No description provided for @fasilSaveHere.
  ///
  /// In ar, this message translates to:
  /// **'احفظ الموضع الحالي في فاصل'**
  String get fasilSaveHere;

  /// No description provided for @fasilLastAt.
  ///
  /// In ar, this message translates to:
  /// **'آخر موضع: {surah} {ayah} · الصفحة {page}'**
  String fasilLastAt(String surah, String ayah, String page);

  /// No description provided for @fasilHint.
  ///
  /// In ar, this message translates to:
  /// **'لكل فاصل لون واسم، ويتحرك إلى آخر موضع قرأت عنده.'**
  String get fasilHint;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @saved.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ'**
  String get saved;

  /// No description provided for @noFawasil.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فواصل بعد'**
  String get noFawasil;

  /// No description provided for @readingTitle.
  ///
  /// In ar, this message translates to:
  /// **'القراءة'**
  String get readingTitle;

  /// No description provided for @keepScreenOn.
  ///
  /// In ar, this message translates to:
  /// **'إبقاء الشاشة مضاءة أثناء القراءة'**
  String get keepScreenOn;

  /// No description provided for @aboutMushafIntro.
  ///
  /// In ar, this message translates to:
  /// **'كل نص في تبيان منقول من مصدر موثق، ولا يُعدَّل بأيدينا. وهذه مصادر المصحف في التطبيق:'**
  String get aboutMushafIntro;

  /// No description provided for @licenseLabel.
  ///
  /// In ar, this message translates to:
  /// **'الرخصة: {license}'**
  String licenseLabel(String license);

  /// No description provided for @versionShort.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار: {version}'**
  String versionShort(String version);

  /// No description provided for @reviewNotesTitle.
  ///
  /// In ar, this message translates to:
  /// **'مسائل معروضة على المراجعة'**
  String get reviewNotesTitle;

  /// No description provided for @reviewNotesBody.
  ///
  /// In ar, this message translates to:
  /// **'{count} مواضع يختلف فيها مصدرا النص (حدود جزأين، وأربعة مواضع في الرسم) معروضة على مراجع متخصص، ويتبع التطبيق نص تنزيل حتى يصدر القرار.'**
  String reviewNotesBody(String count);

  /// No description provided for @mushafOpen.
  ///
  /// In ar, this message translates to:
  /// **'افتح المصحف'**
  String get mushafOpen;

  /// No description provided for @loadingLabel.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل…'**
  String get loadingLabel;

  /// No description provided for @hizbLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحزب {number}'**
  String hizbLabel(String number);

  /// No description provided for @catchwordLabel.
  ///
  /// In ar, this message translates to:
  /// **'الكلمة الأولى في الصفحة التالية: {word}'**
  String catchwordLabel(String word);

  /// No description provided for @catchwordImageLabel.
  ///
  /// In ar, this message translates to:
  /// **'الكلمة الأولى في الصفحة التالية'**
  String get catchwordImageLabel;

  /// No description provided for @tabHizb.
  ///
  /// In ar, this message translates to:
  /// **'الأحزاب'**
  String get tabHizb;

  /// No description provided for @goToPage.
  ///
  /// In ar, this message translates to:
  /// **'انتقال إلى صفحة'**
  String get goToPage;

  /// No description provided for @goToPageHint.
  ///
  /// In ar, this message translates to:
  /// **'رقم الصفحة من ١ إلى {max}'**
  String goToPageHint(String max);

  /// No description provided for @goLabel.
  ///
  /// In ar, this message translates to:
  /// **'انتقال'**
  String get goLabel;

  /// No description provided for @hizbStartsAt.
  ///
  /// In ar, this message translates to:
  /// **'يبدأ من {surah} {ayah}'**
  String hizbStartsAt(String surah, String ayah);

  /// No description provided for @selectionStart.
  ///
  /// In ar, this message translates to:
  /// **'بداية التحديد'**
  String get selectionStart;

  /// No description provided for @selectionEnd.
  ///
  /// In ar, this message translates to:
  /// **'نهاية التحديد'**
  String get selectionEnd;

  /// No description provided for @servicesTitle.
  ///
  /// In ar, this message translates to:
  /// **'خدمات الآيات'**
  String get servicesTitle;

  /// No description provided for @markReading.
  ///
  /// In ar, this message translates to:
  /// **'قراءة'**
  String get markReading;

  /// No description provided for @markReview.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة'**
  String get markReview;

  /// No description provided for @markHifz.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get markHifz;

  /// No description provided for @markTadabbur.
  ///
  /// In ar, this message translates to:
  /// **'تدبر'**
  String get markTadabbur;

  /// No description provided for @autoFasil.
  ///
  /// In ar, this message translates to:
  /// **'فاصل تلقائي عند {surah} {ayah}'**
  String autoFasil(String surah, String ayah);

  /// No description provided for @markMoved.
  ///
  /// In ar, this message translates to:
  /// **'{mark}: {surah} {ayah}'**
  String markMoved(String mark, String surah, String ayah);

  /// No description provided for @verseRange.
  ///
  /// In ar, this message translates to:
  /// **'{surah} {from}–{to}'**
  String verseRange(String surah, String from, String to);

  /// No description provided for @versesCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} آيات'**
  String versesCount(String count);

  /// No description provided for @twoVerses.
  ///
  /// In ar, this message translates to:
  /// **'آيتان'**
  String get twoVerses;

  /// No description provided for @markerStyleLabel.
  ///
  /// In ar, this message translates to:
  /// **'شكل فواصل الآيات'**
  String get markerStyleLabel;

  /// No description provided for @markerTraditional.
  ///
  /// In ar, this message translates to:
  /// **'الفاصل التقليدي'**
  String get markerTraditional;

  /// No description provided for @markerRosette.
  ///
  /// In ar, this message translates to:
  /// **'وردة'**
  String get markerRosette;

  /// No description provided for @markerTheme.
  ///
  /// In ar, this message translates to:
  /// **'حسب الثيم'**
  String get markerTheme;

  /// No description provided for @markerThemeHint.
  ///
  /// In ar, this message translates to:
  /// **'«حسب الثيم» يرسم فاصل الثيم نفسه، وفي «تبيان» وردتها.'**
  String get markerThemeHint;

  /// No description provided for @themeLabel.
  ///
  /// In ar, this message translates to:
  /// **'الثيم'**
  String get themeLabel;

  /// No description provided for @markerTintLabel.
  ///
  /// In ar, this message translates to:
  /// **'لون الفواصل'**
  String get markerTintLabel;

  /// No description provided for @markerTintNone.
  ///
  /// In ar, this message translates to:
  /// **'بلا لون'**
  String get markerTintNone;

  /// No description provided for @reciteMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع التسميع'**
  String get reciteMode;

  /// No description provided for @autoScroll.
  ///
  /// In ar, this message translates to:
  /// **'التمرير التلقائي'**
  String get autoScroll;

  /// No description provided for @resume.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get resume;

  /// No description provided for @pause.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get pause;

  /// No description provided for @slower.
  ///
  /// In ar, this message translates to:
  /// **'أبطأ'**
  String get slower;

  /// No description provided for @faster.
  ///
  /// In ar, this message translates to:
  /// **'أسرع'**
  String get faster;

  /// No description provided for @stopAutoScroll.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف التمرير'**
  String get stopAutoScroll;

  /// No description provided for @speedLabel.
  ///
  /// In ar, this message translates to:
  /// **'السرعة {speed}'**
  String speedLabel(String speed);

  /// No description provided for @surahBannerTitle.
  ///
  /// In ar, this message translates to:
  /// **'({number}) سورة {name} · {type}'**
  String surahBannerTitle(String number, String name, String type);

  /// No description provided for @surahBannerInfo.
  ///
  /// In ar, this message translates to:
  /// **'آياتها {count} · ترتيبها في النزول {order} · نزلت بعد {after}'**
  String surahBannerInfo(String count, String order, String after);

  /// No description provided for @surahBannerInfoFirst.
  ///
  /// In ar, this message translates to:
  /// **'آياتها {count} · ترتيبها في النزول {order}'**
  String surahBannerInfoFirst(String count, String order);

  /// No description provided for @quarterHizb.
  ///
  /// In ar, this message translates to:
  /// **'ربع الحزب {number}'**
  String quarterHizb(String number);

  /// No description provided for @halfHizb.
  ///
  /// In ar, this message translates to:
  /// **'نصف الحزب {number}'**
  String halfHizb(String number);

  /// No description provided for @threeQuartersHizb.
  ///
  /// In ar, this message translates to:
  /// **'ثلاثة أرباع الحزب {number}'**
  String threeQuartersHizb(String number);

  /// No description provided for @coverTitle.
  ///
  /// In ar, this message translates to:
  /// **'القرآن الكريم'**
  String get coverTitle;

  /// No description provided for @coverSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'بالرسم العثماني'**
  String get coverSubtitle;

  /// No description provided for @riwayaHafs.
  ///
  /// In ar, this message translates to:
  /// **'رواية حفص عن عاصم'**
  String get riwayaHafs;

  /// No description provided for @openingInfo.
  ///
  /// In ar, this message translates to:
  /// **'{type} · آياتها {count} · ترتيبها {number}'**
  String openingInfo(String type, String count, String number);

  /// No description provided for @revealedOrder.
  ///
  /// In ar, this message translates to:
  /// **'ترتيبها في النزول {order}'**
  String revealedOrder(String order);

  /// No description provided for @revealedAfter.
  ///
  /// In ar, this message translates to:
  /// **'نزلت بعد {after}'**
  String revealedAfter(String after);

  /// No description provided for @multiSelect.
  ///
  /// In ar, this message translates to:
  /// **'تحديد عدة آيات'**
  String get multiSelect;

  /// No description provided for @multiSelectHint.
  ///
  /// In ar, this message translates to:
  /// **'اسحب المقبضين، أو اقلب الصفحة واضغط آية لتمديد التحديد إليها'**
  String get multiSelectHint;

  /// No description provided for @doneLabel.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get doneLabel;

  /// No description provided for @markRemoved.
  ///
  /// In ar, this message translates to:
  /// **'أُزيل الفاصل'**
  String get markRemoved;

  /// No description provided for @tabMarks.
  ///
  /// In ar, this message translates to:
  /// **'فواصل القراءة'**
  String get tabMarks;

  /// No description provided for @noMarks.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فواصل بعد. اضغط على فاصل أي آية لتعليمها.'**
  String get noMarks;

  /// No description provided for @highlightDivineNames.
  ///
  /// In ar, this message translates to:
  /// **'تمييز لفظ الجلالة'**
  String get highlightDivineNames;

  /// No description provided for @highlightDivineNamesHint.
  ///
  /// In ar, this message translates to:
  /// **'تلوين «الله» و«رب» و«ربنا» في صفحات المصحف'**
  String get highlightDivineNamesHint;

  /// No description provided for @tafsirTitle.
  ///
  /// In ar, this message translates to:
  /// **'التفسير والترجمة'**
  String get tafsirTitle;

  /// No description provided for @tafsirSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات التفسير'**
  String get tafsirSettings;

  /// No description provided for @tafsirFontLabel.
  ///
  /// In ar, this message translates to:
  /// **'خط التفسير'**
  String get tafsirFontLabel;

  /// No description provided for @tafsirFontNaskh.
  ///
  /// In ar, this message translates to:
  /// **'نسخ عثمان طه'**
  String get tafsirFontNaskh;

  /// No description provided for @tafsirFontInterface.
  ///
  /// In ar, this message translates to:
  /// **'خط الواجهة'**
  String get tafsirFontInterface;

  /// No description provided for @tafsirTextSize.
  ///
  /// In ar, this message translates to:
  /// **'حجم النص'**
  String get tafsirTextSize;

  /// No description provided for @tafsirShown.
  ///
  /// In ar, this message translates to:
  /// **'النصوص المعروضة'**
  String get tafsirShown;

  /// No description provided for @tafsirNoneShown.
  ///
  /// In ar, this message translates to:
  /// **'كل النصوص مخفية. اختر نصا من إعدادات التفسير.'**
  String get tafsirNoneShown;

  /// No description provided for @tafsirFootnotes.
  ///
  /// In ar, this message translates to:
  /// **'الحواشي'**
  String get tafsirFootnotes;

  /// No description provided for @previousVerse.
  ///
  /// In ar, this message translates to:
  /// **'الآية السابقة'**
  String get previousVerse;

  /// No description provided for @nextVerse.
  ///
  /// In ar, this message translates to:
  /// **'الآية التالية'**
  String get nextVerse;

  /// No description provided for @sourceVersion.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {version}'**
  String sourceVersion(String version);

  /// No description provided for @sourceRetrieved.
  ///
  /// In ar, this message translates to:
  /// **'نسخة {date}'**
  String sourceRetrieved(String date);

  /// No description provided for @tafsirKashida.
  ///
  /// In ar, this message translates to:
  /// **'الشد بالكشيدة (تجربة)'**
  String get tafsirKashida;

  /// No description provided for @tafsirKashidaHint.
  ///
  /// In ar, this message translates to:
  /// **'ضبط سطور التفسير بمدّ الحروف بدل توسيع المسافات. لا يمس الكلمات القرآنية بين الأقواس، والنسخ يأخذ النص الأصلي'**
  String get tafsirKashidaHint;

  /// No description provided for @copyText.
  ///
  /// In ar, this message translates to:
  /// **'نسخ النص'**
  String get copyText;

  /// No description provided for @copied.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get copied;

  /// No description provided for @listen.
  ///
  /// In ar, this message translates to:
  /// **'استماع'**
  String get listen;

  /// No description provided for @reciterLabel.
  ///
  /// In ar, this message translates to:
  /// **'القارئ'**
  String get reciterLabel;

  /// No description provided for @murattal.
  ///
  /// In ar, this message translates to:
  /// **'مرتل'**
  String get murattal;

  /// No description provided for @repeatLabel.
  ///
  /// In ar, this message translates to:
  /// **'عدد مرات التكرار'**
  String get repeatLabel;

  /// No description provided for @repeatForever.
  ///
  /// In ar, this message translates to:
  /// **'بلا توقف'**
  String get repeatForever;

  /// No description provided for @repeatTimes.
  ///
  /// In ar, this message translates to:
  /// **'×{n}'**
  String repeatTimes(String n);

  /// No description provided for @silenceLabel.
  ///
  /// In ar, this message translates to:
  /// **'سكوت بين كل تكرار والتالي (للترديد خلف القارئ)'**
  String get silenceLabel;

  /// No description provided for @silenceNone.
  ///
  /// In ar, this message translates to:
  /// **'بلا'**
  String get silenceNone;

  /// No description provided for @seconds.
  ///
  /// In ar, this message translates to:
  /// **'{n} ث'**
  String seconds(String n);

  /// No description provided for @repeatVerse.
  ///
  /// In ar, this message translates to:
  /// **'كرر هذه الآية'**
  String get repeatVerse;

  /// No description provided for @playToEnd.
  ///
  /// In ar, this message translates to:
  /// **'أكمل السورة'**
  String get playToEnd;

  /// No description provided for @sleepLabel.
  ///
  /// In ar, this message translates to:
  /// **'مؤقت النوم'**
  String get sleepLabel;

  /// No description provided for @sleepOff.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get sleepOff;

  /// No description provided for @minutes.
  ///
  /// In ar, this message translates to:
  /// **'{n} د'**
  String minutes(String n);

  /// No description provided for @sleepSurahEnd.
  ///
  /// In ar, this message translates to:
  /// **'نهاية السورة'**
  String get sleepSurahEnd;

  /// No description provided for @followRecitation.
  ///
  /// In ar, this message translates to:
  /// **'تقليب الصفحات مع التلاوة'**
  String get followRecitation;

  /// No description provided for @audioDownloads.
  ///
  /// In ar, this message translates to:
  /// **'تحميل التلاوات'**
  String get audioDownloads;

  /// No description provided for @downloadAll.
  ///
  /// In ar, this message translates to:
  /// **'تحميل الكل'**
  String get downloadAll;

  /// No description provided for @audioDownloaded.
  ///
  /// In ar, this message translates to:
  /// **'محملة على الجهاز'**
  String get audioDownloaded;

  /// No description provided for @noTiming.
  ///
  /// In ar, this message translates to:
  /// **'هذه التلاوة بلا توقيت للآيات في هذه السورة: تُسمع كاملة بلا تظليل ولا تكرار آية'**
  String get noTiming;

  /// No description provided for @playerError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تشغيل التلاوة. تأكد من الاتصال بالإنترنت أو حمّل السورة.'**
  String get playerError;

  /// No description provided for @playerSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الاستماع'**
  String get playerSettings;

  /// No description provided for @stopListening.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف الاستماع'**
  String get stopListening;

  /// No description provided for @repeatProgress.
  ///
  /// In ar, this message translates to:
  /// **'التكرار {done} من {total}'**
  String repeatProgress(String done, String total);

  /// No description provided for @audioCredit.
  ///
  /// In ar, this message translates to:
  /// **'التلاوات وتوقيت الآيات: mp3quran.net'**
  String get audioCredit;

  /// No description provided for @tafsirAudioListen.
  ///
  /// In ar, this message translates to:
  /// **'استمع للتفسير'**
  String get tafsirAudioListen;

  /// No description provided for @tafsirAudioListenSurah.
  ///
  /// In ar, this message translates to:
  /// **'استمع لتفسير السورة'**
  String get tafsirAudioListenSurah;

  /// No description provided for @translationAudioAfterVerse.
  ///
  /// In ar, this message translates to:
  /// **'الترجمة المسموعة بعد كل آية'**
  String get translationAudioAfterVerse;

  /// No description provided for @translationAudioHint.
  ///
  /// In ar, this message translates to:
  /// **'تُسمع ترجمة كل آية بعد تلاوتها، حين تتوالى الآيات بلا تكرار'**
  String get translationAudioHint;

  /// No description provided for @clipTranslationOf.
  ///
  /// In ar, this message translates to:
  /// **'ترجمة الآية {ayah}'**
  String clipTranslationOf(String ayah);

  /// No description provided for @englishTafsirOffer.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل التفسير الإنجليزي: {title}'**
  String englishTafsirOffer(String title);

  /// No description provided for @touchReading.
  ///
  /// In ar, this message translates to:
  /// **'القراءة اللمسية'**
  String get touchReading;

  /// No description provided for @touchReadingOn.
  ///
  /// In ar, this message translates to:
  /// **'القراءة اللمسية: المس الآية التي تقرؤها'**
  String get touchReadingOn;

  /// No description provided for @editionOnDevice.
  ///
  /// In ar, this message translates to:
  /// **'على الجهاز'**
  String get editionOnDevice;

  /// No description provided for @editionNotDownloaded.
  ///
  /// In ar, this message translates to:
  /// **'غير محمّل · {size} ميجا'**
  String editionNotDownloaded(String size);

  /// No description provided for @downloadAllEditions.
  ///
  /// In ar, this message translates to:
  /// **'تحميل كل المصاحف ({size} ميجا)'**
  String downloadAllEditions(String size);

  /// No description provided for @downloadInBackgroundNote.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك الخروج من التطبيق: التحميل يكمل في الخلفية، ويصلك إشعار عند انتهائه.'**
  String get downloadInBackgroundNote;

  /// No description provided for @notifDownloading.
  ///
  /// In ar, this message translates to:
  /// **'تحميل صفحات المصحف'**
  String get notifDownloading;

  /// No description provided for @notifComplete.
  ///
  /// In ar, this message translates to:
  /// **'اكتمل تحميل المصحف'**
  String get notifComplete;

  /// No description provided for @notifFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل المصحف'**
  String get notifFailed;

  /// No description provided for @notifPaused.
  ///
  /// In ar, this message translates to:
  /// **'التحميل متوقف مؤقتا'**
  String get notifPaused;

  /// No description provided for @readInMadinaWhileDownloading.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ في مصحف المدينة (الطبعة الحديثة) حتى يكتمل التحميل'**
  String get readInMadinaWhileDownloading;

  /// No description provided for @downloadingBanner.
  ///
  /// In ar, this message translates to:
  /// **'يُحمَّل {name}: {percent}٪. تقرأ الآن في مصحف المدينة (الطبعة الحديثة)'**
  String downloadingBanner(String name, String percent);

  /// No description provided for @versePauseLabel.
  ///
  /// In ar, this message translates to:
  /// **'السكتة بين الآيات'**
  String get versePauseLabel;

  /// No description provided for @versePauseAsRecorded.
  ///
  /// In ar, this message translates to:
  /// **'كما سُجّلت'**
  String get versePauseAsRecorded;

  /// No description provided for @versePauseSecond.
  ///
  /// In ar, this message translates to:
  /// **'ثانية'**
  String get versePauseSecond;

  /// No description provided for @versePauseHalf.
  ///
  /// In ar, this message translates to:
  /// **'نصف ثانية'**
  String get versePauseHalf;

  /// No description provided for @versePauseHint.
  ///
  /// In ar, this message translates to:
  /// **'يقصّر السكتات الطويلة بين الآيات دون المساس بالتلاوة نفسها'**
  String get versePauseHint;

  /// No description provided for @listenFromPage.
  ///
  /// In ar, this message translates to:
  /// **'استمع من أول الصفحة'**
  String get listenFromPage;

  /// No description provided for @repeatHint.
  ///
  /// In ar, this message translates to:
  /// **'إن لم تحدد مقطعًا تتكرر كل آية بهذا العدد ثم تليها التالية'**
  String get repeatHint;

  /// No description provided for @homeTitle.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get homeTitle;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في القرآن، أو اكتب «البقرة ٢٥٥»'**
  String get searchHint;

  /// No description provided for @searchIntro.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كلمة أو أكثر من القرآن، بتشكيل أو دونه، أو اكتب موضعا مثل «٢:٢٥٥» أو «البقرة ٢٥٥».'**
  String get searchIntro;

  /// No description provided for @searchGoTo.
  ///
  /// In ar, this message translates to:
  /// **'اذهب إلى الموضع'**
  String get searchGoTo;

  /// No description provided for @searchNothing.
  ///
  /// In ar, this message translates to:
  /// **'لا نتائج'**
  String get searchNothing;

  /// No description provided for @searchCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} موضعا في {verses} آية'**
  String searchCount(String count, String verses);

  /// No description provided for @searchMore.
  ///
  /// In ar, this message translates to:
  /// **'و{count} آية أخرى، ضيّق البحث لرؤيتها'**
  String searchMore(String count);

  /// No description provided for @searchHistory.
  ///
  /// In ar, this message translates to:
  /// **'عمليات البحث السابقة'**
  String get searchHistory;

  /// No description provided for @searchClearHistory.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get searchClearHistory;

  /// No description provided for @continueReading.
  ///
  /// In ar, this message translates to:
  /// **'متابعة القراءة'**
  String get continueReading;

  /// No description provided for @continueReadingAt.
  ///
  /// In ar, this message translates to:
  /// **'{surah} · الآية {ayah} · صفحة {page}'**
  String continueReadingAt(String surah, String ayah, String page);

  /// No description provided for @openLabel.
  ///
  /// In ar, this message translates to:
  /// **'افتح'**
  String get openLabel;

  /// No description provided for @wordStudy.
  ///
  /// In ar, this message translates to:
  /// **'دراسة الكلمة'**
  String get wordStudy;

  /// No description provided for @wordMeanings.
  ///
  /// In ar, this message translates to:
  /// **'معاني الكلمات'**
  String get wordMeanings;

  /// No description provided for @wordPickHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على الكلمة التي تريد دراستها'**
  String get wordPickHint;

  /// No description provided for @wordStudyChoose.
  ///
  /// In ar, this message translates to:
  /// **'اختر كلمة من كلمات الآية'**
  String get wordStudyChoose;

  /// No description provided for @wordMeaningTitle.
  ///
  /// In ar, this message translates to:
  /// **'المعنى'**
  String get wordMeaningTitle;

  /// No description provided for @wordNoMeaning.
  ///
  /// In ar, this message translates to:
  /// **'لا شرح لهذه الكلمة في «الميسر في غريب القرآن».'**
  String get wordNoMeaning;

  /// No description provided for @wordRootTitle.
  ///
  /// In ar, this message translates to:
  /// **'الجذر'**
  String get wordRootTitle;

  /// No description provided for @wordLemma.
  ///
  /// In ar, this message translates to:
  /// **'المدخل المعجمي'**
  String get wordLemma;

  /// No description provided for @wordNoRoot.
  ///
  /// In ar, this message translates to:
  /// **'لا جذر لهذه الكلمة في المدونة القرآنية.'**
  String get wordNoRoot;

  /// No description provided for @wordNoCorpusData.
  ///
  /// In ar, this message translates to:
  /// **'لا بيانات لهذه الكلمة في المدونة القرآنية.'**
  String get wordNoCorpusData;

  /// No description provided for @rootOccurrencesTitle.
  ///
  /// In ar, this message translates to:
  /// **'مواضع الجذر'**
  String get rootOccurrencesTitle;

  /// No description provided for @rootOccurrencesCount.
  ///
  /// In ar, this message translates to:
  /// **'الكلمات: {words}، الآيات: {verses}'**
  String rootOccurrencesCount(String words, String verses);

  /// No description provided for @verseNoMeanings.
  ///
  /// In ar, this message translates to:
  /// **'لا شرح لكلمات هذه الآية في «الميسر في غريب القرآن».'**
  String get verseNoMeanings;

  /// No description provided for @wordStudyVerse.
  ///
  /// In ar, this message translates to:
  /// **'{surah}، الآية {ayah}'**
  String wordStudyVerse(String surah, String ayah);

  /// No description provided for @downloadAllTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحميل كل المصاحف'**
  String get downloadAllTitle;

  /// No description provided for @downloadAllCount.
  ///
  /// In ar, this message translates to:
  /// **'اكتمل {done} من {total}'**
  String downloadAllCount(String done, String total);

  /// No description provided for @themeArtCredit.
  ///
  /// In ar, this message translates to:
  /// **'الزخارف: مشروع quran-assets من Quran.ws، تطوير Abdullah Ibeid (github.com/quran-ws/quran-assets). المنقول منها من المصاحف برخصة المشاع الإبداعي غير التجارية CC BY-NC-SA 4.0، وتصميمه لمجمع الملك فهد وناشرين آخرين.'**
  String get themeArtCredit;

  /// No description provided for @khatmaTitle.
  ///
  /// In ar, this message translates to:
  /// **'الختمة'**
  String get khatmaTitle;

  /// No description provided for @khatmaNew.
  ///
  /// In ar, this message translates to:
  /// **'ختمة جديدة'**
  String get khatmaNew;

  /// No description provided for @khatmaEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا ختمة الآن'**
  String get khatmaEmptyTitle;

  /// No description provided for @khatmaEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'ضع خطة لختم المصحف: حدد موعد الختم أو مقدار الورد اليومي. والصفحات التي تقرؤها في المصحف تُحسب تلقائيا.'**
  String get khatmaEmptyBody;

  /// No description provided for @khatmaDefaultName.
  ///
  /// In ar, this message translates to:
  /// **'ختمتي'**
  String get khatmaDefaultName;

  /// No description provided for @khatmaNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get khatmaNameLabel;

  /// No description provided for @khatmaByDate.
  ///
  /// In ar, this message translates to:
  /// **'حسب موعد الختم'**
  String get khatmaByDate;

  /// No description provided for @khatmaByAmount.
  ///
  /// In ar, this message translates to:
  /// **'حسب الورد اليومي'**
  String get khatmaByAmount;

  /// No description provided for @khatmaEndDateLabel.
  ///
  /// In ar, this message translates to:
  /// **'موعد الختم'**
  String get khatmaEndDateLabel;

  /// No description provided for @khatmaAmountLabel.
  ///
  /// In ar, this message translates to:
  /// **'المقدار في اليوم'**
  String get khatmaAmountLabel;

  /// No description provided for @khatmaUnitPage.
  ///
  /// In ar, this message translates to:
  /// **'صفحة'**
  String get khatmaUnitPage;

  /// No description provided for @khatmaUnitJuz.
  ///
  /// In ar, this message translates to:
  /// **'جزء'**
  String get khatmaUnitJuz;

  /// No description provided for @khatmaUnitHizb.
  ///
  /// In ar, this message translates to:
  /// **'حزب'**
  String get khatmaUnitHizb;

  /// No description provided for @khatmaAboutPerDay.
  ///
  /// In ar, this message translates to:
  /// **'نحو {count} صفحة في اليوم'**
  String khatmaAboutPerDay(String count);

  /// No description provided for @khatmaDuration.
  ///
  /// In ar, this message translates to:
  /// **'المدة: {count} يوم، والختم يوم {date}'**
  String khatmaDuration(String count, String date);

  /// No description provided for @khatmaEditionNote.
  ///
  /// In ar, this message translates to:
  /// **'بصفحات {edition}'**
  String khatmaEditionNote(String edition);

  /// No description provided for @khatmaReminder.
  ///
  /// In ar, this message translates to:
  /// **'تذكير يومي'**
  String get khatmaReminder;

  /// No description provided for @khatmaReminderOff.
  ///
  /// In ar, this message translates to:
  /// **'بلا تذكير'**
  String get khatmaReminderOff;

  /// No description provided for @khatmaStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الختمة'**
  String get khatmaStart;

  /// No description provided for @khatmaReplaceTitle.
  ///
  /// In ar, this message translates to:
  /// **'ختمة مفتوحة'**
  String get khatmaReplaceTitle;

  /// No description provided for @khatmaReplaceBody.
  ///
  /// In ar, this message translates to:
  /// **'تُحذف الختمة الحالية وسجلها عند بدء ختمة جديدة.'**
  String get khatmaReplaceBody;

  /// No description provided for @khatmaToday.
  ///
  /// In ar, this message translates to:
  /// **'ورد اليوم'**
  String get khatmaToday;

  /// No description provided for @khatmaPagesRange.
  ///
  /// In ar, this message translates to:
  /// **'من صفحة {from} إلى صفحة {to}'**
  String khatmaPagesRange(String from, String to);

  /// No description provided for @khatmaPagesCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الصفحات: {count}'**
  String khatmaPagesCount(String count);

  /// No description provided for @khatmaReadNow.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ الآن'**
  String get khatmaReadNow;

  /// No description provided for @khatmaMarkRead.
  ///
  /// In ar, this message translates to:
  /// **'قرأته في مصحف آخر'**
  String get khatmaMarkRead;

  /// No description provided for @khatmaTodayDone.
  ///
  /// In ar, this message translates to:
  /// **'ورد اليوم مقروء'**
  String get khatmaTodayDone;

  /// No description provided for @khatmaContinue.
  ///
  /// In ar, this message translates to:
  /// **'تابع القراءة'**
  String get khatmaContinue;

  /// No description provided for @khatmaProgress.
  ///
  /// In ar, this message translates to:
  /// **'{done} من {total} صفحة'**
  String khatmaProgress(String done, String total);

  /// No description provided for @khatmaDaysLeft.
  ///
  /// In ar, this message translates to:
  /// **'الأيام الباقية: {count}'**
  String khatmaDaysLeft(String count);

  /// No description provided for @khatmaEnds.
  ///
  /// In ar, this message translates to:
  /// **'الختم يوم {date}'**
  String khatmaEnds(String date);

  /// No description provided for @khatmaBehindTitle.
  ///
  /// In ar, this message translates to:
  /// **'صفحات من الأيام الماضية: {count}'**
  String khatmaBehindTitle(String count);

  /// No description provided for @khatmaBehindBody.
  ///
  /// In ar, this message translates to:
  /// **'أُضيفت إلى ورد اليوم. يمكنك توزيعها على الأيام الباقية، أو تأخير موعد الختم.'**
  String get khatmaBehindBody;

  /// No description provided for @khatmaSpread.
  ///
  /// In ar, this message translates to:
  /// **'وزّعها على الأيام الباقية'**
  String get khatmaSpread;

  /// No description provided for @khatmaExtend.
  ///
  /// In ar, this message translates to:
  /// **'أخّر موعد الختم'**
  String get khatmaExtend;

  /// No description provided for @khatmaComplete.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت الختمة'**
  String get khatmaComplete;

  /// No description provided for @khatmaCompletedOn.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت يوم {date}'**
  String khatmaCompletedOn(String date);

  /// No description provided for @khatmaPast.
  ///
  /// In ar, this message translates to:
  /// **'ختمات سابقة'**
  String get khatmaPast;

  /// No description provided for @khatmaDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف الختمة'**
  String get khatmaDelete;

  /// No description provided for @khatmaDeleteBody.
  ///
  /// In ar, this message translates to:
  /// **'يُحذف سجل هذه الختمة.'**
  String get khatmaDeleteBody;

  /// No description provided for @khatmaTileStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ'**
  String get khatmaTileStart;

  /// No description provided for @khatmaTilePages.
  ///
  /// In ar, this message translates to:
  /// **'ورد اليوم: {count}'**
  String khatmaTilePages(String count);

  /// No description provided for @khatmaReminderTitle.
  ///
  /// In ar, this message translates to:
  /// **'ورد الختمة'**
  String get khatmaReminderTitle;

  /// No description provided for @khatmaReminderBody.
  ///
  /// In ar, this message translates to:
  /// **'ورد اليوم: من صفحة {from} إلى صفحة {to}'**
  String khatmaReminderBody(String from, String to);

  /// No description provided for @khatmaReminderChannel.
  ///
  /// In ar, this message translates to:
  /// **'تذكير الختمة'**
  String get khatmaReminderChannel;

  /// No description provided for @homeTodayTitle.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get homeTodayTitle;

  /// No description provided for @widgetNoKhatma.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ ختمة في تبيان'**
  String get widgetNoKhatma;

  /// No description provided for @reportsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقارير القراءة'**
  String get reportsTitle;

  /// No description provided for @reportsWeek.
  ///
  /// In ar, this message translates to:
  /// **'آخر ٧ أيام'**
  String get reportsWeek;

  /// No description provided for @reportsMonth.
  ///
  /// In ar, this message translates to:
  /// **'آخر ٣٠ يوما'**
  String get reportsMonth;

  /// No description provided for @reportsDays.
  ///
  /// In ar, this message translates to:
  /// **'أيام القراءة'**
  String get reportsDays;

  /// No description provided for @reportsPages.
  ///
  /// In ar, this message translates to:
  /// **'الصفحات'**
  String get reportsPages;

  /// No description provided for @reportsReadingMinutes.
  ///
  /// In ar, this message translates to:
  /// **'دقائق القراءة'**
  String get reportsReadingMinutes;

  /// No description provided for @reportsListeningMinutes.
  ///
  /// In ar, this message translates to:
  /// **'دقائق الاستماع'**
  String get reportsListeningMinutes;

  /// No description provided for @reportsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'تظهر هنا قراءتك واستماعك تلقائيا.'**
  String get reportsEmpty;

  /// No description provided for @reportsDayRead.
  ///
  /// In ar, this message translates to:
  /// **'يوم فيه قراءة أو استماع'**
  String get reportsDayRead;

  /// No description provided for @streakReadToday.
  ///
  /// In ar, this message translates to:
  /// **'قرأت اليوم. الأيام المتتالية: {count}'**
  String streakReadToday(String count);

  /// No description provided for @streakContinue.
  ///
  /// In ar, this message translates to:
  /// **'الأيام المتتالية حتى أمس: {count}. صفحة اليوم تصلها.'**
  String streakContinue(String count);

  /// No description provided for @streakWelcome.
  ///
  /// In ar, this message translates to:
  /// **'مرحبا بعودتك. تابع من حيث وقفت.'**
  String get streakWelcome;

  /// No description provided for @streakNotesToggle.
  ///
  /// In ar, this message translates to:
  /// **'رسائل الاستمرار'**
  String get streakNotesToggle;

  /// No description provided for @streakNotesHint.
  ///
  /// In ar, this message translates to:
  /// **'تعرض الأيام المتتالية فقط، ولا تعرض الأيام الفائتة.'**
  String get streakNotesHint;

  /// No description provided for @journalTitle.
  ///
  /// In ar, this message translates to:
  /// **'دفتر التدبر'**
  String get journalTitle;

  /// No description provided for @journalSearch.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في ملاحظاتك'**
  String get journalSearch;

  /// No description provided for @journalEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا ملاحظات بعد. اضغط مطولا على آية في المصحف واختر «ملاحظة تدبر».'**
  String get journalEmpty;

  /// No description provided for @journalNoMatch.
  ///
  /// In ar, this message translates to:
  /// **'لا ملاحظات فيها هذه الكلمات.'**
  String get journalNoMatch;

  /// No description provided for @journalAdd.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة تدبر'**
  String get journalAdd;

  /// No description provided for @journalHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ملاحظتك على الآية'**
  String get journalHint;

  /// No description provided for @journalEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get journalEdit;

  /// No description provided for @journalOpenVerse.
  ///
  /// In ar, this message translates to:
  /// **'افتح الآية'**
  String get journalOpenVerse;

  /// No description provided for @journalVerseRef.
  ///
  /// In ar, this message translates to:
  /// **'سورة {surah} · آية {ayah}'**
  String journalVerseRef(String surah, String ayah);

  /// No description provided for @journalSaved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظت الملاحظة'**
  String get journalSaved;

  /// No description provided for @journalEarlier.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظاتك على هذه الآية'**
  String get journalEarlier;

  /// No description provided for @elderlyMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع كبار السن'**
  String get elderlyMode;

  /// No description provided for @elderlyModeHint.
  ///
  /// In ar, this message translates to:
  /// **'خط أكبر، وأزرار أكبر بأسمائها، وألوان أوضح، وصفحة رئيسية فيها المهم فقط، وصفحة المصحف بأكبر حجم، وانتقالات أهدأ'**
  String get elderlyModeHint;

  /// No description provided for @searchModeWords.
  ///
  /// In ar, this message translates to:
  /// **'بالكلمات'**
  String get searchModeWords;

  /// No description provided for @searchModeMeaning.
  ///
  /// In ar, this message translates to:
  /// **'بالمعنى'**
  String get searchModeMeaning;

  /// No description provided for @searchMeaningHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب فكرة أو سؤالا بكلماتك'**
  String get searchMeaningHint;

  /// No description provided for @searchMeaningIntro.
  ///
  /// In ar, this message translates to:
  /// **'اكتب فكرة بكلماتك، بالعربية أو بالإنجليزية، مثل «الصبر على البلاء» أو «بر الوالدين»، فتظهر الآيات التي يتناولها معناها في التفسير الميسر والترجمتين. تظهر كل آية بنصها، ومعها النص الذي طابق كما هو من مصدره.'**
  String get searchMeaningIntro;

  /// No description provided for @searchMatchedIn.
  ///
  /// In ar, this message translates to:
  /// **'طابق في: {source}'**
  String searchMatchedIn(String source);

  /// No description provided for @searchMeaningCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} آية'**
  String searchMeaningCount(String count);

  /// No description provided for @semanticPackName.
  ///
  /// In ar, this message translates to:
  /// **'حزمة البحث بالمعنى'**
  String get semanticPackName;

  /// No description provided for @semanticPackOffer.
  ///
  /// In ar, this message translates to:
  /// **'البحث الآن بالكلمات داخل نصوص المعاني. نزّل حزمة البحث بالمعنى (نحو {size} ميجا) ليجد البحث الآيات بمعناها وإن اختلفت الكلمات، دون اتصال.'**
  String semanticPackOffer(String size);

  /// No description provided for @semanticPackDownload.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل الحزمة'**
  String get semanticPackDownload;

  /// No description provided for @semanticPackDownloading.
  ///
  /// In ar, this message translates to:
  /// **'يُنزَّل: {percent}٪'**
  String semanticPackDownloading(String percent);

  /// No description provided for @semanticPackVerifying.
  ///
  /// In ar, this message translates to:
  /// **'يُتحقَّق من الحزمة ويُثبَّت…'**
  String get semanticPackVerifying;

  /// No description provided for @semanticPackFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التنزيل. حاول مرة أخرى.'**
  String get semanticPackFailed;

  /// No description provided for @semanticPackLoading.
  ///
  /// In ar, this message translates to:
  /// **'يُجهَّز البحث بالمعنى…'**
  String get semanticPackLoading;

  /// No description provided for @semanticPackError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح حزمة البحث بالمعنى، فالبحث الآن بالكلمات.'**
  String get semanticPackError;

  /// No description provided for @semanticResultsNote.
  ///
  /// In ar, this message translates to:
  /// **'نتائج تقريبية مرتبة بقرب المعنى. راجع الآية في موضعها وفي تفسيرها.'**
  String get semanticResultsNote;

  /// No description provided for @verseLabel.
  ///
  /// In ar, this message translates to:
  /// **'سورة {surah}، الآية {ayah}'**
  String verseLabel(String surah, String ayah);

  /// No description provided for @pageLabelFull.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة {page}، {surah}'**
  String pageLabelFull(String page, String surah);

  /// No description provided for @markThisVerse.
  ///
  /// In ar, this message translates to:
  /// **'ضع علامة القراءة عند هذه الآية أو أزلها'**
  String get markThisVerse;

  /// No description provided for @loadingPage.
  ///
  /// In ar, this message translates to:
  /// **'تُحمَّل الصفحة {page}'**
  String loadingPage(String page);

  /// No description provided for @clearSearch.
  ///
  /// In ar, this message translates to:
  /// **'مسح البحث'**
  String get clearSearch;

  /// No description provided for @previousPageNumber.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة السابقة'**
  String get previousPageNumber;

  /// No description provided for @nextPageNumber.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة التالية'**
  String get nextPageNumber;

  /// No description provided for @showMenus.
  ///
  /// In ar, this message translates to:
  /// **'إظهار القوائم'**
  String get showMenus;

  /// No description provided for @hideMenus.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء القوائم'**
  String get hideMenus;

  /// No description provided for @downloadSurah.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل سورة {surah}'**
  String downloadSurah(String surah);

  /// No description provided for @retryDownloadSurah.
  ///
  /// In ar, this message translates to:
  /// **'أعد تنزيل سورة {surah}'**
  String retryDownloadSurah(String surah);

  /// No description provided for @deleteSurahDownload.
  ///
  /// In ar, this message translates to:
  /// **'سورة {surah} منزّلة. احذفها'**
  String deleteSurahDownload(String surah);

  /// No description provided for @downloadingSurah.
  ///
  /// In ar, this message translates to:
  /// **'تُنزَّل سورة {surah}'**
  String downloadingSurah(String surah);

  /// No description provided for @verseCounter.
  ///
  /// In ar, this message translates to:
  /// **'الآية {current} من {total}'**
  String verseCounter(String current, String total);

  /// No description provided for @downloadPercentSpoken.
  ///
  /// In ar, this message translates to:
  /// **'اكتمل {percent}٪ من التحميل'**
  String downloadPercentSpoken(String percent);

  /// No description provided for @hifzTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ'**
  String get hifzTitle;

  /// No description provided for @hifzTileNote.
  ///
  /// In ar, this message translates to:
  /// **'المراجعة والتسميع'**
  String get hifzTileNote;

  /// No description provided for @hifzToday.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة اليوم'**
  String get hifzToday;

  /// No description provided for @hifzNothingDue.
  ///
  /// In ar, this message translates to:
  /// **'لا مراجعة مستحقة اليوم.'**
  String get hifzNothingDue;

  /// No description provided for @hifzNothingDueHint.
  ///
  /// In ar, this message translates to:
  /// **'سمّع صفحة أو ربعا أو سورة ثم قيّم تسميعك، فتدخل المراجعة المتباعدة.'**
  String get hifzNothingDueHint;

  /// No description provided for @hifzStartTest.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ تسميعا'**
  String get hifzStartTest;

  /// No description provided for @hifzMap.
  ///
  /// In ar, this message translates to:
  /// **'خريطة الحفظ'**
  String get hifzMap;

  /// No description provided for @hifzMapHint.
  ///
  /// In ar, this message translates to:
  /// **'كل صفحة ملوّنة بقوة حفظها، ومعها علامة تقرأ دون ألوان.'**
  String get hifzMapHint;

  /// No description provided for @hifzAllUnits.
  ///
  /// In ar, this message translates to:
  /// **'كل وحدات المراجعة'**
  String get hifzAllUnits;

  /// No description provided for @hifzDueToday.
  ///
  /// In ar, this message translates to:
  /// **'مستحقة اليوم'**
  String get hifzDueToday;

  /// No description provided for @hifzDueOn.
  ///
  /// In ar, this message translates to:
  /// **'موعدها {date}'**
  String hifzDueOn(String date);

  /// No description provided for @hifzQuarter.
  ///
  /// In ar, this message translates to:
  /// **'الربع {number}'**
  String hifzQuarter(String number);

  /// No description provided for @hifzUnitPage.
  ///
  /// In ar, this message translates to:
  /// **'صفحة'**
  String get hifzUnitPage;

  /// No description provided for @hifzUnitQuarter.
  ///
  /// In ar, this message translates to:
  /// **'ربع'**
  String get hifzUnitQuarter;

  /// No description provided for @hifzUnitSurah.
  ///
  /// In ar, this message translates to:
  /// **'سورة'**
  String get hifzUnitSurah;

  /// No description provided for @hifzChooseUnit.
  ///
  /// In ar, this message translates to:
  /// **'ماذا تسمّع؟'**
  String get hifzChooseUnit;

  /// No description provided for @hifzNumberRange.
  ///
  /// In ar, this message translates to:
  /// **'الرقم، من ١ إلى {max}'**
  String hifzNumberRange(String max);

  /// No description provided for @hifzBegin.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ'**
  String get hifzBegin;

  /// No description provided for @hifzRemove.
  ///
  /// In ar, this message translates to:
  /// **'احذف من المراجعة'**
  String get hifzRemove;

  /// No description provided for @revealNextWord.
  ///
  /// In ar, this message translates to:
  /// **'الكلمة التالية'**
  String get revealNextWord;

  /// No description provided for @revealNextVerse.
  ///
  /// In ar, this message translates to:
  /// **'الآية التالية'**
  String get revealNextVerse;

  /// No description provided for @revealAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get revealAll;

  /// No description provided for @endRecite.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء التسميع'**
  String get endRecite;

  /// No description provided for @verseRemembered.
  ///
  /// In ar, this message translates to:
  /// **'حفظت'**
  String get verseRemembered;

  /// No description provided for @verseMissed.
  ///
  /// In ar, this message translates to:
  /// **'أخطأت'**
  String get verseMissed;

  /// No description provided for @testCounts.
  ///
  /// In ar, this message translates to:
  /// **'حفظت {remembered} · أخطأت {missed}'**
  String testCounts(String remembered, String missed);

  /// No description provided for @revealByLine.
  ///
  /// In ar, this message translates to:
  /// **'لا مواضع لكلمات هذه الآية في هذه الطبعة، فتُكشف سطرا سطرا.'**
  String get revealByLine;

  /// No description provided for @gradeUnit.
  ///
  /// In ar, this message translates to:
  /// **'قيّم'**
  String get gradeUnit;

  /// No description provided for @gradeTitle.
  ///
  /// In ar, this message translates to:
  /// **'كيف كان تسميعك؟'**
  String get gradeTitle;

  /// No description provided for @gradeSuggested.
  ///
  /// In ar, this message translates to:
  /// **'الاختيار المقترح من نتائج الآيات'**
  String get gradeSuggested;

  /// No description provided for @gradeAgain.
  ///
  /// In ar, this message translates to:
  /// **'أعِدها'**
  String get gradeAgain;

  /// No description provided for @gradeHard.
  ///
  /// In ar, this message translates to:
  /// **'صعبة'**
  String get gradeHard;

  /// No description provided for @gradeGood.
  ///
  /// In ar, this message translates to:
  /// **'جيدة'**
  String get gradeGood;

  /// No description provided for @gradeEasy.
  ///
  /// In ar, this message translates to:
  /// **'سهلة'**
  String get gradeEasy;

  /// No description provided for @gradeSaved.
  ///
  /// In ar, this message translates to:
  /// **'المراجعة القادمة: {date}'**
  String gradeSaved(String date);

  /// No description provided for @similarVerses.
  ///
  /// In ar, this message translates to:
  /// **'المتشابهات'**
  String get similarVerses;

  /// No description provided for @similarCount.
  ///
  /// In ar, this message translates to:
  /// **'متشابهات ({count})'**
  String similarCount(String count);

  /// No description provided for @similarThisVerse.
  ///
  /// In ar, this message translates to:
  /// **'الآية'**
  String get similarThisVerse;

  /// No description provided for @similarFollowing.
  ///
  /// In ar, this message translates to:
  /// **'والآية بعدها'**
  String get similarFollowing;

  /// No description provided for @strengthNone.
  ///
  /// In ar, this message translates to:
  /// **'لم يُحفظ'**
  String get strengthNone;

  /// No description provided for @strengthWeak.
  ///
  /// In ar, this message translates to:
  /// **'ضعيف'**
  String get strengthWeak;

  /// No description provided for @strengthFair.
  ///
  /// In ar, this message translates to:
  /// **'متوسط'**
  String get strengthFair;

  /// No description provided for @strengthGood.
  ///
  /// In ar, this message translates to:
  /// **'جيد'**
  String get strengthGood;

  /// No description provided for @strengthStrong.
  ///
  /// In ar, this message translates to:
  /// **'متقن'**
  String get strengthStrong;

  /// No description provided for @mapPages.
  ///
  /// In ar, this message translates to:
  /// **'الصفحات'**
  String get mapPages;

  /// No description provided for @mapSurahs.
  ///
  /// In ar, this message translates to:
  /// **'السور'**
  String get mapSurahs;

  /// No description provided for @mapZoomIn.
  ///
  /// In ar, this message translates to:
  /// **'تكبير'**
  String get mapZoomIn;

  /// No description provided for @mapZoomOut.
  ///
  /// In ar, this message translates to:
  /// **'تصغير'**
  String get mapZoomOut;

  /// No description provided for @mapCell.
  ///
  /// In ar, this message translates to:
  /// **'{name}: {strength}'**
  String mapCell(String name, String strength);

  /// No description provided for @tajweedColors.
  ///
  /// In ar, this message translates to:
  /// **'تلوين أحكام التجويد'**
  String get tajweedColors;

  /// No description provided for @tajweedColorsHint.
  ///
  /// In ar, this message translates to:
  /// **'تلوين الحروف التي يقع عليها الحكم فقط، بالألوان التي تختارها'**
  String get tajweedColorsHint;

  /// No description provided for @tajweedLegend.
  ///
  /// In ar, this message translates to:
  /// **'مفتاح ألوان التجويد'**
  String get tajweedLegend;

  /// No description provided for @tajweedRuleColors.
  ///
  /// In ar, this message translates to:
  /// **'لون كل حكم'**
  String get tajweedRuleColors;

  /// No description provided for @tajweedNoColor.
  ///
  /// In ar, this message translates to:
  /// **'بلا لون'**
  String get tajweedNoColor;

  /// No description provided for @tajweedReset.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الألوان الافتراضية'**
  String get tajweedReset;

  /// No description provided for @tajweedPickColor.
  ///
  /// In ar, this message translates to:
  /// **'لون «{rule}»'**
  String tajweedPickColor(String rule);

  /// No description provided for @tajweedSourceNote.
  ///
  /// In ar, this message translates to:
  /// **'مواضع الأحكام من بيانات quran-tajweed (Collin Fair، رخصة CC BY 4.0)، وهي مولّدة آليا ولم يراجعها متخصص بعد. وموضع الحرف داخل الكلمة تقديري، وفي الشمرلي حدود بعض الكلمات تقديرية أيضا.'**
  String get tajweedSourceNote;

  /// No description provided for @tajweedLegendHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطولا على زر التلوين في الصفحة لعرض هذا المفتاح.'**
  String get tajweedLegendHint;

  /// No description provided for @tajweedHueCrimson.
  ///
  /// In ar, this message translates to:
  /// **'أحمر داكن'**
  String get tajweedHueCrimson;

  /// No description provided for @tajweedHueRed.
  ///
  /// In ar, this message translates to:
  /// **'أحمر'**
  String get tajweedHueRed;

  /// No description provided for @tajweedHueOrange.
  ///
  /// In ar, this message translates to:
  /// **'برتقالي'**
  String get tajweedHueOrange;

  /// No description provided for @tajweedHueGold.
  ///
  /// In ar, this message translates to:
  /// **'ذهبي'**
  String get tajweedHueGold;

  /// No description provided for @tajweedHueGreen.
  ///
  /// In ar, this message translates to:
  /// **'أخضر'**
  String get tajweedHueGreen;

  /// No description provided for @tajweedHueLightGreen.
  ///
  /// In ar, this message translates to:
  /// **'أخضر فاتح'**
  String get tajweedHueLightGreen;

  /// No description provided for @tajweedHueTeal.
  ///
  /// In ar, this message translates to:
  /// **'فيروزي'**
  String get tajweedHueTeal;

  /// No description provided for @tajweedHueBlue.
  ///
  /// In ar, this message translates to:
  /// **'أزرق'**
  String get tajweedHueBlue;

  /// No description provided for @tajweedHuePurple.
  ///
  /// In ar, this message translates to:
  /// **'بنفسجي'**
  String get tajweedHuePurple;

  /// No description provided for @tajweedHuePink.
  ///
  /// In ar, this message translates to:
  /// **'وردي'**
  String get tajweedHuePink;

  /// No description provided for @tajweedHueGrey.
  ///
  /// In ar, this message translates to:
  /// **'رمادي'**
  String get tajweedHueGrey;

  /// No description provided for @tajweedHueViolet.
  ///
  /// In ar, this message translates to:
  /// **'ليلكي'**
  String get tajweedHueViolet;

  /// No description provided for @tajweedHueAmber.
  ///
  /// In ar, this message translates to:
  /// **'كهرماني'**
  String get tajweedHueAmber;

  /// No description provided for @tajweedNoDataRiwaya.
  ///
  /// In ar, this message translates to:
  /// **'لا تلوين للتجويد في مصاحف الروايات (ورش وقالون والدوري وشعبة): لا توجد بعد بيانات أحكام موثوقة لهذه الروايات، ولا نضع أحكاما بلا مصدر. التلوين يعمل في مصاحف حفص.'**
  String get tajweedNoDataRiwaya;

  /// No description provided for @tajweedHamzatWasl.
  ///
  /// In ar, this message translates to:
  /// **'همزة الوصل'**
  String get tajweedHamzatWasl;

  /// No description provided for @tajweedLamShamsiyyah.
  ///
  /// In ar, this message translates to:
  /// **'اللام الشمسية'**
  String get tajweedLamShamsiyyah;

  /// No description provided for @tajweedSilent.
  ///
  /// In ar, this message translates to:
  /// **'الحروف التي لا تُنطق'**
  String get tajweedSilent;

  /// No description provided for @tajweedMadd2.
  ///
  /// In ar, this message translates to:
  /// **'المد الطبيعي (حركتان)'**
  String get tajweedMadd2;

  /// No description provided for @tajweedMadd246.
  ///
  /// In ar, this message translates to:
  /// **'المد العارض واللين (2 أو 4 أو 6 حركات)'**
  String get tajweedMadd246;

  /// No description provided for @tajweedMaddMuttasil.
  ///
  /// In ar, this message translates to:
  /// **'المد المتصل (4 أو 5 حركات)'**
  String get tajweedMaddMuttasil;

  /// No description provided for @tajweedMaddMunfasil.
  ///
  /// In ar, this message translates to:
  /// **'المد المنفصل (4 أو 5 حركات)'**
  String get tajweedMaddMunfasil;

  /// No description provided for @tajweedMadd6.
  ///
  /// In ar, this message translates to:
  /// **'المد اللازم (6 حركات)'**
  String get tajweedMadd6;

  /// No description provided for @tajweedGhunnah.
  ///
  /// In ar, this message translates to:
  /// **'الغنة'**
  String get tajweedGhunnah;

  /// No description provided for @tajweedIkhfa.
  ///
  /// In ar, this message translates to:
  /// **'الإخفاء'**
  String get tajweedIkhfa;

  /// No description provided for @tajweedIkhfaShafawi.
  ///
  /// In ar, this message translates to:
  /// **'الإخفاء الشفوي'**
  String get tajweedIkhfaShafawi;

  /// No description provided for @tajweedIqlab.
  ///
  /// In ar, this message translates to:
  /// **'الإقلاب'**
  String get tajweedIqlab;

  /// No description provided for @tajweedIdghaamGhunnah.
  ///
  /// In ar, this message translates to:
  /// **'الإدغام بغنة'**
  String get tajweedIdghaamGhunnah;

  /// No description provided for @tajweedIdghaamNoGhunnah.
  ///
  /// In ar, this message translates to:
  /// **'الإدغام بلا غنة'**
  String get tajweedIdghaamNoGhunnah;

  /// No description provided for @tajweedIdghaamShafawi.
  ///
  /// In ar, this message translates to:
  /// **'الإدغام الشفوي'**
  String get tajweedIdghaamShafawi;

  /// No description provided for @tajweedIdghaamMutajanisayn.
  ///
  /// In ar, this message translates to:
  /// **'إدغام المتجانسين'**
  String get tajweedIdghaamMutajanisayn;

  /// No description provided for @tajweedIdghaamMutaqaribayn.
  ///
  /// In ar, this message translates to:
  /// **'إدغام المتقاربين'**
  String get tajweedIdghaamMutaqaribayn;

  /// No description provided for @tajweedQalqalah.
  ///
  /// In ar, this message translates to:
  /// **'القلقلة'**
  String get tajweedQalqalah;

  /// No description provided for @editionWarsh.
  ///
  /// In ar, this message translates to:
  /// **'مصحف المدينة برواية ورش عن نافع'**
  String get editionWarsh;

  /// No description provided for @editionQalun.
  ///
  /// In ar, this message translates to:
  /// **'مصحف المدينة برواية قالون عن نافع'**
  String get editionQalun;

  /// No description provided for @editionDouri.
  ///
  /// In ar, this message translates to:
  /// **'مصحف المدينة برواية الدوري عن أبي عمرو'**
  String get editionDouri;

  /// No description provided for @editionShubah.
  ///
  /// In ar, this message translates to:
  /// **'مصحف المدينة برواية شعبة عن عاصم'**
  String get editionShubah;

  /// No description provided for @riwayaWarsh.
  ///
  /// In ar, this message translates to:
  /// **'رواية ورش عن نافع'**
  String get riwayaWarsh;

  /// No description provided for @riwayaQalun.
  ///
  /// In ar, this message translates to:
  /// **'رواية قالون عن نافع'**
  String get riwayaQalun;

  /// No description provided for @riwayaDouri.
  ///
  /// In ar, this message translates to:
  /// **'رواية الدوري عن أبي عمرو'**
  String get riwayaDouri;

  /// No description provided for @riwayaShubah.
  ///
  /// In ar, this message translates to:
  /// **'رواية شعبة عن عاصم'**
  String get riwayaShubah;

  /// No description provided for @riwayatTitle.
  ///
  /// In ar, this message translates to:
  /// **'مصاحف الروايات'**
  String get riwayatTitle;

  /// No description provided for @riwayaEditionDesc.
  ///
  /// In ar, this message translates to:
  /// **'صفحات مصحف المدينة لهذه الرواية من مجمع الملك فهد، بعدّ آياتها وترقيمها. التفسير والترجمة والفواصل تُربط بالآيات المقابلة في عدّ حفص.'**
  String get riwayaEditionDesc;

  /// No description provided for @riwayaGaps.
  ///
  /// In ar, this message translates to:
  /// **'في مصاحف الروايات: لا تظليل للكلمة أثناء التلاوة (تلاواتها موقّتة بالآيات وحدها)، ولا يظهر الحزب وأرباعه في الإطار (الصفحة نفسها تحمل علاماتها المطبوعة).'**
  String get riwayaGaps;

  /// No description provided for @riwayaNoWordBoxes.
  ///
  /// In ar, this message translates to:
  /// **'صفحات هذه الرواية المنزّلة لا تحمل مربعات الكلمات، فلا تلوين فيها للفظ الجلالة ولا اختيار للكلمة. تحملها حزمة الصفحات الأحدث.'**
  String get riwayaNoWordBoxes;

  /// No description provided for @riwayaWordNoStudy.
  ///
  /// In ar, this message translates to:
  /// **'لا دراسة لهذه الكلمة هنا: دراسة الكلمة مبنية على كلمات رواية حفص، وتُفتح لكلمة الرواية حين تكون هي كلمة حفص نفسها في الآية نفسها، بحروفها.'**
  String get riwayaWordNoStudy;

  /// No description provided for @riwayaTafsirNote.
  ///
  /// In ar, this message translates to:
  /// **'الآية {ayah} من سورة {surah} في {riwaya} يقابلها في عدّ حفص: {hafs}. التفسير والترجمة ونص الآية أدناه بعدّ حفص وروايته.'**
  String riwayaTafsirNote(
    String ayah,
    String surah,
    String riwaya,
    String hafs,
  );

  /// No description provided for @riwayaNoHafs.
  ///
  /// In ar, this message translates to:
  /// **'لا تقابلها آية في عدّ حفص'**
  String get riwayaNoHafs;

  /// No description provided for @hafsVerseOne.
  ///
  /// In ar, this message translates to:
  /// **'الآية {number}'**
  String hafsVerseOne(String number);

  /// No description provided for @hafsVerseRange.
  ///
  /// In ar, this message translates to:
  /// **'الآيات {from} إلى {to}'**
  String hafsVerseRange(String from, String to);

  /// No description provided for @riwayaVerseText.
  ///
  /// In ar, this message translates to:
  /// **'نص الآية في {riwaya}'**
  String riwayaVerseText(String riwaya);

  /// No description provided for @riwayaRecitersNote.
  ///
  /// In ar, this message translates to:
  /// **'تلاوات {riwaya}'**
  String riwayaRecitersNote(String riwaya);

  /// No description provided for @reciterPhotosTitle.
  ///
  /// In ar, this message translates to:
  /// **'صور القرّاء'**
  String get reciterPhotosTitle;

  /// No description provided for @reciterPhotosNote.
  ///
  /// In ar, this message translates to:
  /// **'من ويكيميديا كومنز، مصغّرة ومقصوصة في تبيان.'**
  String get reciterPhotosNote;

  /// No description provided for @reciterPhotoCredit.
  ///
  /// In ar, this message translates to:
  /// **'{author}، {license}'**
  String reciterPhotoCredit(String author, String license);

  /// No description provided for @unknownAuthor.
  ///
  /// In ar, this message translates to:
  /// **'مصوّر غير معروف'**
  String get unknownAuthor;

  /// No description provided for @otherRiwayaReciters.
  ///
  /// In ar, this message translates to:
  /// **'قرّاء الروايات الأخرى'**
  String get otherRiwayaReciters;

  /// No description provided for @otherRiwayaHint.
  ///
  /// In ar, this message translates to:
  /// **'تُختار تلاواتهم من مصحف روايتهم، لأن ترقيم آياتها يختلف.'**
  String get otherRiwayaHint;

  /// No description provided for @reciterOfRiwaya.
  ///
  /// In ar, this message translates to:
  /// **'رواية {riwaya}'**
  String reciterOfRiwaya(String riwaya);

  /// No description provided for @copyVerses.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get copyVerses;

  /// No description provided for @shareVerseText.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة نصًا'**
  String get shareVerseText;

  /// No description provided for @shareVerseImage.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة صورة'**
  String get shareVerseImage;

  /// No description provided for @sharePreparing.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تجهيز الصورة…'**
  String get sharePreparing;

  /// No description provided for @shareImageFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تجهيز الصورة'**
  String get shareImageFailed;

  /// No description provided for @shareVerseCredit.
  ///
  /// In ar, this message translates to:
  /// **'نص القرآن الكريم: مشروع تنزيل (tanzil.net) · تطبيق تبيان'**
  String get shareVerseCredit;

  /// No description provided for @backupTitle.
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي'**
  String get backupTitle;

  /// No description provided for @backupExport.
  ///
  /// In ar, this message translates to:
  /// **'حفظ نسخة احتياطية'**
  String get backupExport;

  /// No description provided for @backupExportHint.
  ///
  /// In ar, this message translates to:
  /// **'ملف واحد فيه فواصلك وعلاماتك وموضع القراءة والختمة والتقارير وملاحظات التدبر وتقدم الحفظ، وإعداداتك. احتفظ به أو أرسله لنفسك.'**
  String get backupExportHint;

  /// No description provided for @backupImport.
  ///
  /// In ar, this message translates to:
  /// **'استعادة من نسخة'**
  String get backupImport;

  /// No description provided for @backupImportHint.
  ///
  /// In ar, this message translates to:
  /// **'يدمج النسخة مع ما على جهازك: لا يحذف شيئا، ويأخذ الأحدث عند التعارض، ويعيد الإعدادات كما كانت في النسخة.'**
  String get backupImportHint;

  /// No description provided for @backupDone.
  ///
  /// In ar, this message translates to:
  /// **'تمت الاستعادة: {added} جديد، {updated} محدَّث'**
  String backupDone(String added, String updated);

  /// No description provided for @backupInvalid.
  ///
  /// In ar, this message translates to:
  /// **'هذا الملف ليس نسخة احتياطية من تبيان'**
  String get backupInvalid;

  /// No description provided for @backupFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذرت العملية'**
  String get backupFailed;

  /// No description provided for @playbackSpeedLabel.
  ///
  /// In ar, this message translates to:
  /// **'سرعة التلاوة'**
  String get playbackSpeedLabel;

  /// No description provided for @playbackSpeedValue.
  ///
  /// In ar, this message translates to:
  /// **'×{value}'**
  String playbackSpeedValue(String value);

  /// No description provided for @storageTitle.
  ///
  /// In ar, this message translates to:
  /// **'التخزين والتنزيلات'**
  String get storageTitle;

  /// No description provided for @storageOpen.
  ///
  /// In ar, this message translates to:
  /// **'التخزين والتنزيلات'**
  String get storageOpen;

  /// No description provided for @storageOpenHint.
  ///
  /// In ar, this message translates to:
  /// **'ما نُزِّل على الجهاز وأحجامه، وحذف ما لا تحتاجه'**
  String get storageOpenHint;

  /// No description provided for @storageIntro.
  ///
  /// In ar, this message translates to:
  /// **'كل ما نزّله التطبيق على جهازك. يمكنك حذف أي منها وتنزيله لاحقا. بياناتك (الفواصل، الختمة، الملاحظات) لا تظهر هنا ولا تُمس.'**
  String get storageIntro;

  /// No description provided for @storageTotal.
  ///
  /// In ar, this message translates to:
  /// **'المجموع: {size}'**
  String storageTotal(String size);

  /// No description provided for @storageBundled.
  ///
  /// In ar, this message translates to:
  /// **'مضمّن مع التطبيق'**
  String get storageBundled;

  /// No description provided for @storageSize.
  ///
  /// In ar, this message translates to:
  /// **'{mb} ميجا'**
  String storageSize(String mb);

  /// No description provided for @storageAudioOf.
  ///
  /// In ar, this message translates to:
  /// **'تلاوات {name}'**
  String storageAudioOf(String name);

  /// No description provided for @storageSemantic.
  ///
  /// In ar, this message translates to:
  /// **'حزمة البحث بالمعنى'**
  String get storageSemantic;

  /// No description provided for @storageTiming.
  ///
  /// In ar, this message translates to:
  /// **'تحديثات توقيت التلاوة'**
  String get storageTiming;

  /// No description provided for @storagePartial.
  ///
  /// In ar, this message translates to:
  /// **'تنزيلات غير مكتملة'**
  String get storagePartial;

  /// No description provided for @storagePartialHint.
  ///
  /// In ar, this message translates to:
  /// **'بقايا تنزيلات توقفت؛ حذفها آمن'**
  String get storagePartialHint;

  /// No description provided for @storageClean.
  ///
  /// In ar, this message translates to:
  /// **'تنظيف'**
  String get storageClean;

  /// No description provided for @storageDeleteAsk.
  ///
  /// In ar, this message translates to:
  /// **'حذف {name} ({size})؟'**
  String storageDeleteAsk(String name, String size);

  /// No description provided for @storageFreed.
  ///
  /// In ar, this message translates to:
  /// **'تم تحرير {size}'**
  String storageFreed(String size);

  /// No description provided for @storageEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا شيء منزَّل غير ما يأتي مع التطبيق'**
  String get storageEmpty;

  /// No description provided for @storageUnknown.
  ///
  /// In ar, this message translates to:
  /// **'ملفات أخرى'**
  String get storageUnknown;

  /// No description provided for @asbabTitle.
  ///
  /// In ar, this message translates to:
  /// **'أسباب النزول'**
  String get asbabTitle;

  /// No description provided for @asbabCount.
  ///
  /// In ar, this message translates to:
  /// **'أسباب النزول ({count})'**
  String asbabCount(String count);

  /// No description provided for @bookCitationTahqiq.
  ///
  /// In ar, this message translates to:
  /// **'تحقيق {name}'**
  String bookCitationTahqiq(String name);

  /// No description provided for @bookCitationVolume.
  ///
  /// In ar, this message translates to:
  /// **'ج {volume}'**
  String bookCitationVolume(String volume);

  /// No description provided for @bookCitationPage.
  ///
  /// In ar, this message translates to:
  /// **'ص {page}'**
  String bookCitationPage(String page);

  /// No description provided for @bookCitationPages.
  ///
  /// In ar, this message translates to:
  /// **'ص {from}–{to}'**
  String bookCitationPages(String from, String to);

  /// No description provided for @storageBook.
  ///
  /// In ar, this message translates to:
  /// **'كتاب «{title}»'**
  String storageBook(String title);

  /// No description provided for @storageBooksAvailable.
  ///
  /// In ar, this message translates to:
  /// **'كتب يمكن تنزيلها'**
  String get storageBooksAvailable;

  /// No description provided for @bookPackDownload.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل'**
  String get bookPackDownload;

  /// No description provided for @continuousView.
  ///
  /// In ar, this message translates to:
  /// **'عرض متتالي'**
  String get continuousView;

  /// No description provided for @underVerseTitle.
  ///
  /// In ar, this message translates to:
  /// **'ما يظهر تحت الآية'**
  String get underVerseTitle;

  /// No description provided for @underArabicOnly.
  ///
  /// In ar, this message translates to:
  /// **'عربي فقط'**
  String get underArabicOnly;

  /// No description provided for @underTranslation.
  ///
  /// In ar, this message translates to:
  /// **'عربي مع ترجمة'**
  String get underTranslation;

  /// No description provided for @underTranslationHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر ترجمة أو اثنتين'**
  String get underTranslationHint;

  /// No description provided for @underMuyassar.
  ///
  /// In ar, this message translates to:
  /// **'عربي مع التفسير الميسر'**
  String get underMuyassar;

  /// No description provided for @splitTranslationLabel.
  ///
  /// In ar, this message translates to:
  /// **'بجانب الصفحة على الشاشات العريضة'**
  String get splitTranslationLabel;

  /// No description provided for @splitTranslationHint.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة كما هي، وبجانبها ما اخترته لآياتها'**
  String get splitTranslationHint;

  /// No description provided for @nextSurah.
  ///
  /// In ar, this message translates to:
  /// **'السورة التالية'**
  String get nextSurah;

  /// No description provided for @previousSurah.
  ///
  /// In ar, this message translates to:
  /// **'السورة السابقة'**
  String get previousSurah;

  /// No description provided for @hafsTextNote.
  ///
  /// In ar, this message translates to:
  /// **'النص هنا برواية حفص'**
  String get hafsTextNote;

  /// No description provided for @twoPageSpread.
  ///
  /// In ar, this message translates to:
  /// **'صفحتان متقابلتان'**
  String get twoPageSpread;

  /// No description provided for @twoPageSpreadHint.
  ///
  /// In ar, this message translates to:
  /// **'على الشاشات العريضة في الوضع الأفقي، كالمصحف المفتوح'**
  String get twoPageSpreadHint;

  /// No description provided for @oneVerse.
  ///
  /// In ar, this message translates to:
  /// **'آية آية'**
  String get oneVerse;

  /// No description provided for @oneVerseHint.
  ///
  /// In ar, this message translates to:
  /// **'آية واحدة في كل شاشة بخط كبير، والجهاز بالعرض'**
  String get oneVerseHint;

  /// No description provided for @oneVerseAutoOff.
  ///
  /// In ar, this message translates to:
  /// **'الانتقال التلقائي متوقف. اضغط لتشغيله'**
  String get oneVerseAutoOff;

  /// No description provided for @oneVerseAutoOn.
  ///
  /// In ar, this message translates to:
  /// **'ينتقل للآية التالية كل {seconds} ثانية. اضغط للتغيير'**
  String oneVerseAutoOn(String seconds);

  /// No description provided for @oneVerseAutoShort.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get oneVerseAutoShort;

  /// No description provided for @secondsShort.
  ///
  /// In ar, this message translates to:
  /// **'{n} ث'**
  String secondsShort(String n);

  /// No description provided for @searchScopeAll.
  ///
  /// In ar, this message translates to:
  /// **'كل المصحف'**
  String get searchScopeAll;

  /// No description provided for @searchScopeJuz.
  ///
  /// In ar, this message translates to:
  /// **'في جزء'**
  String get searchScopeJuz;

  /// No description provided for @searchScopeSurah.
  ///
  /// In ar, this message translates to:
  /// **'في سورة'**
  String get searchScopeSurah;

  /// No description provided for @whatsNewTitle.
  ///
  /// In ar, this message translates to:
  /// **'ما الجديد'**
  String get whatsNewTitle;

  /// No description provided for @whatsNewDone.
  ///
  /// In ar, this message translates to:
  /// **'حسنا'**
  String get whatsNewDone;

  /// No description provided for @newOneVerse.
  ///
  /// In ar, this message translates to:
  /// **'آية آية'**
  String get newOneVerse;

  /// No description provided for @newOneVerseBody.
  ///
  /// In ar, this message translates to:
  /// **'زر تحت الصفحة يقلب الموبايل بالعرض ويعرض آية واحدة بخط كبير، مع انتقال تلقائي اختياري.'**
  String get newOneVerseBody;

  /// No description provided for @newUnderVerse.
  ///
  /// In ar, this message translates to:
  /// **'الترجمة تحت الآية'**
  String get newUnderVerse;

  /// No description provided for @newUnderVerseBody.
  ///
  /// In ar, this message translates to:
  /// **'العرض المتتالي من أدوات الصفحة: ترجمة أو اثنتان أو التفسير الميسر تحت كل آية.'**
  String get newUnderVerseBody;

  /// No description provided for @newShare.
  ///
  /// In ar, this message translates to:
  /// **'النسخ والمشاركة'**
  String get newShare;

  /// No description provided for @newShareBody.
  ///
  /// In ar, this message translates to:
  /// **'انسخ الآية أو شاركها نصا أو صورة من صفحة المصحف، ولو امتدت على صفحتين.'**
  String get newShareBody;

  /// No description provided for @newSpread.
  ///
  /// In ar, this message translates to:
  /// **'صفحتان متقابلتان'**
  String get newSpread;

  /// No description provided for @newSpreadBody.
  ///
  /// In ar, this message translates to:
  /// **'على التابلت والشاشات العريضة بالعرض يظهر المصحف مفتوحا.'**
  String get newSpreadBody;

  /// No description provided for @newWidgets.
  ///
  /// In ar, this message translates to:
  /// **'أدوات الشاشة'**
  String get newWidgets;

  /// No description provided for @newWidgetsBody.
  ///
  /// In ar, this message translates to:
  /// **'ورد الختمة واختصارات القراءة والاستماع على الشاشة الرئيسية، وزر استماع في الإعدادات السريعة.'**
  String get newWidgetsBody;

  /// No description provided for @newBackup.
  ///
  /// In ar, this message translates to:
  /// **'النسخة الاحتياطية'**
  String get newBackup;

  /// No description provided for @newBackupBody.
  ///
  /// In ar, this message translates to:
  /// **'احفظ فواصلك وختمتك وملاحظاتك وإعداداتك في ملف واحد، واستعدها على أي جهاز.'**
  String get newBackupBody;

  /// No description provided for @carContinue.
  ///
  /// In ar, this message translates to:
  /// **'تابع من موضع القراءة'**
  String get carContinue;

  /// No description provided for @carReciters.
  ///
  /// In ar, this message translates to:
  /// **'القراء'**
  String get carReciters;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
