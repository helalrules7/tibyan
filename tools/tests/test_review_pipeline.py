"""Tests for the review pipeline: import splitting, link suggestions,
the content hash, and pack export.

Run: python3 -m unittest discover -s tools/tests

The fixture book is made of placeholder sentences («نص تجريبي») around
quotations copied verbatim from the Tanzil simple-clean text; it imitates
the OpenITI layout only.
"""
import json
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(TOOLS))

import export_pack  # noqa: E402
import import_wahidi_asbab as imp  # noqa: E402
import review_db  # noqa: E402

CONTENT_DB = TOOLS.parent / 'assets' / 'db' / 'content.db'

FIXTURE = """######OpenITI#

#META# 040.EdEDITOR\t:: محقق تجريبي
#META#Header#End#

### | مقدمة المؤلف
# نص تجريبي في المقدمة PageV01P003
# نص تجريبي ثان
~~يكمل السطر ms001 هنا
### | سورة الفاتحة
# بسم الله الرحمن الرحيم PageV01P004
### | سورة البقرة
# نص تجريبي عن السورة كلها
# (1) - قوله تعالى: {الم ذلك الكتاب} {1، 2} .
# نص تجريبي للرواية الأولى PageV01P005
# نص تجريبي يكمل الرواية
# قوله - عز وجل - {إن الذين كفروا سواء عليهم}
# {6} .
# نص تجريبي للرواية الثانية
### | .....
# قوله تعالى: {يا أيها الناس اعبدوا ربكم} .
# نص تجريبي للرواية الثالثة PageV01P006
### | سورة بني إسرائيل
# قوله تعالى: {ولا تجعل يدك مغلولة إلى عنقك} الآية {29} .
# نص تجريبي PageV01P007
"""


def verses():
    db = sqlite3.connect(f'file:{CONTENT_DB}?mode=ro', uri=True)
    counts = dict(db.execute('SELECT id, ayah_count FROM surah'))
    names = dict(db.execute('SELECT id, name_ar FROM surah'))
    v = imp.Verses(db.execute(
        'SELECT surah, number, text_search, search_basmala_prefix FROM ayah'), counts)
    db.close()
    return v, names


@unittest.skipUnless(CONTENT_DB.exists(), 'assets/db/content.db (Git LFS) is needed')
class ImportSplitTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.verses, names = verses()
        cls.meta, events = imp.parse_openiti(FIXTURE)
        cls.entries = imp.split_entries(events, imp.surah_resolver(names))

    def test_reads_edition_metadata(self):
        self.assertEqual(self.meta['040.EdEDITOR'], 'محقق تجريبي')

    def test_splits_by_the_books_own_sections_and_headers(self):
        kinds = [(e['kind'], e['section']) for e in self.entries]
        self.assertEqual(kinds, [
            ('front_matter', 'مقدمة المؤلف'),
            ('surah_intro', 'سورة الفاتحة'),
            ('surah_intro', 'سورة البقرة'),
            ('passage', 'سورة البقرة'),
            ('passage', 'سورة البقرة'),
            ('passage', 'سورة البقرة'),   # the "....." heading is not a section
            ('passage', 'سورة بني إسرائيل'),
        ])
        self.assertEqual([e['surah'] for e in self.entries], [None, 1, 2, 2, 2, 2, 17])

    def test_keeps_every_word_and_drops_only_markup(self):
        imp.check_verbatim(FIXTURE, self.entries)  # raises on any difference
        self.assertEqual(self.entries[0]['text'], 'نص تجريبي في المقدمة\nنص تجريبي ثان يكمل السطر هنا')
        for e in self.entries:
            self.assertNotIn('PageV', e['text'])
            self.assertNotIn('ms00', e['text'])

    def test_pages_come_from_the_page_tags(self):
        first, _, _, p1, p2, p3, p4 = self.entries
        self.assertEqual((first['page'], first['page_end']), (3, 4))
        self.assertEqual((p1['page'], p1['page_end']), (5, 6))  # text after tag 5 is on page 6
        self.assertEqual((p4['page'], p4['page_end']), (7, 7))

    def test_header_wrapping_into_next_paragraph_keeps_its_marker(self):
        self.assertEqual(imp.parse_header(self.entries[4]['header']),
                         ('إن الذين كفروا سواء عليهم', (6, 6)))

    def test_links_from_markers_and_quotations(self):
        got = [imp.suggest_links(e, self.verses)[0] for e in self.entries]
        self.assertEqual(got[0], [])
        self.assertEqual(got[1], [])  # basmala only
        self.assertEqual((got[2][0]['ayah_from'], got[2][0]['ayah_to'], got[2][0]['confidence']),
                         (1, 286, 0.5))
        link = got[3][0]
        self.assertEqual((link['surah'], link['ayah_from'], link['ayah_to'], link['basis'],
                          link['confidence']), (2, 1, 2, 'marker+quote', 0.95))
        self.assertEqual((got[4][0]['ayah_from'], got[4][0]['basis']), (6, 'marker+quote'))
        # no verse number: found by the quotation alone
        self.assertEqual((got[5][0]['ayah_from'], got[5][0]['basis'], got[5][0]['confidence']),
                         (21, 'quote', 0.75))
        self.assertEqual((got[6][0]['surah'], got[6][0]['ayah_from']), (17, 29))

    def test_wrong_printed_number_is_flagged_not_trusted(self):
        entry = {'kind': 'passage', 'surah': 2, 'text': '',
                 'header': 'قوله تعالى: {الم ذلك الكتاب} {200} .'}
        links, notes = imp.suggest_links(entry, self.verses)
        self.assertEqual((links[0]['ayah_from'], links[0]['basis'], links[0]['confidence']),
                         (1, 'quote', 0.6))
        self.assertTrue(notes)

    def test_spelling_differences_still_match(self):
        self.assertTrue(imp.same_word('يرجوا', 'يرجو'))
        self.assertTrue(imp.same_word('تحي', 'تحيي'))
        self.assertFalse(imp.same_word('من', 'ما'))

    def test_never_writes_text_it_did_not_read(self):
        source_words = imp.body_words(FIXTURE)
        for e in self.entries:
            for w in e['text'].split():
                self.assertIn(w, source_words)


class ContentHashTest(unittest.TestCase):
    # The same values are asserted in apps/review/test/content_hash_test.dart.
    def test_fixed_vectors(self):
        links = [{'surah': 2, 'ayah_from': 3, 'ayah_to': 4},
                 {'surah': 2, 'ayah_from': 1, 'ayah_to': 1, 'word_from': 2, 'word_to': 5}]
        self.assertEqual(
            review_db.content_hash('test_book', 1, 2, 3, 'نص أول\nسطر ثان', links),
            '09a74b286bb472b432c75ff4244a1e3a812f68bae87e0dc6129478c6d4c1cc7e')
        self.assertEqual(review_db.content_hash('test_book', None, None, None, 'x', []),
                         'd139698903294aec7b3d2958e0d849b5e0ea9fd8444a42ad5a5673910883a9cb')

    def test_link_order_does_not_matter(self):
        a = [{'surah': 1, 'ayah_from': 1, 'ayah_to': 1}, {'surah': 2, 'ayah_from': 5, 'ayah_to': 6}]
        self.assertEqual(review_db.content_hash('k', 1, 1, 1, 't', a),
                         review_db.content_hash('k', 1, 1, 1, 't', list(reversed(a))))


@unittest.skipUnless(CONTENT_DB.exists(), 'assets/db/content.db (Git LFS) is needed')
class ExportPackTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)
        self.path = self.dir / 'r.review.db'
        db = review_db.create(self.path, CONTENT_DB)
        sid = review_db.add_source(db, {
            'key': 'test_book', 'kind': 'asbab_nuzul', 'title': 'كتاب تجريبي', 'author': 'مؤلف',
            'licence': 'test', 'url': 'about:blank', 'file': 'f', 'sha256': '0' * 64,
            'retrieved_at': '2026-10-02'})
        self.ids = []
        for seq in (1, 2, 3):
            e = {'seq': seq, 'kind': 'passage', 'section': 'سورة البقرة', 'volume': 1,
                 'page': seq, 'page_end': seq, 'text': f'نص تجريبي {seq}'}
            links = [{'surah': 2, 'ayah_from': seq, 'ayah_to': seq, 'basis': 'marker',
                      'confidence': 0.95}]
            self.ids.append(review_db.add_draft(db, sid, 'test_book', e, links, 'script:test'))
        db.commit()
        self.db = db

    def tearDown(self):
        self.db.close()
        self.tmp.cleanup()

    def act(self, entry_id, actor, role, action, to_state, **cols):
        """Writes what the review tool writes for one action."""
        h = self.db.execute('SELECT content_hash, state FROM entry WHERE id = ?', (entry_id,)).fetchone()
        sets = ', '.join(f'{k} = ?' for k in cols)
        self.db.execute(f'UPDATE entry SET state = ?{", " + sets if sets else ""} WHERE id = ?',
                        (to_state, *cols.values(), entry_id))
        self.db.execute(
            'INSERT INTO audit (entry_id, at, actor, role, action, from_state, to_state, '
            'hash_before, hash_after) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
            (entry_id, review_db.now(), actor, role, action, h[1], to_state, h[0], h[0]))
        self.db.commit()

    def review(self, entry_id, editor='محرر', reviewer='مراجع'):
        self.act(entry_id, editor, 'editor', 'submit', 'in_review', editor=editor)
        self.act(entry_id, reviewer, 'reviewer', 'approve', 'reviewed', reviewer=reviewer,
                 reviewed_at=review_db.now())

    def test_exports_only_reviewed_rows_with_an_index(self):
        self.review(self.ids[0])
        self.act(self.ids[1], 'محرر', 'editor', 'submit', 'in_review', editor='محرر')
        out = self.dir / 'p.pack.db'
        index = export_pack.export(self.path, out)
        pack = sqlite3.connect(out)
        self.assertEqual(pack.execute('SELECT id FROM entry').fetchall(), [(self.ids[0],)])
        self.assertEqual(pack.execute('SELECT surah, ayah_from FROM entry_link').fetchall(), [(2, 1)])
        self.assertEqual(index['entries'], 1)
        self.assertEqual(index['reviewers'], ['مراجع'])
        self.assertEqual(json.loads(dict(pack.execute('SELECT * FROM pack_index'))['entries']), 1)
        side = json.loads((self.dir / 'p.pack.db.index.json').read_text(encoding='utf-8'))
        self.assertEqual(side['pack_sha256'], review_db.sha256_file(out))
        text = pack.execute('SELECT text FROM entry').fetchone()[0]
        self.assertEqual(text, 'نص تجريبي 1')

    def test_refuses_when_nothing_is_reviewed(self):
        with self.assertRaises(export_pack.ExportError):
            export_pack.export(self.path, self.dir / 'p.pack.db')

    def test_refuses_content_changed_after_review(self):
        self.review(self.ids[0])
        self.db.execute('UPDATE entry_link SET ayah_from = 7, ayah_to = 7 WHERE entry_id = ?',
                        (self.ids[0],))
        self.db.commit()
        with self.assertRaisesRegex(export_pack.ExportError, 'hash mismatch'):
            export_pack.export(self.path, self.dir / 'p.pack.db')

    def test_refuses_review_without_audit_approval(self):
        self.act(self.ids[0], 'محرر', 'editor', 'submit', 'in_review', editor='محرر')
        self.db.execute("UPDATE entry SET state = 'reviewed', reviewer = 'مراجع', "
                        "reviewed_at = 'x' WHERE id = ?", (self.ids[0],))
        self.db.commit()
        with self.assertRaisesRegex(export_pack.ExportError, 'audit'):
            export_pack.export(self.path, self.dir / 'p.pack.db')

    def test_schema_enforces_the_rules(self):
        with self.assertRaises(sqlite3.IntegrityError):  # reviewer == editor
            self.db.execute("UPDATE entry SET state = 'reviewed', editor = 'أ', reviewer = 'أ' "
                            'WHERE id = ?', (self.ids[0],))
        for sql in ('UPDATE audit SET actor = 1', 'DELETE FROM audit',
                    f'DELETE FROM entry WHERE id = {self.ids[0]}',
                    f"UPDATE entry SET text = 'x' WHERE id = {self.ids[0]}"):
            with self.assertRaises(sqlite3.IntegrityError, msg=sql):
                self.db.execute(sql)


CACHED = TOOLS / '.cache' / '0468IbnAhmadWahidiNaysaburi.AsbabNuzul.Shamela0011314-ara1'


@unittest.skipUnless(CACHED.exists() and CONTENT_DB.exists(), 'run fetch_sources.py first')
class RealBookTest(unittest.TestCase):
    def test_whole_book_splits_verbatim(self):
        v, names = verses()
        raw = CACHED.read_text(encoding='utf-8')
        _, events = imp.parse_openiti(raw)
        entries = imp.split_entries(events, imp.surah_resolver(names))
        imp.check_verbatim(raw, entries)
        passages = [e for e in entries if e['kind'] == 'passage']
        self.assertGreater(len(passages), 400)
        linked = sum(1 for e in passages if imp.suggest_links(e, v)[0])
        self.assertEqual(linked, len(passages))


if __name__ == '__main__':
    unittest.main()
