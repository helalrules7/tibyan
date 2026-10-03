"""Uploads an app bundle to a Google Play testing track (internal by
default) through the Play Developer API, with the service account's key.

    python3 tools/play_upload.py build/app/outputs/bundle/release/app-release.aab \
        --name "0.4.0 (6)" --notes "…"

The key stays outside the repository (default
~/.config/tibyan/play-service-account.json). No Google libraries needed:
the token request is signed with openssl, the calls use urllib.
"""
import argparse
import base64
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

PACKAGE = 'app.tibyan.tibyan'
API = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications'
UPLOAD = 'https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications'
SCOPE = 'https://www.googleapis.com/auth/androidpublisher'
KEY = os.path.expanduser('~/.config/tibyan/play-service-account.json')


def b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()


def token(key_path: str) -> str:
    key = json.load(open(key_path))
    now = int(time.time())
    head = b64(json.dumps({'alg': 'RS256', 'typ': 'JWT'}).encode())
    claims = b64(json.dumps({
        'iss': key['client_email'], 'scope': SCOPE, 'aud': key['token_uri'],
        'iat': now, 'exp': now + 3600,
    }).encode())
    signing = f'{head}.{claims}'.encode()
    # The private key goes to openssl on stdin, never to a file.
    pem = key['private_key'].encode()
    r, w = os.pipe()
    os.write(w, pem)
    os.close(w)
    sig = subprocess.run(
        ['openssl', 'dgst', '-sha256', '-sign', f'/dev/fd/{r}'],
        input=signing, capture_output=True, check=True, pass_fds=(r,),
    ).stdout
    os.close(r)
    body = urllib.parse.urlencode({
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': f'{signing.decode()}.{b64(sig)}',
    }).encode()
    with urllib.request.urlopen(key['token_uri'], body) as res:
        return json.load(res)['access_token']


def call(method, url, tok, body=None, data=None, headers=None):
    h = {'Authorization': f'Bearer {tok}', **(headers or {})}
    if body is not None:
        data = json.dumps(body).encode()
        h['Content-Type'] = 'application/json'
    req = urllib.request.Request(url, data=data, method=method, headers=h)
    try:
        with urllib.request.urlopen(req, timeout=1800) as res:
            text = res.read()
            return json.loads(text) if text else {}
    except urllib.error.HTTPError as e:
        sys.exit(f'{method} {url.split("?")[0]} -> {e.code}: {e.read().decode()[:2000]}')


CHUNK = 8 * 1024 * 1024  # every chunk but the last must be a multiple of 256 KB


def upload(session, tok, path, size):
    """Sends the bundle over the resumable session, reporting how far it is.

    The session takes a file in ranges and answers 308 with what it has after
    each one, then the bundle itself on the last. Sending the whole 159 MB in
    a single PUT (what this did first) gives the same bytes with nothing to
    show and nothing to resume, and holds all of it in memory while urllib
    waits.
    """
    sent = 0
    with open(path, 'rb') as f:
        while True:
            chunk = f.read(min(CHUNK, size - sent))
            last = sent + len(chunk) >= size
            req = urllib.request.Request(session, data=chunk, method='PUT',
                                         headers={
                'Authorization': f'Bearer {tok}',
                'Content-Type': 'application/octet-stream',
                'Content-Range': f'bytes {sent}-{sent + len(chunk) - 1}/{size}',
            })
            try:
                with urllib.request.urlopen(req, timeout=1800) as res:
                    print(f'\r  {size / 1e6:.0f} MB sent, all of it.        ')
                    return json.loads(res.read())
            except urllib.error.HTTPError as e:
                if e.code != 308:  # 308 means: nothing wrong, keep going
                    sys.exit(f'PUT -> {e.code}: {e.read().decode()[:2000]}')
                sent += len(chunk)
                print(f'\r  {sent / size * 100:5.1f}%  '
                      f'{sent / 1e6:.0f}/{size / 1e6:.0f} MB', end='', flush=True)
            if last:
                sys.exit('the session did not take the last chunk')


def main():
    p = argparse.ArgumentParser()
    p.add_argument('aab')
    p.add_argument('--track', default='internal')
    p.add_argument('--name', required=True, help='release name, e.g. "0.4.0 (6)"')
    p.add_argument('--notes', default='', help='Arabic release notes')
    p.add_argument('--status', default='completed', choices=['completed', 'draft'])
    p.add_argument('--key', default=KEY)
    a = p.parse_args()

    tok = token(a.key)
    edit = call('POST', f'{API}/{PACKAGE}/edits', tok, body={})['id']
    size = os.path.getsize(a.aab)
    # Resumable upload: start a session, then send the whole file.
    start = urllib.request.Request(
        f'{UPLOAD}/{PACKAGE}/edits/{edit}/bundles?uploadType=resumable',
        data=b'', method='POST', headers={
            'Authorization': f'Bearer {tok}',
            'X-Upload-Content-Type': 'application/octet-stream',
            'X-Upload-Content-Length': str(size),
        })
    with urllib.request.urlopen(start) as res:
        session = res.headers['Location']
    bundle = upload(session, tok, a.aab, size)
    code = bundle['versionCode']
    print(f'uploaded versionCode {code} ({size / 1e6:.1f} MB)')
    release = {'name': a.name, 'versionCodes': [str(code)], 'status': a.status}
    if a.notes:
        release['releaseNotes'] = [{'language': 'ar', 'text': a.notes}]
    call('PUT', f'{API}/{PACKAGE}/edits/{edit}/tracks/{a.track}', tok,
         body={'track': a.track, 'releases': [release]})
    call('POST', f'{API}/{PACKAGE}/edits/{edit}:commit', tok)
    print(f'released {a.name} to {a.track} ({a.status})')


if __name__ == '__main__':
    main()
