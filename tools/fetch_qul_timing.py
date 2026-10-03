"""Download Quranic Universal Library's verse and word timings (QUL, by
Tarteel: https://qul.tarteel.ai/resources/recitation) for the recitations
Tibyan plays from quranicaudio.com that quran.com's QDC API does not time.

Source: https://qul.tarteel.ai/api/v1/audio/surah_segments/<id>?surah=<n>
&per_page=300, the API behind the resource page's own player (the json
and sqlite downloads on that page need an account; this is the same
data). Each surah names its audio file (url, audio_size in bytes,
duration in s); each verse key "s:a" has time_from/time_to and
`segments`, [word, start_ms, end_ms] with 1-based word numbers, times in
that surah file. The layout is that of quran.com's QDC timings, so
build_qdc_timing.py reads both.

QUL recitation 159 is Maher al-Muaiqly (murattal, Hafs), measured on
https://download.quranicaudio.com/quran/maher_almu3aiqly/year1440/NNN.mp3
(resource page 405, "Surah by Surah, with segments").

Usage:
  python3 tools/fetch_qul_timing.py

Writes tools/.cache/qul_timing.json: {qul recitation id: {surah:
{audio_url, file_size, duration, verses: [[verse, from_ms, to_ms,
segments], ...]}}}, keys sorted so the file's SHA-256 is stable. Only
these fields are kept, copied as published.
"""
import json
import sys
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OUT = ROOT / '.cache' / 'qul_timing.json'
API = 'https://qul.tarteel.ai/api/v1/audio/surah_segments/{reciter}?surah={surah}&per_page=300'

# QUL recitation ids: Maher al-Muaiqly 159 (see build_qdc_timing.SETS).
READS = [159]


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
    page = fetch(API.format(reciter=reciter, surah=n))
    # every verse of the surah in one page
    assert page['pagination']['next_page'] is None, (reciter, n)
    verses = []
    for key, v in page['segments'].items():
        s, a = map(int, key.split(':'))
        assert s == n
        verses.append([a, v['time_from'], v['time_to'], v['segments']])
    audio = page['audio']
    return str(n), {'audio_url': audio['url'], 'file_size': int(audio['audio_size']),
                    'duration': audio['duration'], 'verses': sorted(verses)}


def main():
    out = {}
    for reciter in READS:
        with ThreadPoolExecutor(4) as pool:
            out[str(reciter)] = dict(pool.map(lambda n: surah(reciter, n), range(1, 115)))
        print(f'qul recitation {reciter}: 114 surahs')
    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text(json.dumps(out, sort_keys=True, separators=(',', ':')), encoding='utf-8')
    print(OUT)
    return 0


if __name__ == '__main__':
    sys.exit(main())
