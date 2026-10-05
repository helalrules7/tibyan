import 'package:sqlite3/sqlite3.dart';
import 'package:tibyan/features/books/data/book_pack.dart';

/// The pack schema tools/export_pack.py writes (PACK_SCHEMA).
const packSchema = '''
CREATE TABLE pack_index (key TEXT PRIMARY KEY, value TEXT NOT NULL);
CREATE TABLE source (
  id INTEGER PRIMARY KEY, key TEXT NOT NULL UNIQUE, kind TEXT NOT NULL,
  title TEXT NOT NULL, author TEXT NOT NULL, edition TEXT, publisher TEXT,
  tahqiq TEXT, licence TEXT NOT NULL, digitised_by TEXT, url TEXT NOT NULL,
  sha256 TEXT NOT NULL, citation TEXT
);
CREATE TABLE entry (
  id INTEGER PRIMARY KEY, source_id INTEGER NOT NULL REFERENCES source(id),
  seq INTEGER NOT NULL, kind TEXT NOT NULL, section TEXT,
  volume INTEGER, page INTEGER, page_end INTEGER, text TEXT NOT NULL,
  content_hash TEXT NOT NULL, editor TEXT NOT NULL, reviewer TEXT NOT NULL,
  reviewed_at TEXT NOT NULL
);
CREATE TABLE entry_link (
  entry_id INTEGER NOT NULL REFERENCES entry(id), surah INTEGER NOT NULL,
  ayah_from INTEGER NOT NULL, ayah_to INTEGER NOT NULL,
  word_from INTEGER, word_to INTEGER
);
CREATE INDEX entry_link_verse ON entry_link (surah, ayah_from);
''';

/// Placeholder texts only: nothing here is from a book.
const fakeText1 =
    'نص تجريبي أول ﴿نص آية تجريبي﴾ ثم نص تجريبي.\nفقرة تجريبية ثانية.';
const fakeText2 = 'نص تجريبي ثان.';
const fakeText3 = 'نص تجريبي ثالث بلا مراجعة.';
const fakeCitation = 'صيغة ذكر مصدر تجريبية';

/// An in-memory pack: one asbab book with a custom citation, one other
/// kind of book.
///  * entry 1 (asbab, p. 12): 2:1-5
///  * entry 2 (asbab, p. 15-16): 2:10, 2:12-13 and 2:13 again
///  * entry 3 (asbab): 2:3, reviewer is the editor (must never show)
///  * entry 4 (wujuh): 2:3
Database fakePackDb({bool citationColumn = true, String format = '1'}) {
  final db = sqlite3.openInMemory();
  db.execute(
    citationColumn
        ? packSchema
        : packSchema.replaceFirst(', citation TEXT', ''),
  );
  db.execute("INSERT INTO pack_index VALUES ('format', ?)", [format]);
  final cols = citationColumn ? ', citation' : '';
  final extra = citationColumn ? ', ?' : '';
  db.execute(
    'INSERT INTO source (id, key, kind, title, author, edition, publisher, '
    'tahqiq, licence, url, sha256$cols) '
    'VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?$extra)',
    [
      'test_asbab',
      BookKind.asbabNuzul,
      'كتاب تجريبي',
      'مؤلف تجريبي',
      'الطبعة الأولى',
      'ناشر تجريبي',
      null,
      'test',
      'about:blank',
      '0' * 64,
      if (citationColumn) fakeCitation,
    ],
  );
  db.execute(
    'INSERT INTO source (id, key, kind, title, author, licence, url, sha256) '
    "VALUES (2, 'test_wujuh', 'wujuh_nazair', 'كتاب آخر', 'مؤلف', 'test', "
    "'about:blank', ?)",
    ['0' * 64],
  );
  void entry(
    int id,
    int source,
    int seq,
    String text, {
    String? section,
    int? page,
    int? pageEnd,
    String reviewer = 'مراجع',
  }) => db.execute(
    'INSERT INTO entry VALUES (?, ?, ?, ?, ?, NULL, ?, ?, ?, ?, ?, ?, ?)',
    [
      id,
      source,
      seq,
      'passage',
      section,
      page,
      pageEnd,
      text,
      'h$id',
      'محرر',
      reviewer,
      '2026-10-05',
    ],
  );
  void link(int entry, int surah, int from, int to) => db.execute(
    'INSERT INTO entry_link VALUES (?, ?, ?, ?, NULL, NULL)',
    [entry, surah, from, to],
  );
  // Inserted out of order: the query returns the book's order (seq).
  entry(2, 1, 2, fakeText2, page: 15, pageEnd: 16);
  entry(1, 1, 1, fakeText1, section: 'عنوان ﴿تجريبي﴾', page: 12, pageEnd: 12);
  entry(3, 1, 3, fakeText3, reviewer: 'محرر');
  entry(4, 2, 1, 'نص كتاب آخر');
  link(1, 2, 1, 5);
  link(2, 2, 10, 10);
  link(2, 2, 12, 13);
  link(2, 2, 13, 13);
  link(2, 2, 1, 1);
  link(3, 2, 3, 3);
  link(4, 2, 3, 3);
  return db;
}

BookPack fakePack() => BookPack(fakePackDb());
