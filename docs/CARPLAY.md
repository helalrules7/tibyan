# CarPlay (تطبيق صوت)

في السيارة يختار السائق تلاوة كما في Android Auto:

```
تبيان ─ «تابع من موضع القراءة»          (يشغّل)
      └ «القراء» ─ قارئ ─ السور الـ114   (كل سورة تشغّل)
```

وعند التشغيل تظهر شاشة «يُعرض الآن» (Now Playing) بأزرار التشغيل والإيقاف، وتأخذ بياناتها من جلسة الصوت نفسها التي تملأ شاشة القفل.

الكود كله مبني ويُجمَّع في كل بناء iOS، لكن **CarPlay لا يعرض التطبيق إلا إذا وُقِّع بصلاحية `com.apple.developer.carplay-audio`**، وهذه تمنحها Apple بطلب. الصلاحية خارج ملف الصلاحيات الفعلي حتى تصل الموافقة، فلا يتأثر التطبيق العادي ولا بناء CI.

## ما بُني وأين

| الملف | المحتوى |
|---|---|
| `lib/features/audio/car_browser.dart` | `CarBrowser`: الشجرة نفسها لأندرويد وCarPlay (`children(id)` و`play(id)`) |
| `lib/features/audio/car_channel.dart` | `CarChannel`: يجيب CarPlay عبر القناة `app.tibyan/car` من `CarBrowser` |
| `lib/main.dart` (`_startCarBrowsing`) | أندرويد: `JustAudioBackground.browser`. iOS: `CarChannel(browser).attach()` |
| `ios/Runner/CarPlaySceneDelegate.swift` | `CarPlaySceneDelegate` (قوالب `CPListTemplate` و`CPNowPlayingTemplate`) و`CarPlayBridge` (طرف القناة في Swift) |
| `ios/Runner/AppDelegate.swift` | يربط القناة بمحرك Flutter عند إنشائه |
| `ios/Runner/Info.plist` | مشهد `CPTemplateApplicationSceneSessionRoleApplication` بالمفوض `$(PRODUCT_MODULE_NAME).CarPlaySceneDelegate` |
| `ios/Runner/CarPlay.entitlements.disabled` | الصلاحية، **غير مفعّلة** |
| `tools/apple/carplay.rb` | يضيف الملف إلى هدف Runner، ويفعّل الصلاحية أو يعطلها |
| `test/audio/car_channel_test.dart` | اختبارات القناة: تحويل العناصر وتوجيه التشغيل |

### القناة `app.tibyan/car`

| الاستدعاء | من | الجواب |
|---|---|---|
| `children(id)` | Swift ← Dart | `[{id, title, subtitle?, playable}]`، و`root` للقائمة الأولى |
| `play(id)` | Swift ← Dart | يبدأ التلاوة (`continue` أو `play/<قارئ>/<سورة>`) |
| `ready` | Dart ← Swift | يخبر CarPlay أن Dart جاهز، فيعيد ملء القائمة الأولى |

### المحرك حين لا تكون واجهة الهاتف مفتوحة

للتطبيق محرك Flutter واحد. إن فُتحت واجهة الهاتف أولا فمحركها الضمني (`didInitializeImplicitFlutterEngine`) يحمل القناة. وإن شغّل CarPlay التطبيق والهاتف في الجيب، يطلب `CarPlayBridge.ensureEngine()` من `FlutterAppDelegate` محرك الإقلاع (launch engine)، فيعمل `main()` بلا واجهة ويسجَّل فيه الإضافات والقناة؛ ثم حين تُفتح واجهة الهاتف يتبنى `FlutterViewController` (من Main.storyboard) هذا المحرك نفسه بدل إنشاء ثانٍ، و`AppDelegate` لا يعيد التسجيل (يعرف ذلك من مفتاح `TibyanCarPlay`). فالتلاوة في السيارة والتطبيق على الهاتف حالة واحدة.

## كيف تُطلب الصلاحية من Apple

1. ادخل بحساب الفريق في Apple Developer Program (الحساب المدفوع نفسه الذي يوقّع التطبيق). يُفضَّل أن يقدّم الطلب Account Holder أو Admin.
2. افتح نموذج الطلب: <https://developer.apple.com/contact/carplay/> (يحوِّل إلى `developer.apple.com/contact/request/carplay/` ويطلب تسجيل الدخول). الرابط نفسه في صفحة <https://developer.apple.com/carplay/> تحت «Request CarPlay app entitlement».
3. املأ النموذج:
   - **الفئة (Category):** Audio.
   - **الفريق:** فريق Apple Developer الذي يملك التطبيق (Team ID).
   - **Bundle ID:** `app.tibyan.tibyan`.
   - **اسم التطبيق:** تبيان (Tibyan)، ورابطه على App Store أو TestFlight إن وُجد.
   - **الوصف المقترح:**
     > Tibyan is a Quran reading app with recitation audio. In CarPlay it is an audio app: the driver picks a reciter and a surah from short lists (or continues from where they stopped reading) and listens; playback is controlled from the Now Playing screen. No text is shown while driving; all content is audio.
4. وافق على **CarPlay Entitlement Addendum** حين يُعرض.
5. انتظر الرد بالبريد. تراجع Apple كل طلب وفق معايير الفئة، والمدة غير محددة (أيام إلى أسابيع، وأحيانا أطول).

> تحقق: الخطوات أعلاه من وثيقة Apple «Requesting CarPlay Entitlements» (<https://developer.apple.com/documentation/carplay/requesting-carplay-entitlements>) وصفحة CarPlay للمطورين، كما كانت في أكتوبر 2026. **حقول النموذج نفسه لم يمكن رؤيتها** لأنه خلف تسجيل الدخول؛ فما في الخطوة 3 هو ما يلزم عادة لا نسخة من النموذج. إن اختلف شيء فالمرجع ما تعرضه الصفحة.

## بعد الموافقة

تضيف Apple الصلاحية إلى الحساب كـ«managed capability». ثم:

1. **App ID:** في Certificates, Identifiers & Profiles ‹ Identifiers ‹ `app.tibyan.tibyan` ‹ تبويب Additional Capabilities، فعّل **CarPlay Audio App** واحفظ.
2. **ملف Provisioning:** أنشئ ملفا جديدا (تطوير وتوزيع) لهذا الـ App ID بعد التعديل؛ القديم لا يحمل الصلاحية. في Xcode ‹ Runner ‹ Signing & Capabilities: أوقف «Automatically manage signing» إن لم يأتِ التوقيع التلقائي بالصلاحية، ثم Provisioning Profile ‹ Download Profile واختر الملف الجديد.
3. **فعّل الصلاحية في المشروع:**

   ```
   gem install xcodeproj
   ruby tools/apple/carplay.rb enable
   ruby tools/apple/carplay.rb status      # entitlement: com.apple.developer.carplay-audio
   ```

   ينقل السكربت المفتاح من `ios/Runner/CarPlay.entitlements.disabled` إلى `ios/Runner/Runner.entitlements` (الذي يشير إليه `CODE_SIGN_ENTITLEMENTS`). ثبّت التغيير في المستودع. للتراجع: `ruby tools/apple/carplay.rb disable`.
4. **جرّب في المحاكي:** شغّل التطبيق في iOS Simulator من Xcode، ثم من قائمة المحاكي **I/O ‹ External Displays ‹ CarPlay**. يظهر «تبيان» في شاشة CarPlay الرئيسية. أو استعمل تطبيق **CarPlay Simulator** من «Additional Tools for Xcode» (<https://developer.apple.com/download/all/?q=additional%20tools%20for%20xcode>) مع جهاز حقيقي موصول بالـ Mac.
   - افتح «تبيان» في CarPlay قبل فتح التطبيق على الهاتف، وتأكد أن القوائم تمتلئ (هذا مسار محرك الإقلاع).
   - ثم افتح التطبيق على الهاتف أثناء التلاوة: يجب أن يظهر المشغل نفسه لا تلاوة ثانية.
5. **إن لم يتصل مشهد CarPlay** في المحاكي مع أن الصلاحية مفعّلة: مثال Apple يضع `UIApplicationSupportsMultipleScenes` على `true`، وتبيان يتركه `false` (لئلا يفتح iPad نوافذ متعددة لكل منها محرك). جرّب:

   ```
   ruby tools/apple/carplay.rb enable --multiple-scenes
   ```

6. مراجعة App Store: تطبيقات CarPlay تخضع لإرشادات إضافية (CarPlay App Programming Guide / CarPlay Developer Guide).

## الحدود

- **بناء CI بلا توقيع** (`flutter build ios --release --no-codesign` في `native.yml`) لا يحمل أي صلاحية، فلا CarPlay فيه أبدا. يتحقق CI فقط من أن `CarPlaySceneDelegate` مجمَّع داخل التطبيق وأن المشهد مُعلن في Info.plist. **كود Swift لم يُجمَّع إلا على CI** (لا Xcode في بيئة التطوير التي كُتب فيها).
- بلا الصلاحية: المشهد في Info.plist لا يُنشأ أبدا، والتطبيق يعمل كما كان.
- قوائم CarPlay محدودة الطول (`CPListTemplate.maximumItemCount`، ويختلف بحسب السيارة)؛ إن كان أقل من 114 تُقص قائمة السور. التقسيم إلى أجزاء خطوة لاحقة إن احتيج.
- النصوص الثابتة في Swift («تبيان»، «جارٍ التحميل…») عربية فقط؛ أما القوائم فمن `CarText` بلغة الواجهة.
- لا صور للقراء ولا للسور في القوائم بعد.
- **المقابل في أندرويد:** Android Auto لا يحتاج إذنا مسبقا من Google للتطوير (يكفي `automotive_app_desc.xml` و`MediaBrowserService` من `audio_service`)، لكن النشر على Play لسيارات Android Auto يمر بمراجعة جودة تطبيقات السيارات. الشجرة نفسها (`CarBrowser`) تخدم الاثنين.
