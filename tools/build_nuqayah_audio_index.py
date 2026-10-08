"""Build the per-verse audio index of Nuqayah's tafsir recordings
(«التفسير الميسر» and «تفسير السعدي») from read.tafsir.one.

Permission: Nuqayah, by e-mail, 2026-09-28: yes, on condition of no ads and
no profit (docs/licenses/2026-09-28_nuqayah_permission_email.pdf; MISSING_DATA
ن6 / إ9). We still wait for their attribution wording and for how they want
the files fetched, so the index is staged only and the audio is NOT
downloaded or mirrored.

Where the audio is: not documented. The reader loads each book a mushaf
page at a time from get.php (the same endpoint tools/fetch_gharib.py uses
for «الميسر في غريب القرآن»), and its JavaScript builds the player URLs.
This script therefore:
  1. `probe`: saves the reader's HTML, the scripts it loads and one get.php
     page per book, and lists every audio URL or URL template found in them
     (find_audio_urls / find_templates). Read the result and set PATTERNS.
  2. `build`: walks every page of each book through get.php, collects the
     audio URLs found in the responses (or, if a book's responses carry
     none, fills the confirmed template in PATTERNS), checks that each verse
     gets exactly one URL, and HEAD-checks a sample.
     A book whose files turn out to be one per surah gets its template in
     SURAH_PATTERNS instead ({surah} or {s3}); the index then lists the
     surah files, and per-verse offsets only if Nuqayah provides them.
Output: tools/.cache/staging/nuqayah/<book>/ with index.json (the verse
audio index the app reads, format 1: tools/audio_index.py and
docs/features/audio_content.md), head_checks.json, SHA256SUMS and
manifest.json. No text from the responses is kept.

A third-party page links per-surah files of another book
(https://mirrors.quranicaudio.com/tafsir.one/ibn-juzay/001.mp3), so the
recordings may be per surah rather than per verse; `probe` settles this.

Probe of 2026-10-05 (from the reader's own script, not from get.php): the
recordings are one file a surah, at
  https://read.tafsir.one/audio/<key>/<s3>.mp3   (key: almuyassar, alsidi)
and the reader seeks inside them from a times file,
  https://read.tafsir.one/data/times-<key>.txt
114 surahs split by «|», each a comma list of the start (seconds) of each
verse's tafsir in its surah file; an empty value means the verse has no
time of its own (the reader says «choose the previous verse»: it is read
with the verse before). `build` keeps the times file as served and turns it
into offsets (offsets_from_times): a timed verse runs to the next timed
verse, an untimed verse (empty, or past the end of a short line) shares
the span of the timed verse before it, and the last timed verse of a surah
runs to the end of the file (its duration, read with ffprobe). A surah
with no time at all gets no offsets (the app then plays its file whole).

Usage:
  python3 tools/build_nuqayah_audio_index.py probe
  python3 tools/build_nuqayah_audio_index.py build [almuyassar saadi]
"""
import json
import random
import re
import subprocess
import sys
import time

import audio_index
import staging

READER = 'https://read.tafsir.one/'
API = 'https://read.tafsir.one/get.php?uth&src={src}&s={surah}&a={ayah}'
OUT = staging.STAGING / 'nuqayah'
# Book -> get.php `src`. «almuyassar-g» (the gharib book) is confirmed by
# fetch_gharib.py; these two are the reader's path names and are checked by
# `probe` before `build` is trusted.
BOOKS = {'almuyassar': 'almuyassar', 'saadi': 'saadi'}
# Book -> confirmed URL template ({surah}, {ayah}, {s3}, {a3}), filled
# after `probe` only if the get.php responses carry no URL themselves.
PATTERNS = {}
# Book -> confirmed per-surah file template ({surah}, {s3}), when the
# recordings are one file a surah. Offsets of the verses in those files
# are not published; they are added only if Nuqayah sends them.
SURAH_PATTERNS = {
    'almuyassar': 'https://read.tafsir.one/audio/almuyassar/{s3}.mp3',
    'saadi': 'https://read.tafsir.one/audio/alsidi/{s3}.mp3',
}
# Book -> the reader's times file for its surah files (see the docstring).
TIMES = {
    'almuyassar': 'https://read.tafsir.one/data/times-almuyassar.txt',
    'saadi': 'https://read.tafsir.one/data/times-alsidi.txt',
}
# The index's names, for the app (the book titles, as Nuqayah names them).
TITLES = {
    'almuyassar': ('التفسير الميسر', 'Al-Tafsir al-Muyassar'),
    'saadi': ('تفسير السعدي', 'Tafsir al-Sa\'di'),
}
# Credit key in lib/features/mushaf/presentation/source_names.dart.
SOURCE_KEY = 'nuqayah-tafsir-audio'
STATUS = ('APPROVED with conditions (no ads, no profit), attribution wording and '
          'file access pending (letter 8). Index staged only; audio not mirrored.')
AUDIO_RE = re.compile(r'''(?:https?:)?//[^\s"'<>()]+?\.(?:mp3|m4a|ogg|opus|aac|wav)(?:\?[^\s"'<>()]*)?''', re.I)
TEMPLATE_RE = re.compile(r'''[`"']([^`"'\s]*?(?:\$\{[^}]+\}|\{[a-z0-9_]+\}|"\s*\+)[^`"'\s]*?\.(?:mp3|m4a|ogg|opus))[`"']''', re.I)
SCRIPT_RE = re.compile(r'''<script[^>]+src=["']([^"']+)["']''', re.I)


def find_audio_urls(obj):
    """Every audio URL anywhere in a decoded JSON value or a string, in
    order of appearance, without duplicates."""
    found = []

    def walk(o):
        if isinstance(o, dict):
            for v in o.values():
                walk(v)
        elif isinstance(o, list):
            for v in o:
                walk(v)
        elif isinstance(o, str):
            for m in AUDIO_RE.findall(o):
                if m not in found:
                    found.append(m)
    walk(obj)
    return found


def find_templates(js):
    """URL templates for audio files in a script (template literals,
    {placeholders} or string concatenation ending in an audio extension)."""
    out = []
    for m in TEMPLATE_RE.findall(js):
        if m not in out:
            out.append(m)
    return out


def fill(pattern, surah, ayah):
    return pattern.format(surah=surah, ayah=ayah, s3=f'{surah:03d}', a3=f'{ayah:03d}')


def index_payload(book, verses=(), surahs=(), offsets=(), **meta):
    """The app's verse audio index (format 1) for one book."""
    ar, en = TITLES.get(book, (book, book))
    return audio_index.make_index(
        f'nuqayah-{book}', 'tafsir_audio', SOURCE_KEY, verses=verses, surahs=surahs,
        offsets=offsets, title_ar=ar, title_en=en, book=book, src=BOOKS.get(book), **meta)


def page_span(response, ayah):
    """(first verse, verse count) of a get.php page, as fetch_gharib.py reads it."""
    if 'ayahs' in response:
        return int(response['ayahs_start']), len(response['ayahs'])
    return ayah, 1


def assign(page_start, count, urls):
    """Map the audio URLs of one page to its verses. One URL per verse in
    order is accepted; anything else returns None (checked by hand)."""
    if len(urls) != count:
        return None
    return {page_start + i: u for i, u in enumerate(urls)}


def probe():
    d = OUT / 'probe'
    d.mkdir(parents=True, exist_ok=True)
    html = staging.get(READER)
    (d / 'reader.html').write_bytes(html)
    report = {'reader_audio_urls': find_audio_urls(html.decode('utf-8', 'replace')), 'scripts': {}}
    for src in SCRIPT_RE.findall(html.decode('utf-8', 'replace')):
        url = src if src.startswith('http') else READER.rstrip('/') + '/' + src.lstrip('/')
        try:
            js = staging.get(url).decode('utf-8', 'replace')
        except Exception as e:  # report and go on
            report['scripts'][url] = {'error': str(e)}
            continue
        report['scripts'][url] = {'audio_urls': find_audio_urls(js)[:20],
                                  'templates': find_templates(js)[:20]}
    for book, src in BOOKS.items():
        body = staging.get(API.format(src=src, surah=2, ayah=255))
        (d / f'get_{book}_2_255.json').write_bytes(body)
        r = json.loads(body)
        report[book] = {'keys': sorted(r) if isinstance(r, dict) else type(r).__name__,
                        'audio_urls': find_audio_urls(r)}
    (d / 'probe.json').write_text(json.dumps(report, indent=1) + '\n', encoding='utf-8')
    staging.write_sums(d)
    print(json.dumps(report, indent=1))


def offsets_from_times(text, durations):
    """[surah, ayah, start_ms, end_ms] rows from a reader times file (see
    the docstring) and the surah files' durations in ms ({surah: ms}, a
    surah missing from it gets no offset for its last timed verse).
    Returns (offsets, problems); a span that is not increasing is left out
    and reported, never guessed."""
    lines = text.strip().split('|')
    if len(lines) != 114:
        raise ValueError(f'times: {len(lines)} surahs, not 114')
    offsets, problems = [], []
    for surah, line in enumerate(lines, 1):
        count = staging.VERSE_COUNTS[surah - 1]
        values = line.split(',')
        if len(values) > count:
            raise ValueError(f'times: surah {surah} has {len(values)} values for {count} verses')
        starts = [(a, round(float(v) * 1000)) for a, v in enumerate(values, 1) if v.strip()]
        for i, (ayah, start) in enumerate(starts):
            if i + 1 < len(starts):
                end, last = starts[i + 1][1], starts[i + 1][0] - 1
            elif surah in durations:
                end, last = durations[surah], count
            else:
                continue  # end unknown: the app plays the surah file whole
            if not 0 <= start < end:
                problems.append([surah, ayah, start, end])
                continue
            offsets.extend([surah, a, start, end] for a in range(ayah, last + 1))
    return offsets, problems


def duration_ms(url):
    """The duration of a remote audio file in ms (ffprobe reads its head)."""
    out = subprocess.run(
        ['ffprobe', '-v', 'error', '-user_agent', staging.USER_AGENT, '-show_entries',
         'format=duration', '-of', 'default=nw=1:nk=1', url],
        capture_output=True, text=True, timeout=120, check=True).stdout
    return round(float(out.strip()) * 1000)


def build_surah_book(book, sample=10):
    """A book recorded one file a surah: the index lists the 114 files, and
    the verses' offsets in them when the reader has a times file."""
    surahs = [[s, fill(SURAH_PATTERNS[book], s, 0)] for s in range(1, 115)]
    d = OUT / book
    d.mkdir(parents=True, exist_ok=True)
    offsets, problems, durations = [], [], {}
    if book in TIMES:
        times = staging.get(TIMES[book])
        (d / 'times.txt').write_bytes(times)
        for s, u in surahs:
            try:
                durations[s] = duration_ms(u)
            except (subprocess.SubprocessError, ValueError, OSError) as e:
                problems.append([s, 'duration', str(e)])
        (d / 'durations.json').write_text(json.dumps(durations, indent=0) + '\n',
                                          encoding='utf-8')
        offsets, bad = offsets_from_times(times.decode('utf-8'), durations)
        problems += bad
    audio_index.write(d / 'index.json', index_payload(book, surahs=surahs, offsets=offsets,
                                                      times=TIMES.get(book)))
    picks = surahs[:1] + surahs[-1:] + random.Random(20261005).sample(surahs, min(sample, 114))
    checks = [dict(staging.head_record(u), surah=s) for s, u in picks]
    (d / 'head_checks.json').write_text(json.dumps(checks, indent=1) + '\n', encoding='utf-8')
    staging.write_sums(d)
    ok = sum(1 for c in checks if c['status'] == 200)
    staging.write_manifest(d, book=book, source=SURAH_PATTERNS[book], surahs_indexed=114,
                           times=TIMES.get(book), verses_with_offsets=len(offsets),
                           offset_problems=problems, head_checked=len(checks), head_ok=ok,
                           mirrored=False, status=STATUS)
    print(f'{book}: 114 surah files indexed, {len(offsets)} verses with offsets, '
          f'{len(problems)} problems, HEAD {ok}/{len(checks)}')


def build_book(book, sample=10):
    if book in SURAH_PATTERNS:
        return build_surah_book(book, sample)
    src = BOOKS[book]
    index, unassigned = {}, []
    for surah, count in enumerate(staging.VERSE_COUNTS, 1):
        ayah = 1
        while ayah <= count:
            r = json.loads(staging.get(API.format(src=src, surah=surah, ayah=ayah)))
            start, n = page_span(r, ayah)
            got = assign(start, n, find_audio_urls(r)) if book not in PATTERNS else None
            if got is None and book in PATTERNS:
                got = {a: fill(PATTERNS[book], surah, a) for a in range(start, start + n)}
            if got is None:
                unassigned.append([surah, start, n])
            else:
                for a, u in got.items():
                    index[(surah, a)] = u
            ayah = start + n
            time.sleep(0.1)
    d = OUT / book
    d.mkdir(parents=True, exist_ok=True)
    rows = [[s, a, u] for (s, a), u in sorted(index.items())]
    audio_index.write(d / 'index.json',
                      index_payload(book, verses=rows, unassigned_pages=unassigned))
    picks = rows[:1] + rows[-1:] + random.Random(20261005).sample(rows, min(sample, len(rows)))
    checks = [dict(staging.head_record(u), surah=s, ayah=a) for s, a, u in picks]
    (d / 'head_checks.json').write_text(json.dumps(checks, indent=1) + '\n', encoding='utf-8')
    staging.write_sums(d)
    ok = sum(1 for c in checks if c['status'] == 200)
    staging.write_manifest(d, book=book, source=API.replace('{src}', src),
                           verses_indexed=len(rows), unassigned_pages=len(unassigned),
                           head_checked=len(checks), head_ok=ok, mirrored=False, status=STATUS)
    print(f'{book}: {len(rows)} verses indexed, {len(unassigned)} pages unassigned, HEAD {ok}/{len(checks)}')


def main(argv):
    if not argv or argv[0] == 'probe':
        probe()
        return 0
    if argv[0] == 'build':
        for book in argv[1:] or list(BOOKS):
            build_book(book)
        return 0
    print(__doc__)
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
