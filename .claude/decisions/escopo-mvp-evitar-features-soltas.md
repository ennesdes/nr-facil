# Decisão — Escopo do MVP: quais features do brainstorm entram agora

## Contexto

Brainstorm levantou 5 candidatas a feature para o app, a partir de um raio-x de como profissionais de SST usam as NRs no dia a dia:

1. Busca inteligente por termo/contexto (não só número da NR)
2. Checklists interativos por NR/setor
3. Guia rápido de treinamentos tabelado (NR | curso | carga horária | reciclagem)
4. Alertas de atualização de norma
5. Favoritos/dashboard por perfil de indústria

Duas delas (**1** e **4**) já estão cobertas pelo escopo existente e não precisaram de decisão:
- Busca por termo/chunk já implementada — item `15` em [todo.md](../../todo.md), Fase 2 (concluída)
- Alertas de atualização já cobertos pelo sino/badge (item `17`) + feed `app_meta.json` (Fase 4, em andamento)

As outras três exigiam decisão de escopo — risco de o app virar uma coleção de features soltas antes de sequer publicar (o projeto está na Fase 3 de 6, ainda não lançou).

## Pergunta

Para cada uma das 3 features restantes: entra no MVP agora, fica para pós-lançamento (Fase 6+, após validar uso real), ou não entra nunca?

## Opções apresentadas

- **Guia de treinamentos tabelado** — dado derivado do texto normativo, mantido à parte; risco de desatualizar e trabalho manual extra no pipeline.
- **Checklists interativos de campo** — feature de produtividade nova (não é "ler a norma melhor"), com modelo de dados e UI próprios; maior das três em esforço.
- **Favoritos por perfil de indústria** — favoritos simples (item `14`) já resolvem o mesmo problema sem precisar manter presets setor→NRs no conteúdo/manifest.

## Escolha do usuário

- Guia de treinamentos tabelado → **pós-lançamento (Fase 6+)**
- Checklists interativos → **pós-lançamento (Fase 6+)**
- Favoritos por perfil de indústria → **não entra** — mantém apenas o favorito simples já implementado (item `14`)

## Impacto

- **Escopo do MVP atual: sem mudança.** Nenhum item novo entra em Fases 0–5 de [todo.md](../../todo.md); Fase 5 (publicação) segue sem bloqueio novo.
- Guia de treinamentos e checklists ficam como candidatas de backlog pós-lançamento, condicionadas aos critérios de sucesso de 90 dias já definidos em todo.md (1.000 downloads, 200 MAU, nota ≥4.5, receita ≥R$50/mês) — só valem a pena decidir em detalhe se o app validar uso real.
- Favoritos por perfil de indústria descartado como conceito — não deve ser reaberto sem novo pedido explícito do usuário.
