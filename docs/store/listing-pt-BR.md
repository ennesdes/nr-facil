# Play Store — Ficha da loja (pt-BR)

Copy otimizada para SEO na Google Play. Limites: título 30 chars, descrição curta 80 chars, descrição completa 4.000 chars.

Tom de voz e restrições legais: [brand.md](../brand.md).

---

## Copy recomendada (lançamento)

### Título (28/30 caracteres)

```
NR Fácil: Normas do Trabalho
```

### Descrição curta (63/80 caracteres)

```
Normas Regulamentadoras offline e checklist do que pode autuar.
```

### Descrição completa

```
Normas Regulamentadoras (NRs) do Ministério do Trabalho e Emprego no seu celular — com leitura offline, busca por trecho, favoritos e um checklist dos itens que podem gerar autuação. Ideal para quem trabalha com segurança do trabalho (SST) e precisa consultar a norma na obra, na fábrica ou no escritório, mesmo sem internet.

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
• Montar um checklist de itens que podem gerar autuação, a partir do perfil da empresa

CHECKLIST DE AUTUAÇÕES
Na aba Autuações, informe o porte, a atividade e os fatores de risco da empresa. O app reúne os principais itens do Anexo II da NR-28 aplicáveis a esse perfil: o que verificar, a gradação da infração quando houver, e um atalho para o trecho da norma.

• Acompanhe o que já foi conferido — a marcação fica no aparelho
• Abra o texto da norma no ponto do item, em um toque
• Ajuste o perfil quando a realidade da empresa mudar

A lista é uma amostra curada para orientar a verificação interna. Não cobre todas as NRs, não informa valor de multa e não substitui um profissional de SST nem a publicação oficial.

POR QUE O NR FÁCIL
• Foco em consulta rápida: menos tempo procurando, mais tempo aplicando a norma
• Conteúdo público oficial, organizado para leitura no celular
• Atualização automática quando o texto normativo mudar
• Interface limpa, modo escuro e tamanho de fonte ajustável no leitor

NORMAS DISPONÍVEIS
O app sincroniza as Normas Regulamentadoras vigentes publicadas pelo MTE. NRs revogadas aparecem identificadas, com link para o PDF histórico quando aplicável.

FONTES OFICIAIS (VERIFICAÇÃO)
O texto normativo exibido no app é extraído dos PDFs oficiais do governo federal. Para conferir a informação, consulte:

• Ministério do Trabalho e Emprego: https://www.gov.br/trabalho-e-emprego
• Índice oficial das Normas Regulamentadoras: https://www.gov.br/trabalho-e-emprego/pt-br/assuntos/inspecao-do-trabalho/seguranca-e-saude-no-trabalho/ctpp-nrs/normas-regulamentadoras-nrs
• PDF original de cada NR: no índice acima ou pelo botão "Ver PDF original no MTE" dentro do app
• Diário Oficial da União (publicação das portarias que alteram as NRs): https://www.in.gov.br/leiturajornal

COMO O APP RECEBE ATUALIZAÇÕES
O app não possui servidor próprio. Quando você está online, o conteúdo organizado para leitura no celular é atualizado automaticamente a partir dos PDFs oficiais do MTE. Após o download, as normas ficam disponíveis offline.

IMPORTANTE — NÃO GOVERNAMENTAL
Este aplicativo NÃO é governamental e NÃO representa o Ministério do Trabalho e Emprego nem qualquer órgão público. É uma ferramenta independente que organiza conteúdo público oficial das Normas Regulamentadoras para leitura no celular. O conteúdo não substitui a consulta às publicações oficiais nos links acima.

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
| A (padrão) | `Normas Regulamentadoras offline e checklist do que pode autuar.` | 63 |
| B | `Normas Regulamentadoras offline: busca, favoritos e checklist.` | 62 |
| C | `NRs offline: busca, favoritos, atualização e checklist de autuação.` | 67 |

---

## Mapa de keywords

| Keyword | Título | Curta | Longa |
|---------|--------|-------|-------|
| NR / NRs | implícito | — | sim |
| Normas Regulamentadoras | — | sim | sim |
| Normas do trabalho | sim | — | sim |
| Segurança do trabalho / SST | — | — | sim |
| Offline / sem internet | — | sim | sim |
| Busca / favoritos | — | B e C | sim |
| Checklist / autuação | — | sim | sim |
| NR-28 | — | — | sim |
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
- [ ] **Screenshots (telefone, nesta ordem):** os 8 arquivos em `docs/store/screenshots/` — ver [README.md](README.md)

Outros campos (procedure 07):

- [ ] Política de privacidade: https://solvebetter.com.br/apps/nr-facil/privacidade/
- [ ] Classificação de conteúdo
- [ ] Anúncios: sim | Compras no app: sim (remove anúncios, Fase 6)
- [ ] Data safety declarado honestamente

**Nota:** o nome no launcher do Android permanece **NR Fácil** (`android:label`); o título da loja pode ser mais longo (até 30 caracteres).

---

## Referências

- [07-publicar-play-store.md](../procedures/07-publicar-play-store.md) — fluxo de publicação
- [brand.md](../brand.md) — tom de voz e disclaimer
