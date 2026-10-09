# Tibyan — recitation-model training platform

Public contribution site for training the on-device Quran recitation model
(`nvidia-ar-fastconformer-ctc`, CC-BY-4.0). Volunteers read verses from
memory and donate their recording under CC BY 4.0.

## Stack

FastAPI + SQLAlchemy 2 + Jinja2, server-rendered. Works on SQLite locally
and MariaDB in production. Changa for the whole interface, IBM Plex Sans
Arabic for digits only (composite font family in `app/static/style.css`).
Both fonts are self-hosted, copied from the app's `assets/fonts/` (OFL).

**Quran verse text uses only the app's approved mushaf font** — `UthmanicHafs`
(`uthmanic_hafs_v20.ttf`, KFGQPC Hafs 2.0, shipped unmodified) — never the
UI font.

## Layout

- `app/main.py` — app, session middleware, static mount, routers.
- `app/routes/` — pages (index, dashboard, language) and auth.
- `app/templates/` — Jinja2 (RTL Arabic / LTR English).
- `app/static/` — CSS, logo, pattern, fonts.
- `app/config.py` — settings from environment / `.env`.

## Accounts (phase 1)

- Sign up with **email or phone** (either is enough; no OTP yet).
- Age from date of birth; minors need parental consent.
- CC-BY-4.0 consent is recorded per user (`consent_version`, `consent_at`).
- `password_hash` (bcrypt), PDO-free prepared queries, session cookies
  (HttpOnly, SameSite=Lax, Secure in prod), CSRF on every POST.

## Recording (phase 2)

- **Verse prompts:** `tools/export_verse_prompts.py` SELECTs surahs and
  `display_text` verbatim from the app's `assets/db/content.db` into
  `data/verses.json` (git-ignored). No verse text is typed or edited.
- `/record`: a 3-step wizard — pick a surah and an inclusive ayah range,
  read and record (with a
  live sound-level spectrum and clear icon buttons), then metadata and
  submit. The guide step explains that both correct and deliberately
  mistaken recitations are accepted, and how to record well.
- In-browser mic capture (MediaRecorder + Web Audio `AnalyserNode`) or
  file upload; speaker metadata (gender, age bracket, dialect, native
  language, environment, speed).
- Uploads are converted with ffmpeg to 16 kHz mono PCM WAV, checked
  (duration and mean volume) and stored under `media/` — outside the web
  root in production — never listed publicly.
- The model is a `Recording` row with `status=pending`.
- New recordings store their first and last ayah; older recordings with no
  end-ayah value continue to represent a single ayah. The end selector cannot
  precede the start or exceed the selected surah's ayah count. Accepted
  recording exports join the original source ayah texts in order. At startup,
  the app adds the nullable `ayah_end` column to an existing recordings table.

## Peer validation (phase 3)

- `/validate`: a logged-in volunteer reviews one pending recording at a
  time — listen (authenticated `/recordings/{id}/audio`), then accept or
  reject, or file a report.
- The dashboard links directly to this review flow and explains that
  volunteers vote to accept or reject recordings by comparing the audio
  with the displayed text.
- A recording is **accepted after two accept votes**, rejected after two
  reject votes, and **flagged** (taken out of the review queue) when
  reported. A volunteer cannot review or vote on their own recording, and
  votes once per recording.
- Dashboard lists the volunteer's own recordings with their status.

## Data rights (owner delete)

- The recording's owner can delete it at any time from the dashboard
  (`POST /recordings/{id}/delete`): the row, its votes and reports, and the
  audio file are all removed. Deleting removes it from the platform and
  from future exports.

## Admin and NeMo export (phase 4)

- `tools/make_admin.py <email-or-phone>` promotes an account to admin.
- `/admin` (admins only): counts per status, a paginated list of all
  recordings with audio review and direct accept/reject decisions; flagged
  recordings can also be restored to community review. An admin decision
  overrides community votes and can also decide the admin's own recording.
  The latest admin decision is stored as that admin's vote. Re-export accepted
  recordings after decisions to refresh an existing training manifest.
- Export copies accepted WAVs to `media/export/wavs/`, writes
  `media/export/manifest.jsonl` (NeMo format: `audio_filepath`, `duration`,
  `text`) and `media/export/SHA256SUMS`. The verse text comes verbatim from
  the verses loader. `GET /admin/manifest.jsonl` downloads the manifest.
- This project exports training data; it does not contain a NeMo training
  script, model checkpoint, or model-training command. Training itself needs
  to run in a separately provisioned training environment.

## Share image and meta tags

- `app/static/share.png` is the fixed 1200×630 social image referenced by
  the Open Graph and Twitter meta tags in `base.html`. `SITE_URL` controls
  the public image URL (default `https://train.altibyan.app`).
- The Coming Soon page uses `app/static/coming-soon-share.png` (1200×630)
  with its own Open Graph and Twitter tags in `app/templates/coming-soon.html`.
  It uses the Tibyan gold logo and self-hosted Changa typography.

## Local run

```sh
cd training-platform
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/uvicorn app.main:app --reload --port 8123
```

Set `SECRET_KEY` and `DATABASE_URL` in `.env` for production (see
`app/config.py` and `.env.example`). Defaults: SQLite `./training.db`,
`cookie_secure=false`.

## Tests

Install test-only dependencies with `pip install -r requirements-test.txt`,
then run `python -m pytest tests` (or `python -m unittest discover -s tests -v`).
Runner unit tests: `python -m unittest discover -s runner/tests`. The end-to-end workflow
test uses a temporary SQLite database and media directory plus synthetic tone
audio; it requires `ffmpeg` and `ffprobe` and never trains on that test data.

## Contact email

The contact form always stores submitted messages in the database for admins.
Email notifications use Resend SMTP. Verify `train.altibyan.app` in Resend and
add the exact DNS records Resend provides; this does not require replacing the
existing root-domain Namecheap forwarding MX records. The chosen sender is
`no-reply@train.altibyan.app`. Set `SMTP_PASS` to a Resend API key and `SMTP_TO`
to the chosen recipient in the server's private `.env`; the remaining SMTP
settings are shown in `.env.example`. Never commit `.env` or share the API key
in chat.

Resend's [SMTP documentation](https://resend.com/docs/send-with-smtp) lists
`smtp.resend.com`, port 587 with STARTTLS, and username `resend`. Its
[verified-domain guide](https://resend.com/docs/dashboard/domains/introduction)
explains domain verification and recommends using a sending subdomain.

If delivery fails, the form submission remains saved and the application logs
the message ID and delivery error without logging the SMTP password.

## Deploy (phase 5)

**Live:** `https://train.altibyan.app/` — Cloudflare A record `train` →
`217.76.57.212` (DNS only), HestiaCP web domain with Let's Encrypt and the
`tibyan-train` nginx proxy template (→ upstream `127.0.0.1:8001`), and the
app in a Docker container (`python:3.12-slim`, `--network host`,
`--restart unless-stopped`).

- Code and `Dockerfile` live at `/opt/tibyan-training/` on the server;
  `.env` (chmod 600) holds `SECRET_KEY`, `DATABASE_URL` (MariaDB
  `ahmedhelal_tibyan_training`), `SITE_URL`, `MEDIA_DIR=/app/media` and
  `VERSES_PATH=/app/data/verses.json`.
- Private recordings persist in `/home/ahmedhelal/tibyan-training-media`
  (mounted at `/app/media`), outside the web root.
- `data/verses.json` is generated locally by `tools/export_verse_prompts.py`
  and included in the build context; regenerate it when `content.db` changes.
- Promote an admin with `tools/make_admin.py <email-or-phone>` (run inside
  the container or a venv with the same DB access).

**Deploy flow (summary):**
1. Point the subdomain at `217.76.57.212` in Cloudflare (DNS only).
2. `v-add-web-domain ahmedhelal train.altibyan.app`,
   `v-change-web-domain-proxy-tpl … tibyan-train`,
   `v-add-letsencrypt-domain ahmedhelal train.altibyan.app`.
3. Upload code, build the image, run the container with the media mount.

The root site `altibyan.app` and `www.altibyan.app` use the same server and
show a Coming Soon page; `train.altibyan.app` remains the training platform.
Create Cloudflare DNS `A @` pointing to `217.76.57.212`; `www` may be a
CNAME to the root site. The root and `www` virtual hosts must proxy to the app
on `127.0.0.1:8001` and have a Let's Encrypt certificate. Keep any existing
mail DNS records unchanged. The app selects the Coming Soon page by request
hostname.

## Root site, privacy and headers (2026-10-09)

- `altibyan.app` "notify me" addresses go to the `notify_signups` table
  (`email`, `lang`, `wants_beta`). nginx limits `POST /notify` to 6/min per
  IP (`/etc/nginx/conf.d/tibyan-notify-ratelimit.conf`).
- Sign-up stores the birth year only (`users.birth_year`, nullable, added by
  `migrate_user_birth_year`); older rows keep `birth_date`/`phone`.
- `/voice` explains how recordings are used (CC BY 4.0) and deleted.
- Security headers live in the Hestia custom include
  `conf/web/<domain>/nginx.ssl.conf_security`; HSTS and HTTPS redirect use
  Hestia's own `v-add-web-domain-ssl-hsts` / `-ssl-force`.

## Admin panel, notifications and training (2026-10-09)

### Admin panel (`/admin`, admins only; Arabic RTL and English)

- **Dashboard** (`/admin`): recordings awaiting review (pending + reported),
  accepted minutes per voice group (men / women / children /
  unspecified, from the recording's gender and age bracket), volunteer
  accounts and contributors, open requests, the published model version
  and the latest training job. Below it, the review list (filter by
  status, owner, votes, metadata, audio, direct accept/reject); on phones
  each row becomes a card.
- **Requests & emails** (`/admin/requests`): «تواصل معنا» messages
  (read / replied, reply by email), beta-join requests from altibyan.app
  (mark "added to Google Play" / "added to TestFlight"), all «أبلغني»
  sign-ups with CSV export (`/admin/requests/notify.csv`, `?beta=1` for
  beta only; formula-safe), and data-deletion requests sent from the
  `/voice` form (open / done / declined, with the matching account and
  its recording count). Deletions themselves are carried out by hand.
- Additive migration `migrate_request_columns` adds nullable
  `read_at`/`replied_at` (contact) and `play_added_at`/
  `testflight_added_at` (notify sign-ups); new tables are created by
  `create_all`. Existing rows are never changed.

### Notification centre and Web Push

- Every signed-in user has `/notifications` and a bell with the unread
  count in the header. Rows are stored per user (`notifications`) and
  rendered in the reader's language.
- Events — admins: new recording awaiting review, new beta request, new
  contact message, new deletion request, training job finished / failed.
  Volunteers: their recording accepted / rejected (by votes or by an
  admin).
- Web Push uses VAPID (`pywebpush`). Keys: `python -m app.vapid >> .env`
  on the server (`VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`; never in git).
  Without keys push is off and the in-app centre still works.
- The service worker is `/sw.js` (scope `/`, push only, no offline cache);
  the PWA manifest is `/manifest.webmanifest` (standalone, 192/512 icons).
  `/notifications` has the opt-in, opt-out and test buttons; each browser
  subscription belongs to one user (`push_subscriptions`), and endpoints
  the push service reports gone (404/410) are deleted.
- **iPhone / iPad:** Web Push works only on iOS/iPadOS 16.4+ for a site
  added to the Home Screen (Safari → Share → Add to Home Screen) and
  opened from that icon; permission must be requested from a tap (the
  "Turn on notifications" button). The page shows these steps on iOS.

### Training jobs (decision: train on Ahmed's Mac, publish only on approval)

- `/admin/training`: freeze the **fixed held-out evaluation set** once
  (about `EVAL_FRACTION` of accepted recordings per voice group, chosen by
  a stable hash; at least `EVAL_MIN_RECORDINGS` accepted needed). Its
  recordings never train. Then **Start training**: base model (the
  official NVIDIA checkpoint or an earlier job) and hyperparameters
  (defaults: 5 epochs, lr 3e-5, batch 4, clips up to 30 s). The list of
  accepted recordings outside the evaluation set is frozen into the job.
- States: `queued → running → review → published → rolled_back`;
  `running → failed → queued` (retry); `queued/running → cancelled`;
  `review → rejected`. `/admin/training/<id>` shows live progress, stage,
  heartbeat and logs (polled every 5 s), then the WER/CER comparison per
  voice group between the published model and the candidate.
- **Runner API** (`/api/runner/*`, `Authorization: Bearer $RUNNER_TOKEN`
  only; 503 when the token is unset): `POST claim`, `GET jobs/<id>`,
  `POST jobs/<id>/progress` (logs, progress; answers `stop` when
  cancelled), `GET jobs/<id>/dataset` (train + eval entries with verse
  text), `GET jobs/<id>/audio/<rec>` (only recordings in that job's
  snapshot or evaluation set, only while it runs, only if still accepted;
  `X-Sha256` header), `PUT jobs/<id>/files/<name>?offset=N` (resumable
  chunks ≤ 16 MiB, under nginx's 60m body limit),
  `POST jobs/<id>/complete` (server re-checks sizes and SHA-256),
  `POST jobs/<id>/fail`. Uploads stay private under
  `media/training/jobs/<id>/files/`.
- **Approve & publish** (explicit checkbox) copies `model.int8.onnx` and
  `tokens.txt` into `<MIRROR_DIR>/<MODEL_NAME>/<next version>/` with
  `LICENSE.txt` (NVIDIA CC BY 4.0 + «متطوعو تبيان / Tibyan volunteers»
  CC BY 4.0) and `SHA256SUMS` (verified before the directory becomes
  visible), saves the old manifest as `manifest.v<old>.json`, writes the
  new `manifest.json` atomically and updates the model's top-level
  `SHA256SUMS`. Older version directories are kept. **Roll back** restores
  the previous manifest after checking its files. **Reject** deletes the
  uploads; nothing becomes public. Results of the fake runner can never
  be published.
- The runner itself is in [`runner/`](runner/README.md).
- Production mounts the mirror's `recitation-models` directory into the
  container (`MIRROR_DIR=/app/mirror`); published files are chowned to the
  mirror directory's owner.

## Rules

- Quran verse text (the reading prompts, phase 2) is exported verbatim
  from the app's verified `content.db`; it is never typed or edited by hand.
- Raw recordings are stored outside `public_html` and are never publicly
  listed; only consented, processed files reach the training mirror.
