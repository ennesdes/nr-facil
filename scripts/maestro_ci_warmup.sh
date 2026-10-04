#!/usr/bin/env bash
# Garante que o app abre até a 1ª tela antes de rodar flows no CI (GHA).
#
# `sys.boot_completed=1` não significa emulador utilizável: no runner x86_64
# (swiftshader) o app às vezes nem desenha a 1ª tela e todos os flows falham em
# `normas_tab` — mas passam no re-run. Aqui:
#   1. cold start do app e espera a 1ª tela (mesmo id que o Maestro procura)
#   2. falhou → espera o emulador assentar e tenta de novo
#   3. falhou de novo → reinicia o emulador (adb reboot) e tenta pela última vez
# Com --quick (usado entre retries de um flow) faz só o passo 1: o warmup
# completo já rodou antes dos flows, e repeti-lo a cada retry estoura o timeout
# do job.
#
# Nunca derruba o job: se tudo falhar, avisa e deixa os flows rodarem (o resumo
# do workflow então sugere re-run).
#
# Uso (APK já instalado):
#   bash scripts/maestro_ci_warmup.sh [--quick]
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG="${MAESTRO_APP_ID:-br.com.solvebetter.nrfacil}"
ACTIVITY="${MAESTRO_APP_ACTIVITY:-.MainActivity}"
FIRST_SCREEN_ID="${MAESTRO_FIRST_SCREEN_ID:-normas_tab}"
SCREEN_TIMEOUT="${MAESTRO_WARMUP_TIMEOUT:-90}"
SETTLE_SECONDS="${MAESTRO_WARMUP_SETTLE:-45}"

QUICK=false
[[ "${1:-}" == "--quick" ]] && QUICK=true

log() {
  echo ">> [maestro-ci-warmup] $*"
}

first_screen_visible() {
  adb exec-out uiautomator dump /dev/tty 2>/dev/null \
    | grep -q "resource-id=\"$FIRST_SCREEN_ID\""
}

try_open_app() {
  adb shell am force-stop "$PKG" >/dev/null 2>&1 || true
  adb shell pm clear "$PKG" >/dev/null 2>&1 || true
  adb shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS >/dev/null 2>&1 || true
  adb shell am start -W -n "$PKG/$ACTIVITY" >/dev/null 2>&1 || true

  local start=$SECONDS
  while (( SECONDS - start < SCREEN_TIMEOUT )); do
    if first_screen_visible; then
      log "1ª tela visível em ~$((SECONDS - start))s."
      adb shell am force-stop "$PKG" >/dev/null 2>&1 || true
      return 0
    fi
    sleep 3
  done
  log "1ª tela não apareceu em ${SCREEN_TIMEOUT}s."
  return 1
}

log "Abrindo o app até a 1ª tela ($FIRST_SCREEN_ID)..."
try_open_app && exit 0

if $QUICK; then
  echo "AVISO: app não abriu no warmup rápido — retry do flow segue mesmo assim." >&2
  exit 0
fi

log "Aguardando ${SETTLE_SECONDS}s o emulador assentar e tentando de novo..."
sleep "$SETTLE_SECONDS"
try_open_app && exit 0

log "Reiniciando o emulador (adb reboot) e tentando pela última vez..."
adb reboot || true
# Espera o device cair antes do wait-for-device do prepare (senão ele retorna
# na hora com o device ainda "online" pré-reboot).
timeout 60 adb wait-for-disconnect >/dev/null 2>&1 || sleep 10
# `adb wait-for-device` do prepare não tem timeout — se o emulador não voltar,
# o job travaria até o timeout-minutes.
timeout 300 bash "$ROOT/scripts/maestro_ci_prepare.sh" || true
try_open_app && exit 0

echo "AVISO: emulador não abriu o app após warmup + reboot — flows vão rodar mesmo assim." >&2
exit 0
