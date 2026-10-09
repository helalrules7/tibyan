from __future__ import annotations

from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from .config import settings

_connect_args = (
    {"check_same_thread": False}
    if settings.database_url.startswith("sqlite")
    else {}
)

engine = create_engine(
    settings.database_url,
    connect_args=_connect_args,
    pool_pre_ping=True,
)

SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def migrate_recording_ayah_end(bind: Engine = engine) -> None:
    inspector = inspect(bind)
    if "recordings" not in inspector.get_table_names():
        return
    columns = {column["name"] for column in inspector.get_columns("recordings")}
    if "ayah_end" not in columns:
        with bind.begin() as connection:
            connection.execute(
                text("ALTER TABLE recordings ADD COLUMN ayah_end INTEGER NULL")
            )


def migrate_user_birth_year(bind: Engine = engine) -> None:
    """Additive: a nullable birth_year column; existing rows stay untouched."""
    inspector = inspect(bind)
    if "users" not in inspector.get_table_names():
        return
    columns = {column["name"] for column in inspector.get_columns("users")}
    if "birth_year" not in columns:
        try:
            with bind.begin() as connection:
                connection.execute(
                    text("ALTER TABLE users ADD COLUMN birth_year INTEGER NULL")
                )
        except Exception:
            # Another worker added it first; fail only if it is still missing.
            columns = {c["name"] for c in inspect(bind).get_columns("users")}
            if "birth_year" not in columns:
                raise


def add_missing_columns(bind: Engine, table: str, columns: dict[str, str]) -> None:
    """Additive migration: ALTER TABLE ADD COLUMN for each missing nullable
    column; existing rows and columns are never touched."""
    inspector = inspect(bind)
    if table not in inspector.get_table_names():
        return
    present = {c["name"] for c in inspector.get_columns(table)}
    for name, ddl in columns.items():
        if name in present:
            continue
        try:
            with bind.begin() as connection:
                connection.execute(text(f"ALTER TABLE {table} ADD COLUMN {name} {ddl}"))
        except Exception:
            # Another worker added it first; fail only if it is still missing.
            if name not in {c["name"] for c in inspect(bind).get_columns(table)}:
                raise


def migrate_request_columns(bind: Engine = engine) -> None:
    """Read/replied state for contact messages, Play/TestFlight marks for
    beta requests. All nullable."""
    add_missing_columns(
        bind,
        "contact_messages",
        {"read_at": "DATETIME NULL", "replied_at": "DATETIME NULL"},
    )
    add_missing_columns(
        bind,
        "notify_signups",
        {"play_added_at": "DATETIME NULL", "testflight_added_at": "DATETIME NULL"},
    )


class Base(DeclarativeBase):
    pass
