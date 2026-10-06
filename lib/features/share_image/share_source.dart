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
import 'surah_statements.dart';

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

/// The header of surah [surah]: «سورة الأنعام», and under it the statement
/// of its type as the 1924 Cairo mushaf prints it (with the verses excepted
/// from it, [statements]), its place in the order of revelation and the
/// surah revealed before it, from the Tanzil metadata of content.db, as the
/// page banners show them: «مكية إلا الآيات ٢٠ و٢٣ … فمدنية · ترتيبها في
/// النزول ٥٥ · نزلت بعد الحجر». The first surah revealed (al-'Alaq) has no
/// «نزلت بعد».
///
/// [plainType]: the plain «مكية» or «مدنية» of Tanzil instead of the
/// statement, for a text whose verses are numbered otherwise than the
/// statement's (a riwaya with its own count of that surah).
ShareSurahHeader shareSurahHeader(
  int surah,
  List<SurahRow> surahs, {
  required SurahStatements statements,
  bool plainType = false,
}) {
  final s = surahs[surah - 1];
  final before = surahs
      .where((x) => x.revelationOrder == s.revelationOrder - 1)
      .firstOrNull;
  final statement = statements[surah];
  return ShareSurahHeader(
    title: _ar.surahWord(s.nameAr),
    info: [
      if (statement != null && !(plainType && statement.numbered))
        statement.statement
      else
        s.revelation == 'meccan' ? _ar.meccan : _ar.medinan,
      _ar.revealedOrder(_digits(s.revelationOrder)),
      if (before != null) _ar.revealedAfter(before.nameAr),
    ].join(' · '),
  );
}

Map<int, ShareSurahHeader> _headers(
  ShareRange range,
  List<SurahRow> surahs,
  SurahStatements statements, {
  bool Function(int surah)? plainType,
}) => {
  for (final k in range)
    k.surah: shareSurahHeader(
      k.surah,
      surahs,
      statements: statements,
      plainType: plainType?.call(k.surah) ?? false,
    ),
};

/// Whether [data] numbers the verses of [surah] as Hafs does: as many
/// verses, each the same Hafs verse. The statements of the 1342 print name
/// verses by their Kufan (Hafs) numbers.
bool riwayaNumbersAsHafs(RiwayaData data, int surah, int hafsCount) {
  if (data.surahCounts[surah - 1] != hafsCount) return false;
  for (var a = 1; a <= hafsCount; a++) {
    final v = data.verse(surah, a);
    if (v == null || v.hafsFrom != a || v.hafsTo != a) return false;
  }
  return true;
}

/// A Hafs passage (the 1441, 1405 and Shamarly editions): the KFGQPC Hafs
/// text of content.db, verbatim, in the KFGQPC Hafs font.
Future<SharePassage> hafsPassage({
  required MushafRepository repo,
  required ShareRange range,
  required List<SurahRow> surahs,
  required SurahStatements statements,
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
  final mushaf = await hafsMushafPlaces(repo, range);
  return SharePassage(
    verses: verses,
    headers: _headers(range, surahs, statements),
    fontFamily: 'UthmanicHafs',
    basmala: basmala,
    reference: shareReference(range, surahs),
    pageLabel: sharePageLabel,
    tajweed: tajweed,
    divineNames: options.divineNames,
    mushaf: mushaf,
  );
}

/// The line grid's pitch of the 1441 pages (page units), as the page view
/// has it (mushaf_page.dart).
const _pitch1441 = 35.75;

/// The page and line of each word of [range] in the new Madina mushaf
/// (1441H): from its word boxes and the cuts between its lines, the ones
/// the page view draws the pages with. The verse on each side of each
/// surah's part of the range is read too, for the words at its edges.
Future<Map<(int, int, int), MushafPlace>> hafsMushafPlaces(
  MushafRepository repo,
  ShareRange range,
) async {
  final bySurah = <int, (int, int)>{};
  for (final k in range) {
    final (a, b) = bySurah[k.surah] ?? (k.ayah, k.ayah);
    bySurah[k.surah] = (k.ayah < a ? k.ayah : a, k.ayah > b ? k.ayah : b);
  }
  final boxes = <MushafWordBox>[];
  for (final MapEntry(key: s, value: (a, b)) in bySurah.entries) {
    for (final r in await repo.wordBoxesOfVerses(s, a - 1, b + 1)) {
      boxes.add((
        surah: r.surah,
        ayah: r.ayah,
        word: r.word,
        page: r.page,
        left: r.x0 / 10,
        top: r.y0 / 10,
        right: r.x1 / 10,
        bottom: r.y1 / 10,
      ));
    }
  }
  if (boxes.isEmpty) return const {};
  final pages = boxes.map((b) => b.page);
  final cuts = await repo.lineCutsOfPages(
    'madina1441',
    pages.reduce((a, b) => a < b ? a : b),
    pages.reduce((a, b) => a > b ? a : b),
  );
  return mushafPlaces(
    boxes,
    cuts: (page) => cuts[page] ?? const [],
    pitch: _pitch1441,
  );
}

/// The page and line of each word of [range] in a riwaya's own mushaf,
/// from the word boxes and line cuts of its page pack; null when the pack
/// has no word boxes (packs v1).
Map<(int, int, int), MushafPlace>? riwayaMushafPlaces(
  RiwayaData data,
  ShareRange range,
) {
  if (!data.hasWordBoxes || range.isEmpty) return null;
  final first = data.verse(range.first.surah, range.first.ayah);
  final last = data.verse(range.last.surah, range.last.ayah);
  if (first == null || last == null) return null;
  final keys = {for (final k in range) (k.surah, k.ayah)};
  final boxes = <MushafWordBox>[];
  // A verse may run over onto the page after the one it starts on.
  for (var page = first.page; page <= last.page + 1; page++) {
    for (final MapEntry(key: (s, a, w), value: r)
        in data.wordBoxes(page).entries) {
      if (!keys.contains((s, a))) continue;
      boxes.add((
        surah: s,
        ayah: a,
        word: w,
        page: page,
        left: r.left,
        top: r.top,
        right: r.right,
        bottom: r.bottom,
      ));
    }
  }
  return mushafPlaces(
    boxes,
    cuts: (page) => data.lines(page).cuts,
    pitch: data.pitch,
  );
}

/// A riwaya passage: the riwaya's own KFGQPC text from its pack, verbatim,
/// in the riwaya's KFGQPC font ([fontFamily], loaded from the pack). The
/// riwaya's text has no basmala line of its own, so none is drawn, and no
/// tajweed data exists for it. A surah's header has the 1342 statement of
/// its type when the riwaya numbers its verses as Hafs does, and the plain
/// type otherwise ([riwayaNumbersAsHafs]).
SharePassage riwayaPassage({
  required RiwayaData data,
  required String fontFamily,
  required ShareRange range,
  required List<SurahRow> surahs,
  required SurahStatements statements,
  ShareOptions options = const ShareOptions(),
}) => SharePassage(
  verses: [
    for (final k in range)
      if (data.verse(k.surah, k.ayah) case final v?)
        ShareVerse(surah: v.surah, ayah: v.ayah, text: v.text),
  ],
  headers: _headers(
    range,
    surahs,
    statements,
    plainType: (s) => !riwayaNumbersAsHafs(data, s, surahs[s - 1].ayahCount),
  ),
  fontFamily: fontFamily,
  basmala: null,
  reference: shareReference(range, surahs),
  pageLabel: sharePageLabel,
  divineNames: options.divineNames,
  mushaf: riwayaMushafPlaces(data, range),
);
