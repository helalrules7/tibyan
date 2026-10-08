from __future__ import annotations

from fastapi import Depends, Request
from sqlalchemy.orm import Session

from .db import SessionLocal
from .models import User


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def current_user(request: Request, db: Session = Depends(get_db)):
    user_id = request.session.get("user_id")
    if user_id is None:
        return None
    return db.get(User, int(user_id))
