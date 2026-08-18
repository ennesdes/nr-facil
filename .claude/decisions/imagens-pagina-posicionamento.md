# Decisão — Imagens de página: posição correta no texto + recorte por bbox

> Gerado por `/decidir` · Baseado em `.claude/discoveries/imagens-pagina-posicionamento.md`

## Decisão 1 — WIP não commitado em `convert_nr.py`

### Pergunta
Existem alterações não commitadas que já reestruturam as 3 passes para serem "page-aware" mas quebram a execução (orquestrador não atualizado). Continuar esse WIP ou descartar e redesenhar do zero?

### Opções apresentadas
- Continuar o WIP — completar o que já está escrito (per-page text, tables_by_page, pages_to_render)
- Descartar e redesenhar do zero

### Escolha do usuário
Continuar o WIP.

### Impacto esperado
- Custo: menor — reaproveita estrutura já escrita
- Esforço: corrigir `convert_nr()` + implementar crop por bbox + reescrever `merge_passes()`
- Risco: baixo, é conclusão de um refactor já em andamento

---

## Decisão 2 — Posição da imagem no texto da página

### Pergunta
Onde inserir a referência `![...]` dentro do texto da página no Markdown final?

### Opções apresentadas
- **Fim do bloco de texto da página** — simples e robusto, ordem de páginas sempre correta
- **Posição exata via coordenada Y** — mais fiel visualmente, mas `pymupdf4llm` não expõe posição de linha de forma confiável; risco de inserir no lugar errado ou quebrar Markdown (ex.: dentro de uma tabela)

### Escolha do usuário
Fim do bloco de texto da página.

### Justificativa (do usuário)
Prioriza robustez/ausência de falhas sobre precisão visual milimétrica — consistente com a preocupação original do usuário ("pensar na melhor maneira para evitar falhas").

### Impacto esperado
- Custo: nenhum
- Esforço: baixo (concatenação por página, sem heurística de matching de posição)
- Risco: baixo — pior caso é a imagem aparecer no fim da página em vez de no meio do parágrafo exato, nunca fora de ordem entre páginas

---

## Decisão 3 — Múltiplas imagens na mesma página

### Pergunta
Quando uma página tem mais de uma imagem embutida, como organizá-las no Markdown?

### Opções apresentadas
- **Um PNG por imagem, em ordem Y** (bbox individual de cada imagem via `page.get_image_rects(xref)`)
- **Um PNG único da união das áreas** (bbox que engloba todas as imagens da página)

### Escolha do usuário
Um PNG por imagem, em ordem Y.

### Impacto esperado
- Custo: mais arquivos pequenos em vez de menos arquivos grandes (tende a ser menor no total, já que corta espaço em branco entre figuras)
- Esforço: ordenar rects por `y0` antes de renderizar
- Risco: baixo — API padrão do PyMuPDF (`get_image_rects` + `get_pixmap(clip=...)`)

---

## Escopo confirmado (fora desta decisão)
Páginas com **tabela ilegível** (sem imagem embutida) continuam usando `_render_page_png` (página inteira) — é o fallback de 3 níveis já documentado em `docs/architecture.md`; recorte de bbox de tabela é um problema separado, não tratado aqui.

## Próximo passo
Escopo cabe em 1 arquivo (`scripts/convert_nr.py`), 1 feature → pular `/plano` e ir direto para `/fazer imagens-pagina-posicionamento`.
