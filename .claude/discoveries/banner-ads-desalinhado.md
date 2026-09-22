# Descoberta — Banner AdMob da Home aparece desalinhado à esquerda, cortando conteúdo

> Gerado por `/descobrir` · Consumido por `/decidir`

## Demanda

O banner de anúncio fixo acima da bottom nav (Normas/Favoritos/Buscar) às vezes renderiza deslocado todo para a esquerda, cortando parte do conteúdo — em vez do banner adaptativo centralizado e dimensionado corretamente que o código pretende produzir.

## Perspectiva do usuário

- O usuário relatou (via `AskUserQuestion` nesta sessão) que o problema acontece **direto ao abrir o app, sem ação específica** (não é ao girar a tela nem ao trocar de aba), e em **celular normal** (não tablet, não split-screen).
- Isso descarta rotação e o modo tablet como gatilho — é algo que acontece no **carregamento inicial** da Home, antes de qualquer interação do usuário.
- Impacto percebido: além de feio, o banner desalinhado corta visualmente parte do conteúdo da lista (Normas/Favoritos) logo acima da bottom nav — o primeiro contato do usuário com o app pode já vir com uma UI quebrada, o que é ruim para confiança/percepção de qualidade, mesmo não afetando a leitura offline em si.

## Perspectiva do produto

- Ads são a única fonte de receita hoje (Fase 5, item 33 — IAP `remove_ads_lifetime` só entra na Fase 6). Um banner quebrado na tela mais vista do app (Home, sempre visível) tem duplo custo: má impressão visual logo na abertura do app **e** risco de menor viewability/CTR do próprio anúncio (o que a rede AdMob também penaliza).
- Não é uma nova feature nem muda escopo do MVP — é regressão de qualidade em algo já implementado e "pronto" (item 33 já está `[x]` no todo.md).

## Perspectiva técnica

Contexto de código relevante:

- [`app/lib/features/ads/widgets/persistent_banner_ad.dart`](app/lib/features/ads/widgets/persistent_banner_ad.dart) — carrega o banner adaptativo via `AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width)`, onde `width = MediaQuery.sizeOf(context).width.truncate()` é lido em `didChangeDependencies()`. O tamanho resultante (`banner.size`) é usado para dimensionar um `SizedBox` fixo dentro de um `Center`, dentro de um `ClipRect`.
- Guarda de recarregamento: `if (width == _lastWidth && (_bannerAd != null || _isLoading)) return;` — só recarrega o banner quando a largura muda em relação à última carga bem-sucedida/em andamento.
- [`app/lib/features/home/views/home_page.dart`](app/lib/features/home/views/home_page.dart) — `PersistentBannerAd` fica dentro de `bottomNavigationBar: Column(...)`, **fora** de `ResponsiveContent` (que só envolve o `body`). Confirmado com o usuário que isso não é o gatilho aqui (problema ocorre em celular normal), mas é um risco técnico separado que vale registrar: em tablet, o banner pode pedir um `AdSize` baseado na largura cheia da tela enquanto o conteúdo da lista fica limitado a `kListContentMaxWidth` (840dp) — larguras diferentes entre banner e conteúdo. Não é a causa do bug relatado, mas é uma inconsistência latente no mesmo componente.
- Sem teste de widget cobrindo `PersistentBannerAd` (`app/test/features/ads/` só tem `ads_eligibility_test.dart`, que cobre cooldown do interstitial, não o banner).
- Não há lock de orientação (`android:configChanges` inclui `screenSize|smallestScreenSize|density`, sem `screenOrientation` fixo no manifest, sem `SystemChrome.setPreferredOrientations` no código) — rotação é fisicamente possível, mas o usuário confirmou que não é o gatilho neste caso.

**Hipótese técnica principal (dado "acontece ao abrir o app, sem ação"):**

`didChangeDependencies()` roda na montagem inicial do widget, antes do primeiro frame estabilizar completamente. Se `MediaQuery.sizeOf(context).width` retornar um valor transitório/incorreto nesse instante (ex.: durante a transição splash → Home, ou antes das métricas de janela do Android se assentarem), o banner é carregado com um tamanho errado — e como a guarda de recarregamento só reage a **mudança** de largura (não a "correção"), se a largura relatada pelo MediaQuery não mudar de novo depois, o banner errado fica preso pelo resto da sessão. Isso bate com "sempre ao abrir, sem ação específica": não depende de rotação porque o problema não é a largura mudar — é a largura estar errada já na primeira leitura.

Hipótese alternativa (não descartável sem reprodução/log): o `AdWidget`/platform view nativo do Android não reposiciona/redimensiona a tempo durante os primeiros frames de montagem da árvore de widgets (Home sendo construída rapidamente após o splash), deixando o conteúdo nativo do anúncio ancorado numa posição/tamanho de um frame anterior.

| Arquivo | O que pode mudar | Por quê | Risco |
|---------|-----------|---------|-------|
| `app/lib/features/ads/widgets/persistent_banner_ad.dart` | Adiar/validar a leitura de `MediaQuery` usada para o primeiro carregamento (ex.: aguardar o primeiro frame pós-layout via `addPostFrameCallback`, ou obter a largura do próprio `RenderBox`/`LayoutBuilder` do slot do banner em vez do `MediaQuery` global) | Corrige a hipótese principal (largura errada na primeira leitura, nunca corrigida) | médio — mexe na lógica central de carregamento/guarda de recarregamento; precisa não reintroduzir re-carregamentos desnecessários (custo de requisição de ad) |
| `app/test/features/ads/` (novo arquivo) | Adicionar teste de widget para `PersistentBannerAd` cobrindo o cenário de carregamento inicial | Hoje não há nenhuma cobertura de teste para esse widget | baixo |

Nenhum outro arquivo do pipeline Python, `manifest.json` ou `app_meta.json` é afetado — isso é puramente um bug de UI/timing no app Flutter.

## Fidelidade de conteúdo

Não aplicável — não toca `content/`, pipeline ou texto normativo.

## Decisões já resolvidas com o usuário nesta sessão

| Pergunta | Opção escolhida | Por quê |
|----------|------------------|---------|
| Em que situação o banner fica estranho? | Direto ao abrir o app, sem ação específica | Descarta rotação e troca de aba como gatilho; aponta para um problema de largura incorreta já na primeira carga |
| Em qual tipo de aparelho? | Celular normal | Descarta a inconsistência `ResponsiveContent`/tablet como causa deste caso específico (mas ela continua registrada como risco técnico latente acima) |

## todo.md

- [x] Previsto — item 33 "AdMob no app (banner só em listas)" já está fechado; esta descoberta é sobre uma **regressão/bug** num item já entregue, não uma feature nova.

## Lacunas ainda abertas

### D1 — Confirmar a causa raiz antes de escolher a correção *(bloqueia: Sim)*

**Dúvida?**
Existem duas hipóteses técnicas plausíveis (largura errada na primeira leitura do `MediaQuery` vs. atraso de reposicionamento da platform view nativa do anúncio), e elas levam a correções diferentes. Sem reproduzir/instrumentar (log da largura lida em cada carga, e/ou captura de tela do banner quebrado com o valor de `banner.size` naquele momento), não dá para saber com certeza qual mecanismo está causando o bug — só ajustar às cegas arrisca "corrigir" um sintoma sem resolver a causa.

**Opções**
1. Adicionar log temporário (`AppLogger`) com a largura lida e o `banner.size` retornado a cada carregamento, pedir para o usuário reproduzir e mandar o log — mais lento, mas correção certeira.
2. Ir direto para a correção defensiva mais provável (validar/estabilizar a largura antes do primeiro carregamento, via `addPostFrameCallback` ou `LayoutBuilder`) e observar se o sintoma some — mais rápido, risco de não resolver se a causa real for outra (platform view).

**Resposta:**2, eu acho q tem haver com renderização msm, quando entro em uma nr e depois volto para tela inicial o anuncio aparecer normalmente, ou pode até ser um anuncio especifico, n sei, mas da para ver o código e analisar possiveis causas

