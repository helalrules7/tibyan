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
}
