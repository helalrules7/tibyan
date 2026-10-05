"""Stage two QuranEnc items that wait for QuranEnc's reply (letter 12):

1. `english_mokhtasar`: the English translation of «المختصر في تفسير القرآن
   الكريم». It is served by the API but has no public page, so we do not
   know whether QuranEnc's published terms cover it (MISSING_DATA ن12).
   Every surah is fetched from
     https://quranenc.com/api/v1/translation/sura/english_mokhtasar/{sura}
   and each response body is kept byte for byte (raw/NNN.json). The
   QuranEnc English list (translations/list/en) is kept too, to record
   whether the key is listed and with which version.

2. `english_rwwad` audio (MISSING_DATA ن13): one MP3 per verse at
     https://d.quranenc.com/data/audio/english_rwwad/{SSSAAA}.mp3
   The index of 6,236 URLs is written, and a sample is checked with HEAD
   requests. The audio itself is NOT downloaded or mirrored.

   index.json is the verse audio index the app reads (format 1:
   tools/audio_index.py, docs/features/audio_content.md).

3. `pack`: turns the staged english_mokhtasar responses into the optional
   English tafsir pack the app downloads (one SQLite file, its text byte
   for byte from the responses; docs/features/audio_content.md), with
   <pack>.index.json beside it giving pack_sha256 and bytes.

Nothing here enters the app: the files stay in tools/.cache/staging/quranenc/
(git-ignored) until the permission arrives.

Usage:
  python3 tools/fetch_quranenc_extra.py text          # english_mokhtasar
  python3 tools/fetch_quranenc_extra.py audio [N]     # rwwad index + N random HEADs (default 20)
  python3 tools/fetch_quranenc_extra.py pack          # english_mokhtasar.pack.db from `text`
  python3 tools/fetch_quranenc_extra.py all           # text and audio
"""
import json
import random
import sqlite3
import sys
import time
from pathlib import Path

import audio_index as verse_audio
import staging

API = 'https://quranenc.com/api/v1'
SURA_URL = API + '/translation/sura/{key}/{sura}'
LIST_URL = API + '/translations/list/{lang}'
AUDIO_URL = 'https://d.quranenc.com/data/audio/{key}/{sura:03d}{aya:03d}.mp3'
TEXT_KEY = 'english_mokhtasar'
AUDIO_KEY = 'english_rwwad'
OUT = staging.STAGING / 'quranenc'
# Credit keys in lib/features/mushaf/presentation/source_names.dart.
AUDIO_SOURCE = 'quranenc-english-rwwad-audio'
TEXT_SOURCE = 'quranenc-english-mokhtasar'
PACK_FORMAT = '1'
STATUS = ('PENDING: no public QuranEnc page for english_mokhtasar and the terms do '
          'not mention audio; asked in letter 12. Staged only, not shipped.')


def audio_url(key, sura, aya):
    return AUDIO_URL.format(key=key, sura=sura, aya=aya)


def check_sura(payload, sura):
    """The rows of one /translation/sura response, unchanged, after checking
    the structure: one row per verse of the surah, in order. Raises
    ValueError otherwise. Only `sura` and `aya` are read."""
    rows = payload.get('result') if isinstance(payload, dict) else None
    if not isinstance(rows, list):
        raise ValueError(f'surah {sura}: no "result" list')
    expected = staging.VERSE_COUNTS[sura - 1]
    ayas = [int(r['aya']) for r in rows]
    if any(int(r['sura']) != sura for r in rows):
        raise ValueError(f'surah {sura}: rows from another surah')
    if ayas != list(range(1, expected + 1)):
        missing = sorted(set(range(1, expected + 1)) - set(ayas))
        raise ValueError(f'surah {sura}: verses {len(ayas)} of {expected}; missing {missing[:10]}')
    return rows


def listed(list_payload, key):
    """The entry for `key` in a translations/list response, or None."""
    for t in (list_payload or {}).get('translations', []):
        if t.get('key') == key:
            return t
    return None


def fetch_text():
    raw = OUT / TEXT_KEY / 'raw'
    raw.mkdir(parents=True, exist_ok=True)
    body = staging.get(LIST_URL.format(lang='en'))
    (OUT / TEXT_KEY / 'translations_list_en.json').write_bytes(body)
    entry = listed(json.loads(body), TEXT_KEY)
    rows = empty = 0
    for sura in range(1, 115):
        body = staging.get(SURA_URL.format(key=TEXT_KEY, sura=sura))
        result = check_sura(json.loads(body), sura)
        rows += len(result)
        empty += sum(1 for r in result if not (r.get('translation') or '').strip())
        (raw / f'{sura:03d}.json').write_bytes(body)
        time.sleep(0.2)
    staging.write_sums(OUT / TEXT_KEY)
    staging.write_manifest(
        OUT / TEXT_KEY, key=TEXT_KEY, source=SURA_URL.replace('{key}', TEXT_KEY),
        listed_in_translations_list=bool(entry),
        version=(entry or {}).get('version'), last_update=(entry or {}).get('last_update'),
        verses=rows, verses_with_empty_translation=empty, status=STATUS)
    print(f'{TEXT_KEY}: {rows} verses, {empty} empty, listed={bool(entry)} '
          f'version={(entry or {}).get("version")}')


def audio_payload(rows):
    """The app's verse audio index (format 1) for the english_rwwad audio."""
    return verse_audio.make_index(
        'quranenc-english-rwwad', 'translation_audio', AUDIO_SOURCE, verses=rows,
        title_ar='الترجمة الإنجليزية (رواد)', title_en='English translation (Rowwad)',
        lang='en', key=AUDIO_KEY, pattern=AUDIO_URL.replace('{key}', AUDIO_KEY))


def build_text_pack(raw_dir, out, version=None, last_update=None):
    """Writes the English tafsir pack from the staged responses in
    raw_dir (NNN.json, all 114, each checked by check_sura): one SQLite
    file whose `verse.text` is each row's `translation` exactly as served
    and `verse.footnotes` its `footnotes` (NULL when empty). Writes
    <out>.index.json with the pack's SHA-256 and size. Returns that index."""
    raw_dir, out = Path(raw_dir), Path(out)
    rows = []
    for sura in range(1, 115):
        payload = json.loads((raw_dir / f'{sura:03d}.json').read_bytes())
        for r in check_sura(payload, sura):
            text = r.get('translation')
            if not isinstance(text, str) or not text.strip():
                raise ValueError(f"{sura}:{r['aya']}: empty translation")
            notes = r.get('footnotes')
            rows.append((sura, int(r['aya']), text,
                         notes if isinstance(notes, str) and notes.strip() else None))
    if out.exists():
        out.unlink()
    out.parent.mkdir(parents=True, exist_ok=True)
    meta = {'format': PACK_FORMAT, 'kind': 'tafsir_text', 'key': TEXT_KEY,
            'source': TEXT_SOURCE, 'lang': 'en', 'direction': 'ltr',
            'title': 'Al-Mukhtasar fi Tafsir al-Quran al-Karim (English)',
            'url': SURA_URL.replace('{key}', TEXT_KEY), 'verses': str(len(rows))}
    if version:
        meta['version'] = str(version)
    if last_update:
        meta['last_update'] = str(last_update)
    db = sqlite3.connect(out)
    try:
        db.executescript(
            'CREATE TABLE pack_index (key TEXT PRIMARY KEY, value TEXT NOT NULL);'
            'CREATE TABLE verse (surah INTEGER NOT NULL, ayah INTEGER NOT NULL, '
            'text TEXT NOT NULL, footnotes TEXT, PRIMARY KEY (surah, ayah)) WITHOUT ROWID;')
        db.executemany('INSERT INTO pack_index VALUES (?, ?)', sorted(meta.items()))
        db.executemany('INSERT INTO verse VALUES (?, ?, ?, ?)', rows)
        db.commit()
        db.execute('VACUUM')
    finally:
        db.close()
    index = dict(meta, pack_sha256=staging.sha256_file(out), bytes=out.stat().st_size)
    Path(str(out) + '.index.json').write_text(
        json.dumps(index, ensure_ascii=False, indent=1, sort_keys=True) + '\n', encoding='utf-8')
    return index


def text_pack():
    d = OUT / TEXT_KEY
    manifest = json.loads((d / 'manifest.json').read_text(encoding='utf-8'))
    index = build_text_pack(d / 'raw', d / f'{TEXT_KEY}.pack.db',
                            manifest.get('version'), manifest.get('last_update'))
    print(f"{TEXT_KEY}.pack.db: {index['verses']} verses, {index['bytes']} bytes, "
          f"sha256 {index['pack_sha256']}")


def audio_index(sample=20, seed=20261005):
    d = OUT / f'{AUDIO_KEY}_audio'
    d.mkdir(parents=True, exist_ok=True)
    index = [[s, a, audio_url(AUDIO_KEY, s, a)] for s, a in staging.verses()]
    verse_audio.write(d / 'index.json', audio_payload(index))
    picks = [index[0], index[-1]] + random.Random(seed).sample(index[1:-1], sample)
    checks = []
    for s, a, url in picks:
        rec = staging.head_record(url)
        rec.update(surah=s, ayah=a)
        checks.append(rec)
        print(f"{s}:{a} {rec['status']} {rec['content_type']} {rec['content_length']}")
        time.sleep(0.2)
    (d / 'head_checks.json').write_text(json.dumps(checks, indent=1) + '\n', encoding='utf-8')
    staging.write_sums(d)
    ok = sum(1 for c in checks if c['status'] == 200)
    staging.write_manifest(d, key=AUDIO_KEY, pattern=AUDIO_URL.replace('{key}', AUDIO_KEY),
                           urls=len(index), head_checked=len(checks), head_ok=ok,
                           mirrored=False, status=STATUS)
    print(f'{AUDIO_KEY}: {len(index)} URLs; HEAD {ok}/{len(checks)} ok')
    return 0 if ok == len(checks) else 1


def main(argv):
    what = argv[0] if argv else 'all'
    rc = 0
    if what in ('text', 'all'):
        fetch_text()
    if what in ('audio', 'all'):
        rc = audio_index(int(argv[1]) if len(argv) > 1 else 20)
    if what == 'pack':
        text_pack()
    return rc


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
