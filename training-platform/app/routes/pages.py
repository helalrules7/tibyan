from __future__ import annotations

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session
from starlette.responses import RedirectResponse

from ..deps import current_user, get_db
from ..models import Recording
from ..web import msg, render

router = APIRouter()


@router.get("/")
def index(request: Request, db: Session = Depends(get_db)):
    hostname = (request.url.hostname or "").rstrip(".").lower()
    if hostname in {
        "altibya.app",
        "www.altibya.app",
        "altibyan.app",
        "www.altibyan.app",
    }:
        return render(request, "coming-soon.html")

    user = current_user(request, db)
    return render(request, "index.html", user=user)


@router.get("/dashboard")
def dashboard(request: Request, db: Session = Depends(get_db)):
    user = current_user(request, db)
    if user is None:
        return RedirectResponse("/login", status_code=303)
    flash = request.session.pop("flash", None)
    recordings = (
        db.query(Recording)
        .filter(Recording.user_id == user.id)
        .order_by(Recording.id.desc())
        .limit(20)
        .all()
    )
    status_label = lambda status: msg(request, f"status_{status}")
    return render(
        request,
        "dashboard.html",
        user=user,
        flash=flash,
        recordings=recordings,
        status_label=status_label,
    )


@router.get("/lang/{code}")
def set_language(code: str, request: Request):
    if code not in ("ar", "en"):
        code = "ar"
    target = request.headers.get("referer") or "/"
    response = RedirectResponse(target, status_code=303)
    response.set_cookie(
        "lang", code, httponly=True, samesite="lax", max_age=31536000
    )
    return response
