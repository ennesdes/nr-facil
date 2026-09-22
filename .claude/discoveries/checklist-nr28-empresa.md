# Descoberta — Checklist de conformidade por empresa, cruzado com infrações da NR-28

> Gerado por `/descobrir` · Consumido por `/decidir`

## Demanda

Nova tela de "perfil da empresa" (porte, atividade, fatores de risco) que gera um checklist consolidado dos itens das NRs aplicáveis, sinalizando quais estão sujeitos a infração/penalidade (cruzando com o Anexo II da NR-28: código, gradação I1–I4, tipo S/M) e explicando o que verificar em cada um — com link direto pra ler o texto completo daquele item na NR quando o usuário ficar em dúvida.

## Perspectiva do usuário

- Hoje o app é só um leitor: quem quer saber "quais itens desta NR podem gerar autuação" precisa ler a norma inteira (às vezes 80+ páginas) e interpretar sozinho o que é obrigação crítica vs. recomendação.
- Dois perfis de usuário reais, segundo o pedido: (1) técnico/consultor externo de SST que precisa **indicar pontos de risco aos seus clientes** — ferramenta de trabalho e argumento comercial; (2) profissional **interno da empresa**, muitas vezes sem formação jurídica completa, que precisa garantir conformidade sem saber por onde começar.
- Fluxo que o usuário desenhou nesta sessão: preencher dados da empresa → ver um checklist consolidado (entre várias NRs) → ao ficar em dúvida num item, ser levado direto pro texto oficial daquele item dentro da NR.
- Isso elimina o trabalho manual de montar esse cruzamento (NR → obrigação → risco de infração) que hoje cada profissional faz sozinho, sem apoio de ferramenta nenhuma.

## Perspectiva do produto

- Muda o posicionamento do app de "leitor offline de NRs" para "ferramenta de verificação de conformidade" — bem mais próximo de uma ferramenta de trabalho do que de uma biblioteca de PDFs convertidos.
- **Já existe uma decisão registrada sobre uma versão anterior desta ideia:** [`escopo-mvp-evitar-features-soltas`](../decisions/escopo-mvp-evitar-features-soltas.md) jogou "checklists interativos por NR/setor" para pós-lançamento (Fase 6+), condicionado a validar os critérios de sucesso de 90 dias do `todo.md` (1.000 downloads, 200 MAU, nota ≥4.5, receita ≥R$50/mês — **nenhum marcado ainda**). A demanda de agora é mais ambiciosa que aquela (adiciona o cruzamento com NR-28 e o perfil de empresa), mas é a mesma família de ideia — registro isso como contexto, não decido aqui se ela deve furar a fila.
- Onboarding: uma tela de perfil de empresa pode virar parte do primeiro uso do app — hoje o app abre direto na lista de NRs (Normas | Favoritos | Buscar); onde esse cadastro entra na navegação ainda não está definido (ver Lacuna D2).
- Monetização: a tabela atual (`docs/architecture.md`) reserva "diff completo" e "anotações" pro IAP `remove_ads_lifetime` (que hoje só remove ads, sem diferencial de conteúdo). Essa feature seria um diferencial de conteúdo muito mais forte que os atuais — pode virar argumento de venda do premium, ou ficar grátis como parte do valor central. Não decidido aqui (ver Lacuna D3).

## Perspectiva técnica

**Achado importante:** o Anexo II da NR-28 (item da NR ↔ código de infração ↔ gradação I1–I4 ↔ tipo S/M) **já está extraído como texto oficial** em `content/nr-28/nr-28.md` pelo pipeline padrão (mesmo tratamento de qualquer NR — nada de especial foi feito pra isso). Confirmado por grep direto no arquivo: blocos como `| NR-5 | ... | Item/Subitem | Código | Infração | Tipo |` já existem, com linhas tipo `5.4.13, 5.4.14... | 205125-7 | I3 | S`. Também confirmei que `content/nr-05/structure.json` guarda cada item com um campo `"number": "5.4.13"` — ou seja, dá pra casar o item da tabela do Anexo II com o parágrafo exato da NR via esse campo.

| Área | O que muda | Por quê | Risco |
|------|-----------|---------|-------|
| `content/nr-28/nr-28.md` | Nada — é a fonte primária do cruzamento | Já contém o Anexo II oficial extraído | baixo |
| `scripts/` (novo script) | Parse das tabelas do Anexo II do `nr-28.md`, split por bloco de NR, join com o campo `number` do `structure.json` de cada NR pra achar o parágrafo correspondente | Gera o cruzamento estruturado sem reescrever texto normativo — mesmo princípio de `index.json`/`search_index.json` | **médio** — blocos têm cabeçalhos inconsistentes (`**NR-14**`, `\| NR-1 \|`, `ANEXO I` vs `Anexo I` vs `ANEXO 1`), notas de portaria intercaladas quebram a sequência de tabelas, e linhas tipo `"3.1.1 e 3.1.3 do Anexo I"` são ambíguas (Anexo I *da própria NR*, não da NR-28) |
| `content/nr-XX/` (novo artefato, ex. `compliance.json`) | Novo arquivo por NR com os itens sinalizados + código/gradação/tipo + (se a camada rica entrar) explicação/checklist curada | Segue o padrão já usado (`index.json`, `search_index.json`), versionado no Git, sem custo de backend | baixo, depois do parser acima funcionar |
| `manifest.json` / `build_manifest.py` | Provavelmente referenciar o novo artefato por NR | Pro app buscar/cachear via GitHub raw como os outros arquivos | baixo |
| Conteúdo curado (explicação/checklist por item) | Novo *tipo* de conteúdo — não vem do PDF. Decisão desta sessão: será **completo e manual**, atualizado quando a norma mudar (não automático) | Curadoria fora do pipeline de extração — precisa de processo próprio de autoria/revisão | médio — depende de quem escreve (ver Lacuna D1) |
| Sinalização de "checklist desatualizado" | Precisa de algo como `reviewed_against_hash` por NR no artefato de compliance, comparado ao `hash` atual no manifest | Sem isso, o checklist manual fica **silenciosamente** desatualizado quando a NR muda — a atualização automática do dado cru (Anexo II) não cobre a camada de explicação | médio |
| `app/lib/features/` (novo, ex. `company_profile/`) | Tela de cadastro do perfil da empresa (porte, atividade, fatores de risco) | Pedido explícito do usuário | médio-alto — modelo de dados novo, motor de correspondência perfil → NRs/itens aplicáveis, persistência local (sem backend) |
| `app/lib/features/` (novo, ex. `compliance/checklist`) | Tela de checklist consolidado entre as NRs aplicáveis ao perfil, com estado verificado/pendente persistido localmente | Pedido explícito do usuário | médio |
| `app/lib/features/reader/` | Deep-link: item do checklist → abrir o leitor já navegado até o item específico | Pedido explícito ("direcionar o usuário pra NR... item que ele ficou em dúvida") | médio — `index.json` já tem `id` por heading, então parece viável, mas não confirmei se o leitor atual já suporta scroll-to-anchor por id |
| Navegação do app | Onde a tela de perfil/checklist entra (onboarding obrigatório, opcional em Ajustes, nova aba?) | Muda a navegação hoje fixa (Normas \| Favoritos \| Buscar) | não resolvido (Lacuna D2) |

## Fidelidade de conteúdo

- O **dado cru** (item ↔ código ↔ gradação ↔ tipo) é texto oficial já extraído pelo pipeline — não fere o princípio "nunca reescrever texto normativo" (`CLAUDE.md`).
- A **camada de explicação/checklist** que o usuário quer completa é conteúdo **novo e interpretativo** — não é o texto da norma, é derivado dela. O pipeline atual não tem esse tipo de conteúdo hoje (só extrai/estrutura texto oficial). Precisa virar um processo de autoria/revisão separado do pipeline de extração automática — o texto oficial continua acessível na íntegra via link, então não há substituição, só uma camada explicativa ao lado.
- Risco jurídico de enquadramento (o material que o usuário trouxe já identificou isso corretamente): a gradação I1–I4 não equivale a um valor de multa fixo — depende do número de empregados e outros fatores do Anexo I. Rótulo tipo "sujeito a penalidade conforme NR-28" é mais seguro que "gera multa de R$X". É decisão de copy pro `/decidir`, não bloqueia o mapeamento.
- Sobre a preocupação original do usuário ("como isso atualiza automático"): **parcialmente resolvida**. O dado cru (Anexo II) já está coberto pelo pipeline diário existente — qualquer mudança na NR-28 ou nas NRs referenciadas é detectada automaticamente (mudança de hash), igual a qualquer outra NR hoje. A camada de explicação manual **não** se atualiza sozinha — por decisão desta sessão, isso é aceito (normas mudam pouco, atualização manual quando necessário), mas precisa de um sinalizador de "desatualizado" pra não passar despercebido.

## Decisões já resolvidas com o usuário nesta sessão

| Pergunta | Opção escolhida | Por quê |
|----------|------------------|---------|
| Profundidade do conteúdo (dado cru vs. dado cru + explicação) | **Dado cru + explicação/checklist completo por item** | Usuário quer "algo completo para o usuário final"; aceita que a curadoria seja manual e atualizada quando a norma mudar, já que "essas normas não mudam com frequência" |
| Escopo da visão (só pontos de atenção na NR vs. perfil de empresa) | **Perfil da empresa (tela nova) → checklist consolidado entre NRs aplicáveis → link de cada item para ler o texto completo na NR quando em dúvida** | Resolve o problema completo descrito (técnico que indica pontos aos clientes / profissional interno sem formação jurídica), não só uma sinalização dentro de uma NR isolada |

## todo.md

- [ ] Nova demanda (parcialmente prevista)
- Linha relevante: "Checklists interativos → pós-lançamento (Fase 6+)" em [`.claude/decisions/escopo-mvp-evitar-features-soltas.md`](../decisions/escopo-mvp-evitar-features-soltas.md) — mesma família de ideia, mas essa decisão não previa o cruzamento com NR-28 nem o perfil de empresa. `docs/architecture.md` também já cita "Checklist prático (quando a NR tiver um aplicável)" na seção "Evoluções pós-MVP" como candidata condicionada aos critérios de sucesso de 90 dias.

## Lacunas ainda abertas

### D1 — Autoria do conteúdo curado *(bloqueia: Sim)*

**Dúvida?**
Quem escreve/revisa o conteúdo curado (explicação/checklist) por item?

**Opções**
1. Você mesmo — controle total, mas consome seu tempo e depende da sua disponibilidade
2. Um profissional de SST parceiro — mais confiável juridicamente, mas custo e dependência externa
3. Rascunho via IA, revisado por humano antes de publicar — acelera a cobertura de todas as NRs, mas exige um passo de revisão manual por norma antes de publicar

**Resposta:** 3, quero criar a funcionalidade junto com IA, vou ver se ta ok, vou ver se uma profissional gosta ja publicado, ai vou monitorar, se mudar algo eu atualizo o app

### D2 — Onde entra na navegação *(bloqueia: Sim)*

**Dúvida?**
Onde essa feature entra na navegação: onboarding obrigatório, opcional em Ajustes/nova aba, ou acessível a partir de uma NR específica?

**Opções**
1. Onboarding obrigatório no primeiro uso — garante que todo usuário passe pelo cadastro, mas atrasa a entrada no app
2. Opcional, disponível em Ajustes ou nova aba — menos fricção, mas menos gente descobre a feature
3. Acessível a partir de uma NR específica (ex.: botão dentro do leitor) — contextual, mas não dá a visão consolidada entre NRs que o usuário pediu

**Resposta:**opciona, mas tem q ser uma nova aba, n pode ficar escondido do usuário, como é algo para a empresa, n pode ficar fixo a uma nr especifica, uma empresa pode precisar de 0 ou varias nr

### D3 — Monetização *(bloqueia: Não)*

**Dúvida?**
Essa feature fica grátis (valor central do app) ou vira diferencial do IAP `remove_ads_lifetime`?

**Opções**
1. Grátis — reforça o valor central do app, sem criar mais uma decisão de compra
2. Diferencial do IAP — dá ao `remove_ads_lifetime` um benefício de conteúdo, não só remoção de ads

**Resposta:**inicialmente gratis, para validarmos, e monetizar com ads

### D4 — Timing frente à decisão de adiar checklists *(bloqueia: Não)*

**Dúvida?**
Entra antes de validar os critérios de sucesso de 90 dias (contrariando a decisão registrada de adiar checklists) ou fica condicionado a eles?

**Opções**
1. Entra agora, tratando como exceção à decisão registrada
2. Fica condicionado aos critérios de sucesso de 90 dias, como já decidido em [`escopo-mvp-evitar-features-soltas`](../decisions/escopo-mvp-evitar-features-soltas.md)

**Resposta:**1, necessidade de cliente que tem network para mais usuários usarem o app

### D5 — Estratégia de parsing do Anexo II *(bloqueia: Sim, para `/plano`; não bloqueia `/decidir`)*

**Dúvida?**
Como separar os blocos do Anexo II por NR, tratar referências ambíguas ("do Anexo I" da própria NR vs. da NR-28) e notas de portaria intercaladas?

**Opções**
1. Prova de conceito com 2-3 NRs (ex. NR-5, NR-6, NR-35) antes de generalizar para todas
2. Tentar parsing genérico direto para todas as NRs de uma vez

**Resposta:**precisamos achar uma alternativa, vc pode buscar na internet como esta atualmente as regras ao inves de tentar fazer parse de tabela, esse parse ta meio ruim mesmo, como essa informação n vai ser atualizada de forma automatica, n precisamos nos preocupar com isso, buscamos agr informações exatas e verdadeiras, colocamos avisos de que pode estar errado regras atualizadas data xx/xx/xxxx, e quando mudar algo ai eu ajusto no app e lanço uma nova versao, só n podemos confundir o usuário, essa nova funcionalidade precisa atualizar o app, ja as nrs completas sao atualizadas de forma automática

