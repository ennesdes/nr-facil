# Descoberta — Melhorar UX/UI do feed de atualizações de NR

> Gerado por `/descobrir` · Consumido por `/decidir`

## Demanda
Melhorar, de ponta a ponta, como uma NR atualizada é **gerada** (pipeline Python) e **mostrada** ao usuário final (app Flutter) — hoje a "última milha" dessa feature está incompleta: os dados chegam pobres/com bug ao `app_meta.json`, e o app nem sequer lê esse arquivo.

## Perspectiva do usuário
- O único sinal visível de "esta NR mudou" hoje é um emoji 🆕 ao lado do título, em Favoritos/Todos/Atualizações — sem data, sem motivo, sem o que mudou.
- A tela de Atualizações (atrás do sino) lista só o título da NR; não mostra data, portaria, nem resumo — mesmo a documentação do projeto (`docs/architecture.md:135`) já prevendo isso.
- Abrir a NR (pela lista ou pelo botão) marca a NR como "vista" *antes* do usuário efetivamente ler qualquer coisa — o badge 🆕 já some das listas nesse momento, sem o usuário ter tido a chance de saber o que mudou.
- Dentro do próprio leitor, nada indica que aquele conteúdo foi atualizado — o usuário não tem como saber, lendo a NR, que está diante de uma versão nova.
- Isso é especialmente crítico porque "avisar sobre mudanças normativas" é a proposta de valor central do produto (ver memória `project_motivation`), e hoje essa proposta não se sustenta na prática — o feed existe teoricamente (`app_meta.json` é gerado) mas nunca chega ao usuário.

## Perspectiva do produto
- Fase 4 (feed de atualizações sem backend) está tecnicamente pendurada: item 27 (gerar `app_meta.json`) está feito, mas itens 28 (app lê `updates[]`) e 30 (checar `min_app_version`) nunca foram implementados — **zero referências a `app_meta`/`appMeta` em `app/lib`**.
- Há um gap de "descreve vs implementa": `docs/architecture.md` já documenta a UX pretendida (NR, data, portaria, resumo 1 linha, botão Abrir, link "Ver versão anterior") e até um formato de resumo ("Seções alteradas: 6.3, 6.9") que **não bate com o código real** de `build_app_meta.py` (gera só "Atualizado em {data}").
- O pipeline já produz um diff granular e de boa qualidade (`summarize_changes.py`, item novo/removido/alterado por seção) — mas ele é usado *apenas* para consumo interno (changelog do repo + resumo da GitHub Action), nunca chega ao `app_meta.json` nem ao usuário final. É capacidade real, já construída, sendo desperdiçada do ponto de vista de produto.
- Decisão desta sessão: conectar esse diff granular ao feed do app (não só o resumo genérico) — isso expande o escopo original do item 28 (que só previa "ler `updates[]`", sem especificar granularidade).
- Adicionar um banner no leitor é uma superfície de UI nova, fora do escopo original documentado da Fase 4 (que só previa sino + badge) — decisão já tomada nesta sessão.

## Perspectiva técnica

| Arquivo | O que muda | Por quê | Risco |
|---|---|---|---|
| `scripts/build_app_meta.py` (`generate_summary`, L45-53) | Corrigir bug de `f"Atualizado em {new_entry.get('vigente_desde', '?')}"` que imprime literalmente `"None"` quando o valor existe mas é `null` (o `.get(..., '?')` só cobre chave ausente, não valor `None`); e substituir o resumo genérico por dado granular vindo de `summarize_changes.py` | Corrige bug visível ao usuário e implementa a decisão de "resumo granular por item" | médio |
| `scripts/summarize_changes.py` | Precisa ser reutilizado/chamado por `build_app_meta.py` (hoje são duas etapas independentes do workflow, cada uma comparando refs à sua maneira) | Fonte da informação granular que vai para o `app_meta.json` | médio — muda acoplamento entre dois scripts hoje independentes |
| `scripts/scrape_vigencia.py:109` (`meta["portaria"] = text[:150]`) | Corrigir truncamento no meio da palavra (ex.: "de 2024aperfeiçoou") — cortar em limite de palavra ou não usar esse fallback bruto no texto exibido ao usuário | Texto ilegível hoje aparece direto no `app_meta.json`/manifest | baixo |
| `app_meta.json` (schema) | Schema de cada entrada de `updates[]` muda — hoje `{nr_id,title,portaria,pdf_hash,summary,created_at}`; resumo granular provavelmente exige campo estruturado (ex. lista de itens alterados) | Suportar exibição item a item no app | médio — contrato de dado consumido pelo Dart muda, e precisa continuar respeitando a janela de 200 entradas e a regra de não guardar markdown/PDF completo |
| `app/lib/core/constants/app_config.dart` | Adicionar `appMetaUrl` (hoje só existe `manifestUrl`) | Pré-requisito para o app buscar o feed | baixo |
| `app/lib/core/models/` | Criar modelo Dart para `AppMeta`/`UpdateEntry` — hoje não existe nenhum | Nenhum modelo reflete o schema de `app_meta.json` | baixo |
| `app/lib/core/services/content_service.dart` | Buscar `app_meta.json` via GitHub raw, expor `updates[]` observável, comparar `min_app_version` do app instalado | Implementa itens 28 e 30 do todo.md, hoje inexistentes | médio |
| `app/lib/features/updates/views/updates_page.dart` + `updates_controller.dart` | Redesenhar lista para mostrar data/portaria/resumo granular (não só título + badge 🆕 como hoje) | UX pretendida pela doc + decisão de resumo granular | médio |
| Fluxo do leitor (`app/lib/features/reader/...`, `NRReaderController.onInit` L67-85) | Adicionar banner "NR atualizada" quando `hasUpdate == true`, e possivelmente adiar `markNrAsSeen` para depois do usuário ver/dispensar o banner (hoje é chamado assim que o conteúdo carrega, antes de qualquer leitura) | Decisão desta sessão — dar visibilidade dentro do próprio contexto de leitura | médio — muda timing de quando a NR é marcada como "vista" |
| Duas fontes de "mudou" desalinhadas: `build_app_meta.py` usa `pdf_hash`; o app (`ContentService.hasUpdate`) usa `hash` (md) | Precisa reconciliar antes de expor detalhe granular, senão a tela de Atualizações pode listar algo que o app não detecta como pendente de sync (ou vice-versa) | Risco de inconsistência entre o que é anunciado e o que de fato está disponível/sincronizado | alto |

## Fidelidade de conteúdo
- O resumo granular usa `summarize_changes.py`, que já é puramente determinístico (regex/diff textual, sem IA, sem reescrever texto normativo) — consistente com a regra do `CLAUDE.md`/`scripts/README.md` ("nunca reescrever conteúdo normativo"). Ele só aponta *quais* itens mudaram, não reescreve o texto.
- A opção de "diff completo no app" (texto antes/depois) foi **descartada nesta sessão** — reduz o risco de mostrar trecho antigo fora de contexto normativo sem cuidado editorial.
- Atenção ao desalinhamento `pdf_hash` vs `hash`(md): se o resumo granular for gerado a partir de uma comparação que não corresponde exatamente ao conteúdo que o app baixou, o app pode anunciar mudança em itens que ainda não estão no `.md` sincronizado localmente — checar isso é pré-requisito antes de expor o detalhe ao usuário (ver lacuna D1).

## Decisões já resolvidas com o usuário nesta sessão

| Pergunta | Opção escolhida | Por quê |
|---|---|---|
| Nível de detalhe do "o que mudou" mostrado ao usuário | **Resumo granular por item** | Conectar `summarize_changes.py` (já gera diff item a item, hoje só usado no changelog interno/Action summary) ao `app_meta.json`, em vez do resumo genérico atual ("Atualizado em {data}") |
| Indicação de atualização dentro do leitor | **Adicionar banner no leitor** | Hoje nada avisa dentro do leitor que o conteúdo mudou — usuário só vê pelo badge nas listas, que some assim que ele abre a NR |

## todo.md
- [ ] Parcialmente previsto — Fase 4 (itens 28 e 30) já previa app consumir `app_meta.json`/`updates[]` e checar `min_app_version`, mas não previa nível granular de detalhe (só resumo genérico) nem banner no leitor — ambos são extensões de escopo decididas nesta sessão.
- Linhas relevantes: `- [ ] 28 App busca app_meta.json via GitHub raw e lê updates[] no startup`; `- [ ] 30 Check min_app_version no startup (aviso de update obrigatório)`

## Lacunas ainda abertas

| ID | Pergunta | Bloqueia |
|----|----------|----------|
| D1 | Como reconciliar `pdf_hash` (usado por `build_app_meta.py` para decidir se uma NR "mudou") vs `hash`/md (usado pelo app em `ContentService.hasUpdate`) como fonte única de verdade — antes de expor detalhe granular ao usuário? | Sim — risco de a tela de Atualizações anunciar algo que o app ainda não detecta/sincronizou |
| D2 | Como `summarize_changes.py` (hoje roda 1x por execução do workflow, comparando HEAD vs working tree) deve ser reaproveitado por `build_app_meta.py` (etapa separada, roda depois) — chamar a mesma função por NR, extrair lógica compartilhada, ou outro desenho? | Sim — define o design técnico que o `/plano` vai detalhar entre os dois scripts |
| D3 | Formato exato do banner no leitor — só informativo/passivo, ou com ação (ex.: botão "Ver o que mudou" que expande a lista granular)? Comportamento de dispensa (some ao fechar? reaparece se reabrir?) | Não — é decisão de UI que pode ser resolvida em `/decidir` com opções/mockup, não bloqueia o mapeamento |
| D4 | Schema exato de `app_meta.json` após incluir detalhe granular — mantém `summary` como string única concatenada (ex. "Itens alterados: 6.3, 6.9"), ou vira lista estruturada (`items: [{secao, tipo, trecho}]`)? Afeta tamanho do arquivo (janela de 200 entradas) e o parsing no Dart | Sim — precisa ser decidido antes do `/plano` desenhar os dois lados (Python + Dart) em conjunto |
