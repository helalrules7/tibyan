"""Shared helpers for review databases (schema in review_schema.sql).

Structure only: these helpers store text exactly as given and compute
hashes. They never change religious or scholarly text.

The content hash is defined here and in apps/review/lib/src/model/
content_hash.dart; both must give the same value for the same entry
(tools/tests/test_review_db.py and the Dart tests check one fixed case).
"""
import hashlib
import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SCHEMA = ROOT / 'review_schema.sql'
SCHEMA_VERSION = '1'


def now():
    return datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')


def sha256_file(path):
    digest = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            digest.update(chunk)
    return digest.hexdigest()


def _link_key(link):
    return (link['surah'], link['ayah_from'], link['ayah_to'],
            link.get('word_from') or 0, link.get('word_to') or 0)


def content_hash(source_key, volume, page, page_end, text, links):
    """SHA-256 of what a reviewer approves: the passage, where it is in the
    edition, and the verses it is linked to. Notes are not part of it."""
    canonical = {
        'links': [
            {
                'ayah_from': l['ayah_from'],
                'ayah_to': l['ayah_to'],
                'surah': l['surah'],
                'word_from': l.get('word_from'),
                'word_to': l.get('word_to'),
            }
            for l in sorted(links, key=_link_key)
        ],
        'page': page,
        'page_end': page_end,
        'source': source_key,
        'text': text,
        'volume': volume,
    }
    data = json.dumps(canonical, ensure_ascii=False, sort_keys=True, separators=(',', ':'))
    return hashlib.sha256(data.encode('utf-8')).hexdigest()


def create(path, content_db=None):
    """Creates an empty review database at `path` (which must not exist).
    With `content_db`, copies the surah and verse tables from it verbatim."""
    path = Path(path)
    if path.exists():
        raise FileExistsError(f'{path} exists; it may hold review work')
    path.parent.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(path)
    db.executescript(SCHEMA.read_text(encoding='utf-8'))
    db.execute('PRAGMA foreign_keys = ON')
    db.execute("INSERT INTO meta VALUES ('schema_version', ?)", (SCHEMA_VERSION,))
    db.execute("INSERT INTO meta VALUES ('created_at', ?)", (now(),))
    if content_db is not None:
        copy_verses(db, content_db)
    db.commit()
    return db


def copy_verses(db, content_db):
    src = sqlite3.connect(f'file:{content_db}?mode=ro', uri=True)
    db.executemany('INSERT INTO surah VALUES (?, ?, ?)',
                   src.execute('SELECT id, name_ar, ayah_count FROM surah ORDER BY id'))
    db.executemany(
        'INSERT INTO verse VALUES (?, ?, ?, ?, ?, ?)',
        src.execute('SELECT surah, number, display_text, text_search, search_basmala_prefix, page '
                    'FROM ayah ORDER BY surah, number'))
    # Tanzil's licence asks for its notice in every file holding its text
    # (text_search is Tanzil Simple Clean); display_text is KFGQPC Hafs 2.0.
    notice = src.execute("SELECT value FROM meta WHERE key = 'tanzil_notice'").fetchone()
    credits = src.execute(
        'SELECT key, title, publisher, version, license, url, attribution FROM source '
        "WHERE key IN ('tanzil-simple-clean', 'kfgqpc-hafs-2.0')").fetchall()
    src.close()
    if notice:
        db.execute("INSERT INTO meta VALUES ('tanzil_notice', ?)", notice)
    db.execute("INSERT INTO meta VALUES ('verse_sources', ?)", (json.dumps(
        [dict(zip(('key', 'title', 'publisher', 'version', 'license', 'url', 'attribution'), c))
         for c in credits], ensure_ascii=False),))
    db.execute("INSERT INTO meta VALUES ('content_db_sha256', ?)", (sha256_file(content_db),))


def add_source(db, row):
    cols = ', '.join(row)
    marks = ', '.join('?' for _ in row)
    cur = db.execute(f'INSERT INTO source ({cols}) VALUES ({marks})', tuple(row.values()))
    return cur.lastrowid


def add_draft(db, source_id, source_key, entry, links, created_by):
    """Inserts one draft entry with its suggested links and an 'import'
    audit row. `entry` holds seq, kind, section, volume, page, page_end, text."""
    at = now()
    h = content_hash(source_key, entry['volume'], entry['page'], entry['page_end'],
                     entry['text'], links)
    best = max((l['confidence'] for l in links), default=None)
    cur = db.execute(
        'INSERT INTO entry (source_id, seq, kind, section, volume, page, page_end, text, '
        'created_by, created_at, script_confidence, state, content_hash, updated_at) '
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'draft', ?, ?)",
        (source_id, entry['seq'], entry['kind'], entry['section'], entry['volume'],
         entry['page'], entry['page_end'], entry['text'], created_by, at, best, h, at))
    entry_id = cur.lastrowid
    for l in links:
        db.execute(
            'INSERT INTO entry_link (entry_id, surah, ayah_from, ayah_to, word_from, word_to, '
            'quote, basis, confidence, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            (entry_id, l['surah'], l['ayah_from'], l['ayah_to'], l.get('word_from'),
             l.get('word_to'), l.get('quote'), l['basis'], l['confidence'], created_by))
    db.execute(
        'INSERT INTO audit (entry_id, at, actor, role, action, to_state, hash_after, detail) '
        "VALUES (?, ?, ?, 'script', 'import', 'draft', ?, ?)",
        (entry_id, at, created_by, h,
         json.dumps({'links': len(links), 'notes': entry.get('notes', [])}, ensure_ascii=False)))
    return entry_id


def links_of(db, entry_id):
    rows = db.execute(
        'SELECT surah, ayah_from, ayah_to, word_from, word_to FROM entry_link WHERE entry_id = ?',
        (entry_id,)).fetchall()
    return [dict(zip(('surah', 'ayah_from', 'ayah_to', 'word_from', 'word_to'), r)) for r in rows]
