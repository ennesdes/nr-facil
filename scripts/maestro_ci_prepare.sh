#!/usr/bin/env bash
# Prepara emulador/device antes do Maestro no CI (GHA).
#
# Uso:
#   bash scripts/maestro_ci_prepare.sh
set -euo pipefail

PKG="${MAESTRO_APP_ID:-br.com.solvebetter.nrfacil}"
BOOT_TIMEOUT="${MAESTRO_BOOT_TIMEOUT:-180}"

log() {
  echo ">> [maestro-ci-prepare] $*"
}

wait_for_boot() {
  local elapsed=0
  log "Aguardando adb device..."
  adb wait-for-device
  log "Aguardando boot completo (timeout ${BOOT_TIMEOUT}s)..."
  while [[ "$elapsed" -lt "$BOOT_TIMEOUT" ]]; do
    local boot
    boot="$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
    if [[ "$boot" == "1" ]]; then
      log "Boot completo."
      return 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done
  echo "ERRO: timeout aguardando sys.boot_completed (${BOOT_TIMEOUT}s)" >&2
  return 1
}

disable_animations() {
  log "Desabilitando animações (adb settings)..."
  adb shell settings put global window_animation_scale 0 >/dev/null 2>&1 || true
  adb shell settings put global transition_animation_scale 0 >/dev/null 2>&1 || true
  adb shell settings put global animator_duration_scale 0 >/dev/null 2>&1 || true
}

grant_permissions() {
  log "Concedendo permissões para $PKG..."
  adb shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS >/dev/null 2>&1 || true
}

wait_for_boot
disable_animations
grant_permissions

serial="$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device"{print $1; exit}')"
log "Device pronto: ${serial:-desconhecido}"
