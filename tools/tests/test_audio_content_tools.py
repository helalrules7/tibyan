"""Tests for the verse audio index (tools/audio_index.py), the indexes the
staging tools write, and the English tafsir pack (no network).

Run: python3 -m unittest discover -s tools/tests
"""
import json
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(TOOLS))

import audio_index  # noqa: E402
import build_nuqayah_audio_index as nuq  # noqa: E402
import fetch_quranenc_extra as qe  # noqa: E402
import stamp_test_packs as stamp  # noqa: E402
import staging  # noqa: E402

# The fixtures the app's tests read: they must be valid format 1 indexes.
FIXTURES = TOOLS.parent / 'test' / 'fixtures' / 'audio_content'


class AudioIndexTest(unittest.TestCase):
    def test_make_index_sorts_and_validates(self):
        idx = audio_index.make_index(
            'x', 'tafsir_audio', 'nuqayah-tafsir-audio',
            verses=[[2, 2, 'https://h/002002.mp3'], [1, 1, 'https://h/001001.mp3']])
        self.assertEqual(idx['format'], 1)
        self.assertEqual(idx['verses'][0], [1, 1, 'https://h/001001.mp3'])
        self.assertNotIn('surahs', idx)

    def test_surah_files_with_offsets(self):
        idx = audio_index.make_index(
            'x', 'tafsir_audio', 's', surahs=[[1, 'https://h/001.mp3']],
            offsets=[[1, 2, 5000, 9000], [1, 1, 0, 5000]])
        self.assertEqual(idx['offsets'][0], [1, 1, 0, 5000])

    def test_refusals(self):
        def bad(**kw):
            with self.assertRaises(ValueError):
                audio_index.make_index('x', kw.pop('kind', 'tafsir_audio'), 's', **kw)
        bad(verses=[[1, 8, 'https://h/a.mp3']])           # no verse 1:8
        bad(verses=[[1, 1, 'http://h/a.mp3']])            # not https
        bad(verses=[[1, 1, 'https://a'], [1, 1, 'https://b']])  # twice
        bad(kind='video', verses=[[1, 1, 'https://a']])
        bad(surahs=[[1, 'https://a']], offsets=[[2, 1, 0, 10]])  # no surah 2 file
        bad(surahs=[[1, 'https://a']], offsets=[[1, 1, 10, 10]])  # empty span
        bad()                                              # nothing at all

    def test_write(self):
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / 'index.json'
            audio_index.write(path, audio_index.make_index(
                'x', 'translation_audio', 's', verses=[[1, 1, 'https://a']]))
            self.assertEqual(json.loads(path.read_text())['kind'], 'translation_audio')

    def test_app_fixtures_are_valid(self):
        names = sorted(p.name for p in FIXTURES.glob('*.json'))
        self.assertTrue(names)
        for p in FIXTURES.glob('*.json'):
            audio_index.validate(json.loads(p.read_text(encoding='utf-8')))


class ToolPayloadTest(unittest.TestCase):
    def test_rwwad_index(self):
        rows = [[s, a, qe.audio_url(qe.AUDIO_KEY, s, a)] for s, a in staging.verses()]
        idx = qe.audio_payload(rows)
        self.assertEqual(idx['kind'], 'translation_audio')
        self.assertEqual(idx['source'], 'quranenc-english-rwwad-audio')
        self.assertEqual(len(idx['verses']), 6236)
        self.assertEqual(idx['verses'][-1][2],
                         'https://d.quranenc.com/data/audio/english_rwwad/114006.mp3')

    def test_nuqayah_per_verse_and_per_surah(self):
        idx = nuq.index_payload('almuyassar', verses=[[1, 1, 'https://n/1/1.mp3']],
                                unassigned_pages=[])
        self.assertEqual(idx['id'], 'nuqayah-almuyassar')
        self.assertEqual(idx['source'], nuq.SOURCE_KEY)
        self.assertEqual(idx['title_ar'], 'التفسير الميسر')
        per_surah = nuq.index_payload(
            'saadi', surahs=[[s, nuq.fill('https://n/saadi/{s3}.mp3', s, 0)] for s in range(1, 115)])
        self.assertEqual(per_surah['surahs'][1], [2, 'https://n/saadi/002.mp3'])
        self.assertNotIn('verses', per_surah)


class NuqayahTimesTest(unittest.TestCase):
    def _times(self, lines):
        return '|'.join(lines + [''] * (114 - len(lines)))

    def test_offsets_from_times(self):
        # Surah 1 (7 verses): verse 3 has no time of its own (read with 2),
        # verse 7 runs to the end of the file. Surah 2: a short line, its
        # untimed tail shares the last span. Surah 3: no time, no offsets.
        text = self._times(['0.66,97.2,,159.54,195.208,243.54,290.19', '1.5,10'])
        offsets, problems = nuq.offsets_from_times(text, {1: 389634, 2: 50000})
        self.assertEqual(problems, [])
        by = {(s, a): (b, e) for s, a, b, e in offsets}
        self.assertEqual(by[(1, 1)], (660, 97200))
        self.assertEqual(by[(1, 2)], (97200, 159540))
        self.assertEqual(by[(1, 3)], (97200, 159540))
        self.assertEqual(by[(1, 7)], (290190, 389634))
        self.assertEqual(by[(2, 1)], (1500, 10000))
        self.assertEqual(by[(2, 2)], (10000, 50000))
        self.assertEqual(by[(2, 286)], (10000, 50000))
        self.assertFalse(any(s == 3 for s, *_ in offsets))
        # A valid index for the app.
        audio_index.make_index('x', 'tafsir_audio', 's',
                               surahs=[[s, f'https://h/{s:03d}.mp3'] for s in range(1, 115)],
                               offsets=offsets)

    def test_no_duration_no_last_span_and_bad_spans_reported(self):
        offsets, problems = nuq.offsets_from_times(self._times(['5,3,,,,,9']), {})
        # 1:1 runs backwards (reported, left out); 2-6 run to 7; 7 has no end.
        self.assertEqual(offsets, [[1, a, 3000, 9000] for a in range(2, 7)])
        self.assertEqual(problems, [[1, 1, 5000, 3000]])
        with self.assertRaises(ValueError):
            nuq.offsets_from_times('1|2', {})
        with self.assertRaises(ValueError):
            nuq.offsets_from_times(self._times([','.join(['1'] * 8)]), {})


class StampTestPacksTest(unittest.TestCase):
    def test_audio_index(self):
        src = nuq.index_payload('almuyassar', surahs=[[1, 'https://h/001.mp3']])
        out = stamp.stamp_audio_index(src, 'test-nuqayah-almuyassar')
        self.assertEqual(out['id'], 'test-nuqayah-almuyassar')
        self.assertEqual(out['status'], 'test')
        self.assertTrue(out['title_ar'].endswith(stamp.TITLE_MARK_AR))
        self.assertTrue(out['title_en'].endswith(stamp.TITLE_MARK_EN))
        self.assertEqual(out['surahs'], src['surahs'])
        self.assertNotIn('status', src)

    def test_text_pack(self):
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            (d / 'raw').mkdir()
            TextPackTest()._raw(d / 'raw')
            src = d / 'p.pack.db'
            qe.build_text_pack(d / 'raw', src, version='1.0.1')
            out = d / 'test.pack.db'
            index = stamp.stamp_text_pack(src, out)
            self.assertEqual(index['pack_sha256'], staging.sha256_file(out))
            db = sqlite3.connect(out)
            meta = dict(db.execute('SELECT key, value FROM pack_index'))
            self.assertEqual(meta['status'], 'test')
            self.assertTrue(meta['title'].endswith(stamp.TITLE_MARK_EN))
            self.assertEqual(db.execute('SELECT text FROM verse WHERE surah=2 AND ayah=255')
                             .fetchone()[0], 'T 2:255  kept as is ')
            db.close()
            with self.assertRaises(FileExistsError):
                stamp.stamp_text_pack(src, out)


class TextPackTest(unittest.TestCase):
    def _raw(self, d, empty_notes=True):
        for sura, n in enumerate(staging.VERSE_COUNTS, 1):
            rows = [{'id': '0', 'sura': str(sura), 'aya': str(a),
                     'translation': f'T {sura}:{a}  kept as is ',
                     'footnotes': '' if empty_notes or a > 1 else 'note'} for a in range(1, n + 1)]
            (d / f'{sura:03d}.json').write_text(json.dumps({'result': rows}), encoding='utf-8')

    def test_pack(self):
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            (d / 'raw').mkdir()
            self._raw(d / 'raw', empty_notes=False)
            out = d / 'english_mokhtasar.pack.db'
            index = qe.build_text_pack(d / 'raw', out, version='1.0.1')
            self.assertEqual(index['pack_sha256'], staging.sha256_file(out))
            self.assertEqual(index['bytes'], out.stat().st_size)
            saved = json.loads(Path(str(out) + '.index.json').read_text())
            self.assertEqual(saved['pack_sha256'], index['pack_sha256'])
            db = sqlite3.connect(out)
            meta = dict(db.execute('SELECT key, value FROM pack_index'))
            self.assertEqual(meta['format'], '1')
            self.assertEqual(meta['kind'], 'tafsir_text')
            self.assertEqual(meta['version'], '1.0.1')
            self.assertEqual(db.execute('SELECT COUNT(*) FROM verse').fetchone()[0], 6236)
            # Byte for byte, spaces included; empty footnotes are NULL.
            self.assertEqual(db.execute('SELECT text, footnotes FROM verse WHERE surah=2 AND ayah=255')
                             .fetchone(), ('T 2:255  kept as is ', None))
            self.assertEqual(db.execute('SELECT footnotes FROM verse WHERE surah=1 AND ayah=1')
                             .fetchone()[0], 'note')
            db.close()

    def test_refuses_missing_or_empty(self):
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            self._raw(d)
            rows = json.loads((d / '002.json').read_text())['result']
            rows[4]['translation'] = ' '
            (d / '002.json').write_text(json.dumps({'result': rows}))
            with self.assertRaises(ValueError):
                qe.build_text_pack(d, d / 'p.db')
            self._raw(d)
            (d / '114.json').unlink()
            with self.assertRaises(FileNotFoundError):
                qe.build_text_pack(d, d / 'p.db')


if __name__ == '__main__':
    unittest.main()
