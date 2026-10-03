# تبيان | Tibyan

تطبيق مجاني غير ربحي للقرآن الكريم على أندرويد وآي أو إس: تفسير وتلاوة وحفظ.

A free, non-profit Quran app for Android and iOS: tafsir, recitation and memorization.

> **الحالة / Status:** قيد البناء. المرحلة 1 (المصحف) اكتملت في الإصدار 0.2.0. Under construction; Phase 1 (the mushaf) shipped in 0.2.0.

---

## المبادئ

1. **لا يكتب الذكاء الاصطناعي أي محتوى ديني.** كل نص للقرآن أو التفسير أو القراءات أو غيرها يأتي من مصدر موثق، ومصدره محفوظ بجانبه.
2. **لا يظهر محتوى علمي إلا بعد مراجعة متخصص**، واسم المراجع يظهر عليه.
3. **لا نأخذ بيانات بلا إذن.** كل مصدر مسجل في [`docs/DATA_SOURCES.md`](docs/DATA_SOURCES.md)، ونص إذنه محفوظ في [`docs/licenses/`](docs/licenses/).
4. **مجاني بالكامل**: بلا إعلانات، ولا مشتريات، ولا اشتراكات.

## Principles

1. **No AI-written religious content.** Every Quran, tafsir, qiraat or scholarly text comes from a verified source, stored with its source.
2. **Scholarly content appears only after review by a qualified person**, whose name is shown with it.
3. **No data without permission.** Every source is listed in [`docs/DATA_SOURCES.md`](docs/DATA_SOURCES.md), with its license text saved in [`docs/licenses/`](docs/licenses/).
4. **Completely free**: no ads, no purchases, no subscriptions.

---

## ساهم في تصحيح توقيت التلاوات · Help fix recitation timings

إن رأيت التلوين يسبق صوت الكلمة أو يتأخر عنه، صححه بأذنك من المتصفح: [المحرر](https://helalrules7.github.io/tibyan/)، و[الدليل خطوة خطوة](docs/TIMING_GUIDE.md). لا تحتاج خبرة برمجية.

If a word lights up early or late, fix it by ear in your browser: [the editor](https://helalrules7.github.io/tibyan/) and [the step-by-step guide](docs/TIMING_GUIDE.md). No programming needed.

---

## Folder layout

| Path | Contents |
|---|---|
| `lib/core/` | Theme token system, settings, feature flags, routing, crash reporting |
| `lib/features/` | App screens, one folder per feature |
| `lib/l10n/` | Arabic (template) and English interface strings |
| `assets/themes/` | One JSON file per visual style (Classic, Manuscript, Royal, Calm), each with Light, Night and Black |
| `assets/fonts/` | KFGQPC fonts (unmodified) and SIL OFL fonts, in Git LFS |
| `assets/config/` | Feature flags |
| `tools/` | Python scripts that download, verify and build the data reproducibly |
| `docs/` | Data sources, missing data, permission requests, license evidence, verification reports, plan |
| `test/` | Unit and widget tests, including the theme contrast check |

## Setup

Requirements: Flutter (stable), Xcode (for iOS), Android SDK, Git LFS, Python 3.

```sh
git lfs install
git clone https://github.com/helalrules7/tibyan.git
cd tibyan
cp .env.example .env   # optional: crash reporting and sync keys
flutter pub get
flutter run --dart-define-from-file=.env
flutter test
python3 tools/fetch_sources.py   # optional: download and verify raw data
```

## Data

Raw datasets and audio are never committed. The scripts in `tools/` rebuild them from their sources and check each file's SHA-256. What is still missing is tracked in [`docs/MISSING_DATA.md`](docs/MISSING_DATA.md).

## License

Code: [GPL-3.0](LICENSE). Data keeps the license of its source (see [`docs/DATA_SOURCES.md`](docs/DATA_SOURCES.md)). Data derived from OpenITI is published under CC BY-NC-SA 4.0, separately from the code. KFGQPC fonts are distributed unmodified under the Complex's terms.
