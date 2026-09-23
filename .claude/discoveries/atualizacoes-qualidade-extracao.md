# Descoberta — Propagação de correções de extração para apps em produção + qualidade da NR-4 + backlog da tela de Atualizações

> Gerado por `/descobrir` · Consumido por `/decidir`

## Demanda

Três frentes, descobertas na mesma sessão:

1. **Propagação sem mudança de PDF** — depois de corrigir a extração de tabelas da NR-28 (PDF idêntico, só o código de conversão mudou), o usuário quer saber se apps já instalados recebem essa correção, e como o mecanismo de hash do app se relaciona com isso.
2. **Qualidade de extração na NR-4** — um subtítulo quebrado ("2.0 ), com correspondente grau de risco - gr") aparecendo como se fosse um item próprio, e tabelas do Anexo I (CNAE × Grau de Risco) renderizadas como uma imagem PNG por página, sem cabeçalho a partir da 2ª página.
3. **Backlog de ajustes de UX na tela de Atualizações** — depois de rodar a Action e conferir a NR-4 atualizada no app, o usuário levantou 10 pontos de polish/UX na feature de atualizações (sino, badge, tela de Atualizações, comparação antes/depois, tag no leitor) para fazer depois.

## Perspectiva do usuário

- O usuário confia que, ao corrigir a extração no repositório, quem já tem o app instalado eventualmente recebe o conteúdo melhorado — sem isso, cada correção de pipeline vira "conteúdo morto" pra quem não atualiza o app na loja, minando a proposta central de fidelidade de conteúdo.
- Na NR-4, hoje (antes da correção mais recente) o usuário via um item de índice/subtítulo ilegível — "), com correspondente grau de risco - gr" — sem nenhuma pista de que pertence ao Anexo I. Isso é pior que não ter subtítulo nenhum: parece erro do app, não do PDF.
- No Anexo I da NR-4 (tabela CNAE × Grau de Risco, ~26 páginas), a partir da 2ª imagem o usuário vê só código + descrição + número, sem saber que a 3ª coluna é "Grau de Risco" — precisa rolar ~20 imagens pra trás pra lembrar o que cada coluna significa.
- Na tela de Atualizações, o usuário sente ruído e fricção: card duplicado (home e dentro da própria tela), notificações que não consegue dispensar mesmo já tendo "entendido", contraste ruim no contador do sino, uma tag "Atualizada" cortada/feia no app bar do leitor, comparação antes/depois incompleta dentro do leitor mas excessivamente longa (>4 linhas) na tela cheia, e updates que às vezes são só ruído de re-extração (ex.: um hífen que apareceu no meio de um número) e não mudança normativa de verdade.

## Perspectiva do produto

- Fidelidade de conteúdo é a aposta central do produto ([[project_motivation]] em memória). As duas primeiras frentes atacam diretamente essa promessa: se a correção não propaga, ou se o conteúdo "corrigido" ainda tem lixo de extração visível, o diferencial do app não se sustenta.
- O Anexo I da NR-4 (CNAE × Grau de Risco) é uma das tabelas mais consultadas de todo o app — é o que uma empresa usa pra descobrir seu Grau de Risco e dimensionar CIPA/SESMT (a própria NR-4 é sobre isso). Qualidade ruim aqui pesa mais que em anexos menos consultados.
- A tela de Atualizações (sino, item 17 do todo.md: "Histórico + card Continuar leitura" / "Tela Atualizações (sino + badge, não aba)") já está implementada e em produção — os 10 itens de UX são refinamento de uma feature existente, não escopo novo. Ruído no feed (ex.: notificar por um hífen de artefato de extração) é o tipo de coisa que reduz a confiança no sino: se o usuário aprende que "atualização" às vezes não quer dizer nada, passa a ignorar avisos que really importam.
- Nenhum item aqui toca monetização (ads/IAP) ou custo de operação além do já existente (Action diária).

## Perspectiva técnica

### 1. Propagação de correções de extração (PDF idêntico)

| Achado | Detalhe | Evidência |
|---|---|---|
| App **não** usa `pdf_hash` para decidir atualização | `content_service.dart` compara `entry.hash` (linhas 245, 512, 521, 1070, `last_synced_hash`/`last_seen_hash`) — e esse `hash` vem de `build_manifest.py::calculate_md_hash()`, um SHA-256 do **Markdown gerado**, não do PDF | `scripts/build_manifest.py:111-117`, `scripts/build_manifest.py:153-154` (pdf_hash é campo separado, só auditoria) |
| `app_meta.json` (feed do sino) também já usa hash do `.md`, não `pdf_hash` | Comentário no próprio código indica que isso já foi migrado antes (critério D1: pdf_hash → hash) | `scripts/build_app_meta.py:6, 149-150, 184-189` |
| **Conclusão prática:** forçar a propagação já é possível hoje, sem mudar nada no app nem bump de versão | Basta rodar `convert_nr.py --nr <id>` (ou `--all`) + `build_manifest.py` + commit, mesmo com `pdf_hash` idêntico. O hash do `.md` muda, o manifest é regenerado, e no próximo "Verificar atualizações" (ou sync periódico) os apps já instalados detectam `entry.hash != localHash` e rebaixam o conteúdo novo | Confirmado empiricamente: `content/nr-28/meta.json` tem o **mesmo** `pdf_hash` (`58e58df7...`) desde a primeira conversão até o commit `d31578b` (correção de tabelas), mas o `hash` (md) de nr-28 em `manifest.json` mudou nesse commit — `d31578b` de fato regenerou `manifest.json` (556 linhas) |
| **Gap real 1 — a Action diária não pega correções só-de-código** | `scripts/update_nrs.py::process_nr()` só chama `run_conversion()` (que dispara `convert_nr.py`) quando `new_hash != prev_hash` (**pdf_hash**, não o código de extração) — linhas 144-149. Se o PDF não mudou, a Action loga "sem mudança" e nunca reconverte, mesmo que `convert_nr.py`/`build_structure.py` tenham sido corrigidos no mesmo dia | `scripts/update_nrs.py:137-149` |
| Como a correção de NR-28 propagou, então? | Foi manual: alguém rodou `convert_nr.py --nr nr-28` fora do fluxo da Action (a Action só decide *quando* reconverter via `update_nrs.py`; rodar `convert_nr.py` direto ignora esse gate) e commitou o resultado — inclusive `manifest.json` regenerado — direto em `d31578b` | `git show --stat d31578b` (mostra `content/nr-28/meta.json`, `content/nr-28/nr-28.md`, `manifest.json` no mesmo commit) |
| **Gap real 2 — `app_meta.json` não foi regenerado junto** | O commit `d31578b` regenerou `manifest.json` mas não tocou `app_meta.json` — ou seja, o dispositivo vai re-sincronizar o conteúdo sozinho (hash mudou), mas o histórico/sino não vai mostrar nenhuma entrada explicando o que mudou | `git show --stat d31578b -- app_meta.json` (vazio) vs `-- manifest.json` (556 linhas) |

### 2. NR-4 — subtítulo quebrado no Anexo I

| Achado | Detalhe | Evidência |
|---|---|---|
| Causa raiz confirmada | O PDF quebra o título do Anexo I em duas linhas **bold** separadas (reflow de PDF): `"**RELAÇÃO DA CLASSIFICAÇÃO NACIONAL DE ATIVIDADES ECONÔMICAS - CNAE (VERSÃO**"` e, em parágrafo seguinte, `"**2.0), COM CORRESPONDENTE GRAU DE RISCO - GR**"` | `content/nr-04/nr-04.md:295` e `:297` |
| `build_structure.py::parse_bold_major_section_line()` trata cada linha 100% em negrito como candidata a heading própria | Não há merge de heading que continua um heading anterior (ex.: quando a linha começa com minúscula/pontuação de fechamento, não com maiúscula nova) | `scripts/build_structure.py:314` (função), lógica de chamada em `:438-455` |
| Confirmado no dado gerado | `content/nr-04/structure.json` tem um node de heading cujo título é literalmente `'), COM CORRESPONDENTE GRAU DE RISCO - GR'` — exatamente o fragmento que o usuário viu no app | Lido diretamente do JSON nesta sessão |
| Escopo provável | Não é exclusivo da NR-4 — qualquer NR cujo heading quebre em duas linhas bold separadas por parágrafo no PDF original deve reproduzir o mesmo bug. Não medido quantas NRs são afetadas | — |
| O texto corrido (`nr-04.md:41-42`, fora da estrutura de heading) já está correto | `"Anexo I - Relação da Classificação Nacional de Atividades Econômicas - CNAE (Versão 2.0), com correspondente Grau de Risco - GR"` lê normalmente no corpo do Markdown — o bug é só na extração de heading/índice (`structure.json`), não no texto normativo em si | `content/nr-04/nr-04.md:41-42` |

### 3. NR-4 — Anexo I sem cabeçalho a partir da 2ª página

| Achado | Detalhe | Evidência |
|---|---|---|
| Tabela cobre ~26 páginas do PDF, uma imagem PNG por página | `page-006-table-00.png` até pelo menos `page-031-table-00.png`, inseridas sequencialmente no `.md` (decisão já implementada em `imagens-pagina-posicionamento`) | `content/nr-04/nr-04.md:299-...`, `content/nr-04/assets/pages/` |
| Verificado visualmente nesta sessão | `page-006` tem cabeçalho completo (`Códigos \| Denominação \| GR`); `page-007` (e presumivelmente as seguintes) **não tem nenhuma linha de cabeçalho** — só continua as linhas de dado (`02.10-1 ...`) | Leitura direta das duas imagens PNG nesta sessão |
| **Não é coluna faltando** — é cabeçalho ausente | As 3 colunas (código, descrição, GR) estão presentes e completas em `page-007`; a impressão de "faltar coluna" do usuário é o efeito de não ter rótulo nenhum pra saber o que cada coluna significa, não um corte real de dado. Isso é fiel ao PDF original: a maioria dos PDFs não repete cabeçalho de tabela em toda página de continuação | Leitura direta das imagens |
| Implicação pra sugestão do usuário ("pegar página inteira") | Renderizar a página inteira (em vez de bbox recortado) **não resolve** a ausência de cabeçalho — o cabeçalho simplesmente não existe nas páginas 7+ do PDF fonte. Só ajudaria se o bbox atual estivesse cortando conteúdo real existente na página (não confirmado — não visto nas duas páginas inspecionadas) | Raciocínio a partir do achado acima |
| Pista não explorada, potencialmente melhor que qualquer variante de imagem | O conteúdo da tabela é texto simples e bem estruturado em 3 colunas (visível claramente no PNG) — bom candidato a virar Markdown de tabela nativo (pesquisável, acessível, sem problema de cabeçalho por página) em vez de PNG. Não investigado por que essa tabela caiu no fallback de imagem em vez do Pass 1/2 (`extract_tables_pass`/`pymupdf4llm`) — pode ser heurística de "ilegível" disparando por um motivo que não se aplica aqui (tabela grande demais? muitas páginas?) | Requer exploração adicional em `scripts/convert_nr.py` |

## Fidelidade de conteúdo

- Nenhuma correção aqui reescreve texto normativo — todas mexem em como o mesmo PDF é extraído/estruturado (merge de heading, formato de tabela), igual ao precedente já aceito em `tabelas-inline-md` e `imagens-pagina-posicionamento`.
- Reconverter não muda `pdf_hash` (mesmo PDF) — e como descrito acima, isso é irrelevante pra propagação: o que importa pro app é o hash do `.md`/estrutura gerada, que muda normalmente ao reconverter.

## Backlog de ajustes de UX — tela de Atualizações (capturado nesta sessão, para fazer depois)

Não mapeado com as 4 perspectivas completas item a item (são ajustes pequenos e contidos); registrado com arquivo exato pra ir direto a `/fazer` quando priorizado.

| # | Pedido do usuário | Arquivo(s) | Observação técnica |
|---|---|---|---|
| 1 | Texto "Página X (tabelas)" ao tocar — remover o "(tabelas)" | Não localizado o texto exato nesta sessão (grep por `"(tabelas)"` não encontrou string literal) — precisa achar o `Text`/snackbar exato antes de mexer | — |
| 2 | Ícone de notificação (sino) sem contraste no número do contador | `app/lib/core/widgets/update_count_badge.dart:26,34` — texto usa `semantics.onWarningContainer` (cor pensada pra fundo "container", claro) sobre fundo `semantics.warning` (cor sólida) → mismatch de contraste, mais visível no tema claro | Confirmado lendo o código: par de cores errado (`onWarningContainer` não é o par de `warning`, é o par de `warningContainer`) |
| 3 | Remover a tag "Atualizada" do app bar do leitor (ficou cortada/feia) | `app/lib/features/reader/views/widgets/reader_app_bar.dart:58-61` (`NrBadge(variant: .update, compact: true)` dentro do `Row` do título, ao lado do nome já elidido) | Fluxo de `hasPendingUpdate` vem de `nr_reader_controller`/`nr_reader_page` — remover o badge não deve exigir tocar no controller, só a `ReaderAppBar` (o parâmetro pode ficar sem uso ou ser removido em cascata) |
| 4 | Dentro da NR, o "antes/depois" de atualização pendente não aparece completo | Provável painel compacto aberto a partir do leitor (`update_banner.dart` ou bottom sheet) — não localizado o widget exato que trunca; precisa mapear qual componente é aberto a partir de "ver atualizações pendentes" dentro do leitor | Precisa mais exploração antes de decidir o fix |
| 5 | Cores das notificações (ícone + contador) ruins no tema claro | Mesma raiz do item 2 (`update_count_badge.dart`) — mas usuário também menciona "ícone", então checar também a cor do `Icons.notifications`/`notifications_outlined` em `home_page.dart:153-154` | — |
| 6 | Card "atualizações pendentes" na home é redundante (duplica a tela de Atualizações) | `app/lib/features/home/views/widgets/pending_updates_section.dart` (`PendingUpdatesSection`, "Card compacto de atualizações pendentes na home") | Usuário prefere manter só a tela de Atualizações — remover o card, não a tela |
| 7 | Card "N atualizações pendentes" dentro da própria tela de Atualizações também é redundante | `app/lib/features/updates/views/widgets/updates_summary_header.dart` (`UpdatesSummaryHeader`) | A lista de itens abaixo já mostra a mesma informação |
| 8 | Antes/depois com mais de 4 linhas fica ilegível — não faz sentido mostrar tudo | `app/lib/features/updates/views/widgets/update_items_list.dart:120-144` + `app/lib/features/updates/utils/update_item_display.dart` (`fullTextBullets` retorna o texto inteiro como um único bloco, sem limite) | Tensão com o item 4 (usuário quer ver "completo" dentro do leitor, mas "não completo" quando >4 linhas na tela cheia) — provavelmente pede um "ver mais/menos" em vez de sempre-truncado ou sempre-completo; decisão de UX, não só código |
| 9 | Poder minimizar/expandir cada NR atualizada na tela de Atualizações (abrir tudo minimizado por padrão) | `app/lib/features/updates/views/widgets/update_entry_card.dart` — hoje não tem nenhum estado de expansão (`ExpansionTile`/`isExpanded` não encontrado no arquivo) | Precisa de estado (controller ou local `StatefulWidget`) — não é só estilo, é comportamento novo |
| 10 | Poder apagar/dispensar uma atualização já vista (aviso deve sumir) | Não existe hoje nenhum mecanismo de dismiss/delete em `app/lib/features/updates/` (grep por dismiss/delete/remover/descartar/ignorar não achou nada) | Requer decidir onde persistir "dispensado" (GetStorage local, por `nr_id` + hash da entrada?) — toca modelo de dados, não só UI |
| 11 | Detectar se a mudança é "real" (palavras/frases) ou só caracteres/espaços, pra não notificar por ruído de re-extração | `scripts/summarize_changes.py::parse_items()` já normaliza espaços/quebras de linha (reflow do PDF), mas **não** filtra diferenças de baixo nível tipo pontuação/hífen inserido pela extração | Achado concreto no próprio `app_meta.json`: entrada de nr-28 com `"resumo": "...1331400... → ...133140- 0..."` — um hífen+espaço que apareceu no meio de um número por artefato de re-extração, marcado como "item alterado" (ruído, não mudança normativa) — exatamente o caso que o usuário quer filtrar |

## todo.md

- [ ] Nova demanda / refinamento — item 17 ("Histórico + card Continuar leitura" / "Tela Atualizações") e item 21/23b (pipeline automático) já estão `[x]`, mas nenhum desses itens de propagação-por-código ou o backlog de UX do sino estão descritos lá. Nada aqui reabre uma decisão registrada em "Decisões registradas (não reabrir)".

## Decisões já resolvidas com o usuário nesta sessão

| Pergunta | Opção escolhida | Por quê |
|----------|------------------|---------|
| Vale automatizar a reconversão quando só o código de extração muda (PDF idêntico)? | **Versionar o pipeline (`PIPELINE_VERSION`)** — constante de versão do extrator salva em `meta.json`; `update_nrs.py` reconverte quando `pdf_hash` OU `pipeline_version` mudar | Resposta do usuário via `AskUserQuestion` — resolve de forma duradoura em vez de depender de lembrar de rodar `--all` manualmente a cada mudança de extração |
| O feed de atualizações (sino) deve notificar correções de pipeline sem mudança normativa? | **Manter silencioso** — correção de extração não gera entrada no sino/histórico; o dispositivo resincroniza sozinho (via `manifest.json`), e o feed fica reservado pra mudanças normativas reais | Resposta do usuário via `AskUserQuestion` — confirma o comportamento já observado no commit da NR-28 (app_meta.json não regenerado) como correto, não como bug |

## Lacunas ainda abertas

### D3 — Merge de heading quebrado em duas linhas bold *(bloqueia: Sim, para a correção da NR-4)*

**Dúvida?**
`build_structure.py::parse_bold_major_section_line()` trata toda linha 100%-bold como candidata a heading nova, sem checar se ela é continuação de um heading anterior (ex.: começa com fechamento de parênteses/minúscula em vez de início de frase/maiúscula). Precisa de mais exploração pra saber quantas NRs além da NR-4 têm esse padrão de heading quebrado em duas linhas, e qual heurística de "é continuação" é segura sem quebrar headings legítimos que começam com minúscula por outro motivo.

**Opções**
*(não formuladas ainda — precisa levantar quantas NRs são afetadas antes de desenhar a heurística)*

**Resposta:**

### D4 — Direção para tabelas multi-página sem cabeçalho repetido (Anexo I e similares) *(bloqueia: Sim, para a correção do Anexo I)*

**Dúvida?**
Confirmado que o cabeçalho realmente não existe nas páginas 7+ do PDF, e que os dados/colunas parecem completos (não é bug de recorte). Precisa decidir a direção antes de formular opções fechadas: (a) investigar se essa tabela deveria ter ido para Markdown nativo (Pass 1/2) em vez de PNG — por que caiu no fallback de imagem; (b) se PNG for mantido, se vale a pena repetir o cabeçalho em cada imagem de continuação (custo de implementação); (c) se vale a pena, como sugerido pelo usuário, revisar página inteira vs bbox — mas isso sozinho não resolve o cabeçalho ausente.

**Opções**
*(não formuladas ainda — depende de descobrir por que a tabela foi para o fallback de PNG antes de decidir entre "virar Markdown" vs "repetir cabeçalho no PNG" vs "página inteira")*

**Resposta:**

### D5 — Onde persistir "atualização dispensada" (item 10 do backlog de UX) *(bloqueia: Não — só a implementação futura desse item específico)*

**Dúvida?**
Ao dispensar/apagar uma atualização já vista na tela de Atualizações, onde isso deve ser guardado (só local via `GetStorage`, chaveado por `nr_id` + hash da entrada) e isso deve interagir com `last_seen_hash` (que já existe) ou ser um estado novo e independente?

**Opções**
*(não formuladas ainda — depende de olhar `StorageKeys`/`content_service.dart` mais de perto antes de decidir se reaproveita `last_seen_hash` ou cria uma chave nova)*

**Resposta:**
