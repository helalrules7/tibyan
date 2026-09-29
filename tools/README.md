# tools

Scripts that download, verify and prepare data. They handle structure only (download, checksum, split, map to verses, compare). **They never write or change religious text.**

| Script | What it does |
|---|---|
| `fetch_sources.py` | Downloads every source in `sources.json` into `.cache/` and rejects any file whose SHA-256 differs |
| `fetch_quranlab_timing.py` | Downloads QuranLab's word timings for al-Banna (murattal) into `.cache/quranlab_banna_timing.json` |
| `build_quranlab_timing.py` | Finds each al-Banna verse in the mp3quran surah files by its sound, derives verse boundaries and places QuranLab's word timings; surahs that fail a check get no timing |
| `verify_word_timing.py` | Checks word timings against pauses heard in the audio, and verse boundaries against quiet points |
| `verify_text/compare_tanzil_kfgqpc.py` | Lists verses whose base letters differ between Tanzil and the KFGQPC text. Every listed verse goes to a human reviewer |

Rules:
- Raw files stay in `.cache/` (git-ignored) and are rebuilt from `sources.json`.
- A new or changed source gets its own `data(...)` commit that names the source, edition and license, and updates `docs/DATA_SOURCES.md`.
- License evidence for each source lives in `docs/licenses/`.
