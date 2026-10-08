#!/usr/bin/env python3
"""Promote a user to platform admin.

Usage:
    python3 tools/make_admin.py EMAIL_OR_PHONE

Must be run from the training-platform directory (so `app` is importable).
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "training-platform"))

from sqlalchemy.orm import Session  # noqa: E402

from app.db import SessionLocal  # noqa: E402
from app.models import User  # noqa: E402


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2

    identifier = sys.argv[1].strip().lower()
    db: Session = SessionLocal()
    try:
        user = (
            db.query(User)
            .filter((User.email == identifier) | (User.phone == identifier))
            .first()
        )
        if user is None:
            print(f"No user found for {identifier!r}")
            return 1
        user.is_admin = True
        db.commit()
        print(f"{identifier!r} is now an admin.")
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    raise SystemExit(main())
