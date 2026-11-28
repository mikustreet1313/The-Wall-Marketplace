# Despliegue de cierre seguro de cuentas de creador

**Estado: preparado en GitHub, no desplegado ni activado en Supabase.**

## Archivos relacionados

- `supabase/functions/close-creator-account/index.ts`: función que valida la sesión, comprueba que la cuenta pertenece a un creador, marca el perfil como CLOSED y bloquea el inicio de sesión sin borrar el usuario de Auth.
- `docs/PROPOSED_ACCOUNT_CLOSURE.sql`: añade `account_status` y `closed_at` a `profiles`.
- `docs/PROPOSED_CLOSED_CREATOR_WRITE_POLICIES.sql`: añade barreras RLS para que una cuenta cerrada no pueda escribir, incluso con un JWT que siga vigente.

## Orden obligatorio antes de activar

1. Revisar y ejecutar primero las dos propuestas SQL en un proyecto Supabase de pruebas, no directamente en producción.
2. Comprobar que un creador ACTIVE puede publicar, editar y gestionar sus archivos.
3. Comprobar que un perfil CLOSED no puede publicar, editar ni borrar; sus publicaciones públicas y su nombre artístico siguen visibles.
4. Comprobar que clientes y administradores conservan los permisos que les correspondan.
5. Desplegar esta Edge Function y configurar sus secretos.
6. Solo después, conectar el botón de cierre de cuenta de MY WALL a esta función.

## Secretos de la Edge Function

Configurar en el entorno de Supabase:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

La clave `SUPABASE_SERVICE_ROLE_KEY` debe existir únicamente como secreto del servidor/Edge Function. **Nunca** ponerla en `index.html`, en otro archivo público ni en GitHub.

## Comportamiento y límites actuales

- Solo acepta solicitudes POST con un JWT válido.
- No acepta un ID de usuario enviado por el navegador: obtiene el usuario del JWT validado.
- Solo permite el cierre de perfiles con rol CREATOR.
- No elimina `auth.users`, `profiles`, `wall_posts` ni `wall_post_media`.
- Si el bloqueo de Auth falla, intenta revertir el estado del perfil. Si también falla la reversión, deja el estado CLOSED y devuelve un error que requiere revisión administrativa; las barreras RLS son esenciales.
- El bloqueo de Auth no sustituye las barreras RLS: los JWT ya emitidos pueden seguir siendo válidos hasta expirar.
- Aún no hay integración con pedidos, pagos, disputas ni subastas. Antes de activar ventas, esos procesos deben añadirse al control de cierre.
- El flujo CUSTOMER no está incluido; requiere una política separada de conservación y borrado de datos.

## Importante

No activar esta función hasta haber revisado las políticas RLS reales del proyecto y probado la migración en un entorno de pruebas. Las propuestas SQL de este repositorio no se han ejecutado.
