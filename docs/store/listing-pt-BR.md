# Play Store — Ficha da loja (pt-BR)

Copy otimizada para SEO na Google Play. Limites: título 30 chars, descrição curta 80 chars, descrição completa 4.000 chars.

Tom de voz e restrições legais: [brand.md](../brand.md).

---

## Copy recomendada (lançamento)

### Título (28/30 caracteres)

```
NR Fácil: Normas do Trabalho
```

### Descrição curta (74/80 caracteres)

```
Normas Regulamentadoras offline: busca, favoritos e atualização automática.
```

### Descrição completa

```
Normas Regulamentadoras (NRs) do Ministério do Trabalho e Emprego no seu celular — com leitura offline, busca por trecho e favoritos. Ideal para quem trabalha com segurança do trabalho (SST) e precisa consultar a norma na obra, na fábrica ou no escritório, mesmo sem internet.

PARA QUEM É
• Técnicos de segurança do trabalho, SESMT e CIPA
• Engenheiros, médicos do trabalho e ergonomistas
• Empregadores e gestores que consultam NRs no dia a dia

O QUE VOCÊ FAZ NO APP
• Consultar o texto das NRs com leitor otimizado para leitura prolongada
• Buscar palavras e trechos em todas as normas com destaque nos resultados
• Salvar favoritos e continuar de onde parou
• Baixar conteúdo para usar offline — sem depender de conexão no campo
• Receber aviso quando uma NR for atualizada e ver o que mudou
• Acessar o PDF original no portal do MTE em um toque

POR QUE O NR FÁCIL
• Foco em consulta rápida: menos tempo procurando, mais tempo aplicando a norma
• Conteúdo público oficial, organizado para leitura no celular
• Atualização automática quando o texto normativo mudar
• Interface limpa, modo escuro e tamanho de fonte ajustável no leitor

NORMAS DISPONÍVEIS
O app sincroniza as Normas Regulamentadoras vigentes publicadas pelo MTE. NRs revogadas aparecem identificadas, com link para o PDF histórico quando aplicável.

IMPORTANTE
Este aplicativo disponibiliza conteúdo público oficial das Normas Regulamentadoras do Ministério do Trabalho e Emprego. Não é um aplicativo governamental. O conteúdo não substitui a consulta às publicações oficiais no portal gov.br.

Baixe o NR Fácil e tenha as normas do trabalho sempre à mão.
```

---

## Variantes para teste A/B

### Título

| ID | Texto | Chars | Quando testar |
|----|-------|-------|---------------|
| A (padrão) | `NR Fácil: Normas do Trabalho` | 28 | Lançamento |
| B | `NR Fácil – NRs Offline SST` | 21 | Público técnico SST |
| C | `NR Fácil` | 8 | Foco em marca |

### Descrição curta

| ID | Texto | Chars |
|----|-------|-------|
| A (padrão) | `Normas Regulamentadoras offline: busca, favoritos e atualização automática.` | 74 |
| B | `NRs do trabalho offline. Busca rápida, favoritos e leitura sem internet.` | 72 |
| C | `Consulte NRs oficiais offline com busca. Segurança do trabalho e SST.` | 69 |

---

## Mapa de keywords

| Keyword | Título | Curta | Longa |
|---------|--------|-------|-------|
| NR / NRs | implícito | — | sim |
| Normas Regulamentadoras | — | sim | sim |
| Normas do trabalho | sim | — | sim |
| Segurança do trabalho / SST | — | — | sim |
| Offline / sem internet | — | sim | sim |
| Busca / favoritos | — | sim | sim |
| MTE | — | — | sim |

**Evitar:** “melhor app”, “oficial do MTE”, emojis no título/curta, keyword stuffing, “grátis para sempre”.

---

## Checklist — Play Console

Presença na loja → **Ficha principal** (idioma: Português (Brasil)):

- [ ] **Título do app:** copiar título Opção A acima
- [ ] **Descrição curta:** copiar descrição curta Opção A acima
- [ ] **Descrição completa:** copiar bloco completo acima
- [ ] **Ícone do app:** `docs/store/play_store_icon_512.png`
- [ ] **Gráfico de recursos:** `docs/store/feature_graphic_1024x500.png`
- [ ] **Screenshots:** ≥4 (Home, Leitor, Busca, Atualizações) — ver [README.md](README.md)

Outros campos (procedure 07):

- [ ] Política de privacidade (URL GitHub Pages)
- [ ] Classificação de conteúdo
- [ ] Anúncios: sim | Compras no app: sim (remove anúncios, Fase 6)
- [ ] Data safety declarado honestamente

**Nota:** o nome no launcher do Android permanece **NR Fácil** (`android:label`); o título da loja pode ser mais longo (até 30 caracteres).

---

## Referências

- [07-publicar-play-store.md](../procedures/07-publicar-play-store.md) — fluxo de publicação
- [brand.md](../brand.md) — tom de voz e disclaimer
