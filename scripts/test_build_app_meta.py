#!/usr/bin/env python3
"""
Testes unitários para as funções puras de build_app_meta.py:
- parse_summary_items
- generate_summary

Uso:
  python3 scripts/test_build_app_meta.py
  python3 scripts/test_build_app_meta.py -v (verbose)
"""
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import build_app_meta
from build_app_meta import (
    parse_summary_items,
    generate_summary,
)


class TestParseSummaryItems(unittest.TestCase):
    """Testes para parse_summary_items."""

    def test_parse_novo_item(self):
        """Parse de um novo item (🆕)."""
        lines = [
            "### NR-06",
            "- 🆕 Novo item **6.3**: Procedimento de isolamento de energia",
        ]
        items = parse_summary_items(lines)
        self.assertEqual(len(items), 1)
        self.assertEqual(items[0]["item"], "6.3")
        self.assertEqual(items[0]["tipo"], "novo")
        self.assertEqual(items[0]["resumo"], "Procedimento de isolamento de energia")

    def test_parse_removido_item(self):
        """Parse de um item removido (❌)."""
        lines = [
            "### NR-10",
            "- ❌ Item removido **10.4**: Antigo procedimento de teste",
        ]
        items = parse_summary_items(lines)
        self.assertEqual(len(items), 1)
        self.assertEqual(items[0]["item"], "10.4")
        self.assertEqual(items[0]["tipo"], "removido")
        self.assertEqual(items[0]["resumo"], "Antigo procedimento de teste")

    def test_parse_alterado_item(self):
        """Parse de um item alterado (✏️)."""
        lines = [
            "### NR-01",
            "- ✏️ Item alterado **1.2**",
            "  - antes: …requisitos anteriores…",
            "  - depois: …requisitos novos…",
        ]
        items = parse_summary_items(lines)
        self.assertEqual(len(items), 1)
        self.assertEqual(items[0]["item"], "1.2")
        self.assertEqual(items[0]["tipo"], "alterado")

    def test_parse_mixed_items(self):
        """Parse de múltiplos itens de tipos diferentes."""
        lines = [
            "### NR-17",
            "- 🆕 Novo item **17.1**: Nova seção",
            "- ❌ Item removido **17.2**: Seção antiga",
            "- ✏️ Item alterado **17.3**",
            "  - antes: …antes…",
            "  - depois: …depois…",
        ]
        items = parse_summary_items(lines)
        self.assertEqual(len(items), 3)
        self.assertEqual(items[0]["tipo"], "novo")
        self.assertEqual(items[1]["tipo"], "removido")
        self.assertEqual(items[2]["tipo"], "alterado")

    def test_parse_ignores_indented_lines(self):
        """Linhas indentadas (sub-detalhes) são ignoradas."""
        lines = [
            "### NR-05",
            "- 🆕 Novo item **5.1**: Item novo",
            "  - antes: …texto…",
            "  - depois: …texto novo…",
            "  - (+1 outro(s) trecho(s) diferente(s))",
        ]
        items = parse_summary_items(lines)
        # Deve ter apenas 1 item (as sub-linhas são ignoradas)
        self.assertEqual(len(items), 1)
        self.assertEqual(items[0]["item"], "5.1")

    def test_parse_empty_list(self):
        """Lista vazia de linhas."""
        items = parse_summary_items([])
        self.assertEqual(items, [])

    def test_parse_heading_only(self):
        """Apenas cabeçalho, sem itens."""
        lines = ["### NR-20"]
        items = parse_summary_items(lines)
        self.assertEqual(items, [])

    def test_parse_complex_item_number(self):
        """Item com número complexo (ex.: 10.4.2.1)."""
        lines = [
            "### NR-10",
            "- 🆕 Novo item **10.4.2.1**: Descrição detalhada",
        ]
        items = parse_summary_items(lines)
        self.assertEqual(len(items), 1)
        self.assertEqual(items[0]["item"], "10.4.2.1")

    def test_parse_resumo_with_special_chars(self):
        """Resumo com caracteres especiais (acentuação, etc.)."""
        lines = [
            "### NR-06",
            "- 🆕 Novo item **6.5**: Equipamento de proteção à pessoa — EPP obrigatório",
        ]
        items = parse_summary_items(lines)
        self.assertEqual(len(items), 1)
        self.assertIn("EPP", items[0]["resumo"])
        self.assertIn("—", items[0]["resumo"])

    def test_parse_resumo_empty_for_alterado(self):
        """Item alterado tem resumo vazio (detalhes estão nas sub-linhas)."""
        lines = [
            "### NR-03",
            "- ✏️ Item alterado **3.1**",
        ]
        items = parse_summary_items(lines)
        self.assertEqual(len(items), 1)
        self.assertEqual(items[0]["resumo"], "")


class TestGenerateSummary(unittest.TestCase):
    """Testes para generate_summary."""

    def test_empty_items_list(self):
        """Lista vazia → resumo genérico."""
        summary = generate_summary([])
        self.assertEqual(summary, "Atualização disponível")
        # Garantir que não contém "None"
        self.assertNotIn("None", summary)

    def test_single_novo_item(self):
        """Um novo item."""
        items = [
            {"item": "6.3", "tipo": "novo", "resumo": "..."}
        ]
        summary = generate_summary(items)
        self.assertIn("novo item adicionado", summary)
        self.assertIn("6.3", summary)
        self.assertNotIn("None", summary)

    def test_single_removido_item(self):
        """Um item removido."""
        items = [
            {"item": "10.4", "tipo": "removido", "resumo": "..."}
        ]
        summary = generate_summary(items)
        self.assertIn("item removido", summary)
        self.assertIn("10.4", summary)
        self.assertNotIn("None", summary)

    def test_single_alterado_item(self):
        """Um item alterado."""
        items = [
            {"item": "1.2", "tipo": "alterado", "resumo": ""}
        ]
        summary = generate_summary(items)
        self.assertIn("item alterado", summary)
        self.assertIn("1.2", summary)
        self.assertNotIn("None", summary)

    def test_multiple_items(self):
        """Múltiplos itens → contagem total."""
        items = [
            {"item": "6.3", "tipo": "novo", "resumo": "..."},
            {"item": "10.4", "tipo": "removido", "resumo": "..."},
            {"item": "1.2", "tipo": "alterado", "resumo": ""},
        ]
        summary = generate_summary(items)
        self.assertIn("3 itens alterados", summary)
        self.assertNotIn("None", summary)

    def test_many_items(self):
        """Muitos itens (ex.: 25)."""
        items = [
            {"item": f"{i}.{j}", "tipo": "novo", "resumo": "..."}
            for i in range(5) for j in range(5)
        ]
        summary = generate_summary(items)
        self.assertIn("25 itens", summary)
        self.assertNotIn("None", summary)

    def test_summary_never_contains_literal_none(self):
        """
        Teste crítico (CA1): summary nunca deve conter "None" como string literal.
        Testa vários cenários de entrada.
        """
        test_cases = [
            [],  # vazio
            [{"item": "1.1", "tipo": "novo", "resumo": "item"}],  # um item
            [
                {"item": "1.1", "tipo": "novo", "resumo": "..."},
                {"item": "1.2", "tipo": "removido", "resumo": "..."},
            ],  # múltiplos
        ]

        for items in test_cases:
            summary = generate_summary(items)
            self.assertNotIn("None", summary, f"Summary contém 'None': {summary}")
            self.assertNotIn("null", summary, f"Summary contém 'null': {summary}")


class TestIntegration(unittest.TestCase):
    """Testes de integração."""

    def test_parse_then_generate_summary(self):
        """Parse de linhas de summarize_md, gera items, depois summary."""
        lines = [
            "### NR-06",
            "- 🆕 Novo item **6.3**: Procedimento novo",
            "- ❌ Item removido **6.1**: Procedimento antigo",
            "  - antes: …antigo…",
        ]
        items = parse_summary_items(lines)
        summary = generate_summary(items)

        # Verificar que items foram parseados corretamente
        self.assertEqual(len(items), 2)

        # Verificar que summary é coerente
        self.assertIn("2 itens", summary)
        self.assertNotIn("None", summary)

    def test_real_world_scenario_nr_06_like(self):
        """Simula um cenário real similar a NR-06."""
        # Linha real que summarize_md poderia gerar
        lines = [
            "### NR-06",
            "- 🆕 Novo item **6.21**: Equipamento de proteção contra radiação",
            "- ✏️ Item alterado **6.5**",
            "  - antes: …Proteção auditiva em ambientes com ruído acima de 85 dB…",
            "  - depois: …Proteção auditiva obrigatória em ambientes com ruído acima de 80 dB…",
        ]
        items = parse_summary_items(lines)
        summary = generate_summary(items)

        self.assertEqual(len(items), 2)
        self.assertIn("2 itens alterados", summary)
        self.assertNotIn("None", summary)


class TestBuildAppMetaIntegration(unittest.TestCase):
    """Testes de integração para build_app_meta() (orquestração completa)."""

    def _run_with_manifest(self, manifest, previous_app_meta=None):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            manifest_file = tmp_path / "manifest.json"
            app_meta_file = tmp_path / "app_meta.json"
            manifest_file.write_text(json.dumps(manifest), encoding="utf-8")
            if previous_app_meta is not None:
                app_meta_file.write_text(json.dumps(previous_app_meta), encoding="utf-8")

            with patch.object(build_app_meta, "MANIFEST_FILE", manifest_file), \
                 patch.object(build_app_meta, "APP_META_FILE", app_meta_file):
                build_app_meta.build_app_meta(dry_run=False)
                return json.loads(app_meta_file.read_text(encoding="utf-8"))

    def test_first_version_never_contains_none(self):
        """NR sem entrada anterior no feed → 'Primeira versão (...)', nunca 'None' literal."""
        manifest = {
            "nrs": [
                {"id": "nr-99", "title": "NR TESTE", "hash": "abc123", "pdf_hash": "def456", "publicado_em": None}
            ]
        }
        result = self._run_with_manifest(manifest)

        self.assertEqual(len(result["updates"]), 1)
        entry = result["updates"][0]
        self.assertTrue(entry["summary"].startswith("Primeira versão"))
        self.assertNotIn("None", entry["summary"])
        self.assertEqual(entry["items"], [])

    def test_unchanged_hash_generates_no_entry(self):
        """Hash (md) igual ao anterior → nenhuma entrada nova."""
        manifest = {"nrs": [{"id": "nr-01", "title": "NR-01", "hash": "same", "pdf_hash": "irrelevant"}]}
        previous = {"updates": [{"nr_id": "nr-01", "hash": "same"}]}
        result = self._run_with_manifest(manifest, previous_app_meta=previous)

        self.assertEqual(len(result["updates"]), 1)  # só a entrada anterior, nenhuma nova

    def test_changed_hash_without_git_history_falls_back_gracefully(self):
        """Hash mudou mas git_show falha (sem histórico) → items vazio, sem quebrar."""
        manifest = {"nrs": [{"id": "nr-02", "title": "NR-02", "hash": "new-hash", "pdf_hash": "irrelevant"}]}
        previous = {"updates": [{"nr_id": "nr-02", "hash": "old-hash"}]}

        with patch.object(build_app_meta, "git_show", return_value=None):
            result = self._run_with_manifest(manifest, previous_app_meta=previous)

        entries = [u for u in result["updates"] if u.get("hash") == "new-hash"]
        self.assertEqual(len(entries), 1)
        self.assertEqual(entries[0]["items"], [])
        self.assertNotIn("None", entries[0]["summary"])


if __name__ == "__main__":
    # Executa testes com saída verbosa
    unittest.main(verbosity=2)
