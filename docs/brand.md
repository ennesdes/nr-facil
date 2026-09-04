# NR Fácil — Identidade Visual (Brand Book)

Referência de marca para o app, assets da Play Store e comunicação externa.  
Implementação técnica dos tokens: [design-system.md](design-system.md).

---

## 1. Missão e posicionamento

### O que é

**NR Fácil** é um app Android para consulta **offline** das Normas Regulamentadoras oficiais do Ministério do Trabalho e Emprego (MTE), com busca, favoritos e atualização automática via GitHub.

### Proposta de valor

| Benefício | Mensagem |
|-----------|----------|
| Offline | Consulte NRs sem internet, em campo ou no escritório |
| Atualizado | Sincronização automática quando o texto normativo mudar |
| Rápido | Busca full-text com destaque de trechos |
| Gratuito | Todas as NRs disponíveis sem paywall de conteúdo |

### Posicionamento

NR Fácil é uma **ferramenta de trabalho** para profissionais de SST — não um app institucional do governo. É um organizador e leitor de conteúdo público oficial: complementa, nunca substitui, as publicações no portal gov.br.

### Público-alvo

- Técnicos de segurança do trabalho, SESMT, CIPA
- Engenheiros, médicos do trabalho, ergonomistas
- Empregadores e gestores que consultam NRs no dia a dia

### Diferencial competitivo

- Offline-first (sem depender de conexão em obra/indústria)
- Zero backend — conteúdo versionado no GitHub, custo operacional R$ 0
- Feed de atualizações granular (o que mudou, por seção)

---

## 2. Princípios de design

Estes princípios guiam todas as decisões visuais e de UX:

| Princípio | Significado |
|-----------|-------------|
| **Clareza normativa** | Hierarquia tipográfica forte; leitura prolongada sem fadiga; destaque de busca sutil mas visível |
| **Confiança sem oficialidade** | Tom profissional e sóbrio; evitar verde-amarelo clichê de obra e qualquer semiótica governamental |
| **Acessível em campo** | Contraste WCAG AA mínimo; tamanho de fonte ajustável; touch targets ≥ 48dp |
| **Conteúdo em primeiro lugar** | UI discreta nas listas; leitor sem anúncios; chrome mínimo no texto normativo |
| **Estado sempre visível** | Badges semânticos consistentes: atualização, revogada, não baixada, offline |

---

## 3. Logo

### Conceito

Mark minimalista que combina o monograma **NR** com linhas horizontais que representam texto normativo (documento):

```
┌─────────────┐
│  NR         │  ← monograma "NR" em semibold
│  ───        │  ← 2–3 linhas = parágrafos de norma
└─────────────┘
```

### Especificações do ícone

| Propriedade | Valor |
|-------------|-------|
| Forma | Quadrado com cantos arredondados 12px |
| Fundo | `#0F5C4E` (primary) |
| Monograma | Branco `#FFFFFF`, peso semibold |
| Linhas decorativas | Branco 60% opacidade, 2–3 traços horizontais abaixo do monograma |
| Área de respiro | Padding interno mínimo 15% da largura do ícone |

### Variações

| Variação | Uso |
|----------|-----|
| **Ícone sólido** | Launcher do app, favicon, ícone 512×512 Play Store |
| **Ícone outline** | Fundos claros onde o sólido não contrasta |
| **Monocromático branco** | Sobre fundo `primary` (splash, feature graphic) |
| **Monocromático escuro** | Sobre fundo claro em materiais impressos |

### Wordmark

```
NR Fácil
^^       ^^^^^^
semibold  regular
```

- Família: Inter (mesma do app)
- "NR" em semibold; "Fácil" em regular
- Cor padrão: `onSurface` (`#1A1C1E`) em fundos claros; branco em fundos escuros
- Espaçamento entre ícone e wordmark: 12px

### Usos proibidos

- Capacete de obra, cruz médica, escudo/brasão
- Cores da bandeira brasileira como elemento dominante
- Logotipo ou brasão do MTE, gov.br ou da República
- Distorcer proporções, rotacionar ou aplicar gradientes no mark
- Usar o wordmark sem o ícone em tamanhos menores que 120px de largura (usar só o ícone)

---

## 4. Paleta de cores

Direção: **verde-teal institucional** — remete a segurança e compliance sem parecer sinalização de obra.

### Cores primárias (light mode)

| Nome | Hex | Uso |
|------|-----|-----|
| Primary | `#0F5C4E` | Labels NR, links, FAB, ícones ativos, splash |
| On Primary | `#FFFFFF` | Texto e ícones sobre primary |
| Primary Container | `#D4EDE6` | Fundo de chips selecionados, badges NR |
| On Primary Container | `#0A3D34` | Texto sobre primaryContainer |
| Secondary | `#1E3A5F` | Ênfase secundária, headers alternativos |
| Surface | `#FAFBFC` | Fundo geral (off-white, menos fadiga) |
| Surface Container | `#F0F2F4` | Containers, inputs, áreas elevadas |
| Surface Container High | `#E8EAED` | Preamble, footer do leitor (light) |
| Surface Bright | `#FFFFFF` | Cards brancos sobre fundo off-white |
| Outline | `#B0BAC4` | Bordas de input, divisores |
| On Surface | `#1A1C1E` | Texto principal |
| On Surface Variant | `#4A5560` | Metadata, subtítulos, placeholders |

### Cores semânticas (ambos os modos)

| Nome | Hex | Uso |
|------|-----|-----|
| Success | `#2E7D4F` | Sync OK, download concluído, verificado |
| Warning | `#B45309` | Atualização disponível, avisos |
| Warning Container | `#FEF3C7` | Fundo badge "Atualização disponível" |
| On Warning Container | `#92400E` | Texto sobre warningContainer |
| Error | `#C62828` | Erros, badge de notificação |
| Info | `#1565A8` | Links externos (PDF MTE), banners informativos |
| Info Container | `#E3F0FA` | Fundo do UpdateBanner |
| On Info Container | `#0D4A7A` | Texto/CTA sobre infoContainer |
| Search Highlight | `#FFF3CD` / `#5C4A1A` | Destaque de busca (light / dark) |
| On Search Highlight | `#1A1C1E` / `#FFE082` | Texto sobre highlight (light / dark) |
| Muted | `#6B7280` / `#9AA0A6` | Texto atenuado (light / dark) |

### Cores dark mode

| Nome | Hex | Uso |
|------|-----|-----|
| Surface | `#121212` | Fundo geral |
| Surface Container | `#1E1E1E` | Cards de seção no leitor |
| Surface Container High | `#2A2A2A` | Preamble, footer do leitor |
| On Surface | `#E8EAED` | Texto principal |
| On Surface Variant | `#B8BFC6` | Texto secundário |
| Outline | `#6E7A85` | Bordas e divisores |
| Primary | `#4DB6A0` | Labels NR (mais claro para contraste em fundo escuro) |

### Estados especiais

| Estado | Tratamento |
|--------|------------|
| NR revogada | Texto `muted` + badge com fundo `surfaceContainerHigh` |
| NR com atualização | Chip `warningContainer` + texto `onWarningContainer` |
| Não baixada | Ícone `cloud_off` em `onSurfaceVariant` |
| Highlight de busca | `searchHighlight` + `onSearchHighlight` (leitor e busca global) |

### Contraste

Todas as combinações texto/fundo críticas são validadas por `scripts/audit_contrast.py` (**WCAG 2.1 AA**: 4.5:1 texto normal, 3:1 texto grande).

---

## 5. Tipografia

### Família

**[Inter](https://fonts.google.com/specimen/Inter)** — Google Fonts, licença OFL.

Motivos: excelente legibilidade em português, números tabulares para labels "NR-06", ampla adoção em apps profissionais.

### Escala tipográfica (UI)

| Token | Tamanho | Peso | Uso |
|-------|---------|------|-----|
| Display Small | 28sp | 600 | Títulos de tela (Atualizações) |
| Title Large | 20sp | 600 | Títulos de seção |
| Title Medium | 16sp | 600 | Labels NR em listas |
| Body Large | 16sp | 400 | Títulos de NR, corpo do leitor (base) |
| Body Medium | 14sp | 400 | Listas, metadata |
| Body Small | 12sp | 400 | Disclaimer legal, timestamps |
| Label Medium | 12sp | 600 | Badges, chips |

### Leitor (escala relativa)

O usuário ajusta o tamanho base entre 12–20px. A escala relativa é:

- `h1` = base + 8
- `h2` = base + 6
- `h3` = base + 4
- Corpo = base, `lineHeight` 1.6
- Footer legal = `bodySmall` itálico, cor `onSurfaceVariant`

---

## 6. Iconografia

- **Biblioteca:** Material Symbols Outlined (peso consistente em todo o app)
- **Tamanhos:** 20dp (inline), 24dp (AppBar/ações), 48dp (estados vazios), 64dp (empty states principais)

| Contexto | Ícone |
|----------|-------|
| Leitor | `menu_book` |
| Favorito (ativo) | `star` |
| Favorito (inativo) | `star_outline` |
| Atualizações | `notifications` |
| Busca | `search` |
| Download | `download` |
| Não baixada / offline | `cloud_off` |
| PDF externo | `picture_as_pdf` |
| Erro | `error_outline` |
| Sucesso | `check_circle` |

---

## 7. Tom de voz

### Personalidade

- **Direto** — sem rodeios; o usuário está em campo e precisa de resposta rápida
- **Técnico** — vocabulário de SST quando necessário, mas sem jargão desnecessário
- **Confiável** — informa limitações (não substitui publicação oficial) sem alarmismo
- **Neutro** — sem superlativos de marketing

### Verbos preferidos

Consultar, Baixar, Atualizar, Sincronizar, Buscar, Favoritar, Continuar leitura

### Evitar

- "O melhor app de NRs"
- "Oficial do MTE" (não somos)
- "Grátis para sempre" (pode haver IAP no futuro)
- Emojis em UI (exceto onde já existir legado a migrar)

### Exemplos de copy

| Contexto | Copy |
|----------|------|
| Título Play Store | NR Fácil: Normas do Trabalho |
| Descrição curta | Normas Regulamentadoras offline: busca, favoritos e atualização automática. |
| Empty state favoritos | Você ainda não tem favoritos. Toque na estrela em qualquer NR para adicionar. |
| Erro de sync | Não foi possível sincronizar. Verifique sua conexão e tente novamente. |
| Atualização obrigatória | Uma nova versão do app é necessária para continuar. |
| Disclaimer legal | Este aplicativo disponibiliza conteúdo público oficial das Normas Regulamentadoras do Ministério do Trabalho e Emprego. O conteúdo não substitui a consulta às publicações oficiais no portal gov.br. |
| Badge atualização | Atualização disponível |
| Badge revogada | Revogada |
| Link PDF | Ver PDF original no MTE |

---

## 8. Restrições legais de marca

### Conteúdo normativo

Textos de leis, decretos e atos oficiais são de domínio público (Lei 9.610/98, art. 8º, IV). NRs podem ser reproduzidas sem licença do órgão, desde que o texto não seja alterado.

### O que NÃO fazer

- Usar brasão da República ou logotipos oficiais do MTE/gov.br (proteção de marca)
- Sugerir oficialidade ou vínculo institucional com o governo
- Alterar o texto normativo exibido no app
- Omitir o disclaimer legal no leitor

### O que fazer

- Manter disclaimer visível no footer de cada NR
- Link para PDF original no portal MTE
- Guardar PDF original + `pdf_hash` como evidência de fidelidade (pipeline)

---

## 9. Assets da Play Store (Fase 5)

Especificações e arquivos gerados para o item 37 do [todo.md](../todo.md):

| Asset | Dimensão | Arquivo |
|-------|----------|---------|
| Ícone launcher (fonte) | 1024×1024 | `app/assets/branding/app_icon.png` |
| Ícone Play Store | 512×512 | `docs/store/play_store_icon_512.png` |
| Feature graphic | 1024×500 | `docs/store/feature_graphic_1024x500.png` |
| Splash (mark) | 512×512 | `app/assets/branding/splash_mark.png` |

Fontes SVG versionadas em `app/assets/branding/`. Regenerar PNGs: `python3 scripts/generate_branding.py` (ver `docs/store/README.md`).

| Asset | Dimensão | Diretriz |
|-------|----------|----------|
| Ícone | 512×512 px | Mark NR sobre fundo `primary`; sem wordmark (ilegível em tamanho pequeno) |
| Feature graphic | 1024×500 px | Fundo `surface`; wordmark + tagline "Consulte NRs oficiais offline" |
| Screenshots | ≥ 4 telas | Home/Favoritos, Leitor, Busca com highlight, Atualizações — modo claro |
| Splash screen | Full screen | Fundo `primary` + mark branco centralizado (via `flutter_native_splash`) |

### Estilo de screenshots

- Modo claro como padrão (maioria dos usuários)
- Device frame opcional (Pixel ou genérico Android)
- Sem texto promocional sobreposto nas capturas (regra Play Store)
- Mostrar conteúdo real (NR-06 ou similar), não placeholders

---

## 10. Referências

- [design-system.md](design-system.md) — tokens técnicos e specs de componentes
- [architecture.md](architecture.md) — arquitetura do app e restrições legais
- [procedures/07-publicar-play-store.md](procedures/07-publicar-play-store.md) — ficha da loja
