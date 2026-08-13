#!/usr/bin/env bash
# Setup inicial do projeto NR Fácil
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Verificando FVM..."
if ! command -v fvm &>/dev/null; then
  echo "FVM não encontrado. Rode: dart pub global activate fvm"
  exit 1
fi

echo "==> Instalando Flutter via FVM..."
fvm install
fvm use

echo "==> Flutter doctor..."
fvm flutter doctor

if [ -f "app/pubspec.yaml" ]; then
  echo "==> Flutter pub get..."
  cd app
  fvm flutter pub get
  cd "$ROOT"
else
  echo "⚠ app/ ainda não existe — pule pub get até criar o projeto Flutter (todo item 03)"
fi

echo "==> Python venv (opcional)..."
if command -v python3 &>/dev/null; then
  if [ ! -d ".venv" ]; then
    python3 -m venv .venv
  fi
  # shellcheck disable=SC1091
  source .venv/bin/activate
  if [ -f "scripts/requirements.txt" ]; then
    pip install -q -r scripts/requirements.txt
  fi
  echo "venv ativo: source .venv/bin/activate"
fi

echo ""
echo "✓ Setup concluído. Próximo: marque item 01 no todo.md"
