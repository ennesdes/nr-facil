#!/usr/bin/env bash
# Captura telas do fluxo Checklist → design/compliance/checklist/
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEVICE="${1:-emulator-5554}"
APP_DIR="$ROOT/app"
DESIGN="$ROOT/design"
TAB_CHECKLIST_X=947
TAB_Y=2310

shot() {
  local rel="$1"
  mkdir -p "$(dirname "$DESIGN/$rel")"
  adb -s "$DEVICE" shell am force-stop com.android.chrome >/dev/null 2>&1 || true
  sleep 0.2
  (cd "$APP_DIR" && fvm flutter screenshot -d "$DEVICE" -o "$DESIGN/$rel")
}

tap() { adb -s "$DEVICE" shell input tap "$1" "$2"; }

open_checklist_tab() {
  tap "$TAB_CHECKLIST_X" "$TAB_Y"
  sleep 1.5
}

# --- Home Normas ---
shot home/normas/01-lista-normas.png

# --- Perfil (sem dados) ---
"$ROOT/scripts/seed_compliance_storage.sh" clear "$DEVICE" >/dev/null
open_checklist_tab
sleep 0.8
shot compliance/checklist/01-perfil-onboarding.png
adb -s "$DEVICE" shell input keyevent 4
sleep 0.8

# --- Checklist Comércio / NR-05 ---
"$ROOT/scripts/seed_compliance_storage.sh" comercio "$DEVICE" >/dev/null
open_checklist_tab
shot compliance/checklist/02-checklist-overview.png
for _ in 1 2 3; do
  adb -s "$DEVICE" shell input swipe 540 1700 540 600 500
  sleep 0.5
done
shot compliance/checklist/03-checklist-nr05-cipa.png

# --- Checklist Indústria / NR-12 ---
"$ROOT/scripts/seed_compliance_storage.sh" industria "$DEVICE" >/dev/null
open_checklist_tab
for _ in 1 2 3 4; do
  adb -s "$DEVICE" shell input swipe 540 1700 540 600 500
  sleep 0.5
done
shot compliance/checklist/04-checklist-nr12-industria.png

# --- Erro: perfil removido com aba Checklist já aberta ---
NO_RESTART=1 "$ROOT/scripts/seed_compliance_storage.sh" clear "$DEVICE" >/dev/null
tap 980 263
sleep 1
shot compliance/checklist/05-erro-perfil-ausente.png

echo "OK — prints em $DESIGN/compliance/checklist/"
