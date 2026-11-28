-- THE WALL ! — Auditoría de seguridad de solo lectura
-- Ejecutar en Supabase SQL Editor cuando revisemos el proyecto.
-- Este archivo NO modifica tablas, políticas, usuarios ni archivos.

-- 1) Comprobar RLS y FORCE RLS en tablas de la aplicación.
select
  n.nspname as schema_name,
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as force_rls
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind = 'r'
  and c.relname in (
    'profiles',
    'wall_posts',
    'wall_post_media',
    'wall_post_interactions'
  )
order by c.relname;

-- 2) Listar políticas RLS reales de las tablas de la aplicación.
select
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname in ('public', 'storage')
  and (
    tablename in (
      'profiles',
      'wall_posts',
      'wall_post_media',
      'wall_post_interactions'
    )
    or (schemaname = 'storage' and tablename = 'objects')
  )
order by schemaname, tablename, policyname;

-- 3) Comprobar que el bucket de medios existe y si es público.
select id, name, public, file_size_limit, allowed_mime_types
from storage.buckets
where id = 'wall media';

-- 4) Revisar permisos concedidos a los roles de aplicación.
select
  table_schema,
  table_name,
  grantee,
  privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name in (
    'profiles',
    'wall_posts',
    'wall_post_media',
    'wall_post_interactions'
  )
  and grantee in ('anon', 'authenticated')
order by table_name, grantee, privilege_type;

-- 5) Comprobar existencia y configuración de la función de recuentos.
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as arguments,
  p.prosecdef as security_definer,
  p.proconfig as function_settings
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'get_public_post_interaction_counts';

-- 6) Comprobar trigger de creación automática del perfil.
select
  event_object_schema,
  event_object_table,
  trigger_name,
  action_timing,
  event_manipulation,
  action_statement
from information_schema.triggers
where trigger_schema = 'auth'
  and event_object_table = 'users'
order by trigger_name;


-- 7) Comprobar si ya existen las columnas necesarias para el cierre de creador.
-- Esta consulta devuelve cero filas si aún no se ha aplicado la propuesta.
select
  column_name,
  data_type,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'profiles'
  and column_name in ('account_status', 'closed_at')
order by column_name;

-- 8) Comprobar si existen restricciones de estado de cuenta.
select
  conname,
  pg_get_constraintdef(oid) as definition
from pg_constraint
where conrelid = 'public.profiles'::regclass
  and conname = 'profiles_account_status_check';

-- Nota de seguridad:
-- No crear políticas nuevas a ciegas. Primero comparar los resultados anteriores
-- con docs/THE_WALL_PRODUCT_RULES.md y corregir únicamente las diferencias reales.
-- Este script no reemplaza una revisión de permisos, funciones SECURITY DEFINER,
-- configuración de Auth, Storage ni pruebas con usuarios de distintos roles.
