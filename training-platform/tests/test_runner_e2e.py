"""The real runner code (fake trainer) against a live server: claim,
dataset download, progress, resumable chunked upload, complete."""
from __future__ import annotations

import socket
import sys
import tempfile
import threading
import time
import unittest
from pathlib import Path

import uvicorn

from test_admin_training import TOKEN, PlatformCase

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "runner"))

from tibyan_runner.api import Api  # noqa: E402
from tibyan_runner.config import Config  # noqa: E402
from tibyan_runner.pipeline import Pipeline  # noqa: E402

from app import training  # noqa: E402
from app.config import settings  # noqa: E402
from app.models import TrainingJob  # noqa: E402


def free_port() -> int:
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


class RunnerEndToEnd(PlatformCase):
    def test_fake_runner_end_to_end(self):
        job_id, _, _ = self._queued_job()
        port = free_port()
        server = uvicorn.Server(uvicorn.Config(self.app, host="127.0.0.1", port=port,
                                               log_level="warning"))
        thread = threading.Thread(target=server.run, daemon=True)
        thread.start()
        for _ in range(100):
            if server.started:
                break
            time.sleep(0.05)
        try:
            with tempfile.TemporaryDirectory() as home:
                cfg = Config(url=f"http://127.0.0.1:{port}", token=TOKEN, name="mac-test",
                             home=Path(home), nice=0, device="cpu", poll_seconds=1, threads=1)
                api = Api(cfg, retries=1)
                job = api.claim()["job"]
                self.assertEqual(job["id"], job_id)
                job["chunk_bytes"] = 1000  # force several chunks
                result = Pipeline(cfg, api, threading.Event(), fake=True).run(job)
                self.assertEqual(result, "completed")
                # Audio is gone from the runner once the job is done.
                self.assertFalse((Path(home) / "jobs" / str(job_id) / "audio").exists())
        finally:
            server.should_exit = True
            thread.join(timeout=5)
        with self.Session() as db:
            job = db.get(TrainingJob, job_id)
            self.assertEqual(job.status, "review")
            self.assertTrue(training.is_fake(job))
            files = training.job_files(job)
            self.assertGreater(files["model.int8.onnx"]["bytes"], 1000)
            self.assertIn("candidate", training.job_metrics(job))
        self.assertEqual(settings.runner_token, TOKEN)


if __name__ == "__main__":
    unittest.main()
