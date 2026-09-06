#!/usr/bin/env bash
# Importa branding a partir de branding-input/ (sem acessar ~/Downloads).
set -euo pipefail

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Erro: não rode este script com sudo." >&2
  echo "O Flutter recusa rodar como root e app/ios/ ficará com permissões erradas." >&2
  echo "Use: ./scripts/import_branding.sh" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INPUT="$ROOT/branding-input"

mkdir -p "$INPUT"

find_logo() {
  local candidate
  for candidate in \
    "$INPUT/logo.png" \
    "$INPUT"/ChatGPT\ Image*.png \
    "$INPUT"/ChatGPT\ Image*.jpg; do
    [[ -f "$candidate" ]] || continue
    printf '%s' "$candidate"
    return 0
  done
  return 1
}

find_icons() {
  find "$INPUT" -maxdepth 1 -type d -name 'easyappicon-icons-*' 2>/dev/null | head -1
}

if ! LOGO=$(find_logo); then
  cat >&2 <<EOF
Erro: logo não encontrada em branding-input/

O Terminal não consegue ler ~/Downloads no macOS (Operation not permitted).
Use o Finder:

  1. Abra ~/Downloads
  2. Arraste "ChatGPT Image 5 de set. de 2026, 20_37_00.png" para:
     $INPUT/logo.png
  3. Arraste a pasta easyappicon-icons-1788651440281 para:
     $INPUT/

Depois rode de novo: ./scripts/import_branding.sh
EOF
  exit 1
fi

ICON_SRC=$(find_icons || true)
if [[ -z "$ICON_SRC" ]]; then
  cat >&2 <<EOF
Erro: pasta easyappicon-icons-* não encontrada em branding-input/

Arraste a pasta easyappicon-icons-1788651440281 do Downloads para:
  $INPUT/

Depois rode de novo: ./scripts/import_branding.sh
EOF
  exit 1
fi

# Normaliza o nome da logo para logo.png (sem tocar no Downloads).
if [[ "$LOGO" != "$INPUT/logo.png" ]]; then
  cp "$LOGO" "$INPUT/logo.png"
fi

echo "Logo: $INPUT/logo.png"
echo "EasyAppIcon: $(basename "$ICON_SRC")"

source "$ROOT/.venv/bin/activate"
python3 "$ROOT/scripts/import_branding.py"
