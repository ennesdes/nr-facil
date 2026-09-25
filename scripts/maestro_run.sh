#!/usr/bin/env bash
# Executa smoke Maestro do NR Fácil (flows em .maestro/flows/ci/).
#
# Uso:
#   bash scripts/maestro_run.sh              # smoke (default)
#   bash scripts/maestro_run.sh --smoke
#   bash scripts/maestro_run.sh --flow <yaml>
#
# Pré-requisitos: Maestro CLI, adb, device/emulador conectado, fvm.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PKG="br.com.solvebetter.nrfacil"
APP_DIR="$ROOT/app"
APK_DEBUG="$APP_DIR/build/app/outputs/flutter-apk/app-debug.apk"
CI_DIR="$ROOT/.maestro/flows/ci"
E2E_TARGET="lib/main_e2e.dart"

MAESTRO_BIN=""

fail() {
  echo "ERRO: $*" >&2
  exit 1
}

resolve_maestro() {
  if [[ -n "$MAESTRO_BIN" ]]; then
    return 0
  fi

  local candidate=""
  for candidate in \
    "${MAESTRO_BIN_OVERRIDE:-}" \
    "$(command -v maestro 2>/dev/null || true)" \
    "$HOME/.maestro/bin/maestro"; do
    [[ -z "$candidate" || ! -x "$candidate" ]] && continue
    if "$candidate" test --help >/dev/null 2>&1; then
      MAESTRO_BIN="$candidate"
      return 0
    fi
  done

  fail "$(cat <<'EOF'
Maestro CLI (mobile UI testing) não encontrado.

Instale: curl -fsSL "https://get.maestro.mobile.dev" | bash
Docs: scripts/README.md (seção Maestro E2E)
EOF
)"
}

require_maestro() {
  resolve_maestro
}

require_device() {
  local devices
  devices="$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device"{print $1}')"
  if [[ -z "$devices" ]]; then
    fail "Nenhum device/emulador conectado (adb devices vazio)."
  fi
}

flutter_cmd() {
  if command -v fvm >/dev/null 2>&1 && [[ -f "$ROOT/.fvmrc" ]]; then
    fvm flutter "$@"
  else
    flutter "$@"
  fi
}

build_debug_apk() {
  echo ">> Build APK debug (target=$E2E_TARGET)..."
  (
    cd "$APP_DIR"
    flutter_cmd build apk --debug --target="$E2E_TARGET"
  )
  [[ -f "$APK_DEBUG" ]] || fail "APK não gerado em $APK_DEBUG"
}

install_apk() {
  local apk="${MAESTRO_APK:-$APK_DEBUG}"
  echo ">> Instalando $apk ..."
  adb install -r "$apk"
}

should_skip_build() {
  [[ "${MAESTRO_SKIP_BUILD:-}" == "1" ]]
}

flow_title() {
  local flow="$1"
  local title
  title="$(awk '/^---$/{exit} /^name:/{sub(/^name: */,""); print; exit}' "$flow")"
  title="${title%\"}"
  title="${title#\"}"
  [[ -n "$title" ]] && echo "$title" || basename "$flow" .yaml
}

flow_description() {
  local flow="$1"
  awk '/^---$/{p=1; next} p && /^#/{sub(/^# ?/,""); print; next} p && !/^#/{exit}' "$flow" \
    | paste -sd ' ' -
}

extract_junit_failure() {
  local junit_file="$1"
  [[ -f "$junit_file" ]] || { echo "sem relatório JUnit"; return; }
  local msg
  msg="$(grep -o '<failure message="[^"]*"' "$junit_file" | head -1 | sed -E 's/<failure message="//; s/"$//')"
  if [[ -z "$msg" ]]; then
    msg="$(sed -n 's/.*<failure>\([^<]*\)<\/failure>.*/\1/p' "$junit_file" | head -1)"
  fi
  [[ -n "$msg" ]] && echo "$msg" || echo "falha sem mensagem detalhada — ver relatório completo"
}

run_maestro_test() {
  local flow="$1"
  local name desc results_dir start_ts end_ts duration passed status_label exit_code error
  name="$(basename "$flow" .yaml)"
  desc="$(flow_description "$flow")"
  results_dir="$ROOT/build/maestro-results"
  mkdir -p "$results_dir"
  echo ">> Maestro ($MAESTRO_BIN): $name"
  echo "   Valida: $desc"
  start_ts=$(date +%s)
  if "$MAESTRO_BIN" test --format junit --output "$results_dir/${name}.xml" "$flow"; then
    passed=true
    status_label="✅ passou"
    exit_code=0
    error=""
  else
    passed=false
    status_label="❌ falhou"
    exit_code=1
    error="$(extract_junit_failure "$results_dir/${name}.xml")"
  fi
  end_ts=$(date +%s)
  duration=$((end_ts - start_ts))
  echo ">> Resultado: $status_label (${duration}s)"
  [[ -n "$error" ]] && echo ">> Motivo: $error"

  if command -v jq >/dev/null 2>&1; then
    jq -n \
      --arg flow "$name" \
      --arg desc "$desc" \
      --arg status "$status_label" \
      --argjson passed "$passed" \
      --argjson duration "$duration" \
      --arg error "$error" \
      '{flow: $flow, desc: $desc, status: $status, passed: $passed, duration: $duration, error: $error}' \
      > "$results_dir/status-${name}.json"
  fi
  return $exit_code
}

run_single_flow() {
  local flow="$1"
  require_maestro
  require_device
  resolve_maestro
  if should_skip_build; then
    echo ">> MAESTRO_SKIP_BUILD=1 — APK já instalado pelo job CI"
  else
    build_debug_apk
    install_apk
  fi
  run_maestro_test "$flow"
}

run_maestro_dir_sequential() {
  local dir="$1"
  local flow failed=0 total=0 passed=0
  local results_dir="$ROOT/build/maestro-results"
  mkdir -p "$results_dir"

  shopt -s nullglob
  local flows=("$dir"/*.yaml)
  shopt -u nullglob

  [[ ${#flows[@]} -gt 0 ]] || fail "Nenhum flow YAML em $dir"

  echo ">> Maestro ($MAESTRO_BIN): ${#flows[@]} flows em $dir (sequencial)"

  local summary_rows=()

  for flow in "${flows[@]}"; do
    total=$((total + 1))
    local name title desc junit_out start_ts end_ts elapsed status error
    name="$(basename "$flow" .yaml)"
    title="$(flow_title "$flow")"
    desc="$(flow_description "$flow")"
    junit_out="$results_dir/${name}.xml"

    echo ""
    echo "── [$total/${#flows[@]}] $title ──"
    echo "   Valida: $desc"

    start_ts=$(date +%s)
    error=""
    if "$MAESTRO_BIN" test --format junit --output "$junit_out" "$flow"; then
      passed=$((passed + 1))
      status="✅ passou"
    else
      failed=1
      status="❌ falhou"
      error="$(extract_junit_failure "$junit_out")"
      echo ">> FAILED: $flow" >&2
      echo ">> Motivo: $error" >&2
    fi
    end_ts=$(date +%s)
    elapsed=$((end_ts - start_ts))

    summary_rows+=("| $title | $desc | $status | ${elapsed}s | ${error:-—} |")
  done

  echo ""
  echo ">> Resultado: $passed/$total flows passaram"

  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    {
      echo ""
      echo "### Resultado por flow"
      echo ""
      echo "| Flow | Valida | Resultado | Duração | Motivo (se falhou) |"
      echo "|------|--------|-----------|---------|---------------------|"
      for row in "${summary_rows[@]}"; do
        echo "$row"
      done
      echo ""
      echo "**Total: $passed/$total flows passaram.**"
    } >> "$GITHUB_STEP_SUMMARY"
  fi

  [[ $failed -eq 0 ]] || exit 1
}

run_smoke() {
  require_maestro
  require_device
  if should_skip_build; then
    echo ">> MAESTRO_SKIP_BUILD=1 — APK já instalado pelo job CI"
  else
    build_debug_apk
    install_apk
  fi
  run_maestro_dir_sequential "$CI_DIR"
}

MODE="${1:---smoke}"
FLOW_PATH="${2:-}"

case "$MODE" in
  --smoke|--free)
    run_smoke
    ;;
  --flow)
    [[ -n "$FLOW_PATH" ]] || fail "Uso: bash scripts/maestro_run.sh --flow <caminho.yaml>"
    run_single_flow "$FLOW_PATH"
    ;;
  *)
    cat <<EOF
Uso: bash scripts/maestro_run.sh [--smoke | --flow <path>]

  --smoke   Build debug (main_e2e.dart) + flows em .maestro/flows/ci/
  --free    Alias de --smoke
  --flow    Um YAML isolado

Package: $PKG
Target:  $E2E_TARGET
EOF
    exit 1
    ;;
esac
