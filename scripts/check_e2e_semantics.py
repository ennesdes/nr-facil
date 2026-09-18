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

# `id: valor` com ou sem aspas (Maestro aceita ambos)
MAESTRO_ID_RE = re.compile(
    r'^\s*id:\s*(?:["\']([a-zA-Z0-9_$\-]+)["\']|([a-zA-Z0-9_$\-]+))\s*$'
)

# Literais em Semantics(identifier: 'foo') ou identifier: XxxSemanticsIds.foo
DART_IDENTIFIER_RE = re.compile(r'identifier:\s*([\'"]?)([a-z0-9_A-Z.$]+)\1')

# static const String foo = 'valor';
DART_CONST_RE = re.compile(
    r"static\s+const\s+String\s+(\w+)\s*=\s*['\"]([a-zA-Z0-9_$\-]+)['\"]"
)

# static String foo(...) => 'prefix_$nrId';
DART_DYNAMIC_PREFIX_RE = re.compile(
    r"static\s+String\s+\w+\([^)]*\)\s*=>\s*['\"]([a-zA-Z0-9_]+)\$"
)


def collect_maestro_ids() -> dict[str, list[tuple[str, int]]]:
    """Coleta todos os `id:` dos flows/subflows Maestro com arquivo e linha."""
    ids: dict[str, list[tuple[str, int]]] = {}

    if not MAESTRO_DIR.exists():
        return ids

    for yaml_file in MAESTRO_DIR.rglob("*.yaml"):
        text = yaml_file.read_text(encoding="utf-8")
        for line_num, line in enumerate(text.splitlines(), 1):
            match = MAESTRO_ID_RE.match(line)
            if not match:
                continue
            id_value = match.group(1) or match.group(2)
            ids.setdefault(id_value, []).append(
                (str(yaml_file.relative_to(ROOT)), line_num)
            )

    return ids


def collect_dart_literals() -> set[str]:
    """Coleta literais passados a `Semantics(identifier: ...)` em app/lib."""
    literals: set[str] = set()

    for dart_file in (ROOT / "app/lib").rglob("*.dart"):
        text = dart_file.read_text(encoding="utf-8")
        for match in DART_IDENTIFIER_RE.finditer(text):
            value = match.group(2)
            if "$" in value:
                continue
            if "." in value:
                continue
            literals.add(value)

    return literals


def collect_dart_constants() -> dict[str, str]:
    """Coleta constantes de *_semantics_ids.dart com seus valores."""
    constants: dict[str, str] = {}

    if not SEMANTICS_DIR.exists():
        return constants

    for dart_file in SEMANTICS_DIR.glob("*.dart"):
        text = dart_file.read_text(encoding="utf-8")
        for match in DART_CONST_RE.finditer(text):
            const_name = match.group(1)
            const_value = match.group(2)
            constants[const_value] = f"{dart_file.name}::{const_name}"

    return constants


def collect_dart_dynamic_prefixes() -> list[str]:
    """Coleta prefixos de IDs dinâmicos (ex.: nr_tile_ a partir de nr_tile_\$nrId)."""
    prefixes: list[str] = []

    if not SEMANTICS_DIR.exists():
        return prefixes

    for dart_file in SEMANTICS_DIR.glob("*.dart"):
        text = dart_file.read_text(encoding="utf-8")
        for match in DART_DYNAMIC_PREFIX_RE.finditer(text):
            prefixes.append(match.group(1))

    return prefixes


def maestro_id_is_valid(
    maestro_id: str,
    dart_constants: dict[str, str],
    dart_literals: set[str],
    dynamic_prefixes: list[str],
) -> bool:
    if maestro_id in dart_constants or maestro_id in dart_literals:
        return True
    return any(maestro_id.startswith(prefix) for prefix in dynamic_prefixes)


def main() -> int:
    maestro_ids = collect_maestro_ids()
    dart_constants = collect_dart_constants()
    dart_literals = collect_dart_literals()
    dynamic_prefixes = collect_dart_dynamic_prefixes()

    if not maestro_ids:
        print("ℹ Nenhum flow Maestro encontrado em .maestro/ — pulando gate")
        return 0

    missing: list[tuple[str, str, int]] = []
    for maestro_id, locations in sorted(maestro_ids.items()):
        if maestro_id_is_valid(
            maestro_id, dart_constants, dart_literals, dynamic_prefixes
        ):
            continue
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
        f"{len(dart_constants)} constantes Dart "
        f"e {len(dynamic_prefixes)} prefixos dinâmicos"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
