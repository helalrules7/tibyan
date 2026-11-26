"""altibyan.app/beta: join the beta test (email + platforms), then the
public Google Play / TestFlight links with illustrated install steps."""
from __future__ import annotations

from fastapi import APIRouter, BackgroundTasks, Depends, Form, HTTPException, Request
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from starlette.responses import RedirectResponse

from .. import analytics, ratelimit, releases
from ..deps import get_db
from ..i18n import get_lang
from ..launch_mail import (
    PLAY_TEST_URL,
    TESTFLIGHT_APP_URL,
    TESTFLIGHT_URL,
    send_beta_confirmation,
    send_signup_alert,
)
from ..mail import valid_email
from ..models import NotifySignup
from ..notifications import notify_admins
from ..push import utcnow
from ..web import check_csrf, render

router = APIRouter()
PLATFORMS = ("ios", "android", "mac")


GUIDE_ORDER = ("android", "ios", "mac")


def _page(request: Request, status_code: int = 200, **context):
    chosen = context.get("chosen") or []
    # A Mac-only tester still needs TestFlight steps, so keep all three
    # guides, with the ones the visitor picked first.
    context["guide_order"] = [p for p in GUIDE_ORDER if p in chosen] + [
        p for p in GUIDE_ORDER if p not in chosen
    ]
    response = render(
        request,
        "beta.html",
        play_url=PLAY_TEST_URL,
        testflight_url=TESTFLIGHT_URL,
        testflight_app_url=TESTFLIGHT_APP_URL,
        downloads=releases.downloads(),
        human_size=releases.human_size,
        prefix="/en" if get_lang(request) == "en" else "",
        **context,
    )
    response.status_code = status_code
    return response


@router.get("/beta")
def beta_page(request: Request):
    """Tibyan launched (26 Nov 2026): the beta page now sends visitors to the
    download page, in the visitor's language."""
    prefix = "/en" if request.scope.get("tibyan_lang") == "en" else ""
    return RedirectResponse(f"{prefix}/download", status_code=301)


@router.post("/beta/join")
def beta_join(
    request: Request,
    background: BackgroundTasks,
    db: Session = Depends(get_db),
    email: str = Form(""),
    platform: list[str] = Form([]),
    website: str = Form(""),
    csrf: str = Form(""),
):
    check_csrf(request, csrf)
    email = email.strip().lower()[:255]
    chosen = [p for p in PLATFORMS if p in set(platform)]

    if website:  # honeypot: same thank-you, nothing stored
        request.session["beta"] = "ok"
        return RedirectResponse(("/en" if get_lang(request) == "en" else "") + "/beta#install", status_code=303)
    if ratelimit.hit("beta", request):
        return _page(request, 429, state="busy", chosen=[], errors={}, old={"email": email, "platforms": chosen})

    errors = {}
    if not valid_email(email):
        errors["email"] = True
    if not chosen:
        errors["platform"] = True
    if errors:
        return _page(request, 422, state=None, chosen=[], errors=errors, old={"email": email, "platforms": chosen})

    lang = get_lang(request)
    row = db.query(NotifySignup).filter(NotifySignup.email == email).first()
    before = set(row.platforms) if row is not None and row.wants_beta else set()
    merged = [p for p in PLATFORMS if p in before | set(chosen)]
    if row is None:
        row = NotifySignup(email=email, lang=lang)
        db.add(row)
    row.wants_beta = True
    row.beta_platforms = ",".join(merged)
    row.beta_requested_at = utcnow()
    try:
        db.commit()
    except IntegrityError:  # the same address raced in; retry as an update
        db.rollback()
        row = db.query(NotifySignup).filter(NotifySignup.email == email).one()
        row.wants_beta = True
        row.beta_platforms = ",".join(p for p in PLATFORMS if p in set(row.platforms) | set(chosen))
        row.beta_requested_at = utcnow()
        db.commit()

    if set(merged) != before:  # something new to act on
        notify_admins(db, "beta_request", {}, "/admin/requests?tab=beta")
        background.add_task(send_beta_confirmation, email, lang, merged)
        background.add_task(send_signup_alert, "beta", email, lang, merged)

    request.session["beta"] = "ok"
    request.session["beta_platforms"] = chosen
    return RedirectResponse(("/en" if get_lang(request) == "en" else "") + "/beta#install", status_code=303)


@router.api_route("/download/{platform}", methods=["GET", "HEAD"])
def download(platform: str, request: Request):
    """302 to the newest release's asset for this platform. Counted per
    platform per day (no cookies, no IPs), off the request path."""
    if platform not in releases.PATTERNS and platform != "windows-zip":
        raise HTTPException(status_code=404)
    analytics.record_download(platform, request.headers.get("user-agent"), request.method)
    response = RedirectResponse(releases.download_url(platform), status_code=302)
    response.headers["Cache-Control"] = "no-store"
    return response
