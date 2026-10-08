"""Tests for the altafsir.com tafsir importer (import_altafsir.py) and the
al-Damghani wujuh importer (import_damghani_wujuh.py).

Run: python3 -m unittest discover -s tools/tests

The fixtures are made of placeholder sentences («نص تجريبي») around
quotations copied verbatim from the Tanzil simple-clean text; they imitate
the OpenITI layout of each source only.
"""
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(TOOLS))

import import_altafsir as alt  # noqa: E402
import import_damghani_wujuh as dam  # noqa: E402
import review_db  # noqa: E402
from import_wahidi_asbab import body_words, check_verbatim, parse_openiti  # noqa: E402

CONTENT_DB = TOOLS.parent / 'assets' / 'db' / 'content.db'
NEEDS_DB = unittest.skipUnless(CONTENT_DB.exists(), 'assets/db/content.db (Git LFS) is needed')

ALTAFSIR = """﻿######OpenITI#


#META# Author: مؤلف تجريبي
#META# Source: altafsir.com

#META#Header#End#

### | [1 - سورة الفاتحة]

### || [1.1-7]

# نص تجريبي { الحمد لله رب العالمين } نص تجريبي
~~يكمل ms0001 السطر

### | [2 ms0002 - سورة البقرة]

# نص تجريبي قبل أول مجموعة

### || [2.1-2]

# نص تجريبي { ذلك الكتاب لا ريب فيه } نص

### || [2.3] ms0003

# نص تجريبي بلا اقتباس

### || [2.4]

# نص تجريبي { يؤمنون } نص

### || [2.7]

# نص تجريبي { يا أيها الناس اعبدوا ربكم }

### || [2.300]

# نص تجريبي
"""

DAMGHANI = """######OpenITI#

#META# المحقق: عبد العزيز سيد الأهل
#META# دار النشر: دار العلم للملايين
#META#Header#End#

ملاحظة تجريبية
PageV01P012
### | CHECK [13-89]
# باب الهمزة
# أب على أربعة أوجه
# معنى . معنى
# فوجه منها : نص تجريبي قوله تعالى في سورة الحج " ملة أبيكم إبراهيم " نص
# الثاني : نص تجريبي هو على وجهين في سورة البقرة " نص غير موجود في الآية " @ PageV01P013
~~الثالث : نص تجريبي قوله تعالى في سورة عبس وفاكهة وأبا نص تجريبي ج ب ر على أربعة
~~أوجه معنى معنى فوجه منها نص في سورة الحشر هو الله الذي لا إله إلا هو الملك نص
~~الثاني نص تجريبي في سورة النساء (( يا أيها الناس اتقوا ربكم )) نص
# @
PageV01P014
"""


class AltafsirSplitTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        _, events = parse_openiti(ALTAFSIR)
        cls.entries = alt.split_entries(events)

    def test_headings(self):
        self.assertEqual(alt.parse_heading('[2 ms0002 - سورة البقرة]'), ('surah', 2, 'سورة البقرة'))
        self.assertEqual(alt.parse_heading('[2.1-5]'), ('verses', 2, 1, 5))
        self.assertEqual(alt.parse_heading('[2.3] ms0003'), ('verses', 2, 3, 3))
        self.assertIsNone(alt.parse_heading('CHECK'))

    def test_splits_at_altafsir_headings(self):
        got = [(e['kind'], e['section'], e['range']) for e in self.entries]
        self.assertEqual(got, [
            ('passage', 'سورة الفاتحة', (1, 1, 7)),
            ('surah_intro', 'سورة البقرة', None),
            ('passage', 'سورة البقرة', (2, 1, 2)),
            ('passage', 'سورة البقرة', (2, 3, 3)),
            ('passage', 'سورة البقرة', (2, 4, 4)),
            ('passage', 'سورة البقرة', (2, 7, 7)),
            ('passage', 'سورة البقرة', (2, 300, 300)),
        ])
        self.assertTrue(all(e['page'] is None for e in self.entries))

    def test_keeps_every_word_and_drops_only_markup(self):
        check_verbatim(ALTAFSIR, self.entries)  # raises on any difference
        self.assertEqual(self.entries[0]['text'], 'نص تجريبي { الحمد لله رب العالمين } نص تجريبي يكمل السطر')
        words = body_words(ALTAFSIR)
        for e in self.entries:
            self.assertNotIn('ms000', e['text'])
            for w in e['text'].split():
                self.assertIn(w, words)

    @NEEDS_DB
    def test_links_rest_on_the_heading_and_are_confirmed_by_quotations(self):
        verses = alt.load_verses(CONTENT_DB)
        got = [alt.suggest_links(e, verses) for e in self.entries]
        summary = [[(l['surah'], l['ayah_from'], l['ayah_to'], l['basis'], l['confidence'])
                    for l in links] for links, _ in got]
        self.assertEqual(summary, [
            [(1, 1, 7, 'marker+quote', 0.95)],
            [(2, 1, 286, 'marker', 0.5)],          # text before the first group: whole surah
            [(2, 1, 2, 'marker+quote', 0.95)],
            [(2, 3, 3, 'marker', 0.6)],            # nothing quoted: stays low
            [(2, 4, 4, 'marker+quote', 0.85)],     # one-word quotation only
            [(2, 7, 7, 'marker', 0.5)],            # the quotation is from another verse
            [],                                     # 2:300 does not exist: no link
        ])
        self.assertIn('outside surah 2', ' '.join(got[6][1]))
        notes, uncovered = alt.coverage_notes(self.entries, verses.counts)
        self.assertEqual(notes[self.entries[5]['seq']], ['no verse group for 2:5-6 before this one'])
        self.assertEqual(uncovered, 6236 - 7 - 5)  # 1:1-7, 2:1-4 and 2:7 are covered

    @NEEDS_DB
    def test_build_writes_drafts_only(self):
        with tempfile.TemporaryDirectory() as tmp:
            src = Path(tmp) / 'book'
            src.write_text(ALTAFSIR, encoding='utf-8')
            out = Path(tmp) / 'b.review.db'
            stats = alt.build(alt.BOOKS['saadi'], out, CONTENT_DB, src,
                              {'url': 'about:blank', 'file': 'book', 'sha256': '0' * 64})
            self.assertEqual(stats['entries'], 7)
            self.assertEqual(stats['unlinked_passages'][0]['heading'], '[2.300]')
            db = sqlite3.connect(out)
            self.assertEqual(db.execute("SELECT DISTINCT state FROM entry").fetchall(), [('draft',)])
            self.assertEqual(db.execute('SELECT kind FROM source').fetchone(), ('tafsir',))
            db.close()


class DamghaniSplitTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = dam.strip_page_marks(DAMGHANI)
        _, events = parse_openiti(cls.text)
        cls.entries = dam.split_entries(events)

    def test_page_break_marks_are_markup(self):
        self.assertNotIn('@', self.text)
        self.assertEqual(self.text.replace(' ', ''), DAMGHANI.replace('@', '').replace(' ', ''))

    def test_splits_at_chapters_word_headers_and_senses(self):
        got = [(e['kind'], e['section'], e['ordinal']) for e in self.entries]
        first, second = 'أب على أربعة أوجه', 'ج ب ر على أربعة أوجه'
        self.assertEqual(got, [
            ('front_matter', None, None),
            ('chapter', 'باب الهمزة', None),
            ('word', first, None),
            ('wajh', first, 1),
            ('wajh', first, 2),    # «هو على وجهين» inside it is not a header
            ('wajh', first, 3),
            ('word', second, None),  # found inside running text
            ('wajh', second, 1),
            ('wajh', second, 2),     # the next ordinal, without a colon
        ])
        self.assertEqual(self.entries[2]['text'], 'أب على أربعة أوجه\nمعنى . معنى')

    def test_keeps_every_word_and_pages(self):
        check_verbatim(self.text, self.entries)
        self.assertEqual([e['page'] for e in self.entries[:5]], [12, 13, 13, 13, 13])
        self.assertEqual(self.entries[-1]['page'], 14)

    @NEEDS_DB
    def test_links_from_the_surah_named_and_its_quotation(self):
        quran = dam.load_quran(CONTENT_DB)
        got = {e['seq']: dam.suggest_links(e, quran) for e in self.entries}
        by_seq = {seq: [(l['surah'], l['ayah_from'], l['basis'], l['confidence']) for l in links]
                  for seq, (links, _) in got.items()}
        self.assertEqual(by_seq[4], [(22, 78, 'quote', 0.8)])       # delimited, whole quotation
        self.assertEqual(by_seq[5], [])                              # not in the surah: noted
        self.assertIn('not found', ' '.join(got[5][1]))
        self.assertEqual(by_seq[6], [])                              # two words only: too short
        self.assertEqual(by_seq[8], [(59, 23, 'quote', 0.6)])       # longest start decides 22 vs 23
        self.assertEqual(by_seq[9], [(4, 1, 'quote', 0.8)])          # (( … )) delimiters

    def test_surah_name_followed_by_a_quote_mark(self):
        toks, refs = dam.references('في سورة السجدة " لتنذر قوما "')
        self.assertEqual(refs[0][1][:2], ['السجدة', '"'])

    @NEEDS_DB
    def test_build_writes_drafts_only(self):
        with tempfile.TemporaryDirectory() as tmp:
            src = Path(tmp) / 'book'
            src.write_text(DAMGHANI, encoding='utf-8')
            out = Path(tmp) / 'd.review.db'
            stats = dam.build(out, CONTENT_DB, src, {'url': 'about:blank', 'file': 'book', 'sha256': '0' * 64})
            self.assertEqual((stats['words'], stats['senses'], stats['senses_linked']), (2, 5, 3))
            db = sqlite3.connect(out)
            self.assertEqual(db.execute("SELECT DISTINCT state FROM entry").fetchall(), [('draft',)])
            for key, value in db.execute('SELECT source.key, entry.content_hash FROM entry, source'):
                self.assertEqual(len(value), 64)
            db.close()


SAADI = TOOLS / '.cache' / '1376CabdRahmanSacdi.TaysirKarimRahman.Tafsir10098-ara1'


@unittest.skipUnless(CONTENT_DB.exists() and SAADI.exists(), 'run fetch_sources.py first')
class RealBooksTest(unittest.TestCase):
    def test_saadi_splits_verbatim_and_links_every_group(self):
        raw = SAADI.read_text(encoding='utf-8')
        _, events = parse_openiti(raw)
        entries = alt.split_entries(events)
        check_verbatim(raw, entries)
        verses = alt.load_verses(CONTENT_DB)
        self.assertEqual(sum(1 for e in entries if alt.suggest_links(e, verses)[0]), len(entries))


if __name__ == '__main__':
    unittest.main()
