# توقيت التلاوات · Recitation timings

متى تبدأ كل آية وكل كلمة في ملف السورة الصوتي، لكل قارئ يسمح ترخيص توقيته بالنشر. لتصحيحها استعمل المحرر: https://helalrules7.github.io/tibyan/ — والطريقة في [CONTRIBUTING](../../apps/timing-editor/CONTRIBUTING.md)، والتفاصيل والرخص في [docs/TIMING.md](../../docs/TIMING.md).

When each verse and each word starts in a surah's audio file, for the reciters whose timing licence allows publishing. Fix them with the editor (link above); see the contributing guide and docs/TIMING.md.

- `<reciter>/NNN.json`: one surah, one verse per line: `[verse, start_ms, end_ms, [[word, start_ms, end_ms], ...]]`. Times only; no Quran text.
- `reciters.json`: every recitation, its timing sources, licence and whether it is published here.
- `verse_words.json`: how many words each verse has. `<reciter>/audio.json`: each audio file's duration.

Licence: CC BY 4.0, with the attribution of each reciter's sources in `reciters.json`. Corrections contributed here are released under the same licence.
