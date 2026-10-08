from __future__ import annotations

import secrets

from fastapi import HTTPException, Request

from .config import settings
from .i18n import get_lang, t as translate
from .templating import templates


def msg(request: Request, key: str) -> str:
    """Translate a key into the request's current language."""
    return translate(get_lang(request), key)


def render(request: Request, template: str, **context):
    """Render a page with the current language, translations and CSRF."""
    lang = get_lang(request)
    context.setdefault("lang", lang)
    context.setdefault("dir", "rtl" if lang == "ar" else "ltr")
    context.setdefault("csrf", csrf_token(request))
    context.setdefault("site_url", settings.site_url)
    context["t"] = lambda key: translate(lang, key)
    return templates.TemplateResponse(request, template, context)


def csrf_token(request: Request) -> str:
    token = request.session.get("csrf")
    if not token:
        token = secrets.token_urlsafe(32)
        request.session["csrf"] = token
    return token


def check_csrf(request: Request, sent: str) -> None:
    if not sent or not secrets.compare_digest(request.session.get("csrf", ""), sent):
        raise HTTPException(status_code=400, detail="Invalid request.")


def redirect(path: str, code: int = 303):
    from starlette.responses import RedirectResponse

    return RedirectResponse(path, status_code=code)
