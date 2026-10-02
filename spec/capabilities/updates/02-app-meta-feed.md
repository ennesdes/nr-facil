# app_meta.json

> **SSOT:** leitura no startup e alimentação da UI de updates.

## Campos

| Campo | Uso |
|-------|-----|
| `min_app_version` | Força update obrigatório (`ForcedUpdateDialog`) |
| `updates[]` | Janela rolante (últimas 200 entradas) |

## Entrada típica

`nr_id`, `title`, `portaria`, `hash`, `pdf_hash`, `summary`, `items[]` (`tipo`: novo | removido | alterado), `created_at`.

## Regras

| Condição | Então |
|----------|--------|
| `items` vazio | UI usa `summary` |
| Entrada legada sem `items` | Parser trata como lista vazia |
| Escrita | Somente GitHub Action — app só lê via raw HTTP |

Gerado por `scripts/build_app_meta.py`.
