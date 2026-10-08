import '../mushaf/presentation/source_names.dart';

/// The credit keys of the streamed audio and the optional English tafsir
/// pack. Their wording lives in one place, [sourceText] (source_names.dart),
/// with every other source of the app; the indexes and the pack name their
/// key (`source`), so what plays or shows always carries its own line.
abstract final class ContentSources {
  /// Nuqayah's tafsir recordings (MISSING_DATA ن6، إ9): their condition is
  /// no ads and no profit, which the line says.
  static const nuqayahTafsirAudio = 'nuqayah-tafsir-audio';

  /// QuranEnc's english_rwwad verse audio (ن13، إ12).
  static const quranEncRwwadAudio = 'quranenc-english-rwwad-audio';

  /// QuranEnc's english_mokhtasar text (ن12، إ12).
  static const quranEncMokhtasar = 'quranenc-english-mokhtasar';
}

/// The credit line of [key] in [languageCode] (Arabic for `ar`, else
/// English), with the [version] when the source has one and the line does
/// not already name it. A key with no wording gives the key itself, so a
/// line is never missing.
String contentCredit(String key, String languageCode, {String? version}) {
  final line = sourceText(key, languageCode)?.credit ?? key;
  if (version == null || line.contains(version)) return line;
  return languageCode == 'ar'
      ? '$line · الإصدار $version'
      : '$line · version $version';
}
