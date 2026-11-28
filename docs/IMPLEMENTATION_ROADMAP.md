# THE WALL ! — Hoja de ruta de implementación

Esta hoja de ruta consolida las decisiones tomadas en las conversaciones del proyecto. El orden prioriza seguridad y dependencias para evitar construir pagos o subastas sobre una base incompleta.

## Fase 0 — Base técnica y protección (en curso)

- [x] Conectar GitHub Pages con el repositorio.
- [x] Conectar Supabase Auth.
- [x] Roles CUSTOMER, CREATOR y ADMIN en el modelo de perfiles.
- [x] Panel privado inicial del creador.
- [x] Publicar obras con varios archivos multimedia.
- [x] Galería pública y galería del propietario.
- [x] Editar metadatos de una obra.
- [x] Likes y favoritos en el muro público.
- [x] Consulta de recuentos de interacciones mediante RPC.
- [x] Documentar decisiones y auditoría de solo lectura.
- [ ] Probar en navegador añadir archivos a una obra existente.
- [ ] Ejecutar y revisar el informe SQL de RLS, Storage, grants y funciones.
- [ ] Probar acceso con cuentas separadas de creador y cliente.
- [ ] Revisar el flujo de borrado y recuperación de errores sin borrar la obra de prueba.

## Fase 1 — Identidad, catálogo y administración

1. Crear una sección ADMIN separada y protegida por rol validado en servidor.
2. Crear flujo de propuestas de modalidades artísticas:
   - Creador propone nombre, descripción y categoría.
   - Estado inicial PENDING.
   - ADMIN aprueba o rechaza y deja nota.
   - Solo modalidades aprobadas aparecen en el catálogo público y formularios.
3. Permitir al creador editar su perfil público: nombre artístico, biografía, disciplina, avatar y enlaces.
4. Definir moderación, denuncia y retirada de contenido.
5. Añadir registro de auditoría para acciones administrativas relevantes.

Dependencia: RLS y verificación real de roles; nunca confiar solo en ocultar botones.

## Fase 2 — Publicaciones y experiencia de cliente

1. Terminar edición multimedia: añadir archivos y, posteriormente, reordenar o retirar archivos individuales.
2. Permitir seleccionar portada y abrir galería ampliada.
3. Añadir filtros reales por modalidad y búsqueda.
4. Terminar favoritos del cliente y una vista de publicaciones guardadas.
5. Mostrar estadísticas de publicaciones e interacciones al propietario.
6. Crear THE WALL IS YOURS como selección editorial dinámica, con controles de administración.
7. Definir paginación y límites de carga para galerías grandes.

Dependencia: validar políticas de lectura de Storage y consultas para usuarios anónimos/autenticados.

## Fase 3 — Writer y Literature

1. Diseñar tablas independientes para obras literarias y sus versiones.
2. Writer: editor, borradores, publicar/retirar, autoría y visibilidad.
3. Literature: catálogo de lectura, ficha de autor, filtros y lectura accesible.
4. Permitir guardar favoritos literarios y controlar comentarios solo si se acuerdan.
5. Aplicar RLS: el escritor gestiona sus propios textos; lectura pública solo para textos publicados.

No almacenar textos literarios en `wall_posts` si ello obliga a mezclar permisos y campos incompatibles con obras visuales.

## Fase 4 — Venta directa

1. Crear listings de venta vinculados a una obra.
2. Distinguir obra física/digital, original/edición, cantidad disponible, moneda y precio.
3. Diseñar estados de pedido y transiciones válidas: pending, payment, shipped, completed, además de cancelled/refunded/disputed.
4. Diseñar inventario reservado y evitar sobreventa.
5. Preparar checkout con desglose de artículo, envío, comisión, impuestos y total.
6. Añadir portal My Sales del creador y vista de pedidos del comprador.
7. Integrar un proveedor de pagos con cuentas conectadas (por ejemplo, Stripe Connect) solo tras decidir países, entidad legal, onboarding, comisiones y reembolsos.
8. No guardar datos de tarjetas en THE WALL.

Dependencia crítica: lógica de pagos y cambios de estado en backend confiable, webhooks firmados e idempotencia. No procesar dinero desde JavaScript del navegador.

## Fase 5 — Subastas

1. Definir subasta, unidades, precio inicial, incremento mínimo, fecha/hora de cierre y compra inmediata opcional.
2. Definir máximo de unidades por participante.
3. Registrar pujas inmutables con usuario, importe, unidades solicitadas y marca temporal del servidor.
4. Validar incremento, elegibilidad, límites y cierre en transacción de base de datos o backend.
5. Resolver empates por la puja registrada primero.
6. Para múltiples unidades, adjudicar a las mejores pujas hasta agotar unidades, respetando máximo por participante; cada ganador paga su propia puja ganadora.
7. Para una unidad, un solo ganador.
8. Notificar cuando una puja queda superada y mostrar contador sincronizado con servidor.
9. Gestionar pagos fallidos, reservas vencidas, cancelaciones y disputas.

Dependencia crítica: transacciones/funciones de servidor, reloj de servidor y pruebas concurrentes. No activar subastas reales con lógica solo de frontend.

## Fase 6 — Marketplace internacional

1. Modelo de países habilitados y restricciones.
2. Monedas y redondeo por moneda.
3. Idiomas y traducciones.
4. Motor fiscal configurable por jurisdicción, tipo de vendedor, comprador y producto.
5. Envíos, seguimiento, aduanas y restricciones para obras físicas.
6. Entrega protegida y derechos/licencias para productos digitales.
7. Activación progresiva de países tras verificar pagos, fiscalidad, envíos y requisitos legales.

No aplicar un IVA universal ni afirmar que todos los países están habilitados.

## Fase 7 — Preparación para lanzamiento

- Términos y condiciones.
- Política de privacidad y cookies.
- Propiedad intelectual y licencias.
- Política de envíos, devoluciones y reembolsos.
- Reglas de subastas.
- Procedimientos de soporte, reclamaciones y moderación.
- Pruebas de accesibilidad, seguridad, carga y recuperación.
- Copias de seguridad y procedimiento de incidentes.
- Revisión legal/fiscal en las jurisdicciones activadas.

## Orden recomendado de trabajo inmediato

1. Probar el cambio multimedia ya guardado.
2. Auditar las políticas reales de Supabase sin modificarlas a ciegas.
3. Resolver los hallazgos de RLS y Storage con migraciones pequeñas.
4. Completar perfil creador y propuestas de modalidades con aprobación ADMIN.
5. Terminar estadísticas y área cliente.
6. Construir Writer/Literature.
7. Después iniciar ventas, pagos y subastas.
