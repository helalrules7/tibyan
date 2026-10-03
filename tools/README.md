# tools

Scripts that download, verify and prepare data. They handle structure only (download, checksum, split, map to verses, compare). **They never write or change religious text.**

| Script | What it does |
|---|---|
| `fetch_sources.py` | Downloads every source in `sources.json` into `.cache/` and rejects any file whose SHA-256 differs |
| `fetch_quranlab_timing.py` | Downloads QuranLab's word timings for al-Banna (murattal) into `.cache/quranlab_banna_timing.json` |
| `build_quranlab_timing.py` | Finds each al-Banna verse in the mp3quran surah files by its sound, derives verse boundaries and places QuranLab's word timings; surahs that fail a check get no timing |
| `timing_files.py` | The recitation timings kept as text in `data/timing/` (docs/TIMING.md): `export` from content.db, `check` (the same rules as the timing editor), `pack` for the server, `site` (the editor with the app's words, for GitHub Pages); `apply()` puts them into content.db during the build |
| `build_timing_peaks.py` | Waveform peaks (one byte per 10 ms) of a reciter's surah files for the timing editor, and `data/timing/<slug>/audio.json` (durations); runs on the server |
| `verify_word_timing.py` | Checks word timings against pauses heard in the audio, and verse boundaries against quiet points |
| `build_shamarly.py` | Shamarly mushaf page geometry from its page images (lines, cuts, verse markers, verse and word boxes, headers) into `.cache/shamarly_geometry.db`; `shamarly_image.py` holds its image helpers |
| `verify_shamarly.py` | Checks that geometry against the images, `shamerly.db` and the first-word index; `--preview PAGES` draws overlays |
| `fetch_gharib.py` | Downloads «الميسر في غريب القرآن» from Nuqayah's reader (read.tafsir.one), page by page, into `.cache/nuqayah_almuyassar_gharib.json` |
| `build_word_study.py` | Roots and lemmas (Quranic Arabic Corpus 0.4) and the book's entries, mapped to our word numbers for `content.db` (`word_root`, `gharib`); prints the coverage |
| `build_mutashabih.py` | The mutashabihat links (Waqar144/Quran_Mutashabihat_Data) as verse-id ranges for `content.db` (`mutashabih`); links only, no text. Run alone it updates the bundled `content.db` in place |
| `build_themes.py` | Copies the eight heritage themes' frame, header and marker SVGs unchanged from a quran-assets checkout into `assets/themes/`, and writes each theme's JSON (interface colours checked against the contrast rules, art class colours per mode) |
| `verify_text/compare_tanzil_kfgqpc.py` | Lists verses whose base letters differ between Tanzil and the KFGQPC text. Every listed verse goes to a human reviewer |
| `import_wahidi_asbab.py` | Splits al-Wahidi's «أسباب نزول القرآن» (OpenITI) by the book's own sections and passage headers into a review database of drafts, with suggested verse links and their confidence. Proves the split kept every word |
| `review_db.py`, `review_schema.sql` | The review database: schema (append-only audit log, frozen text, reviewer ≠ editor) and the content hash shared with the review tool |
| `build_tajweed.py` | Places the cpfair/quran-tajweed spans (CC BY 4.0) on the three editions' pages for `content.db` (`tajweed_page`): Tanzil 2017 offsets moved letter by letter onto the KFGQPC words, then onto the page contours (1441) or the ink inside the word boxes (1405, Shamarly). Never writes text; `--into DB` adds the table to a built database |
| `measure_letter_widths.py` | Measures where each letter of each KFGQPC word ends in the KFGQPC font (headless Chrome, measuring only) into `word_letter_widths.json`, for `build_tajweed.py` |
| `verify_tajweed.py` | Draws new-edition pages with their tajweed colouring (`tools/out/tajweed_NNN.png`) for a person to check |
| `riwayat.py` | Readers for the riwaya sources (quran-ws pages and outlines, KFGQPC riwaya texts and fonts, Quranpedia), and the riwaya → Hafs verse map worked out by aligning the base letters of the KFGQPC riwaya and Hafs texts (letters compared, never changed) |
| `verify_riwayat.py` | Cross-checks the riwaya sources (verse counts per surah, start pages, the map's coverage and order, the map against Quranpedia's `number_in_hafs`); `--report` writes `docs/verification/` |
| `build_riwaya_packs.py` | Builds the Warsh, Qalun, al-Duri and Shu'bah page packs: the quran-ws SVG pages unchanged (xz each), `riwaya.json.xz` (verses, map, outlines, line cuts, measured grid) and the riwaya's KFGQPC font, into `out/pages-<riwaya>-v1.zip` |
| `fetch_riwaya_timing.py` | Downloads mp3quran's verse timings of the riwaya recitations into `.cache/mp3quran_riwaya_timing.json` |
| `riwaya_reciters.py` | The riwaya recitations, their timings and sources in `content.db` (called by `build_content_db.py`; also adds them to a built file) |
| `export_pack.py` | Builds a data pack from a review database with reviewed entries only, after re-checking each one's hash and approval; writes the pack's index |

Tests: `python3 -m unittest discover -s tools/tests`. The review workflow is in `docs/review/README.md`.

Rules:
- Raw files stay in `.cache/` (git-ignored) and are rebuilt from `sources.json`.
- A new or changed source gets its own `data(...)` commit that names the source, edition and license, and updates `docs/DATA_SOURCES.md`.
- License evidence for each source lives in `docs/licenses/`.
