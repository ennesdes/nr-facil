#!/usr/bin/env bash
# Copia PNGs do último run Maestro (fluxo design) para design/
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUN_DIR="${1:-}"
if [[ -z "$RUN_DIR" ]]; then
  RUN_DIR="$(ls -td "$HOME/.maestro/tests"/*/compliance_checklist 2>/dev/null | head -1 || true)"
fi
if [[ -z "$RUN_DIR" || ! -d "$RUN_DIR" ]]; then
  echo "Nenhum run Maestro encontrado. Rode: maestro test .maestro/flows/design/compliance_checklist.yaml"
  exit 1
fi

SHOT_DIR="$RUN_DIR/takeScreenshot"
if [[ ! -d "$SHOT_DIR" ]]; then
  SHOT_DIR="$RUN_DIR"
fi

copy_one() {
  local src_name="$1"
  local dest_rel="$2"
  if [[ -f "$SHOT_DIR/$src_name" ]]; then
    local dest="$ROOT/design/$dest_rel"
    mkdir -p "$(dirname "$dest")"
    cp "$SHOT_DIR/$src_name" "$dest"
    echo "→ $dest_rel"
  else
    echo "AVISO: ausente — $src_name" >&2
  fi
}

copy_one design-home-normas-01-lista.png home/normas/01-lista-normas.png
copy_one design-checklist-01-perfil-onboarding.png compliance/checklist/01-perfil-onboarding.png
copy_one design-checklist-01b-perfil-preenchido.png compliance/checklist/01b-perfil-preenchido.png
copy_one design-checklist-02-overview.png compliance/checklist/02-checklist-overview.png
copy_one design-checklist-03-nr05-cipa.png compliance/checklist/03-checklist-nr05-cipa.png
copy_one design-checklist-04-nr12-industria.png compliance/checklist/04-checklist-nr12-industria.png
copy_one design-checklist-05-erro-perfil.png compliance/checklist/05-erro-perfil-ausente.png

echo "Sincronizado a partir de $RUN_DIR"
