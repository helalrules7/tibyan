// The timing file and its rules, without any page code, so it can be
// tested with `node --test apps/timing-editor/test`. The checks mirror
// `validate` in tools/timing_files.py; tools/tests/timing_cases.json holds
// the cases both must agree on.
//
// A file: {format: 1, reciter, surah, verses: [[n, start, end, [[w, start, end], ...]], ...]}
// Times are whole milliseconds in the surah's audio file.

export const FORMAT = 1;
export const TOLERANCE_MS = 50;
export const MIN_SPAN_MS = 20;
// mp3quran's published verse ends run up to ~350 ms past the end of some
// files; past that by this much is a warning, further an error.
export const DURATION_SLACK_MS = 500;

/** The canonical text of a timing file: one verse per line. */
export function dumps(doc) {
  const verse = (v) => JSON.stringify(v).replace(/,/g, ', ');
  const lines = [
    '{',
    `  "format": ${FORMAT},`,
    `  "reciter": ${JSON.stringify(doc.reciter)},`,
    `  "surah": ${doc.surah},`,
    '  "verses": [',
    ...doc.verses.map((v, i) => `    ${verse(v)}${i < doc.verses.length - 1 ? ',' : ''}`),
    '  ]',
    '}',
  ];
  return lines.join('\n') + '\n';
}

export function clone(x) {
  return JSON.parse(JSON.stringify(x));
}

const isInt = (x) => Number.isInteger(x);
const issue = (level, code, verse = null, word = null, detail = '') => ({ level, code, verse, word, detail });

/**
 * Every problem in one surah's file. [counts] is each verse's word count
 * (verse 1 first), null per verse for a riwaya recitation (timed by verse
 * only); [durationMs] the audio file's length, or null.
 */
export function validate(doc, slug, surah, counts, durationMs = null) {
  const out = [];
  if (doc === null || typeof doc !== 'object' || Array.isArray(doc)) {
    return [issue('error', 'schema', null, null, 'the file is not a JSON object')];
  }
  if (doc.format !== FORMAT) out.push(issue('error', 'schema', null, null, `"format" must be ${FORMAT}`));
  if (doc.reciter !== slug) out.push(issue('error', 'schema', null, null, `"reciter" must be "${slug}"`));
  if (doc.surah !== surah) out.push(issue('error', 'schema', null, null, `"surah" must be ${surah}`));
  const verses = doc.verses;
  if (!Array.isArray(verses)) {
    out.push(issue('error', 'schema', null, null, '"verses" must be a list'));
    return out;
  }
  const n = counts.length;
  const seen = [];
  let prevVerseEnd = null;
  let prevWord = null; // [verse, word, end]
  for (const entry of verses) {
    let ok = Array.isArray(entry) && entry.length === 4 && entry.slice(0, 3).every(isInt) && Array.isArray(entry[3]);
    if (ok) ok = entry[3].every((w) => Array.isArray(w) && w.length === 3 && w.every(isInt));
    if (!ok) {
      out.push(issue('error', 'schema', null, null, 'a verse must be [number, start, end, [[word, start, end], ...]] of whole numbers'));
      continue;
    }
    const [a, start, end, words] = entry;
    if (a < 0 || a > n || (seen.length && a <= seen[seen.length - 1])) {
      out.push(issue('error', 'verse_order', a, null, `verse ${a} is out of order or not in this surah`));
      continue;
    }
    seen.push(a);
    if (start < 0 || end <= start) out.push(issue('error', 'verse_span', a, null, `${start}..${end}`));
    if (prevVerseEnd !== null && start < prevVerseEnd) {
      out.push(issue('error', 'verse_overlap', a, null, `starts at ${start}, before the previous verse ends at ${prevVerseEnd}`));
    }
    if (durationMs !== null && end > durationMs) {
      const big = end - durationMs > DURATION_SLACK_MS;
      out.push(issue(big ? 'error' : 'warning', big ? 'verse_duration' : 'past_audio_end', a, null,
        `ends at ${end}, after the audio ends at ${durationMs}`));
    }
    prevVerseEnd = Math.max(end, prevVerseEnd ?? 0);
    if (a === 0 || counts[a - 1] === null) {
      if (words.length) out.push(issue('error', 'schema', a, null, 'this verse has no word numbering (the opening, or a riwaya recitation)'));
      continue;
    }
    if (!words.length) {
      out.push(issue('warning', 'words_missing', a, null, `${counts[a - 1]} words have no timing`));
      continue;
    }
    const numbers = words.map((w) => w[0]);
    if (numbers.length !== counts[a - 1] || numbers.some((k, i) => k !== i + 1)) {
      out.push(issue('error', 'words_partial', a, null, `words must be 1..${counts[a - 1]} in order`));
      continue;
    }
    for (const [k, ws, we] of words) {
      if (ws < 0 || we <= ws) out.push(issue('error', 'word_span', a, k, `${ws}..${we}`));
      if (prevWord !== null && ws < prevWord[2]) {
        const over = prevWord[2] - ws;
        if (prevWord[0] === a || over > TOLERANCE_MS) {
          out.push(issue('error', 'word_overlap', a, k, `starts ${over} ms before the previous word ends`));
        } else {
          out.push(issue('warning', 'word_overlap_small', a, k, `${over} ms into the previous verse's last word`));
        }
      }
      const outside = Math.max(start - ws, we - end, 0);
      if (outside > TOLERANCE_MS) out.push(issue('error', 'word_outside', a, k, `${outside} ms outside its verse`));
      else if (outside > 0) out.push(issue('warning', 'word_outside_small', a, k, `${outside} ms outside its verse`));
      if (durationMs !== null && we > durationMs) {
        const big = we - durationMs > DURATION_SLACK_MS;
        out.push(issue(big ? 'error' : 'warning', big ? 'word_duration' : 'past_audio_end', a, k,
          `ends at ${we}, after the audio ends at ${durationMs}`));
      }
      prevWord = [a, k, we];
    }
  }
  const missing = [];
  for (let a = 1; a <= n; a++) if (!seen.includes(a)) missing.push(a);
  if (missing.length && seen.length) {
    out.push(issue('error', 'verse_missing', missing[0], null,
      `${missing.length} verse(s) have no timing: ${missing.slice(0, 10).join(', ')}`));
  }
  if (!seen.length) out.push(issue('error', 'verse_missing', null, null, 'the file has no verses'));
  return out;
}

/** Arabic text for each issue code. */
export const ISSUE_AR = {
  schema: 'صيغة الملف غير صحيحة',
  path: 'مسار الملف غير صحيح',
  layout: 'ترتيب الأسطر غير المعتاد',
  verse_order: 'ترتيب الآيات غير صحيح',
  verse_missing: 'آيات بلا توقيت',
  verse_span: 'نهاية الآية قبل بدايتها',
  verse_overlap: 'الآية تبدأ قبل نهاية التي قبلها',
  verse_duration: 'الآية تتجاوز نهاية الملف الصوتي',
  words_missing: 'كلمات الآية بلا توقيت',
  words_partial: 'بعض كلمات الآية بلا توقيت',
  word_span: 'نهاية الكلمة قبل بدايتها',
  word_overlap: 'الكلمة تبدأ قبل نهاية التي قبلها',
  word_overlap_small: 'تداخل صغير مع آخر كلمة من الآية السابقة',
  word_outside: 'الكلمة خارج حدود آيتها',
  word_outside_small: 'الكلمة تتجاوز حدود آيتها قليلا',
  word_duration: 'الكلمة تتجاوز نهاية الملف الصوتي',
  past_audio_end: 'تتجاوز نهاية الملف الصوتي قليلا',
};

/** Index of the verse entry numbered [a], or -1. */
export function verseIndex(doc, a) {
  return doc.verses.findIndex((v) => v[0] === a);
}

/** Every timed word in time order: {verse, word, start, end}. */
export function flatWords(doc) {
  const out = [];
  for (const [a, , , words] of doc.verses) for (const [k, s, e] of words) out.push({ verse: a, word: k, start: s, end: e });
  out.sort((x, y) => x.start - y.start);
  return out;
}

/** The word sounding at [ms] in [flat] (from flatWords), or null. */
export function wordAt(flat, ms) {
  let lo = 0;
  let hi = flat.length - 1;
  let found = -1;
  while (lo <= hi) {
    const mid = (lo + hi) >> 1;
    if (flat[mid].start <= ms) {
      found = mid;
      lo = mid + 1;
    } else hi = mid - 1;
  }
  if (found < 0) return null;
  const w = flat[found];
  return ms <= w.end ? w : null;
}

/** The verse entry whose window holds [ms], or null. */
export function verseAt(doc, ms) {
  for (const v of doc.verses) if (v[1] <= ms && ms < v[2]) return v;
  return null;
}

/** Verses (numbers) that differ between two files, and how many words. */
export function diff(base, doc) {
  const old = new Map(base.verses.map((v) => [v[0], v]));
  const now = new Map(doc.verses.map((v) => [v[0], v]));
  const verses = [];
  const words = new Set();
  for (const a of new Set([...old.keys(), ...now.keys()])) {
    const o = old.get(a);
    const n = now.get(a);
    if (JSON.stringify(o) === JSON.stringify(n)) continue;
    verses.push(a);
    const ow = new Map((o?.[3] ?? []).map((w) => [w[0], w]));
    const nw = new Map((n?.[3] ?? []).map((w) => [w[0], w]));
    for (const k of new Set([...ow.keys(), ...nw.keys()])) {
      if (JSON.stringify(ow.get(k)) !== JSON.stringify(nw.get(k))) words.add(`${a}:${k}`);
    }
  }
  verses.sort((x, y) => x - y);
  return { verses, words };
}

/**
 * Edits with undo and redo. Each step records the verse entries it
 * changed, before and after, so undo restores exactly.
 */
export class History {
  constructor(doc) {
    this.doc = doc;
    this.undoStack = [];
    this.redoStack = [];
  }

  /** Applies [change] (a function that edits verse entries of this.doc in place) as one step. */
  apply(label, verseNumbers, change) {
    const idx = verseNumbers.map((a) => verseIndex(this.doc, a)).filter((i) => i >= 0);
    const before = idx.map((i) => clone(this.doc.verses[i]));
    change(this.doc);
    const after = idx.map((i) => clone(this.doc.verses[i]));
    if (JSON.stringify(before) === JSON.stringify(after)) return false;
    this.undoStack.push({ label, idx, before, after });
    if (this.undoStack.length > 500) this.undoStack.shift();
    this.redoStack = [];
    return true;
  }

  /** Records a step made elsewhere (a drag): verse indexes and their entries before and after. */
  push(label, idx, before, after) {
    if (JSON.stringify(before) === JSON.stringify(after)) return false;
    this.undoStack.push({ label, idx, before, after });
    if (this.undoStack.length > 500) this.undoStack.shift();
    this.redoStack = [];
    return true;
  }

  undo() {
    const step = this.undoStack.pop();
    if (!step) return null;
    step.idx.forEach((i, j) => { this.doc.verses[i] = clone(step.before[j]); });
    this.redoStack.push(step);
    return step;
  }

  redo() {
    const step = this.redoStack.pop();
    if (!step) return null;
    step.idx.forEach((i, j) => { this.doc.verses[i] = clone(step.after[j]); });
    this.undoStack.push(step);
    return step;
  }
}

/**
 * Moves one edge of a word to [ms]. With [linked], a neighbour whose edge
 * touched this one (within a frame) moves with it, so a boundary between
 * two words stays one boundary. The edge never crosses the word's other
 * edge or a neighbour's far edge. Returns the verse numbers changed.
 */
export function moveWordEdge(doc, a, k, edge, ms, linked = true) {
  const flat = [];
  for (const v of doc.verses) for (const w of v[3]) flat.push({ v, w });
  flat.sort((x, y) => x.w[1] - y.w[1]);
  const i = flat.findIndex((x) => x.v[0] === a && x.w[0] === k);
  if (i < 0) return [];
  const w = flat[i].w;
  const prev = flat[i - 1];
  const next = flat[i + 1];
  const touched = [a];
  ms = Math.round(ms);
  if (edge === 'start') {
    let lo = prev ? prev.w[1] + MIN_SPAN_MS : 0;
    const hi = w[2] - MIN_SPAN_MS;
    const joined = linked && prev && Math.abs(prev.w[2] - w[1]) <= 10;
    if (!joined && prev) lo = Math.max(lo, prev.w[2]);
    ms = Math.min(Math.max(ms, lo), hi);
    if (joined) {
      prev.w[2] = ms;
      if (prev.v[0] !== a) touched.push(prev.v[0]);
    }
    w[1] = ms;
  } else {
    const lo = w[1] + MIN_SPAN_MS;
    let hi = next ? next.w[2] - MIN_SPAN_MS : Number.MAX_SAFE_INTEGER;
    const joined = linked && next && Math.abs(next.w[1] - w[2]) <= 10;
    if (!joined && next) hi = Math.min(hi, next.w[1]);
    ms = Math.min(Math.max(ms, lo), hi);
    if (joined) {
      next.w[1] = ms;
      if (next.v[0] !== a) touched.push(next.v[0]);
    }
    w[2] = ms;
  }
  return touched;
}

/** Moves one edge of a verse; with [linked], the neighbouring verse's touching edge follows. */
export function moveVerseEdge(doc, a, edge, ms, linked = true) {
  const i = verseIndex(doc, a);
  if (i < 0) return [];
  const v = doc.verses[i];
  const prev = doc.verses[i - 1];
  const next = doc.verses[i + 1];
  const touched = [a];
  ms = Math.round(ms);
  if (edge === 'start') {
    const joined = linked && prev && Math.abs(prev[2] - v[1]) <= 10;
    let lo = prev ? (joined ? prev[1] + MIN_SPAN_MS : prev[2]) : 0;
    ms = Math.min(Math.max(ms, lo), v[2] - MIN_SPAN_MS);
    if (joined) {
      prev[2] = ms;
      touched.push(prev[0]);
    }
    v[1] = ms;
  } else {
    const joined = linked && next && Math.abs(next[1] - v[2]) <= 10;
    const hi = next ? (joined ? next[2] - MIN_SPAN_MS : next[1]) : Number.MAX_SAFE_INTEGER;
    ms = Math.min(Math.max(ms, v[1] + MIN_SPAN_MS), hi);
    if (joined) {
      next[1] = ms;
      touched.push(next[0]);
    }
    v[2] = ms;
  }
  return touched;
}

/**
 * Tap to mark: the reader presses at each word's start while listening.
 * Marks word [k] of verse [a] as starting at [ms]; the word before it in
 * the same verse ends there (a boundary is one moment). In a verse without
 * word timings the words are created one tap at a time, so every time is
 * one a person marked. Returns the verse numbers changed, or [] when the
 * tap was refused (out of order).
 */
export function tapStart(doc, a, k, ms) {
  const v = doc.verses[verseIndex(doc, a)];
  if (!v) return [];
  ms = Math.round(ms);
  const words = v[3];
  const at = words.findIndex((w) => w[0] === k);
  const before = at > 0 ? words[at - 1] : at < 0 ? words[words.length - 1] : null;
  if (before && ms <= before[1] + MIN_SPAN_MS) return [];
  if (at >= 0) {
    const w = words[at];
    if (ms >= w[2] - MIN_SPAN_MS && at === words.length - 1) w[2] = ms + 300;
    w[1] = Math.min(ms, w[2] - MIN_SPAN_MS);
  } else {
    if (k !== words.length + 1) return [];
    words.push([k, ms, ms + 300]);
  }
  if (before) before[2] = ms;
  return [a];
}

/** Tap to mark: word [k] of verse [a] ends at [ms] (a pause follows). */
export function tapEnd(doc, a, k, ms) {
  const v = doc.verses[verseIndex(doc, a)];
  const w = v?.[3].find((x) => x[0] === k);
  if (!w) return [];
  ms = Math.round(ms);
  if (ms <= w[1] + MIN_SPAN_MS) return [];
  w[2] = ms;
  return [a];
}
