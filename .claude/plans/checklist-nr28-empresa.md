# Plano — Checklist de conformidade por empresa, cruzado com infrações da NR-28

> **Descoberta:** `.claude/discoveries/checklist-nr28-empresa.md`
> **Decisão:** `.claude/decisions/checklist-nr28-empresa.md`

## O que será feito e por quê

- **Nova aba "Checklist" na bottom nav** — dá visibilidade permanente ao recurso, sem escondê-lo (decisão D2: não pode ficar em Ajustes nem preso a uma NR específica)
- **Tela de perfil da empresa** — captura porte/atividade/fatores de risco pra filtrar o que realmente se aplica a cada usuário
- **Checklist consolidado com sinalização de infração** — resolve o problema central: saber quais itens podem gerar autuação, sem ler a NR inteira
- **Deep-link pro texto oficial** — quando o usuário fica em dúvida, reaproveita a infraestrutura já existente do leitor (`ReaderNavigation.open` com `initialAnchor`), sem criar mecanismo novo
- **Dataset curado, não gerado por pipeline** — atualiza junto com uma nova versão do app, com disclaimer de data visível (decisão D5, que descartou o parsing automático da tabela do Anexo II da NR-28)
- **Grátis com ads, sem gate de IAP** — decisão D3, priorizada agora como exceção por causa de um cliente concreto (decisão D4)

## Escopo

- Modelo de dados de perfil de empresa e de item de conformidade
- Dataset `compliance.json` bundlado como asset do app (não sincronizado via GitHub raw)
- Tela de cadastro/edição do perfil da empresa (porte, atividade, fatores de risco)
- Tela de checklist consolidado: itens das NRs aplicáveis ao perfil, com indicação de infração/gradação, explicação, estado verificado/pendente persistido, e link para o texto oficial
- Nova aba na bottom nav
- Ads na tela de checklist (mesmo padrão das telas de lista existentes)
- Disclaimer de data de última revisão do conteúdo curado

## Fora de escopo

- Não alterar `manifest.json` nem `app_meta.json` — o dataset de conformidade não passa pelo pipeline automático (decisão D5)
- Não criar script novo em `scripts/` — nenhum parser da tabela do Anexo II da NR-28 (ideia descartada em D5)
- Não implementar IAP nem qualquer gate de pagamento para esta feature (decisão D3)
- Não cobrir as ~38 NRs de uma vez — a cobertura inicial do `compliance.json` é incremental, definida durante a curadoria de conteúdo (fora deste plano de código), sem bloquear a arquitetura
- Não implementar múltiplos perfis de empresa/lista "Minhas empresas" — v1 usa perfil único por instalação; o modelo de dados fica preparado para evoluir para lista, mas a tela de múltiplos perfis fica fora deste plano
- Não resolver a inconsistência preexistente entre `CLAUDE.md` (descreve 2 abas) e o código atual (3 abas: Normas/Favoritos/Buscar) — este plano só soma uma 4ª aba ao que já existe

## Impacto estimado

### App Flutter
- 1 aba nova na bottom nav
- 2 telas novas (perfil da empresa, checklist consolidado)
- ~10 arquivos novos + ~4 arquivos editados

### Pipeline Python
- Nenhum

### app_meta.json / manifest
- Nenhum

### Testes
- 6 critérios de aceite
- ~5 arquivos de teste novos/editados

## Referências

| Arquivo | Seções utilizadas |
|---------|-------------------|
| `docs/architecture.md` | § Navegação (bottom nav atual: Normas\|Favoritos\|Buscar), § App Flutter (leitor, ads, offline), § Monetização |
| `.claude/decisions/checklist-nr28-empresa.md` | D1–D5 (todas as decisões consumidas neste plano) |
| `.claude/discoveries/checklist-nr28-empresa.md` | Perspectiva de usuário/produto; achado técnico sobre a NR-28 (nota: o parsing automático descrito ali foi descartado por D5) |
| `app/lib/features/reader/utils/reader_navigation.dart` | `ReaderNavigation.open(nrId, initialAnchor)` — reaproveitado para o deep-link |
| `app/lib/core/services/storage_service.dart` | Wrapper de `GetStorage` — reaproveitado para persistir perfil e estado do checklist |
| `todo.md` | Nenhum item ainda — feature nova, não prevista na checklist atual |

## Decisões tomadas

| Decisão | Escolha | Fundamento |
|---------|---------|------------|
| Autoria do conteúdo | IA + revisão humana pós-publicação | `.claude/decisions/checklist-nr28-empresa.md` D1 |
| Navegação | Nova aba na bottom nav, visível, não vinculada a NR específica | D2 |
| Monetização | Grátis + ads | D3 |
| Timing | Entra agora, exceção à fila de pós-90-dias | D4 |
| Fonte dos dados de infração | Curadoria manual/pesquisa, não parsing automático do Anexo II; atualiza via release do app, com disclaimer de data | D5 |
| Múltiplos perfis de empresa | Perfil único na v1; modelo de dados com `id` para evoluir a lista depois sem reescrever | Resolvido nesta sessão de `/plano` via `AskUserQuestion` — usuário escolheu "começar único, evoluir depois" |
| Nome/ícone da nova aba | "Checklist" (`Icons.checklist`) | Resolvido via `/decidir D1` — descreve o resultado final que o usuário vê, mais concreto pro usuário leigo do que "Conformidade" |

## Decisões abertas

*(nenhuma — plano pronto para /fazer)*

## Riscos

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| `compliance.json` publicado sem revisão prévia de profissional de SST (aceito conscientemente na decisão de autoria do conteúdo, `.claude/decisions/checklist-nr28-empresa.md` D1) | Alto | Disclaimer de data de revisão sempre visível na tela do checklist; revisão profissional planejada para depois de publicado |
| 4ª aba satura a bottom nav em telas pequenas | Médio | Validar visualmente em tela pequena (ex. Android <5") na Fase 4; rótulo curto |
| Mapeamento perfil→NR incompleto (fator de risco sem NR mapeada, ou vice-versa) | Médio | Cobertura incremental — começar com poucas NRs curadas e crescer via atualização do app, sem bloquear a arquitetura |
| Usuário confundir este dataset (atualiza só por release) com o conteúdo das NRs (atualiza automático via pipeline) | Médio | Disclaimer explícito diferenciando as duas fontes na tela do checklist |

## Dependências entre fases

- Fase 2 depende de Fase 1 — precisa do modelo `CompanyProfile` e do `StorageService`
- Fase 3 depende de Fase 1 e Fase 2 — precisa do `ComplianceService`/dataset e de um perfil salvo
- Fase 4 depende de Fase 2 e Fase 3 — a aba só faz sentido depois de existir pra onde navegar
- Fase 5 depende das Fases 1–4 concluídas

---

## Detalhamento

### Fase 1 — Modelos, dataset e serviço de conformidade
**Objetivo:** ter o dataset curado de conformidade acessível pelo app, com os modelos de dados prontos para as telas seguintes.
**Arquivos:**
- `app/assets/compliance/compliance.json` (novo — dataset curado; conteúdo real é trabalho de curadoria com IA + revisão humana, fora do escopo de código deste plano, mas o arquivo precisa existir com uma estrutura definida e pelo menos os dados de 1 NR piloto pra validar o mecanismo)
- `app/pubspec.yaml` (editar — registrar `assets/compliance/` na lista de assets)
- `app/lib/core/models/compliance_item.dart` (novo — item: `nrId`, `itemNumber`, `infracao` bool, `gradacao` (I1–I4, opcional), `tipo` (S/M, opcional), `explicacao`, `responsavel`, `riskFactors` que o tornam aplicável)
- `app/lib/core/models/company_profile.dart` (novo — `id` (string, fixo tipo `"default"` na v1, preparado pra virar lista depois), porte, atividade, fatores de risco)
- `app/lib/core/services/compliance_service.dart` (novo — carrega `compliance.json` do bundle, expõe consultas por NR e por fatores de risco, expõe `atualizadoEm` do dataset pro disclaimer)

**Agente sugerido:** `flutter-senior`
**Depende de:** nenhuma

#### Passos
1. Definir o schema de `compliance.json` (lista de NRs → lista de itens, cada um com os campos do `ComplianceItem`, mais um campo raiz `atualizado_em: "dd/mm/aaaa"`)
2. Popular com pelo menos 1 NR piloto (conteúdo real da curadoria — a definir por você durante a autoria, não bloqueia a mecânica)
3. Criar `CompanyProfile` e `ComplianceItem` com serialização JSON (`toJson`/`fromJson`) seguindo o padrão dos outros models em `core/models/`
4. Criar `ComplianceService` como `GetxService`, carregando o asset no `onInit` (mesmo padrão de inicialização do `StorageService`)
5. Registrar `ComplianceService` no binding apropriado

#### Testes desta fase
- Caminho feliz: `ComplianceService` carrega o JSON do bundle e retorna itens de uma NR conhecida
- Falha: JSON malformado ou ausente não derruba o app (fallback pra lista vazia + log)
- Edge case: item sem `gradacao`/`tipo` (campos opcionais) não quebra a serialização

---

### Fase 2 — Tela de perfil da empresa
**Objetivo:** usuário cadastra/edita o perfil da empresa, persistido localmente.
**Arquivos:**
- `app/lib/features/compliance/controllers/company_profile_controller.dart` (novo)
- `app/lib/features/compliance/views/company_profile_page.dart` (novo)
- `app/lib/features/compliance/views/widgets/risk_factor_form.dart` (novo — grupo de checkboxes dos fatores de risco)
- `app/lib/features/compliance/bindings/compliance_binding.dart` (novo)
- `app/lib/core/constants/storage_keys.dart` (editar — nova chave para o perfil)

**Agente sugerido:** `flutter-senior`
**Depende de:** Fase 1

#### Passos
1. `CompanyProfileController` lê/grava o perfil via `StorageService`, usando `id: "default"` fixo por enquanto
2. Tela com formulário: porte (nº de funcionários), atividade/setor, checkboxes de fatores de risco (altura, espaço confinado, produtos químicos, máquinas — conjunto exato a validar durante a curadoria do `compliance.json`, já que cada fator precisa corresponder a um `riskFactor` usado nos itens)
3. Ao salvar, navegar para o checklist (Fase 3)
4. Se já existir perfil salvo, abrir direto no checklist ao entrar na aba (perfil vira tela de edição, acessível a partir do checklist)

#### Testes desta fase
- Caminho feliz: preencher e salvar persiste o perfil e o `StorageService` retorna os mesmos dados após reabrir
- Falha: campos obrigatórios vazios não permitem salvar
- Edge case: nenhum fator de risco marcado ainda é um perfil válido (empresa sem risco especial identificado)

---

### Fase 3 — Checklist consolidado
**Objetivo:** a partir do perfil salvo, mostrar os itens aplicáveis de todas as NRs relevantes, com sinalização de infração, estado de verificação persistido, disclaimer de data e link pro texto oficial.
**Arquivos:**
- `app/lib/features/compliance/controllers/checklist_controller.dart` (novo — motor de correspondência perfil→itens + estado verificado/pendente)
- `app/lib/features/compliance/views/checklist_page.dart` (novo)
- `app/lib/features/compliance/views/widgets/checklist_item_card.dart` (novo — badge de infração/gradação, checkbox de verificação, botão "Ver na norma")
- `app/lib/features/compliance/views/widgets/compliance_disclaimer_banner.dart` (novo — "regras atualizadas em dd/mm/aaaa, pode estar desatualizado")
- `app/lib/features/compliance/views/checklist_page.dart` integra `PersistentBannerAd` já existente (sem criar widget de ads novo)

**Agente sugerido:** `flutter-senior`
**Depende de:** Fase 1, Fase 2

#### Passos
1. `ChecklistController` cruza `CompanyProfile.riskFactors` com `ComplianceItem.riskFactors` via `ComplianceService` para montar a lista consolidada (pode abranger várias NRs)
2. Estado verificado/pendente por item, persistido via `StorageService` (chave composta por perfil + item)
3. Cada card mostra: NR + item, badge de infração/gradação (quando `infracao == true`), explicação curada, botão "Ver na norma" chamando `ReaderNavigation.open(nrId: ..., initialAnchor: ...)`
4. `ComplianceDisclaimerBanner` fixo no topo, lendo `atualizadoEm` do `ComplianceService`
5. Integrar `PersistentBannerAd` seguindo o mesmo padrão usado em Favoritos/Todos/Buscar

#### Testes desta fase
- Caminho feliz: perfil com 1 fator de risco retorna só os itens mapeados a esse fator
- Falha: perfil sem nenhum fator de risco aplicável mostra estado vazio explicativo, não uma tela quebrada
- Edge case: marcar/desmarcar um item persiste corretamente entre sessões do app

---

### Fase 4 — Integração na navegação
**Objetivo:** adicionar a aba na bottom nav, roteando para perfil (se ainda não cadastrado) ou checklist (se já existe).
**Arquivos:**
- `app/lib/features/home/controllers/home_controller.dart` (editar — novo `tabChecklist`)
- `app/lib/features/home/views/home_page.dart` (editar — novo `BottomNavigationBarItem` + rota condicional perfil/checklist)
- `app/lib/core/bindings/app_binding.dart` (editar, se `ComplianceService` precisar de registro eager)

**Agente sugerido:** `flutter-senior`
**Depende de:** Fase 2, Fase 3

#### Passos
1. Adicionar `tabChecklist` seguindo o padrão de `tabNormas`/`tabFavoritos`/`tabBuscar` em `HomeController`
2. Adicionar o item na `BottomNavigationBar` com rótulo "Checklist" e ícone `Icons.checklist`
3. Ao tocar na aba: se não há perfil salvo → `CompanyProfilePage`; se há → `ChecklistPage` (com opção de editar o perfil a partir dali)

#### Testes desta fase
- Caminho feliz: tocar na aba pela primeira vez abre o cadastro de perfil
- Falha: nenhuma (navegação simples, sem estado de erro esperado)
- Edge case: tocar na aba com perfil já salvo abre direto o checklist, não o formulário

---

### Fase 5 — Testes
**Objetivo:** cobertura da lógica nova antes de considerar a feature pronta.
**Arquivos:**
- `app/test/core/services/compliance_service_test.dart` (novo)
- `app/test/features/compliance/company_profile_controller_test.dart` (novo)
- `app/test/features/compliance/checklist_controller_test.dart` (novo)
- `app/test/features/home/home_controller_test.dart` (editar, se existir — cobrir a nova aba)

**Agente sugerido:** `qa-engineer`
**Depende de:** Fases 1–4

#### Testes desta fase
- Round-trip de serialização de `CompanyProfile` e `ComplianceItem`
- `ChecklistController` filtra corretamente por fatores de risco (caminho feliz, perfil vazio, perfil com todos os fatores)
- Persistência de estado verificado/pendente sobrevive a reload do controller
- Navegação da nova aba (perfil vs. checklist conforme estado salvo)

---

## Critérios de aceite

### CA1 — Cadastro do perfil da empresa
**Dado** que o usuário abre a aba de Checklist pela primeira vez
**Quando** ele preenche porte, atividade e fatores de risco e salva
**Então** o perfil é persistido localmente e o app navega para o checklist consolidado

### CA2 — Checklist reflete o perfil
**Dado** um perfil salvo com fatores de risco X e Y
**Quando** o usuário abre o checklist
**Então** apenas os itens das NRs mapeadas para X e Y aparecem, com indicação de infração/gradação quando aplicável

### CA3 — Deep-link pro texto oficial
**Dado** um item do checklist em que o usuário está em dúvida
**Quando** ele toca em "Ver na norma"
**Então** o leitor abre na NR correta, navegado até o item específico

### CA4 — Estado de verificação persiste
**Dado** que o usuário marca um item do checklist como verificado
**Quando** ele fecha e reabre o app
**Então** o item continua marcado como verificado

### CA5 — Disclaimer de atualização visível
**Dado** que o dataset de conformidade tem uma data de última revisão
**Quando** o usuário abre o checklist
**Então** vê um aviso com essa data e o texto de que as regras podem estar desatualizadas

### CA6 — Perfil sem fatores de risco aplicáveis
**Dado** uma empresa sem nenhum fator de risco marcado
**Quando** o checklist é gerado
**Então** mostra um estado vazio explicativo, não uma tela quebrada ou lista vazia sem contexto

## Checklist de entrega
- [ ] Descoberta vinculada em `.claude/discoveries/checklist-nr28-empresa.md`
- [x] Decisões abertas resolvidas *(nenhuma — D1 resolvida via `/decidir D1`, ver Decisões tomadas)*
- [ ] `fvm flutter analyze --fatal-infos` sem erros
- [ ] Testes: caminho feliz + falha + edge case (ver Fase 5)
- [ ] `todo.md` atualizado com novo item (feature não estava prevista)
- [ ] `docs/architecture.md` atualizado — seção Navegação (4ª aba) e uma nova seção descrevendo o dataset de conformidade e seu ciclo de atualização via release, diferente do resto do pipeline

## Contexto para /fazer

> Seção de consumo direto — `/fazer` lê esta seção primeiro, depois a fase indicada.

**Objetivo:**
Usuário cadastra o perfil da empresa e vê um checklist consolidado dos itens de NR aplicáveis, sinalizando quais podem gerar infração, com link direto pro texto oficial de cada item.

**Arquivos previstos:**
- `app/assets/compliance/compliance.json`
- `app/lib/core/models/company_profile.dart`, `app/lib/core/models/compliance_item.dart`
- `app/lib/core/services/compliance_service.dart`
- `app/lib/features/compliance/` (controllers, views, bindings, widgets)
- `app/lib/features/home/controllers/home_controller.dart`, `app/lib/features/home/views/home_page.dart`
- `app/test/core/services/compliance_service_test.dart`, `app/test/features/compliance/*_test.dart`

**Não fazer:**
- Não tocar `manifest.json`, `app_meta.json` ou `scripts/`
- Não implementar múltiplos perfis de empresa (v1 é perfil único)
- Não implementar IAP/gate de pagamento para esta feature
- Não re-pesquisar o parsing do Anexo II da NR-28 — essa abordagem foi descartada (D5)

**Critérios obrigatórios:**
- Todos os CA1–CA6 verificados
- Decisões tomadas respeitadas (grátis+ads, perfil único, dataset bundlado não sincronizado via pipeline)
- Fases na ordem das Dependências (1 → 2 → 3 → 4 → 5)

**Ordem de execução sugerida:**
1. Fase 1 → modelos + dataset + serviço
2. Fase 2 → tela de perfil
3. Fase 3 → checklist consolidado
4. Fase 4 → integração na navegação
5. Fase 5 → testes
