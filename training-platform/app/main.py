from __future__ import annotations

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from starlette.middleware.sessions import SessionMiddleware

from . import models  # noqa: F401  (register the tables)
from .config import settings
from .db import Base, engine, migrate_recording_ayah_end
from .routes import admin, auth, contact, pages, record, validate
from .templating import STATIC_DIR

Base.metadata.create_all(bind=engine)
migrate_recording_ayah_end(engine)

app = FastAPI(title="Tibyan Recitation Training")

app.add_middleware(
    SessionMiddleware,
    secret_key=settings.secret_key,
    same_site="lax",
    https_only=settings.cookie_secure,
    max_age=7 * 24 * 3600,
)

app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")
app.include_router(pages.router)
app.include_router(auth.router)
app.include_router(record.router)
app.include_router(validate.router)
app.include_router(admin.router)
app.include_router(contact.router)
