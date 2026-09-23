# Plano — Ampliar cobertura do checklist de conformidade (NR-28) para segmento + fatores de risco

> **Descoberta:** `.claude/discoveries/checklist-cobertura-completa.md`
> **Decisão:** todas as decisões de trade-off foram resolvidas inline na descoberta (D1-D4) — sem arquivo de decisão separado.

> **Nota sobre a fonte do pedido:** o texto colado junto com este `/plano` trazia uma proposta de agrupamento segmento→NRs que aproveitei (alinhada com o que já estava planejado), mas também continha citações jurídicas específicas não verificadas (caso do TST, valores de indenização, fator de conversão UFIR, mecânica de eventos do eSocial). Nenhuma dessas afirmações entra neste plano nem no conteúdo do app — não foram checadas contra fonte oficial, e o app já tem o princípio de nunca afirmar valor de multa sem verificação item a item. eSocial é um sistema totalmente diferente do que este checklist cobre (obrigações de NR × infração NR-28) e fica fora de escopo.

> **Nota sobre a 2ª revisão (feedback colado no pedido de `/plano` revisado):** trazia 4 sugestões de UI/dado. Avaliei cada uma — 1 entrou no plano (achado durante a avaliação: já existe um bug de conteúdo relacionado), 3 ficaram de fora nesta rodada. Ver "O que será feito e por quê" (item novo) e "Fora de escopo" (itens excluídos, com justificativa) abaixo.

## O que será feito e por quê

- **`segments` no dataset** — cada segmento (Comércio, Indústria, Construção Civil, Serviços/Escritório, Saúde, Transporte/Logística) leva um conjunto-base de NRs, corrigindo o campo "atividade" que hoje existe na tela mas não faz nada
- **Motor de match aditivo** — item aparece se a NR dele está no segmento escolhido **OU** se bate um fator de risco marcado (decisão já tomada: soma, não interseção)
- **Ampliar de 7 para 13 NRs** (~15-20 era o teto aceito; 13 é o conjunto que dá pra curar com confiança nesta rodada de fases, sem forçar as ~20 de uma vez)
- **Cada NR nova passa pelo mesmo processo de verificação** que already achou 1 item desalinhado (NR-6 6.3.1) — texto oficial + Anexo II da NR-28, nunca um dos dois isolado
- **Curadoria em fases por segmento** — permite entregar valor incrementalmente e revisar a qualidade antes de continuar, em vez de uma tacada só arriscando qualidade
- **Corrigir o rótulo de `tipo` (S/M) e exibir como badge no checklist** — o dado já existe (`ComplianceItem.tipo`, todos os 14 itens atuais preenchidos) mas `tipoLabel` está **incorreto**: mapeia `'S' → 'Simples'` e `'M' → 'Multa'`, quando o Anexo II da NR-28 usa S = Segurança do Trabalho e M = Medicina do Trabalho (achado ao avaliar a sugestão externa colada no pedido — não é invenção nova, é bug existente). Além de corrigir o texto, o campo nunca é lido em nenhuma tela hoje (`grep` confirma zero usos de `tipoLabel` fora do model) — vira badge visível no card do item

## Escopo

- Modelo de dados: `segments` no `compliance.json`, `CompanyProfile.segmentoId`
- Motor de correspondência: lógica aditiva segmento OR fator de risco
- UI: dropdown de atividade/segmento data-driven (mesmo padrão do formulário de fatores de risco)
- Curadoria de conteúdo: 6 NRs novas (NR-11, NR-15, NR-16, NR-18, NR-24, NR-32) + aprofundar 3 já cobertas (NR-12, NR-17, NR-35) com mais itens cada
- Correção de bug + UI: `tipoLabel` (S/M) corrigido para Segurança do Trabalho / Medicina do Trabalho, exibido como badge no `checklist_item_card.dart`
- Testes: cobrir a regra de soma (segmento + fator de risco, sem duplicar item que bate nos dois critérios)

## Fora de escopo

- **eSocial** (S-2210, S-2220, S-2240) — sistema de escrituração digital, não faz parte do que este checklist mapeia (obrigação de NR × infração NR-28). Não confundir os dois no roadmap.
- Valores de multa em R$, jurisprudência específica (casos do TST), fator de conversão UFIR — nada disso é citado no app; o princípio já registrado (`docs/compliance-checklist-cobertura.md`) continua valendo: mostrar código/gradação/tipo oficiais, nunca um valor monetário calculado
- NR-4 — não tem tabela própria de infração no Anexo II da NR-28 (confirmado por busca nesta sessão); não entra nesta expansão
- Cobrir as ~38 NRs de uma vez ou todos os itens de cada NR — decisão já tomada (D1 da descoberta) de ir por um conjunto amplo e viável, não exaustivo
- Agricultura como 7º segmento — o texto colado sugeriu, mas os 6 segmentos aprovados pelo usuário na descoberta já fecharam essa lista; não expandir sem novo pedido explícito
- **Conteúdo educativo sobre mecânica da multa** (tooltip/tela explicando gradação × nº de empregados × reajuste anual) — sugestão razoável e não conflita com o princípio de nunca calcular valor em R$ (explica o mecanismo, não cita valor), mas é um tipo de conteúdo novo (texto genérico sobre processo, não item por NR) que precisa da mesma verificação contra fonte oficial (aqui, a fórmula de gradação × porte e o índice de reajuste) antes de entrar no app — não verificado nesta sessão. Fica como candidato a um `/descobrir` próprio depois que a expansão de segmento estiver publicada, para não misturar dois tipos de curadoria no mesmo plano
- **Aviso sobre agravantes (reincidência/fraude/resistência) e embargo/interdição** — mesma razão acima, com risco maior: envolve citar mecanismo de agravamento (ex. art. 201 da CLT, citado no texto colado) que não foi conferido contra a fonte oficial nesta sessão. Não entra sem essa verificação — mesmo princípio que já vetou os outros conteúdos jurídicos não verificados do pedido original
- **Critério da "dupla visita"** — mesma razão: informação sobre procedimento de fiscalização (regulado por instrução normativa, não pela NR-28 em si), não verificada nesta sessão. Também vira candidato ao `/descobrir` futuro sugerido acima, junto com os dois itens anteriores

## Impacto estimado

### App Flutter
- 0 telas novas (reaproveita perfil + checklist já existentes)
- ~7 arquivos de código alterados (modelo, service, controller, view, storage_keys se necessário, + `compliance_item.dart` e `checklist_item_card.dart` pra Fase 0)
- `compliance.json` cresce de 14 para uma faixa estimada de 35-50 itens (6 NRs novas + aprofundamento de 3 já cobertas)

### Pipeline Python
- Nenhum (dataset continua bundlado, fora do pipeline — decisão D5 de `checklist-nr28-empresa`)

### app_meta.json / manifest
- Nenhum

### Testes
- Ajustar 3 arquivos de teste existentes + novos casos pra regra de soma (segmento sozinho, fator de risco sozinho, os dois batendo no mesmo item sem duplicar, nenhum dos dois)

## Referências

| Arquivo | Seções utilizadas |
|---------|-------------------|
| `.claude/discoveries/checklist-cobertura-completa.md` | Demanda, Perspectiva técnica, Decisões já resolvidas |
| `.claude/decisions/checklist-nr28-empresa.md` | D1 (curadoria IA+revisão humana), D5 (dataset bundlado, não pipeline) |
| `docs/compliance-checklist-cobertura.md` | Estado atual (7 NRs/14 itens) e limitações já conhecidas |
| `docs/architecture.md` | § "Checklist de conformidade (NR-28)" |
| `app/assets/compliance/compliance.json` | Schema atual de item e risk_factor a estender |

## Decisões tomadas

| Decisão | Escolha | Fundamento |
|---------|---------|------------|
| Escala do alvo | Conjunto amplo e viável (~15-20 NRs, executando 13 nesta leva de fases) | Descoberta D1 |
| Motor de correspondência | Segmento da empresa (base) + fatores de risco (soma) | Descoberta D2 |
| Regra de cruzamento | Aditiva (OR) — segmento e fator de risco somam, não fazem interseção | Descoberta D3 |
| Segmentos | Comércio, Indústria, Construção Civil, Serviços/Escritório, Saúde, Transporte/Logística | Descoberta D4 |
| Conteúdo jurídico não verificado (do texto colado neste `/plano`) | Excluído — não entra no app nem no plano | Princípio já registrado: nunca afirmar o que não foi verificado item a item |

## Decisões abertas

*(nenhuma — plano pronto para /fazer)*

## Riscos

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| Item desalinhado entre NR-28 e o texto atual da norma (já aconteceu 1x — NR-6 6.3.1) — com 6 NRs novas, a chance de mais casos passarem despercebidos aumenta | Alto | Cada item novo passa pelo mesmo processo manual de verificação cruzada (texto oficial + Anexo II) usado até agora; nenhum item entra só porque está na tabela da NR-28 |
| Alguma das 6 NRs novas não ter correspondência de texto no Anexo II (só imagem, como aconteceu com a NR-35) | Médio | Mesma técnica já usada: ler a imagem da página diretamente quando não houver texto |
| Regra de soma gerar item duplicado (bate segmento E fator de risco ao mesmo tempo) | Médio | `getApplicableItems` deve deduplicar por `nrId + itemNumber` antes de retornar a lista |
| Volume de curadoria consumir várias sessões — expectativa de "tudo pronto de uma vez" | Médio | Fases claramente separadas por segmento (ver Detalhamento); cada uma é entregável e revisável isoladamente |

## Dependências entre fases

- Fase 0 (fix do rótulo Tipo S/M) é independente — não bloqueia nem é bloqueada por nenhuma outra fase, pode rodar antes, em paralelo ou depois
- Fases 2-7 (curadoria por segmento) dependem da Fase 1 (o `segments` precisa existir no schema antes de qualquer item referenciar um segmento)
- Fase 8 (testes) depende de todas as fases de conteúdo estarem concluídas (ou pode rodar parcialmente após cada fase de conteúdo, cobrindo só o que já existe)

---

## Detalhamento

### Fase 0 — Fix: rótulo de Tipo (S/M) e badge no checklist
**Objetivo:** corrigir o rótulo incorreto de `tipo` e exibi-lo no card do item, sem depender de nada da expansão de segmento.
**Arquivos:**
- `app/lib/core/models/compliance_item.dart` (editar — `tipoLabel`: `'S' → 'Segurança do Trabalho'`, `'M' → 'Medicina do Trabalho'`)
- `app/lib/features/compliance/views/widgets/checklist_item_card.dart` (editar — adicionar badge de `tipoLabel` ao lado do badge de gradação já existente, linha 157)

**Agente sugerido:** `flutter-senior`
**Depende de:** nenhuma

**Atenção — nome de campo já usado com outro significado:** `tipo` também existe em `app/lib/core/models/app_meta.dart:164` (`UpdateItem.tipo`, valores `"novo"/"removido"/"alterado"`, feature de atualizações/sino de notificações) — mesmo nome, domínio totalmente diferente. Checado nesta sessão: não há colisão visual (a tela de updates nunca mostra "S"/"M", e o card do checklist hoje só renderiza `gradacaoLabel`, nunca a letra crua). Para não confundir, a UI deve **sempre mostrar o texto completo** ("Segurança do Trabalho" / "Medicina do Trabalho"), nunca a abreviação "S"/"M" sozinha, e o nome do getter continua `tipoLabel` (já escopado em `ComplianceItem`, sem ambiguidade real de tipo/classe) — não renomear o campo do model, só documentar a distinção pra quem for mexer depois.

#### Passos
1. Corrigir o `switch` de `tipoLabel` em `compliance_item.dart`
2. Adicionar o badge no `checklist_item_card.dart`, reaproveitando o mesmo estilo visual do badge de `gradacaoLabel` já existente, sempre com o texto completo (nunca só a letra)

#### Testes desta fase
- Unit test de `tipoLabel` para `'S'`, `'M'` e `null`

---

### Fase 1 — Arquitetura: segmento no motor de correspondência
**Objetivo:** o app sabe filtrar itens por segmento + fator de risco (somando), com o dropdown de atividade virando data-driven — sem nenhum item de conteúdo novo ainda.
**Arquivos:**
- `app/assets/compliance/compliance.json` (editar — adicionar array raiz `segments: [{id, label, nr_ids_base: []}]` com os 6 segmentos e `nr_ids_base` vazio ou só com as NRs universais por enquanto)
- `app/lib/core/models/company_profile.dart` (editar — `atividade: String` vira `segmentoId: String`)
- `app/lib/core/services/compliance_service.dart` (editar — `getSegments()`, e `getApplicableItems` passa a receber `segmentoId` além de `riskFactors`, com lógica OR e deduplicação)
- `app/lib/features/compliance/controllers/company_profile_controller.dart` (editar — remove `atividadeOptions` estático, busca de `ComplianceService.getSegments()`)
- `app/lib/features/compliance/views/company_profile_page.dart` (editar — dropdown data-driven, mesmo padrão do `RiskFactorForm`)

**Agente sugerido:** `flutter-senior`
**Depende de:** nenhuma

#### Passos
1. Definir schema de `segments` no `compliance.json`: `{"id": "comercio", "label": "Comércio", "nr_ids_base": ["nr-01","nr-05","nr-07","nr-24"]}` (e assim para os outros 5, com as NRs universais em todos + as específicas por segmento conforme a tabela da Fase 2-7)
2. `CompanyProfile.segmentoId` substitui `atividade` (campo de migração não é necessário — feature não publicada ainda)
3. `ComplianceService.getApplicableItems(segmentoId, riskFactors)`: item aplicável = `item.nrId` está em `segmento.nr_ids_base` OU `item.riskFactors` intersecciona `riskFactors` do perfil — retornar sem duplicar (usar `Set`/chave única por `nrId+itemNumber`)
4. `CompanyProfileController` busca `ComplianceService.getSegments()` no lugar da lista estática
5. `company_profile_page.dart` renderiza o dropdown a partir dessa lista

#### Testes desta fase
- Caminho feliz: segmento sozinho retorna os itens do `nr_ids_base`
- Fator de risco sozinho (sem bater segmento) ainda retorna os itens daquele fator
- Item que bate segmento E fator de risco aparece **uma vez só**, não duplicado
- Nenhum segmento nem fator de risco selecionado → lista vazia (mantém CA6 já existente)

---

### Fase 2 — Curadoria: Indústria (NR-11, NR-15 novas + aprofundar NR-12)
**Objetivo:** segmento Indústria com cobertura real além do único item de NR-12 que já existe.
**Arquivos:** `app/assets/compliance/compliance.json` (só este — curadoria de conteúdo)
**Agente sugerido:** nenhum — curadoria feita diretamente (mesmo processo manual desta sessão: ler texto oficial da NR + tabela Anexo II da NR-28, verificar correspondência antes de incluir)
**Depende de:** Fase 1

#### Passos
1. NR-11 (Transporte, Movimentação, Armazenagem) — extrair 2-3 itens centrais (ex.: sinalização de área de circulação, treinamento de operador de empilhadeira)
2. NR-15 (Insalubridade) — extrair 1-2 itens centrais (ex.: obrigação de laudo/adicional quando aplicável)
3. NR-12 — adicionar mais 1-2 itens além do já existente (12.1.7), ex. proteções de partes móveis, capacitação

#### Testes desta fase
- `getApplicableItems` com segmento "indústria" retorna os itens novos de NR-11/NR-15 mais os de NR-12

---

### Fase 3 — Curadoria: Construção Civil (NR-18 nova + aprofundar NR-35)
**Objetivo:** segmento Construção Civil cobre o canteiro de obras (NR-18) além do trabalho em altura já existente.
**Arquivos:** `app/assets/compliance/compliance.json`
**Agente sugerido:** nenhum — curadoria manual
**Depende de:** Fase 1

#### Passos
1. NR-18 (Condições de Segurança em Canteiros de Obras) — extrair 2-3 itens centrais (ex.: PCMAT, áreas de vivência, proteção de periferia)
2. NR-35 — adicionar 1-2 itens além dos 4 já existentes, se houver algo central ainda não coberto

#### Testes desta fase
- Segmento "construção_civil" retorna itens de NR-18 + os já existentes de NR-35

---

### Fase 4 — Curadoria: Saúde (NR-32 nova)
**Objetivo:** segmento Saúde cobre riscos biológicos de ambientes de saúde.
**Arquivos:** `app/assets/compliance/compliance.json`
**Agente sugerido:** nenhum — curadoria manual
**Depende de:** Fase 1

#### Passos
1. NR-32 (Segurança e Saúde no Trabalho em Serviços de Saúde) — extrair 2-3 itens centrais (ex.: PGR específico de risco biológico, gerenciamento de resíduos perfurocortantes, imunização)
2. Confirmar se a tabela do Anexo II da NR-28 pra NR-32 está em texto ou só em imagem (verificar antes de assumir)

#### Testes desta fase
- Segmento "saude" retorna os itens de NR-32

---

### Fase 5 — Curadoria: Transporte/Logística (NR-16 nova)
**Objetivo:** segmento Transporte/Logística cobre periculosidade e movimentação.
**Arquivos:** `app/assets/compliance/compliance.json`
**Agente sugerido:** nenhum — curadoria manual
**Depende de:** Fase 1 (e reaproveita itens de NR-11 já feitos na Fase 2, se o segmento também incluir NR-11 no `nr_ids_base`)

#### Passos
1. NR-16 (Atividades e Operações Perigosas) — extrair 1-2 itens centrais (ex.: caracterização de periculosidade, armazenamento de inflamáveis)
2. Incluir NR-11 no `nr_ids_base` deste segmento (reaproveitando o conteúdo da Fase 2, sem duplicar curadoria)

#### Testes desta fase
- Segmento "transporte_logistica" retorna itens de NR-16 + NR-11 (sem duplicar item que também aparece por fator de risco, se houver sobreposição)

---

### Fase 6 — Curadoria: Comércio e Serviços/Escritório (aprofundar NR-17)
**Objetivo:** os dois segmentos mais "leves" em risco físico ganham mais profundidade em ergonomia, já que hoje só têm 1 item de NR-17.
**Arquivos:** `app/assets/compliance/compliance.json`
**Agente sugerido:** nenhum — curadoria manual
**Depende de:** Fase 1

#### Passos
1. NR-17 — adicionar 2-3 itens além do já existente (17.3.1): organização do trabalho (17.4.x), mobiliário (17.6.x), ou os Anexos específicos (operadores de checkout, teleatendimento) se fizer sentido pro público-alvo
2. Definir `nr_ids_base` de "comercio" e "servicos_escritorio" — ambos puxam as universais + NR-17; diferenciar se algum item for específico de um dos dois

#### Testes desta fase
- Segmentos "comercio" e "servicos_escritorio" retornam os itens de NR-17 esperados

---

### Fase 7 — Universais: NR-24 nova
**Objetivo:** todo segmento ganha a base de condições sanitárias, já que é universal.
**Arquivos:** `app/assets/compliance/compliance.json`
**Agente sugerido:** nenhum — curadoria manual
**Depende de:** Fase 1

#### Passos
1. NR-24 (Condições Sanitárias e de Conforto) — extrair 1-2 itens centrais (ex.: instalações sanitárias, água potável)
2. Incluir `nr-24` no `nr_ids_base` de todos os 6 segmentos

#### Testes desta fase
- Qualquer segmento retorna os itens de NR-24

---

### Fase 8 — Testes finais e ajuste de regressão
**Objetivo:** suíte de testes cobre a arquitetura de segmento + fator de risco com o dataset final, sem regressão nos 14 itens já existentes.
**Arquivos:** `app/test/core/services/compliance_service_test.dart`, `app/test/features/compliance/company_profile_controller_test.dart`, `app/test/features/compliance/checklist_controller_test.dart`
**Agente sugerido:** `qa-engineer`
**Depende de:** Fases 1-7

#### Testes desta fase
- Round-trip de `segmentoId` no `CompanyProfile`
- Cada um dos 6 segmentos retorna pelo menos os itens universais
- Regra de soma sem duplicação, com o dataset completo (não só um fixture pequeno)
- Nenhuma regressão nos 14 itens já existentes da Fase 7 anterior (checklist-nr28-empresa)

---

## Critérios de aceite

### CA1 — Segmento define a base do checklist
**Dado** um perfil com segmento "Indústria" e nenhum fator de risco marcado
**Quando** o checklist é gerado
**Então** aparecem todos os itens do `nr_ids_base` de Indústria (universais + NR-11/NR-12/NR-15)

### CA2 — Fator de risco soma itens de fora do segmento
**Dado** um perfil com segmento "Serviços/Escritório" e o fator de risco "trabalho em altura" marcado
**Quando** o checklist é gerado
**Então** aparecem os itens universais/de Serviços **e também** os itens de NR-35, mesmo não sendo do segmento

### CA3 — Sem duplicação
**Dado** um item cuja NR está no segmento escolhido **e** cujo fator de risco também bate
**Quando** o checklist é gerado
**Então** o item aparece **uma única vez**

### CA4 — Dropdown de segmento é data-driven
**Dado** a tela de perfil da empresa
**Quando** o usuário abre o dropdown de atividade/segmento
**Então** as opções vêm do `compliance.json`, não de uma lista fixa no código

### CA5 — Sem regressão no conteúdo já existente
**Dado** os 14 itens já curados (NR-1/5/6/7/12/17/35)
**Quando** a nova arquitetura de segmento entra em vigor
**Então** todos continuam aparecendo corretamente pros perfis que já os contemplavam antes

### CA6 — Tipo (S/M) correto e visível
**Dado** um item do checklist com `tipo: "S"` ou `tipo: "M"`
**Quando** o card do item é exibido
**Então** aparece um badge com "Segurança do Trabalho" ou "Medicina do Trabalho" (nunca mais "Simples"/"Multa")

## Checklist de entrega
- [ ] Descoberta vinculada em `.claude/discoveries/checklist-cobertura-completa.md`
- [ ] Decisões abertas resolvidas *(nenhuma)*
- [ ] `fvm flutter analyze --fatal-infos` sem erros
- [ ] Testes: caminho feliz + falha + edge case (ver Fase 8)
- [ ] `todo.md` atualizado — expandir a Fase 7 já registrada ou abrir itens novos
- [ ] `docs/architecture.md` atualizado — cobertura de NRs e modelo de segmento
- [ ] `docs/compliance-checklist-cobertura.md` atualizado com a lista final de itens/NRs cobertos

## Contexto para /fazer

> Seção de consumo direto — `/fazer` lê esta seção primeiro, depois a fase indicada.

**Objetivo:**
Checklist filtra por segmento da empresa (base) somado a fatores de risco, cobrindo 13 NRs no total (7 já existentes + NR-11, NR-15, NR-16, NR-18, NR-24, NR-32 novas).

**Arquivos previstos:**
- `app/lib/core/models/compliance_item.dart` (Fase 0)
- `app/lib/features/compliance/views/widgets/checklist_item_card.dart` (Fase 0)
- `app/assets/compliance/compliance.json`
- `app/lib/core/models/company_profile.dart`
- `app/lib/core/services/compliance_service.dart`
- `app/lib/features/compliance/controllers/company_profile_controller.dart`
- `app/lib/features/compliance/views/company_profile_page.dart`
- `app/test/core/services/compliance_service_test.dart`, `app/test/features/compliance/*_test.dart`

**Não fazer:**
- Não implementar nada relacionado a eSocial
- Não citar valor de multa em R$, jurisprudência específica ou fator de conversão UFIR em nenhum texto do app
- Não incluir NR-4 (sem correspondência confirmada no Anexo II)
- Não expandir pra mais de 6 segmentos ou tentar cobrir todas as ~38 NRs nesta rodada
- Não adicionar conteúdo educativo sobre mecânica de multa, agravantes/interdição ou "dupla visita" nesta rodada (candidatos a `/descobrir` futuro — ver "Fora de escopo")

**Critérios obrigatórios:**
- Todos os CA1-CA6 verificados
- Cada item de conteúdo novo passa pela mesma verificação cruzada (texto oficial + Anexo II) que já descartou o item 6.3.1 da NR-6
- Fases na ordem das Dependências (Fase 0 é independente; Fase 1 antes das Fases 2-7; Fase 8 por último)

**Ordem de execução sugerida:**
1. Fase 0 → fix do rótulo Tipo (pode ser feita a qualquer momento, inclusive em paralelo)
2. Fase 1 → arquitetura de segmento
3. Fases 2-7 → curadoria por segmento (podem ser feitas em qualquer ordem entre si, todas dependem só da Fase 1; podem ser executadas em sessões separadas)
4. Fase 8 → testes finais
