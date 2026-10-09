from __future__ import annotations

import re
import time
from datetime import date, datetime

from fastapi import APIRouter, Depends, Form, Request
from sqlalchemy.orm import Session
from starlette.responses import RedirectResponse

from ..config import settings
from ..deps import current_user, get_db
from ..models import User
from ..security import hash_password, verify_password
from ..web import check_csrf, msg, render

router = APIRouter()

_EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def _normalize_phone(raw: str) -> str:
    raw = raw.strip()
    plus = raw.startswith("+")
    digits = re.sub(r"\D", "", raw)
    return ("+" + digits) if plus and digits else digits


def may_be_minor(birth_year: int, today: date | None = None) -> bool:
    """True when someone born in birth_year could still be under adult_age.

    With only the year known, a person who turns adult_age this year may not
    have had the birthday yet, so that year still asks for guardian consent.
    """
    today = today or date.today()
    return today.year - birth_year <= settings.adult_age


def parse_birth_year(raw: str, today: date | None = None) -> int | None:
    today = today or date.today()
    raw = raw.strip()
    if not raw.isdigit():
        return None
    year = int(raw)
    if not (today.year - 120 <= year <= today.year):
        return None
    return year


@router.get("/register")
def register_form(request: Request, db: Session = Depends(get_db)):
    if current_user(request, db):
        return RedirectResponse("/dashboard", status_code=303)
    return _register_page(request, errors={}, old={})


def _register_page(request: Request, errors: dict, old: dict):
    this_year = date.today().year
    return render(
        request,
        "register.html",
        errors=errors,
        old=old,
        this_year=this_year,
        minor_from_year=this_year - settings.adult_age,
    )


@router.post("/register")
def register_submit(
    request: Request,
    db: Session = Depends(get_db),
    email: str = Form(""),
    phone: str = Form(""),
    password: str = Form(""),
    password_confirm: str = Form(""),
    birth_year: str = Form(""),
    consent: bool = Form(False),
    parental: bool = Form(False),
    csrf: str = Form(""),
):
    if current_user(request, db):
        return RedirectResponse("/dashboard", status_code=303)
    check_csrf(request, csrf)

    old = {
        "email": email,
        "phone": phone,
        "birth_year": birth_year,
        "consent": consent,
        "parental": parental,
    }
    errors = {}

    email = email.strip().lower()
    phone = _normalize_phone(phone)

    if email and not _EMAIL_RE.match(email):
        errors["email"] = msg(request, "err_email")
    if phone and not (7 <= len(re.sub(r"\D", "", phone)) <= 15):
        errors["phone"] = msg(request, "err_phone")
    if not email and not phone:
        errors["identifier"] = msg(request, "err_email_or_phone")

    if len(password) < 8:
        errors["password"] = msg(request, "err_password_short")
    if password != password_confirm:
        errors["password"] = msg(request, "err_password_mismatch")

    year = parse_birth_year(birth_year)
    if year is None:
        errors["birth"] = msg(request, "err_birth")

    if not consent:
        errors["consent"] = msg(request, "err_consent")

    minor = year is not None and may_be_minor(year)
    if minor and not parental:
        errors["parental"] = msg(request, "err_parental")

    if errors:
        return _register_page(request, errors=errors, old=old)

    if email and db.query(User).filter(User.email == email).first() is not None:
        errors["email"] = msg(request, "err_email_exists")
        return _register_page(request, errors=errors, old=old)
    if phone and db.query(User).filter(User.phone == phone).first() is not None:
        errors["phone"] = msg(request, "err_phone_exists")
        return _register_page(request, errors=errors, old=old)

    user = User(
        email=email or None,
        phone=phone or None,
        password_hash=hash_password(password),
        birth_year=year,
        consent_ccby=True,
        consent_parental=parental,
        consent_version=settings.consent_version,
        consent_at=datetime.utcnow(),
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    request.session.clear()
    request.session["user_id"] = user.id
    request.session["flash"] = msg(request, "success_registered")
    return RedirectResponse("/dashboard", status_code=303)


@router.get("/login")
def login_form(request: Request, db: Session = Depends(get_db)):
    if current_user(request, db):
        return RedirectResponse("/dashboard", status_code=303)
    return render(request, "login.html", errors=[], identifier="")


@router.post("/login")
def login_submit(
    request: Request,
    db: Session = Depends(get_db),
    identifier: str = Form(""),
    password: str = Form(""),
    csrf: str = Form(""),
):
    if current_user(request, db):
        return RedirectResponse("/dashboard", status_code=303)
    check_csrf(request, csrf)

    identifier = identifier.strip().lower()
    if _EMAIL_RE.match(identifier):
        user = db.query(User).filter(User.email == identifier).first()
    else:
        user = db.query(User).filter(User.phone == _normalize_phone(identifier)).first()

    if user is None or not verify_password(password, user.password_hash):
        time.sleep(0.3)  # flatten the timing difference
        return render(request, "login.html", errors=[msg(request, "err_login")], identifier=identifier)

    request.session.clear()
    request.session["user_id"] = user.id
    return RedirectResponse("/dashboard", status_code=303)


@router.get("/logout")
def logout_form(request: Request, db: Session = Depends(get_db)):
    user = current_user(request, db)
    return render(request, "logout.html", user=user)


@router.post("/logout")
def logout_submit(request: Request, csrf: str = Form("")):
    check_csrf(request, csrf)
    request.session.clear()
    return RedirectResponse("/", status_code=303)
