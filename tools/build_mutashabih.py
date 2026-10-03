"""Add the mutashabihat links (similar verses) to assets/db/content.db.

Structure only: the source lists, for a verse (or a run of verses), the
verses that resemble it. We store those links as verse-id ranges; no text
is copied or written. The app shows the verses' own text from the `ayah`
table, never any note or commentary.

Input (fetch_sources.py, id waqar144-mutashabihat):
  tools/.cache/waqar144_mutashabiha_data.json
    github.com/Waqar144/Quran_Mutashabihat_Data at commit f35f6d5, by
    Waqar Ahmed, "based on the work of Qari Idrees Al Asim". The README
    says the data "is free to use as you see fit", asking for a mention;
    there is no licence file. Verse numbers are absolute and 0-based
    (0 = 1:1), checked against 2:3 ~ 8:3 ~ 27:3 ~ 31:4.

QUL's mutashabihat (4,001 similar verses / 5,277 phrases) needs a QUL
account to download and has no licence yet (letter 1); it is not used.

Table:
  mutashabih(id, src_from, src_to, mut_from, mut_to, context, source_id)
    src_from..src_to  the verse ids (ayah.id, 1..6236) of the passage
    mut_from..mut_to  a passage that resembles it
    context           1 when the source marks the link as needing the
                      start of the next verse to tell the passages apart

Usage:
  python3 tools/build_mutashabih.py        # updates assets/db/content.db in place
  (build_content_db.py calls add() on a full build)
"""
import hashlib
import json
import sqlite3
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CACHE = ROOT / '.cache'
DATA = CACHE / 'waqar144_mutashabiha_data.json'
# 13..17 are taken; 18 and 19 are left for branches in flight.
SOURCE_ID = 20


def _span(entry):
    """(first, last) verse id, 1-based, of a src or mut entry."""
    ayah = entry['ayah']
    ids = ayah if isinstance(ayah, list) else [ayah]
    # One entry lists the same verse twice ([3947, 3947]).
    ids = sorted({i + 1 for i in ids})
    assert ids == list(range(ids[0], ids[-1] + 1)), ids
    assert all(1 <= i <= 6236 for i in ids), ids
    return ids[0], ids[-1]


def rows(data):
    """Links as (src_from, src_to, mut_from, mut_to, context), deduplicated,
    in the order of the source."""
    out, seen = [], set()
    for juz in sorted(data, key=int):
        for e in data[juz]:
            src = _span(e['src'])
            for m in e['muts']:
                row = (*src, *_span(m), 1 if e.get('ctx') else 0)
                if row[:4] not in seen and src != row[2:4]:
                    seen.add(row[:4])
                    out.append(row)
    return out


def add(db):
    """Creates the table in an open content database and fills it."""
    data = json.loads(DATA.read_text(encoding='utf-8'))
    links = rows(data)
    db.executescript('''
    DROP TABLE IF EXISTS mutashabih;
    CREATE TABLE mutashabih (               -- similar verses, as verse-id ranges (ayah.id)
      id INTEGER PRIMARY KEY,
      src_from INTEGER NOT NULL, src_to INTEGER NOT NULL,
      mut_from INTEGER NOT NULL, mut_to INTEGER NOT NULL,
      context INTEGER NOT NULL,             -- 1: show the start of the next verse too
      source_id INTEGER NOT NULL);
    CREATE INDEX mutashabih_src ON mutashabih(src_from);
    CREATE INDEX mutashabih_mut ON mutashabih(mut_from);
    ''')
    db.execute('DELETE FROM source WHERE id = ?', (SOURCE_ID,))
    db.execute('INSERT INTO source VALUES (?,?,?,?,?,?,?,?,?,?,?)', (
        SOURCE_ID, 'waqar144-mutashabihat', 'Quran mutashabihat (similar verses): links between verses',
        'Waqar Ahmed (Quran_Mutashabihat_Data), based on the work of Qari Idrees Al Asim', 'f35f6d5',
        'No licence file; README: "free to use as you see fit", a mention appreciated. Permission to be confirmed',
        'https://github.com/Waqar144/Quran_Mutashabihat_Data',
        'المتشابهات: Quran_Mutashabihat_Data (Waqar Ahmed، عن عمل القارئ إدريس العاصم)', None,
        hashlib.sha256(DATA.read_bytes()).hexdigest(), date.today().isoformat()))
    db.executemany(
        'INSERT INTO mutashabih (src_from, src_to, mut_from, mut_to, context, source_id) '
        'VALUES (?,?,?,?,?,?)', [(*r, SOURCE_ID) for r in links])
    return len(links)


def main():
    from build_content_db import SCHEMA_VERSION  # one number for both scripts
    out = ROOT.parent / 'assets' / 'db' / 'content.db'
    db = sqlite3.connect(out)
    n = add(db)
    db.execute("UPDATE meta SET value = ? WHERE key = 'schema_version'", (str(SCHEMA_VERSION),))
    db.execute(f'PRAGMA user_version = {SCHEMA_VERSION}')
    db.commit()
    db.execute('VACUUM')
    db.close()
    print(f'mutashabih: {n} links')
    return 0


if __name__ == '__main__':
    sys.exit(main())
