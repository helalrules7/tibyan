"""Small HTTP client for the platform's runner API (stdlib only)."""
from __future__ import annotations

import hashlib
import json
import time
import urllib.error
import urllib.request
from pathlib import Path

from .config import Config


class ApiError(Exception):
    def __init__(self, status: int, body: str):
        super().__init__(f"HTTP {status}: {body[:300]}")
        self.status = status
        self.body = body


class Api:
    def __init__(self, cfg: Config, retries: int = 5):
        self.cfg = cfg
        self.retries = retries

    def _headers(self, extra: dict | None = None) -> dict:
        h = {
            "Authorization": f"Bearer {self.cfg.token}",
            "X-Runner-Name": self.cfg.name,
            "User-Agent": "tibyan-runner/0.1",
        }
        h.update(extra or {})
        return h

    def _open(self, method: str, path: str, data: bytes | None = None,
              headers: dict | None = None, timeout: int = 120):
        url = path if path.startswith("http") else f"{self.cfg.url}{path}"
        last: Exception | None = None
        for attempt in range(self.retries):
            req = urllib.request.Request(url, data=data, method=method,
                                         headers=self._headers(headers))
            try:
                return urllib.request.urlopen(req, timeout=timeout)
            except urllib.error.HTTPError as exc:
                body = exc.read().decode("utf-8", "replace")
                if exc.code >= 500 or exc.code == 429:
                    last = ApiError(exc.code, body)
                else:
                    raise ApiError(exc.code, body) from None
            except (urllib.error.URLError, TimeoutError, ConnectionError, OSError) as exc:
                last = exc
            time.sleep(min(60, 2 ** attempt))
        raise last  # type: ignore[misc]

    def json(self, method: str, path: str, body: dict | None = None) -> dict:
        data = json.dumps(body).encode() if body is not None else None
        headers = {"Content-Type": "application/json"} if data is not None else {}
        with self._open(method, path, data, headers) as resp:
            raw = resp.read()
        return json.loads(raw) if raw else {}

    # ---- endpoints ----
    def ping(self) -> dict:
        return self.json("GET", "/api/runner/ping")

    def claim(self) -> dict:
        return self.json("POST", "/api/runner/claim")

    def progress(self, job_id: int, progress: float | None, stage: str | None,
                 logs: list[str]) -> dict:
        body: dict = {"logs": logs}
        if progress is not None:
            body["progress"] = progress
        if stage:
            body["stage"] = stage
        return self.json("POST", f"/api/runner/jobs/{job_id}/progress", body)

    def dataset(self, job_id: int) -> dict:
        return self.json("GET", f"/api/runner/jobs/{job_id}/dataset")

    def complete(self, job_id: int, metrics: dict, files: dict) -> dict:
        return self.json("POST", f"/api/runner/jobs/{job_id}/complete",
                         {"metrics": metrics, "files": files})

    def fail(self, job_id: int, error: str) -> dict:
        return self.json("POST", f"/api/runner/jobs/{job_id}/fail", {"error": error})

    def download(self, path: str, dest: Path, expect_sha: str | None = None,
                 auth: bool = True) -> str:
        """Stream to dest.part then rename; verify sha256 (X-Sha256 header
        or expect_sha). Returns the digest."""
        dest.parent.mkdir(parents=True, exist_ok=True)
        part = dest.with_name(dest.name + ".part")
        h = hashlib.sha256()
        if auth:
            resp = self._open("GET", path, timeout=600)
        else:
            resp = urllib.request.urlopen(
                urllib.request.Request(path, headers={"User-Agent": "tibyan-runner/0.1"}),
                timeout=600,
            )
        with resp, part.open("wb") as out:
            header_sha = resp.headers.get("X-Sha256")
            while chunk := resp.read(1024 * 1024):
                h.update(chunk)
                out.write(chunk)
        digest = h.hexdigest()
        want = expect_sha or header_sha
        if want and digest != want:
            part.unlink(missing_ok=True)
            raise ApiError(0, f"checksum mismatch for {dest.name}")
        part.replace(dest)
        return digest

    def remote_size(self, job_id: int, name: str) -> int:
        return int(self.json("GET", f"/api/runner/jobs/{job_id}/files/{name}").get("size", 0))

    def upload(self, job_id: int, name: str, path: Path, chunk: int,
               on_progress=None) -> None:
        """Resumable chunked upload: continue from the size the server has."""
        total = path.stat().st_size
        offset = self.remote_size(job_id, name)
        if offset > total:
            offset = 0
        with path.open("rb") as f:
            while offset < total or total == 0:
                f.seek(offset)
                data = f.read(chunk)
                try:
                    with self._open(
                        "PUT", f"/api/runner/jobs/{job_id}/files/{name}?offset={offset}",
                        data, {"Content-Type": "application/octet-stream"}, timeout=600,
                    ) as resp:
                        offset = json.loads(resp.read())["size"]
                except ApiError as exc:
                    if exc.status == 409 and "offset_mismatch" in exc.body:
                        offset = json.loads(exc.body)["size"]
                        continue
                    raise
                if on_progress:
                    on_progress(offset, total)
                if total == 0:
                    break
