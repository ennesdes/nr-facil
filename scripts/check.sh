#!/usr/bin/env bash
# Lint e testes — rodar antes de cada commit
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ERRORS=0

if [ -f "app/pubspec.yaml" ]; then
  echo "==> flutter analyze..."
  cd app
  fvm flutter analyze --fatal-infos || ERRORS=1

  echo "==> flutter test..."
  fvm flutter test || ERRORS=1
  cd "$ROOT"
else
  echo "⚠ app/pubspec.yaml não encontrado — pulando Flutter checks"
fi

if [ -f "scripts/validate_manifest.py" ]; then
  echo "==> validate manifest..."
  python3 scripts/validate_manifest.py || ERRORS=1
fi

if [ -f "scripts/validate_quality.py" ]; then
  echo "==> validate quality..."
  python3 scripts/validate_quality.py --all || ERRORS=1
fi

if [ -f "scripts/audit_contrast.py" ]; then
  echo "==> audit contrast..."
  python3 scripts/audit_contrast.py || ERRORS=1
fi

if [ "$ERRORS" -ne 0 ]; then
  echo "✗ check.sh falhou"
  exit 1
fi

echo "✓ check.sh OK"
