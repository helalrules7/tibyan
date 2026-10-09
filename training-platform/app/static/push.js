// Web Push opt-in on /notifications. Needs a user gesture (iOS requires
// it, and the site must be opened from the Home Screen there).
(function () {
  var box = document.getElementById('push-box');
  if (!box) return;
  var csrf = box.getAttribute('data-csrf');
  var state = document.getElementById('push-state');
  var enableBtn = document.getElementById('push-enable');
  var disableBtn = document.getElementById('push-disable');
  var testBtn = document.getElementById('push-test');
  var msgs = {
    on: box.getAttribute('data-on'), off: box.getAttribute('data-off'),
    unsupported: box.getAttribute('data-unsupported'), ios: box.getAttribute('data-ios'),
    denied: box.getAttribute('data-denied'), server: box.getAttribute('data-server-off'),
    error: box.getAttribute('data-error'), sent: box.getAttribute('data-sent')
  };
  function say(text) { state.textContent = text; }
  function show(on) {
    enableBtn.hidden = on; disableBtn.hidden = !on; testBtn.hidden = !on;
    say(on ? msgs.on : msgs.off);
  }
  var ios = /iphone|ipad|ipod/i.test(navigator.userAgent) ||
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  var standalone = window.matchMedia('(display-mode: standalone)').matches || navigator.standalone === true;
  if (!('serviceWorker' in navigator) || !('PushManager' in window) || !('Notification' in window)) {
    say(ios && !standalone ? msgs.ios : msgs.unsupported);
    return;
  }
  if (box.getAttribute('data-enabled') !== '1') { say(msgs.server); return; }

  function b64ToBytes(s) {
    var pad = '='.repeat((4 - s.length % 4) % 4);
    var raw = atob((s + pad).replace(/-/g, '+').replace(/_/g, '/'));
    var out = new Uint8Array(raw.length);
    for (var i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
    return out;
  }
  function post(url, body) {
    return fetch(url, {
      method: 'POST', credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrf },
      body: JSON.stringify(body || {})
    });
  }
  var regPromise = navigator.serviceWorker.register('/sw.js', { scope: '/' });

  regPromise.then(function (reg) { return reg.pushManager.getSubscription(); })
    .then(function (sub) {
      // Re-send an existing subscription so the server knows this account.
      if (sub) post('/api/push/subscribe', { subscription: sub.toJSON() });
      show(!!sub);
    })
    .catch(function () { show(false); });

  enableBtn.addEventListener('click', function () {
    enableBtn.disabled = true;
    Notification.requestPermission().then(function (perm) {
      if (perm !== 'granted') { say(msgs.denied); enableBtn.disabled = false; return; }
      return fetch('/api/push/key', { credentials: 'same-origin' })
        .then(function (r) { return r.json(); })
        .then(function (k) {
          return regPromise.then(function (reg) {
            return reg.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: b64ToBytes(k.publicKey) });
          });
        })
        .then(function (sub) { return post('/api/push/subscribe', { subscription: sub.toJSON() }); })
        .then(function (r) { if (!r.ok) throw new Error('subscribe'); show(true); })
        .catch(function () { say(msgs.error); })
        .then(function () { enableBtn.disabled = false; });
    });
  });

  disableBtn.addEventListener('click', function () {
    regPromise.then(function (reg) { return reg.pushManager.getSubscription(); })
      .then(function (sub) {
        if (!sub) return;
        return post('/api/push/unsubscribe', { endpoint: sub.endpoint }).then(function () { return sub.unsubscribe(); });
      })
      .then(function () { show(false); })
      .catch(function () { say(msgs.error); });
  });

  testBtn.addEventListener('click', function () {
    post('/api/push/test').then(function () { say(msgs.sent); }).catch(function () { say(msgs.error); });
  });
})();
