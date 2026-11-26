"""The one place for Tibyan's store links and their status.

Each entry is either live (a real link) or "soon" (shown as «قريبًا», no
link). Direct downloads point at /download/<platform>, which redirects to
the newest release asset and counts the download (routes/beta.py).
"""
from __future__ import annotations

from dataclasses import dataclass

LIVE = "live"
SOON = "soon"

APT_SETUP = "curl -fsSL https://apt.altibyan.app/setup.sh | sudo bash"
APT_INSTALL = "sudo apt install tibyan"


@dataclass(frozen=True)
class Store:
    key: str
    os: str  # android / ios / macos / windows / linux: used to highlight the visitor's OS
    name_ar: str
    name_en: str
    kind_ar: str
    kind_en: str
    url: str | None
    status: str = LIVE

    @property
    def live(self) -> bool:
        return self.status == LIVE and bool(self.url)

    def name(self, ar: bool) -> str:
        return self.name_ar if ar else self.name_en

    def kind(self, ar: bool) -> str:
        return self.kind_ar if ar else self.kind_en


# Official stores, in the order the home page shows them.
STORES: tuple[Store, ...] = (
    Store("google-play", "android", "Google Play", "Google Play", "أندرويد", "Android",
          "https://play.google.com/store/apps/details?id=app.tibyan.tibyan"),
    Store("app-store", "ios", "App Store", "App Store", "آيفون وآيباد", "iPhone and iPad",
          "https://apps.apple.com/app/id6818990351", SOON),
    Store("mac-app-store", "macos", "Mac App Store", "Mac App Store", "ماك", "Mac",
          "https://apps.apple.com/app/id6818990351?platform=mac", SOON),
    Store("microsoft-store", "windows", "Microsoft Store", "Microsoft Store", "ويندوز", "Windows",
          "https://apps.microsoft.com/detail/9N944SZ21PTS"),
    Store("appgallery", "android", "AppGallery", "AppGallery", "هواوي", "Huawei",
          "https://appgallery.huawei.com/app/C119643893"),
)

# Direct downloads (outside the stores), all through the counted redirect.
DIRECT: tuple[Store, ...] = (
    Store("apk", "android", "ملف APK", "APK file", "أندرويد", "Android", "/download/android"),
    Store("windows-setup", "windows", "مثبّت ويندوز", "Windows Setup", "Setup.exe", "Setup.exe",
          "/download/windows"),
    Store("linux-deb", "linux", "لينكس · deb", "Linux (.deb)", "apt.altibyan.app", "apt.altibyan.app",
          "#linux"),
    Store("linux-appimage", "linux", "لينكس · AppImage", "Linux (AppImage)", "AppImage", "AppImage",
          "/download/linux-appimage"),
)

ALL: tuple[Store, ...] = STORES + DIRECT
BY_KEY = {s.key: s for s in ALL}


def get(key: str) -> Store:
    return BY_KEY[key]


def detect_os(user_agent: str | None) -> str | None:
    """Best-effort OS from a User-Agent; None when unknown (bots, empty)."""
    ua = (user_agent or "").lower()
    if not ua:
        return None
    if "android" in ua:
        return "android"
    if "iphone" in ua or "ipad" in ua or "ipod" in ua:
        return "ios"
    if "windows" in ua:
        return "windows"
    if "macintosh" in ua or "mac os x" in ua:
        return "macos"
    if "linux" in ua or "x11" in ua:
        return "linux"
    return None
