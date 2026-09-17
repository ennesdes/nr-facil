# Descoberta — Cobertura de testes Maestro + CI no GitHub Actions

> Gerado por `/descobrir` · Consumido por `/decidir`
> Referência: `treino_base` (`.maestro/`, `test/e2e/README.md`, `.github/workflows/maestro-e2e.yml`, `scripts/maestro_*.sh`)

## Demanda

Introduzir uma suíte de testes E2E com Maestro (jornada real do usuário no app Android) e um workflow de CI no GitHub Actions que rode essa suíte a cada PR — hoje o NR Fácil não tem nenhum teste E2E, só `flutter test` (unit/widget) no `ci.yml` existente.

## Perspectiva do usuário

- Usuário de NR Fácil espera abrir o app offline e encontrar a norma certa, ler sem travar, favoritar, buscar e ver atualizações — sem nunca ter feito login (não há conta).
- Hoje uma regressão de navegação (ex.: drawer do leitor não abre, botão de favoritar não persiste, busca não realça o termo) só seria pega por teste unitário se alguém pensar em escrever esse caso — não há rede de segurança de "o app inteiro ainda funciona de ponta a ponta".
- Como o app é pequeno (sem autenticação, sem compra ainda), o usuário não tem "múltiplos perfis" de risco como em apps com login — o risco está concentrado em navegação, leitura offline e persistência local (favoritos, histórico).

## Perspectiva do produto/negócio

- Fase atual é 3 (Pipeline automático) — Fases 5/6 (ads, IAP) já foram implementadas segundo o `todo.md`, mas o app ainda está pré-lançamento real na Play Store (itens de "Fase 5" marcados `[x]` mas "Fase 6" IAP em aberto: `in_app_purchase` **não está no `pubspec.yaml`** ainda).
- Repositório é **público** no GitHub → minutos de GitHub Actions em runner Ubuntu são gratuitos e ilimitados para repositórios públicos — não há conflito com a restrição de custo zero do projeto ([[project_motivation]]).
- Não há tela de login nem IAP real hoje — ao contrário do `treino_base`, não existe a exclusão "Tier 3 manual" para OAuth/compra: **não há decisão de exclusão a tomar por esse motivo agora**. Isso reduz bastante a complexidade da suíte comparado à referência.
- Anúncios (`google_mobile_ads`, banner só nas listas) precisam continuar nunca aparecendo no leitor — é uma regra do `CLAUDE.md` que testes E2E podem proteger.

## Perspectiva técnica

| Área | O que muda | Por quê | Risco |
|------|-----------|---------|-------|
| `.maestro/` (novo: `config.yaml`, `flows/ci/`, `subflows/`) | Cria toda a estrutura de flows/subflows do zero | Não existe nenhum arquivo Maestro hoje no repo | Baixo — construção nova, sem legado pra conciliar |
| Semantics IDs em `app/lib/**` | Hoje só 3 usos de `Key('...')` no app inteiro e nenhum `Semantics(identifier:)` — não existe convenção de ID estável pra automação | Maestro precisa de seletor determinístico (`id:`) por tela/ação; sem isso os flows dependem de texto visível (frágil a mudança de copy) | **Médio-alto** — é o maior trabalho de instrumentação da demanda, toca praticamente toda tela (`home_page.dart`, `nr_reader_page.dart`, `search_page.dart`, `settings_page.dart`, `updates_page.dart`, `favoritos_tab.dart`, `normas_tab.dart`) |
| Conteúdo de NR pro leitor no CI | Leitor busca o `.md` da NR do GitHub raw em runtime (`content_service.dart:845`) — só o `manifest.json` vem embutido em `assets/seed/manifest.json`, não o texto das NRs | Decidido nesta sessão: usar conteúdo fixo local/mock para o build de teste, não a rede real do GitHub raw (ver decisão abaixo) | Médio — precisa de um mecanismo de override (ex.: variante de build/flavor de teste ou seed de 1–2 NRs completas com `.md` embutido) que hoje não existe |
| `.github/workflows/maestro-e2e.yml` (novo) | Novo workflow, no padrão do `treino_base`: job `plan` descobre flows em `.maestro/flows/ci/`, job `build` gera APK debug, job `avd-prepare` prepara emulador+Maestro CLI 1x (cache), job `smoke` roda 1 job/flow em matrix, job `summary` consolida | Replicar a arquitetura já validada em produção no `treino_base` (evita reinventar cache de AVD/Maestro CLI, matrix dinâmico) | Baixo-médio — é praticamente uma adaptação direta; principal ajuste é o nome do pacote/app (`nrfacil`) e o caminho do APK |
| `.github/actions/flutter-setup` (existente, usado pelo `ci.yml`) | Precisa decidir se o novo workflow reaproveita essa action composta ou usa `subosito/flutter-action` direto (como o `treino_base` faz) | Consistência com o `ci.yml` já existente no NR Fácil vs paridade exata com a referência | Baixo — decisão de execução, não bloqueia o mapeamento |
| `scripts/maestro_dev.sh`, `scripts/maestro_run.sh`, `scripts/maestro_ci.sh`, `scripts/maestro_ci_flow.sh` (novos) | Portar os 4 scripts do `treino_base` adaptando paths (`app/`, nome do pacote) | Padroniza rodar local vs CI com o mesmo contrato (`build/maestro-results/status.json`) | Baixo — cópia adaptada, lógica já validada |
| `scripts/check.sh` / `CLAUDE.md` "run before every commit" | Não roda Maestro (emulador é pesado demais pra rodar em todo commit local) | Igual ao `treino_base`: Maestro é gate de PR via CI, não do `check.sh` local | Baixo — só precisa documentar a distinção, sem mudar `check.sh` |
| `docs/architecture.md`, `CLAUDE.md` | Precisam registrar a nova camada de teste (pirâmide: unit → Maestro) e a convenção de Semantics ID | `core/documentation.mdc` do `treino_base` trata isso como pré-requisito — no NR Fácil não há regra equivalente hoje, mas é boa prática manter `CLAUDE.md`/`docs/architecture.md` como fonte única (`CLAUDE.md` já os trata como autoritativos) | Baixo |

### Telas/fluxos mapeados para cobertura (decidido: cobertura total já na 1ª suíte)

| Tela/fluxo | Arquivo | Observação |
|---|---|---|
| Home — aba Normas (Todos) | `home_page.dart`, `normas_tab.dart` | Lista de NRs, tap abre leitor |
| Home — aba Favoritos | `favoritos_tab.dart` | Favoritar/desfavoritar, persistência |
| Home — aba Buscar | `search_page.dart`, `search_tab.dart` | Busca por chunks + highlight |
| Leitor de NR | `nr_reader_page.dart` + widgets (`reader_footer.dart`, drawer, font size) | Índice lateral, ajuste de fonte, link "Ver PDF original no MTE" (`reader_footer.dart:59`) e disclaimer legal (`reader_footer.dart:43`) — regra do `CLAUDE.md` que não pode regredir |
| NR revogada | `revoked_nr_page.dart` | Estado especial de norma revogada |
| Settings | `settings_page.dart` | Ajustes do app |
| Atualizações (sino) | `updates_page.dart` + `updates_bottom_sheet` | Badge, lista de updates, tap abre leitor marcando como vista |
| Ads | `persistent_banner_ad.dart` | Confirmar banner só em telas de lista, nunca no leitor |

## Fidelidade de conteúdo

Não se aplica diretamente — a suíte Maestro não altera o pipeline de conversão nem o texto normativo. O único ponto de contato é a decisão de usar conteúdo **fixo/mock** para os testes de leitor (não o conteúdo real baixado do GitHub raw), o que significa que o texto exibido nos testes E2E não reflete necessariamente a NR real mais atual — é aceitável pois o objetivo é validar navegação/UI, não o conteúdo em si (isso já é responsabilidade do `validate_manifest.py` e da validação manual do pipeline).

## Decisões já resolvidas com o usuário nesta sessão

| Pergunta | Opção escolhida | Por quê |
|----------|------------------|---------|
| Nível de cobertura da 1ª suíte Maestro | **Cobertura total** (todas as ~6 telas/fluxos já na primeira suíte) | App pequeno, sem login/IAP para excluir — não há motivo pra faseamento por risco como no `treino_base` |
| Fonte de conteúdo de NR para o leitor no CI | **Conteúdo fixo/mock local** (não rede real do GitHub raw) | Determinismo — evita que o teste dependa de rede estável no runner e de commits automáticos diários da Action que mudam o texto exibido |

## todo.md

- [ ] Nova demanda — nenhuma menção a Maestro, testes E2E ou CI de UI em nenhuma fase do `todo.md`. Fase atual (3 — Pipeline automático) não previa isso; é trabalho de infraestrutura de qualidade transversal, não amarrado a uma fase específica.

## Lacunas ainda abertas

| ID | Pergunta | Bloqueia |
|----|----------|----------|
| D1 | Como exatamente servir "conteúdo fixo/mock" no build de teste — flavor/variant de build dedicado, endpoint local (ex.: servidor HTTP embutido no APK de teste apontando pro `.md` local), ou seed maior em `assets/seed/` com 1–2 NRs completas (`.md` + `index.json`) usadas só quando um flag de teste está ativo? Precisa de exploração técnica no `content_service.dart` antes de decidir. | Sim |
| D2 | Quantos flows Maestro na matrix do CI (1 flow cobrindo tudo sequencialmente vs 3–4 flows paralelos por área — leitura, favoritos/busca, updates/settings) — trade-off tempo de CI vs isolamento de falha, análogo ao D4 do `treino_base` | Não — decisão de execução, `/plano` resolve |
| D3 | Reaproveitar `.github/actions/flutter-setup` (já usado no `ci.yml` do NR Fácil) no novo `maestro-e2e.yml`, ou replicar a action composta `subosito/flutter-action` direto como no `treino_base`, por paridade com a referência? | Não — decisão de execução |
| D4 | Convenção de Semantics ID: seguir exatamente o padrão `treino_base` (`XxxSemanticsIds` por feature + barrel + gate `check_e2e_semantics.py`) ou uma versão simplificada, dado que o NR Fácil não tem Marionette (motor de teste em Dart complementar ao Maestro) para reaproveitar os mesmos literais? | Sim — afeta o esforço de instrumentação de toda a base |

## Próximo passo

`/decidir maestro-e2e-ci` — resolver D1 (mecanismo de conteúdo fixo) e D4 (convenção de Semantics ID) antes de detalhar o plano; D2/D3 ficam para `/plano`.
