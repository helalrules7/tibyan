from __future__ import annotations

from datetime import date, datetime
from typing import Optional

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[Optional[str]] = mapped_column(String(255), unique=True, index=True, nullable=True)
    phone: Mapped[Optional[str]] = mapped_column(String(32), unique=True, index=True, nullable=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    # Legacy: full birth date from accounts created before consent 1.1.
    # New sign-ups store only the birth year (privacy notice promise).
    birth_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    birth_year: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    # CC-BY-4.0 consent is required at sign-up.
    consent_ccby: Mapped[bool] = mapped_column(Boolean, default=False)
    # Parental consent, required when the volunteer is a minor.
    consent_parental: Mapped[bool] = mapped_column(Boolean, default=False)
    consent_version: Mapped[Optional[str]] = mapped_column(String(16), nullable=True)
    consent_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.current_timestamp()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        server_default=func.current_timestamp(),
        onupdate=func.current_timestamp(),
    )


class Recording(Base):
    __tablename__ = "recordings"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)

    surah: Mapped[int] = mapped_column(Integer)
    ayah: Mapped[int] = mapped_column(Integer)
    ayah_end: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    # Relative path under settings.media_dir (never under the web root).
    audio_path: Mapped[str] = mapped_column(String(512))
    audio_duration_ms: Mapped[int] = mapped_column(Integer)
    audio_format: Mapped[str] = mapped_column(String(16), default="wav")

    # Speaker / environment metadata for ASR quality.
    gender: Mapped[Optional[str]] = mapped_column(String(16), nullable=True)
    age_bracket: Mapped[Optional[str]] = mapped_column(String(16), nullable=True)
    dialect: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    native_language: Mapped[Optional[str]] = mapped_column(String(16), nullable=True)
    environment: Mapped[Optional[str]] = mapped_column(String(16), nullable=True)
    speed: Mapped[Optional[str]] = mapped_column(String(16), nullable=True)

    # pending -> accepted | rejected | flagged (phase 3/4).
    status: Mapped[str] = mapped_column(String(16), default="pending")
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.current_timestamp()
    )


class RecordingVote(Base):
    __tablename__ = "recording_votes"
    __table_args__ = (
        UniqueConstraint("recording_id", "user_id", name="uq_vote_once"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    recording_id: Mapped[int] = mapped_column(
        ForeignKey("recordings.id"), index=True
    )
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    # accept | reject
    verdict: Mapped[str] = mapped_column(String(8))
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.current_timestamp()
    )


class ClipReport(Base):
    __tablename__ = "clip_reports"

    id: Mapped[int] = mapped_column(primary_key=True)
    recording_id: Mapped[int] = mapped_column(
        ForeignKey("recordings.id"), index=True
    )
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.current_timestamp()
    )


class ContactMessage(Base):
    __tablename__ = "contact_messages"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(120))
    email: Mapped[str] = mapped_column(String(255))
    subject: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    message: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.current_timestamp()
    )
    # Added by migrate_request_columns (nullable; old rows stay unread).
    read_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    replied_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)


class NotifySignup(Base):
    """An address that asked to hear when Tibyan launches (altibyan.app)."""

    __tablename__ = "notify_signups"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    lang: Mapped[str] = mapped_column(String(8), default="ar")
    wants_beta: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.current_timestamp()
    )
    # Beta testers an admin added to Google Play / TestFlight (nullable,
    # added by migrate_request_columns).
    play_added_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    testflight_added_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)


class DeletionRequest(Base):
    """A request (from /voice) to delete recordings or a whole account."""

    __tablename__ = "deletion_requests"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("users.id"), index=True, nullable=True
    )
    email: Mapped[str] = mapped_column(String(255))
    # recordings | account
    scope: Mapped[str] = mapped_column(String(16), default="account")
    details: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    # open | done | declined
    status: Mapped[str] = mapped_column(String(16), default="open", index=True)
    handled_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    handled_by: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.current_timestamp()
    )


class Notification(Base):
    """In-app notification; the text is rendered from `kind` + `data` in
    the reader's language, so one row serves Arabic and English."""

    __tablename__ = "notifications"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    kind: Mapped[str] = mapped_column(String(40))
    data: Mapped[Optional[str]] = mapped_column(Text, nullable=True)  # JSON
    url: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    read_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.current_timestamp()
    )


class PushSubscription(Base):
    """A browser's Web Push subscription for one user."""

    __tablename__ = "push_subscriptions"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    # sha256(endpoint): unique without a long-text index (MariaDB limits).
    endpoint_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    endpoint: Mapped[str] = mapped_column(Text)
    p256dh: Mapped[str] = mapped_column(String(255))
    auth: Mapped[str] = mapped_column(String(64))
    lang: Mapped[str] = mapped_column(String(8), default="ar")
    user_agent: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    failures: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.current_timestamp()
    )
    last_success_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)


class EvalSet(Base):
    """A frozen, held-out evaluation set. Its recordings never train."""

    __tablename__ = "eval_sets"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(64))
    created_by: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.current_timestamp()
    )


class EvalSetItem(Base):
    __tablename__ = "eval_set_items"
    __table_args__ = (
        UniqueConstraint("eval_set_id", "recording_id", name="uq_eval_item"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    eval_set_id: Mapped[int] = mapped_column(ForeignKey("eval_sets.id"), index=True)
    # No FK: an owner may delete the recording; the item then drops out.
    recording_id: Mapped[int] = mapped_column(Integer, index=True)


class TrainingJob(Base):
    """One fine-tune run on the Mac runner (see app/training.py)."""

    __tablename__ = "training_jobs"

    id: Mapped[int] = mapped_column(primary_key=True)
    status: Mapped[str] = mapped_column(String(16), default="queued", index=True)
    # nvidia-base | job:<id>
    base_model: Mapped[str] = mapped_column(String(64), default="nvidia-base")
    params: Mapped[str] = mapped_column(Text)  # JSON hyperparameters
    # JSON {"train": [recording ids]} frozen at creation.
    dataset: Mapped[str] = mapped_column(Text)
    eval_set_id: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    train_count: Mapped[int] = mapped_column(Integer, default=0)
    train_ms: Mapped[int] = mapped_column(Integer, default=0)
    note: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    created_by: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.current_timestamp()
    )

    runner: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    claimed_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    heartbeat_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    finished_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    progress: Mapped[float] = mapped_column(default=0.0)
    stage: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    error: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    # Model version the runner compared against (manifest version at claim).
    compared_version: Mapped[Optional[str]] = mapped_column(String(16), nullable=True)
    metrics: Mapped[Optional[str]] = mapped_column(Text, nullable=True)  # JSON
    files: Mapped[Optional[str]] = mapped_column(Text, nullable=True)  # JSON

    decided_by: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    decided_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    published_version: Mapped[Optional[str]] = mapped_column(String(16), nullable=True)
    previous_version: Mapped[Optional[str]] = mapped_column(String(16), nullable=True)


class TrainingJobLog(Base):
    __tablename__ = "training_job_logs"

    id: Mapped[int] = mapped_column(primary_key=True)
    job_id: Mapped[int] = mapped_column(ForeignKey("training_jobs.id"), index=True)
    line: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.current_timestamp()
    )
