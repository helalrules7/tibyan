from __future__ import annotations

import unittest

from starlette.requests import Request

from app.routes.pages import index


def make_request(host: str) -> Request:
    return Request(
        {
            "type": "http",
            "method": "GET",
            "path": "/",
            "headers": [(b"host", host.encode("ascii"))],
            "query_string": b"",
            "server": (host, 80),
            "scheme": "http",
            "client": ("127.0.0.1", 1234),
            "root_path": "",
            "session": {},
        }
    )


class ComingSoonTests(unittest.TestCase):
    def test_main_domain_serves_coming_soon(self):
        for host in (
            "altibya.app",
            "www.altibya.app",
            "altibyan.app",
            "www.altibyan.app",
        ):
            with self.subTest(host=host):
                response = index(make_request(host), db=None)
                self.assertIn("تجربة جديدة من تبيان".encode(), response.body)
                self.assertIn(b"train.altibyan.app", response.body)
                self.assertIn(
                    b'https://altibyan.app/static/coming-soon-share.png?v=1',
                    response.body,
                )
                self.assertIn(b'name="twitter:card" content="summary_large_image"', response.body)

    def test_training_subdomain_keeps_its_existing_homepage(self):
        response = index(make_request("train.altibyan.app"), db=None)
        self.assertIn("ساعدنا ندرّب نموذج التسميع".encode(), response.body)
        self.assertNotIn("تجربة جديدة من تبيان".encode(), response.body)


if __name__ == "__main__":
    unittest.main()
