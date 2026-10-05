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
