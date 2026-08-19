# Descoberta — Imagens de página e tabelas ilegíveis: recorte por bbox, não página inteira

> Gerado por `/descobrir` (revisão) · Consumido por `/decidir` (já concluído nesta sessão)
> Substitui a versão anterior deste arquivo — o WIP que ela descrevia foi commitado (`f8591ea`, "ajustes tabelas"), mas tomou um caminho diferente do decidido, reabrindo o problema.

## Demanda

Depois do commit `f8591ea` (que fechou o trabalho de tabelas inline), o item 12b do `todo.md` continua aberto e surgiu um problema novo e simétrico em tabelas: tanto imagem embutida quanto tabela ilegível hoje viram PNG de **página inteira** (`_render_page_png` compartilhado), duplicando texto que o Pass 1 já extraiu. Pior: para imagem embutida, a referência `![...]` nem chega a ser inserida no `.md`. A correção é unificar os dois casos num recorte por bbox (só a área da imagem/tabela), como já tinha sido decidido para imagens antes — e nunca implementado.

## Achado crítico — o que realmente foi commitado em `f8591ea`

A descoberta anterior deste arquivo assumia que o WIP terminaria em recorte por bbox por imagem. Não foi isso que aconteceu — o trabalho de tabelas (`.claude/plans/tabelas-inline-md.md`, Fase 3) tomou uma rota mais simples: extrair `_render_page_png` como helper único e reusá-lo tanto para páginas com imagem embutida quanto para páginas com tabela ilegível, **sem** implementar o recorte por bbox de imagem que já estava decidido. Estado atual de `scripts/convert_nr.py`:

- `extract_images_pass()` (linha ~301) só identifica `pages_to_render` = união de páginas com imagem embutida (`page.get_images(full=True)`) e páginas com tabela ilegível (marcadas pelo Pass 2). Não faz mais nada com bbox de imagem individual.
- `merge_passes()` (linha ~358) renderiza PNG de página inteira via `_render_page_png` para **toda** página em `pages_to_render`, mas só insere a referência `![Tabela da página N](...)` quando a página tem um item `{"illegible_page": True}` em `tables_by_page` (linha ~401-403).
- **Consequência:** uma página que só tem imagem embutida (sem tabela ilegível) gera o PNG mas nunca referencia — a imagem é invisível no `.md`, exatamente o bug que o item 12b descreve. Confirmado no commit `8aa382d` ("Anota gap..."), feito *depois* de `f8591ea` — ou seja, o próprio time percebeu que o gap sobreviveu ao "ajustes tabelas".
- Página com tabela ilegível E imagem embutida ao mesmo tempo: hoje gera 1 único PNG de página inteira, referenciado 1 vez (pela tabela) — a imagem embutida nessa página específica fica "escondida dentro" do mesmo PNG da tabela, sem ordem própria de leitura.

## Perspectiva do usuário

Sem mudança de fundo em relação à descoberta anterior: o usuário ainda não vê imagens/diagramas de página no leitor (item 12b), e agora também herda um problema simétrico em tabelas ilegíveis — quando uma tabela ilegível existe numa página comprida, o PNG de página inteira mostra de novo, como imagem, todo o texto normativo que o usuário já leu como Markdown logo acima, o que é confuso e redundante (parece que o conteúdo "se repete").

## Perspectiva do produto

Mesmo racional da descoberta original: fidelidade de conteúdo é a proposta de valor central. Reduzir o PNG à área real da imagem/tabela também reduz tamanho de repo (já foi o ganho medido no item 23b — 300MB → 57MB só por não renderizar página sem imagem; recorte por bbox reduz ainda mais, por cortar espaço em branco/texto ao redor).

## Perspectiva técnica

| Arquivo | O que muda | Por quê | Risco |
|---------|-----------|---------|-------|
| `scripts/convert_nr.py::extract_images_pass()` | Para cada página com imagem embutida: obter bbox de cada imagem via `page.get_image_rects(xref)` (fitz), ordenar por `y0` | Retomar a decisão original, nunca implementada | baixo — API padrão do PyMuPDF |
| `scripts/convert_nr.py::extract_tables_pass()` | Quando uma tabela é marcada ilegível, capturar seu bbox via `page.find_tables()` (pdfplumber, expõe `.bbox` por tabela) em vez de só marcar `{"illegible_page": True}` | Permite recortar só a área da tabela, não a página inteira | baixo-médio — `find_tables()` e `extract_tables()` podem não retornar exatamente os mesmos objetos por tabela; precisa casar por índice/posição |
| `scripts/convert_nr.py::merge_passes()` | Para cada página, juntar bbox de imagens + bbox de tabelas ilegíveis num único fluxo, ordenar tudo por `y0`, renderizar 1 PNG por item via `page.get_pixmap(clip=bbox, matrix=...)`, inserir `![...]` no fim do texto da página, na ordem | Fecha o item 12b e resolve a duplicação de texto+PNG de página inteira nos dois casos, incluindo o caso misto (imagem + tabela ilegível na mesma página) | médio — é o coração da mudança; precisa preservar ordem de leitura quando os dois tipos coexistem na mesma página |
| `scripts/convert_nr.py::_render_page_png()` | Deixa de ser chamado para esses dois casos; pode ser removido se não sobrar nenhum consumidor de página inteira | Nenhum caso conhecido hoje precisa mais de página inteira, já que tanto imagem quanto tabela ilegível passam a usar bbox | baixo — confirmar que não há outro caller antes de remover |
| Conteúdo já commitado (27 NRs) | Reconversão via `convert_nr.py --all` (nunca editar `.md` à mão) | Aplicar o novo formato ao que já está no repo | baixo — reprocessamento determinístico, reversível via git |

## Fidelidade de conteúdo

Não altera texto normativo — só reorganiza onde a referência de imagem/tabela aparece e reduz a área renderizada em PNG nos dois casos. Sem risco de reescrita de conteúdo.

## Decisões já resolvidas com o usuário nesta sessão

| Pergunta | Opção escolhida | Por quê |
|----------|------------------|---------|
| Imagem embutida: retomar bbox por imagem ou só inserir a referência da página inteira já renderizada? | Retomar bbox por imagem | Evita duplicar texto da página inteira como imagem; arquivos menores; era a decisão original, só nunca foi implementada |
| Tabela ilegível: recortar bbox da tabela ou manter página inteira? | Recortar bbox da tabela | Mesmo racional das imagens — evita duplicar texto normativo já extraído no Pass 1 |
| Página com tabela ilegível + imagem embutida ao mesmo tempo | Cada uma vira seu próprio recorte bbox, intercalado na ordem Y | Como os dois casos passam a usar bbox, o problema de duplicar o mesmo PNG de página inteira desaparece — nenhuma exceção especial necessária |

## todo.md

- [ ] Ainda aberto — item 12b: "Imagens de página (Pass 3) nunca aparecem no leitor... só falta a referência virar `![...]` de verdade no ponto certo do texto" — **não fechado pelo commit `f8591ea`**, apesar de ter mexido no mesmo código
- Relacionado: item 23b (fechado) — só renderizar página com imagem, não todas; a mudança desta descoberta reduz ainda mais (bbox em vez de página inteira)
- Relacionado: `.claude/decisions/tabelas-inline-md.md` Decisão 2 (PNG de página inteira para tabela ilegível) — esta descoberta **substitui** essa escolha por recorte de bbox

## Lacunas ainda abertas

*(nenhuma — todas as dúvidas foram resolvidas com o usuário nesta sessão)*
