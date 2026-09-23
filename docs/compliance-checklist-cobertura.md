# Checklist de conformidade (NR-28) — o que cobre e o que falta

> Mapa de conteúdo do `app/assets/compliance/compliance.json`, atualizado em 22/09/2026. Não é um documento de arquitetura — é o inventário do dataset para referência rápida e revisão por profissional de SST.

## Motor de correspondência

O checklist usa **segmento da empresa** (base) **somado** aos **fatores de risco** marcados no perfil (regra aditiva — OR). Um item entra se a NR dele está no `nr_ids_base` do segmento escolhido **ou** se algum fator de risco do item coincide com o perfil. Itens não duplicam quando os dois critérios batem ao mesmo tempo.

**6 segmentos** (dropdown data-driven no perfil):

| Segmento | NRs na base (além de NR-01, NR-05, NR-07 e NR-24 em todos) |
|----------|--------------------------------------------------------------|
| Comércio | NR-17 |
| Serviços/Escritório | NR-17 |
| Indústria | NR-11, NR-12, NR-15 |
| Construção Civil | NR-18, NR-35 |
| Saúde | NR-32 |
| Transporte/Logística | NR-11, NR-16 |

NR-06 (EPI), NR-35 (fora de Construção Civil) e demais itens ligados a fatores específicos continuam entrando **só** quando o fator correspondente está marcado, mesmo que a NR não esteja na base do segmento.

## O que o checklist cobre hoje

**13 normas, 32 itens**, todos com código de infração, gradação (I1–I4) e tipo (S/M) oficiais da NR-28.

| NR | Item | O que cobre | Gradação | Tipo | Segmento / fator |
|----|------|-------------|----------|------|------------------|
| NR-1 | 1.4.1 | Deveres gerais do empregador | I3 (varia I2–I4) | S | Fator: empregados CLT |
| NR-1 | 1.5.3.1 / 1.5.3.1.1 | Implementar o PGR | I3 | S | Fator: empregados CLT |
| NR-5 | 5.2.1 / 5.8.1 / 5.8.1.1 | Constituir a CIPA | I4 | S | Fator: empregados CLT |
| NR-5 | 5.4.13 / 5.4.14 / 5.8.2 / 5.8.2.3 | Nomear representante (prestadora) | I3 | S | Fator: serviços a terceiros |
| NR-5 | 5.3.1 | Atribuições da CIPA (SIPAT etc.) | I2 | S | Fator: CIPA constituída |
| NR-6 | 6.5.1 | Fornecer, exigir e manter EPI | I3 (varia) | S | Fator: usa EPI |
| NR-7 | 7.5.1 | PCMSO com base no PGR | I4 | M | Fator: empregados CLT |
| NR-7 | 7.4.1 | Garantir e custear PCMSO | I2 (varia) | M | Fator: empregados CLT |
| NR-11 | 11.1.5 / 11.1.6 / 11.1.6.1 | Treino e habilitação de operadores | I3 | S | Indústria, Transporte/Logística |
| NR-11 | 11.3.2–11.3.5 | Armazenamento seguro de materiais | I3 | S | Indústria, Transporte/Logística |
| NR-12 | 12.1.7 | Medidas de proteção em máquinas | I3 | S | Indústria; fator: máquinas |
| NR-12 | 12.5.1 | Proteções em zonas de perigo | I4 | S | Indústria; fator: máquinas |
| NR-12 | 12.16.2 | Capacitação em máquinas | I2 | S | Indústria; fator: máquinas |
| NR-15 | 15.2 | Adicional de insalubridade | I1 | S | Indústria |
| NR-16 | 16.2 | Adicional de periculosidade | I1 | S | Transporte/Logística |
| NR-16 | 16.8 | Delimitação de áreas de risco | I3 | S | Transporte/Logística |
| NR-17 | 17.3.1 | Avaliação ergonômica preliminar | I4 | S | Comércio, Serviços; fator CLT |
| NR-17 | 17.4.3 | Prevenção de posturas/movimentos repetitivos | I4 | S | Comércio, Serviços |
| NR-17 | 17.6.1 | Mobiliário regulável | I4 | S | Comércio, Serviços |
| NR-18 | 18.4.1 / 18.4.5 | PGR no canteiro | I3 | S | Construção Civil |
| NR-18 | 18.5.1 | Áreas de vivência | I3 | S | Construção Civil |
| NR-18 | 18.9.4 / 18.9.4.1 | Proteção na periferia da obra | I3 | S | Construção Civil |
| NR-24 | 24.2.1 | Instalações sanitárias | I2 | S | Todos os segmentos |
| NR-24 | 24.9.1 | Água potável | I2 | S | Todos os segmentos |
| NR-32 | 32.2.2.1 inc. I | Riscos biológicos no PGR | I3 | S | Saúde |
| NR-32 | 32.2.4.15 | Vedado reencape de agulhas | I4 | S | Saúde |
| NR-32 | 32.2.4.17.1–17.7 | Imunização dos trabalhadores | I4 | M | Saúde |
| NR-35 | 35.3.1 | Responsabilidades no trabalho em altura | I3 (varia) | S | Construção Civil; fator altura |
| NR-35 | 35.4.1 | Autorização formal | I4 | S | Construção Civil; fator altura |
| NR-35 | 35.4.2.1 | Treinamento inicial (8 h) | I3 | S | Construção Civil; fator altura |
| NR-35 | 35.5.1 | Planejar trabalho em altura | I2 | S | Construção Civil; fator altura |
| NR-35 | 35.6.1 | Sistema de proteção contra quedas | I4 | S | Construção Civil; fator altura |

Cada item no JSON também traz `explicacao` completa, `responsavel`, `codigo_infracao` e `reader_anchor_id` (âncora no leitor da NR, quando existe heading no `content/`).

### Fatores de risco do perfil (6)

Tenho empregados CLT · Presto serviços a terceiros · Já tem CIPA constituída · Usa EPI · Trabalho em altura · Possui máquinas.

## O que NÃO está coberto (limitações conhecidas)

- **13 das ~38 NRs vigentes** — conjunto ampliado por segmento, ainda não exaustivo.
- **Normas relevantes fora desta leva**, se quiser continuar depois: NR-4 (SESMT — sem tabela própria confirmada na NR-28), NR-9/NR-10 (agentes físicos/elétrica), NR-20 (inflamáveis), NR-23 (incêndio), NR-33 (espaço confinado), entre outras.
- **Dentro de cada NR, só itens centrais** — cada norma tem dezenas de linhas na tabela da NR-28.
- **Nenhum item foi revisado por profissional de SST** — rascunho com IA, revisão prevista após publicação (`.claude/decisions/checklist-nr28-empresa.md`, D1).
- **Item descartado por inconsistência**: NR-6 item 6.3.1 (definição, não obrigação) — não incluído.
- **Âncoras vazias** em NR-11, NR-15, NR-16, NR-32, partes de NR-12 e NR-35 — abre a NR correta, mas não rola até o parágrafo exato no leitor.

## O que perguntar ao profissional (por item, ao revisar)

- A explicação está certa e acionável para quem não é jurista?
- O responsável indicado faz sentido para o porte da empresa?
- Falta prazo ou periodicidade que a fiscalização cobra na prática?
- Alguma NR fora das 13 é prioridade para o público-alvo?

## Onde isso vive no app

- Dado: `app/assets/compliance/compliance.json` — bundlado, **não** sincronizado pelo pipeline das NRs.
- Fluxo: perfil (segmento + fatores) → checklist → “Ver na norma”.
- Plano da expansão: [`.claude/plans/checklist-cobertura-completa.md`](../.claude/plans/checklist-cobertura-completa.md).
