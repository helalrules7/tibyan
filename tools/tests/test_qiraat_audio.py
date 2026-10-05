"""Tests for qiraat_audio: building the AQQD verse-level index from an OSF
listing (a fixture: osf.io is not reachable from every environment), and
the checks run on contributors' word ranges.

Run: python3 -m unittest discover -s tools/tests
"""
import io
import json
import shutil
import sys
import tempfile
import unittest
import wave
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(TOOLS))

import qiraat_audio as qa  # noqa: E402

FIXTURE = Path(__file__).parent / 'aqqd_listing_fixture.json'


def wav_bytes(frames, rate=44100):
    buf = io.BytesIO()
    with wave.open(buf, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(b'\0\0' * frames)
    return buf.getvalue()


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.data = self.tmp / 'qiraat_audio'
        self.data.mkdir()
        self.index = self.data / 'index'
        for f in ('styles.json', 'provenance.json'):
            shutil.copy(qa.DATA / f, self.data / f)
        self.provenance = qa.load_json(self.data / 'provenance.json')

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def build(self):
        return qa.build(qa.load_json(FIXTURE), self.provenance, self.index)

    def check(self):
        return qa.check(root=self.index, data=self.data)

    def edit(self, surah, fn):
        path = qa.index_path(surah, self.index)
        doc = qa.load_json(path)
        fn(doc)
        path.write_text(qa.dumps(doc), encoding='utf-8')

    def clip(self, doc, ayah, style, name):
        return next(c for c in doc['verses'][str(ayah)][style] if c['file'] == name)


class BuildTest(Base):
    def test_builds_per_surah_files_from_the_listing(self):
        written, clips, skipped = self.build()
        self.assertEqual((written, clips), (2, 4))
        self.assertEqual(skipped, ['readme.txt', 'R009_S1_Surah_002_Aya3_C1.wav'])  # no URL for the last
        doc = qa.load_json(qa.index_path(36, self.index))
        self.assertEqual(sorted(doc['verses']['40']), ['S2', 'S5'])
        s5 = doc['verses']['40']['S5']
        self.assertEqual([c['clip'] for c in s5], [1, 2])
        self.assertEqual(s5[0]['url'], 'https://osf.io/download/abc02/')  # from the id
        self.assertEqual(s5[1]['path'], '/AQQD/Surah_036/R023_S5_Surah_036_Aya40_C2.wav')
        self.assertEqual({c['group'] for c in s5}, {'unknown'})
        self.assertEqual(self.check(), {})

    def test_groups_come_from_provenance_reciters(self):
        self.provenance['reciters'] = {'R023': 'authors_own'}
        (self.data / 'provenance.json').write_text(json.dumps(self.provenance), encoding='utf-8')
        self.build()
        doc = qa.load_json(qa.index_path(36, self.index))
        self.assertEqual({c['group'] for c in doc['verses']['40']['S5']}, {'authors_own'})
        self.assertEqual(doc['verses']['40']['S2'][0]['group'], 'unknown')
        self.assertEqual(self.check(), {})

    def test_rebuild_keeps_durations_and_word_ranges(self):
        self.build()

        def add(doc):
            c = self.clip(doc, 40, 'S5', 'R023_S5_Surah_036_Aya40_C2.wav')
            c['duration_ms'] = 9999
            c['words'] = [{'range': [100, 900, 2], 'by': 'alice'}]
        self.edit(36, add)
        written, _, _ = self.build()
        self.assertEqual(written, 0)
        c = self.clip(qa.load_json(qa.index_path(36, self.index)), 40, 'S5', 'R023_S5_Surah_036_Aya40_C2.wav')
        self.assertEqual((c['duration_ms'], c['words'][0]['range']), (9999, [100, 900, 2]))

    def test_canonical_layout_is_one_clip_per_line(self):
        self.build()
        text = qa.index_path(36, self.index).read_text(encoding='utf-8')
        self.assertEqual(sum('"file":' in line for line in text.splitlines()), 3)
        self.assertEqual(qa.dumps(json.loads(text)), text)
        self.assertEqual(json.loads(qa.dumps({'surah': 2, 'verses': {}})), {'format': 1, 'surah': 2, 'verses': {}})


class DurationTest(Base):
    def test_header_gives_the_duration(self):
        self.assertEqual(qa.wav_duration_ms(wav_bytes(44100 * 3 // 2)[:8192]), 1500)
        self.assertIsNone(qa.wav_duration_ms(b'ID3 not a wav'))

    def test_durations_fill_missing_only(self):
        self.build()
        n = qa.durations(root=self.index, fetch=lambda url: wav_bytes(44100 * 2))
        self.assertEqual(n, 4)
        doc = qa.load_json(qa.index_path(1, self.index))
        self.assertEqual(doc['verses']['4']['S2'][0]['duration_ms'], 2000)
        self.assertEqual(qa.durations(root=self.index, fetch=lambda url: 1 / 0), 0)


class CheckTest(Base):
    NAME = 'R023_S5_Surah_036_Aya40_C2.wav'  # 882,044 bytes: at most 10,000 ms

    def setUp(self):
        super().setUp()
        self.build()

    def words(self, words, **clip):
        def fn(doc):
            c = self.clip(doc, 40, 'S5', self.NAME)
            c['words'] = words
            c.update(clip)
        self.edit(36, fn)
        return [e for errs in self.check().values() for e in errs]

    def test_good_ranges_pass(self):
        errs = self.words([{'range': [100, 900, 2], 'by': 'alice', 'reviewed_by': 'bob'},
                           {'range': [900, 1500, 3], 'by': 'alice'}])
        self.assertEqual(errs, [])

    def test_word_must_exist_in_the_verse(self):
        n = qa.verse_words()[35][39]
        errs = self.words([{'range': [100, 900, n + 1], 'by': 'alice'}])
        self.assertTrue(any(f'the verse has {n} words' in e for e in errs), errs)
        self.assertTrue(any('verse has' in e for e in self.words([{'range': [100, 900, 0], 'by': 'a'}])))

    def test_range_inside_the_clip(self):
        self.assertTrue(any('past the clip (10000 ms)' in e for e in self.words([{'range': [100, 10001, 1], 'by': 'a'}])))
        self.assertTrue(any('past the clip (3000 ms)' in e
                            for e in self.words([{'range': [100, 3001, 1], 'by': 'a'}], duration_ms=3000)))
        self.assertTrue(any('start must be before end' in e for e in self.words([{'range': [900, 900, 1], 'by': 'a'}])))
        self.assertTrue(any('no duration or size' in e
                            for e in self.words([{'range': [1, 2, 1], 'by': 'a'}], size=None, duration_ms=None)))

    def test_no_overlaps(self):
        errs = self.words([{'range': [100, 900, 2], 'by': 'a'}, {'range': [800, 1500, 3], 'by': 'a'}])
        self.assertTrue(any('words 2 and 3 overlap' in e for e in errs), errs)

    def test_schema(self):
        self.assertTrue(any('"range": [start_ms' in e for e in self.words([{'range': [1, 2], 'by': 'a'}])))
        self.assertTrue(any('"by"' in e for e in self.words([{'range': [1, 2, 1]}])))
        self.assertTrue(any('second person' in e
                            for e in self.words([{'range': [1, 2, 1], 'by': 'Ali', 'reviewed_by': 'ali'}])))
        self.assertTrue(any('unknown keys' in e for e in self.words([], note='x')))
        self.assertTrue(any('https link on osf.io' in e for e in self.words([], url='http://example.com/a.wav')))
        self.assertTrue(any("group must be 'unknown'" in e for e in self.words([], group='authors_own')))

    def test_verse_must_exist_and_match_the_name(self):
        def fn(doc):
            doc['verses']['84'] = doc['verses'].pop('40')
        self.edit(36, fn)
        errs = [e for es in self.check().values() for e in es]
        self.assertTrue(any('no such verse' in e for e in errs), errs)

        def back(doc):
            doc['verses']['41'] = doc['verses'].pop('84')
        self.edit(36, back)
        errs = [e for es in self.check().values() for e in es]
        self.assertTrue(any('the name says S5 36:40' in e for e in errs), errs)

    def test_layout_and_style_map(self):
        path = qa.index_path(36, self.index)
        path.write_text(json.dumps(qa.load_json(path)), encoding='utf-8')
        self.assertIn('canonical', self.check()[path.as_posix()][0])
        styles = qa.load_json(self.data / 'styles.json')
        styles['styles']['S5'] = {'name': 'guess'}
        (self.data / 'styles.json').write_text(json.dumps(styles), encoding='utf-8')
        self.assertIn('styles.json', self.check())

    def test_repository_index_is_valid(self):
        self.assertEqual(qa.check(), {})


if __name__ == '__main__':
    unittest.main()
