# Plano — Tabelas inline, sem duplicação e sem falso-positivo no pipeline de conversão

> **Descoberta:** `.claude/discoveries/tabelas-inline-md.md`
> **Decisão:** `.claude/decisions/tabelas-inline-md.md`

## O que será feito e por quê

- **Extração por página no Pass 1** — trocar `pymupdf4llm.to_markdown` de saída única para `page_chunks=True`, porque sem isso não dá pra saber onde inserir cada tabela nem comparar tabela-por-página com o Pass 2.
- **Pass 2 reescrito para gerar Markdown, não HTML** — porque a decisão foi manter pdfplumber como fonte de verdade da tabela (grade mais limpa), convertida pra Markdown nativo do `flutter_markdown`.
- **Filtro de falso-positivo (tabela de 1 coluna)** — 118/573 tabelas hoje commitadas são caixas de texto, não dados tabulares; descartar sempre.
- **Detecção de tabela ilegível → fallback PNG de página inteira** — caso a grade do pdfplumber saia com texto vertical quebrado (ex.: NR-03 TABELA 3.4), mostrar a página renderizada em vez de uma tabela ilegível.
- **Inserção inline por página** — cada tabela (Markdown ou PNG-fallback) entra no `.md` logo após o texto da página onde ela aparece, no lugar do bloco `## Tabelas` acumulado no fim.
- **Reconversão das 27 NRs já commitadas** — rodar `--all` localmente e revisar o diff antes de commitar, corrigindo o conteúdo que já está no repositório.

## Escopo

- `scripts/convert_nr.py`: `extract_text_pass`, `extract_tables_pass`, `extract_images_pass`, `merge_passes`, `convert_nr` (orquestração)
- Reconversão de `content/*/nr-*.md` (27 NRs, via script — nunca editado à mão)
- Possível adição de testes unitários para as funções puras novas (conversão tabela→Markdown, heurística de ilegibilidade)

## Fora de escopo

- Não alterar o leitor Flutter (`app/lib/features/reader/`) — Markdown de tabela padrão já é renderizado por `flutter_markdown` sem mudança de código; `flutter_widget_from_html` continua fora do MVP conforme já registrado em `IMPLEMENTATION_SUMMARY.md`
- Não mudar `manifest.json`/`index.json`/`search_index.json` schema — tabela inline é só texto Markdown a mais dentro do `.md` já indexado
- Não mudar detecção de update (`pdf_hash`) — reconversão usa o mesmo PDF já commitado, hash não muda
- Não implementar classificação de complexidade por NR — os 3 passes continuam rodando sempre, sem exceção (regra já registrada em `todo.md`)

## Impacto estimado

### App Flutter
- Nenhum arquivo — ganho é automático via Markdown padrão

### Pipeline Python
- 1 script: `scripts/convert_nr.py`
- Possível novo arquivo de teste: `scripts/test_convert_nr.py` (funções puras)

### app_meta.json / manifest
- Nenhum — schema inalterado

### Testes
- 3 cenários automatizáveis (funções puras) + verificação empírica nas 27 NRs reconvertidas (ver Fase 4)

## Referências

| Arquivo | Seções utilizadas |
|---------|-------------------|
| `docs/architecture.md` | § Pipeline de conteúdo (3 camadas, 3-level fallback tabelas/imagens) |
| `CLAUDE.md` | "Scripts vs AI: ... nunca por hand-editing generated output" |
| `todo.md` | linha 117 — "Pipeline uniforme: 3 passes sempre executados, sem classificação de complexidade" |
| `.claude/discoveries/tabelas-inline-md.md` | Achados empíricos (20% falso-positivo, caso NR-03, bug de link no reader) |
| `.claude/decisions/tabelas-inline-md.md` | D1–D4 |

## Decisões tomadas

| Decisão | Escolha | Fundamento |
|---------|---------|------------|
| Fonte da tabela quando os 2 passes coincidem | Sempre pdfplumber (Pass 2), convertido a Markdown | Escolha do usuário — grade mais limpa que a tentativa nativa do Pass 1 |
| Fallback de tabela ilegível | PNG de página inteira (reaproveita Pass 3) | Escolha do usuário — usuário vê a tabela como está no PDF oficial |
| Falso-positivo (tabela de 1 coluna) | Descartar sempre | Escolha do usuário — texto já coberto pelo Pass 1 como parágrafo |
| Reconversão das 27 NRs | Rodar `--all` local antes de commitar | Escolha do usuário — não depender do cron pra ver o resultado |
| Testes automatizados novos | Cobrir só as funções puras (conversão tabela→Markdown, heurística ilegibilidade) | Repo não tem pytest hoje para `scripts/`; não introduzir infra de teste nova além do necessário para a lógica nova, mantendo o padrão atual (`check.sh` não roda testes Python) |

## Decisões abertas

*(nenhuma — plano pronto para /fazer)*

## Riscos

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| Heurística de "mesma tabela" (dedupe Pass 1 vs Pass 2) remove texto legítimo do Pass 1 que não era tabela | Médio | Restringir a remoção a linhas que já são uma tabela Markdown válida (`\|---\|` de separador) na mesma página — nunca remover parágrafo comum |
| Heurística de "ilegível" (texto vertical quebrado) gera falso-positivo e esconde uma tabela que na verdade estava OK | Médio | Critério conservador: só cai pra PNG se a maioria das células da tabela tiver múltiplas quebras de linha de 1 caractere cada — caso raro e bem diferente de tabela normal |
| Render de página sob demanda (Pass 2 → PNG) duplica lógica já existente no Pass 3 | Baixo | Extrair um helper único de "renderizar página N como PNG" reusado pelos dois passes, evitando renderizar a mesma página duas vezes |
| Reconversão das 27 NRs gera diff grande difícil de revisar à mão | Médio | Revisar por amostragem (NR-01, NR-03, NR-04 — já usadas como caso de teste) + `scripts/validate_manifest.py` + `git diff --stat` pro resto |

## Dependências entre fases

- Fase 2 depende de Fase 1 — precisa do texto por página pra fazer o dedupe e saber onde inserir
- Fase 3 depende de Fase 1 e Fase 2 — junta texto por página + tabelas (Markdown ou PNG) num único `.md`
- Fase 4 depende de Fase 1, 2 e 3 concluídas e revisadas

---

## Detalhamento

### Fase 1 — Pass 1 por página
**Objetivo:** `extract_text_pass` retorna o texto segmentado por página (não mais uma string única), preservando tudo que a função já faz hoje (normalização acontece depois, sem mudança).
**Arquivos:** `scripts/convert_nr.py` (`extract_text_pass`, ajuste de `save_metadata` para usar `len("".join(páginas))` no lugar do `len(md_text)` atual)
**Agente sugerido:** `python-pipeline`
**Depende de:** nenhuma

#### Passos
1. Trocar `pymupdf4llm.to_markdown(str(pdf_file))` por `pymupdf4llm.to_markdown(str(pdf_file), page_chunks=True)`, que retorna uma lista de dicts (`{"text": ..., "metadata": {...}}`) — um por página
2. `extract_text_pass` passa a retornar `list[str]` (só o campo `text` de cada chunk), mantendo a assinatura de retorno documentada na docstring
3. Ajustar `convert_nr()` e `save_metadata()` para os pontos que hoje esperam uma string única (`len(md_text)`, log de "chars extraídos") — usar `sum(len(p) for p in paginas)`

#### Testes desta fase
- Caminho feliz: rodar em NR-01 (`--dry-run` não serve aqui, precisa baixar/ler o PDF já commitado) e conferir que `len(paginas) == número de páginas do PDF` (usar `fitz.open(pdf).page_count` como referência)
- Falha: PDF corrompido/ilegível → mesma exceção tratada hoje em `extract_text_pass` (try/except existente), só muda o tipo de retorno no caminho de sucesso
- Edge case: NR de 1 página só (verificar que não quebra ao ter lista de tamanho 1)

---

### Fase 2 — Pass 2 reescrito: filtro, formato e dedupe
**Objetivo:** `extract_tables_pass` recebe o texto por página da Fase 1, descarta falso-positivo, converte tabela pra Markdown, remove do texto da página qualquer tentativa duplicada de tabela que o Pass 1 já tenha feito, e sinaliza quais tabelas são ilegíveis (para a Fase 3 tratar com PNG).
**Arquivos:** `scripts/convert_nr.py` (`extract_tables_pass`, + funções auxiliares novas: `_table_to_markdown(table: list[list]) -> str`, `_is_probably_illegible(table: list[list]) -> bool`, `_strip_duplicate_markdown_table(page_text: str) -> str`)
**Agente sugerido:** `python-pipeline`
**Depende de:** Fase 1

#### Passos
1. `_table_to_markdown`: recebe a lista de linhas do pdfplumber (`page.extract_tables()`), gera `| col | col |` + linha separadora `|---|---|`, escapando `|` literal dentro de célula (`\|`)
2. Filtro de falso-positivo: antes de gerar Markdown, calcular `max(len(row) for row in table)`; se `<= 1`, descartar a tabela inteira (não vira arquivo, não vira referência) — decisão D3
3. `_is_probably_illegible`: heurística — célula é suspeita se seu texto tiver ≥3 quebras de linha e a maior "palavra" entre quebras tiver 1–2 caracteres (sinal de texto vertical quebrado char-a-char, como visto na NR-03); tabela é ilegível se ≥50% das células não vazias forem suspeitas
4. `_strip_duplicate_markdown_table`: recebe o texto da página (Fase 1) e remove blocos que já são uma tabela Markdown válida (linha com `|` seguida de linha `|---|`) — evita ter a tentativa ruim do Pass 1 e a versão boa do Pass 2 juntas na mesma página (decisão D1)
5. `extract_tables_pass` passa a retornar uma estrutura por página, ex. `dict[int, list[str | dict]]` — lista de blocos a inserir (string Markdown pronta, ou marcador `{"illegible_page": True}` para a Fase 3 resolver com PNG) — junto com o texto de página já limpo pela função 4

6. Parar de escrever em `assets/tables/*.html` — a decisão foi sempre preferir Markdown; não há mais consumidor do HTML depois desta fase (nem o app usa `flutter_widget_from_html` hoje)

#### Testes desta fase
- Caminho feliz: tabela simples multi-coluna (ex. NR-01 página 4 é falso-positivo — usar uma tabela real, como NR-03 página 2 ou 3) vira Markdown válido e não duplica o que o Pass 1 já tinha
- Falha: tabela vazia (`extract_tables()` retorna lista vazia) → função retorna sem erro, sem gerar entrada
- Edge case: tabela de 1 coluna (NR-01 página 4) é descartada; tabela ilegível (NR-03 TABELA 3.4, página 5) é marcada `illegible_page` em vez de virar Markdown ruim

---

### Fase 3 — Inserção inline e fallback PNG compartilhado
**Objetivo:** `merge_passes` monta o `.md` final concatenando página por página (texto + tabelas daquela página), e páginas marcadas como `illegible_page` recebem o PNG da página renderizada — reaproveitando (sem duplicar) a lógica de render que já existe no Pass 3.
**Arquivos:** `scripts/convert_nr.py` (`extract_images_pass` — extrair helper `_render_page_png(doc, page_num, pages_dir) -> Path`; `merge_passes` reescrito; `convert_nr()` — orquestração ajustada pra passar os dados por página entre os passes)
**Agente sugerido:** `python-pipeline`
**Depende de:** Fase 1, Fase 2

#### Passos
1. Extrair de `extract_images_pass` um helper `_render_page_png(doc: fitz.Document, page_num: int, pages_dir: Path) -> Path`, reaproveitado tanto pelo caminho existente (páginas com imagem embutida) quanto pelo novo caminho (páginas com tabela ilegível)
2. `extract_images_pass` continua com sua lista de páginas-com-imagem-embutida; a nova lista de páginas-com-tabela-ilegível (vinda da Fase 2) é unida a essa antes de renderizar, evitando renderizar a mesma página duas vezes
3. `merge_passes(paginas_texto: list[str], tabelas_por_pagina: dict, imagens_por_pagina: dict, nr_id: str) -> str`: para cada página em ordem, concatena `paginas_texto[i]` + blocos de tabela daquela página (Markdown pronto, ou `![Tabela N](../assets/pages/page-XXX.png)` se `illegible_page`)
4. Remover o bloco `## Tabelas` acumulado no fim e o comentário oculto de imagens — cada referência agora mora no ponto certo do texto
5. `convert_nr()`: ajustar a chamada em sequência (Pass 1 → Pass 2 usando o output do Pass 1 → Pass 3 usando a lista unificada de páginas → merge)

#### Testes desta fase
- Caminho feliz: reconverter NR-01 (`--dry-run` não serve; precisa gravar) num diretório de teste e conferir visualmente que a tabela da página 4 (antigo falso-positivo, agora descartada) não aparece mais, e que outra NR com tabela real mostra o Markdown logo após o parágrafo certo
- Falha: PDF sem nenhuma tabela nem imagem (ex. NR-02) → `merge_passes` produz exatamente o texto por página concatenado, sem seções extras
- Edge case: NR-03 — TABELA 3.4 (página 5) aparece como imagem PNG inline, no lugar do texto "TABELA 3.4 - Tabela de excesso de risco..."; nenhuma tabela-fantasma de 1 coluna sobra em nenhuma NR

---

### Fase 4 — Reconversão das 27 NRs e validação
**Objetivo:** aplicar o novo pipeline ao conteúdo já commitado e confirmar que nada quebrou.
**Arquivos:** nenhum arquivo de código — execução + revisão de diff em `content/*/nr-*.md` e `content/*/assets/`
**Agente sugerido:** `python-pipeline` (execução) + revisão humana do diff antes de commitar
**Depende de:** Fase 1, 2, 3

#### Passos
1. `python3 scripts/convert_nr.py --all` (local, com `.venv` ativado)
2. `git status` — confirmar que `assets/tables/*.html` some (não é mais gerado) e que os `.md` mudaram
3. Revisar por amostragem: NR-01 (falso-positivo sumiu), NR-03 (TABELA 3.4 virou imagem inline), NR-04 (16 tabelas — conferir que pelo menos as primeiras 2–3 ficaram no lugar certo)
4. `python3 scripts/validate_manifest.py` (se `manifest.json` já existir e for afetado por contagem de chars/hash)
5. `./scripts/check.sh` antes de commitar

#### Testes desta fase
- Caminho feliz: `check.sh` passa, diff das 27 NRs revisado
- Falha: se alguma NR falhar na reconversão (`convert_nr()` retorna `False`), isolar e investigar antes de commitar as demais (mesmo comportamento de isolamento de erro já existente em `update_nrs.py`)
- Edge case: NRs revogadas (NR-2, NR-27) — confirmar que continuam puladas pela conversão (`list_all_nrs()`), não afetadas por este plano

## Critérios de aceite

### CA1 — Tabela real aparece no lugar certo
**Dado** uma NR com tabela multi-coluna (ex. NR-03, página 2 ou 3)
**Quando** a NR é reconvertida
**Então** a tabela em Markdown aparece imediatamente após o parágrafo que a referencia, não mais num bloco `## Tabelas` no fim do arquivo

### CA2 — Falso-positivo desaparece
**Dado** a "tabela" de 1 coluna da NR-01 (página 4, hoje um bloco de texto comum detectado como tabela)
**Quando** a NR-01 é reconvertida
**Então** nenhuma referência a essa tabela aparece no `.md` — o texto já está coberto normalmente pelo Pass 1

### CA3 — Tabela ilegível vira imagem
**Dado** a TABELA 3.4 da NR-03 (cabeçalho rotacionado, ilegível nos dois passes hoje)
**Quando** a NR-03 é reconvertida
**Então** o `.md` mostra `![Tabela ...](../assets/pages/page-005.png)` no lugar do texto da tabela, sem tentativa de Markdown/HTML ilegível

### CA4 — Sem duplicação
**Dado** uma página onde Pass 1 já tentou renderizar a tabela como Markdown
**Quando** o Pass 2 processa a mesma página
**Então** só a versão do Pass 2 (convertida) aparece no `.md` final — não as duas

### CA5 — Nenhum HTML de tabela novo
**Dado** qualquer NR reconvertida
**Quando** a conversão termina
**Então** `assets/tables/*.html` não é mais gerado (arquivos antigos podem ser removidos do repo como parte da Fase 4)

## Checklist de entrega
- [ ] Descoberta vinculada em `.claude/discoveries/tabelas-inline-md.md`
- [ ] Decisões abertas resolvidas *(nenhuma)*
- [ ] `./scripts/check.sh` passa
- [ ] `validate_manifest.py` passa
- [ ] Testes: caminho feliz + falha + edge case (por fase, listados acima)
- [ ] `todo.md` — sem item específico a marcar (é correção de qualidade dentro do item 12 já `[x]`); registrar como nota se o time achar relevante
- [ ] `docs/architecture.md` § Pipeline de conteúdo atualizado: trocar "Pass tabelas: pdfplumber → HTML em assets/tables/" por "Pass tabelas: pdfplumber → Markdown inline (fallback PNG de página se ilegível)"

## Contexto para /fazer

**Objetivo:** tabelas do `.md` de cada NR aparecem como Markdown no ponto certo do texto (ou como imagem de página, se ilegíveis nos dois passes), sem duplicar o que o Pass 1 já capturou e sem falso-positivo de tabelas de 1 coluna; as 27 NRs já commitadas são reconvertidas com o novo pipeline.

**Arquivos previstos:**
- `scripts/convert_nr.py`
- `scripts/test_convert_nr.py` (novo, só para as funções puras: `_table_to_markdown`, `_is_probably_illegible`, `_strip_duplicate_markdown_table`)
- `content/*/nr-*.md` e `content/*/assets/` (27 NRs, via reconversão — nunca editado à mão)
- `docs/architecture.md` (1 linha da seção Pipeline de conteúdo)

**Não fazer:**
- Não editar nenhum `content/*/nr-*.md` à mão — só via `scripts/convert_nr.py`
- Não tocar no leitor Flutter (`app/lib/features/reader/`) — Markdown de tabela é renderizado automaticamente
- Não introduzir classificação de complexidade por NR nem pular nenhum dos 3 passes
- Não mudar schema de `manifest.json`/`app_meta.json`

**Critérios obrigatórios:**
- CA1 a CA5 verificados nas NRs de exemplo citadas (NR-01, NR-03, NR-04)
- Decisões tomadas (D1–D4) respeitadas como estão registradas
- Fases executadas em ordem: 1 → 2 → 3 → 4

**Ordem de execução sugerida:**
1. Fase 1 → Pass 1 por página
2. Fase 2 → Pass 2 reescrito (filtro + formato + dedupe + marcação de ilegível)
3. Fase 3 → merge inline + fallback PNG compartilhado
4. Fase 4 → reconversão das 27 NRs + validação
