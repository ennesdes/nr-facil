# Dataset `compliance.json`

> **SSOT:** ciclo de vida do asset em `app/assets/compliance/compliance.json`.

## Diferença do conteúdo normativo

| | NRs (`content/`) | Checklist |
|--|------------------|-----------|
| Origem | Pipeline Python + GitHub | Curadoria humana (IA assiste) |
| Atualização | Action diária | Nova versão do app na loja |
| Sync GitHub raw | Sim | **Não** |

## Schema (conceitual)

- `segments`: `{ id, label, nr_ids_base }`
- `risk_factors`: `{ id, label }`
- `items`: regras de match, textos, NR-28, anchors
- `atualizado_em`: exibido como disclaimer na UI

## Regras

| Condição | Então |
|----------|--------|
| Novo fator de risco | Adicionar em JSON — formulário renderiza da lista, sem enum fixo no Dart |
| Expansão de cobertura | Incremental; documentar em `docs/compliance-checklist-cobertura.md` |
