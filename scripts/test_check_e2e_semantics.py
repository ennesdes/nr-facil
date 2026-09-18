#!/usr/bin/env python3
"""Testes unitários para scripts/check_e2e_semantics.py.

Testa:
- Caminho feliz: todos os ids Maestro existem como constantes Dart
- Falha: um id Maestro sem constante Dart correspondente
- Edge case: diretório .maestro/ vazio ou ausente
"""

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


class CheckE2ESemanticsBoundaryTest(unittest.TestCase):
    """Testes do gate e2e_semantics contra estrutura real do projeto."""

    def test_empty_maestro_dir_succeeds(self):
        """Se .maestro/ não existe ou está vazio, o gate passa."""
        with tempfile.TemporaryDirectory() as tmpdir:
            tmpdir_p = Path(tmpdir)
            # Cria estrutura mínima: app/lib e scripts/
            app_lib = tmpdir_p / "app" / "lib"
            scripts = tmpdir_p / "scripts"
            scripts.mkdir(parents=True)
            app_lib.mkdir(parents=True)

            # Cria dummy check_e2e_semantics.py neste tmpdir
            script = scripts / "check_e2e_semantics.py"
            script.write_text(
                (ROOT / "scripts" / "check_e2e_semantics.py").read_text()
            )

            # Sem .maestro/flows/ → gate deve passar
            result = subprocess.run(
                ["python3", str(script)],
                cwd=str(tmpdir_p),
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, f"stderr: {result.stderr}")
            self.assertIn("Nenhum flow", result.stdout)

    def test_matching_maestro_id_and_dart_constant_succeeds(self):
        """Quando id Maestro tem constante Dart correspondente, teste passa."""
        with tempfile.TemporaryDirectory() as tmpdir:
            tmpdir_p = Path(tmpdir)

            # Estrutura
            maestro_flows = tmpdir_p / ".maestro" / "flows" / "ci"
            semantics_dir = tmpdir_p / "app" / "lib" / "core" / "constants" / "semantics"
            scripts = tmpdir_p / "scripts"
            scripts.mkdir(parents=True)
            maestro_flows.mkdir(parents=True)
            semantics_dir.mkdir(parents=True)

            # Cria um flow com id
            flow_yaml = maestro_flows / "test_flow.yaml"
            flow_yaml.write_text(
                """commands:
  - tapOn:
      id: "test_button"
"""
            )

            # Cria uma constante Dart correspondente
            const_file = semantics_dir / "test_semantics_ids.dart"
            const_file.write_text(
                """class TestSemanticsIds {
  static const String testButton = 'test_button';
}
"""
            )

            # Copia o script
            script = scripts / "check_e2e_semantics.py"
            script.write_text(
                (ROOT / "scripts" / "check_e2e_semantics.py").read_text()
            )

            # Executa
            result = subprocess.run(
                ["python3", str(script)],
                cwd=str(tmpdir_p),
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, f"stderr: {result.stderr}\nstdout: {result.stdout}")
            self.assertIn("OK", result.stdout)

    def test_missing_dart_constant_fails(self):
        """Quando id Maestro não tem constante Dart, teste falha."""
        with tempfile.TemporaryDirectory() as tmpdir:
            tmpdir_p = Path(tmpdir)

            # Estrutura
            maestro_flows = tmpdir_p / ".maestro" / "flows" / "ci"
            semantics_dir = tmpdir_p / "app" / "lib" / "core" / "constants" / "semantics"
            scripts = tmpdir_p / "scripts"
            scripts.mkdir(parents=True)
            maestro_flows.mkdir(parents=True)
            semantics_dir.mkdir(parents=True)

            # Cria um flow com id órfão
            flow_yaml = maestro_flows / "orphan_flow.yaml"
            flow_yaml.write_text(
                """commands:
  - tapOn:
      id: "orphan_button_id"
"""
            )

            # Cria arquivo Dart vazio (sem a constante)
            const_file = semantics_dir / "empty_semantics_ids.dart"
            const_file.write_text("// vazio\n")

            # Copia o script
            script = scripts / "check_e2e_semantics.py"
            script.write_text(
                (ROOT / "scripts" / "check_e2e_semantics.py").read_text()
            )

            # Executa
            result = subprocess.run(
                ["python3", str(script)],
                cwd=str(tmpdir_p),
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(result.returncode, 0, f"script deveria falhar, stdout: {result.stdout}")
            self.assertIn("não encontrados", result.stdout)
            self.assertIn("orphan_button_id", result.stdout)

    def test_unquoted_maestro_id_and_dynamic_prefix_succeeds(self):
        """IDs sem aspas no YAML e prefixos dinâmicos (ex.: nr_tile_nr-25) passam."""
        with tempfile.TemporaryDirectory() as tmpdir:
            tmpdir_p = Path(tmpdir)

            maestro_flows = tmpdir_p / ".maestro" / "flows" / "ci"
            semantics_dir = tmpdir_p / "app" / "lib" / "core" / "constants" / "semantics"
            scripts = tmpdir_p / "scripts"
            scripts.mkdir(parents=True)
            maestro_flows.mkdir(parents=True)
            semantics_dir.mkdir(parents=True)

            flow_yaml = maestro_flows / "dynamic_flow.yaml"
            flow_yaml.write_text(
                """commands:
  - tapOn:
      id: nr_tile_nr-25
"""
            )

            const_file = semantics_dir / "home_semantics_ids.dart"
            const_file.write_text(
                """class HomeSemanticsIds {
  static String nrTile(String nrId) => 'nr_tile_$nrId';
}
"""
            )

            script = scripts / "check_e2e_semantics.py"
            script.write_text(
                (ROOT / "scripts" / "check_e2e_semantics.py").read_text()
            )

            result = subprocess.run(
                ["python3", str(script)],
                cwd=str(tmpdir_p),
                capture_output=True,
                text=True,
            )
            self.assertEqual(
                result.returncode,
                0,
                f"stderr: {result.stderr}\nstdout: {result.stdout}",
            )
            self.assertIn("OK", result.stdout)


if __name__ == "__main__":
    unittest.main()
