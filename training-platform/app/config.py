from __future__ import annotations

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # sqlite:///./training.db locally; mysql+pymysql://... on the server.
    database_url: str = "sqlite:///./training.db"
    secret_key: str = "dev-secret-change-me"
    # Secure session cookie; true in production (HTTPS).
    cookie_secure: bool = False
    consent_version: str = "1.1"
    adult_age: int = 18

    # Public progress counter on the training home page.
    training_goal_minutes: int = 600

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

    # Web Push (VAPID). Generate once with tools/gen_vapid.py and keep the
    # private key only in the server's .env. Empty = push disabled; the
    # in-app notification centre still works.
    vapid_public_key: str = ""
    vapid_private_key: str = ""
    vapid_subject: str = "https://train.altibyan.app"

    # Training runner (the Mac). Bearer token for /api/runner/*; empty =
    # runner API disabled (503).
    runner_token: str = ""
    # A running job whose runner has been silent this long can be taken
    # over by the next claim (the runner resumes from its own checkpoint).
    runner_stale_seconds: int = 3600
    # Largest single upload chunk and the largest file a runner may upload.
    runner_chunk_bytes: int = 16 * 1024 * 1024
    runner_max_file_bytes: int = 1024 * 1024 * 1024

    # Public model mirror (host dir mounted into the container). Publishing
    # writes <mirror_dir>/<model_name>/<version>/ and updates manifest.json.
    mirror_dir: str = "./mirror"
    mirror_base_url: str = "https://tibyan.ahmedhelal.dev/mirror/recitation-models"
    model_name: str = "nvidia-ar-fastconformer-ctc"
    # The official NVIDIA checkpoint the first fine-tune starts from.
    base_model_url: str = (
        "https://tibyan.ahmedhelal.dev/mirror/sources/"
        "nvidia-stt-ar-fastconformer-hybrid-large-pcd-v1.0/"
        "stt_ar_fastconformer_hybrid_large_pcd_v1.0.nemo"
    )
    base_model_sha256: str = (
        "d29d19d7c054a5fc010ac6815e9cbb0dd1b21a30e0a7f7f2982e1fecaf0c3e31"
    )
    # Share of accepted recordings frozen into the held-out evaluation set.
    eval_fraction: float = 0.1
    eval_min_recordings: int = 5

    class Config:
        env_file = ".env"


settings = Settings()
