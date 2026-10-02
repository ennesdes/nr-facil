#!/usr/bin/env python3
"""Warn when app/lib/features/*/views changes without FEATURE.md or spec/capabilities/."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VIEWS_PREFIX = "app/lib/features/"


def changed_files() -> list[str]:
    files: set[str] = set()
    for cmd in (
        ["git", "diff", "--name-only", "HEAD"],
        ["git", "diff", "--name-only", "--cached"],
    ):
        r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
        if r.returncode == 0:
            for ln in r.stdout.splitlines():
                if ln.strip():
                    files.add(ln.strip())
    status = subprocess.run(
        ["git", "status", "--porcelain"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    for line in status.stdout.splitlines():
        if len(line) < 4:
            continue
        path = line[3:].strip()
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        files.add(path)
    return sorted(files)


def feature_from_path(path: str) -> str | None:
    if not path.startswith(VIEWS_PREFIX):
        return None
    parts = path[len(VIEWS_PREFIX) :].split("/")
    if len(parts) < 2 or parts[1] != "views":
        return None
    return parts[0]


def main() -> int:
    files = changed_files()
    features_touched: set[str] = set()
    doc_touched: set[str] = set()

    for f in files:
        feat = feature_from_path(f)
        if feat:
            features_touched.add(feat)
        if f.startswith("app/lib/features/") and f.endswith("/FEATURE.md"):
            doc_touched.add(f.split("/")[3])
        if f.startswith("spec/capabilities/"):
            doc_touched.add(f.split("/")[2])

    demand_active_touched = any(f.startswith("spec/demands/active/") for f in files)

    if not features_touched:
        print("FEATURE_DOCS: n/a")
        return 0

    missing = features_touched - doc_touched
    if missing and demand_active_touched:
        print("FEATURE_DOCS: ok (spec/demands/active)")
        return 0
    if not missing:
        print("FEATURE_DOCS: ok")
        return 0

    print("FEATURE_DOCS: aviso — views/ sem FEATURE.md ou spec/capabilities/ no diff:")
    for feat in sorted(missing):
        print(f"  app/lib/features/{feat}/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
