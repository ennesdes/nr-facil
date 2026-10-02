# Manifest e meta por NR

> **SSOT:** estrutura de `manifest.json` (raiz) e `content/<nr-id>/meta.json`.

## manifest.json

- Gerado por `scripts/build_manifest.py`; validado por `scripts/validate_manifest.py`.
- Campos por NR (exemplo): `id`, `title`, `version`, `hash` (MD convertido), `pdf_hash`, `updated_at`, `portaria`, `publicado_em`, `vigente_desde`, `url`, `reviewed`, `revogada` quando aplicável.

## Por NR (`content/nr-XX/`)

| Arquivo | Uso |
|---------|-----|
| `nr-XX.md` | Texto normativo estruturado |
| `nr-XX.pdf` | PDF original + auditoria |
| `index.json` | Índice lateral do leitor |
| `search_index.json` | Chunks de busca (NRs vigentes) |
| `meta.json` | Metadados locais; `scrape_vigencia.py` mescla sem apagar `pdf_hash` |

## Regras

| Condição | Então |
|----------|--------|
| NR revogada no `nr_index.json` | Não entra em `search_index.json`; app lista com badge na aba Normas |
| `pdf_hash` mudou no pipeline | Reprocessar passes de conversão |
| Hash MD mudou | Nova entrada em `app_meta.json` (feed) |
