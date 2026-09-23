#!/usr/bin/env bash
# Salva PNG do emulador Android em design/<feature>/...
# Uso: ./scripts/capture_design_screenshots.sh <caminho-relativo-design> [device-serial]
# Ex.: ./scripts/capture_design_screenshots.sh compliance/checklist/02-checklist-overview.png

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REL="${1:?informe o caminho relativo em design/, ex: compliance/checklist/01-perfil.png}"
DEVICE="${2:-emulator-5554}"
OUT="$ROOT/design/$REL"
mkdir -p "$(dirname "$OUT")"
adb -s "$DEVICE" exec-out screencap -p > "$OUT"
echo "Salvo: $OUT ($(wc -c < "$OUT") bytes)"
