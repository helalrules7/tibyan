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

  /// No description provided for @crashConsentTitle.
  ///
  /// In ar, this message translates to:
  /// **'ساعدنا على تحسين تبيان'**
  String get crashConsentTitle;

  /// No description provided for @crashConsentBody.
  ///
  /// In ar, this message translates to:
  /// **'إذا تعطّل التطبيق، يمكنه أن يرسل إلينا تقريرًا تقنيًا مجهولًا يصف موضع العطل وطراز الجهاز وإصدار النظام، لنصلحه سريعًا. لا يتضمن التقرير اسمك ولا بريدك ولا عنوان IP ولا شيئًا مما تقرؤه أو تسجّله. تُحفظ التقارير على خادم تبيان وحده، ويمكنك تغيير اختيارك في أي وقت من الإعدادات.'**
  String get crashConsentBody;

  /// No description provided for @crashConsentAgree.
  ///
  /// In ar, this message translates to:
  /// **'أوافق'**
  String get crashConsentAgree;

  /// No description provided for @crashConsentDecline.
  ///
  /// In ar, this message translates to:
  /// **'لا، شكرًا'**
  String get crashConsentDecline;

  /// No description provided for @aboutTitle.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In ar, this message translates to:
  /// **'تبيان تطبيق لقراءة القرآن الكريم وتدبّره، وشيفرته مفتوحة. كل نص فيه من مصدر موثق مذكور بجانبه.'**
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
  /// **'طبعة ١٤٤١هـ من مجمع الملك فهد، مع تظليل الآية أثناء التلاوة.'**
  String get editionNewDesc;

  /// No description provided for @editionOld.
  ///
  /// In ar, this message translates to:
  /// **'مصحف المدينة: الطبعة القديمة'**
  String get editionOld;

  /// No description provided for @editionOldDesc.
  ///
  /// In ar, this message translates to:
  /// **'طبعة ١٤٠٥هـ المشهورة في التطبيقات القديمة، مع تظليل الكلمة.'**
  String get editionOldDesc;

  /// No description provided for @editionShamarly.
  ///
  /// In ar, this message translates to:
  /// **'مصحف الشمرلي (الطبعة المصرية)'**
  String get editionShamarly;

  /// No description provided for @editionShamarlyDesc.
  ///
  /// In ar, this message translates to:
  /// **'طبعة الشمرلي المصرية المعروفة، ٥٢٢ صفحة، مع تظليل الآية وتظليل الكلمة في كثير من الآيات.'**
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
  /// **'{n, plural, =0{لا آيات} =1{آية واحدة} =2{آيتان} few{{count} آيات} many{{count} آية} other{{count} آية}}'**
  String ayahCount(int n, String count);

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
  /// **'{n, plural, =0{لا مواضع} =1{موضع واحد} =2{موضعان} few{{count} مواضع} many{{count} موضعًا} other{{count} موضع}} يختلف فيها مصدرا النص (حدود جزأين، وأربعة مواضع في الرسم) معروضة على مراجع متخصص، ويتبع التطبيق نص تنزيل حتى يصدر القرار.'**
  String reviewNotesBody(int n, String count);

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
  /// **'{n, plural, =0{لا آيات} =1{آية واحدة} =2{آيتان} few{{count} آيات} many{{count} آية} other{{count} آية}}'**
  String versesCount(int n, String count);

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

  /// No description provided for @downloadsSectionMushaf.
  ///
  /// In ar, this message translates to:
  /// **'المصاحف'**
  String get downloadsSectionMushaf;

  /// No description provided for @downloadsSectionRecitations.
  ///
  /// In ar, this message translates to:
  /// **'القراءات الصوتية'**
  String get downloadsSectionRecitations;

  /// No description provided for @downloadsSectionResources.
  ///
  /// In ar, this message translates to:
  /// **'الموارد'**
  String get downloadsSectionResources;

  /// No description provided for @downloadsOnDevice.
  ///
  /// In ar, this message translates to:
  /// **'على الجهاز · {size} ميجا'**
  String downloadsOnDevice(String size);

  /// No description provided for @downloadsAvailable.
  ///
  /// In ar, this message translates to:
  /// **'متاح للتحميل · {size} ميجا'**
  String downloadsAvailable(String size);

  /// No description provided for @downloadsReciterOnDevice.
  ///
  /// In ar, this message translates to:
  /// **'على الجهاز: {done} / {total} · {size} ميجا'**
  String downloadsReciterOnDevice(String done, String total, String size);

  /// No description provided for @downloadsAvailableShort.
  ///
  /// In ar, this message translates to:
  /// **'متاح للتحميل'**
  String get downloadsAvailableShort;

  /// No description provided for @downloadsGoesOn.
  ///
  /// In ar, this message translates to:
  /// **'يكمل التحميل في الخلفية'**
  String get downloadsGoesOn;

  /// No description provided for @pause.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get pause;

  /// No description provided for @downloadsOpen.
  ///
  /// In ar, this message translates to:
  /// **'مركز التحميلات'**
  String get downloadsOpen;

  /// No description provided for @downloadsOpenHint.
  ///
  /// In ar, this message translates to:
  /// **'المصاحف والقراءات الصوتية والموارد: ما على الجهاز وما يحمَّل وما هو متاح'**
  String get downloadsOpenHint;

  /// No description provided for @audioDownloadResume.
  ///
  /// In ar, this message translates to:
  /// **'استئناف'**
  String get audioDownloadResume;

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

  /// No description provided for @shareAsMushafPages.
  ///
  /// In ar, this message translates to:
  /// **'صفحات المصحف كما هي'**
  String get shareAsMushafPages;

  /// No description provided for @shareAsMushafPagesHint.
  ///
  /// In ar, this message translates to:
  /// **'كل صورة صفحة من مصحفك كما تقرؤها، بدل كتابة الآيات من جديد'**
  String get shareAsMushafPagesHint;

  /// No description provided for @shareBrandColours.
  ///
  /// In ar, this message translates to:
  /// **'ألوان تبيان الأصلية'**
  String get shareBrandColours;

  /// No description provided for @shareBrandColoursHint.
  ///
  /// In ar, this message translates to:
  /// **'بدلًا من ألوان الواجهة والمصحف الحالية'**
  String get shareBrandColoursHint;

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

  /// No description provided for @englishTafsirVisibilityLabel.
  ///
  /// In ar, this message translates to:
  /// **'التفسير الإنجليزي'**
  String get englishTafsirVisibilityLabel;

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

  /// No description provided for @sajdahTimer.
  ///
  /// In ar, this message translates to:
  /// **'مؤقت سجدات التلاوة'**
  String get sajdahTimer;

  /// No description provided for @sajdahTimerHint.
  ///
  /// In ar, this message translates to:
  /// **'عند آية السجدة يتوقف الشيخ وتظهر بطاقة بأدعية السجود وعدّ تنازلي، ثم تُستكمل التلاوة'**
  String get sajdahTimerHint;

  /// No description provided for @sajdahTimerLength.
  ///
  /// In ar, this message translates to:
  /// **'مدة المؤقت'**
  String get sajdahTimerLength;

  /// No description provided for @sajdahCardLabel.
  ///
  /// In ar, this message translates to:
  /// **'سجدة تلاوة'**
  String get sajdahCardLabel;

  /// No description provided for @sajdahTapToContinue.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للاستكمال'**
  String get sajdahTapToContinue;

  /// No description provided for @sajdahContinue.
  ///
  /// In ar, this message translates to:
  /// **'استكمال'**
  String get sajdahContinue;

  /// No description provided for @sajdahSecondsLeft.
  ///
  /// In ar, this message translates to:
  /// **'{seconds, plural, =0{لم تبقَ ثوانٍ} =1{ثانية واحدة متبقية} =2{ثانيتان متبقيتان} few{{n} ثوانٍ متبقية} many{{n} ثانية متبقية} other{{n} ثانية متبقية}}'**
  String sajdahSecondsLeft(int seconds, String n);

  /// No description provided for @tapJumpLabel.
  ///
  /// In ar, this message translates to:
  /// **'عند لمس آية أثناء الاستماع'**
  String get tapJumpLabel;

  /// No description provided for @tapJumpHint.
  ///
  /// In ar, this message translates to:
  /// **'لمسة على آية في الصفحة تنقل الشيخ إليها'**
  String get tapJumpHint;

  /// No description provided for @tapJumpVerseStart.
  ///
  /// In ar, this message translates to:
  /// **'من أول الآية'**
  String get tapJumpVerseStart;

  /// No description provided for @tapJumpFromWord.
  ///
  /// In ar, this message translates to:
  /// **'من الكلمة الملموسة'**
  String get tapJumpFromWord;

  /// No description provided for @tapJumpNoTiming.
  ///
  /// In ar, this message translates to:
  /// **'هذه التلاوة لا تدعم الانتقال إلى آية'**
  String get tapJumpNoTiming;

  /// No description provided for @listenFromVerse.
  ///
  /// In ar, this message translates to:
  /// **'استمع من هذه الآية'**
  String get listenFromVerse;

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
  /// **'مركز التحميلات ({size} ميجا متاحة)'**
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
  /// **'{total, plural, =0{لا مواضع} =1{موضع واحد} =2{موضعان} few{{count} مواضع} many{{count} موضعًا} other{{count} موضع}} {verseTotal, plural, =0{في لا آيات} =1{في آية واحدة} =2{في آيتين} few{في {verses} آيات} many{في {verses} آية} other{في {verses} آية}}'**
  String searchCount(int total, String count, int verseTotal, String verses);

  /// No description provided for @searchMore.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =0{} =1{وآية أخرى} =2{وآيتان أخريان} few{و{count} آيات أخرى} many{و{count} آية أخرى} other{و{count} آية أخرى}}، ضيّق البحث لرؤيتها'**
  String searchMore(int n, String count);

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
  /// **'{surah} | الآية {ayah} · صفحة {page}'**
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
  /// **'مركز التحميلات'**
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

  /// No description provided for @khatmaPrimaryLabel.
  ///
  /// In ar, this message translates to:
  /// **'الختمة الأساسية'**
  String get khatmaPrimaryLabel;

  /// No description provided for @khatmaOtherPlans.
  ///
  /// In ar, this message translates to:
  /// **'ختمات أخرى'**
  String get khatmaOtherPlans;

  /// No description provided for @khatmaSetPrimary.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كأساسية'**
  String get khatmaSetPrimary;

  /// No description provided for @khatmaPause.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get khatmaPause;

  /// No description provided for @khatmaResume.
  ///
  /// In ar, this message translates to:
  /// **'استئناف'**
  String get khatmaResume;

  /// No description provided for @khatmaPaused.
  ///
  /// In ar, this message translates to:
  /// **'متوقفة مؤقتا'**
  String get khatmaPaused;

  /// No description provided for @khatmaStepPlan.
  ///
  /// In ar, this message translates to:
  /// **'الخطة'**
  String get khatmaStepPlan;

  /// No description provided for @khatmaStepSchedule.
  ///
  /// In ar, this message translates to:
  /// **'الجدول'**
  String get khatmaStepSchedule;

  /// No description provided for @khatmaStepReview.
  ///
  /// In ar, this message translates to:
  /// **'المراجعة'**
  String get khatmaStepReview;

  /// No description provided for @khatmaLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل بيانات إعداد الختمة: {error}'**
  String khatmaLoadFailed(String error);

  /// No description provided for @khatmaCreateFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إنشاء الختمة: {error}'**
  String khatmaCreateFailed(String error);

  /// No description provided for @khatmaKindLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الخطة'**
  String get khatmaKindLabel;

  /// No description provided for @khatmaSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الختمة'**
  String get khatmaSettings;

  /// No description provided for @khatmaTabPlan.
  ///
  /// In ar, this message translates to:
  /// **'الخطة'**
  String get khatmaTabPlan;

  /// No description provided for @khatmaTabStats.
  ///
  /// In ar, this message translates to:
  /// **'الإحصاءات'**
  String get khatmaTabStats;

  /// No description provided for @khatmaStatsPageEquivalents.
  ///
  /// In ar, this message translates to:
  /// **'مكافئ الصفحات'**
  String get khatmaStatsPageEquivalents;

  /// No description provided for @khatmaStatsSessions.
  ///
  /// In ar, this message translates to:
  /// **'جلسات القراءة'**
  String get khatmaStatsSessions;

  /// No description provided for @khatmaStatsMinutes.
  ///
  /// In ar, this message translates to:
  /// **'دقائق القراءة'**
  String get khatmaStatsMinutes;

  /// No description provided for @khatmaStatsNoActivity.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد قراءة مسجلة لهذه الختمة في هذه الفترة.'**
  String get khatmaStatsNoActivity;

  /// No description provided for @khatmaStatsWeek.
  ///
  /// In ar, this message translates to:
  /// **'الأسبوع'**
  String get khatmaStatsWeek;

  /// No description provided for @khatmaStatsMonth.
  ///
  /// In ar, this message translates to:
  /// **'الشهر'**
  String get khatmaStatsMonth;

  /// No description provided for @khatmaStatsYear.
  ///
  /// In ar, this message translates to:
  /// **'السنة'**
  String get khatmaStatsYear;

  /// No description provided for @khatmaStatsPreviousPeriod.
  ///
  /// In ar, this message translates to:
  /// **'الفترة السابقة'**
  String get khatmaStatsPreviousPeriod;

  /// No description provided for @khatmaStatsNextPeriod.
  ///
  /// In ar, this message translates to:
  /// **'الفترة التالية'**
  String get khatmaStatsNextPeriod;

  /// No description provided for @khatmaReminderForPlan.
  ///
  /// In ar, this message translates to:
  /// **'الختمة: {plan}'**
  String khatmaReminderForPlan(String plan);

  /// No description provided for @khatmaReminderMissedTitle.
  ///
  /// In ar, this message translates to:
  /// **'ما زال هناك وقت لورد {plan}'**
  String khatmaReminderMissedTitle(String plan);

  /// No description provided for @khatmaReminderMissedBody.
  ///
  /// In ar, this message translates to:
  /// **'ورد اليوم: من صفحة {from} إلى صفحة {to}'**
  String khatmaReminderMissedBody(String from, String to);

  /// No description provided for @khatmaReminderRecoveryTitle.
  ///
  /// In ar, this message translates to:
  /// **'خطة تعويض لطيفة لختمة {plan}'**
  String khatmaReminderRecoveryTitle(String plan);

  /// No description provided for @khatmaReminderRecoveryBody.
  ///
  /// In ar, this message translates to:
  /// **'ورد اليوم من صفحة {from} إلى صفحة {to}. افتح الخطة للاطلاع على خيارات التعويض.'**
  String khatmaReminderRecoveryBody(String from, String to);

  /// No description provided for @khatmaReminderTargetTitle.
  ///
  /// In ar, this message translates to:
  /// **'بقي يوم على موعد ختمة {plan}'**
  String khatmaReminderTargetTitle(String plan);

  /// No description provided for @khatmaReminderTargetBody.
  ///
  /// In ar, this message translates to:
  /// **'راجع تقدمك وخطتك قبل الموعد.'**
  String get khatmaReminderTargetBody;

  /// No description provided for @khatmaReminderCompletedTitle.
  ///
  /// In ar, this message translates to:
  /// **'أتممت ختمة {plan}'**
  String khatmaReminderCompletedTitle(String plan);

  /// No description provided for @khatmaReminderCompletedBody.
  ///
  /// In ar, this message translates to:
  /// **'أتممت الختمة. تقبّل الله منك.'**
  String get khatmaReminderCompletedBody;

  /// No description provided for @khatmaReminderPlanLimit.
  ///
  /// In ar, this message translates to:
  /// **'يمكن تفعيل التذكيرات لعشرين ختمة مفتوحة كحد أقصى.'**
  String get khatmaReminderPlanLimit;

  /// No description provided for @khatmaSaveSettings.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الإعدادات'**
  String get khatmaSaveSettings;

  /// No description provided for @khatmaSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ إعدادات الختمة: {error}'**
  String khatmaSaveFailed(String error);

  /// No description provided for @khatmaAutoRestart.
  ///
  /// In ar, this message translates to:
  /// **'بدء الخطة من جديد عند إكمالها'**
  String get khatmaAutoRestart;

  /// No description provided for @khatmaReplan.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الخطة'**
  String get khatmaReplan;

  /// No description provided for @khatmaCatchUpToday.
  ///
  /// In ar, this message translates to:
  /// **'إنجاز الورد الفائت اليوم'**
  String get khatmaCatchUpToday;

  /// No description provided for @khatmaCatchUpGradually.
  ///
  /// In ar, this message translates to:
  /// **'تعويض الورد تدريجيا'**
  String get khatmaCatchUpGradually;

  /// No description provided for @khatmaCompletionBody.
  ///
  /// In ar, this message translates to:
  /// **'أتممت هذه الختمة. تقبّل الله منك.'**
  String get khatmaCompletionBody;

  /// No description provided for @khatmaReusePlan.
  ///
  /// In ar, this message translates to:
  /// **'استخدام هذه الخطة مرة أخرى'**
  String get khatmaReusePlan;

  /// No description provided for @khatmaKindFull.
  ///
  /// In ar, this message translates to:
  /// **'القرآن كاملا'**
  String get khatmaKindFull;

  /// No description provided for @khatmaKindPartial.
  ///
  /// In ar, this message translates to:
  /// **'نطاق محدد'**
  String get khatmaKindPartial;

  /// No description provided for @khatmaKindDaily.
  ///
  /// In ar, this message translates to:
  /// **'ورد يومي'**
  String get khatmaKindDaily;

  /// No description provided for @khatmaKindCustom.
  ///
  /// In ar, this message translates to:
  /// **'نطاق مخصص'**
  String get khatmaKindCustom;

  /// No description provided for @khatmaPresetLabel.
  ///
  /// In ar, this message translates to:
  /// **'قالب جاهز'**
  String get khatmaPresetLabel;

  /// No description provided for @khatmaPresetCustom.
  ///
  /// In ar, this message translates to:
  /// **'خطة مخصصة'**
  String get khatmaPresetCustom;

  /// No description provided for @khatmaPresetMonth.
  ///
  /// In ar, this message translates to:
  /// **'ختمة في شهر'**
  String get khatmaPresetMonth;

  /// No description provided for @khatmaPresetRamadan30.
  ///
  /// In ar, this message translates to:
  /// **'رمضان: {n, plural, =0{لا أيام} =1{يوم واحد} =2{يومان} few{{days} أيام} many{{days} يومًا} other{{days} يوم}}'**
  String khatmaPresetRamadan30(int n, String days);

  /// No description provided for @khatmaPresetRamadanTwice.
  ///
  /// In ar, this message translates to:
  /// **'ختمتان في رمضان'**
  String get khatmaPresetRamadanTwice;

  /// No description provided for @khatmaPresetBeforeLastTen.
  ///
  /// In ar, this message translates to:
  /// **'قبل العشر الأواخر'**
  String get khatmaPresetBeforeLastTen;

  /// No description provided for @khatmaPresetWeekly.
  ///
  /// In ar, this message translates to:
  /// **'ختمة في أسبوع'**
  String get khatmaPresetWeekly;

  /// No description provided for @khatmaPresetDailyJuz.
  ///
  /// In ar, this message translates to:
  /// **'جزء يوميا'**
  String get khatmaPresetDailyJuz;

  /// No description provided for @khatmaFromSurah.
  ///
  /// In ar, this message translates to:
  /// **'من سورة'**
  String get khatmaFromSurah;

  /// No description provided for @khatmaToSurah.
  ///
  /// In ar, this message translates to:
  /// **'إلى سورة'**
  String get khatmaToSurah;

  /// No description provided for @khatmaFromAyah.
  ///
  /// In ar, this message translates to:
  /// **'من آية'**
  String get khatmaFromAyah;

  /// No description provided for @khatmaToAyah.
  ///
  /// In ar, this message translates to:
  /// **'إلى آية'**
  String get khatmaToAyah;

  /// No description provided for @khatmaRangeError.
  ///
  /// In ar, this message translates to:
  /// **'اختر آية بداية تسبق آية النهاية.'**
  String get khatmaRangeError;

  /// No description provided for @khatmaScheduleMode.
  ///
  /// In ar, this message translates to:
  /// **'طريقة توزيع الورد'**
  String get khatmaScheduleMode;

  /// No description provided for @khatmaScheduleAdaptive.
  ///
  /// In ar, this message translates to:
  /// **'متغير حسب التقدم'**
  String get khatmaScheduleAdaptive;

  /// No description provided for @khatmaScheduleFixed.
  ///
  /// In ar, this message translates to:
  /// **'جدول ثابت'**
  String get khatmaScheduleFixed;

  /// No description provided for @khatmaRestDays.
  ///
  /// In ar, this message translates to:
  /// **'أيام راحة (اختياري)'**
  String get khatmaRestDays;

  /// No description provided for @khatmaAtLeastOneReadingDay.
  ///
  /// In ar, this message translates to:
  /// **'اترك يوما واحدا على الأقل للقراءة كل أسبوع.'**
  String get khatmaAtLeastOneReadingDay;

  /// No description provided for @khatmaCountingMode.
  ///
  /// In ar, this message translates to:
  /// **'طريقة احتساب القراءة'**
  String get khatmaCountingMode;

  /// No description provided for @khatmaCountWirdConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد إتمام الورد (الموصى به)'**
  String get khatmaCountWirdConfirm;

  /// No description provided for @khatmaCountWirdConfirmSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'لا يُحتسب ورد اليوم إلا بعد أن تؤكد إتمامه بنفسك'**
  String get khatmaCountWirdConfirmSubtitle;

  /// No description provided for @wirdConfirmDone.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد إتمام الورد'**
  String get wirdConfirmDone;

  /// No description provided for @wirdCompletedCelebration.
  ///
  /// In ar, this message translates to:
  /// **'مبارك! سُجِّل إتمام ورد اليوم'**
  String get wirdCompletedCelebration;

  /// No description provided for @wirdEndOfPortion.
  ///
  /// In ar, this message translates to:
  /// **'وصلت لنهاية ورد اليوم'**
  String get wirdEndOfPortion;

  /// No description provided for @wirdEndOfPortionQuestion.
  ///
  /// In ar, this message translates to:
  /// **'هل أتممت قراءة ورد اليوم؟'**
  String get wirdEndOfPortionQuestion;

  /// No description provided for @wirdCompletedToday.
  ///
  /// In ar, this message translates to:
  /// **'تم إتمام ورد اليوم'**
  String get wirdCompletedToday;

  /// No description provided for @wirdLater.
  ///
  /// In ar, this message translates to:
  /// **'لاحقاً'**
  String get wirdLater;

  /// No description provided for @khatmaCountAuto.
  ///
  /// In ar, this message translates to:
  /// **'احتساب تلقائي'**
  String get khatmaCountAuto;

  /// No description provided for @khatmaCountAsk.
  ///
  /// In ar, this message translates to:
  /// **'السؤال في كل مرة'**
  String get khatmaCountAsk;

  /// No description provided for @khatmaCountManual.
  ///
  /// In ar, this message translates to:
  /// **'عند تحديدها كمقروءة فقط'**
  String get khatmaCountManual;

  /// No description provided for @khatmaMakePrimary.
  ///
  /// In ar, this message translates to:
  /// **'جعلها الختمة الأساسية'**
  String get khatmaMakePrimary;

  /// No description provided for @khatmaUnitRub.
  ///
  /// In ar, this message translates to:
  /// **'ربع حزب'**
  String get khatmaUnitRub;

  /// No description provided for @khatmaReviewRange.
  ///
  /// In ar, this message translates to:
  /// **'النطاق: {from}–{to}'**
  String khatmaReviewRange(String from, String to);

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
  /// **'نحو {n, plural, =0{لا صفحات} =1{صفحة واحدة} =2{صفحتين} few{{count} صفحات} many{{count} صفحة} other{{count} صفحة}} في اليوم'**
  String khatmaAboutPerDay(int n, String count);

  /// No description provided for @khatmaDuration.
  ///
  /// In ar, this message translates to:
  /// **'المدة: {n, plural, =0{لا أيام} =1{يوم واحد} =2{يومان} few{{count} أيام} many{{count} يومًا} other{{count} يوم}}، والختم يوم {date}'**
  String khatmaDuration(int n, String count, String date);

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
  /// **'{done} من {n, plural, =0{لا صفحات} =1{صفحة واحدة} =2{صفحتين} few{{total} صفحات} many{{total} صفحة} other{{total} صفحة}}'**
  String khatmaProgress(String done, int n, String total);

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
  /// **'ينضم ما فات إلى ورد اليوم. اختر إنجازه اليوم، أو تعويضه تدريجيا، أو توزيع الباقي، أو مد موعد الختم.'**
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
  /// **'قرأت اليوم.'**
  String get streakReadToday;

  /// No description provided for @streakWelcome.
  ///
  /// In ar, this message translates to:
  /// **'مرحبا بعودتك. تابع من حيث وقفت.'**
  String get streakWelcome;

  /// No description provided for @readDaysOfLast.
  ///
  /// In ar, this message translates to:
  /// **'قرأت {read} من {n, plural, =0{لا أيام} =1{آخر يوم} =2{آخر يومين} few{آخر {days} أيام} many{آخر {days} يومًا} other{آخر {days} يوم}}'**
  String readDaysOfLast(String read, int n, String days);

  /// No description provided for @streakNotesToggle.
  ///
  /// In ar, this message translates to:
  /// **'رسائل الاستمرار'**
  String get streakNotesToggle;

  /// No description provided for @streakNotesHint.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات هادئة عن قراءتك، لا تعدّ الأيام المتتالية ولا تعرض الأيام الفائتة.'**
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
  /// **'سورة {surah} | آية {ayah}'**
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
  /// **'{n, plural, =0{لا آيات} =1{آية واحدة} =2{آيتان} few{{count} آيات} many{{count} آية} other{{count} آية}}'**
  String searchMeaningCount(int n, String count);

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

  /// No description provided for @deleteSurahDownloadTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف تنزيل سورة {surah}؟'**
  String deleteSurahDownloadTitle(String surah);

  /// No description provided for @deleteSurahDownloadBody.
  ///
  /// In ar, this message translates to:
  /// **'ستُحذف تلاوة هذه السورة المنزّلة من الجهاز، ويمكنك تنزيلها مرة أخرى متى شئت.'**
  String get deleteSurahDownloadBody;

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
  /// **'المد العارض واللين (٢ أو ٤ أو ٦ حركات)'**
  String get tajweedMadd246;

  /// No description provided for @tajweedMaddMuttasil.
  ///
  /// In ar, this message translates to:
  /// **'المد المتصل (٤ أو ٥ حركات)'**
  String get tajweedMaddMuttasil;

  /// No description provided for @tajweedMaddMunfasil.
  ///
  /// In ar, this message translates to:
  /// **'المد المنفصل (٤ أو ٥ حركات)'**
  String get tajweedMaddMunfasil;

  /// No description provided for @tajweedMadd6.
  ///
  /// In ar, this message translates to:
  /// **'المد اللازم (٦ حركات)'**
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

  /// No description provided for @reciterPhotoWithPermission.
  ///
  /// In ar, this message translates to:
  /// **'صور بترخيص المشاع الإبداعي'**
  String get reciterPhotoWithPermission;

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
  /// **'مشاركة كصورة'**
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

  /// No description provided for @shareSurahImage.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة السورة كصورة'**
  String get shareSurahImage;

  /// No description provided for @shareImageTitle.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة كصورة'**
  String get shareImageTitle;

  /// No description provided for @shareImageOf.
  ///
  /// In ar, this message translates to:
  /// **'{n} من {total}'**
  String shareImageOf(String n, String total);

  /// No description provided for @sharePreviousImage.
  ///
  /// In ar, this message translates to:
  /// **'الصورة السابقة'**
  String get sharePreviousImage;

  /// No description provided for @shareNextImage.
  ///
  /// In ar, this message translates to:
  /// **'الصورة التالية'**
  String get shareNextImage;

  /// No description provided for @shareButton.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get shareButton;

  /// No description provided for @saveToPhotos.
  ///
  /// In ar, this message translates to:
  /// **'حفظ في الصور'**
  String get saveToPhotos;

  /// No description provided for @savedToPhotos.
  ///
  /// In ar, this message translates to:
  /// **'حُفظت الصور'**
  String get savedToPhotos;

  /// No description provided for @savedToFolder.
  ///
  /// In ar, this message translates to:
  /// **'حُفظت الصور في {folder}'**
  String savedToFolder(String folder);

  /// No description provided for @saveToPhotosFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الحفظ في الصور'**
  String get saveToPhotosFailed;

  /// No description provided for @shareImageRiwayaUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'نص هذه الرواية وخطها غير متاحين على هذا الجهاز بعد، فلا تُشارك آياتها صورةً. نزّل صفحات الرواية أولا.'**
  String get shareImageRiwayaUnavailable;

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

  /// No description provided for @munasabatTitle.
  ///
  /// In ar, this message translates to:
  /// **'المناسبات'**
  String get munasabatTitle;

  /// No description provided for @munasabatCount.
  ///
  /// In ar, this message translates to:
  /// **'المناسبات ({count})'**
  String munasabatCount(String count);

  /// No description provided for @wujuhTitle.
  ///
  /// In ar, this message translates to:
  /// **'الوجوه والنظائر'**
  String get wujuhTitle;

  /// No description provided for @bookKindTafsir.
  ///
  /// In ar, this message translates to:
  /// **'تفسير'**
  String get bookKindTafsir;

  /// No description provided for @bookEntryVerses.
  ///
  /// In ar, this message translates to:
  /// **'الآيات {from}–{to}'**
  String bookEntryVerses(String from, String to);

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

  /// No description provided for @landscapeFitLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة في الوضع الأفقي'**
  String get landscapeFitLabel;

  /// No description provided for @landscapeFitWidth.
  ///
  /// In ar, this message translates to:
  /// **'بعرض الشاشة'**
  String get landscapeFitWidth;

  /// No description provided for @landscapeFitWidthHint.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة بعرض الشاشة، وتُقرأ بالتمرير لأسفل'**
  String get landscapeFitWidthHint;

  /// No description provided for @landscapeFitPage.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة كاملة'**
  String get landscapeFitPage;

  /// No description provided for @landscapeFitPageHint.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة كلها على ارتفاع الشاشة'**
  String get landscapeFitPageHint;

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
  /// **'ينتقل للآية التالية {n, plural, =0{فورًا} =1{كل ثانية} =2{كل ثانيتين} few{كل {seconds} ثوانٍ} many{كل {seconds} ثانية} other{كل {seconds} ثانية}}. اضغط للتغيير'**
  String oneVerseAutoOn(int n, String seconds);

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
  /// **'انسخ الآية أو شاركها نصا أو صورة بتصميم تبيان، ولو امتدت على صفحات. واضغط مطولا على اسم السورة أعلى الصفحة لمشاركة السورة كلها صورا.'**
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

  /// No description provided for @pagesMapCurrent.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة الحالية'**
  String get pagesMapCurrent;

  /// No description provided for @pagesMapRead.
  ///
  /// In ar, this message translates to:
  /// **'مقروءة في الختمة'**
  String get pagesMapRead;

  /// No description provided for @pagesMapMarked.
  ///
  /// In ar, this message translates to:
  /// **'فيها فاصل'**
  String get pagesMapMarked;

  /// No description provided for @pagesRange.
  ///
  /// In ar, this message translates to:
  /// **'ص {first}–{last}'**
  String pagesRange(String first, String last);

  /// No description provided for @pagesMapJuzRead.
  ///
  /// In ar, this message translates to:
  /// **'قُرئ {read} من {total}'**
  String pagesMapJuzRead(String read, String total);

  /// No description provided for @focusModeTitle.
  ///
  /// In ar, this message translates to:
  /// **'وضع التركيز'**
  String get focusModeTitle;

  /// No description provided for @focusModeHint.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة وحدها بلا إطار ولا شيء تحتها، وشريط رفيع في الأعلى'**
  String get focusModeHint;

  /// No description provided for @focusToolsLabel.
  ///
  /// In ar, this message translates to:
  /// **'إظهار الأدوات'**
  String get focusToolsLabel;

  /// No description provided for @focusToolsButton.
  ///
  /// In ar, this message translates to:
  /// **'الزرار البسيط'**
  String get focusToolsButton;

  /// No description provided for @focusToolsButtonHint.
  ///
  /// In ar, this message translates to:
  /// **'ثلاثة أزرار صغيرة في الشريط العلوي'**
  String get focusToolsButtonHint;

  /// No description provided for @focusToolsMenu.
  ///
  /// In ar, this message translates to:
  /// **'القائمة'**
  String get focusToolsMenu;

  /// No description provided for @focusToolsMenuHint.
  ///
  /// In ar, this message translates to:
  /// **'ضغطة مطولة على الصفحة تفتح نافذة فيها كل الأدوات'**
  String get focusToolsMenuHint;

  /// No description provided for @pageTurnLabel.
  ///
  /// In ar, this message translates to:
  /// **'تأثير قلب الصفحة'**
  String get pageTurnLabel;

  /// No description provided for @pageTurnNormal.
  ///
  /// In ar, this message translates to:
  /// **'طبيعي'**
  String get pageTurnNormal;

  /// No description provided for @pageTurnNormalHint.
  ///
  /// In ar, this message translates to:
  /// **'تنزلق الصفحة جانبًا'**
  String get pageTurnNormalHint;

  /// No description provided for @pageTurnCurl.
  ///
  /// In ar, this message translates to:
  /// **'قلب ثلاثي الأبعاد'**
  String get pageTurnCurl;

  /// No description provided for @pageTurnCurlHint.
  ///
  /// In ar, this message translates to:
  /// **'تنقلب الصفحة كورق المصحف'**
  String get pageTurnCurlHint;

  /// No description provided for @pageTurnBend.
  ///
  /// In ar, this message translates to:
  /// **'انحناء الورقة'**
  String get pageTurnBend;

  /// No description provided for @pageTurnBendHint.
  ///
  /// In ar, this message translates to:
  /// **'تلتف الصفحة مع إصبعك كالورق ويظهر ظهرها'**
  String get pageTurnBendHint;

  /// No description provided for @pageTurnFold.
  ///
  /// In ar, this message translates to:
  /// **'انحناء خفيف'**
  String get pageTurnFold;

  /// No description provided for @pageTurnFoldHint.
  ///
  /// In ar, this message translates to:
  /// **'ينثني طرف الصفحة مع إصبعك، أخف على الجهاز'**
  String get pageTurnFoldHint;

  /// No description provided for @pageTurnFade.
  ///
  /// In ar, this message translates to:
  /// **'تلاشي'**
  String get pageTurnFade;

  /// No description provided for @pageTurnFadeHint.
  ///
  /// In ar, this message translates to:
  /// **'تظهر الصفحة التالية فوق السابقة بهدوء'**
  String get pageTurnFadeHint;

  /// No description provided for @pageFillLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملء الشاشة'**
  String get pageFillLabel;

  /// No description provided for @pageFillLines.
  ///
  /// In ar, this message translates to:
  /// **'توزيع السطور'**
  String get pageFillLines;

  /// No description provided for @pageFillLinesHint.
  ///
  /// In ar, this message translates to:
  /// **'كل سطر بعرض الشاشة، والسطور موزعة على طولها'**
  String get pageFillLinesHint;

  /// No description provided for @pageFillStretch.
  ///
  /// In ar, this message translates to:
  /// **'توزيع + مط خفيف'**
  String get pageFillStretch;

  /// No description provided for @pageFillStretchHint.
  ///
  /// In ar, this message translates to:
  /// **'ومط أفقي حتى ١٢٪ حيث تملأ الصفحة الطول'**
  String get pageFillStretchHint;

  /// No description provided for @pageFillFull.
  ///
  /// In ar, this message translates to:
  /// **'مط كامل'**
  String get pageFillFull;

  /// No description provided for @pageFillFullHint.
  ///
  /// In ar, this message translates to:
  /// **'تملأ الصفحة الشاشة طولا وعرضا، ويتغير بذلك شكل الحروف'**
  String get pageFillFullHint;

  /// No description provided for @playerStyleLabel.
  ///
  /// In ar, this message translates to:
  /// **'شكل المشغل'**
  String get playerStyleLabel;

  /// No description provided for @playerStyleAuto.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get playerStyleAuto;

  /// No description provided for @playerStyleAutoHint.
  ///
  /// In ar, this message translates to:
  /// **'العادي في القراءة، وشكل وضع التركيز مع وضع التركيز'**
  String get playerStyleAutoHint;

  /// No description provided for @playerStyleNormal.
  ///
  /// In ar, this message translates to:
  /// **'العادي'**
  String get playerStyleNormal;

  /// No description provided for @playerStylePill.
  ///
  /// In ar, this message translates to:
  /// **'وضع التركيز'**
  String get playerStylePill;

  /// No description provided for @playerStylePillHint.
  ///
  /// In ar, this message translates to:
  /// **'صغير وشفاف، فيه تشغيل وإعدادات وإغلاق'**
  String get playerStylePillHint;

  /// No description provided for @playerStyleButton.
  ///
  /// In ar, this message translates to:
  /// **'الزر الواحد'**
  String get playerStyleButton;

  /// No description provided for @playerStyleButtonHint.
  ///
  /// In ar, this message translates to:
  /// **'زر صغير: ضغطة للتشغيل والإيقاف، وضغطة مطولة للقائمة'**
  String get playerStyleButtonHint;

  /// No description provided for @focusExit.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء التركيز'**
  String get focusExit;

  /// No description provided for @focusTools.
  ///
  /// In ar, this message translates to:
  /// **'الأدوات'**
  String get focusTools;

  /// No description provided for @focusShowTools.
  ///
  /// In ar, this message translates to:
  /// **'إظهار الأدوات'**
  String get focusShowTools;

  /// No description provided for @focusHideTools.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء الأدوات'**
  String get focusHideTools;

  /// No description provided for @focusMenus.
  ///
  /// In ar, this message translates to:
  /// **'القوائم'**
  String get focusMenus;

  /// No description provided for @focusPageTools.
  ///
  /// In ar, this message translates to:
  /// **'أدوات الصفحة'**
  String get focusPageTools;

  /// No description provided for @playerFull.
  ///
  /// In ar, this message translates to:
  /// **'المشغل كاملًا'**
  String get playerFull;

  /// No description provided for @tajweedMarksSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أحكام التجويد: ألوانها ومواضعها'**
  String get tajweedMarksSubtitle;

  /// No description provided for @tajweedMarksHint.
  ///
  /// In ar, this message translates to:
  /// **'كل حكم بلونه في صفحات المصحف، ومواضعه في المصحف كله. اضغط الحكم لتعرض مواضعه، واضغط الموضع لتفتح صفحته.'**
  String get tajweedMarksHint;

  /// No description provided for @tajweedRuleCount.
  ///
  /// In ar, this message translates to:
  /// **'الآيات: {verses} · الحروف الملونة: {letters}'**
  String tajweedRuleCount(String verses, String letters);

  /// No description provided for @tajweedPlaceAt.
  ///
  /// In ar, this message translates to:
  /// **'{surah} {ayah} · الصفحة {page}'**
  String tajweedPlaceAt(String surah, String ayah, String page);

  /// No description provided for @tajweedIndexColorNote.
  ///
  /// In ar, this message translates to:
  /// **'الألوان كما تُرسم في الصفحات الآن: اختيارك، أو اللون الافتراضي. وتُغيَّر من «شكل المصحف».'**
  String get tajweedIndexColorNote;

  /// No description provided for @tajweedIndexLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذرت قراءة مواضع هذا الحكم.'**
  String get tajweedIndexLoadError;

  /// No description provided for @tajweedMarksInkNote.
  ///
  /// In ar, this message translates to:
  /// **'حين يقع الحكم على علامة وحدها (مثل الميم الصغيرة) تبقى العلامة هنا بلون النص: الخط لا يلوّن العلامة دون جزء من حرفها. وتظهر ملونة في صفحة المصحف.'**
  String get tajweedMarksInkNote;

  /// No description provided for @assistantTitle.
  ///
  /// In ar, this message translates to:
  /// **'المساعد'**
  String get assistantTitle;

  /// No description provided for @assistantIntro.
  ///
  /// In ar, this message translates to:
  /// **'المساعدة في استخدام التطبيق والمصحف'**
  String get assistantIntro;

  /// No description provided for @tajweedMarksTitle.
  ///
  /// In ar, this message translates to:
  /// **'علامات التجويد'**
  String get tajweedMarksTitle;

  /// No description provided for @moreLabel.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get moreLabel;

  /// No description provided for @wirdIndicator.
  ///
  /// In ar, this message translates to:
  /// **'ورد اليوم: {read} من {total}'**
  String wirdIndicator(String read, String total);

  /// No description provided for @khatmaContinueMine.
  ///
  /// In ar, this message translates to:
  /// **'متابعة ختمتي'**
  String get khatmaContinueMine;

  /// No description provided for @askCreditLine.
  ///
  /// In ar, this message translates to:
  /// **'قراءتك الأخيرة تدخل في «{plan}». أتُحتسب لها؟'**
  String askCreditLine(String plan);

  /// No description provided for @askCreditCount.
  ///
  /// In ar, this message translates to:
  /// **'احتسب'**
  String get askCreditCount;

  /// No description provided for @askCreditNo.
  ///
  /// In ar, this message translates to:
  /// **'لا'**
  String get askCreditNo;

  /// No description provided for @khatmaPendingTitle.
  ///
  /// In ar, this message translates to:
  /// **'قراءات تنتظر الاحتساب'**
  String get khatmaPendingTitle;

  /// No description provided for @khatmaPendingOn.
  ///
  /// In ar, this message translates to:
  /// **'قراءة {date}'**
  String khatmaPendingOn(String date);

  /// Short home-tile label for the recitation check.
  ///
  /// In ar, this message translates to:
  /// **'التسميع'**
  String get tasmeeTileLabel;

  /// No description provided for @tasmeeTitle.
  ///
  /// In ar, this message translates to:
  /// **'التسميع'**
  String get tasmeeTitle;

  /// No description provided for @tasmeeDescription.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ من حفظك؛ يسمعك تبيان على جهازك ويُظهر الكلمات ويعلّم مواضع الخطأ. لا يُرسل الصوت ولا يُقيَّم التجويد.'**
  String get tasmeeDescription;

  /// No description provided for @tasmeeSelectRange.
  ///
  /// In ar, this message translates to:
  /// **'اختر نطاق التسميع'**
  String get tasmeeSelectRange;

  /// No description provided for @tasmeeSurah.
  ///
  /// In ar, this message translates to:
  /// **'السورة'**
  String get tasmeeSurah;

  /// No description provided for @tasmeeJuz.
  ///
  /// In ar, this message translates to:
  /// **'الجزء'**
  String get tasmeeJuz;

  /// No description provided for @tasmeeHizb.
  ///
  /// In ar, this message translates to:
  /// **'الحزب'**
  String get tasmeeHizb;

  /// No description provided for @tasmeeFirstHalf.
  ///
  /// In ar, this message translates to:
  /// **'الأول'**
  String get tasmeeFirstHalf;

  /// No description provided for @tasmeeSecondHalf.
  ///
  /// In ar, this message translates to:
  /// **'الثاني'**
  String get tasmeeSecondHalf;

  /// No description provided for @tasmeeFromSecondQuarter.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ من الربع الثاني'**
  String get tasmeeFromSecondQuarter;

  /// No description provided for @tasmeeMode.
  ///
  /// In ar, this message translates to:
  /// **'طريقة التسميع'**
  String get tasmeeMode;

  /// No description provided for @tasmeeContinuous.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get tasmeeContinuous;

  /// No description provided for @tasmeeVerseByVerse.
  ///
  /// In ar, this message translates to:
  /// **'آية بآية'**
  String get tasmeeVerseByVerse;

  /// No description provided for @tasmeeInvalidRange.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من أرقام النطاق.'**
  String get tasmeeInvalidRange;

  /// No description provided for @tasmeeDownloadModel.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل نموذج التسميع'**
  String get tasmeeDownloadModel;

  /// No description provided for @tasmeeListening.
  ///
  /// In ar, this message translates to:
  /// **'أستمع إليك'**
  String get tasmeeListening;

  /// No description provided for @tasmeeNotListening.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للبدء واقرأ من حفظك'**
  String get tasmeeNotListening;

  /// No description provided for @tasmeeModelLoad.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تجهيز النموذج'**
  String get tasmeeModelLoad;

  /// No description provided for @tasmeeWordWrong.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get tasmeeWordWrong;

  /// No description provided for @tasmeeWordSkipped.
  ///
  /// In ar, this message translates to:
  /// **'متجاوزة'**
  String get tasmeeWordSkipped;

  /// No description provided for @tasmeeSessionComplete.
  ///
  /// In ar, this message translates to:
  /// **'انتهى التسميع'**
  String get tasmeeSessionComplete;

  /// No description provided for @tasmeeSessionDoubtful.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =0{لا كلمات مشكوك فيها} =1{كلمة واحدة مشكوك فيها، لم تُحسب في الدقة} =2{كلمتان مشكوك فيهما، لم تُحسبا في الدقة} few{{count} كلمات مشكوك فيها، لم تُحسب في الدقة} many{{count} كلمة مشكوك فيها، لم تُحسب في الدقة} other{{count} كلمة مشكوك فيها، لم تُحسب في الدقة}}'**
  String tasmeeSessionDoubtful(int n, String count);

  /// No description provided for @tasmeeAccuracy.
  ///
  /// In ar, this message translates to:
  /// **'الدقة'**
  String get tasmeeAccuracy;

  /// No description provided for @tasmeeAccuracyShort.
  ///
  /// In ar, this message translates to:
  /// **'الدقة'**
  String get tasmeeAccuracyShort;

  /// No description provided for @tasmeeAcrossSurahs.
  ///
  /// In ar, this message translates to:
  /// **'{fromSurah} {fromAyah} – {toSurah} {toAyah} · {mode}'**
  String tasmeeAcrossSurahs(
    String fromSurah,
    String fromAyah,
    String toSurah,
    String toAyah,
    String mode,
  );

  /// No description provided for @tasmeeAyah.
  ///
  /// In ar, this message translates to:
  /// **'آية'**
  String get tasmeeAyah;

  /// No description provided for @tasmeeCancelDownload.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التنزيل'**
  String get tasmeeCancelDownload;

  /// No description provided for @tasmeeClearHistory.
  ///
  /// In ar, this message translates to:
  /// **'مسح سجل التسميع'**
  String get tasmeeClearHistory;

  /// No description provided for @tasmeeClearHistoryBody.
  ///
  /// In ar, this message translates to:
  /// **'يُمسح ما يحفظه التطبيق عن جلساتك السابقة (آخر تسميع). لا يوجد صوت محفوظ أصلا.'**
  String get tasmeeClearHistoryBody;

  /// No description provided for @tasmeeClearHistoryHint.
  ///
  /// In ar, this message translates to:
  /// **'آخر تسميع ونتيجته'**
  String get tasmeeClearHistoryHint;

  /// No description provided for @tasmeeTrainTitle.
  ///
  /// In ar, this message translates to:
  /// **'ساعدنا في تحسين النموذج وتدريبه بتسجيلاتك'**
  String get tasmeeTrainTitle;

  /// No description provided for @tasmeeTrainBody.
  ///
  /// In ar, this message translates to:
  /// **'على منصة «تدريب التسميع» تقرأ آيات من حفظك وتتبرّع بتسجيلك، ليتعلّم نموذج التسميع ويصبح أدق. المشاركة اختيارية بالكامل.'**
  String get tasmeeTrainBody;

  /// No description provided for @tasmeeTrainHowTitle.
  ///
  /// In ar, this message translates to:
  /// **'كيف تشارك؟'**
  String get tasmeeTrainHowTitle;

  /// No description provided for @tasmeeTrainStep1.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حسابًا ببريدك الإلكتروني ووافق على شروط المشاركة.'**
  String get tasmeeTrainStep1;

  /// No description provided for @tasmeeTrainStep2.
  ///
  /// In ar, this message translates to:
  /// **'اختر سورة ونطاق آيات، واقرأها من حفظك في الميكروفون. التسجيل الواحد حتى دقيقتين.'**
  String get tasmeeTrainStep2;

  /// No description provided for @tasmeeTrainStep3.
  ///
  /// In ar, this message translates to:
  /// **'سجّل في مكان هادئ وقريبًا من الميكروفون، بوضوح وبسرعة مريحة. القراءة الصحيحة والخطأ المتعمّد كلاهما مطلوب للتدريب.'**
  String get tasmeeTrainStep3;

  /// No description provided for @tasmeeTrainStep4.
  ///
  /// In ar, this message translates to:
  /// **'يراجع متطوعون تسجيلك قبل دخوله بيانات التدريب.'**
  String get tasmeeTrainStep4;

  /// No description provided for @tasmeeTrainPrivacy.
  ///
  /// In ar, this message translates to:
  /// **'الخصوصية: نطلب بريدك الإلكتروني وسنة ميلادك فقط، ومن هم دون ١٨ يحتاجون موافقة ولي الأمر. التسجيلات المقبولة تُشارك برخصة CC BY 4.0، والملفات الخام لا تُعرض للعامة، وتقدر تمسح تسجيلاتك في أي وقت.'**
  String get tasmeeTrainPrivacy;

  /// No description provided for @tasmeeTrainOpen.
  ///
  /// In ar, this message translates to:
  /// **'افتح منصة التدريب'**
  String get tasmeeTrainOpen;

  /// No description provided for @tasmeeTrainOpenFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح المتصفح. افتح train.altibyan.app يدويًا.'**
  String get tasmeeTrainOpenFailed;

  /// No description provided for @tasmeeClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get tasmeeClose;

  /// No description provided for @tasmeeConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get tasmeeConfirm;

  /// No description provided for @tasmeeContinueLast.
  ///
  /// In ar, this message translates to:
  /// **'أكمل'**
  String get tasmeeContinueLast;

  /// No description provided for @tasmeeContinuousHint.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ متصلا؛ تظهر كل كلمة في موضعها لحظة قراءتها'**
  String get tasmeeContinuousHint;

  /// No description provided for @tasmeeDefaultsNote.
  ///
  /// In ar, this message translates to:
  /// **'القيم الافتراضية من الإعدادات › التسميع'**
  String get tasmeeDefaultsNote;

  /// No description provided for @tasmeeDeleteModel.
  ///
  /// In ar, this message translates to:
  /// **'حذف النموذج'**
  String get tasmeeDeleteModel;

  /// No description provided for @tasmeeDeleteModelBody.
  ///
  /// In ar, this message translates to:
  /// **'يُحذف نموذج التسميع من الجهاز. تحتاج إلى تنزيله ثانية قبل التسميع القادم.'**
  String get tasmeeDeleteModelBody;

  /// No description provided for @tasmeeDone.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get tasmeeDone;

  /// No description provided for @tasmeeDownloadShort.
  ///
  /// In ar, this message translates to:
  /// **'نزّل النموذج'**
  String get tasmeeDownloadShort;

  /// No description provided for @tasmeeDownloadSize.
  ///
  /// In ar, this message translates to:
  /// **'نزّل ({size} م.ب)'**
  String tasmeeDownloadSize(String size);

  /// No description provided for @tasmeeDurationWords.
  ///
  /// In ar, this message translates to:
  /// **'المدة {minutes} د {seconds} ث · {n, plural, =0{لا كلمات} =1{كلمة واحدة} =2{كلمتان} few{{words} كلمات} many{{words} كلمة} other{{words} كلمة}}'**
  String tasmeeDurationWords(
    String minutes,
    String seconds,
    int n,
    String words,
  );

  /// No description provided for @tasmeeElapsed.
  ///
  /// In ar, this message translates to:
  /// **'المدة'**
  String get tasmeeElapsed;

  /// No description provided for @tasmeeEnd.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء'**
  String get tasmeeEnd;

  /// No description provided for @tasmeeFeedback.
  ///
  /// In ar, this message translates to:
  /// **'أثناء التسميع'**
  String get tasmeeFeedback;

  /// No description provided for @tasmeeFinishing.
  ///
  /// In ar, this message translates to:
  /// **'أنهي التسميع…'**
  String get tasmeeFinishing;

  /// No description provided for @tasmeeFromPage.
  ///
  /// In ar, this message translates to:
  /// **'من صفحة'**
  String get tasmeeFromPage;

  /// No description provided for @tasmeeFromSurah.
  ///
  /// In ar, this message translates to:
  /// **'من سورة'**
  String get tasmeeFromSurah;

  /// No description provided for @tasmeeHelp.
  ///
  /// In ar, this message translates to:
  /// **'المساعدة'**
  String get tasmeeHelp;

  /// No description provided for @tasmeeHint.
  ///
  /// In ar, this message translates to:
  /// **'تلميح'**
  String get tasmeeHint;

  /// No description provided for @tasmeeHistory.
  ///
  /// In ar, this message translates to:
  /// **'السجل'**
  String get tasmeeHistory;

  /// No description provided for @tasmeeKindHalfHizb.
  ///
  /// In ar, this message translates to:
  /// **'نصف حزب'**
  String get tasmeeKindHalfHizb;

  /// No description provided for @tasmeeKindHizb.
  ///
  /// In ar, this message translates to:
  /// **'حزب'**
  String get tasmeeKindHizb;

  /// No description provided for @tasmeeKindJuz.
  ///
  /// In ar, this message translates to:
  /// **'جزء'**
  String get tasmeeKindJuz;

  /// No description provided for @tasmeeKindPages.
  ///
  /// In ar, this message translates to:
  /// **'صفحات'**
  String get tasmeeKindPages;

  /// No description provided for @tasmeeKindQuarter.
  ///
  /// In ar, this message translates to:
  /// **'ربع حزب'**
  String get tasmeeKindQuarter;

  /// No description provided for @tasmeeKindSurah.
  ///
  /// In ar, this message translates to:
  /// **'سورة'**
  String get tasmeeKindSurah;

  /// No description provided for @tasmeeKindThreeQuarters.
  ///
  /// In ar, this message translates to:
  /// **'٣ أرباع حزب'**
  String get tasmeeKindThreeQuarters;

  /// No description provided for @tasmeeKindVerses.
  ///
  /// In ar, this message translates to:
  /// **'آيات'**
  String get tasmeeKindVerses;

  /// No description provided for @tasmeeLastSession.
  ///
  /// In ar, this message translates to:
  /// **'آخر تسميع: {range} · {accuracy}'**
  String tasmeeLastSession(String range, String accuracy);

  /// No description provided for @tasmeeLenient.
  ///
  /// In ar, this message translates to:
  /// **'متسامح'**
  String get tasmeeLenient;

  /// No description provided for @tasmeeLenientHint.
  ///
  /// In ar, this message translates to:
  /// **'يقبل فرقا أكبر في نطق الكلمة'**
  String get tasmeeLenientHint;

  /// No description provided for @tasmeeLess.
  ///
  /// In ar, this message translates to:
  /// **'أقل'**
  String get tasmeeLess;

  /// No description provided for @tasmeeListeningVerse.
  ///
  /// In ar, this message translates to:
  /// **'الآية {ayah}: أستمع إليك'**
  String tasmeeListeningVerse(String ayah);

  /// No description provided for @tasmeeMarkAndGoOn.
  ///
  /// In ar, this message translates to:
  /// **'تابع وعلّمه'**
  String get tasmeeMarkAndGoOn;

  /// No description provided for @tasmeeMedium.
  ///
  /// In ar, this message translates to:
  /// **'متوسط'**
  String get tasmeeMedium;

  /// No description provided for @tasmeeMediumHint.
  ///
  /// In ar, this message translates to:
  /// **'يتجاوز عن حرف واحد في الكلمة الطويلة'**
  String get tasmeeMediumHint;

  /// No description provided for @tasmeeMicOff.
  ///
  /// In ar, this message translates to:
  /// **'الميكروفون غير مسموح'**
  String get tasmeeMicOff;

  /// No description provided for @tasmeeMicPrivacy.
  ///
  /// In ar, this message translates to:
  /// **'التسميع يسمع قراءتك على جهازك فقط. لا يُرسل الصوت ولا يُحفظ.'**
  String get tasmeeMicPrivacy;

  /// No description provided for @tasmeeMistakes.
  ///
  /// In ar, this message translates to:
  /// **'{count} أخطاء'**
  String tasmeeMistakes(String count);

  /// No description provided for @tasmeeModelChecking.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ معرفة الحجم…'**
  String get tasmeeModelChecking;

  /// No description provided for @tasmeeModelDetails.
  ///
  /// In ar, this message translates to:
  /// **'المصدر والرخصة في «عن المصحف» › المصادر'**
  String get tasmeeModelDetails;

  /// No description provided for @tasmeeModelFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال. تحقق من الإنترنت وحاول ثانية.'**
  String get tasmeeModelFailed;

  /// No description provided for @tasmeeModelInstalled.
  ///
  /// In ar, this message translates to:
  /// **'النموذج منزّل (الإصدار {version})'**
  String tasmeeModelInstalled(String version);

  /// No description provided for @tasmeeModelMissing.
  ///
  /// In ar, this message translates to:
  /// **'نموذج التسميع غير منزّل'**
  String get tasmeeModelMissing;

  /// No description provided for @tasmeeModelOffline.
  ///
  /// In ar, this message translates to:
  /// **'يعمل بعدها بلا إنترنت'**
  String get tasmeeModelOffline;

  /// No description provided for @tasmeeModelProgress.
  ///
  /// In ar, this message translates to:
  /// **'{done} من {total} م.ب'**
  String tasmeeModelProgress(String done, String total);

  /// No description provided for @tasmeeModelRemove.
  ///
  /// In ar, this message translates to:
  /// **'تحذفه متى شئت من الإعدادات › التسميع'**
  String get tasmeeModelRemove;

  /// No description provided for @tasmeeModelSize.
  ///
  /// In ar, this message translates to:
  /// **'{size} م.ب · مرة واحدة'**
  String tasmeeModelSize(String size);

  /// No description provided for @tasmeeModelSizeUnknown.
  ///
  /// In ar, this message translates to:
  /// **'مرة واحدة'**
  String get tasmeeModelSizeUnknown;

  /// No description provided for @tasmeeModelSpace.
  ///
  /// In ar, this message translates to:
  /// **'المساحة المستخدمة: {size} م.ب'**
  String tasmeeModelSpace(String size);

  /// No description provided for @tasmeeModelTitle.
  ///
  /// In ar, this message translates to:
  /// **'نموذج التسميع'**
  String get tasmeeModelTitle;

  /// No description provided for @tasmeeModelUpdate.
  ///
  /// In ar, this message translates to:
  /// **'تحديث النموذج'**
  String get tasmeeModelUpdate;

  /// No description provided for @tasmeeModelUpdateAvailable.
  ///
  /// In ar, this message translates to:
  /// **'تحديث لنموذج التسميع متاح ({size} م.ب)'**
  String tasmeeModelUpdateAvailable(String size);

  /// No description provided for @tasmeeModelUpdateKeeps.
  ///
  /// In ar, this message translates to:
  /// **'يبقى النموذج الحالي يعمل حتى يكتمل تنزيل الجديد، ثم يُحذف'**
  String get tasmeeModelUpdateKeeps;

  /// No description provided for @tasmeeModelUpdateTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحديث نموذج التسميع'**
  String get tasmeeModelUpdateTitle;

  /// No description provided for @tasmeeModelVoiceStays.
  ///
  /// In ar, this message translates to:
  /// **'صوتك يبقى على جهازك، لا يُرسل ولا يُحفظ'**
  String get tasmeeModelVoiceStays;

  /// No description provided for @tasmeeModelWifiNote.
  ///
  /// In ar, this message translates to:
  /// **'يُفضَّل التنزيل عبر Wi‑Fi؛ قد تُحسب بيانات الهاتف'**
  String get tasmeeModelWifiNote;

  /// No description provided for @tasmeeMore.
  ///
  /// In ar, this message translates to:
  /// **'أكثر'**
  String get tasmeeMore;

  /// No description provided for @tasmeeNew.
  ///
  /// In ar, this message translates to:
  /// **'تسميع جديد'**
  String get tasmeeNew;

  /// No description provided for @tasmeeNoAudioKept.
  ///
  /// In ar, this message translates to:
  /// **'يُحفظ آخر تسميع لتكمل منه. لا يُحفظ أي صوت.'**
  String get tasmeeNoAudioKept;

  /// No description provided for @tasmeeNoMistakes.
  ///
  /// In ar, this message translates to:
  /// **'بلا أخطاء'**
  String get tasmeeNoMistakes;

  /// No description provided for @tasmeeNotNow.
  ///
  /// In ar, this message translates to:
  /// **'ليس الآن'**
  String get tasmeeNotNow;

  /// No description provided for @tasmeeNothingToReview.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت، لا آيات تحتاج مراجعة.'**
  String get tasmeeNothingToReview;

  /// No description provided for @tasmeeNoticeDeviceBody.
  ///
  /// In ar, this message translates to:
  /// **'صوتك لا يُرسل إلى أي خادم ولا يُحفظ.'**
  String get tasmeeNoticeDeviceBody;

  /// No description provided for @tasmeeNoticeDeviceTitle.
  ///
  /// In ar, this message translates to:
  /// **'يعمل على جهازك'**
  String get tasmeeNoticeDeviceTitle;

  /// No description provided for @tasmeeNoticeMishearBody.
  ///
  /// In ar, this message translates to:
  /// **'الكلمة التي يشك فيها تُعلَّم بنقاط خفيفة ولا تُحسب عليك.'**
  String get tasmeeNoticeMishearBody;

  /// No description provided for @tasmeeNoticeMishearTitle.
  ///
  /// In ar, this message translates to:
  /// **'قد يخطئ في السماع'**
  String get tasmeeNoticeMishearTitle;

  /// No description provided for @tasmeeNoticeOk.
  ///
  /// In ar, this message translates to:
  /// **'فهمت'**
  String get tasmeeNoticeOk;

  /// No description provided for @tasmeeNoticeStart.
  ///
  /// In ar, this message translates to:
  /// **'فهمت، ابدأ'**
  String get tasmeeNoticeStart;

  /// No description provided for @tasmeeNoticeTajweedBody.
  ///
  /// In ar, this message translates to:
  /// **'ولا المخارج ولا المدود ولا الوقف والابتداء.'**
  String get tasmeeNoticeTajweedBody;

  /// No description provided for @tasmeeNoticeTajweedTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا يقيّم التجويد ولا أحكام الأداء'**
  String get tasmeeNoticeTajweedTitle;

  /// No description provided for @tasmeeNoticeTitle.
  ///
  /// In ar, this message translates to:
  /// **'التسميع يختبر حفظك، لا تجويدك'**
  String get tasmeeNoticeTitle;

  /// No description provided for @tasmeeNoticeWordsBody.
  ///
  /// In ar, this message translates to:
  /// **'هل قرأت ما في المصحف كلمة كلمة؟'**
  String get tasmeeNoticeWordsBody;

  /// No description provided for @tasmeeNoticeWordsTitle.
  ///
  /// In ar, this message translates to:
  /// **'يتحقق من الكلمات وترتيبها'**
  String get tasmeeNoticeWordsTitle;

  /// No description provided for @tasmeeOnError.
  ///
  /// In ar, this message translates to:
  /// **'عند الخطأ'**
  String get tasmeeOnError;

  /// No description provided for @tasmeeOneMistake.
  ///
  /// In ar, this message translates to:
  /// **'خطأ واحد'**
  String get tasmeeOneMistake;

  /// No description provided for @tasmeeOneTo.
  ///
  /// In ar, this message translates to:
  /// **'من ١ إلى {max}'**
  String tasmeeOneTo(String max);

  /// No description provided for @tasmeeOpenDeviceSettings.
  ///
  /// In ar, this message translates to:
  /// **'افتح إعدادات الجهاز'**
  String get tasmeeOpenDeviceSettings;

  /// No description provided for @tasmeeOtherEdition.
  ///
  /// In ar, this message translates to:
  /// **'التسميع يتبع صفحات مصحف المدينة الجديد (١٤٤١)؛ في طبعتك تظهر الكلمات هنا متتابعة.'**
  String get tasmeeOtherEdition;

  /// No description provided for @tasmeePause.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get tasmeePause;

  /// No description provided for @tasmeePaused.
  ///
  /// In ar, this message translates to:
  /// **'متوقف مؤقتا'**
  String get tasmeePaused;

  /// No description provided for @tasmeeProgress.
  ///
  /// In ar, this message translates to:
  /// **'ما سُمّع من النطاق'**
  String get tasmeeProgress;

  /// No description provided for @tasmeeQuarterOfHizb.
  ///
  /// In ar, this message translates to:
  /// **'الربع'**
  String get tasmeeQuarterOfHizb;

  /// No description provided for @tasmeeRange.
  ///
  /// In ar, this message translates to:
  /// **'النطاق'**
  String get tasmeeRange;

  /// No description provided for @tasmeeRangeSummary.
  ///
  /// In ar, this message translates to:
  /// **'من {from} إلى {to} · {verseTotal, plural, =0{لا آيات} =1{آية واحدة} =2{آيتان} few{{verses} آيات} many{{verses} آية} other{{verses} آية}} · {wordTotal, plural, =0{لا كلمات} =1{كلمة واحدة} =2{كلمتان} few{{words} كلمات} many{{words} كلمة} other{{words} كلمة}} · ص {pages}'**
  String tasmeeRangeSummary(
    String from,
    String to,
    int verseTotal,
    String verses,
    int wordTotal,
    String words,
    String pages,
  );

  /// No description provided for @tasmeeReReadWord.
  ///
  /// In ar, this message translates to:
  /// **'أعد قراءة الكلمة المعلّمة بالأحمر'**
  String get tasmeeReReadWord;

  /// No description provided for @tasmeeReciteAgain.
  ///
  /// In ar, this message translates to:
  /// **'سمّع هذه الآيات ثانية'**
  String get tasmeeReciteAgain;

  /// No description provided for @tasmeeReciteVerse.
  ///
  /// In ar, this message translates to:
  /// **'سمّع الآية'**
  String get tasmeeReciteVerse;

  /// No description provided for @tasmeeRedownload.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تنزيل النموذج'**
  String get tasmeeRedownload;

  /// No description provided for @tasmeeRedownloadBody.
  ///
  /// In ar, this message translates to:
  /// **'يُحذف النموذج الحالي ثم يُنزّل من جديد.'**
  String get tasmeeRedownloadBody;

  /// No description provided for @tasmeeRepeat.
  ///
  /// In ar, this message translates to:
  /// **'أعد'**
  String get tasmeeRepeat;

  /// No description provided for @tasmeeResume.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get tasmeeResume;

  /// No description provided for @tasmeeRetry.
  ///
  /// In ar, this message translates to:
  /// **'حاول ثانية'**
  String get tasmeeRetry;

  /// No description provided for @tasmeeReviewRow.
  ///
  /// In ar, this message translates to:
  /// **'الآية {ayah}، الدقة {accuracy}'**
  String tasmeeReviewRow(String ayah, String accuracy);

  /// No description provided for @tasmeeRingSemantics.
  ///
  /// In ar, this message translates to:
  /// **'{title}، {note}: {value}'**
  String tasmeeRingSemantics(String title, String note, String value);

  /// No description provided for @tasmeeSeconds.
  ///
  /// In ar, this message translates to:
  /// **'{count} ث'**
  String tasmeeSeconds(String count);

  /// No description provided for @tasmeeSessionTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسميع · {surah}'**
  String tasmeeSessionTitle(String surah);

  /// No description provided for @tasmeeSettingsNote.
  ///
  /// In ar, this message translates to:
  /// **'الطريقة، السلوك عند الخطأ، النموذج'**
  String get tasmeeSettingsNote;

  /// No description provided for @tasmeeSkipWord.
  ///
  /// In ar, this message translates to:
  /// **'تجاوزها'**
  String get tasmeeSkipWord;

  /// No description provided for @tasmeeStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ'**
  String get tasmeeStart;

  /// No description provided for @tasmeeStartReciting.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ التسميع'**
  String get tasmeeStartReciting;

  /// No description provided for @tasmeeStopToCorrect.
  ///
  /// In ar, this message translates to:
  /// **'توقّف للتصحيح'**
  String get tasmeeStopToCorrect;

  /// No description provided for @tasmeeStopToCorrectHint.
  ///
  /// In ar, this message translates to:
  /// **'لا يتقدم حتى تقرأ الكلمة الصحيحة'**
  String get tasmeeStopToCorrectHint;

  /// No description provided for @tasmeeStrict.
  ///
  /// In ar, this message translates to:
  /// **'صارم'**
  String get tasmeeStrict;

  /// No description provided for @tasmeeStrictHint.
  ///
  /// In ar, this message translates to:
  /// **'الكلمة كما هي حرفا حرفا'**
  String get tasmeeStrictHint;

  /// No description provided for @tasmeeStrictness.
  ///
  /// In ar, this message translates to:
  /// **'حساسية المطابقة'**
  String get tasmeeStrictness;

  /// No description provided for @tasmeeSummary.
  ///
  /// In ar, this message translates to:
  /// **'الملخص'**
  String get tasmeeSummary;

  /// No description provided for @tasmeeTestByTouch.
  ///
  /// In ar, this message translates to:
  /// **'اختبر حفظك باللمس بدلا من ذلك'**
  String get tasmeeTestByTouch;

  /// No description provided for @tasmeeThisVerse.
  ///
  /// In ar, this message translates to:
  /// **'دقة الآية'**
  String get tasmeeThisVerse;

  /// No description provided for @tasmeeToPage.
  ///
  /// In ar, this message translates to:
  /// **'إلى صفحة'**
  String get tasmeeToPage;

  /// No description provided for @tasmeeToReview.
  ///
  /// In ar, this message translates to:
  /// **'آيات تحتاج مراجعة'**
  String get tasmeeToReview;

  /// No description provided for @tasmeeToSurah.
  ///
  /// In ar, this message translates to:
  /// **'إلى سورة'**
  String get tasmeeToSurah;

  /// No description provided for @tasmeeToastDuration.
  ///
  /// In ar, this message translates to:
  /// **'مدة ظهور نتيجة الآية'**
  String get tasmeeToastDuration;

  /// No description provided for @tasmeeVerseByVerseHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط، اقرأ آية، ثم تظهر كاملة بنتيجتها'**
  String get tasmeeVerseByVerseHint;

  /// No description provided for @tasmeeVerseDone.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الآية'**
  String get tasmeeVerseDone;

  /// No description provided for @tasmeeVerseNumber.
  ///
  /// In ar, this message translates to:
  /// **'الآية {ayah}'**
  String tasmeeVerseNumber(String ayah);

  /// No description provided for @tasmeeVerseOf.
  ///
  /// In ar, this message translates to:
  /// **'الآية {n} من {count}: اضغط وسمّعها'**
  String tasmeeVerseOf(String n, String count);

  /// No description provided for @tasmeeVerseResult.
  ///
  /// In ar, this message translates to:
  /// **'الآية {ayah} · {accuracy} · {detail}'**
  String tasmeeVerseResult(String ayah, String accuracy, String detail);

  /// No description provided for @tasmeeVersesHeading.
  ///
  /// In ar, this message translates to:
  /// **'الآيات'**
  String get tasmeeVersesHeading;

  /// No description provided for @tasmeeVersesLine.
  ///
  /// In ar, this message translates to:
  /// **'الآيات {from}–{to} · {mode}'**
  String tasmeeVersesLine(String from, String to, String mode);

  /// No description provided for @tasmeeVibration.
  ///
  /// In ar, this message translates to:
  /// **'الاهتزاز عند الخطأ'**
  String get tasmeeVibration;

  /// No description provided for @tasmeeVibrationHint.
  ///
  /// In ar, this message translates to:
  /// **'اهتزاز خفيف حين تُعلَّم كلمة خطأ أو متجاوزة'**
  String get tasmeeVibrationHint;

  /// No description provided for @tasmeeWholeSession.
  ///
  /// In ar, this message translates to:
  /// **'للتسميع كله'**
  String get tasmeeWholeSession;

  /// No description provided for @tasmeeWordCorrectedShort.
  ///
  /// In ar, this message translates to:
  /// **'صُحّحت'**
  String get tasmeeWordCorrectedShort;

  /// No description provided for @tasmeeWordHinted.
  ///
  /// In ar, this message translates to:
  /// **'بتلميح'**
  String get tasmeeWordHinted;

  /// No description provided for @tasmeeAllowMicHint.
  ///
  /// In ar, this message translates to:
  /// **'افتح إعدادات الجهاز، ثم اسمح لتبيان باستخدام الميكروفون.'**
  String get tasmeeAllowMicHint;

  /// No description provided for @tasmeeAutoUpdateModel.
  ///
  /// In ar, this message translates to:
  /// **'تحديث النموذج تلقائيًا على الواي فاي'**
  String get tasmeeAutoUpdateModel;

  /// No description provided for @tasmeeAutoUpdateModelHint.
  ///
  /// In ar, this message translates to:
  /// **'يُنزَّل الإصدار الأحدث في الخلفية ويبقى الحالي يعمل حتى يكتمل'**
  String get tasmeeAutoUpdateModelHint;

  /// No description provided for @tasmeeModelUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث نموذج التسميع إلى الإصدار {version}'**
  String tasmeeModelUpdated(String version);

  /// No description provided for @sourceInstalledVersion.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار المثبّت: {version}'**
  String sourceInstalledVersion(String version);

  /// No description provided for @sourceAlsoCredited.
  ///
  /// In ar, this message translates to:
  /// **'ويُنسب أيضًا إلى: {names}'**
  String sourceAlsoCredited(String names);

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navGroupReading.
  ///
  /// In ar, this message translates to:
  /// **'القراءة'**
  String get navGroupReading;

  /// No description provided for @navGroupListening.
  ///
  /// In ar, this message translates to:
  /// **'الاستماع'**
  String get navGroupListening;

  /// No description provided for @navGroupWird.
  ///
  /// In ar, this message translates to:
  /// **'الورد والحفظ'**
  String get navGroupWird;

  /// No description provided for @navCollapse.
  ///
  /// In ar, this message translates to:
  /// **'طيّ الشريط الجانبي'**
  String get navCollapse;

  /// No description provided for @navExpand.
  ///
  /// In ar, this message translates to:
  /// **'توسيع الشريط الجانبي'**
  String get navExpand;

  /// No description provided for @homeSections.
  ///
  /// In ar, this message translates to:
  /// **'الأقسام'**
  String get homeSections;

  /// No description provided for @homeContinueHint.
  ///
  /// In ar, this message translates to:
  /// **'تابع من حيث توقفت'**
  String get homeContinueHint;

  /// No description provided for @interfaceStyleTitle.
  ///
  /// In ar, this message translates to:
  /// **'شكل الواجهة'**
  String get interfaceStyleTitle;

  /// No description provided for @interfaceStyleHint.
  ///
  /// In ar, this message translates to:
  /// **'شكل الرئيسية والفهرس والإعدادات والنوافذ، ولا يغيّر شكل صفحة المصحف'**
  String get interfaceStyleHint;

  /// No description provided for @interfaceStyleMakhtuta.
  ///
  /// In ar, this message translates to:
  /// **'مخطوطة'**
  String get interfaceStyleMakhtuta;

  /// No description provided for @interfaceStyleHandasi.
  ///
  /// In ar, this message translates to:
  /// **'هندسي'**
  String get interfaceStyleHandasi;

  /// No description provided for @interfaceStyleLayli.
  ///
  /// In ar, this message translates to:
  /// **'ليلي ذهبي'**
  String get interfaceStyleLayli;

  /// No description provided for @settingsGroupAppearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get settingsGroupAppearance;

  /// No description provided for @settingsGroupListening.
  ///
  /// In ar, this message translates to:
  /// **'الاستماع والتسميع'**
  String get settingsGroupListening;

  /// No description provided for @settingsGroupData.
  ///
  /// In ar, this message translates to:
  /// **'البيانات والخصوصية'**
  String get settingsGroupData;

  /// No description provided for @progressSaved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظت النتيجة'**
  String get progressSaved;

  /// No description provided for @progressNewlyMastered.
  ///
  /// In ar, this message translates to:
  /// **'أُتقنت آيات جديدة: {count}'**
  String progressNewlyMastered(String count);

  /// No description provided for @progressStillMastered.
  ///
  /// In ar, this message translates to:
  /// **'متقن: {count}'**
  String progressStillMastered(String count);

  /// No description provided for @progressToReview.
  ///
  /// In ar, this message translates to:
  /// **'تحتاج مراجعة: {count}'**
  String progressToReview(String count);

  /// No description provided for @hifzTabToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get hifzTabToday;

  /// No description provided for @hifzTabProgress.
  ///
  /// In ar, this message translates to:
  /// **'التقدّم'**
  String get hifzTabProgress;

  /// No description provided for @hifzTabHistory.
  ///
  /// In ar, this message translates to:
  /// **'السجل'**
  String get hifzTabHistory;

  /// No description provided for @hifzTabHardWords.
  ///
  /// In ar, this message translates to:
  /// **'الكلمات الصعبة'**
  String get hifzTabHardWords;

  /// No description provided for @hifzTabGoals.
  ///
  /// In ar, this message translates to:
  /// **'الأهداف'**
  String get hifzTabGoals;

  /// No description provided for @hifzJourney.
  ///
  /// In ar, this message translates to:
  /// **'مسيرة الحفظ'**
  String get hifzJourney;

  /// No description provided for @hifzJourneyLine.
  ///
  /// In ar, this message translates to:
  /// **'محفوظ {n, plural, =0{لا آيات} =1{آية واحدة} =2{آيتان} few{{memorized} آيات} many{{memorized} آية} other{{memorized} آية}}، منها {mastered} متقنة'**
  String hifzJourneyLine(int n, String memorized, String mastered);

  /// No description provided for @hifzJourneyEmpty.
  ///
  /// In ar, this message translates to:
  /// **'سمّع ما تحفظ فيُحفظ هنا تقدّمك.'**
  String get hifzJourneyEmpty;

  /// No description provided for @progressOverall.
  ///
  /// In ar, this message translates to:
  /// **'في المجمل'**
  String get progressOverall;

  /// No description provided for @progressJuzCount.
  ///
  /// In ar, this message translates to:
  /// **'أجزاء'**
  String get progressJuzCount;

  /// No description provided for @progressPagesCount.
  ///
  /// In ar, this message translates to:
  /// **'صفحات'**
  String get progressPagesCount;

  /// No description provided for @progressVersesCount.
  ///
  /// In ar, this message translates to:
  /// **'آيات'**
  String get progressVersesCount;

  /// No description provided for @progressMemorized.
  ///
  /// In ar, this message translates to:
  /// **'محفوظ'**
  String get progressMemorized;

  /// No description provided for @progressMastered.
  ///
  /// In ar, this message translates to:
  /// **'متقن'**
  String get progressMastered;

  /// No description provided for @progressNeedsReview.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج مراجعة'**
  String get progressNeedsReview;

  /// No description provided for @progressAccuracy30.
  ///
  /// In ar, this message translates to:
  /// **'متوسط الدقة في آخر ٣٠ يوما'**
  String get progressAccuracy30;

  /// No description provided for @progressBySurah.
  ///
  /// In ar, this message translates to:
  /// **'حسب السورة'**
  String get progressBySurah;

  /// No description provided for @progressByJuz.
  ///
  /// In ar, this message translates to:
  /// **'حسب الجزء'**
  String get progressByJuz;

  /// No description provided for @progressLastRecited.
  ///
  /// In ar, this message translates to:
  /// **'آخر تسميع {date}'**
  String progressLastRecited(String date);

  /// No description provided for @progressNotRecited.
  ///
  /// In ar, this message translates to:
  /// **'لم يُسمَّع بعد'**
  String get progressNotRecited;

  /// No description provided for @progressShares.
  ///
  /// In ar, this message translates to:
  /// **'محفوظ {memorized} · متقن {mastered}'**
  String progressShares(String memorized, String mastered);

  /// No description provided for @progressAccuracy.
  ///
  /// In ar, this message translates to:
  /// **'الدقة {value}'**
  String progressAccuracy(String value);

  /// No description provided for @progressSuggestRecite.
  ///
  /// In ar, this message translates to:
  /// **'آيات محفوظة لم تُسمَّع بعد: {count}. سمّعها لتصير متقنة.'**
  String progressSuggestRecite(String count);

  /// No description provided for @progressMasteryRule.
  ///
  /// In ar, this message translates to:
  /// **'الآية تصير «متقنة» إذا سمّعتها بدقة ٩٠٪ أو أكثر.'**
  String get progressMasteryRule;

  /// No description provided for @progressEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم تعلّم حفظ شيء بعد. علّم ما تحفظ في الخريطة، أو سمّع.'**
  String get progressEmpty;

  /// No description provided for @progressOpenMap.
  ///
  /// In ar, this message translates to:
  /// **'افتح الخريطة'**
  String get progressOpenMap;

  /// No description provided for @historyEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا تسميع محفوظ بعد. كل جلسة تسميع تُحفظ هنا وحدها، نتيجتها فقط دون صوت.'**
  String get historyEmpty;

  /// No description provided for @recitationVoice.
  ///
  /// In ar, this message translates to:
  /// **'بالصوت'**
  String get recitationVoice;

  /// No description provided for @recitationTouch.
  ///
  /// In ar, this message translates to:
  /// **'باللمس'**
  String get recitationTouch;

  /// No description provided for @recitationTest.
  ///
  /// In ar, this message translates to:
  /// **'اختبار الحفظ'**
  String get recitationTest;

  /// No description provided for @historyVerses.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =0{لا آيات} =1{آية واحدة} =2{آيتان} few{{count} آيات} many{{count} آية} other{{count} آية}}'**
  String historyVerses(int n, String count);

  /// No description provided for @sessionSummary.
  ///
  /// In ar, this message translates to:
  /// **'ملخّص الجلسة'**
  String get sessionSummary;

  /// No description provided for @sessionDelete.
  ///
  /// In ar, this message translates to:
  /// **'احذف من السجل'**
  String get sessionDelete;

  /// No description provided for @sessionSensitivity.
  ///
  /// In ar, this message translates to:
  /// **'حساسية المطابقة: {level}'**
  String sessionSensitivity(String level);

  /// No description provided for @sessionSlips.
  ///
  /// In ar, this message translates to:
  /// **'مواضع الخطأ'**
  String get sessionSlips;

  /// No description provided for @hardWordsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا كلمات صعبة بعد. الكلمة التي تخطئ فيها أو تتخطاها أكثر من مرة تظهر هنا.'**
  String get hardWordsEmpty;

  /// No description provided for @hardWordsCount.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =0{لا مرات} =1{مرة واحدة} =2{مرتان} few{{count} مرات} many{{count} مرة} other{{count} مرة}} · آخرها {date}'**
  String hardWordsCount(int n, String count, String date);

  /// No description provided for @hardWordsHint.
  ///
  /// In ar, this message translates to:
  /// **'آيات هذه الكلمات تأتي أولا في المراجعة.'**
  String get hardWordsHint;

  /// No description provided for @goalsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا أهداف بعد. اختر هدفا جاهزا أو اصنع هدفك.'**
  String get goalsEmpty;

  /// No description provided for @goalNew.
  ///
  /// In ar, this message translates to:
  /// **'هدف جديد'**
  String get goalNew;

  /// No description provided for @goalTemplateAmma.
  ///
  /// In ar, this message translates to:
  /// **'جزء عمّ في شهرين'**
  String get goalTemplateAmma;

  /// No description provided for @goalTemplatePageDaily.
  ///
  /// In ar, this message translates to:
  /// **'صفحة يوميا'**
  String get goalTemplatePageDaily;

  /// No description provided for @goalTemplateHizbWeekly.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة حزب كل أسبوع'**
  String get goalTemplateHizbWeekly;

  /// No description provided for @goalTemplateFixSurah.
  ///
  /// In ar, this message translates to:
  /// **'تثبيت سورة'**
  String get goalTemplateFixSurah;

  /// No description provided for @goalOpen.
  ///
  /// In ar, this message translates to:
  /// **'هدف مفتوح'**
  String get goalOpen;

  /// No description provided for @goalOpenHint.
  ///
  /// In ar, this message translates to:
  /// **'تختار النطاق والمدة والوحدة'**
  String get goalOpenHint;

  /// No description provided for @goalFromSurah.
  ///
  /// In ar, this message translates to:
  /// **'من سورة'**
  String get goalFromSurah;

  /// No description provided for @goalToSurah.
  ///
  /// In ar, this message translates to:
  /// **'إلى سورة'**
  String get goalToSurah;

  /// No description provided for @goalSurah.
  ///
  /// In ar, this message translates to:
  /// **'السورة'**
  String get goalSurah;

  /// No description provided for @goalHizb.
  ///
  /// In ar, this message translates to:
  /// **'الحزب'**
  String get goalHizb;

  /// No description provided for @goalDays.
  ///
  /// In ar, this message translates to:
  /// **'المدة: {n, plural, =0{لا أيام} =1{يوم واحد} =2{يومان} few{{days} أيام} many{{days} يومًا} other{{days} يوم}}'**
  String goalDays(int n, String days);

  /// No description provided for @goalUnit.
  ///
  /// In ar, this message translates to:
  /// **'الوحدة'**
  String get goalUnit;

  /// No description provided for @goalCreate.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ الهدف'**
  String get goalCreate;

  /// No description provided for @goalTodayWird.
  ///
  /// In ar, this message translates to:
  /// **'ورد اليوم'**
  String get goalTodayWird;

  /// No description provided for @goalMemorize.
  ///
  /// In ar, this message translates to:
  /// **'احفظ'**
  String get goalMemorize;

  /// No description provided for @goalReview.
  ///
  /// In ar, this message translates to:
  /// **'راجع'**
  String get goalReview;

  /// No description provided for @goalReviewDue.
  ///
  /// In ar, this message translates to:
  /// **'وحدات مستحقة للمراجعة: {count}'**
  String goalReviewDue(String count);

  /// No description provided for @goalReviewHard.
  ///
  /// In ar, this message translates to:
  /// **'آيات فيها كلمات صعبة: {count}'**
  String goalReviewHard(String count);

  /// No description provided for @goalNothingToday.
  ///
  /// In ar, this message translates to:
  /// **'لا ورد اليوم.'**
  String get goalNothingToday;

  /// No description provided for @goalMasteredShare.
  ///
  /// In ar, this message translates to:
  /// **'متقن {value}'**
  String goalMasteredShare(String value);

  /// No description provided for @goalLeft.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =0{لم تبقَ صفحات} =1{تبقّت صفحة واحدة} =2{تبقّت صفحتان} few{تبقّت {pages} صفحات} many{تبقّى {pages} صفحة} other{تبقّى {pages} صفحة}}'**
  String goalLeft(int n, String pages);

  /// No description provided for @goalUntil.
  ///
  /// In ar, this message translates to:
  /// **'حتى {date}'**
  String goalUntil(String date);

  /// No description provided for @goalBehind.
  ///
  /// In ar, this message translates to:
  /// **'تبقّى من الأيام الماضية {n, plural, =0{لا شيء} =1{صفحة واحدة} =2{صفحتان} few{{pages} صفحات} many{{pages} صفحة} other{{pages} صفحة}}'**
  String goalBehind(int n, String pages);

  /// No description provided for @goalCatchUp.
  ///
  /// In ar, this message translates to:
  /// **'عوّض على أيام'**
  String get goalCatchUp;

  /// No description provided for @goalExtend.
  ///
  /// In ar, this message translates to:
  /// **'مد الموعد'**
  String get goalExtend;

  /// No description provided for @goalPause.
  ///
  /// In ar, this message translates to:
  /// **'أوقف مؤقتا'**
  String get goalPause;

  /// No description provided for @goalResume.
  ///
  /// In ar, this message translates to:
  /// **'استأنف'**
  String get goalResume;

  /// No description provided for @goalDelete.
  ///
  /// In ar, this message translates to:
  /// **'احذف الهدف'**
  String get goalDelete;

  /// No description provided for @goalReminder.
  ///
  /// In ar, this message translates to:
  /// **'تذكير يومي'**
  String get goalReminder;

  /// No description provided for @goalReminderAt.
  ///
  /// In ar, this message translates to:
  /// **'تذكير {time}'**
  String goalReminderAt(String time);

  /// No description provided for @goalReminderOff.
  ///
  /// In ar, this message translates to:
  /// **'أوقف التذكير'**
  String get goalReminderOff;

  /// No description provided for @goalPaused.
  ///
  /// In ar, this message translates to:
  /// **'متوقف'**
  String get goalPaused;

  /// No description provided for @goalComplete.
  ///
  /// In ar, this message translates to:
  /// **'اكتمل الهدف، بارك الله فيك.'**
  String get goalComplete;

  /// No description provided for @goalCountedByMastery.
  ///
  /// In ar, this message translates to:
  /// **'يُحسب التقدّم بالتسميع المتقن، لا بالتعليم باليد.'**
  String get goalCountedByMastery;

  /// No description provided for @goalReminderTitle.
  ///
  /// In ar, this message translates to:
  /// **'ورد الحفظ'**
  String get goalReminderTitle;

  /// No description provided for @goalReminderBody.
  ///
  /// In ar, this message translates to:
  /// **'احفظ: الصفحات {from}–{to}'**
  String goalReminderBody(String from, String to);

  /// No description provided for @goalRecite.
  ///
  /// In ar, this message translates to:
  /// **'سمّع'**
  String get goalRecite;

  /// No description provided for @hifzMapShowMastery.
  ///
  /// In ar, this message translates to:
  /// **'الإتقان'**
  String get hifzMapShowMastery;

  /// No description provided for @hifzMapShowStrength.
  ///
  /// In ar, this message translates to:
  /// **'القوة'**
  String get hifzMapShowStrength;

  /// No description provided for @whatsNewHifzProgress.
  ///
  /// In ar, this message translates to:
  /// **'مسيرة الحفظ'**
  String get whatsNewHifzProgress;

  /// No description provided for @onbStepOf.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة {step} من {total}'**
  String onbStepOf(String step, String total);

  /// No description provided for @onbSkipAll.
  ///
  /// In ar, this message translates to:
  /// **'تخطَّ الكل'**
  String get onbSkipAll;

  /// No description provided for @onbSkip.
  ///
  /// In ar, this message translates to:
  /// **'تخطَّ'**
  String get onbSkip;

  /// No description provided for @onbInterfaceTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر شكل الواجهة وإضاءتها'**
  String get onbInterfaceTitle;

  /// No description provided for @onbPageTurnTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر كيف تُقلب صفحات المصحف'**
  String get onbPageTurnTitle;

  /// No description provided for @onbPageTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر شكل صفحة المصحف'**
  String get onbPageTitle;

  /// No description provided for @onbReciterTitle.
  ///
  /// In ar, this message translates to:
  /// **'اسمع المصحف بصوت من تحب'**
  String get onbReciterTitle;

  /// No description provided for @onbReciterSuggest.
  ///
  /// In ar, this message translates to:
  /// **'نزّل المصحف كاملًا بصوت الشيخ {name}'**
  String onbReciterSuggest(String name);

  /// No description provided for @onbReciterSize.
  ///
  /// In ar, this message translates to:
  /// **'نحو {size} ميجا · يكمل في الخلفية وأنت تتابع'**
  String onbReciterSize(String size);

  /// No description provided for @onbReciterOther.
  ///
  /// In ar, this message translates to:
  /// **'اختر شيخًا آخر'**
  String get onbReciterOther;

  /// No description provided for @onbReciterOnline.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تسمع أي شيخ أونلاين من غير تحميل'**
  String get onbReciterOnline;

  /// No description provided for @onbDownloadingBg.
  ///
  /// In ar, this message translates to:
  /// **'يُنزَّل في الخلفية: {done} من {total}'**
  String onbDownloadingBg(String done, String total);

  /// No description provided for @onbTasmeeTitle.
  ///
  /// In ar, this message translates to:
  /// **'التسميع بصوتك'**
  String get onbTasmeeTitle;

  /// No description provided for @onbTasmeeBody.
  ///
  /// In ar, this message translates to:
  /// **'يستمع تبيان لتلاوتك وينبّهك عند الخطأ، على جهازك ومن غير إنترنت. يحتاج نموذج تعرّف على الصوت يُنزَّل مرة واحدة.'**
  String get onbTasmeeBody;

  /// No description provided for @onbTasmeeDownload.
  ///
  /// In ar, this message translates to:
  /// **'نزّل النموذج'**
  String get onbTasmeeDownload;

  /// No description provided for @onbTasmeeDownloading.
  ///
  /// In ar, this message translates to:
  /// **'يُنزَّل النموذج في الخلفية: {percent}٪'**
  String onbTasmeeDownloading(String percent);

  /// No description provided for @onbTasmeeReady.
  ///
  /// In ar, this message translates to:
  /// **'نموذج التسميع جاهز'**
  String get onbTasmeeReady;

  /// No description provided for @onbTasmeeFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التنزيل. تقدر تنزّله لاحقًا من الإعدادات › الحفظ والتسميع.'**
  String get onbTasmeeFailed;

  /// No description provided for @onbStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ القراءة'**
  String get onbStart;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionAppearanceHint.
  ///
  /// In ar, this message translates to:
  /// **'الواجهة، الإضاءة، اللغة، الخط'**
  String get settingsSectionAppearanceHint;

  /// No description provided for @settingsSectionMushaf.
  ///
  /// In ar, this message translates to:
  /// **'المصحف'**
  String get settingsSectionMushaf;

  /// No description provided for @settingsSectionMushafHint.
  ///
  /// In ar, this message translates to:
  /// **'الطبعة، شكل الصفحة، التجويد، التركيز'**
  String get settingsSectionMushafHint;

  /// No description provided for @settingsSectionListening.
  ///
  /// In ar, this message translates to:
  /// **'الاستماع'**
  String get settingsSectionListening;

  /// No description provided for @settingsSectionListeningHint.
  ///
  /// In ar, this message translates to:
  /// **'القرّاء، المشغّل، مؤقت السجدة'**
  String get settingsSectionListeningHint;

  /// No description provided for @settingsSectionHifz.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ والتسميع'**
  String get settingsSectionHifz;

  /// No description provided for @settingsSectionHifzHint.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ، التسميع، نموذج الصوت'**
  String get settingsSectionHifzHint;

  /// No description provided for @settingsSectionKhatma.
  ///
  /// In ar, this message translates to:
  /// **'الختمة والتذكيرات'**
  String get settingsSectionKhatma;

  /// No description provided for @settingsSectionKhatmaHint.
  ///
  /// In ar, this message translates to:
  /// **'الخطط، التذكيرات، الورد'**
  String get settingsSectionKhatmaHint;

  /// No description provided for @settingsSectionStorage.
  ///
  /// In ar, this message translates to:
  /// **'التخزين والنسخ الاحتياطي'**
  String get settingsSectionStorage;

  /// No description provided for @settingsSectionStorageHint.
  ///
  /// In ar, this message translates to:
  /// **'المساحة، النسخ، الاستعادة'**
  String get settingsSectionStorageHint;

  /// No description provided for @settingsSectionAssistant.
  ///
  /// In ar, this message translates to:
  /// **'المساعد'**
  String get settingsSectionAssistant;

  /// No description provided for @settingsSectionAssistantHint.
  ///
  /// In ar, this message translates to:
  /// **'المساعدة في استخدام التطبيق والمصحف'**
  String get settingsSectionAssistantHint;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In ar, this message translates to:
  /// **'عن تبيان'**
  String get settingsSectionAbout;

  /// No description provided for @settingsSectionAboutHint.
  ///
  /// In ar, this message translates to:
  /// **'الجديد، المصادر، الإصدار'**
  String get settingsSectionAboutHint;

  /// No description provided for @settingsSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الإعدادات'**
  String get settingsSearchHint;

  /// No description provided for @settingsSearchEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا إعداد بهذا الاسم. جرّب كلمة أخرى.'**
  String get settingsSearchEmpty;

  /// No description provided for @settingsKhatmaPlans.
  ///
  /// In ar, this message translates to:
  /// **'خطط الختمة وتذكيراتها'**
  String get settingsKhatmaPlans;

  /// No description provided for @settingsWirdIndicator.
  ///
  /// In ar, this message translates to:
  /// **'مؤشر الورد فوق المصحف'**
  String get settingsWirdIndicator;

  /// No description provided for @settingsCountListening.
  ///
  /// In ar, this message translates to:
  /// **'احتساب الاستماع من الورد'**
  String get settingsCountListening;

  /// No description provided for @emptyOpenMushaf.
  ///
  /// In ar, this message translates to:
  /// **'افتح المصحف حيث توقفت'**
  String get emptyOpenMushaf;

  /// No description provided for @journalAddNote.
  ///
  /// In ar, this message translates to:
  /// **'أضف ملاحظة'**
  String get journalAddNote;

  /// No description provided for @tasbihStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ التسبيح'**
  String get tasbihStart;

  /// No description provided for @zeroLabel.
  ///
  /// In ar, this message translates to:
  /// **'صفر'**
  String get zeroLabel;

  /// No description provided for @settingsHifzOpen.
  ///
  /// In ar, this message translates to:
  /// **'افتح الحفظ'**
  String get settingsHifzOpen;

  /// No description provided for @tasmeeSettingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات التسميع'**
  String get tasmeeSettingsTitle;

  /// No description provided for @settingsHifzGoals.
  ///
  /// In ar, this message translates to:
  /// **'أهداف الحفظ وتذكيراتها'**
  String get settingsHifzGoals;

  /// No description provided for @digitsFontTitle.
  ///
  /// In ar, this message translates to:
  /// **'خط الأرقام في الواجهة (Tibyan Digits)'**
  String get digitsFontTitle;

  /// No description provided for @digitsFontNote.
  ///
  /// In ar, this message translates to:
  /// **'أرقام الواجهة كلها بخط واحد واضح: مقتطع من IBM Plex Sans Arabic (حقوقه لشركة IBM، 2017) يضم الأرقام وحدها، وسُمّي باسم جديد لأن «Plex» اسم محجوز. الرخصة: رخصة الخطوط المفتوحة SIL OFL 1.1، وهي تبيح الاقتطاع والتعديل بشرط تغيير الاسم وبقاء الرخصة نفسها.'**
  String get digitsFontNote;

  /// No description provided for @reportProblemTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإبلاغ عن مشكلة'**
  String get reportProblemTitle;

  /// No description provided for @reportProblemHint.
  ///
  /// In ar, this message translates to:
  /// **'أرسل لنا عطلا أو مشكلة أو اقتراحا'**
  String get reportProblemHint;

  /// No description provided for @reportType.
  ///
  /// In ar, this message translates to:
  /// **'نوع البلاغ'**
  String get reportType;

  /// No description provided for @reportTypeBug.
  ///
  /// In ar, this message translates to:
  /// **'عطل'**
  String get reportTypeBug;

  /// No description provided for @reportTypeProblem.
  ///
  /// In ar, this message translates to:
  /// **'مشكلة'**
  String get reportTypeProblem;

  /// No description provided for @reportTypeSuggestion.
  ///
  /// In ar, this message translates to:
  /// **'تحسين مقترح'**
  String get reportTypeSuggestion;

  /// No description provided for @reportTypeOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get reportTypeOther;

  /// No description provided for @reportDescription.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get reportDescription;

  /// No description provided for @reportDescriptionHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ما حدث، وأين، وما توقعت أن يحدث'**
  String get reportDescriptionHint;

  /// No description provided for @reportDescriptionShort.
  ///
  /// In ar, this message translates to:
  /// **'اكتب خمسة أحرف على الأقل'**
  String get reportDescriptionShort;

  /// No description provided for @reportPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف (اختياري)'**
  String get reportPhone;

  /// No description provided for @reportPhoneInvalid.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف غير صحيح'**
  String get reportPhoneInvalid;

  /// No description provided for @reportEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني (اختياري)'**
  String get reportEmail;

  /// No description provided for @reportEmailInvalid.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني غير صحيح'**
  String get reportEmailInvalid;

  /// No description provided for @reportContactNote.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف والبريد اختياريان، نستخدمهما للرد عليك فقط، ويُحذفان من جهازك بعد إرسال البلاغ.'**
  String get reportContactNote;

  /// No description provided for @reportDeviceTitle.
  ///
  /// In ar, this message translates to:
  /// **'يُرفق مع البلاغ'**
  String get reportDeviceTitle;

  /// No description provided for @reportDeviceVersion.
  ///
  /// In ar, this message translates to:
  /// **'إصدار التطبيق: {version}'**
  String reportDeviceVersion(String version);

  /// No description provided for @reportDeviceSystem.
  ///
  /// In ar, this message translates to:
  /// **'النظام: {platform} {os}'**
  String reportDeviceSystem(String platform, String os);

  /// No description provided for @reportSend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال البلاغ'**
  String get reportSend;

  /// No description provided for @reportSent.
  ///
  /// In ar, this message translates to:
  /// **'وصل بلاغك، شكرا لك.'**
  String get reportSent;

  /// No description provided for @reportQueued.
  ///
  /// In ar, this message translates to:
  /// **'لا اتصال الآن. حُفظ البلاغ وسيُرسل وحده حين يعود الاتصال.'**
  String get reportQueued;

  /// No description provided for @reportFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إرسال البلاغ. راجع ما كتبت وحاول مرة أخرى.'**
  String get reportFailed;

  /// No description provided for @reportRateLimited.
  ///
  /// In ar, this message translates to:
  /// **'أرسلت بلاغات كثيرة للتو. حاول بعد قليل.'**
  String get reportRateLimited;

  /// No description provided for @reportPendingCount.
  ///
  /// In ar, this message translates to:
  /// **'بلاغات تنتظر الإرسال: {n}'**
  String reportPendingCount(int n);

  /// No description provided for @helpGroupUsage.
  ///
  /// In ar, this message translates to:
  /// **'استخدام التطبيق'**
  String get helpGroupUsage;

  /// No description provided for @helpGroupMarks.
  ///
  /// In ar, this message translates to:
  /// **'التجويد والضبط'**
  String get helpGroupMarks;

  /// No description provided for @helpGroupFaq.
  ///
  /// In ar, this message translates to:
  /// **'أسئلة شائعة وحلول'**
  String get helpGroupFaq;

  /// No description provided for @onbTasmeeChecking.
  ///
  /// In ar, this message translates to:
  /// **'نتحقق من حجم النموذج…'**
  String get onbTasmeeChecking;

  /// No description provided for @onbTasmeeManifestFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر جلب معلومات النموذج. تأكد من اتصالك بالإنترنت ثم أعد المحاولة.'**
  String get onbTasmeeManifestFailed;

  /// No description provided for @onbTasmeeUnsupported.
  ///
  /// In ar, this message translates to:
  /// **'التسميع بالصوت غير متاح على هذا الجهاز بعد. تقدر تكمل وتستخدم باقي التطبيق.'**
  String get onbTasmeeUnsupported;

  /// No description provided for @menuGo.
  ///
  /// In ar, this message translates to:
  /// **'انتقال'**
  String get menuGo;

  /// No description provided for @menuPlayback.
  ///
  /// In ar, this message translates to:
  /// **'التلاوة'**
  String get menuPlayback;

  /// No description provided for @menuView.
  ///
  /// In ar, this message translates to:
  /// **'عرض'**
  String get menuView;

  /// No description provided for @menuWindow.
  ///
  /// In ar, this message translates to:
  /// **'نافذة'**
  String get menuWindow;

  /// No description provided for @menuHelp.
  ///
  /// In ar, this message translates to:
  /// **'مساعدة'**
  String get menuHelp;

  /// No description provided for @aboutApp.
  ///
  /// In ar, this message translates to:
  /// **'عن تبيان'**
  String get aboutApp;

  /// No description provided for @playPause.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل أو إيقاف مؤقت'**
  String get playPause;

  /// No description provided for @verseOfDayTitle.
  ///
  /// In ar, this message translates to:
  /// **'آية اليوم'**
  String get verseOfDayTitle;

  /// No description provided for @widgetsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الودجات'**
  String get widgetsTitle;

  /// No description provided for @widgetVerseHint.
  ///
  /// In ar, this message translates to:
  /// **'آية من القرآن كل يوم، تفتحها في المصحف بلمسة'**
  String get widgetVerseHint;

  /// No description provided for @widgetKhatmaHint.
  ///
  /// In ar, this message translates to:
  /// **'ورد اليوم من الختمة وأول آية فيه'**
  String get widgetKhatmaHint;

  /// No description provided for @widgetActionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تبيان: اختصارات'**
  String get widgetActionsTitle;

  /// No description provided for @widgetActionsHint.
  ///
  /// In ar, this message translates to:
  /// **'متابعة القراءة، الاستماع، البحث، وتسجيل ورد اليوم'**
  String get widgetActionsHint;

  /// No description provided for @widgetAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get widgetAdd;

  /// No description provided for @widgetHowToIos.
  ///
  /// In ar, this message translates to:
  /// **'للإضافة: اضغط مطولًا على الشاشة الرئيسية، ثم «+»، وابحث عن «تبيان».'**
  String get widgetHowToIos;

  /// No description provided for @widgetHowToMac.
  ///
  /// In ar, this message translates to:
  /// **'للإضافة: انقر بزر الفأرة الأيمن على سطح المكتب، ثم «تعديل الأدوات»، وابحث عن «تبيان».'**
  String get widgetHowToMac;

  /// No description provided for @widgetHowToAndroid.
  ///
  /// In ar, this message translates to:
  /// **'للإضافة: اضغط مطولًا على الشاشة الرئيسية، ثم «الأدوات»، واختر «تبيان».'**
  String get widgetHowToAndroid;

  /// No description provided for @widgetRefresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الودجات الآن'**
  String get widgetRefresh;

  /// No description provided for @widgetRefreshed.
  ///
  /// In ar, this message translates to:
  /// **'حُدّثت الودجات'**
  String get widgetRefreshed;

  /// No description provided for @playSurahNamed.
  ///
  /// In ar, this message translates to:
  /// **'استمع إلى سورة {surah}'**
  String playSurahNamed(String surah);

  /// No description provided for @listenNowPlaying.
  ///
  /// In ar, this message translates to:
  /// **'تُتلى الآن'**
  String get listenNowPlaying;

  /// No description provided for @listenChooseReciter.
  ///
  /// In ar, this message translates to:
  /// **'اختر القارئ'**
  String get listenChooseReciter;

  /// No description provided for @listenSurahs.
  ///
  /// In ar, this message translates to:
  /// **'السور'**
  String get listenSurahs;

  /// No description provided for @listenOtherRiwayaNote.
  ///
  /// In ar, this message translates to:
  /// **'لا يتابعها المصحف المفتوح لاختلاف ترقيم الآيات، ولا تُحتسب في الختمة.'**
  String get listenOtherRiwayaNote;

  /// No description provided for @sectionTasbih.
  ///
  /// In ar, this message translates to:
  /// **'المسبحة'**
  String get sectionTasbih;

  /// Title of the Tasbih counter screen.
  ///
  /// In ar, this message translates to:
  /// **'المسبحة'**
  String get tasbihTitle;

  /// Daily count shown on the Tasbih home tile.
  ///
  /// In ar, this message translates to:
  /// **'اليوم {count}'**
  String tasbihTileToday(String count);

  /// Prompt on the Tasbih home tile before any counts today.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ العدّ'**
  String get tasbihTileStart;

  /// Count button label and accessibility label for the counting area.
  ///
  /// In ar, this message translates to:
  /// **'عد'**
  String get tasbihCountAction;

  /// Current count and target displayed or announced by the counter.
  ///
  /// In ar, this message translates to:
  /// **'{count} من {target}'**
  String tasbihCountOf(String count, String target);

  /// Completed round total on the counter and in the daily log.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =0{لا دورات} =1{دورة واحدة} =2{دورتان} few{{count} دورات} many{{count} دورة} other{{count} دورة}}'**
  String tasbihRounds(int n, String count);

  /// Label for a round number in the Tasbih counter.
  ///
  /// In ar, this message translates to:
  /// **'الدورة {count}'**
  String tasbihRoundLabel(String count);

  /// Accessibility announcement when a counter round is completed.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت الدورة {count}'**
  String tasbihRoundClosed(String count);

  /// Accessibility label for an entry count in the daily log.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{مرة واحدة} =2{مرتان} few{{count} مرات} many{{count} مرة} other{{count} مرة}}'**
  String tasbihTimes(int n, String count);

  /// Target label beside the counter and in the entry editor.
  ///
  /// In ar, this message translates to:
  /// **'الهدف'**
  String get tasbihTarget;

  /// Label for the unlimited counting option in target controls.
  ///
  /// In ar, this message translates to:
  /// **'بلا هدف'**
  String get tasbihNoTarget;

  /// Tooltip for the button that increases the counting target.
  ///
  /// In ar, this message translates to:
  /// **'زيادة الهدف'**
  String get tasbihTargetMore;

  /// Tooltip for the button that decreases the counting target.
  ///
  /// In ar, this message translates to:
  /// **'إنقاص الهدف'**
  String get tasbihTargetLess;

  /// Tooltip and accessibility label for restarting the current round.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الدورة من جديد'**
  String get tasbihReset;

  /// Selection sheet title and accessibility hint for the entry selector.
  ///
  /// In ar, this message translates to:
  /// **'اختر الذكر'**
  String get tasbihChooseDhikr;

  /// Heading for bundled entries in the selection sheet.
  ///
  /// In ar, this message translates to:
  /// **'من المصدر'**
  String get tasbihAppAdhkar;

  /// Heading for user-created entries in the selection sheet.
  ///
  /// In ar, this message translates to:
  /// **'أذكاري'**
  String get tasbihMyAdhkar;

  /// Badge identifying user-created entries on the counter and selection sheet.
  ///
  /// In ar, this message translates to:
  /// **'من إضافتك'**
  String get tasbihMine;

  /// Add-entry action and title of the new-entry editor.
  ///
  /// In ar, this message translates to:
  /// **'أضف ذكرًا خاصًا بك'**
  String get tasbihAddDhikr;

  /// Edit action in the entry menu and title of the entry editor.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الذكر'**
  String get tasbihEditDhikr;

  /// Delete action in the menu for a user-created entry.
  ///
  /// In ar, this message translates to:
  /// **'حذف الذكر'**
  String get tasbihDeleteDhikr;

  /// Label for the text field in the entry editor.
  ///
  /// In ar, this message translates to:
  /// **'النص'**
  String get tasbihDhikrText;

  /// Placeholder in the text field of the entry editor.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الذكر كما تحب أن تراه'**
  String get tasbihDhikrTextHint;

  /// Label for the optional reference field in the entry editor.
  ///
  /// In ar, this message translates to:
  /// **'المرجع (اختياري)'**
  String get tasbihDhikrReference;

  /// Helper text below the text field in the entry editor.
  ///
  /// In ar, this message translates to:
  /// **'يظهر بعلامة «من إضافتك» ولا يُنسب لأي مصدر.'**
  String get tasbihMineNote;

  /// Save button in the entry editor.
  ///
  /// In ar, this message translates to:
  /// **'احفظ الذكر'**
  String get tasbihSave;

  /// Source and license attribution at the bottom of the selection sheet.
  ///
  /// In ar, this message translates to:
  /// **'المصدر: {source}، برخصة {license}'**
  String tasbihSourceLine(String source, String license);

  /// Empty-state message in the counter entry selector.
  ///
  /// In ar, this message translates to:
  /// **'لا أذكار بعد. أضف ذكرًا خاصًا بك لتبدأ.'**
  String get tasbihEmpty;

  /// Daily log screen title and tooltip for opening it from the counter.
  ///
  /// In ar, this message translates to:
  /// **'سجل الأيام'**
  String get tasbihLog;

  /// Introductory helper text at the top of the daily log.
  ///
  /// In ar, this message translates to:
  /// **'مجموع كل ذكر في يومه، لآخر ثلاثين يومًا.'**
  String get tasbihLogHint;

  /// Empty-state message in the daily log.
  ///
  /// In ar, this message translates to:
  /// **'لم تعدّ شيئًا بعد.'**
  String get tasbihLogEmpty;

  /// Heading for the current day in the daily log.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get tasbihToday;

  /// Heading for the previous day in the daily log.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get tasbihYesterday;

  /// Fallback entry title in the daily log after an entry is deleted.
  ///
  /// In ar, this message translates to:
  /// **'ذكر محذوف'**
  String get tasbihDeletedDhikr;

  /// Gesture hint beneath the bead counter.
  ///
  /// In ar, this message translates to:
  /// **'اسحب الحبة لأسفل، أو اضغط'**
  String get tasbihDragHint;

  /// Gesture hint at the bottom of the full-screen counter.
  ///
  /// In ar, this message translates to:
  /// **'اضغط في أي مكان للعدّ، واسحب لأسفل للخروج'**
  String get tasbihScreenHint;

  /// Tooltip on the electronic counter reset control.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطولًا على R لتصفير الدورة'**
  String get tasbihLcdHint;

  /// No description provided for @settingsSectionTasbih.
  ///
  /// In ar, this message translates to:
  /// **'المسبحة'**
  String get settingsSectionTasbih;

  /// No description provided for @settingsSectionTasbihHint.
  ///
  /// In ar, this message translates to:
  /// **'الشكل والخامة والاهتزاز والصوت'**
  String get settingsSectionTasbihHint;

  /// Heading and setting label for the counter style options.
  ///
  /// In ar, this message translates to:
  /// **'شكل المسبحة'**
  String get tasbihStyle;

  /// Bead counter option in the style picker.
  ///
  /// In ar, this message translates to:
  /// **'مسبحة ثلاثية الأبعاد'**
  String get tasbihStyleMisbaha;

  /// Large button counter option in the style picker.
  ///
  /// In ar, this message translates to:
  /// **'زر كبير'**
  String get tasbihStyleButton;

  /// Electronic counter option in the style picker.
  ///
  /// In ar, this message translates to:
  /// **'عداد إلكتروني'**
  String get tasbihStyleLcd;

  /// Full-screen counter option in the style picker.
  ///
  /// In ar, this message translates to:
  /// **'الشاشة كلها'**
  String get tasbihStyleScreen;

  /// Subtitle on the large button option when elderly mode is enabled.
  ///
  /// In ar, this message translates to:
  /// **'مقترح لوضع كبار السن'**
  String get tasbihSuggestedElderly;

  /// Heading for bead rendering options in Tasbih settings.
  ///
  /// In ar, this message translates to:
  /// **'طريقة رسم الحبات'**
  String get tasbihRender;

  /// Shaded bead rendering option in Tasbih settings.
  ///
  /// In ar, this message translates to:
  /// **'إيحاء ثلاثي الأبعاد'**
  String get tasbihRenderSuggested;

  /// Subtitle for the shaded bead rendering option.
  ///
  /// In ar, this message translates to:
  /// **'حبات مظللة، خفيفة على كل الأجهزة'**
  String get tasbihRenderSuggestedHint;

  /// True 3D bead rendering option in Tasbih settings.
  ///
  /// In ar, this message translates to:
  /// **'ثلاثي الأبعاد حقيقي'**
  String get tasbihRenderReal;

  /// Subtitle for the true 3D bead rendering option.
  ///
  /// In ar, this message translates to:
  /// **'كرات في فراغ ثلاثي بمنظور وإضاءة'**
  String get tasbihRenderRealHint;

  /// Label for the bead material picker in Tasbih settings.
  ///
  /// In ar, this message translates to:
  /// **'خامة الحبات'**
  String get tasbihMaterial;

  /// Amber option in the bead material picker.
  ///
  /// In ar, this message translates to:
  /// **'كهرمان'**
  String get tasbihMaterialAmber;

  /// Wood option in the bead material picker.
  ///
  /// In ar, this message translates to:
  /// **'خشب'**
  String get tasbihMaterialWood;

  /// Pearl option in the bead material picker.
  ///
  /// In ar, this message translates to:
  /// **'لؤلؤ'**
  String get tasbihMaterialPearl;

  /// Label for the counter vibration switch in Tasbih settings.
  ///
  /// In ar, this message translates to:
  /// **'اهتزاز خفيف مع كل عدّة'**
  String get tasbihHaptics;

  /// Subtitle for the counter vibration switch.
  ///
  /// In ar, this message translates to:
  /// **'واهتزازة أقوى عند تمام الدورة'**
  String get tasbihHapticsHint;

  /// Label for the bead click sound switch in Tasbih settings.
  ///
  /// In ar, this message translates to:
  /// **'صوت نقرة الحبة'**
  String get tasbihSound;

  /// Label for the switch to keep the screen awake while counting.
  ///
  /// In ar, this message translates to:
  /// **'إبقاء الشاشة مضاءة في المسبحة'**
  String get tasbihKeepScreenOn;

  /// Label for the volume-button counting switch in Tasbih settings.
  ///
  /// In ar, this message translates to:
  /// **'العدّ بأزرار الصوت'**
  String get tasbihVolumeKeys;

  /// Subtitle for the volume-button counting switch.
  ///
  /// In ar, this message translates to:
  /// **'والمسبحة مفتوحة، كل ضغطة تعدّ ولا يتغير الصوت'**
  String get tasbihVolumeKeysHint;

  /// Heading of the Tasbih source credits section on the About screen.
  ///
  /// In ar, this message translates to:
  /// **'مصدر أذكار المسبحة'**
  String get tasbihSourcesTitle;

  /// Navigation action that opens the counter from Tasbih settings.
  ///
  /// In ar, this message translates to:
  /// **'فتح المسبحة'**
  String get tasbihOpen;

  /// Bead click sound credit in the About screen source section.
  ///
  /// In ar, this message translates to:
  /// **'صوت نقرة الحبة مُولَّد برمجيًا داخل المشروع، وهو برخصة CC0.'**
  String get tasbihClickNote;

  /// Compact stage and count progress line beneath the selected entry.
  ///
  /// In ar, this message translates to:
  /// **'{stage}/{stages} · {count}/{of}'**
  String tasbihStageLine(String stage, String stages, String count, String of);

  /// Accessibility announcement and label for the current counter stage.
  ///
  /// In ar, this message translates to:
  /// **'المرحلة {stage} من {stages}'**
  String tasbihStageAnnounce(String stage, String stages);

  /// Message in the target controls when an entry uses fixed stages.
  ///
  /// In ar, this message translates to:
  /// **'الهدف من مراحل الذكر'**
  String get tasbihStagesFixed;

  /// No description provided for @fasilStyleLabel.
  ///
  /// In ar, this message translates to:
  /// **'شكل الفاصلة'**
  String get fasilStyleLabel;

  /// No description provided for @fasilStyleHint.
  ///
  /// In ar, this message translates to:
  /// **'كيف تظهر فواصلك المسمّاة على الصفحة'**
  String get fasilStyleHint;

  /// No description provided for @fasilStyleTint.
  ///
  /// In ar, this message translates to:
  /// **'صفحة ملوّنة'**
  String get fasilStyleTint;

  /// No description provided for @fasilStyleTintHint.
  ///
  /// In ar, this message translates to:
  /// **'تتلوّن الآية بلون الفاصلة، أخفّ الأشكال'**
  String get fasilStyleTintHint;

  /// No description provided for @fasilStyleRibbon.
  ///
  /// In ar, this message translates to:
  /// **'شريطة قماش'**
  String get fasilStyleRibbon;

  /// No description provided for @fasilStyleRibbonHint.
  ///
  /// In ar, this message translates to:
  /// **'شريطة تتدلّى على الصفحة كالمصحف المطبوع'**
  String get fasilStyleRibbonHint;

  /// No description provided for @fasilStyleTab.
  ///
  /// In ar, this message translates to:
  /// **'لسان مقوّى'**
  String get fasilStyleTab;

  /// No description provided for @fasilStyleTabHint.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة بقبّة مزخرفة تطلّ من أعلى الصفحة'**
  String get fasilStyleTabHint;

  /// No description provided for @fasilChooserTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر شكل فواصلك'**
  String get fasilChooserTitle;

  /// No description provided for @fasilChooserHint.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تغيّره في أي وقت من الإعدادات › المصحف'**
  String get fasilChooserHint;

  /// No description provided for @fasilPlaceLabel.
  ///
  /// In ar, this message translates to:
  /// **'مكانها على الصفحة'**
  String get fasilPlaceLabel;

  /// No description provided for @fasilPlaceTop.
  ///
  /// In ar, this message translates to:
  /// **'الحافة العليا'**
  String get fasilPlaceTop;

  /// No description provided for @fasilPlaceSide.
  ///
  /// In ar, this message translates to:
  /// **'الحافة الجانبية'**
  String get fasilPlaceSide;

  /// No description provided for @fasilMaterialLabel.
  ///
  /// In ar, this message translates to:
  /// **'الخامة'**
  String get fasilMaterialLabel;

  /// No description provided for @fasilSilk.
  ///
  /// In ar, this message translates to:
  /// **'حرير'**
  String get fasilSilk;

  /// No description provided for @fasilLinen.
  ///
  /// In ar, this message translates to:
  /// **'كتّان'**
  String get fasilLinen;

  /// No description provided for @fasilVelvet.
  ///
  /// In ar, this message translates to:
  /// **'قطيفة'**
  String get fasilVelvet;

  /// No description provided for @fasilTassel.
  ///
  /// In ar, this message translates to:
  /// **'شُرّابة في طرف الشريطة'**
  String get fasilTassel;

  /// No description provided for @fasilSuggestHifz.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get fasilSuggestHifz;

  /// No description provided for @fasilSuggestTilawa.
  ///
  /// In ar, this message translates to:
  /// **'تلاوة'**
  String get fasilSuggestTilawa;

  /// No description provided for @fasilSuggestReview.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة'**
  String get fasilSuggestReview;

  /// No description provided for @fasilRename.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تسمية'**
  String get fasilRename;

  /// No description provided for @fasilColor.
  ///
  /// In ar, this message translates to:
  /// **'اللون'**
  String get fasilColor;

  /// No description provided for @fasilMoveHere.
  ///
  /// In ar, this message translates to:
  /// **'نقل إلى الصفحة الحالية'**
  String get fasilMoveHere;

  /// No description provided for @fasilDeleted.
  ///
  /// In ar, this message translates to:
  /// **'حُذفت الفاصلة'**
  String get fasilDeleted;

  /// No description provided for @fasilUndo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get fasilUndo;

  /// No description provided for @fasilPreview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة'**
  String get fasilPreview;

  /// No description provided for @fasilDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'حذف الفاصلة «{name}»؟'**
  String fasilDeleteConfirm(String name);

  /// No description provided for @fasilOnPage.
  ///
  /// In ar, this message translates to:
  /// **'فاصلة {name}، الصفحة {page}'**
  String fasilOnPage(String name, String page);

  /// No description provided for @memorizeMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع الحفظ'**
  String get memorizeMode;

  /// No description provided for @memorizeVerses.
  ///
  /// In ar, this message translates to:
  /// **'احفظ هذه الآيات'**
  String get memorizeVerses;

  /// No description provided for @memorizeStart.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ بإخفاء الكلمات'**
  String get memorizeStart;

  /// No description provided for @memorizeStyleTitle.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الإخفاء'**
  String get memorizeStyleTitle;

  /// No description provided for @memorizeStyleAll.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء كل الكلمات'**
  String get memorizeStyleAll;

  /// No description provided for @memorizeStyleFirstLetter.
  ///
  /// In ar, this message translates to:
  /// **'إظهار أول حرف من كل آية'**
  String get memorizeStyleFirstLetter;

  /// No description provided for @memorizeStyleFirstWord.
  ///
  /// In ar, this message translates to:
  /// **'إظهار أول كلمة من كل آية'**
  String get memorizeStyleFirstWord;

  /// No description provided for @memorizeStyleAlternate.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء كلمة وإظهار كلمة'**
  String get memorizeStyleAlternate;

  /// No description provided for @memorizeStyleProgressive.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء متدرج مع كل تكرار'**
  String get memorizeStyleProgressive;

  /// No description provided for @memorizeRevealVerse.
  ///
  /// In ar, this message translates to:
  /// **'اكشف الآية'**
  String get memorizeRevealVerse;

  /// No description provided for @memorizeRevealAll.
  ///
  /// In ar, this message translates to:
  /// **'اكشف الكل'**
  String get memorizeRevealAll;

  /// No description provided for @memorizeHideAll.
  ///
  /// In ar, this message translates to:
  /// **'أخفِ الكل'**
  String get memorizeHideAll;

  /// No description provided for @memorizeRepeat.
  ///
  /// In ar, this message translates to:
  /// **'كرّر'**
  String get memorizeRepeat;

  /// No description provided for @memorizeMastered.
  ///
  /// In ar, this message translates to:
  /// **'أتقنتها'**
  String get memorizeMastered;

  /// No description provided for @memorizeMissed.
  ///
  /// In ar, this message translates to:
  /// **'أخطأت'**
  String get memorizeMissed;

  /// No description provided for @memorizeClose.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء الحفظ'**
  String get memorizeClose;

  /// No description provided for @memorizeHint.
  ///
  /// In ar, this message translates to:
  /// **'المس كلمة لكشفها، أو اضغط مطولًا واسحب لكشف عدة كلمات.'**
  String get memorizeHint;

  /// No description provided for @memorizeProgressiveHint.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ الصفحة، ثم اضغط «كرّر» ليُخفى المزيد.'**
  String get memorizeProgressiveHint;

  /// No description provided for @memorizeLevel.
  ///
  /// In ar, this message translates to:
  /// **'المرحلة {level} من {total}'**
  String memorizeLevel(String level, String total);

  /// No description provided for @memorizeByVoice.
  ///
  /// In ar, this message translates to:
  /// **'الكشف بالتسميع'**
  String get memorizeByVoice;

  /// No description provided for @memorizeByVoiceHint.
  ///
  /// In ar, this message translates to:
  /// **'تظهر الكلمات كلما قرأتها بصوتك.'**
  String get memorizeByVoiceHint;

  /// No description provided for @memorizeVoiceNeedsModel.
  ///
  /// In ar, this message translates to:
  /// **'حمّل نموذج التسميع من إعدادات التسميع لتكشف الكلمات بصوتك.'**
  String get memorizeVoiceNeedsModel;

  /// No description provided for @memorizeVoiceEdition.
  ///
  /// In ar, this message translates to:
  /// **'الكشف بالتسميع متاح في طبعات رواية حفص.'**
  String get memorizeVoiceEdition;

  /// No description provided for @memorizeListening.
  ///
  /// In ar, this message translates to:
  /// **'يستمع…'**
  String get memorizeListening;

  /// No description provided for @memorizeNoWords.
  ///
  /// In ar, this message translates to:
  /// **'لا تتوفر مواضع الكلمات في هذه الصفحة من هذه الطبعة، فتُخفى الآيات كاملة وتُكشف آيةً آية.'**
  String get memorizeNoWords;

  /// No description provided for @memorizeSomeVerses.
  ///
  /// In ar, this message translates to:
  /// **'بعض الآيات بلا مواضع للكلمات في هذه الطبعة، فتُخفى كاملة.'**
  String get memorizeSomeVerses;

  /// No description provided for @memorizeOutOfScope.
  ///
  /// In ar, this message translates to:
  /// **'الآيات المختارة ليست في هذه الصفحة.'**
  String get memorizeOutOfScope;

  /// No description provided for @gkTitle.
  ///
  /// In ar, this message translates to:
  /// **'ختمة جماعية'**
  String get gkTitle;

  /// No description provided for @gkSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'وزّع الأجزاء على أهلك وأصحابك برابط، بلا حساب.'**
  String get gkSubtitle;

  /// No description provided for @gkCreate.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء ختمة جماعية'**
  String get gkCreate;

  /// No description provided for @gkJoin.
  ///
  /// In ar, this message translates to:
  /// **'الانضمام برابط'**
  String get gkJoin;

  /// No description provided for @gkMine.
  ///
  /// In ar, this message translates to:
  /// **'ختماتي الجماعية'**
  String get gkMine;

  /// No description provided for @gkNone.
  ///
  /// In ar, this message translates to:
  /// **'لم تنضمّ إلى ختمة جماعية بعد.'**
  String get gkNone;

  /// No description provided for @gkKhatmaName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الختمة (اختياري)'**
  String get gkKhatmaName;

  /// No description provided for @gkOrganizerName.
  ///
  /// In ar, this message translates to:
  /// **'اسمك منظّمًا (اختياري)'**
  String get gkOrganizerName;

  /// No description provided for @gkUnitJuz.
  ///
  /// In ar, this message translates to:
  /// **'٣٠ جزءًا'**
  String get gkUnitJuz;

  /// No description provided for @gkUnitHizb.
  ///
  /// In ar, this message translates to:
  /// **'٦٠ حزبًا'**
  String get gkUnitHizb;

  /// No description provided for @gkTargetDate.
  ///
  /// In ar, this message translates to:
  /// **'موعد الختم (اختياري)'**
  String get gkTargetDate;

  /// No description provided for @gkNoDate.
  ///
  /// In ar, this message translates to:
  /// **'بلا موعد'**
  String get gkNoDate;

  /// No description provided for @gkCreateAction.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء'**
  String get gkCreateAction;

  /// No description provided for @gkLinkHint.
  ///
  /// In ar, this message translates to:
  /// **'الصق رابط الختمة'**
  String get gkLinkHint;

  /// No description provided for @gkLinkInvalid.
  ///
  /// In ar, this message translates to:
  /// **'هذا ليس رابط ختمة جماعية.'**
  String get gkLinkInvalid;

  /// No description provided for @gkOpen.
  ///
  /// In ar, this message translates to:
  /// **'فتح'**
  String get gkOpen;

  /// No description provided for @gkProgress.
  ///
  /// In ar, this message translates to:
  /// **'محجوز {taken} من {total} · تمّ {done}'**
  String gkProgress(int taken, int done, int total);

  /// No description provided for @gkJuzN.
  ///
  /// In ar, this message translates to:
  /// **'الجزء {n}'**
  String gkJuzN(int n);

  /// No description provided for @gkHizbN.
  ///
  /// In ar, this message translates to:
  /// **'الحزب {n}'**
  String gkHizbN(int n);

  /// No description provided for @gkOpenPart.
  ///
  /// In ar, this message translates to:
  /// **'متاح'**
  String get gkOpenPart;

  /// No description provided for @gkTakenPart.
  ///
  /// In ar, this message translates to:
  /// **'محجوز'**
  String get gkTakenPart;

  /// No description provided for @gkDonePart.
  ///
  /// In ar, this message translates to:
  /// **'تمّ'**
  String get gkDonePart;

  /// No description provided for @gkClaim.
  ///
  /// In ar, this message translates to:
  /// **'احجز'**
  String get gkClaim;

  /// No description provided for @gkYourName.
  ///
  /// In ar, this message translates to:
  /// **'اسمك كما سيظهر للمشاركين'**
  String get gkYourName;

  /// No description provided for @gkMarkDone.
  ///
  /// In ar, this message translates to:
  /// **'تمّت قراءته'**
  String get gkMarkDone;

  /// No description provided for @gkUndoDone.
  ///
  /// In ar, this message translates to:
  /// **'لم أُتمّه بعد'**
  String get gkUndoDone;

  /// No description provided for @gkRelease.
  ///
  /// In ar, this message translates to:
  /// **'تراجع عن الحجز'**
  String get gkRelease;

  /// No description provided for @gkReleaseOther.
  ///
  /// In ar, this message translates to:
  /// **'تحرير الجزء'**
  String get gkReleaseOther;

  /// No description provided for @gkShare.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الرابط'**
  String get gkShare;

  /// No description provided for @gkShareText.
  ///
  /// In ar, this message translates to:
  /// **'شارك معنا في «{title}»: اختر جزءًا واكتب اسمك.\n{link}'**
  String gkShareText(String title, String link);

  /// No description provided for @gkRename.
  ///
  /// In ar, this message translates to:
  /// **'إعادة التسمية'**
  String get gkRename;

  /// No description provided for @gkDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف الختمة'**
  String get gkDelete;

  /// No description provided for @gkDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'ستُحذف الختمة عند جميع المشاركين.'**
  String get gkDeleteConfirm;

  /// No description provided for @gkForget.
  ///
  /// In ar, this message translates to:
  /// **'إزالة من قائمتي'**
  String get gkForget;

  /// No description provided for @gkCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get gkCancel;

  /// No description provided for @gkSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get gkSave;

  /// No description provided for @gkOfflineCached.
  ///
  /// In ar, this message translates to:
  /// **'لا اتصال بالإنترنت. هذه آخر حالة محفوظة.'**
  String get gkOfflineCached;

  /// No description provided for @gkErrOffline.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال. حاول مرة أخرى.'**
  String get gkErrOffline;

  /// No description provided for @gkErrNotFound.
  ///
  /// In ar, this message translates to:
  /// **'هذه الختمة غير موجودة؛ ربما حُذفت.'**
  String get gkErrNotFound;

  /// No description provided for @gkErrTaken.
  ///
  /// In ar, this message translates to:
  /// **'سبقك أحد إلى هذا الجزء.'**
  String get gkErrTaken;

  /// No description provided for @gkErrForbidden.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكنك تعديل هذا الجزء من هذا الجهاز.'**
  String get gkErrForbidden;

  /// No description provided for @gkErrBusy.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة، حاول بعد قليل.'**
  String get gkErrBusy;

  /// No description provided for @gkErrInvalid.
  ///
  /// In ar, this message translates to:
  /// **'تحقّق ممّا كتبت.'**
  String get gkErrInvalid;

  /// No description provided for @gkOrganizer.
  ///
  /// In ar, this message translates to:
  /// **'ينظّمها {name}'**
  String gkOrganizer(String name);

  /// No description provided for @gkTarget.
  ///
  /// In ar, this message translates to:
  /// **'الموعد {date}'**
  String gkTarget(String date);

  /// No description provided for @gkYou.
  ///
  /// In ar, this message translates to:
  /// **'أنت'**
  String get gkYou;

  /// No description provided for @gkCompleted.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت الختمة.'**
  String get gkCompleted;

  /// No description provided for @gkRemind.
  ///
  /// In ar, this message translates to:
  /// **'ذكّرني بجزئي'**
  String get gkRemind;

  /// No description provided for @gkReminderSet.
  ///
  /// In ar, this message translates to:
  /// **'تذكير: {date}'**
  String gkReminderSet(String date);

  /// No description provided for @gkReminderCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التذكير'**
  String get gkReminderCancel;

  /// No description provided for @gkReminderBody.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت قراءة {part} في الختمة الجماعية.'**
  String gkReminderBody(String part);

  /// No description provided for @gkPrivacyNote.
  ///
  /// In ar, this message translates to:
  /// **'يحفظ خادم تبيان اسم الختمة والأسماء المكتوبة وحالة الأجزاء فقط، ويحذفها تلقائيًا بعد انتهاء الختمة.'**
  String get gkPrivacyNote;

  /// No description provided for @settingsSectionAccessibility.
  ///
  /// In ar, this message translates to:
  /// **'إمكانية الوصول'**
  String get settingsSectionAccessibility;

  /// No description provided for @settingsSectionAccessibilityHint.
  ///
  /// In ar, this message translates to:
  /// **'تقليل الحركة، قارئ الشاشة'**
  String get settingsSectionAccessibilityHint;

  /// No description provided for @reduceMotionLabel.
  ///
  /// In ar, this message translates to:
  /// **'تقليل الحركة'**
  String get reduceMotionLabel;

  /// No description provided for @reduceMotionHint.
  ///
  /// In ar, this message translates to:
  /// **'يتبع إعداد الجهاز تلقائيًا، ويمكنك تفعيله هنا دائمًا: انتقالات بلا انزلاق وحركات أقل'**
  String get reduceMotionHint;

  /// No description provided for @announceVerseNumberLabel.
  ///
  /// In ar, this message translates to:
  /// **'قراءة رقم الآية مع نصها'**
  String get announceVerseNumberLabel;

  /// No description provided for @announceVerseNumberHint.
  ///
  /// In ar, this message translates to:
  /// **'في قارئ الشاشة: اسم السورة ورقم الآية قبل نص الآية'**
  String get announceVerseNumberHint;

  /// No description provided for @systemAccessibilitySettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات إمكانية الوصول في الجهاز'**
  String get systemAccessibilitySettings;

  /// No description provided for @systemAccessibilitySettingsHint.
  ///
  /// In ar, this message translates to:
  /// **'حجم الخط، قارئ الشاشة، تقليل الحركة على مستوى الجهاز'**
  String get systemAccessibilitySettingsHint;

  /// No description provided for @systemSettingsUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح إعدادات الجهاز'**
  String get systemSettingsUnavailable;

  /// No description provided for @weeklyReportTitle.
  ///
  /// In ar, this message translates to:
  /// **'التقرير الأسبوعي'**
  String get weeklyReportTitle;

  /// No description provided for @weeklyReportHint.
  ///
  /// In ar, this message translates to:
  /// **'ملخص هادئ لقراءتك وحفظك في سبعة أيام'**
  String get weeklyReportHint;

  /// No description provided for @weeklyRange.
  ///
  /// In ar, this message translates to:
  /// **'{from} – {to}'**
  String weeklyRange(String from, String to);

  /// No description provided for @weeklyThisWeek.
  ///
  /// In ar, this message translates to:
  /// **'آخر سبعة أيام'**
  String get weeklyThisWeek;

  /// No description provided for @weeklyPrevious.
  ///
  /// In ar, this message translates to:
  /// **'الأسبوع السابق'**
  String get weeklyPrevious;

  /// No description provided for @weeklyNext.
  ///
  /// In ar, this message translates to:
  /// **'الأسبوع التالي'**
  String get weeklyNext;

  /// No description provided for @weeklyNoteFresh.
  ///
  /// In ar, this message translates to:
  /// **'أسبوع جديد وبداية جديدة. صفحة واحدة تكفي لتبدأ.'**
  String get weeklyNoteFresh;

  /// No description provided for @weeklyNoteSome.
  ///
  /// In ar, this message translates to:
  /// **'بارك الله في وقتك. كل صفحة تقرؤها خير.'**
  String get weeklyNoteSome;

  /// No description provided for @weeklyMissedDays.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{يوم واحد بلا ورد هذا الأسبوع} =2{يومان بلا ورد هذا الأسبوع} few{{count} أيام بلا ورد هذا الأسبوع} many{{count} يومًا بلا ورد هذا الأسبوع} other{{count} يوم بلا ورد هذا الأسبوع}}'**
  String weeklyMissedDays(int n, String count);

  /// No description provided for @weeklyNoteMost.
  ///
  /// In ar, this message translates to:
  /// **'ما شاء الله، كان القرآن رفيقك في أكثر أيام هذا الأسبوع.'**
  String get weeklyNoteMost;

  /// No description provided for @weeklyDailyChart.
  ///
  /// In ar, this message translates to:
  /// **'دقائق القراءة والاستماع في كل يوم'**
  String get weeklyDailyChart;

  /// No description provided for @weeklyDayMinutes.
  ///
  /// In ar, this message translates to:
  /// **'{day}: {minutes} دقيقة'**
  String weeklyDayMinutes(String day, String minutes);

  /// No description provided for @weeklyActiveDays.
  ///
  /// In ar, this message translates to:
  /// **'أيام فيها قراءة أو ذكر'**
  String get weeklyActiveDays;

  /// No description provided for @weeklyRecitations.
  ///
  /// In ar, this message translates to:
  /// **'جلسات التسميع'**
  String get weeklyRecitations;

  /// No description provided for @weeklyVersesRecited.
  ///
  /// In ar, this message translates to:
  /// **'آيات سمّعتها'**
  String get weeklyVersesRecited;

  /// No description provided for @weeklyTasbih.
  ///
  /// In ar, this message translates to:
  /// **'التسبيحات'**
  String get weeklyTasbih;

  /// No description provided for @weeklyKhatmas.
  ///
  /// In ar, this message translates to:
  /// **'الختمات'**
  String get weeklyKhatmas;

  /// No description provided for @weeklyKhatmaProgress.
  ///
  /// In ar, this message translates to:
  /// **'{percent}٪ من الختمة'**
  String weeklyKhatmaProgress(String percent);

  /// No description provided for @weeklyKhatmaGained.
  ///
  /// In ar, this message translates to:
  /// **'قرأت {percent}٪ منها هذا الأسبوع'**
  String weeklyKhatmaGained(String percent);

  /// No description provided for @weeklyEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'لم يُسجَّل شيء في هذه الأيام، ولا بأس. ستظهر هنا قراءتك واستماعك وتسميعك تلقائيًا.'**
  String get weeklyEmptyBody;

  /// No description provided for @weeklyReminderToggle.
  ///
  /// In ar, this message translates to:
  /// **'تذكير أسبوعي بالتقرير'**
  String get weeklyReminderToggle;

  /// No description provided for @weeklyReminderHint.
  ///
  /// In ar, this message translates to:
  /// **'إشعار على هذا الجهاز في اليوم والوقت اللذين تختارهما'**
  String get weeklyReminderHint;

  /// No description provided for @weeklyReminderWhen.
  ///
  /// In ar, this message translates to:
  /// **'يوم التذكير ووقته'**
  String get weeklyReminderWhen;

  /// No description provided for @weeklyReminderTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقريرك الأسبوعي جاهز'**
  String get weeklyReminderTitle;

  /// No description provided for @weeklyReminderBody.
  ///
  /// In ar, this message translates to:
  /// **'ألقِ نظرة هادئة على أسبوعك مع القرآن.'**
  String get weeklyReminderBody;

  /// No description provided for @weeklyReminderChannel.
  ///
  /// In ar, this message translates to:
  /// **'التقرير الأسبوعي'**
  String get weeklyReminderChannel;

  /// No description provided for @kahfReminderToggle.
  ///
  /// In ar, this message translates to:
  /// **'تذكير الجمعة بسورة الكهف'**
  String get kahfReminderToggle;

  /// No description provided for @kahfReminderHint.
  ///
  /// In ar, this message translates to:
  /// **'إشعار على هذا الجهاز صباح كل جمعة يفتح سورة الكهف'**
  String get kahfReminderHint;

  /// No description provided for @kahfReminderTitle.
  ///
  /// In ar, this message translates to:
  /// **'تذكير: سورة الكهف'**
  String get kahfReminderTitle;

  /// No description provided for @kahfReminderBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لفتح السورة.'**
  String get kahfReminderBody;

  /// No description provided for @kahfReminderChannel.
  ///
  /// In ar, this message translates to:
  /// **'تذكير الجمعة'**
  String get kahfReminderChannel;

  /// No description provided for @liveActivityVerse.
  ///
  /// In ar, this message translates to:
  /// **'الآية {number}'**
  String liveActivityVerse(String number);

  /// No description provided for @liveActivityPlay.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get liveActivityPlay;

  /// No description provided for @liveActivityPreviousVerse.
  ///
  /// In ar, this message translates to:
  /// **'الآية السابقة'**
  String get liveActivityPreviousVerse;

  /// No description provided for @liveActivityNextVerse.
  ///
  /// In ar, this message translates to:
  /// **'الآية التالية'**
  String get liveActivityNextVerse;

  /// No description provided for @syncTitle.
  ///
  /// In ar, this message translates to:
  /// **'المزامنة'**
  String get syncTitle;

  /// No description provided for @syncHint.
  ///
  /// In ar, this message translates to:
  /// **'بين أجهزتك عبر iCloud أو Google Drive، دون حساب في تبيان'**
  String get syncHint;

  /// No description provided for @syncSwitch.
  ///
  /// In ar, this message translates to:
  /// **'مزامنة بين أجهزتي'**
  String get syncSwitch;

  /// No description provided for @syncViaICloud.
  ///
  /// In ar, this message translates to:
  /// **'عبر حسابك في iCloud'**
  String get syncViaICloud;

  /// No description provided for @syncViaDrive.
  ///
  /// In ar, this message translates to:
  /// **'عبر حسابك في Google Drive، في مجلد خاص بالتطبيق لا يظهر بين ملفاتك'**
  String get syncViaDrive;

  /// No description provided for @syncWhat.
  ///
  /// In ar, this message translates to:
  /// **'يُزامَن: الفواصل والعلامات، والختمات وتقدمها، والمسبحة، وسجل الحفظ، وإعدادات المظهر وقلب الصفحات والقارئ. لا تُزامَن التنزيلات ولا إعدادات الجهاز.'**
  String get syncWhat;

  /// No description provided for @syncPrivacy.
  ///
  /// In ar, this message translates to:
  /// **'تبقى البيانات في حسابك أنت، ولا يصل إليها تبيان. وتعمل دون اتصال، وتُزامَن عند عودة الاتصال.'**
  String get syncPrivacy;

  /// No description provided for @syncNow.
  ///
  /// In ar, this message translates to:
  /// **'زامن الآن'**
  String get syncNow;

  /// No description provided for @syncLast.
  ///
  /// In ar, this message translates to:
  /// **'آخر مزامنة: {time}'**
  String syncLast(String time);

  /// No description provided for @syncNever.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم المزامنة بعد'**
  String get syncNever;

  /// No description provided for @syncRunning.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ المزامنة…'**
  String get syncRunning;

  /// No description provided for @syncFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذرت المزامنة، وستُعاد المحاولة تلقائيًا.'**
  String get syncFailed;

  /// No description provided for @syncNotInBuild.
  ///
  /// In ar, this message translates to:
  /// **'غير متاحة في هذه النسخة'**
  String get syncNotInBuild;

  /// No description provided for @syncNoAccountICloud.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول إلى iCloud في إعدادات الجهاز وفعّل iCloud Drive لهذا التطبيق.'**
  String get syncNoAccountICloud;

  /// No description provided for @syncNoAccountDrive.
  ///
  /// In ar, this message translates to:
  /// **'اختر حساب Google لتفعيل المزامنة.'**
  String get syncNoAccountDrive;

  /// No description provided for @syncUnsupported.
  ///
  /// In ar, this message translates to:
  /// **'المزامنة غير متاحة على هذا الجهاز.'**
  String get syncUnsupported;

  /// No description provided for @syncNoGoogleServices.
  ///
  /// In ar, this message translates to:
  /// **'تحتاج مزامنة Google Drive إلى خدمات Google Play، وهي غير متوفرة على هذا الجهاز. لنقل بياناتك استخدم «النسخ الاحتياطي» في الإعدادات.'**
  String get syncNoGoogleServices;

  /// No description provided for @syncDeleteCloud.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف المزامنة وحذف بيانات السحابة'**
  String get syncDeleteCloud;

  /// No description provided for @syncDeleteConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف بيانات المزامنة من السحابة؟'**
  String get syncDeleteConfirmTitle;

  /// No description provided for @syncDeleteConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'تتوقف المزامنة ويُحذف ما رفعته أجهزتك إلى السحابة. تبقى بياناتك على هذا الجهاز كما هي. وإن بقيت المزامنة مفعّلة على جهاز آخر رفع بياناته من جديد.'**
  String get syncDeleteConfirmBody;

  /// No description provided for @syncDeleted.
  ///
  /// In ar, this message translates to:
  /// **'حُذفت بيانات المزامنة من السحابة.'**
  String get syncDeleted;

  /// No description provided for @syncDeleteFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الوصول إلى السحابة، فلم يُحذف شيء.'**
  String get syncDeleteFailed;

  /// No description provided for @shareVerseVideo.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة كمقطع فيديو'**
  String get shareVerseVideo;

  /// No description provided for @shareVideoTitle.
  ///
  /// In ar, this message translates to:
  /// **'مقطع فيديو للتلاوة'**
  String get shareVideoTitle;

  /// No description provided for @shareVideoFrom.
  ///
  /// In ar, this message translates to:
  /// **'من الآية'**
  String get shareVideoFrom;

  /// No description provided for @shareVideoTo.
  ///
  /// In ar, this message translates to:
  /// **'إلى الآية'**
  String get shareVideoTo;

  /// No description provided for @shareVideoReciter.
  ///
  /// In ar, this message translates to:
  /// **'القارئ'**
  String get shareVideoReciter;

  /// No description provided for @shareVideoLength.
  ///
  /// In ar, this message translates to:
  /// **'مدة المقطع نحو {seconds} ثانية'**
  String shareVideoLength(String seconds);

  /// No description provided for @shareVideoTooLong.
  ///
  /// In ar, this message translates to:
  /// **'المقطع أطول من {max} ثانية، اختر آيات أقل.'**
  String shareVideoTooLong(String max);

  /// No description provided for @shareVideoWordsNote.
  ///
  /// In ar, this message translates to:
  /// **'تُضاء الكلمة المتلوة كلمةً كلمة.'**
  String get shareVideoWordsNote;

  /// No description provided for @shareVideoAyahNote.
  ///
  /// In ar, this message translates to:
  /// **'لا توقيت كلمات لهذا القارئ، فتُضاء الآية كلها.'**
  String get shareVideoAyahNote;

  /// No description provided for @shareVideoNoTimings.
  ///
  /// In ar, this message translates to:
  /// **'لا توقيت آيات لهذا القارئ في هذه السورة، فلا يمكن صنع مقطع بتلاوته.'**
  String get shareVideoNoTimings;

  /// No description provided for @shareVideoRiwaya.
  ///
  /// In ar, this message translates to:
  /// **'مقاطع الفيديو متاحة الآن لرواية حفص فقط.'**
  String get shareVideoRiwaya;

  /// No description provided for @shareVideoMake.
  ///
  /// In ar, this message translates to:
  /// **'اصنع المقطع'**
  String get shareVideoMake;

  /// No description provided for @shareVideoAudio.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل التلاوة…'**
  String get shareVideoAudio;

  /// No description provided for @shareVideoRendering.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ صنع المقطع… {percent}٪'**
  String shareVideoRendering(String percent);

  /// No description provided for @shareVideoSaving.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ حفظ المقطع…'**
  String get shareVideoSaving;

  /// No description provided for @shareVideoReady.
  ///
  /// In ar, this message translates to:
  /// **'المقطع جاهز'**
  String get shareVideoReady;

  /// No description provided for @shareVideoShare.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة المقطع'**
  String get shareVideoShare;

  /// No description provided for @shareVideoFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر صنع المقطع'**
  String get shareVideoFailed;

  /// No description provided for @shareVideoOffline.
  ///
  /// In ar, this message translates to:
  /// **'التلاوة غير محمّلة على الجهاز ولا اتصال بالإنترنت.'**
  String get shareVideoOffline;

  /// No description provided for @shareVideoUnsupported.
  ///
  /// In ar, this message translates to:
  /// **'صنع مقاطع الفيديو غير متاح على هذا الجهاز.'**
  String get shareVideoUnsupported;

  /// No description provided for @reelHeading.
  ///
  /// In ar, this message translates to:
  /// **'من القرآن الكريم'**
  String get reelHeading;

  /// No description provided for @reelVoice.
  ///
  /// In ar, this message translates to:
  /// **'بصوت الشيخ {name}'**
  String reelVoice(String name);

  /// No description provided for @reelCredit.
  ///
  /// In ar, this message translates to:
  /// **'تلاوة الشيخ {name} · {source}'**
  String reelCredit(String name, String source);

  /// No description provided for @reelJoin.
  ///
  /// In ar, this message translates to:
  /// **'حمّل التطبيق الآن'**
  String get reelJoin;

  /// No description provided for @reelVerse.
  ///
  /// In ar, this message translates to:
  /// **'الآية {n}'**
  String reelVerse(String n);

  /// No description provided for @reelVerses.
  ///
  /// In ar, this message translates to:
  /// **'الآيات {from} إلى {to}'**
  String reelVerses(String from, String to);

  /// No description provided for @tabFawasil.
  ///
  /// In ar, this message translates to:
  /// **'الفواصل'**
  String get tabFawasil;

  /// No description provided for @fasilMoveTo.
  ///
  /// In ar, this message translates to:
  /// **'انقل إلى…'**
  String get fasilMoveTo;

  /// No description provided for @fasilMoveTitle.
  ///
  /// In ar, this message translates to:
  /// **'انقل «{name}» إلى'**
  String fasilMoveTitle(String name);

  /// No description provided for @fasilMoveBySurah.
  ///
  /// In ar, this message translates to:
  /// **'سورة وآية'**
  String get fasilMoveBySurah;

  /// No description provided for @fasilMoveByPage.
  ///
  /// In ar, this message translates to:
  /// **'رقم الصفحة'**
  String get fasilMoveByPage;

  /// No description provided for @fasilMoveCurrent.
  ///
  /// In ar, this message translates to:
  /// **'موضع القراءة الحالي'**
  String get fasilMoveCurrent;

  /// No description provided for @fasilSurah.
  ///
  /// In ar, this message translates to:
  /// **'السورة'**
  String get fasilSurah;

  /// No description provided for @fasilAyah.
  ///
  /// In ar, this message translates to:
  /// **'الآية'**
  String get fasilAyah;

  /// No description provided for @fasilPage.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة'**
  String get fasilPage;

  /// No description provided for @fasilMove.
  ///
  /// In ar, this message translates to:
  /// **'انقل'**
  String get fasilMove;

  /// No description provided for @fasilMoved.
  ///
  /// In ar, this message translates to:
  /// **'نُقلت الفاصلة'**
  String get fasilMoved;

  /// No description provided for @fasilRenameAction.
  ///
  /// In ar, this message translates to:
  /// **'أعد التسمية'**
  String get fasilRenameAction;

  /// No description provided for @fasilChangeStyle.
  ///
  /// In ar, this message translates to:
  /// **'غيّر الشكل والخامة واللون'**
  String get fasilChangeStyle;

  /// No description provided for @fasilStyleTitle.
  ///
  /// In ar, this message translates to:
  /// **'مظهر «{name}»'**
  String fasilStyleTitle(String name);

  /// No description provided for @fasilFollowDefault.
  ///
  /// In ar, this message translates to:
  /// **'اتبع الإعداد الافتراضي'**
  String get fasilFollowDefault;

  /// No description provided for @fasilDefaultOption.
  ///
  /// In ar, this message translates to:
  /// **'الافتراضي'**
  String get fasilDefaultOption;

  /// No description provided for @fasilLimitTitle.
  ///
  /// In ar, this message translates to:
  /// **'بلغت الحدّ الأقصى: {max} فواصل، منها العلامات الثابتة'**
  String fasilLimitTitle(int max);

  /// No description provided for @fasilLimitHint.
  ///
  /// In ar, this message translates to:
  /// **'تُحسب العلامات الثابتة التي وضعتها (قراءة، مراجعة، حفظ، تدبر) ضمن الحدّ. انقل إحدى فواصلك إلى هذا الموضع، أو احذف واحدة لتضيف فاصلة جديدة.'**
  String get fasilLimitHint;

  /// No description provided for @fasilLimitOver.
  ///
  /// In ar, this message translates to:
  /// **'لديك {count} فواصل وُضعت قبل تحديد الحدّ، وهي محفوظة كلها. لتضيف فاصلة جديدة احذف حتى يبقى {keep} أو أقل.'**
  String fasilLimitOver(int count, int keep);

  /// No description provided for @fasilMoveHereShort.
  ///
  /// In ar, this message translates to:
  /// **'انقلها إلى هنا'**
  String get fasilMoveHereShort;

  /// No description provided for @fasilReorderHint.
  ///
  /// In ar, this message translates to:
  /// **'اسحب الفاصلة لترتيبها كما تظهر على حافة الصفحة.'**
  String get fasilReorderHint;

  /// No description provided for @fasilItemLabel.
  ///
  /// In ar, this message translates to:
  /// **'فاصلة {name}، {surah} الآية {ayah}، الصفحة {page}'**
  String fasilItemLabel(String name, String surah, String ayah, String page);

  /// No description provided for @fasilInvalidPlace.
  ///
  /// In ar, this message translates to:
  /// **'موضع غير صحيح'**
  String get fasilInvalidPlace;

  /// No description provided for @fasilCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} من {max}'**
  String fasilCount(int count, int max);

  /// No description provided for @fasilMoveUp.
  ///
  /// In ar, this message translates to:
  /// **'قدّمها'**
  String get fasilMoveUp;

  /// No description provided for @fasilMoveDown.
  ///
  /// In ar, this message translates to:
  /// **'أخّرها'**
  String get fasilMoveDown;

  /// No description provided for @whatsNewBuild.
  ///
  /// In ar, this message translates to:
  /// **'التحديث {build}'**
  String whatsNewBuild(String build);

  /// No description provided for @whatsNewIntro.
  ///
  /// In ar, this message translates to:
  /// **'ما أضفناه وحسّنّاه في التحديثات الأخيرة.'**
  String get whatsNewIntro;

  /// No description provided for @wn42Fawasil.
  ///
  /// In ar, this message translates to:
  /// **'فواصل على ذوقك'**
  String get wn42Fawasil;

  /// No description provided for @wn42FawasilBody.
  ///
  /// In ar, this message translates to:
  /// **'لكل فاصل شكله وخامته ولونه، وتتسع الصفحة لثمانية فواصل؛ فإن أضفت تاسعًا عرضنا عليك نقل أحدها أو حذفه.'**
  String get wn42FawasilBody;

  /// No description provided for @wn42Index.
  ///
  /// In ar, this message translates to:
  /// **'الفواصل في الفهرس'**
  String get wn42Index;

  /// No description provided for @wn42IndexBody.
  ///
  /// In ar, this message translates to:
  /// **'انقل أي فاصل إلى سورة وآية أو إلى صفحة، وأعد تسميته أو ترتيبه، واحذفه مع إمكان التراجع.'**
  String get wn42IndexBody;

  /// No description provided for @wn42Ribbons.
  ///
  /// In ar, this message translates to:
  /// **'أشرطة في الهامش'**
  String get wn42Ribbons;

  /// No description provided for @wn42RibbonsBody.
  ///
  /// In ar, this message translates to:
  /// **'تتدلى الأشرطة في هامش الصفحة بجوار النص كشريط المصحف، ولا تغطي سطرًا أبدًا.'**
  String get wn42RibbonsBody;

  /// No description provided for @wn42Speed.
  ///
  /// In ar, this message translates to:
  /// **'تقليب أسلس'**
  String get wn42Speed;

  /// No description provided for @wn42SpeedBody.
  ///
  /// In ar, this message translates to:
  /// **'صار تقليب الصفحات أخف وأسرع، وتنفتح الصفحة من الفهرس ومن الشاشة الرئيسية في الحال.'**
  String get wn42SpeedBody;

  /// No description provided for @wn42Crash.
  ///
  /// In ar, this message translates to:
  /// **'تقارير أعطال مجهولة الهوية'**
  String get wn42Crash;

  /// No description provided for @wn42CrashBody.
  ///
  /// In ar, this message translates to:
  /// **'بإذنك وحده: تقارير لا تحمل اسمك ولا جهازك ولا ما تكتبه، تعيننا على إصلاح الأخطاء أسرع، ويمكنك تغييرها من الإعدادات.'**
  String get wn42CrashBody;

  /// No description provided for @wn41Hifz.
  ///
  /// In ar, this message translates to:
  /// **'وضع الحفظ'**
  String get wn41Hifz;

  /// No description provided for @wn41HifzBody.
  ///
  /// In ar, this message translates to:
  /// **'يخفي المصحف الكلمات لتستظهرها، بخمسة أنماط للإخفاء، وتنكشف الكلمة بلمسة أو مع تلاوتك.'**
  String get wn41HifzBody;

  /// No description provided for @wn41Group.
  ///
  /// In ar, this message translates to:
  /// **'الختمة الجماعية'**
  String get wn41Group;

  /// No description provided for @wn41GroupBody.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ ختمة وشارك رابطها، فيختار كل مشارك جزءًا باسمه، بلا حساب ولا بريد.'**
  String get wn41GroupBody;

  /// No description provided for @wn41Report.
  ///
  /// In ar, this message translates to:
  /// **'التقرير الأسبوعي'**
  String get wn41Report;

  /// No description provided for @wn41ReportBody.
  ///
  /// In ar, this message translates to:
  /// **'دقائق قراءتك واستماعك وصفحات أسبوعك وتقدّم ختماتك، بملاحظات هادئة لا تقارن بين الأسابيع.'**
  String get wn41ReportBody;

  /// No description provided for @wn41Sync.
  ///
  /// In ar, this message translates to:
  /// **'المزامنة بين أجهزتك'**
  String get wn41Sync;

  /// No description provided for @wn41SyncBody.
  ///
  /// In ar, this message translates to:
  /// **'تنتقل فواصلك وختماتك ومسبحتك وإعداداتك بين أجهزتك عبر iCloud أو Google Drive الخاص بك، دون خادم لتبيان.'**
  String get wn41SyncBody;

  /// No description provided for @wn41Watch.
  ///
  /// In ar, this message translates to:
  /// **'الساعة'**
  String get wn41Watch;

  /// No description provided for @wn41WatchBody.
  ///
  /// In ar, this message translates to:
  /// **'ورد اليوم والمسبحة على Apple Watch وWear OS، مع إضافات لواجهة الساعة.'**
  String get wn41WatchBody;

  /// No description provided for @wn41Video.
  ///
  /// In ar, this message translates to:
  /// **'المشاركة مقطعًا مرئيًا'**
  String get wn41Video;

  /// No description provided for @wn41VideoBody.
  ///
  /// In ar, this message translates to:
  /// **'شارك آيات بتلاوة القارئ الذي تختاره في مقطع رأسي يُصنع على جهازك، بلا موسيقى ولا مؤثرات.'**
  String get wn41VideoBody;

  /// No description provided for @wn41A11y.
  ///
  /// In ar, this message translates to:
  /// **'إمكانية الوصول'**
  String get wn41A11y;

  /// No description provided for @wn41A11yBody.
  ///
  /// In ar, this message translates to:
  /// **'تقليل الحركة، وقراءة رقم الآية لقارئ الشاشة، ونص أكبر حتى الضعف دون تداخل.'**
  String get wn41A11yBody;

  /// No description provided for @wn40Tasbih.
  ///
  /// In ar, this message translates to:
  /// **'المسبحة'**
  String get wn40Tasbih;

  /// No description provided for @wn40TasbihBody.
  ///
  /// In ar, this message translates to:
  /// **'زر التصفير والضغط المطوّل يستجيبان كما ينبغي، ولكل ذكر من الأذكار المعدّة وصف قصير.'**
  String get wn40TasbihBody;

  /// No description provided for @khatmaPlansLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل الختمات. أعد المحاولة بعد قليل.'**
  String get khatmaPlansLoadFailed;

  /// No description provided for @fasilColorOption.
  ///
  /// In ar, this message translates to:
  /// **'اللون {n} من {count}'**
  String fasilColorOption(int n, int count);

  /// No description provided for @wn42Night.
  ///
  /// In ar, this message translates to:
  /// **'ليلي وأسود متمايزان'**
  String get wn42Night;

  /// No description provided for @wn42NightBody.
  ///
  /// In ar, this message translates to:
  /// **'صار الوضعان الليلي والأسود مختلفين بوضوح، والأسود أسود خالص يناسب شاشات OLED.'**
  String get wn42NightBody;

  /// No description provided for @wn42Kahf.
  ///
  /// In ar, this message translates to:
  /// **'تذكير سورة الكهف'**
  String get wn42Kahf;

  /// No description provided for @wn42KahfBody.
  ///
  /// In ar, this message translates to:
  /// **'تذكير يوم الجمعة بقراءة سورة الكهف، مفعّل افتراضيًا ويمكنك إيقافه من الإعدادات.'**
  String get wn42KahfBody;

  /// No description provided for @wn42Voice.
  ///
  /// In ar, this message translates to:
  /// **'اختصارات Siri وGoogle Assistant'**
  String get wn42Voice;

  /// No description provided for @wn42VoiceBody.
  ///
  /// In ar, this message translates to:
  /// **'افتح المصحف أو ورد اليوم أو المسبحة بصوتك.'**
  String get wn42VoiceBody;

  /// No description provided for @wn42Live.
  ///
  /// In ar, this message translates to:
  /// **'التلاوة على شاشة القفل'**
  String get wn42Live;

  /// No description provided for @wn42LiveBody.
  ///
  /// In ar, this message translates to:
  /// **'نشاط مباشر وجزيرة ديناميكية على iPhone يعرضان التلاوة وتقدّم السورة، مع الانتقال إلى الآية السابقة والتالية.'**
  String get wn42LiveBody;

  /// No description provided for @wn42Desktop.
  ///
  /// In ar, this message translates to:
  /// **'تبيان على Windows وLinux'**
  String get wn42Desktop;

  /// No description provided for @wn42DesktopBody.
  ///
  /// In ar, this message translates to:
  /// **'تطبيقان لسطح المكتب، يُنزَّلان من موقع تبيان.'**
  String get wn42DesktopBody;

  /// No description provided for @widgetListen.
  ///
  /// In ar, this message translates to:
  /// **'استمع'**
  String get widgetListen;

  /// No description provided for @widgetTodayWird.
  ///
  /// In ar, this message translates to:
  /// **'ورد اليوم'**
  String get widgetTodayWird;

  /// No description provided for @widgetStartWird.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الورد'**
  String get widgetStartWird;

  /// The khatma widget's day of the plan.
  ///
  /// In ar, this message translates to:
  /// **'اليوم {n} من {m}'**
  String widgetDayOf(String n, String m);

  /// No description provided for @widgetTileContinue.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get widgetTileContinue;

  /// No description provided for @widgetTileListen.
  ///
  /// In ar, this message translates to:
  /// **'استماع'**
  String get widgetTileListen;

  /// No description provided for @widgetTileSearch.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get widgetTileSearch;

  /// No description provided for @widgetTileRead.
  ///
  /// In ar, this message translates to:
  /// **'قرأت الورد'**
  String get widgetTileRead;

  /// No description provided for @widgetTileDone.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get widgetTileDone;

  /// No description provided for @updateCheckTitle.
  ///
  /// In ar, this message translates to:
  /// **'البحث عن تحديثات'**
  String get updateCheckTitle;

  /// No description provided for @updateChecking.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ البحث عن تحديث…'**
  String get updateChecking;

  /// No description provided for @updateUpToDate.
  ///
  /// In ar, this message translates to:
  /// **'لديك أحدث إصدار.'**
  String get updateUpToDate;

  /// No description provided for @updateDownloading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تنزيل الإصدار {version} {percent}'**
  String updateDownloading(String version, String percent);

  /// No description provided for @updateReady.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {version} جاهز للتثبيت.'**
  String updateReady(String version);

  /// No description provided for @updateRestart.
  ///
  /// In ar, this message translates to:
  /// **'أعد التشغيل للتحديث'**
  String get updateRestart;

  /// No description provided for @updateFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر البحث عن تحديث. حاول لاحقًا.'**
  String get updateFailed;

  /// No description provided for @storePrivacyTitle.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get storePrivacyTitle;

  /// No description provided for @storePrivacyBody.
  ///
  /// In ar, this message translates to:
  /// **'لا يحتاج تبيان إلى حساب، ولا يجمع أي بيانات شخصية، وتبقى بياناتك على جهازك. يُرجى قراءة سياسة الخصوصية قبل المتابعة.'**
  String get storePrivacyBody;

  /// No description provided for @storePrivacyRead.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ سياسة الخصوصية'**
  String get storePrivacyRead;

  /// No description provided for @storePrivacyAccept.
  ///
  /// In ar, this message translates to:
  /// **'موافق'**
  String get storePrivacyAccept;

  /// No description provided for @storePrivacyExit.
  ///
  /// In ar, this message translates to:
  /// **'خروج'**
  String get storePrivacyExit;

  /// No description provided for @cellularDownloadsToggle.
  ///
  /// In ar, this message translates to:
  /// **'التحميل عبر بيانات الجوال'**
  String get cellularDownloadsToggle;

  /// No description provided for @cellularDownloadsHint.
  ///
  /// In ar, this message translates to:
  /// **'عند الإيقاف تنتظر التحميلات شبكة Wi‑Fi، ويسألك التطبيق قبل استخدام بيانات الجوال'**
  String get cellularDownloadsHint;

  /// No description provided for @cellularPausedTitle.
  ///
  /// In ar, this message translates to:
  /// **'التحميلات متوقفة: أنت على بيانات الجوال'**
  String get cellularPausedTitle;

  /// No description provided for @cellularPausedBody.
  ///
  /// In ar, this message translates to:
  /// **'تبقّى نحو {size} ميجا، وتكمل تلقائيًا عند الاتصال بشبكة Wi‑Fi.'**
  String cellularPausedBody(String size);

  /// No description provided for @cellularPausedBodyNoSize.
  ///
  /// In ar, this message translates to:
  /// **'تكمل تلقائيًا عند الاتصال بشبكة Wi‑Fi.'**
  String get cellularPausedBodyNoSize;

  /// No description provided for @cellularContinue.
  ///
  /// In ar, this message translates to:
  /// **'متابعة عبر البيانات'**
  String get cellularContinue;

  /// No description provided for @cellularWait.
  ///
  /// In ar, this message translates to:
  /// **'انتظار Wi‑Fi'**
  String get cellularWait;
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
