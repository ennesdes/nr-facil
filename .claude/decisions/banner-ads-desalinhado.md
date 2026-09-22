# Decisão — Banner AdMob da Home aparece desalinhado à esquerda, cortando conteúdo

> Gerado por `/decidir` a partir de `.claude/discoveries/banner-ads-desalinhado.md` (lacuna D1)
> Consumido por `/fazer`

## Contexto

A descoberta (`.claude/discoveries/banner-ads-desalinhado.md`) já havia isolado o gatilho com o usuário: o banner aparece quebrado **direto ao abrir o app**, em **celular normal**, sem rotação nem troca de aba envolvida. A lacuna D1 perguntava se valia a pena instrumentar/logar antes de corrigir, ou ir direto para a correção defensiva mais provável.

O usuário respondeu diretamente no campo **Resposta** do bloco D1 (não em branco — não foi delegado a agente), escolhendo a opção 2, com um dado novo e importante:

> "eu acho q tem haver com renderização msm, quando entro em uma nr e depois volto para tela inicial o anuncio aparecer normalmente, ou pode até ser um anuncio especifico, n sei, mas da para ver o código e analisar possiveis causas"

Esse dado reforça a **Hipótese técnica principal** já registrada na descoberta: `didChangeDependencies()` lê uma largura errada/transitória na primeira montagem da Home (splash → Home), carrega o banner com o tamanho errado, e a guarda de recarregamento (`width == _lastWidth`) só reage a **mudança** de largura — não a uma leitura "atrasada, porém correta". Entrar numa NR e voltar aciona um novo ciclo de `didChangeDependencies` na Home (a navegação altera a árvore/MediaQuery observado), momento em que a largura já está estável — e por isso o banner volta ao normal. Isso é consistente com o comportamento relatado e reduz a necessidade de log/instrumentação separada (opção 1) — a análise do código já explica o padrão observado.

## Opções apresentadas na descoberta

1. **Instrumentar primeiro** — logar largura lida e `banner.size` a cada carregamento, pedir para o usuário reproduzir e mandar o log antes de corrigir. Mais lento, correção certeira.
2. **Correção defensiva direta** — validar/estabilizar a largura antes do primeiro carregamento (ex.: `addPostFrameCallback`, ou obter a largura via `LayoutBuilder` do próprio slot em vez do `MediaQuery` global), observando se o sintoma some. Mais rápido, risco de não resolver se a causa real for outra.

## Escolha do usuário

**Opção 2 — correção defensiva direta**, com uma condição explícita do usuário: **antes de aplicar a correção, analisar o código para confirmar a causa mais provável** (não aplicar às cegas) — o usuário não quer só "tentar e ver se resolve" sem entendimento, mas também não quer o ciclo completo de instrumentação/log/reprodução da opção 1.

## Justificativa (do usuário)

- O padrão relatado — abrir uma NR e voltar para a Home "conserta" o anúncio — é, na visão do usuário, mais compatível com um problema de renderização/timing do próprio banner do que com algo específico de um anúncio (embora o usuário deixe essa segunda possibilidade em aberto, sem descartar).
- O usuário confia que a análise do código (já levantada na descoberta) é suficiente para mirar a correção certa, sem precisar do ciclo de log + reprodução.

## Impacto esperado

- **Custo:** nenhum custo de operação (GitHub Actions, serviços externos) — mudança é só no app Flutter.
- **Esforço:** baixo/médio — ajuste concentrado em `persistent_banner_ad.dart` (garantir que a primeira leitura de largura usada para carregar o banner adaptativo seja a largura final/estável, e não uma leitura transitória do frame inicial), mais um teste de widget cobrindo o cenário de carregamento inicial (hoje sem cobertura).
- **Risco:** médio — a mudança mexe na lógica central de carregamento/guarda de recarregamento; precisa preservar o comportamento correto em rotação e troca de tamanho de tela (não pode reintroduzir recarregamentos desnecessários, que têm custo de requisição de anúncio) e precisa ser validada num carregamento real do app (não só em teste), já que o bug é de timing/plataforma nativa e pode não se manifestar do mesmo jeito em ambiente de teste headless.
- Risco residual aceito: se a causa real for a hipótese alternativa (platform view nativa não reposicionando a tempo), a correção pode não eliminar 100% o sintoma — isso será visível ao validar no app real, e nesse caso a opção 1 (instrumentar) fica como próximo recurso.

## Relacionado (não é o escopo desta correção, registrado como risco técnico latente)

A descoberta também registrou uma inconsistência separada, não confirmada como causa deste bug: em tablets, `PersistentBannerAd` fica fora de `ResponsiveContent` e pode pedir um `AdSize` mais largo que o conteúdo da lista (`kListContentMaxWidth`). Não faz parte desta decisão — fica registrado para uma descoberta futura, caso surjam relatos em tablet.
