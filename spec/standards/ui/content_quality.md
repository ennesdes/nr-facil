# Qualidade de conteúdo na UI — NR Fácil

> Escolha entre texto, ícone e imagem. Copy: `copy_voice.md`.

## Quando usar cada meio

| Meio | Usar quando |
|------|-------------|
| **Texto** | Norma, infração, instrução legal, erro |
| **Ícone** | Ação universal (busca, favorito, download, sino) |
| **Imagem** | Diagrama da NR (asset do pipeline), não decoração |

## Leitor

- Texto normativo vem do Markdown — não resumir nem alterar no app
- PNG de tabela/diagrama: alt text descritivo quando possível
- Link PDF MTE sempre disponível

## Listas

- Título da NR + metadados (portaria, revogada, atualização)
- Badge de atualização só quando `hasUpdate`

## Checklist

- Código/gradação NR-28 visíveis quando o item tiver
- Disclaimer `atualizado_em` sempre visível na tela do checklist

## Animação

- Curta (< 300ms) para feedback (snackbar, toggle)
- Sem animação que atrase leitura no leitor
