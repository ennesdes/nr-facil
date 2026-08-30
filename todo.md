# NR Fácil — Checklist

**Fase atual:** 3 — Pipeline automático  
**Próximo:** [ ] 26 — Monitorar primeiro commit automático da Action

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
- [x] 12b Imagens de página e tabelas ilegíveis como PNG recortado (Fases 1–2 do plano `.claude/plans/imagens-pagina-posicionamento.md`): `extract_images_pass` e `extract_tables_pass` capturam bboxes; `merge_passes` combina e renderiza cada bbox separado (não mais página inteira); inserem `![...]` no `.md` na ordem Y correta

**Pronto quando:** App lê 3+ NRs offline; leitor com fonte ajustável e modo escuro.

---

## Fase 2 — Busca, favoritos e UX (Semana 2)

- [x] 14 Abas Favoritos / Todos
- [x] 15 Busca por chunks + highlight → [docs/prompts.md#i6](docs/prompts.md#i6)
- [x] 16 Histórico + card Continuar leitura
- [x] 17 Tela Atualizações (sino + badge, não aba)
- [x] 18 Aviso legal MTE no app
- [x] 20 `./scripts/check.sh` passa

**Pronto quando:** Busca < 1s; favoritos persistem; abas navegáveis.

---

## Fase 3 — Pipeline automático (Semana 3)

- [x] 21 GitHub Action `update-nrs.yml` → [docs/prompts.md#i7](docs/prompts.md#i7)
- [x] 22 `requirements.txt` + testar Action com `workflow_dispatch`
- [x] 23 Rodar `discover_nrs.py` para todas NRs do MVP e validar `nr_index.json` (overrides pontuais em `scripts/nr_sources.json` se algum scraping falhar)
- [x] 23b `convert_nr.py` renderizava PNG de toda página do PDF (Pass 3), não só das que têm imagem — gerava ~300MB desnecessários em `content/*/assets/pages/`. Corrigido: só renderiza página com imagem embutida (`page.get_images()`); repo caiu pra ~57MB. Também corrigido bug relacionado: `scrape_vigencia.py` sobrescrevia `meta.json` inteiro e apagava o `pdf_hash` gravado por `convert_nr.py` — agora mescla
- [x] 24 App busca manifest do GitHub raw
- [x] 25 Botão "Verificar atualizações"
- [x] 26 Monitorar primeiro commit automático da Action

**Pronto quando:** Action roda sem erro; app detecta NR atualizada.

---

## Fase 4 — Feed de atualizações sem backend (Semana 3, paralelo)

- [x] 27 `scripts/build_app_meta.py` gera `app_meta.json` (feed + versão mínima) → `scripts/README.md#9-build_app_metapy`
- [x] 28 App busca `app_meta.json` via GitHub raw e lê `updates[]` no startup → [docs/prompts.md#i8](docs/prompts.md#i8)
- [x] 30 Check `min_app_version` no startup (aviso de update obrigatório)

**Pronto quando:** App lê feed de atualizações de `app_meta.json` via GitHub raw; custo R$ 0, sem conta externa.

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
- Sem backend: feed de atualizações + versão mínima em `app_meta.json` versionado no GitHub (raw), não Supabase/Firebase — motivo: limite de projetos free na conta/organização já em uso por outros projetos
- Abas Favoritos / Todos; atualizações no sino
- Pipeline uniforme: 3 passes (texto/tabelas/imagens) sempre executados em toda NR, sem classificação de complexidade prévia
- Descoberta de NRs e status de revogação via scraping da página-índice do gov.br (`nr_index.json`), não lista manual fixa
- Erro numa NR isola só ela (não atualiza, loga, segue as demais); Action falha no final para notificar
- Freemium: grátis + ads; premium R$ 9,90 vitalício (sem ads + diff)
- Lançamento faseado: Fase 5 publica só grátis + ads; IAP/pro entra na Fase 6, após validar uso real
