# Procedure 07 — Publicar na Play Store

## Objetivo

Enviar AAB, passar revisão e publicar o NR Fácil.

## Pré-requisitos

- [ ] Conta Play Console ativa (procedure 02)
- [ ] Keystore configurado (procedure 06)
- [ ] AAB gerado: `app/build/app/outputs/bundle/release/app-release.aab`
- [ ] Privacy policy publicada (procedure 08)
- [ ] Ícone 512×512, feature graphic 1024×500, ≥4 screenshots

## Passo a passo

### 1. Teste interno (primeiro)

1. Play Console → seu app → **Teste → Teste interno**
2. **Criar nova versão**
3. Upload do `app-release.aab`
4. Nome da versão: ex. `1.0.0 (1)`
5. Notas da versão (o que mudou)
6. Adicione seu e-mail como testador
7. **Revisar e lançar** para teste interno
8. Instale pelo link de teste no celular

### 2. Preencher ficha da loja

**Presença na loja → Ficha principal** (idioma: Português (Brasil)).

Copy completa e variantes A/B: [docs/store/listing-pt-BR.md](../store/listing-pt-BR.md).

| Campo | Valor (recomendado) |
|-------|---------------------|
| Título (30 chars) | `NR Fácil: Normas do Trabalho` |
| Descrição curta (80 chars) | `Normas Regulamentadoras offline: busca, favoritos e atualização automática.` |
| Descrição completa | Ver [listing-pt-BR.md](../store/listing-pt-BR.md) — seção "Descrição completa" |
| Ícone | `docs/store/play_store_icon_512.png` |
| Feature graphic | `docs/store/feature_graphic_1024x500.png` |
| Screenshots | ≥4 telas (Home, Leitor, Busca, Atualizações) |

**Checklist Play Console:** marcar itens em [listing-pt-BR.md](../store/listing-pt-BR.md#checklist--play-console).

### 3. Política e classificação

- **Política de privacidade**: URL do GitHub Pages (procedure 08)
- **Classificação de conteúdo**: questionário (geralmente "Todos" ou baixa idade)
- **Público-alvo**: profissionais, não app infantil
- **Anúncios**: sim, contém anúncios
- **Compras no app**: sim (remover anúncios)

### 4. Data safety

Declare honestamente:

- Dados coletados: mínimo (AdMob coleta conforme política Google)
- Favoritos: armazenados **localmente** no dispositivo
- Sem conta de usuário no MVP

### 5. Produção

1. Após teste interno ok → **Produção → Criar nova versão**
2. Mesmo AAB ou versão incrementada
3. **Enviar para revisão**
4. Aguarde 1–7 dias (primeira revisão pode demorar)

### 6. Após publicação

- Monitore **Android vitals** e avaliações
- Responda reviews
- Acompanhe métricas do [todo.md](../../todo.md) (90 dias)

## Checklist final

- [ ] AAB assinado com keystore de produção
- [ ] versionCode incrementado a cada upload
- [ ] Privacy policy URL válida
- [ ] Texto legal no app sobre conteúdo MTE
- [ ] Ads só em listas, não no leitor
- [ ] IAP testado em licença de teste

## Troubleshooting

| Problema | Solução |
|----------|---------|
| Rejeição por política | Leia e-mail do Google; corrija privacy policy ou permissões |
| "Upload key" diferente | Use sempre o mesmo keystore |
| IAP não aparece | Produto ativo no Play Console; aguarde propagação 24h |

## Próximo passo

→ Monitorar critérios de sucesso no [todo.md](../../todo.md)
