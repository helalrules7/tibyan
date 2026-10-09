// Live status for a training job page: polls status.json every 5 s while
// the job is queued or running, appends new log lines.
(function () {
  var root = document.getElementById('job-live');
  if (!root) return;
  var url = root.getAttribute('data-url');
  var lastId = parseInt(root.getAttribute('data-last-log') || '0', 10);
  var bar = document.getElementById('job-bar');
  var pct = document.getElementById('job-pct');
  var stage = document.getElementById('job-stage');
  var status = document.getElementById('job-status');
  var hb = document.getElementById('job-heartbeat');
  var log = document.getElementById('job-log');
  var agoTpl = root.getAttribute('data-ago');
  var active = root.getAttribute('data-active') === '1';
  function tick() {
    fetch(url + '?after=' + lastId, { credentials: 'same-origin', cache: 'no-store' })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (d) {
        if (!d) return;
        var p = Math.round(d.progress * 1000) / 10;
        bar.style.width = p + '%';
        pct.textContent = p + '%';
        stage.textContent = d.stage || '—';
        status.textContent = d.status_label;
        status.className = 'job-badge job-' + d.status;
        if (hb) hb.textContent = d.heartbeat_age == null ? '—' : agoTpl.replace('{s}', d.heartbeat_age);
        var stick = log.scrollTop + log.clientHeight >= log.scrollHeight - 8;
        d.logs.forEach(function (l) {
          log.appendChild(document.createTextNode(l.line + '\n'));
          lastId = l.id;
        });
        if (stick) log.scrollTop = log.scrollHeight;
        if (d.status !== 'queued' && d.status !== 'running' && active) {
          active = false;
          setTimeout(function () { location.reload(); }, 1200);
        }
      })
      .catch(function () {});
  }
  log.scrollTop = log.scrollHeight;
  if (active) setInterval(function () { if (!document.hidden) tick(); }, 5000);
})();
