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
