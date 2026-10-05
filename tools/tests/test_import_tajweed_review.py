"""Tests for the tajweed review importer (import_tajweed_review.py)."""
import re
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(TOOLS))

import import_tajweed_review as itr  # noqa: E402

CONTENT_DB = TOOLS.parent / 'assets' / 'db' / 'content.db'


def have_db():
    return CONTENT_DB.exists() and CONTENT_DB.read_bytes()[:15] == b'SQLite format 3'


class PartsTest(unittest.TestCase):
    def test_words_leave_out_the_hizb_sign_and_the_verse_number(self):
        self.assertEqual(itr.words_of('۞ إِنَّ ٱللَّهَ ٢٦'), ['إِنَّ', 'ٱللَّهَ'])

    def test_a_letter_is_a_base_with_its_marks(self):
        self.assertEqual(itr.letters('ٱللَّهِ'), [[0, 1], [1, 2], [2, 5], [5, 7]])

    def test_each_line_names_the_word_and_ends_with_the_row(self):
        text = itr.entry_text(['بِسۡمِ', 'ٱللَّهِ'], [(2, 1, 'body', 'lam_shamsiyyah')])
        self.assertEqual(text, 'ك2 ح2 «ٱللَّهِ» اللام الشمسية [lam_shamsiyyah 2:1:body]')

    def test_the_sample_is_juz_30_and_the_same_every_run(self):
        verses = {(s, a): {'juz': 30 if s > 77 else 1} for s in range(1, 115) for a in range(1, 4)}
        first, n30 = itr.choose(verses, 10)
        self.assertEqual(n30, 3 * 37)
        self.assertEqual(first, itr.choose(verses, 10)[0])
        self.assertEqual(len(first), 3 * 37 + 10)


@unittest.skipUnless(have_db(), 'assets/db/content.db (Git LFS) is needed')
class BuildTest(unittest.TestCase):
    def test_every_rule_row_of_the_chosen_verses_lands_as_a_draft(self):
        with tempfile.TemporaryDirectory() as d:
            out = Path(d) / 't.db'
            stats = itr.build(out, CONTENT_DB, 20)
            db = sqlite3.connect(out)
            src = sqlite3.connect(f'file:{CONTENT_DB}?mode=ro', uri=True)
            self.assertEqual(stats['letters_out_of_range'], 0)
            self.assertEqual({r[0] for r in db.execute('SELECT DISTINCT state FROM entry')}, {'draft'})
            line = re.compile(r'\[([a-z_0-9]+) (\d+):(\d+):(body|marks)\]$')
            for text, s, a in db.execute(
                    'SELECT text, surah, ayah_from FROM entry JOIN entry_link ON entry_id = entry.id'):
                got = sorted((int(m[2]), int(m[3]), m[4], m[1])
                             for m in (line.search(l) for l in text.split('\n')) if m)
                want = sorted(src.execute(
                    "SELECT word, letter, part, rule FROM tajweed_letter "
                    "WHERE riwaya = 'hafs' AND surah = ? AND ayah = ?", (s, a)).fetchall())
                self.assertEqual(got, want, (s, a))
            self.assertEqual(stats['entries'], stats['juz30'] + 20)


if __name__ == '__main__':
    unittest.main()
