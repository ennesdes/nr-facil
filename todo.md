# NR Fácil — Checklist

**Fase atual:** 2 — Busca, favoritos e UX  
**Próximo:** [ ] 15 — Busca por chunks + highlight

> Marque `[x]` ao concluir. Não apague itens — é o histórico de progresso.  
> Detalhes técnicos: [docs/architecture.md](docs/architecture.md)  
> Prompts Cursor: [docs/prompts.md](docs/prompts.md)  
> Comandos terminal: [scripts/README.md](scripts/README.md)

---

## Fase 0 — Setup (Semana 1, dias 1–2)

- [x] 01 Configurar FVM → [docs/procedures/01-configurar-fvm.md](docs/procedures/01-configurar-fvm.md)
- [x] 02 Criar estrutura monorepo + `.gitignore` → [docs/prompts.md#i0](docs/prompts.md#i0)
- [x] 03 Projeto Flutter em `app/` → [docs/prompts.md#i1](docs/prompts.md#i1)
- [x] 04 Conta Google Play Console → [docs/procedures/02-conta-play-console.md](docs/procedures/02-conta-play-console.md)
- [x] 05 Mapear URLs MTE (5 NRs) → [docs/procedures/03-mapear-urls-mte.md](docs/procedures/03-mapear-urls-mte.md)
- [x] 06 Rodar `./scripts/setup.sh` e `fvm flutter doctor` sem erros

**Pronto quando:** FVM ok, repo estruturado, app roda Hello World no emulador.

---

## Fase 1 — Conteúdo offline (Semana 1, dias 3–7)

- [x] 08 Scripts pipeline (convert, manifest, index) → [docs/prompts.md#i2](docs/prompts.md#i2)
- [x] 09 Converter NR-01, NR-06, NR-17 → `python3 scripts/convert_nr.py --nr nr-XX`
- [x] 10 Validar qualidade das 3 NRs no app (ler 2–3 seções vs PDF)
- [x] 11 ContentService (sync manifest + cache) → [docs/prompts.md#i3](docs/prompts.md#i3)
- [x] 12 Leitor Markdown + índice lateral + assets → [docs/prompts.md#i4](docs/prompts.md#i4)

**Pronto quando:** App lê 3+ NRs offline; leitor com fonte ajustável e modo escuro.

---

## Fase 2 — Busca, favoritos e UX (Semana 2)

- [x] 14 Abas Favoritos / Todos
- [ ] 15 Busca por chunks + highlight → [docs/prompts.md#i6](docs/prompts.md#i6)
- [ ] 16 Histórico + card Continuar leitura
- [ ] 17 Tela Atualizações (sino + badge, não aba)
- [ ] 18 Aviso legal MTE no app
- [ ] 20 `./scripts/check.sh` passa

**Pronto quando:** Busca < 1s; favoritos persistem; abas navegáveis.

---

## Fase 3 — Pipeline automático (Semana 3)

- [ ] 21 GitHub Action `update-nrs.yml` → [docs/prompts.md#i7](docs/prompts.md#i7)
- [ ] 22 `requirements.txt` + testar Action com `workflow_dispatch`
- [ ] 23 Rodar `discover_nrs.py` para todas NRs do MVP e validar `nr_index.json` (overrides pontuais em `scripts/nr_sources.json` se algum scraping falhar)
- [ ] 24 App busca manifest do GitHub raw
- [ ] 25 Botão "Verificar atualizações"
- [ ] 26 Monitorar primeiro commit automático da Action

**Pronto quando:** Action roda sem erro; app detecta NR atualizada.

---

## Fase 4 — Supabase mínimo (Semana 3, paralelo)

- [ ] 27 Criar projeto Supabase → [docs/procedures/04-projeto-supabase.md](docs/procedures/04-projeto-supabase.md)
- [ ] 28 Tabelas `app_versions` + `nr_updates` (migration)
- [ ] 29 Action insere em `nr_updates` ao detectar mudança
- [ ] 30 Check versão mínima no startup → [docs/prompts.md#i8](docs/prompts.md#i8)
- [ ] 31 `.env` local (nunca commitar) com URL + anon key

**Pronto quando:** App lê feed de atualizações do Supabase; custo R$ 0.

---

## Fase 5 — Monetização (ads) e publicação (Semana 4)

- [ ] 32 Configurar AdMob → [docs/procedures/05-configurar-admob.md](docs/procedures/05-configurar-admob.md)
- [ ] 33 AdMob no app (banner só em listas) → [docs/prompts.md#i9](docs/prompts.md#i9)
- [ ] 34 Gerar keystore → [docs/procedures/06-gerar-keystore.md](docs/procedures/06-gerar-keystore.md)
- [ ] 35 Build release AAB → [docs/prompts.md#i10](docs/prompts.md#i10)
- [ ] 36 Privacy policy + GitHub Pages → [docs/procedures/08-github-pages-privacidade.md](docs/procedures/08-github-pages-privacidade.md)
- [ ] 37 Publicar Play Store → [docs/procedures/07-publicar-play-store.md](docs/procedures/07-publicar-play-store.md)
- [ ] 38 review-bugbot + security-review antes de publicar
- [ ] 39 Teste interno → produção

**Pronto quando:** AAB no teste interno; versão grátis + ads funciona; app publicado.

---

## Fase 6 — Versão Pro (pós-lançamento)

> Só inicia depois do app publicado e com uso real validado (ver critérios de sucesso abaixo).

- [ ] 40 IAP `remove_ads_lifetime` → [docs/prompts.md#i9b](docs/prompts.md#i9b)
- [ ] 42 Publicar update na Play Store com IAP habilitado

**Pronto quando:** compra remove anúncios; restorePurchases funciona; update publicado.

---

## Critérios de sucesso (90 dias pós-lançamento)

- [ ] 1.000 downloads
- [ ] 200 usuários ativos/mês
- [ ] Nota ≥ 4.5
- [ ] Receita ≥ R$ 50/mês

Se não atingir em 90 dias: encerrar sem culpa.

---

## Decisões registradas (não reabrir)

- Monorepo, Android-only, FVM, GitHub = fonte da verdade
- Supabase mínimo (só metadados, sem blobs)
- Abas Favoritos / Todos; atualizações no sino
- Pipeline uniforme: 3 passes (texto/tabelas/imagens) sempre executados em toda NR, sem classificação de complexidade prévia
- Descoberta de NRs e status de revogação via scraping da página-índice do gov.br (`nr_index.json`), não lista manual fixa
- Erro numa NR isola só ela (não atualiza, loga, segue as demais); Action falha no final para notificar
- Freemium: grátis + ads; premium R$ 9,90 vitalício (sem ads + diff)
- Lançamento faseado: Fase 5 publica só grátis + ads; IAP/pro entra na Fase 6, após validar uso real
