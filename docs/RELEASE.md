# الإصدار

## كيف يخرج إصدار

```
python3 tools/release/prepare.py 0.5.0     # يرفع pubspec ويقطع قسم [Unreleased] في CHANGELOG
git commit -am "release: 0.5.0"
git tag v0.5.0 && git push origin main v0.5.0
```

دفع الوسم `v*` يشغل `.github/workflows/release.yml`:

1. يتأكد أن الوسم يطابق `pubspec.yaml` وأن في CHANGELOG قسما لهذا الإصدار (`tools/release/check_version.py`)، وإلا يفشل قبل البناء.
2. أندرويد: APK و AAB، موقعان بمفتاح الرفع إن وُجدت الأسرار، وإلا بمفتاح التطوير (للتجربة فقط). ويُرفع الـ AAB إلى المسار الداخلي في Google Play إن وُجد مفتاح الخدمة.
3. iOS وmacOS: تطبيقان بلا توقيع (zip)، يوقَّعان من Xcode بشهادة الفريق.
4. يُنشر إصدار GitHub بملاحظات من CHANGELOG ومعه الملفات الأربعة.

## ما يلزمك أنت (لا يستطيع المستودع فعله)

أسرار GitHub (Settings ‹ Secrets and variables ‹ Actions):

| السر | المحتوى |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload.jks` لمفتاح الرفع |
| `ANDROID_KEYSTORE_PASSWORD`، `ANDROID_KEY_ALIAS`، `ANDROID_KEY_PASSWORD` | بيانات المفتاح |
| `PLAY_SERVICE_ACCOUNT_JSON` | مفتاح حساب خدمة Play (نص JSON)، له صلاحية الإصدار على التطبيق |

بدونها يعمل خط الإصدار كله ما عدا التوقيع الحقيقي والرفع إلى Play. احفظ مفتاح الرفع نسخة احتياطية خارج GitHub: ضياعه يمنع تحديث التطبيق على Play.

iOS وmacOS:
- حساب Apple Developer، وApp ID بالمعرفات `app.tibyan.tibyan` و`.TibyanWidget` و`.TibyanActions`.
- App Group: iOS `group.app.tibyan.tibyan`، macOS `<TeamID>.group.app.tibyan.tibyan` (docs/HOME_WIDGET.md).
- أرشِف ووقّع من Xcode ثم ارفع بـ Transporter إلى TestFlight (التوقيع الآلي من CI يحتاج شهادة وملف provisioning في الأسرار، ولم يُضف حتى تُنشأ).

## فحص قبل الوسم

`ci.yml` (format وanalyze وtest) و`native.yml` (بناء أندرويد وiOS وmacOS مع الامتدادات) خضراء على الفرع الذي يُدمج.
