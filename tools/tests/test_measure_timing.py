"""Tests for measure_timing.py (the timing-measure workflow's tool) and the
verse alignment it adds to build_aligned_timing.py. The model is not
needed: the alignment is tried on made-up letter probabilities.

Run: python3 -m unittest discover -s tools/tests   (needs numpy; the
alignment tests also torch and torchaudio, and skip without them)
"""
import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(TOOLS))

HAVE_NUMPY = importlib.util.find_spec('numpy') is not None
HAVE_TORCH = HAVE_NUMPY and all(importlib.util.find_spec(m) is not None for m in ('torch', 'torchaudio'))

if HAVE_NUMPY:
    import numpy as np
    import build_aligned_timing as al
    import measure_timing as mt
    import timing_files as tf


@unittest.skipUnless(HAVE_NUMPY, 'needs numpy')
class SpecTest(unittest.TestCase):
    def test_surahs(self):
        self.assertEqual(mt.parse_surahs('1,9,21-23', 'sudais'), [1, 9, 21, 22, 23])
        self.assertEqual(len(mt.parse_surahs('all', 'sudais')), 114)
        missing = mt.parse_surahs('missing', 'mustafa-ismail')
        self.assertEqual(len(missing), 57)
        self.assertNotIn(1, missing)
        # Mohammad Sayed (Warsh): the 50 surahs whose published timing counts as Hafs does
        self.assertEqual(len(mt.parse_surahs('missing', 'warsh-msayed-105')), 50)
        self.assertEqual(mt.parse_surahs('missing', 'warsh-abdulbasit-106'), list(range(1, 115)))

    def test_verses(self):
        sudais = mt.reciter('sudais')
        self.assertEqual(mt.parse_verses('2:3,1:5', sudais), [(1, 5), (2, 3)])
        flagged = mt.parse_verses('flagged', sudais)
        self.assertEqual(len(flagged), 39)          # MISSING_DATA ث13
        self.assertIn((37, 78), flagged)
        known = mt.parse_verses('known', mt.reciter('abdulbasit'))
        self.assertEqual(len(known), 9)             # the overlaps fix-known leaves
        self.assertIn((48, 15), known)

    def test_plan_covers_the_spec_once(self):
        r = mt.reciter('tablawi')
        for mode, spec in (('surahs', 'all'), ('verses', 'flagged')):
            parts = mt.plan(mode, r, spec, 5)
            self.assertLessEqual(len(parts), 5)
            items = [x for p in parts for x in mt.spec_items(mode, r, p)]
            self.assertEqual(sorted(items), mt.spec_items(mode, r, spec))
        # the five ث13 reciters: 399 verses without words
        total = sum(len(mt.parse_verses('flagged', mt.reciter(s)))
                    for s in ('dosari', 'sudais', 'afasy', 'ghamdi', 'tablawi'))
        self.assertEqual(total, 399)

    def test_pack_hash_is_the_apps(self):
        for riwaya in ('warsh', 'qalun', 'douri', 'shubah'):
            self.assertRegex(mt.pack_sha(riwaya), '^[0-9a-f]{64}$')

    def test_doc_of(self):
        doc = mt.doc_of('sudais', 112, [(0, 0, 900), (1, 900, 2000)], [(1, 1, 950, 1500), (1, 2, 1500, 1990)], False)
        self.assertEqual(doc['verses'], [[0, 0, 900, []], [1, 900, 2000, [[1, 950, 1500], [2, 1500, 1990]]]])
        riwaya = mt.doc_of('x', 1, [(1, 0, 900)], [(1, 1, 0, 800)], True)
        self.assertEqual(riwaya['verses'], [[1, 0, 900, []]])

    def test_credit(self):
        doc = tf.load_json(tf.DATA / 'reciters.json')
        new = mt.credit(json.loads(json.dumps(doc)), 'warsh-abdulbasit-106', 'surahs', [1, 2, 3], [], False, '2026-10-05')
        r = next(x for x in new['reciters'] if x['slug'] == 'warsh-abdulbasit-106')
        self.assertTrue(r['publish'])
        self.assertEqual(r['verse_timing']['attribution'], 'Tibyan')
        self.assertEqual(r['verse_timing']['licence'], mt.LICENCE)
        self.assertIn('1-3', r['note'])
        part = mt.credit(json.loads(json.dumps(doc)), 'abdulbasit', 'verses', [], [(48, 15)], True, '2026-10-05')
        r = next(x for x in part['reciters'] if x['slug'] == 'abdulbasit')
        self.assertEqual(r['measured']['word_verses'], ['48:15'])
        self.assertIn('quran-align', r['word_timing']['source'])
        self.assertIn('Tibyan', r['word_timing']['attribution'])
        self.assertNotIn('Tibyan', r['verse_timing']['attribution'])
        mi = mt.credit(json.loads(json.dumps(doc)), 'mustafa-ismail', 'surahs', [2, 3], [], True, '2026-10-05')
        r = next(x for x in mi['reciters'] if x['slug'] == 'mustafa-ismail')
        self.assertEqual(r['measured']['surahs'], [2, 3])
        self.assertEqual(r['word_timing']['attribution'], 'Tibyan')

    def test_riwaya_letters_are_read(self):
        self.assertEqual(al.letters('ڢِى'), ['ف', 'ى'])
        self.assertEqual(al.letters('ٱلۡحَمۡدُ'), ['ا', 'ل', 'ح', 'م', 'د'])


@unittest.skipUnless(HAVE_TORCH, 'needs torch and torchaudio')
class AlignVerseTest(unittest.TestCase):
    """A made-up verse of two words, ab and cd, in 2 s of frames: silence,
    a, b, silence, c, d, silence."""

    def test_words_land_on_their_letters(self):
        ids = {'<pad>': 0, 'ا': 1, 'ب': 2, 'ت': 3, 'ث': 4}
        lay = [0] * 10 + [1] * 8 + [2] * 8 + [0] * 20 + [3] * 8 + [4] * 8 + [0] * 38
        e = np.full((len(lay), 5), -8.0, np.float32)
        for t, k in enumerate(lay):
            e[t, k] = -0.05
        v = al.align_verse(e, ['اب', 'تث'], ids)
        self.assertIsNotNone(v)
        (s1, e1, sc1), (s2, e2, sc2) = v
        self.assertTrue(9 <= s1 <= 11 and 25 <= e1 <= 27, v)
        self.assertTrue(45 <= s2 <= 47 and 61 <= e2 <= 63, v)
        self.assertGreater(min(sc1, sc2), al.MIN_SCORE)
        # in ms, a verse window from frame 0 to 2 s, a pause heard at 1300 ms
        spans = al.word_spans(v, 0, 2000, [(1300, 2000)])
        self.assertEqual(spans[0], (s1 * 20, s2 * 20))
        self.assertEqual(spans[1], (s2 * 20, 1300))

    def test_window_too_short(self):
        ids = {'<pad>': 0, 'ا': 1, 'ب': 2}
        self.assertIsNone(al.align_verse(np.zeros((3, 3), np.float32), ['ابابا'], ids))


@unittest.skipUnless(HAVE_NUMPY, 'needs numpy')
class FinishTest(unittest.TestCase):
    def test_finish_assembles_and_checks(self):
        src = tf.load_json(tf.surah_path('sudais', 112))
        with tempfile.TemporaryDirectory() as tmp:
            shard = Path(tmp) / 'shard-1'
            (shard / 'timing' / 'sudais').mkdir(parents=True)
            (shard / 'timing' / 'sudais' / '112.json').write_text(tf.dumps(src), encoding='utf-8')
            (shard / 'result.json').write_text(json.dumps({
                'mode': 'surahs', 'slug': 'sudais', 'surahs': {'112': {
                    'audio': tf.load_json(tf.DATA / 'sudais' / 'audio.json')['files']['112'],
                    'verses': 4, 'with_words': 4, 'flagged': []}}}), encoding='utf-8')
            out = Path(tmp) / 'out'
            self.assertEqual(mt.finish('surahs', 'sudais', [shard], out), 0)
            self.assertEqual((out / 'data/timing/sudais/112.json').read_text(encoding='utf-8'), tf.dumps(src))
            self.assertFalse((out / 'data/timing/sudais/audio.json').exists(), 'no new audio file')
            report = (out / 'REPORT.md').read_text(encoding='utf-8')
            self.assertIn('| 112 | 4 | 4 |', report)
            rec = tf.load_json(out / 'data/timing/reciters.json')
            r = next(x for x in rec['reciters'] if x['slug'] == 'sudais')
            self.assertEqual(r['measured']['surahs'], [112])


if __name__ == '__main__':
    unittest.main()
