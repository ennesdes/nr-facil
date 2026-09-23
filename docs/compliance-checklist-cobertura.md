# Checklist de conformidade (NR-28) — o que cobre e o que falta

> Mapa de conteúdo do `app/assets/compliance/compliance.json`, atualizado em 22/09/2026. Não é um documento de arquitetura — é só o inventário do que já está dentro do checklist hoje, para referência rápida e para levar ao profissional de SST revisar.

## O que o checklist cobre hoje

**7 normas, 14 itens, todos com código de infração, gradação (I1-I4) e tipo (S/M) oficiais da NR-28.**

| NR | Item | O que cobre | Gradação | Tipo | Fator de risco no perfil |
|----|------|-------------|----------|------|---------------------------|
| NR-1 | 1.4.1 | Deveres gerais do empregador (cumprir normas, informar riscos, ordens de serviço, procedimentos p/ acidente) | I3 (varia I2-I4 por alínea) | S | Tenho empregados CLT |
| NR-1 | 1.5.3.1 / 1.5.3.1.1 | Implementar o PGR (Programa de Gerenciamento de Riscos) | I3 | S | Tenho empregados CLT |
| NR-5 | 5.2.1 / 5.8.1 / 5.8.1.1 | Constituir a CIPA | I4 | S | Tenho empregados CLT |
| NR-5 | 5.4.13 / 5.4.14 / 5.8.2 / 5.8.2.3 | Nomear representante quando dispensada de CIPA própria | I3 | S | Presto serviços a terceiros |
| NR-5 | 5.3.1 | Cumprir atribuições da CIPA (inclui promover a SIPAT) | I2 | S | Já tem CIPA constituída |
| NR-6 | 6.5.1 | Fornecer, exigir uso e manter o EPI | I3 (varia I2-I4 por alínea) | S | Usa EPI |
| NR-7 | 7.5.1 | Elaborar o PCMSO com base no PGR | I4 | M | Tenho empregados CLT |
| NR-7 | 7.4.1 | Garantir e custear o PCMSO, indicar médico responsável | I2 (varia; alínea "a" é I4) | M | Tenho empregados CLT |
| NR-12 | 12.1.7 | Adotar medidas de proteção em máquinas e equipamentos | I3 | S | Possui máquinas |
| NR-17 | 17.3.1 | Realizar avaliação ergonômica preliminar | I4 | S | Tenho empregados CLT |
| NR-35 | 35.3.1 | Responsabilidades gerais da empresa no trabalho em altura | I3 (varia; alínea "h" é I4) | S | Trabalho em altura |
| NR-35 | 35.4.1 | Autorizar formalmente o trabalhador para trabalho em altura | I4 | S | Trabalho em altura |
| NR-35 | 35.5.1 | Planejar e organizar todo trabalho em altura (AR/PT) | I2 | S | Trabalho em altura |
| NR-35 | 35.6.1 | Usar Sistema de Proteção Contra Quedas (SPQ) | I4 | S | Trabalho em altura |

Cada item no arquivo real também tem: o código de infração exato da NR-28, a explicação completa (o texto acima é resumido) e o `reader_anchor_id` (âncora pra abrir o texto oficial da NR direto naquele ponto).

### Fatores de risco do perfil da empresa (6 hoje)

Tenho empregados CLT · Presto serviços a terceiros · Já tem CIPA constituída · Usa EPI · Trabalho em altura · Possui máquinas.

## O que NÃO está coberto (limitações conhecidas)

- **Só 7 das ~38 NRs vigentes.** Prioridade foi dar as normas de aplicação mais ampla (NR-1, NR-7 aplicam a quase toda empresa) + os exemplos originais (NR-5, NR-6, NR-35).
- **Normas de peso que ainda faltam**, se quiser continuar depois: NR-4 (SESMT — não tem tabela de infração própria na NR-28, verificar com o profissional), NR-9/NR-15/NR-16 (insalubridade/periculosidade), NR-10 (elétrica), NR-18 (construção civil), NR-20 (inflamáveis/combustíveis), NR-23 (incêndio), NR-24 (condições sanitárias), NR-33 (espaço confinado).
- **Dentro das 7 normas cobertas, só os itens mais centrais foram extraídos** — cada NR tem dezenas de itens na tabela da NR-28 (ex.: NR-35 sozinha tem mais de 60 linhas), aqui entrou 1 a 4 por norma, os que mais diretamente respondem "o que a empresa precisa fazer".
- **Nenhum item ainda foi revisado por um profissional de SST** — é o combinado (decisão registrada em `.claude/decisions/checklist-nr28-empresa.md`, item D1): IA monta o rascunho, profissional revisa depois de publicado.
- **Um item foi descartado por inconsistência**: a tabela da NR-28 aponta o item 6.3.1 da NR-6 como infração, mas o texto atual desse item é só uma definição (não uma obrigação) — não incluído, mas vale o profissional saber que esse tipo de desalinhamento existe na tabela oficial.
- **3 itens não têm âncora pro leitor** (35.3.1, 35.5.1, 12.1.7) — o texto da norma não tem um heading próprio nesse ponto exato; abrir esses itens leva pra NR certa, mas não rola até o parágrafo exato.

## O que perguntar ao profissional (por item, ao revisar)

- A explicação está certa e completa pra alguém sem formação jurídica agir em cima dela?
- O "responsável" apontado está certo, ou muda conforme o porte da empresa?
- Falta prazo/periodicidade que a fiscalização cobra na prática?
- Existe pegadinha de campo (autuação comum que a empresa não esperava) que vale adicionar na explicação?
- Alguma das ~38 NRs faltantes é mais urgente pro público que vocês estão mirando?

## Onde isso vive no app

- Dado: `app/assets/compliance/compliance.json` — bundlado no app, **não** sincronizado pelo pipeline automático das NRs. Atualiza só quando sai uma nova versão do app na loja.
- Como usar: perfil da empresa (fatores de risco marcados) → checklist consolidado com esses itens → botão "Ver na norma" abre o texto oficial.
- Referências: `.claude/plans/checklist-nr28-empresa.md` (plano completo), `.claude/decisions/checklist-nr28-empresa.md` (decisões tomadas), `docs/architecture.md` § "Checklist de conformidade (NR-28)".
