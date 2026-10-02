import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'content_database.g.dart';

/// Tables of the bundled, read-only `assets/db/content.db`, built by
/// `tools/build_content_db.py`. The app never writes to it.
@DataClassName('SurahRow')
class Surah extends Table {
  @override
  String get tableName => 'surah';

  IntColumn get id => integer()();
  TextColumn get nameAr => text()();
  TextColumn get nameEn => text()();
  TextColumn get meaningEn => text()();
  TextColumn get revelation => text()();
  IntColumn get revelationOrder => integer()();
  IntColumn get ayahCount => integer()();

  /// First page in the new edition (1441H).
  IntColumn get startPage => integer()();

  /// First page in the old edition (1405H).
  IntColumn get startPage1405 => integer().named('start_page_1405')();
  IntColumn get sourceId => integer()();

  /// Page of verse 1 in the Shamarly (Egyptian) edition.
  IntColumn get startPageShamarly => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AyahRow')
class Ayah extends Table {
  @override
  String get tableName => 'ayah';

  IntColumn get id => integer()();
  IntColumn get surah => integer()();
  IntColumn get number => integer()();

  /// Tanzil Uthmani text, verbatim (may start with the basmala). Kept for
  /// reference and comparison; not shown.
  TextColumn get verseText => text().named('text')();

  /// KFGQPC Hafs 2.0 text, verbatim, for the KFGQPC Hafs font. Shown in the
  /// continuous view. Ends with a space and the verse-number glyph.
  TextColumn get displayText => text()();

  /// Characters of the basmala before verse 1 in the Tanzil file.
  IntColumn get basmalaPrefix => integer()();
  TextColumn get textSearch => text()();
  IntColumn get searchBasmalaPrefix => integer()();
  IntColumn get juz => integer()();
  IntColumn get hizbQuarter => integer()();
  IntColumn get manzil => integer()();

  /// Page in the new edition (1441H).
  IntColumn get page => integer()();

  /// Page in the old edition (1405H).
  IntColumn get page1405 => integer().named('page_1405')();
  TextColumn get sajda => text().nullable()();
  IntColumn get textSourceId => integer()();
  IntColumn get displaySourceId => integer()();
  IntColumn get pageSourceId => integer()();

  /// Page where the verse starts in the Shamarly (Egyptian) edition.
  IntColumn get pageShamarly => integer()();

  /// Page of the verse's marker in the Shamarly edition: a verse may run
  /// over a page break there.
  IntColumn get pageShamarlyEnd => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AyahPolygonRow')
class AyahPolygon extends Table {
  @override
  String get tableName => 'ayah_polygon';

  IntColumn get page => integer()();
  IntColumn get surah => integer()();
  IntColumn get number => integer()();
  TextColumn get path => text()();
  RealColumn get markerX => real().nullable()();
  RealColumn get markerY => real().nullable()();

  @override
  Set<Column> get primaryKey => {page, surah, number};
}

@DataClassName('SourceRow')
class Source extends Table {
  @override
  String get tableName => 'source';

  IntColumn get id => integer()();
  TextColumn get key => text()();
  TextColumn get title => text()();
  TextColumn get publisher => text()();
  TextColumn get version => text().nullable()();
  TextColumn get license => text()();
  TextColumn get url => text()();
  TextColumn get attribution => text()();
  TextColumn get notice => text().nullable()();
  TextColumn get sha256 => text()();
  TextColumn get retrievedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A word's box on a page of the new edition, in tenths of the page's
/// viewBox units. Derived from the page geometry by
/// tools/build_word_boxes.py.
@DataClassName('WordBoxRow')
class WordBox extends Table {
  @override
  String get tableName => 'word_box';

  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();

  /// 1-based among the words of the KFGQPC text.
  IntColumn get word => integer()();
  IntColumn get page => integer()();
  IntColumn get x0 => integer()();
  IntColumn get y0 => integer()();
  IntColumn get x1 => integer()();
  IntColumn get y1 => integer()();

  /// 1 when every word of the verse matched its predicted letter groups.
  IntColumn get exact => integer()();

  @override
  Set<Column> get primaryKey => {surah, ayah, word};

  @override
  bool get withoutRowId => true;
}

/// Where to split a page into its 15 lines (see tools/build_line_cuts.py).
@DataClassName('LineCutRow')
class LineCut extends Table {
  @override
  String get tableName => 'line_cut';

  TextColumn get edition => text()();
  IntColumn get page => integer()();

  /// 0..13: the gap below line [gap].
  IntColumn get gap => integer()();

  /// Page units (1441) or image pixels (1405).
  RealColumn get y => real()();

  @override
  Set<Column> get primaryKey => {edition, page, gap};

  @override
  bool get withoutRowId => true;
}

/// New-edition marks that cross a cut, with the line they belong to.
@DataClassName('LineOverflowRow')
class LineOverflow extends Table {
  @override
  String get tableName => 'line_overflow';

  IntColumn get page => integer()();
  IntColumn get line => integer()();
  TextColumn get path => text()();

  @override
  Set<Column> get primaryKey => {page, line, path};
}

/// Old-edition ink that crosses a cut (image px), with the line it belongs to.
@DataClassName('OldOverflowRow')
class LineOverflow1405 extends Table {
  @override
  String get tableName => 'line_overflow_1405';

  IntColumn get page => integer()();
  IntColumn get line => integer()();
  IntColumn get x0 => integer()();
  IntColumn get y0 => integer()();
  IntColumn get x1 => integer()();
  IntColumn get y1 => integer()();

  @override
  Set<Column> get primaryKey => {page, line, x0, y0};
}

/// A Shamarly page image (886 x 1377 px): `cover`, `ornate` or `text`.
/// Baseline of line j = [gridTop] + j * [pitch].
@DataClassName('ShamarlyPageRow')
class ShamarlyPage extends Table {
  @override
  String get tableName => 'shamarly_page';

  IntColumn get page => integer()();
  TextColumn get kind => text()();
  IntColumn get lines => integer()();
  RealColumn get gridTop => real().nullable()();
  RealColumn get pitch => real().nullable()();

  @override
  Set<Column> get primaryKey => {page};
}

/// A line slot of a Shamarly page: `text`, `header` (a surah header takes
/// two slots) or `basmala`; its band y0..y1 in image px.
@DataClassName('ShamarlyLineRow')
class ShamarlyLine extends Table {
  @override
  String get tableName => 'shamarly_line';

  IntColumn get page => integer()();
  IntColumn get line => integer()();
  TextColumn get kind => text()();
  IntColumn get surah => integer().nullable()();
  IntColumn get y0 => integer()();
  IntColumn get y1 => integer()();

  @override
  Set<Column> get primaryKey => {page, line};

  @override
  bool get withoutRowId => true;
}

/// Shamarly ink crossing a band edge (image px), with the line it belongs to.
@DataClassName('ShamarlyOverflowRow')
class ShamarlyLineOverflow extends Table {
  @override
  String get tableName => 'shamarly_line_overflow';

  IntColumn get page => integer()();
  IntColumn get line => integer()();
  IntColumn get x0 => integer()();
  IntColumn get y0 => integer()();
  IntColumn get x1 => integer()();
  IntColumn get y1 => integer()();

  @override
  Set<Column> get primaryKey => {page, line, x0, y0};
}

/// A printed surah-header frame; [firstLine] is null on the ornate pages.
@DataClassName('ShamarlyHeaderRow')
class ShamarlyHeader extends Table {
  @override
  String get tableName => 'shamarly_header';

  IntColumn get surah => integer()();
  IntColumn get page => integer()();
  IntColumn get firstLine => integer().nullable()();
  IntColumn get x0 => integer()();
  IntColumn get y0 => integer()();
  IntColumn get x1 => integer()();
  IntColumn get y1 => integer()();

  @override
  Set<Column> get primaryKey => {surah};
}

/// A Shamarly box in image px: a verse-end marker ring ([ShamarlyMarker]),
/// one verse on one line ([ShamarlyVerseBox]) or one word ([ShamarlyWordBox]).
@DataClassName('ShamarlyMarkerRow')
class ShamarlyMarker extends Table {
  @override
  String get tableName => 'shamarly_marker';

  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();
  IntColumn get page => integer()();
  IntColumn get line => integer()();
  IntColumn get x0 => integer()();
  IntColumn get y0 => integer()();
  IntColumn get x1 => integer()();
  IntColumn get y1 => integer()();

  @override
  Set<Column> get primaryKey => {surah, ayah};

  @override
  bool get withoutRowId => true;
}

@DataClassName('ShamarlyVerseBoxRow')
class ShamarlyVerseBox extends Table {
  @override
  String get tableName => 'shamarly_verse_box';

  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();

  /// 0.. in reading order.
  IntColumn get part => integer()();
  IntColumn get page => integer()();
  IntColumn get line => integer()();
  IntColumn get x0 => integer()();
  IntColumn get y0 => integer()();
  IntColumn get x1 => integer()();
  IntColumn get y1 => integer()();

  @override
  Set<Column> get primaryKey => {surah, ayah, part};

  @override
  bool get withoutRowId => true;
}

@DataClassName('ShamarlyWordBoxRow')
class ShamarlyWordBox extends Table {
  @override
  String get tableName => 'shamarly_word_box';

  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();

  /// Numbered as in [WordBox].
  IntColumn get word => integer()();
  IntColumn get page => integer()();
  IntColumn get line => integer()();
  IntColumn get x0 => integer()();
  IntColumn get y0 => integer()();
  IntColumn get x1 => integer()();
  IntColumn get y1 => integer()();

  /// How sure the split into words is: 2 stable, 1 not yet reviewed.
  IntColumn get level => integer()();

  @override
  Set<Column> get primaryKey => {surah, ayah, word};

  @override
  bool get withoutRowId => true;
}

/// The catchword of a Shamarly page, cut from the next page's image
/// (tools/build_shamarly_catchword.py): the box of the next page's first
/// word(s) in image px, and [erase], the rectangles of other ink inside
/// it ("x0,y0,x1,y1" separated by spaces), which are not drawn.
@DataClassName('ShamarlyCatchwordRow')
class ShamarlyCatchword extends Table {
  @override
  String get tableName => 'shamarly_catchword';

  IntColumn get page => integer()();
  IntColumn get x0 => integer()();
  IntColumn get y0 => integer()();
  IntColumn get x1 => integer()();
  IntColumn get y1 => integer()();

  /// Whole words in the box: 1 or 2.
  IntColumn get words => integer()();
  TextColumn get erase => text()();

  @override
  Set<Column> get primaryKey => {page};
}

/// A tafsir or translation shipped in the content database.
@DataClassName('CommentaryEditionRow')
class CommentaryEdition extends Table {
  @override
  String get tableName => 'commentary_edition';

  IntColumn get sourceId => integer()();

  /// `tafsir` or `translation`.
  TextColumn get kind => text()();
  TextColumn get language => text()();

  /// `rtl` or `ltr`.
  TextColumn get direction => text()();
  TextColumn get nameAr => text()();
  TextColumn get nameEn => text()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {sourceId};
}

/// One verse's entry in a tafsir or translation, verbatim from the source.
@DataClassName('CommentaryRow')
class Commentary extends Table {
  @override
  String get tableName => 'commentary';

  IntColumn get sourceId => integer()();
  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();
  TextColumn get body => text().named('text')();
  TextColumn get footnotes => text().nullable()();

  @override
  Set<Column> get primaryKey => {sourceId, surah, ayah};

  @override
  bool get withoutRowId => true;
}

/// A recitation, streamed or downloaded one surah file at a time.
@DataClassName('ReciterRow')
class Reciter extends Table {
  @override
  String get tableName => 'reciter';

  IntColumn get id => integer()();
  TextColumn get nameAr => text()();
  TextColumn get nameEn => text()();

  /// `murattal`, and only that: the mujawwad readings are not offered.
  TextColumn get style => text()();

  /// A surah's file is this URL followed by `NNN.mp3`.
  TextColumn get folderUrl => text()();
  IntColumn get sourceId => integer()();

  /// The riwaya recited (`Riwaya.name`: hafs, warsh, qalun, douri,
  /// shubah). Its verse timings are numbered by that riwaya's own count.
  TextColumn get riwaya => text().withDefault(const Constant('hafs'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Where a verse starts and ends in its surah file, in milliseconds.
/// Verse 0 is the opening before verse 1, when the source times it.
@DataClassName('AyahTimingRow')
class AyahTiming extends Table {
  @override
  String get tableName => 'ayah_timing';

  IntColumn get reciter => integer()();
  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();
  IntColumn get startMs => integer()();
  IntColumn get endMs => integer()();

  @override
  Set<Column> get primaryKey => {reciter, surah, ayah};

  @override
  bool get withoutRowId => true;
}

/// Where a word starts and ends in its surah file, in milliseconds.
/// Words are numbered as in [WordBox].
@DataClassName('WordTimingRow')
class WordTiming extends Table {
  @override
  String get tableName => 'word_timing';

  IntColumn get reciter => integer()();
  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();
  IntColumn get word => integer()();
  IntColumn get startMs => integer()();
  IntColumn get endMs => integer()();

  @override
  Set<Column> get primaryKey => {reciter, surah, ayah, word};

  @override
  bool get withoutRowId => true;
}

/// Where a verse's recited speech starts and ends in its surah file, in
/// milliseconds (tools/build_ayah_speech.py), for shortening the silences
/// between verses.
@DataClassName('AyahSpeechRow')
class AyahSpeech extends Table {
  @override
  String get tableName => 'ayah_speech';

  IntColumn get reciter => integer()();
  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();
  IntColumn get startMs => integer()();
  IntColumn get endMs => integer()();

  @override
  Set<Column> get primaryKey => {reciter, surah, ayah};

  @override
  bool get withoutRowId => true;
}

/// A word's root, lemma and part of speech from the Quranic Arabic Corpus
/// 0.4 (tools/build_word_study.py). Words are numbered as in [WordBox];
/// verses whose word count differs from the corpus have no rows.
@DataClassName('WordRootRow')
class WordRoot extends Table {
  @override
  String get tableName => 'word_root';

  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();
  IntColumn get word => integer()();

  /// Arabic letters separated by spaces, as the corpus shows them
  /// («ر ح م»); null for words without a root.
  TextColumn get root => text().nullable()();
  TextColumn get lemma => text().nullable()();

  /// The corpus's part-of-speech tag (N, V, PN, ADJ, ...).
  TextColumn get pos => text()();

  @override
  Set<Column> get primaryKey => {surah, ayah, word};

  @override
  bool get withoutRowId => true;
}

/// An entry of «الميسر في غريب القرآن», verbatim: the words the book
/// quotes and its explanation. [wordFrom]..[wordTo] are the words it
/// explains when that is certain; null when the entry belongs to the verse
/// only (its words occur more than once, or were not found).
@DataClassName('GharibRow')
class Gharib extends Table {
  @override
  String get tableName => 'gharib';

  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();

  /// Order of the entry within its verse, as in the book.
  IntColumn get ord => integer()();
  IntColumn get wordFrom => integer().nullable()();
  IntColumn get wordTo => integer().nullable()();
  TextColumn get phrase => text()();
  TextColumn get body => text().named('text')();

  @override
  Set<Column> get primaryKey => {surah, ayah, ord};

  @override
  bool get withoutRowId => true;
}

/// Similar verses (mutashabihat): a passage and one passage that resembles
/// it, as ranges of verse ids (`ayah.id`). Links only, from
/// tools/build_mutashabih.py; the verses' text comes from [Ayah].
@DataClassName('MutashabihRow')
class Mutashabih extends Table {
  @override
  String get tableName => 'mutashabih';

  IntColumn get id => integer()();
  IntColumn get srcFrom => integer()();
  IntColumn get srcTo => integer()();
  IntColumn get mutFrom => integer()();
  IntColumn get mutTo => integer()();

  /// 1 when the start of the following verse tells the passages apart.
  IntColumn get context => integer()();
  IntColumn get sourceId => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Surah,
    Ayah,
    AyahPolygon,
    Source,
    WordBox,
    LineCut,
    LineOverflow,
    LineOverflow1405,
    CommentaryEdition,
    Commentary,
    Reciter,
    AyahTiming,
    WordTiming,
    AyahSpeech,
    ShamarlyPage,
    ShamarlyLine,
    ShamarlyLineOverflow,
    ShamarlyHeader,
    ShamarlyMarker,
    ShamarlyVerseBox,
    ShamarlyWordBox,
    ShamarlyCatchword,
    WordRoot,
    Gharib,
    Mutashabih,
  ],
)
class ContentDatabase extends _$ContentDatabase {
  ContentDatabase(super.executor);

  /// Must match `SCHEMA_VERSION` in tools/build_content_db.py.
  @override
  int get schemaVersion => 16;

  /// The file is built ahead of time; never create or migrate it here.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {},
    onUpgrade: (m, from, to) async {},
  );

  /// Copies the bundled database to app storage when missing or when the
  /// app changed, then opens it read-only in a background isolate.
  ///
  /// The copy is stamped with the app's build number, so a launch that
  /// already holds this build's copy neither reads nor hashes the 31 MB
  /// asset again: doing that on every launch cost the app a few hundred
  /// milliseconds before the first frame, on a phone.
  static Future<ContentDatabase> openBundled(AssetBundle bundle) async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'content.db'));
    final stamp = File(p.join(dir.path, 'content.db.stamp'));
    // Under a debug build the asset can change without the build number
    // changing, so there the copy is checked by its checksum as before.
    final build = kDebugMode
        ? null
        : (await PackageInfo.fromPlatform()).buildNumber;
    final installed = file.existsSync() && stamp.existsSync();
    if (installed && build != null && stamp.readAsStringSync() == 'b$build') {
      return _open(file);
    }
    final data = await bundle.load('assets/db/content.db');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final mark = build == null ? 's${sha256.convert(bytes)}' : 'b$build';
    if (!installed || stamp.readAsStringSync() != mark) {
      await file.writeAsBytes(bytes, flush: true);
      await stamp.writeAsString(mark);
    }
    return _open(file);
  }

  /// Opens [file] read-only, off the main isolate.
  static ContentDatabase _open(File file) => ContentDatabase(
    NativeDatabase.createInBackground(
      file,
      setup: (db) => db.execute('PRAGMA query_only = ON'),
    ),
  );
}
