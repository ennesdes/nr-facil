# Plano — Suíte Maestro E2E + CI no GitHub Actions

> **Descoberta:** `.claude/discoveries/maestro-e2e-ci.md`
> **Decisão:** `.claude/decisions/maestro-e2e-ci.md`
> **Referência de implementação:** projeto `treino_base` (`.maestro/`, `test/e2e/README.md`, `.github/workflows/maestro-e2e.yml`, `scripts/maestro_*.sh`)

## O que será feito e por quê

- **Fundação de Semantics ID + gate Dart↔Maestro** — o app hoje não tem nenhum `Semantics(identifier:)`; sem isso os flows dependem de texto visível (frágil a mudança de copy).
- **`main_e2e.dart` + fixture `nr-25`** — entrypoint de build isolado que injeta um `MockClient` no `ContentService`, reaproveitando a mesma NR (`nr-25`) já usada pelo preset Marionette `reader_nr25` existente — conteúdo determinístico, sem depender de rede real no CI.
- **Instrumentação das ~8 telas** em 3 blocos (Navegação, Leitura, Gestão) — cada bloco alimenta um flow Maestro correspondente.
- **3 flows Maestro (`ci/`) + subflows reaproveitáveis** — cobertura total das telas mapeadas na descoberta, rodando em paralelo no CI.
- **Scripts locais (`maestro_dev.sh`/`maestro_run.sh`/`maestro_ci.sh`/`maestro_ci_flow.sh`)** — mesmo contrato do `treino_base`, adaptado ao pacote `nrfacil`.
- **Workflow `maestro-e2e.yml`** — matrix de 3 jobs, reaproveitando a action composta `.github/actions/flutter-setup` já usada no `ci.yml`.

Nota do usuário: o projeto **vai ganhar Marionette em breve** (ver `app/lib/debug/marionette_extensions.dart`, já com `debug.resetStorage` e `debug.navigateTo` registrados, mas ainda sem specs/flows de teste). Este plano não implementa specs Marionette, mas a convenção de Semantics ID (Fase 1) é desenhada para ser reaproveitável por elas depois, sem retrabalho.

## Escopo

- App Flutter (`app/lib/`): novo entrypoint `main_e2e.dart`, classes `*SemanticsIds` por bloco, `Semantics(identifier:)` nas telas mapeadas.
- Testes E2E: `.maestro/` (config, flows, subflows), fixture `nr-25` embutida como asset de teste.
- Automação: `scripts/maestro_*.sh`, `scripts/check_e2e_semantics.py`, `.github/workflows/maestro-e2e.yml`.
- Documentação: `docs/architecture.md` (nova seção "Testes E2E") e `CLAUDE.md` (referência rápida) atualizados ao final.

## Fora de escopo

- Não criar specs/flows Marionette (fica para quando o pacote realmente ganhar cobertura de teste própria — este plano só evita retrabalho futuro).
- Não automatizar login/IAP real — não existem hoje no app (`in_app_purchase` nem está no `pubspec.yaml`).
- Não alterar `ci.yml` existente (`flutter analyze` + `flutter test` + `validate_manifest.py`) — o Maestro é um workflow novo e separado.
- Não mudar o `ContentService` de produção — a mock fica isolada em `main_e2e.dart`.
- Não adicionar `Semantics(identifier:)` em telas fora das ~8 mapeadas na descoberta (ex.: onboarding, se existir — não mapeado; confirmar se não existe antes da Fase 3).

## Impacto estimado

### App Flutter
- 1 entrypoint novo (`main_e2e.dart`)
- ~4 classes `*SemanticsIds` novas + 1 barrel
- ~9 arquivos de widget/tela recebendo `Semantics(identifier:)` (sem mudança de comportamento visível)

### Pipeline Python
- Nenhum

### app_meta.json / manifest
- Nenhum — fixture de teste é estática, não gerada pelo pipeline

### Testes
- 3 flows Maestro (Leitura, Navegação, Gestão) + ~8-10 subflows reaproveitáveis
- 1 script de gate (`check_e2e_semantics.py`) com teste próprio

## Referências

| Arquivo | Seções utilizadas |
|---------|-------------------|
| `.claude/discoveries/maestro-e2e-ci.md` | Perspectiva técnica, telas mapeadas |
| `.claude/decisions/maestro-e2e-ci.md` | Decisões 1–3 (mock, Semantics ID, granularidade) |
| `app/lib/debug/marionette_extensions.dart` | Convenção de preset `nr-25` / nomes de tela já usados pelo Marionette debug |
| `.github/actions/flutter-setup/action.yml` | Reuso no novo workflow |
| `app/test/support/offline_http_client.dart` | Padrão de `MockClient` a reaproveitar no `main_e2e.dart` |

## Decisões tomadas

| Decisão | Escolha | Fundamento |
|---------|---------|------------|
| Mock de conteúdo no CI | Entrypoint dedicado `main_e2e.dart` | `.claude/decisions/maestro-e2e-ci.md` Decisão 1 |
| Convenção de Semantics ID | Classes de constantes + gate automático | `.claude/decisions/maestro-e2e-ci.md` Decisão 2 |
| Granularidade dos flows | 3 flows — Leitura / Navegação / Gestão | `.claude/decisions/maestro-e2e-ci.md` Decisão 3 |
| Reuso de `.github/actions/flutter-setup` (D3 da descoberta) | Reaproveitar a action composta existente | Já encapsula `subosito/flutter-action` + cache de `.dart_tool` + `pub get` com `ci_step_report.sh` — sem trade-off real, é a mesma base que o `treino_base` monta manualmente |
| NR fixture para o mock | `nr-25` | Já é a NR usada pelo preset Marionette `reader_nr25` (`marionette_extensions.dart`) — mantém uma única NR de referência para teste em todo o projeto |

## Decisões abertas

*(nenhuma — plano pronto para /fazer)*

## Riscos

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| Fixture `nr-25` embutida em `assets/e2e_seed/` aumenta o tamanho do APK de produção (pubspec não distingue assets por entrypoint) | Baixo (nr-25.md tem 50 linhas, poucos KB) | Aceitar — tamanho desprezível; se crescer, mover para carregamento via `rootBundle` só a partir de `main_e2e.dart` com asset variant separada não é suportado pelo Flutter sem flavors — reavaliar só se o tamanho virar problema real |
| Emulador Android no GitHub Actions é a camada mais lenta/instável da pirâmide de teste (mesma observação do `treino_base`) | Médio | Cache de AVD + Maestro CLI entre jobs (`avd-prepare` compartilhado), `fail-fast: false` na matrix para não derrubar os 3 flows por 1 flaky |
| Semantics ID digitado errado no YAML do Maestro falha silenciosamente (elemento não encontrado, sem apontar a causa) | Médio | `scripts/check_e2e_semantics.py` (gate) valida que todo `id:` usado em `.maestro/flows/` e `.maestro/subflows/` existe como literal em alguma classe `*SemanticsIds` |
| Repositório público — custo de CI | Nenhum | Actions em runner padrão é gratuito/ilimitado para repos públicos (confirmado via `gh repo view`) |

## Dependências entre fases

- Fase 2 (`main_e2e.dart` + fixture) depende da Fase 1 (estrutura `.maestro/` + gate) só para o gate reconhecer o diretório — pode rodar em paralelo na prática, mas é mais simples sequencial.
- Fases 3, 4, 5 (instrumentação Semantics ID por bloco) dependem da Fase 1 (barrel + convenção definida) — podem rodar em qualquer ordem entre si.
- Fase 6 (flows Maestro) depende das Fases 2, 3, 4, 5 (precisa dos IDs existindo e do app de teste buildável).
- Fase 7 (scripts locais) depende da Fase 6 (referencia os flows).
- Fase 8 (CI workflow) depende das Fases 6 e 7.

---

## Detalhamento

### Fase 1 — Fundação: convenção de Semantics ID + gate + esqueleto `.maestro/`
**Objetivo:** Estabelecer o padrão de `*SemanticsIds` reaproveitável (inclusive por futuras specs Marionette) e o gate que garante consistência Dart↔Maestro, mais o esqueleto do diretório `.maestro/`.
**Arquivos:**
- `app/lib/core/constants/e2e_semantics_ids.dart` (barrel — reexporta todas as classes `*SemanticsIds`)
- `scripts/check_e2e_semantics.py` (novo)
- `scripts/test_check_e2e_semantics.py` (novo, teste do gate)
- `.maestro/config.yaml` (novo)
- `scripts/README.md` (atualizar com a nova entrada)

**Agente sugerido:** `flutter-senior` (barrel Dart) + `python-pipeline` (script de gate)
**Depende de:** nenhuma

#### Passos
1. Criar `e2e_semantics_ids.dart` como barrel vazio inicialmente (`export` das classes que as Fases 3–5 vão criar) — documentar a convenção no topo do arquivo: `Semantics(identifier: XxxSemanticsIds.foo)` no widget, mesmo literal em `id: '...'` no YAML Maestro.
2. Criar `.maestro/config.yaml` com `appId` do pacote (`com.nrfacil.app` ou equivalente — confirmar em `app/android/app/build.gradle`) e `flows` apontando para `flows/ci`.
3. Criar `scripts/check_e2e_semantics.py`: varre `.maestro/flows/**/*.yaml` e `.maestro/subflows/**/*.yaml` extraindo todo valor de `id:`; varre `app/lib/**/*.dart` extraindo literais passados a `Semantics(identifier: ...)` (via regex simples, não AST); falha listando quais `id:` do YAML não têm literal Dart correspondente.
4. Teste do gate: `scripts/test_check_e2e_semantics.py` cobre caso feliz (todos os ids batem) e caso de falha (id órfão no YAML).
5. Adicionar chamada do gate em `scripts/check.sh` (não bloqueante para quem não tocou `.maestro/` — só roda se o diretório existir e tiver flows, mesmo padrão de guarda usado pelo restante do `check.sh`).

#### Testes desta fase
- Caminho feliz: todos os `id:` usados nos flows existem como literal Dart → gate passa.
- Falha: um `id:` no YAML sem literal Dart correspondente → gate falha com mensagem clara (arquivo + id órfão).
- Edge case: `.maestro/flows/ci/` vazio (antes da Fase 6 existir) → gate não falha por ausência de flows.

---

### Fase 2 — `main_e2e.dart` + fixture `nr-25`
**Objetivo:** Entrypoint de build isolado que serve conteúdo determinístico (NR-25 real) via `MockClient`, sem tocar o `main.dart` de produção.
**Arquivos:**
- `app/lib/main_e2e.dart` (novo)
- `app/assets/e2e_seed/manifest.json` (novo — só a entrada de `nr-25`, copiada/reduzida de `content/nr-25/meta.json` + `app/assets/seed/manifest.json`)
- `app/assets/e2e_seed/nr-25/nr-25.md` (novo — cópia de `content/nr-25/nr-25.md`)
- `app/assets/e2e_seed/nr-25/index.json` (novo — cópia de `content/nr-25/index.json`)
- `app/pubspec.yaml` (declarar `assets/e2e_seed/` em `flutter.assets`)

**Agente sugerido:** `flutter-senior`
**Depende de:** Fase 1 (não estritamente, mas mantém ordem sequencial simples)

#### Passos
1. Copiar os 3 arquivos de `content/nr-25/` para `app/assets/e2e_seed/nr-25/` (conteúdo real, sem reescrever texto normativo — só uma cópia estática para teste).
2. Criar `app/assets/e2e_seed/manifest.json` com uma única entrada `nr-25` (mesmos campos do manifest real: `id`, `title`, `version`, `hash`, `pdf_hash`, `url`, `pdf_url`, `revogada: false`).
3. Criar `main_e2e.dart`: mesmo bootstrap do `main.dart` (Firebase, GetStorage, tema), mas registra `ContentService` com um `http.Client` mock (`MockClient`, mesmo padrão de `test/support/offline_http_client.dart`) que responde:
   - `.../manifest.json` → conteúdo de `assets/e2e_seed/manifest.json`
   - `.../nr-25.md` → conteúdo de `assets/e2e_seed/nr-25/nr-25.md`
   - qualquer outra URL → 404 (comportamento determinístico, sem rede real)
4. Confirmar no `ContentService` que o `httpClient` injetado é de fato usado em todos os pontos de fetch relevantes (manifest + conteúdo da NR) — se algum ponto usar um client global não injetável, ajustar a injeção nesta fase (é a única fase que pode tocar `content_service.dart`, e só se necessário).
5. Adicionar ao `pubspec.yaml`: `- assets/e2e_seed/` em `flutter.assets`.

#### Testes desta fase
- Caminho feliz: `flutter build apk --debug --target=lib/main_e2e.dart` compila e abre no emulador mostrando a Home com `nr-25` disponível.
- Falha: mock client retorna 404 pra URL não mapeada — app deve degradar como já degrada hoje pra manifest indisponível (não travar).
- Edge case: `nr-25` já teria `revogada: false` — não testar aqui o caminho de NR revogada com a fixture real (isso é tratado na Fase 4, ver nota).

---

### Fase 3 — Semantics ID: bloco Navegação (Home / Normas / Favoritos / Busca)
**Objetivo:** Instrumentar as telas do flow "Navegação" com IDs estáveis.
**Arquivos:**
- `app/lib/core/constants/semantics/home_semantics_ids.dart` (novo)
- `app/lib/features/home/views/home_page.dart`
- `app/lib/features/home/views/widgets/normas_tab.dart`
- `app/lib/features/home/views/widgets/favoritos_tab.dart`
- `app/lib/features/search/views/search_tab.dart` (ou `search_page.dart`, confirmar qual é o widget ativo na aba)

**Agente sugerido:** `flutter-senior`
**Depende de:** Fase 1

#### Passos
1. Criar `HomeSemanticsIds` com constantes para: aba Normas/Favoritos/Buscar (bottom nav), item de lista de NR (função `nrListTile(String nrId)` → `'nr_tile_$nrId'`, análogo ao padrão de índice por posição do `treino_base`), botão de favoritar/desfavoritar por NR, ícone de sino (atualizações), ícone de settings.
2. Adicionar `Semantics(identifier: ...)` nos widgets correspondentes em `home_page.dart`, `normas_tab.dart`, `favoritos_tab.dart`.
3. Instrumentar campo de busca e item de resultado em `search_tab.dart`.
4. Exportar `HomeSemanticsIds` no barrel (`e2e_semantics_ids.dart`, Fase 1).

#### Testes desta fase
- Caminho feliz: `flutter test` dos widgets tocados continua verde (instrumentação não muda comportamento).
- Falha: N/A (mudança aditiva).
- Edge case: lista vazia de favoritos — `EmptyState` também recebe um id, pro flow validar o estado vazio se quiser.

---

### Fase 4 — Semantics ID: bloco Leitura (Reader + NR revogada)
**Objetivo:** Instrumentar o leitor — incluindo os elementos de compliance (link PDF original, disclaimer) que o `CLAUDE.md` marca como obrigatórios.
**Arquivos:**
- `app/lib/core/constants/semantics/reader_semantics_ids.dart` (novo)
- `app/lib/features/reader/views/nr_reader_page.dart`
- `app/lib/features/reader/views/widgets/reader_footer.dart`
- `app/lib/features/reader/views/widgets/nr_reader_header.dart` (drawer/índice + controle de fonte, confirmar nome exato do widget de font-size ao abrir o arquivo)
- `app/lib/features/reader/views/revoked_nr_page.dart`

**Agente sugerido:** `flutter-senior`
**Depende de:** Fase 1

#### Passos
1. Criar `ReaderSemanticsIds`: botão abrir índice/drawer, controle de tamanho de fonte, toggle modo escuro (se estiver aqui e não em Settings — confirmar), link "Ver PDF original no MTE" (`reader_footer.dart:59`), texto do disclaimer legal (`reader_footer.dart:43`), botão de favoritar dentro do leitor (se existir).
2. Instrumentar `nr_reader_page.dart` e os widgets citados.
3. Instrumentar `revoked_nr_page.dart` com um id de tela + qualquer ação disponível nela (ex.: voltar, ver PDF).
4. Exportar no barrel.

#### Testes desta fase
- Caminho feliz: `flutter test` dos testes de reader existentes continua verde.
- Falha: N/A.
- Edge case: NR revogada — como a fixture `nr-25` da Fase 2 não é revogada, o flow Maestro de Leitura (Fase 6) só valida navegação até `revoked_nr_page.dart` se houver uma forma determinística de chegar lá (ex.: uma segunda entrada mock `revogada: true` na fixture, adicionar se necessário nesta fase revisando a Fase 2).

---

### Fase 5 — Semantics ID: bloco Gestão (Settings / Atualizações / Ads)
**Objetivo:** Instrumentar as telas de gestão e o ponto de checagem "banner nunca aparece no leitor".
**Arquivos:**
- `app/lib/core/constants/semantics/management_semantics_ids.dart` (novo)
- `app/lib/features/settings/views/settings_page.dart`
- `app/lib/features/updates/views/updates_page.dart`
- `app/lib/features/updates/views/widgets/updates_bottom_sheet.dart` (confirmar nome exato do widget de sheet)
- `app/lib/features/ads/widgets/persistent_banner_ad.dart`

**Agente sugerido:** `flutter-senior`
**Depende de:** Fase 1

#### Passos
1. Criar `ManagementSemanticsIds`: opções de Settings, botão "Verificar atualizações", item de update na lista, botão de sino/badge na Home (se não já coberto na Fase 3), o próprio widget de banner (`PersistentBannerAd`) recebe um id fixo pra o subflow de asserção negativa (Fase 6) confirmar ausência dele na árvore do leitor.
2. Instrumentar os 4 arquivos.
3. Exportar no barrel.

#### Testes desta fase
- Caminho feliz: `flutter test` de settings/updates continua verde.
- Falha: N/A.
- Edge case: lista de updates vazia (`EmptyState`) — reaproveitar o mesmo padrão da Fase 3.

---

### Fase 6 — Flows Maestro (3 flows CI + subflows)
**Objetivo:** Traduzir a cobertura instrumentada nas Fases 3–5 em flows Maestro executáveis.
**Arquivos:**
- `.maestro/flows/ci/01_leitura.yaml`
- `.maestro/flows/ci/02_navegacao.yaml`
- `.maestro/flows/ci/03_gestao.yaml`
- `.maestro/subflows/*.yaml` (múltiplos — ex.: `open_reader_nr25.yaml`, `toggle_favorite.yaml`, `search_and_highlight.yaml`, `check_updates_badge.yaml`, `assert_no_banner_in_reader.yaml` — nomes definidos ao implementar, cobrindo cada ponto das Fases 3–5)

**Agente sugerido:** `flutter-senior` (conhece as telas/ids) — pode também usar o agente `tech-lead` se surgir dúvida de arquitetura do `.maestro/config.yaml`
**Depende de:** Fases 2, 3, 4, 5

#### Passos
1. `01_leitura.yaml`: abrir `nr-25` pela Home → abrir índice lateral → ajustar fonte → confirmar link "Ver PDF original no MTE" e disclaimer visíveis → voltar → (se a Fase 4 adicionar fixture de NR revogada) navegar até ela e confirmar `revoked_nr_page`.
2. `02_navegacao.yaml`: aba Normas → aba Favoritos (favoritar uma NR, confirmar persiste ao reabrir) → aba Buscar (buscar termo, confirmar highlight, abrir resultado).
3. `03_gestao.yaml`: abrir Settings, alternar uma opção → abrir Atualizações (sino), confirmar lista/estado vazio → assert banner de ads presente na lista e ausente no leitor (reaproveita subflow de leitura ou navega de novo até o reader).
4. Cada flow usa `appId` do `main_e2e.dart` build (instalar o APK gerado com esse target no `smoke` do CI).

#### Testes desta fase
- Caminho feliz: cada flow roda localmente com `maestro test .maestro/flows/ci/0X_*.yaml` contra um emulador com o APK de `main_e2e.dart` instalado.
- Falha: flow que depende de elemento sem `Semantics(identifier:)` correspondente é pego pelo gate da Fase 1 antes de chegar a essa fase.
- Edge case: aba Favoritos vazia no primeiro boot da fixture (nr-25 não é favorito por padrão) — `02_navegacao.yaml` deve favoritar antes de checar persistência, não assumir estado pré-existente.

---

### Fase 7 — Scripts locais (`maestro_dev.sh`, `maestro_run.sh`, `maestro_ci.sh`, `maestro_ci_flow.sh`)
**Objetivo:** Portar os scripts do `treino_base`, adaptando paths e nome do pacote (`nrfacil`) e o target de build (`lib/main_e2e.dart`).
**Arquivos:**
- `scripts/maestro_dev.sh`
- `scripts/maestro_run.sh`
- `scripts/maestro_ci.sh`
- `scripts/maestro_ci_flow.sh`

**Agente sugerido:** `tech-lead` (scripts de infraestrutura de CI/dev) ou `flutter-senior`
**Depende de:** Fase 6

#### Passos
1. Adaptar `maestro_dev.sh`: sobe emulador (se `--no-boot` não passado), builda `app/` com `--target=lib/main_e2e.dart --debug`, instala, roda todos os flows de `.maestro/flows/ci/` sequencialmente.
2. Adaptar `maestro_run.sh`: só roda a suíte contra device já ligado; suporta `--flow <yaml>` pra um flow específico.
3. Adaptar `maestro_ci.sh`/`maestro_ci_flow.sh`: contrato igual ao `treino_base` — grava `build/maestro-results/status.json` com `{desc, status, passed, duration, error}` por flow, consumido pelo job `summary` do workflow.
4. Documentar os 4 comandos em `scripts/README.md`.

#### Testes desta fase
- Caminho feliz: `bash scripts/maestro_dev.sh` local roda os 3 flows contra um emulador já configurado na máquina do dev.
- Falha: flow falha → `status.json` registra `passed: false` + `error` com a causa do Maestro.
- Edge case: `--no-boot` sem device conectado → mensagem de erro clara, não trava esperando.

---

### Fase 8 — Workflow CI `maestro-e2e.yml`
**Objetivo:** Rodar os 3 flows em paralelo a cada PR, no padrão validado do `treino_base` (jobs `plan` → `build` → `avd-prepare` → `smoke` (matrix) → `summary`).
**Arquivos:**
- `.github/workflows/maestro-e2e.yml` (novo)

**Agente sugerido:** `tech-lead`
**Depende de:** Fases 6, 7

#### Passos
1. Job `plan`: descobre os 3 flows em `.maestro/flows/ci/*.yaml` (mesmo `jq`/`ls` do `treino_base`).
2. Job `build`: usa `.github/actions/flutter-setup` (reuso, decisão tomada) + Java 17 + build `flutter build apk --debug --target=lib/main_e2e.dart --no-pub --target-platform android-x64` → upload do APK como artifact.
3. Job `avd-prepare`: idêntico ao `treino_base` — cache de AVD (API 34, google_apis, x86_64, pixel_6) + cache do Maestro CLI, 1x reaproveitado pela matrix.
4. Job `smoke`: matrix dos 3 flows, cada um baixa o APK, restaura os caches, roda `scripts/maestro_ci_flow.sh` no emulador, publica `status.json` + relatório em caso de falha.
5. Job `summary`: consolida os 3 resultados no `GITHUB_STEP_SUMMARY`, igual ao `treino_base` (passou/falhou por flow + comando local equivalente).
6. Trigger: `pull_request` (branches `main`) + `workflow_dispatch` — sem trigger em `push` direto (mesmo padrão do `treino_base`, evita rodar 2x em merge).

#### Testes desta fase
- Caminho feliz: abrir um PR de teste → os 3 jobs de `smoke` rodam em paralelo e reportam verde no summary.
- Falha: quebrar deliberadamente um `id:` num flow → o job correspondente falha e o `summary` aponta qual flow e o motivo.
- Edge case: cache miss total (primeira execução) — `avd-prepare` deve gerar o snapshot do zero sem travar por timeout (`timeout-minutes: 15`, igual à referência).

---

## Critérios de aceite

### CA1 — Gate de consistência Dart↔Maestro funciona
**Dado** um `id:` usado em qualquer flow/subflow `.maestro/`
**Quando** `python3 scripts/check_e2e_semantics.py` roda
**Então** o script falha se esse `id` não existir como literal Dart em alguma classe `*SemanticsIds`, e passa quando existir.

### CA2 — Build `main_e2e.dart` não depende de rede
**Dado** o app buildado com `--target=lib/main_e2e.dart` rodando sem conexão de rede no emulador
**Quando** o usuário abre a NR-25 no leitor
**Então** o conteúdo real de NR-25 aparece, servido 100% pela fixture local (`assets/e2e_seed/`).

### CA3 — 3 flows Maestro cobrem as telas mapeadas
**Dado** os 3 flows (`01_leitura`, `02_navegacao`, `03_gestao`)
**Quando** rodados localmente via `bash scripts/maestro_dev.sh`
**Então** todos passam, cobrindo: Home/Normas, Favoritos, Buscar, Leitor (índice, fonte, link PDF, disclaimer), Settings, Atualizações e a ausência de banner de ads no leitor.

### CA4 — CI roda em paralelo a cada PR
**Dado** um Pull Request aberto contra `main`
**Quando** o workflow `maestro-e2e.yml` dispara
**Então** os 3 flows rodam em jobs `smoke` paralelos (matrix), com cache de AVD/Maestro CLI reaproveitado, e o `summary` consolida passou/falhou por flow.

### CA5 — Produção não é afetada
**Dado** o `main.dart` de produção
**Quando** `flutter build apk --release` (sem `--target`) roda
**Então** nenhum código de mock/teste (`main_e2e.dart`, `MockClient`) é referenciado — o app de produção continua buscando conteúdo real do GitHub raw.

## Checklist de entrega
- [ ] Descoberta vinculada em `.claude/discoveries/maestro-e2e-ci.md`
- [ ] Decisões abertas resolvidas *(nenhuma)*
- [ ] `fvm flutter analyze --fatal-infos` sem erros
- [ ] `validate_manifest.py` passa (não deveria ser afetado, confirmar mesmo assim)
- [ ] `scripts/check_e2e_semantics.py` passa
- [ ] Testes: caminho feliz + falha + edge case (por fase, ver acima)
- [ ] Os 3 flows Maestro passam localmente (`bash scripts/maestro_dev.sh`)
- [ ] `todo.md`: nenhuma linha existente cobre isso — não marcar item, mas pode-se adicionar uma nota transversal se o usuário quiser
- [ ] `docs/architecture.md` atualizado com seção "Testes E2E (Maestro)"
- [ ] `CLAUDE.md` atualizado com referência rápida ao novo workflow/comandos

## Contexto para /fazer

> Seção de consumo direto — `/fazer` lê **esta seção primeiro**, depois a fase indicada.

**Objetivo:**
Ter uma suíte Maestro (3 flows: Leitura, Navegação, Gestão) cobrindo todas as telas do app, rodando local (`scripts/maestro_dev.sh`) e em CI a cada PR (`maestro-e2e.yml`), com um gate que impede o YAML e o código Dart de divergirem nos seletores.

**Arquivos previstos:**
- `app/lib/main_e2e.dart`, `app/assets/e2e_seed/**`
- `app/lib/core/constants/e2e_semantics_ids.dart` + `app/lib/core/constants/semantics/*.dart`
- ~9 arquivos de tela/widget recebendo `Semantics(identifier:)`
- `.maestro/config.yaml`, `.maestro/flows/ci/*.yaml`, `.maestro/subflows/*.yaml`
- `scripts/maestro_dev.sh`, `maestro_run.sh`, `maestro_ci.sh`, `maestro_ci_flow.sh`, `check_e2e_semantics.py` (+ teste)
- `.github/workflows/maestro-e2e.yml`

**Não fazer:**
- Não criar specs Marionette agora (fora de escopo — só preparar a convenção de IDs para reaproveitamento futuro)
- Não tocar `ci.yml` existente
- Não mudar o `ContentService` de produção além do necessário pra garantir que a injeção de `httpClient` cubra todos os pontos de fetch (Fase 2, só se necessário)
- Não expandir cobertura além das ~8 telas já mapeadas na descoberta

**Critérios obrigatórios:**
- Todos os CA1…CA5 verificados
- Decisões tomadas respeitadas (entrypoint dedicado, classes+gate, 3 flows, reuso da action)
- Fases na ordem das Dependências (Fase 1 → 2 → {3,4,5} → 6 → 7 → 8)

**Ordem de execução sugerida:**
1. Fase 1 → fundação (barrel + gate + `.maestro/config.yaml`)
2. Fase 2 → `main_e2e.dart` + fixture `nr-25`
3. Fases 3, 4, 5 → instrumentação por bloco (podem intercalar)
4. Fase 6 → flows Maestro
5. Fase 7 → scripts locais
6. Fase 8 → workflow CI
