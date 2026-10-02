"""Download mp3quran.net verse timings for the riwaya recitations Tibyan
ships (see RIWAYA_RECITERS in build_content_db.py).

Usage:
  python3 tools/fetch_riwaya_timing.py

Writes tools/.cache/mp3quran_riwaya_timing.json: {read id: {surah: [[ayah,
start_ms, end_ms], ...]}}, keys sorted so the file's SHA-256 is stable.
Only the timing fields are kept; they are copied as published. The verses
are numbered as in the riwaya (mp3quran numbers them so).
"""
import json
import sys
from pathlib import Path

from fetch_ayat_timing import API, fetch

ROOT = Path(__file__).resolve().parent
OUT = ROOT / '.cache' / 'mp3quran_riwaya_timing.json'

# mp3quran "read" ids with timing, by riwaya.
READS = {
    'warsh': [120, 14, 16, 80, 134],
    'qalun': [270, 75, 208],
    'douri': [269],
    'shubah': [305],
}


def main():
    out = {}
    for reads in READS.values():
        for read in reads:
            out[str(read)] = {}
            for surah in range(1, 115):
                rows = fetch(API.format(surah=surah, read=read))
                out[str(read)][str(surah)] = [
                    [int(r['ayah']), int(r['start_time']), int(r['end_time'])] for r in rows
                ]
            print(f'read {read}: 114 surahs', flush=True)
    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text(json.dumps(out, sort_keys=True, separators=(',', ':')), encoding='utf-8')
    print(OUT)
    return 0


if __name__ == '__main__':
    sys.exit(main())
