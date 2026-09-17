# Decisão — Cobertura Maestro + CI (mock de conteúdo, Semantics IDs, granularidade de flows)

> Gerado por `/decidir` · Consumido por `/plano`
> Descoberta: `.claude/discoveries/maestro-e2e-ci.md`

## Contexto

`CLAUDE.md` e `docs/architecture.md` não têm nenhuma seção sobre testes E2E/Maestro — tema novo, sem regra prévia a respeitar. As 3 lacunas abaixo (D1, D2, D4 da descoberta) foram decididas com o usuário via `AskUserQuestion`; D3 (reuso de `.github/actions/flutter-setup`) permanece não-bloqueante e fica para o `/plano`.

---

## Decisão 1 — Mecanismo de conteúdo mock (D1)

### Pergunta
Como servir conteúdo fixo/mock de NR pro leitor no build de teste do Maestro, já que o `ContentService` busca o `.md` real do GitHub raw em runtime e só o `manifest.json` vem embutido?

### Opções apresentadas
- **Opção A — Entrypoint dedicado `main_e2e.dart`**: build separado (`flutter build apk --target=lib/main_e2e.dart`) injeta um `MockClient` com 1-2 NRs fixas no `ContentService`, reaproveitando a mesma injeção já usada em `test/support/offline_http_client.dart`. Prós: zero risco de código de teste vazar pro build de produção. Contras: mais um entrypoint pra manter.
- **Opção B — Flag em runtime no `main.dart`** (`--dart-define=E2E_MOCK=true`): menos arquivo novo, mas adiciona branch de teste no caminho de produção e risco da flag vazar num build real.

### Escolha do usuário
**Opção A — Entrypoint dedicado `main_e2e.dart`**

### Justificativa
Reaproveita o seam de injeção de dependência que já existe (`ContentService(httpClient: ...)`) e mantém o `main.dart` de produção livre de qualquer branch de teste — mesmo padrão de isolamento que o projeto já usa nos testes de widget.

### Impacto esperado
- Esforço: baixo-médio — novo `lib/main_e2e.dart` + fixture de 1-2 NRs completas (`.md` + `index.json`) num diretório de teste (ex.: `app/test/e2e/fixtures/` ou `assets/e2e_seed/`, a definir no `/plano`).
- Risco: baixo — não toca o `main.dart` real; falha em compilar o entrypoint de teste não afeta o build de release.

---

## Decisão 2 — Convenção de Semantics ID (D4)

### Pergunta
Que convenção usar para os seletores do Maestro, dado que o NR Fácil não tem Marionette pra reaproveitar os mesmos literais (só o Maestro consome os IDs)?

### Opções apresentadas
- **Opção A — Classes de constantes + gate automático**: uma classe `XxxSemanticsIds` por feature (`ReaderSemanticsIds`, `HomeSemanticsIds` etc.) + script que garante que todo `id:` usado nos flows Maestro existe de fato no código Dart. Mais setup inicial, evita drift silencioso.
- **Opção B — `Semantics(identifier:)` direto, sem constantes/gate**: mais rápido agora, risco de digitar o id errado no YAML e o teste falhar silenciosamente sem aviso em code review.

### Escolha do usuário
**Opção A — Classes de constantes + gate automático**

### Justificativa
Evita que o YAML do Maestro e o widget Dart divirjam sem aviso conforme a suíte cresce — mesmo princípio do `treino_base` (`check_e2e_semantics.py`), adaptado para não depender de Marionette (o gate aqui verifica só Dart ↔ Maestro, não um terceiro consumidor).

### Impacto esperado
- Esforço: médio — precisa instrumentar `Semantics(identifier:)` em praticamente toda tela mapeada na descoberta (maior item de trabalho da demanda).
- Risco: baixo — puramente aditivo, não muda comportamento visível.

---

## Decisão 3 — Granularidade dos flows Maestro no CI (D2)

### Pergunta
Como agrupar as ~8 telas/fluxos mapeados em flows paralelos no CI, dado que o usuário já preferiu dividir em 2+ flows por velocidade?

### Opções apresentadas
- **Opção A — 2 flows**: "Leitura" (leitor + NR revogada) e "Descoberta e gestão" (Favoritos, Busca, Settings, Atualizações, ads).
- **Opção B — 3 flows**: "Leitura" (leitor + revogada), "Navegação" (Normas/Favoritos/Busca), "Gestão" (Settings/Atualizações/ads).

### Escolha do usuário
**Opção B — 3 flows: Leitura / Navegação / Gestão**

### Justificativa
Mais isolamento de falha — ao quebrar, o job identifica exatamente qual área (leitura, navegação ou gestão) regrediu, ao custo de mais um job de emulador rodando em paralelo no CI (aceitável em repositório público, minutos de Actions gratuitos).

### Impacto esperado
- Custo: nenhum adicional (repo público → Actions ilimitado/gratuito).
- Esforço: baixo — só reflete no `.github/workflows/maestro-e2e.yml` (matrix com 3 nomes de flow em vez de 1 ou 2) e na organização de `.maestro/flows/ci/`.
- Risco: baixo.

---

## Decisões não resolvidas aqui (ficam para o `/plano`)

- **D3** — reaproveitar `.github/actions/flutter-setup` (já usado no `ci.yml` existente) vs replicar `subosito/flutter-action` direto como no `treino_base`. Não-bloqueante, decisão de execução.

## Próximo passo

`/plano maestro-e2e-ci` — detalhar fases (estrutura `.maestro/`, instrumentação de Semantics IDs por tela, `main_e2e.dart` + fixtures, scripts `maestro_*.sh`, workflow `maestro-e2e.yml` com 3 flows, gate de consistência Dart↔Maestro).
