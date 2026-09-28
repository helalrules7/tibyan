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
  /// **'الشكل'**
  String get appearanceTitle;

  /// No description provided for @styleLabel.
  ///
  /// In ar, this message translates to:
  /// **'الشكل'**
  String get styleLabel;

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

  /// No description provided for @previewLabel.
  ///
  /// In ar, this message translates to:
  /// **'معاينة'**
  String get previewLabel;

  /// No description provided for @selected.
  ///
  /// In ar, this message translates to:
  /// **'محدد'**
  String get selected;
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
