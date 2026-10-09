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
