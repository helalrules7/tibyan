"""Checks that a release tag, pubspec.yaml and CHANGELOG.md agree.

    python3 tools/release/check_version.py v0.5.0

Fails (exit 1) when the tag's version is not pubspec.yaml's, or the
changelog has no section for it, so a mistyped tag never builds a release.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def pubspec_version(text: str) -> str:
    m = re.search(r'^version:\s*(\d+\.\d+\.\d+)(?:\+\d+)?\s*$', text, re.M)
    if not m:
        raise SystemExit('pubspec.yaml has no version: x.y.z+n line')
    return m.group(1)


def check(tag: str, pubspec: str, changelog: str) -> list[str]:
    version = tag[1:] if tag.startswith('v') else tag
    problems = []
    if pubspec_version(pubspec) != version:
        problems.append(
            f'tag {tag} is version {version}, pubspec.yaml says {pubspec_version(pubspec)}')
    if not re.search(rf'^## \[{re.escape(version)}\]', changelog, re.M):
        problems.append(f'CHANGELOG.md has no "## [{version}]" section')
    return problems


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    problems = check(
        sys.argv[1],
        (ROOT / 'pubspec.yaml').read_text(encoding='utf-8'),
        (ROOT / 'CHANGELOG.md').read_text(encoding='utf-8'),
    )
    for p in problems:
        print('error:', p)
    sys.exit(1 if problems else 0)
