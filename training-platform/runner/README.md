# Tibyan training runner (the Mac)

Fine-tunes the app's recitation model — NVIDIA's Arabic FastConformer
(`nvidia/stt_ar_fastconformer_hybrid_large_pcd_v1.0`, CC BY 4.0), CTC
branch — on volunteer recordings approved on https://train.altibyan.app,
then exports it for sherpa-onnx (int8) exactly like the mirror's
`convert/export_nemo_ctc.py`, evaluates it against the published model,
and uploads the results. **Nothing reaches the app until an admin presses
"Approve & publish"** in `/admin/training/<job>`.

Training runs on Apple Silicon (MPS) and falls back to the CPU. The
server only prepares data and stores results.

## How a job flows

1. Admin, once: `/admin/training` → **Freeze the evaluation set** (about
   10 % of accepted recordings per voice group; they never train, so every
   model is scored on the same clips).
2. Admin: **Start training** (base model + hyperparameters). The list of
   accepted recordings is frozen into the job.
3. Runner: `claim` → downloads the dataset manifest and the audio (token
   only, never public; checksums verified) → fine-tunes → exports
   `model.int8.onnx` + `tokens.txt` → transcribes the held-out set with
   sherpa-onnx using **both** the published model and the new one → WER /
   CER per voice group → resumable chunked upload → `complete`.
4. Admin gets a notification, compares, then **Approve & publish** (new
   version directory on the mirror, `SHA256SUMS` verified, attribution to
   NVIDIA and «متطوعو تبيان / Tibyan volunteers», `manifest.json` updated,
   old version kept) or **Reject** (uploads deleted; nothing public).
   **Roll back** points `manifest.json` at the previous version again.

## Setup (once)

Needs Python 3.12 and about 5 GB of disk for the venv and models.
Everything stays inside the venv; nothing is installed system-wide.

```sh
mkdir -p ~/tibyan-runner && cd ~/tibyan-runner
uv venv -p 3.12 venv            # or: python3.12 -m venv venv
uv pip install -p venv/bin/python \
  -r /path/to/training-platform/runner/requirements-train.txt \
  -e /path/to/training-platform/runner
```

`requirements-train.txt` pins the versions this was tested with (PyTorch
2.14 with MPS, NeMo 3.0, onnxruntime, sherpa-onnx).

The token: Ahmed copies `RUNNER_TOKEN` from the server's
`/opt/tibyan-training/.env` into a private file on the Mac (never into the
repo):

```sh
mkdir -p ~/.config/tibyan-runner
cat > ~/.config/tibyan-runner/env <<'EOF'
TIBYAN_RUNNER_URL=https://train.altibyan.app
TIBYAN_RUNNER_TOKEN=<paste the token>
EOF
chmod 600 ~/.config/tibyan-runner/env
venv/bin/tibyan-runner check     # platform OK, torch + MPS, nemo, sherpa_onnx
```

Other settings (environment or the same file): `TIBYAN_RUNNER_NAME`
(default: the Mac's host name), `TIBYAN_RUNNER_HOME` (default
`~/Library/Application Support/tibyan-runner`), `TIBYAN_RUNNER_DEVICE`
(`auto` | `mps` | `cpu`), `TIBYAN_RUNNER_THREADS` (default: half the
cores), `TIBYAN_RUNNER_NICE` (default 10), `TIBYAN_RUNNER_POLL_SECONDS`
(default 120).

## Run

```sh
venv/bin/tibyan-runner poll           # keep polling for jobs
venv/bin/tibyan-runner poll --once    # run one job if queued, then exit
venv/bin/tibyan-runner status         # local job state
```

As a LaunchAgent (starts at login, restarts after a crash, background
priority): copy `launchd/app.altibyan.tibyan-runner.plist` to
`~/Library/LaunchAgents/`, replace `YOUR_USER`, then

```sh
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/app.altibyan.tibyan-runner.plist
launchctl bootout   gui/$(id -u)/app.altibyan.tibyan-runner     # stop (checkpoints first)
tail -f ~/Library/Logs/tibyan-runner.log
```

## Safe to interrupt, resumable

- Ctrl-C / `SIGTERM` (also `launchctl bootout`) finishes the current step,
  saves a checkpoint (`jobs/<id>/ckpt.pt`) and exits; the job stays
  "running" on the platform. The next `poll` by the same runner name
  resumes it: finished stages are recorded in `jobs/<id>/state.json`,
  audio already downloaded is reused after a checksum check, training
  restarts from the checkpoint, and uploads continue from the size the
  server already has. A second Ctrl-C exits immediately.
- If a runner goes silent for an hour (`RUNNER_STALE_SECONDS`), another
  runner may take the job over.
- Admin "Cancel" is seen at the next progress report; the runner stops
  and deletes the job's audio.
- The Mac stays usable: `nice 10`, background QoS and low-priority I/O
  under launchd, and PyTorch limited to half the cores.

## Privacy

Volunteer audio is downloaded only with the runner token, only for the
job's frozen snapshot and evaluation set, only while the job runs, and
only if each recording is still accepted (an owner's deletion takes it
out). The runner deletes the job's audio once the job completes, fails or
is cancelled. Kept on the Mac: the fine-tuned `model.nemo` (needed to
continue training from a published job) and the exported files.

## Notes and limits

- Training targets are the verse text from `verses.json` (exported
  verbatim from `content.db`) normalised to plain letters (no diacritics,
  common Uthmani spellings mapped to their usual forms, see
  `textnorm.py`) — the same normalisation the app applies before
  matching. So the fine-tuned model writes undiacritised text.
- Only the encoder and the CTC decoder train; the transducer branch inside
  `model.nemo` is untouched and not exported.
- Clips longer than `max_duration_s` (default 30 s) are skipped in
  training. Evaluation cuts long clips into ~8 s segments at the quietest
  point, like the app's `SpeechSegmentBuffer`.
- `--max-steps N` stops training after N optimiser steps (smoke tests).
- `--fake` / `--dry-run` replaces NeMo with a fake trainer to test the
  whole pipeline. Its "model" is random bytes; the platform refuses to
  publish fake results.
