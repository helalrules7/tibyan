"""Tests for tools/import_dar_alathar.py with a fixture in the shape we
asked Dar al-Athar for.

The fixture texts are placeholders («نص تجريبي») around quotations copied
from the Tanzil simple-clean text; nothing in them is from the book.
"""
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(TOOLS))

import export_pack  # noqa: E402
import import_dar_alathar as imp  # noqa: E402
import review_db  # noqa: E402

CONTENT_DB = TOOLS.parent / 'assets' / 'db' / 'content.db'

TEXT_1 = 'نص تجريبي قبل الآية ﴿الم ذلك الكتاب لا ريب فيه﴾ ثم نص تجريبي.\nفقرة ثانية: صلى الله عليه وسلم.'
TEXT_2 = 'نص تجريبي عن ﴿يا أيها الناس اعبدوا ربكم﴾ رضي الله عنه.'
CITATION = 'نقلا عن «الصحيح المسند من أسباب النزول»، طبعة دار الآثار، بإذن منها'


def make_file(path, *, asbab_cols='id INTEGER, surah INTEGER, title TEXT, text TEXT, page INTEGER',
              rows=None, links=None, meta='row', extra_sql=''):
    db = sqlite3.connect(path)
    db.execute(f'CREATE TABLE asbab ({asbab_cols})')
    db.execute('CREATE TABLE links (asbab_id INTEGER, surah INTEGER, ayah_from INTEGER, ayah_to INTEGER)')
    if rows is None:
        rows = [(1, 2, 'قوله تعالى: ﴿الم﴾', TEXT_1, 12), (2, 2, None, TEXT_2, 15)]
    marks = ', '.join('?' for _ in rows[0]) if rows else ''
    for r in rows:
        db.execute(f'INSERT INTO asbab VALUES ({marks})', r)
    if links is None:
        links = [(1, 2, 1, 2), (2, 2, 21, 21), (2, 2, 22, 22)]
    db.executemany('INSERT INTO links VALUES (?, ?, ?, ?)', links)
    if meta == 'row':
        db.execute('CREATE TABLE meta (edition TEXT, citation TEXT)')
        db.execute('INSERT INTO meta VALUES (?, ?)', ('الطبعة الأولى', CITATION))
    elif meta == 'kv':
        db.execute('CREATE TABLE meta (key TEXT, value TEXT)')
        db.executemany('INSERT INTO meta VALUES (?, ?)',
                       [('edition', 'الطبعة الأولى'), ('citation', CITATION)])
    if extra_sql:
        db.executescript(extra_sql)
    db.commit()
    db.close()


@unittest.skipUnless(CONTENT_DB.exists(), 'assets/db/content.db (Git LFS) is needed')
class ImportDarAlatharTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)
        self.src = self.dir / 'dar.sqlite'
        self.out = self.dir / 'r.review.db'

    def tearDown(self):
        self.tmp.cleanup()

    def run_import(self, mapping=None, **kw):
        return imp.build(self.src, self.out, CONTENT_DB, imp.parse_map(mapping), **kw)

    def refused(self, pattern, mapping=None, **kw):
        with self.assertRaisesRegex(imp.ImportError_, pattern):
            self.run_import(mapping, **kw)
        self.assertFalse(self.out.exists(), 'nothing is written when the file is refused')

    def test_imports_drafts_verbatim_with_links_pages_and_citation(self):
        make_file(self.src)
        stats = self.run_import()
        self.assertEqual((stats['entries'], stats['links']), (2, 3))
        db = sqlite3.connect(self.out)
        entries = db.execute('SELECT id, seq, kind, section, page, page_end, text, state, created_by '
                             'FROM entry ORDER BY seq').fetchall()
        self.assertEqual([e[6] for e in entries], [TEXT_1, TEXT_2])  # byte for byte
        self.assertEqual([(e[3], e[4], e[5]) for e in entries],
                         [('قوله تعالى: ﴿الم﴾', 12, 12), (None, 15, 15)])
        self.assertEqual({e[7] for e in entries}, {'draft'})
        self.assertEqual({e[2] for e in entries}, {'passage'})
        links = db.execute('SELECT entry_id, surah, ayah_from, ayah_to, basis, confidence '
                           'FROM entry_link ORDER BY entry_id, ayah_from').fetchall()
        self.assertEqual(links, [(entries[0][0], 2, 1, 2, 'marker', 1.0),
                                 (entries[1][0], 2, 21, 21, 'marker', 1.0),
                                 (entries[1][0], 2, 22, 22, 'marker', 1.0)])
        source = db.execute('SELECT key, kind, title, edition, file, sha256 FROM source').fetchone()
        self.assertEqual(source[:5], ('sahih_musnad_asbab_wadii', 'asbab_nuzul',
                                      'الصحيح المسند من أسباب النزول', 'الطبعة الأولى', 'dar.sqlite'))
        self.assertEqual(source[5], review_db.sha256_file(self.src))
        self.assertEqual(dict(db.execute('SELECT key, value FROM meta'))[
            'source_citation:sahih_musnad_asbab_wadii'], CITATION)
        self.assertEqual(db.execute("SELECT count(*) FROM audit WHERE action = 'import'").fetchone()[0], 2)
        # The hash covers text, page and links, as for every other import.
        e = entries[0]
        self.assertEqual(
            db.execute('SELECT content_hash FROM entry WHERE id = ?', (e[0],)).fetchone()[0],
            review_db.content_hash('sahih_musnad_asbab_wadii', None, 12, 12, TEXT_1,
                                   review_db.links_of(db, e[0])))
        db.close()

    def test_key_value_meta_and_renamed_columns(self):
        make_file(self.src, asbab_cols='id INTEGER, surah INTEGER, title TEXT, nass TEXT, page INTEGER',
                  meta='kv')
        self.run_import(['asbab.text=nass'])
        db = sqlite3.connect(self.out)
        self.assertEqual(db.execute('SELECT text FROM entry ORDER BY seq').fetchall(),
                         [(TEXT_1,), (TEXT_2,)])
        self.assertEqual(db.execute('SELECT edition FROM source').fetchone()[0], 'الطبعة الأولى')
        db.close()

    def test_bad_map_is_refused(self):
        with self.assertRaises(imp.ImportError_):
            imp.parse_map(['asbab.nothing=x'])
        with self.assertRaises(imp.ImportError_):
            imp.parse_map(['nope=x'])

    def test_missing_column_is_refused(self):
        make_file(self.src, asbab_cols='id INTEGER, surah INTEGER, title TEXT, nass TEXT, page INTEGER')
        self.refused(r'asbab\.text')

    def test_unknown_columns_and_tables_are_refused_unless_allowed(self):
        make_file(self.src, asbab_cols='id INTEGER, surah INTEGER, title TEXT, text TEXT, page INTEGER, '
                                       'hukm TEXT',
                  rows=[(1, 2, None, TEXT_1, 12, 'صحيح')], links=[(1, 2, 1, 2)],
                  extra_sql='CREATE TABLE footnotes (id INTEGER, text TEXT);')
        self.refused('hukm')
        self.refused('footnotes')
        stats = self.run_import(allow_extra=True)
        self.assertEqual(stats['entries'], 1)
        self.assertTrue(any('hukm' in w for w in stats['warnings']))

    def test_symbol_glyphs_are_refused(self):
        make_file(self.src, rows=[(1, 2, None, 'نص تجريبي قال ﷺ', 3)], links=[(1, 2, 1, 1)])
        self.refused('U\\+FDFA')

    def test_markup_and_carriage_returns_are_refused(self):
        make_file(self.src, rows=[(1, 2, None, 'نص <b>تجريبي</b>', 3)], links=[(1, 2, 1, 1)])
        self.refused('markup')
        self.src.unlink()
        make_file(self.src, rows=[(1, 2, None, 'نص\r\nتجريبي', 3)], links=[(1, 2, 1, 1)])
        self.refused('carriage')

    def test_verses_outside_the_mushaf_are_refused(self):
        make_file(self.src, links=[(1, 2, 1, 2), (2, 2, 280, 290)])
        self.refused('outside the mushaf')
        self.src.unlink()
        make_file(self.src, links=[(1, 2, 3, 2), (2, 2, 21, 21)])
        self.refused('outside the mushaf')

    def test_links_to_missing_rows_and_unlinked_rows_are_refused(self):
        make_file(self.src, links=[(1, 2, 1, 2), (9, 2, 5, 5)])
        self.refused('no asbab row with that id')
        self.src.unlink()
        make_file(self.src, links=[(1, 2, 1, 2)])
        self.refused('asbab id 2: no verse linked')
        stats = self.run_import(allow_unlinked=True)
        self.assertEqual(stats['unlinked'], 1)

    def test_empty_text_duplicate_ids_and_missing_edition_are_refused(self):
        make_file(self.src, rows=[(1, 2, None, '  ', 3), (1, 2, None, TEXT_2, 4)],
                  links=[(1, 2, 1, 1)], meta=None,
                  extra_sql="CREATE TABLE meta (edition TEXT, citation TEXT);"
                            "INSERT INTO meta VALUES ('', NULL);")
        with self.assertRaises(imp.ImportError_) as caught:
            self.run_import()
        message = str(caught.exception)
        for part in ('text is empty', 'id appears twice', 'edition is missing'):
            self.assertIn(part, message)

    def test_links_into_another_surah_are_kept_and_noted(self):
        make_file(self.src, links=[(1, 2, 1, 2), (2, 2, 21, 21), (2, 3, 7, 7)])
        stats = self.run_import()
        self.assertEqual(stats['other_surah_links'], 1)
        db = sqlite3.connect(self.out)
        detail = db.execute("SELECT detail FROM audit WHERE action = 'import' ORDER BY id DESC").fetchone()[0]
        self.assertIn('linked outside its surah', detail)
        db.close()

    def test_reviewed_entries_export_with_the_publishers_citation(self):
        make_file(self.src)
        self.run_import()
        db = sqlite3.connect(self.out)
        entry_id, h = db.execute('SELECT id, content_hash FROM entry WHERE seq = 1').fetchone()
        db.execute("UPDATE entry SET state = 'in_review', editor = 'محرر' WHERE id = ?", (entry_id,))
        db.execute("UPDATE entry SET state = 'reviewed', reviewer = 'مراجع', reviewed_at = 'x' "
                   'WHERE id = ?', (entry_id,))
        db.execute("INSERT INTO audit (entry_id, at, actor, role, action, from_state, to_state, "
                   "hash_before, hash_after) VALUES (?, 'x', 'مراجع', 'reviewer', 'approve', "
                   "'in_review', 'reviewed', ?, ?)", (entry_id, h, h))
        db.commit()
        db.close()
        pack_path = self.dir / 'p.pack.db'
        export_pack.export(self.out, pack_path)
        pack = sqlite3.connect(pack_path)
        self.assertEqual(pack.execute('SELECT citation, edition FROM source').fetchone(),
                         (CITATION, 'الطبعة الأولى'))
        self.assertEqual(pack.execute('SELECT text FROM entry').fetchall(), [(TEXT_1,)])
        pack.close()


if __name__ == '__main__':
    unittest.main()
