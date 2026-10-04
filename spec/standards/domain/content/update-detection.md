# Detecção de atualização

> **SSOT:** critérios de hash no pipeline vs no app.

## Pipeline (`update_nrs.py` / `convert_nr.py`)

| Gatilho | Uso |
|---------|-----|
| `pdf_hash` (SHA-256 do PDF) | Decidir se reprocessa extração do PDF |
| Metadados HTML (`scrape_vigencia.py`) | Enriquecer `meta.json` / manifest — **não** substituem `pdf_hash` como gatilho de texto |

## App (`ContentService`)

| Chave | Significado |
|-------|-------------|
| `last_synced_hash` / `nrCoreSyncedHash` | Conteúdo baixado no aparelho |
| `last_seen_hash` (`nrLastSeenHash`) | Hash que o usuário já **revisou** (viu o diff) |
| `hasUpdate` | Hash remoto no manifest ≠ `last_seen_hash` |

API canônica na UI: `acknowledgeNrUpdate(nrId, reason)` — grava `last_seen_hash` e analytics `acknowledge_update`.

## Regras de UX

| Condição | Então |
|----------|--------|
| Usuário abre o leitor sem ver o diff | **Não** chamar `acknowledgeNrUpdate` — badge permanece |
| Usuário abre bottom sheet “O que mudou” | `acknowledgeNrUpdate` com `sheetView` |
| Usuário toca item alterado na lista de mudanças | `acknowledgeNrUpdate` com `itemTap` + navega ao trecho |
| Só há `summary` (sem `items`) | Botão “Marcar como revisada” → `summaryButton` |
| Usuário fecha banner no leitor (X) | `bannerDismiss` |
| Card da home: “Ocultar aviso” | Só dispensa o card (`pendingUpdatesCardDismissedSnapshot`) — **não** revisa |

## Feed (`app_meta.json`)

- Detecção de mudança no feed usa `hash` do markdown convertido (alinhado ao app).
- `pdf_hash` na entrada do feed é auditoria/compatibilidade.
