#!/usr/bin/env python3
"""Warn when spec rule files exceed line budget (default 500)."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = ROOT / "spec"
BUDGET = 500
SKIP = {"README.md", "INDEX.md"}


def main() -> int:
    over: list[str] = []
    for path in SPEC.rglob("*.md"):
        if path.name in SKIP or "_templates" in path.parts:
            continue
        if "demands/done" in str(path):
            continue
        lines = path.read_text(encoding="utf-8").count("\n") + 1
        if lines > BUDGET:
            over.append(f"{path.relative_to(ROOT)} ({lines} linhas)")

    if not over:
        print("DOC_BUDGET: ok")
        return 0

    print("DOC_BUDGET: aviso")
    for item in sorted(over):
        print(f"  - {item}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
