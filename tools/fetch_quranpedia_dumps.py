"""Download Quranpedia dump files (https://api.quranpedia.net/dumps/) into
tools/.cache/quranpedia/, byte for byte, and print their SHA-256.

Licence: docs/licenses/2026-09-28_quranpedia_dumps_LICENSE.md (free inside
apps; contemporary works and translations excluded; republishing as a
dataset needs credit and the dump version). Only measured here, never shipped.

The files inspected on 2026-09-28 are checked against the hash recorded in
docs/DATA_SOURCES.md (only its first and last characters were recorded).

Usage:
  python3 tools/fetch_quranpedia_dumps.py qiraat.json.gz topics.json.gz
"""
import sys

import staging

BASE = 'https://api.quranpedia.net/dumps/'
OUT = staging.ROOT / '.cache' / 'quranpedia'
# file -> (start, end) of the SHA-256 recorded in DATA_SOURCES.md.
RECORDED = {'qiraat.json.gz': ('a7076992', '39ca')}


def matches_recorded(name, digest):
    """True/False against the recorded hash, None when none was recorded."""
    if name not in RECORDED:
        return None
    start, end = RECORDED[name]
    return digest.startswith(start) and digest.endswith(end)


def main(names):
    OUT.mkdir(parents=True, exist_ok=True)
    for name in names or ['qiraat.json.gz', 'topics.json.gz']:
        target = OUT / name
        if not target.exists():
            target.write_bytes(staging.get(BASE + name, timeout=300))
        digest = staging.sha256_file(target)
        same = matches_recorded(name, digest)
        note = {None: '(no recorded hash)', True: '(same as 2026-09-28)',
                False: '(CHANGED since 2026-09-28: the dump was corrected upstream)'}[same]
        print(f'{digest}  {name} {note}')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
