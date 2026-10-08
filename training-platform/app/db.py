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


class Base(DeclarativeBase):
    pass
