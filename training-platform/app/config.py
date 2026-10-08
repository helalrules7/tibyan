from __future__ import annotations

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # sqlite:///./training.db locally; mysql+pymysql://... on the server.
    database_url: str = "sqlite:///./training.db"
    secret_key: str = "dev-secret-change-me"
    # Secure session cookie; true in production (HTTPS).
    cookie_secure: bool = False
    consent_version: str = "1.0"
    adult_age: int = 18

    # Public origin used for meta/share tags.
    site_url: str = "https://train.altibyan.app"

    # Verse prompts, exported verbatim from content.db by
    # tools/export_verse_prompts.py.
    verses_path: str = "./data/verses.json"

    # Private media root (outside the web root in production).
    media_dir: str = "./media"

    # Uploads and audio processing.
    max_upload_bytes: int = 50 * 1024 * 1024
    min_clip_ms: int = 800
    max_clip_ms: int = 120_000
    ffmpeg_bin: str = "ffmpeg"
    ffprobe_bin: str = "ffprobe"

    # Outgoing email (contact form). Leave smtp_host empty to only store
    # messages in the database.
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_pass: str = ""
    smtp_from: str = ""
    smtp_to: str = ""

    class Config:
        env_file = ".env"


settings = Settings()
