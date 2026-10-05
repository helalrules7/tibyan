"""Prepares a release: moves the changelog's [Unreleased] section under the
new version and date, and sets the version and build number in pubspec.yaml.

    python3 tools/release/prepare.py 0.5.0            # build number + 1
    python3 tools/release/prepare.py 0.5.0 --build 9

Then commit, tag `v0.5.0` and push the tag: .github/workflows/release.yml
does the rest (docs/RELEASE.md).
"""
import argparse
import datetime
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def bump_pubspec(text: str, version: str, build: int | None) -> str:
    m = re.search(r'^version:\s*\d+\.\d+\.\d+\+(\d+)\s*$', text, re.M)
    if not m:
        raise SystemExit('pubspec.yaml has no version: x.y.z+n line')
    number = build if build is not None else int(m.group(1)) + 1
    return text[:m.start()] + f'version: {version}+{number}' + text[m.end():]


def cut_changelog(text: str, version: str, today: str) -> str:
    if re.search(rf'^## \[{re.escape(version)}\]', text, re.M):
        raise SystemExit(f'CHANGELOG.md already has {version}')
    m = re.search(r'^## \[Unreleased\][ \t]*$', text, re.M)
    if not m:
        raise SystemExit('CHANGELOG.md has no [Unreleased] section')
    text = text[:m.end()] + f'\n\n## [{version}] - {today}' + text[m.end():]
    # Compare links: Unreleased now starts from the new tag.
    link = re.search(r'^\[Unreleased\]: (.*)/compare/(v[\d.]+)\.\.\.HEAD$', text, re.M)
    if link:
        base, previous = link.group(1), link.group(2)
        text = text.replace(
            link.group(0),
            f'[Unreleased]: {base}/compare/v{version}...HEAD\n'
            f'[{version}]: {base}/compare/{previous}...v{version}')
    return text


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('version', help='x.y.z')
    ap.add_argument('--build', type=int, help='build number (default: current + 1)')
    args = ap.parse_args()
    if not re.fullmatch(r'\d+\.\d+\.\d+', args.version):
        raise SystemExit('version must look like 0.5.0')
    pub = ROOT / 'pubspec.yaml'
    log = ROOT / 'CHANGELOG.md'
    pub.write_text(bump_pubspec(pub.read_text(encoding='utf-8'), args.version, args.build), encoding='utf-8')
    log.write_text(cut_changelog(log.read_text(encoding='utf-8'), args.version,
                                 datetime.date.today().isoformat()), encoding='utf-8')
    print(f'pubspec.yaml and CHANGELOG.md are at {args.version}')
