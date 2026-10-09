from __future__ import annotations

from fastapi import APIRouter, Depends, Form, Request
from sqlalchemy.orm import Session
from starlette.responses import FileResponse, PlainTextResponse, RedirectResponse, Response

from ..deps import current_user, get_db
from ..mail import valid_email
from ..models import DeletionRequest, Recording
from ..notifications import notify_admins
from ..stats import public_progress
from ..templating import STATIC_DIR
from ..web import check_csrf, msg, render

router = APIRouter()

ROOT_HOSTS = {
    "altibya.app",
    "www.altibya.app",
    "altibyan.app",
    "www.altibyan.app",
}
ROOT_ORIGIN = "https://altibyan.app"
TRAIN_ORIGIN = "https://train.altibyan.app"
# Public, indexable pages of the training platform (the rest needs a login).
TRAIN_PUBLIC_PATHS = ("/", "/voice", "/register", "/login", "/contact")


def is_root_host(request: Request) -> bool:
    return (request.url.hostname or "").rstrip(".").lower() in ROOT_HOSTS


@router.get("/")
def index(request: Request, db: Session = Depends(get_db)):
    if is_root_host(request):
        notify = request.session.pop("notify", None)
        return render(request, "coming-soon.html", notify=notify)

    user = current_user(request, db)
    return render(request, "index.html", user=user, progress=public_progress(db))


@router.get("/voice")
def voice(request: Request, db: Session = Depends(get_db)):
    """How volunteers' recordings are used and how to delete them."""
    if is_root_host(request):
        return RedirectResponse(f"{TRAIN_ORIGIN}/voice", status_code=301)
    return render(
        request,
        "voice.html",
        user=current_user(request, db),
        deletion=request.session.pop("deletion", None),
    )


@router.post("/voice/delete-request")
def deletion_request(
    request: Request,
    db: Session = Depends(get_db),
    email: str = Form(""),
    scope: str = Form("account"),
    details: str = Form(""),
    website: str = Form(""),
    csrf: str = Form(""),
):
    """Ask the team to delete recordings or a whole account. A logged-in
    request is linked to the account; `website` is a honeypot."""
    check_csrf(request, csrf)
    user = current_user(request, db)
    email = email.strip().lower()[:255]
    if user is not None and not email:
        email = (user.email or "").lower()
    if website:
        request.session["deletion"] = "ok"
    elif not valid_email(email) or scope not in ("recordings", "account"):
        request.session["deletion"] = "invalid"
    else:
        row = DeletionRequest(
            user_id=user.id if user else None,
            email=email,
            scope=scope,
            details=details.strip()[:2000] or None,
        )
        db.add(row)
        db.commit()
        notify_admins(
            db, "deletion_request", {"scope": scope}, "/admin/requests?tab=deletion"
        )
        request.session["deletion"] = "ok"
    return RedirectResponse("/voice#delete-request", status_code=303)


@router.get("/robots.txt")
def robots(request: Request):
    if is_root_host(request):
        body = f"User-agent: *\nAllow: /\n\nSitemap: {ROOT_ORIGIN}/sitemap.xml\n"
    else:
        body = (
            "User-agent: *\n"
            "Disallow: /admin\n"
            "Disallow: /dashboard\n"
            "Disallow: /record\n"
            "Disallow: /recordings/\n"
            "Disallow: /validate\n"
            "Disallow: /logout\n"
            "Disallow: /lang/\n"
            f"\nSitemap: {TRAIN_ORIGIN}/sitemap.xml\n"
        )
    return PlainTextResponse(body)


@router.get("/sitemap.xml")
def sitemap(request: Request):
    if is_root_host(request):
        urls = [f"{ROOT_ORIGIN}/"]
    else:
        urls = [f"{TRAIN_ORIGIN}{path}" for path in TRAIN_PUBLIC_PATHS]
    entries = "".join(f"  <url><loc>{url}</loc></url>\n" for url in urls)
    body = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
        f"{entries}</urlset>\n"
    )
    return Response(body, media_type="application/xml")


@router.get("/favicon.ico")
def favicon():
    return FileResponse(
        f"{STATIC_DIR}/favicon.ico",
        media_type="image/x-icon",
        headers={"Cache-Control": "public, max-age=604800"},
    )


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
