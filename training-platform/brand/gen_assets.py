#!/usr/bin/env python3
"""Regenerate the site's brand assets from the app's logo and cover C.

Sources (never edited here):
  assets/brand/tibyan_logo.svg          the logo, copied byte-for-byte
  docs/brand/facebook/src/gen.py        cover C: teal field, khatam lattice, gold star

Outputs in app/static/:
  brand/tibyan-logo.svg                 unchanged copy (CSS mask; takes currentColor)
  brand/pattern.svg                     khatam tile, black strokes (used as a CSS mask)
  brand/logo-cream.png                 raster logo for e-mail
  favicon.ico, favicon.svg, favicon-32.png (16-32 px drawn without the grid),
  apple-touch-icon.png, ... (from docs/brand/facebook/profile_teal@2x.png)
  icon-192.png, icon-512.png, icon-maskable-192.png, icon-maskable-512.png
  share.png, coming-soon-share.png      1200x630 social images

Needs rsvg-convert, ImageMagick (`magick`) and Google Chrome (headless).
Usage: python3 brand/gen_assets.py   (from training-platform/)
"""
from __future__ import annotations

import math
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
TP = HERE.parent
REPO = TP.parent
STATIC = TP / "app" / "static"
BRAND = STATIC / "brand"
LOGO_SRC = REPO / "assets" / "brand" / "tibyan_logo.svg"
# Approved profile picture (cream logo in a gold star on the teal star grid):
# the source of every favicon / app icon from 48 px up.
PROFILE = HERE / "profile_teal@2x.png"  # copy of docs/brand/facebook/profile_teal@2x.png
FONTS = STATIC / "fonts"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

TEAL, TEAL_HI, TEAL_LO = "#0F6660", "#11706A", "#0A4F4A"
CREAM, GOLD, MINT, SOFT = "#F6F1E8", "#D9B266", "#55BDB2", "#CFE3DF"
LOGO_W, LOGO_H = 1392, 1019


def star_pts(cx, cy, r, inner=0.7654):
    """8-point star outline (same geometry as gen.py / the app's StarPainter)."""
    pts = []
    for i in range(16):
        a = math.pi / 8 * i - math.pi / 2
        rr = r if i % 2 == 0 else r * inner
        pts.append(f"{cx + rr * math.cos(a):.2f},{cy + rr * math.sin(a):.2f}")
    return " ".join(pts)


def khatam(size, stroke, op, sw=1.2, pid="kh"):
    s, r = size, size * 0.36
    corners = "".join(f'<polygon points="{star_pts(x, y, r)}"/>' for x, y in [(0, 0), (s, 0), (0, s), (s, s)])
    return (f'<pattern id="{pid}" width="{s}" height="{s}" patternUnits="userSpaceOnUse">'
            f'<g fill="none" stroke="{stroke}" stroke-opacity="{op}" stroke-width="{sw}">'
            f'<polygon points="{star_pts(s / 2, s / 2, r)}"/>{corners}'
            f'<circle cx="{s / 2}" cy="{s / 2}" r="{r * 0.42:.2f}"/></g></pattern>')


def logo_path() -> str:
    return re.search(r'\sd="([^"]+)"', LOGO_SRC.read_text()).group(1)


def logo_group(color, x, y, w):
    k = w / LOGO_W
    return (f'<g transform="translate({x:.1f} {y:.1f}) scale({k:.5f})">'
            f'<path fill="{color}" d="{logo_path()}"/></g>')


def run(*cmd):
    subprocess.run(cmd, check=True, capture_output=True)


def svg_to_png(svg: str, out: Path, w: int, h: int):
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as f:
        f.write(svg)
    run("rsvg-convert", "-w", str(w), "-h", str(h), "-o", str(out), f.name)


def tile_svg():
    s, r = 104, 104 * 0.36
    corners = "".join(f'<polygon points="{star_pts(x, y, r)}"/>' for x, y in [(0, 0), (s, 0), (0, s), (s, s)])
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{s}" height="{s}" viewBox="0 0 {s} {s}">'
            f'<g fill="none" stroke="#000" stroke-width="1.2"><polygon points="{star_pts(s / 2, s / 2, r)}"/>'
            f'{corners}<circle cx="{s / 2}" cy="{s / 2}" r="{r * 0.42:.2f}"/></g></svg>\n')


def small_icon_svg(S):
    """16-32 px: the profile picture without its faint grid (teal, gold star, cream logo)."""
    star_r = S * 0.49
    lw = S * 0.66
    lh = lw * LOGO_H / LOGO_W
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {S} {S}">'
            f'<rect width="{S}" height="{S}" rx="{S * 0.18:.1f}" fill="{TEAL}"/>'
            f'<polygon points="{star_pts(S / 2, S / 2, star_r, .83)}" fill="{TEAL}" stroke="{GOLD}" '
            f'stroke-width="{max(1.0, S * 0.035):.2f}"/>'
            f'{logo_group(CREAM, (S - lw) / 2, (S - lh) / 2, lw)}</svg>')


def from_profile(out: Path, size: int, pad: float = 0.0):
    """Resize the profile picture; `pad` shrinks it onto a teal canvas (maskable safe zone)."""
    inner = round(size * (1 - 2 * pad))
    run("magick", str(PROFILE), "-resize", f"{inner}x{inner}", "-background", TEAL,
        "-gravity", "center", "-extent", f"{size}x{size}", "-strip", str(out))


SHARE_HTML = """<!doctype html><html dir="rtl" lang="ar"><head><meta charset="utf-8"><style>
@font-face{font-family:Changa;src:url('file://FONTS/Changa.ttf')}
@font-face{font-family:Digits;src:url('file://FONTS/IBMPlexSansArabic-Medium.ttf');unicode-range:U+0030-0039,U+0660-0669}
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:1200px;height:630px;overflow:hidden}
body{position:relative;font-family:Digits,Changa,sans-serif;color:#F6F1E8;-webkit-font-smoothing:antialiased}
.abs{position:absolute}
</style></head><body>BODY</body></html>"""


def share_image(out: Path, title: str, sub: str, chips: list[str], url: str):
    W, H = 1200, 630
    cx, cy = 300, 315
    bg = (f'<svg class="abs" width="{W}" height="{H}" style="left:0;top:0"><defs>{khatam(96, CREAM, .06)}'
          f'<linearGradient id="t" x1="1" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{TEAL_HI}"/>'
          f'<stop offset="1" stop-color="{TEAL_LO}"/></linearGradient>'
          f'<radialGradient id="hl" cx="25%" cy="45%" r="45%"><stop offset="0" stop-color="{MINT}" stop-opacity=".22"/>'
          f'<stop offset="1" stop-color="{MINT}" stop-opacity="0"/></radialGradient></defs>'
          f'<rect width="{W}" height="{H}" fill="url(#t)"/><rect width="{W}" height="{H}" fill="url(#kh)"/>'
          f'<rect width="{W}" height="{H}" fill="url(#hl)"/>'
          f'<polygon points="{star_pts(cx, cy, 250, .78)}" fill="{CREAM}" fill-opacity=".045" stroke="{GOLD}" stroke-opacity=".55" stroke-width="1.4"/>'
          f'<polygon points="{star_pts(cx, cy, 234, .78)}" fill="none" stroke="{GOLD}" stroke-opacity=".25" stroke-width="1"/>'
          f'{logo_group(CREAM, cx - 160, cy - 160 * LOGO_H / LOGO_W - 6, 320)}</svg>')
    dot = f'<svg width="10" height="10" viewBox="0 0 20 20"><polygon points="{star_pts(10, 10, 9)}" fill="{GOLD}"/></svg>'
    chip_html = "".join(f'<span style="display:inline-flex;align-items:center;gap:10px">{dot}{c}</span>' for c in chips)
    text = (f'<div class="abs" style="right:70px;top:170px;width:560px;text-align:right">'
            f'<div style="font-weight:600;font-size:54px;line-height:1.25">{title}</div>'
            f'<div style="margin-top:14px;font-size:26px;color:{SOFT};line-height:1.5">{sub}</div>'
            f'<div style="margin-top:34px;display:flex;gap:28px;font-size:24px;font-weight:500">{chip_html}</div>'
            f'<div dir="ltr" style="margin-top:38px;font-size:20px;letter-spacing:.06em;color:{GOLD};text-align:right">{url}</div></div>')
    html = SHARE_HTML.replace("FONTS", str(FONTS)).replace("BODY", bg + text)
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False) as f:
        f.write(html)
    run(CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
        "--force-device-scale-factor=1", f"--window-size={W},{H}", "--virtual-time-budget=3000",
        f"--screenshot={out}", "file://" + f.name)


def main():
    BRAND.mkdir(exist_ok=True)
    shutil.copyfile(LOGO_SRC, BRAND / "tibyan-logo.svg")
    (BRAND / "pattern.svg").write_text(tile_svg())

    # e-mail logos (PNG: mail clients do not render SVG)
    for name, color in (("logo-cream", CREAM),):
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {LOGO_W} {LOGO_H}">'
               f'<path fill="{color}" d="{logo_path()}"/></svg>')
        svg_to_png(svg, BRAND / f"{name}.png", 280, round(280 * LOGO_H / LOGO_W))

    (STATIC / "favicon.svg").write_text(small_icon_svg(64))
    tmp = Path(tempfile.mkdtemp())
    for s in (16, 32, 48):
        svg_to_png(small_icon_svg(s), tmp / f"f{s}.png", s, s)
    shutil.copyfile(tmp / "f32.png", STATIC / "favicon-32.png")
    from_profile(tmp / "f48.png", 48)
    run("magick", str(tmp / "f16.png"), str(tmp / "f32.png"), str(tmp / "f48.png"), str(STATIC / "favicon.ico"))

    from_profile(STATIC / "apple-touch-icon.png", 180)
    for s in (192, 512):
        from_profile(STATIC / f"icon-{s}.png", s)
        # maskable: whole picture inside the 80% safe zone, teal bleed around it
        from_profile(STATIC / f"icon-maskable-{s}.png", s, pad=0.1)

    share_image(STATIC / "share.png", "منصة تدريب نموذج التسميع",
                "سجّل تلاوتك من حفظك، وساعد في تدريب نموذج التسميع القرآني.",
                ["سجّل", "راجع", "درّب"], "train.altibyan.app")
    share_image(STATIC / "coming-soon-share.png", "مصحفك… بهدوء",
                "تطبيق قرآن غير ربحي بلا إعلانات. متاح الآن.",
                ["اقرأ", "استمع", "احفظ"], "altibyan.app")
    print("brand assets written to", STATIC)


if __name__ == "__main__":
    main()
