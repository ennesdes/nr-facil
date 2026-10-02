# Conversão — 3 passes

Ver [`../../standards/domain/content/normative-fidelity.md`](../../standards/domain/content/normative-fidelity.md).

## Passes (sempre os três)

1. Texto — `pymupdf4llm`
2. Tabelas — `pdfplumber` (+ PNG bbox se ilegível)
3. Imagens — bboxes embutidas → PNG recortado (não página inteira sem imagem)

Merge → `nr-XX.md` + `index.json` + `search_index.json` + `quality_report.json`.

## Gatilho

`convert_nr.py` roda quando `pdf_hash` mudou (`update_nrs.py`).
