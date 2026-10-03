"""Turn reciter photos into the small squares the app ships.

Put each photo in `tools/photos/<reciter id>.<jpg|png|webp>` (see the
licence table in `assets/reciters/README.md` for where they come from) and
run this. Each is cropped to a centred square and written as a 128 px WebP
in `assets/reciters/<id>.webp`, about 6 KB: a list of every reciter costs
the app less than 100 KB, and Flutter decodes each one once.

Usage:
  python3 tools/build_reciter_photos.py [--check]

`--check` reports what would be written and the total size without writing.
"""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
SRC = ROOT / 'photos'
OUT = ROOT.parent / 'assets' / 'reciters'
SIZE = 128
QUALITY = 82


def main() -> None:
    check = '--check' in sys.argv
    OUT.mkdir(parents=True, exist_ok=True)
    total = 0
    written = 0
    sources = sorted(
        p
        for p in SRC.glob('*')
        if p.suffix.lower() in {'.jpg', '.jpeg', '.png', '.webp'}
    )
    if not sources:
        print(f'no photos in {SRC.relative_to(ROOT.parent)}')
        return
    for src in sources:
        if not src.stem.isdigit():
            print(f'{src.name}: skipped, the name must be the reciter id')
            continue
        dst = OUT / f'{src.stem}.webp'
        with Image.open(src) as im:
            im = im.convert('RGB')
            side = min(im.size)
            left = (im.width - side) // 2
            top = (im.height - side) // 2
            im = im.crop((left, top, left + side, top + side))
            im = im.resize((SIZE, SIZE), Image.LANCZOS)
            if not check:
                im.save(dst, 'WEBP', quality=QUALITY, method=6)
        size = dst.stat().st_size if dst.exists() else 0
        total += size
        written += 1
        print(f'{src.name} -> {dst.name} ({size // 1024} KB)' if not check else
              f'{src.name} -> would write {dst.name}')
    if check:
        print(f'{written} photos; sizes are only known after writing')
    else:
        print(f'{written} photos, {total / 1024:.0f} KB in all')


if __name__ == '__main__':
    main()
