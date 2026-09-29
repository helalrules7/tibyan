# Changelog

All notable changes to Tibyan are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

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

[Unreleased]: https://github.com/helalrules7/tibyan/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/helalrules7/tibyan/releases/tag/v0.2.0
[0.1.1]: https://github.com/helalrules7/tibyan/releases/tag/v0.1.1
[0.1.0]: https://github.com/helalrules7/tibyan/releases/tag/v0.1.0
