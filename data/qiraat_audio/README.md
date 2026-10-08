# صوت القراءات (AQQD) · Qiraat audio index

فهرس مقاطع AQQD (مجموعة بيانات القراءات القرآنية المشروحة، مشروع OSF `6sh5d`) على مستوى الآية: لكل آية، ولكل أسلوب قراءة، المقاطع الموجودة ومكانها على OSF. لا صوت هنا ولا نص قرآني. لإضافة موضع الكلمة المختلف فيها داخل مقطع، اتبع [الدليل](../../docs/QIRAAT_AUDIO.md).

The verse-level index of the AQQD clips (OSF project `6sh5d`): per verse and qiraat style, the clips and where they are on OSF. No audio and no Quran text. To add where the differing word sits inside a clip, see the guide above.

- `index/NNN.json`: one surah; `verses` → verse number → style code (`S5`) → clips, one per line. Each clip: `file`, `reciter`, `clip`, `path` (OSF), `url` (streamed, never bundled), `size`, `duration_ms` (null until read from the WAV header), `group`, `words`. A word entry is `{"range": [start_ms, end_ms, word], "by": "...", "reviewed_by": "..."}`: milliseconds from the start of the clip and the word's number in the verse as in the app (KFGQPC Hafs words, `data/timing/verse_words.json`). Only entries with `reviewed_by` (a second person) are played.
- `styles.json`: style code → qira'a. Filled by hand from the dataset paper's table; `null` = unknown. Never guessed.
- `provenance.json`: the provenance groups and their licence (CC0 only for the authors' own recordings), and which reciter code belongs to which group. Clips of an unclear group are not played by the app.

Built and checked by `tools/qiraat_audio.py` (`build`, `durations`, `check`, `format`). The check runs on every pull request that touches this folder.

Licence: the clips are the AQQD authors' (CC0 1.0 per their paper, for their own recordings; see `provenance.json`). The index and contributed word ranges are released under CC0 1.0 as well.
