# المساهمة في توقيت التلاوات · Contributing recitation timings

<div dir="rtl">

## بالعربية

**الدليل المصور خطوة خطوة:** [docs/TIMING_GUIDE.md](../../docs/TIMING_GUIDE.md)، وهو نفسه في المحرر (زر «الدليل»).

تطبيق تبيان يظلل الآية والكلمة وقت تلاوتهما. هذا التوقيت يأتي من مصادر مفتوحة، وفيه أخطاء صغيرة: كلمة يسبقها التظليل أو يتأخر عنها. يمكنك تصحيحها من المتصفح، بلا تثبيت أي شيء.

1. افتح المحرر: https://helalrules7.github.io/tibyan/
2. اختر القارئ والسورة، وشغّل التلاوة. الكلمة المسموعة تظلَّل في النص وعلى الموجة.
3. إن رأيت خطأ: انقر الكلمة، ثم عدّل بدايتها أو نهايتها بالسحب على الموجة، أو بأزرار ±١٠ و±٥٠ مللي ثانية، أو «= الآن» أثناء التشغيل. خفّض السرعة وكرر الكلمة لتسمع الحد جيدا. ولكلمات كثيرة متتالية استعمل «وضع النقر»: اضغط مسافة عند بداية كل كلمة وأنت تسمع.
4. لوحة «الفحص» تعرض الأخطاء فورا (ترتيب، تداخل، كلمة خارج آيتها...). أصلحها قبل الإرسال. وفيها «⚑ أخطاء قديمة من المصدر»: كلمات جاءت بأخطاء من البيانات الأصلية (مثل كلمة تبدأ قبل نهاية التي قبلها). لا تمنع الإرسال، وتصحيحها من أنفع ما تساهم به.
5. اضغط «اقترح التعديل»: انسخ الملف الجديد، وافتحه في محرر GitHub، والصق مكان القديم، ثم «Propose changes» و«Create pull request». يحتاج هذا حسابا مجانيا على GitHub، وGitHub ينشئ لك نسخة (fork) تلقائيا.
6. في وصف الطلب: اكتب ما سمعته وما عدلته (مثلا: «البقرة ٢٥٥، الكلمة ٧ كانت تبدأ مبكرا بنصف ثانية»).

**بعد الإرسال:** يفحص GitHub الملف آليا ويكتب تعليقا فيه رابط يفتح تعديلك في المحرر، فيستمع المراجع إليه. بعد الدمج يصل التوقيت الجديد إلى التطبيق خلال يوم تقريبا، دون تحديث التطبيق.

**قواعد:**
- عدّل ملفات `data/timing/<القارئ>/NNN.json` فقط. لا تعدل نص القرآن (ليس في هذه الملفات أصلا)، ولا ملفات القراء أو المدد.
- لا تخمن: عدّل ما سمعته بوضوح فقط. وإن شككت فاكتب ذلك في الطلب.
- التوقيت منشور برخصة CC BY 4.0. بإرسال تعديلك توافق على نشره بنفس الرخصة.
- القراء المتاحون هم من تسمح رخصة توقيتهم بالنشر؛ التفاصيل في [docs/TIMING.md](../../docs/TIMING.md).

</div>

## English

**Step-by-step guide with pictures:** [docs/TIMING_GUIDE.md](../../docs/TIMING_GUIDE.md) (also in the editor: «الدليل»).

Tibyan highlights the verse and the word being recited. Those timings come from open sources and have small mistakes: a word lit up a little early or late. You can fix them in your browser.

1. Open the editor: https://helalrules7.github.io/tibyan/
2. Pick a reciter and a surah and press play. The word being recited is highlighted in the text and on the waveform.
3. To fix a word: click it, then move its start or end by dragging on the waveform, with the ±10/±50 ms buttons, or with "= now" while playing. Slow the playback down and loop the word to hear the boundary. For many words in a row, use tap mode: press Space at the start of each word as you listen.
4. The checks panel shows problems as you go (order, overlaps, a word outside its verse…). Fix them before sending. Problems marked ⚑ came with the source data; they don't block a pull request, and fixing them is one of the most useful contributions.
5. Press «اقترح التعديل» (propose the change): copy the new file, open it in GitHub's editor, paste over the old content, then **Propose changes** and **Create pull request**. You need a free GitHub account; GitHub forks the repository for you.
6. In the pull request, say what you heard and what you changed.

A check runs on every pull request and comments with a link that opens your change in the editor, so a reviewer can listen to it. Once merged, the app picks up the new timings within about a day, without an app update.

Rules: change only `data/timing/<reciter>/NNN.json`; only what you clearly heard; timings are published under CC BY 4.0 and your change is released under the same licence. Which reciters are here, and why, is in [docs/TIMING.md](../../docs/TIMING.md).

### Working on the editor itself

```sh
python3 tools/timing_files.py site --out /tmp/timing-site   # needs assets/db/content.db (git lfs pull)
python3 -m http.server -d /tmp/timing-site 8000             # then open http://localhost:8000/
node --test apps/timing-editor/test                         # the model's tests
python3 -m unittest discover -s tools/tests                 # the format and checks, in Python
```

Plain HTML, CSS and JavaScript modules, no build step and no third-party code. The Quran words are exported from `content.db` exactly as the app shows them, and drawn with the KFGQPC font, unmodified.
