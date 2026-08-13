# Procedure 04 — Projeto Supabase (mínimo)

## Objetivo

Criar projeto Supabase free tier com **apenas 2 tabelas leves** — sem armazenar MD/PDF.

## Pré-requisitos

- Conta em https://supabase.com (grátis)
- GitHub = fonte da verdade do conteúdo (não duplicar no Supabase)

## O que o Supabase faz neste projeto

| Sim | Não |
|-----|-----|
| Feed de atualizações (texto curto) | Armazenar Markdown |
| Versão mínima do APK | Armazenar PDFs |
| Link para versão anterior (GitHub) | Histórico completo de textos |

## Passo a passo

### 1. Criar projeto

1. https://supabase.com/dashboard → **New project**
2. Nome: `nr-facil`
3. Senha do banco: gere forte e **guarde** (só para admin)
4. Região: **South America (São Paulo)** se disponível
5. Plano: **Free**

### 2. Anotar credenciais

Em **Project Settings → API**:

- **Project URL** → `SUPABASE_URL`
- **anon public** key → `SUPABASE_ANON_KEY`
- **service_role** key → `SUPABASE_SERVICE_ROLE_KEY` (só GitHub Actions, nunca no app)

### 3. Criar arquivo `.env` local (nunca commitar)

Na raiz do projeto:

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
```

Para a Action, adicione secrets no GitHub:  
**Settings → Secrets → Actions** → `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`

### 4. Executar migration

No **SQL Editor** do Supabase, cole e execute o conteúdo de:  
`docs/supabase/migration.sql` (criado na Fase 4)

Ou peça ao Cursor:

```
Use skill supabase: aplique migration em docs/supabase/migration.sql
```

### 5. Verificar RLS

- `app_versions` e `nr_updates`: leitura pública (anon)
- Escrita: apenas `service_role` (Action)

### 6. Testar leitura

No SQL Editor:

```sql
select * from app_versions;
select * from nr_updates order by updated_at desc limit 5;
```

## Custo

Free tier: ~500 MB banco, suficiente para milhares de linhas de metadados. **R$ 0** no MVP.

## Troubleshooting

| Problema | Solução |
|----------|---------|
| RLS bloqueia leitura no app | Confirme policy `SELECT` para `anon` |
| Action não insere | Use `service_role` key no secret, não anon |
| Projeto pausado por inatividade | Restaure no dashboard (free tier pausa após 1 semana sem uso) |

## Próximo passo

→ [docs/architecture.md](../architecture.md#supabase-mínimo) e item 29 do [todo.md](../../todo.md)
