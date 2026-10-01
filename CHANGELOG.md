# Changelog

All notable changes to Tibyan are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added (themes)
- Eight heritage themes beside Zakhrafa (still the default): Seljuk, Umayyad, Timurid, Hijazi, Fatimid, Andalusi, Mamluk and Abbasid. Each draws its frame, surah header and verse marker from quran-assets as they are, recoloured per mode (light, bright white, night, black), in all three editions and on the opening pages. The juz, hizb and surah sit above the frame, the page number inside the theme's marker below it.
- A theme picker in «شكل المصحف» and on the first-launch style screen, and a verse-marker shape «حسب الثيم» (the default in the new themes).
- Sources and licences of the theme art in DATA_SOURCES.md and the «عن المصحف» screen; the traced mushaf ornaments are provisional (CC BY-NC-SA 4.0, permission not yet obtained, MISSING_DATA.md إ14).

### Added (word study)
- «دراسة الكلمة» (word study) in the verse services: tap it, then tap a word on the page, in all three editions. A sheet shows the word, its meaning quoted from «الميسر في غريب القرآن» (Nuqayah, by permission), its root and lemma from the Quranic Arabic Corpus 0.4, and every verse where the root occurs (count shown; a tap opens that verse's page with it selected). The verse's words are listed in the sheet, so any of them can be studied, including where the page has no word boxes.
- «معاني الكلمات» (word meanings) in the verse services: every entry of the book for the selected verses.
- A word the book does not explain shows no meaning; nothing is filled in. Roots cover 6,229 of 6,236 verses (the other 7 split words differently from the corpus); 11,233 of the book's 11,362 entries are tied to their words, the rest are shown with their verse.

### Added (reading and downloads)
- The new Madina edition ships with the app and opens on first launch; while another chosen edition downloads, it is read meanwhile, with a progress banner.
- Editions download in the background (the system's downloader), with progress and completion notifications, and a "download all editions" button in settings and on the edition screen.
- Listening: an option to shorten the long silences reciters leave between verses (as recorded, 1 second, or half a second), from each verse's measured speech span.

### Changed
- Arabic is the default language whatever the device's language.
- Recitation mode covers only the words, so verse markers with their numbers and the hizb sign stay visible.
- The continuous view is no longer offered on the first-launch and download screens.

### Added (listening)
- Seven recitations from mp3quran.net: al-Minshawi, al-Husary, Abdul Basit, al-Banna and Mustafa Ismail (murattal), and al-Banna and Mustafa Ismail (mujawwad).
- The recited verse is highlighted and pages turn with it, using mp3quran's published verse timings (five recitations; two surahs with a verse missing in the source play without highlighting).
- The recited word is highlighted too, in both editions, for al-Minshawi, al-Husary and Abdul Basit: quran-align's word timings (CC BY 4.0) placed on the mp3quran files using the speech and pauses heard in each verse (99.8% of verses; under 0.2% of words fall in a pause).
- Verse and word highlighting for al-Banna (murattal) in 100 of 114 surahs: QuranLab's word timings (CC BY 4.0) placed on the mp3quran files, with verse boundaries found by matching each verse's sound (0.16% of words fall in a pause); the other 14 surahs play without highlighting.
- Touch reading: tap the verse you are reading and it is shaded in red, replacing the last one. Its button and the hide-verses button sit just under the page number.
- Repeat a verse or a selected stretch 1 to 10 times or until stopped, with silence between repeats; sleep timer; background playback with lock-screen controls; per-surah downloads that resume.

### Changed
- The verse highlight is a framed box per line instead of following every letter.
- Page packs and recitations are fetched from the Tibyan mirror first, with the original source as the fallback (the mirror was only a fallback before, and the sources were slow).

### Changed (recitations)
- Only murattal recitations are offered: the two mujawwad ones (al-Banna and Mustafa Ismail) are removed.
- New recitation: Yasser al-Dosari (murattal), from quranicaudio.com, with verse and word highlighting from quran.com's QDC timings (110 surahs, 95.7% of words).
- Four more from mp3quran.net, each with every verse of all 114 surahs timed: Abdul-Rahman al-Sudais, Mishary al-Afasy, Saad al-Ghamdi and Muhammad al-Tablaway. Their verse is highlighted and the page turns with it; their words are not, mp3quran publishing no word timings. al-Sudais is here rather than on quranicaudio.com: quran.com's timings for him name files that are not the bytes his own URL serves.
- Mustafa Ismail (murattal) now has verse timing for nearly all the Quran, derived from the recitation itself, so changing to him no longer restarts the surah.

### Fixed
- Android release builds now declare the INTERNET permission needed to download pages and recitations.
- Changing the reciter while listening no longer turns the page to the first page of the surah: the page no longer follows the verse reported while the new file is still loading.
- The page clips of the new Madina edition are built once per page instead of on every rebuild, and the divine names are drawn once per line instead of redrawing the whole page for every one of them; the Shamarly catchword is cut from a page decoded at the size it is drawn; the bundled database is no longer read and hashed on every launch. Pages either side of the one being read are now built ahead, so turning a page does not wait.

## [0.4.0] - 2026-09-29

### Added (tafsir and translation)
- Tafsir and translation screen, opened from verse services: al-Tafsir al-Muyassar (KFGQPC, via QuranEnc), Saheeh International 1.1.2 with its footnotes (via QuranEnc), and Pickthall (public domain, via Tanzil). Every text is shown verbatim with its source's credit and version.
- Swipe or use the arrows to move through the surah's verses; texts sit side by side on wide screens for comparison.
- Tafsir settings: Uthman Taha Naskh or the interface font, text size, and which texts are shown.
- Trial, off by default: justify Arabic tafsir with kashida (tatweel) instead of wider spaces. Display only; Quran words in brackets are never stretched, and a copy button gives the original text.

## [0.3.0] - 2026-09-29

### Added (Zakhrafa style)
- New default style «Zakhrafa»: an illuminated turquoise, coral and navy frame, built from vector ornaments provided by Ahmed.
- Page view: immersive reading with controls on touch; cartouches for juz, hizb and surah (each opens the index at the current place) and a centred page number (go to page); catchword under the frame; surah headers and hizb quarter marks in the frame's design; cover page; al-Fatiha and the opening of al-Baqarah in a fully ornate page; light and golden splash screens.
- Verse services on long press, multi-verse selection with handles, four one-tap marks (reading, review, memorizing, reflection); tapping a verse marker sets the reading mark.
- Recitation mode, auto-scroll with ten speeds, verse marker shape and colour settings, a hizb tab in the index.
- Page packs fall back to the Tibyan mirror when the source fails.

### Fixed
- Both editions fill the frame's height; lines are split where no mark is clipped.

### Changed
- Old edition (1405H) pages now fill the screen: the text takes the full width, and the 15 lines spread evenly over the full height, without stretching the calligraphy. Pages 1 and 2 are centred whole, so their ornament stays intact.

### Added
- First launch now starts with the interface language (Arabic, English or the device language), titled in both languages; then style and colours, then the edition.

## [0.2.0] - 2026-09-29

Phase 1: the mushaf.

### Added
- First launch: choose the style and colours with a live preview of a real mushaf page, then the Madina edition (new 1441H or old 1405H). Defaults: Calm, Light, new edition.
- Page view of the new Madina edition (1441H): the KFGQPC page artwork, unchanged, downloaded once (65 MB, resumable, checked by SHA-256 page by page) and then offline. Pages turn right to left in every language; tap a verse to highlight it.
- Page view of the old Madina edition (1405H): page images downloaded directly from quran.com (63 MB, checked by SHA-256), not re-hosted. Verses highlight through quran.com's glyph boxes.
- Continuous view: the KFGQPC Hafs text (version 2.0, digitally signed), verbatim, in the KFGQPC Hafs font, justified, with the basmala above each surah and adjustable size.
- Index: surahs, juz and pages; search by surah name, page number, or a reference such as 2:255.
- Fawasil: named bookmarks that move to where you last read with them, plus automatic last-position saving.
- About this mushaf: every source with its license and attribution, and the Tanzil notice.
- Settings: edition, keep the screen on while reading, Quran text size.
- Word boxes for all 77,430 words of the new edition, derived from the page geometry (`tools/build_word_boxes.py`); not used in the app yet, pending human review.
- Bundled content database (`assets/db/content.db`), built reproducibly by `tools/build_content_db.py`: KFGQPC text (shown), Tanzil Uthmani text (kept verbatim for comparison), Tanzil search text, surah, juz, hizb, sajda and page metadata for both editions, verse outlines, word boxes, and the reviewer's decisions.

### Text review
- Six places where Tanzil and the KFGQPC text differ (two juz boundaries, four spellings) went to a qualified reviewer. All six are decided and recorded in `docs/review/DECISIONS.md`; the KFGQPC text matches all six.
- Permission to include the KFGQPC Hafs text has been requested from KFGQPC (letter 13). If refused, the continuous view returns to the Tanzil text.

### How to test
1. Fresh install: pick a style and mode (the page preview follows), then an edition.
2. Download the pages (Wi-Fi recommended). Pause and resume once.
3. Page view: swipe through pages, tap a verse, save it to a new fasil, reopen the app: it opens where you stopped.
4. Index: search `2:255`, then open surah 114 and page 604.
5. Continuous view: open Al-Isra 7 and Ya-Sin 22; change the text size in Settings.
6. Settings: switch to the old edition, download its pages, open 5:77 (page 121 there, 120 in the new edition).
7. About this mushaf: every source is listed with its license.

## [0.1.1] - 2026-09-28

### Fixed
- Selected radio buttons and switches were invisible in several styles (for example, white on white in Calm light). Controls now use a dedicated colour that is at least 7:1 against the page in all 12 style/mode combinations, and a test guards it.

### Added
- Changa as a third interface font option.

### How to test
1. Settings: the selected language option is clearly marked in every style and mode.
2. Turn the crash-report switch on and off: both states are clear.
3. Settings > Appearance > Interface font: choose Changa.

## [0.1.0] - 2026-09-28

Phase 0: foundation. No Quran or religious text appears in this release.

### Added
- Flutter app (Android, iOS) with Arabic and English interfaces and full right-to-left layout.
- Theme token system: 4 styles (Classic, Manuscript, Royal, Calm) x 3 modes (Light, Night, Black), defined as JSON files. A test fails the build if any combination breaks a contrast rule.
- Settings: style, colour mode (automatic follows the device), interface font (IBM Plex Sans Arabic or KFGQPC AN), language, and crash-report opt-in.
- Feature flags; every scholarly feature starts switched off.
- Opt-in crash reporting that sends no personal data.
- CI on every push (format, analyze, test) and release builds on tags.
- `tools/fetch_sources.py`: downloads and verifies raw sources by SHA-256.
- Planning documents: data sources, missing data, permission requests, source links and saved license evidence in `docs/`.
- Text verification tool `tools/verify_text/compare_tanzil_kfgqpc.py`.

### How to test
1. Install the APK from this release, or run `flutter run`.
2. Settings > Appearance: try all 4 styles in Light, Night and Black; check that text is easy to read everywhere.
3. Switch the interface font between IBM Plex Sans Arabic and KFGQPC AN.
4. Switch the language to English and back to Arabic; the layout should flip direction.
5. Close and reopen the app: every choice should be kept.

[Unreleased]: https://github.com/helalrules7/tibyan/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/helalrules7/tibyan/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/helalrules7/tibyan/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/helalrules7/tibyan/releases/tag/v0.2.0
[0.1.1]: https://github.com/helalrules7/tibyan/releases/tag/v0.1.1
[0.1.0]: https://github.com/helalrules7/tibyan/releases/tag/v0.1.0
