# Plano — Imagens de página: recorte por bbox + posição correta no texto

> **Descoberta:** `.claude/discoveries/imagens-pagina-posicionamento.md`
> **Decisão:** `.claude/decisions/imagens-pagina-posicionamento.md`

## O que será feito e por quê

- **Terminar o refactor "page-aware" já iniciado (não commitado)** em `scripts/convert_nr.py` — hoje `convert_nr()` chama as passes com a assinatura antiga e quebra em runtime.
- **Recortar PNG só do bbox de cada imagem embutida** (não a página inteira) — evita duplicar texto que o Pass 1 já extraiu e reduz tamanho do repo, um PNG por imagem, ordenado por posição vertical (`y0`).
- **Inserir a referência `![...]` no fim do bloco de texto da própria página** no merge final — resolve o item 12b do todo.md (imagem hoje fica presa num comentário HTML que nenhum Markdown renderiza).
- **Manter páginas com tabela ilegível renderizando a página inteira** — fallback já documentado em `docs/architecture.md`, fora do escopo desta decisão.

## Escopo
- `scripts/convert_nr.py`: `extract_tables_pass`, `extract_images_pass`, `merge_passes`, `convert_nr`
- `scripts/test_convert_nr.py`: testes novos para o merge por página e o recorte por bbox

## Fora de escopo
- Não alterar o pipeline de tabelas além de corrigir a chamada quebrada (recorte de bbox de tabela ilegível é problema separado, não pedido pelo usuário)
- Não mudar `manifest.json`/`app_meta.json`
- Não alterar o app Flutter/leitor (`photo_view` já suporta imagem local + zoom, conforme CLAUDE.md)
- Não tentar posicionamento por coordenada Y dentro do texto (decidido: fim do bloco da página)

## Impacto estimado

### App Flutter
- Nenhum

### Pipeline Python
- 1 script (`scripts/convert_nr.py`)

### app_meta.json / manifest
- Nenhum

### Testes
- ~5–6 cenários novos (merge por página, bbox único, múltiplas imagens ordenadas, página sem imagem, tabela ilegível sem imagem)

## Referências

| Arquivo | Seções utilizadas |
|---------|-------------------|
| `docs/architecture.md` | Pipeline de conteúdo — fallback de 3 níveis (texto/tabelas/imagens) |
| `todo.md` | Item 12b (imagens nunca aparecem no leitor) e 23b (só renderizar página com imagem, já fechado) |
| `CLAUDE.md` | "nunca rewrite normative text — só extrair, estruturar e exibir melhor" |

## Decisões tomadas

| Decisão | Escolha | Fundamento |
|---------|---------|------------|
| Continuar WIP não commitado ou redesenhar | Continuar o WIP | Escolha do usuário via `/decidir` — direção já correta, só faltava terminar |
| Posição da imagem no texto | Fim do bloco de texto da página | Escolha do usuário via `/decidir` — robustez sobre precisão milimétrica |
| Múltiplas imagens na mesma página | Um PNG por imagem, ordenado por Y | Escolha do usuário via `/decidir` — evita espaço em branco/texto entre figuras num PNG único |
| Tabela ilegível sem imagem | Mantém página inteira (`_render_page_png`) | Já é o fallback documentado em `docs/architecture.md`, não reaberto |

## Decisões abertas

*(nenhuma — plano pronto para /fazer)*

## Riscos

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| `pages_text` (Pass 1) e `tables_by_page`/`pages_to_render` (Pass 2/3) desalinharem por índice de página | Alto (imagem/tabela na página errada) | Todas as passes abrem o mesmo `pdf_file` com bibliotecas da família PyMuPDF/pdfplumber — mesmo `len(doc)` esperado; adicionar assert/log se os tamanhos não baterem |
| Página com imagem decorativa embutida (ex.: logo/timbre repetido em toda página) gera PNG desnecessário em toda página do documento | Médio (poluição visual, repo maior) | Fora do escopo desta decisão — já é comportamento herdado do Pass 3 atual (não piora, não é o foco do pedido do usuário) |
| `get_image_rects(xref)` retornar lista vazia para alguma imagem (ex.: imagem referenciada mas não desenhada na página) | Baixo | Pular essa imagem (log debug), sem quebrar a passe inteira |

## Dependências entre fases
Fase única — sem dependências entre fases.

---

## Detalhamento

### Fase 1 — Corrigir orquestração + recorte por bbox + merge por página
**Objetivo:** `convert_nr()` roda sem quebrar, gera 1 PNG recortado por imagem embutida (ordenado por Y), e o Markdown final tem a imagem inserida no fim do texto da página correta — sem comentário HTML escondido.
**Arquivos:** `scripts/convert_nr.py`
**Agente sugerido:** `python-pipeline`
**Depende de:** nenhuma

#### Passos
1. `extract_tables_pass`: confirmar assinatura/retorno atual (`{"pages_text": [...], "tables_by_page": {...}}`) — já está correta no WIP, só ajustar quem chama.
2. `extract_images_pass`: para cada `page_num` em `pages_to_render` que tem imagem embutida (`page.get_images(full=True)`):
   - Para cada `xref` de imagem: `rects = page.get_image_rects(xref)`; se vazio, pular (log debug).
   - Ordenar todas as imagens da página por `rect.y0`.
   - Renderizar cada uma com `page.get_pixmap(clip=rect, matrix=fitz.Matrix(2, 2))`, salvar em `assets/pages/page-{NNN}-img-{i:02d}.png`.
   - Para páginas em `pages_to_render` SEM imagem embutida (ou seja, só tabela ilegível), manter `_render_page_png` (página inteira) como já está.
   - Retornar `dict[int, list[Path]]` (`page_num` 0-based → lista de PNGs da página, já em ordem).
3. `merge_passes`: reescrever para receber `pages_text: list[str]`, `tables_by_page: dict[int, list]`, `images_by_page: dict[int, list[Path]]` e iterar página a página (`for page_num, page_text in enumerate(pages_text)`), montando: texto da página → tabelas da página (se houver) → imagens da página como `![Página N — imagem i](../assets/pages/page-NNN-img-NN.png)` (uma por linha, na ordem).
4. `convert_nr()`: atualizar chamadas para passar os argumentos corretos entre passes (`tables_by_page` para `extract_images_pass`, resultado de `extract_images_pass` para `merge_passes`) e concatenar `pages_text_cleaned` (retornado por `extract_tables_pass`) em vez do `text_md` bruto do Pass 1.
5. Limpar PNGs órfãos de conversão anterior (glob `page-*.png` antes de gerar) — já existe no HEAD, só adaptar ao novo padrão de nome de arquivo.

#### Testes desta fase
- Caminho feliz: PDF com 1 imagem numa página → 1 PNG `page-XXX-img-00.png` gerado, referência aparece no Markdown logo após o texto daquela página.
- Falha: `page.get_image_rects(xref)` retorna lista vazia para uma imagem → pass não quebra, imagem é pulada, log de debug emitido.
- Edge case 1: página com 2+ imagens → PNGs numerados e inseridos na ordem correta de `y0`.
- Edge case 2: página com tabela ilegível e sem imagem embutida → continua renderizando página inteira (comportamento herdado).
- Edge case 3: PDF sem nenhuma imagem embutida → `images_by_page` vazio, Markdown final sem seção de imagens, sem comentário HTML residual.

---

## Critérios de aceite

### CA1 — Imagem aparece no leitor
**Dado** um PDF de NR com ao menos uma imagem embutida numa página
**Quando** `convert_nr.py --nr <nr-id>` roda
**Então** o `.md` gerado contém uma referência `![...]` (não um comentário HTML) apontando para um PNG existente em `assets/pages/`, posicionada após o texto da página correspondente

### CA2 — PNG recortado, não página inteira
**Dado** uma página com uma imagem embutida
**Quando** o Pass 3 processa essa página
**Então** o PNG gerado tem dimensões correspondentes ao bbox da imagem (menor que a página inteira), não à página completa

### CA3 — Ordem correta com múltiplas imagens
**Dado** uma página com 2+ imagens embutidas em posições verticais diferentes
**Quando** o Pass 3 processa essa página
**Então** os PNGs são gerados e referenciados no Markdown na mesma ordem em que aparecem de cima para baixo na página original

### CA4 — Pipeline não quebra
**Dado** qualquer PDF de NR (com ou sem imagens)
**Quando** `convert_nr.py --nr <nr-id>` roda
**Então** o script completa sem exceção e `scripts/check.sh` / `validate_manifest.py` continuam passando

## Checklist de entrega
- [ ] Descoberta vinculada em `.claude/discoveries/imagens-pagina-posicionamento.md`
- [ ] Decisões abertas resolvidas *(nenhuma)*
- [ ] Testes: caminho feliz + falha + edge cases (3)
- [ ] `todo.md` atualizado — marcar item 12b como `[x]`
- [ ] Rodar `python3 scripts/convert_nr.py --nr <alguma-nr-com-imagem> --verbose` manualmente e inspecionar o `.md` gerado

## Contexto para /fazer

**Objetivo:**
Terminar o refactor page-aware de `convert_nr.py` para que imagens embutidas virem PNGs recortados por bbox, inseridos como `![...]` de verdade no fim do bloco de texto da página correta, na ordem certa.

**Arquivos previstos:**
- `scripts/convert_nr.py`
- `scripts/test_convert_nr.py`

**Não fazer:**
- Não mexer no app Flutter/leitor
- Não implementar recorte de bbox para tabelas ilegíveis (fora de escopo)
- Não tentar posicionamento por coordenada Y dentro do parágrafo (decidido: fim do bloco da página)
- Não expandir para outras fases

**Critérios obrigatórios:**
- CA1, CA2, CA3, CA4 verificados
- Decisões tomadas (tabela acima) respeitadas

**Ordem de execução sugerida:**
1. Fase 1 (única) → corrigir `convert_nr()`, `extract_images_pass`, `merge_passes`, adicionar testes
