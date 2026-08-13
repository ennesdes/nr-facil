-- NR Fácil — Supabase mínimo (metadados apenas, sem blobs)
-- Aplicar no SQL Editor do Supabase ou via MCP migration

-- Versão mínima do app APK
create table if not exists app_versions (
  id bigint generated always as identity primary key,
  app_version text not null,
  min_content_version int not null default 1,
  created_at timestamptz default now()
);

-- Feed leve de atualizações de NRs (escrito pela GitHub Action)
create table if not exists nr_updates (
  id bigint generated always as identity primary key,
  nr_id text not null,
  updated_at timestamptz not null,
  summary text,
  portaria text,
  prev_commit_url text,
  created_at timestamptz default now()
);

create index if not exists nr_updates_nr_id_idx on nr_updates (nr_id);
create index if not exists nr_updates_updated_at_idx on nr_updates (updated_at desc);

-- RLS: leitura pública
alter table app_versions enable row level security;
alter table nr_updates enable row level security;

create policy "app_versions_read_public"
  on app_versions for select
  to anon, authenticated
  using (true);

create policy "nr_updates_read_public"
  on nr_updates for select
  to anon, authenticated
  using (true);

-- Escrita: apenas service_role (bypass RLS) — usado na GitHub Action
-- Não criar policy de INSERT para anon

-- Seed inicial (opcional)
insert into app_versions (app_version, min_content_version)
values ('1.0.0', 1)
on conflict do nothing;
