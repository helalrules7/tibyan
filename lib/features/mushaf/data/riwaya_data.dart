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
  }) {
    for (var i = 0; i < verses.length; i++) {
      final v = verses[i];
      _index[v.key] = i;
      (_byPage[v.page] ??= []).add(i);
      for (var h = v.hafsFrom; h > 0 && h <= v.hafsTo; h++) {
        _fromHafs.putIfAbsent((surah: v.surah, ayah: h), () => v.key);
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
  final _index = <RiwayaKey, int>{};
  final _byPage = <int, List<int>>{};
  final _fromHafs = <RiwayaKey, RiwayaKey>{};

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

  static Rect _rect(List<dynamic> v) => Rect.fromLTRB(
    (v[0] as num).toDouble(),
    (v[1] as num).toDouble(),
    (v[2] as num).toDouble(),
    (v[3] as num).toDouble(),
  );

  /// Parses the pack's `riwaya.json`.
  static RiwayaData parse(String json) {
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
    return RiwayaData(
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
  }

  /// Reads and parses `riwaya.json.xz` from an installed pack, off the UI
  /// thread.
  static Future<RiwayaData> load(Directory packDir) {
    final path = p.join(packDir.path, 'riwaya.json.xz');
    return Isolate.run(
      () => parse(
        utf8.decode(XZDecoder().decodeBytes(File(path).readAsBytesSync())),
      ),
    );
  }
}
