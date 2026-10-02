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

## iOS (الكود جاهز، والهدف يحتاج Xcode)

ملف الأداة: `ios/TibyanWidget/TibyanWidget.swift` (WidgetKit، ‏`systemSmall` و`systemMedium`). لم يُضف إلى مشروع Xcode لأن إضافة هدف (target) لا يمكن التحقق منها دون Xcode. الخطوات:

1. افتح `ios/Runner.xcworkspace` في Xcode.
2. File ‹ New ‹ Target ‹ Widget Extension. الاسم: `TibyanWidget`. ألغِ «Include Configuration App Intent» و«Live Activity».
3. احذف ملف Swift الذي أنشأه Xcode، وأضف `ios/TibyanWidget/TibyanWidget.swift` إلى الهدف الجديد فقط.
4. اضبط Deployment Target للهدف على iOS 17 (لأجل `containerBackground`)، أو احذف ذلك السطر لدعم iOS 14.
5. App Groups: في Signing & Capabilities أضف App Groups للهدفين **Runner** و**TibyanWidget** بالمعرف `group.app.tibyan.tibyan` (يطابق `PluginHomeWidgetSync.appGroup`). يحتاج هذا تفعيل المجموعة في حساب Apple Developer.
6. Bundle ID للأداة: `app.tibyan.tibyan.TibyanWidget`.
7. تأكد أن `Runner` ‹ Build Phases ‹ Embed Foundation Extensions يضم `TibyanWidget.appex`.
8. ابن وجرّب على المحاكي: أضف الأداة من الشاشة الرئيسية، وابدأ ختمة في التطبيق، ثم اضغط الأداة.

ما أُضيف لـ iOS في هذا الفرع:
- `CFBundleURLTypes` بالمخطط `tibyan` في `ios/Runner/Info.plist`، ليفتح رابط الأداة التطبيق.
- الحزمة تتعرف على ضغطة الأداة من معامل `homeWidget` في الرابط.

قبل إعداد App Group، تفشل كتابة بيانات الأداة على iOS بصمت (`PluginHomeWidgetSync.write` يلتقط الخطأ)، والتطبيق يعمل كما هو.
