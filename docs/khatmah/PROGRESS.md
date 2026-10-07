# الختمة v1.1: سجل التنفيذ

الخطة: `docs/superpowers/specs/2026-10-07-khatmah-v1-design.md`. المراحل 1–5 (المنطق النقي) بوكيل واحد على فرع `khatmah_v1/engine`، بقرار أحمد 5.

---

## المرحلة 1: QuranIndex والأوزان وإصلاح الروايات

**ما تم:**
- `lib/features/khatma/domain/quran_index.dart` (Dart نقي):
  - `QuranIndex`: `idOf`/`keyOf`، والجزء والحزب والربع، و`weight`/`weightOf`/`ayahAtWeightOffset`، وقوائم الحدود (السور 114، الأجزاء 30، الأحزاب 60، الأرباع 240).
  - الوزن = حروف `text_search` بلا مسافات ولا بسملة ÷ حروف صفحته في 1441 (القرار 3). المجموع 604 بسماحية 1e-9، وكل صفحة 1.
  - `EditionPageMap`: صفحة البداية والنهاية لكل آية في طبعة (الشمرلي بالمدى)، و`ayahsOn(page)`، و`pagesOf(from,to)`، و`pageEnds` (حدود الصفحات للتقريب)، و`weightOfPage`.
- `data/quran_index_loader.dart`: يقرأ الصفوف من content.db عند أول طلب (بلا asset ولا جدول)، و`riwayaPages()` تبني صفحات رواية بأرقام حفص من الحزمة (بداية الآية ومخططاتها على الصفحات؛ آية حفص التي لا تعدها الرواية، كبسملة الفاتحة، تتبع الآية بعدها).
- **إصلاح الروايات:** `MushafRepository.ayahsOnPage(page, edition, riwaya)` يرجع آيات حفص لصفحة الرواية من الحزمة، و`KhatmaService.pagesIn` يحوّل بين أي طبعتين عبر `editionPagesProvider`.
- providers: `quranIndexProvider`، `editionRiwayaDataProvider` (حزمة أي رواية مثبتة، لا الحالية فقط)، `editionPagesProvider`.
- `docs/MISSING_DATA.md` (ث5-هـ): أرباع الروايات تحتاج مصدرا، والورد يُقرَّب للصفحة ثم الآية (القرار 2).
- اختبارات `test/khatma/quran_index_test.dart` على content.db الحقيقية (12 اختبارا).

**تغيّر عن الخطة:**
- اسم الصنف `EditionPageMap` لا `EditionPages` (الاسم محجوز لامتداد موجود في `mushaf_repository.dart`).
- وزن الكهف (293..304) بين 11 و12 صفحة: تبدأ بعد رأس الصفحة 293 وتنتهي قبل آخر 304.

**مفتوح:**
- وحدة الحفظ بالصفحات في الروايات (`HifzRepository.unit`) ما زالت بلا صفحات؛ لم ألمسها (خارج الختمة). الإصلاح نفسه متاح لها عبر `riwayaPages`.
