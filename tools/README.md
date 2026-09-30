# tools

Scripts that download, verify and prepare data. They handle structure only (download, checksum, split, map to verses, compare). **They never write or change religious text.**

| Script | What it does |
|---|---|
| `fetch_sources.py` | Downloads every source in `sources.json` into `.cache/` and rejects any file whose SHA-256 differs |
| `fetch_quranlab_timing.py` | Downloads QuranLab's word timings for al-Banna (murattal) into `.cache/quranlab_banna_timing.json` |
| `build_quranlab_timing.py` | Finds each al-Banna verse in the mp3quran surah files by its sound, derives verse boundaries and places QuranLab's word timings; surahs that fail a check get no timing |
| `verify_word_timing.py` | Checks word timings against pauses heard in the audio, and verse boundaries against quiet points |
| `build_shamarly.py` | Shamarly mushaf page geometry from its page images (lines, cuts, verse markers, verse and word boxes, headers) into `.cache/shamarly_geometry.db`; `shamarly_image.py` holds its image helpers |
| `verify_shamarly.py` | Checks that geometry against the images, `shamerly.db` and the first-word index; `--preview PAGES` draws overlays |
| `fetch_gharib.py` | Downloads «الميسر في غريب القرآن» from Nuqayah's reader (read.tafsir.one), page by page, into `.cache/nuqayah_almuyassar_gharib.json` |
| `build_word_study.py` | Roots and lemmas (Quranic Arabic Corpus 0.4) and the book's entries, mapped to our word numbers for `content.db` (`word_root`, `gharib`); prints the coverage |
| `verify_text/compare_tanzil_kfgqpc.py` | Lists verses whose base letters differ between Tanzil and the KFGQPC text. Every listed verse goes to a human reviewer |

Rules:
- Raw files stay in `.cache/` (git-ignored) and are rebuilt from `sources.json`.
- A new or changed source gets its own `data(...)` commit that names the source, edition and license, and updates `docs/DATA_SOURCES.md`.
- License evidence for each source lives in `docs/licenses/`.
