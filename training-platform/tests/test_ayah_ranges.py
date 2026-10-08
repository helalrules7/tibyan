import unittest
from unittest.mock import patch

from sqlalchemy import create_engine, inspect, text

from app import verses
from app.db import migrate_recording_ayah_end


class AyahRangeTests(unittest.TestCase):
    def test_joins_a_valid_range_in_order(self):
        rows = [
            {"number": 1, "text": "verse-one"},
            {"number": 2, "text": "verse-two"},
            {"number": 3, "text": "verse-three"},
        ]
        with patch.object(verses, "ayahs_of", return_value=rows):
            self.assertTrue(verses.ayah_range_is_valid(1, 1, 3))
            self.assertEqual(
                verses.ayah_range_text(1, 1, 3),
                "verse-one verse-two verse-three",
            )

    def test_rejects_invalid_or_incomplete_ranges(self):
        rows = [{"number": 1, "text": "verse-one"}, {"number": 3, "text": "verse-three"}]
        with patch.object(verses, "ayahs_of", return_value=rows):
            self.assertFalse(verses.ayah_range_is_valid(1, 2, 1))
            self.assertFalse(verses.ayah_range_is_valid(1, 1, 3))
            self.assertIsNone(verses.ayah_range_text(1, 2, 1))
            self.assertIsNone(verses.ayah_range_text(1, 1, 3))

    def test_migrates_an_existing_recordings_table(self):
        engine = create_engine("sqlite:///:memory:")
        try:
            with engine.begin() as connection:
                connection.execute(text("CREATE TABLE recordings (id INTEGER PRIMARY KEY)"))
            migrate_recording_ayah_end(engine)
            columns = {column["name"] for column in inspect(engine).get_columns("recordings")}
            self.assertIn("ayah_end", columns)

            migrate_recording_ayah_end(engine)
            self.assertIn(
                "ayah_end",
                {column["name"] for column in inspect(engine).get_columns("recordings")},
            )
        finally:
            engine.dispose()


if __name__ == "__main__":
    unittest.main()
