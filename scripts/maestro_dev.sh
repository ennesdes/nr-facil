#!/usr/bin/env bash
# Bootstrap E2E Maestro: emulador (se precisar) → build/install → smoke (3 flows).
#
# Uso:
#   bash scripts/maestro_dev.sh              # smoke (default)
#   bash scripts/maestro_dev.sh --flow <yaml>
#   bash scripts/maestro_dev.sh --rebuild
#   bash scripts/maestro_dev.sh --no-boot
#
# Variáveis opcionais:
#   MAESTRO_AVD            nome do AVD (default: primeiro da lista)
#   MAESTRO_BOOT_TIMEOUT   segundos para aguardar boot (default: 300)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_DIR="$ROOT/app"
APK_DEBUG="$APP_DIR/build/app/outputs/flutter-apk/app-debug.apk"
EMULATOR_LOG="/tmp/nr-facil-emulator.log"
BOOT_TIMEOUT="${MAESTRO_BOOT_TIMEOUT:-300}"

NO_BOOT=false
REBUILD=false
MAESTRO_ARGS=()

fail() {
  echo ""
  echo "ERRO: $*" >&2
  exit 1
}

log_step() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "▶ $*"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

log_info() {
  echo "  • $*"
}

usage() {
  cat <<EOF
Uso: bash scripts/maestro_dev.sh [opções] [--smoke | --flow <yaml>]

Bootstrap: emulador + build (main_e2e.dart) + smoke (.maestro/flows/ci/).

Opções:
  --smoke      Smoke (default)
  --free       Alias de --smoke
  --flow PATH  Um flow YAML
  --rebuild    Apaga APK debug antes do build
  --no-boot    Não inicia emulador
  --avd NAME   AVD específico
  -h, --help

Exemplos:
  bash scripts/maestro_dev.sh
  bash scripts/maestro_dev.sh --flow .maestro/flows/ci/01_leitura.yaml

Docs: scripts/README.md (seção Maestro E2E)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-boot)
      NO_BOOT=true
      shift
      ;;
    --rebuild)
      REBUILD=true
      shift
      ;;
    --smoke|--free)
      MAESTRO_ARGS+=("--smoke")
      shift
      ;;
    --flow)
      [[ -n "${2:-}" ]] || fail "Uso: --flow <caminho.yaml>"
      MAESTRO_ARGS+=("--flow" "$2")
      shift 2
      ;;
    --avd)
      [[ -n "${2:-}" ]] || fail "Uso: --avd <nome>"
      export MAESTRO_AVD="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Argumento desconhecido: $1 (use --help)"
      ;;
  esac
done

if [[ ${#MAESTRO_ARGS[@]} -eq 0 ]]; then
  MAESTRO_ARGS=(--smoke)
fi

find_android_sdk() {
  local candidate=""
  for candidate in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Library/Android/sdk"; do
    [[ -n "$candidate" && -d "$candidate/platform-tools" ]] || continue
    echo "$candidate"
    return 0
  done
  return 1
}

device_serial() {
  adb devices 2>/dev/null | awk 'NR>1 && $2=="device"{print $1; exit}'
}

device_ready() {
  [[ -n "$(device_serial)" ]]
}

boot_completed() {
  [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]
}

resolve_avd() {
  local avd="${MAESTRO_AVD:-}"
  if [[ -n "$avd" ]]; then
    echo "$avd"
    return 0
  fi
  avd="$("$EMULATOR_BIN" -list-avds 2>/dev/null | head -1)"
  [[ -n "$avd" ]] || return 1
  echo "$avd"
}

emulator_running() {
  pgrep -f "qemu-system" >/dev/null 2>&1 || pgrep -f "emulator.*-avd" >/dev/null 2>&1
}

start_emulator() {
  local avd="$1"
  log_info "Iniciando AVD: $avd"
  log_info "Log: $EMULATOR_LOG"
  : >"$EMULATOR_LOG"
  nohup "$EMULATOR_BIN" -avd "$avd" -no-snapshot-load >>"$EMULATOR_LOG" 2>&1 &
  log_info "PID emulador: $!"
}

wait_for_device() {
  local elapsed=0
  log_info "Aguardando boot (timeout ${BOOT_TIMEOUT}s)…"
  while [[ "$elapsed" -lt "$BOOT_TIMEOUT" ]]; do
    if device_ready && boot_completed; then
      echo ""
      log_info "Pronto: $(device_serial)"
      return 0
    fi
    sleep 3
    elapsed=$((elapsed + 3))
    printf "  … %ds / %ds\r" "$elapsed" "$BOOT_TIMEOUT"
  done
  echo ""
  return 1
}

log_step "1/4 — Android SDK"
SDK="$(find_android_sdk)" || fail "$(cat <<'EOF'
Android SDK não encontrado.

Instale Android Studio e crie um AVD, ou defina:
  export ANDROID_HOME="$HOME/Library/Android/sdk"
EOF
)"

ADB_BIN="$SDK/platform-tools/adb"
EMULATOR_BIN="$SDK/emulator/emulator"
[[ -x "$ADB_BIN" ]] || fail "adb não encontrado em $ADB_BIN"
[[ -x "$EMULATOR_BIN" ]] || fail "emulator não encontrado em $EMULATOR_BIN"

export PATH="$SDK/platform-tools:$SDK/emulator:$HOME/.maestro/bin:${PATH:-}"
log_info "SDK: $SDK"

log_step "2/4 — Maestro CLI"
MAESTRO_BIN=""
for candidate in \
  "${MAESTRO_BIN_OVERRIDE:-}" \
  "$(command -v maestro 2>/dev/null || true)" \
  "$HOME/.maestro/bin/maestro"; do
  [[ -z "$candidate" || ! -x "$candidate" ]] && continue
  if "$candidate" test --help >/dev/null 2>&1; then
    MAESTRO_BIN="$candidate"
    break
  fi
done

if [[ -z "$MAESTRO_BIN" ]]; then
  fail "Maestro CLI não encontrado. Instale: curl -fsSL \"https://get.maestro.mobile.dev\" | bash"
fi

log_info "$("$MAESTRO_BIN" --version 2>/dev/null | head -1 || echo "Maestro OK")"

log_step "3/4 — Emulador / device"
if device_ready && boot_completed; then
  log_info "Já conectado: $(device_serial)"
elif device_ready; then
  log_info "Device detectado ($(device_serial)); aguardando boot…"
  wait_for_device || fail "Device não terminou o boot a tempo."
elif $NO_BOOT; then
  fail "Nenhum device/emulador conectado e --no-boot está ativo."
else
  AVD="$(resolve_avd)" || fail "Nenhum AVD encontrado. Crie um no Android Studio."
  if emulator_running; then
    log_info "Processo de emulador já em execução; aguardando adb…"
  else
    start_emulator "$AVD"
  fi
  wait_for_device || fail "Timeout após ${BOOT_TIMEOUT}s esperando o emulador. Log: $EMULATOR_LOG"
fi

log_step "4/4 — Build, instalação e testes"
if $REBUILD && [[ -f "$APK_DEBUG" ]]; then
  log_info "Removendo APK antigo (--rebuild)"
  rm -f "$APK_DEBUG"
fi

echo ""
log_info "Delegando para scripts/maestro_run.sh ${MAESTRO_ARGS[*]}"
echo ""

exec bash "$ROOT/scripts/maestro_run.sh" "${MAESTRO_ARGS[@]}"
