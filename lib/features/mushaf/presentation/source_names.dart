/// How each source in content.db is named in the interface, in Arabic and
/// English: title, publisher, licence and credit line. Keyed by the
/// source's `key`. A source's published notice (for example Tanzil's) is
/// never translated; it is shown exactly as published.
typedef SourceText = ({
  String title,
  String publisher,
  String license,
  String credit,
});

const _ar = <String, SourceText>{
  'tanzil-uthmani': (
    title: 'نص القرآن الكريم بالرسم العثماني (تنزيل)',
    publisher: 'مشروع تنزيل',
    license:
        'المشاع الإبداعي، النسبة 3.0 (CC BY 3.0)، بشرط النقل الحرفي دون تعديل',
    credit: 'نص القرآن الكريم: مشروع تنزيل (tanzil.net)',
  ),
  'tanzil-simple-clean': (
    title: 'نص القرآن الكريم المبسّط (تنزيل)، للبحث فقط',
    publisher: 'مشروع تنزيل',
    license:
        'المشاع الإبداعي، النسبة 3.0 (CC BY 3.0)، بشرط النقل الحرفي دون تعديل',
    credit: 'نص البحث: مشروع تنزيل (tanzil.net)',
  ),
  'tanzil-metadata': (
    title: 'بيانات السور والأجزاء والأحزاب والصفحات (تنزيل)',
    publisher: 'مشروع تنزيل',
    license: 'المشاع الإبداعي، النسبة (CC BY)',
    credit: 'البيانات الوصفية: مشروع تنزيل (tanzil.net)',
  ),
  'quran-ws-hafs': (
    title: 'صفحات مصحف المدينة الحديث (1441هـ) وحدود الآيات',
    publisher: 'مشروع Quran.ws، والرسم لمجمع الملك فهد لطباعة المصحف الشريف',
    license: 'المشاع الإبداعي، النسبة 4.0 (CC BY 4.0)، والرسم وفق شروط المجمع',
    credit: 'صفحات المصحف: مجمع الملك فهد لطباعة المصحف الشريف',
  ),
  'kfgqpc-hafs-2.0': (
    title: 'نص حفص العثماني، الإصدار 2.0 (موقّع رقميا)',
    publisher: 'مجمع الملك فهد لطباعة المصحف الشريف',
    license: 'وفق شروط المجمع، وطُلب إذن النص',
    credit: 'نص القرآن الكريم: مجمع الملك فهد لطباعة المصحف الشريف',
  ),
  'qurancom-images-1024': (
    title: 'صفحات مصحف المدينة القديم (1405هـ) ومواضع الكلمات',
    publisher: 'موقع Quran.com (مؤسسة القرآن)، والرسم لمجمع الملك فهد',
    license: 'طُلب الإذن المكتوب (الرسالتان 2 و10)',
    credit: 'صفحات الطبعة القديمة: مجمع الملك فهد، عن موقع Quran.com',
  ),
  'quranenc-arabic-moyassar': (
    title: 'التفسير الميسر',
    publisher: 'مجمع الملك فهد لطباعة المصحف الشريف',
    license: 'شروط موسوعة القرآن الكريم (QuranEnc): دون تعديل أو إضافة أو حذف، مع ذكر الناشر والموقع ورقم الإصدار',
    credit: 'التفسير الميسر: مجمع الملك فهد لطباعة المصحف الشريف، عبر موقع QuranEnc.com',
  ),
  'quranenc-english-saheeh': (
    title: 'الترجمة الإنجليزية: صحيح إنترناشونال',
    publisher: 'صحيح إنترناشونال',
    license: 'شروط موسوعة القرآن الكريم (QuranEnc): دون تعديل أو إضافة أو حذف، مع ذكر المترجم والموقع ورقم الإصدار',
    credit: 'صحيح إنترناشونال، عبر موقع QuranEnc.com',
  ),
  'tanzil-en-pickthall': (
    title: 'الترجمة الإنجليزية: بكثال',
    publisher: 'محمد مارمادوك بكثال (1930)',
    license: 'ملكية عامة، ونسخة تنزيل للاستخدام غير التجاري',
    credit: 'بكثال (1930)، النص عن موقع تنزيل',
  ),
  'mp3quran': (
    title: 'التلاوات وتوقيت الآيات',
    publisher: 'موقع mp3quran.net',
    license: 'إذن عام من الموقع بنسخ أي مادة واستعمال أي رابط',
    credit: 'التلاوات وتوقيت الآيات: mp3quran.net',
  ),
  'quran-align-word-timing': (
    title: 'توقيت الكلمات (quran-align)، مطبَّقا على ملفات mp3quran',
    publisher: 'كولن فير (quran-align)، والتطبيق على الملفات من تبيان',
    license: 'المشاع الإبداعي، النسبة 4.0 (CC BY 4.0)',
    credit: 'توقيت الكلمات: quran-align © 2016 Collin Fair',
  ),
  'quranlab-word-timing': (
    title: 'توقيت الكلمات للبنا (مرتل)، وحدود الآيات',
    publisher: 'QuranLab، واستخراج حدود الآيات من تبيان',
    license: 'المشاع الإبداعي، النسبة 4.0 (CC BY 4.0)',
    credit: 'توقيت الكلمات للبنا: QuranLab، وحدود الآيات من تبيان',
  ),
  'shamarly-archive-org': (
    title: 'صفحات مصحف الشمرلي (الطبعة المصرية)',
    publisher: 'بخط محمد سعد إبراهيم الشهير بحداد؛ الصور عن أرشيف الإنترنت',
    license: 'مجاني، يجوز نسخه وتداوله على أن يعامل بكل احترام، ولا يجوز استخدامه في الأغراض التجارية (نص الغلاف)',
    credit: 'صفحات مصحف الشمرلي: أرشيف الإنترنت (archive.org)',
  ),
  'quranic-corpus': (
    title: 'المدونة القرآنية: الجذور والصرف',
    publisher: 'كايس دوكس (المدونة القرآنية Quranic Arabic Corpus، جامعة ليدز)',
    license: 'رخصة جنو العمومية (GPL)، بشرط نقل الملف حرفيا دون تعديل',
    credit: 'الجذور والصرف: المدونة القرآنية Quranic Arabic Corpus (corpus.quran.com)',
  ),
  'nuqayah-almuyassar-gharib': (
    title: 'الميسر في غريب القرآن',
    publisher: 'نقاية (التفسير التفاعلي read.tafsir.one)، بإذن مكتوب',
    license: 'إذن مكتوب من نقاية: بلا إعلانات ولا ربح',
    credit: 'الميسر في غريب القرآن: عن التفسير التفاعلي لنقاية (read.tafsir.one)، بإذنهم',
  ),
  'quranicaudio': (
    title: 'تلاوة ياسر الدوسري (مرتل)',
    publisher: 'موقع quranicaudio.com (صوت Quran.com)',
    license: 'إذن من الموقع بالبريد (2026-10-01)، بشرط ذكر اسم الموقع',
    credit: 'تلاوة ياسر الدوسري: quranicaudio.com',
  ),
  'qdc-timing': (
    title: 'توقيت آيات ياسر الدوسري وكلماته',
    publisher: 'Quran.com (واجهة QDC)، ومقاطع الكلمات من مكتبة QUL',
    license: 'الإذن قيد الطلب من Quran.com (رسالة 14)',
    credit: 'توقيت الآيات والكلمات: Quran.com',
  ),
  'quran-assets': (
    title: 'إطارات الثيمات وترويساتها وفواصلها (quran-assets)',
    publisher: 'مشروع quran-assets من Quran.ws، تطوير Abdullah Ibeid؛ الإطارات والترويسات منقولة من مصاحف مطبوعة، وتصميمها لمجمع الملك فهد وناشرين آخرين، وبعض الفواصل من خطوط مفتوحة',
    license: 'المنقول من المصاحف: المشاع الإبداعي غير التجاري 4.0 (CC BY-NC-SA 4.0)، مبدئي ولم يُحصل على إذن الناشرين بعد؛ فواصل الخطوط: رخصة الخطوط المفتوحة (OFL 1.1)',
    credit: 'زخارف الثيمات: quran-assets من Quran.ws، تطوير Abdullah Ibeid (github.com/quran-ws/quran-assets)، عن مصاحف مجمع الملك فهد وغيره، وخطوط Noto وScheherazade New وKufam وMirza',
  ),
  'multilingual-e5-small': (
    title: 'نموذج البحث بالمعنى (multilingual-e5-small)',
    publisher: 'intfloat (Liang Wang وآخرون)، على Hugging Face؛ أوزانه مكممة في تبيان، ومتجهات الآيات محسوبة من نصوص المعاني كما هي',
    license: 'رخصة MIT كما في بطاقة النموذج: يُسمح بالاستعمال والنسخ والتعديل والتوزيع مع ذكر الرخصة',
    credit:
        'البحث بالمعنى: نموذج multilingual-e5-small (MIT)، في حزمة اختيارية',
  ),
};

const _en = <String, SourceText>{
  'tanzil-uthmani': (
    title: 'Quran text, Uthmani script (Tanzil)',
    publisher: 'Tanzil Project',
    license: 'CC BY 3.0, verbatim copies only',
    credit: 'Quran text: Tanzil Project (tanzil.net)',
  ),
  'tanzil-simple-clean': (
    title: 'Quran text, simple script (Tanzil), for search only',
    publisher: 'Tanzil Project',
    license: 'CC BY 3.0, verbatim copies only',
    credit: 'Search text: Tanzil Project (tanzil.net)',
  ),
  'tanzil-metadata': (
    title: 'Surahs, juz, hizb and pages (Tanzil)',
    publisher: 'Tanzil Project',
    license: 'CC BY',
    credit: 'Metadata: Tanzil Project (tanzil.net)',
  ),
  'quran-ws-hafs': (
    title: 'New Madina edition pages (1441H) and verse outlines',
    publisher: 'Quran.ws; page artwork by the King Fahd Glorious Quran Printing Complex',
    license: 'CC BY 4.0; artwork under the Complex\'s terms',
    credit: 'Mushaf pages: King Fahd Glorious Quran Printing Complex',
  ),
  'kfgqpc-hafs-2.0': (
    title: 'Uthmanic Hafs text, version 2.0 (digitally signed)',
    publisher: 'King Fahd Glorious Quran Printing Complex',
    license: 'The Complex\'s terms; permission for the text requested',
    credit: 'Quran text: King Fahd Glorious Quran Printing Complex',
  ),
  'qurancom-images-1024': (
    title: 'Old Madina edition pages (1405H) and word positions',
    publisher: 'Quran.com (Quran Foundation); artwork by the King Fahd Complex',
    license: 'Written permission requested (letters 2 and 10)',
    credit: 'Old edition pages: King Fahd Complex, via Quran.com',
  ),
  'quranenc-arabic-moyassar': (
    title: 'Al-Tafsir al-Muyassar',
    publisher: 'King Fahd Glorious Quran Printing Complex',
    license: 'QuranEnc terms: no change, addition or removal; credit the publisher, QuranEnc.com and the version',
    credit: 'Al-Tafsir al-Muyassar: King Fahd Complex, via QuranEnc.com',
  ),
  'quranenc-english-saheeh': (
    title: 'English translation: Saheeh International',
    publisher: 'Saheeh International',
    license: 'QuranEnc terms: no change, addition or removal; credit the translator, QuranEnc.com and the version',
    credit: 'Saheeh International, via QuranEnc.com',
  ),
  'tanzil-en-pickthall': (
    title: 'English translation: Pickthall',
    publisher: 'Mohammed Marmaduke Pickthall (1930)',
    license: 'Public domain; Tanzil\'s copy for non-commercial use',
    credit: 'Pickthall (1930), text from Tanzil.net',
  ),
  'mp3quran': (
    title: 'Recitations and verse timings',
    publisher: 'mp3quran.net',
    license:
        'The site\'s general permission to copy any material or use any link',
    credit: 'Recitations and verse timings: mp3quran.net',
  ),
  'quran-align-word-timing': (
    title: 'Word timings (quran-align), placed on the mp3quran files',
    publisher: 'Collin Fair (quran-align); placement by Tibyan',
    license: 'CC BY 4.0',
    credit: 'Word timings: quran-align © 2016 Collin Fair',
  ),
  'quranlab-word-timing': (
    title: 'Word timings for al-Banna (murattal), and verse boundaries',
    publisher: 'QuranLab; verse boundaries derived by Tibyan',
    license: 'CC BY 4.0',
    credit: 'Word timings for al-Banna: QuranLab; verse boundaries by Tibyan',
  ),
  'shamarly-archive-org': (
    title: 'Shamarly (Egyptian) mushaf pages',
    publisher: 'Calligraphy by Mohamed Saad Ibrahim (Haddad); images from the Internet Archive',
    license: 'Free; may be copied and circulated if treated with respect, not for commercial use (cover text)',
    credit: 'Shamarly mushaf pages: Internet Archive (archive.org)',
  ),
  'quranic-corpus': (
    title: 'Quranic Arabic Corpus: roots and morphology',
    publisher: 'Kais Dukes (Quranic Arabic Corpus, University of Leeds)',
    license: 'GNU GPL; verbatim copies only',
    credit: 'Roots and morphology: Quranic Arabic Corpus (corpus.quran.com)',
  ),
  'nuqayah-almuyassar-gharib': (
    title: 'Al-Muyassar fi Gharib al-Quran',
    publisher: 'Nuqayah (read.tafsir.one), by written permission',
    license: 'Written permission from Nuqayah: no ads and no profit',
    credit: 'Al-Muyassar fi Gharib al-Quran: from Nuqayah\'s read.tafsir.one, by permission',
  ),
  'quranicaudio': (
    title: 'Yasser al-Dosari (murattal)',
    publisher: 'quranicaudio.com (Quran.com audio)',
    license: 'Permission granted by the site by email (2026-10-01), on condition that the site is named',
    credit: 'Yasser al-Dosari: quranicaudio.com',
  ),
  'qdc-timing': (
    title: 'Verse and word timings for Yasser al-Dosari',
    publisher: 'Quran.com (QDC API); word segments from the QUL library',
    license: 'Permission requested from Quran.com (letter 14)',
    credit: 'Verse and word timings: Quran.com',
  ),
  'quran-assets': (
    title: 'Theme frames, surah headers and verse markers (quran-assets)',
    publisher: 'quran-assets by Quran.ws, developed by Abdullah Ibeid; frames and headers traced from printed mushafs, designs by the King Fahd Complex and other publishers; some markers from open fonts',
    license: 'Traced from mushafs: CC BY-NC-SA 4.0, provisional, publishers\' permission not yet obtained; font markers: SIL Open Font License 1.1',
    credit: 'Theme ornaments: quran-assets by Quran.ws, developed by Abdullah Ibeid (github.com/quran-ws/quran-assets), from mushafs of the King Fahd Complex and others, and the Noto, Scheherazade New, Kufam and Mirza fonts',
  ),
  'multilingual-e5-small': (
    title: 'Search-by-meaning model (multilingual-e5-small)',
    publisher: 'intfloat (Liang Wang et al.), on Hugging Face; weights quantised by Tibyan, verse vectors computed from the meaning texts as stored',
    license: 'MIT License, as stated on the model card: use, copy, modify and distribute with the licence kept',
    credit: 'Search by meaning: the multilingual-e5-small model (MIT), in an optional pack',
  ),
};

/// Sources that are not in content.db (bundled with the app), listed after
/// the database's own: key, link and version.
const bundledSources = [
  (
    key: 'quran-assets',
    url: 'https://github.com/quran-ws/quran-assets',
    version: 'd4cae845c9aae1fbe56ee69d04bc7d8964419373',
  ),
  (
    key: 'multilingual-e5-small',
    url: 'https://huggingface.co/intfloat/multilingual-e5-small',
    version: '614241f622f53c4eeff9890bdc4f31cfecc418b3',
  ),
];

/// The interface text of a source, or null for one not listed here (it is
/// then shown as stored).
SourceText? sourceText(String key, String languageCode) =>
    (languageCode == 'ar' ? _ar : _en)[key];
