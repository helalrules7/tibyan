"""Download quran.com's verse and word timings (the QDC audio API, made
with Quranic Universal Library's segment tools) for the recitations
Tibyan plays from quranicaudio.com.

Source: https://api.qurancdn.com/api/qdc/audio/reciters/<id>/audio_files
?chapter=<n>&segments=true, the API quran.com's player uses. Each surah
entry names its audio file (audio_url, file_size, duration); each verse
has timestamp_from/timestamp_to and `segments`, [word, start_ms, end_ms]
with 1-based word numbers (a word read twice, when the reciter repeats a
phrase, appears twice). Times are in that surah file.

Usage:
  python3 tools/fetch_qdc_timing.py

Writes tools/.cache/qdc_timing.json: {qdc reciter id: {surah: {audio_url,
file_size, duration, verses: [[verse, from_ms, to_ms, segments], ...]}}},
keys sorted so the file's SHA-256 is stable. Only these fields are kept,
copied as published.
"""
import json
import sys
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OUT = ROOT / '.cache' / 'qdc_timing.json'
API = ('https://api.qurancdn.com/api/qdc/audio/reciters/{reciter}/audio_files'
       '?chapter={surah}&segments=true')

# QDC reciter ids: Abdul-Rahman al-Sudais 3, Saud al-Shuraim 10,
# Yasser al-Dosari 97 (see build_qdc_timing.RECITERS).
READS = [3, 10, 97]


def fetch(url):
    for attempt in range(6):
        try:
            request = urllib.request.Request(url, headers={'User-Agent': 'tibyan-tools/0.1'})
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.loads(response.read())
        except Exception:
            if attempt == 5:
                raise
            time.sleep(3 * (attempt + 1))


def surah(reciter, n):
    f = fetch(API.format(reciter=reciter, surah=n))['audio_files'][0]
    assert f['chapter_id'] == n
    verses = []
    for v in f['verse_timings']:
        s, a = map(int, v['verse_key'].split(':'))
        assert s == n
        verses.append([a, v['timestamp_from'], v['timestamp_to'], v['segments']])
    return str(n), {'audio_url': f['audio_url'], 'file_size': f['file_size'],
                    'duration': f['duration'], 'verses': verses}


def main():
    out = {}
    for reciter in READS:
        with ThreadPoolExecutor(6) as pool:
            out[str(reciter)] = dict(pool.map(lambda n: surah(reciter, n), range(1, 115)))
        print(f'qdc reciter {reciter}: 114 surahs')
    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text(json.dumps(out, sort_keys=True, separators=(',', ':')), encoding='utf-8')
    print(OUT)
    return 0


if __name__ == '__main__':
    sys.exit(main())
