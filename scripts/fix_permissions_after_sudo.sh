#!/usr/bin/env bash
# Repara permissões quebradas após rodar flutter/import com sudo.
set -euo pipefail

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Erro: não rode este script com sudo." >&2
  echo "Use: ./scripts/fix_permissions_after_sudo.sh" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/app"
USER="$(whoami)"

echo "==> Corrigindo dono e permissões (senha do macOS uma vez)…"
sudo chown -R "$USER:staff" "$HOME/.pub-cache" "$APP"
sudo chmod -R u+rwX "$HOME/.pub-cache" "$APP"
chmod +x "$APP/android/gradlew" 2>/dev/null || true

echo "==> Limpando build cache do Flutter…"
cd "$APP"
fvm flutter clean

echo "==> Reparando pub cache…"
fvm flutter pub cache repair

echo "==> Resolvendo dependências…"
fvm flutter pub get

echo ""
echo "✓ Pronto. Rode: cd app && fvm flutter run"
