# Descoberta — Ampliar cobertura do checklist de conformidade (NR-28) para um conjunto amplo e viável de normas

> Gerado por `/descobrir` · Consumido por `/plano` (todas as decisões de trade-off já foram resolvidas nesta sessão — ver seção própria abaixo)

## Demanda

Expandir o checklist de conformidade — hoje um piloto com 7 NRs / 14 itens, usando 6 fatores de risco binários (`.claude/decisions/checklist-nr28-empresa.md`, `docs/compliance-checklist-cobertura.md`) — para um conjunto amplo e viável de ~15-20 NRs, migrando o motor de correspondência de "só fatores de risco" para "segmento/atividade da empresa (base) + fatores de risco (soma itens extras)".

## Perspectiva do usuário

- Hoje, mesmo com 14 itens curados com cuidado, existe risco real de falsa sensação de segurança: o usuário pode achar que "já viu os principais riscos da minha empresa" quando na prática isso cobre uma fração pequena do que existe (7 de ~38 NRs vigentes, 1-4 itens por norma de dezenas possíveis). Numa ferramenta de conformidade jurídica, essa lacuna entre expectativa e cobertura real é um risco de produto, não só uma limitação técnica.
- O campo "atividade" já existe na tela de perfil (dropdown: Comércio, Indústria, Serviços, Construção Civil, Transporte, Saúde, Educação, Agricultura, Outro) mas hoje **não influencia nada** no que aparece no checklist — o usuário preenche achando que vai refinar o resultado, e não refina. Isso é enganoso e será corrigido por esta mudança.

## Perspectiva do produto

- Essa expansão é a continuação natural da exceção já registrada (`.claude/decisions/checklist-nr28-empresa.md` D4 — priorizada por causa de um cliente concreto). O volume de trabalho cresce bastante (de 14 para provavelmente 40-80 itens), o que reforça — não enfraquece — a necessidade de tratar isso como investimento sério, não um extra rápido.
- Migrar "atividade" de texto livre pra "segmento com conjunto de NRs pré-mapeado" é uma melhoria de precisão que também **corrige** o campo hoje decorativo, sem adicionar uma tela nova (reaproveita o dropdown existente).

## Perspectiva técnica

| Arquivo | O que muda | Por quê | Risco |
|---------|-----------|---------|-------|
| `app/assets/compliance/compliance.json` | Cresce de 14 para ~40-80 itens, cobrindo ~15-20 NRs; novo array raiz `segments` (`{id, label, nr_ids_base}`) | Mesmo padrão já usado pra `risk_factors` (dado-driven, não hardcoded) | **Alto volume** — repetir o processo de extração (texto oficial + cruzamento NR-28) ~3-5x mais vezes; risco de mais itens desalinhados passarem despercebidos (já achamos 1 caso — NR-6 item 6.3.1 — no lote piloto) |
| `app/lib/core/models/company_profile.dart` | `atividade: String` livre vira `segmentoId: String` referenciando um `segments` do dataset | Precisão do match — hoje o campo não é usado em nada | baixo (é um rename + mudança de tipo, sem migração real de usuários pois a feature ainda não foi publicada) |
| `app/lib/core/services/compliance_service.dart` | Nova lógica: itens aplicáveis = itens cujo NR está no `nr_ids_base` do segmento escolhido **OU** cujo `risk_factors` bate com os fatores marcados (soma, não interseção) | Decisão tomada nesta sessão (ver abaixo) | médio — lógica de match muda de "só risk_factors" pra "segmento OR risk_factors", precisa de testes novos cobrindo a combinação |
| `app/lib/features/compliance/views/company_profile_page.dart` | Dropdown de atividade passa a ser data-driven a partir de `ComplianceService.getSegments()`, igual ao `RiskFactorForm` já feito pra fatores de risco | Consistência com o padrão já estabelecido | baixo |
| `app/lib/features/compliance/controllers/company_profile_controller.dart` | Remove `atividadeOptions` estático (hardcoded), busca do `ComplianceService` | Idem acima | baixo |
| Testes existentes (`company_profile_controller_test.dart`, `checklist_controller_test.dart`, `compliance_service_test.dart`) | Precisam de ajustes/novos casos pra cobrir segmento + regra de soma | A mudança de modelo de dados quebra pressupostos dos testes atuais | médio |

## Fidelidade de conteúdo

- Mesmo princípio da expansão anterior: cada item novo precisa vir de texto oficial real (NR + Anexo II da NR-28), com o mesmo cuidado que descartou o item 6.3.1 da NR-6 por desalinhamento. Com volume ~3-5x maior, a chance de mais casos assim passarem despercebidos aumenta proporcionalmente — vale que o `/plano` prevja alguma forma de checagem sistemática (nem que seja uma revisão amostral), não só a checagem manual item a item feita até agora.
- Nenhum item, novo ou antigo, foi revisado por profissional de SST ainda — decisão já registrada (D1 de `checklist-nr28-empresa`) de que isso acontece depois de publicado. O volume maior torna essa revisão ainda mais importante.

## Decisões já resolvidas com o usuário nesta sessão

| Pergunta | Opção escolhida | Por quê |
|----------|------------------|---------|
| Escala do alvo ("completo" = o quê?) | Conjunto amplo mas viável: ~15-20 NRs mais aplicáveis, principais itens de cada | Cobrir todas as ~38 NRs com todos os itens é inviável em prazo razoável; esse meio-termo amplia bastante sem perder qualidade |
| Motor de correspondência | Migrar pra segmento/atividade da empresa (já existe como campo, hoje sem uso real) combinado com fatores de risco | Mais preciso e escalável que só fatores de risco binários; corrige um campo que já existe e engana o usuário hoje |
| Regra de cruzamento segmento × fator de risco | Somam: todo item do segmento aparece por padrão, fatores de risco somam itens extras de fora do segmento | Mais abrangente — prioriza não deixar passar batido algo que o usuário sinalizou explicitamente via fator de risco, mesmo fora do segmento típico |
| Segmentos e NRs-base | Aprovada a proposta: Comércio, Indústria, Construção Civil, Serviços/Escritório, Saúde, Transporte/Logística — cada um com um conjunto-base de NRs além das universais (NR-1, NR-5, NR-7); detalhamento exato de qual NR entra em qual segmento fica pro `/plano` | Usuário topou a proposta como ponto de partida, sem precisar fechar cada NR agora |

## todo.md

- [ ] Parcialmente previsto
- Linha relevante: Fase 7 já registrada em `todo.md` (itens 43-47, todos `[x]`) cobre o piloto de 7 NRs/14 itens — esta descoberta é uma expansão dessa mesma fase, não uma fase nova. O `/plano` deve decidir se isso vira novos itens dentro da Fase 7 ou uma Fase 7b.

## Lacunas ainda abertas

*(nenhuma — todas as dúvidas de trade-off foram resolvidas com o usuário nesta sessão; o que resta — qual NR exata entra em cada segmento, quais itens específicos extrair — é trabalho de execução do `/plano`/`/fazer`, não decisão em aberto)*
