"""Every kind of book goes through tools/export_pack.py into a pack the
app reads (the app's side is test/books/export_pipeline_test.dart).

Run: python3 -m unittest discover -s tools/tests
"""
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import book_pack_fixtures as fx  # noqa: E402


class ExportKindsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.packs = fx.build(cls.tmp.name)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def open(self, kind):
        db = sqlite3.connect(f'file:{self.packs[kind]}?mode=ro', uri=True)
        self.addCleanup(db.close)
        return db

    def test_one_pack_per_kind_in_the_format_the_app_reads(self):
        self.assertEqual(set(self.packs), {'asbab_nuzul', 'tafsir', 'munasabat', 'wujuh_nazair'})
        for kind in self.packs:
            db = self.open(kind)
            index = dict(db.execute('SELECT key, value FROM pack_index'))
            self.assertEqual(index['format'], '1', kind)
            self.assertEqual(index['kind'], kind)
            self.assertEqual([r[0] for r in db.execute('SELECT kind FROM source')], [kind])
            self.assertTrue(Path(self.packs[kind] + '.index.json').exists())

    def test_only_reviewed_entries_text_byte_for_byte(self):
        db = self.open('asbab_nuzul')
        self.assertEqual([r[0] for r in db.execute('SELECT text FROM entry')], ['نص سبب تجريبي.'])
        db = self.open('tafsir')
        self.assertEqual(db.execute('SELECT text FROM entry').fetchone()[0], fx.TAFSIR_TEXT)
        for kind in self.packs:
            for editor, reviewer in self.open(kind).execute('SELECT editor, reviewer FROM entry'):
                self.assertNotEqual(editor, reviewer)

    def test_ranges_and_words_kept(self):
        self.assertEqual(
            self.open('tafsir').execute('SELECT surah, ayah_from, ayah_to FROM entry_link').fetchall(),
            [(2, 1, 5)])
        rows = self.open('wujuh_nazair').execute(
            'SELECT e.kind, e.section, l.word_from, l.word_to FROM entry e '
            'JOIN entry_link l ON l.entry_id = e.id ORDER BY e.seq').fetchall()
        self.assertEqual(rows, [('word', 'كلمة على وجهين', None, None),
                                ('wajh', 'كلمة على وجهين', 3, 3)])


if __name__ == '__main__':
    unittest.main()
