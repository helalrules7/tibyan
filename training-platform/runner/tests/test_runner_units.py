import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tibyan_runner.metrics import score  # noqa: E402
from tibyan_runner.textnorm import norm_text  # noqa: E402


class RunnerUnitTests(unittest.TestCase):
    def test_norm_drops_marks_and_maps_uthmani(self):
        self.assertEqual(norm_text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ"), "بسم الله الرحمن")

    def test_score_per_group(self):
        items = [
            {"id": 1, "text": "بسم الله الرحمن الرحيم", "group": "men"},
            {"id": 2, "text": "الحمد لله", "group": "women"},
        ]
        m = score(items, {1: "بسم الله الرحيم", 2: "الحمد لله"})["groups"]
        self.assertEqual(m["men"]["wer"], 25.0)
        self.assertEqual(m["women"]["wer"], 0.0)
        self.assertEqual(m["all"]["n"], 2)
        self.assertAlmostEqual(m["all"]["wer"], round(100 / 6, 2))

    def test_segments_cut_long_audio(self):
        try:
            import numpy as np
        except ImportError:
            self.skipTest("numpy not installed")
        from tibyan_runner.audio import SR, segments

        x = np.random.default_rng(0).uniform(-0.3, 0.3, SR * 20).astype("float32")
        x[SR * 7:SR * 7 + 3200] = 0.0  # a pause at 7 s
        segs = segments(x)
        self.assertGreater(len(segs), 1)
        self.assertTrue(all(len(s) <= 11 * SR for s in segs))
        self.assertLess(abs(len(segs[0]) - int(7.1 * SR)), int(0.2 * SR))


if __name__ == "__main__":
    unittest.main()
