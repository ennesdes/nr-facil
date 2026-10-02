# Leitor — experiência principal

> **SSOT:** `NrReaderPage` e corpo Markdown.

## Escopo

Leitura offline do `.md` convertido; não substitui o PDF oficial.

## Regras

| Condição | Então |
|----------|--------|
| Render | `flutter_markdown` + tipografia customizada (`reader_typography`) |
| Rodapé | Link PDF MTE + aviso legal fixo |
| Fonte | Controle de tamanho; tema global em Ajustes |
| NR revogada | Não usa este leitor — ver `RevokedNrPage` |

## Pode / Não pode

| Pode | Não pode |
|------|----------|
| Estrutura hierárquica do `index.json` | Anúncios no leitor |
| Fallback Markdown se bloco estruturado falhar | Editar texto normativo |
