"""Testes para validate_quality.py."""
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from validate_quality import analyze_nr_quality, mark_reviewed


class TestValidateQuality(unittest.TestCase):
    def test_detects_dou_footer(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            nr_dir = Path(tmp) / "nr-99"
            nr_dir.mkdir()
            md = nr_dir / "nr-99.md"
            md.write_text(
                "**1.1** Texto normativo.\n\n"
                "Este texto não substitui o publicado no DOU\n\n"
                "continuação.\n",
                encoding="utf-8",
            )
            with patch("validate_quality.CONTENT_DIR", Path(tmp)):
                report = analyze_nr_quality("nr-99")
            self.assertFalse(report["ok"])
            self.assertTrue(any("dou_footer" in w for w in report["warnings"]))

    def test_passes_clean_text(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            nr_dir = Path(tmp) / "nr-99"
            nr_dir.mkdir()
            md = nr_dir / "nr-99.md"
            md.write_text("**6.1.1** Texto íntegro sem artefatos.\n", encoding="utf-8")
            with patch("validate_quality.CONTENT_DIR", Path(tmp)):
                report = analyze_nr_quality("nr-99")
            self.assertTrue(report["ok"])
            self.assertEqual(report["warnings"], [])

    def test_mark_reviewed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            nr_dir = Path(tmp) / "nr-99"
            nr_dir.mkdir()
            with patch("validate_quality.ensure_content_dir", return_value=nr_dir):
                mark_reviewed("nr-99", True)
            meta = json.loads((nr_dir / "meta.json").read_text(encoding="utf-8"))
            self.assertTrue(meta["reviewed"])


if __name__ == "__main__":
    unittest.main()
