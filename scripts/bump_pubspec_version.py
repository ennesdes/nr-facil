#!/usr/bin/env python3
"""Increment versionCode (+1) and versionName patch (+1) in app/pubspec.yaml.

Modes:
  (no args)     compute next version, write it, print it (legacy/local use).
  --dry-run     compute next version, print it, do NOT write the file.
  --set X.Y.Z+N write the given exact version string, print it.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PUBSPEC = ROOT / "app" / "pubspec.yaml"

VERSION_RE = re.compile(
    r"^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$",
    re.MULTILINE,
)

EXPLICIT_VERSION_RE = re.compile(r"^\d+\.\d+\.\d+\+\d+$")


def read_content() -> str:
    if not PUBSPEC.is_file():
        print(f"pubspec.yaml not found: {PUBSPEC}", file=sys.stderr)
        sys.exit(1)
    return PUBSPEC.read_text(encoding="utf-8")


def compute_next_version(content: str) -> str:
    match = VERSION_RE.search(content)
    if not match:
        print(
            "Invalid or missing version line in pubspec.yaml "
            "(expected format: version: X.Y.Z+N)",
            file=sys.stderr,
        )
        sys.exit(1)

    major, minor, patch, build = (int(g) for g in match.groups())
    return f"{major}.{minor}.{patch + 1}+{build + 1}"


def write_version(content: str, new_version: str) -> None:
    new_content, count = VERSION_RE.subn(f"version: {new_version}", content, count=1)
    if count == 0:
        print(
            "Invalid or missing version line in pubspec.yaml "
            "(expected format: version: X.Y.Z+N)",
            file=sys.stderr,
        )
        sys.exit(1)
    PUBSPEC.write_text(new_content, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--dry-run", action="store_true", help="compute only, don't write")
    group.add_argument("--set", metavar="X.Y.Z+N", help="write this exact version, don't increment")
    args = parser.parse_args()

    content = read_content()

    if args.set:
        if not EXPLICIT_VERSION_RE.match(args.set):
            print(f"Invalid version format: {args.set} (expected X.Y.Z+N)", file=sys.stderr)
            return 1
        write_version(content, args.set)
        print(args.set)
        return 0

    new_version = compute_next_version(content)
    if not args.dry_run:
        write_version(content, new_version)
    print(new_version)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
