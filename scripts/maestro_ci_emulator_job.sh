#!/usr/bin/env bash
# Job GHA: emulador já bootado (android-emulator-runner) → prepare → install APK → flow.
#
# Uso (uma linha no workflow — o runner executa cada linha do script em shell separado):
#   bash scripts/maestro_ci_emulator_job.sh 01_leitura
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLOW_BASENAME="${1:?Uso: bash scripts/maestro_ci_emulator_job.sh <flow-basename-sem-.yaml>}"

export MAESTRO_APP_ID="${MAESTRO_APP_ID:-br.com.solvebetter.nrfacil}"
export MAESTRO_APK="${MAESTRO_APK:-$ROOT/app/build/app/outputs/flutter-apk/app-debug.apk}"
export MAESTRO_SKIP_BUILD=1
export MAESTRO_CI_MAX_ATTEMPTS="${MAESTRO_CI_MAX_ATTEMPTS:-3}"
export PATH="$HOME/.maestro/bin:${PATH:-}"

chmod +x \
  "$ROOT/scripts/maestro_run.sh" \
  "$ROOT/scripts/maestro_ci_flow.sh" \
  "$ROOT/scripts/maestro_ci_prepare.sh"

bash "$ROOT/scripts/maestro_ci_prepare.sh"
adb install -r "$MAESTRO_APK"
bash "$ROOT/scripts/maestro_ci_flow.sh" "$ROOT/.maestro/flows/ci/${FLOW_BASENAME}.yaml"
