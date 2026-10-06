import '../../core/db/content_database.dart';
import '../../l10n/app_localizations.dart';
import '../mushaf/data/mushaf_repository.dart';
import '../mushaf/data/riwaya_data.dart';
import '../mushaf/data/tajweed.dart';
import '../mushaf/presentation/widgets/illuminated_frame.dart'
    show NumberFormatter;
import 'share_document.dart';
import 'share_layout.dart';
import 'share_text_runs.dart';

/// A stretch of verses to share, in the numbers of the text it is drawn
/// from (a riwaya's own count for a riwaya edition).
typedef ShareRange = List<({int surah, int ayah})>;

/// The choices of the preview: tajweed colours and the divine name.
class ShareOptions {
  const ShareOptions({
    this.tajweed = false,
    this.divineNames = false,
    this.tajweedHues = const {},
  });

  final bool tajweed;
  final bool divineNames;

  /// The reader's tajweed colours (rule key to hue name).
  final Map<String, String> tajweedHues;

  ShareOptions copyWith({bool? tajweed, bool? divineNames}) => ShareOptions(
    tajweed: tajweed ?? this.tajweed,
    divineNames: divineNames ?? this.divineNames,
    tajweedHues: tajweedHues,
  );
}

/// The texts of the pictures are Arabic whatever the interface language.
final AppLocalizations _ar = lookupAppLocalizations(
  AppLocalizations.supportedLocales.firstWhere((l) => l.languageCode == 'ar'),
);
final _digits = NumberFormatter(
  AppLocalizations.supportedLocales.firstWhere((l) => l.languageCode == 'ar'),
);

/// «١ من ٤».
String sharePageLabel(int index, int count) =>
    _ar.shareImageOf(_digits(index + 1), _digits(count));

/// The passage's reference: «البقرة ٢٥٥», «البقرة ١–٥», or both ends when
/// it runs over two surahs.
String shareReference(ShareRange range, List<SurahRow> surahs) {
  final a = range.first, b = range.last;
  String name(int s) => surahs[s - 1].nameAr;
  if (a.surah != b.surah) {
    return '${name(a.surah)} ${_digits(a.ayah)} – '
        '${name(b.surah)} ${_digits(b.ayah)}';
  }
  return a.ayah == b.ayah
      ? '${name(a.surah)} ${_digits(a.ayah)}'
      : _ar.verseRange(name(a.surah), _digits(a.ayah), _digits(b.ayah));
}

Map<int, ShareSurahHeader> _headers(ShareRange range, List<SurahRow> surahs) =>
    {
      for (final k in range)
        k.surah: () {
          final s = surahs[k.surah - 1];
          return ShareSurahHeader(
            title: _ar.surahWord(s.nameAr),
            info:
                '${s.revelation == 'meccan' ? _ar.meccan : _ar.medinan}'
                ' · ${_ar.revealedOrder(_digits(s.revelationOrder))}',
          );
        }(),
    };

/// A Hafs passage (the 1441, 1405 and Shamarly editions): the KFGQPC Hafs
/// text of content.db, verbatim, in the KFGQPC Hafs font.
Future<SharePassage> hafsPassage({
  required MushafRepository repo,
  required ShareRange range,
  required List<SurahRow> surahs,
  ShareOptions options = const ShareOptions(),
}) async {
  final verses = <ShareVerse>[];
  final tajweed = <(int, int), List<ShareTajweedLetter>>{};
  // Verses of each surah in the range, read surah by surah.
  final bySurah = <int, List<int>>{};
  for (final k in range) {
    (bySurah[k.surah] ??= []).add(k.ayah);
  }
  final rows = <(int, int), AyahRow>{};
  for (final MapEntry(key: s, value: ayahs) in bySurah.entries) {
    for (final r in await repo.ayahsOfSurah(s)) {
      if (ayahs.contains(r.number)) rows[(s, r.number)] = r;
    }
    if (options.tajweed) {
      final from = ayahs.reduce((a, b) => a < b ? a : b);
      final to = ayahs.reduce((a, b) => a > b ? a : b);
      for (final (ayah, word, letter, marks, rule) in await repo.tajweedLetters(
        s,
        from,
        to,
      )) {
        final r = TajweedRule.byKey(rule);
        final hue = r == null ? null : tajweedHueOf(r, options.tajweedHues);
        if (hue == null) continue;
        (tajweed[(s, ayah)] ??= []).add(
          ShareTajweedLetter(
            word: word,
            letter: letter,
            marksOnly: marks,
            color: hue.on(darkPaper: false),
          ),
        );
      }
    }
  }
  for (final k in range) {
    final r = rows[(k.surah, k.ayah)];
    if (r == null) continue;
    verses.add(ShareVerse(surah: k.surah, ayah: k.ayah, text: r.displayText));
  }
  final basmala = (await repo.ayah(1, 1)).displayBody;
  return SharePassage(
    verses: verses,
    headers: _headers(range, surahs),
    fontFamily: 'UthmanicHafs',
    basmala: basmala,
    reference: shareReference(range, surahs),
    pageLabel: sharePageLabel,
    tajweed: tajweed,
    divineNames: options.divineNames,
  );
}

/// A riwaya passage: the riwaya's own KFGQPC text from its pack, verbatim,
/// in the riwaya's KFGQPC font ([fontFamily], loaded from the pack). The
/// riwaya's text has no basmala line of its own, so none is drawn, and no
/// tajweed data exists for it.
SharePassage riwayaPassage({
  required RiwayaData data,
  required String fontFamily,
  required ShareRange range,
  required List<SurahRow> surahs,
  ShareOptions options = const ShareOptions(),
}) => SharePassage(
  verses: [
    for (final k in range)
      if (data.verse(k.surah, k.ayah) case final v?)
        ShareVerse(surah: v.surah, ayah: v.ayah, text: v.text),
  ],
  headers: _headers(range, surahs),
  fontFamily: fontFamily,
  basmala: null,
  reference: shareReference(range, surahs),
  pageLabel: sharePageLabel,
  divineNames: options.divineNames,
);
