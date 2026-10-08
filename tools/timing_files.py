"""Recitation timings kept as text in `data/timing/`, one file per reciter
per surah, so anyone can correct them in a pull request.

The files hold times only, never Quran text: each verse's start and end in
the surah's audio file, and each word's start and end, words numbered as in
`content.db`'s `word_box` (KFGQPC words, the hizb sign not counted).

    {
      "format": 1,
      "reciter": "sudais",
      "surah": 1,
      "verses": [
        [1, 3720, 6040, [[1, 3721, 3979], [2, 4058, 4494], ...]],
        ...
      ]
    }

One verse per line, so a change shows as the verses it touched. Times are
whole milliseconds from the start of the surah file; verse 0 is the opening
before verse 1 (it never has words). A verse with an empty word list has no
word timings yet.

`data/timing/reciters.json` lists every recitation and whether its timing
may be published; only those marked `"publish": true` have files here.
`data/timing/verse_words.json` holds how many words each verse has (counts
only), and `data/timing/<slug>/audio.json` each surah file's duration, so
the checks need neither the database nor the audio.

The same rules are checked by the editor (`apps/timing-editor/js/model.js`);
`tools/tests/timing_cases.json` holds the cases both must agree on.

Usage:
  python3 tools/timing_files.py export SLUG          files from assets/db/content.db
  python3 tools/timing_files.py check [--base REF_DIR] [--json OUT] [FILES...]
  python3 tools/timing_files.py pack --out DIR       packs and manifest.json for the server
  python3 tools/timing_files.py site --out DIR       the editor with its data, for GitHub Pages
  python3 tools/timing_files.py verse-words          writes data/timing/verse_words.json
  python3 tools/timing_files.py known-errors         writes data/timing/known_errors.json
  python3 tools/timing_files.py fix-known [SLUG...]  fixes the known errors that need no listening
"""
import argparse
import gzip
import hashlib
import io
import json
import re
import shutil
import sqlite3
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent
DATA = REPO / 'data' / 'timing'
DB = REPO / 'assets' / 'db' / 'content.db'
EDITOR = REPO / 'apps' / 'timing-editor'
FORMAT = 1
# Words may cross into the next verse, or past their verse's window, by
# this much before it counts as an error: the shipped timings were measured
# on 10 ms frames and some carry a few tens of ms of rounding.
TOLERANCE_MS = 50
# mp3quran's published verse ends run up to ~350 ms past the end of some
# files; past that by this much is a warning, further an error.
DURATION_SLACK_MS = 500
FILE_RE = re.compile(r'^data/timing/([a-z0-9-]+)/(\d{3})\.json$')
HIZB = '۞'  # ۞, drawn but not a word


# ------------------------------------------------------------------ format

def dumps(doc):
    """The canonical text of a timing file: one verse per line."""
    lines = [
        '{',
        f'  "format": {FORMAT},',
        f'  "reciter": {json.dumps(doc["reciter"])},',
        f'  "surah": {int(doc["surah"])},',
        '  "verses": [',
    ]
    verses = doc['verses']
    for i, v in enumerate(verses):
        sep = ',' if i < len(verses) - 1 else ''
        lines.append('    ' + json.dumps(v, separators=(', ', ': ')) + sep)
    lines += ['  ]', '}']
    return '\n'.join(lines) + '\n'


def load_json(path):
    return json.loads(Path(path).read_text(encoding='utf-8'))


def reciters():
    return load_json(DATA / 'reciters.json')['reciters']


def published():
    """Reciters whose timing is published here, by slug."""
    return {r['slug']: r for r in reciters() if r.get('publish')}


def verse_words():
    """{surah: [word count of verse 1, verse 2, ...]}, Hafs."""
    surahs = load_json(DATA / 'verse_words.json')['surahs']
    return {i: counts for i, counts in enumerate(surahs, start=1)}


def counts_for(slug, surah):
    """What the checks compare a file with: each verse's word count (Hafs),
    or None per verse for a riwaya recitation, which is timed by verse
    only and numbered by its riwaya. None when the surah is unknown."""
    r = {x['slug']: x for x in reciters()}.get(slug)
    if r is None or not 1 <= surah <= 114:
        return None
    riwaya = r.get('riwaya', 'hafs')
    if riwaya == 'hafs':
        return verse_words().get(surah)
    n = load_json(DATA / 'verse_words.json')['riwayat'][riwaya][surah - 1]
    return [None] * n


def known_errors():
    """Errors already in the published data when it was exported, by
    (slug, surah, verse, word, code). They are reported but do not block:
    fixing them is a task for contributors (docs/MISSING_DATA.md)."""
    path = DATA / 'known_errors.json'
    if not path.exists():
        return set()
    return {tuple(e) for e in load_json(path)['errors']}


def durations(slug):
    """{surah: duration in ms of its audio file}, or {} when unmeasured."""
    path = DATA / slug / 'audio.json'
    if not path.exists():
        return {}
    files = load_json(path)['files']
    return {int(k): v['duration_ms'] for k, v in files.items()}


def surah_path(slug, surah):
    return DATA / slug / f'{surah:03d}.json'


# -------------------------------------------------------------- validation

def _is_int(x):
    return isinstance(x, int) and not isinstance(x, bool)


def _issue(level, code, verse=None, word=None, detail=''):
    return {'level': level, 'code': code, 'verse': verse, 'word': word, 'detail': detail}


def validate(doc, slug, surah, counts, duration_ms=None):
    """Every problem in one surah's file, as dicts with level ('error' or
    'warning'), code, verse, word and a short English detail. [counts] is
    the word count of each verse (verse 1 first); [duration_ms] the audio
    file's length, when known. Mirrors `validate` in the editor's model.js.
    """
    out = []
    if not isinstance(doc, dict):
        return [_issue('error', 'schema', detail='the file is not a JSON object')]
    if doc.get('format') != FORMAT:
        out.append(_issue('error', 'schema', detail=f'"format" must be {FORMAT}'))
    if doc.get('reciter') != slug:
        out.append(_issue('error', 'schema', detail=f'"reciter" must be "{slug}"'))
    if doc.get('surah') != surah:
        out.append(_issue('error', 'schema', detail=f'"surah" must be {surah}'))
    verses = doc.get('verses')
    if not isinstance(verses, list):
        out.append(_issue('error', 'schema', detail='"verses" must be a list'))
        return out
    n = len(counts)
    seen = []
    prev_verse_end = None
    prev_word = None  # (verse, word, end) of the last word placed
    for entry in verses:
        ok = (isinstance(entry, list) and len(entry) == 4 and all(_is_int(x) for x in entry[:3])
              and isinstance(entry[3], list))
        if ok:
            ok = all(isinstance(w, list) and len(w) == 3 and all(_is_int(x) for x in w)
                     for w in entry[3])
        if not ok:
            out.append(_issue('error', 'schema', detail='a verse must be [number, start, end, [[word, start, end], ...]] of whole numbers'))
            continue
        a, start, end, words = entry
        if a < 0 or a > n or (seen and a <= seen[-1]):
            out.append(_issue('error', 'verse_order', a, detail=f'verse {a} is out of order or not in this surah'))
            continue
        seen.append(a)
        if start < 0 or end <= start:
            out.append(_issue('error', 'verse_span', a, detail=f'{start}..{end}'))
        if prev_verse_end is not None and start < prev_verse_end:
            out.append(_issue('error', 'verse_overlap', a, detail=f'starts at {start}, before the previous verse ends at {prev_verse_end}'))
        if duration_ms is not None and end > duration_ms:
            level, code = (('error', 'verse_duration') if end - duration_ms > DURATION_SLACK_MS
                           else ('warning', 'past_audio_end'))
            out.append(_issue(level, code, a, detail=f'ends at {end}, after the audio ends at {duration_ms}'))
        prev_verse_end = max(end, prev_verse_end or 0)
        if a == 0 or counts[a - 1] is None:
            if words:
                out.append(_issue('error', 'schema', a, detail='this verse has no word numbering (the opening, or a riwaya recitation)'))
            continue
        if not words:
            out.append(_issue('warning', 'words_missing', a, detail=f'{counts[a - 1]} words have no timing'))
            continue
        numbers = [w[0] for w in words]
        if numbers != list(range(1, counts[a - 1] + 1)):
            out.append(_issue('error', 'words_partial', a, detail=f'words must be 1..{counts[a - 1]} in order'))
            continue
        for k, ws, we in words:
            if ws < 0 or we <= ws:
                out.append(_issue('error', 'word_span', a, k, f'{ws}..{we}'))
            if prev_word is not None and ws < prev_word[2]:
                over = prev_word[2] - ws
                if prev_word[0] == a or over > TOLERANCE_MS:
                    out.append(_issue('error', 'word_overlap', a, k, f'starts {over} ms before the previous word ends'))
                else:
                    out.append(_issue('warning', 'word_overlap_small', a, k, f'{over} ms into the previous verse\'s last word'))
            outside = max(start - ws, we - end, 0)
            if outside > TOLERANCE_MS:
                out.append(_issue('error', 'word_outside', a, k, f'{outside} ms outside its verse'))
            elif outside > 0:
                out.append(_issue('warning', 'word_outside_small', a, k, f'{outside} ms outside its verse'))
            if duration_ms is not None and we > duration_ms:
                level, code = (('error', 'word_duration') if we - duration_ms > DURATION_SLACK_MS
                               else ('warning', 'past_audio_end'))
                out.append(_issue(level, code, a, k, f'ends at {we}, after the audio ends at {duration_ms}'))
            prev_word = (a, k, we)
    missing = [a for a in range(1, n + 1) if a not in seen]
    if missing and seen:
        out.append(_issue('error', 'verse_missing', missing[0],
                          detail=f'{len(missing)} verse(s) have no timing: {", ".join(map(str, missing[:10]))}'))
    if not seen:
        out.append(_issue('error', 'verse_missing', detail='the file has no verses'))
    return out


# ------------------------------------------------------------- db <-> rows

def rows_of(doc, reciter_id):
    """(ayah_timing rows, word_timing rows) of one surah's file."""
    surah = doc['surah']
    ayahs, words = [], []
    for a, start, end, ws in doc['verses']:
        ayahs.append((reciter_id, surah, a, start, end))
        words += [(reciter_id, surah, a, k, s, e) for k, s, e in ws]
    return ayahs, words


def reciter_rows(slug, reciter_id):
    ayahs, words = [], []
    for path in sorted((DATA / slug).glob('[0-9][0-9][0-9].json')):
        a, w = rows_of(load_json(path), reciter_id)
        ayahs += a
        words += w
    return ayahs, words


def apply(db):
    """Replaces the timings of every published reciter in [db] (a
    content.db being built) with the rows of its files here. Called by
    build_content_db.py after the generated timings are in, so the files
    win, and records each reciter's pack version in `meta`
    (`timing_version:<slug>`). Returns {slug: (verse rows, word rows)}."""
    done = {}
    for slug, r in published().items():
        if not (DATA / slug).is_dir():
            continue
        ayahs, words = reciter_rows(slug, r['id'])
        if not ayahs:
            continue
        db.execute('DELETE FROM ayah_timing WHERE reciter = ?', (r['id'],))
        db.execute('DELETE FROM word_timing WHERE reciter = ?', (r['id'],))
        db.executemany('INSERT INTO ayah_timing VALUES (?,?,?,?,?)', ayahs)
        db.executemany('INSERT INTO word_timing VALUES (?,?,?,?,?,?)', words)
        # The app uses a downloaded pack only when it is newer than this.
        try:
            version = git_version(slug)
        except (OSError, subprocess.CalledProcessError, ValueError):
            version = 0
        db.execute('INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)',
                   (f'timing_version:{slug}', str(version)))
        done[slug] = (len(ayahs), len(words))
    return done


def export(slug, db_path=DB):
    """Writes data/timing/<slug>/NNN.json from content.db's rows, exactly
    (and removes surah files content.db no longer times)."""
    r = published().get(slug)
    if r is None:
        raise SystemExit(f'{slug}: not a published reciter in data/timing/reciters.json')
    db = sqlite3.connect(f'file:{db_path}?mode=ro', uri=True)
    verses = {}
    for s, a, start, end in db.execute(
            'SELECT surah, ayah, start_ms, end_ms FROM ayah_timing WHERE reciter = ? '
            'ORDER BY surah, ayah', (r['id'],)):
        verses.setdefault(s, {})[a] = [a, start, end, []]
    for s, a, k, start, end in db.execute(
            'SELECT surah, ayah, word, start_ms, end_ms FROM word_timing WHERE reciter = ? '
            'ORDER BY surah, ayah, word', (r['id'],)):
        verse = verses.get(s, {}).get(a)
        assert verse is not None, f'word timing without its verse: {s}:{a}'
        verse[3].append([k, start, end])
    db.close()
    out = DATA / slug
    out.mkdir(parents=True, exist_ok=True)
    for old in out.glob('[0-9][0-9][0-9].json'):
        if int(old.stem) not in verses:
            old.unlink()
    for s, vs in sorted(verses.items()):
        doc = {'format': FORMAT, 'reciter': slug, 'surah': s,
               'verses': [vs[a] for a in sorted(vs)]}
        surah_path(slug, s).write_text(dumps(doc), encoding='utf-8')
    print(f'{slug}: {len(verses)} surahs written to {out.relative_to(REPO)}')


def write_verse_words(db_path=DB):
    """Hafs word counts from content.db; riwaya verse counts from the
    riwaya sources (tools/.cache, via riwaya_reciters.py)."""
    db = sqlite3.connect(f'file:{db_path}?mode=ro', uri=True)
    counts = {}
    for s, a, n in db.execute('SELECT surah, ayah, COUNT(*) FROM word_box GROUP BY surah, ayah'):
        counts.setdefault(s, {})[a] = n
    ayahs = dict(db.execute('SELECT id, ayah_count FROM surah'))
    db.close()
    surahs = [[counts[s][a] for a in range(1, ayahs[s] + 1)] for s in range(1, 115)]
    lines = ['{', '  "format": 1,',
             '  "about": "Words in each verse, as numbered in content.db word_box (KFGQPC words; the hizb sign is not a word). Counts only.",',
             '  "surahs": [']
    lines += ['    ' + json.dumps(c, separators=(', ', ': ')) + (',' if i < 113 else '')
              for i, c in enumerate(surahs)]
    import riwaya_reciters
    riwayat = riwaya_reciters.riwaya_counts()
    lines += ['  ],', '  "riwayat": {']
    names = sorted(riwayat)
    for j, name in enumerate(names):
        row = [riwayat[name][s] for s in range(1, 115)]
        lines.append(f'    {json.dumps(name)}: ' + json.dumps(row, separators=(', ', ': ')) + (',' if j < len(names) - 1 else ''))
    lines += ['  }', '}']
    (DATA / 'verse_words.json').write_text('\n'.join(lines) + '\n', encoding='utf-8')


def write_known_errors():
    """Records the errors in the published files as they are now. Run after
    an export; a contributor's fix makes an entry stale, which is harmless."""
    rows = []
    for slug in sorted(published()):
        durs = durations(slug)
        for path in sorted((DATA / slug).glob('[0-9][0-9][0-9].json')):
            doc = load_json(path)
            s = doc['surah']
            for i in validate(doc, slug, s, counts_for(slug, s), durs.get(s)):
                if i['level'] == 'error':
                    rows.append([slug, s, i['verse'], i['word'], i['code']])
    lines = ['{', '  "format": 1,',
             '  "about": "Errors already in the published timings, from their sources: [reciter, surah, verse, word, code]. Reported, not blocking; fixing them is a task for contributors (docs/MISSING_DATA.md).",',
             '  "errors": [']
    lines += ['    ' + json.dumps(r, ensure_ascii=False, separators=(', ', ': ')) + (',' if j < len(rows) - 1 else '')
              for j, r in enumerate(rows)]
    lines += ['  ]', '}']
    (DATA / 'known_errors.json').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(f'{len(rows)} known errors')


# ------------------------------------------------------ mechanical fixes

# The only source errors fixed without listening (docs/TIMING.md, "known
# errors"); everything else is left to a person in the editor, or to a
# new measurement. Neither rule invents a time: each moves one edge onto a
# time already in the file, by less than the source's own rounding.
#
# 1. A word of one millisecond is a word quran-align gave no length
#    (build_word_timing.py writes such a word as start..start+1). When
#    the next word starts inside that one millisecond, or up to one
#    quran-align frame (10 ms) before it, the overlap is rounding: the
#    next word starts where the point word ends (a boundary is one moment,
#    as in the editor). Larger overlaps are left: the next word's start
#    was measured somewhere else, and only listening can tell.
POINT_WORD_MS = 1
POINT_OVERLAP_MS = 12   # one 10 ms frame stretched onto the surah file, plus the 1 ms
# 2. Nothing is heard after the audio ends: the last verse of a file whose
#    published end runs past the end of the audio by less than a second
#    (and none of whose words do) ends where the audio ends. Longer
#    overruns mean the timing was measured on another file.
AUDIO_END_FIX_MS = 1000


def fix_doc(doc, duration_ms=None):
    """(a fixed copy of doc, [(verse, word, code, before, after)]) by the two
    rules above; doc itself is not changed."""
    out = json.loads(json.dumps(doc))
    fixes = []
    for entry in out['verses']:
        a, _, _, words = entry
        for i in range(1, len(words)):
            p, w = words[i - 1], words[i]
            over = p[2] - w[1]
            if (0 < over <= POINT_OVERLAP_MS and p[2] - p[1] <= POINT_WORD_MS
                    and p[2] < w[2]):
                fixes.append((a, w[0], 'word_overlap', w[1], p[2]))
                w[1] = p[2]
    if duration_ms is not None and out['verses']:
        last = out['verses'][-1]
        a, start, end, words = last
        over = end - duration_ms
        if (DURATION_SLACK_MS < over < AUDIO_END_FIX_MS and start < duration_ms
                and all(w[2] <= duration_ms for w in words)):
            fixes.append((a, None, 'verse_duration', end, duration_ms))
            last[2] = duration_ms
    return out, fixes


def fix_known(slugs=None):
    """Applies fix_doc to the files that have known errors (of [slugs], or
    all). Returns the fixes, as (slug, surah, verse, word, code, before,
    after). Run `known-errors` afterwards."""
    done = []
    files = sorted({(e[0], e[1]) for e in known_errors() if slugs is None or e[0] in slugs})
    for slug, surah in files:
        path = surah_path(slug, surah)
        doc = load_json(path)
        fixed, fixes = fix_doc(doc, durations(slug).get(surah))
        if not fixes:
            continue
        before = {(i['verse'], i['word'], i['code']) for i in
                  validate(doc, slug, surah, counts_for(slug, surah), durations(slug).get(surah))}
        after = validate(fixed, slug, surah, counts_for(slug, surah), durations(slug).get(surah))
        new = [i for i in after if i['level'] == 'error' and (i['verse'], i['word'], i['code']) not in before]
        assert not new, (slug, surah, new)
        path.write_text(dumps(fixed), encoding='utf-8')
        done += [(slug, surah, *f) for f in fixes]
    return done


# ------------------------------------------------------------------- check

def _file_label(slug, surah):
    return f'data/timing/{slug}/{surah:03d}.json'


def check_file(path, base_dir=None):
    """Validates one timing file. Returns a dict with the issues, those in
    verses unchanged from [base_dir]'s copy marked `old`, and a short
    summary of what changed."""
    full = Path(path) if Path(path).is_absolute() else REPO / path
    rel = full.resolve().relative_to(REPO.resolve()).as_posix()
    m = FILE_RE.match(rel)
    result = {'file': rel, 'issues': [], 'changed_verses': [], 'changed_words': 0, 'new': False}
    if not m:
        result['issues'].append(_issue('error', 'path', detail='timing files are data/timing/<reciter>/NNN.json'))
        return result
    slug, surah = m.group(1), int(m.group(2))
    pub = published()
    counts = counts_for(slug, surah)
    if slug not in pub or counts is None:
        result['issues'].append(_issue('error', 'path', detail=f'"{slug}" is not a published reciter, or {surah} is not a surah'))
        return result
    if not full.exists():
        result['issues'].append(_issue('error', 'path', detail='the file was removed; timing files are corrected, not deleted'))
        return result
    text = full.read_text(encoding='utf-8')
    try:
        doc = json.loads(text)
    except ValueError as e:
        result['issues'].append(_issue('error', 'schema', detail=f'not valid JSON: {e}'))
        return result
    issues = validate(doc, slug, surah, counts, durations(slug).get(surah))
    if not issues and text != dumps(doc):
        issues.append(_issue('warning', 'layout', detail='not in the usual layout (one verse per line); fine, but the diff is harder to read'))
    base = None
    if base_dir is not None:
        bp = Path(base_dir) / rel
        if bp.exists():
            try:
                base = json.loads(bp.read_text(encoding='utf-8'))
            except ValueError:
                base = None
        else:
            result['new'] = True
    if base is not None and isinstance(doc, dict) and isinstance(doc.get('verses'), list):
        old = {v[0]: v for v in base.get('verses', []) if isinstance(v, list) and v}
        new = {v[0]: v for v in doc['verses'] if isinstance(v, list) and v and _is_int(v[0])}
        changed = sorted(a for a in set(old) | set(new) if old.get(a) != new.get(a))
        result['changed_verses'] = changed
        words = 0
        for a in changed:
            ow = {w[0]: w for w in (old.get(a) or [0, 0, 0, []])[3] if isinstance(w, list) and w}
            nw = {w[0]: w for w in (new.get(a) or [0, 0, 0, []])[3] if isinstance(w, list) and w}
            words += sum(1 for k in set(ow) | set(nw) if ow.get(k) != nw.get(k))
        result['changed_words'] = words
        for i in issues:
            i['old'] = i['verse'] is not None and i['verse'] not in changed and i['code'] not in ('schema', 'layout')
    known = known_errors()
    for i in issues:
        if i['level'] == 'error' and (slug, surah, i['verse'], i['word'], i['code']) in known:
            i['old'] = True
            i['known'] = True
    result['issues'] = issues
    return result


def check(files, base_dir=None):
    results = [check_file(f, base_dir) for f in files]
    failed = any(i['level'] == 'error' and not i.get('old') for r in results for i in r['issues'])
    return results, failed


def summary_markdown(results, editor_links=None):
    lines = []
    for r in results:
        new_errors = [i for i in r['issues'] if i['level'] == 'error' and not i.get('old')]
        old_errors = [i for i in r['issues'] if i['level'] == 'error' and i.get('old')]
        warnings = [i for i in r['issues'] if i['level'] == 'warning']
        mark = '❌' if new_errors else '✅'
        head = f'{mark} `{r["file"]}`'
        if r['changed_verses']:
            vs = r['changed_verses']
            shown = ', '.join(map(str, vs[:15])) + (' …' if len(vs) > 15 else '')
            head += f' — {len(vs)} verse(s) changed ({shown}), {r["changed_words"]} word(s)'
        elif r['new']:
            head += ' — new file'
        lines.append(head)
        if editor_links and r['file'] in editor_links:
            lines.append(f'  - [Listen and review in the editor / استمع وراجع في المحرر]({editor_links[r["file"]]})')
        for i in new_errors[:20]:
            where = f'{i["verse"]}' + (f':{i["word"]}' if i['word'] else '') if i['verse'] is not None else '—'
            lines.append(f'  - error `{i["code"]}` at {where}: {i["detail"]}')
        if len(new_errors) > 20:
            lines.append(f'  - … and {len(new_errors) - 20} more errors')
        if old_errors:
            lines.append(f'  - {len(old_errors)} error(s) already in the data on main (known, or in verses this change did not touch): not blocking')
        fresh = [i for i in warnings if not i.get('old')]
        for i in fresh[:10]:
            where = f'{i["verse"]}' + (f':{i["word"]}' if i['word'] else '') if i['verse'] is not None else '—'
            lines.append(f'  - warning `{i["code"]}` at {where}: {i["detail"]}')
        if len(fresh) > 10:
            lines.append(f'  - … and {len(fresh) - 10} more warnings')
        if len(warnings) > len(fresh):
            lines.append(f'  - {len(warnings) - len(fresh)} warning(s) in verses this change did not touch')
    return '\n'.join(lines)


# -------------------------------------------------------------------- pack

def git_version(slug):
    """The pack's version: commits on this branch that touched the
    reciter's files. Only ever grows on main."""
    out = subprocess.run(['git', 'rev-list', '--count', 'HEAD', '--', f'data/timing/{slug}'],
                         cwd=REPO, capture_output=True, text=True, check=True)
    return int(out.stdout.strip())


def build_pack(slug, version):
    r = published()[slug]
    surahs = {}
    for path in sorted((DATA / slug).glob('[0-9][0-9][0-9].json')):
        doc = load_json(path)
        surahs[str(doc['surah'])] = doc['verses']
    body = {'format': FORMAT, 'slug': slug, 'reciter_id': r['id'], 'folder_url': r['folder_url'],
            'version': version, 'surahs': surahs}
    raw = json.dumps(body, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
    buf = io.BytesIO()
    with gzip.GzipFile(fileobj=buf, mode='wb', mtime=0, compresslevel=9) as z:
        z.write(raw)
    return buf.getvalue()


def pack(out_dir, versions=None):
    """timing-<slug>-v<n>.json.gz per published reciter and manifest.json."""
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    entries = []
    for slug, r in sorted(published().items()):
        if not any((DATA / slug).glob('[0-9][0-9][0-9].json')):
            continue
        version = (versions or {}).get(slug) or git_version(slug)
        data = build_pack(slug, version)
        name = f'timing-{slug}-v{version}.json.gz'
        (out / name).write_bytes(data)
        entries.append({'slug': slug, 'reciter_id': r['id'], 'version': version, 'file': name,
                        'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
    manifest = {'format': FORMAT, 'reciters': entries}
    (out / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    return manifest


# -------------------------------------------------------------------- site

def _display_words(display_text):
    """Words of a verse as the app numbers them (`_words` in
    mushaf_providers.dart): the KFGQPC text without its number glyph,
    split at spaces, the hizb sign left out. Returns (words, number glyph),
    each piece exactly as stored."""
    cut = max(display_text.rfind(' '), display_text.rfind(' '))
    body, number = display_text[:cut], display_text[cut + 1:]
    return [w for w in re.split('[  ]', body) if w and w != HIZB], number


def site(out_dir, db_path=DB):
    """The editor with what it reads: the Quran words exported verbatim
    from content.db, the timing files, and the KFGQPC font, unchanged."""
    out = Path(out_dir)
    if out.exists():
        shutil.rmtree(out)
    shutil.copytree(EDITOR, out, ignore=shutil.ignore_patterns('test', 'node_modules', '*.md', 'package.json',
                                                               'guide.template.html'))
    write_guide(out)
    db = sqlite3.connect(f'file:{db_path}?mode=ro', uri=True)
    counts = verse_words()
    (out / 'quran').mkdir()
    names = []
    for sid, name_ar, name_en, n in db.execute('SELECT id, name_ar, name_en, ayah_count FROM surah ORDER BY id'):
        names.append({'n': sid, 'ar': name_ar, 'en': name_en, 'verses': n})
        verses = []
        for a, text in db.execute('SELECT number, display_text FROM ayah WHERE surah = ? ORDER BY number', (sid,)):
            words, number = _display_words(text)
            assert len(words) == counts[sid][a - 1], (sid, a, len(words), counts[sid][a - 1])
            verses.append({'n': a, 'words': words, 'mark': number})
        (out / 'quran' / f'{sid:03d}.json').write_text(
            json.dumps({'surah': sid, 'verses': verses}, ensure_ascii=False, separators=(',', ':')),
            encoding='utf-8')
    db.close()
    (out / 'quran' / 'surahs.json').write_text(json.dumps(names, ensure_ascii=False), encoding='utf-8')
    shutil.copytree(DATA, out / 'timing')
    fonts = out / 'fonts'
    fonts.mkdir(exist_ok=True)
    # Unchanged: the KFGQPC licence allows use, copying and distribution, not modification.
    shutil.copy2(REPO / 'assets/fonts/kfgqpc/uthmanic_hafs_v20.ttf', fonts / 'uthmanic_hafs_v20.ttf')
    for f in ('IBMPlexSansArabic-Regular.ttf', 'IBMPlexSansArabic-SemiBold.ttf', 'OFL.txt'):
        shutil.copy2(REPO / 'assets/fonts/ofl/ibmplexsansarabic' / f,
                     fonts / (f if f != 'OFL.txt' else 'IBMPlexSansArabic-OFL.txt'))
    shutil.copy2(REPO / 'docs/licenses/2026-09-28_kfgqpc_fonts_embedded_licenses.txt', fonts / 'KFGQPC-LICENSE.txt')
    shutil.copy2(EDITOR / 'CONTRIBUTING.md', out / 'CONTRIBUTING.md')
    (out / '.nojekyll').write_text('')
    print(f'site written to {out}')


# ------------------------------------------------------------------- guide

GUIDE = REPO / 'docs' / 'TIMING_GUIDE.md'
_IMG_PREFIX = '../apps/timing-editor/'


def _inline(text):
    import html
    out = html.escape(text, quote=False)
    out = re.sub(r'`([^`]+)`', r'<code>\1</code>', out)
    out = re.sub(r'\*\*([^*]+)\*\*', r'<b>\1</b>', out)
    out = re.sub(r'\[([^\]]+)\]\(([^)\s]+)\)', r'<a href="\2">\1</a>', out)
    out = re.sub(r'(?<!href=")(https://[^\s<)،]+)', r'<a href="\1" target="_blank" rel="noopener" dir="ltr">\1</a>', out)
    return out


def guide_html(md):
    """docs/TIMING_GUIDE.md as the body of guide.html: the same text, so the
    page and the document never differ. Handles the little Markdown the
    guide uses: headings, paragraphs, lists, a table, images, a quote."""
    import html
    parts = md.split('\n---\n')
    sections = []
    for n, part in enumerate(parts):
        lang, direction = ('ar', 'rtl') if n == 0 else ('en', 'ltr')
        out, para, lst = [], [], None
        steps = 0

        def flush():
            nonlocal para, lst
            if para:
                out.append('<p>' + _inline(' '.join(para)) + '</p>')
                para = []
            if lst:
                out.append(f'<{lst[0]}>' + ''.join(f'<li>{_inline(x)}</li>' for x in lst[1]) + f'</{lst[0]}>')
                lst = None

        lines = part.strip('\n').split('\n')
        i = 0
        while i < len(lines):
            line = lines[i].rstrip()
            m_img = re.fullmatch(r'!\[([^\]]*)\]\(([^)]+)\)', line)
            m_ol = re.match(r'^([0-9٠-٩]+)\.\s+(.*)$', line)
            if not line:
                flush()
            elif line.startswith('#'):
                flush()
                level = len(line) - len(line.lstrip('#'))
                title = line[level:].strip()
                anchor = ''
                if level == 3 and n == 0:
                    steps += 1
                    anchor = f' id="step-{steps}"'
                out.append(f'<h{level}{anchor}>{_inline(title)}</h{level}>')
            elif m_img:
                flush()
                src = m_img.group(2).replace(_IMG_PREFIX, '')
                alt = html.escape(m_img.group(1))
                out.append(f'<figure><img src="{src}" alt="{alt}" loading="lazy"><figcaption>{alt}</figcaption></figure>')
            elif line.startswith('> '):
                flush()
                out.append('<aside>' + _inline(line[2:]) + '</aside>')
            elif line.startswith('|'):
                flush()
                rows = []
                while i < len(lines) and lines[i].startswith('|'):
                    cells = [c.strip() for c in lines[i].strip('|').split('|')]
                    if not all(set(c) <= set('-: ') for c in cells):
                        rows.append(cells)
                    i += 1
                head, body = rows[0], rows[1:]
                out.append('<table><thead><tr>' + ''.join(f'<th>{_inline(c)}</th>' for c in head) + '</tr></thead><tbody>'
                           + ''.join('<tr>' + ''.join(f'<td>{_inline(c)}</td>' for c in r) + '</tr>' for r in body)
                           + '</tbody></table>')
                continue
            elif line.startswith('- ') or m_ol:
                kind = 'ul' if line.startswith('- ') else 'ol'
                if para:
                    out.append('<p>' + _inline(' '.join(para)) + '</p>')
                    para = []
                if not lst or lst[0] != kind:
                    if lst:
                        flush()
                    lst = (kind, [])
                lst[1].append(line[2:] if kind == 'ul' else m_ol.group(2))
            else:
                if lst:
                    flush()
                para.append(line)
            i += 1
        flush()
        sections.append(f'<section lang="{lang}" dir="{direction}">' + '\n'.join(out) + '</section>')
    return '\n'.join(sections)


def write_guide(out_dir):
    body = guide_html(GUIDE.read_text(encoding='utf-8'))
    page = (EDITOR / 'guide.template.html').read_text(encoding='utf-8').replace('<!-- GUIDE -->', body)
    (Path(out_dir) / 'guide.html').write_text(page, encoding='utf-8')


# --------------------------------------------------------------------- cli

def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    e = sub.add_parser('export')
    e.add_argument('slugs', nargs='+')
    sub.add_parser('known-errors', help='write data/timing/known_errors.json: the errors in the published data now')
    fx = sub.add_parser('fix-known', help='fix the known errors that need no listening (fix_doc), then run known-errors')
    fx.add_argument('slugs', nargs='*')
    c = sub.add_parser('check')
    c.add_argument('files', nargs='*')
    c.add_argument('--base', help='a checkout of the base branch, to tell changed verses from old ones')
    c.add_argument('--json', help='write the results here')
    c.add_argument('--markdown', help='write a summary here')
    c.add_argument('--editor', help='editor URL; links are added per file')
    k = sub.add_parser('pack')
    k.add_argument('--out', required=True)
    s = sub.add_parser('site')
    s.add_argument('--out', required=True)
    sub.add_parser('verse-words')
    args = p.parse_args(argv)
    if args.cmd == 'export':
        for slug in args.slugs:
            export(slug)
    elif args.cmd == 'known-errors':
        write_known_errors()
    elif args.cmd == 'fix-known':
        for slug, surah, verse, word, code, before, after in fix_known(args.slugs or None):
            where = f'{surah}:{verse}' + (f' word {word}' if word else '')
            print(f'{slug} {where}: {code}, {before} -> {after}')
    elif args.cmd == 'verse-words':
        write_verse_words()
    elif args.cmd == 'pack':
        for e in pack(args.out)['reciters']:
            print(f'{e["file"]}: {e["bytes"]} bytes, sha256 {e["sha256"]}')
    elif args.cmd == 'site':
        site(args.out)
    elif args.cmd == 'check':
        files = args.files or sorted(str(f.relative_to(REPO)) for f in DATA.glob('*/[0-9][0-9][0-9].json'))
        results, failed = check(files, args.base)
        links = None
        if args.editor:
            links = {}
            for r in results:
                m = FILE_RE.match(r['file'])
                if m:
                    links[r['file']] = f'{args.editor}&reciter={m.group(1)}&surah={int(m.group(2))}'
        md = summary_markdown(results, links)
        if args.json:
            Path(args.json).write_text(json.dumps({'failed': failed, 'results': results}, indent=1), encoding='utf-8')
        if args.markdown:
            Path(args.markdown).write_text(md + '\n', encoding='utf-8')
        print(md if len(results) < 20 else
              f'{len(results)} files, {sum(1 for r in results for i in r["issues"] if i["level"] == "error" and not i.get("old"))} errors')
        return 1 if failed else 0
    return 0


if __name__ == '__main__':
    sys.exit(main())
