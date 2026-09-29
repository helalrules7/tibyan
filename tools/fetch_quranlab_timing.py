"""Download QuranLab's word timings for Mahmoud Ali al-Banna (murattal).

Source: https://huggingface.co/datasets/quranlab/quran-audio, config
`mahmoud-ali-al-banna` (word timings CC BY 4.0; the dataset hosts no
audio). The rows are read through the Hugging Face datasets-server API,
so no Parquet library is needed.

Each row is one verse, aligned on everyayah's per-verse file
(mahmoud_ali_al_banna_32kbps/SSSAAA.mp3). `segments` hold one entry per
word: word_start/word_end are 0-based word indices [start, end) of the
Tanzil Uthmani text, start_ms/end_ms are times in the per-verse file.

Usage:
  python3 tools/fetch_quranlab_timing.py

Writes tools/.cache/quranlab_banna_timing.json:
  {surah: {ayah: [[word_start, word_end, start_ms, end_ms], ...]}}
Verses without timing are left out. Keys are sorted so the file's
SHA-256 is stable. Only the timing fields are kept, copied as published.
"""
import json
import sys
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OUT = ROOT / '.cache' / 'quranlab_banna_timing.json'
CONFIG = 'mahmoud-ali-al-banna'
API = ('https://datasets-server.huggingface.co/rows?dataset=quranlab/quran-audio'
       f'&config={CONFIG}&split=train&offset={{offset}}&length=100')


def fetch(url):
    # The API answers 429 when asked too fast: go slowly and back off.
    for attempt in range(8):
        try:
            request = urllib.request.Request(url, headers={'User-Agent': 'tibyan-tools/0.1'})
            with urllib.request.urlopen(request, timeout=60) as response:
                time.sleep(1)
                return json.loads(response.read())
        except Exception:
            if attempt == 7:
                raise
            time.sleep(10 * (attempt + 1))


def main():
    out, offset, total = {}, 0, None
    while total is None or offset < total:
        page = fetch(API.format(offset=offset))
        total = page['num_rows_total']
        for item in page['rows']:
            assert not item.get('truncated_cells'), item['row']['verse_key']
            row = item['row']
            assert row['recitation_id'] == CONFIG and row['riwayah'] == 'hafs-asim'
            if not row['has_word_timing']:
                continue
            out.setdefault(str(row['surah']), {})[str(row['ayah'])] = [
                [s['word_start'], s['word_end'], s['start_ms'], s['end_ms']]
                for s in row['segments']
            ]
        offset += len(page['rows'])
    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text(json.dumps(out, sort_keys=True, separators=(',', ':')), encoding='utf-8')
    print(f'{sum(len(v) for v in out.values())} of {total} verses timed -> {OUT}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
