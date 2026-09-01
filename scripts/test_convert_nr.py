#!/usr/bin/env python3
"""
Testes unitários para as funções puras de convert_nr.py:
- _table_to_markdown
- _is_probably_illegible
- _strip_duplicate_markdown_table
- _combine_and_sort_bboxes

Uso:
  python3 scripts/test_convert_nr.py
  python3 scripts/test_convert_nr.py -v (verbose)
"""
import unittest
try:
    import pymupdf as fitz
except ImportError:
    fitz = None

from convert_nr import (
    _table_to_markdown,
    _is_probably_illegible,
    _strip_duplicate_markdown_table,
    _combine_and_sort_bboxes,
)


class TestTableToMarkdown(unittest.TestCase):
    """Testes para _table_to_markdown."""

    def test_simple_table(self):
        """Tabela simples de 2 colunas, 2 linhas."""
        table = [
            ["Col1", "Col2"],
            ["Val1", "Val2"],
        ]
        result = _table_to_markdown(table)
        self.assertIn("| Col1 | Col2 |", result)
        self.assertIn("| --- | --- |", result)
        self.assertIn("| Val1 | Val2 |", result)

    def test_table_with_none(self):
        """Tabela com valores None."""
        table = [
            ["Col1", "Col2"],
            ["Val1", None],
        ]
        result = _table_to_markdown(table)
        # None deve ser convertido para string vazia
        self.assertIn("| Col1 | Col2 |", result)
        self.assertIn("| Val1 |  |", result)

    def test_table_with_pipe_escape(self):
        """Tabela com pipe literal dentro de célula."""
        table = [
            ["Col1", "Col2"],
            ["A|B", "Val2"],
        ]
        result = _table_to_markdown(table)
        # Pipe deve ser escapado como \|
        self.assertIn("A\\|B", result)

    def test_empty_table(self):
        """Tabela vazia."""
        result = _table_to_markdown([])
        self.assertEqual(result, "")

    def test_multirow_table(self):
        """Tabela com múltiplas linhas."""
        table = [
            ["A", "B", "C"],
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
        ]
        result = _table_to_markdown(table)
        # Deve ter header, separador e 3 linhas de dados
        lines = result.split("\n")
        self.assertEqual(len(lines), 5)  # header + sep + 3 dados
        self.assertIn("| --- | --- | --- |", result)

    def test_table_with_newlines_in_cells(self):
        """Quebras de linha dentro de célula devem virar espaço (uma linha por row)."""
        table = [
            ["GRAU\nde\nRISCO*", "0 a\n19"],
            ["1", "Efetivos"],
        ]
        result = _table_to_markdown(table)
        self.assertIn("| GRAU de RISCO* | 0 a 19 |", result)
        self.assertEqual(len(result.split("\n")), 3)


class TestIsProbablyIllegible(unittest.TestCase):
    """Testes para _is_probably_illegible."""

    def test_normal_table(self):
        """Tabela normal multi-coluna — não deve ser ilegível."""
        table = [
            ["Col1", "Col2"],
            ["Valor normal", "Outro valor"],
            ["Mais dados", "Fim"],
        ]
        self.assertFalse(_is_probably_illegible(table))

    def test_table_with_vertical_text(self):
        """Tabela com texto vertical quebrado char-by-char."""
        # Simulando: T\nE\nX\nT\nO (cada caractere em uma linha)
        table = [
            ["Col1", "Col2"],
            ["T\nE\nX\nT\nO", "N\nO\nR\nM"],  # ambas suspeitas (100% de dados)
        ]
        self.assertTrue(_is_probably_illegible(table))

    def test_table_all_empty(self):
        """Tabela com todas as células vazias."""
        table = [
            ["", ""],
            ["", ""],
        ]
        self.assertFalse(_is_probably_illegible(table))

    def test_table_one_mildly_suspicious_cell_below_ratio(self):
        """1 célula com 3 quebras (abaixo do gatilho de 5+) e ratio baixo (33%) — não é ilegível."""
        table = [
            ["Col1", "Col2", "Col3"],
            ["Normal", "Normal", "T\nE\nX"],  # só 1 de 3 é suspeito, e só 3 quebras
        ]
        self.assertFalse(_is_probably_illegible(table))

    def test_table_one_severely_suspicious_cell_triggers_regardless_of_ratio(self):
        """1 única célula muito suspeita (5+ quebras) já marca a tabela inteira — caso real: NR-03 TABELA 3.4, onde só 1 de 144 células vem com texto vertical quebrado."""
        table = [
            ["Col1", "Col2", "Col3"],
            ["Normal", "Normal", "T\nE\nX\nT\nO"],  # só 1 de 3, mas com 5 quebras
        ]
        self.assertTrue(_is_probably_illegible(table))

    def test_table_mostly_suspicious(self):
        """Tabela com maioria suspeita (>= 50%)."""
        table = [
            ["Col1", "Col2"],
            ["T\nE\nX", "A\nB\nC"],  # ambas suspeitas (100%)
        ]
        self.assertTrue(_is_probably_illegible(table))

    def test_table_with_long_text_multiple_lines(self):
        """Múltiplas linhas mas com palavras compridas — não é char-by-char."""
        table = [
            ["Col1", "Col2"],
            ["Hello\nWorld\nTest", "Normal"],  # múltiplas linhas mas não char-by-char
        ]
        self.assertFalse(_is_probably_illegible(table))


class TestStripDuplicateMarkdownTable(unittest.TestCase):
    """Testes para _strip_duplicate_markdown_table."""

    def test_text_without_table(self):
        """Texto sem tabela Markdown — não deve mudar."""
        text = "Este é um parágrafo normal\ncom múltiplas linhas."
        result = _strip_duplicate_markdown_table(text)
        # Não deve remover nada
        self.assertEqual(result.strip(), text.strip())

    def test_text_with_simple_table(self):
        """Texto com tabela Markdown simples."""
        text = "Parágrafo\n\n| Col1 | Col2 |\n| --- | --- |\n| A | B |\n\nOutro parágrafo"
        result = _strip_duplicate_markdown_table(text)
        # Tabela deve ser removida
        self.assertNotIn("| Col1 | Col2 |", result)
        self.assertNotIn("| --- | --- |", result)
        # Parágrafos devem estar preservados
        self.assertIn("Parágrafo", result)
        self.assertIn("Outro parágrafo", result)

    def test_text_with_table_at_start(self):
        """Tabela no início do texto."""
        text = "| Col1 | Col2 |\n| --- | --- |\n| A | B |\n\nTexto depois"
        result = _strip_duplicate_markdown_table(text)
        self.assertNotIn("| Col1 | Col2 |", result)
        self.assertIn("Texto depois", result)

    def test_text_with_multiple_tables(self):
        """Texto com múltiplas tabelas Markdown."""
        text = (
            "Para 1\n\n| A | B |\n| --- | --- |\n| 1 | 2 |\n\n"
            "Para 2\n\n| C | D |\n| --- | --- |\n| 3 | 4 |\n\n"
            "Para 3"
        )
        result = _strip_duplicate_markdown_table(text)
        # Ambas as tabelas devem ser removidas
        self.assertNotIn("| A | B |", result)
        self.assertNotIn("| C | D |", result)
        # Parágrafos devem estar
        self.assertIn("Para 1", result)
        self.assertIn("Para 2", result)
        self.assertIn("Para 3", result)

    def test_text_preserves_pipes_in_normal_text(self):
        """Pipes em texto normal (não tabela) devem ser preservados."""
        text = "Use o comando: git log | grep commit\n\nEste é um parágrafo."
        result = _strip_duplicate_markdown_table(text)
        # Pipes em texto normal não são tabela
        self.assertIn("git log | grep commit", result)

    def test_text_with_malformed_table_no_separator(self):
        """Tabela malformada sem linha separadora `|---|` (caso real: NR-03,
        onde o Pass 1 produz linhas de dados em pipe sem nunca gerar o separador)
        — ainda deve ser removida, já que 2+ linhas seguidas em formato `|...|`
        já são sinal suficiente de tabela, com ou sem separador."""
        text = (
            "Parágrafo antes\n\n"
            "|Classificação|Nenhuma|Rara|N|N|\n"
            "|Classificação|Leve|Remota|N|P|\n\n"
            "Parágrafo depois"
        )
        result = _strip_duplicate_markdown_table(text)
        self.assertNotIn("|Classificação|Nenhuma|Rara|N|N|", result)
        self.assertNotIn("|Classificação|Leve|Remota|N|P|", result)
        self.assertIn("Parágrafo antes", result)
        self.assertIn("Parágrafo depois", result)

    def test_text_with_single_pipe_line_not_removed(self):
        """Uma única linha isolada em formato `|...|` não é bloco de tabela (precisa de 2+)."""
        text = "Parágrafo\n\n| só uma linha solta |\n\nOutro parágrafo"
        result = _strip_duplicate_markdown_table(text)
        self.assertIn("| só uma linha solta |", result)

    def test_table_with_extra_spaces(self):
        """Tabela Markdown com espaços extras."""
        text = "Texto\n\n  | Col1 | Col2 |  \n  | --- | --- |  \n| A | B |\n\nMais"
        result = _strip_duplicate_markdown_table(text)
        # Deve remover mesmo com espaços
        self.assertNotIn("| Col1 | Col2 |", result)
        self.assertIn("Texto", result)
        self.assertIn("Mais", result)


class TestIntegration(unittest.TestCase):
    """Testes de integração entre as funções."""

    def test_table_to_markdown_then_strip(self):
        """Gera Markdown de tabela, depois remove com strip."""
        table = [
            ["Col1", "Col2"],
            ["Val1", "Val2"],
        ]
        markdown = _table_to_markdown(table)
        text_with_table = f"Parágrafo\n\n{markdown}\n\nOutro parágrafo"

        # Strip deve remover a tabela
        result = _strip_duplicate_markdown_table(text_with_table)
        self.assertNotIn("| Col1 | Col2 |", result)
        self.assertIn("Parágrafo", result)
        self.assertIn("Outro parágrafo", result)

    def test_illegible_table_detection_then_markdown_conversion(self):
        """Detecta ilegibilidade, e se fosse normal, converteria a Markdown."""
        # Tabela ilegível (50%+ de dados suspeitos)
        illegible_table = [
            ["A", "B"],
            ["T\nE\nX\nT", "N\nO\nR"],  # ambas células suspeitas
        ]
        self.assertTrue(_is_probably_illegible(illegible_table))

        # Se fosse convertida (mesmo sendo ilegível), geraria Markdown válido
        markdown = _table_to_markdown(illegible_table)
        self.assertIn("| --- | --- |", markdown)


@unittest.skipIf(fitz is None, "pymupdf not installed")
class TestCombineAndSortBboxes(unittest.TestCase):
    """Testes para _combine_and_sort_bboxes."""

    def test_single_image(self):
        """Uma página com uma imagem."""
        images_by_page = {
            0: [fitz.Rect(10, 20, 100, 120)],
        }
        tables_by_page = {}

        result = _combine_and_sort_bboxes(images_by_page, tables_by_page)

        self.assertIn(0, result)
        self.assertEqual(len(result[0]), 1)
        self.assertEqual(result[0][0]["kind"], "image")
        self.assertEqual(result[0][0]["bbox"], fitz.Rect(10, 20, 100, 120))

    def test_single_illegible_table(self):
        """Uma página com uma tabela ilegível."""
        images_by_page = {}
        tables_by_page = {
            0: [{"illegible_page": True, "bbox": (10, 20, 100, 120)}],
        }

        result = _combine_and_sort_bboxes(images_by_page, tables_by_page)

        self.assertIn(0, result)
        self.assertEqual(len(result[0]), 1)
        self.assertEqual(result[0][0]["kind"], "table")
        # bbox deve ser normalizado para fitz.Rect
        bbox = result[0][0]["bbox"]
        self.assertEqual(bbox.x0, 10)
        self.assertEqual(bbox.y0, 20)
        self.assertEqual(bbox.x1, 100)
        self.assertEqual(bbox.y1, 120)

    def test_image_and_table_together(self):
        """Uma página com imagem e tabela ilegível juntas."""
        # Imagem no topo (y0=20), tabela embaixo (y0=50)
        images_by_page = {
            0: [fitz.Rect(10, 20, 100, 40)],
        }
        tables_by_page = {
            0: [{"illegible_page": True, "bbox": (10, 50, 100, 120)}],
        }

        result = _combine_and_sort_bboxes(images_by_page, tables_by_page)

        self.assertIn(0, result)
        items = result[0]
        self.assertEqual(len(items), 2)

        # Deve estar ordenado por y0: imagem (20) antes da tabela (50)
        self.assertEqual(items[0]["kind"], "image")
        self.assertEqual(items[0]["bbox"].y0, 20)
        self.assertEqual(items[1]["kind"], "table")
        self.assertEqual(items[1]["bbox"].y0, 50)

    def test_multiple_images_ordered_by_y(self):
        """Múltiplas imagens na mesma página, devem estar ordenadas por y0."""
        # Imagem 1 em y0=100, Imagem 2 em y0=50 (desordenada)
        images_by_page = {
            0: [fitz.Rect(10, 100, 100, 120), fitz.Rect(10, 50, 100, 70)],
        }
        tables_by_page = {}

        result = _combine_and_sort_bboxes(images_by_page, tables_by_page)

        self.assertIn(0, result)
        items = result[0]
        self.assertEqual(len(items), 2)

        # Deve estar ordenado por y0: 50 antes de 100
        self.assertEqual(items[0]["bbox"].y0, 50)
        self.assertEqual(items[1]["bbox"].y0, 100)

    def test_empty_images_and_tables(self):
        """Sem imagens nem tabelas ilegíveis."""
        images_by_page = {}
        tables_by_page = {}

        result = _combine_and_sort_bboxes(images_by_page, tables_by_page)

        self.assertEqual(result, {})

    def test_table_without_bbox(self):
        """Tabela ilegível sem bbox capturado (fallback)."""
        images_by_page = {}
        tables_by_page = {
            0: [{"illegible_page": True}],  # sem "bbox"
        }

        result = _combine_and_sort_bboxes(images_by_page, tables_by_page)

        # Tabela sem bbox deve ser ignorada
        self.assertNotIn(0, result)

    def test_multiple_pages(self):
        """Múltiplas páginas com combinações diferentes."""
        images_by_page = {
            0: [fitz.Rect(10, 20, 100, 40)],
            1: [fitz.Rect(10, 50, 100, 70)],
        }
        tables_by_page = {
            1: [{"illegible_page": True, "bbox": (10, 100, 100, 120)}],
        }

        result = _combine_and_sort_bboxes(images_by_page, tables_by_page)

        # Página 0: 1 imagem
        self.assertIn(0, result)
        self.assertEqual(len(result[0]), 1)
        self.assertEqual(result[0][0]["kind"], "image")

        # Página 1: 1 imagem + 1 tabela
        self.assertIn(1, result)
        self.assertEqual(len(result[1]), 2)
        self.assertEqual(result[1][0]["kind"], "image")
        self.assertEqual(result[1][1]["kind"], "table")

    def test_mixed_with_markdown_table(self):
        """Tabela Markdown (não PNG) deve ser ignorada na combinação de bboxes."""
        images_by_page = {
            0: [fitz.Rect(10, 20, 100, 40)],
        }
        tables_by_page = {
            0: [
                "| Col | Data |\n| --- | --- |\n| A | B |",  # tabela Markdown
                {"illegible_page": True, "bbox": (10, 100, 100, 120)},  # tabela PNG
            ],
        }

        result = _combine_and_sort_bboxes(images_by_page, tables_by_page)

        self.assertIn(0, result)
        items = result[0]
        # Deve ter 2 itens: 1 imagem + 1 tabela ilegível (tabela Markdown ignorada)
        self.assertEqual(len(items), 2)
        self.assertEqual(items[0]["kind"], "image")
        self.assertEqual(items[1]["kind"], "table")


if __name__ == "__main__":
    # Executa testes com saída verbosa
    unittest.main(verbosity=2)
