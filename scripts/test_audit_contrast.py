"""Testes para scripts/audit_contrast.py."""

from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPT = ROOT / "scripts" / "audit_contrast.py"


def _load_module():
    spec = importlib.util.spec_from_file_location("audit_contrast", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules["audit_contrast"] = module
    spec.loader.exec_module(module)
    return module


class AuditContrastTest(unittest.TestCase):
    def test_contrast_ratio_black_on_white(self):
        mod = _load_module()
        ratio = mod.contrast_ratio("#000000", "#FFFFFF")
        self.assertEqual(ratio, 21.0)

    def test_parse_app_colors_reads_known_tokens(self):
        mod = _load_module()
        colors = mod.parse_app_colors(mod.APP_COLORS)
        self.assertEqual(colors["primary"], "#0F5C4E")
        self.assertEqual(colors["searchHighlightDark"], "#5C4A1A")

    def test_critical_pairs_pass_wcag_aa(self):
        mod = _load_module()
        colors = mod.parse_app_colors(mod.APP_COLORS)
        failures = mod.audit(colors)
        self.assertEqual(failures, [])


if __name__ == "__main__":
    unittest.main()
