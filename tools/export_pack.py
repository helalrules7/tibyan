"""Build a data pack (SQLite) from a review database: reviewed rows only.

Every exported entry must be in state 'reviewed', have a reviewer who is
not its editor, still match the content hash the reviewer approved (the
hash is recomputed here), and have an 'approve' row in the audit log for
that hash by that reviewer. Any reviewed entry that fails a check stops
the export: it means the review database was changed outside the tool.

Text is copied byte for byte. Nothing is edited.

The pack gets an index (pack_index table, and <pack>.index.json beside it)
with counts, reviewers, the review database's SHA-256 and the pack's
content hash. The script then prints the data(...) commit message and the
docs/DATA_SOURCES.md row to add by hand.

Usage:
  python3 tools/export_pack.py data/review/wahidi_asbab.review.db \\
      --out data/packs/asbab_wahidi.pack.db

Test packs (closed testing only, owner's decision 2026-10-05):
  python3 tools/export_pack.py data/review/wahidi_asbab.review.db \\
      --out test-asbab-wahidi.pack.db --test-drafts
exports every entry as it stands, drafts included, unreviewed. Each text is
still checked against the content hash the import wrote (so it is exactly
what was imported), and copied byte for byte. The pack is stamped as test
data: pack_index `status` = `test-drafts`, each book title ends with
TEST_TITLE_SUFFIX, and an unreviewed entry has an empty reviewer. The app
shows such a pack's unreviewed entries only because of that status; a test
pack must never be listed for a public release.
"""
import argparse
import hashlib
import json
import sqlite3
import sys
from pathlib import Path

import review_db

PACK_FORMAT = '1'
TEST_STATUS = 'test-drafts'
TEST_TITLE_SUFFIX = ' (مسودة للاختبار)'

PACK_SCHEMA = """
CREATE TABLE pack_index (key TEXT PRIMARY KEY, value TEXT NOT NULL);
CREATE TABLE source (
  id INTEGER PRIMARY KEY, key TEXT NOT NULL UNIQUE, kind TEXT NOT NULL,
  title TEXT NOT NULL, author TEXT NOT NULL, edition TEXT, publisher TEXT,
  tahqiq TEXT, licence TEXT NOT NULL, digitised_by TEXT, url TEXT NOT NULL,
  sha256 TEXT NOT NULL, citation TEXT
);
CREATE TABLE entry (
  id INTEGER PRIMARY KEY, source_id INTEGER NOT NULL REFERENCES source(id),
  seq INTEGER NOT NULL, kind TEXT NOT NULL, section TEXT,
  volume INTEGER, page INTEGER, page_end INTEGER, text TEXT NOT NULL,
  content_hash TEXT NOT NULL, editor TEXT NOT NULL, reviewer TEXT NOT NULL,
  reviewed_at TEXT NOT NULL
);
CREATE TABLE entry_link (
  entry_id INTEGER NOT NULL REFERENCES entry(id), surah INTEGER NOT NULL,
  ayah_from INTEGER NOT NULL, ayah_to INTEGER NOT NULL,
  word_from INTEGER, word_to INTEGER
);
CREATE INDEX entry_link_verse ON entry_link (surah, ayah_from);
"""


class ExportError(Exception):
    pass


def check_entry(db, row, source_keys, verse_counts):
    """Returns a list of problems with one reviewed entry (empty when fine)."""
    (entry_id, source_id, volume, page, page_end, text, editor, reviewer,
     content_hash) = row
    problems = []
    if not reviewer or not editor or reviewer == editor:
        problems.append('reviewer missing or same as editor')
    links = review_db.links_of(db, entry_id)
    actual = review_db.content_hash(source_keys[source_id], volume, page, page_end, text, links)
    if actual != content_hash:
        problems.append('content changed after review (hash mismatch)')
    approve = db.execute(
        "SELECT actor, hash_after FROM audit WHERE entry_id = ? AND action = 'approve' "
        'ORDER BY id DESC LIMIT 1', (entry_id,)).fetchone()
    if approve is None or approve[0] != reviewer or approve[1] != content_hash:
        problems.append('no approval in the audit log for this content by this reviewer')
    for l in links:
        count = verse_counts.get(l['surah'])
        if count is None or not (1 <= l['ayah_from'] <= l['ayah_to'] <= count):
            problems.append(f"link outside the mushaf: {l}")
    return problems


def check_draft(db, row, source_keys, verse_counts):
    """Problems with one entry of a test export (empty when fine): its text
    and links must still match the hash written when it was imported or
    last saved, and its links must be in the mushaf. Review is not
    required."""
    entry_id, source_id, volume, page, page_end, text = row[:6]
    content_hash = row[8]
    problems = []
    links = review_db.links_of(db, entry_id)
    if review_db.content_hash(source_keys[source_id], volume, page, page_end, text,
                              links) != content_hash:
        problems.append('content does not match its hash')
    for l in links:
        count = verse_counts.get(l['surah'])
        if count is None or not (1 <= l['ayah_from'] <= l['ayah_to'] <= count):
            problems.append(f"link outside the mushaf: {l}")
    return problems


def export(review_path, out, allow_empty=False, test_drafts=False):
    review_path, out = Path(review_path), Path(out)
    if out.exists():
        raise ExportError(f'{out} exists')
    db = sqlite3.connect(f'file:{review_path}?mode=ro', uri=True)
    try:
        return _export(db, review_path, out, allow_empty, test_drafts)
    finally:
        db.close()


def _export(db, review_path, out, allow_empty, test_drafts=False):
    source_keys = dict(db.execute('SELECT id, key FROM source'))
    verse_counts = dict(db.execute('SELECT id, ayah_count FROM surah'))
    rows = db.execute(
        'SELECT id, source_id, volume, page, page_end, text, editor, reviewer, content_hash '
        'FROM entry ' + ('' if test_drafts else "WHERE state = 'reviewed' ")
        + 'ORDER BY source_id, seq').fetchall()
    if not rows and not allow_empty:
        raise ExportError('no entries: nothing to export' if test_drafts
                          else 'no reviewed entries: nothing to export')
    failures = {}
    for row in rows:
        problems = (check_draft if test_drafts else check_entry)(db, row, source_keys,
                                                                 verse_counts)
        if problems:
            failures[row[0]] = problems
    if failures:
        raise ExportError(('entries' if test_drafts else 'reviewed entries')
                          + ' failed their checks: ' + json.dumps(failures, ensure_ascii=False))

    out.parent.mkdir(parents=True, exist_ok=True)
    pack = sqlite3.connect(out)
    pack.executescript(PACK_SCHEMA)
    used_sources = sorted({r[1] for r in rows})
    for sid in used_sources:
        row = db.execute('SELECT id, key, kind, title, author, edition, publisher, tahqiq, licence, '
                         'digitised_by, url, sha256 FROM source WHERE id = ?', (sid,)).fetchone()
        # The citation wording a publisher asked for, kept as given
        # (tools/import_dar_alathar.py stores it in meta).
        citation = db.execute('SELECT value FROM meta WHERE key = ?',
                              (f'source_citation:{row[1]}',)).fetchone()
        if test_drafts:
            # The title (ours to label, not the book's text) says it is a test draft.
            row = (*row[:3], row[3] + TEST_TITLE_SUFFIX, *row[4:])
        pack.execute('INSERT INTO source VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                     (*row, citation[0] if citation else None))
    ids = [r[0] for r in rows]
    hashes = []
    links = 0
    for entry_id in ids:
        e = db.execute(
            'SELECT id, source_id, seq, kind, section, volume, page, page_end, text, content_hash, '
            'editor, reviewer, reviewed_at FROM entry WHERE id = ?', (entry_id,)).fetchone()
        if test_drafts:
            # A draft has no editor or reviewer yet: its importer stands as
            # the editor, and the reviewer stays empty (unreviewed).
            created_by = db.execute('SELECT created_by FROM entry WHERE id = ?',
                                    (entry_id,)).fetchone()[0]
            e = (*e[:10], e[10] or created_by, e[11] or '', e[12] or '')
        pack.execute('INSERT INTO entry VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', e)
        hashes.append(e[9])
        for l in db.execute('SELECT entry_id, surah, ayah_from, ayah_to, word_from, word_to '
                            'FROM entry_link WHERE entry_id = ? ORDER BY surah, ayah_from',
                            (entry_id,)):
            pack.execute('INSERT INTO entry_link VALUES (?, ?, ?, ?, ?, ?)', l)
            links += 1

    reviewers = sorted({r[7] for r in rows if r[7]})
    index = {
        'format': PACK_FORMAT,
        'kind': ','.join(sorted({db.execute('SELECT kind FROM source WHERE id = ?', (s,)).fetchone()[0]
                                 for s in used_sources})),
        'sources': [source_keys[s] for s in used_sources],
        'created_at': review_db.now(),
        'entries': len(ids),
        'links': links,
        'reviewers': reviewers,
        'review_db': review_path.name,
        'review_db_sha256': review_db.sha256_file(review_path),
        'content_sha256': hashlib.sha256('\n'.join(hashes).encode()).hexdigest(),
        'entries_in_review_db': db.execute('SELECT count(*) FROM entry').fetchone()[0],
    }
    if test_drafts:
        index['status'] = TEST_STATUS
        index['entries_reviewed'] = sum(1 for r in rows if r[7])
    for k, v in index.items():
        pack.execute('INSERT INTO pack_index VALUES (?, ?)',
                     (k, v if isinstance(v, str) else json.dumps(v, ensure_ascii=False)))
    pack.commit()
    pack.close()
    index['pack_sha256'] = review_db.sha256_file(out)
    Path(str(out) + '.index.json').write_text(
        json.dumps(index, ensure_ascii=False, indent=2, sort_keys=True) + '\n', encoding='utf-8')
    return index


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('review_db', type=Path)
    ap.add_argument('--out', type=Path, required=True)
    ap.add_argument('--allow-empty', action='store_true')
    ap.add_argument('--test-drafts', action='store_true',
                    help='closed testing only: export every entry, drafts included, '
                         'stamped as test data (see the module docstring)')
    args = ap.parse_args(argv)
    try:
        index = export(args.review_db, args.out, args.allow_empty, args.test_drafts)
    except ExportError as e:
        print(f'export refused: {e}', file=sys.stderr)
        return 1
    print(json.dumps(index, ensure_ascii=False, indent=1, sort_keys=True))
    if args.test_drafts:
        print(f"\nTEST PACK ({TEST_STATUS}): {index['entries']} entries, "
              f"{index['entries_reviewed']} reviewed. For closed testing only.")
        return 0
    print('\nCommit it on its own:')
    print(f"  data({index['kind']}): pack of {index['entries']} reviewed entries from "
          f"{', '.join(index['sources'])}")
    print('Add to docs/DATA_SOURCES.md:')
    print(f"  | {index['kind']} pack | {', '.join(index['sources'])} | reviewed by "
          f"{', '.join(index['reviewers'])} | {index['entries']} entries, {index['links']} links | "
          f"`{index['pack_sha256'][:8]}…{index['pack_sha256'][-4:]}` |")
    return 0


if __name__ == '__main__':
    sys.exit(main())
