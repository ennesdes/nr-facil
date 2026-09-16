#!/usr/bin/env bash
# Roda localmente tudo que a CI valida (analyze, test, format, manifest) e já
# corrige o que dá pra corrigir sozinho (format, seed manifest), para não
# precisar disparar a Action e voltar depois para corrigir.
#
# Uso: ./scripts/precommit.sh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ERRORS=0
FIXED=()

if [ -f "app/pubspec.yaml" ]; then
  cd app

  echo "==> dart format (auto-fix)..."
  FORMAT_OUT="$(fvm dart format lib test 2>&1)"
  if echo "$FORMAT_OUT" | grep -qv "^Formatted .*(0 changed)"; then
    CHANGED=$(echo "$FORMAT_OUT" | grep -c "^Changed" || true)
    if [ "$CHANGED" -gt 0 ]; then
      FIXED+=("dart format ($CHANGED arquivo(s))")
    fi
  fi
  echo "$FORMAT_OUT" | tail -1

  echo "==> flutter analyze..."
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

if [ -f "manifest.json" ] && [ -f "app/assets/seed/manifest.json" ]; then
  echo "==> seed manifest (auto-fix)..."
  if ! diff -q manifest.json app/assets/seed/manifest.json >/dev/null 2>&1; then
    cp manifest.json app/assets/seed/manifest.json
    FIXED+=("app/assets/seed/manifest.json sincronizado")
  fi
fi

if [ -f "scripts/validate_quality.py" ]; then
  echo "==> validate quality..."
  python3 scripts/validate_quality.py --all || ERRORS=1
fi

if [ -f "scripts/audit_contrast.py" ]; then
  echo "==> audit contrast..."
  python3 scripts/audit_contrast.py || ERRORS=1
fi

echo ""
echo "───────────────────────────────────────"
if [ ${#FIXED[@]} -gt 0 ]; then
  echo "🔧 Corrigido automaticamente:"
  for f in "${FIXED[@]}"; do
    echo "   - $f"
  done
fi

if [ "$ERRORS" -ne 0 ]; then
  echo "✗ Falhas que precisam de correção manual (veja o log acima)."
  echo "───────────────────────────────────────"
  exit 1
fi

if [ ${#FIXED[@]} -gt 0 ]; then
  echo "✓ Tudo passou — revise as correções automáticas acima e commite."
else
  echo "✓ Tudo OK — nada para corrigir. Pode commitar."
fi
echo "───────────────────────────────────────"
