import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' show Rect;

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../../../core/db/content_database.dart';

/// A verse identified by surah and number, in some riwaya's count.
typedef RiwayaKey = ({int surah, int ayah});

/// One verse of a riwaya edition, as printed.
class RiwayaVerse {
  const RiwayaVerse({
    required this.surah,
    required this.ayah,
    required this.page,
    required this.juz,
    required this.hafsFrom,
    required this.hafsTo,
    required this.text,
  });

  final int surah;
  final int ayah;

  /// Page where the verse starts.
  final int page;
  final int juz;

  /// The Hafs verses of the same surah this verse covers, [hafsFrom] to
  /// [hafsTo]; both 0 when it covers none.
  final int hafsFrom;
  final int hafsTo;

  /// The KFGQPC text of the riwaya, verbatim, for the riwaya's own font.
  final String text;

  RiwayaKey get key => (surah: surah, ayah: ayah);

  /// The Hafs verses this verse covers, in order.
  List<RiwayaKey> get hafs => [
    if (hafsFrom > 0)
      for (var a = hafsFrom; a <= hafsTo; a++) (surah: surah, ayah: a),
  ];
}

/// Line cuts and the marks that cross them, for one page.
class RiwayaPageLines {
  const RiwayaPageLines(this.cuts, this.overflow);

  final List<double> cuts;

  /// (line, outline) of each mark that crosses a cut.
  final List<(int, String)> overflow;
}

/// A riwaya edition's verses, verse map and page geometry, read from its
/// page pack (`riwaya.json.xz`, built by tools/build_riwaya_packs.py).
///
/// Its verses are numbered by the riwaya's own count. [toHafs] and
/// [fromHafs] go between that count and Hafs's, from the map in the pack
/// (worked out from the KFGQPC texts of both riwayat, and checked against
/// Quranpedia's published map).
class RiwayaData {
  RiwayaData({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.pageCount,
    required this.firstLine,
    required this.pitch,
    required this.openingInk,
    required this.openingBody,
    required this.fontFile,
    required this.surahCounts,
    required this.surahStartPages,
    required this.verses,
    required this.polygonsByPage,
    required this.linesByPage,
    this.wordBoxesByPage = const {},
  }) {
    for (var i = 0; i < verses.length; i++) {
      final v = verses[i];
      _index[v.key] = i;
      (_byPage[v.page] ??= []).add(i);
      for (var h = v.hafsFrom; h > 0 && h <= v.hafsTo; h++) {
        final k = (surah: v.surah, ayah: h);
        _fromHafs.putIfAbsent(k, () => v.key);
        _hafsCovers[k] = (_hafsCovers[k] ?? 0) + 1;
      }
    }
  }

  final String id;
  final String nameAr;
  final String nameEn;
  final int pageCount;

  /// Line grid of the pages (page units): first line centre and pitch.
  final double firstLine;
  final double pitch;

  /// Pages 1 and 2: the ink of their text block, and the block without its
  /// printed surah header.
  final List<Rect> openingInk;
  final List<Rect> openingBody;

  /// The riwaya's KFGQPC font, a file in the pack.
  final String fontFile;

  /// Verses per surah, and the page of each surah's first verse (1..114).
  final List<int> surahCounts;
  final List<int> surahStartPages;
  final List<RiwayaVerse> verses;

  /// Verse outlines and line cuts, by page.
  final Map<int, List<AyahPolygonRow>> polygonsByPage;
  final Map<int, RiwayaPageLines> linesByPage;

  /// The box of each word, by page, keyed by (surah, verse, word) in the
  /// riwaya's count, in page units (`words.json.xz`, from
  /// tools/build_riwaya_word_boxes.py). Empty for a pack built before the
  /// word boxes (v1).
  final Map<int, Map<(int, int, int), Rect>> wordBoxesByPage;
  final _index = <RiwayaKey, int>{};
  final _byPage = <int, List<int>>{};
  final _fromHafs = <RiwayaKey, RiwayaKey>{};
  final _hafsCovers = <RiwayaKey, int>{};

  /// Whether the pack carries word boxes.
  bool get hasWordBoxes => wordBoxesByPage.isNotEmpty;

  /// The word boxes on [page]; empty without them.
  Map<(int, int, int), Rect> wordBoxes(int page) =>
      wordBoxesByPage[page] ?? const {};

  /// The words of a verse, numbered from 1 as in [wordBoxes]: its text
  /// split at its spaces, without the verse number and without ۞.
  List<String> words(int surah, int ayah) {
    final v = verse(surah, ayah);
    return v == null ? const [] : riwayaWords(v.text);
  }

  /// The Hafs word (surah, verse, word) that word [word] of a riwaya verse
  /// is, only when that is certain: the verse is the whole of one Hafs
  /// verse and no other riwaya verse shares it, both have the same number
  /// of words, and the two words have the same letters ([hafsWords] are
  /// the Hafs verse's words, numbered as the word study numbers them).
  /// Otherwise null, and no Hafs word data is shown for it.
  (int, int, int)? hafsWord(
    int surah,
    int ayah,
    int word,
    List<String> hafsWords,
  ) {
    final v = verse(surah, ayah);
    if (v == null || v.hafsFrom == 0 || v.hafsFrom != v.hafsTo) return null;
    if (_hafsCovers[(surah: surah, ayah: v.hafsFrom)] != 1) return null;
    final own = riwayaWords(v.text);
    if (own.length != hafsWords.length || word < 1 || word > own.length) {
      return null;
    }
    if (wordLetters(own[word - 1]) != wordLetters(hafsWords[word - 1])) {
      return null;
    }
    return (surah, v.hafsFrom, word);
  }

  RiwayaVerse? verse(int surah, int ayah) {
    final i = _index[(surah: surah, ayah: ayah)];
    return i == null ? null : verses[i];
  }

  /// Verses that start on [page], in order.
  List<RiwayaVerse> versesOnPage(int page) => [
    for (final i in _byPage[page] ?? const <int>[]) verses[i],
  ];

  /// Verse outlines on [page] (verses running over from the page before
  /// included), in page units.
  List<AyahPolygonRow> polygons(int page) => polygonsByPage[page] ?? const [];

  RiwayaPageLines lines(int page) =>
      linesByPage[page] ?? const RiwayaPageLines([], []);

  int pageOf(int surah, int ayah) => verse(surah, ayah)?.page ?? 1;

  /// The Hafs verses a riwaya verse covers.
  List<RiwayaKey> toHafs(int surah, int ayah) =>
      verse(surah, ayah)?.hafs ?? const [];

  /// The riwaya verse that holds the start of a Hafs verse. A Hafs verse
  /// the riwaya does not count (the basmala of al-Fatiha) goes to the
  /// riwaya verse that follows it.
  RiwayaKey fromHafs(int surah, int ayah) {
    final hit = _fromHafs[(surah: surah, ayah: ayah)];
    if (hit != null) return hit;
    for (var a = ayah + 1; a <= ayah + 3; a++) {
      final next = _fromHafs[(surah: surah, ayah: a)];
      if (next != null) return next;
    }
    return (surah: surah, ayah: 1);
  }

  /// The first Hafs verse of a riwaya verse, for what is kept in Hafs
  /// numbers (bookmarks, the reading position, tafsir).
  RiwayaKey firstHafs(int surah, int ayah) {
    final hs = toHafs(surah, ayah);
    return hs.isEmpty ? (surah: surah, ayah: ayah) : hs.first;
  }

  /// A verse of the riwaya as a content row, so the page view can treat
  /// it like a Hafs verse. Only its numbers, page, juz and text are real;
  /// it is never written anywhere.
  AyahRow row(RiwayaVerse v) => AyahRow(
    id: (_index[v.key] ?? 0) + 1,
    surah: v.surah,
    number: v.ayah,
    verseText: v.text,
    displayText: v.text,
    basmalaPrefix: 0,
    textSearch: '',
    searchBasmalaPrefix: 0,
    juz: v.juz,
    // The riwaya's hizb quarters are not in the sources; 0 = unknown.
    hizbQuarter: 0,
    manzil: 0,
    page: v.page,
    page1405: 0,
    textSourceId: 0,
    displaySourceId: 0,
    pageSourceId: 0,
    pageShamarly: 0,
    pageShamarlyEnd: 0,
  );

  List<AyahRow> ayahsOnPage(int page) => [
    for (final v in versesOnPage(page)) row(v),
  ];

  /// First verse of each juz, by the riwaya's own juz numbers.
  List<RiwayaVerse> juzStarts() {
    final out = <RiwayaVerse>[];
    var last = 0;
    for (final v in verses) {
      if (v.juz != last) {
        out.add(v);
        last = v.juz;
      }
    }
    return out;
  }

  static final _spaces = RegExp('[  ]');
  static final _numberGlyphs = RegExp('[ﰀ-﷿]+\$');
  static final _arabicDigits = RegExp('^[٠-٩]+\$');
  static final _notLetter = RegExp('[^ء-غف-يٱے]');

  /// A verse's words: [text] (verbatim) split at its spaces and no-break
  /// spaces, without the verse number at its end (the number glyph of the
  /// KFGQPC font, joined to the last word in Warsh 16:123; Arabic-Indic
  /// numerals in Shu'bah 2:286) and without ۞. As
  /// tools/build_riwaya_word_boxes.py splits it.
  static List<String> riwayaWords(String text) {
    final tokens = [
      for (final t in text.split(_spaces))
        if (t.isNotEmpty) t,
    ];
    if (tokens.isEmpty) return const [];
    final last = tokens.removeLast().replaceAll(_numberGlyphs, '');
    if (last.isNotEmpty && !_arabicDigits.hasMatch(last)) tokens.add(last);
    return [
      for (final t in tokens)
        if (t != '۞') t,
    ];
  }

  /// A word's letters only (no marks, signs or small letters), as
  /// written: two words are the same word only when these are equal. The
  /// alif wasla is an alif with a sign (ٱ = ا) and the yeh barree a form
  /// of yeh (ے = ي); every other letter must be the same (يؤمنون and
  /// يومنون differ).
  static String wordLetters(String word) =>
      word.replaceAll(_notLetter, '').replaceAll('ٱ', 'ا').replaceAll('ے', 'ي');

  static Rect _rect(List<dynamic> v) => Rect.fromLTRB(
    (v[0] as num).toDouble(),
    (v[1] as num).toDouble(),
    (v[2] as num).toDouble(),
    (v[3] as num).toDouble(),
  );

  /// Parses the pack's `riwaya.json`, and its `words.json` when the pack
  /// has one.
  static RiwayaData parse(String json, [String? wordsJson]) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    final grid = d['grid'] as List<dynamic>;
    final opening = d['opening'] as List<dynamic>;
    final surahs = d['surahs'] as List<dynamic>;
    final polygons = <int, List<AyahPolygonRow>>{};
    for (final raw in d['polygons'] as List<dynamic>) {
      final q = raw as List<dynamic>;
      final page = q[0] as int;
      (polygons[page] ??= []).add(
        AyahPolygonRow(
          page: page,
          surah: q[1] as int,
          number: q[2] as int,
          path: q[3] as String,
          markerX: (q[4] as num?)?.toDouble(),
          markerY: (q[5] as num?)?.toDouble(),
        ),
      );
    }
    final cuts = d['cuts'] as Map<String, dynamic>;
    final overflow = d['overflow'] as Map<String, dynamic>;
    final lines = <int, RiwayaPageLines>{
      for (final e in cuts.entries)
        int.parse(e.key): RiwayaPageLines(
          [for (final c in e.value as List<dynamic>) (c as num).toDouble()],
          [
            for (final o in (overflow[e.key] as List<dynamic>?) ?? const [])
              ((o as List<dynamic>)[0] as int, o[1] as String),
          ],
        ),
    };
    final data = RiwayaData(
      id: d['id'] as String,
      nameAr: d['name_ar'] as String,
      nameEn: d['name_en'] as String,
      pageCount: d['pages'] as int,
      firstLine: (grid[0] as num).toDouble(),
      pitch: (grid[1] as num).toDouble(),
      openingInk: [for (final o in opening) _rect((o as List)[0] as List)],
      openingBody: [for (final o in opening) _rect((o as List)[1] as List)],
      fontFile: d['font'] as String,
      surahCounts: [for (final s in surahs) (s as List)[0] as int],
      surahStartPages: [for (final s in surahs) (s as List)[1] as int],
      verses: [
        for (final raw in d['verses'] as List<dynamic>)
          RiwayaVerse(
            surah: (raw as List)[0] as int,
            ayah: raw[1] as int,
            page: raw[2] as int,
            juz: raw[3] as int,
            hafsFrom: raw[4] as int,
            hafsTo: raw[5] as int,
            text: raw[6] as String,
          ),
      ],
      polygonsByPage: polygons,
      linesByPage: lines,
    );
    if (wordsJson == null) return data;
    return RiwayaData(
      id: data.id,
      nameAr: data.nameAr,
      nameEn: data.nameEn,
      pageCount: data.pageCount,
      firstLine: data.firstLine,
      pitch: data.pitch,
      openingInk: data.openingInk,
      openingBody: data.openingBody,
      fontFile: data.fontFile,
      surahCounts: data.surahCounts,
      surahStartPages: data.surahStartPages,
      verses: data.verses,
      polygonsByPage: data.polygonsByPage,
      linesByPage: data.linesByPage,
      wordBoxesByPage: parseWordBoxes(wordsJson, data),
    );
  }

  /// The boxes of `words.json` (boxes in tenths of the page's units), by
  /// page. A verse is kept only when it has one box for each of its words
  /// in [data] ([words]); a format this version does not know gives none.
  static Map<int, Map<(int, int, int), Rect>> parseWordBoxes(
    String json,
    RiwayaData data,
  ) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    if (d['format'] != 1) return const {};
    final out = <int, Map<(int, int, int), Rect>>{};
    for (final raw in d['verses'] as List<dynamic>) {
      final v = raw as List<dynamic>;
      final surah = v[0] as int;
      final ayah = v[1] as int;
      final boxes = v[4] as List<dynamic>;
      final count = data.words(surah, ayah).length;
      if (count == 0 || v[3] != count || boxes.length != count) continue;
      for (var i = 0; i < boxes.length; i++) {
        final b = boxes[i] as List<dynamic>;
        (out[b[0] as int] ??= {})[(surah, ayah, i + 1)] = Rect.fromLTRB(
          (b[1] as num) / 10,
          (b[2] as num) / 10,
          (b[3] as num) / 10,
          (b[4] as num) / 10,
        );
      }
    }
    return out;
  }

  /// Reads and parses `riwaya.json.xz`, and `words.json.xz` when the pack
  /// has it (packs v2), from an installed pack, off the UI thread.
  static Future<RiwayaData> load(Directory packDir) {
    final path = p.join(packDir.path, 'riwaya.json.xz');
    final wordsPath = p.join(packDir.path, 'words.json.xz');
    return Isolate.run(() {
      String read(String path) =>
          utf8.decode(XZDecoder().decodeBytes(File(path).readAsBytesSync()));
      final words = File(wordsPath).existsSync() ? read(wordsPath) : null;
      return parse(read(path), words);
    });
  }
}
