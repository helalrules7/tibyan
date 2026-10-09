// Collapsible top menu on small screens. Without JavaScript the menu
// simply stays expanded, so every link remains reachable.
(function () {
  var button = document.querySelector('.menu-toggle');
  var nav = document.getElementById('site-nav');
  if (!button || !nav) return;
  document.documentElement.classList.add('js-menu');
  button.hidden = false;
  button.addEventListener('click', function () {
    var open = button.getAttribute('aria-expanded') === 'true';
    button.setAttribute('aria-expanded', String(!open));
    nav.classList.toggle('open', !open);
  });
  document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape' && nav.classList.contains('open')) {
      button.setAttribute('aria-expanded', 'false');
      nav.classList.remove('open');
      button.focus();
    }
  });
})();

// Notification bell: unread count (and the admin link for admins).
(function () {
  var bell = document.querySelector('.bell');
  if (!bell || !window.fetch) return;
  var badge = bell.querySelector('.bell-count');
  var adminLink = document.querySelector('.nav-admin');
  function refresh() {
    fetch('/api/notifications/unread', { credentials: 'same-origin', cache: 'no-store' })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (data) {
        if (!data) return;
        if (adminLink) adminLink.hidden = !data.admin;
        if (data.count > 0) {
          badge.textContent = data.count > 99 ? '99+' : String(data.count);
          badge.hidden = false;
          bell.classList.add('has-unread');
        } else {
          badge.hidden = true;
          bell.classList.remove('has-unread');
        }
      })
      .catch(function () {});
  }
  refresh();
  setInterval(function () { if (!document.hidden) refresh(); }, 60000);
  document.addEventListener('visibilitychange', function () { if (!document.hidden) refresh(); });
})();
