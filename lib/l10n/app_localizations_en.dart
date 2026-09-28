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
}
