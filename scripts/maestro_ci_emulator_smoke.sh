#!/usr/bin/env bash
# Job GHA: emulador já bootado → prepare → install APK → todos os flows CI em sequência.
#
# Uso (uma linha no workflow — o runner executa cada linha do script em shell separado):
#   bash scripts/maestro_ci_emulator_smoke.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CI_DIR="$ROOT/.maestro/flows/ci"

export MAESTRO_APP_ID="${MAESTRO_APP_ID:-br.com.solvebetter.nrfacil}"
export MAESTRO_APK="${MAESTRO_APK:-$ROOT/app/build/app/outputs/flutter-apk/app-debug.apk}"
export MAESTRO_CI_MAX_ATTEMPTS="${MAESTRO_CI_MAX_ATTEMPTS:-3}"
export MAESTRO_SKIP_BUILD=1
export PATH="$HOME/.maestro/bin:${PATH:-}"

chmod +x \
  "$ROOT/scripts/maestro_run.sh" \
  "$ROOT/scripts/maestro_ci_flow.sh" \
  "$ROOT/scripts/maestro_ci_prepare.sh"

bash "$ROOT/scripts/maestro_ci_prepare.sh"
adb install -r "$MAESTRO_APK"

shopt -s nullglob
flows=("$CI_DIR"/*.yaml)
shopt -u nullglob

[[ ${#flows[@]} -gt 0 ]] || {
  echo "ERRO: nenhum flow em $CI_DIR" >&2
  exit 1
}

failed=0
for flow in "${flows[@]}"; do
  name="$(basename "$flow" .yaml)"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "▶ Flow: $name"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if bash "$ROOT/scripts/maestro_ci_flow.sh" "$flow"; then
    echo ">> OK: $name"
  else
    echo ">> FALHOU: $name" >&2
    status_file="$ROOT/build/maestro-results/status-${name}.json"
    if [[ -f "$status_file" ]] && command -v jq >/dev/null 2>&1; then
      err="$(jq -r '.error // empty' "$status_file")"
      [[ -n "$err" ]] && echo ">> Motivo: $err" >&2
      echo ">> JUnit: $ROOT/build/maestro-results/${name}.xml" >&2
    fi
    failed=1
  fi
done

exit "$failed"
