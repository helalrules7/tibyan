from __future__ import annotations

from pathlib import Path

from fastapi.templating import Jinja2Templates

_templates_dir = Path(__file__).parent / "templates"
_static_dir = Path(__file__).parent / "static"

templates = Jinja2Templates(directory=str(_templates_dir))
STATIC_DIR = str(_static_dir)
