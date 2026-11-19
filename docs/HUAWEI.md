# Huawei AppGallery («تبيان» على أجهزة هواوي)

Huawei phones and tablets (EMUI, HarmonyOS 2 to 4) run the Android app but
have no Google Play services (GMS). Tibyan has a Huawei build for
AppGallery: same package (`app.tibyan.tibyan`), same upload key, one switch,
`--dart-define=TIBYAN_STORE=huawei`. There are no Gradle product flavors:
Gradle reads `TIBYAN_STORE` from the dart-defines, so Play builds and CI
need no `--flavor` and keep their output paths.

## 1. What differs in the Huawei build

| Area | Play build | Huawei build |
|---|---|---|
| Google Drive sync (google_sign_in) | On | Off. The sync screen says Drive needs Google Play services and points to «النسخ الاحتياطي» (backup file export/import) |
| In-app review (Play review API) | Play review sheet | No-op (never asks) |
| Watch (`app.tibyan/watch`) | Wear OS (play-services-wearable) | Huawei watches over Wear Engine (`src/huawei/kotlin/WatchBridge.kt`, docs/HUAWEI-WATCH.md) |
| Crash reports (GlitchTip) | `TIBYAN_CHANNEL=production` | `TIBYAN_CHANNEL=huawei` (a store build in the consent sheet) |
| Editions | 1441 and 1405, identical features | 1441 and 1405, identical features (nothing above depends on the edition) |
| Everything else (mushaf, audio, downloads, tasmee, notifications, widgets, backup) | On | On, none of it uses GMS |

The Play build also checks Google Play services at run time
(`GoogleServices.available()` in `lib/core/platform/app_store.dart`, native
`Gms.available` over `app.tibyan/store`). A Huawei user who sideloads the
Play APK gets the same fallbacks, not a crash.

The google_sign_in and in_app_review plugins still bundle their Google
libraries (play-services-auth, play-services-base, play review) in the
Huawei APK. They are never called there. Excluding them would break plugin
registration and R8.

### GMS audit

| Dependency | Needs GMS / Play? | Huawei build |
|---|---|---|
| google_sign_in (Drive sync) | Yes, play-services-auth | Off, backup file instead |
| in_app_review | Yes, Play review + play-services-base | No-op |
| play-services-wearable (Wear OS) | Yes | Not linked; Wear Engine instead |
| Assistant shortcuts (`res/xml/shortcuts.xml`) | Only Google Assistant reads them | Inert, harmless |
| Android Auto meta-data | Only Android Auto reads it | Inert, harmless |
| Firebase, Play Core updates, Play Asset Delivery, GMS location | Not used | n/a |
| flutter_local_notifications | No (local only) | Works |
| background_downloader, audio_service, just_audio, record, sherpa_onnx, home_widget, app_links, sentry_flutter | No | Works |

## 2. Build (on the Mac)

```sh
cp ~/.config/tibyan/key.properties android/key.properties   # once per checkout
N=43   # the build number
flutter build apk --release --split-per-abi --build-number=$N \
  --dart-define-from-file=$HOME/.config/tibyan/sentry.env \
  --dart-define=TIBYAN_CHANNEL=huawei \
  --dart-define=TIBYAN_STORE=huawei \
  --split-debug-info=build/symbols/$N
tools/upload_symbols.sh $N   # matched by debug id, sharing N with Play is fine
```

`--split-per-abi` gives one APK per CPU type instead of one universal
APK (~205 MB → ~153 MB for arm64-v8a). The outputs are in
`build/app/outputs/flutter-apk/`, signed with the upload key:

| File | ABI | versionCode |
|---|---|---|
| `app-arm64-v8a-release.apk` | arm64-v8a (all current Huawei phones) | 2000 + N |
| `app-armeabi-v7a-release.apk` | armeabi-v7a (old 32-bit phones) | 1000 + N |
| `app-x86_64-release.apk` | x86_64 (emulators; don't upload) | 4000 + N |

Flutter adds `1000 × ABI` to the build number in split builds, so each ABI
has its own versionCode and all of them are above the old universal ones
(≤ 56). Once a split APK is live, don't go back to a universal APK with the
plain build number: it would be lower than 2000 + N and AppGallery would
refuse it as a downgrade. (Passing `-Pforce-version-code-ignoring-abi=true`
keeps the plain number, but then two APKs share one versionCode.)

In AppGallery Connect upload the arm64-v8a and armeabi-v7a APKs together in
**Software package** (multi-APK). An AAB (`flutter build appbundle`, same
flags, no `--split-per-abi`) also works and AppGallery splits it itself.
Don't pass `google.env` because Drive is off.

## 3. AppGallery Connect, step by step (browser)

You need a Huawei Developer account (developer.huawei.com, identity verified).

1. AppGallery Connect → **My apps** → **New app**: Android, phone + tablet.
   - Name: «تبيان - القرآن الكريم» (default language Arabic); English «Tibyan: Quran».
   - Package `app.tibyan.tibyan`. Category **Books & Reference** (Religion if offered).
2. **App information**: paste the listing from section 4.
   - Icon: `docs/brand/store/graphics/play_icon_512x512.png`.
   - Screenshots: 3 to 5 portrait at 1080×1920 (9:16). Reuse the Play phone shots if they are 9:16, else render from `docs/brand/store/templates/android_phone/1080x1920`. Use the Arabic set for Arabic and the English set for English.
   - A promo graphic, if asked, can be rendered from `docs/brand/store/templates/android_phone/1920x1080`.
3. **Privacy**: policy URL `https://altibyan.app/privacy`. No personal data. Crash reports are anonymous and sent only with consent. Permissions: microphone (tasmee, on-device only) and notifications (reminders).
4. **Content rating**: no violence, gambling, public user content, ads or purchases. Expected: 3+ / Everyone.
5. **App signing**: choose "AppGallery Connect manages the app signing key" and upload the upload key's certificate only:
   `keytool -export -rfc -keystore ~/.config/tibyan/upload-keystore.jks -alias <alias from key.properties> -file upload_cert.pem`
   Never upload the .jks or its passwords.
6. **Software package**: upload `app-arm64-v8a-release.apk` and `app-armeabi-v7a-release.apk` (or the .aab).
7. Countries: the same as Play (or start with the Arab region). Free, no in-app purchases, no ads.
8. **Review notes** (paste):
   > Tibyan is a free, non-profit Quran reader with no ads, no accounts and no in-app purchases. The microphone is used only for the optional on-device recitation check; no audio leaves the device. Google Drive sync and Wear OS are not available in this build because they need Google services; the app offers file backup instead. No login is needed to test any feature.
9. Submit. Don't choose immediate release until the app has been tried on a Huawei device or with Huawei Cloud Debugging.

## 4. Listing copy (فصحى)

Arabic:
- الاسم: تبيان - القرآن الكريم
- الوصف الموجز: مصحف بلا إعلانات: استماع وتفسير وتسميع وحفظ دون إنترنت
- الوصف الكامل: النص العربي في `docs/brand/store/LISTING.md` (قسم Google Play)، مع تعديلين:
  - احذف من البند ٨: «مع تزامن فوري مع ساعات اليد الذكية (Wear OS وApple Watch)».
  - استبدل البند ٩ بما يلي: «٩. نسخ احتياطي آمن: احفظ علاماتك وختماتك وتقدم حفظك في ملف واحد، واستعِدها على أي جهاز.»

English:
- Name: Tibyan: Quran
- Short: Ad-free Quran app: recitation, tafsir, smart oral testing, and offline reading.
- Full: the English text in `LISTING.md`, with the same two edits. Drop the smartwatch sync sentence and make item 9:
  "9. Safe backup: save your bookmarks, khatmas and memorization progress in one file and restore it on any device."

## 5. Later

- Huawei Drive Kit sync and AppGallery in-app review (need the HMS Core SDK and agconnect-services.json).
- Huawei watches: docs/HUAWEI-WATCH.md. HarmonyOS NEXT: `handoff/09-huawei.md` part B.
