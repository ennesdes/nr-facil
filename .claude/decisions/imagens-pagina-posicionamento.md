# Decisão — Imagens de página e tabelas ilegíveis: recorte por bbox unificado

> Gerado por `/decidir` (revisão) · Baseado em `.claude/discoveries/imagens-pagina-posicionamento.md`
> Substitui a versão anterior — o WIP que ela cobria foi commitado (`f8591ea`) por um caminho diferente (página inteira compartilhada), que reabriu o item 12b e criou duplicação equivalente em tabelas ilegíveis.

## Decisão 1 — Imagem embutida: bbox por imagem ou inserir referência da página inteira já renderizada?

### Pergunta
Hoje `_render_page_png` já gera o PNG de página inteira para páginas com imagem embutida, mas o merge nunca insere a referência `![...]`. Corrigir só isso (fix mínimo) ou retomar o recorte por bbox por imagem (decisão original, nunca implementada)?

### Opções apresentadas
- **Retomar bbox por imagem** — `page.get_image_rects(xref)` por imagem, ordenar por `y0`, 1 PNG recortado por imagem
- **Fix mínimo** — manter página inteira, só adicionar a referência no merge

### Escolha do usuário
Retomar bbox por imagem.

### Justificativa (do usuário)
Evita duplicar o texto da página inteira como imagem; arquivos menores; era a decisão original — só não chegou a ser implementada porque o trabalho de tabelas tomou a rota do helper compartilhado antes.

### Impacto esperado
- Custo: nenhum
- Esforço: baixo-médio — reintroduz a lógica de `get_image_rects` que a descoberta original já detalhava
- Risco: baixo — API padrão do PyMuPDF

---

## Decisão 2 — Tabela ilegível: recortar bbox da tabela ou manter página inteira?

### Pergunta
`f8591ea` implementou PNG de página inteira para tabela ilegível (decisão registrada em `.claude/decisions/tabelas-inline-md.md`, Decisão 2). Isso duplica o texto normativo da página inteira como imagem sempre que há 1 tabela ilegível nela. Manter como está ou recortar só a área da tabela?

### Opções apresentadas
- **Recortar bbox da tabela** — via `page.find_tables()` do pdfplumber (expõe `.bbox` por tabela), renderizado com `page.get_pixmap(clip=bbox, ...)` do fitz
- **Manter página inteira** — já implementado e commitado, sem trabalho adicional

### Escolha do usuário
Recortar bbox da tabela.

### Justificativa (do usuário)
Mesmo racional de imagens — evita repetir para o usuário, como PNG, texto normativo que ele já leu como Markdown na mesma página.

### Impacto esperado
- Custo: nenhum
- Esforço: médio — `find_tables()` e `extract_tables()` (já usado no Pass 2) podem não retornar objetos 1:1; precisa casar bbox com a tabela certa (por ordem/posição, já que ambos os métodos iteram na mesma ordem de leitura do pdfplumber)
- Risco: médio — se o casamento bbox↔tabela falhar silenciosamente, o recorte pode vir errado (ex.: bbox de outra tabela da mesma página); mitigar com fallback para página inteira nesse caso específico (log de warning)

**Esta decisão substitui** a Decisão 2 de `.claude/decisions/tabelas-inline-md.md` ("PNG da página inteira, Recomendado") — mantém a escolha de *mostrar uma imagem* como fallback de ilegibilidade, mas muda a área renderizada de página inteira para bbox da tabela.

---

## Decisão 3 — Página com tabela ilegível E imagem embutida ao mesmo tempo

### Pergunta
Hoje esse caso gera 1 único PNG de página inteira, referenciado só pela tabela — a imagem fica "escondida" dentro do mesmo PNG, sem ordem própria. Como tratar depois que ambos os casos usam bbox?

### Opções apresentadas
- **Cada uma vira seu próprio recorte bbox, na ordem Y** — como os dois casos passam a usar bbox, basta juntar as duas listas (bboxes de imagem + bbox de tabela ilegível) e ordenar por `y0` antes de renderizar/inserir
- **Decidir depois, caso a caso** — deixar como lacuna aberta

### Escolha do usuário
Cada uma vira seu próprio recorte, na ordem Y.

### Justificativa (do usuário)
O problema de duplicar o mesmo PNG de página inteira desaparece sozinho quando os dois casos usam bbox — não precisa de tratamento especial para a combinação, só de uma ordenação unificada por posição vertical antes do merge.

### Impacto esperado
- Custo: nenhum
- Esforço: baixo — é consequência natural das Decisões 1 e 2, não exige código extra além de ordenar a lista combinada
- Risco: baixo

---

## Escopo confirmado

- `_render_page_png` (página inteira) deixa de ter consumidor conhecido depois desta mudança — remover se confirmado que não sobra nenhum caller.
- Reconversão das 27 NRs já commitadas continua sendo feita via `convert_nr.py --all` local, revisando o diff antes de commitar (mesmo padrão já usado em `tabelas-inline-md`).

## Próximo passo
Escopo toca 1 arquivo (`scripts/convert_nr.py`) mas 2 funções centrais (`extract_images_pass`/`extract_tables_pass` + `merge_passes`) e reconversão de 27 NRs → `/plano imagens-pagina-posicionamento` antes de `/fazer`.
