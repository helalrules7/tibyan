# أداة الشاشة الرئيسية (ورد الختمة)

تعرض الأداة ورد اليوم من الختمة (من صفحة كذا إلى صفحة كذا) ومرجع أول آية فيه (اسم السورة ورقم الآية فقط، بلا نص). الضغط عليها يفتح التطبيق على أول صفحة من الورد، في الطبعة التي يقرأ بها القارئ الآن.

## كيف تصل البيانات

`KhatmaService.refresh()` (في `lib/features/khatma/khatma_providers.dart`) يكتب عبر حزمة `home_widget` مفتاحا لكل يوم من الأيام الأربعة عشر القادمة، فتنتقل الأداة لليوم التالي وحدها دون فتح التطبيق:

| المفتاح | المحتوى |
|---|---|
| `title` | اسم الختمة |
| `idle` | ما يظهر في يوم لا ورد فيه (الورد مقروء، أو الختمة اكتملت، أو لا ختمة) |
| `edition` | طبعة الختمة |
| `days` | الأيام المكتوبة، مفصولة بفواصل |
| `portion_yyyy-MM-dd` | نص الورد |
| `ref_yyyy-MM-dd` | مرجع أول آية |
| `uri_yyyy-MM-dd` | `tibyan://khatma?page=…&edition=…&homeWidget` |

يُعاد الحساب عند فتح التطبيق، وعند عودته من الخلفية، وبعد كل صفحة تُحسب للختمة، وعند تغيير الخطة.

## أندرويد (مكتمل)

- `android/app/src/main/kotlin/app/tibyan/tibyan/KhatmaWidgetProvider.kt`: ‏`RemoteViews` عادي (بلا Glance)، يقرأ مفتاح اليوم.
- `res/layout/khatma_widget.xml` و`res/xml/khatma_widget_info.xml` (تحديث كل ساعة احتياطا لتغير اليوم) و`res/values{,-ar}/strings.xml`.
- مسجل في `AndroidManifest.xml`.
- الضغط: `HomeWidgetLaunchIntent` إلى `MainActivity` مع الرابط، ويقرؤه `main.dart` (`_startKhatma`).

## iOS وmacOS (WidgetKit)

مصدر الأدوات في `apple/` ومشترك بين المنصتين:

| المجلد | المحتوى |
|---|---|
| `apple/TibyanWidget/` | أداة الورد (`systemSmall` و`systemMedium`) |
| `apple/TibyanActions/` | أداة الاختصارات، امتداد مستقل: متابع، استماع، بحث، «قرأت الورد» |
| `apple/Shared/WidgetStore.swift` | الوصول إلى App Group وطابور الإجراءات |
| `apple/Extension-Info.plist`، `Widget-*.xcconfig`، `Widget-*.entitlements` | إعدادات الامتدادين |

الأهداف (targets) لا تُكتب يدويا: `tools/apple/add_widget_targets.rb` يضيف الامتدادين إلى `ios/Runner.xcodeproj` و`macos/Runner.xcodeproj` (وجودهما مسجل في المستودع، والسكربت لا يكرر إضافتهما). يعمل بلا Xcode:

```
gem install xcodeproj
ruby tools/apple/add_widget_targets.rb ios
ruby tools/apple/add_widget_targets.rb macos
```

الحد الأدنى: iOS 17 وmacOS 14 (لأجل `containerBackground` وأزرار `AppIntent` داخل الأداة). يتحقق `.github/workflows/native.yml` من البناء ومن وجود الامتدادين داخل التطبيق.

### أداة الاختصارات (Action center)

- متابع واستماع وبحث: روابط `tibyan://action/<name>?homeWidget` تفتح التطبيق (استماع يشغل التلاوة من أول صفحة القراءة).
- «قرأت الورد»: لا يفتح التطبيق. `MarkPortionDoneIntent` يضيف `portion_done` إلى طابور `pending_actions` في App Group ويعرض الأداة «تم»؛ وعند أول تشغيل أو عودة للتطبيق يقرأ `takePending` الطابور ويسجل ورد اليوم مقروءا (`KhatmaService.markTodayRead`). على أندرويد الزر بث (`broadcast`) إلى `ActionsWidgetProvider` نفسه بنفس الطابور (`HomeWidgetPreferences`).
- لا تلاوة بلا تشغيل التطبيق: تشغيل الصوت من الأداة يحتاج عملية التطبيق، فاستماع يفتحه.

### ما لا يستطيع المستودع فعله وحده

1. **App Group:** فعّله في حساب Apple Developer: iOS: `group.app.tibyan.tibyan`. macOS: `<TeamID>.group.app.tibyan.tibyan` (يأتي من `$(TeamIdentifierPrefix)`، ولا يُكتب في الكود). يلزمه التوقيع بفريق؛ قبله تفشل كتابة البيانات بصمت والتطبيق يعمل كما هو.
2. Bundle IDs: `app.tibyan.tibyan.TibyanWidget` و`app.tibyan.tibyan.TibyanActions` لكل منصة.
3. الأدوات المكتبية على macOS تُضاف من «تحرير الأدوات» في مركز الإشعارات.
4. قناة macOS (`app.tibyan/widget` في `macos/Runner/AppDelegate.swift`) تكتب مفاتيح الأداة وتستقبل روابط `tibyan://`، لأن `home_widget` لا يدعم macOS.
