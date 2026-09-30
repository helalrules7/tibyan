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

  /// No description provided for @comingSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريبا'**
  String get comingSoon;

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
  /// **'اسحب المقبضين لتحديد الآيات'**
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

  /// No description provided for @mujawwad.
  ///
  /// In ar, this message translates to:
  /// **'مجود'**
  String get mujawwad;

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
