from __future__ import annotations

import unittest
from unittest.mock import patch

from fastapi import FastAPI
from fastapi.testclient import TestClient
from starlette.middleware.sessions import SessionMiddleware

from app import releases
from app.routes import beta

GH = "https://github.com/helalrules7/tibyan/releases/download"


def asset(tag, name, size=262_717_575):
    return {"name": name, "size": size, "browser_download_url": f"{GH}/{tag}/{name}"}


RELEASES = [
    {"tag_name": "v0.6.0", "draft": True, "prerelease": True,
     "assets": [asset("v0.6.0", "tibyan-0.6.0-universal.apk")]},
    {"tag_name": "v0.5.0", "draft": False, "prerelease": True, "assets": [
        asset("v0.5.0", "SHA256SUMS.txt", 651),
        asset("v0.5.0", "tibyan-0.5.0-android-armeabi-v7a.apk"),
        asset("v0.5.0", "tibyan-0.5.0-android-arm64-v8a.apk", 90_000_000),
        asset("v0.5.0", "tibyan-0.5.0-universal.apk"),
        asset("v0.5.0", "tibyan-0.5.0-macos.zip", 141_878_800),
        asset("v0.5.0", "tibyan-0.5.0-windows-x64.zip"),
    ]},
    {"tag_name": "v0.4.0", "draft": False, "prerelease": False, "assets": [
        asset("v0.4.0", "app-release.apk"),
        asset("v0.4.0", "tibyan-0.4.0-linux-x64.tar.gz"),
    ]},
]


class DownloadsTest(unittest.TestCase):
    def setUp(self):
        releases.reset()
        app = FastAPI()
        app.add_middleware(SessionMiddleware, secret_key="test-only", https_only=False)
        app.include_router(beta.router)
        self.client = TestClient(app, base_url="https://altibyan.app")

    def tearDown(self):
        releases.reset()

    def get(self, platform):
        return self.client.get(f"/download/{platform}", follow_redirects=False)

    def test_redirects_to_newest_prerelease_assets(self):
        with patch.object(releases, "_fetch", return_value=RELEASES):
            want = {
                "android": f"{GH}/v0.5.0/tibyan-0.5.0-android-arm64-v8a.apk",
                "android-armeabi-v7a": f"{GH}/v0.5.0/tibyan-0.5.0-android-armeabi-v7a.apk",
                "android-universal": f"{GH}/v0.5.0/tibyan-0.5.0-universal.apk",
                "macos": f"{GH}/v0.5.0/tibyan-0.5.0-macos.zip",
                "windows": f"{GH}/v0.5.0/tibyan-0.5.0-windows-x64.zip",
                "linux": f"{GH}/v0.4.0/tibyan-0.4.0-linux-x64.tar.gz",  # older release fills the gap
            }
            for platform, url in want.items():
                r = self.get(platform)
                self.assertEqual(r.status_code, 302, platform)
                self.assertEqual(r.headers["location"], url)

    def test_android_falls_back_to_universal_without_split(self):
        only_universal = [{"tag_name": "v0.3.0", "draft": False,
                           "assets": [asset("v0.3.0", "tibyan-0.3.0-universal.apk")]}]
        with patch.object(releases, "_fetch", return_value=only_universal):
            r = self.get("android")
            self.assertEqual(r.headers["location"], f"{GH}/v0.3.0/tibyan-0.3.0-universal.apk")
            # No x86_64 build anywhere: the releases page.
            self.assertEqual(self.get("android-x86_64").headers["location"], releases.RELEASES_PAGE)

    def test_unknown_platform_404(self):
        self.assertEqual(self.get("ios").status_code, 404)

    def test_cache_hits_api_once(self):
        with patch.object(releases, "_fetch", return_value=RELEASES) as fetch:
            for _ in range(3):
                self.get("android")
                self.get("macos")
            self.assertEqual(fetch.call_count, 1)

    def test_cache_expires(self):
        with patch.object(releases, "_fetch", return_value=RELEASES) as fetch, \
                patch.object(releases, "_now", side_effect=[1000.0, 1000.0 + releases.CACHE_TTL + 1]):
            self.get("android")
            self.get("android")
            self.assertEqual(fetch.call_count, 2)

    def test_api_failure_falls_back_to_releases_page(self):
        with patch.object(releases, "_fetch", side_effect=OSError("down")):
            r = self.get("windows")
        self.assertEqual(r.status_code, 302)
        self.assertEqual(r.headers["location"], releases.RELEASES_PAGE)

    def test_failure_keeps_last_good_data(self):
        with patch.object(releases, "_fetch", return_value=RELEASES):
            self.get("android")
        releases._cache["at"] = 1.0  # force expiry
        with patch.object(releases, "_fetch", side_effect=OSError("down")):
            r = self.get("android")
        self.assertTrue(r.headers["location"].endswith("tibyan-0.5.0-android-arm64-v8a.apk"))

    def test_no_matching_asset_falls_back(self):
        with patch.object(releases, "_fetch", return_value=[RELEASES[2]]):
            self.assertEqual(self.get("macos").headers["location"], releases.RELEASES_PAGE)

class HeadTest(DownloadsTest):
    def test_head_redirects(self):
        with patch.object(releases, "_fetch", return_value=RELEASES):
            r = self.client.head("/download/macos", follow_redirects=False)
        self.assertEqual(r.status_code, 302)
        self.assertTrue(r.headers["location"].endswith("tibyan-0.5.0-macos.zip"))


class WindowsInstallerTest(unittest.TestCase):
    FEED = {"version": "0.8.3", "build": 48, "size": 40_000_000, "sha256": "ab" * 32,
            "url": "https://tibyan.ahmedhelal.dev/win/Tibyan-Windows-Setup-v0.8.3.exe"}

    def setUp(self):
        releases.reset()
        app = FastAPI()
        app.add_middleware(SessionMiddleware, secret_key="test-only", https_only=False)
        app.include_router(beta.router)
        self.client = TestClient(app, base_url="https://altibyan.app")

    def get(self, platform):
        return self.client.get(f"/download/{platform}", follow_redirects=False)

    def test_installer_preferred_and_zip_kept(self):
        with patch.object(releases, "_fetch", return_value=RELEASES), \
                patch.object(releases, "_fetch_win", return_value=self.FEED):
            self.assertEqual(self.get("windows").headers["location"], self.FEED["url"])
            self.assertEqual(self.get("windows-zip").headers["location"],
                             f"{GH}/v0.5.0/tibyan-0.5.0-windows-x64.zip")

    def test_feed_on_other_host_ignored(self):
        bad = dict(self.FEED, url="https://evil.example/x.exe")
        with patch.object(releases, "_fetch", return_value=RELEASES), \
                patch.object(releases, "_fetch_win", return_value=bad):
            self.assertEqual(self.get("windows").headers["location"],
                             f"{GH}/v0.5.0/tibyan-0.5.0-windows-x64.zip")
