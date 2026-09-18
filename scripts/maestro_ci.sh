#!/usr/bin/env bash
# Maestro smoke para CI (GitHub Actions + emulador já bootado).
#
# Uso:
#   bash scripts/maestro_ci.sh
#   bash scripts/maestro_ci.sh --smoke
#
# Local com emulador: bash scripts/maestro_dev.sh --no-boot
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_DIR="$ROOT/app"
E2E_TARGET="lib/main_e2e.dart"
APK_DEBUG="$APP_DIR/build/app/outputs/flutter-apk/app-debug.apk"

install_maestro() {
  if command -v maestro >/dev/null 2>&1 && maestro test --help >/dev/null 2>&1; then
    return 0
  fi
  if [[ -x "$HOME/.maestro/bin/maestro" ]] && "$HOME/.maestro/bin/maestro" test --help >/dev/null 2>&1; then
    export PATH="$HOME/.maestro/bin:$PATH"
    return 0
  fi
  echo ">> Instalando Maestro CLI..."
  curl -fsSL "https://get.maestro.mobile.dev" | bash
  export PATH="$HOME/.maestro/bin:$PATH"
}

install_maestro
export PATH="$HOME/.maestro/bin:${PATH:-}"

chmod +x "$ROOT/scripts/maestro_run.sh"

echo ">> Validar ids Maestro ↔ Dart (E2E semantics)"
python3 "$ROOT/scripts/check_e2e_semantics.py"

flutter_cmd() {
  if command -v fvm >/dev/null 2>&1 && [[ -f "$ROOT/.fvmrc" ]]; then
    fvm flutter "$@"
  else
    flutter "$@"
  fi
}

echo ">> flutter pub get"
(
  cd "$APP_DIR"
  flutter_cmd pub get
)
echo ">> Build APK debug (target=$E2E_TARGET, x86_64 — emulador CI)"
(
  cd "$APP_DIR"
  flutter_cmd build apk --debug --no-pub --target="$E2E_TARGET" --target-platform android-x64
)
echo ">> adb install -r"
adb install -r "$APK_DEBUG"

exec bash "$ROOT/scripts/maestro_run.sh" --smoke
