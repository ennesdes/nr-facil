#!/usr/bin/env bash
# Injeta perfil de empresa no GetStorage do app (emulador/debug).
# Uso: ./scripts/seed_compliance_storage.sh [comercio|industria|clear] [device]
set -euo pipefail
PRESET="${1:-comercio}"
DEVICE="${2:-emulator-5554}"
PKG=br.com.solvebetter.nrfacil
TMP="$(mktemp -d)"
GS="$TMP/GetStorage.gs"

adb -s "$DEVICE" shell run-as "$PKG" cat app_flutter/GetStorage.gs > "$GS"

python3 - "$PRESET" "$GS" <<'PY'
import json, sys
preset, path = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as f:
    data = json.load(f)

key = "nr_facil_company_profile"
if preset == "clear":
    data.pop(key, None)
else:
    if preset == "comercio":
        data[key] = {
            "id": "default",
            "porte": "11 a 50 funcionários",
            "segmento_id": "comercio",
            "risk_factors": ["empregados_clt", "possui_cipa"],
        }
    elif preset == "industria":
        data[key] = {
            "id": "default",
            "porte": "11 a 50 funcionários",
            "segmento_id": "industria",
            "risk_factors": ["possui_maquinas"],
        }
    else:
        raise SystemExit(f"preset desconhecido: {preset}")

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
PY

adb -s "$DEVICE" push "$GS" /data/local/tmp/GetStorage.gs
adb -s "$DEVICE" shell run-as "$PKG" cp /data/local/tmp/GetStorage.gs app_flutter/GetStorage.gs
adb -s "$DEVICE" shell run-as "$PKG" cp app_flutter/GetStorage.gs app_flutter/GetStorage.bak
rm -rf "$TMP"

if [[ "${NO_RESTART:-}" != "1" ]]; then
  adb -s "$DEVICE" shell am force-stop "$PKG"
  adb -s "$DEVICE" shell am start -n "$PKG/.MainActivity"
  sleep 2
fi
