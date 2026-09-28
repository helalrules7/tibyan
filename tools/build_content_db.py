"""Build assets/db/content.db, the read-only content database bundled with the app.

Structure only: this script copies texts verbatim from their sources and
joins them by (surah, ayah). It never edits religious text.

Inputs (downloaded and SHA-256-verified by fetch_sources.py):
  tools/.cache/quran-uthmani.txt        Tanzil Uthmani 1.1   (display, copy)
  tools/.cache/quran-simple-clean.txt   Tanzil Simple Clean  (search only)
  tools/.cache/quran-data.xml           Tanzil metadata      (surahs, juz, hizb, sajda)
  tools/.cache/hafs-kfqc-json.zip       quran-ws 1.1.1       (pages, verse polygons)

Usage:
  python3 tools/fetch_sources.py
  python3 tools/build_content_db.py
"""
import hashlib
import json
import re
import sqlite3
import sys
import xml.etree.ElementTree as ET
import zipfile
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent
CACHE = ROOT / '.cache'
OUT = REPO / 'assets' / 'db' / 'content.db'
SCHEMA_VERSION = 1

TANZIL_NOTICE_MARK = '# PLEASE DO NOT REMOVE OR CHANGE THIS COPYRIGHT BLOCK'


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_tanzil(path):
    """Returns ({(surah, ayah): text}, copyright block) exactly as in the file."""
    verses = {}
    lines = path.read_text(encoding='utf-8').split('\n')
    for line in lines:
        parts = line.split('|')
        if len(parts) == 3 and parts[0].isdigit():
            verses[(int(parts[0]), int(parts[1]))] = parts[2]
    start = next(i for i, l in enumerate(lines) if l.startswith(TANZIL_NOTICE_MARK))
    notice = '\n'.join(lines[start:]).strip()
    return verses, notice


def basmala_prefix_length(verses, key):
    """Tanzil's text files put the basmala before verse 1 of 112 surahs.
    The text is stored verbatim; the app hides this prefix when it shows
    the basmala as a surah header. Returns the prefix length in characters
    (0 when there is none)."""
    surah, ayah = key
    if ayah != 1 or surah in (1, 9):
        return 0
    words = verses[key].split(' ')
    basmala_words = verses[(1, 1)].split(' ')
    # Compare base letters only: the basmala before some surahs carries
    # different marks (for example, an extra shadda) than 1:1.
    strip = lambda w: re.sub(r'[ً-ٰٟۖ-ۭـ]', '', w)
    if [strip(w) for w in words[:4]] == [strip(w) for w in basmala_words]:
        return len(' '.join(words[:4])) + 1
    return 0


def main():
    uthmani_path = CACHE / 'quran-uthmani.txt'
    clean_path = CACHE / 'quran-simple-clean.txt'
    meta_path = CACHE / 'quran-data.xml'
    qws_path = CACHE / 'hafs-kfqc-json.zip'

    uthmani, notice = read_tanzil(uthmani_path)
    clean, clean_notice = read_tanzil(clean_path)
    meta = ET.parse(meta_path).getroot()

    surahs = [
        dict(
            id=int(s.get('index')), ayas=int(s.get('ayas')),
            name_ar=s.get('name'), name_en=s.get('tname'),
            meaning_en=s.get('ename'), type=s.get('type'),
            revelation_order=int(s.get('order')),
        )
        for s in meta.find('suras')
    ]
    order = [(s['id'], a) for s in surahs for a in range(1, s['ayas'] + 1)]
    assert len(order) == 6236 and set(order) == set(uthmani) == set(clean)

    def spans(tag):
        starts = {(int(e.get('sura')), int(e.get('aya'))): i + 1
                  for i, e in enumerate(meta.find(tag))}
        current, out = 0, {}
        for key in order:
            current = starts.get(key, current)
            out[key] = current
        return out

    juz, quarter, manzil = spans('juzs'), spans('hizbs'), spans('manzils')
    sajda = {(int(e.get('sura')), int(e.get('aya'))): e.get('type')
             for e in meta.find('sajdas')}

    # quran-ws: page numbers and verse polygons for the new Madina edition
    pages, polygons = {}, []
    with zipfile.ZipFile(qws_path) as z:
        for name in sorted(z.namelist()):
            m = re.fullmatch(r'(?:.*/)?(\d{3})\.json', name)
            if not m:
                continue
            page = int(m.group(1))
            for a in json.loads(z.read(name)):
                key = (a['surahNumber'], a['ayahNumber'])
                pages.setdefault(key, page)
                polygons.append((page, key[0], key[1], a['polygon'],
                                 a.get('x'), a.get('y')))
        surah_meta = {s['number']: s for s in json.loads(z.read(
            next(n for n in z.namelist() if n.endswith('surah.json'))))}
    assert set(pages) == set(order), 'every verse must have a page'

    OUT.parent.mkdir(parents=True, exist_ok=True)
    if OUT.exists():
        OUT.unlink()
    db = sqlite3.connect(OUT)
    db.executescript('''
    PRAGMA journal_mode = OFF;
    CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
    CREATE TABLE source (
      id INTEGER PRIMARY KEY, key TEXT UNIQUE NOT NULL, title TEXT NOT NULL,
      publisher TEXT NOT NULL, version TEXT, license TEXT NOT NULL,
      url TEXT NOT NULL, attribution TEXT NOT NULL, notice TEXT,
      sha256 TEXT NOT NULL, retrieved_at TEXT NOT NULL);
    CREATE TABLE surah (
      id INTEGER PRIMARY KEY, name_ar TEXT NOT NULL, name_en TEXT NOT NULL,
      meaning_en TEXT NOT NULL, revelation TEXT NOT NULL,
      revelation_order INTEGER NOT NULL, ayah_count INTEGER NOT NULL,
      start_page INTEGER NOT NULL, source_id INTEGER NOT NULL);
    CREATE TABLE ayah (
      id INTEGER PRIMARY KEY,               -- 1..6236 in mushaf order
      surah INTEGER NOT NULL REFERENCES surah(id),
      number INTEGER NOT NULL,
      text TEXT NOT NULL,                   -- Tanzil Uthmani, verbatim
      basmala_prefix INTEGER NOT NULL,      -- chars of the basmala before verse 1
      text_search TEXT NOT NULL,            -- Tanzil Simple Clean, verbatim
      search_basmala_prefix INTEGER NOT NULL,
      juz INTEGER NOT NULL, hizb_quarter INTEGER NOT NULL,
      manzil INTEGER NOT NULL, page INTEGER NOT NULL,
      sajda TEXT,                           -- recommended | obligatory | NULL
      text_source_id INTEGER NOT NULL, page_source_id INTEGER NOT NULL,
      UNIQUE (surah, number));
    CREATE TABLE ayah_polygon (             -- verse outline on a page (viewBox units)
      page INTEGER NOT NULL, surah INTEGER NOT NULL, number INTEGER NOT NULL,
      path TEXT NOT NULL, marker_x REAL, marker_y REAL,
      PRIMARY KEY (page, surah, number));
    CREATE TABLE review_note (              -- open questions for a qualified reviewer
      id INTEGER PRIMARY KEY, topic TEXT NOT NULL, surah INTEGER, number INTEGER,
      note TEXT NOT NULL);
    ''')

    today = date.today().isoformat()
    db.executemany('INSERT INTO source VALUES (?,?,?,?,?,?,?,?,?,?,?)', [
        (1, 'tanzil-uthmani', 'Tanzil Quran Text (Uthmani)', 'Tanzil Project', '1.1',
         'CC BY 3.0, verbatim copies only', 'https://tanzil.net',
         'Quran text: Tanzil Project (tanzil.net)', notice, sha256(uthmani_path), today),
        (2, 'tanzil-simple-clean', 'Tanzil Quran Text (Simple Clean), search only',
         'Tanzil Project', '1.1', 'CC BY 3.0, verbatim copies only', 'https://tanzil.net',
         'Search text: Tanzil Project (tanzil.net)', clean_notice, sha256(clean_path), today),
        (3, 'tanzil-metadata', 'Tanzil Quran Metadata', 'Tanzil Project', '1.0', 'cc-by',
         'https://tanzil.net/docs/quran_metadata', 'Metadata: Tanzil Project (tanzil.net)',
         None, sha256(meta_path), today),
        (4, 'quran-ws-hafs', 'Quran SVG: page layer and verse polygons (Hafs, KFGQPC 1441H)',
         'Quran.ws; page artwork: King Fahd Glorious Quran Printing Complex', '1.1.1',
         'CC BY 4.0 (attribution waived in products); artwork under KFGQPC terms',
         'https://github.com/quran-ws/quran-svg',
         'Mushaf pages: King Fahd Glorious Quran Printing Complex', None,
         sha256(qws_path), today),
    ])

    db.executemany('INSERT INTO surah VALUES (?,?,?,?,?,?,?,?,?)', [
        (s['id'], s['name_ar'], s['name_en'], s['meaning_en'],
         'meccan' if s['type'] == 'Meccan' else 'medinan', s['revelation_order'],
         s['ayas'], surah_meta[s['id']]['pageNumber'], 3)
        for s in surahs
    ])

    rows = []
    for i, key in enumerate(order, start=1):
        rows.append((
            i, key[0], key[1], uthmani[key], basmala_prefix_length(uthmani, key),
            clean[key], basmala_prefix_length(clean, key),
            juz[key], quarter[key], manzil[key], pages[key], sajda.get(key), 1, 4,
        ))
    db.executemany('INSERT INTO ayah VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)', rows)
    db.executemany('INSERT INTO ayah_polygon VALUES (?,?,?,?,?,?)', polygons)
    db.executemany('INSERT INTO review_note (topic, surah, number, note) VALUES (?,?,?,?)', [
        ('juz-boundary', 3, 92, 'Tanzil and the KFGQPC 2.0 data place a juz boundary differently near this verse. Juz numbers currently follow Tanzil.'),
        ('juz-boundary', 9, 93, 'Tanzil and the KFGQPC 2.0 data place a juz boundary differently near this verse. Juz numbers currently follow Tanzil.'),
        ('text-difference', 15, 7, 'Word joining differs from the KFGQPC text (see docs/verification).'),
        ('text-difference', 17, 7, 'Small waw differs from the KFGQPC text (see docs/verification).'),
        ('text-difference', 27, 20, 'Word joining differs from the KFGQPC text (see docs/verification).'),
        ('text-difference', 36, 22, 'Word joining differs from the KFGQPC text (see docs/verification).'),
    ])
    db.executemany('INSERT INTO meta VALUES (?,?)', [
        ('schema_version', str(SCHEMA_VERSION)),
        ('built_at', today),
        ('tanzil_notice', notice),
    ])
    db.execute('CREATE INDEX ayah_page ON ayah(page)')
    db.execute('CREATE INDEX ayah_juz ON ayah(juz)')
    db.commit()
    db.execute('VACUUM')
    db.close()

    check = sqlite3.connect(OUT)
    assert check.execute('SELECT COUNT(*) FROM ayah').fetchone()[0] == 6236
    assert check.execute('SELECT COUNT(DISTINCT page) FROM ayah').fetchone()[0] == 604
    prefixed = check.execute('SELECT COUNT(*) FROM ayah WHERE basmala_prefix > 0').fetchone()[0]
    assert prefixed == 112, prefixed
    print(f'built {OUT.relative_to(REPO)}: 6236 verses, 604 pages, '
          f'{len(polygons)} polygons, {OUT.stat().st_size // 1024} KB')
    return 0


if __name__ == '__main__':
    sys.exit(main())
