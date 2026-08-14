# Procedure 03 — Validar descoberta de URLs no MTE

## Objetivo

A lista de NRs, links de PDF/página e status de revogação é **gerada automaticamente** por `discover_nrs.py` (scraping da página-índice do gov.br) — não é mais mapeada à mão. Este procedure é sobre **validar manualmente**, para as primeiras NRs do MVP, que o scraper está pegando os links certos, antes de confiar nele para todas as NRs.

## Pré-requisitos

- Navegador com internet
- `discover_nrs.py` implementado (item 08 do `todo.md`) e rodado ao menos uma vez, gerando `nr_index.json`

## Importante

- **Não existe API** do MTE — o scraper depende da estrutura HTML da página-índice, que pode mudar
- Se `discover_nrs.py` não achar um link/campo esperado para uma NR, ele deve lançar erro isolado por NR (ver `docs/architecture.md`) — a NR fica sem `pdf_url`/`page_url` até alguém corrigir
- Correção de exceção pontual: adicionar override em `scripts/nr_sources.json` (ver comentário `_comment` no arquivo)

## Passo a passo

### 1. Rodar o scraper

```bash
python3 scripts/discover_nrs.py
```

Gera/atualiza `nr_index.json` na raiz do repo.

### 2. Validar as 5 NRs prioritárias do MVP

Prioridade inicial: **NR-01, NR-06, NR-10, NR-17, NR-18**

Para cada uma:

1. Abra a URL gerada em `nr_index.json` (`pdf_url` e `page_url`) no navegador
2. Confirme que `pdf_url` abre/baixa um PDF válido (não página de erro)
3. Confirme que é a versão **vigente** (não futura, não revogada)
4. Compare `page_url` com a página real da NR no gov.br

### 3. Se algo estiver errado

- Link 404 ou apontando pra NR errada → provável mudança de estrutura no site; ajustar seletor em `discover_nrs.py`, não só a URL
- Exceção pontual que não vale ajustar o scraper geral (ex. uma NR com página fora do padrão) → adicionar override em `scripts/nr_sources.json`

### 4. NRs revogadas

`nr_index.json` já marca `revogada: true` automaticamente. Confirme visualmente na página-índice do gov.br que a marcação bate (hoje: NR-2, NR-27).

## Troubleshooting

| Problema | Solução |
|----------|---------|
| `discover_nrs.py` falha pra uma NR específica | Adicionar override em `scripts/nr_sources.json`, não editar `nr_index.json` à mão (é gerado) |
| Página-índice mudou de estrutura inteira | Ajustar seletores em `discover_nrs.py`; a Action já vai ter falhado avisando isso |
| PDF abre no navegador sem URL clara | Ajustar o seletor de link no scraper para pegar o link de download, não o viewer |

## Próximo passo

→ Item 09 do [todo.md](../../todo.md) — converter NR-01, NR-06, NR-17
