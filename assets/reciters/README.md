# صور القُرّاء

الصور اللي بتظهر جنب اسم القارئ في قايمة القُرّاء وشاشة التحميلات.
مصغّرة ١٢٨×١٢٨ WebP (≈٦ كيلو للصورة) بـ
`python3 tools/build_reciter_photos.py` من ملفات في `tools/photos/`.

الصورة اسمها = رقم القارئ في `content.db` (مثلاً `11.webp` للسديس).
اللي مفيش له صورة بيظهر بالحروف الأولى في دايرة ✓ (مش شرط تكتمل).

## المصدر

الصور هي صور مقالات القُرّاء على ويكيبيديا العربية (صور تاريخية
لأعلام متوفين، بقرار مالك المشروع). تُجلب بـ
`python3 tools/fetch_reciter_photos.py`:

| # | القارئ | المصدر (صورة المقال) |
|---|--------|----------------------|
| 1 | محمد صديق المنشاوي | [ar](https://upload.wikimedia.org/wikipedia/commons/e/ee/Elminshwey.jpg?utm_source=ar.wikipedia.org&utm_campaign=api&utm_content=thumbnail_unscaled) |
| 2 | محمود خليل الحصري | [ar](https://upload.wikimedia.org/wikipedia/commons/7/70/Hussary.jpg?utm_source=ar.wikipedia.org&utm_campaign=api&utm_content=thumbnail_unscaled) |
| 3 | عبد الباسط عبد الصمد | [Commons](https://commons.wikimedia.org/wiki/File:Abdul_Basit_Abdul_Samad_at_Centenary_Celebration_Of_Darul_Uloom_Deoband_1980.jpg) — Prasar Bharati، GODL-India، لقطة من فيديو 1980 مقصوصة على الوجه |
| 4 | محمود علي البنا | صورة ملونة اختارها مالك المشروع (2026-10-03)، مقصوصة على الوجه؛ مصدرها ورخصتها لم يُوثَّقا بعد (إ22) |
| 10 | ياسر الدوسري | [ar](https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8b/Yasser_Al-Dosari_%28cropped%29.jpg/960px-Yasser_Al-Dosari_%28cropped%29.jpg?utm_source=ar.wikipedia.org&utm_campaign=api&utm_content=thumbnail) |
| 11 | عبد الرحمن السديس | [ar](https://upload.wikimedia.org/wikipedia/commons/1/18/Abdul-Rahman_Al-Sudais_%28Cropped%2C_2011%29.jpg?utm_source=ar.wikipedia.org&utm_campaign=api&utm_content=thumbnail_unscaled) |
| 12 | مشاري العفاسي | [ar](https://upload.wikimedia.org/wikipedia/commons/2/24/%D0%9C%D0%B8%D1%88%D0%B0%D1%80%D0%B8_%D0%A0%D0%B0%D1%88%D0%B8%D0%B4.jpg?utm_source=ar.wikipedia.org&utm_campaign=api&utm_content=thumbnail_unscaled) |
| 13 | سعد الغامدي | [ar](https://thumb.wikimedia.org/wikipedia/commons/thumb/4/43/Saad_al_Ghamdi.jpg/960px-Saad_al_Ghamdi.jpg?utm_source=ar.wikipedia.org&utm_campaign=api&utm_content=thumbnail) |

| 5 | مصطفى إسماعيل | [Commons](https://commons.wikimedia.org/wiki/File:Mustafa_Ismail_(1).jpg) — صورة الوش |
| 14 | محمد محمود الطبلاوي | صورة ملونة اختارها مالك المشروع (2026-10-03)، مقصوصة على الوجه؛ مصدرها ورخصتها لم يُوثَّقا بعد (إ22) |
| 15 | ماهر المعيقلي | [Commons](https://commons.wikimedia.org/wiki/File:Maher_Al_Mueaqly.png) — وليد أيوب، CC BY-SA 3.0 (`fetch_reciter_photos.py 15`) |

**تبديل أو إضافة صورة:** حِطّ ملفك في `tools/photos/<رقم القارئ>.jpg`
وشغّل `python3 tools/build_reciter_photos.py` — مفيش أي تعديل كود.

## قواعد اختيار الصورة

1. صورة شخصية واضحة، الوجه في المنتصف (القصّ بياخد المربع الأوسط).
2. مصدره Wikimedia Commons / صورة رسمية بإذن مكتوب.
3. اسم المصوّر ورخصته في بطاقة «صور القرّاء» في شاشة المصادر
   (`reciterPhotoCredits` في `lib/features/mushaf/presentation/source_names.dart`).
   صورتا 4 و14 اختارهما مالك المشروع ولم يُوثَّق مصدرهما ورخصتهما بعد:
   بند إ22 في `docs/MISSING_DATA.md`.
