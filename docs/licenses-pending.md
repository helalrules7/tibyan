# رخص معلقة: التسميع السماعي

مبدأ الخطة 3: أي نموذج أو بيانات رخصتها غير واضحة أو توافقها مع GPL 3.0 غير محسوم يُوثق هنا **ولا يُنشر** على المرآة ولا يُشحن حتى يقرر أحمد. هذا ليس استشارة قانونية.

تاريخ الفحص: 2026-10-07 (بطاقات HuggingFace المحفوظة في مجلد التجربة المؤقت).

| المصدر | الرخصة المعلنة | ما يعلّقها | الحالة |
|---|---|---|---|
| [`mohammed/fastconformer-quran-ar`](https://huggingface.co/mohammed/fastconformer-quran-ar) (NeMo، FastConformer Hybrid Large، 114.6M معامل) | CC-BY-4.0 على البطاقة (لا يوجد ملف LICENSE مستقل في الريبو) | (1) توافق CC-BY-4.0 للأوزان مع توزيعها ضمن تطبيق GPLv3 غير محسوم (CC تنصح بعدم استعمال رخصها للبرمجيات، والأوزان بين البرمجيات والبيانات). (2) مدرَّب على `tarteel-ai/everyayah`، وeveryayah بلا رخصة (`docs/licenses/2026-09-28_everyayah_disclaimer_no-license.pdf`). (3) مشتق من نموذج NVIDIA أدناه، فيرث شروطه ونسبته | جُرِّب محليا فقط (تحويل sherpa-onnx في مجلد مؤقت)، **غير منشور** |
| [`nvidia/stt_ar_fastconformer_hybrid_large_pcd_v1.0`](https://huggingface.co/nvidia/stt_ar_fastconformer_hybrid_large_pcd_v1.0) | CC-BY-4.0 (البطاقة، قسم License) | (1) نفس سؤال CC-BY-4.0 مع GPLv3. (2) من بيانات تدريبه (نحو 1,100 ساعة) **390 ساعة من everyayah** بلا رخصة، و690 ساعة MASC (رخصتها لم تُفحص هنا) | خط أساس للمقارنة فقط، **غير منشور** |
| [`tarteel-ai/whisper-base-ar-quran`](https://huggingface.co/tarteel-ai/whisper-base-ar-quran) (نموذج البيتا الحالي) | Apache-2.0 | بيانات التدريب غير موثقة («the None dataset») | أحمد وافق عليه للبيتا المحدودة فقط (2026-10-07)، منشور على المرآة؛ القرار للإصدار العام ما زال مفتوحا |
| `Quran-Lab/zipformer_p-arabic-v3`، `Muno459/fastconformer-quran` | `other`، مقيدان (gated) | النص غير مقروء دون طلب وصول | لم يُنزَّلا ولم يُجرَّبا. يحتاج أحمد طلب الوصول |

**المطلوب من أحمد:**

1. هل نقبل أوزانا بـ CC-BY-4.0 داخل تطبيق GPLv3 (مع نسبة واضحة في شاشة الرخص)، أم نطلب من صاحب `mohammed/fastconformer-quran-ar` إذنا صريحا أو رخصة أخرى؟
2. هل نقبل نموذجا دُرِّب على everyayah (بلا رخصة)؟ هذا يمس كل المرشحين المفتوحين تقريبا، ومنهم Tarteel على الأرجح.
3. لا نشر لأي نموذج CTC على المرآة قبل الجواب.
