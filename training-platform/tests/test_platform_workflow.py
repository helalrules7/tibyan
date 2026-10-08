import io
import json
import math
import shutil
import struct
import tempfile
import unittest
import wave
from datetime import date
from html.parser import HTMLParser
from pathlib import Path
from unittest.mock import patch

from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from starlette.middleware.sessions import SessionMiddleware

from app import verses
from app.config import settings
from app.db import Base
from app.deps import get_db
from app.models import Recording, RecordingVote, User
from app.routes import admin, auth, pages, record, validate
from app.security import hash_password


TEST_VERSES = {
    "surahs": [
        {
            "number": 1,
            "name_ar": "سورة اختبار",
            "name_en": "Test Surah",
            "ayah_count": 2,
        }
    ],
    "ayahs": [
        {"surah": 1, "number": 1, "text": "fixture verse one"},
        {"surah": 1, "number": 2, "text": "fixture verse two"},
    ],
}
TEST_PASSWORD = "test-only-password-42"


class CsrfParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.token = None

    def handle_starttag(self, tag, attrs):
        if tag != "input":
            return
        attributes = dict(attrs)
        if attributes.get("name") == "csrf":
            self.token = attributes.get("value")


def csrf_from(response):
    parser = CsrfParser()
    parser.feed(response.text)
    if not parser.token:
        raise AssertionError("CSRF token was not rendered.")
    return parser.token


def synthetic_stereo_wav(duration_seconds=1.2, sample_rate=48000):
    samples = io.BytesIO()
    with wave.open(samples, "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        for index in range(int(duration_seconds * sample_rate)):
            value = int(
                0.35
                * 32767
                * math.sin(2 * math.pi * 440 * index / sample_rate)
            )
            wav.writeframesraw(struct.pack("<hh", value, value))
    return samples.getvalue()


@unittest.skipUnless(
    shutil.which("ffmpeg") and shutil.which("ffprobe"),
    "ffmpeg and ffprobe are required for the recording workflow test",
)
class PlatformWorkflowTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.media_dir = Path(self.temp_dir.name) / "media"
        self.old_media_dir = settings.media_dir
        settings.media_dir = str(self.media_dir)

        self.engine = create_engine(
            "sqlite://",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )
        Base.metadata.create_all(self.engine)
        self.Session = sessionmaker(bind=self.engine, autoflush=False)
        self.verses_patch = patch.object(
            verses, "verses_data", return_value=TEST_VERSES
        )
        self.verses_patch.start()

        self.app = FastAPI()
        self.app.add_middleware(
            SessionMiddleware,
            secret_key="integration-test-only",
            same_site="lax",
            https_only=False,
        )
        self.app.include_router(pages.router)
        self.app.include_router(auth.router)
        self.app.include_router(record.router)
        self.app.include_router(validate.router)
        self.app.include_router(admin.router)

        def override_get_db():
            db = self.Session()
            try:
                yield db
            finally:
                db.close()

        self.app.dependency_overrides[get_db] = override_get_db

    def tearDown(self):
        self.verses_patch.stop()
        settings.media_dir = self.old_media_dir
        self.engine.dispose()
        self.temp_dir.cleanup()

    def create_user(self, email, phone=None, is_admin=False):
        with self.Session() as db:
            user = User(
                email=email,
                phone=phone,
                password_hash=hash_password(TEST_PASSWORD),
                birth_date=date(1990, 1, 1),
                consent_ccby=True,
                consent_parental=False,
                consent_version="test",
                is_admin=is_admin,
            )
            db.add(user)
            db.commit()
            db.refresh(user)
            return user.id

    def login(self, client, identifier, password=TEST_PASSWORD):
        response = client.get("/login")
        result = client.post(
            "/login",
            data={
                "identifier": identifier,
                "password": password,
                "csrf": csrf_from(response),
            },
            follow_redirects=False,
        )
        return result

    def test_signup_login_record_review_and_training_export(self):
        audio_bytes = synthetic_stereo_wav()
        with TestClient(self.app) as author:
            registration = author.get("/register")
            with TestClient(self.app) as login_form:
                self.assertIn(
                    "autocapitalize=\"none\"", login_form.get("/login").text
                )
            created = author.post(
                "/register",
                data={
                    "email": "volunteer@example.test",
                    "phone": "01001234567",
                    "password": TEST_PASSWORD,
                    "password_confirm": TEST_PASSWORD,
                    "birth_date": "1990-01-01",
                    "consent": "1",
                    "csrf": csrf_from(registration),
                },
                follow_redirects=False,
            )
            self.assertEqual(created.status_code, 303)
            self.assertEqual(created.headers["location"], "/dashboard")
            self.assertEqual(author.get("/dashboard").status_code, 200)

            with TestClient(self.app) as email_login:
                self.assertEqual(
                    self.login(email_login, "VOLUNTEER@example.test").status_code,
                    303,
                )
            with TestClient(self.app) as phone_login:
                self.assertEqual(
                    self.login(phone_login, "01001234567").status_code,
                    303,
                )
            with TestClient(self.app) as invalid_login:
                response = self.login(
                    invalid_login, "volunteer@example.test", "wrong-password"
                )
                self.assertEqual(response.status_code, 200)
                self.assertIn("غير صحيحة", response.text)

            record_page = author.get("/record")
            self.assertEqual(record_page.status_code, 200)
            self.assertIn("طريقة التسجيل", record_page.text)
            self.assertEqual(len(author.get("/api/surahs").json()), 1)
            self.assertEqual(
                len(author.get("/api/surah/1").json()["ayahs"]), 2
            )

            uploaded = author.post(
                "/record",
                data={
                    "surah": "1",
                    "ayah": "1",
                    "ayah_end": "2",
                    "csrf": csrf_from(record_page),
                },
                files={"audio": ("synthetic.wav", audio_bytes, "audio/wav")},
                follow_redirects=False,
            )
            self.assertEqual(uploaded.status_code, 303)
            with self.Session() as db:
                recording = db.query(Recording).one()
                recording_id = recording.id
                self.assertEqual((recording.ayah, recording.ayah_end), (1, 2))
                self.assertGreater(recording.audio_duration_ms, 800)

            first_reviewer_id = self.create_user("reviewer1@example.test")
            second_reviewer_id = self.create_user("reviewer2@example.test")
            for email in ("reviewer1@example.test", "reviewer2@example.test"):
                with TestClient(self.app) as reviewer:
                    self.assertEqual(self.login(reviewer, email).status_code, 303)
                    review_page = reviewer.get("/validate")
                    self.assertIn("صوّت بالقبول أو الرفض", review_page.text)
                    self.assertIn(
                        "fixture verse one fixture verse two", review_page.text
                    )
                    audio_response = reviewer.get(
                        f"/recordings/{recording_id}/audio"
                    )
                    self.assertEqual(audio_response.status_code, 200)
                    self.assertEqual(audio_response.headers["content-type"], "audio/wav")
                    vote = reviewer.post(
                        f"/validate/{recording_id}",
                        data={
                            "verdict": "accept",
                            "csrf": csrf_from(review_page),
                        },
                        follow_redirects=False,
                    )
                    self.assertEqual(vote.status_code, 303)
                    with self.Session() as db:
                        current = db.get(Recording, recording_id)
                        expected = (
                            "pending"
                            if email == "reviewer1@example.test"
                            else "accepted"
                        )
                        self.assertEqual(current.status, expected)

            with self.Session() as db:
                self.assertEqual(
                    db.query(RecordingVote)
                    .filter(RecordingVote.recording_id == recording_id)
                    .count(),
                    2,
                )
                self.assertNotEqual(first_reviewer_id, second_reviewer_id)

            admin_id = self.create_user("admin@example.test", is_admin=True)
            with self.Session() as db:
                admin_recording = Recording(
                    user_id=admin_id,
                    surah=1,
                    ayah=1,
                    ayah_end=1,
                    audio_path=recording.audio_path,
                    audio_duration_ms=recording.audio_duration_ms,
                    status="flagged",
                )
                db.add(admin_recording)
                db.commit()
                db.refresh(admin_recording)
                admin_recording_id = admin_recording.id

            with TestClient(self.app) as administrator:
                self.assertEqual(
                    self.login(administrator, "admin@example.test").status_code,
                    303,
                )
                admin_page = administrator.get("/admin")
                self.assertIn("بما في ذلك تسجيلاتك", admin_page.text)
                self.assertIn(f"#{admin_recording_id}", admin_page.text)
                self.assertIn(
                    f"/admin/flagged/{admin_recording_id}/restore",
                    admin_page.text,
                )
                decision = administrator.post(
                    f"/admin/recordings/{admin_recording_id}/decision",
                    data={
                        "verdict": "accept",
                        "page": "1",
                        "csrf": csrf_from(admin_page),
                    },
                    follow_redirects=False,
                )
                self.assertEqual(decision.status_code, 303)
                with self.Session() as db:
                    current = db.get(Recording, admin_recording_id)
                    self.assertEqual(current.status, "accepted")
                    admin_vote = (
                        db.query(RecordingVote)
                        .filter(
                            RecordingVote.recording_id == admin_recording_id,
                            RecordingVote.user_id == admin_id,
                        )
                        .one()
                    )
                    self.assertEqual(admin_vote.verdict, "accept")

                admin_page = administrator.get("/admin")
                rejection = administrator.post(
                    f"/admin/recordings/{admin_recording_id}/decision",
                    data={
                        "verdict": "reject",
                        "page": "1",
                        "csrf": csrf_from(admin_page),
                    },
                    follow_redirects=False,
                )
                self.assertEqual(rejection.status_code, 303)
                with self.Session() as db:
                    current = db.get(Recording, admin_recording_id)
                    self.assertEqual(current.status, "rejected")
                    admin_vote = (
                        db.query(RecordingVote)
                        .filter(
                            RecordingVote.recording_id == admin_recording_id,
                            RecordingVote.user_id == admin_id,
                        )
                        .one()
                    )
                    self.assertEqual(admin_vote.verdict, "reject")

                admin_page = administrator.get("/admin")
                export = administrator.post(
                    "/admin/export",
                    data={"csrf": csrf_from(admin_page)},
                    follow_redirects=False,
                )
                self.assertEqual(export.status_code, 303)

            export_root = self.media_dir / "export"
            manifest_rows = [
                json.loads(line)
                for line in (export_root / "manifest.jsonl")
                .read_text(encoding="utf-8")
                .splitlines()
            ]
            self.assertEqual(len(manifest_rows), 1)
            manifest = next(
                row
                for row in manifest_rows
                if row["audio_filepath"] == f"wavs/{recording_id}.wav"
            )
            self.assertEqual(
                manifest["text"], "fixture verse one fixture verse two"
            )
            self.assertEqual(manifest["audio_filepath"], f"wavs/{recording_id}.wav")
            self.assertTrue((export_root / manifest["audio_filepath"]).is_file())
            checksum = (export_root / "SHA256SUMS").read_text(encoding="utf-8")
            self.assertIn(f"wavs/{recording_id}.wav", checksum)

    def test_non_admin_cannot_make_an_admin_recording_decision(self):
        owner_id = self.create_user("owner@example.test")
        self.create_user("reviewer@example.test")
        admin_id = self.create_user("admin@example.test", is_admin=True)
        with self.Session() as db:
            recording = Recording(
                user_id=owner_id,
                surah=1,
                ayah=1,
                ayah_end=1,
                audio_path="recordings/not-needed-for-this-route.wav",
                audio_duration_ms=1000,
                status="pending",
            )
            db.add(recording)
            db.commit()
            db.refresh(recording)
            recording_id = recording.id

        with TestClient(self.app) as reviewer:
            self.assertEqual(self.login(reviewer, "reviewer@example.test").status_code, 303)
            review_page = reviewer.get("/validate")
            self.assertIn("ساهم في مراجعة تسجيلات الآخرين", reviewer.get("/dashboard").text)
            response = reviewer.post(
                f"/admin/recordings/{recording_id}/decision",
                data={"verdict": "accept", "csrf": csrf_from(review_page)},
                follow_redirects=False,
            )
            self.assertEqual(response.status_code, 303)
            self.assertEqual(response.headers["location"], "/dashboard")

        with self.Session() as db:
            self.assertEqual(db.get(Recording, recording_id).status, "pending")
            self.assertEqual(
                db.query(RecordingVote)
                .filter(
                    RecordingVote.recording_id == recording_id,
                    RecordingVote.user_id == admin_id,
                )
                .count(),
                0,
            )

    def test_admin_recordings_are_paginated_and_decision_keeps_page(self):
        owner_id = self.create_user("pagination-owner@example.test")
        self.create_user("pagination-admin@example.test", is_admin=True)
        with self.Session() as db:
            db.add_all(
                Recording(
                    user_id=owner_id,
                    surah=1,
                    ayah=1,
                    ayah_end=1,
                    audio_path=f"recordings/{index}.wav",
                    audio_duration_ms=1000,
                    status="pending",
                )
                for index in range(51)
            )
            db.commit()
            recording_ids = [
                row[0]
                for row in db.query(Recording.id).order_by(Recording.id).all()
            ]

        with TestClient(self.app) as administrator:
            self.assertEqual(
                self.login(administrator, "pagination-admin@example.test").status_code,
                303,
            )
            first_page = administrator.get("/admin")
            self.assertIn(f"<td>#{recording_ids[-1]} ·", first_page.text)
            self.assertNotIn(f"<td>#{recording_ids[0]} ·", first_page.text)

            second_page = administrator.get("/admin?page=2")
            self.assertIn(f"<td>#{recording_ids[0]} ·", second_page.text)
            self.assertNotIn(f"<td>#{recording_ids[-1]} ·", second_page.text)
            decision = administrator.post(
                f"/admin/recordings/{recording_ids[0]}/decision",
                data={
                    "verdict": "accept",
                    "page": "2",
                    "csrf": csrf_from(second_page),
                },
                follow_redirects=False,
            )
            self.assertEqual(decision.headers["location"], "/admin?page=2")

    def test_invalid_ayah_range_is_rejected_before_audio_is_saved(self):
        with TestClient(self.app) as author:
            registration = author.get("/register")
            author.post(
                "/register",
                data={
                    "email": "range@example.test",
                    "password": TEST_PASSWORD,
                    "password_confirm": TEST_PASSWORD,
                    "birth_date": "1990-01-01",
                    "consent": "1",
                    "csrf": csrf_from(registration),
                },
                follow_redirects=False,
            )
            record_page = author.get("/record")
            response = author.post(
                "/record",
                data={
                    "surah": "1",
                    "ayah": "2",
                    "ayah_end": "1",
                    "csrf": csrf_from(record_page),
                },
                files={
                    "audio": ("synthetic.wav", synthetic_stereo_wav(), "audio/wav")
                },
                follow_redirects=False,
            )
            self.assertEqual(response.status_code, 303)
            with self.Session() as db:
                self.assertEqual(db.query(Recording).count(), 0)


if __name__ == "__main__":
    unittest.main()
