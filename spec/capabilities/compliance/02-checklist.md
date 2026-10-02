# Checklist consolidado

## Fluxo

Perfil → itens aplicáveis (`ComplianceService`) → cards com infração NR-28 quando houver → link para leitor.

## Regras

| Condição | Então |
|----------|--------|
| Item marcado | `StorageKeys.complianceItemChecked(nrId, itemNumber)` |
| Toque "ver na norma" | `ReaderNavigation.open` com `initialAnchor` |
| Monetização | Grátis com ads nas listas — sem IAP |

## Info

Sheet informativo sobre limitações do checklist — copy em `compliance_copy.dart` / `copy_voice.md`.
