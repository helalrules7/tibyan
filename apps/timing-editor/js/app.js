// The timing editor page. Reads (all static, from this site unless noted):
//   quran/surahs.json, quran/NNN.json   the app's words, exported verbatim
//   timing/reciters.json, timing/verse_words.json, timing/<slug>/audio.json
//   timing/<slug>/NNN.json              the file on main when this site was built
//   tibyan.ahmedhelal.dev/timing/peaks/<slug>/NNN.bin   waveform peaks
//   the recitation itself: our mirror, else the source (as the app does)
// With ?pr=N or ?src=<raw.githubusercontent.com URL> it shows a proposed
// file against main, for review.

import {
  dumps, validate, clone, flatWords, wordAt, diff, History, moveWordEdge, moveVerseEdge,
  tapStart, tapEnd, verseIndex, ISSUE_AR,
} from './model.js';
import { Timeline, formatMs } from './timeline.js';

const REPO = 'helalrules7/tibyan';
const SERVER = 'https://tibyan.ahmedhelal.dev';
const MIRROR = `${SERVER}/mirror/sources/recitations`;
const LOCAL = ['localhost', '127.0.0.1', ''].includes(location.hostname);

const $ = (id) => document.getElementById(id);
const pad3 = (n) => String(n).padStart(3, '0');
const audio = new Audio();
audio.preload = 'auto';
audio.preservesPitch = true;

const S = {
  reciters: [], surahs: [], counts: {}, reciter: null, surah: 1, quran: null, durations: {},
  base: null, doc: null, history: null, flat: [], issues: [], bad: new Set(), changed: new Set(),
  changedVerses: [], selected: null, loop: '', tapNext: null, lastTapped: null, playUntil: null,
  review: null, drag: null, nowWord: null, urls: [], urlIndex: 0,
};

function status(text) {
  const el = $('status');
  el.textContent = text;
  el.classList.add('show');
  clearTimeout(status.t);
  status.t = setTimeout(() => el.classList.remove('show'), 2600);
}

async function getJSON(url) {
  const r = await fetch(url, { cache: 'no-cache' });
  if (!r.ok) throw new Error(`${r.status} ${url}`);
  return r.json();
}

function surahUrls(folder, surah) {
  const source = folder.includes('{surah}') ? folder.replace('{surah}', String(surah)) : `${folder}${pad3(surah)}.mp3`;
  const path = new URL(source).pathname;
  return [`${MIRROR}${path}`, source];
}

function storage() {
  try {
    return window.localStorage;
  } catch {
    return null;
  }
}

function hash(text) {
  let h = 2166136261;
  for (let i = 0; i < text.length; i++) h = Math.imul(h ^ text.charCodeAt(i), 16777619);
  return (h >>> 0).toString(16);
}

// ------------------------------------------------------------------ load

async function init() {
  const [reciters, surahs, words, known] = await Promise.all([
    getJSON('timing/reciters.json'), getJSON('quran/surahs.json'), getJSON('timing/verse_words.json'),
    getJSON('timing/known_errors.json').catch(() => ({ errors: [] })),
  ]);
  S.reciters = reciters.reciters.filter((r) => r.publish);
  S.surahs = surahs;
  words.surahs.forEach((c, i) => { S.counts[i + 1] = c; });
  S.riwayat = words.riwayat || {};
  // Errors that came with the source data: shown, flagged, not blocking.
  S.known = new Set(known.errors.map(([r, s, a, k, code]) => `${r}|${s}|${a}|${k ?? ''}|${code}`));
  const q = new URLSearchParams(location.search);
  let slug = q.get('reciter');
  let surah = Number(q.get('surah')) || 1;
  let verse = q.has('verse') ? Number(q.get('verse')) : null;
  let srcUrl = null;
  if (q.has('pr')) {
    try {
      const found = await prFile(Number(q.get('pr')), slug, surah);
      if (found) ({ slug, surah, url: srcUrl } = found);
      S.review = { label: `طلب الدمج #${q.get('pr')}`, pr: Number(q.get('pr')) };
    } catch (e) {
      status(`تعذر جلب طلب الدمج: ${e.message}`);
    }
  } else if (q.has('src')) {
    const u = q.get('src');
    if (/^https:\/\/raw\.githubusercontent\.com\//.test(u)) {
      srcUrl = u;
      const m = u.match(/data\/timing\/([a-z0-9-]+)\/(\d{3})\.json$/);
      if (m) {
        slug = m[1];
        surah = Number(m[2]);
      }
      S.review = { label: 'ملف مقترح' };
    } else status('يُقبل src من raw.githubusercontent.com فقط');
  }
  if (!S.reciters.some((r) => r.slug === slug)) slug = S.reciters[0]?.slug;
  fillPickers(slug, surah);
  await loadSurah(slug, surah, { srcUrl, verse });
}

async function prFile(n, slug, surah) {
  const api = `https://api.github.com/repos/${REPO}`;
  const [pr, files] = await Promise.all([getJSON(`${api}/pulls/${n}`), getJSON(`${api}/pulls/${n}/files?per_page=100`)]);
  const timing = files.map((f) => f.filename).filter((f) => /^data\/timing\/[a-z0-9-]+\/\d{3}\.json$/.test(f));
  if (!timing.length) throw new Error('لا ملفات توقيت فيه');
  const want = slug && surah ? `data/timing/${slug}/${pad3(surah)}.json` : null;
  const path = timing.includes(want) ? want : timing[0];
  const m = path.match(/data\/timing\/([a-z0-9-]+)\/(\d{3})\.json$/);
  S.prFiles = timing;
  return { slug: m[1], surah: Number(m[2]), url: `https://raw.githubusercontent.com/${pr.head.repo.full_name}/${pr.head.sha}/${path}` };
}

const RIWAYA_AR = { hafs: 'حفص عن عاصم', warsh: 'ورش عن نافع', qalun: 'قالون عن نافع', douri: 'الدوري عن أبي عمرو', shubah: 'شعبة عن عاصم' };

/** Each verse's word count, or null per verse for a riwaya recitation (timed by verse only). */
function countsNow() {
  const riwaya = S.reciter?.riwaya || 'hafs';
  if (riwaya === 'hafs') return S.counts[S.surah];
  return Array(S.riwayat[riwaya]?.[S.surah - 1] ?? 0).fill(null);
}

const isRiwaya = () => (S.reciter?.riwaya || 'hafs') !== 'hafs';

function fillPickers(slug, surah) {
  const groups = [];
  for (const r of S.reciters) {
    let g = groups.find((x) => x.riwaya === r.riwaya);
    if (!g) {
      g = { riwaya: r.riwaya, el: document.createElement('optgroup') };
      g.el.label = RIWAYA_AR[r.riwaya] || r.riwaya;
      groups.push(g);
    }
    g.el.append(new Option(r.name_ar, r.slug, false, r.slug === slug));
  }
  $('reciter').replaceChildren(...groups.map((g) => g.el));
  $('surah').replaceChildren(...S.surahs.map((s) => new Option(`${s.n}. ${s.ar}`, s.n, false, s.n === surah)));
}

async function loadSurah(slug, surah, { srcUrl = null, verse = null } = {}) {
  audio.pause();
  S.reciter = S.reciters.find((r) => r.slug === slug);
  S.surah = surah;
  // A riwaya recitation has verses only: no words to tap or select.
  if (isRiwaya() && S.tap) setTap(false);
  $('tap').disabled = isRiwaya();
  document.querySelector('input[name=target][value=word]').disabled = isRiwaya();
  $('reciter').value = slug;
  $('surah').value = String(surah);
  const path = `timing/${slug}/${pad3(surah)}.json`;
  const [quran, audioInfo, baseText] = await Promise.all([
    S.reciters.find((r) => r.slug === slug)?.riwaya === 'hafs' ? getJSON(`quran/${pad3(surah)}.json`) : null,
    getJSON(`timing/${slug}/audio.json`).catch(() => ({ files: {} })),
    fetch(path, { cache: 'no-cache' }).then((r) => (r.ok ? r.text() : null)),
  ]);
  S.quran = quran;
  S.durations = audioInfo.files || {};
  S.peaksRate = audioInfo.peaks_per_second || 100;
  S.base = baseText ? JSON.parse(baseText) : null;
  let doc = S.base ? clone(S.base) : null;
  if (srcUrl) {
    try {
      doc = await getJSON(srcUrl);
    } catch (e) {
      status(`تعذر جلب الملف المقترح: ${e.message}`);
    }
  }
  if (!doc) {
    S.doc = null;
    $('words').textContent = 'لا توقيت لهذه السورة بعد.';
    return;
  }
  S.original = clone(doc);
  // A draft kept in this browser, made on the same base.
  const key = `tibyan-timing:${slug}:${surah}`;
  const store = storage();
  S.draftKey = key;
  S.draftBase = hash(dumps(doc));
  if (!srcUrl && store) {
    try {
      const draft = JSON.parse(store.getItem(key) || 'null');
      if (draft && draft.base === S.draftBase && draft.text !== dumps(doc)
        && confirm('لديك تعديلات محفوظة في هذا المتصفح لهذه السورة. أستعيدها؟')) {
        doc = JSON.parse(draft.text);
      }
    } catch { /* a broken draft is ignored */ }
  }
  S.doc = doc;
  S.history = new History(S.doc);
  S.selected = null;
  S.tapNext = null;
  const s = S.surahs[surah - 1];
  $('surah-title').textContent = `سورة ${s.ar}`;
  $('verse').replaceChildren(...S.doc.verses.map((v) => new Option(v[0] === 0 ? 'الافتتاح' : `${v[0]}`, v[0])));
  const rec = S.reciter;
  $('attribution').textContent = `التوقيت: ${[rec.verse_timing?.attribution, rec.word_timing?.attribution].filter(Boolean).join(' · ')}`;
  const note = $('source-note');
  if (S.review) {
    note.hidden = false;
    note.textContent = `${S.review.label}: تُعرض التعديلات المقترحة، والكلمات المعدلة بلون مختلف. المقارنة مع الملف على main.`;
  } else note.hidden = true;
  renderWords();
  recompute();
  history.replaceState(null, '', `?${new URLSearchParams({
    ...(S.review?.pr ? { pr: S.review.pr } : {}), reciter: slug, surah, ...(srcUrl && !S.review?.pr ? { src: srcUrl } : {}),
  })}`);
  loadAudio();
  const first = verse != null ? S.doc.verses.find((v) => v[0] === verse)
    : S.review && S.changedVerses.length ? S.doc.verses.find((v) => v[0] === S.changedVerses[0])
      : S.doc.verses.find((v) => v[0] > 0) || S.doc.verses[0];
  const v = first || S.doc.verses[0];
  select(v[3].length ? { kind: 'word', verse: v[0], word: v[3][0][0] } : { kind: 'verse', verse: v[0] }, true);
}

function loadAudio() {
  S.urls = surahUrls(S.reciter.folder_url, S.surah);
  S.urlIndex = 0;
  audio.src = S.urls[0];
  audio.playbackRate = Number($('speed').value);
  const dur = S.durations[pad3(S.surah)]?.duration_ms;
  timeline.setAudio(dur || 0, null, S.peaksRate);
  loadPeaks(dur);
}

audio.addEventListener('error', () => {
  if (S.urlIndex < S.urls.length - 1) {
    S.urlIndex++;
    audio.src = S.urls[S.urlIndex];
    audio.playbackRate = Number($('speed').value);
  } else status('تعذر تحميل التلاوة من الخادمين.');
});
audio.addEventListener('loadedmetadata', () => {
  const host = new URL(S.urls[S.urlIndex]).host;
  $('wave-status').textContent = `${$('wave-status').dataset.peaks || ''} · الصوت من ${host === new URL(SERVER).host ? 'مرآة تبيان' : host}`;
  if (!timeline.duration) timeline.setAudio(audio.duration * 1000, timeline.peaks, S.peaksRate);
});

async function loadPeaks(duration) {
  const token = (loadPeaks.token = {});
  const ws = $('wave-status');
  ws.dataset.peaks = 'الموجة: تحميل…';
  ws.textContent = ws.dataset.peaks;
  const name = `${S.reciter.slug}/${pad3(S.surah)}.bin`;
  const sources = [...(LOCAL ? [`peaks/${name}`] : []), `${SERVER}/timing/peaks/${name}`];
  for (const url of sources) {
    try {
      const r = await fetch(url);
      if (!r.ok) continue;
      const peaks = new Uint8Array(await r.arrayBuffer());
      if (token !== loadPeaks.token) return;
      timeline.setAudio(duration || (peaks.length * 1000) / S.peaksRate, peaks, S.peaksRate);
      ws.dataset.peaks = 'الموجة: جاهزة';
      ws.textContent = ws.dataset.peaks;
      return;
    } catch { /* next */ }
  }
  // No peaks published: decode the file here if it is small enough.
  const bytes = S.durations[pad3(S.surah)]?.bytes ?? Infinity;
  if (bytes > 40e6) {
    ws.dataset.peaks = 'الموجة: غير متاحة لهذه السورة (استعمل السمع)';
    ws.textContent = ws.dataset.peaks;
    return;
  }
  for (const url of S.urls) {
    try {
      const r = await fetch(url.startsWith(MIRROR) ? `${url}?cors=1` : url);
      if (!r.ok) continue;
      const ctx = new (window.OfflineAudioContext || window.webkitOfflineAudioContext)(1, 8000, 8000);
      const buf = await ctx.decodeAudioData(await r.arrayBuffer());
      const data = buf.getChannelData(0);
      const per = buf.sampleRate / S.peaksRate;
      const peaks = new Uint8Array(Math.ceil(data.length / per));
      for (let i = 0; i < peaks.length; i++) {
        let m = 0;
        const end = Math.min((i + 1) * per, data.length);
        for (let j = Math.floor(i * per); j < end; j++) m = Math.max(m, Math.abs(data[j]));
        peaks[i] = Math.min(255, Math.round(m * 255));
      }
      if (token !== loadPeaks.token) return;
      timeline.setAudio(buf.duration * 1000, peaks, S.peaksRate);
      ws.dataset.peaks = 'الموجة: محسوبة في المتصفح';
      ws.textContent = ws.dataset.peaks;
      return;
    } catch { /* next */ }
  }
  ws.dataset.peaks = 'الموجة: غير متاحة (استعمل السمع)';
  ws.textContent = ws.dataset.peaks;
}

// ------------------------------------------------------------- the text

function wordText(a, k) {
  return S.quran?.verses[a - 1]?.words[k - 1] ?? '';
}

function renderWords() {
  const box = $('words');
  const frag = document.createDocumentFragment();
  if (isRiwaya()) {
    // A riwaya recitation is timed by verse, and numbered by its riwaya:
    // its verses are shown by number only (the Hafs text would not match).
    const note = document.createElement('p');
    note.className = 'note';
    note.textContent = `تلاوة برواية ${RIWAYA_AR[S.reciter.riwaya] || S.reciter.riwaya}: التوقيت للآيات فقط، والآيات مرقمة بعدّ الرواية.`;
    frag.append(note);
    for (const v of S.doc.verses) {
      const mark = document.createElement('button');
      mark.type = 'button';
      mark.className = 'mark num';
      mark.id = `m-${v[0]}`;
      mark.dataset.v = v[0];
      mark.tabIndex = -1;
      mark.textContent = v[0] === 0 ? 'الافتتاح' : `﴿${v[0]}﴾`;
      frag.append(mark, ' ');
    }
    box.replaceChildren(frag);
    return;
  }
  if (S.doc.verses.some((v) => v[0] === 0)) {
    const b = document.createElement('button');
    b.className = 'mark';
    b.dataset.v = '0';
    b.textContent = '﴿الافتتاح﴾';
    b.style.fontFamily = "'Plex Arabic', sans-serif";
    b.style.fontSize = '1rem';
    frag.append(b, ' ');
  }
  for (const v of S.quran.verses) {
    const block = document.createElement('span');
    block.className = 'verse-block';
    v.words.forEach((text, i) => {
      const b = document.createElement('button');
      b.type = 'button';
      b.className = 'w';
      b.id = `w-${v.n}-${i + 1}`;
      b.dataset.v = v.n;
      b.dataset.k = i + 1;
      b.tabIndex = -1;
      b.setAttribute('role', 'option');
      b.textContent = text;
      block.append(b, ' ');
    });
    const mark = document.createElement('button');
    mark.type = 'button';
    mark.className = 'mark';
    mark.id = `m-${v.n}`;
    mark.dataset.v = v.n;
    mark.tabIndex = -1;
    mark.setAttribute('aria-label', `الآية ${v.n}`);
    mark.textContent = v.mark;
    block.append(mark, ' ');
    frag.append(block);
  }
  box.replaceChildren(frag);
}

{
  $('words').addEventListener('click', (e) => {
    const b = e.target.closest('button');
    if (!b) return;
    const a = Number(b.dataset.v);
    if (b.classList.contains('mark')) select({ kind: 'verse', verse: a }, true);
    else {
      const k = Number(b.dataset.k);
      if (S.doc.verses[verseIndex(S.doc, a)]?.[3].some((w) => w[0] === k)) select({ kind: 'word', verse: a, word: k }, true);
      else {
        select({ kind: 'verse', verse: a }, true);
        status('هذه الكلمة بلا توقيت بعد: استعمل وضع النقر لتعليم كلمات الآية');
        S.tapNext = { verse: a, word: firstUntimed(a) };
      }
    }
  });
}

function firstUntimed(a) {
  const v = S.doc.verses[verseIndex(S.doc, a)];
  return v ? v[3].length + 1 : 1;
}

// ---------------------------------------------------------- recompute

function recompute(light = false) {
  S.flat = flatWords(S.doc);
  timeline.invalidate();
  if (light) return;
  S.issues = validate(S.doc, S.reciter.slug, S.surah, countsNow(), S.durations[pad3(S.surah)]?.duration_ms ?? null);
  for (const i of S.issues) {
    if (i.level === 'error' && S.known.has(`${S.reciter.slug}|${S.surah}|${i.verse}|${i.word ?? ''}|${i.code}`)) i.level = 'known';
  }
  S.bad = new Set();
  S.knownBad = new Set();
  for (const i of S.issues) {
    if (i.level === 'warning' || i.verse == null) continue;
    const key = i.word ? `${i.verse}:${i.word}` : `${i.verse}`;
    S.bad.add(key);
    if (i.level === 'known') S.knownBad.add(key);
  }
  const d = S.base ? diff(S.base, S.doc) : { verses: [], words: new Set() };
  S.changed = d.words;
  S.changedVerses = d.verses;
  const timed = new Set(S.flat.map((w) => `${w.verse}:${w.word}`));
  for (const b of $('words').querySelectorAll('.w')) {
    const key = `${b.dataset.v}:${b.dataset.k}`;
    b.classList.toggle('untimed', !timed.has(key));
    b.classList.toggle('bad', S.bad.has(key) && !S.knownBad.has(key));
    b.classList.toggle('known', S.knownBad.has(key));
    b.classList.toggle('changed', S.changed.has(key));
  }
  for (const m of $('words').querySelectorAll('.mark')) m.classList.toggle('bad', S.bad.has(m.dataset.v));
  renderIssues();
  renderInspector();
  $('undo').disabled = !S.history.undoStack.length;
  $('redo').disabled = !S.history.redoStack.length;
  saveDraft();
}

function renderIssues() {
  const list = $('issues');
  const errors = S.issues.filter((i) => i.level === 'error').length;
  const knownN = S.issues.filter((i) => i.level === 'known').length;
  const warnings = S.issues.length - errors - knownN;
  $('check-count').textContent = [errors && `${errors} خطأ`, knownN && `${knownN} قديم`, warnings && `${warnings} تنبيه`]
    .filter(Boolean).join(' · ');
  const item = (i) => {
    const li = document.createElement('li');
    li.className = i.level;
    const b = document.createElement('button');
    b.type = 'button';
    const where = i.verse == null ? '' : i.word ? `${i.verse}:${i.word} ` : `آية ${i.verse} `;
    b.textContent = `${i.level === 'error' ? '✕' : i.level === 'known' ? '⚑' : '!'} ${where}${ISSUE_AR[i.code] || i.code}`;
    b.title = i.detail;
    b.addEventListener('click', () => {
      if (i.verse == null) return;
      const ok = i.word && S.doc.verses[verseIndex(S.doc, i.verse)]?.[3].some((w) => w[0] === i.word);
      select(ok ? { kind: 'word', verse: i.verse, word: i.word } : { kind: 'verse', verse: i.verse }, true);
    });
    li.append(b);
    return li;
  };
  const items = S.issues.filter((i) => i.level === 'error').slice(0, 200).map(item);
  if (!items.length) {
    const li = document.createElement('li');
    li.className = 'ok';
    li.textContent = '✓ لا أخطاء';
    items.push(li);
  }
  const knownList = S.issues.filter((i) => i.level === 'known');
  if (knownList.length) {
    // Came with the source data; fixing them is welcome (docs/MISSING_DATA.md).
    const li = document.createElement('li');
    const det = document.createElement('details');
    det.open = true;
    const sum = document.createElement('summary');
    sum.className = 'known';
    sum.textContent = `أخطاء قديمة من المصدر، ساعد في تصحيحها (${knownList.length})`;
    const ul = document.createElement('ul');
    ul.className = 'issues';
    ul.append(...knownList.slice(0, 200).map(item));
    det.append(sum, ul);
    li.append(det);
    items.push(li);
  }
  const warned = S.issues.filter((i) => i.level === 'warning');
  if (warned.length) {
    // Warnings (small overlaps kept from the source) stay folded away.
    const li = document.createElement('li');
    const det = document.createElement('details');
    const sum = document.createElement('summary');
    sum.textContent = `تنبيهات لا تمنع الإرسال (${warned.length})`;
    const ul = document.createElement('ul');
    ul.className = 'issues';
    ul.append(...warned.slice(0, 200).map(item));
    det.append(sum, ul);
    li.append(det);
    items.push(li);
  }
  list.replaceChildren(...items);
  const ch = $('changes');
  if (S.changedVerses.length) {
    ch.replaceChildren(`عدّلت ${S.changed.size} كلمة في ${S.changedVerses.length} آية: `,
      ...S.changedVerses.slice(0, 30).flatMap((a, j) => {
        const b = document.createElement('button');
        b.type = 'button';
        b.className = 'small';
        b.textContent = a;
        b.addEventListener('click', () => select({ kind: 'verse', verse: a }, true));
        return j ? [' ', b] : [b];
      }));
  } else ch.textContent = S.review ? 'لا فرق عن الملف على main.' : 'لم تعدّل شيئا بعد.';
}

let draftTimer;
function saveDraft() {
  clearTimeout(draftTimer);
  draftTimer = setTimeout(() => {
    const store = storage();
    if (!store || S.review) return;
    try {
      const text = dumps(S.doc);
      if (text === dumps(S.original)) store.removeItem(S.draftKey);
      else store.setItem(S.draftKey, JSON.stringify({ base: S.draftBase, text, at: Date.now() }));
    } catch { /* storage full or blocked: nothing kept */ }
  }, 800);
}

// ------------------------------------------------------------- select

function selectedSpan() {
  const sel = S.selected;
  if (!sel) return null;
  const v = S.doc.verses[verseIndex(S.doc, sel.verse)];
  if (!v) return null;
  if (sel.kind === 'verse') return [v[1], v[2]];
  const w = v[3].find((x) => x[0] === sel.word);
  return w ? [w[1], w[2]] : null;
}

function select(target, seek = false, keepView = false) {
  const prev = S.selected;
  S.selected = target;
  if (prev?.kind === 'word') {
    const old = $(`w-${prev.verse}-${prev.word}`);
    old?.classList.remove('sel');
    if (old) old.tabIndex = -1;
  }
  if (prev?.kind === 'verse') $(`m-${prev.verse}`)?.classList.remove('sel');
  const el = target.kind === 'word' ? $(`w-${target.verse}-${target.word}`) : $(`m-${target.verse}`);
  if (el) {
    el.classList.add('sel');
    el.tabIndex = 0;
    el.setAttribute('aria-selected', 'true');
    reveal(el);
  }
  document.querySelector(`input[name=target][value=${target.kind}]`).checked = true;
  $('verse').value = String(target.verse);
  const span = selectedSpan();
  if (span && !keepView) {
    if (span[0] < timeline.t0 || span[1] > timeline.t0 + timeline.span || seek) {
      if (target.kind === 'verse') {
        timeline.show(span[0], span[1], 0.05);
      } else {
        // About 12 ms a pixel: words wide enough to grab on a phone too.
        const around = Math.max(timeline.w * 12, span[1] - span[0] + 1000);
        const before = Math.min(around * 0.3, 2500);
        timeline.show(span[0] - before, span[0] - before + around, 0);
      }
    }
    if (seek) audio.currentTime = span[0] / 1000;
  }
  if (S.tap && target.kind === 'word') S.tapNext = { ...target };
  renderInspector();
  timeline.invalidate();
}

/** Scrolls the text box (not the page) so [el] is in view. */
function reveal(el, center = false) {
  const box = $('words');
  const top = el.offsetTop - box.offsetTop;
  if (center || top < box.scrollTop || top + el.offsetHeight > box.scrollTop + box.clientHeight) {
    box.scrollTo({ top: top - box.clientHeight / 2, behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth' });
  }
}

function renderInspector() {
  const sel = S.selected;
  const span = selectedSpan();
  $('sel-word').textContent = !sel ? '—' : sel.kind === 'word' ? wordText(sel.verse, sel.word)
    : isRiwaya() ? (sel.verse ? `﴿${sel.verse}﴾` : 'الافتتاح') : (S.quran?.verses[sel.verse - 1]?.mark ?? 'الافتتاح');
  $('sel-ref').textContent = !sel ? '' : sel.kind === 'word' ? `الآية ${sel.verse} · الكلمة ${sel.word}` : `الآية ${sel.verse}`;
  $('sel-start').value = span ? span[0] : '';
  $('sel-end').value = span ? span[1] : '';
}

function move(step) {
  const flat = S.flat;
  if (!flat.length) return;
  const sel = S.selected;
  let i = sel?.kind === 'word' ? flat.findIndex((w) => w.verse === sel.verse && w.word === sel.word) : -1;
  if (i < 0 && sel) i = flat.findIndex((w) => w.verse === sel.verse) - (step > 0 ? 1 : 0);
  const j = Math.min(Math.max(i + step, 0), flat.length - 1);
  select({ kind: 'word', verse: flat[j].verse, word: flat[j].word }, !audio.paused ? false : true);
  $(`w-${flat[j].verse}-${flat[j].word}`)?.focus({ preventScroll: true });
}

// ------------------------------------------------------------------ edit

const linked = () => $('linked').checked;
const neighbours = (a) => [a - 1, a, a + 1];

function setEdge(edge, ms, label = 'تعديل') {
  const sel = S.selected;
  if (!sel || !Number.isFinite(ms)) return;
  const changed = S.history.apply(label, neighbours(sel.verse), (d) => {
    if (sel.kind === 'word') moveWordEdge(d, sel.verse, sel.word, edge, ms, linked());
    else moveVerseEdge(d, sel.verse, edge, ms, linked());
  });
  if (changed) recompute();
  else renderInspector();
}

function nudge(edge, delta) {
  const span = selectedSpan();
  if (span) setEdge(edge, (edge === 'start' ? span[0] : span[1]) + delta, `${edge} ${delta}`);
}

const nowMs = () => Math.round(audio.currentTime * 1000);

function onDrag(phase, target, edge, ms) {
  if (phase === 'start') {
    const idx = neighbours(target.verse).map((a) => verseIndex(S.doc, a)).filter((i) => i >= 0);
    S.drag = { idx, before: idx.map((i) => clone(S.doc.verses[i])) };
    return;
  }
  if (!S.drag) return;
  S.drag.idx.forEach((i, j) => { S.doc.verses[i] = clone(S.drag.before[j]); });
  if (target.kind === 'word') moveWordEdge(S.doc, target.verse, target.word, edge, ms, linked());
  else moveVerseEdge(S.doc, target.verse, edge, ms, linked());
  if (phase === 'move') {
    recompute(true);
    renderInspector();
    return;
  }
  const after = S.drag.idx.map((i) => clone(S.doc.verses[i]));
  S.history.push('سحب', S.drag.idx, S.drag.before, after);
  S.drag = null;
  recompute();
}

function undo() {
  if (S.history.undo()) {
    recompute();
    status('تراجعت');
  }
}

function redo() {
  if (S.history.redo()) {
    recompute();
    status('أعدت');
  }
}

// ------------------------------------------------------------- tap mode

function setTap(on) {
  S.tap = on;
  $('tap').checked = on;
  $('tap-hint').hidden = !on;
  $('tap-button').hidden = !on;
  if (on) {
    const sel = S.selected;
    S.tapNext = sel?.kind === 'word' ? { ...sel } : sel ? { verse: sel.verse, word: firstUntimed(sel.verse) > (countsNow()[sel.verse - 1] || 0) ? 1 : firstUntimed(sel.verse) } : null;
    status('وضع النقر: اضغط مسافة عند بداية كل كلمة');
  }
}

function tap() {
  const next = S.tapNext;
  if (!next) return;
  const t = nowMs();
  let ok = false;
  S.history.apply('نقر', [next.verse], (d) => { ok = tapStart(d, next.verse, next.word, t).length > 0; });
  if (!ok) {
    status('لم تُعلَّم: الوقت قبل الكلمة السابقة');
    return;
  }
  S.lastTapped = { ...next };
  const count = countsNow()[next.verse - 1] || 0;
  S.tapNext = next.word < count ? { verse: next.verse, word: next.word + 1 } : { verse: next.verse + 1, word: 1 };
  recompute();
  const target = S.doc.verses[verseIndex(S.doc, S.tapNext.verse)]?.[3].some((w) => w[0] === S.tapNext.word)
    ? { kind: 'word', ...S.tapNext } : { kind: 'word', ...S.lastTapped };
  const keep = S.tapNext;
  select(target, false);
  S.tapNext = keep;
}

function tapStop() {
  const last = S.lastTapped;
  if (!last) return;
  const t = nowMs();
  if (S.history.apply('نهاية', [last.verse], (d) => tapEnd(d, last.verse, last.word, t))) {
    recompute();
    status(`نهاية ${wordText(last.verse, last.word)}`);
  }
}

// -------------------------------------------------------------- playback

function togglePlay() {
  if (audio.paused) {
    S.playUntil = null;
    audio.play().catch((e) => status(`تعذر التشغيل: ${e.message}`));
  } else audio.pause();
}

function playSelected() {
  const span = selectedSpan();
  if (!span) return;
  audio.currentTime = Math.max(span[0] - 150, 0) / 1000;
  S.playUntil = span[1];
  audio.play().catch(() => {});
}

function loopSpan() {
  if (!S.loop || !S.selected) return null;
  if (S.loop === 'verse' || S.selected.kind === 'verse') {
    const v = S.doc.verses[verseIndex(S.doc, S.selected.verse)];
    return v ? [v[1], v[2]] : null;
  }
  return selectedSpan();
}

audio.addEventListener('play', () => { $('play').textContent = 'إيقاف'; });
audio.addEventListener('pause', () => { $('play').textContent = 'تشغيل'; });

function frame() {
  if (S.doc) {
    const now = audio.currentTime * 1000;
    if (!audio.paused) {
      const loop = loopSpan();
      if (loop && (now >= loop[1] || now < loop[0] - 400)) audio.currentTime = loop[0] / 1000;
      else if (S.playUntil != null && now >= S.playUntil) {
        audio.pause();
        S.playUntil = null;
      }
      if ($('follow').checked && !timeline.drag) timeline.follow(now);
      timeline.invalidate();
    }
    $('clock').textContent = formatMs(now);
    const w = wordAt(S.flat, now);
    const key = w ? `${w.verse}-${w.word}` : null;
    if (key !== S.nowWord) {
      if (S.nowWord) $(`w-${S.nowWord}`)?.classList.remove('now');
      if (key) {
        const el = $(`w-${key}`);
        el?.classList.add('now');
        if (!audio.paused && $('follow').checked && el) reveal(el);
      }
      S.nowWord = key;
    }
    timeline.draw();
  }
  requestAnimationFrame(frame);
}

// ---------------------------------------------------------------- submit

function fileName() {
  return `${pad3(S.surah)}.json`;
}

function download() {
  const blob = new Blob([dumps(S.doc)], { type: 'application/json' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = fileName();
  a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}

async function copyText(text) {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch {
    const ta = document.createElement('textarea');
    ta.value = text;
    ta.setAttribute('readonly', '');
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.append(ta);
    ta.select();
    const ok = document.execCommand('copy');
    ta.remove();
    return ok;
  }
}

function openSubmit() {
  if (!S.changedVerses.length) {
    status('لا تعديلات لاقتراحها');
    return;
  }
  const errors = S.issues.filter((i) => i.level === 'error');
  const s = S.surahs[S.surah - 1];
  const verses = S.changedVerses;
  $('submit-summary').textContent = `${S.reciter.name_ar} · سورة ${s.ar}: ${S.changed.size} كلمة في ${verses.length} آية (${verses.slice(0, 12).join('، ')}${verses.length > 12 ? '…' : ''}).`
    + (errors.length ? ` تنبيه: في الملف ${errors.length} خطأ سيرفضه الفحص الآلي؛ أصلحها أولا إن استطعت.` : '');
  const path = `data/timing/${S.reciter.slug}/${fileName()}`;
  $('gh-edit').href = `https://github.com/${REPO}/edit/main/${path}`;
  $('pr-title').textContent = `timing(${S.reciter.slug}): ${s.en} ${verses.length === 1 ? `verse ${verses[0]}` : `verses ${verses[0]}–${verses[verses.length - 1]}`}`;
  $('copy-state').textContent = '';
  $('submit-dialog').showModal();
}

// ---------------------------------------------------------------- wiring

const timeline = new Timeline($('timeline'), {
  state: () => ({
    doc: S.doc, selected: S.selected, bad: S.bad, changed: S.changed, now: audio.currentTime * 1000, text: wordText,
  }),
  onSeek: (ms) => { audio.currentTime = Math.max(ms, 0) / 1000; timeline.invalidate(); },
  onSelect: (target, seek, keepView) => select(target, seek, keepView),
  onDrag,
});

$('reciter').addEventListener('change', (e) => { S.review = null; loadSurah(e.target.value, S.surah); });
$('surah').addEventListener('change', (e) => { S.review = null; loadSurah(S.reciter.slug, Number(e.target.value)); });
$('verse').addEventListener('change', (e) => {
  const a = Number(e.target.value);
  const v = S.doc.verses[verseIndex(S.doc, a)];
  select(v[3].length ? { kind: 'word', verse: a, word: 1 } : { kind: 'verse', verse: a }, true);
});
$('play').addEventListener('click', togglePlay);
$('back').addEventListener('click', () => { audio.currentTime = Math.max(audio.currentTime - 2, 0); });
$('fwd').addEventListener('click', () => { audio.currentTime += 2; });
$('speed').addEventListener('change', (e) => { audio.playbackRate = Number(e.target.value); });
$('loop').addEventListener('change', (e) => { S.loop = e.target.value; });
$('tap').addEventListener('change', (e) => setTap(e.target.checked));
$('tap-button').addEventListener('click', tap);
$('zoom-in').addEventListener('click', () => timeline.zoom(0.6, audio.currentTime * 1000));
$('zoom-out').addEventListener('click', () => timeline.zoom(1.6, audio.currentTime * 1000));
$('play-sel').addEventListener('click', playSelected);
$('fit-verse').addEventListener('click', () => {
  const a = S.selected?.verse;
  const v = S.doc.verses[verseIndex(S.doc, a)];
  if (!v?.[3].length) return;
  const first = v[3][0][1];
  const last = v[3][v[3].length - 1][2];
  // Each edge moves on its own, so a neighbour that touched it follows.
  const changed = S.history.apply('مطابقة الآية', neighbours(a), (d) => {
    moveVerseEdge(d, a, 'start', Math.min(first, d.verses[verseIndex(d, a)][2] - 20), linked());
    moveVerseEdge(d, a, 'end', last, linked());
    moveVerseEdge(d, a, 'start', first, linked());
  });
  if (changed) recompute();
});
$('undo').addEventListener('click', undo);
$('redo').addEventListener('click', redo);
for (const group of document.querySelectorAll('.nudges')) {
  group.addEventListener('click', (e) => {
    const b = e.target.closest('button');
    if (!b) return;
    const edge = group.dataset.edge;
    if (b.hasAttribute('data-now')) setEdge(edge, nowMs(), `${edge} = now`);
    else nudge(edge, Number(b.dataset.d));
  });
}
for (const id of ['sel-start', 'sel-end']) {
  $(id).addEventListener('change', (e) => setEdge(id === 'sel-start' ? 'start' : 'end', Number(e.target.value)));
}
for (const r of document.querySelectorAll('input[name=target]')) {
  r.addEventListener('change', () => {
    if (!S.selected) return;
    const v = S.doc.verses[verseIndex(S.doc, S.selected.verse)];
    if (r.value === 'verse') select({ kind: 'verse', verse: S.selected.verse });
    else if (v?.[3].length) select({ kind: 'word', verse: S.selected.verse, word: 1 });
  });
}
$('submit').addEventListener('click', openSubmit);
$('download').addEventListener('click', download);
$('download-2').addEventListener('click', download);
$('reset').addEventListener('click', () => {
  if (!S.changedVerses.length || !confirm('تجاهل كل تعديلاتك على هذه السورة؟')) return;
  S.doc = clone(S.base);
  S.history = new History(S.doc);
  recompute();
});
$('copy').addEventListener('click', async () => {
  $('copy-state').textContent = (await copyText(dumps(S.doc))) ? 'نُسخ ✓' : 'تعذر النسخ: نزّل الملف';
});
$('copy-title').addEventListener('click', () => copyText($('pr-title').textContent));
$('help-open').addEventListener('click', () => $('help-dialog').showModal());

// First visit: three lines and a link to the guide, until dismissed.
{
  let seen = false;
  try {
    seen = localStorage.getItem('tibyan-timing:welcome') === '1';
  } catch { /* storage blocked: show it */ }
  if (!seen) $('welcome').hidden = false;
  $('welcome-close').addEventListener('click', () => {
    $('welcome').hidden = true;
    try {
      localStorage.setItem('tibyan-timing:welcome', '1');
    } catch { /* fine */ }
  });
}

const SPEEDS = ['0.5', '0.6', '0.75', '0.9', '1'];
document.addEventListener('keydown', (e) => {
  if (document.querySelector('dialog[open]')) return;
  const tag = e.target.tagName;
  const typing = tag === 'INPUT' && e.target.type === 'number' || tag === 'SELECT' || tag === 'TEXTAREA';
  if (e.code === 'Escape' && S.tap) {
    setTap(false);
    return;
  }
  if (typing) return;
  const mod = e.ctrlKey || e.metaKey;
  if (mod && e.code === 'KeyZ') {
    e.preventDefault();
    if (e.shiftKey) redo();
    else undo();
    return;
  }
  if (mod && e.code === 'KeyY') {
    e.preventDefault();
    redo();
    return;
  }
  if (mod || e.altKey) return;
  const onButton = tag === 'BUTTON' && !e.target.classList.contains('w') && !e.target.classList.contains('mark');
  const big = e.shiftKey ? 50 : 10;
  switch (e.code) {
    case 'Space':
      if (onButton && !S.tap) return;
      e.preventDefault();
      if (S.tap && !audio.paused) tap();
      else togglePlay();
      break;
    case 'Enter':
    case 'NumpadEnter':
      if (onButton) return;
      e.preventDefault();
      if (S.tap) tapStop();
      else playSelected();
      break;
    case 'ArrowLeft': e.preventDefault(); move(1); break;
    case 'ArrowRight': e.preventDefault(); move(-1); break;
    case 'Comma': e.preventDefault(); nudge('start', -big); break;
    case 'Period': e.preventDefault(); nudge('start', big); break;
    case 'Semicolon': e.preventDefault(); nudge('end', -big); break;
    case 'Quote': e.preventDefault(); nudge('end', big); break;
    case 'KeyS': setEdge('start', nowMs(), 'start = now'); break;
    case 'KeyE': setEdge('end', nowMs(), 'end = now'); break;
    case 'KeyL': {
      const order = ['', 'word', 'verse'];
      S.loop = order[(order.indexOf(S.loop) + 1) % 3];
      $('loop').value = S.loop;
      status(S.loop === 'word' ? 'تكرار الكلمة' : S.loop === 'verse' ? 'تكرار الآية' : 'بلا تكرار');
      break;
    }
    case 'BracketLeft':
    case 'BracketRight': {
      const i = SPEEDS.indexOf($('speed').value) + (e.code === 'BracketLeft' ? -1 : 1);
      if (i >= 0 && i < SPEEDS.length) {
        $('speed').value = SPEEDS[i];
        audio.playbackRate = Number(SPEEDS[i]);
        status(`السرعة ${SPEEDS[i]}×`);
      }
      break;
    }
    default:
  }
});

init().catch((e) => {
  $('words').textContent = `تعذر التحميل: ${e.message}`;
});
requestAnimationFrame(frame);
