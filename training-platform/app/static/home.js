/* altibyan.app home: the working reader and its player.
   Texts come verbatim from /api/quran/* (the app's own database); this file
   only shows them. Verse text is never animated, split or altered. */
(function () {
  'use strict';
  var reader = document.querySelector('[data-reader]');
  if (!reader) return;

  var S = JSON.parse(document.getElementById('x-strings').textContent);
  var $ = function (sel, root) { return (root || document).querySelector(sel); };
  var $$ = function (sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); };

  var page = $('[data-page]', reader), flow = $('[data-flow]', reader);
  var sheet = $('[data-sheet]', reader), memo = $('[data-memo]', reader);
  var dock = $('[data-dock]'), audio = $('[data-audio]'), fill = $('[data-fill]'), seek = $('[data-seek]');
  var dialog = $('[data-surahs]'), lead = $('[data-lead]');
  var msg = $('[data-dock-msg]');

  var state = {
    surah: Number(reader.dataset.surah), name: '', mode: 'read', picked: null,
    reciter: Number($('[data-reciter-select]').value),
    timing: null,          // {surah, reciter, url, ayahs:[[n,start,end]]} of what is loaded in <audio>
    playingAyah: null
  };

  function surahButton(id) { return $('[data-pick="' + id + '"]', dialog); }
  function surahName(id) {
    var b = surahButton(id);
    return S.ar ? S.surah + ' ' + b.dataset.nameAr : b.dataset.nameEn;
  }
  state.name = surahName(state.surah);

  function getJSON(url) {
    return fetch(url, { headers: { Accept: 'application/json' } }).then(function (r) {
      if (!r.ok) throw new Error(String(r.status));
      return r.json();
    });
  }
  function ayahEl(n) { return $('.x-ayah[data-n="' + n + '"]', flow); }

  /* ---------- modes: the three verbs ---------- */
  function setMode(mode) {
    state.mode = mode;
    reader.dataset.mode = mode;
    $$('[data-verbs] .x-verb').forEach(function (b) {
      var on = b.dataset.mode === mode;
      b.classList.toggle('is-on', on);
      b.setAttribute('aria-pressed', String(on));
    });
    lead.textContent = lead.dataset[mode];
    memo.hidden = mode !== 'memorize';
    if (mode !== 'reflect') closeSheet();
    if (mode === 'memorize') hideAll();
    if (mode === 'reflect') pick(state.picked || 1);
  }
  $$('[data-verbs] .x-verb').forEach(function (b) {
    b.addEventListener('click', function () {
      setMode(b.dataset.mode);
      if (window.matchMedia('(max-width: 900px)').matches) reader.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
    });
  });

  /* ---------- verses ---------- */
  function pick(n) {
    $$('.x-ayah.is-picked', flow).forEach(function (e) { e.classList.remove('is-picked'); });
    var el = ayahEl(n);
    if (!el) return;
    state.picked = n;
    el.classList.add('is-picked');
    if (state.mode === 'reflect') showTafsir(n);
  }
  function onAyah(el) {
    var n = Number(el.dataset.n);
    if (state.mode === 'memorize') { el.classList.toggle('is-shown'); return; }
    pick(n);
    if (isLoaded() && !audio.paused) seekToAyah(n);
  }
  flow.addEventListener('click', function (e) {
    var el = e.target.closest('.x-ayah');
    if (el) onAyah(el);
  });
  flow.addEventListener('keydown', function (e) {
    var el = e.target.closest('.x-ayah');
    if (el && (e.key === 'Enter' || e.key === ' ')) { e.preventDefault(); onAyah(el); }
  });
  function hideAll() { $$('.x-ayah.is-shown', flow).forEach(function (e) { e.classList.remove('is-shown'); }); }
  $('[data-hide-all]', reader).addEventListener('click', hideAll);

  /* ---------- tafsir ---------- */
  var tafsirTicket = 0;
  function showTafsir(n) {
    var ticket = ++tafsirTicket, text = $('[data-sheet-text]', sheet);
    $('[data-sheet-title]', sheet).textContent = S.tafsir + ' · ' + S.ayah + ' ' + n;
    text.textContent = S.loading;
    sheet.hidden = false;
    getJSON('/api/quran/tafsir/' + state.surah + '/' + n).then(function (d) {
      if (ticket === tafsirTicket) text.textContent = d.text;
    }).catch(function () {
      if (ticket === tafsirTicket) text.textContent = S.loadError;
    });
  }
  function closeSheet() { sheet.hidden = true; tafsirTicket++; }
  $('[data-close-sheet]', sheet).addEventListener('click', closeSheet);

  /* ---------- surah loading ---------- */
  function render(d) {
    var old = $('[data-basmala]', page);
    if (old) old.remove();
    if (d.basmala) {
      var b = document.createElement('p');
      b.className = 'x-basmala';
      b.setAttribute('data-basmala', '');
      b.textContent = d.basmala;
      page.insertBefore(b, flow);
    }
    flow.textContent = '';
    d.ayahs.forEach(function (a) {
      var s = document.createElement('span');
      s.className = 'x-ayah';
      s.setAttribute('role', 'button');
      s.tabIndex = 0;
      s.dataset.n = a.n;
      s.textContent = a.t;
      flow.appendChild(s);
      flow.appendChild(document.createTextNode(' '));
    });
  }
  function loadSurah(id, ayah) {
    page.classList.add('is-loading');
    return getJSON('/api/quran/surah/' + id).then(function (d) {
      state.surah = id;
      state.name = surahName(id);
      state.picked = null;
      reader.dataset.surah = id;
      $('[data-surah-name]', reader).textContent = state.name;
      $$('[data-pick]', dialog).forEach(function (b) { b.removeAttribute('aria-current'); });
      surahButton(id).setAttribute('aria-current', 'true');
      render(d);
      closeSheet();
      page.scrollTop = 0;
      if (ayah) { pick(ayah); var el = ayahEl(ayah); if (el) el.scrollIntoView({ block: 'center' }); }
      else if (state.mode === 'reflect') pick(1);
      markPlaying();
    }).catch(function () {
      flow.textContent = S.loadError;
    }).then(function () { page.classList.remove('is-loading'); });
  }

  /* ---------- surah picker ---------- */
  $('[data-open-surahs]', reader).addEventListener('click', function () {
    if (dialog.showModal) dialog.showModal(); else dialog.setAttribute('open', '');
    var cur = surahButton(state.surah);
    if (cur) cur.scrollIntoView({ block: 'center' });
  });
  function closeDialog() { if (dialog.close) dialog.close(); else dialog.removeAttribute('open'); }
  $('[data-close-surahs]', dialog).addEventListener('click', closeDialog);
  dialog.addEventListener('click', function (e) {
    if (e.target === dialog) closeDialog();
    var b = e.target.closest('[data-pick]');
    if (!b) return;
    closeDialog();
    var id = Number(b.dataset.pick), wasPlaying = isLoaded() && !audio.paused;
    loadSurah(id).then(function () { if (wasPlaying) play(1); });
  });
  var strip = function (s) { return s.replace(/[ً-ٰٟـ]/g, '').replace(/[أإآٱ]/g, 'ا').toLowerCase(); };
  $('[data-surah-filter]', dialog).addEventListener('input', function (e) {
    var q = strip(e.target.value.trim());
    $$('[data-pick]', dialog).forEach(function (b) {
      var hit = !q || b.dataset.pick === q || strip(b.dataset.nameAr).indexOf(q) > -1 || b.dataset.nameEn.toLowerCase().indexOf(q) > -1;
      b.parentNode.hidden = !hit;
    });
  });

  /* ---------- search ---------- */
  var form = $('[data-search]', reader), results = $('[data-results]', form), searchBtn = $('[data-toggle-search]', reader);
  var searchTimer = 0, searchTicket = 0;
  searchBtn.addEventListener('click', function () {
    form.hidden = !form.hidden;
    searchBtn.setAttribute('aria-expanded', String(!form.hidden));
    if (!form.hidden) $('input', form).focus();
  });
  form.addEventListener('submit', function (e) { e.preventDefault(); });
  $('input', form).addEventListener('input', function (e) {
    clearTimeout(searchTimer);
    var q = e.target.value.trim(), ticket = ++searchTicket;
    if (q.length < 2) { results.textContent = ''; return; }
    searchTimer = setTimeout(function () {
      getJSON('/api/quran/search?q=' + encodeURIComponent(q)).then(function (d) {
        if (ticket !== searchTicket) return;
        results.textContent = '';
        if (!d.results.length) { empty(S.noResults); return; }
        d.results.forEach(function (r) {
          var li = document.createElement('li'), b = document.createElement('button');
          var where = document.createElement('b'), t = document.createElement('span');
          b.type = 'button';
          where.textContent = (S.ar ? S.surah + ' ' + r.name_ar : r.name_en) + ' · ' + S.ayah + ' ' + r.n;
          t.textContent = r.t;
          t.lang = 'ar';
          b.appendChild(where); b.appendChild(t); li.appendChild(b); results.appendChild(li);
          b.addEventListener('click', function () {
            form.hidden = true;
            searchBtn.setAttribute('aria-expanded', 'false');
            if (state.mode === 'memorize') setMode('read');
            loadSurah(r.s, r.n);
          });
        });
      }).catch(function () { if (ticket === searchTicket) { results.textContent = ''; empty(S.loadError); } });
    }, 260);
  });
  function empty(text) {
    var li = document.createElement('li');
    li.className = 'x-empty';
    li.textContent = text;
    results.appendChild(li);
  }

  /* ---------- player ---------- */
  function isLoaded() { return !!state.timing && !!audio.getAttribute('src'); }
  function total() {
    if (isFinite(audio.duration) && audio.duration > 0) return audio.duration;
    var a = state.timing && state.timing.ayahs;
    return a && a.length ? a[a.length - 1][2] / 1000 : 0;
  }
  function ayahAt(sec) {
    var a = state.timing.ayahs, ms = sec * 1000, lo = 0, hi = a.length - 1, hit = null;
    while (lo <= hi) {
      var mid = (lo + hi) >> 1;
      if (ms < a[mid][1]) hi = mid - 1; else { hit = a[mid]; lo = mid + 1; }
    }
    return hit ? hit[0] : null;
  }
  function startOf(n) {
    var a = state.timing.ayahs;
    for (var i = 0; i < a.length; i++) if (a[i][0] === n) return a[i][1] / 1000;
    return 0;
  }
  function drawTicks() {
    var bar = $('[data-bar]', dock), a = state.timing.ayahs, end = a.length ? a[a.length - 1][2] : 0;
    $$('i', bar).forEach(function (t) { t.remove(); });
    if (!end || a.length > 300) return;
    a.forEach(function (t) {
      if (t[0] < 2) return;
      var i = document.createElement('i');
      i.style.insetInlineStart = (t[1] / end * 100) + '%';
      bar.insertBefore(i, seek);
    });
  }
  function setIcons(playing) {
    document.body.classList.toggle('is-playing', playing);
    $$('[data-play]').forEach(function (b) {
      $('[data-icon-play]', b).toggleAttribute('hidden', playing);    // SVG has no .hidden property
      $('[data-icon-pause]', b).toggleAttribute('hidden', !playing);
    });
  }
  function markReciter() {
    $$('[data-reciter]').forEach(function (b) {
      b.setAttribute('aria-pressed', String(isLoaded() && Number(b.dataset.reciter) === state.reciter));
    });
    $('[data-reciter-select]').value = String(state.reciter);
  }
  function markPlaying() {
    $$('.x-ayah.is-playing', flow).forEach(function (e) { e.classList.remove('is-playing'); });
    if (!isLoaded() || state.timing.surah !== state.surah || state.playingAyah == null) return;
    var el = ayahEl(state.playingAyah);
    if (!el) return;
    el.classList.add('is-playing');
    // follow the recitation inside the reader only (never scroll the whole page)
    var top = el.offsetTop - page.offsetTop, view = page.clientHeight;
    if (top < page.scrollTop || top + el.offsetHeight > page.scrollTop + view) page.scrollTop = Math.max(0, top - view / 3);
  }
  function showNow() {
    $('[data-now-surah]', dock).textContent = surahName(state.timing.surah);
    var n = state.playingAyah;
    $('[data-now-ayah]', dock).textContent = n ? S.ayah + ' ' + n : S.opening;
  }
  function load(surah, reciter) {
    msg.textContent = '';
    return getJSON('/api/quran/timing/' + reciter + '/' + surah).then(function (d) {
      state.timing = { surah: surah, reciter: reciter, url: d.url, ayahs: d.ayahs };
      state.reciter = reciter;
      state.playingAyah = null;
      audio.src = d.url;
      dock.hidden = false;
      document.body.classList.add('has-dock');
      drawTicks(); markReciter(); showNow();
    });
  }
  function play(fromAyah) {
    var need = !isLoaded() || state.timing.surah !== state.surah || state.timing.reciter !== state.reciter;
    var ready = need ? load(state.surah, state.reciter) : Promise.resolve();
    return ready.then(function () {
      if (fromAyah && fromAyah > 1) seekToAyah(fromAyah);
      return audio.play();
    }).catch(function (e) {
      if (e && e.name === 'AbortError') return;
      dock.hidden = false;
      msg.textContent = S.audioError;
      setIcons(false);
    });
  }
  function seekToAyah(n) {
    var t = startOf(n);
    try { audio.currentTime = t; } catch (e) {
      audio.addEventListener('loadedmetadata', function once() { audio.removeEventListener('loadedmetadata', once); audio.currentTime = t; });
    }
  }
  function toggle() {
    if (isLoaded() && state.timing.surah === state.surah && state.timing.reciter === state.reciter) {
      if (audio.paused) audio.play().catch(function () {}); else audio.pause();
    } else play(state.picked);
  }
  $$('[data-play]').forEach(function (b) {
    b.addEventListener('click', function () {
      // the dock button drives what is loaded; the reader button drives the open surah
      if (b.closest('[data-dock]') && isLoaded()) { if (audio.paused) audio.play().catch(function () {}); else audio.pause(); }
      else toggle();
    });
  });
  $$('[data-reciter]').forEach(function (b) {
    b.addEventListener('click', function () {
      var id = Number(b.dataset.reciter);
      if (isLoaded() && id === state.reciter && state.timing.surah === state.surah) { toggle(); return; }
      state.reciter = id;
      play(state.picked);
    });
  });
  $('[data-reciter-select]').addEventListener('change', function (e) {
    var at = state.playingAyah, surah = state.timing ? state.timing.surah : state.surah;
    state.reciter = Number(e.target.value);
    load(surah, state.reciter).then(function () { if (at) seekToAyah(at); return audio.play(); }).catch(function () { msg.textContent = S.audioError; });
  });
  function step(dir) {
    if (!isLoaded()) return;
    var a = state.timing.ayahs, cur = state.playingAyah == null ? 0 : state.playingAyah;
    var idx = 0;
    for (var i = 0; i < a.length; i++) if (a[i][0] === cur) idx = i;
    var next = a[Math.min(a.length - 1, Math.max(0, idx + dir))];
    if (next) audio.currentTime = next[1] / 1000;
  }
  $('[data-prev]', dock).addEventListener('click', function () { step(-1); });
  $('[data-next]', dock).addEventListener('click', function () { step(1); });
  $('[data-stop]', dock).addEventListener('click', function () {
    audio.pause();
    audio.removeAttribute('src');
    audio.load();
    state.timing = null; state.playingAyah = null;
    dock.hidden = true;
    document.body.classList.remove('has-dock');
    markReciter(); markPlaying(); setIcons(false);
  });
  seek.addEventListener('input', function () {
    var t = total();
    if (isLoaded() && t) audio.currentTime = seek.value / 1000 * t;
  });
  audio.addEventListener('play', function () { setIcons(true); msg.textContent = ''; });
  audio.addEventListener('pause', function () { setIcons(false); });
  audio.addEventListener('ended', function () { setIcons(false); });
  audio.addEventListener('error', function () {
    if (!audio.getAttribute('src')) return;
    msg.textContent = S.audioError;
    setIcons(false);
  });
  audio.addEventListener('timeupdate', function () {
    if (!isLoaded()) return;
    var t = total(), now = audio.currentTime;
    if (t) { fill.style.width = (now / t * 100) + '%'; seek.value = Math.round(now / t * 1000); }
    var n = ayahAt(now);
    if (n === 0) n = null;
    if (n !== state.playingAyah) { state.playingAyah = n; showNow(); markPlaying(); }
  });

  /* ---------- the «why» statement lights up line by line as it is read ---------- */
  var why = $('[data-reveal]');
  if (why && window.matchMedia('(prefers-reduced-motion: no-preference)').matches) {
    var lines = $$('span', why), raf = 0;
    var paint = function () {
      raf = 0;
      var r = why.getBoundingClientRect(), vh = window.innerHeight;
      var p = Math.min(1, Math.max(0, (vh * 0.85 - r.top) / (vh * 0.55)));
      lines.forEach(function (el, i) {
        var o = Math.min(1, Math.max(0.16, p * lines.length - i));
        el.style.setProperty('--o', o.toFixed(2));
      });
    };
    window.addEventListener('scroll', function () { if (!raf) raf = requestAnimationFrame(paint); }, { passive: true });
    paint();
  }

  /* ---------- share ---------- */
  var share = $('[data-share]');
  if (share) share.addEventListener('click', function () {
    var url = share.dataset.url;
    if (navigator.share) { navigator.share({ title: document.title, url: url }).catch(function () {}); return; }
    if (navigator.clipboard) navigator.clipboard.writeText(url).then(function () { share.textContent = share.dataset.copied; });
  });
})();
