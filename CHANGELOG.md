# Changelog

All notable changes to Tibyan are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

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

[Unreleased]: https://github.com/helalrules7/tibyan/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/helalrules7/tibyan/releases/tag/v0.1.1
[0.1.0]: https://github.com/helalrules7/tibyan/releases/tag/v0.1.0
