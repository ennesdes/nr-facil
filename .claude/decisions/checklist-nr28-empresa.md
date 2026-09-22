# Decisão — Checklist de conformidade por empresa, cruzado com infrações da NR-28

> Gerado por `/decidir` a partir de [`.claude/discoveries/checklist-nr28-empresa.md`](../discoveries/checklist-nr28-empresa.md)
> **Nota de processo:** as 5 lacunas (D1–D5) já vieram respondidas pelo usuário diretamente no arquivo de descoberta antes desta rodada — nenhuma foi decidida por IA. (D2–D4 chegaram a ser delegadas ao agente `tech-lead` por engano, com base numa leitura desatualizada do arquivo; as escolhas do agente coincidiram com as respostas do usuário, mas a decisão registrada aqui é a do usuário, não a do agente.)

---

## D1 — Autoria do conteúdo curado

**Pergunta:** Quem escreve/revisa o conteúdo curado (explicação/checklist) por item?

**Opções apresentadas:**
1. Você mesmo
2. Um profissional de SST parceiro
3. Rascunho via IA, revisado por humano antes de publicar

**Escolha do usuário:** Opção 3 — com uma variação importante: a validação por um profissional de SST acontece **depois** de publicado, não antes.

**Justificativa (do usuário):** "quero criar a funcionalidade junto com IA, vou ver se tá ok, vou ver se uma profissional gosta já publicado, aí vou monitorar, se mudar algo eu atualizo o app"

**Impacto esperado:**
- Custo: baixo — sem serviço pago recorrente, uso pontual de IA pra gerar o conteúdo
- Esforço: médio — autoria por NR/item + ciclo de validação pós-publicação com profissional de SST
- Risco: conteúdo vai ao ar **sem revisão profissional prévia** — reforça a necessidade do disclaimer de data/precisão descrito em D5 até a validação acontecer

---

## D2 — Onde entra na navegação

**Pergunta:** Onboarding obrigatório, opcional em Ajustes/nova aba, ou a partir de uma NR específica?

**Opções apresentadas:**
1. Onboarding obrigatório no primeiro uso
2. Opcional, disponível em Ajustes ou nova aba
3. Acessível a partir de uma NR específica

**Escolha do usuário:** Opção 2, especificando **nova aba** (não em Ajustes) — rejeitou explicitamente a opção 3.

**Justificativa (do usuário):** "opcional, mas tem que ser uma nova aba, não pode ficar escondido do usuário, como é algo para a empresa, não pode ficar fixo a uma NR específica, uma empresa pode precisar de 0 ou várias NRs"

**Impacto esperado:**
- Custo: nenhum
- Esforço: adiciona uma aba à bottom nav. Atenção: há uma inconsistência hoje entre `CLAUDE.md` (2 abas: Favoritos/Todos) e `docs/architecture.md` (3 abas: Normas/Favoritos/Buscar) — pré-existente, não criada por esta decisão. O `/plano` precisa reconciliar isso ao desenhar onde a nova aba entra.
- Risco: mais uma aba pode saturar a bottom nav em telas pequenas — aceito conscientemente pelo usuário em troca de visibilidade

---

## D3 — Monetização

**Pergunta:** Fica grátis ou vira diferencial do IAP `remove_ads_lifetime`?

**Opções apresentadas:**
1. Grátis
2. Diferencial do IAP

**Escolha do usuário:** Opção 1 — grátis inicialmente, monetizado por ads (reaproveitando o AdMob já integrado nas telas de lista).

**Justificativa (do usuário):** "inicialmente grátis, para validarmos, e monetizar com ads"

**Impacto esperado:**
- Custo: nenhum adicional — reaproveita AdMob já existente
- Esforço: baixo nesta parte — sem fluxo de compra novo
- Risco: renuncia um diferencial de IAP por ora; decisão reversível, mas migrar de grátis pra pago depois costuma gerar resistência de usuários

---

## D4 — Timing frente à decisão de adiar checklists (Fase 6+, pós-critérios de 90 dias)

**Pergunta:** Entra agora, como exceção, ou fica condicionado aos critérios de sucesso de 90 dias já registrados?

**Opções apresentadas:**
1. Entra agora, como exceção à decisão registrada
2. Fica condicionado aos critérios de sucesso de 90 dias

**Escolha do usuário:** Opção 1 — entra agora.

**Justificativa (do usuário):** "necessidade de cliente que tem network para mais usuários usarem o app" — há um cliente concreto com potencial de trazer volume de usuários, o que justifica furar a fila da decisão anterior ([`escopo-mvp-evitar-features-soltas`](escopo-mvp-evitar-features-soltas.md)).

**Impacto esperado:**
- Custo: nenhuma mudança de custo de operação
- Esforço: reordena prioridade — feature entra antes de completar os critérios de sucesso do lançamento atual
- Risco: se o cliente não trouxer o volume esperado, o esforço não terá validado a hipótese original de uso real pós-90-dias — mitigado por não bloquear nada da Fase 5 (já publicada)

---

## D5 — Fonte dos dados de infração (revisão da abordagem técnica de `/descobrir`)

**Pergunta original:** Como separar os blocos do Anexo II da NR-28 por NR e tratar ambiguidades de parsing (headers inconsistentes, referências "do Anexo I" ambíguas, notas de portaria intercaladas)?

**Opções apresentadas:**
1. Prova de conceito com 2-3 NRs antes de generalizar
2. Parsing genérico direto para todas as NRs

**Escolha do usuário:** **Nenhuma das duas.** Resposta livre que redefine a abordagem: abandonar o parsing automático do Anexo II como fonte primária ("esse parse tá meio ruim mesmo") e, em vez disso, pesquisar diretamente informações exatas e atualizadas sobre as infrações — já que essa camada é curada manualmente (D1) e não precisa de atualização automática. Incluir aviso visível de "regras atualizadas em dd/mm/aaaa, pode estar desatualizado". Quando algo mudar, atualizar manualmente e lançar nova versão do app — diferente das NRs completas, que continuam atualizando sozinhas via pipeline diário.

**Justificativa (do usuário):** "como essa informação não vai ser atualizada de forma automática, não precisamos nos preocupar com isso, buscamos agora informações exatas e verdadeiras, colocamos avisos de que pode estar errado regras atualizadas data xx/xx/xxxx, e quando mudar algo aí eu ajusto no app e lanço uma nova versão, só não podemos confundir o usuário, essa nova funcionalidade precisa atualizar o app, já as NRs completas são atualizadas de forma automática"

**Impacto esperado (revisa a Perspectiva técnica do `/descobrir`):**
- Custo: elimina o trabalho de engenharia de um parser frágil para o Anexo II; substitui por trabalho de pesquisa/curadoria de conteúdo (mesmo processo do D1)
- Esforço: o artefato de compliance por NR deixa de ser gerado por script de parsing automático — vira um **dataset curado manualmente**, versionado no repo com um campo de data de revisão (ex. `atualizado_em`), e distribuído **junto do binário do app** (atualiza via nova versão publicada na loja), não via o mecanismo de GitHub raw usado para `manifest.json`/`content/`/`app_meta.json`. Esse é o único artefato do projeto com esse padrão de atualização — vale deixar isso explícito no `/plano` pra não confundir com o resto do pipeline.
- Risco: sem cruzamento automático com o texto oficial do Anexo II, a precisão depende inteiramente da qualidade da pesquisa/curadoria — reforça a necessidade do disclaimer de data (já prevista pelo usuário) e do ciclo de revisão por profissional de SST (D1)

---

## Resumo da feature decidida

- Nova aba na navegação (não em Ajustes, não vinculada a uma NR específica) com: tela de cadastro do perfil da empresa → checklist consolidado entre as NRs aplicáveis → link de cada item pro texto completo na NR quando em dúvida
- Conteúdo do checklist (explicação + sinalização de infração) é **curado com apoio de IA, revisado por um profissional de SST depois de publicado**, com aviso de data de última revisão visível ao usuário
- Dataset de compliance é **versionado manualmente e atualizado via releases do app** — não pelo pipeline automático diário que atualiza as NRs
- Grátis, monetizado por ads (mesmo padrão das telas de lista atuais)
- Entra **agora**, como exceção à decisão de adiar checklists para pós-lançamento, motivada por um cliente com potencial de trazer volume de usuários

## Próximo passo

Escopo abrange múltiplas telas novas (perfil da empresa, checklist consolidado), nova aba de navegação, deep-link no leitor, e um novo tipo de dataset com ciclo de atualização próprio — mais de 5 arquivos e mais de uma feature. `/plano checklist-nr28-empresa` é obrigatório para quebrar isso em fases antes de qualquer implementação.
