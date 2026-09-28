"""Download every source listed in tools/sources.json and verify it.

Usage:
  python3 tools/fetch_sources.py            # all sources
  python3 tools/fetch_sources.py tanzil-uthmani-1.1

Files land in tools/.cache/ (git-ignored). A file whose SHA-256 differs
from the manifest is rejected: a changed upstream file must be reviewed
and the manifest updated in its own data(...) commit.
"""
import hashlib
import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CACHE = ROOT / '.cache'


def sha256(path):
    digest = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            digest.update(chunk)
    return digest.hexdigest()


def download(source, target):
    data = None
    if source.get('method', 'GET') == 'POST':
        data = urllib.parse.urlencode(source['form']).encode()
    request = urllib.request.Request(
        source['url'], data=data, headers={'User-Agent': 'tibyan-tools/0.1'})
    with urllib.request.urlopen(request, timeout=300) as response:
        target.write_bytes(response.read())


def main(wanted):
    manifest = json.loads((ROOT / 'sources.json').read_text(encoding='utf-8'))
    CACHE.mkdir(exist_ok=True)
    failed = False
    for source in manifest['sources']:
        if wanted and source['id'] not in wanted:
            continue
        target = CACHE / source['file']
        if not target.exists() or sha256(target) != source['sha256']:
            download(source, target)
        actual = sha256(target)
        if actual == source['sha256']:
            print(f"ok       {source['id']}")
        else:
            failed = True
            print(f"MISMATCH {source['id']}: expected {source['sha256']}, got {actual}")
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main(set(sys.argv[1:])))
