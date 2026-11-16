#!/usr/bin/env python3
"""Generate Apple App Store Promotional Graphics matching the Tibyan luxury brand style:
1. Header Art:
   - 3840 x 1646 px
   - 5244 x 2950 px
2. Search Results Art:
   - 1920 x 1280 px
   - 3840 x 2560 px
   - 5244 x 2950 px

Featuring:
- Foldable iPhone Duo (Landscape open fold with two facing Mushaf pages)
- iPhone Portrait (Modern iPhone showing listening & illuminated ayah reading)
- Apple Watch Ultra (Titanium watch showing smart misbaha with gold progress ring)
- Official Tibyan calligraphic logo, Changa bold typography, feature pills, and trust highlights.
"""
import math, os, subprocess
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../..'))
STORE = os.path.join(ROOT, 'docs/brand/store')
GRAPHICS = os.path.join(STORE, 'graphics')
ASSETS = os.path.join(GRAPHICS, 'assets')
FONTS = os.path.join(ROOT, 'assets/fonts/ofl')
LOGO_SVG = os.path.join(STORE, 'src/logo_F6F1E8.svg')
CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'

TEAL_1 = '#11706A'
TEAL_2 = '#0A4F4A'
DEEP_BG = '#041B19'
CREAM = '#F6F1E8'
GOLD = '#D9B266'
GOLD_LIGHT = '#ECC87D'
MINT = '#CFE3DF'
GLOW = '#55BDB2'

DUO_PATH = os.path.join(ASSETS, 'device_duo_landscape.png')
IPHONE_PATH = os.path.join(ASSETS, 'device_iphone_portrait.png')
WATCH_PATH = os.path.join(ASSETS, 'device_watch_ultra.png')

def star_pts(cx, cy, r, inner=0.7654):
    pts = []
    for i in range(16):
        a = math.pi / 8 * i - math.pi / 2
        rr = r if i % 2 == 0 else r * inner
        pts.append(f"{cx + rr * math.cos(a):.2f},{cy + rr * math.sin(a):.2f}")
    return ' '.join(pts)

def khatam_tile(size, stroke, op, sw=1.2):
    s = size
    r = s * 0.36
    star = star_pts(s / 2, s / 2, r)
    corners = ''.join(f'<polygon points="{star_pts(x, y, r)}"/>' for x, y in [(0, 0), (s, 0), (0, s), (s, s)])
    return (f'<pattern id="kh" width="{s}" height="{s}" patternUnits="userSpaceOnUse">'
            f'<g fill="none" stroke="{stroke}" stroke-opacity="{op}" stroke-width="{sw}">'
            f'<polygon points="{star}"/>{corners}'
            f'<circle cx="{s/2}" cy="{s/2}" r="{r*0.42:.2f}"/></g></pattern>')

def font_css():
    f = 'file://' + FONTS
    return f'''
@font-face {{ font-family: 'Plex'; src: url('{f}/ibmplexsansarabic/IBMPlexSansArabic-Medium.ttf'); font-weight: 500; }}
@font-face {{ font-family: 'Plex'; src: url('{f}/ibmplexsansarabic/IBMPlexSansArabic-SemiBold.ttf'); font-weight: 600; }}
@font-face {{ font-family: 'Plex'; src: url('{f}/ibmplexsansarabic/IBMPlexSansArabic-Bold.ttf'); font-weight: 700; }}
@font-face {{ font-family: 'Changa'; src: url('{f}/changa/Changa%5Bwght%5D.ttf'); font-weight: 700; }}
@font-face {{ font-family: 'PlexLatin'; src: url('{f}/ibmplexsans/IBMPlexSans%5Bwdth,wght%5D.ttf'); font-weight: 100 700; }}
'''

COPY = {
    'ar': {
        'title': 'تبيان — القرآن الكريم',
        'sub': 'مصحف شامل: استماع وتفسير وتسميع',
        'pills': [
            ('اقرأ', '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20 M4 4.5A2.5 2.5 0 0 1 6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15z"/>'),
            ('استمع', '<path d="M3 18v-6a9 9 0 0 1 18 0v6 M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z"/>'),
            ('احفظ', '<path d="M22 11.08V12a10 10 0 1 1-5.93-9.14 M22 4L12 14.01l-3-3"/>'),
            ('سمّع', '<path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z M19 10v2a7 7 0 0 1-14 0v-2 M12 19v4 M8 23h8"/>'),
            ('المسبحة والورد', '<circle cx="12" cy="12" r="7"/><polyline points="12 9 12 12 13.5 13.5"/><path d="M16.51 17.35l-.35 3.83a2 2 0 0 1-2 1.82H9.83a2 2 0 0 1-2-1.82l-.35-3.83m.01-10.7l.35-3.83A2 2 0 0 1 9.83 1h4.35a2 2 0 0 1 2 1.82l.35 3.83"/>'),
        ],
        'bullets': [
            '✦ يعمل دون إنترنت',
            '✦ متوافق مع كافة أجهزة Apple',
        ],
        'duo_badge': 'صفحتان متقابلتان كالمصحف الشريف',
        'dir': 'rtl',
        'font_title': 'Changa, Plex, sans-serif',
        'font_body': 'Plex, sans-serif',
    },
    'en': {
        'title': 'Tibyan — The Holy Quran',
        'sub': 'Complete Mushaf: Listen, Tafsir & Smart Recitation',
        'pills': [
            ('Read', '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20 M4 4.5A2.5 2.5 0 0 1 6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15z"/>'),
            ('Listen', '<path d="M3 18v-6a9 9 0 0 1 18 0v6 M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z"/>'),
            ('Memorize', '<path d="M22 11.08V12a10 10 0 1 1-5.93-9.14 M22 4L12 14.01l-3-3"/>'),
            ('Recite', '<path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z M19 10v2a7 7 0 0 1-14 0v-2 M12 19v4 M8 23h8"/>'),
            ('Watch & Dhikr', '<circle cx="12" cy="12" r="7"/><polyline points="12 9 12 12 13.5 13.5"/><path d="M16.51 17.35l-.35 3.83a2 2 0 0 1-2 1.82H9.83a2 2 0 0 1-2-1.82l-.35-3.83m.01-10.7l.35-3.83A2 2 0 0 1 9.83 1h4.35a2 2 0 0 1 2 1.82l.35 3.83"/>'),
        ],
        'bullets': [
            '✦ Offline Ready',
            '✦ Built for Apple Ecosystem',
        ],
        'duo_badge': 'Two Facing Pages Like the Printed Mushaf',
        'dir': 'ltr',
        'font_title': 'PlexLatin, Changa, sans-serif',
        'font_body': 'PlexLatin, Plex, sans-serif',
    }
}

def render_artwork(w, h, kind='header', lang='ar', out_png=''):
    c = COPY[lang]
    is_rtl = c['dir'] == 'rtl'
    
    # Scale reference: base width 3840
    scale = w / 3840.0
    
    tile_size = int(140 * scale)
    tile_svg = khatam_tile(tile_size, CREAM, 0.05, 1.4 * scale)
    
    # Background decorations
    # Big watermark star behind devices
    star_cx = int(w * 0.28 if is_rtl else w * 0.72)
    star_cy = int(h * 0.52)
    star_r1 = int(min(w, h) * 0.46)
    star_r2 = int(star_r1 * 0.88)
    star1_pts = star_pts(star_cx, star_cy, star_r1)
    star2_pts = star_pts(star_cx, star_cy, star_r2)
    
    # Device positioning based on aspect ratio
    # If ratio is ultra-wide (~2.33:1 like 3840x1646): side-by-side
    # If ratio is 3:2 (~1.5:1 like 3840x2560, 1920x1280): taller arrangement
    is_tall = (h / w) > 0.55
    
    if not is_tall:
        # Header wide banner layout (e.g. 3840x1646)
        duo_w = int(1560 * scale)
        duo_h = int(duo_w * (1595 / 2169))
        duo_left = int(w * 0.045 if is_rtl else w - duo_w - w * 0.045)
        duo_top = int(h * 0.5 - duo_h * 0.5 + 20 * scale)
        
        phone_w = int(620 * scale)
        phone_h = int(phone_w * (1979 / 982))
        phone_left = int(w * 0.02 if is_rtl else w - phone_w - w * 0.02)
        phone_top = int(duo_top + duo_h * 0.03)
        
        watch_w = int(490 * scale)
        watch_h = int(watch_w * (1053 / 916))
        watch_left = int((duo_left + duo_w - watch_w * 0.70) if is_rtl else (duo_left - watch_w * 0.30))
        watch_top = int(duo_top + duo_h - watch_h * 0.75)
        
        # Content box - bold and expansive
        content_w = int(w * 0.48)
        content_side = f"{'right' if is_rtl else 'left'}:{int(w * 0.04)}px;"
        content_top = int(h * 0.5 - 680 * scale)
        
        logo_w = int(880 * scale)
        logo_h = int(380 * scale)
        title_size = int(165 * scale)
        sub_size = int(58 * scale)
        pill_font_size = int(44 * scale)
        pill_icon_size = int(42 * scale)
        bullet_size = int(38 * scale)
        pill_pad_v = int(22 * scale)
        pill_pad_h = int(44 * scale)
        pill_gap = int(22 * scale)
        content_gap = int(40 * scale)
        
    else:
        # 3:2 and 16:9 tall banner layout (e.g. 3840x2560, 5244x2950, 1920x1280)
        duo_w = int(1850 * scale)
        duo_h = int(duo_w * (1595 / 2169))
        duo_left = int(w * 0.045 if is_rtl else w - duo_w - w * 0.045)
        duo_top = int(h * 0.5 - duo_h * 0.5 + 40 * scale)
        
        phone_w = int(740 * scale)
        phone_h = int(phone_w * (1979 / 982))
        phone_left = int(w * 0.018 if is_rtl else w - phone_w - w * 0.018)
        phone_top = int(duo_top - 30 * scale)
        
        watch_w = int(590 * scale)
        watch_h = int(watch_w * (1053 / 916))
        watch_left = int((duo_left + duo_w - watch_w * 0.65) if is_rtl else (duo_left - watch_w * 0.35))
        watch_top = int(duo_top + duo_h - watch_h * 0.72)
        
        # Content box - bold and expansive
        content_w = int(w * 0.48)
        content_side = f"{'right' if is_rtl else 'left'}:{int(w * 0.04)}px;"
        content_top = int(h * 0.5 - 900 * scale)
        
        logo_w = int(960 * scale)
        logo_h = int(420 * scale)
        title_size = int(178 * scale)
        sub_size = int(64 * scale)
        pill_font_size = int(48 * scale)
        pill_icon_size = int(46 * scale)
        bullet_size = int(42 * scale)
        pill_pad_v = int(24 * scale)
        pill_pad_h = int(48 * scale)
        pill_gap = int(24 * scale)
        content_gap = int(48 * scale)

    # Build pills HTML
    pills_html = []
    for label, icon_svg in c['pills']:
        pills_html.append(f'''
        <div style="display:inline-flex;align-items:center;gap:{int(16*scale)}px;padding:{pill_pad_v}px {pill_pad_h}px;border-radius:999px;background:rgba(10,63,59,0.85);backdrop-filter:blur(20px);border:3px solid rgba(217,178,102,0.75);box-shadow:0 12px 35px rgba(0,0,0,0.45);">
          <svg width="{pill_icon_size}" height="{pill_icon_size}" viewBox="0 0 24 24" fill="none" stroke="{GOLD_LIGHT}" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">{icon_svg}</svg>
          <span style="font-size:{pill_font_size}px;font-weight:700;color:{CREAM};white-space:nowrap;">{label}</span>
        </div>
        ''')
    pills_joined = ''.join(pills_html)
    
    # Build bullets HTML
    bullets_html = ''.join(f'<span style="white-space:nowrap;">{b}</span>' for b in c['bullets'])
    
    html = f'''<!doctype html>
<html dir="{c['dir']}" lang="{lang}">
<head>
<meta charset="utf-8">
<style>
{font_css()}
* {{ margin:0; padding:0; box-sizing:border-box; }}
html, body {{
  width: {w}px;
  height: {h}px;
  overflow: hidden;
  background: {DEEP_BG};
  font-family: {c['font_body']};
  -webkit-font-smoothing: antialiased;
}}
.abs {{ position: absolute; }}
</style>
</head>
<body>

<!-- Background Artwork -->
<svg class="abs" width="{w}" height="{h}" viewBox="0 0 {w} {h}">
  <defs>
    {tile_svg}
    <linearGradient id="bg" x1="1" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="{TEAL_1}"/>
      <stop offset="55%" stop-color="{TEAL_2}"/>
      <stop offset="100%" stop-color="{DEEP_BG}"/>
    </linearGradient>
    <radialGradient id="hl" cx="{'28%' if is_rtl else '72%'}" cy="50%" r="55%">
      <stop offset="0%" stop-color="{GLOW}" stop-opacity="0.28"/>
      <stop offset="60%" stop-color="{GLOW}" stop-opacity="0.08"/>
      <stop offset="100%" stop-color="{GLOW}" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="glow_brand" cx="{'80%' if is_rtl else '20%'}" cy="25%" r="45%">
      <stop offset="0%" stop-color="{GOLD}" stop-opacity="0.12"/>
      <stop offset="100%" stop-color="{GOLD}" stop-opacity="0"/>
    </radialGradient>
  </defs>
  
  <rect width="{w}" height="{h}" fill="url(#bg)"/>
  <rect width="{w}" height="{h}" fill="url(#kh)"/>
  <rect width="{w}" height="{h}" fill="url(#hl)"/>
  <rect width="{w}" height="{h}" fill="url(#glow_brand)"/>
  
  <!-- Decorative Girih Stars Watermark -->
  <polygon points="{star1_pts}" fill="{CREAM}" fill-opacity="0.035" stroke="{GOLD}" stroke-opacity="0.35" stroke-width="{2.2*scale:.1f}"/>
  <polygon points="{star2_pts}" fill="none" stroke="{GOLD_LIGHT}" stroke-opacity="0.2" stroke-width="{1.4*scale:.1f}"/>
</svg>

<!-- Device Trio (Left Side) -->

<!-- 1. iPhone Duo (Foldable landscape open) -->
<div class="abs" style="left:{duo_left}px;top:{duo_top}px;width:{duo_w}px;height:{duo_h}px;filter:drop-shadow(0 {40*scale:.0f}px {80*scale:.0f}px rgba(0,0,0,0.75)) drop-shadow(0 0 {60*scale:.0f}px rgba(85,189,178,0.22));">
  <img src="file://{DUO_PATH}" style="width:100%;height:100%;display:block;"/>
</div>

<!-- 2. iPhone Portrait (Elevated on the outer side) -->
<div class="abs" style="left:{phone_left}px;top:{phone_top}px;width:{phone_w}px;height:{phone_h}px;transform:rotate({' -2deg' if is_rtl else ' 2deg'});filter:drop-shadow(0 {35*scale:.0f}px {70*scale:.0f}px rgba(0,0,0,0.85)) drop-shadow(0 0 {25*scale:.0f}px rgba(217,178,102,0.18));">
  <img src="file://{IPHONE_PATH}" style="width:100%;height:100%;display:block;"/>
</div>

<!-- 3. Apple Watch Ultra (Sitting proudly in foreground) -->
<div class="abs" style="left:{watch_left}px;top:{watch_top}px;width:{watch_w}px;height:{watch_h}px;transform:rotate({' 3deg' if is_rtl else ' -3deg'});filter:drop-shadow(0 {30*scale:.0f}px {60*scale:.0f}px rgba(0,0,0,0.9)) drop-shadow(0 0 {30*scale:.0f}px rgba(85,189,178,0.25));">
  <img src="file://{WATCH_PATH}" style="width:100%;height:100%;display:block;"/>
</div>

<!-- Content & Branding (Right Side) -->
<div class="abs" style="{content_side}top:{content_top}px;width:{content_w}px;text-align:{'right' if is_rtl else 'left'};display:flex;flex-direction:column;gap:{content_gap}px;">
  
  <!-- Logo -->
  <div style="width:{logo_w}px;height:{logo_h}px;background:url('file://{LOGO_SVG}') {'right' if is_rtl else 'left'} center/contain no-repeat;filter:drop-shadow(0 4px 15px rgba(0,0,0,0.5));"></div>
  
  <!-- Title & Subtitle -->
  <div>
    <h1 style="font-family:{c['font_title']};font-size:{title_size}px;font-weight:700;color:{CREAM};line-height:1.2;text-shadow:0 {4*scale:.0f}px {18*scale:.0f}px rgba(0,0,0,0.6);">
      {c['title']}
    </h1>
    <p style="font-family:{c['font_body']};font-size:{sub_size}px;font-weight:500;color:{MINT};margin-top:{int(12*scale)}px;line-height:1.4;text-shadow:0 {2*scale:.0f}px {10*scale:.0f}px rgba(0,0,0,0.4);">
      {c['sub']}
    </p>
  </div>
  
  <!-- Feature Pills -->
  <div style="display:flex;flex-wrap:wrap;gap:{pill_gap}px;margin-top:{int(8*scale)}px;">
    {pills_joined}
  </div>
  
  <!-- Trust & Value propositions -->
  <div style="display:flex;flex-wrap:wrap;gap:{int(20*scale)}px;margin-top:{int(10*scale)}px;color:{GOLD_LIGHT};font-size:{bullet_size}px;font-weight:600;text-shadow:0 {2*scale:.0f}px {8*scale:.0f}px rgba(0,0,0,0.6);">
    {bullets_html}
  </div>

</div>

</body>
</html>'''

    tmp_html = os.path.join(STORE, f'src/_tmp_render_{w}x{h}_{lang}.html')
    with open(tmp_html, 'w') as f:
        f.write(html)
        
    os.makedirs(os.path.dirname(out_png), exist_ok=True)
    
    cmd = [
        CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars',
        '--allow-file-access-from-files', '--force-device-scale-factor=1',
        f'--window-size={w},{h}', '--virtual-time-budget=3000',
        f'--screenshot={out_png}', 'file://' + tmp_html
    ]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    if os.path.exists(tmp_html):
        os.remove(tmp_html)
        
    # Ensure RGB PNG without alpha as per App Store specification
    im = Image.open(out_png).convert('RGB')
    im.save(out_png, quality=95)
    print(f"Generated [{kind}] {out_png} ({im.size})")

def main():
    # 1. Header Art: 3840x1646 and 5244x2950
    header_sizes = [(3840, 1646), (5244, 2950)]
    for lang in ['ar', 'en']:
        for w, h in header_sizes:
            out_p = os.path.join(GRAPHICS, 'header', lang, f'{w}x{h}.png')
            render_artwork(w, h, kind='header', lang=lang, out_png=out_p)
            
    # 2. Search Results Art: 1920x1280, 3840x2560, and 5244x2950
    search_sizes = [(1920, 1280), (3840, 2560), (5244, 2950)]
    for lang in ['ar', 'en']:
        for w, h in search_sizes:
            out_p = os.path.join(GRAPHICS, 'search_results', lang, f'{w}x{h}.png')
            render_artwork(w, h, kind='search_results', lang=lang, out_png=out_p)

if __name__ == '__main__':
    main()
