# Motor de match do checklist

> **SSOT:** regra aditiva OR em `ComplianceService.getApplicableItems`.

## Entrada

- `segmentoId` do `CompanyProfile`
- `riskFactors` selecionados no perfil

## Regra

Item entra no checklist se:

1. `nr_id` do item ∈ `nr_ids_base` do segmento em `compliance.json`, **ou**
2. `risk_factors` do item ∩ perfil ≠ ∅

Deduplicação por par (`nrId`, `itemNumber`).

## Infração NR-28

Itens podem carregar código, gradação I1–I4 e tipo S/M — exibidos no card; deep-link para o leitor via `ReaderNavigation.open` com `initialAnchor`.

## v1

Perfil único por instalação (`CompanyProfile.id` fixo); estrutura preparada para múltiplos perfis depois.
