#!/usr/bin/env bash
# Valida secrets obrigatórios do deploy — falha cedo, antes de setup/build.
# Nunca imprime valores; só nomes ausentes.
set -uo pipefail

missing=""

[[ -z "${PLAY_SERVICE_ACCOUNT_JSON:-}" ]] && missing="${missing} PLAY_SERVICE_ACCOUNT_JSON"
[[ -z "${ANDROID_KEYSTORE_BASE64:-}" ]] && missing="${missing} ANDROID_KEYSTORE_BASE64"
[[ -z "${KEYSTORE_PASSWORD:-}" ]] && missing="${missing} KEYSTORE_PASSWORD"
[[ -z "${KEY_ALIAS:-}" ]] && missing="${missing} KEY_ALIAS"
[[ -z "${KEY_PASSWORD:-}" ]] && missing="${missing} KEY_PASSWORD"
[[ -z "${ADMOB_APP_ID:-}" ]] && missing="${missing} ADMOB_APP_ID"
[[ -z "${ADMOB_BANNER_UNIT_ID:-}" ]] && missing="${missing} ADMOB_BANNER_UNIT_ID"
[[ -z "${ADMOB_INTERSTITIAL_UNIT_ID:-}" ]] && missing="${missing} ADMOB_INTERSTITIAL_UNIT_ID"

if [[ -n "${missing}" ]]; then
  echo "Missing required secret(s):${missing}"
  exit 1
fi

echo "All required secrets present."
