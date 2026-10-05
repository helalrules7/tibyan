# تبيان | Tibyan

تطبيق مجاني غير ربحي للقرآن الكريم على أندرويد وآي أو إس وماك وويندوز ولينكس: مصحف وتفسير وتلاوة وحفظ.

A free, non-profit Quran app for Android, iOS, macOS, Windows and Linux: mushaf, tafsir, recitation and memorization.

> **الحالة / Status:** قيد البناء، والإصدار الحالي 0.4.0. ما بُني مسجل في [`CHANGELOG.md`](CHANGELOG.md)، وما ينقصه من بيانات أو مراجعة في [`docs/MISSING_DATA.md`](docs/MISSING_DATA.md). Under construction, at 0.4.0: what is built is in the changelog, what still needs data or review in `docs/MISSING_DATA.md`.

### ما فيه الآن · What it has

- **المصحف:** ثلاث طبعات حفص (المدينة الحديثة والقديمة 1405 والشمرلي) وأربع روايات (ورش وقالون والدوري وشعبة)، وعشرة أشكال، والتجويد الملوّن، ووضع التسميع، والتمرير التلقائي، والعرض المتتالي مع الترجمة أو الميسر تحت الآية.
- **خدمات الآية:** التفسير والترجمة، ومعاني الكلمات ودراستها، والمتشابهات، والعلامات الأربع والفواصل، والنسخ والمشاركة نصا وصورة.
- **التلاوة:** قراء كثيرون، وتظليل الآية والكلمة، والتكرار والسرعة ومؤقت النوم، والتنزيل للاستماع بلا إنترنت.
- **الختمة والحفظ:** مخطط الختمة وتذكيرها وتقاريرها ودفتر التدبر، واختبار الحفظ والمراجعة المتباعدة وخريطة الحفظ.
- **البحث:** بالكلمات وبالمعنى.
- **أدوات الشاشة:** ورد الختمة وأداة الاختصارات (أندرويد وiOS وماك)، وزر «استماع» في إعدادات أندرويد السريعة، وأدوات شاشة القفل في iOS.
- **بياناتك:** نسخة احتياطية في ملف واحد واستعادتها، وشاشة التخزين والتنزيلات.

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

## ساهم في صوت القراءات · Help with qiraat audio

إن كنت تعرف القراءات، استمع إلى مقطع آية بقراءة ما وحدد موضع الكلمة المختلف فيها بالمللي ثانية، ثم أرسله في طلب دمج يراجعه شخص ثانٍ: [الدليل](docs/QIRAAT_AUDIO.md).

If you know the qiraat, mark where the differing word sits in a verse clip and send it in a pull request; a second person reviews it: [the guide (Arabic)](docs/QIRAAT_AUDIO.md).

---

## Folder layout

| Path | Contents |
|---|---|
| `lib/core/` | Theme token system, settings, feature flags, routing, crash reporting |
| `lib/features/` | App screens, one folder per feature |
| `lib/l10n/` | Arabic (template) and English interface strings |
| `assets/themes/` | One JSON file per visual style (Zakhrafa, the default; Simple; and eight heritage styles), each with Light, Bright white, Night and Black |
| `assets/fonts/` | KFGQPC fonts (unmodified) and SIL OFL fonts, in Git LFS |
| `assets/config/` | Feature flags |
| `tools/` | Python scripts that download, verify and build the data reproducibly; `tools/apple/` generates the widget targets, `tools/release/` cuts a release |
| `android/`, `ios/`, `macos/`, `windows/`, `linux/` | Platform projects |
| `apple/` | WidgetKit extensions shared by iOS and macOS (docs/HOME_WIDGET.md) |
| `apps/` | The scholarly review tool and the recitation timing editor (web) |
| `data/` | Recitation timings as text (CC BY 4.0) and the review file |
| `docs/` | Data sources, missing data, permission requests, license evidence, verification reports, plan |
| `test/` | Unit and widget tests, including the theme contrast check |

## Setup

Requirements: Flutter 3.47.5 (stable), Xcode (iOS, macOS), Android SDK, Visual Studio (Windows), GTK 3, libmpv and libcurl (Linux), Git LFS, Python 3; Ruby with `xcodeproj` only to regenerate the widget targets.

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

## Releases

`python3 tools/release/prepare.py x.y.z`, commit, then push the tag `vx.y.z`: see [`docs/RELEASE.md`](docs/RELEASE.md).

## Data

Raw datasets and audio are never committed. The scripts in `tools/` rebuild them from their sources and check each file's SHA-256. What is still missing is tracked in [`docs/MISSING_DATA.md`](docs/MISSING_DATA.md).

## License

Code: [GPL-3.0](LICENSE). Data keeps the license of its source (see [`docs/DATA_SOURCES.md`](docs/DATA_SOURCES.md)). Data derived from OpenITI is published under CC BY-NC-SA 4.0, separately from the code. KFGQPC fonts are distributed unmodified under the Complex's terms.
