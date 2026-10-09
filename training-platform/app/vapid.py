"""Generate a VAPID key pair for Web Push.

    python -m app.vapid >> .env      # on the server, never into the repo

Prints VAPID_PUBLIC_KEY / VAPID_PRIVATE_KEY lines (base64url: the public key
as an uncompressed P-256 point, the private key as the raw 32-byte scalar,
the formats the browser and pywebpush expect).
"""
from __future__ import annotations

import base64

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def generate() -> tuple[str, str]:
    key = ec.generate_private_key(ec.SECP256R1())
    private = key.private_numbers().private_value.to_bytes(32, "big")
    public = key.public_key().public_bytes(
        serialization.Encoding.X962, serialization.PublicFormat.UncompressedPoint
    )
    return b64url(public), b64url(private)


if __name__ == "__main__":
    public, private = generate()
    print(f"VAPID_PUBLIC_KEY={public}")
    print(f"VAPID_PRIVATE_KEY={private}")
