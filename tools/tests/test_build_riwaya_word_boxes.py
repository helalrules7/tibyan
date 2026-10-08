"""Tests for build_riwaya_word_boxes: splitting a verse into its words,
the piece counts, the verse a page splits in two, and the pack's
words.json. The strings are letter sequences made up for the tests, not
verse text.

Run: python3 -m unittest discover -s tools/tests
"""
import sys
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(TOOLS))

import build_riwaya_packs  # noqa: E402
import build_riwaya_word_boxes as W  # noqa: E402
import build_word_boxes as B  # noqa: E402

NUMBER = 'ﰀ'  # a verse-number glyph of the KFGQPC fonts


def segment(page, line, pieces, y=100.0):
    """A verse's segment on a line, as page_segments gives it: pieces
    (x0, x1, [bbox]) right to left, and the contours (bbox, points)."""
    out_pieces, contours = [], []
    for x0, x1 in pieces:
        bbox = (float(x0), y - 5, float(x1), y + 5)
        out_pieces.append((x0, x1, [bbox]))
        contours.append((bbox, [(x0, y - 5), (x1, y - 5), (x1, y + 5), (x0, y + 5)]))
    return (page, line, out_pieces, contours)


class TokensTest(unittest.TestCase):
    def test_spaces_and_the_verse_number(self):
        self.assertEqual(W.verse_tokens('سس  اس ' + NUMBER), ['سس', 'اس'])

    def test_number_joined_to_the_last_word(self):
        self.assertEqual(W.verse_tokens('سس اس' + NUMBER), ['سس', 'اس'])

    def test_number_in_arabic_indic_digits(self):
        self.assertEqual(W.verse_tokens('سس اس ٢٨٦'), ['سس', 'اس'])

    def test_hizb_sign_is_aligned_but_not_a_word(self):
        tokens = W.verse_tokens('۞ سس اس ' + NUMBER)
        self.assertEqual(tokens, ['۞', 'سس', 'اس'])
        self.assertEqual(W.words_of(tokens), ['سس', 'اس'])

    def test_yeh_barree_joins_only_the_letter_before(self):
        self.assertEqual(B.predicted_pieces('سے'), 1)
        self.assertEqual(B.predicted_pieces('سےس'), 2)
        self.assertEqual(B.predicted_pieces('اس'), 2)


class SplitVerseTest(unittest.TestCase):
    # Text: verse 1 = سس اس (1 + 2 pieces), verse 2 = سس (1 piece).
    # Printed: three verses of 1, 2 and 1 pieces: text verse 1 is printed
    # as verses 1 and 2.
    text = {(1, 1): ['سس', 'اس'], (1, 2): ['سس']}

    def by_verse(self):
        return {
            (1, 1): [segment(1, 0, [(280, 300)])],
            (1, 2): [segment(1, 0, [(240, 250), (200, 230)])],
            (1, 3): [segment(1, 1, [(260, 300)], y=140.0)],
        }

    def test_the_split_verse_is_found_from_the_pieces(self):
        k = W.split_verse(1, {1: 2}, {1: 3}, self.text, self.by_verse())
        self.assertEqual(k, 1)

    def test_words_go_to_the_printed_verse_they_lie_in(self):
        result = W.derive(self.by_verse(), self.text, {1: 3},
                          lambda words: {w: 10.0 for w in words})
        self.assertEqual(sorted(result), [(1, 1), (1, 2), (1, 3)])
        self.assertEqual(result[(1, 1)][1], ['سس'])
        self.assertEqual(result[(1, 2)][1], ['اس'])
        self.assertEqual(result[(1, 3)][1], ['سس'])
        # Word numbers start again in each printed verse; the box spans
        # the word's pieces.
        self.assertEqual(result[(1, 2)][2], [(1, 1, 200.0, 95.0, 250.0, 105.0)])
        self.assertTrue(all(exact for exact, _, _ in result.values()))

    def test_same_count_keeps_the_numbering(self):
        text = {(1, 1): ['سس'], (1, 2): ['اس']}
        by_verse = {
            (1, 1): [segment(1, 0, [(280, 300)])],
            (1, 2): [segment(1, 0, [(240, 250), (200, 230)])],
        }
        result = W.derive(by_verse, text, {1: 2}, lambda words: {w: 10.0 for w in words})
        self.assertEqual({k: v[1] for k, v in result.items()}, {(1, 1): ['سس'], (1, 2): ['اس']})


class PackTest(unittest.TestCase):
    def test_words_json_in_tenths(self):
        out = W.to_json({(2, 5): (True, ['سس', 'اس'], [(1, 3, 10.04, 20.0, 30.06, 40.0),
                                                     (2, 3, 1.0, 2.0, 3.0, 4.0)])})
        self.assertEqual(out['format'], 1)
        self.assertEqual(out['verses'], [[2, 5, 1, 2, [[3, 100, 200, 301, 400], [3, 10, 20, 30, 40]]]])

    def test_pack_keeps_only_verses_whose_words_match_its_text(self):
        built = {
            (1, 1): (True, ['سس', 'اس'], [(1, 1, 0, 0, 1, 1), (2, 1, 0, 0, 1, 1)]),
            (1, 2): (False, ['سس'], [(1, 1, 0, 0, 1, 1)]),
        }
        verses = [
            [1, 1, 1, 1, 1, 1, 'سس اس ' + NUMBER],
            [1, 2, 1, 1, 2, 2, 'سس سس ' + NUMBER],  # another text: left out
            [1, 3, 1, 1, 3, 3, 'سس ' + NUMBER],      # no boxes: left out
        ]
        original = W.build
        W.build = lambda riwaya: built
        try:
            out = build_riwaya_packs.word_boxes('warsh', verses)
        finally:
            W.build = original
        self.assertEqual([v[:2] for v in out['verses']], [[1, 1]])
        self.assertEqual(out['left_out'], [[1, 2], [1, 3]])


if __name__ == '__main__':
    unittest.main()
