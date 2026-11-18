# دليل وتعليمات رفع المتجر عبر Cowork (COWORK_PROMPT)

هذا الملف مُخصص لعميل الأتمتة (Claude Cowork / Browser Agent) لتعبئة بيانات متجري **Google Play Console** و**Apple App Store Connect** ورفع الأصول والوسائط.

---

## ⚠️ قواعد التوقف الإلزامية (MANDATORY STOP GATES)

أيها الوكيل، هناك خطوط حمراء يجب عليك **التوقف فورًا عندها والرجوع للمالك أحمد**:

1. **تسجيل الدخول والتحقق بخطوتين (2FA):**
   - افتح صفحة تسجيل الدخول ثم **توقف** واطلب من أحمد تسجيل الدخول وتخطي التحقق.
2. **الاتفاقيات والضرائب والحسابات المالية (Agreements & Banking):**
   - لا تضغط «موافقة» على أي بنود قانونية أو اتفاقيات جديدة دون عرضها على أحمد.
3. **زر الإرسال للمراجعة أو النشر (NEVER CLICK SUBMIT / PUBLISH):**
   - ارفع جميع الملفات، واملأ كل النصوص والحقول، واحفظ المسودة (Save Draft).
   - **ممنوع تمامًا** الضغط على:
     - `Submit for Review` (في Apple App Store Connect).
     - `Send changes for review` أو `Publish` أو `Rollout release` (في Google Play Console).
   - توقف عند الخطوة الأخيرة، والتقط لقطة شاشة للنموذج المكتمل، واطلب من أحمد الضغط على الزر بنفسه.

---

## أولاً: إعداد Google Play Console

### 1. المسارات والملفات المطلوبة
جميع الملفات جاهزة ومجهزة محليًا في المسار:
`docs/brand/store/`

- **أيقونة التطبيق (512×512):**
  `docs/brand/store/graphics/play_icon_512x512.png`
- **صورة الغلاف (1024×500):**
  `docs/brand/store/graphics/play_feature_graphic_1024x500.png`
- **رابط الفيديو (YouTube URL):**
  *(الفيديو محليًا في `docs/brand/store/video/preview_30s_landscape.mp4` — إذا تم رفعه على قناة يوتيوب يتم وضع رابطه هنا، أو تركه فارغًا لحين رفعه).*
- **صور شاشة الهاتف (Phone Screenshots):**
  المجلد `docs/brand/store/screenshots/android_phone/` (8 صور بالترتيب من 01 إلى 08).
- **صور شاشة تابلت 7 بوصة (7-inch Tablet Screenshots):**
  المجلد `docs/brand/store/screenshots/android_tablet_7/` (8 صور).
- **صور شاشة تابلت 10 بوصة (10-inch Tablet Screenshots):**
  المجلد `docs/brand/store/screenshots/android_tablet_10/` (8 صور).
- **صور شاشة ساعة Wear OS:**
  المجلد `docs/brand/play/wear/` (`wear-tile.png` و `wear-misbaha.png`).

### 2. الحقول النصية (أدخلها في المتجر الرئيسي)
ارجع إلى ملف `docs/brand/store/LISTING.md` لنسخ النصوص:
- **Default Language:** `Arabic (العربية)`
- **App Name:** `تبيان - القرآن الكريم`
- **Short Description (80 حرف):**
  `مصحف بلا إعلانات: استماع وتفسير وتسميع وحفظ دون إنترنت`
- **Full Description:**
  انسخ النص الكامل من قسم «الوصف الكامل بالعربية» في `docs/brand/store/LISTING.md`.

### 3. إضافة اللغة الإنجليزية (Manage Translations -> Add English)
- **App Name:** `Tibyan: Quran`
- **Short Description (80 chars):**
  `Ad-free Quran app: recitation, tafsir, smart oral testing, and offline reading.`
- **Full Description:**
  انسخ النص الكامل من قسم «Full Description - English» في `docs/brand/store/LISTING.md`.

### 4. فئة التطبيق والجمهور المستهدف
- **App Category:** `Books & Reference` (الكتب والمراجع).
- **Tags:** `Quran`, `Education`, `Reference`, `Religion`.
- **Target Audience:** اختر **`13+`** (13 سنة فما فوق) — هذا قرار مؤكد من أحمد لتجنب تعقيدات سياسة العائلات.
- **Ads:** اختر **`No, my app does not contain ads`** (تطبيق لا يحتوي على إعلانات).
- **Privacy Policy:** ضع الرابط `https://altibyan.app/privacy`.

---

## ثانياً: إعداد Apple App Store Connect

### 1. المسارات والملفات المطلوبة
- **صور شاشة iPhone 6.9" (1290×2796):**
  المجلد `docs/brand/store/screenshots/iphone_6.9/` (8 صور).
- **صور شاشة iPad Pro 13" (2048×2732):**
  المجلد `docs/brand/store/screenshots/ipad_13/` (8 صور).
- **صور شاشة Mac (2880×1800):**
  المجلد `docs/brand/store/screenshots/mac/` (8 صور).
- **صور شاشة Apple Watch (Watch Ultra / Series 10):**
  المجلد `docs/brand/appstore/watch/` و `docs/brand/play/wear/`.
- **فيديو معاينة التطبيق (App Preview):** لا تَرفع أي فيديو لـ Apple. `preview_30s_portrait.mp4` فيه «مجاني · غير ربحي» وأسماء منصات أخرى ويخالف 2.3.10 و2.3.14.
- **صور شاشة Mac البديلة:** `docs/brand/store/templates/mac/2880x1800/` (01 إلى 10).

### 2. الحقول النصية (العربية الأساسية)
- **اسم التطبيق (Name):** `تبيان`
- **العنوان الفرعي (Subtitle - 30 حرف):** `مصحف شامل: تلاوة وحفظ`
- **الكلمات المفتاحية (Keywords - 100 حرف):**
  `قرآن,مصحف,تلاوة,تفسير,تسميع,حفظ,المدينة,الشمرلي,أذكار,مسبحة,ختمة`
- **الوصف (Description):**
  انسخ النص الكامل من قسم «الوصف الكامل لـ App Store بالعربية» في `docs/brand/store/LISTING.md` (لا تستخدم وصف Google Play).
- **الفئة الأساسية (Primary Category):** `Reference` (مراجع).
- **الفئة الثانوية (Secondary Category):** `Education` (تعليم).
- **رابط سياسة الخصوصية:** `https://altibyan.app/privacy`.
- **رابط الدعم الفني:** `https://altibyan.app/`.
- **رابط التسويق:** `https://altibyan.app/beta`.

### 3. الحقول النصية (الإنجليزية - English Localization)
- **Name:** `Tibyan`
- **Subtitle (30 chars):** `Quran: Recite, Study, Memorize`
- **Keywords (100 chars):**
  `quran,mushaf,quranic,tafsir,recitation,islam,tajweed,khatmah,tasbih,misbaha`
- **Description:**
  انسخ النص من قسم «الوصف الكامل لـ App Store بالإنجليزية» في `docs/brand/store/LISTING.md`.

---

## ثالثاً: خطة العمل خطوة بخطوة للوكيل

1. ابدأ بفتح متصفحك على:
   - `https://play.google.com/console`
   - `https://appstoreconnect.apple.com`
2. توقف واطلب من أحمد إتمام تسجيل الدخول في حال طلب رمز التحقق (2FA).
3. اختر تطبيق **Tibyan** في كلتا المنصتين.
4. انتقل لصفحة تفاصيل المتجر الرئيسية (Main Store Listing).
5. ارفع الأيقونة والغلاف وجميع لقطات الشاشة في أماكنها المخصصة لكل منصة وحجم شاشة.
6. انسخ الحقول النصية والبيانات الموضحة أعلاه بعناية وبدون تعديل.
7. اضغط «حفظ المسودة» (Save Draft) وتأكد من عدم وجود أي خطأ أو علامة تنبيه حمراء.
8. **توقف فورًا**: التقط صورة للشاشة وأخبر أحمد أن كل شيء جاهز لمراجعته وضغط زر الإرسال.
