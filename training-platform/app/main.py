from __future__ import annotations

from fastapi import FastAPI, Request
from fastapi.exception_handlers import http_exception_handler
from fastapi.staticfiles import StaticFiles
from starlette.exceptions import HTTPException as StarletteHTTPException
from starlette.middleware.sessions import SessionMiddleware
from starlette.responses import RedirectResponse

from . import analytics, models  # noqa: F401  (register the tables)
from .config import settings
from .db import engine, run_migrations
from .routes import (
    admin,
    admin_requests,
    admin_training,
    annotations,
    auth,
    beta,
    quran,
    contact,
    khatma,
    notifications,
    notify,
    pages,
    record,
    reports,
    runner,
    validate,
)
from .i18n import get_lang, t as translate
from .templating import STATIC_DIR, templates

run_migrations(engine)

app = FastAPI(title="Tibyan Recitation Training")

app.add_middleware(
    SessionMiddleware,
    secret_key=settings.secret_key,
    same_site="lax",
    https_only=settings.cookie_secure,
    max_age=7 * 24 * 3600,
)

@app.middleware("http")
async def _en_prefix(request: Request, call_next):
    """altibyan.app: English lives under /en/ (Arabic at the bare path).
    /en/<path> is served by <path> with the language set to English; an old
    lang=en cookie on a bare page redirects to its /en twin."""
    if not pages.is_root_host(request):
        return await call_next(request)
    path = request.url.path
    if path == "/en":
        return RedirectResponse("/en/", status_code=301)
    if path.startswith("/en/"):
        inner = path[3:]
        request.scope["path"] = inner
        request.scope["raw_path"] = inner.encode()
        request.scope["tibyan_lang"] = "en"
        response = await call_next(request)
        if request.method == "GET" and inner in pages.LOCALIZED:
            response.set_cookie("lang", "en", httponly=True, samesite="lax", max_age=31536000)
        return response
    if path in pages.LOCALIZED:
        if request.method == "GET" and request.cookies.get("lang") == "en":
            query = request.url.query
            target = pages.localized_path(path, "en") + (f"?{query}" if query else "")
            return RedirectResponse(target, status_code=302)
        request.scope["tibyan_lang"] = "ar"
    return await call_next(request)


@app.middleware("http")
async def _count_page_views(request: Request, call_next):
    response = await call_next(request)
    try:
        analytics.count_page(request, response)
    except Exception:  # counting must never break a page
        pass
    return response


app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")
app.include_router(pages.router)
app.include_router(auth.router)
app.include_router(record.router)
app.include_router(validate.router)
app.include_router(admin.router)
app.include_router(contact.router)
app.include_router(notify.router)
app.include_router(beta.router)
app.include_router(admin_requests.router)
app.include_router(admin_training.router)
app.include_router(notifications.router)
app.include_router(runner.router)
app.include_router(reports.router)
app.include_router(annotations.router)
app.include_router(khatma.router)
app.include_router(quran.router)


@app.on_event("startup")
async def _group_khatma_cleanup() -> None:
    """Delete expired group khatmas every 6 hours (and lazily on requests)."""
    import asyncio
    import logging

    from starlette.concurrency import run_in_threadpool

    from . import group_khatma
    from .db import SessionLocal

    def sweep() -> None:
        db = SessionLocal()
        try:
            group_khatma.cleanup(db)
        finally:
            db.close()

    async def loop() -> None:
        while True:
            try:
                await run_in_threadpool(sweep)
            except Exception:  # keep the loop alive
                logging.getLogger(__name__).exception("group khatma cleanup")
            await asyncio.sleep(6 * 3600)

    app.state.group_khatma_cleanup = asyncio.create_task(loop())


# ---------- branded error pages (HTML clients only; APIs keep JSON) ----------
ERROR_PAGES = (404, 429, 500)


def _wants_html(request: Request) -> bool:
    return (
        not request.url.path.startswith("/api/")
        and "text/html" in request.headers.get("accept", "")
    )


def error_page(request: Request, code: int):
    lang = get_lang(request)
    return templates.TemplateResponse(
        request,
        "error.html",
        {
            "code": code,
            "lang": lang,
            "dir": "rtl" if lang == "ar" else "ltr",
            "t": lambda key: translate(lang, key),
        },
        status_code=code,
        headers={"Cache-Control": "no-store"},
    )


@app.exception_handler(StarletteHTTPException)
async def html_http_errors(request: Request, exc: StarletteHTTPException):
    if exc.status_code in ERROR_PAGES and _wants_html(request):
        return error_page(request, exc.status_code)
    return await http_exception_handler(request, exc)


@app.exception_handler(Exception)
async def html_server_error(request: Request, exc: Exception):
    # Starlette re-raises after this response, so the traceback is still logged.
    if _wants_html(request):
        return error_page(request, 500)
    from fastapi.responses import PlainTextResponse

    return PlainTextResponse("Internal Server Error", status_code=500)
