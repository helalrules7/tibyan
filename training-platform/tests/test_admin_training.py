"""Admin panel, notification centre, Web Push, runner API, training job
state machine, and publish / rollback to the model mirror."""
from __future__ import annotations

import hashlib
import json
import tempfile
import unittest
from datetime import date
from pathlib import Path
from unittest.mock import patch

from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from starlette.middleware.sessions import SessionMiddleware

from app import push, training, verses
from app.config import settings
from app.db import Base
from app.deps import get_db
from app.models import (
    ContactMessage,
    DeletionRequest,
    EvalSetItem,
    Notification,
    NotifySignup,
    PushSubscription,
    Recording,
    TrainingJob,
    User,
)
from app.routes import (
    admin,
    admin_requests,
    admin_training,
    auth,
    contact,
    notifications,
    notify,
    pages,
    record,
    runner,
    validate,
)
from app.security import hash_password
from test_platform_workflow import TEST_VERSES, csrf_from

PASSWORD = "test-only-password-42"
TOKEN = "test-runner-token-not-a-secret"
OLD_MODEL = b"old-model-bytes"
OLD_TOKENS = b"<blk> 0\n"


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class AdminTrainingTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.media = root / "media"
        self.mirror = root / "mirror"
        self._old = {
            k: getattr(settings, k)
            for k in ("media_dir", "mirror_dir", "runner_token", "vapid_public_key",
                      "vapid_private_key", "eval_min_recordings", "runner_chunk_bytes")
        }
        settings.media_dir = str(self.media)
        settings.mirror_dir = str(self.mirror)
        settings.runner_token = TOKEN
        settings.vapid_public_key = "test-public-key"
        settings.vapid_private_key = "test-private-key"
        settings.eval_min_recordings = 5
        settings.runner_chunk_bytes = 64

        self.engine = create_engine(
            "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool
        )
        Base.metadata.create_all(self.engine)
        self.Session = sessionmaker(bind=self.engine, autoflush=False)
        self.verses_patch = patch.object(verses, "verses_data", return_value=TEST_VERSES)
        self.verses_patch.start()

        self.pushed: list[tuple[dict, dict]] = []
        self.push_status = 201
        push._sender = lambda sub, payload: (self.pushed.append((sub, payload)), self.push_status)[1]
        push.synchronous = True
        push._session_factory = self.Session

        self.app = FastAPI()
        self.app.add_middleware(SessionMiddleware, secret_key="test-only", https_only=False)
        for r in (pages, auth, record, validate, admin, contact, notify, admin_requests,
                  admin_training, notifications, runner):
            self.app.include_router(r.router)

        def override_get_db():
            db = self.Session()
            try:
                yield db
            finally:
                db.close()

        self.app.dependency_overrides[get_db] = override_get_db
        self._make_mirror()

    def tearDown(self):
        push._sender = None
        push.synchronous = False
        push._session_factory = None
        self.verses_patch.stop()
        for k, v in self._old.items():
            setattr(settings, k, v)
        self.engine.dispose()
        self.tmp.cleanup()

    # ---------- helpers -------------------------------------------------
    def _make_mirror(self):
        model = self.mirror / settings.model_name
        (model / "1").mkdir(parents=True)
        (model / "1" / "model.int8.onnx").write_bytes(OLD_MODEL)
        (model / "1" / "tokens.txt").write_bytes(OLD_TOKENS)
        (model / "LICENSE.txt").write_text("CC BY 4.0 full text\n")
        manifest = {
            "id": settings.model_name, "version": "1", "license": "CC-BY-4.0",
            "engine": "sherpa-onnx-nemo-ctc", "language": "ar", "attribution": "NVIDIA",
            "files": [
                {"name": "model.int8.onnx", "url": "https://x/1/model.int8.onnx",
                 "sha256": sha(OLD_MODEL), "bytes": len(OLD_MODEL)},
                {"name": "tokens.txt", "url": "https://x/1/tokens.txt",
                 "sha256": sha(OLD_TOKENS), "bytes": len(OLD_TOKENS)},
            ],
        }
        (model / "manifest.json").write_text(json.dumps(manifest))
        (model / "SHA256SUMS").write_text(
            f"{sha(OLD_MODEL)}  1/model.int8.onnx\n{sha(OLD_TOKENS)}  1/tokens.txt\n"
            f"{sha((model / 'manifest.json').read_bytes())}  manifest.json\n"
        )
        self.model_dir = model

    def user(self, email, is_admin=False):
        with self.Session() as db:
            u = User(email=email, password_hash=hash_password(PASSWORD),
                     birth_date=date(1990, 1, 1), consent_ccby=True, consent_version="t",
                     is_admin=is_admin)
            db.add(u)
            db.commit()
            return u.id

    def client(self, email=None):
        c = TestClient(self.app)
        if email:
            page = c.get("/login")
            r = c.post("/login", data={"identifier": email, "password": PASSWORD,
                                       "csrf": csrf_from(page)}, follow_redirects=False)
            self.assertEqual(r.status_code, 303)
        return c

    def recording(self, owner, status="accepted", gender="male", age="18_40", ms=2000):
        with self.Session() as db:
            rec = Recording(user_id=owner, surah=1, ayah=1, ayah_end=2, audio_path="",
                            audio_duration_ms=ms, gender=gender, age_bracket=age, status=status)
            db.add(rec)
            db.commit()
            path = self.media / "recordings" / f"{rec.id}.wav"
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b"RIFF-fake-wav-" + str(rec.id).encode())
            rec.audio_path = f"recordings/{rec.id}.wav"
            db.commit()
            return rec.id

    def csrf(self, c, path="/notifications"):
        return csrf_from(c.get(path))

    def auth(self, token=TOKEN, name="mac-test"):
        return {"Authorization": f"Bearer {token}", "X-Runner-Name": name}

    def notifications_of(self, uid):
        with self.Session() as db:
            return [n.kind for n in db.query(Notification).filter(Notification.user_id == uid)]

    def seed_dataset(self, owner, n=12):
        groups = [("male", "18_40"), ("female", "18_40"), ("male", "under_18")]
        return [self.recording(owner, gender=groups[i % 3][0], age=groups[i % 3][1])
                for i in range(n)]

    # ---------- permissions ---------------------------------------------
    def test_admin_pages_require_admin(self):
        self.user("vol@example.test")
        self.user("adm@example.test", is_admin=True)
        anon, vol, adm = self.client(), self.client("vol@example.test"), self.client("adm@example.test")
        for path in ("/admin", "/admin/requests", "/admin/training", "/admin/requests/notify.csv"):
            self.assertEqual(anon.get(path, follow_redirects=False).headers["location"], "/login")
            self.assertEqual(vol.get(path, follow_redirects=False).headers["location"], "/dashboard")
            self.assertEqual(adm.get(path).status_code, 200, path)
        self.assertEqual(vol.get("/admin/training/1/status.json").status_code, 403)
        self.assertEqual(anon.get("/api/notifications/unread").status_code, 401)
        self.assertEqual(vol.get("/api/notifications/unread").json(), {"count": 0, "admin": False})
        self.assertTrue(adm.get("/api/notifications/unread").json()["admin"])

    def test_runner_api_needs_the_token(self):
        self.user("adm@example.test", is_admin=True)
        adm = self.client("adm@example.test")
        self.assertEqual(adm.post("/api/runner/claim").status_code, 401)  # session is not enough
        c = self.client()
        self.assertEqual(c.post("/api/runner/claim", headers=self.auth("wrong")).status_code, 401)
        self.assertEqual(c.post("/api/runner/claim", headers={"Authorization": TOKEN}).status_code, 401)
        self.assertEqual(c.get("/api/runner/ping", headers=self.auth()).json()["ok"], True)
        settings.runner_token = ""
        self.assertEqual(c.get("/api/runner/ping", headers=self.auth()).status_code, 503)

    def test_volunteer_cannot_start_or_publish_training(self):
        self.user("vol@example.test")
        vol = self.client("vol@example.test")
        token = self.csrf(vol)
        r = vol.post("/admin/training/jobs", data={"csrf": token}, follow_redirects=False)
        self.assertEqual(r.headers["location"], "/dashboard")
        r = vol.post("/admin/training/1/action", data={"csrf": token, "action": "publish",
                                                       "confirm": "yes"}, follow_redirects=False)
        self.assertEqual(r.headers["location"], "/dashboard")
        with self.Session() as db:
            self.assertEqual(db.query(TrainingJob).count(), 0)

    # ---------- notification fan-out -------------------------------------
    def test_events_fan_out_to_admins_and_owner(self):
        a1 = self.user("a1@example.test", is_admin=True)
        a2 = self.user("a2@example.test", is_admin=True)
        vol = self.user("vol@example.test")
        with self.Session() as db:
            db.add(PushSubscription(user_id=a1, endpoint_hash="h1", endpoint="https://push.example/1",
                                    p256dh="k" * 40, auth="a" * 16, lang="en"))
            db.commit()

        c = self.client()
        page = c.get("/contact")
        c.post("/contact", data={"name": "Sara", "email": "s@example.test",
                                 "message": "hello", "csrf": csrf_from(page)})
        page = c.get("/voice")
        c.post("/voice/delete-request", data={"email": "s@example.test", "scope": "account",
                                              "csrf": csrf_from(page)})
        # Honeypot: stored nowhere, nobody notified.
        c.post("/voice/delete-request", data={"email": "bot@example.test", "website": "x",
                                              "csrf": csrf_from(page)})
        token = csrf_from(c.get("/contact"))
        c.post("/notify", data={"email": "n@example.test", "csrf": token})
        c.post("/notify", data={"email": "b@example.test", "beta": "1", "csrf": token})

        for admin_id in (a1, a2):
            self.assertEqual(
                sorted(self.notifications_of(admin_id)),
                ["beta_request", "contact_message", "deletion_request"],
            )
        self.assertEqual(self.notifications_of(vol), [])
        with self.Session() as db:
            self.assertEqual(db.query(DeletionRequest).count(), 1)
        # One push per event to a1's single (English) subscription.
        self.assertEqual(len(self.pushed), 3)
        self.assertTrue(all(p["lang"] == "en" for _, p in self.pushed))
        self.assertIn("Sara", self.pushed[0][1]["body"])

        # Admin decision notifies the owner, in-app.
        rid = self.recording(vol, status="pending")
        adm = self.client("a1@example.test")
        adm.post(f"/admin/recordings/{rid}/decision",
                 data={"verdict": "accept", "csrf": self.csrf(adm, "/admin")})
        self.assertEqual(self.notifications_of(vol), ["recording_accepted"])

    def test_community_votes_notify_owner(self):
        owner = self.user("owner@example.test")
        self.user("r1@example.test")
        self.user("r2@example.test")
        rid = self.recording(owner, status="pending")
        for email in ("r1@example.test", "r2@example.test"):
            c = self.client(email)
            c.post(f"/validate/{rid}", data={"verdict": "reject", "csrf": self.csrf(c, "/validate")})
        self.assertEqual(self.notifications_of(owner), ["recording_rejected"])

    def test_gone_push_subscription_is_removed(self):
        a = self.user("a@example.test", is_admin=True)
        with self.Session() as db:
            db.add(PushSubscription(user_id=a, endpoint_hash="h", endpoint="https://push.example/x",
                                    p256dh="k" * 40, auth="a" * 16))
            db.commit()
        self.push_status = 410
        c = self.client()
        c.post("/contact", data={"name": "N", "email": "n@example.test", "message": "m",
                                 "csrf": csrf_from(c.get("/contact"))})
        with self.Session() as db:
            self.assertEqual(db.query(PushSubscription).count(), 0)

    # ---------- push subscription flow -----------------------------------
    def test_subscribe_test_push_and_unsubscribe(self):
        self.user("a@example.test", is_admin=True)
        c = self.client("a@example.test")
        token = self.csrf(c)
        sub = {"endpoint": "https://fcm.googleapis.com/fcm/send/abc",
               "keys": {"p256dh": "B" * 87, "auth": "x" * 22}}
        self.assertEqual(c.post("/api/push/subscribe", json={"subscription": sub}).status_code, 400)
        r = c.post("/api/push/subscribe", json={"subscription": sub}, headers={"X-CSRF-Token": token})
        self.assertEqual(r.json(), {"ok": True})
        # Same endpoint again: still one row.
        c.post("/api/push/subscribe", json={"subscription": sub}, headers={"X-CSRF-Token": token})
        bad = dict(sub, endpoint="http://insecure.example/x")
        self.assertEqual(c.post("/api/push/subscribe", json={"subscription": bad},
                                headers={"X-CSRF-Token": token}).status_code, 400)
        with self.Session() as db:
            self.assertEqual(db.query(PushSubscription).count(), 1)

        r = c.post("/api/push/test", headers={"X-CSRF-Token": token})
        self.assertEqual(r.json()["subscriptions"], 1)
        self.assertEqual(len(self.pushed), 1)
        self.assertEqual(self.pushed[0][0]["endpoint"], sub["endpoint"])
        self.assertEqual(c.get("/api/notifications/unread").json()["count"], 1)
        page = c.get("/notifications")
        self.assertIn("push-box", page.text)
        c.post("/notifications/read-all", data={"csrf": token})
        self.assertEqual(c.get("/api/notifications/unread").json()["count"], 0)

        r = c.post("/api/push/unsubscribe", json={"endpoint": sub["endpoint"]},
                   headers={"X-CSRF-Token": token})
        self.assertEqual(r.json()["removed"], 1)

    def test_service_worker_and_manifest_are_served_at_root(self):
        c = self.client()
        sw = c.get("/sw.js")
        self.assertEqual(sw.status_code, 200)
        self.assertIn("showNotification", sw.text)
        self.assertEqual(sw.headers["service-worker-allowed"], "/")
        m = c.get("/manifest.webmanifest").json()
        self.assertEqual(m["display"], "standalone")
        self.assertEqual({i["sizes"] for i in m["icons"]}, {"192x192", "512x512"})

    # ---------- requests & emails ----------------------------------------
    def test_requests_page_states_and_csv(self):
        self.user("a@example.test", is_admin=True)
        with self.Session() as db:
            db.add(ContactMessage(name="N", email="n@example.test", message="m"))
            db.add(NotifySignup(email="=cmd@example.test", lang="ar", wants_beta=True))
            db.add(DeletionRequest(email="d@example.test", scope="recordings"))
            db.commit()
        c = self.client("a@example.test")
        token = self.csrf(c, "/admin/requests")
        c.post("/admin/requests/contact/1", data={"state": "replied", "csrf": token})
        c.post("/admin/requests/beta/1", data={"platform": "play", "value": "1", "csrf": token})
        c.post("/admin/requests/deletion/1", data={"state": "done", "csrf": token})
        with self.Session() as db:
            m = db.get(ContactMessage, 1)
            self.assertIsNotNone(m.read_at)
            self.assertIsNotNone(m.replied_at)
            self.assertIsNotNone(db.get(NotifySignup, 1).play_added_at)
            self.assertIsNone(db.get(NotifySignup, 1).testflight_added_at)
            self.assertEqual(db.get(DeletionRequest, 1).status, "done")
        for tab in ("contact", "beta", "notify", "deletion"):
            self.assertEqual(c.get(f"/admin/requests?tab={tab}").status_code, 200)
        csv_text = c.get("/admin/requests/notify.csv").text
        self.assertIn("'=cmd@example.test", csv_text)  # formula injection neutralised
        self.assertIn("email,lang,wants_beta", csv_text)

    def test_dashboard_shows_minutes_by_voice_group(self):
        a = self.user("a@example.test", is_admin=True)
        self.recording(a, gender="female", ms=90_000)
        self.recording(a, age="under_18", ms=30_000)
        c = self.client("a@example.test")
        stats = admin.dashboard_stats(self.Session())
        self.assertEqual(stats["accepted_minutes"]["women"], 1.5)
        self.assertEqual(stats["accepted_minutes"]["children"], 0.5)
        self.assertEqual(stats["model_version"], "1")
        page = c.get("/admin")
        self.assertIn("dash-grid", page.text)

    # ---------- state machine --------------------------------------------
    def test_state_machine(self):
        job = TrainingJob(status="queued", params="{}", dataset="{}")
        for bad in ("review", "published", "failed", "rolled_back"):
            with self.assertRaises(training.InvalidTransition):
                training.transition(job, bad)
        for step in ("running", "review", "published", "rolled_back"):
            training.transition(job, step)
        with self.assertRaises(training.InvalidTransition):
            training.transition(job, "published")
        job.status = "failed"
        training.transition(job, "queued")
        job.status = "rejected"
        with self.assertRaises(training.InvalidTransition):
            training.transition(job, "queued")
        with self.assertRaises(ValueError):
            training.clean_params({"epochs": "0"})
        self.assertEqual(training.clean_params({"epochs": "3"})["epochs"], 3)

    def test_eval_set_is_frozen_stratified_and_held_out(self):
        a = self.user("a@example.test", is_admin=True)
        ids = self.seed_dataset(a, 12)
        c = self.client("a@example.test")
        token = self.csrf(c, "/admin/training")
        r = c.post("/admin/training/jobs", data={"csrf": token}, follow_redirects=False)
        self.assertEqual(r.headers["location"], "/admin/training")  # no eval set yet
        c.post("/admin/training/eval-set", data={"csrf": token})
        with self.Session() as db:
            held = {i.recording_id for i in db.query(EvalSetItem)}
        self.assertEqual(len(held), 3)  # one per voice group (4 each, 10%)
        # Freezing again does not change it.
        c.post("/admin/training/eval-set", data={"csrf": token})
        with self.Session() as db:
            self.assertEqual(db.query(EvalSetItem).count(), 3)
        r = c.post("/admin/training/jobs", data={"csrf": token, "epochs": "2"},
                   follow_redirects=False)
        self.assertEqual(r.headers["location"], "/admin/training/1")
        with self.Session() as db:
            job = db.get(TrainingJob, 1)
            self.assertEqual(set(training.job_train_ids(job)), set(ids) - held)
            self.assertEqual(training.job_params(job)["epochs"], 2)
        self.assertEqual(c.get("/admin/training/1").status_code, 200)

    # ---------- runner end to end + publish / rollback -------------------
    def _queued_job(self):
        a = self.user("a@example.test", is_admin=True)
        vol = self.user("v@example.test")
        ids = self.seed_dataset(vol, 12)
        rejected = self.recording(vol, status="rejected")
        with self.Session() as db:
            training.freeze_eval_set(db, a)
            job = training.create_job(db, a, "nvidia-base", {})
            return job.id, ids, rejected

    def _upload(self, c, job_id, name, data):
        size = 0
        while size < len(data):
            chunk = data[size:size + settings.runner_chunk_bytes]
            r = c.put(f"/api/runner/jobs/{job_id}/files/{name}?offset={size}", content=chunk,
                      headers=self.auth())
            self.assertEqual(r.status_code, 200, r.text)
            size = r.json()["size"]

    def _run_to_review(self, new_model=b"new-model-" * 20, tokens=b"<blk> 0\n"):
        job_id, ids, rejected = self._queued_job()
        c = self.client()
        claim = c.post("/api/runner/claim", headers=self.auth()).json()
        self.assertEqual(claim["job"]["id"], job_id)
        self.assertEqual(claim["job"]["current_model"]["version"], "1")
        # Another runner gets nothing while it is fresh.
        self.assertIsNone(c.post("/api/runner/claim", headers=self.auth(name="other")).json()["job"])
        # Same runner resumes the same job.
        self.assertTrue(c.post("/api/runner/claim", headers=self.auth()).json()["resumed"])

        ds = c.get(f"/api/runner/jobs/{job_id}/dataset", headers=self.auth()).json()
        self.assertEqual(len(ds["train"]) + len(ds["eval"]), 12)
        self.assertEqual(ds["train"][0]["text"], "fixture verse one fixture verse two")
        audio = c.get(ds["train"][0]["audio"], headers=self.auth())
        self.assertEqual(audio.headers["x-sha256"], sha(audio.content))
        self.assertEqual(c.get(f"/api/runner/jobs/{job_id}/audio/{rejected}",
                               headers=self.auth()).status_code, 403)
        self.assertEqual(c.get(ds["train"][0]["audio"]).status_code, 401)

        r = c.post(f"/api/runner/jobs/{job_id}/progress", headers=self.auth(),
                   json={"progress": 0.5, "stage": "training", "logs": ["epoch 1 loss 1.0"]})
        self.assertEqual(r.json(), {"status": "running", "stop": False})

        bad = c.put(f"/api/runner/jobs/{job_id}/files/model.int8.onnx?offset=5",
                    content=b"x", headers=self.auth())
        self.assertEqual(bad.status_code, 409)
        self.assertEqual(c.put(f"/api/runner/jobs/{job_id}/files/evil.sh?offset=0",
                               content=b"x", headers=self.auth()).status_code, 400)
        self._upload(c, job_id, "model.int8.onnx", new_model)
        self._upload(c, job_id, "tokens.txt", tokens)
        files = {"model.int8.onnx": {"sha256": sha(new_model), "bytes": len(new_model)},
                 "tokens.txt": {"sha256": sha(tokens), "bytes": len(tokens)}}
        wrong = dict(files, **{"tokens.txt": {"sha256": "0" * 64, "bytes": len(tokens)}})
        metrics = {"current": {"groups": {"all": {"n": 3, "wer": 20.0, "cer": 8.0}}},
                   "candidate": {"groups": {"all": {"n": 3, "wer": 15.0, "cer": 6.0}}}}
        self.assertEqual(c.post(f"/api/runner/jobs/{job_id}/complete", headers=self.auth(),
                                json={"metrics": metrics, "files": wrong}).status_code, 409)
        r = c.post(f"/api/runner/jobs/{job_id}/complete", headers=self.auth(),
                   json={"metrics": metrics, "files": files})
        self.assertEqual(r.json()["status"], "review")
        with self.Session() as db:
            admin_id = db.query(User).filter(User.is_admin.is_(True)).first().id
        self.assertIn("training_done", self.notifications_of(admin_id))
        return job_id, new_model

    def test_runner_flow_publish_and_rollback(self):
        job_id, new_model = self._run_to_review()
        adm = self.client("a@example.test")
        token = self.csrf(adm, f"/admin/training/{job_id}")
        page = adm.get(f"/admin/training/{job_id}").text
        self.assertIn("-5.0", page)  # WER delta shown

        # Without the confirmation box nothing is published.
        adm.post(f"/admin/training/{job_id}/action", data={"csrf": token, "action": "publish"})
        self.assertEqual(training.read_manifest()["version"], "1")

        adm.post(f"/admin/training/{job_id}/action",
                 data={"csrf": token, "action": "publish", "confirm": "yes"})
        manifest = training.read_manifest()
        self.assertEqual(manifest["version"], "2")
        self.assertEqual(manifest["files"][0]["sha256"], sha(new_model))
        self.assertTrue(manifest["files"][0]["url"].endswith("/2/model.int8.onnx"))
        self.assertIn("Tibyan volunteers", manifest["attribution"])
        v2 = self.model_dir / "2"
        for line in (v2 / "SHA256SUMS").read_text().splitlines():
            digest, name = line.split("  ")
            self.assertEqual(sha((v2 / name).read_bytes()), digest)
        self.assertIn("متطوعو تبيان", (v2 / "LICENSE.txt").read_text())
        self.assertTrue((self.model_dir / "manifest.v1.json").is_file())
        self.assertTrue((self.model_dir / "1" / "model.int8.onnx").is_file())  # kept
        top = (self.model_dir / "SHA256SUMS").read_text()
        self.assertIn("1/model.int8.onnx", top)
        self.assertIn(f"{sha(new_model)}  2/model.int8.onnx", top)
        self.assertIn(f"{sha((self.model_dir / 'manifest.json').read_bytes())}  manifest.json", top)
        with self.Session() as db:
            job = db.get(TrainingJob, job_id)
            self.assertEqual((job.status, job.published_version, job.previous_version),
                             ("published", "2", "1"))

        adm.post(f"/admin/training/{job_id}/action",
                 data={"csrf": token, "action": "rollback", "confirm": "yes"})
        self.assertEqual(training.read_manifest()["version"], "1")
        self.assertTrue(v2.is_dir())
        top = (self.model_dir / "SHA256SUMS").read_text()
        self.assertIn("1/model.int8.onnx", top)
        self.assertIn(f"{sha((self.model_dir / 'manifest.json').read_bytes())}  manifest.json", top)
        with self.Session() as db:
            self.assertEqual(db.get(TrainingJob, job_id).status, "rolled_back")

    def test_fake_runner_result_can_never_be_published(self):
        job_id, _ = self._run_to_review()
        with self.Session() as db:
            job = db.get(TrainingJob, job_id)
            job.metrics = json.dumps({"fake": True, "runner": {"fake": True}})
            db.commit()
        adm = self.client("a@example.test")
        token = self.csrf(adm, f"/admin/training/{job_id}")
        self.assertNotIn('value="publish"', adm.get(f"/admin/training/{job_id}").text)
        adm.post(f"/admin/training/{job_id}/action",
                 data={"csrf": token, "action": "publish", "confirm": "yes"})
        self.assertEqual(training.read_manifest()["version"], "1")
        self.assertFalse((self.model_dir / "2").exists())
        with self.Session() as db:
            self.assertEqual(db.get(TrainingJob, job_id).status, "review")

    def test_reject_keeps_nothing_public(self):
        job_id, _ = self._run_to_review()
        before = sorted(p.name for p in self.model_dir.iterdir())
        adm = self.client("a@example.test")
        token = self.csrf(adm, f"/admin/training/{job_id}")
        adm.post(f"/admin/training/{job_id}/action", data={"csrf": token, "action": "reject"})
        self.assertEqual(sorted(p.name for p in self.model_dir.iterdir()), before)
        self.assertEqual(training.read_manifest()["version"], "1")
        self.assertFalse(training.upload_dir(job_id).exists())
        with self.Session() as db:
            self.assertEqual(db.get(TrainingJob, job_id).status, "rejected")

    def test_cancel_stops_runner_and_fail_notifies(self):
        job_id, _, _ = self._queued_job()
        c = self.client()
        c.post("/api/runner/claim", headers=self.auth())
        adm = self.client("a@example.test")
        token = self.csrf(adm, f"/admin/training/{job_id}")
        adm.post(f"/admin/training/{job_id}/action", data={"csrf": token, "action": "cancel"})
        r = c.post(f"/api/runner/jobs/{job_id}/progress", headers=self.auth(), json={})
        self.assertEqual(r.json(), {"status": "cancelled", "stop": True})
        self.assertEqual(c.get(f"/api/runner/jobs/{job_id}/dataset",
                               headers=self.auth()).status_code, 409)

        with self.Session() as db:
            a = db.query(User).filter(User.is_admin.is_(True)).first().id
            job2 = training.create_job(db, a, "nvidia-base", {})
        c.post("/api/runner/claim", headers=self.auth())
        r = c.post(f"/api/runner/jobs/{job2.id}/fail", headers=self.auth(), json={"error": "boom"})
        self.assertEqual(r.json()["status"], "failed")
        self.assertIn("training_failed", self.notifications_of(a))
        adm.post(f"/admin/training/{job2.id}/action", data={"csrf": token, "action": "retry"})
        with self.Session() as db:
            self.assertEqual(db.get(TrainingJob, job2.id).status, "queued")

    def test_deleted_recording_drops_out_of_the_dataset(self):
        job_id, ids, _ = self._queued_job()
        c = self.client()
        c.post("/api/runner/claim", headers=self.auth())
        ds = c.get(f"/api/runner/jobs/{job_id}/dataset", headers=self.auth()).json()
        victim = ds["train"][0]["id"]
        with self.Session() as db:
            db.delete(db.get(Recording, victim))
            db.commit()
        ds2 = c.get(f"/api/runner/jobs/{job_id}/dataset", headers=self.auth()).json()
        self.assertNotIn(victim, [e["id"] for e in ds2["train"]])
        self.assertEqual(ds2["dropped"]["train"], 1)
        self.assertEqual(c.get(f"/api/runner/jobs/{job_id}/audio/{victim}",
                               headers=self.auth()).status_code, 410)


if __name__ == "__main__":
    unittest.main()
