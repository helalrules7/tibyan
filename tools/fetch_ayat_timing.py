"""Download mp3quran.net verse timings for the reciters Tibyan ships.

Usage:
  python3 tools/fetch_ayat_timing.py

Writes tools/.cache/mp3quran_ayat_timing.json: {read id: {surah: [[ayah,
start_ms, end_ms], ...]}}, keys sorted so the file's SHA-256 is stable.
Only the timing fields are kept; they are copied as published.
"""
import json
import sys
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OUT = ROOT / '.cache' / 'mp3quran_ayat_timing.json'
API = 'https://www.mp3quran.net/api/v3/ayat_timing?surah={surah}&read={read}'

# mp3quran "read" ids with timing for the reciters Tibyan ships: al-Minshawi,
# al-Husary, Abdul Basit, al-Sudais, al-Tablaway, al-Afasy and al-Ghamdi
# (see build_content_db.RECITERS). al-Banna's and Mustafa Ismail's murattal
# have no published timing (tools/build_quranlab_timing.py derives it), and
# al-Dosari's comes from quran.com (tools/build_qdc_timing.py).
# Each of these seven covers all 114 surahs with every verse timed, measured
# 2026-10-01; reads 31 (al-Shuraim) and 74 (al-Hudhaify) were left out: a
# duplicated verse and a gap in nearly every surah make them unusable.
READS = [112, 118, 53, 54, 106, 123, 30]


def fetch(url):
    for attempt in range(5):
        try:
            request = urllib.request.Request(url, headers={'User-Agent': 'tibyan-tools/0.1'})
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.loads(response.read())
        except Exception:
            if attempt == 4:
                raise
            time.sleep(2 * (attempt + 1))


def main():
    out = {}
    for read in [int(a) for a in sys.argv[1:]] or READS:
        out[str(read)] = {}
        for surah in range(1, 115):
            rows = fetch(API.format(surah=surah, read=read))
            out[str(read)][str(surah)] = [
                [int(r['ayah']), int(r['start_time']), int(r['end_time'])] for r in rows
            ]
        print(f'read {read}: 114 surahs')
    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text(json.dumps(out, sort_keys=True, separators=(',', ':')), encoding='utf-8')
    print(OUT)
    return 0


if __name__ == '__main__':
    sys.exit(main())
