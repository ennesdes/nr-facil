#!/usr/bin/env bash
# Executa um flow Maestro no CI com retry e reset (adb/emulador instável no GHA).
#
# Uso (emulador já bootado, APK já instalado):
#   MAESTRO_APK=app/build/app/outputs/flutter-apk/app-debug.apk \
#     bash scripts/maestro_ci_flow.sh .maestro/flows/ci/01_leitura.yaml
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLOW="${1:?Uso: bash scripts/maestro_ci_flow.sh <flow.yaml>}"
PKG="${MAESTRO_APP_ID:-br.com.solvebetter.nrfacil}"
APK="${MAESTRO_APK:-$ROOT/app/build/app/outputs/flutter-apk/app-debug.apk}"

export MAESTRO_SKIP_BUILD=1
export MAESTRO_APP_ID="$PKG"
export MAESTRO_APK="$APK"
export PATH="$HOME/.maestro/bin:${PATH:-}"

attempt=1
max_attempts="${MAESTRO_CI_MAX_ATTEMPTS:-3}"

prepare_device() {
  bash "$ROOT/scripts/maestro_ci_prepare.sh"
}

reinstall_app() {
  if [[ ! -f "$APK" ]]; then
    echo "AVISO: APK não encontrado em $APK — retry sem reinstall." >&2
    return 0
  fi
  echo ">> Limpando dados do app e reinstalando APK..."
  adb shell pm clear "$PKG" >/dev/null 2>&1 || true
  adb install -r "$APK"
}

prepare_device

until bash "$ROOT/scripts/maestro_run.sh" --flow "$FLOW"; do
  if [[ $attempt -ge $max_attempts ]]; then
    echo "Falhou após $attempt tentativa(s) — desistindo." >&2
    exit 1
  fi
  echo "Tentativa $attempt/$max_attempts falhou — reset adb + app e tentando de novo..." >&2
  adb kill-server || true
  adb start-server
  prepare_device
  reinstall_app
  attempt=$((attempt + 1))
done
