"""Testes para normalize_md.py."""
from __future__ import annotations

import unittest

from normalize_md import DOU_NOTE, normalize_markdown


class TestNormalizeMarkdown(unittest.TestCase):
    def test_removes_dou_line_splitting_item(self) -> None:
        text = (
            "**6.1.1** O objetivo desta NR é estabelecer os requisitos para aprovação,\n\n"
            f"{DOU_NOTE}\n\n"
            "comercialização, fornecimento e utilização de EPI.\n"
        )
        result = normalize_markdown(text)
        self.assertNotIn(DOU_NOTE, result)
        self.assertIn("aprovação, comercialização", result)

    def test_removes_standalone_dou_line(self) -> None:
        text = f"# **6.1 Objetivo**\n\n{DOU_NOTE}\n\n**6.1.1** Texto do item.\n"
        result = normalize_markdown(text)
        self.assertNotIn(DOU_NOTE, result)
        self.assertIn("**6.1.1** Texto do item.", result)

    def test_fixes_broken_hyphenation(self) -> None:
        text = "O empregador deve- se certificar de que o trabalhador usa EPI.\n"
        result = normalize_markdown(text)
        self.assertIn("deve-se", result)
        self.assertNotIn("deve- se", result)

    def test_removes_orphan_page_numbers(self) -> None:
        text = "Parágrafo inicial.\n\n42\n\nContinuação do texto.\n"
        result = normalize_markdown(text)
        self.assertNotIn("\n42\n", result)
        self.assertIn("Continuação do texto.", result)

    def test_preserves_headings_and_tables(self) -> None:
        text = "# **6.1 Objetivo**\n\n| Col A | Col B |\n| --- | --- |\n| 1 | 2 |\n"
        result = normalize_markdown(text)
        self.assertIn("# **6.1 Objetivo**", result)
        self.assertIn("| Col A | Col B |", result)

    def test_strips_br_tags_in_tables(self) -> None:
        text = (
            "| **Publicação**<br>Portaria MTb | **D.O.U.**<br>06/07/78 |\n"
            "| --- | --- |\n"
            "| <br>Portaria SIT | 06/03/12 |\n"
        )
        result = normalize_markdown(text)
        self.assertNotIn("<br>", result)
        self.assertIn("**Publicação** Portaria MTb", result)

    def test_strips_mark_tags(self) -> None:
        text = "**<mark>35.1 Objetivo</mark>**\n\n<mark>Texto normativo.</mark>\n"
        result = normalize_markdown(text)
        self.assertNotIn("<mark>", result)
        self.assertIn("**35.1 Objetivo**", result)
        self.assertIn("Texto normativo.", result)

    def test_strips_picture_text_blocks(self) -> None:
        text = (
            "Texto antes.\n\n"
            "<!-- Start of picture text -->\n"
            "FORMULÁRIO<br>com lixo OCR\n"
            "<!-- End of picture text -->\n\n"
            "Texto depois.\n"
        )
        result = normalize_markdown(text)
        self.assertNotIn("picture text", result)
        self.assertNotIn("FORMULÁRIO", result)
        self.assertIn("Texto antes.", result)
        self.assertIn("Texto depois.", result)

    def test_merges_spurious_fragment_heading(self) -> None:
        text = (
            "e) noções sobre as legislações trabalhista e previdenciária relativas à segurança e saúde no\n\n"
            "# trabalho;\n\n"
            "f) próximo item.\n"
        )
        result = normalize_markdown(text)
        self.assertNotIn("# trabalho", result)
        self.assertIn("saúde no trabalho;", result)


if __name__ == "__main__":
    unittest.main()
