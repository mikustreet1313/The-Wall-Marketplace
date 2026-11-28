# THE WALL ! — Plan de pruebas de aceptación

Este documento es una lista de pruebas manuales y técnicas. No se debe marcar una prueba como superada solo porque exista código.

## A. Cuentas y acceso

- [ ] Registrar un creador nuevo y comprobar confirmación de correo si está activada.
- [ ] Iniciar sesión como creador y comprobar que llega a su panel.
- [ ] Iniciar sesión como cliente y comprobar que no puede abrir funciones privadas de creador.
- [ ] Cerrar sesión y comprobar que el panel privado redirige al acceso.
- [ ] Comprobar que un usuario no puede leer ni modificar perfiles privados de otros usuarios.

## B. Obras del creador

- [x] Publicar una obra con una imagen (prueba confirmada por el usuario).
- [x] Ver la obra y su imagen en Mis creaciones (confirmado por el usuario).
- [x] Editar el título y guardar (confirmado por el usuario).
- [ ] Añadir una segunda imagen a una obra existente y confirmar que ambas aparecen.
- [ ] Añadir un vídeo a una obra existente y confirmar reproducción.
- [ ] Confirmar que añadir archivos no elimina los anteriores.
- [ ] Cambiar visibilidad a privada y comprobar que otra cuenta no la ve.
- [ ] Cambiar visibilidad a pública y comprobar que aparece en el muro público.
- [ ] Probar programada con fecha futura y pasada.
- [ ] Probar borrado únicamente con una publicación desechable, nunca con la única obra del usuario.

## C. Muro público e interacciones

- [ ] Abrir el muro sin iniciar sesión: publicaciones públicas visibles.
- [ ] Confirmar que publicaciones privadas nunca aparecen.
- [ ] Confirmar que publicaciones programadas aparecen solo al llegar su hora.
- [ ] Abrir imágenes en ampliación y reproducir vídeos.
- [ ] Dar Me gusta, recargar y comprobar persistencia.
- [ ] Retirar Me gusta y comprobar recuento.
- [ ] Guardar una publicación, abrir favoritos y comprobar que aparece.
- [ ] Retirar favorito y comprobar que desaparece.
- [ ] Confirmar que un usuario no puede interactuar en nombre de otro.
- [ ] Confirmar que el creador ve solo las interacciones de sus obras.

## D. Seguridad Supabase

- [ ] Ejecutar `docs/SQL_SECURITY_AUDIT_READ_ONLY.sql` y guardar resultados.
- [ ] Confirmar RLS activado en todas las tablas que contienen datos de usuarios.
- [ ] Revisar todas las políticas anon/authenticated y grants.
- [ ] Revisar bucket `wall media`: privado y políticas correctas.
- [ ] Confirmar que los usuarios solo escriben bajo su propia carpeta de Storage.
- [ ] Revisar funciones SECURITY DEFINER, search_path y privilegios EXECUTE.
- [ ] Probar permisos con dos cuentas distintas y sesión anónima.
- [ ] Confirmar que ningún secreto de servidor aparece en archivos públicos.

## E. No activar antes de cumplir

- Pagos reales: no activar hasta probar webhooks, idempotencia, reembolsos, disputas y reconciliación.
- Subastas reales: no activar hasta probar pujas concurrentes, desempate, límite por participante y adjudicación transaccional.
- Mercado internacional: no habilitar país hasta revisar pagos, impuestos, envíos, restricciones y textos legales.
- Writer/Literature: no publicar textos de prueba con datos reales hasta probar permisos de autor y visibilidad.
