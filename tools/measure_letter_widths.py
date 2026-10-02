"""Measures where each letter of each word ends in the KFGQPC Hafs font,
for build_tajweed.py (where a tajweed letter lies inside a printed word).

For every word of the KFGQPC text, the width of each prefix that ends
after a letter (the letter with its marks) is measured, with a zero-width
joiner after it so the last letter keeps the shape it has inside the
word. Uses headless Google Chrome (canvas measureText) so Arabic shaping
is exact. The font is only measured, never modified or drawn.

Output: tools/word_letter_widths.json  {word: [prefix width at 100 px, ...]}
        (one number per letter; the last one is the whole word)
Usage:  python3 tools/measure_letter_widths.py
"""
import html
import json
import re
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
from build_word_boxes import HIZB, TEXT_ZIP, load_text  # noqa: E402
from build_tajweed import letters  # noqa: E402

CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
FONT = 'UthmanicHafs_v2-0 font/uthmanic_hafs_v20.ttf'
OUT = ROOT / 'word_letter_widths.json'
ZWJ = '‍'


def prefixes(word):
    """The strings measured for a word: each prefix through a letter."""
    spans = letters(word)
    return [word[:end] + (ZWJ if i < len(spans) - 1 else '') for i, (_, end) in enumerate(spans)]


def main():
    words = sorted({w for ws in load_text().values() for w in ws if w != HIZB})
    jobs = {w: prefixes(w) for w in words}
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        with zipfile.ZipFile(TEXT_ZIP) as z:
            (tmp / 'font.ttf').write_bytes(z.read(FONT))
        (tmp / 'measure.html').write_text(
            '<!doctype html><meta charset=utf-8><style>@font-face{font-family:K;src:url(font.ttf)}</style>'
            '<pre id=o></pre><script>const jobs=' + json.dumps(jobs, ensure_ascii=False) + ';'
            "document.fonts.load('100px K').then(()=>{const c=document.createElement('canvas').getContext('2d');"
            "c.font='100px K';c.direction='rtl';const r={};"
            "for(const w in jobs)r[w]=jobs[w].map(p=>Math.round(c.measureText(p).width*100)/100);"
            "document.getElementById('o').textContent=JSON.stringify(r);});</script>", encoding='utf-8')
        dom = subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--allow-file-access-from-files',
                              '--virtual-time-budget=60000', '--dump-dom', (tmp / 'measure.html').as_uri()],
                             capture_output=True, text=True, check=True).stdout
    widths = json.loads(html.unescape(re.search(r'<pre id="o">(.*?)</pre>', dom, re.S).group(1)))
    assert len(widths) == len(words)
    OUT.write_text(json.dumps(dict(sorted(widths.items())), ensure_ascii=False, separators=(',', ':')),
                   encoding='utf-8')
    print(f'{len(widths)} words measured -> {OUT.relative_to(ROOT.parent)}')


if __name__ == '__main__':
    main()
