"""Import Dar al-Athar's SQLite file of «الصحيح المسند من أسباب النزول» as review drafts.

The book is Shaykh Muqbil b. Hadi al-Wadi'i's, published by Dar al-Athar
(Sanaa), the body his heirs authorise; they gave permission on 2026-09-28
and prepare the file themselves. The shape we asked for:

  asbab(id, surah, title, text, page)          one occasion of revelation
  links(asbab_id, surah, ayah_from, ayah_to)    the verses it is about
  meta(edition, citation)                       one row (or key/value rows)

What the script does (structure only, never the text):
  * reads each row and stores its text byte for byte as a draft entry
    (kind 'passage', the row's title as the entry's section, its page);
  * stores each link as the publisher gave it: basis 'marker', confidence 1;
  * stores the edition in the source row and the citation wording the
    publisher chose in the review database's meta
    (`source_citation:<source key>`), which export_pack.py copies into the
    pack so the app shows it exactly.

It fails loudly, and writes nothing, when the file is not what we expect:
a missing table or column, a column we do not know (it may hold something
the text needs), an empty text, a verse outside the mushaf, a link to a
missing row, a row with no link, symbol glyphs (ﷺ and the like: we asked for
the salawat and taraddi in letters), markup, or carriage returns. Column and
table names can be mapped when the publisher's differ (--map).

Everything lands as a draft. A reviewer qualified in hadith checks every
entry in apps/review/ before anything reaches a pack.

Usage:
  python3 tools/import_dar_alathar.py FILE.sqlite
  python3 tools/import_dar_alathar.py FILE.sqlite --out X.review.db \\
      --map asbab.text=nass --map links=ayat
"""
import argparse
import json
import re
import sqlite3
import sys
from pathlib import Path

import review_db

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent
SCRIPT = 'script:import_dar_alathar@1'
DEFAULT_OUT = REPO / 'data' / 'review' / 'sahih_musnad_asbab.review.db'
CONTENT_DB = REPO / 'assets' / 'db' / 'content.db'

SOURCE_ROW = {
    'key': 'sahih_musnad_asbab_wadii',
    'kind': 'asbab_nuzul',
    'title': 'الصحيح المسند من أسباب النزول',
    'author': 'مقبل بن هادي الوادعي (ت 1422هـ)',
    'publisher': 'دار الآثار للنشر والتوزيع - صنعاء',
    'tahqiq': None,
    'licence': 'Permission from Dar al-Athar, the publisher authorised by the author and '
               'his heirs (email of 2026-09-28: docs/licenses/2026-09-28_dar-alathar_reply_email.pdf)',
    'digitised_by': 'دار الآثار (ملف SQLite أعدّته الدار)',
    'url': 'https://www.dar-alathar.com/',
}

# The fields we read, and their default names in the publisher's file.
DEFAULT_MAP = {
    'asbab': {'table': 'asbab', 'id': 'id', 'surah': 'surah', 'title': 'title',
              'text': 'text', 'page': 'page'},
    'links': {'table': 'links', 'asbab_id': 'asbab_id', 'surah': 'surah',
              'ayah_from': 'ayah_from', 'ayah_to': 'ayah_to'},
    'meta': {'table': 'meta', 'edition': 'edition', 'citation': 'citation'},
}
OPTIONAL = {('asbab', 'title'), ('asbab', 'page'), ('meta', 'citation')}

# Ligature and symbol glyphs instead of words (ﷺ ﷻ ﷽ …), and private-use
# code points that only a special font draws: the text must spell them out.
# The verse brackets ﴿ ﴾ (U+FD3F, U+FD3E) are wanted and not in this range.
SYMBOLS = re.compile('[\\uFDF0-\\uFDFF\\uE000-\\uF8FF]')
MARKUP = re.compile(r'<\s*/?\s*[A-Za-z][^>]*>|&[a-z]+;|&#\d+;')


class ImportError_(Exception):
    """The file is not what the script expects; nothing was written."""


def parse_map(items):
    """`--map asbab.text=nass` renames a column, `--map links=ayat` a table."""
    mapping = json.loads(json.dumps(DEFAULT_MAP))
    for item in items or []:
        key, sep, value = item.partition('=')
        table, _, field = key.partition('.')
        if not sep or not value or table not in mapping:
            raise ImportError_(f'bad --map {item!r}: use TABLE=NAME or TABLE.FIELD=NAME')
        if field and field not in mapping[table]:
            raise ImportError_(f'bad --map {item!r}: {table} has no field {field!r}')
        mapping[table][field or 'table'] = value
    return mapping


def columns(src, table):
    return [r[1] for r in src.execute(f'PRAGMA table_info("{table}")')]


def read_file(path, mapping, allow_extra=False):
    """Reads the publisher's file. Returns (rows, links, meta, warnings);
    raises ImportError_ listing every problem found."""
    src = sqlite3.connect(f'file:{path}?mode=ro', uri=True)
    problems, warnings = [], []
    try:
        tables = {r[0] for r in src.execute("SELECT name FROM sqlite_master WHERE type = 'table'")}
        cols = {}
        for part, fields in mapping.items():
            table = fields['table']
            if table not in tables:
                problems.append(f'table {table!r} ({part}) is missing; tables: {sorted(tables)}')
                continue
            have = columns(src, table)
            cols[part] = have
            if part == 'meta' and {'key', 'value'} <= set(have):
                continue  # key/value rows
            for field, name in fields.items():
                if field == 'table' or name in have:
                    continue
                if (part, field) in OPTIONAL:
                    warnings.append(f'{table}.{name} is missing')
                else:
                    problems.append(f'column {table}.{name} ({part}.{field}) is missing; '
                                    f'columns: {have}')
            known = {n for f, n in fields.items() if f != 'table'}
            extra = [c for c in have if c not in known]
            if extra:
                msg = f'{table} has columns the script does not read: {extra}'
                (warnings if allow_extra else problems).append(msg)
        unexpected = sorted(t for t in tables - {f['table'] for f in mapping.values()}
                            if not t.startswith('sqlite_'))
        if unexpected:
            msg = f'tables the script does not read: {unexpected}'
            (warnings if allow_extra else problems).append(msg)
        if problems:
            raise ImportError_('\n'.join(problems))

        def select(part, fields):
            m = mapping[part]
            have = cols[part]
            exprs = [f'"{m[f]}"' if m[f] in have else 'NULL' for f in fields]
            return src.execute(f'SELECT {", ".join(exprs)} FROM "{m["table"]}"').fetchall()

        rows = [dict(zip(('id', 'surah', 'title', 'text', 'page'), r))
                for r in select('asbab', ('id', 'surah', 'title', 'text', 'page'))]
        links = [dict(zip(('asbab_id', 'surah', 'ayah_from', 'ayah_to'), r))
                 for r in select('links', ('asbab_id', 'surah', 'ayah_from', 'ayah_to'))]
        if {'key', 'value'} <= set(cols['meta']):
            meta = {k: v for k, v in src.execute(f'SELECT key, value FROM "{mapping["meta"]["table"]}"')}
            meta = {'edition': meta.get(mapping['meta']['edition']),
                    'citation': meta.get(mapping['meta']['citation'])}
        else:
            meta_rows = select('meta', ('edition', 'citation'))
            if len(meta_rows) != 1:
                raise ImportError_(f'meta should have one row, it has {len(meta_rows)}')
            meta = dict(zip(('edition', 'citation'), meta_rows[0]))
    finally:
        src.close()
    return rows, links, meta, warnings


def check(rows, links, meta, ayah_counts, allow_unlinked=False):
    """Every problem with the data, as a list of strings (empty when fine)."""
    problems = []
    ids = set()
    for r in rows:
        where = f'asbab id {r["id"]!r}'
        if not isinstance(r['id'], int):
            problems.append(f'{where}: id is not an integer')
        elif r['id'] in ids:
            problems.append(f'{where}: id appears twice')
        ids.add(r['id'])
        if not isinstance(r['surah'], int) or r['surah'] not in ayah_counts:
            problems.append(f'{where}: surah {r["surah"]!r} is not 1-114')
        if not isinstance(r['text'], str) or not r['text'].strip():
            problems.append(f'{where}: text is empty')
            continue
        if r['title'] is not None and not isinstance(r['title'], str):
            problems.append(f'{where}: title is not text')
        if r['page'] is not None and (not isinstance(r['page'], int) or r['page'] < 1):
            problems.append(f'{where}: page {r["page"]!r} is not a page number')
        for field in ('text', 'title'):
            value = r[field] or ''
            symbols = sorted(set(SYMBOLS.findall(value)))
            if symbols:
                problems.append(f'{where}: {field} has symbol glyphs '
                                f'{[f"U+{ord(c):04X}" for c in symbols]}; they should be in letters')
            if MARKUP.search(value):
                problems.append(f'{where}: {field} has markup ({MARKUP.search(value).group(0)!r})')
            if '\r' in value:
                problems.append(f'{where}: {field} has carriage returns (\\r)')
    seen = set()
    linked = set()
    for l in links:
        where = f'link {l["asbab_id"]!r} → {l["surah"]!r}:{l["ayah_from"]!r}-{l["ayah_to"]!r}'
        if l['asbab_id'] not in ids:
            problems.append(f'{where}: no asbab row with that id')
        values = (l['surah'], l['ayah_from'], l['ayah_to'])
        if not all(isinstance(v, int) for v in values):
            problems.append(f'{where}: surah and verses must be integers')
            continue
        count = ayah_counts.get(l['surah'])
        if count is None or not (1 <= l['ayah_from'] <= l['ayah_to'] <= count):
            problems.append(f'{where}: outside the mushaf'
                            + (f' (surah {l["surah"]} has {count} verses)' if count else ''))
        key = (l['asbab_id'], *values)
        if key in seen:
            problems.append(f'{where}: the same link appears twice')
        seen.add(key)
        linked.add(l['asbab_id'])
    if not allow_unlinked:
        for r in rows:
            if r['id'] not in linked:
                problems.append(f'asbab id {r["id"]!r}: no verse linked')
    edition = meta.get('edition')
    if not isinstance(edition, str) or not edition.strip():
        problems.append('meta: edition is missing')
    citation = meta.get('citation')
    if citation is not None and (not isinstance(citation, str) or not citation.strip()):
        problems.append('meta: citation is empty')
    return problems


def build(path, out, content_db, mapping, allow_extra=False, allow_unlinked=False):
    """Writes the review database. Returns stats; raises ImportError_."""
    path, out = Path(path), Path(out)
    if out.exists():
        raise ImportError_(f'{out} exists; it may hold review work')
    content = sqlite3.connect(f'file:{content_db}?mode=ro', uri=True)
    ayah_counts = dict(content.execute('SELECT id, ayah_count FROM surah'))
    content.close()
    rows, links, meta, warnings = read_file(path, mapping, allow_extra)
    problems = check(rows, links, meta, ayah_counts, allow_unlinked)
    if problems:
        raise ImportError_('\n'.join(problems))
    if not rows:
        raise ImportError_('the file has no asbab rows')

    by_entry = {}
    for l in links:
        by_entry.setdefault(l['asbab_id'], []).append(l)

    db = review_db.create(out, content_db)
    source = dict(SOURCE_ROW, edition=meta['edition'], file=path.name,
                  sha256=review_db.sha256_file(path), retrieved_at=review_db.now()[:10])
    source_id = review_db.add_source(db, source)
    if meta.get('citation'):
        db.execute('INSERT INTO meta VALUES (?, ?)',
                   (f'source_citation:{source["key"]}', meta['citation']))
    stats = {'entries': 0, 'links': 0, 'unlinked': 0, 'other_surah_links': 0,
             'warnings': warnings}
    for seq, r in enumerate(sorted(rows, key=lambda r: r['id']), 1):
        entry_links = [{'surah': l['surah'], 'ayah_from': l['ayah_from'], 'ayah_to': l['ayah_to'],
                        'quote': None, 'basis': 'marker', 'confidence': 1.0}
                       for l in sorted(by_entry.get(r['id'], []),
                                       key=lambda l: (l['surah'], l['ayah_from'], l['ayah_to']))]
        notes = [f'Dar al-Athar row id {r["id"]}']
        other = [l for l in entry_links if l['surah'] != r['surah']]
        if other:
            notes.append(f'linked outside its surah ({r["surah"]}): '
                         + ', '.join(f'{l["surah"]}:{l["ayah_from"]}-{l["ayah_to"]}' for l in other))
            stats['other_surah_links'] += 1
        if not entry_links:
            notes.append('no verse linked in the publisher\'s file')
            stats['unlinked'] += 1
        entry = {'seq': seq, 'kind': 'passage', 'section': r['title'], 'volume': None,
                 'page': r['page'], 'page_end': r['page'], 'text': r['text'], 'notes': notes}
        review_db.add_draft(db, source_id, source['key'], entry, entry_links, SCRIPT)
        stats['entries'] += 1
        stats['links'] += len(entry_links)

    # Prove the text went in byte for byte.
    stored = dict(db.execute('SELECT seq, text FROM entry'))
    for seq, r in enumerate(sorted(rows, key=lambda r: r['id']), 1):
        if stored[seq] != r['text']:
            raise ImportError_(f'asbab id {r["id"]}: stored text differs from the file')
    db.execute("INSERT INTO meta VALUES ('import_stats', ?)",
               (json.dumps(stats, ensure_ascii=False, sort_keys=True),))
    db.commit()
    db.close()
    return stats


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('file', type=Path, help="Dar al-Athar's SQLite file")
    ap.add_argument('--out', type=Path, default=DEFAULT_OUT)
    ap.add_argument('--content-db', type=Path, default=CONTENT_DB)
    ap.add_argument('--map', action='append', metavar='TABLE[.FIELD]=NAME',
                    help='a table or column name in the file that differs from the default')
    ap.add_argument('--allow-extra-columns', action='store_true',
                    help='import even when the file has tables or columns the script does not read')
    ap.add_argument('--allow-unlinked', action='store_true',
                    help='import rows that have no verse link (noted on the entry)')
    args = ap.parse_args(argv)
    try:
        stats = build(args.file, args.out, args.content_db, parse_map(args.map),
                      args.allow_extra_columns, args.allow_unlinked)
    except ImportError_ as e:
        print(f'import refused, nothing written:\n{e}', file=sys.stderr)
        return 1
    print(json.dumps(stats, ensure_ascii=False, sort_keys=True, indent=1))
    return 0


if __name__ == '__main__':
    sys.exit(main())
