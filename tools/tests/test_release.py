import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'release'))
import check_version  # noqa: E402
import prepare  # noqa: E402

PUBSPEC = 'name: x\nversion: 0.4.0+5\n'
LOG = (
    '# Changelog\n\n## [Unreleased]\n\n### Added\n- a\n\n## [0.4.0] - 2026-01-01\n- b\n\n'
    '[Unreleased]: https://github.com/o/r/compare/v0.4.0...HEAD\n'
    '[0.4.0]: https://github.com/o/r/compare/v0.3.0...v0.4.0\n'
)


class Release(unittest.TestCase):
    def test_bump_adds_one_to_the_build(self):
        self.assertIn('version: 0.5.0+6', prepare.bump_pubspec(PUBSPEC, '0.5.0', None))
        self.assertIn('version: 0.5.0+9', prepare.bump_pubspec(PUBSPEC, '0.5.0', 9))

    def test_changelog_cut(self):
        out = prepare.cut_changelog(LOG, '0.5.0', '2026-10-05')
        self.assertIn('## [Unreleased]\n\n## [0.5.0] - 2026-10-05\n\n### Added', out)
        self.assertIn('[Unreleased]: https://github.com/o/r/compare/v0.5.0...HEAD', out)
        self.assertIn('[0.5.0]: https://github.com/o/r/compare/v0.4.0...v0.5.0', out)

    def test_cut_twice_refuses(self):
        out = prepare.cut_changelog(LOG, '0.5.0', '2026-10-05')
        with self.assertRaises(SystemExit):
            prepare.cut_changelog(out, '0.5.0', '2026-10-05')

    def test_check_accepts_a_matching_tag(self):
        out = prepare.cut_changelog(LOG, '0.5.0', '2026-10-05')
        pub = prepare.bump_pubspec(PUBSPEC, '0.5.0', None)
        self.assertEqual(check_version.check('v0.5.0', pub, out), [])

    def test_check_names_each_mismatch(self):
        self.assertEqual(len(check_version.check('v0.9.0', PUBSPEC, LOG)), 2)


if __name__ == '__main__':
    unittest.main()
