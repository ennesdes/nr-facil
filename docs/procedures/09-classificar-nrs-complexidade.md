# Procedure 09 — Classificar NRs por complexidade

## Objetivo

Auditar cada NR antes da conversão em massa — evitar surpresas com tabelas e diagramas.

## Pré-requisitos

- PDFs abertos no navegador (links do procedure 03)
- Planilha ou arquivo de notas

## Classes

| Classe | Descrição | Exemplos | Pipeline |
|--------|-----------|----------|----------|
| **A** | Só texto | NR-3, NR-5, NR-28 | pymupdf4llm nível 1 |
| **B** | Tabelas simples | NR-6, NR-10 | Nível 1 + amostra manual |
| **C** | Tabelas + anexos | NR-12, NR-17, NR-18 | Níveis 1+2, revisão manual |
| **D** | Diagramas/fluxos | Anexos NR-33 | Nível 3 (PNG de página) |

## Passo a passo

### 1. Para cada NR do MVP

1. Abra o PDF oficial
2. Folheie rapidamente (2–3 min)
3. Anote:
   - Tem tabelas? Quantas páginas?
   - Tem imagens/diagramas?
   - Anexos extensos?

### 2. Classifique A/B/C/D

Registre em `scripts/nr_sources.json` (campo opcional):

```json
"nr-06": {
  "title": "EPI",
  "pdf_url": "...",
  "complexity": "B",
  "revogada": false
}
```

### 3. Ordem de conversão no MVP

**Fase 1 — converter primeiro (A/B):**

1. NR-01 (B)
2. NR-06 (B)
3. NR-17 (B/C)
4. NR-10 (B)
5. NR-18 (C) — deixar para depois se necessário

### 4. NRs revogadas

NR-2, NR-27: marque `revogada: true`, não converta.

### 5. Registrar warnings esperados

Para classe C/D, anote páginas problemáticas — ajuda na revisão manual.

## Critério de revisão manual

Após conversão, revise **só** NRs com:

- `quality_report.json` com warnings
- Classe C ou D
- Primeiras 5 NRs do lançamento (obrigatório)

## Próximo passo

→ Item 09 do [todo.md](../../todo.md) — converter NR-01, NR-06, NR-17
