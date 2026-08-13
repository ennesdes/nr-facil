#!/usr/bin/env python3
"""Valida manifest.json na raiz do repositório."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "manifest.json"

REQUIRED_TOP = {"generated_at", "version", "nrs"}
REQUIRED_NR = {"id", "title", "hash", "url"}


def validate(manifest_path: Path) -> list[str]:
    errors: list[str] = []
    if not manifest_path.exists():
        errors.append(f"manifest não encontrado: {manifest_path} (ok na Fase 0)")
        return errors

    try:
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        return [f"JSON inválido: {e}"]

    missing = REQUIRED_TOP - set(data.keys())
    if missing:
        errors.append(f"campos ausentes no manifest: {missing}")

    nrs = data.get("nrs", [])
    if not isinstance(nrs, list):
        errors.append("'nrs' deve ser uma lista")
        return errors

    for i, nr in enumerate(nrs):
        if not isinstance(nr, dict):
            errors.append(f"nrs[{i}] deve ser objeto")
            continue
        nr_missing = REQUIRED_NR - set(nr.keys())
        if nr_missing:
            errors.append(f"nrs[{i}] ({nr.get('id', '?')}): faltando {nr_missing}")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Valida manifest.json")
    parser.add_argument("--path", type=Path, default=MANIFEST)
    args = parser.parse_args()

    errors = validate(args.path)
    if not args.path.exists():
        print("⚠ manifest.json ainda não existe — Fase 0 ok")
        return 0

    if errors:
        for e in errors:
            print(f"✗ {e}")
        return 1

    print("✓ manifest.json válido")
    return 0


if __name__ == "__main__":
    sys.exit(main())
