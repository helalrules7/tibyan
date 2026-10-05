"""The verse audio index that the app reads (format 1): where the audio of
each verse is, for a streamed recording that is never bundled or mirrored
(a tafsir read aloud, or a translation read after each verse).

Written by tools/build_nuqayah_audio_index.py (Nuqayah's tafsir audio) and
tools/fetch_quranenc_extra.py (QuranEnc's english_rwwad); read by
lib/features/content_extras/verse_audio_index.dart. docs/features/
audio_content.md describes it.

    {
      "format": 1,
      "id": "nuqayah-almuyassar",          # the index's own name
      "kind": "tafsir_audio",              # or "translation_audio"
      "source": "nuqayah-tafsir-audio",    # credit key (source_names.dart)
      "title_ar": "...", "title_en": "...",
      "verses":  [[surah, ayah, url], ...],               # one file a verse
      "surahs":  [[surah, url], ...],                     # one file a surah
      "offsets": [[surah, ayah, start_ms, end_ms], ...]   # verses in them
    }

A verse plays from its own file when "verses" has it, else from its
surah's file between its offsets. A surah file without offsets plays
whole, as the tafsir of the surah. Other keys are kept (they record where
the index came from) and the app ignores them. URLs are https only.
"""
import json

import staging

FORMAT = 1
KINDS = ('tafsir_audio', 'translation_audio')


def make_index(id, kind, source, *, verses=(), surahs=(), offsets=(), **meta):
    """A format 1 index, checked with [validate]. Rows are sorted."""
    index = dict(meta)
    index.update(format=FORMAT, id=id, kind=kind, source=source)
    if verses:
        index['verses'] = sorted([int(s), int(a), u] for s, a, u in verses)
    if surahs:
        index['surahs'] = sorted([int(s), u] for s, u in surahs)
    if offsets:
        index['offsets'] = sorted([int(s), int(a), int(b), int(e)] for s, a, b, e in offsets)
    validate(index)
    return index


def validate(index):
    """Raises ValueError on anything the app would refuse or misplay."""
    if index.get('format') != FORMAT:
        raise ValueError(f'format must be {FORMAT}')
    if index.get('kind') not in KINDS:
        raise ValueError(f'unknown kind {index.get("kind")!r}')
    for key in ('id', 'source'):
        if not isinstance(index.get(key), str) or not index[key]:
            raise ValueError(f'missing {key}')

    def verse_ok(s, a):
        return 1 <= s <= 114 and 1 <= a <= staging.VERSE_COUNTS[s - 1]

    def url_ok(u):
        return isinstance(u, str) and u.startswith('https://')

    seen = set()
    for row in index.get('verses', []):
        s, a, u = row
        if not verse_ok(s, a):
            raise ValueError(f'no verse {s}:{a}')
        if not url_ok(u):
            raise ValueError(f'{s}:{a}: not an https URL: {u!r}')
        if (s, a) in seen:
            raise ValueError(f'{s}:{a} twice')
        seen.add((s, a))
    surahs = set()
    for s, u in index.get('surahs', []):
        if not 1 <= s <= 114 or s in surahs:
            raise ValueError(f'surah {s}: out of range or twice')
        if not url_ok(u):
            raise ValueError(f'surah {s}: not an https URL: {u!r}')
        surahs.add(s)
    spans = set()
    for s, a, b, e in index.get('offsets', []):
        if not verse_ok(s, a) or s not in surahs:
            raise ValueError(f'offset for {s}:{a} without its surah file')
        if not 0 <= b < e:
            raise ValueError(f'{s}:{a}: offsets {b}..{e}')
        if (s, a) in spans:
            raise ValueError(f'offsets for {s}:{a} twice')
        spans.add((s, a))
    if not seen and not surahs:
        raise ValueError('empty index')


def write(path, index):
    """Writes the index compactly (UTF-8, one line) after [validate]."""
    validate(index)
    path.write_text(json.dumps(index, ensure_ascii=False, separators=(',', ':')) + '\n',
                    encoding='utf-8')
