// node --test apps/timing-editor/test
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

import {
  dumps, validate, History, moveWordEdge, moveVerseEdge, tapStart, tapEnd, diff, flatWords, wordAt, clone,
} from '../js/model.js';

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, '..', '..', '..');
const cases = JSON.parse(readFileSync(join(repo, 'tools/tests/timing_cases.json'), 'utf8'));
const key = (i) => `${i.level}:${i.code}:${i.verse ?? ''}:${i.word || ''}`;

test('the shared cases give the same issues as the Python checks', () => {
  for (const c of cases.cases) {
    const got = validate(c.doc, cases.slug, cases.surah, c.counts ?? cases.counts, c.duration_ms).map(key).sort();
    assert.deepEqual(got, c.expect, c.name);
  }
});

test('dumps writes the files exactly as the repository holds them', () => {
  const reciters = JSON.parse(readFileSync(join(repo, 'data/timing/reciters.json'), 'utf8')).reciters;
  let n = 0;
  for (const r of reciters.filter((x) => x.publish)) {
    const dir = join(repo, 'data/timing', r.slug);
    for (const f of readdirSync(dir).filter((x) => /^\d{3}\.json$/.test(x))) {
      const text = readFileSync(join(dir, f), 'utf8');
      assert.equal(dumps(JSON.parse(text)), text, `${r.slug}/${f}`);
      n++;
    }
  }
  assert.ok(n >= 114);
});

const sample = () => ({
  format: 1, reciter: 't', surah: 1,
  verses: [
    [1, 1000, 2000, [[1, 1000, 1400], [2, 1400, 2000]]],
    [2, 2000, 4000, [[1, 2000, 2500], [2, 2600, 3000], [3, 3100, 3990]]],
  ],
});

test('a linked boundary moves both words, and undo and redo restore it', () => {
  const doc = sample();
  const h = new History(doc);
  h.apply('move', [1], (d) => moveWordEdge(d, 1, 2, 'start', 1450));
  assert.deepEqual(doc.verses[0][3], [[1, 1000, 1450], [2, 1450, 2000]]);
  h.undo();
  assert.deepEqual(doc.verses[0][3], [[1, 1000, 1400], [2, 1400, 2000]]);
  h.redo();
  assert.deepEqual(doc.verses[0][3][1], [2, 1450, 2000]);
});

test('an edge never crosses its neighbour', () => {
  const doc = sample();
  moveWordEdge(doc, 2, 2, 'start', 1000, false);
  assert.equal(doc.verses[1][3][1][1], 2500); // stops at the previous word's end
  moveWordEdge(doc, 2, 2, 'end', 9000, false);
  assert.equal(doc.verses[1][3][1][2], 3100);
  moveWordEdge(doc, 2, 1, 'end', 100, false);
  assert.equal(doc.verses[1][3][0][2], 2020);
});

test('verse edges move together when they touch', () => {
  const doc = sample();
  moveVerseEdge(doc, 2, 'start', 1950);
  assert.equal(doc.verses[0][2], 1950);
  assert.equal(doc.verses[1][1], 1950);
});

test('tapping creates the words of an untimed verse one by one', () => {
  const doc = sample();
  doc.verses[1][3] = [];
  assert.deepEqual(tapStart(doc, 2, 1, 2010), [2]);
  assert.deepEqual(tapStart(doc, 2, 3, 2500), [], 'out of order is refused');
  tapStart(doc, 2, 2, 2600);
  tapStart(doc, 2, 3, 3100);
  tapEnd(doc, 2, 3, 3950);
  assert.deepEqual(doc.verses[1][3], [[1, 2010, 2600], [2, 2600, 3100], [3, 3100, 3950]]);
  const issues = validate(doc, 't', 1, [2, 3]).filter((i) => i.level === 'error');
  assert.deepEqual(issues, []);
});

test('diff names the changed verses and words', () => {
  const base = sample();
  const doc = clone(base);
  doc.verses[1][3][2][2] = 3980;
  const d = diff(base, doc);
  assert.deepEqual(d.verses, [2]);
  assert.deepEqual([...d.words], ['2:3']);
});

test('wordAt finds the word sounding, and nothing in a pause', () => {
  const flat = flatWords(sample());
  assert.equal(wordAt(flat, 1500).word, 2);
  assert.equal(wordAt(flat, 3050), null);
  assert.equal(wordAt(flat, 10), null);
});
