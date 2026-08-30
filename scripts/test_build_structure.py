#!/usr/bin/env python3
"""
Testes unitários para build_structure.py.

Uso:
  python3 scripts/test_build_structure.py
  python3 scripts/test_build_structure.py -v
"""
import unittest
from pathlib import Path

from build_structure import (
    build_structure,
    is_normative_section_heading,
    parse_section_heading,
    slugify,
    strip_markdown_inline,
)

ROOT = Path(__file__).resolve().parent.parent
CONTENT_DIR = ROOT / "content"


class TestHelpers(unittest.TestCase):
  def test_slugify(self):
    self.assertEqual(slugify("**6.1 Objetivo**"), "61-objetivo")

  def test_strip_markdown_inline(self):
    self.assertEqual(strip_markdown_inline("**6.1 Objetivo**"), "6.1 Objetivo")

  def test_parse_section_heading_numbered(self):
    number, title = parse_section_heading("**6.1 Objetivo**")
    self.assertEqual(number, "6.1")
    self.assertEqual(title, "Objetivo")

  def test_parse_section_heading_anexo(self):
    number, title = parse_section_heading(
      "**ANEXO I LISTA DE EQUIPAMENTOS DE PROTEÇÃO INDIVIDUAL**"
    )
    self.assertEqual(number, "ANEXO I")
    self.assertIn("LISTA", title)

  def test_is_normative_section_heading(self):
    self.assertTrue(is_normative_section_heading("**6.1 Objetivo**"))
    self.assertTrue(is_normative_section_heading("**ANEXO I LISTA**"))
    self.assertFalse(is_normative_section_heading("**SUMÁRIO**"))
    self.assertFalse(is_normative_section_heading("**Publicação**"))


class TestBuildStructureNr06(unittest.TestCase):
  @classmethod
  def setUpClass(cls):
    md_path = CONTENT_DIR / "nr-06" / "nr-06.md"
    if not md_path.exists():
      raise unittest.SkipTest("content/nr-06/nr-06.md não encontrado")
    cls.structure = build_structure(md_path.read_text(encoding="utf-8"))

  def test_has_title(self):
    self.assertIn("NR 06", self.structure["title"])

  def test_has_preamble_blocks(self):
    blocks = self.structure["preamble"]["blocks"]
    self.assertGreater(len(blocks), 0)
    types = {b["type"] for b in blocks}
    self.assertIn("table", types)

  def test_has_normative_sections(self):
    sections = self.structure["sections"]
    self.assertGreater(len(sections), 5)
    numbers = [s["number"] for s in sections]
    self.assertIn("6.1", numbers)
    self.assertIn("6.2", numbers)

  def test_section_has_items(self):
    section_61 = next(s for s in self.structure["sections"] if s["number"] == "6.1")
    item_blocks = [b for b in section_61["blocks"] if b["type"] == "item"]
    self.assertGreater(len(item_blocks), 0)
    self.assertEqual(item_blocks[0]["number"], "6.1.1")

  def test_section_65_has_list(self):
    section_65 = next(s for s in self.structure["sections"] if s["number"] == "6.5")
    list_blocks = [b for b in section_65["blocks"] if b["type"] == "list"]
    self.assertGreater(len(list_blocks), 0)
    self.assertEqual(list_blocks[0]["items"][0]["label"], "a")

  def test_sections_have_ids(self):
    for section in self.structure["sections"]:
      self.assertTrue(section["id"])


class TestBuildStructureNr12(unittest.TestCase):
  @classmethod
  def setUpClass(cls):
    md_path = CONTENT_DIR / "nr-12" / "nr-12.md"
    if not md_path.exists():
      raise unittest.SkipTest("content/nr-12/nr-12.md não encontrado")
    cls.structure = build_structure(md_path.read_text(encoding="utf-8"))

  def test_has_many_sections(self):
    self.assertGreater(len(self.structure["sections"]), 10)

  def test_has_section_12_1(self):
    numbers = [s["number"] for s in self.structure["sections"]]
    self.assertIn("12.1", numbers)


class TestBuildStructureNr17(unittest.TestCase):
  @classmethod
  def setUpClass(cls):
    md_path = CONTENT_DIR / "nr-17" / "nr-17.md"
    if not md_path.exists():
      raise unittest.SkipTest("content/nr-17/nr-17.md não encontrado")
    cls.structure = build_structure(md_path.read_text(encoding="utf-8"))

  def test_has_anexo_sections(self):
    numbers = [s["number"] for s in self.structure["sections"]]
    anexos = [n for n in numbers if n.startswith("ANEXO")]
    self.assertGreater(len(anexos), 0)

  def test_section_17_1_has_items(self):
    section = next(s for s in self.structure["sections"] if s["number"] == "17.1")
    items = [b for b in section["blocks"] if b["type"] == "item"]
    self.assertGreater(len(items), 0)


if __name__ == "__main__":
  unittest.main()
