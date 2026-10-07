# رخص التسميع السماعي: المعلّق والمحسوم

مبدأ الخطة 3: أي نموذج أو بيانات رخصتها غير واضحة أو توافقها مع GPL 3.0 غير محسوم يُوثق هنا **ولا يُنشر** على المرآة ولا يُشحن حتى يقرر أحمد. هذا ليس استشارة قانونية.

تاريخ الفحص: 2026-10-07 (بطاقات HuggingFace المحفوظة في مجلد التجربة المؤقت).

## محسوم

### قرار أحمد (2026-10-07): أوزان CC-BY-4.0 ونماذج مدرَّبة على everyayah

1. **أوزان بـ CC-BY-4.0 مقبولة داخل تطبيق تبيان (GPLv3)** بشرط النسبة الصحيحة (أدناه). الأوزان تُنزَّل منفصلة عن التطبيق بطلب المستخدم، وتبقى برخصتها.
2. **نموذج مدرَّب على everyayah مقبول للبيتا.** everyayah بلا رخصة (`docs/licenses/2026-09-28_everyayah_disclaimer_no-license.pdf`)؛ القرار للبيتا، ويُراجع قبل الإصدار العام.
3. **البيتا تنتقل إلى نموذج NVIDIA العربي** (فرع CTC، int8، عبر `sherpa_onnx`) بدل Whisper.

| المصدر | الرخصة | الحالة |
|---|---|---|
| [`nvidia/stt_ar_fastconformer_hybrid_large_pcd_v1.0`](https://huggingface.co/nvidia/stt_ar_fastconformer_hybrid_large_pcd_v1.0) (revision `7f32349d952f42a28dce979ba73270aa2bbdfa89`) | CC-BY-4.0 (البطاقة، قسم License: «ready for commercial and non-commercial use») | **نموذج البيتا.** منشور على المرآة: `https://tibyan.ahmedhelal.dev/mirror/recitation-models/nvidia-ar-fastconformer-ctc/` (والأصل `.nemo` وبطاقته في `mirror/sources/nvidia-stt-ar-fastconformer-hybrid-large-pcd-v1.0/`). بيانات تدريبه حسب البطاقة نحو 1,100 ساعة: MASC 690، Common Voice 17.0 العربي 65، FLEURS العربي 5، **everyayah 390** |
| [`mohammed/fastconformer-quran-ar`](https://huggingface.co/mohammed/fastconformer-quran-ar) | CC-BY-4.0 على البطاقة | مسموح بقرار أحمد، لكنه **غير مستعمل وغير منشور** (بديل ثان في التقييم). مشتق من نموذج NVIDIA ومدرَّب على everyayah؛ إن استُعمل فنسبته تذكر صاحبه وNVIDIA معا |
| [`tarteel-ai/whisper-base-ar-quran`](https://huggingface.co/tarteel-ai/whisper-base-ar-quran) | Apache-2.0 | نموذج البيتا السابق؛ باقٍ على المرآة للمقارنة فقط، والتطبيق لم يعد ينزّله. بيانات تدريبه غير موثقة («the None dataset») |

**شروط النسبة (CC-BY-4.0، القسم 3):** في كل مكان يُعرض فيه النموذج أو يُوزَّع:

1. ذكر صاحب العمل واسمه: نموذج NVIDIA «STT Ar FastConformer Hybrid Transducer-CTC Large PCD» (`nvidia/stt_ar_fastconformer_hybrid_large_pcd_v1.0`).
2. ذكر الرخصة مع رابطها: CC BY 4.0، `https://creativecommons.org/licenses/by/4.0/`.
3. بيان التعديل: تبيان صدّر فرع CTC وحده إلى ONNX وكمّم أوزانه إلى int8 (`convert/export_nemo_ctc.py`).
4. عدم الإيحاء بتأييد NVIDIA.

**أين تحققت النسبة:**

- المرآة: `LICENSE.txt` (النسبة والتعديلات ونص الرخصة كاملا) و`SOURCE.txt` بجانب الملفات، وحقل `attribution` في `manifest.json`.
- التطبيق: نص `tasmeeModelAttribution` (عربي وإنجليزي) في بطاقة التعريف بشاشة اختيار نطاق التسميع، وفي شاشة الجلسة تحت زر تنزيل النموذج، وفي نافذة الموافقة على التنزيل.

## معلّق

| المصدر | الرخصة المعلنة | ما يعلّقها | الحالة |
|---|---|---|---|
| `Quran-Lab/zipformer_p-arabic-v3`، `Muno459/fastconformer-quran` | `other`، مقيدان (gated) | النص غير مقروء دون طلب وصول | لم يُنزَّلا ولم يُجرَّبا. يحتاج أحمد طلب الوصول |
| الإصدار العام (لا البيتا) | — | قرار everyayah أعلاه للبيتا فقط؛ وبيانات Tarteel غير موثقة؛ ورخصة MASC لم تُفحص هنا | يُراجع قبل الإصدار العام |
