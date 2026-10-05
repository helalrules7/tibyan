"""Tiny reviewed books of every kind, exported with tools/export_pack.py.

Used by test_export_kinds.py, and by the app's test
(test/books/export_pipeline_test.dart), which runs this file to build the
packs and then reads them as the app does:

  python3 tools/tests/book_pack_fixtures.py OUT_DIR

writes OUT_DIR/<kind>.pack.db (and its .index.json) for each kind and
prints a JSON map {kind: pack path}.

Every text is a placeholder («نص تجريبي»); nothing is from a book. The
review steps are the ones the review tool records (submit by an editor,
approve by another person, both in the audit log).
"""
import json
import sys
import tempfile
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(TOOLS))

import export_pack  # noqa: E402
import review_db  # noqa: E402

# Only the counts the links need: the export checks every link against them.
SURAHS = [(1, 'الفاتحة', 7), (2, 'البقرة', 286)]

TAFSIR_TEXT = 'نص تفسير تجريبي {نص بين معقوفين} ثم ﴿نص آية تجريبي﴾.\nفقرة ثانية.'
WORD_TEXT = 'كلمة على وجهين: نص تجريبي، ونص تجريبي.'
WAJH_TEXT = 'فوجه منها: نص وجه تجريبي.'

# kind -> (source key, [(entry, links, reviewed)])
BOOKS = {
    'asbab_nuzul': ('fixture_asbab', [
        ({'kind': 'passage', 'section': 'عنوان تجريبي', 'text': 'نص سبب تجريبي.'},
         [{'surah': 2, 'ayah_from': 1, 'ayah_to': 2}], True),
        ({'kind': 'passage', 'section': None, 'text': 'نص لم يراجع.'},
         [{'surah': 2, 'ayah_from': 1, 'ayah_to': 1}], False),
    ]),
    'tafsir': ('fixture_tafsir', [
        ({'kind': 'passage', 'section': '[2.1-5]', 'text': TAFSIR_TEXT},
         [{'surah': 2, 'ayah_from': 1, 'ayah_to': 5}], True),
    ]),
    'munasabat': ('fixture_munasabat', [
        ({'kind': 'passage', 'section': '[2.2-3]', 'text': 'نص مناسبة تجريبي.'},
         [{'surah': 2, 'ayah_from': 2, 'ayah_to': 3}], True),
    ]),
    'wujuh_nazair': ('fixture_wujuh', [
        ({'kind': 'word', 'section': 'كلمة على وجهين', 'text': WORD_TEXT},
         [{'surah': 1, 'ayah_from': 1, 'ayah_to': 1}], True),
        ({'kind': 'wajh', 'section': 'كلمة على وجهين', 'text': WAJH_TEXT},
         [{'surah': 1, 'ayah_from': 1, 'ayah_to': 1, 'word_from': 3, 'word_to': 3}], True),
    ]),
}


def _act(db, entry_id, actor, role, action, to_state, **cols):
    """Writes what the review tool writes for one action."""
    h, state = db.execute('SELECT content_hash, state FROM entry WHERE id = ?',
                          (entry_id,)).fetchone()
    sets = ''.join(f', {k} = ?' for k in cols)
    db.execute(f'UPDATE entry SET state = ?{sets} WHERE id = ?',
               (to_state, *cols.values(), entry_id))
    db.execute(
        'INSERT INTO audit (entry_id, at, actor, role, action, from_state, to_state, '
        'hash_before, hash_after) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        (entry_id, review_db.now(), actor, role, action, state, to_state, h, h))


def review_db_for(kind, path):
    """A review database holding the fixture book of `kind`, its entries
    reviewed as BOOKS says."""
    key, entries = BOOKS[kind]
    db = review_db.create(path)
    db.executemany('INSERT INTO surah VALUES (?, ?, ?)', SURAHS)
    sid = review_db.add_source(db, {
        'key': key, 'kind': kind, 'title': f'كتاب تجريبي ({kind})', 'author': 'مؤلف تجريبي',
        'licence': 'test', 'url': 'about:blank', 'file': 'f', 'sha256': '0' * 64,
        'retrieved_at': '2026-10-05'})
    for seq, (entry, links, reviewed) in enumerate(entries, 1):
        e = {'seq': seq, 'volume': 1, 'page': seq, 'page_end': seq, **entry}
        full = [{'basis': 'marker', 'confidence': 1.0, **l} for l in links]
        entry_id = review_db.add_draft(db, sid, key, e, full, 'script:fixture')
        _act(db, entry_id, 'محرر', 'editor', 'submit', 'in_review', editor='محرر')
        if reviewed:
            _act(db, entry_id, 'مراجع', 'reviewer', 'approve', 'reviewed',
                 reviewer='مراجع', reviewed_at=review_db.now())
    db.commit()
    db.close()


def build(out_dir):
    """Exports one pack per kind into out_dir; returns {kind: pack path}."""
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    packs = {}
    with tempfile.TemporaryDirectory() as tmp:
        for kind in BOOKS:
            review = Path(tmp) / f'{kind}.review.db'
            review_db_for(kind, review)
            out = out_dir / f'{kind}.pack.db'
            export_pack.export(review, out)
            packs[kind] = str(out)
    return packs


if __name__ == '__main__':
    print(json.dumps(build(sys.argv[1]), ensure_ascii=False))
