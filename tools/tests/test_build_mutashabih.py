"""Tests for build_mutashabih: verse numbering and deduplication.

Run: python3 -m unittest discover -s tools/tests
"""
import sys
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(TOOLS))

import build_mutashabih  # noqa: E402


class RowsTest(unittest.TestCase):
    def test_absolute_numbers_are_zero_based(self):
        # 9 is 2:3 (verse id 10), 1162 is 8:3 (verse id 1163).
        data = {'1': [{'src': {'ayah': 9}, 'muts': [{'ayah': 1162}]}]}
        self.assertEqual(build_mutashabih.rows(data), [(10, 10, 1163, 1163, 0)])

    def test_runs_context_and_duplicates(self):
        data = {
            '2': [
                {'src': {'ayah': [53, 54]}, 'muts': [{'ayah': [128, 129]}], 'ctx': 2},
                # The same link again, and a verse listed twice in a run.
                {'src': {'ayah': [53, 54]}, 'muts': [{'ayah': [128, 129]}]},
                {'src': {'ayah': [3947, 3947]}, 'muts': [{'ayah': 10}]},
            ],
            '1': [{'src': {'ayah': 5}, 'muts': [{'ayah': 5}]}],  # to itself: dropped
        }
        self.assertEqual(
            build_mutashabih.rows(data),
            [(54, 55, 129, 130, 1), (3948, 3948, 11, 11, 0)],
        )

    def test_gaps_are_refused(self):
        with self.assertRaises(AssertionError):
            build_mutashabih.rows({'1': [{'src': {'ayah': [1, 3]}, 'muts': [{'ayah': 9}]}]})


if __name__ == '__main__':
    unittest.main()
