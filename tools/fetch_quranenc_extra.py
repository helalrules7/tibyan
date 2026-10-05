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

Nothing here enters the app: the files stay in tools/.cache/staging/quranenc/
(git-ignored) until the permission arrives.

Usage:
  python3 tools/fetch_quranenc_extra.py text          # english_mokhtasar
  python3 tools/fetch_quranenc_extra.py audio [N]     # rwwad index + N random HEADs (default 20)
  python3 tools/fetch_quranenc_extra.py all
"""
import json
import random
import sys
import time

import staging

API = 'https://quranenc.com/api/v1'
SURA_URL = API + '/translation/sura/{key}/{sura}'
LIST_URL = API + '/translations/list/{lang}'
AUDIO_URL = 'https://d.quranenc.com/data/audio/{key}/{sura:03d}{aya:03d}.mp3'
TEXT_KEY = 'english_mokhtasar'
AUDIO_KEY = 'english_rwwad'
OUT = staging.STAGING / 'quranenc'
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


def audio_index(sample=20, seed=20261005):
    d = OUT / f'{AUDIO_KEY}_audio'
    d.mkdir(parents=True, exist_ok=True)
    index = [[s, a, audio_url(AUDIO_KEY, s, a)] for s, a in staging.verses()]
    (d / 'index.json').write_text(json.dumps(
        {'key': AUDIO_KEY, 'pattern': AUDIO_URL.replace('{key}', AUDIO_KEY), 'verses': index},
        separators=(',', ':')) + '\n', encoding='utf-8')
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
    return rc


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
