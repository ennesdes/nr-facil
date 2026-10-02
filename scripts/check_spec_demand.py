#!/usr/bin/env python3
"""Warn when spec/demands/active/*/spec.md is missing required SDD sections."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ACTIVE = ROOT / "spec" / "demands" / "active"

CHECKS: tuple[tuple[str, str], ...] = (
    (r"^##\s*1\.\s*Visão", "seção 1 (Visão Geral)"),
    (r"^##\s*2\.\s*Escopo", "seção 2 (Escopo)"),
    (r"^##\s*7\.\s*Critérios", "seção 7 (Critérios de Aceitação)"),
    (r"^##\s*8\.\s*Definition", "seção 8 (DoD)"),
)


def main() -> int:
    specs = list(ACTIVE.glob("*/spec.md"))
    if not specs:
        print("SPEC_DEMAND: n/a (nenhuma demanda ativa)")
        return 0

    warnings: list[str] = []
    for path in specs:
        text = path.read_text(encoding="utf-8")
        slug = path.parent.name
        for pattern, label in CHECKS:
            if not re.search(pattern, text, re.MULTILINE):
                warnings.append(f"{slug}: falta {label}")

    if not warnings:
        print("SPEC_DEMAND: ok")
        return 0

    print("SPEC_DEMAND: aviso")
    for w in warnings:
        print(f"  - {w}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
