-- THE WALL ! — Propuesta de esquema para modalidades y Writer/Literature
-- ESTADO: BORRADOR. NO EJECUTADO.
-- Requiere primero revisar docs/SQL_SECURITY_AUDIT_READ_ONLY.sql.
-- Script aditivo: no altera ni elimina tablas existentes ni datos actuales.
-- Revisar en una rama/proyecto de pruebas antes de producción.

begin;

-- Catálogo de modalidades que se muestran en formularios y filtros.
create table if not exists public.art_modalities (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null,
  description text,
  status text not null default 'APPROVED'
    check (status in ('PENDING','APPROVED','REJECTED','ARCHIVED')),
  created_by uuid references auth.users(id) on delete set null,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  review_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists art_modalities_slug_unique
  on public.art_modalities (slug);

create table if not exists public.modality_suggestions (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 2 and 100),
  description text check (description is null or char_length(description) <= 2000),
  suggested_category text,
  status text not null default 'PENDING'
    check (status in ('PENDING','APPROVED','REJECTED')),
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  review_note text,
  created_at timestamptz not null default now()
);

create index if not exists modality_suggestions_creator_created_idx
  on public.modality_suggestions (creator_id, created_at desc);

-- Writer: los textos se almacenan separados de las obras visuales.
create table if not exists public.literature_works (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 200),
  subtitle text,
  content text not null check (char_length(content) <= 500000),
  excerpt text check (excerpt is null or char_length(excerpt) <= 1000),
  genre text,
  language_code text not null default 'es',
  status text not null default 'DRAFT'
    check (status in ('DRAFT','PUBLISHED','ARCHIVED')),
  visibility text not null default 'PRIVATE'
    check (visibility in ('PRIVATE','PUBLIC')),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (status = 'PUBLISHED' and visibility = 'PUBLIC' and published_at is not null)
    or status <> 'PUBLISHED'
    or visibility <> 'PUBLIC'
  )
);

create index if not exists literature_works_public_idx
  on public.literature_works (published_at desc)
  where status = 'PUBLISHED' and visibility = 'PUBLIC';

create index if not exists literature_works_creator_idx
  on public.literature_works (creator_id, updated_at desc);

-- updated_at se mantiene desde el cliente/backend inicialmente;
-- antes de producción, añadir trigger común si el proyecto ya dispone de uno.

alter table public.art_modalities enable row level security;
alter table public.modality_suggestions enable row level security;
alter table public.literature_works enable row level security;

-- El catálogo solo expone modalidades aprobadas. ADMIN puede consultar todo.
drop policy if exists "Approved modalities are readable" on public.art_modalities;
create policy "Approved modalities are readable"
on public.art_modalities for select to anon, authenticated
using (
  status = 'APPROVED'
  or exists (
    select 1 from public.profiles me
    where me.id = (select auth.uid()) and me.role::text = 'ADMIN'
  )
);

drop policy if exists "Admins manage modalities" on public.art_modalities;
create policy "Admins manage modalities"
on public.art_modalities for all to authenticated
using (
  exists (
    select 1 from public.profiles me
    where me.id = (select auth.uid()) and me.role::text = 'ADMIN'
  )
)
with check (
  exists (
    select 1 from public.profiles me
    where me.id = (select auth.uid()) and me.role::text = 'ADMIN'
  )
);

-- Los creadores envían propuestas y solo consultan sus propias propuestas.
drop policy if exists "Creators submit modality suggestions" on public.modality_suggestions;
create policy "Creators submit modality suggestions"
on public.modality_suggestions for insert to authenticated
with check (
  creator_id = (select auth.uid())
  and status = 'PENDING'
  and reviewed_by is null
  and reviewed_at is null
);

drop policy if exists "Creators and admins read modality suggestions" on public.modality_suggestions;
create policy "Creators and admins read modality suggestions"
on public.modality_suggestions for select to authenticated
using (
  creator_id = (select auth.uid())
  or exists (
    select 1 from public.profiles me
    where me.id = (select auth.uid()) and me.role::text = 'ADMIN'
  )
);

drop policy if exists "Admins review modality suggestions" on public.modality_suggestions;
create policy "Admins review modality suggestions"
on public.modality_suggestions for update to authenticated
using (
  exists (
    select 1 from public.profiles me
    where me.id = (select auth.uid()) and me.role::text = 'ADMIN'
  )
)
with check (
  exists (
    select 1 from public.profiles me
    where me.id = (select auth.uid()) and me.role::text = 'ADMIN'
  )
);

-- Writer: cada autor gestiona sus textos; público solo ve textos publicados.
drop policy if exists "Published literature is public" on public.literature_works;
create policy "Published literature is public"
on public.literature_works for select to anon, authenticated
using (
  (status = 'PUBLISHED' and visibility = 'PUBLIC')
  or creator_id = (select auth.uid())
  or exists (
    select 1 from public.profiles me
    where me.id = (select auth.uid()) and me.role::text = 'ADMIN'
  )
);

drop policy if exists "Creators create their own literature drafts" on public.literature_works;
create policy "Creators create their own literature drafts"
on public.literature_works for insert to authenticated
with check (
  creator_id = (select auth.uid())
  and status = 'DRAFT'
  and visibility = 'PRIVATE'
  and published_at is null
);

drop policy if exists "Creators update their own literature" on public.literature_works;
create policy "Creators update their own literature"
on public.literature_works for update to authenticated
using (creator_id = (select auth.uid()))
with check (creator_id = (select auth.uid()));

drop policy if exists "Creators delete their own literature" on public.literature_works;
create policy "Creators delete their own literature"
on public.literature_works for delete to authenticated
using (creator_id = (select auth.uid()));

drop policy if exists "Admins moderate literature" on public.literature_works;
create policy "Admins moderate literature"
on public.literature_works for all to authenticated
using (
  exists (
    select 1 from public.profiles me
    where me.id = (select auth.uid()) and me.role::text = 'ADMIN'
  )
)
with check (
  exists (
    select 1 from public.profiles me
    where me.id = (select auth.uid()) and me.role::text = 'ADMIN'
  )
);

-- Conceder únicamente los privilegios de tabla necesarios.
grant select on public.art_modalities to anon, authenticated;
grant insert, select, update, delete on public.art_modalities to authenticated;
grant insert, select, update on public.modality_suggestions to authenticated;
grant select, insert, update, delete on public.literature_works to authenticated;
grant select on public.literature_works to anon;

commit;

-- Antes de aplicar en producción:
-- 1) Confirmar que profiles.role contiene CREATOR/ADMIN y que ADMIN se asigna de forma segura.
-- 2) Revisar grants/RLS existentes y probar con anon, CUSTOMER, CREATOR y ADMIN.
-- 3) Añadir control de límites, sanitización de contenido y política de publicación.
-- 4) Confirmar que no hay políticas permisivas adicionales que amplíen acceso.
-- 5) Aplicar primero en un proyecto Supabase de pruebas y validar con cuentas separadas.
