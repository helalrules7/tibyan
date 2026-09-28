"""Compare the Tanzil Uthmani text with the KFGQPC Hafs text, verse by verse.

Structure-only check: it never edits either text. It reports which verses
differ in their base letters once the two encodings' conventions are set
aside (diacritic code points, pause marks, hamza forms, alef maksura/yeh).
Every reported verse must be checked by a human reviewer.

Usage:
  python3 compare_tanzil_kfgqpc.py quran-uthmani.txt hafsData_v18.json
"""
import json
import re
import sys
import unicodedata as ud

MAP = {'ى': 'ي', 'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ؤ': 'و', 'ئ': 'ي'}
DROP = set('ـ۞۩ ء')


def load_tanzil(path):
    verses = {}
    for line in open(path, encoding='utf-8'):
        parts = line.rstrip('\n').split('|')
        if len(parts) == 3 and parts[0].isdigit():
            verses[(int(parts[0]), int(parts[1]))] = parts[2]
    return verses


def skeleton(text):
    text = re.sub(r'[ \s]*[٠-٩]+\s*$', '', text)
    out = []
    for ch in ud.normalize('NFD', text):
        if ud.category(ch) == 'Mn' or ch in DROP:
            continue
        out.append(MAP.get(ch, ch))
    return re.sub(r'\s+', ' ', ''.join(out)).strip()


def strip_basmala(verses, key):
    """Tanzil's text file puts the basmala before verse 1 of 112 surahs."""
    text = verses[key]
    if key[1] != 1 or key[0] == 1:
        return text
    basmala = skeleton(verses[(1, 1)])
    words = text.split(' ')
    if skeleton(' '.join(words[:4])) == basmala:
        return ' '.join(words[4:])
    return text


def main(tanzil_path, kfgqpc_path):
    tanzil = load_tanzil(tanzil_path)
    kfgqpc = {(int(r['sora']), int(r['aya_no'])): r['aya_text']
              for r in json.load(open(kfgqpc_path, encoding='utf-8-sig'))}
    assert set(tanzil) == set(kfgqpc), 'verse keys differ'
    differing = [key for key in sorted(tanzil)
                 if skeleton(strip_basmala(tanzil, key)) != skeleton(kfgqpc[key])]
    print(f'verses: {len(tanzil)}, differing in base letters: {len(differing)}')
    for key in differing:
        print(f'{key[0]}:{key[1]}')
        print('  tanzil:', tanzil[key])
        print('  kfgqpc:', kfgqpc[key])
    return 1 if differing else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1], sys.argv[2]))
