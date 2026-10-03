// The waveform with the verse and word boxes, drawn on one canvas. Time
// runs from right to left, like the text. Edges are dragged with a mouse,
// a pen or a finger; an empty area pans; a tap seeks.

const RULER = 18;
const VERSE_TOP = 18;
const VERSE_H = 24;
const WAVE_TOP = 46;
const LABEL_H = 34;

function css(name) {
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
}

export function formatMs(ms) {
  const neg = ms < 0;
  ms = Math.abs(Math.round(ms));
  const m = Math.floor(ms / 60000);
  const s = Math.floor((ms % 60000) / 1000);
  const r = ms % 1000;
  return `${neg ? '-' : ''}${m}:${String(s).padStart(2, '0')}.${String(r).padStart(3, '0')}`;
}

export class Timeline {
  /**
   * [host] supplies: state() -> {doc, selected, bad, changed, now, text(a, k)},
   * onSeek(ms), onSelect(sel), onDrag(phase, target, ms), onView().
   */
  constructor(canvas, host) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.host = host;
    this.t0 = 0;
    this.span = 8000;
    this.duration = 0;
    this.peaks = null;
    this.peaksRate = 100;
    this.drag = null;
    this.dirty = true;
    this._resize();
    new ResizeObserver(() => this._resize()).observe(canvas);
    canvas.addEventListener('pointerdown', (e) => this._down(e));
    canvas.addEventListener('pointermove', (e) => this._move(e));
    canvas.addEventListener('pointerup', (e) => this._up(e));
    canvas.addEventListener('pointercancel', () => { this.drag = null; });
    canvas.addEventListener('wheel', (e) => this._wheel(e), { passive: false });
    matchMedia('(prefers-color-scheme: dark)').addEventListener?.('change', () => this.invalidate());
  }

  invalidate() {
    this.dirty = true;
  }

  setAudio(duration, peaks, rate = 100) {
    this.duration = duration;
    this.peaks = peaks;
    this.peaksRate = rate;
    this.invalidate();
  }

  /** Shows [start, end] with a margin. */
  show(start, end, margin = 0.15) {
    const len = Math.max(end - start, 400);
    this.span = Math.min(Math.max(len * (1 + 2 * margin), 1500), Math.max(this.duration, 1500));
    this.t0 = start - (this.span - len) / 2;
    this._clamp();
  }

  /** Keeps [ms] in view, turning the page as the playhead reaches the edge. */
  follow(ms) {
    if (ms < this.t0 || ms > this.t0 + this.span * 0.92) {
      this.t0 = ms - this.span * 0.08;
      this._clamp();
    }
  }

  zoom(factor, aroundMs = this.t0 + this.span / 2) {
    const rel = (aroundMs - this.t0) / this.span;
    this.span = Math.min(Math.max(this.span * factor, 300), Math.max(this.duration || 60000, 1000));
    this.t0 = aroundMs - rel * this.span;
    this._clamp();
    this.host.onView?.();
  }

  _clamp() {
    const max = Math.max((this.duration || 0) - this.span, 0);
    this.t0 = Math.min(Math.max(this.t0, 0), max || this.t0);
    if (this.t0 < 0) this.t0 = 0;
    this.invalidate();
  }

  _resize() {
    const dpr = window.devicePixelRatio || 1;
    const r = this.canvas.getBoundingClientRect();
    this.w = Math.max(r.width, 100);
    this.h = Math.max(r.height, 120);
    this.canvas.width = Math.round(this.w * dpr);
    this.canvas.height = Math.round(this.h * dpr);
    this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    this.invalidate();
  }

  x(ms) {
    return this.w - ((ms - this.t0) / this.span) * this.w;
  }

  t(x) {
    return this.t0 + ((this.w - x) / this.w) * this.span;
  }

  draw() {
    if (!this.dirty) return;
    this.dirty = false;
    const { ctx, w, h } = this;
    const st = this.host.state();
    const c = {
      bg: css('--bg'), ink: css('--ink'), muted: css('--muted'), line: css('--line'), verse: css('--verse'),
      word: css('--word'), sel: css('--sel'), bad: css('--bad'), wave: css('--wave'), changed: css('--changed'),
    };
    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = c.bg;
    ctx.fillRect(0, 0, w, h);
    const waveBottom = h - LABEL_H;
    const t1 = this.t0 + this.span;

    // ruler
    const steps = [100, 200, 500, 1000, 2000, 5000, 10000, 30000, 60000, 300000];
    const step = steps.find((s) => (s / this.span) * w >= 70) || 600000;
    ctx.fillStyle = c.muted;
    ctx.strokeStyle = c.line;
    ctx.font = '11px ui-monospace, monospace';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    for (let tt = Math.ceil(this.t0 / step) * step; tt <= t1; tt += step) {
      const x = this.x(tt);
      ctx.beginPath();
      ctx.moveTo(x, RULER - 5);
      ctx.lineTo(x, waveBottom);
      ctx.globalAlpha = 0.35;
      ctx.stroke();
      ctx.globalAlpha = 1;
      ctx.fillText(formatMs(tt).replace(/\.?0+$/, '').replace(/:$/, ''), x, 2);
    }

    // waveform
    const mid = (WAVE_TOP + waveBottom) / 2;
    const half = (waveBottom - WAVE_TOP) / 2 - 2;
    ctx.fillStyle = c.wave;
    if (this.peaks) {
      for (let x = 0; x < w; x++) {
        const a = this.t(x + 1);
        const b = this.t(x);
        let i0 = Math.floor((a * this.peaksRate) / 1000);
        let i1 = Math.ceil((b * this.peaksRate) / 1000);
        if (i1 <= i0) i1 = i0 + 1;
        let m = 0;
        for (let i = Math.max(i0, 0); i < Math.min(i1, this.peaks.length); i++) if (this.peaks[i] > m) m = this.peaks[i];
        const hh = (m / 255) * half;
        if (hh > 0.3) ctx.fillRect(x, mid - hh, 1, hh * 2);
      }
    } else {
      ctx.fillRect(0, mid, w, 1);
    }

    if (!st.doc) return;
    const sel = st.selected;
    // verses
    for (const [a, s, e, words] of st.doc.verses) {
      if (e < this.t0 || s > t1) continue;
      const xs = this.x(s);
      const xe = this.x(e);
      const isSel = sel?.kind === 'verse' && sel.verse === a;
      const bad = st.bad.has(`${a}`);
      ctx.fillStyle = bad ? c.bad : c.verse;
      ctx.globalAlpha = isSel ? 0.55 : 0.28;
      ctx.fillRect(xe, VERSE_TOP, xs - xe, VERSE_H);
      ctx.globalAlpha = 1;
      ctx.strokeStyle = isSel ? c.sel : bad ? c.bad : c.verse;
      ctx.lineWidth = isSel ? 2 : 1;
      ctx.strokeRect(xe + 0.5, VERSE_TOP + 0.5, xs - xe - 1, VERSE_H - 1);
      ctx.fillStyle = c.ink;
      ctx.font = '600 12px "Plex Arabic", system-ui, sans-serif';
      ctx.textAlign = 'right';
      ctx.textBaseline = 'middle';
      const right = Math.min(xs, w);
      if (right - Math.max(xe, 0) > 48) ctx.fillText(`آية ${a}`, right - 4, VERSE_TOP + VERSE_H / 2);
      // words
      for (const [k, ws, we] of words) {
        if (we < this.t0 || ws > t1) continue;
        const x0 = this.x(we);
        const x1 = this.x(ws);
        const wsel = sel?.kind === 'word' && sel.verse === a && sel.word === k;
        const wbad = st.bad.has(`${a}:${k}`);
        const changed = st.changed.has(`${a}:${k}`);
        const col = wsel ? c.sel : wbad ? c.bad : changed ? c.changed : c.word;
        ctx.fillStyle = col;
        ctx.globalAlpha = wsel ? 0.3 : 0.14;
        ctx.fillRect(x0, WAVE_TOP, x1 - x0, waveBottom - WAVE_TOP);
        ctx.globalAlpha = 1;
        ctx.fillRect(x1 - 2, WAVE_TOP, 2, waveBottom - WAVE_TOP + 6); // start edge (right)
        ctx.globalAlpha = 0.6;
        ctx.fillRect(x0, WAVE_TOP + 10, 1.5, waveBottom - WAVE_TOP - 10); // end edge
        ctx.globalAlpha = 1;
        if (wsel) {
          ctx.fillRect(x1 - 6, WAVE_TOP - 2, 6, 10);
          ctx.fillRect(x0, WAVE_TOP + 8, 5, 10);
        }
        const label = st.text(a, k);
        if (label && x1 - x0 > 14) {
          ctx.save();
          ctx.beginPath();
          ctx.rect(x0 + 1, waveBottom, x1 - x0 - 2, LABEL_H);
          ctx.clip();
          ctx.fillStyle = wsel ? c.sel : c.ink;
          ctx.font = '20px "KFGQPC Hafs", serif';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.direction = 'rtl';
          ctx.fillText(label, (x0 + x1) / 2, waveBottom + LABEL_H / 2 + 2);
          ctx.restore();
        }
      }
    }
    // playhead
    if (st.now != null && st.now >= this.t0 && st.now <= t1) {
      const x = this.x(st.now);
      ctx.fillStyle = c.ink;
      ctx.fillRect(x - 1, 0, 2, h);
    }
  }

  _hit(px, py, touch) {
    const st = this.host.state();
    if (!st.doc) return null;
    const grab = touch ? 14 : 7;
    const ms = this.t(px);
    const inVerseLane = py >= VERSE_TOP && py < VERSE_TOP + VERSE_H + 2;
    let best = null;
    const consider = (target, edge, x) => {
      const d = Math.abs(px - x);
      if (d <= grab && (!best || d < best.d)) best = { target, edge, d };
    };
    for (const [a, s, e, words] of st.doc.verses) {
      if (e < this.t0 - this.span || s > this.t0 + 2 * this.span) continue;
      if (inVerseLane) {
        consider({ kind: 'verse', verse: a }, 'start', this.x(s));
        consider({ kind: 'verse', verse: a }, 'end', this.x(e));
      } else {
        for (const [k, ws, we] of words) {
          consider({ kind: 'word', verse: a, word: k }, 'start', this.x(ws));
          consider({ kind: 'word', verse: a, word: k }, 'end', this.x(we));
        }
      }
    }
    // a selected item's edge wins a tie, so a boundary of two words picks the selected one
    const sel = st.selected;
    if (best && sel) {
      for (const [a, s, e, words] of st.doc.verses) {
        if (sel.kind === 'word' && a === sel.verse && !inVerseLane) {
          const w = words.find((x) => x[0] === sel.word);
          if (w) {
            if (Math.abs(px - this.x(w[1])) <= grab + 3) best = { target: { ...sel }, edge: 'start' };
            else if (Math.abs(px - this.x(w[2])) <= grab + 3) best = { target: { ...sel }, edge: 'end' };
          }
        }
        void s; void e;
      }
    }
    if (best) return { type: 'edge', ...best };
    for (const [a, s, e, words] of st.doc.verses) {
      if (ms < s || ms >= e) continue;
      if (inVerseLane) return { type: 'box', target: { kind: 'verse', verse: a } };
      const w = words.find((x) => x[1] <= ms && ms < x[2]);
      if (w) return { type: 'box', target: { kind: 'word', verse: a, word: w[0] } };
    }
    return null;
  }

  _pos(e) {
    const r = this.canvas.getBoundingClientRect();
    return [e.clientX - r.left, e.clientY - r.top];
  }

  _down(e) {
    const [px, py] = this._pos(e);
    const hit = this._hit(px, py, e.pointerType !== 'mouse');
    this.canvas.setPointerCapture(e.pointerId);
    if (hit?.type === 'edge') {
      this.drag = { kind: 'edge', target: hit.target, edge: hit.edge };
      this.host.onSelect(hit.target, false, true);
      this.host.onDrag('start', hit.target, hit.edge, this.t(px));
    } else {
      this.drag = { kind: 'pan', x: px, t0: this.t0, moved: false, hit };
    }
  }

  _move(e) {
    const [px, py] = this._pos(e);
    if (!this.drag) {
      const hit = this._hit(px, py, false);
      this.canvas.style.cursor = hit?.type === 'edge' ? 'ew-resize' : hit ? 'pointer' : 'crosshair';
      return;
    }
    if (this.drag.kind === 'edge') {
      this.host.onDrag('move', this.drag.target, this.drag.edge, this.t(px));
      this.invalidate();
    } else {
      const dx = px - this.drag.x;
      if (Math.abs(dx) > 4) this.drag.moved = true;
      if (this.drag.moved) {
        this.t0 = this.drag.t0 + (dx / this.w) * this.span;
        this._clamp();
        this.host.onView?.();
      }
    }
  }

  _up(e) {
    const [px] = this._pos(e);
    const d = this.drag;
    this.drag = null;
    if (!d) return;
    if (d.kind === 'edge') {
      this.host.onDrag('end', d.target, d.edge, this.t(px));
    } else if (!d.moved) {
      if (d.hit?.type === 'box') this.host.onSelect(d.hit.target, true);
      else this.host.onSeek(this.t(px));
    }
    this.invalidate();
  }

  _wheel(e) {
    e.preventDefault();
    const [px] = this._pos(e);
    if (e.ctrlKey || e.metaKey) {
      this.zoom(Math.exp(e.deltaY * 0.002), this.t(px));
    } else {
      // Down scrolls on in time; sideways follows the right-to-left axis.
      const d = Math.abs(e.deltaX) > Math.abs(e.deltaY) ? -e.deltaX : e.deltaY;
      this.t0 += (d / this.w) * this.span;
      this._clamp();
      this.host.onView?.();
    }
  }
}
