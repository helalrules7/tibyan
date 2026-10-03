"""Tests for timing_files: the format, the checks, and that the files give
content.db exactly the rows it had.

Run: python3 -m unittest discover -s tools/tests
"""
import gzip
import hashlib
import json
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(TOOLS))

import timing_files as tf  # noqa: E402

CASES = json.loads((Path(__file__).parent / 'timing_cases.json').read_text(encoding='utf-8'))


def key(i):
    return f'{i["level"]}:{i["code"]}:{"" if i["verse"] is None else i["verse"]}:{i["word"] or ""}'


def have_db():
    """content.db is in Git LFS; a checkout without LFS has a pointer."""
    return tf.DB.exists() and tf.DB.read_bytes()[:15] == b'SQLite format 3'


class ValidateTest(unittest.TestCase):
    def test_shared_cases(self):
        for case in CASES['cases']:
            with self.subTest(case['name']):
                got = sorted(key(i) for i in tf.validate(
                    case['doc'], CASES['slug'], CASES['surah'], CASES['counts'], case['duration_ms']))
                self.assertEqual(got, case['expect'])


class FilesTest(unittest.TestCase):
    def test_every_published_file_is_canonical_and_valid(self):
        counts = tf.verse_words()
        for slug in tf.published():
            durations = tf.durations(slug)
            files = sorted((tf.DATA / slug).glob('[0-9][0-9][0-9].json'))
            self.assertTrue(files, slug)
            for path in files:
                text = path.read_text(encoding='utf-8')
                doc = json.loads(text)
                self.assertEqual(text, tf.dumps(doc), path.name)
                errors = [i for i in tf.validate(doc, slug, doc['surah'], counts[doc['surah']],
                                                 durations.get(doc['surah'])) if i['level'] == 'error']
                self.assertEqual(errors, [], f'{slug}/{path.name}')

    def test_only_publishable_reciters_have_files(self):
        listed = {r['slug']: r for r in tf.reciters()}
        self.assertEqual(len(listed), len(tf.reciters()), 'slugs are unique')
        for d in tf.DATA.iterdir():
            if d.is_dir():
                r = listed.get(d.name)
                self.assertIsNotNone(r, d.name)
                self.assertEqual(r['licence'], 'publishable', d.name)
                self.assertTrue(r['publish'], d.name)
        for r in listed.values():
            if r['publish']:
                self.assertEqual(r['licence'], 'publishable', r['slug'])
                self.assertTrue((tf.DATA / r['slug'] / 'audio.json').exists(), r['slug'])

    def test_check_marks_old_errors_and_changes(self):
        with tempfile.TemporaryDirectory() as base:
            rel = 'data/timing/sudais/001.json'
            (Path(base) / rel).parent.mkdir(parents=True)
            doc = tf.load_json(tf.REPO / rel)
            changed = json.loads(json.dumps(doc))
            changed['verses'][1][3][0][2] += 10
            (Path(base) / rel).write_text(tf.dumps(changed), encoding='utf-8')
            r = tf.check_file(rel, base)
            self.assertEqual(r['changed_verses'], [2])
            self.assertEqual(r['changed_words'], 1)

    def test_pack_is_deterministic_and_complete(self):
        with tempfile.TemporaryDirectory() as out:
            m1 = tf.pack(out, versions={s: 7 for s in tf.published()})
            m2 = tf.pack(out, versions={s: 7 for s in tf.published()})
            self.assertEqual(m1, m2)
            for e in m1['reciters']:
                data = (Path(out) / e['file']).read_bytes()
                self.assertEqual(hashlib.sha256(data).hexdigest(), e['sha256'])
                body = json.loads(gzip.decompress(data))
                self.assertEqual(body['version'], 7)
                self.assertEqual(len(body['surahs']), len(list((tf.DATA / e['slug']).glob('[0-9]*.json'))))


@unittest.skipUnless(have_db(), 'content.db not fetched (git lfs pull)')
class ContentDbTest(unittest.TestCase):
    """The files are the source of truth: build_content_db.py puts their
    rows in, and they must be the rows the database already has."""

    def setUp(self):
        self.db = sqlite3.connect(f'file:{tf.DB}?mode=ro', uri=True)

    def tearDown(self):
        self.db.close()

    def test_rows_are_identical(self):
        for slug, r in tf.published().items():
            ayahs, words = tf.reciter_rows(slug, r['id'])
            db_ayahs = self.db.execute('SELECT * FROM ayah_timing WHERE reciter = ? ORDER BY surah, ayah',
                                       (r['id'],)).fetchall()
            db_words = self.db.execute('SELECT * FROM word_timing WHERE reciter = ? ORDER BY surah, ayah, word',
                                       (r['id'],)).fetchall()
            self.assertEqual(sorted(ayahs), db_ayahs, slug)
            self.assertEqual(sorted(words), db_words, slug)

    def test_apply_keeps_the_rows(self):
        mem = sqlite3.connect(':memory:')
        self.db.backup(mem)
        before = mem.execute('SELECT COUNT(*), SUM(start_ms), SUM(end_ms) FROM word_timing').fetchone()
        done = tf.apply(mem)
        self.assertIn('sudais', done)
        after = mem.execute('SELECT COUNT(*), SUM(start_ms), SUM(end_ms) FROM word_timing').fetchone()
        self.assertEqual(before, after)
        version = mem.execute("SELECT value FROM meta WHERE key = 'timing_version:sudais'").fetchone()
        self.assertIsNotNone(version)

    def test_verse_words_match_word_boxes(self):
        counts = tf.verse_words()
        for s, a, n in self.db.execute('SELECT surah, ayah, COUNT(*) FROM word_box GROUP BY surah, ayah'):
            self.assertEqual(counts[s][a - 1], n, (s, a))
        self.assertEqual(sum(len(c) for c in counts.values()), 6236)

    def test_editor_words_are_the_app_words(self):
        counts = tf.verse_words()
        for s, a, text in self.db.execute('SELECT surah, number, display_text FROM ayah'):
            words, number = tf._display_words(text)
            self.assertEqual(len(words), counts[s][a - 1], (s, a))
            # Nothing added or dropped but the separators and the hizb sign.
            rebuilt = ' '.join(words)
            self.assertEqual(rebuilt.replace(' ', ''),
                             text[:len(text) - len(number) - 1].replace(' ', '').replace(' ', '')
                             .replace(tf.HIZB, ''), (s, a))


if __name__ == '__main__':
    unittest.main()
