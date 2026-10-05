import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../../mushaf/data/page_pack.dart';

/// What a reviewed book pack holds; matches the source `kind` in the
/// review database (tools/review_schema.sql).
abstract final class BookKind {
  static const asbabNuzul = 'asbab_nuzul';
  static const tafsir = 'tafsir';
  static const munasabat = 'munasabat';
  static const wujuhNazair = 'wujuh_nazair';
}

/// The kind of one entry of a book (`entry.kind`), as the import scripts
/// split it.
abstract final class EntryKind {
  static const passage = 'passage';
  static const surahIntro = 'surah_intro';

  /// al-Damghani's word header («… على N أوجه») and one of its senses.
  static const word = 'word';
  static const wajh = 'wajh';
}

/// A reviewed book pack on Tibyan's mirror: a SQLite file built by
/// tools/export_pack.py from a review database (reviewed entries only,
/// text byte for byte). It is downloaded and checked like the page packs
/// (same resume, fallbacks and SHA-256 check) and installed as
/// `packs/<id>/book.db`. docs/features/asbab_nuzul.md says how a pack
/// gets here.
class BookPackSpec {
  const BookPackSpec({
    required this.id,
    required this.url,
    required this.sha256,
    required this.bytes,
    required this.kind,
    required this.title,
    this.fallbacks = const [],
  });

  final String id;

  /// On Tibyan's mirror: `…/mirror/books/<id>.pack.db`.
  final String url;
  final List<String> fallbacks;

  /// The pack file's SHA-256 (`pack_sha256` in its `.index.json`).
  final String sha256;
  final int bytes;

  /// [BookKind]: which feature shows it.
  final String kind;

  /// The book's title, for the storage screen and the download
  /// notification before the pack is on the device.
  final String title;

  /// The same file as a pack the page-pack installer and the background
  /// downloader handle.
  PagePackSpec get pack => PagePackSpec(
    id: id,
    url: url,
    sha256: sha256,
    bytes: bytes,
    format: PackFormat.book,
    fallbacks: fallbacks,
  );

  /// Every reviewed book pack the app can download. Empty until a pack is
  /// reviewed, exported and put on the mirror.
  static const all = <BookPackSpec>[];
}

/// The book an entry is from, as the pack's `source` row gives it.
class BookSource {
  const BookSource({
    required this.id,
    required this.key,
    required this.kind,
    required this.title,
    required this.author,
    this.edition,
    this.publisher,
    this.tahqiq,
    this.citation,
  });

  final int id;
  final String key;
  final String kind;
  final String title;
  final String author;
  final String? edition;
  final String? publisher;
  final String? tahqiq;

  /// The citation wording the publisher asked for, shown exactly as given.
  final String? citation;
}

/// Where an entry is linked in the mushaf (Hafs numbers): one verse or a
/// range of verses of one surah, and optionally words (1-based, of the
/// KFGQPC text) of the first and last verse.
class BookLink {
  const BookLink({
    required this.surah,
    required this.ayahFrom,
    required this.ayahTo,
    this.wordFrom,
    this.wordTo,
  });

  final int surah;
  final int ayahFrom;
  final int ayahTo;
  final int? wordFrom;
  final int? wordTo;

  /// The passage covers several verses.
  bool get isRange => ayahTo != ayahFrom;

  bool covers(int surah, int ayah) =>
      surah == this.surah && ayahFrom <= ayah && ayah <= ayahTo;

  /// Covers word [word] of [ayah]: a link without words covers every word
  /// of its verses.
  bool coversWord(int ayah, int word) =>
      !(wordFrom != null && ayah == ayahFrom && word < wordFrom!) &&
      !(wordTo != null && ayah == ayahTo && word > wordTo!);
}

/// One reviewed passage of a book. [text] is the book's text byte for
/// byte; [section] is the book's own heading for it.
class BookEntry {
  const BookEntry({
    required this.id,
    required this.source,
    required this.seq,
    required this.text,
    this.kind = EntryKind.passage,
    this.section,
    this.volume,
    this.page,
    this.pageEnd,
    this.link,
  });

  final int id;
  final BookSource source;
  final int seq;
  final String text;

  /// [EntryKind].
  final String kind;
  final String? section;
  final int? volume;
  final int? page;
  final int? pageEnd;

  /// The link that put the entry on the verse it was asked for (the
  /// first in the mushaf's order when several do); null for an entry
  /// read by itself, such as a word header.
  final BookLink? link;
}

/// An opened reviewed book pack (read-only).
class BookPack {
  /// Reads [db] as a pack: refuses a file that is not one, or one of a
  /// format this version does not know.
  BookPack(this._db, {this.spec}) {
    final tables = {
      for (final r in _db.select(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      ))
        r['name'] as String,
    };
    for (final t in const ['pack_index', 'source', 'entry', 'entry_link']) {
      if (!tables.contains(t)) throw FormatException('Not a book pack: $t');
    }
    final format = _db.select(
      "SELECT value FROM pack_index WHERE key = 'format'",
    );
    if (format.isEmpty || format.first['value'] != supportedFormat) {
      throw const FormatException('Unknown book pack format');
    }
    final hasCitation = _db
        .select('PRAGMA table_info(source)')
        .any((r) => r['name'] == 'citation');
    for (final r in _db.select(
      'SELECT id, key, kind, title, author, edition, publisher, tahqiq'
      '${hasCitation ? ', citation' : ''} FROM source',
    )) {
      sources[r['id'] as int] = BookSource(
        id: r['id'] as int,
        key: r['key'] as String,
        kind: r['kind'] as String,
        title: r['title'] as String,
        author: r['author'] as String,
        edition: _text(r['edition']),
        publisher: _text(r['publisher']),
        tahqiq: _text(r['tahqiq']),
        citation: hasCitation ? _text(r['citation']) : null,
      );
    }
  }

  /// Opens an installed pack file read-only.
  factory BookPack.open(File file, {BookPackSpec? spec}) {
    final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
    try {
      return BookPack(db, spec: spec);
    } catch (_) {
      db.close();
      rethrow;
    }
  }

  /// The `format` in pack_index that tools/export_pack.py writes.
  static const supportedFormat = '1';

  final Database _db;
  final BookPackSpec? spec;
  final Map<int, BookSource> sources = {};

  /// The reviewed entries linked to [surah]:[ayah], in the book's order,
  /// each once even when several of its links cover the verse. A link
  /// covers the verse when its surah matches and
  /// `ayah_from <= ayah <= ayah_to`. [kind] keeps one kind of book,
  /// [source] one book (its key), [entryKinds] some kinds of entries;
  /// with [word], a link that names words must cover that word.
  /// An entry without a reviewer other than its editor is never returned
  /// (export_pack.py exports none; this guards a hand-made file).
  List<BookEntry> entriesFor(
    int surah,
    int ayah, {
    String? kind,
    String? source,
    Set<String>? entryKinds,
    int? word,
  }) {
    final rows = _db.select(
      'SELECT e.id, e.source_id, e.seq, e.kind, e.section, e.volume, '
      'e.page, e.page_end, e.text, l.ayah_from, l.ayah_to, l.word_from, '
      'l.word_to FROM entry_link l '
      'JOIN entry e ON e.id = l.entry_id '
      'JOIN source s ON s.id = e.source_id '
      'WHERE l.surah = ? AND l.ayah_from <= ? AND l.ayah_to >= ? '
      '$_reviewed '
      '${kind == null ? '' : 'AND s.kind = ? '}'
      '${source == null ? '' : 'AND s.key = ? '}'
      'ORDER BY e.source_id, e.seq, l.ayah_from, l.ayah_to',
      [surah, ayah, ayah, ?kind, ?source],
    );
    final seen = <int>{};
    final out = <BookEntry>[];
    for (final r in rows) {
      final id = r['id'] as int;
      if (seen.contains(id)) continue;
      if (entryKinds != null && !entryKinds.contains(r['kind'])) continue;
      final link = BookLink(
        surah: surah,
        ayahFrom: r['ayah_from'] as int,
        ayahTo: r['ayah_to'] as int,
        wordFrom: r['word_from'] as int?,
        wordTo: r['word_to'] as int?,
      );
      if (word != null && !link.coversWord(ayah, word)) continue;
      seen.add(id);
      out.add(_entry(r, link));
    }
    return out;
  }

  /// The entry [entry] belongs under: the nearest entry of [kind] before
  /// it in the same book, when it carries the same heading (al-Damghani
  /// puts each sense under its word header). Null when that entry is not
  /// in the pack (not reviewed) or the headings differ: never a guess.
  BookEntry? parentOf(BookEntry entry, {required String kind}) {
    if (entry.section == null) return null;
    final rows = _db.select(
      'SELECT e.id, e.source_id, e.seq, e.kind, e.section, e.volume, '
      'e.page, e.page_end, e.text, e.editor, e.reviewer FROM entry e '
      'WHERE e.source_id = ? AND e.seq < ? AND e.kind = ? '
      'ORDER BY e.seq DESC LIMIT 1',
      [entry.source.id, entry.seq, kind],
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    final reviewer = r['reviewer'] as String?;
    if (reviewer == null || reviewer.isEmpty || reviewer == r['editor']) {
      return null;
    }
    if (r['section'] != entry.section) return null;
    return _entry(r, null);
  }

  /// The books of [kind] in this pack.
  List<BookSource> sourcesOf(String kind) => [
    for (final s in sources.values)
      if (s.kind == kind) s,
  ];

  static const _reviewed =
      "AND e.reviewer IS NOT NULL AND e.reviewer <> '' "
      'AND e.reviewer <> e.editor';

  BookEntry _entry(Row r, BookLink? link) => BookEntry(
    id: r['id'] as int,
    source: sources[r['source_id'] as int]!,
    seq: r['seq'] as int,
    kind: r['kind'] as String,
    section: _text(r['section']),
    volume: r['volume'] as int?,
    page: r['page'] as int?,
    pageEnd: r['page_end'] as int?,
    text: r['text'] as String,
    link: link,
  );

  void close() => _db.close();

  static String? _text(Object? v) =>
      v is String && v.trim().isNotEmpty ? v : null;
}
