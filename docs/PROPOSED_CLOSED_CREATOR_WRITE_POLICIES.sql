-- THE WALL ! — restricciones de escritura para creadores con cuenta cerrada
-- PROPUESTA NO EJECUTADA. Revisar en Supabase antes de aplicar.
-- Requiere public.profiles.account_status (ver PROPOSED_ACCOUNT_CLOSURE.sql).
-- No elimina ni modifica publicaciones existentes.

begin;

-- wall_posts: las cuentas cerradas no pueden insertar, actualizar ni borrar; las políticas permisivas existentes siguen controlando rol y propiedad.
drop policy if exists "active creators can insert own posts" on public.wall_posts;
create policy "active creators can insert own posts"
on public.wall_posts as restrictive
for insert to authenticated
with check (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.account_status = 'ACTIVE'
  )
);

drop policy if exists "active creators can update own posts" on public.wall_posts;
create policy "active creators can update own posts"
on public.wall_posts as restrictive
for update to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.account_status = 'ACTIVE'
  )
)
with check (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.account_status = 'ACTIVE'
  )
);

drop policy if exists "active creators can delete own posts" on public.wall_posts;
create policy "active creators can delete own posts"
on public.wall_posts as restrictive
for delete to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.account_status = 'ACTIVE'
  )
);

-- wall_post_media: impedir nuevas cargas, cambios y borrados de archivos.
drop policy if exists "active creators can insert own post media" on public.wall_post_media;
create policy "active creators can insert own post media"
on public.wall_post_media as restrictive
for insert to authenticated
with check (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.account_status = 'ACTIVE'
  )
);

drop policy if exists "active creators can update own post media" on public.wall_post_media;
create policy "active creators can update own post media"
on public.wall_post_media as restrictive
for update to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.account_status = 'ACTIVE'
  )
)
with check (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.account_status = 'ACTIVE'
  )
);

drop policy if exists "active creators can delete own post media" on public.wall_post_media;
create policy "active creators can delete own post media"
on public.wall_post_media as restrictive
for delete to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.account_status = 'ACTIVE'
  )
);

-- Storage: impedir escrituras en el bucket privado wall media para cuentas cerradas. Las políticas permisivas existentes siguen controlando propiedad y rutas.
drop policy if exists "active creators can upload wall media" on storage.objects;
create policy "active creators can upload wall media"
on storage.objects as restrictive
for insert to authenticated
with check (
  bucket_id <> 'wall media'
  or exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.account_status = 'ACTIVE'
  )
);

drop policy if exists "active creators can update wall media" on storage.objects;
create policy "active creators can update wall media"
on storage.objects as restrictive
for update to authenticated
using (
  bucket_id <> 'wall media'
  or exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.account_status = 'ACTIVE'
  )
)
with check (
  bucket_id <> 'wall media'
  or exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.account_status = 'ACTIVE'
  )
);

drop policy if exists "active creators can delete wall media" on storage.objects;
create policy "active creators can delete wall media"
on storage.objects as restrictive
for delete to authenticated
using (
  bucket_id <> 'wall media'
  or exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.account_status = 'ACTIVE'
  )
);

commit;

-- ADVERTENCIAS DE REVISIÓN:
-- 1. Confirmar nombres y definiciones de políticas actuales antes de aplicar.
-- 2. Las políticas RESTRICTIVE se combinan con AND y se suman a las políticas
--    permisivas existentes. No sustituyen las comprobaciones de propiedad.
-- 3. Probar con una cuenta CREATOR activa, una cerrada, una CUSTOMER y ADMIN; los permisos concretos siguen dependiendo de las políticas permisivas existentes.
-- 4. La lectura pública de publicaciones y archivos debe seguir funcionando.
-- 5. Esta migración no cierra Auth ni gestiona pedidos pendientes; eso corresponde
--    a la Edge Function y a los módulos de ventas/subastas cuando existan.
