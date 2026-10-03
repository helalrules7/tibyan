"""Download recitation audio into tools/.cache for the timing tools.

  python3 tools/fetch_recitation_audio.py surahs 5 8        # surah files of reciters 5 and 8
  python3 tools/fetch_recitation_audio.py verses Mustafa_Ismail_48kbps

Surah files land in tools/.cache/audio/<reciter>/NNN.mp3, fetched from the
reciter's folder URL (build_content_db.RECITERS); Tibyan's mirror is not
used here, so the files are the source's own bytes and their SHA-256
can be checked against the mirror (tools/.cache/audio/<reciter>/SHA256SUMS
is written for that).
Per-verse files (everyayah.com/data/<folder>/SSSAAA.mp3) land in
tools/.cache/everyayah/<folder>/ (from the folder's zip when offered,
else file by file); they are used to build and check
timings only and are not shipped.
Files already present are kept. Needs curl.
"""
import hashlib
import subprocess
import zipfile
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import build_content_db as c

CACHE = Path(__file__).resolve().parent / '.cache'


def get(url, target):
    if target.exists() and target.stat().st_size > 0:
        return True
    part = target.with_suffix('.part')
    ok = subprocess.run(['curl', '-sfL', '--retry', '5', '--retry-delay', '5',
                         '-A', 'tibyan-tools/0.1', '-o', str(part), url]).returncode == 0
    if ok:
        part.rename(target)
    return ok


def sha256(path):
    digest = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            digest.update(chunk)
    return digest.hexdigest()


def surahs(reciter):
    folder = next(r[4] for r in c.RECITERS if r[0] == reciter)
    out = CACHE / 'audio' / str(reciter)
    out.mkdir(parents=True, exist_ok=True)
    jobs = [(c.surah_url(folder, s), out / f'{s:03d}.mp3') for s in range(1, 115)]
    with ThreadPoolExecutor(4) as pool:
        failed = [t.name for (u, t), ok in zip(jobs, pool.map(lambda j: get(*j), jobs)) if not ok]
    lines = [f'{sha256(t)}  {t.name}\n' for _, t in jobs if t.exists()]
    (out / 'SHA256SUMS').write_text(''.join(lines))
    print(f'reciter {reciter}: {len(lines)} of 114 surah files, failed: {failed}')


def verses(folder):
    import sqlite3
    db = sqlite3.connect(c.OUT)
    keys = db.execute('SELECT surah, number FROM ayah ORDER BY surah, number').fetchall()
    out = CACHE / 'everyayah' / folder
    out.mkdir(parents=True, exist_ok=True)
    # everyayah offers each folder as one zip: much faster than 6,236 requests.
    archive = CACHE / 'everyayah' / f'{folder}.zip'
    if get(f'https://everyayah.com/data/{folder}/000_versebyverse.zip', archive):
        with zipfile.ZipFile(archive) as z:
            for name in z.namelist():
                base = Path(name).name
                if base.endswith('.mp3') and not (out / base).exists():
                    (out / base).write_bytes(z.read(name))
    jobs = [(f'https://everyayah.com/data/{folder}/{s:03d}{a:03d}.mp3', out / f'{s:03d}{a:03d}.mp3')
            for s, a in keys]
    with ThreadPoolExecutor(8) as pool:
        failed = [t.name for (u, t), ok in zip(jobs, pool.map(lambda j: get(*j), jobs)) if not ok]
    print(f'{folder}: {len(jobs) - len(failed)} of {len(jobs)} verse files, failed: {failed[:20]}')


def main():
    kind, *args = sys.argv[1:]
    for a in args:
        surahs(int(a)) if kind == 'surahs' else verses(a)
    return 0


if __name__ == '__main__':
    sys.exit(main())
