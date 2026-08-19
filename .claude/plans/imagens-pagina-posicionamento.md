# Plano — Recorte por bbox unificado (imagens embutidas + tabelas ilegíveis)

> **Descoberta:** `.claude/discoveries/imagens-pagina-posicionamento.md`
> **Decisão:** `.claude/decisions/imagens-pagina-posicionamento.md`
> Substitui o plano anterior — o WIP que ele cobria foi commitado (`f8591ea`) por uma rota diferente (página inteira compartilhada via `_render_page_png`), que deixou o item 12b aberto e criou duplicação equivalente em tabelas ilegíveis.

## O que será feito e por quê

- **Imagem embutida: recortar 1 PNG por bbox** (`page.get_image_rects(xref)`), não mais página inteira — corrige o item 12b (referência nunca inserida hoje) e evita duplicar texto já extraído no Pass 1.
- **Tabela ilegível: recortar 1 PNG por bbox da tabela** (`page.find_tables()` do pdfplumber), não mais página inteira — substitui a Decisão 2 de `tabelas-inline-md` (página inteira), pelo mesmo motivo.
- **Unificar a inserção no merge**: para cada página, juntar bboxes de imagem + bbox de tabela ilegível numa única lista ordenada por `y0`, renderizar cada um como PNG próprio, inserir `![...]` no fim do texto da página, na ordem certa — resolve o caso misto (imagem + tabela ilegível na mesma página) sem tratamento especial.
- **Remover `_render_page_png`** (página inteira) se, depois da mudança, não sobrar nenhum caller.
- **Reconverter as 27 NRs já commitadas** com o novo pipeline, revisando o diff antes de commitar.

## Escopo

- `scripts/convert_nr.py`: `extract_images_pass`, `extract_tables_pass`, `merge_passes`, `convert_nr` (orquestração), possível remoção de `_render_page_png`
- `scripts/test_convert_nr.py`: testes para recorte por bbox (imagem e tabela) e merge com ordenação combinada
- Reconversão de `content/*/nr-*.md` e `content/*/assets/pages/` (27 NRs, via script)
- `docs/architecture.md` § Pipeline de conteúdo: atualizar a linha sobre fallback de tabela ilegível (página inteira → bbox da tabela)

## Fora de escopo

- Não alterar o app Flutter/leitor (`photo_view` já suporta imagem local + zoom)
- Não mudar `manifest.json`/`app_meta.json`
- Não tentar posicionamento por coordenada Y dentro do parágrafo de texto (decidido antes, mantido: referência sempre no fim do bloco de texto da página)
- Não mudar a lógica do Pass 2 além de expor o bbox da tabela ilegível (filtro de 1 coluna, heurística de ilegibilidade e dedupe de Markdown continuam como estão)

## Impacto estimado

### App Flutter
- Nenhum

### Pipeline Python
- 1 script (`scripts/convert_nr.py`)

### app_meta.json / manifest
- Nenhum

### Testes
- ~7–8 cenários novos: bbox único de imagem, múltiplas imagens ordenadas, bbox de tabela ilegível, página com imagem + tabela ilegível juntas (ordem combinada), página sem imagem nem tabela ilegível, `get_image_rects` vazio, `find_tables()` não achar bbox correspondente (fallback)

## Referências

| Arquivo | Seções utilizadas |
|---------|-------------------|
| `docs/architecture.md` | Pipeline de conteúdo — fallback de 3 níveis (texto/tabelas/imagens) |
| `todo.md` | Item 12b (ainda aberto) e 23b (fechado) |
| `.claude/decisions/tabelas-inline-md.md` | Decisão 2, substituída por esta |
| `CLAUDE.md` | "nunca rewrite normative text — só extrair, estruturar e exibir melhor" |

## Decisões tomadas

| Decisão | Escolha | Fundamento |
|---------|---------|------------|
| Imagem embutida | Recorte por bbox por imagem, ordenado por Y | Escolha do usuário — evita duplicar texto de página inteira; era a decisão original nunca implementada |
| Tabela ilegível | Recorte por bbox da tabela (`find_tables().bbox`) | Escolha do usuário — mesmo racional; substitui a página inteira decidida antes em `tabelas-inline-md` |
| Página com os dois casos juntos | Cada um vira seu próprio recorte, intercalado por Y | Escolha do usuário — consequência natural de unificar em bbox, sem tratamento especial |

## Decisões abertas

*(nenhuma — plano pronto para /fazer)*

## Riscos

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| `find_tables()` (pdfplumber) não retorna as tabelas na mesma ordem/quantidade que `extract_tables()` (já usado no Pass 2 para o conteúdo da tabela) | Alto (bbox errado associado à tabela errada) | Casar por índice de iteração (mesma chamada `page.find_tables()` expõe `.extract()` por objeto — usar o objeto único em vez de chamar `extract_tables()` e `find_tables()` separadamente, se a API permitir); se não bater, fallback para página inteira só nessa tabela específica + log de warning |
| `get_image_rects(xref)` retorna lista vazia para alguma imagem | Baixo | Pular essa imagem (log debug), sem quebrar a passe inteira |
| Página com imagem decorativa embutida (logo/timbre repetido) gera PNG desnecessário | Médio (poluição visual) | Fora do escopo — comportamento herdado, não piora com bbox (na verdade melhora: PNG passa a ser só a logo, não a página inteira) |
| Remoção de `_render_page_png` quebra algum caller não previsto | Baixo | Grep por `_render_page_png` antes de remover; só remover se zero callers restantes |
| Reconversão das 27 NRs gera diff grande difícil de revisar | Médio | Revisar por amostragem (NR-03 — já tem o caso real da TABELA 3.4 rotacionada — e NR-04, com mais tabelas) + `git diff --stat` para o resto |

## Dependências entre fases

- Fase 2 depende de Fase 1 — merge unificado só faz sentido depois que os dois passes já produzem listas de bbox
- Fase 3 depende de Fase 1 e Fase 2

---

## Detalhamento

### Fase 1 — Bbox por imagem e por tabela ilegível (sem merge ainda)
**Objetivo:** `extract_images_pass` retorna bboxes de imagem por página; `extract_tables_pass` retorna bbox da tabela ilegível por página (em vez de só marcar `{"illegible_page": True}`).
**Arquivos:** `scripts/convert_nr.py` (`extract_images_pass`, `extract_tables_pass`)
**Agente sugerido:** `python-pipeline`
**Depende de:** nenhuma

#### Passos
1. `extract_images_pass`: para cada página com imagem embutida (`page.get_images(full=True)`), para cada `xref`: `rects = page.get_image_rects(xref)`; se vazio, pular (log debug). Ordenar por `rect.y0`. Retornar `dict[int, list[fitz.Rect]]` (página 0-based → bboxes ordenados).
2. `extract_tables_pass`: quando uma tabela é marcada ilegível (`_is_probably_illegible`), capturar seu bbox junto — usar o mesmo objeto de tabela do pdfplumber que já expõe `.bbox` (`page.find_tables()` em vez de/além de `extract_tables()`, ou usar `table.bbox` se a API do `extract_tables()` já expuser via objeto `Table`). Substituir `{"illegible_page": True}` por `{"illegible_page": True, "bbox": (x0, top, x1, bottom)}`.
3. Testar isoladamente que os bboxes capturados fazem sentido (dimensões menores que a página, dentro dos limites do `page.rect`).

#### Testes desta fase
- Caminho feliz: PDF com 1 imagem numa página → 1 bbox capturado, dimensões menores que a página inteira
- Falha: `get_image_rects(xref)` retorna lista vazia → pass não quebra, imagem pulada, log debug
- Edge case: tabela ilegível (NR-03 TABELA 3.4) → bbox capturado corretamente, coordenadas dentro da página 5

---

### Fase 2 — Merge unificado por bbox, ordenado por Y
**Objetivo:** `merge_passes` recebe bboxes de imagem + bbox de tabela ilegível por página, renderiza 1 PNG por item (`page.get_pixmap(clip=bbox, matrix=fitz.Matrix(2,2))`), insere `![...]` no fim do texto da página na ordem Y correta — cobrindo os casos isolados e o caso misto.
**Arquivos:** `scripts/convert_nr.py` (`merge_passes`, `convert_nr`), remover `_render_page_png` se sem callers
**Agente sugerido:** `python-pipeline`
**Depende de:** Fase 1

#### Passos
1. `merge_passes`: para cada página, montar uma lista combinada de itens `{"bbox": rect, "kind": "image" | "table"}` — imagens da Fase 1 + tabela ilegível (se houver) — ordenar por `bbox.y0` (ou `bbox[1]`, formato tupla do pdfplumber).
2. Renderizar cada item com `page.get_pixmap(clip=bbox, matrix=fitz.Matrix(2, 2))`, salvar em `assets/pages/page-{NNN}-{kind}-{i:02d}.png`.
3. Inserir `![Página N — imagem i](../assets/pages/page-NNN-image-00.png)` ou `![Tabela da página N](../assets/pages/page-NNN-table-00.png)` no fim do texto da página, na ordem da lista combinada.
4. `convert_nr()`: ajustar a passagem de dados entre passes (bboxes de imagem do Pass 3, bbox de tabela do Pass 2, ambos para o merge).
5. Confirmar via `grep -n "_render_page_png" scripts/convert_nr.py` que não sobra nenhum caller antes de remover a função.

#### Testes desta fase
- Caminho feliz: página com 1 imagem → PNG recortado, referência no fim do texto da página
- Caminho feliz: página com 1 tabela ilegível → PNG recortado (só a área da tabela, não a página inteira)
- Edge case: página com 2+ imagens → PNGs numerados, ordem Y correta
- Edge case: página com imagem embutida E tabela ilegível → 2 PNGs distintos, inseridos na ordem Y correta (não misturados num só)
- Edge case: PDF sem imagem nem tabela ilegível → sem PNGs gerados, sem seção residual no `.md`
- Falha: bbox de tabela não encontrado (`find_tables()` não bate com `extract_tables()`) → fallback para página inteira só nessa tabela, log de warning (não quebra o pipeline)

---

### Fase 3 — Reconversão das 27 NRs e validação
**Objetivo:** aplicar o novo pipeline ao conteúdo já commitado.
**Arquivos:** nenhum arquivo de código — execução + revisão de diff
**Agente sugerido:** `python-pipeline` (execução) + revisão humana do diff
**Depende de:** Fase 1, Fase 2

#### Passos
1. `python3 scripts/convert_nr.py --all` (local, `.venv` ativado)
2. `git status` — confirmar que `assets/pages/page-NNN.png` (página inteira) some, substituído por `page-NNN-image-NN.png`/`page-NNN-table-NN.png`
3. Revisar por amostragem: NR-03 (TABELA 3.4 vira PNG recortado, não página inteira), alguma NR com imagem/diagrama de página (verificar `todo.md`/`assets/pages` das NRs já convertidas para achar candidata)
4. `python3 scripts/validate_manifest.py` (se aplicável)
5. `./scripts/check.sh` antes de commitar

#### Testes desta fase
- Caminho feliz: `check.sh` passa, diff revisado
- Falha: alguma NR falha na reconversão → isolar antes de commitar as demais
- Edge case: NRs revogadas continuam puladas (comportamento herdado, não afetado)

## Critérios de aceite

### CA1 — Imagem aparece no leitor, recortada
**Dado** um PDF de NR com ao menos uma imagem embutida numa página
**Quando** `convert_nr.py --nr <nr-id>` roda
**Então** o `.md` gerado contém uma referência `![...]` apontando para um PNG cujas dimensões correspondem ao bbox da imagem (não à página inteira), posicionada após o texto da página correspondente

### CA2 — Tabela ilegível vira PNG recortado, não página inteira
**Dado** a TABELA 3.4 da NR-03 (ou outra tabela ilegível conhecida)
**Quando** a NR é reconvertida
**Então** o `.md` mostra `![Tabela da página N](.../page-NNN-table-00.png)` com dimensões do bbox da tabela, não da página inteira

### CA3 — Ordem correta em página mista
**Dado** uma página com imagem embutida E tabela ilegível
**Quando** o pipeline processa essa página
**Então** os dois PNGs aparecem no Markdown na ordem vertical (Y) correta, como itens distintos — não um único PNG de página inteira

### CA4 — Pipeline não quebra
**Dado** qualquer PDF de NR (com ou sem imagens/tabelas ilegíveis)
**Quando** `convert_nr.py --nr <nr-id>` roda
**Então** o script completa sem exceção e `scripts/check.sh` / `validate_manifest.py` continuam passando

## Checklist de entrega
- [ ] Descoberta vinculada em `.claude/discoveries/imagens-pagina-posicionamento.md`
- [ ] Decisões abertas resolvidas *(nenhuma)*
- [ ] Testes: caminho feliz + falha + edge cases (por fase, listados acima)
- [ ] `todo.md` — marcar item 12b como `[x]`
- [ ] `docs/architecture.md` § Pipeline de conteúdo atualizado (tabela ilegível: página inteira → bbox)
- [ ] `.claude/decisions/tabelas-inline-md.md` — anotar que a Decisão 2 foi substituída por este plano
- [ ] Rodar `python3 scripts/convert_nr.py --nr <nr-com-imagem>` e `--nr nr-03` manualmente e inspecionar o `.md` gerado

## Contexto para /fazer

**Objetivo:**
Substituir o PNG de página inteira (usado hoje tanto para imagem embutida quanto para tabela ilegível) por recorte de bbox em ambos os casos, inserido como `![...]` de verdade no fim do texto da página correta, na ordem Y — fechando o item 12b e eliminando a duplicação de texto normativo em tabelas ilegíveis.

**Arquivos previstos:**
- `scripts/convert_nr.py`
- `scripts/test_convert_nr.py`

**Não fazer:**
- Não mexer no app Flutter/leitor
- Não mudar a lógica de detecção de ilegibilidade nem o filtro de 1 coluna (já corretos)
- Não tentar posicionamento por coordenada Y dentro do parágrafo (mantido: fim do bloco da página)
- Não expandir para outras fases

**Critérios obrigatórios:**
- CA1, CA2, CA3, CA4 verificados
- Decisões tomadas (tabela acima) respeitadas

**Ordem de execução sugerida:**
1. Fase 1 → bbox por imagem e por tabela ilegível
2. Fase 2 → merge unificado ordenado por Y
3. Fase 3 → reconversão das 27 NRs + validação
