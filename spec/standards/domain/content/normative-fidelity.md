# Fidelidade normativa

> **SSOT:** princípios legais e de pipeline — nunca alterar texto normativo.

## Princípio

> Nunca reescrever o conteúdo normativo. Só extrair, estruturar e exibir melhor.

## Pipeline

- 3 passes uniformes (texto, tabelas, imagens) + merge em um `.md`.
- PDF original salvo com `pdf_hash` por NR.
- `quality_report.json` por NR: `char_ratio`, `warnings[]`, fallbacks PNG.

## App

- Link fixo "Ver PDF original no MTE".
- Disclaimer visível (texto em `copy_voice.md` / footer do leitor).
- Não usar brasão ou logotipos oficiais do MTE/gov.br.

## Base legal (resumo)

Textos de atos oficiais: Lei 9.610/98, art. 8º, IV. O app **suplementa**, não substitui, publicações oficiais.
