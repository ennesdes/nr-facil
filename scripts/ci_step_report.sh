#!/usr/bin/env bash
# Wrapper para steps do CI: cronometra, reporta sucesso/falha no Job Summary.
# Uso: ci_step_report.sh "Nome da etapa" comando [args...]
set -uo pipefail

if [[ $# -lt 2 ]]; then
  echo "Uso: ci_step_report.sh \"Nome da etapa\" comando [args...]" >&2
  exit 2
fi

STEP_NAME="$1"
shift

SUMMARY_FILE="${GITHUB_STEP_SUMMARY:-/dev/null}"
START_EPOCH="$(date +%s)"

echo "▶ ${STEP_NAME}…"

OUTPUT_FILE="$(mktemp)"
trap 'rm -f "$OUTPUT_FILE"' EXIT

set +e
"$@" >"$OUTPUT_FILE" 2>&1
EXIT_CODE=$?
set -e

END_EPOCH="$(date +%s)"
DURATION="$((END_EPOCH - START_EPOCH))"

cat "$OUTPUT_FILE"

if [[ "$EXIT_CODE" -eq 0 ]]; then
  {
    echo "✅ ${STEP_NAME} — ${DURATION}s"
    echo ""
  } >>"$SUMMARY_FILE"
  exit 0
fi

ERROR_SNIPPET="$(grep -E \
  'error •|warning •|FAILED|Expected:|Actual:|Exception|Error:|fatal:|Missing secret|Missing required secret|not found|FAILURE:' \
  "$OUTPUT_FILE" 2>/dev/null | head -30 || true)"

if [[ -z "$ERROR_SNIPPET" ]]; then
  ERROR_SNIPPET="$(tail -30 "$OUTPUT_FILE")"
fi

if [[ "$EXIT_CODE" -gt 128 ]]; then
  SIGNAL_NUM="$((EXIT_CODE - 128))"
  ERROR_SNIPPET="Processo finalizado pelo sistema operacional (sinal ${SIGNAL_NUM}), não pelo comando — provável falta de memória (OOM) no runner.

Saída antes de ser morto:
${ERROR_SNIPPET}"
fi

CMD_STR="$*"

{
  echo "## ❌ ${STEP_NAME}"
  echo ""
  echo "- **O quê:** ${STEP_NAME}"
  echo "- **Onde:** \`${CMD_STR}\`"
  echo "- **Duração até falha:** ${DURATION}s"
  echo "- **Por quê:**"
  echo '```'
  echo "$ERROR_SNIPPET"
  echo '```'
  echo ""
} >>"$SUMMARY_FILE"

exit "$EXIT_CODE"
