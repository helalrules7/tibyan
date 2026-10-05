# tools

Scripts that download, verify and prepare data. They handle structure only (download, checksum, split, map to verses, compare). **They never write or change religious text.**

| Script | What it does |
|---|---|
| `fetch_sources.py` | Downloads every source in `sources.json` into `.cache/` and rejects any file whose SHA-256 differs |
| `fetch_quranlab_timing.py` | Downloads QuranLab's word timings for al-Banna (murattal) into `.cache/quranlab_banna_timing.json` |
| `build_quranlab_timing.py` | Finds each al-Banna verse in the mp3quran surah files by its sound, derives verse boundaries and places QuranLab's word timings; surahs that fail a check get no timing |
| `timing_files.py` | The recitation timings kept as text in `data/timing/` (docs/TIMING.md): `export` from content.db, `check` (the same rules as the timing editor), `known-errors` and `fix-known` (the source errors that need no listening), `pack` for the server, `site` (the editor with the app's words, for GitHub Pages); `apply()` puts them into content.db during the build |
| `build_timing_peaks.py` | Waveform peaks (one byte per 10 ms) of a reciter's surah files for the timing editor, and `data/timing/<slug>/audio.json` (durations); runs on the server |
| `build_banna_timing.py` | al-Banna verse by verse: keeps every verse found by its sound (QuranLab's words carried over), times the rest by forced alignment on the surah file (wav2vec2 Arabic CTC, torchaudio); `--compare N` checks the aligner against QuranLab, `--apply` writes reciter 4's rows into `content.db`. Needs torch/torchaudio/transformers (see its docstring) |
| `build_aligned_timing.py` | Verse and word timings for al-Dosari, al-Sudais, al-Afasy, al-Ghamdi and al-Tablaway measured on the surah files played: `emit` (wav2vec2 Arabic CTC output per surah), `align` (forced alignment with the word-box words, boundaries at the quietest point of each pause), `apply` (rows into content.db) |
| `measure_timing.py` | The timing-measure workflow's tool (docs/TIMING.md): measures whole surahs (Hafs verses and words; riwaya verses by the riwaya's own count, from the app's riwaya pack) or the words of single verses in their windows, with `build_aligned_timing.py`, on the files the app plays; `plan`, `run`, `finish` (files to review, credit in `reciters.json`, peaks, report) |
| `verify_word_timing.py` | Checks word timings against pauses heard in the audio, and verse boundaries against quiet points; `--db` checks the rows content.db ships, `--relative` also counts pauses that reverberation keeps above -35 dB |
| `build_shamarly.py` | Shamarly mushaf page geometry from its page images (lines, cuts, verse markers, verse and word boxes, headers) into `.cache/shamarly_geometry.db`; `shamarly_image.py` holds its image helpers |
| `verify_shamarly.py` | Checks that geometry against the images, `shamerly.db` and the first-word index; `--preview PAGES` draws overlays |
| `fetch_gharib.py` | Downloads «الميسر في غريب القرآن» from Nuqayah's reader (read.tafsir.one), page by page, into `.cache/nuqayah_almuyassar_gharib.json` |
| `build_word_study.py` | Roots and lemmas (Quranic Arabic Corpus 0.4) and the book's entries, mapped to our word numbers for `content.db` (`word_root`, `gharib`); prints the coverage |
| `build_mutashabih.py` | The mutashabihat links (Waqar144/Quran_Mutashabihat_Data) as verse-id ranges for `content.db` (`mutashabih`); links only, no text. Run alone it updates the bundled `content.db` in place |
| `build_themes.py` | Copies the eight heritage themes' frame, header and marker SVGs unchanged from a quran-assets checkout into `assets/themes/`, and writes each theme's JSON (interface colours checked against the contrast rules, art class colours per mode) |
| `verify_text/compare_tanzil_kfgqpc.py` | Lists verses whose base letters differ between Tanzil and the KFGQPC text. Every listed verse goes to a human reviewer |
| `import_wahidi_asbab.py` | Splits al-Wahidi's «أسباب نزول القرآن» (OpenITI) by the book's own sections and passage headers into a review database of drafts, with suggested verse links and their confidence. Proves the split kept every word |
| `import_altafsir.py` | Same for the altafsir.com copies of al-Tabari, al-Qurtubi, Ibn Kathir, al-Baghawi, al-Saadi and al-Biqa'i (OpenITI): one draft per verse group of altafsir's headings, linked to those verses and confirmed by the passage's own quotations. `all` or one book; the six files stay out of the repository until review starts |
| `import_damghani_wujuh.py` | Same for al-Damghani's «إصلاح الوجوه والنظائر» (OpenITI): chapters, word headers and one draft per sense, linked to the verses it quotes after a surah's name |
| `import_tajweed_review.py` | The tajweed rules the app colours with (`tajweed_letter`) as review drafts: Juz' 'Amma and a seeded sample, one entry per verse, coloured in apps/review (ن15) |
| `import_dar_alathar.py` | Dar al-Athar's SQLite file of al-Wadi'i's «الصحيح المسند من أسباب النزول» as review drafts: text byte for byte, the publisher's verse links (basis `marker`, confidence 1), pages, edition and citation wording. Refuses the whole file on anything unexpected (missing or unknown columns, verses outside the mushaf, unlinked rows, ﷺ-style symbols, markup); `--map` renames columns (docs/features/asbab_nuzul.md) |
| `review_db.py`, `review_schema.sql` | The review database: schema (append-only audit log, frozen text, reviewer ≠ editor) and the content hash shared with the review tool |
| `build_tajweed.py` | Places the cpfair/quran-tajweed spans (CC BY 4.0) on the three editions' pages for `content.db` (`tajweed_page`): Tanzil 2017 offsets moved letter by letter onto the KFGQPC words, then onto the page contours (1441) or the ink inside the word boxes (1405, Shamarly). Never writes text; `--into DB` adds the table to a built database |
| `measure_letter_widths.py` | Measures where each letter of each KFGQPC word ends in the KFGQPC font (headless Chrome, measuring only) into `word_letter_widths.json`, for `build_tajweed.py` |
| `verify_tajweed.py` | Draws new-edition pages with their tajweed colouring (`tools/out/tajweed_NNN.png`) for a person to check |
| `riwayat.py` | Readers for the riwaya sources (quran-ws pages and outlines, KFGQPC riwaya texts and fonts, Quranpedia), and the riwaya → Hafs verse map worked out by aligning the base letters of the KFGQPC riwaya and Hafs texts (letters compared, never changed) |
| `verify_riwayat.py` | Cross-checks the riwaya sources (verse counts per surah, start pages, the map's coverage and order, the map against Quranpedia's `number_in_hafs`); `--report` writes `docs/verification/` |
| `build_riwaya_packs.py` | Builds the Warsh, Qalun, al-Duri and Shu'bah page packs: the quran-ws SVG pages unchanged (xz each), `riwaya.json.xz` (verses, map, outlines, line cuts, measured grid), `words.json.xz` (word boxes) and the riwaya's KFGQPC font, into `out/pages-<riwaya>-v2.zip` |
| `build_riwaya_word_boxes.py` | Word boxes of the riwaya pages, derived like `build_word_boxes.py`'s: each riwaya's quran-ws page geometry split by the piece counts of its own KFGQPC text and the word widths of its own KFGQPC font (HarfBuzz; needs `pip install uharfbuzz`). Prints statistics; `--out DIR` writes `words-<riwaya>.json` |
| `verify_riwaya_word_boxes.py` | Checks the riwaya word boxes (coverage, inside the verse outline, reading order, overlaps, widths against the font); `--render DIR` draws the flagged pages |
| `fetch_riwaya_timing.py` | Downloads mp3quran's verse timings of the riwaya recitations into `.cache/mp3quran_riwaya_timing.json` |
| `riwaya_reciters.py` | The riwaya recitations, their timings and sources in `content.db` (called by `build_content_db.py`; also adds them to a built file) |
| `export_pack.py` | Builds a data pack from a review database with reviewed entries only, after re-checking each one's hash and approval; writes the pack's index. The app installs it as a reviewed book pack (docs/features/asbab_nuzul.md) |
| `qiraat_audio.py` | The AQQD qiraat clips indexed by verse and style in `data/qiraat_audio/` (MISSING_DATA ن2, docs/QIRAAT_AUDIO.md): `listing` (OSF file list), `build` (index files, keeping word ranges and durations), `durations` (from each WAV header by HTTP range, no audio kept), `check` (CI: schema, verse and word exist, ranges inside the clip, no overlaps, a second-person reviewer), `format` |
| `staging.py` | Helpers for staged sources (downloaded and verified, never shipped while a permission is pending): `tools/.cache/staging/<source>/` with `SHA256SUMS` and `manifest.json` |
| `fetch_quranenc_extra.py` | Stages QuranEnc `english_mokhtasar` (each surah's API response byte for byte) and the `english_rwwad` per-verse audio URL index with HEAD checks of a sample; the audio is not downloaded. `pack` turns the staged text into the optional English tafsir pack (SQLite, text byte for byte, `.index.json` with `pack_sha256`) |
| `build_nuqayah_audio_index.py` | `probe` finds where read.tafsir.one keeps its tafsir audio; `build` indexes al-Muyassar and al-Saadi verse by verse (or surah by surah, `SURAH_PATTERNS`) and HEAD-checks a sample; the audio is not downloaded |
| `audio_index.py` | The verse audio index the app reads (format 1: per-verse files, or per-surah files with optional verse offsets), written and checked for the two tools above; docs/features/audio_content.md |
| `fetch_quranpedia_dumps.py` | Downloads Quranpedia dump files (e.g. `qiraat.json.gz`, `topics.json.gz`) into `.cache/quranpedia/` and compares them with the hashes recorded on 2026-09-28 |
| `measure_aqqd_coverage.py` | `listing` reads the AQQD file list from OSF (no audio); `measure` counts, per qira'a style, the Quranpedia qiraat verses and words that have AQQD clips (verse level: an upper bound for words) |
| `inspect_quranpedia_topics.py` | Depth, counts, verse and surah coverage, source fields and the first levels' titles of Quranpedia's `topics.json` |

Tests: `python3 -m unittest discover -s tools/tests`. The review workflow is in `docs/review/README.md`.

Rules:
- Raw files stay in `.cache/` (git-ignored) and are rebuilt from `sources.json`.
- A new or changed source gets its own `data(...)` commit that names the source, edition and license, and updates `docs/DATA_SOURCES.md`.
- License evidence for each source lives in `docs/licenses/`.
