-- THE WALL ! — propuesta de cambio aditivo para cierre de cuentas de creador
-- IMPORTANTE: PROPUESTA NO EJECUTADA. Revisar primero y probar en un proyecto Supabase de pruebas.
-- No elimina perfiles, usuarios de Auth ni publicaciones.

begin;

alter table public.profiles
  add column if not exists account_status text not null default 'ACTIVE',
  add column if not exists closed_at timestamptz;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.profiles'::regclass
      and conname = 'profiles_account_status_check'
  ) then
    alter table public.profiles
      add constraint profiles_account_status_check
      check (account_status in ('ACTIVE', 'CLOSED'));
  end if;
end
$$;

comment on column public.profiles.account_status is
  'Estado de cuenta de THE WALL: ACTIVE o CLOSED. CLOSED conserva la atribución pública del creador.';
comment on column public.profiles.closed_at is
  'Fecha y hora del cierre de cuenta, si se ha cerrado.';

commit;

-- Comprobación posterior (solo lectura):
-- select id, role, display_name, account_status, closed_at
-- from public.profiles
-- order by created_at desc
-- limit 20;

-- Notas:
-- 1. No ejecutar hasta confirmar que el esquema real coincide con el esperado.
-- 2. La función segura de cierre debe validar el JWT y el rol en servidor.
-- 3. La función debe actualizar account_status/closed_at y bloquear el acceso de Auth
--    mediante Admin API usando SUPABASE_SERVICE_ROLE_KEY guardada como secreto
--    de Edge Function. Esa clave nunca debe ir al HTML ni al repositorio.
-- 4. Las futuras tablas de ventas y subastas deberán rechazar operaciones nuevas
--    cuando el perfil del creador no esté ACTIVE.
-- 5. Las publicaciones PUBLIC existentes se conservan. No cambiar creator_id,
--    display_name ni borrar filas de wall_posts/wall_post_media.
-- 6. Antes de cerrar, el backend debe detectar pedidos, pagos, disputas o subastas
--    pendientes y resolverlos según las reglas de producto y la ley aplicable.
-- 7. Esta propuesta cubre únicamente CREATOR. El cierre de CUSTOMER queda pendiente.
