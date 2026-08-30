# Plano — Feed de atualizações de NR: dados corretos + granulares, ponta a ponta

> **Descoberta:** `.claude/discoveries/feed-atualizacoes-ux.md`
> **Decisão:** `.claude/decisions/feed-atualizacoes-ux.md`

## O que será feito e por quê
> Leitura de 30 segundos — direção antes dos detalhes.

- **Corrigir a geração de dados no pipeline** — `build_app_meta.py` hoje produz texto quebrado ("Atualizado em None") e portaria truncada no meio da palavra; passa a comparar por `hash` (md), não `pdf_hash`, e a reaproveitar o diff granular já existente em `summarize_changes.py`
- **Fazer o app finalmente ler `app_meta.json`** — item 28/30 do todo.md nunca foram implementados; hoje toda a UI de "atualização" é alimentada só pelo `manifest.json` + hash local
- **Checar `min_app_version` no startup** — aviso obrigatório de update quando a versão instalada estiver abaixo do mínimo (item 30, nunca implementado)
- **Redesenhar a tela de Atualizações** — hoje mostra só título; passa a mostrar data, portaria e a lista granular de itens alterados
- **Adicionar banner no leitor** — avisa quando a NR aberta foi atualizada, com CTA "Ver o que mudou" que expande os itens, e adia `markNrAsSeen` para depois dessa interação

## Escopo
- Pipeline: `scripts/build_app_meta.py`, `scripts/scrape_vigencia.py`
- Schema: `app_meta.json` ganha `items[]` estruturado por entrada de `updates[]`
- App: modelo de dados novo (`AppMeta`/`UpdateEntry`/`UpdateItem`), `ContentService` (fetch + parsing + check de versão), tela de Atualizações, fluxo do leitor (banner + CTA)

## Fora de escopo
- Não implementar diff textual completo (antes/depois) nem o link "Ver versão anterior" (commit GitHub) — descartado no `/descobrir`, é feature Premium pós-MVP (`docs/architecture.md:137`)
- Não mexer na tela de detalhe de NR revogada (TODO explícito no código, item 16 do todo.md — tangencial a esta demanda)
- Não adicionar o ícone "Ajustes" na app bar (mencionado em `docs/architecture.md:150` mas não implementado — fora do escopo desta demanda)
- Não alterar as chaves de storage `nrLastSyncedHash`/`nrLastSeenHash` nem a lógica de sync incremental do `manifest.json` — só o *timing* de `markNrAsSeen` no leitor muda
- Não reescrever texto normativo — o diff granular usado (`summarize_md`) já é puramente determinístico (regex/diff), sem IA

## Impacto estimado

### App Flutter
- 5 arquivos alterados, 3 arquivos novos (modelo + 2 widgets), 1 dependência nova (`package_info_plus`)

### Pipeline Python
- 2 scripts alterados (`build_app_meta.py`, `scrape_vigencia.py`)

### app_meta.json / manifest
- Schema de cada entrada em `updates[]` ganha `items: [{item, tipo, resumo}]` (mesmo teto de 30 itens por NR que `summarize_changes.py` já aplica); `summary` passa a ser um resumo curto derivado (nunca mais string com "None" literal)

### Testes
- 4 cenários no pipeline (Fase 1) + ~8 cenários no app (Fases 2–5), detalhados por fase abaixo

## Referências

| Arquivo | Seções utilizadas |
|---------|-------------------|
| `docs/architecture.md` | § "app_meta.json (sem backend)" (L116-143), § "App Flutter" / "Detecção de atualização" (L145-173) |
| `docs/prompts.md` | I8 — app_meta.json no app (Fase 4, itens 28/30) |
| `todo.md` | Itens 28 e 30 (Fase 4) |
| `.claude/discoveries/feed-atualizacoes-ux.md` | Perspectiva técnica (mapa completo de arquivos hoje envolvidos) |
| `.claude/decisions/feed-atualizacoes-ux.md` | D1–D4 |

## Decisões tomadas

| Decisão | Escolha | Fundamento |
|---------|---------|------------|
| D1 — fonte de "mudou" | `build_app_meta.py` compara `hash` (md), não `pdf_hash` | Escolha do usuário via `/decidir` — alinha com `ContentService.hasUpdate` já em produção |
| D2 — reuso do diff granular | Importar `summarize_md()` de `summarize_changes.py` direto | Escolha do usuário via `/decidir` — reaproveita lógica já testada, sem reordenar o workflow |
| D3 — formato do banner no leitor | Banner com CTA "Ver o que mudou" (expande itens) | Escolha do usuário via `/decidir` |
| D4 — schema do resumo granular | `items: [{item, tipo, resumo}]` estruturado por entrada | Escolha do usuário via `/decidir` |
| Leitura da versão instalada do app | Adicionar `package_info_plus` como dependência | Única opção tecnicamente viável e leve para ler a versão do app em runtime sem hardcode duplicado (pubspec.yaml só define a versão do build, não é lido em runtime); pacote padrão do ecossistema Flutter, sem setup nativo — não é o tipo de "SDK novo" que `docs/prompts.md#i8` desaconselha (essa ressalva é sobre serviços/backends, não sobre leitura de metadado local do app) |
| Campo `summary` após adicionar `items[]` | Vira resumo curto derivado (ex.: contagem de itens ou primeiro item), nunca mais referencia campos que podem ser `None` | Consequência direta de D4 — elimina o bug "Atualizado em None" sem precisar de decisão nova, já que a causa raiz (`new_entry.get('vigente_desde', '?')` não cobre valor `None`) precisa ser corrigida de qualquer forma |

## Decisões abertas

*(nenhuma — plano pronto para /fazer)*

## Riscos

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| `summarize_md()` espera texto antigo via `git_show(ref, path)` — em runners onde `build_app_meta.py` roda fora de um checkout git completo, a chamada falha | Médio | Fase 1: tratar `git_show` retornando erro/None como "sem diff granular disponível" e cair para o resumo curto, sem quebrar a geração do `app_meta.json` |
| Mudar `build_app_meta.py` de `pdf_hash` para `hash` pode gerar uma leva grande de entradas "novas" na primeira execução pós-deploy (todas as NRs cujo `hash` já mudou historicamente mas nunca foi comparado por esse critério) | Baixo | Fase 1: rodar `--dry-run` localmente antes do merge e revisar o diff de `app_meta.json` gerado; se a leva for grande, é aceitável (janela de 200 entradas absorve) |
| Adicionar banner no leitor + adiar `markNrAsSeen` pode deixar o badge 🆕 "preso" se o usuário nunca interagir com o banner | Médio | Fase 5: `markNrAsSeen` dispara ao dispensar o banner (X) **ou** ao abrir o CTA — qualquer uma das duas interações resolve, cobrindo o caminho feliz sem exigir ação extra do usuário |
| Nova dependência `package_info_plus` | Baixo | Pacote estável, mantido pelo time Flutter community (`flutter.dev/packages`), sem configuração nativa adicional |

## Dependências entre fases

Fase 2 depende de:
- Fase 1 concluída — schema de `app_meta.json` (`items[]`) estável antes de escrever o modelo Dart

Fase 3 depende de:
- Fase 2 concluída — precisa de `ContentService` já expondo `min_app_version`

Fase 4 depende de:
- Fase 2 concluída — precisa do modelo `UpdateEntry`/`UpdateItem` e de `ContentService.updates`

Fase 5 depende de:
- Fase 2 concluída — precisa do modelo/dados
- Fase 4 concluída — reaproveita o widget de lista de itens granulares criado ali

---

## Detalhamento

### Fase 1 — Pipeline: dados corretos e granulares
**Objetivo:** `build_app_meta.py` gera entradas de `updates[]` sem bugs de texto, comparando por `hash` (md) e incluindo `items[]` granulares reaproveitados de `summarize_changes.py`.
**Arquivos:** `scripts/build_app_meta.py`, `scripts/scrape_vigencia.py`
**Agente sugerido:** `python-pipeline`
**Depende de:** nenhuma

#### Passos
1. `scripts/build_app_meta.py` — trocar a chave usada em `last_hash_by_nr`/comparação de mudança de `pdf_hash` para `hash` (a lógica de `old_hash == new_hash` em `build_app_meta()` passa a ler `u.get("hash")` das entradas anteriores e `nr.get("hash")` do manifest atual)
2. `scripts/build_app_meta.py` — importar `summarize_md` (e o necessário para obter texto antigo, ex. `git_show`) de `summarize_changes.py`; quando uma NR mudou, chamar `summarize_md(nr_id, old_text, new_text)` lendo `old_text` via `git_show("HEAD", f"content/{nr_id}/{nr_id}.md")` e `new_text` do arquivo atual em disco — se `git_show` falhar (ex. arquivo novo, sem histórico), tratar como "sem diff disponível" e seguir com `items=[]`
3. `scripts/build_app_meta.py` — mapear a lista de strings retornada por `summarize_md` para o schema `items: [{item, tipo, resumo}]` (extrair `item`/`tipo` dos marcadores 🆕/❌/✏️ já usados por `summarize_changes.py`)
4. `scripts/build_app_meta.py` (`generate_summary`) — corrigir o bug de `None`: nunca interpolar um valor que pode ser `None` diretamente na f-string; se não houver `items[]`, gerar um resumo curto sem depender de `vigente_desde` (ex.: `"Atualização disponível"` genérico, ou contagem de itens quando houver: `f"{len(items)} itens alterados"`)
5. `scripts/scrape_vigencia.py:109` — corrigir o fallback `text[:150]` para não truncar no meio da palavra (cortar no último espaço antes do limite, ou reduzir o limite com reticências apropriadas)
6. Criar `scripts/test_build_app_meta.py` seguindo o padrão de `scripts/test_convert_nr.py` (unittest, funções puras testáveis sem rede/git real — usar fixtures/mocks para `git_show`)

#### Testes desta fase
- Caminho feliz: NR com `hash` diferente do anterior e `summarize_md` retornando itens → entrada gerada com `items[]` populado e `summary` curto e coerente
- Falha: `vigente_desde`/`publicado_em` ausentes ou `None` → `summary` nunca contém a string literal `"None"`
- Edge: NR sem entrada anterior (primeira versão) → não chama `summarize_md` (não há `old_text`), usa o resumo de "Primeira versão" existente
- Edge: portaria com texto de fallback maior que o limite → corta em limite de palavra, sem palavras coladas

---

### Fase 2 — App: modelo de dados + fetch de `app_meta.json`
**Objetivo:** `ContentService` busca `app_meta.json` via GitHub raw, expõe `updates[]`/`items[]` tipados e o `min_app_version`, sem quebrar o fluxo de sync existente do `manifest.json`.
**Arquivos:** `app/lib/core/constants/app_config.dart`, `app/lib/core/models/app_meta.dart` (novo), `app/lib/core/services/content_service.dart`, `app/pubspec.yaml`
**Agente sugerido:** `flutter-senior`
**Depende de:** Fase 1 (schema de `items[]` estável)

#### Passos
1. `app/pubspec.yaml` — adicionar `package_info_plus` às dependências
2. `app/lib/core/constants/app_config.dart` — adicionar `appMetaUrl` (mesmo padrão de `manifestUrl`, apontando pra `app_meta.json` na raiz do repo via GitHub raw)
3. `app/lib/core/models/app_meta.dart` (novo) — modelos `AppMeta` (`generatedAt`, `minAppVersion`, `updates: List<UpdateEntry>`), `UpdateEntry` (`nrId`, `title`, `portaria`, `pdfHash`, `summary`, `items: List<UpdateItem>`, `createdAt`), `UpdateItem` (`item`, `tipo`, `resumo`) — com `fromJson` tolerante a `items` ausente/vazio (entradas legadas antes da Fase 1)
4. `app/lib/core/services/content_service.dart` — novo método `_downloadAppMeta()` (mesmo padrão de `_downloadManifest()`), chamado dentro de `sync()`; expor `appMeta` (Rx) e um getter `updatesForNr(String nrId)` retornando as entradas relevantes; falha ao buscar `app_meta.json` não deve interromper o sync do `manifest.json` (fail-soft, como já é o padrão de erro do serviço)
5. `app/lib/core/services/content_service.dart` — expor `bool get forcedUpdateRequired` comparando a versão instalada (via `PackageInfo.fromPlatform()`) com `appMeta.value?.minAppVersion` (comparação semver simples: major.minor.patch)

#### Testes desta fase
- Caminho feliz: `app_meta.json` mockado com `items[]` → `ContentService.appMeta` expõe os dados tipados corretamente
- Falha: `app_meta.json` inacessível/404 (offline) → `sync()` do manifest continua funcionando normalmente, `appMeta` permanece `null`/anterior
- Edge: entrada de `updates[]` sem `items[]` (schema legado) → parsing não quebra, `items` vira lista vazia
- Edge: `min_app_version` igual ou menor que a versão instalada → `forcedUpdateRequired == false`

---

### Fase 3 — App: aviso obrigatório de versão mínima
**Objetivo:** app mostra um diálogo bloqueante no startup quando a versão instalada estiver abaixo de `min_app_version`.
**Arquivos:** `app/lib/features/home/controllers/home_controller.dart`, `app/lib/features/home/views/widgets/forced_update_dialog.dart` (novo)
**Agente sugerido:** `flutter-senior`
**Depende de:** Fase 2

#### Passos
1. `app/lib/features/home/views/widgets/forced_update_dialog.dart` (novo) — `AlertDialog` não dispensável (sem botão de fechar/back), texto explicando que uma atualização é obrigatória, botão único levando à Play Store (link) — reaproveitar o texto/estilo do aviso legal já existente no leitor como referência de tom
2. `app/lib/features/home/controllers/home_controller.dart` — no `onInit()`, após `_contentService.sync()` (que agora também busca `app_meta.json`), checar `_contentService.forcedUpdateRequired` e, se `true`, exibir `ForcedUpdateDialog` via `Get.dialog(barrierDismissible: false)`

#### Testes desta fase
- Caminho feliz: `min_app_version` acima da versão instalada → diálogo aparece e bloqueia navegação (barrier não dispensável)
- Edge: `min_app_version` igual/abaixo da versão instalada → diálogo não aparece

---

### Fase 4 — Tela de Atualizações: exibir dados granulares
**Objetivo:** `UpdatesPage` mostra data, portaria e a lista de itens alterados de cada NR atualizada, usando os dados de `app_meta.json` (Fase 2), não só o título.
**Arquivos:** `app/lib/features/updates/views/updates_page.dart`, `app/lib/features/updates/controllers/updates_controller.dart`, `app/lib/features/updates/views/widgets/update_items_list.dart` (novo)
**Agente sugerido:** `flutter-senior`
**Depende de:** Fase 2

#### Passos
1. `app/lib/features/updates/views/widgets/update_items_list.dart` (novo) — widget que renderiza uma `List<UpdateItem>` como linhas com ícone por tipo (🆕/❌/✏️) + texto do item + resumo; usado tanto aqui quanto na Fase 5 (bottom sheet do leitor)
2. `app/lib/features/updates/controllers/updates_controller.dart` — expor, por NR da lista `updatedNrs`, a `UpdateEntry` correspondente vinda de `ContentService.updatesForNr(nrId)` (join entre o `manifest.value!.nrs` filtrado e o feed do `app_meta.json`)
3. `app/lib/features/updates/views/updates_page.dart` — cada item da lista passa a mostrar, abaixo do título: data (`createdAt`/`vigente_desde` formatada), portaria (já corrigida na Fase 1) e o `UpdateItemsList` com os itens granulares (quando existirem); entradas sem correspondência em `app_meta.json` (fallback) continuam mostrando só o título + badge 🆕, como hoje

#### Testes desta fase
- Caminho feliz: NR atualizada com `items[]` no `app_meta.json` → tela mostra data, portaria e itens
- Edge: NR com `hasUpdate == true` mas sem entrada correspondente em `app_meta.json` (nunca sincronizado o feed) → cai no fallback atual (só título + badge), sem erro
- Edge: `items[]` vazio mas `summary` presente → mostra o resumo curto no lugar da lista

---

### Fase 5 — Leitor: banner de atualização com CTA
**Objetivo:** ao abrir uma NR com `hasUpdate == true`, o leitor mostra um banner dispensável com CTA "Ver o que mudou" (abre bottom sheet reaproveitando `UpdateItemsList` da Fase 4); `markNrAsSeen` só é chamado ao dispensar o banner ou ao abrir o CTA — não mais imediatamente ao carregar o conteúdo.
**Arquivos:** `app/lib/features/reader/controllers/nr_reader_controller.dart`, `app/lib/features/reader/views/nr_reader_page.dart`, `app/lib/features/reader/views/widgets/update_banner.dart` (novo)
**Agente sugerido:** `flutter-senior`
**Depende de:** Fase 2, Fase 4 (reaproveita `UpdateItemsList`)

#### Passos
1. `app/lib/features/reader/controllers/nr_reader_controller.dart` (`onInit`, L67-85) — remover a chamada automática de `_contentService.markNrAsSeen(nrId)` logo após carregar o conteúdo; guardar se a NR tinha `hasUpdate == true` no momento da abertura (capturado antes de qualquer chamada a `markNrAsSeen`, já que essa própria chamada muda o resultado de `hasUpdate`); expor esse estado (`showUpdateBanner`) e um método `dismissUpdateBanner()` que chama `markNrAsSeen` nesse momento
2. `app/lib/features/reader/views/widgets/update_banner.dart` (novo) — banner dispensável (ícone X) com texto curto + botão "Ver o que mudou"; botão abre um `showModalBottomSheet` com `UpdateItemsList` (reaproveitado da Fase 4) usando a `UpdateEntry` da NR atual; tanto dispensar quanto abrir o CTA chamam `dismissUpdateBanner()`
3. `app/lib/features/reader/views/nr_reader_page.dart` — renderizar `UpdateBanner` no topo do corpo quando `controller.showUpdateBanner.value == true`

#### Testes desta fase
- Caminho feliz: abrir NR com `hasUpdate == true` → banner aparece; tocar "Ver o que mudou" → bottom sheet com itens; banner some e `markNrAsSeen` é chamado
- Caminho feliz alternativo: dispensar o banner (X) sem abrir o CTA → banner some e `markNrAsSeen` também é chamado
- Edge: abrir NR sem atualização (`hasUpdate == false`) → banner nunca aparece, comportamento idêntico ao atual

---

## Critérios de aceite

### CA1 — Resumo sem bugs de texto
**Dado** uma NR cujo `vigente_desde` é `null` no manifest
**Quando** `build_app_meta.py` gera a entrada correspondente em `app_meta.json`
**Então** o campo `summary` não contém a string literal `"None"` em nenhum lugar

### CA2 — Portaria legível
**Dado** uma NR cujo `portaria` vem do fallback de texto bruto em `scrape_vigencia.py`
**Quando** o texto excede o limite de caracteres
**Então** o corte acontece em limite de palavra, sem duas palavras coladas

### CA3 — Diff granular no feed
**Dado** uma NR cujo conteúdo `.md` mudou de fato (novo `hash`)
**Quando** `build_app_meta.py` roda
**Então** a entrada gerada em `updates[]` inclui `items[]` com pelo menos um item, refletindo a mesma granularidade que `summarize_changes.py` produziria para o changelog

### CA4 — App lê o feed
**Dado** o app em execução com rede disponível
**Quando** `ContentService.sync()` roda no startup
**Então** `ContentService.appMeta` fica populado com os dados de `app_meta.json`, sem impedir o sync do `manifest.json` caso o feed falhe

### CA5 — Aviso obrigatório de versão
**Dado** `min_app_version` em `app_meta.json` maior que a versão instalada
**Quando** o app abre
**Então** um diálogo bloqueante (não dispensável) aparece antes de qualquer outra interação

### CA6 — Tela de Atualizações rica
**Dado** uma NR atualizada com entrada correspondente em `app_meta.json` (com `items[]`)
**Quando** o usuário abre a tela de Atualizações
**Então** vê data, portaria e a lista de itens alterados daquela NR — não só o título

### CA7 — Banner no leitor não antecipa "visto"
**Dado** uma NR com `hasUpdate == true`
**Quando** o usuário abre o leitor mas ainda não dispensou o banner nem abriu "Ver o que mudou"
**Então** o badge 🆕 dessa NR continua aparecendo nas listas (Favoritos/Todos) até uma dessas duas interações acontecer

## Checklist de entrega
- [ ] Descoberta vinculada em `.claude/discoveries/feed-atualizacoes-ux.md`
- [ ] Decisões abertas resolvidas *(nenhuma — já resolvidas em `/decidir`)*
- [ ] `fvm flutter analyze --fatal-infos` sem erros
- [ ] `validate_manifest.py` passa
- [ ] `python3 scripts/build_app_meta.py --dry-run` revisado manualmente antes do merge (ver risco de leva grande de entradas na Fase 1)
- [ ] Testes: caminho feliz + falha + edge case em cada fase
- [ ] `todo.md` — marcar item 28 e 30 como `[x]` ao final
- [ ] `docs/architecture.md` atualizado: schema de `app_meta.json` (seção "Schema", L129), texto de exemplo de resumo (L143, hoje desatualizado), e comportamento do leitor/banner (nova subseção)

## Contexto para /fazer

> Seção de consumo direto — `/fazer` lê **esta seção primeiro**, depois a fase indicada.

**Objetivo:**
Fazer o feed de atualizações funcionar de ponta a ponta — dados corretos e granulares no pipeline, consumidos e exibidos de fato no app (tela de Atualizações + banner no leitor + aviso de versão mínima).

**Arquivos previstos:**
- `scripts/build_app_meta.py`, `scripts/scrape_vigencia.py`, `scripts/test_build_app_meta.py`
- `app/lib/core/constants/app_config.dart`, `app/lib/core/models/app_meta.dart`, `app/lib/core/services/content_service.dart`, `app/pubspec.yaml`
- `app/lib/features/home/controllers/home_controller.dart`, `app/lib/features/home/views/widgets/forced_update_dialog.dart`
- `app/lib/features/updates/views/updates_page.dart`, `app/lib/features/updates/controllers/updates_controller.dart`, `app/lib/features/updates/views/widgets/update_items_list.dart`
- `app/lib/features/reader/controllers/nr_reader_controller.dart`, `app/lib/features/reader/views/nr_reader_page.dart`, `app/lib/features/reader/views/widgets/update_banner.dart`
- Testes correspondentes em `app/test/...`

**Não fazer:**
- Não implementar diff antes/depois completo nem link "Ver versão anterior" (Premium pós-MVP, descartado)
- Não mexer na tela de NR revogada nem adicionar ícone "Ajustes" — fora de escopo
- Não alterar as chaves de storage `nrLastSyncedHash`/`nrLastSeenHash`
- Não expandir escopo além das 5 fases — se surgir necessidade nova, parar e registrar como lacuna, não implementar ad hoc
- Não re-pesquisar o código já mapeado — usar este plano + `.claude/discoveries/feed-atualizacoes-ux.md` como referência

**Critérios obrigatórios:**
- Todos os CA1–CA7 verificados
- Decisões tomadas (D1–D4 + package_info_plus) respeitadas
- Fases executadas na ordem das dependências (Fase 1 → Fase 2 → Fases 3 e 4 em paralelo → Fase 5)

**Ordem de execução sugerida:**
1. Fase 1 (pipeline) — pré-requisito de schema para tudo o resto
2. Fase 2 (app: modelo + fetch) — pré-requisito das Fases 3, 4 e 5
3. Fase 3 (aviso de versão) e Fase 4 (tela de Atualizações) — podem ser feitas em paralelo, ambas dependem só da Fase 2
4. Fase 5 (banner no leitor) — por último, reaproveita o widget criado na Fase 4
