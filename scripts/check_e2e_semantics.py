#!/usr/bin/env python3
"""Valida que todo Maestro `id:` existe em constantes Dart (*_semantics_ids.dart).

Uso:
  python3 scripts/check_e2e_semantics.py

Maestro deve usar os mesmos literais definidos em lib/core/constants/semantics/*.dart
(e reexportados pelo barrel e2e_semantics_ids.dart).
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAESTRO_DIR = ROOT / ".maestro"
SEMANTICS_DIR = ROOT / "app/lib/core/constants/semantics"
BARREL_FILE = ROOT / "app/lib/core/constants/e2e_semantics_ids.dart"

# Regex para extrair `id: 'value'` ou `id: "value"` em YAML (aceita a-z, A-Z, 0-9, _, $, -)
MAESTRO_ID_RE = re.compile(r'^\s*id:\s*["\']([a-zA-Z0-9_$\-]+)["\']\s*$')

# Regex para extrair literais Dart em Semantics(identifier: ...)
# Busca por `identifier: XxxSemanticsIds.foo` ou `identifier: 'literal'` ou `identifier: "literal"`
DART_IDENTIFIER_RE = re.compile(r'identifier:\s*([\'"]?)([a-z0-9_A-Z.]+)\1')


def collect_maestro_ids() -> dict[str, list[tuple[str, int]]]:
    """Coleta todos os `id:` dos flows/subflows Maestro com arquivo e linha aprox."""
    ids: dict[str, list[tuple[str, int]]] = {}

    if not MAESTRO_DIR.exists():
        return ids

    for yaml_file in MAESTRO_DIR.rglob("*.yaml"):
        text = yaml_file.read_text(encoding="utf-8")
        for line_num, line in enumerate(text.splitlines(), 1):
            match = MAESTRO_ID_RE.match(line)
            if match:
                id_value = match.group(1)
                if id_value not in ids:
                    ids[id_value] = []
                ids[id_value].append((str(yaml_file.relative_to(ROOT)), line_num))

    return ids


def collect_dart_literals() -> set[str]:
    """Coleta todos os literais string passados a `Semantics(identifier: ...)` em Dart."""
    literals: set[str] = set()

    # Procura em todo app/lib/**/*.dart
    for dart_file in (ROOT / "app/lib").rglob("*.dart"):
        text = dart_file.read_text(encoding="utf-8")
        for match in DART_IDENTIFIER_RE.finditer(text):
            value = match.group(2)
            # Extrai literais simples (sem interpolação)
            if not '$' in value and not '.' in value:
                literals.add(value)
            # Se for XxxSemanticsIds.foo, extrai só o "foo" parte (valor da constante)
            elif '.' in value and value.startswith(value.split('.')[0][0].upper()):
                # É algo como XxxSemanticsIds.foo — será resolvido dinamicamente
                # Por enquanto, considera como válido se a classe existir
                pass

    return literals


def collect_dart_constants() -> dict[str, str]:
    """Coleta constantes de *_semantics_ids.dart com seus valores."""
    constants: dict[str, str] = {}

    if not SEMANTICS_DIR.exists():
        return constants

    for dart_file in SEMANTICS_DIR.glob("*.dart"):
        text = dart_file.read_text(encoding="utf-8")
        # Regex para `static const String foo = 'valor';`
        const_re = re.compile(r'static\s+const\s+String\s+(\w+)\s*=\s*[\'"]([a-z0-9_]+)[\'"]')
        for match in const_re.finditer(text):
            const_name = match.group(1)
            const_value = match.group(2)
            constants[const_value] = f"{dart_file.name}::{const_name}"

    return constants


def main() -> int:
    maestro_ids = collect_maestro_ids()
    dart_constants = collect_dart_constants()
    dart_literals = collect_dart_literals()

    # Se não há flows no .maestro/, sair OK
    if not maestro_ids:
        print("ℹ Nenhum flow Maestro encontrado em .maestro/ — pulando gate")
        return 0

    # Verifica se cada id Maestro existe em Dart
    missing: list[tuple[str, str, int]] = []
    for maestro_id, locations in sorted(maestro_ids.items()):
        found = False

        # Verifica em constantes Dart
        if maestro_id in dart_constants:
            found = True
        # Verifica em literais extraídos
        elif maestro_id in dart_literals:
            found = True

        if not found:
            for yaml_path, line_num in locations:
                missing.append((maestro_id, yaml_path, line_num))

    if missing:
        print("✗ IDs de Maestro não encontrados em constantes Dart:")
        for maestro_id, yaml_path, line_num in missing:
            print(f"  {yaml_path}:{line_num} → id: '{maestro_id}'")
        print(
            "\nCorreja em lib/core/constants/semantics/*.dart ou atualize "
            "scripts/check_e2e_semantics.py se necessário.",
            file=sys.stderr,
        )
        return 1

    print(
        f"✓ OK: {len(maestro_ids)} IDs Maestro validados contra "
        f"{len(dart_constants)} constantes Dart"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
