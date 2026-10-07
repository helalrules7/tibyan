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

---

## المرحلة 2: البيانات (user.db v5، IntervalSet، الترحيل، rebuildAll، النسخ الاحتياطي)

**ما تم:**
- `domain/interval_set.dart`: مجموعة نطاقات آيات مرتبة ومدموجة دائما (اتحاد، تقاطع، طرح، `firstGap`، `containsRange`، `weigh`، صيغة JSON `[[from,to],…]`). 15 اختبارا منها مقارنة عشوائية بمجموعات أرقام عادية (400 حالة).
- `domain/khatmah.dart` (نقي): الأنواع (`KhatmahKind`، `PacingMode`، `ScheduleMode`، `WirdUnit`، `CountingMode`، `KhatmahStatus`، `AheadChoice`، `SessionSource`، `EntryPoint`، `DecidedBy`)، و`Khatmah` (الخطة)، و`Credit` (الاحتساب)، و`PausePeriod`، و`KhatmahOrder` (الترتيب الدائري و`frontier`)، و`Ledger` (التغطية ووزن كل يوم من الاحتسابات، بإعادة التشغيل بترتيب بداية الجلسات).
- user.db v5 (`habit_tables.dart` و`user_database.dart`):
  - `khatma`: الأعمدة الجديدة كلها كما في القسم 3.1، ولم يُحذف عمود.
  - `reading_session`: `source` و`entry_point` و`active_seconds` و`ranges`؛ و`mode` صار نوع العرض.
  - جداول جديدة: `khatma_pause` و`session_attribution` (مع أعمدة المزامنة، وفي `syncedTables` و`applyRemote`)، والـcache: `khatma_coverage` و`daily_stat`.
  - الترحيل في `onUpgrade` يضيف الأعمدة (ويتحقق من وجودها أولا)، ويملأ `status` من `completedAt`/`deletedAt`، و`pacing_mode` من `daily_portion`، ويجعل الختمة المفتوحة الأحدث `is_primary`.
- `data/khatmah_store.dart`: قراءة وكتابة الختمات والإيقافات والجلسات والاحتسابات (كل كتابة إلى الـoutbox)، و`rebuild`/`rebuildAll`، و`migrateLegacy`.
- **ترحيل السجل القديم (`migrateLegacy`)** يحتاج QuranIndex، فلا يجري داخل `onUpgrade` (قاعدة المستخدم لا ترى content.db هناك). يعمل عند التشغيل لكل ختمة بلا `range_start`، في transaction لكل ختمة، ومرة واحدة:
  - الآية تُحتسب في يوم قراءة الصفحة التي **تنتهي** عليها، في طبعة الختمة (الشمرلي بالبداية والنهاية).
  - جلسة `manual`/`other` لكل يوم، ومعها احتساب `auto`. `khatma_log` يبقى كما هو.
  - `daily_weight` من `daily_portion` (صفحة/جزء/حزب ← وزن) أو من الأيام المتبقية.
  - ختمة رواية حزمتها غير موجودة تنتظر التشغيل التالي.
- النسخ الاحتياطي: `khatma_pause` و`session_attribution` في النسخة؛ الـcache لا يدخلها ويُعاد بناؤه.
- التقارير (`watchReadingSince`) تعدّ جلسات `reader` فقط، حتى لا تتكرر صفحات الجلسات المرحّلة واليدوية والصوتية.
- اختبارات: `migration_v5_test.dart` على قاعدة v4 حقيقية مبنية من مخطط v4 نفسه (`test/fixtures/user_db_v4.sql`، مأخوذ من الكود قبل التعديل): السيناريو 17 (نفس الصفحات ونفس النسبة ونفس أول صفحة غير مقروءة)، وختمة شمرلي تحفظ صفحاتها، وعدم التكرار، والانتظار، والسيناريو 13 (حذف الـcache ثم `rebuildAll`). و`khatmah_backup_test.dart`.

**تغيّر عن الخطة:**
- قاعدة «الصفحة المقروءة»: الصفحة مقروءة إذا غُطيت كل آية **تنتهي** عليها (وإن لم تنته عليها آية: كل آية فيها). بهذه القاعدة تبقى صفحات الشمرلي المقروءة نفسها بعد الترحيل، وتُحسب الصفحة بنفس المعنى في أي طبعة.
- أعمدة زائدة على القسم 3.1: `recovery` (اختيار التعويض، JSON)، و`session_attribution.day` و`at` (اليوم المنطقي للجلسة وبدايتها، حتى لا تتغير الإحصائيات القديمة إن تغير `dayStartHour`)، وقيمة `declined` في `decidedBy` (رفض «ask» حتى لا يُسأل مرة أخرى).
- `test/hifz/user_database_hifz_test.dart` كان يتوقع رقم المخطط 4؛ صار 5 (تغيير مقصود في الخطة).

**مفتوح:**
- الربط بالتطبيق (تشغيل `migrateLegacy` و`rebuildAll` عند البدء، وتحويل `KhatmaService` للمحرك) في المرحلة 4، مع المحرك نفسه. حتى ذلك الـcommit يكتب التطبيق في `khatma_log` كما كان.

---

## المرحلة 3: Reading Tracker

**ما تم:**
- `domain/reading_tracker.dart` (نقي) طُوِّر:
  - **الوزن:** الصفحة تُحتسب بعد `minDwell × وزنها` (والصفحتان المتقابلتان بمجموع الوزنين)، والحد الأدنى 5 ثوانٍ للصفحة.
  - **الخمول:** عداد الوقت النشط يتوقف بعد 3 دقائق بلا لمس (`touch`) ولا تقليب؛ الصفحة نفسها تُحتسب مرة واحدة.
  - **`freeze`** (شاشة فوق القارئ) و**`suspend`** (اختبار الحفظ ووضع التسميع، القرار 4): لا صفحة ولا وقت؛ وعند العودة يبدأ انتظار الصفحة من جديد. ما بقي على الشاشة وقتا كافيا قبل الدفع يُحتسب.
  - «آية آية» (`showVerse`): الآية بعد `minDwell × وزنها`، بحد أدنى ثانيتين.
  - العرض المتصل (`showVerses`): كل آية في منطقة القراءة (نصف الشاشة الأوسط) تجمع وقتها وتُحتسب حين يكفي.
  - مصدر الفتح: `onlyAfterPage`/`onlyAfterVerse` للبحث والتفسير والحفظ.
  - الجلسة لها `uuid` و`activeSeconds` و`mode` والآيات المقروءة.
  - `ListeningCounter`: جلسة استماع ما دامت التلاوة تعمل، وكل آية مرة.
- **الصوت (`recitation.dart`):** `_verseHeard` عند نقطة `done + 1` (قبل كارت السجدة والترجمة)، وعند نهاية الملف، وعند نهاية آخر تكرار لمقطع. `step` و`jumpTo` يضعان `_moving` حول القفز فلا تُحتسب الآية المتروكة، وكل آية تُبلَّغ مرة واحدة. الاحتساب في `KhatmaService.verseRecited` مربوط بإعداد «احتساب الاستماع»، ويعمل بلا أي شاشة (في الخلفية).
- **`CoverObserver`** (`lib/core/router/cover_observer.dart`) في الـGoRouter: شاشة كاملة فوق القارئ تجمّد التتبع، والـdialogs والـsheets لا تجمّده. مستعمل في المصحف و«آية آية» والعرض المتصل.
- **مصدر الفتح:** `entry=` في `/mushaf` و`/verse` و`/read`، و`mushafLocation`/`openVerse` يقبلانه. موسوم الآن: البحث ودراسة الكلمة (`search`)، واختبار الحفظ (`memorization`)، والفواصل (`bookmark`) وآخر قراءة (`lastRead`).
- **حفظ الموضع** من «آية آية» (`view: verse`) والعرض المتصل (`view: continuous`).
- الإعدادات (نموذج فقط، بلا واجهة): `dayStartHour` (3)، و`readingSpeed` (بطيئة 20/متوسطة 15/سريعة 10 ثوانٍ للصفحة)، و`countListening` (مفعّل)، و`showWirdIndicator` (مفعّل)، بمفاتيح `settings.khatma.*` فتدخل النسخة الاحتياطية.
- الجلسات تُكتب في `reading_session` (المصدر ونوع العرض ومصدر الفتح والوقت النشط والآيات) وتنمو مع كل قراءة.
- اختبارات: `reading_tracker_test.dart` (السيناريوهات 8 و19 و20، والخمول، والتعليق، ومصدر الفتح، والعرض المتصل)، و`listening_count_test.dart` (السيناريو 9 على `RecitationController` الحقيقي بمشغل وهمي: الآية المتخطاة والمقفوز عنها لا تُحتسب، ونهاية السورة تُحتسب).

**تغيّر عن الخطة:**
- الرابط `entry=` لا `from=`: `from` مستعمل في `/mushaf` لبداية وحدة اختبار الحفظ.
- «آية آية» والعرض المتصل: الحد الأدنى للآية ثانيتان (الخطة تذكر 5 ثوانٍ للصفحة فقط).
- ما زالت الصفحات تُكتب أيضا في `khatma_log` القديم حتى ينتقل `KhatmaService` للمحرك (المرحلتان 4–5).

**مفتوح:**
- السيناريو 21 (الاستماع والشاشة مقفولة) مغطى بأن الاحتساب يعمل من `RecitationController` بلا شاشة؛ التأكد على جهاز في المرحلة 11.
- الرئيسية وبقية المداخل (`home`، `widget`، `notification`، `khatmahContinue`) تُوسم مع الروابط العميقة في المرحلة 6.
