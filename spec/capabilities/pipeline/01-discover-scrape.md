# Discover e scraping

## Scripts

- `discover_nrs.py` → `nr_index.json` (`pdf_url`, `page_url`, `revogada`, `substitui_por`)
- `scrape_vigencia.py` → metadados HTML mesclados em `meta.json`
- Overrides pontuais: `scripts/nr_sources.json`

## Regras

| Condição | Então |
|----------|--------|
| Layout gov.br mudou (campo obrigatório) | Exceção — falha isolada por NR ou job inteiro se índice geral |
| `pdf_hash` | Sempre do PDF baixado — nunca inferido do site |
