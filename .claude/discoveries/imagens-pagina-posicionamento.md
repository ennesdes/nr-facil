# Descoberta — Imagens de página: posição correta no texto + recorte por bbox

> Gerado por `/descobrir` · Consumido por `/decidir` (já concluído nesta sessão)

## Demanda
Terminar o refactor (já iniciado, não commitado) do Pass 3 de `convert_nr.py`: em vez de renderizar a página inteira em PNG e escondê-la num comentário HTML no fim do arquivo (nunca aparece no leitor — item 12b do todo.md), cada imagem embutida deve virar um PNG recortado só da própria área (bbox), inserido como `![...]` de verdade logo após o bloco de texto da página correspondente, na ordem correta.

## Achado crítico — estado do working tree
`scripts/convert_nr.py` tem alterações **não commitadas** que já mudam a estrutura das 3 passes para serem "page-aware" (pré-requisito pra essa feature), mas ficaram **incompletas e quebram a execução**:
- Pass 1 (`extract_text_pass`) agora retorna `list[str]` (texto por página, via `pymupdf4llm.to_markdown(..., page_chunks=True)`) em vez de uma string única.
- Pass 2 (`extract_tables_pass`) retorna `dict` (`pages_text` + `tables_by_page`) em vez de string.
- Pass 3 (`extract_images_pass`) só identifica `pages_to_render` (união de páginas com imagem embutida `page.get_images()` e páginas com tabela ilegível) — não gera mais o markdown de imagem.
- `_render_page_png(doc, page_num, pages_dir)` existe (renderiza página inteira, zoom 2x) mas **não é chamada** em lugar nenhum.
- `convert_nr()` (orquestrador) **não foi atualizado**: ainda chama `extract_tables_pass(pdf_file, nr_id)` com 2 args (assinatura nova pede 3), trata retornos como strings, e `merge_passes()` ainda espera 3 strings prontas — **quebra em runtime**.

Confirmado com o usuário: continuar esse WIP (não descartar/redesenhar do zero).

## Perspectiva do usuário
Hoje o usuário do app nunca vê imagens/diagramas de página (ex.: fluxogramas de NRs) — item 12b. Depois da correção, a imagem aparece no ponto certo do conteúdo, sem duplicar como texto+imagem da mesma informação, o que aumenta a confiança na leitura offline.

## Perspectiva do produto
Consistente com o MVP: fidelidade ao conteúdo original é a proposta de valor central do app. Sem impacto em monetização/custo de CI (mesmo processamento, só reorganiza a saída).

## Perspectiva técnica

| Arquivo | O que muda | Por quê | Risco |
|---------|-----------|---------|-------|
| `scripts/convert_nr.py::convert_nr()` | Atualizar chamadas para as novas assinaturas (`tables_by_page`, `pages_to_render`) | Corrigir quebra atual | baixo (mecânico) |
| `scripts/convert_nr.py::extract_images_pass()` | Para cada página em `pages_to_render` com imagem embutida: obter bbox de cada imagem via `page.get_image_rects(xref)`, ordenar por `y0`, renderizar 1 PNG por imagem (`get_pixmap(clip=rect, matrix=...)`) | Evitar duplicar texto já extraído no Pass 1; reduzir tamanho do repo (equivalente ao ganho do item 23b, mas por imagem) | baixo — API padrão do PyMuPDF |
| `scripts/convert_nr.py::merge_passes()` | Reescrever para iterar página a página (`zip` de `pages_text`, tabelas da página, imagens da página) em vez de concatenar texto + bloco de tabelas + comentário no fim | Ordem correta e imagem visível de fato no Markdown | médio — é o coração da mudança; precisa preservar numeração/estrutura de headings entre páginas |
| Páginas com tabela ilegível (sem imagem embutida) | Mantém renderização de página inteira via `_render_page_png` (fora do escopo desta decisão) | Já é o fallback de 3 níveis documentado em `docs/architecture.md`; crop de bbox de tabela é problema separado | — |

## Fidelidade de conteúdo
Não altera texto normativo — só reorganiza onde a referência de imagem aparece e reduz a área renderizada em PNG. Sem risco de reescrita de conteúdo.

## Decisões já resolvidas com o usuário nesta sessão

| Pergunta | Opção escolhida | Por quê |
|----------|------------------|---------|
| WIP não commitado em `convert_nr.py`: continuar ou descartar? | Continuar o WIP | É a direção certa (per-page), só faltava terminar |
| Onde inserir a imagem no texto da página? | No fim do bloco de texto da página | Robusto — `pymupdf4llm` não expõe posição de linha de forma confiável; tentar posição exata via Y arrisca inserir no lugar errado ou quebrar Markdown (ex.: dentro de tabela) |
| Múltiplas imagens na mesma página | Um PNG por imagem, em ordem Y (bbox individual) | Mantém arquivos pequenos e ordem de leitura correta, sem misturar espaço em branco/texto entre figuras |

## todo.md
- [x] Previsto — item 12b: "Imagens de página (Pass 3) nunca aparecem no leitor... só falta a referência virar `![...]` de verdade no ponto certo do texto"
- Relacionado: item 23b (já fechado) — só renderizar páginas com imagem, não todas

## Lacunas ainda abertas
*(nenhuma — todas as dúvidas foram resolvidas com o usuário nesta sessão)*
