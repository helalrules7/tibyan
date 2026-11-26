/* altibyan.app home: the working reader and its player.
   Texts come verbatim from /api/quran/* (the app's own database); this file
   only shows them. Verse text is never animated, split or altered. */
(function () {
  'use strict';
  var $ = function (sel, root) { return (root || document).querySelector(sel); };
  var $$ = function (sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); };

  /* ---------- share (works without the reader) ---------- */
  var share = $('[data-share]');
  if (share) share.addEventListener('click', function () {
    var url = share.dataset.url;
    if (navigator.share) { navigator.share({ title: document.title, url: url }).catch(function () {}); return; }
    if (navigator.clipboard) navigator.clipboard.writeText(url).then(function () { share.textContent = share.dataset.copied; });
  });

  /* ---------- real screens: pick a feature, see its screenshot ---------- */
  var shotImg = $('[data-shot-img]'), shotView = $('#shot-view');
  $$('[data-shots] [role="tab"]').forEach(function (tab) {
    var show = function () {
      if (tab.getAttribute('aria-selected') === 'true') return;
      $$('[data-shots] [role="tab"]').forEach(function (t) { t.setAttribute('aria-selected', String(t === tab)); });
      shotView.setAttribute('aria-labelledby', tab.id);
      var next = new Image();
      shotImg.classList.add('is-swapping');
      next.onload = next.onerror = function () {
        if (tab.getAttribute('aria-selected') !== 'true') return;
        shotImg.src = tab.dataset.shot;
        shotImg.alt = tab.dataset.alt;
        shotImg.classList.remove('is-swapping');
      };
      next.src = tab.dataset.shot;
    };
    tab.addEventListener('click', show);
    tab.addEventListener('mouseenter', show);
    tab.addEventListener('focus', show);
  });

  /* ---------- the promise lights up line by line as it is read ---------- */
  var why = $('[data-reveal]');
  if (why && window.matchMedia('(prefers-reduced-motion: no-preference)').matches) {
    var lines = $$('span', why), raf = 0;
    var paint = function () {
      raf = 0;
      var r = why.getBoundingClientRect(), vh = window.innerHeight;
      var p = Math.min(1, Math.max(0, (vh * 0.95 - r.top) / (vh * 0.4)));
      lines.forEach(function (el, i) {
        el.style.setProperty('--o', Math.min(1, Math.max(0.22, p * lines.length - i)).toFixed(2));
      });
    };
    window.addEventListener('scroll', function () { if (!raf) raf = requestAnimationFrame(paint); }, { passive: true });
    paint();
  }

  var reader = $('[data-reader]');
  if (!reader) return;

  var S = JSON.parse($('#x-strings').textContent);
  var page = $('[data-page]', reader), flow = $('[data-flow]', reader), index = $('[data-surahs]', reader);
  var dock = $('[data-dock]'), audio = $('[data-audio]'), fill = $('[data-fill]'), seek = $('[data-seek]');
  var msg = $('[data-dock-msg]');
  var phone = window.matchMedia('(max-width: 720px)');

  var state = {
    surah: Number(reader.dataset.surah), mode: 'read', picked: null,
    reciter: Number($('[data-reciter-select]').value),
    timing: null,          // {surah, reciter, url, ayahs:[[n,start,end]]} of what is loaded in <audio>
    playingAyah: null
  };
  var texts = {};          // surah id -> {n: verse text}, as received
  texts[state.surah] = {};
  $$('.x-ayah', flow).forEach(function (e) { texts[state.surah][e.dataset.n] = e.textContent; });

  function surahButton(id) { return $('[data-pick="' + id + '"]', index); }
  function surahName(id) {
    var b = surahButton(id);
    return S.ar ? S.surah + ' ' + b.dataset.nameAr : b.dataset.nameEn;
  }
  function getJSON(url) {
    return fetch(url, { headers: { Accept: 'application/json' } }).then(function (r) {
      if (!r.ok) throw new Error(String(r.status));
      return r.json();
    });
  }
  function ayahEl(n) { return $('.x-ayah[data-n="' + n + '"]', flow); }

  /* ---------- the side pane ---------- */
  function setPane(view, open) {
    reader.dataset.pane = view;
    reader.classList.toggle('is-pane-open', !!open);
  }
  function restPane() {          // what the pane shows when nothing asks for it
    if (state.mode === 'reflect') setPane('tafsir', !phone.matches || state.picked != null);
    else if (state.mode === 'memorize') setPane('memo', true);
    else setPane('index', false);
  }
  $('[data-close-pane]', reader).addEventListener('click', function () {
    reader.classList.remove('is-pane-open');
    if (state.mode !== 'read') reader.dataset.pane = state.mode === 'reflect' ? 'tafsir' : 'memo';
  });
  $('[data-open-surahs]', reader).addEventListener('click', function () {
    var showing = reader.dataset.pane === 'index' && (!phone.matches || reader.classList.contains('is-pane-open'));
    if (showing && (phone.matches || state.mode !== 'read')) { restPane(); if (phone.matches) reader.classList.remove('is-pane-open'); return; }
    setPane('index', true);
    var cur = surahButton(state.surah);
    if (cur) cur.scrollIntoView({ block: 'center' });
  });

  /* ---------- modes ---------- */
  function setMode(mode) {
    state.mode = mode;
    reader.dataset.mode = mode;
    $$('[data-verbs] .x-verb', reader).forEach(function (b) {
      var on = b.dataset.mode === mode;
      b.classList.toggle('is-on', on);
      b.setAttribute('aria-pressed', String(on));
    });
    if (mode === 'memorize') hideAll();
    restPane();
    if (mode === 'reflect' && !phone.matches) pick(state.picked || 1);
  }
  $$('[data-verbs] .x-verb', reader).forEach(function (b) {
    b.addEventListener('click', function () { setMode(b.dataset.mode); });
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
    if (state.mode === 'memorize') { el.classList.toggle('is-shown'); countShown(); return; }
    pick(n);
    if (isLoaded() && !audio.paused && state.timing.surah === state.surah) seekToAyah(n);
  }
  flow.addEventListener('click', function (e) {
    var el = e.target.closest('.x-ayah');
    if (el) onAyah(el);
  });
  flow.addEventListener('keydown', function (e) {
    var el = e.target.closest('.x-ayah');
    if (el && (e.key === 'Enter' || e.key === ' ')) { e.preventDefault(); onAyah(el); }
  });
  function countShown() {
    $('[data-memo-shown]', reader).textContent = $$('.x-ayah.is-shown', flow).length;
    $('[data-memo-total]', reader).textContent = $$('.x-ayah', flow).length;
  }
  function hideAll() { $$('.x-ayah.is-shown', flow).forEach(function (e) { e.classList.remove('is-shown'); }); countShown(); }
  $('[data-hide-all]', reader).addEventListener('click', hideAll);

  /* ---------- tafsir: the verse, then its interpretation ---------- */
  var tafsirTicket = 0;
  function showTafsir(n) {
    var ticket = ++tafsirTicket, text = $('[data-tafsir-text]', reader);
    $('[data-tafsir-ref]', reader).textContent = S.tafsir + ' · ' + S.ayah + ' ' + n;
    $('[data-tafsir-ayah]', reader).textContent = (texts[state.surah] || {})[n] || '';
    text.textContent = S.loading;
    setPane('tafsir', true);
    getJSON('/api/quran/tafsir/' + state.surah + '/' + n).then(function (d) {
      if (ticket === tafsirTicket) text.textContent = d.text;
    }).catch(function () {
      if (ticket === tafsirTicket) text.textContent = S.loadError;
    });
  }
  function clearTafsir() {
    tafsirTicket++;
    $('[data-tafsir-ref]', reader).textContent = '';
    $('[data-tafsir-ayah]', reader).textContent = '';
    $('[data-tafsir-text]', reader).textContent = S.tapForTafsir;
  }

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
    texts[d.id] = {};
    d.ayahs.forEach(function (a) {
      texts[d.id][a.n] = a.t;
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
      state.picked = null;
      reader.dataset.surah = id;
      $('[data-surah-name]', reader).textContent = surahName(id);
      $$('[data-pick]', index).forEach(function (b) { b.removeAttribute('aria-current'); });
      surahButton(id).setAttribute('aria-current', 'true');
      render(d);
      clearTafsir();
      countShown();
      page.scrollTop = 0;
      restPane();
      if (ayah) { pick(ayah); var el = ayahEl(ayah); if (el) page.scrollTop = Math.max(0, el.offsetTop - page.offsetTop - 40); }
      else if (state.mode === 'reflect' && !phone.matches) pick(1);
      markPlaying();
    }).catch(function () {
      flow.textContent = S.loadError;
    }).then(function () { page.classList.remove('is-loading'); });
  }

  /* ---------- surah index ---------- */
  index.addEventListener('click', function (e) {
    var b = e.target.closest('[data-pick]');
    if (!b) return;
    var id = Number(b.dataset.pick), wasPlaying = isLoaded() && !audio.paused;
    loadSurah(id).then(function () { if (wasPlaying) play(1); });
  });
  var strip = function (s) { return s.replace(/[ً-ٰٟـ]/g, '').replace(/[أإآٱ]/g, 'ا').toLowerCase(); };
  $('[data-surah-filter]', index).addEventListener('input', function (e) {
    var q = strip(e.target.value.trim());
    $$('[data-pick]', index).forEach(function (b) {
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
      // only the buttons that speak for what is loaded show «pause»
      var mine = playing && (b.closest('[data-dock]') || b.closest('[data-stage]') || state.timing.surah === state.surah);
      $('[data-icon-play]', b).toggleAttribute('hidden', !!mine);    // SVG has no .hidden property
      $('[data-icon-pause]', b).toggleAttribute('hidden', !mine);
    });
    var label = $('[data-stage-play-label]');
    label.textContent = playing ? label.dataset.pauseText : label.dataset.playText;
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
    var ref = $('[data-stage-ref]'), text = $('[data-stage-text]'), hint = $('[data-stage-hint]');
    if (!isLoaded()) {
      ref.textContent = ref.dataset.idle; text.textContent = ''; hint.hidden = false;
      return;
    }
    var n = state.playingAyah, name = surahName(state.timing.surah), where = n ? S.ayah + ' ' + n : S.opening;
    $('[data-now-surah]', dock).textContent = name;
    $('[data-now-ayah]', dock).textContent = where;
    $('[data-surah-select]').value = String(state.timing.surah);
    ref.textContent = name + ' · ' + where;
    text.textContent = n ? ((texts[state.timing.surah] || {})[n] || '') : '';
    hint.hidden = true;
  }
  $('[data-stage-ref]').dataset.idle = $('[data-stage-ref]').textContent;

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
  function resumeOrPause() { if (audio.paused) audio.play().catch(function () {}); else audio.pause(); }
  function toggle() {
    if (isLoaded() && state.timing.surah === state.surah && state.timing.reciter === state.reciter) resumeOrPause();
    else play(state.picked);
  }
  $$('[data-play]').forEach(function (b) {
    b.addEventListener('click', function () {
      // the dock and the stage drive what is loaded; the reader button drives the open surah
      if ((b.closest('[data-dock]') || b.closest('[data-stage]')) && isLoaded()) resumeOrPause();
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
  $('[data-surah-select]').addEventListener('change', function (e) {
    loadSurah(Number(e.target.value)).then(function () { play(1); });
  });
  $('[data-volume]').addEventListener('input', function (e) { audio.volume = e.target.value / 100; });
  function step(dir) {
    if (!isLoaded()) return;
    var a = state.timing.ayahs, cur = state.playingAyah == null ? 0 : state.playingAyah, idx = 0;
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
    setIcons(false); markReciter(); markPlaying(); showNow();
  });
  seek.addEventListener('input', function () {
    var t = total();
    if (isLoaded() && t) audio.currentTime = seek.value / 1000 * t;
  });
  function buffering(on) {
    dock.classList.toggle('is-buffering', on);
    if (on) msg.textContent = S.buffering; else if (msg.textContent === S.buffering) msg.textContent = '';
  }
  audio.addEventListener('waiting', function () { buffering(true); });
  audio.addEventListener('loadstart', function () { if (audio.getAttribute('src')) buffering(true); });
  audio.addEventListener('playing', function () { buffering(false); });
  audio.addEventListener('canplay', function () { buffering(false); });
  audio.addEventListener('play', function () { setIcons(true); });
  audio.addEventListener('pause', function () { setIcons(false); });
  audio.addEventListener('ended', function () { setIcons(false); });
  audio.addEventListener('error', function () {
    if (!audio.getAttribute('src')) return;
    dock.classList.remove('is-buffering');
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

  phone.addEventListener('change', restPane);
  countShown();
})();
