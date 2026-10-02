"""Tests for how build_tajweed.py places cpfair spans on the KFGQPC words.

The texts below are copied from the sources (Tanzil 2017 and KFGQPC 2.0,
verse 2:6 and the opening of 2:5); nothing is typed by hand.

Run: python3 -m unittest discover -s tools/tests   (skipped without tools/.cache)
"""
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
import build_tajweed as bt  # noqa: E402
import build_word_boxes as bw  # noqa: E402


HAVE_CACHE = bt.TAJWEED.exists() and bw.TEXT_ZIP.exists()


@unittest.skipUnless(HAVE_CACHE, 'needs tools/.cache (python3 tools/fetch_sources.py)')
class Letters(unittest.TestCase):
    def test_letters_keep_their_marks(self):
        word = bw.load_text()[(2, 6)][0]          # إِنَّ
        spans = bt.letters(word)
        self.assertEqual([word[s:e] for s, e in spans], [word[0:2], word[2:]])

    def test_runs_follow_the_joining_letters(self):
        for words in list(bw.load_text().values())[:300]:
            for w in words:
                self.assertEqual(len(bt.runs(w)), bw.predicted_pieces(w), w)


@unittest.skipUnless(HAVE_CACHE, 'needs tools/.cache')
class Spans(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.kfgqpc = bw.load_text()
        cls.tanzil = bt.read_tanzil(bt.TANZIL_2017)
        cls.data = {(e['surah'], e['ayah']): e['annotations']
                    for e in json.loads(bt.TAJWEED.read_text(encoding='utf-8'))}

    def spans(self, key):
        return bt.verse_spans(self.data[key], self.tanzil[key], self.kfgqpc[key],
                              bt.basmala_prefix(self.tanzil, key))

    def letter(self, key, wi, li):
        w = self.kfgqpc[key][wi]
        s, e = bt.letters(w)[li]
        return w[s:e]

    def test_ghunnah_lands_on_the_noon_with_shadda(self):
        key = (2, 6)
        got = [(r, wi, li, p) for r, wi, li, p in self.spans(key) if r == 'ghunnah']
        self.assertEqual(got, [('ghunnah', 0, 1, 'body')])
        self.assertEqual(self.letter(key, 0, 1)[0], 'ن')

    def test_every_span_lands_on_the_same_letter_in_both_texts(self):
        # Letters may be spelled differently (ى/ي, ء ا/أ), never be another letter.
        same = str.maketrans({'ى': 'ي', 'ئ': 'ي', 'ؤ': 'و', 'ۦ': 'ـ', 'ء': 'أ', 'ا': 'أ'})
        for key in [(2, 5), (2, 6), (2, 255), (36, 1), (112, 1), (114, 6)]:
            where = bt.letter_map(self.tanzil[key], self.kfgqpc[key])
            for i, hit in where.items():
                if hit is None or not hit[1]:
                    continue
                (wi, li), _ = hit
                a = self.tanzil[key][i].translate(same)
                b = self.letter(key, wi, li)[0].translate(same)
                self.assertEqual(a, b, (key, i))

    def test_marks_only_spans_colour_only_the_marks(self):
        # 2:5 «أُو۟لَٰٓئِكَ»: madd_muttasil covers the dagger alef and maddah.
        got = [s for s in self.spans((2, 5)) if s[0] == 'madd_muttasil']
        self.assertEqual(got[0], ('madd_muttasil', 0, 2, 'marks'))

    def test_spans_across_words_reach_both_words(self):
        # 2:5 «هُدًى مِّن»: idghaam with ghunnah from the tanween to the meem.
        got = {(wi, li) for r, wi, li, _ in self.spans((2, 5)) if r == 'idghaam_ghunnah'}
        self.assertIn((3, 0), got)
        self.assertTrue(any(wi == 2 for wi, _ in got))

    def test_basmala_before_verse_one_is_left_out(self):
        self.assertGreater(bt.basmala_prefix(self.tanzil, (2, 1)), 0)
        self.assertEqual(bt.basmala_prefix(self.tanzil, (1, 1)), 0)
        self.assertEqual(bt.basmala_prefix(self.tanzil, (9, 1)), 0)
        for r, wi, li, _ in self.spans((2, 1)):   # الٓمٓ: one word only
            self.assertEqual(wi, 0)


@unittest.skipUnless(HAVE_CACHE and bt.LETTER_WIDTHS.exists(), 'needs tools/.cache')
class Placement(unittest.TestCase):
    def test_letter_ranges_share_out_each_piece(self):
        word = bw.load_text()[(2, 6)][0]          # إِنَّ: pieces إ and نّ
        ranges, piece_of, exact = bt.letter_ranges(word, [(90.0, 100.0), (80.0, 88.0)])
        self.assertTrue(exact)
        self.assertEqual(piece_of, {0: 0, 1: 1})
        self.assertEqual(ranges[0], (90.0, 100.0))
        self.assertEqual(ranges[1], (80.0, 88.0))

    def test_unexpected_pieces_share_out_the_whole_word(self):
        word = bw.load_text()[(2, 6)][0]
        ranges, piece_of, exact = bt.letter_ranges(word, [(80.0, 100.0)])
        self.assertFalse(exact)
        self.assertEqual(ranges[0][1], 100.0)
        self.assertEqual(ranges[1][0], 80.0)
        self.assertLessEqual(ranges[1][1], ranges[0][0] + 1e-9)


if __name__ == '__main__':
    unittest.main()
