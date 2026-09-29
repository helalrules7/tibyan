"""Build assets/db/content.db, the read-only content database bundled with the app.

Structure only: this script copies texts verbatim from their sources and
joins them by (surah, ayah). It never edits religious text.

Inputs (downloaded and SHA-256-verified by fetch_sources.py):
  tools/.cache/quran-uthmani.txt        Tanzil Uthmani 1.1   (display, copy)
  tools/.cache/quran-simple-clean.txt   Tanzil Simple Clean  (search only)
  tools/.cache/quran-data.xml           Tanzil metadata      (surahs, juz, hizb, sajda,
                                                             pages of the old 1405H edition)
  tools/.cache/hafs-kfqc-json.zip       quran-ws 1.1.1       (pages, verse polygons)
  tools/.cache/UthmanicHafs_v2-0.zip    KFGQPC Hafs 2.0      (continuous view, KFGQPC font)
  tools/.cache/hafs-kfqc-svg.zip        quran-ws 1.1.1       (word boxes, see build_word_boxes.py)
  tools/.cache/qe_arabic_moyassar.sqlite  QuranEnc             (al-Tafsir al-Muyassar)
  tools/.cache/qe_english_saheeh.sqlite   QuranEnc 1.1.2       (Saheeh International)
  tools/.cache/tanzil_en.pickthall.txt    Tanzil               (Pickthall, public domain)
  tools/.cache/mp3quran_ayat_timing.json  mp3quran.net         (verse timings, fetch_ayat_timing.py)
  tools/.cache/word_timing.json           quran-align placed on mp3quran files (build_word_timing.py)
  tools/.cache/quranlab_banna_timing.json QuranLab word timings, al-Banna (fetch_quranlab_timing.py)
  tools/.cache/quranlab_ayah_timing.json  al-Banna verse timings derived from it (build_quranlab_timing.py)
  tools/.cache/quranlab_word_timing.json  al-Banna word timings placed with it (build_quranlab_timing.py)
  tools/.cache/shamarly_geometry.db       Shamarly page geometry (build_shamarly.py): page numbers,
                                          lines, verse, marker and word boxes; no text

Usage:
  python3 tools/fetch_sources.py
  python3 tools/build_content_db.py
"""
import hashlib
import json
import math
import re
import sqlite3
import sys
import xml.etree.ElementTree as ET
import zipfile
from datetime import date
from pathlib import Path

import build_line_cuts
import build_word_boxes

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent
CACHE = ROOT / '.cache'
OUT = REPO / 'assets' / 'db' / 'content.db'
SCHEMA_VERSION = 11
SHAMARLY = CACHE / 'shamarly_geometry.db'

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


def read_kfgqpc(path):
    """Returns {(surah, ayah): aya_text} from the KFGQPC Hafs 2.0 data, verbatim.
    Each text ends with a space and the verse-number glyph of the KFGQPC font."""
    with zipfile.ZipFile(path) as z:
        rows = json.loads(z.read('UthmanicHafs_v2-0 data/hafsData_v2-0.json'))
    out = {}
    for r in rows:
        text = r['aya_text']
        assert text[-2] in '\u00a0 ' and '\ufc00' <= text[-1] <= '\ufdff', (r['sura_no'], r['aya_no'])
        out[(r['sura_no'], r['aya_no'])] = text
    return out


def read_quranenc(path):
    """Returns {(surah, ayah): (text, footnotes)} from a QuranEnc SQLite file, verbatim."""
    db = sqlite3.connect(path)
    rows = db.execute('SELECT sura, aya, translation, footnotes FROM translations').fetchall()
    db.close()
    return {(s, a): (t, f or None) for s, a, t, f in rows}


def read_tanzil_translation(path):
    """Returns ({(surah, ayah): text}, header comment block) from a Tanzil translation file, verbatim."""
    verses, notice = {}, []
    for line in path.read_text(encoding='utf-8').split('\n'):
        parts = line.split('|')
        if len(parts) == 3 and parts[0].isdigit():
            verses[(int(parts[0]), int(parts[1]))] = parts[2]
        elif line.startswith('#'):
            notice.append(line)
    return verses, '\n'.join(notice).strip()


# Recitations streamed from mp3quran.net: (id, name_ar, name_en, style,
# folder URL, mp3quran timing read id or None). al-Banna and Mustafa Ismail
# have no published timing for their murattal, so their mujawwad is added.
# al-Banna's murattal (4) gets verse timings derived by
# build_quranlab_timing.py instead.
RECITERS = [
    (1, 'محمد صديق المنشاوي', 'Mohamed Siddiq al-Minshawi', 'murattal',
     'https://server10.mp3quran.net/minsh/', 112),
    (2, 'محمود خليل الحصري', 'Mahmoud Khalil al-Husary', 'murattal',
     'https://server13.mp3quran.net/husr/', 118),
    (3, 'عبد الباسط عبد الصمد', 'Abdul Basit Abdul Samad', 'murattal',
     'https://server7.mp3quran.net/basit/', 53),
    (4, 'محمود علي البنا', 'Mahmoud Ali al-Banna', 'murattal',
     'https://server8.mp3quran.net/bna/', None),
    (5, 'مصطفى إسماعيل', 'Mustafa Ismail', 'murattal',
     'https://server8.mp3quran.net/mustafa/', None),
    (6, 'محمود علي البنا', 'Mahmoud Ali al-Banna', 'mujawwad',
     'https://server8.mp3quran.net/bna/Almusshaf-Al-Mojawwad/', 122),
    (7, 'مصطفى إسماعيل', 'Mustafa Ismail', 'mujawwad',
     'https://server8.mp3quran.net/mustafa/Almusshaf-Al-Mojawwad/', 288),
]


def timing_rows(timing, counts):
    """Verse timings as published, for surahs where every verse has one.
    A surah with a missing verse gets no rows (it plays without
    highlighting) and is returned in the gaps list."""
    rows, gaps = [], []
    for reciter, *_, read in RECITERS:
        if read is None:
            continue
        for surah, entries in timing[str(read)].items():
            surah = int(surah)
            numbers = [a for a, _, _ in entries if a > 0]
            if numbers != list(range(1, counts[surah] + 1)):
                gaps.append((reciter, surah))
                continue
            rows += [(reciter, surah, a, start, end) for a, start, end in entries]
    return rows, gaps


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
    kfgqpc_path = CACHE / 'UthmanicHafs_v2-0.zip'
    moyassar_path = CACHE / 'qe_arabic_moyassar.sqlite'
    saheeh_path = CACHE / 'qe_english_saheeh.sqlite'
    pickthall_path = CACHE / 'tanzil_en.pickthall.txt'
    timing_path = CACHE / 'mp3quran_ayat_timing.json'
    word_timing_path = CACHE / 'word_timing.json'
    quranlab_path = CACHE / 'quranlab_banna_timing.json'
    quranlab_ayah_path = CACHE / 'quranlab_ayah_timing.json'
    quranlab_word_path = CACHE / 'quranlab_word_timing.json'

    uthmani, notice = read_tanzil(uthmani_path)
    clean, clean_notice = read_tanzil(clean_path)
    meta = ET.parse(meta_path).getroot()
    kfgqpc = read_kfgqpc(kfgqpc_path)
    moyassar = read_quranenc(moyassar_path)
    saheeh = read_quranenc(saheeh_path)
    pickthall, pickthall_notice = read_tanzil_translation(pickthall_path)

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
    assert len(order) == 6236 and set(order) == set(uthmani) == set(clean) == set(kfgqpc)
    assert set(order) == set(moyassar) == set(saheeh) == set(pickthall)

    def spans(tag):
        starts = {(int(e.get('sura')), int(e.get('aya'))): i + 1
                  for i, e in enumerate(meta.find(tag))}
        current, out = 0, {}
        for key in order:
            current = starts.get(key, current)
            out[key] = current
        return out

    juz, quarter, manzil = spans('juzs'), spans('hizbs'), spans('manzils')
    # Tanzil's page data follows the old Madina edition (1405H); checked
    # against the quran.com glyph boxes for all 6,236 verses.
    page_old = spans('pages')
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
      start_page INTEGER NOT NULL,          -- new edition (1441H)
      start_page_1405 INTEGER NOT NULL,     -- old edition (1405H)
      source_id INTEGER NOT NULL,
      start_page_shamarly INTEGER NOT NULL);  -- Shamarly (Egyptian) edition: page of verse 1
    CREATE TABLE ayah (
      id INTEGER PRIMARY KEY,               -- 1..6236 in mushaf order
      surah INTEGER NOT NULL REFERENCES surah(id),
      number INTEGER NOT NULL,
      text TEXT NOT NULL,                   -- Tanzil Uthmani, verbatim (reference)
      display_text TEXT NOT NULL,           -- KFGQPC Hafs 2.0, verbatim (shown)
      basmala_prefix INTEGER NOT NULL,      -- chars of the basmala before verse 1
      text_search TEXT NOT NULL,            -- Tanzil Simple Clean, verbatim
      search_basmala_prefix INTEGER NOT NULL,
      juz INTEGER NOT NULL, hizb_quarter INTEGER NOT NULL,
      manzil INTEGER NOT NULL,
      page INTEGER NOT NULL,                -- new edition (1441H), quran-ws
      page_1405 INTEGER NOT NULL,           -- old edition (1405H), Tanzil
      sajda TEXT,                           -- recommended | obligatory | NULL
      text_source_id INTEGER NOT NULL, display_source_id INTEGER NOT NULL,
      page_source_id INTEGER NOT NULL,
      page_shamarly INTEGER NOT NULL,       -- Shamarly edition: page where the verse starts
      page_shamarly_end INTEGER NOT NULL,   -- Shamarly edition: page of its marker (a verse may run over a page)
      UNIQUE (surah, number));
    CREATE TABLE ayah_polygon (             -- verse outline on a page (viewBox units)
      page INTEGER NOT NULL, surah INTEGER NOT NULL, number INTEGER NOT NULL,
      path TEXT NOT NULL, marker_x REAL, marker_y REAL,
      PRIMARY KEY (page, surah, number));
    CREATE TABLE word_box (                 -- word boxes on the new edition's pages (tenths of viewBox units)
      surah INTEGER NOT NULL, ayah INTEGER NOT NULL,
      word INTEGER NOT NULL,                -- 1-based, words of the KFGQPC text (۞ not counted)
      page INTEGER NOT NULL,
      x0 INTEGER NOT NULL, y0 INTEGER NOT NULL, x1 INTEGER NOT NULL, y1 INTEGER NOT NULL,
      exact INTEGER NOT NULL,               -- 1: every word in the verse matched its predicted pieces
      PRIMARY KEY (surah, ayah, word)) WITHOUT ROWID;
    CREATE TABLE line_cut (                 -- where to split a page into its 15 lines
      edition TEXT NOT NULL, page INTEGER NOT NULL,
      gap INTEGER NOT NULL,                 -- 0..13, below line gap
      y REAL NOT NULL,                      -- page units (1441) or image px (1405)
      PRIMARY KEY (edition, page, gap)) WITHOUT ROWID;
    CREATE TABLE line_overflow (            -- 1441 marks that cross a cut, and their line
      page INTEGER NOT NULL, line INTEGER NOT NULL, path TEXT NOT NULL);
    CREATE TABLE line_overflow_1405 (       -- 1405 ink crossing a cut (image px), and its line
      page INTEGER NOT NULL, line INTEGER NOT NULL,
      x0 INTEGER NOT NULL, y0 INTEGER NOT NULL, x1 INTEGER NOT NULL, y1 INTEGER NOT NULL);
    CREATE TABLE commentary_edition (       -- tafsir and translation texts shipped in this file
      source_id INTEGER PRIMARY KEY REFERENCES source(id),
      kind TEXT NOT NULL,                   -- tafsir | translation
      language TEXT NOT NULL, direction TEXT NOT NULL,
      name_ar TEXT NOT NULL, name_en TEXT NOT NULL,
      sort_order INTEGER NOT NULL);
    CREATE TABLE commentary (               -- one entry per verse, verbatim from the source
      source_id INTEGER NOT NULL, surah INTEGER NOT NULL, ayah INTEGER NOT NULL,
      text TEXT NOT NULL, footnotes TEXT,
      PRIMARY KEY (source_id, surah, ayah)) WITHOUT ROWID;
    CREATE TABLE reciter (                  -- recitations streamed or downloaded per surah
      id INTEGER PRIMARY KEY, name_ar TEXT NOT NULL, name_en TEXT NOT NULL,
      style TEXT NOT NULL,                  -- murattal | mujawwad
      folder_url TEXT NOT NULL,             -- surah file = folder_url + NNN.mp3
      source_id INTEGER NOT NULL);
    CREATE TABLE ayah_timing (              -- ms from the start of the surah file; ayah 0 = opening before verse 1
      reciter INTEGER NOT NULL, surah INTEGER NOT NULL, ayah INTEGER NOT NULL,
      start_ms INTEGER NOT NULL, end_ms INTEGER NOT NULL,
      PRIMARY KEY (reciter, surah, ayah)) WITHOUT ROWID;
    CREATE TABLE word_timing (              -- ms in the surah file; word as in word_box
      reciter INTEGER NOT NULL, surah INTEGER NOT NULL, ayah INTEGER NOT NULL,
      word INTEGER NOT NULL, start_ms INTEGER NOT NULL, end_ms INTEGER NOT NULL,
      PRIMARY KEY (reciter, surah, ayah, word)) WITHOUT ROWID;
    CREATE TABLE ayah_speech (              -- where a verse's recited speech starts and ends (ms in the surah file)
      reciter INTEGER NOT NULL, surah INTEGER NOT NULL, ayah INTEGER NOT NULL,
      start_ms INTEGER NOT NULL, end_ms INTEGER NOT NULL,
      PRIMARY KEY (reciter, surah, ayah)) WITHOUT ROWID;
    CREATE TABLE shamarly_page (            -- Shamarly page images 1..522 (886x1377 px): cover, ornate, text
      page INTEGER PRIMARY KEY, kind TEXT NOT NULL, lines INTEGER NOT NULL,
      grid_top REAL, pitch REAL);           -- baseline of line j = grid_top + j * pitch (px)
    CREATE TABLE shamarly_line (            -- line slots: text | header | basmala, band y0..y1 (px)
      page INTEGER NOT NULL, line INTEGER NOT NULL, kind TEXT NOT NULL, surah INTEGER,
      y0 INTEGER NOT NULL, y1 INTEGER NOT NULL,
      PRIMARY KEY (page, line)) WITHOUT ROWID;
    CREATE TABLE shamarly_line_overflow (   -- ink crossing a band edge (px), and its line
      page INTEGER NOT NULL, line INTEGER NOT NULL,
      x0 INTEGER NOT NULL, y0 INTEGER NOT NULL, x1 INTEGER NOT NULL, y1 INTEGER NOT NULL);
    CREATE TABLE shamarly_header (          -- printed surah-header frames (two line slots)
      surah INTEGER PRIMARY KEY, page INTEGER NOT NULL, first_line INTEGER,
      x0 INTEGER NOT NULL, y0 INTEGER NOT NULL, x1 INTEGER NOT NULL, y1 INTEGER NOT NULL);
    CREATE TABLE shamarly_marker (          -- verse-end marker rings (px)
      surah INTEGER NOT NULL, ayah INTEGER NOT NULL, page INTEGER NOT NULL, line INTEGER NOT NULL,
      x0 INTEGER NOT NULL, y0 INTEGER NOT NULL, x1 INTEGER NOT NULL, y1 INTEGER NOT NULL,
      PRIMARY KEY (surah, ayah)) WITHOUT ROWID;
    CREATE TABLE shamarly_verse_box (       -- one box per verse per line, reading order (px)
      surah INTEGER NOT NULL, ayah INTEGER NOT NULL, part INTEGER NOT NULL,
      page INTEGER NOT NULL, line INTEGER NOT NULL,
      x0 INTEGER NOT NULL, y0 INTEGER NOT NULL, x1 INTEGER NOT NULL, y1 INTEGER NOT NULL,
      PRIMARY KEY (surah, ayah, part)) WITHOUT ROWID;
    CREATE TABLE shamarly_word_box (        -- word boxes (px); word as in word_box
      surah INTEGER NOT NULL, ayah INTEGER NOT NULL, word INTEGER NOT NULL,
      page INTEGER NOT NULL, line INTEGER NOT NULL,
      x0 INTEGER NOT NULL, y0 INTEGER NOT NULL, x1 INTEGER NOT NULL, y1 INTEGER NOT NULL,
      level INTEGER NOT NULL,               -- words_matched of the verse: 2 stable split, 1 unreviewed
      PRIMARY KEY (surah, ayah, word)) WITHOUT ROWID;
    CREATE TABLE review_note (              -- open questions for a qualified reviewer
      id INTEGER PRIMARY KEY, topic TEXT NOT NULL, surah INTEGER, number INTEGER,
      note TEXT NOT NULL,
      decision TEXT);                       -- NULL while open; see docs/review/DECISIONS.md
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
        (5, 'kfgqpc-hafs-2.0', 'Uthmanic Hafs text, version 2.0 (digitally signed)',
         'King Fahd Glorious Quran Printing Complex', '2.0',
         'KFGQPC; permission for the text requested, see docs/DATA_SOURCES.md',
         'https://qurancomplex.gov.sa', 'Quran text: King Fahd Glorious Quran Printing Complex',
         None, sha256(kfgqpc_path), today),
        (6, 'qurancom-images-1024', 'Old Madina edition (1405H): page images and glyph boxes, width 1024',
         'Quran.com (Quran Foundation); page artwork: King Fahd Glorious Quran Printing Complex', None,
         'No written license yet; permission requested (letters 2 and 10). Downloaded from quran.com, not re-hosted',
         'https://files.quran.app/hafs/madani/zips/images_1024.zip',
         'Old edition pages: King Fahd Glorious Quran Printing Complex, via Quran.com', None,
         '401b432deb2c7415818116d9b36db34c31e405f652b0206926da851943286b85', today),
        # QuranEnc publishes no version number for this tafsir; the SHA-256
        # and the retrieval date identify the copy.
        (7, 'quranenc-arabic-moyassar', 'التفسير الميسر',
         'King Fahd Glorious Quran Printing Complex', None,
         'QuranEnc terms: no change, addition or removal; credit the publisher and QuranEnc.com; state the version',
         'https://quranenc.com/ar/browse/arabic_moyassar',
         'التفسير الميسر: مجمع الملك فهد لطباعة المصحف الشريف، عبر موقع QuranEnc.com',
         None, sha256(moyassar_path), today),
        (8, 'quranenc-english-saheeh', 'Saheeh International',
         'Saheeh International', '1.1.2',
         'QuranEnc terms: no change, addition or removal; credit the translator and QuranEnc.com; state the version',
         'https://quranenc.com/en/browse/english_saheeh',
         'Saheeh International, via QuranEnc.com, version 1.1.2',
         None, sha256(saheeh_path), today),
        (9, 'tanzil-en-pickthall', 'The Meaning of the Glorious Koran',
         'Mohammed Marmaduke Pickthall (1930)', None,
         'Public domain; Tanzil copy for non-commercial use',
         'https://tanzil.net/trans/en.pickthall',
         'Pickthall (1930), text from Tanzil.net', pickthall_notice, sha256(pickthall_path), today),
    ])
    db.execute('INSERT INTO source VALUES (?,?,?,?,?,?,?,?,?,?,?)', (
        10, 'mp3quran', 'Recitations and verse timings', 'mp3quran.net', None,
        'mp3quran.net general permission to copy any material or use any link',
        'https://mp3quran.net', 'التلاوات وتوقيت الآيات: mp3quran.net', None,
        sha256(timing_path), today))
    db.executemany('INSERT INTO reciter VALUES (?,?,?,?,?,?)',
                   [(i, ar, en, style, url, 10) for i, ar, en, style, url, _ in RECITERS])
    counts = {s['id']: s['ayas'] for s in surahs}
    timings, gaps = timing_rows(json.loads(timing_path.read_text(encoding='utf-8')), counts)
    db.executemany('INSERT INTO ayah_timing VALUES (?,?,?,?,?)', timings)
    db.execute('INSERT INTO source VALUES (?,?,?,?,?,?,?,?,?,?,?)', (
        11, 'quran-align-word-timing', 'Word timings (quran-align, placed on the mp3quran files)',
        'Collin Fair (quran-align); placement by Tibyan', '2016-11-24',
        'CC BY 4.0', 'https://github.com/cpfair/quran-align',
        'توقيت الكلمات: quran-align © 2016 Collin Fair (CC BY 4.0)', None,
        sha256(word_timing_path), today))
    db.executemany('INSERT INTO word_timing VALUES (?,?,?,?,?,?)',
                   json.loads(word_timing_path.read_text(encoding='utf-8')))
    db.execute('INSERT INTO source VALUES (?,?,?,?,?,?,?,?,?,?,?)', (
        12, 'quranlab-word-timing',
        'Word timings for al-Banna (murattal), QuranLab; verse boundaries derived by Tibyan',
        'QuranLab (quranlab/quran-audio); placement and verse boundaries by Tibyan', None,
        'CC BY 4.0', 'https://huggingface.co/datasets/quranlab/quran-audio',
        'توقيت الكلمات للبنا: QuranLab (CC BY 4.0)، وحدود الآيات مستخرجة في تبيان', None,
        sha256(quranlab_path), today))
    db.executemany('INSERT INTO ayah_timing VALUES (?,?,?,?,?)',
                   json.loads(quranlab_ayah_path.read_text(encoding='utf-8')))
    db.executemany('INSERT INTO word_timing VALUES (?,?,?,?,?,?)',
                   json.loads(quranlab_word_path.read_text(encoding='utf-8')))
    for reciter, surah in gaps:
        print(f'timing gap: reciter {reciter}, surah {surah} (plays without highlighting)')
    # Speech spans measured by tools/build_ayah_speech.py, which reads the
    # timings above from the previous build; absent on a first build.
    speech_path = CACHE / 'ayah_speech.json'
    if speech_path.exists():
        db.executemany('INSERT INTO ayah_speech VALUES (?,?,?,?,?)',
                       json.loads(speech_path.read_text(encoding='utf-8')))
    shamarly = sqlite3.connect(f'file:{SHAMARLY}?mode=ro', uri=True)
    sh_meta = dict(shamarly.execute('SELECT key, value FROM meta'))
    db.execute('INSERT INTO source VALUES (?,?,?,?,?,?,?,?,?,?,?)', (
        13, 'shamarly-archive-org', 'Shamarly (Egyptian) mushaf: page images; page geometry by Tibyan',
        'archive.org (details/shamerly); geometry: Tibyan (tools/build_shamarly.py)', None,
        'No licence stated; used with the owner\'s consent',
        'https://archive.org/details/shamerly',
        'صفحات مصحف الشمرلي: archive.org (details/shamerly)', None,
        sh_meta['sha256_pages_zip'], today))
    sh_pages = {(s, a): (p, e) for s, a, p, e in shamarly.execute(
        'SELECT surah, ayah, page, end_page FROM ayah')}
    assert set(sh_pages) == set(order), 'every verse must have a Shamarly page'
    db.executemany('INSERT INTO shamarly_page VALUES (?,?,?,?,?)',
                   shamarly.execute('SELECT page, kind, lines, grid_top, pitch FROM page ORDER BY page'))
    db.executemany('INSERT INTO shamarly_line VALUES (?,?,?,?,?,?)', shamarly.execute(
        'SELECT page, line, kind, surah, y0, y1 FROM line ORDER BY page, line'))
    db.executemany('INSERT INTO shamarly_line_overflow VALUES (?,?,?,?,?,?)', shamarly.execute(
        'SELECT page, line, x0, y0, x1, y1 FROM line_overflow ORDER BY page, line, y0, x0'))
    db.executemany('INSERT INTO shamarly_header VALUES (?,?,?,?,?,?,?)', shamarly.execute(
        'SELECT surah, page, first_line, x0, y0, x1, y1 FROM header ORDER BY surah'))
    db.executemany('INSERT INTO shamarly_marker VALUES (?,?,?,?,?,?,?,?)', shamarly.execute(
        'SELECT surah, ayah, page, line, x0, y0, x1, y1 FROM marker ORDER BY surah, ayah'))
    db.executemany('INSERT INTO shamarly_verse_box VALUES (?,?,?,?,?,?,?,?,?)', shamarly.execute(
        'SELECT surah, ayah, part, page, line, x0, y0, x1, y1 FROM verse_box ORDER BY surah, ayah, part'))
    db.executemany('INSERT INTO shamarly_word_box VALUES (?,?,?,?,?,?,?,?,?,?)', shamarly.execute(
        'SELECT w.surah, w.ayah, w.word, w.page, w.line, w.x0, w.y0, w.x1, w.y1, a.words_matched '
        'FROM word_box w JOIN ayah a ON a.surah = w.surah AND a.ayah = w.ayah '
        'WHERE a.words_matched >= 1 ORDER BY w.surah, w.ayah, w.word'))
    shamarly.close()
    db.executemany('INSERT INTO commentary_edition VALUES (?,?,?,?,?,?,?)', [
        (7, 'tafsir', 'ar', 'rtl', 'التفسير الميسر', 'Al-Tafsir al-Muyassar', 1),
        (8, 'translation', 'en', 'ltr', 'الترجمة الإنجليزية: صحيح إنترناشونال', 'Saheeh International', 2),
        (9, 'translation', 'en', 'ltr', 'الترجمة الإنجليزية: بكثال', 'Pickthall', 3),
    ])
    db.executemany('INSERT INTO commentary VALUES (?,?,?,?,?)', [
        (sid, *key, *entry)
        for sid, texts in ((7, moyassar), (8, saheeh), (9, {k: (v, None) for k, v in pickthall.items()}))
        for key in order
        for entry in [texts[key]]
    ])

    db.executemany('INSERT INTO surah VALUES (?,?,?,?,?,?,?,?,?,?,?)', [
        (s['id'], s['name_ar'], s['name_en'], s['meaning_en'],
         'meccan' if s['type'] == 'Meccan' else 'medinan', s['revelation_order'],
         s['ayas'], surah_meta[s['id']]['pageNumber'], page_old[(s['id'], 1)], 3,
         sh_pages[(s['id'], 1)][0])
        for s in surahs
    ])

    rows = []
    for i, key in enumerate(order, start=1):
        rows.append((
            i, key[0], key[1], uthmani[key], kfgqpc[key], basmala_prefix_length(uthmani, key),
            clean[key], basmala_prefix_length(clean, key),
            juz[key], quarter[key], manzil[key], pages[key], page_old[key], sajda.get(key), 1, 5, 4,
            *sh_pages[key],
        ))
    db.executemany('INSERT INTO ayah VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)', rows)
    db.executemany('INSERT INTO ayah_polygon VALUES (?,?,?,?,?,?)', polygons)
    # Decisions of the reviewer (2026-09-28), recorded in docs/review/DECISIONS.md.
    db.executemany('INSERT INTO review_note (topic, surah, number, note, decision) VALUES (?,?,?,?,?)', [
        ('juz-boundary', 3, 92, 'Tanzil and the KFGQPC 2.0 data place a juz boundary differently near this verse.',
         'Juz 4 starts at 3:93. Juz numbers follow Tanzil.'),
        ('juz-boundary', 9, 93, 'Tanzil and the KFGQPC 2.0 data place a juz boundary differently near this verse.',
         'Juz 11 starts at 9:93. Juz numbers follow Tanzil.'),
        ('text-difference', 15, 7, 'Word joining differs between Tanzil and the KFGQPC text.',
         'The KFGQPC spelling is accepted: the two words look separate either way.'),
        ('text-difference', 17, 7, 'Small waw differs between Tanzil and the KFGQPC text.',
         'The form drawn by the KFGQPC font (small waw with madda) is the chosen one.'),
        ('text-difference', 27, 20, 'Word joining differs between Tanzil and the KFGQPC text.',
         'Joined, as in the KFGQPC text.'),
        ('text-difference', 36, 22, 'Word joining differs between Tanzil and the KFGQPC text.',
         'Joined, as in the KFGQPC text.'),
    ])
    db.executemany('INSERT INTO meta VALUES (?,?)', [
        ('schema_version', str(SCHEMA_VERSION)),
        ('built_at', today),
        ('tanzil_notice', notice),
    ])
    # drift reads user_version as the schema version; the app opens this
    # file read-only, so the version must already be set here.
    db.execute(f'PRAGMA user_version = {SCHEMA_VERSION}')
    word_boxes = build_word_boxes.build()
    db.executemany('INSERT INTO word_box VALUES (?,?,?,?,?,?,?,?,?)', [
        (s, a, n, page, math.floor(x0 * 10), math.floor(y0 * 10), math.ceil(x1 * 10), math.ceil(y1 * 10),
         int(exact))
        for (s, a), (exact, words) in word_boxes.items()
        for n, page, x0, y0, x1, y1 in words
    ])
    for page, cuts, overflow in build_line_cuts.new_edition():
        db.executemany('INSERT INTO line_cut VALUES (?,?,?,?)',
                       [('madina1441', page, j, round(y, 2)) for j, y in enumerate(cuts)])
        db.executemany('INSERT INTO line_overflow VALUES (?,?,?)', [(page, k, d) for k, d in overflow])
    if build_line_cuts.IMAGES.exists():
        for page, cuts, overflow in build_line_cuts.old_edition():
            db.executemany('INSERT INTO line_cut VALUES (?,?,?,?)',
                           [('madina1405', page, j, y) for j, y in enumerate(cuts)])
            db.executemany('INSERT INTO line_overflow_1405 VALUES (?,?,?,?,?,?)',
                           [(page, k, *b) for k, b in overflow])
    db.execute('CREATE INDEX line_overflow_page ON line_overflow(page)')
    db.execute('CREATE INDEX ayah_page ON ayah(page)')
    db.execute('CREATE INDEX word_box_page ON word_box(page)')
    db.execute('CREATE INDEX ayah_juz ON ayah(juz)')
    db.execute('CREATE INDEX ayah_page_shamarly ON ayah(page_shamarly)')
    db.execute('CREATE INDEX shamarly_line_overflow_page ON shamarly_line_overflow(page)')
    db.execute('CREATE INDEX shamarly_verse_box_page ON shamarly_verse_box(page)')
    db.execute('CREATE INDEX shamarly_word_box_page ON shamarly_word_box(page)')
    db.execute('CREATE INDEX shamarly_marker_page ON shamarly_marker(page)')
    db.commit()
    db.execute('VACUUM')
    db.close()

    check = sqlite3.connect(OUT)
    assert check.execute('SELECT COUNT(*) FROM ayah').fetchone()[0] == 6236
    assert check.execute('SELECT COUNT(DISTINCT page) FROM ayah').fetchone()[0] == 604
    assert check.execute('SELECT COUNT(DISTINCT page_1405) FROM ayah').fetchone()[0] == 604
    prefixed = check.execute('SELECT COUNT(*) FROM ayah WHERE basmala_prefix > 0').fetchone()[0]
    assert prefixed == 112, prefixed
    assert check.execute('PRAGMA user_version').fetchone()[0] == SCHEMA_VERSION
    assert check.execute('SELECT COUNT(*) FROM word_box').fetchone()[0] == 77430
    assert check.execute('SELECT COUNT(*) FROM commentary').fetchone()[0] == 3 * 6236
    assert check.execute('SELECT COUNT(DISTINCT reciter) FROM ayah_timing').fetchone()[0] == 6
    # Shamarly: every text page 2..522 carries verses; verses in order never go back a page.
    covered = {p for s, e in check.execute('SELECT page_shamarly, page_shamarly_end FROM ayah')
               for p in range(s, e + 1)}
    assert covered == set(range(2, 523)), sorted(set(range(2, 523)) ^ covered)
    ends = [r[0] for r in check.execute('SELECT page_shamarly_end FROM ayah ORDER BY id')]
    assert ends == sorted(ends)
    assert check.execute('SELECT COUNT(*) FROM shamarly_marker').fetchone()[0] == 6236
    print(f'built {OUT.relative_to(REPO)}: 6236 verses, 604 pages, '
          f'{len(polygons)} polygons, {OUT.stat().st_size // 1024} KB')
    return 0


if __name__ == '__main__':
    sys.exit(main())
