"""Tests for the staging tools' parsing logic (no network).

Run: python3 -m unittest discover -s tools/tests
"""
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(TOOLS))

import build_nuqayah_audio_index as nuq  # noqa: E402
import fetch_quranenc_extra as qe  # noqa: E402
import fetch_quranpedia_dumps as qp  # noqa: E402
import inspect_quranpedia_topics as topics  # noqa: E402
import measure_aqqd_coverage as aqqd  # noqa: E402
import staging  # noqa: E402


class StagingTest(unittest.TestCase):
    def test_verse_counts(self):
        self.assertEqual(len(staging.VERSE_COUNTS), 114)
        self.assertEqual(sum(staging.VERSE_COUNTS), 6236)
        vs = list(staging.verses())
        self.assertEqual(vs[0], (1, 1))
        self.assertEqual(vs[-1], (114, 6))
        self.assertIn((2, 286), vs)

    def test_sums_and_manifest(self):
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            (d / 'raw').mkdir()
            (d / 'raw' / 'a.json').write_bytes(b'{}')
            staging.write_sums(d)
            line = (d / 'SHA256SUMS').read_text().strip()
            self.assertEqual(line, staging.sha256_bytes(b'{}') + '  raw/a.json')
            staging.write_manifest(d, source='x')
            self.assertIn('"sha256sums"', (d / 'manifest.json').read_text())


class QuranEncTest(unittest.TestCase):
    def test_audio_url(self):
        self.assertEqual(qe.audio_url('english_rwwad', 2, 255),
                         'https://d.quranenc.com/data/audio/english_rwwad/002255.mp3')
        self.assertEqual(qe.audio_url('english_rwwad', 114, 6),
                         'https://d.quranenc.com/data/audio/english_rwwad/114006.mp3')

    def test_check_sura(self):
        rows = [{'id': str(i), 'sura': '1', 'aya': str(i), 'translation': 't'} for i in range(1, 8)]
        self.assertIs(qe.check_sura({'result': rows}, 1), rows)
        with self.assertRaises(ValueError):
            qe.check_sura({'result': rows[:-1]}, 1)
        with self.assertRaises(ValueError):
            qe.check_sura({'result': rows}, 2)
        with self.assertRaises(ValueError):
            qe.check_sura({'error': 'x'}, 1)

    def test_listed(self):
        payload = {'translations': [{'key': 'english_saheeh', 'version': '1.1.2'}]}
        self.assertEqual(qe.listed(payload, 'english_saheeh')['version'], '1.1.2')
        self.assertIsNone(qe.listed(payload, 'english_mokhtasar'))


class NuqayahTest(unittest.TestCase):
    def test_find_audio_urls(self):
        r = {'data': [{'audio': 'https://a.example/x/001001.mp3'},
                      {'x': 'see //cdn.example/y.m4a?v=2 and https://a.example/x/001001.mp3'}],
             'n': 3}
        self.assertEqual(nuq.find_audio_urls(r),
                         ['https://a.example/x/001001.mp3', '//cdn.example/y.m4a?v=2'])

    def test_find_templates(self):
        js = 'const u=`https://m.example/${book}/${s}.mp3`; f("https://m.example/{s3}{a3}.mp3")'
        self.assertEqual(nuq.find_templates(js),
                         ['https://m.example/${book}/${s}.mp3', 'https://m.example/{s3}{a3}.mp3'])

    def test_fill_and_assign(self):
        self.assertEqual(nuq.fill('https://h/{s3}{a3}.mp3', 2, 5), 'https://h/002005.mp3')
        self.assertEqual(nuq.assign(3, 2, ['u3', 'u4']), {3: 'u3', 4: 'u4'})
        self.assertIsNone(nuq.assign(3, 2, ['u3']))

    def test_page_span(self):
        self.assertEqual(nuq.page_span({'ayahs_start': '6', 'ayahs': [1, 2, 3]}, 7), (6, 3))
        self.assertEqual(nuq.page_span({'ayah': 'x', 'data': []}, 282), (282, 1))


class AqqdTest(unittest.TestCase):
    def test_parse_name(self):
        self.assertEqual(aqqd.parse_name('R023_S5_Surah_036_Aya40_C2.wav'), (23, 5, 36, 40, 2))
        self.assertEqual(aqqd.parse_name('dir/R1_S8_Surah_002_Aya_255_C10.WAV'), (1, 8, 2, 255, 10))
        self.assertIsNone(aqqd.parse_name('readme.txt'))

    def test_qiraat_words_shapes(self):
        nested = {'surahs': [{'surah': 2, 'ayahs': [{'ayah': 4, 'words': [
            {'word_id': 3, 'readings': [{'reader': 'x'}]}, {'word_id': 5}]}]}]}
        self.assertEqual(aqqd.qiraat_words(nested), {(2, 4): {3, 5}})
        keyed = {'2:4': [{'word': 'w1'}, {'word': 'w2'}], '1:1': {'position': 1}}
        self.assertEqual(aqqd.qiraat_words(keyed), {(2, 4): {'w1', 'w2'}, (1, 1): {1}})

    def test_coverage(self):
        words = {(1, 1): {1}, (2, 4): {3, 5}, (3, 1): {2}}
        names = ['R1_S1_Surah_002_Aya4_C1.wav', 'R2_S1_Surah_002_Aya4_C2.wav',
                 'R1_S2_Surah_002_Aya4_C1.wav', 'R1_S2_Surah_003_Aya1_C1.wav',
                 'R3_S2_Surah_009_Aya1_C1.wav', 'notes.txt']
        by, reciters, bad = aqqd.clips_by_style(names)
        self.assertEqual(bad, ['notes.txt'])
        self.assertEqual(reciters, {1: 2, 2: 2})
        rows = aqqd.coverage(words, by)
        self.assertEqual(rows[1], dict(clips=2, verses=1, qiraat_verses=1, qiraat_words=2))
        self.assertEqual(rows[2], dict(clips=3, verses=3, qiraat_verses=2, qiraat_words=3))
        self.assertEqual(rows['any']['qiraat_verses'], 2)
        self.assertEqual(rows['2+'], dict(clips=None, verses=1, qiraat_verses=1, qiraat_words=2))


class TopicsTest(unittest.TestCase):
    TREE = {'topics': [
        {'title': 'A', 'children': [
            {'title': 'A1', 'ayahs': [{'surah': 2, 'ayah': 3, 'ayah_to': 5}]},
            {'title': 'A2', 'verses': ['3:7', '4:1-2'], 'source': 'book'}]},
        {'title': 'B', 'ayahs': [{'sura': 2, 'aya': 4}]}]}

    def test_tree_stats(self):
        st = topics.tree_stats(self.TREE)
        self.assertEqual(st['per_depth'], {1: 2, 2: 2})
        self.assertEqual(st['topics'], 4)
        self.assertEqual(st['leaves'], 3)
        self.assertEqual(st['topics_with_verses'], 3)
        self.assertEqual(st['verses'], 6)  # 2:3-5, 3:7, 4:1-2 (2:4 twice)
        self.assertEqual(st['surahs'], [2, 3, 4])
        self.assertEqual(st['source_fields'], {'source': 1})
        self.assertEqual(st['nodes'][0], (1, 'A', 0, 2))


class QuranpediaDumpsTest(unittest.TestCase):
    def test_matches_recorded(self):
        self.assertTrue(qp.matches_recorded('qiraat.json.gz', 'a7076992' + '0' * 52 + '39ca'))
        self.assertFalse(qp.matches_recorded('qiraat.json.gz', '0' * 64))
        self.assertIsNone(qp.matches_recorded('topics.json.gz', '0' * 64))


if __name__ == '__main__':
    unittest.main()
