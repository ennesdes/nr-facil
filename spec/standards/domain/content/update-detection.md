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
| `last_synced_hash` | Hash baixado localmente |
| `last_seen_hash` | Hash que o usuário já “viu” |
| `hasUpdate` | Remoto ≠ `last_seen_hash` |

## Regras de UX

| Condição | Então |
|----------|--------|
| Usuário abre NR com atualização pendente | Banner no leitor; **não** gravar `last_seen_hash` automaticamente |
| Usuário dispensa banner (X) ou toca "Ver o que mudou" | `markNrAsSeen` grava `last_seen_hash` |
| Abertura a partir do sino (Atualizações) | Não marcar como vista antes de navegar |

## Feed (`app_meta.json`)

- Detecção de mudança no feed usa `hash` do markdown convertido (alinhado ao app).
- `pdf_hash` na entrada do feed é auditoria/compatibilidade.
