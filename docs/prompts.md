# Prompts Cursor — NR Fácil

Copie e cole no Agent ou Plan mode. Checklist: [todo.md](../todo.md).

## Cola rápida

```
@todo.md qual o próximo item não marcado?
```

```
Fase X, item Y do @todo.md
Implemente [descrição]
Arquivos: @caminho/
Reutilizar: @outro/arquivo
Não fazer: [fora do escopo]
```

```
[colar 15 linhas do erro]
@arquivo.dart — corrija apenas isso
```

```
/review-bugbot mudanças não commitadas
/security-review antes de publicar
```

## Qual modo usar

| Situação | Modo |
|----------|------|
| Dúvida de arquitetura | Plan mode |
| Implementar feature | Agent + @arquivo |
| Explorar repo grande | subagente `explore` (1x/fase) |
| Erro no terminal | Você roda → cola erro → Agent |
| PDF / manifest | Script — **nunca IA** |
| Antes de publicar | review-bugbot + security-review |
| Supabase | skill supabase + @docs/architecture.md |

## Economia de tokens

1. Um chat = uma entrega
2. Use `@arquivo` em vez de descrever o projeto
3. Cole só o erro relevante
4. Plan mode 1x por fase
5. Scripts para tarefas repetitivas
6. Referencie "Fase 2, item 15" em vez de reexplicar

---

## Prompts por fase

### I5 — Abas Favoritos/Todos (Fase 2, item 14)

```
Fase 2, item 14 do @todo.md

Bottom nav: Favoritos | Todos
- Favoritos padrão se >= 1 favorito
- Card Continuar leitura no topo
- Drag-and-drop em favoritos
- Estrela toggle em Todos e no leitor
- Empty state com sugestões NR-06, NR-10, NR-18
- Badge 🆕 se favorito atualizado

Ver @docs/architecture.md seção navegação.
```

### I6 — Busca (Fase 2, item 15)

```
Fase 2, item 15 do @todo.md

Busca full-text:
- Carregar search_index.json em memória
- Tela de resultados com chunk + highlight
- Navegar para âncora no leitor
- Filtro local por título na aba Todos (separado)

Meta: < 1s para 38 NRs.
```

### I7 — GitHub Action (Fase 3, item 21)

```
Fase 3, item 21 do @todo.md

Crie .github/workflows/update-nrs.yml:
- cron 09:00 UTC + workflow_dispatch
- Roda update_nrs, convert_nr, build_manifest
- push_nr_updates.py (Supabase service_role)
- commit automático se mudou

E ci.yml com fvm flutter analyze + test + validate_manifest.
```

### I8 — Supabase no app (Fase 4, item 30)

```
Fase 4 do @todo.md

Use skill supabase:
- Aplicar @docs/supabase/migration.sql
- App: ler nr_updates no startup (feed atualizações)
- App: checar app_versions (aviso APK desatualizado)
- .env.example com SUPABASE_URL e SUPABASE_ANON_KEY
- Nunca commitar .env
```

### I9 — AdMob (Fase 5, item 33)

```
Fase 5, item 33 do @todo.md

- google_mobile_ads: banner só em Favoritos, Todos e Busca
- NUNCA no leitor
- IDs de teste em debug
```

### I9b — IAP remove_ads_lifetime (Fase 6, item 40)

```
Fase 6, item 40 do @todo.md

- in_app_purchase: remove_ads_lifetime
- Flag local + restorePurchases no startup
- Esconder ads quando flag ativa
- IDs de teste em debug
```

### I10 — Build release (Fase 5, item 35)

```
Fase 5, item 35 do @todo.md

Configure signing release em app/android/
- Ler key.properties (gitignored)
- fvm flutter build appbundle
- Checklist final Play Store
```

---

## Fluxo descobrir → revisar

### 1. Descobrir
```
@todo.md — estou na Fase X. O que existe e qual o próximo passo?
```
```
Use explore: mapeie app/lib/ e liste o que falta para Fase 2.
```

### 2. Decidir
```
Plan mode: [pergunta objetiva com trade-offs]
```

### 3. Planejar
```
Plan mode: planeje Fase X. Referencie @todo.md e @docs/architecture.md
```

### 4. Implementar
Use prompts I0–I10 acima.

### 5. Testar
Você roda `./scripts/check.sh`. Se falhar:
```
flutter test falhou: [erro]
@arquivo — corrija apenas isso
```

### 6. Revisar
```
/review-bugbot
/security-review
```

---

## Manutenção

```
Rode discover_nrs.py para pegar a NR-XX nova automaticamente; se o scraper não achar, adicione override em scripts/nr_sources.json e converta com convert_nr.py
```

```
Corrija formatação MD da NR-XX — só layout, não alterar texto oficial
```

```
Investigue falha da GitHub Action: [colar log]
```

---

## Scripts vs IA

| Sempre script | Sempre IA |
|---------------|-----------|
| convert_nr.py | UI Flutter |
| build_manifest.py | Arquitetura |
| validate_manifest.py | Debug específico |
| check.sh | Code review |
| GitHub Action | Testes complexos (1ª vez) |
