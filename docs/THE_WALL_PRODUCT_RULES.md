# THE WALL ! — Reglas de producto y criterios de implementación

Documento maestro de requisitos acordados. Sirve para evitar que futuras modificaciones contradigan decisiones ya tomadas. Una regla descrita aquí es un requisito de producto; no significa que la función ya esté programada o activada.

## 1. Principios del marketplace

- THE WALL ! será un marketplace creativo internacional, abierto a creadores y compradores de distintos países, dentro de los límites legales, de pagos, logística, impuestos y restricciones aplicables.
- La arquitectura debe permitir habilitar países progresivamente, sin asumir que todos los países estarán disponibles desde el primer día.
- Mantener la identidad visual editorial ya aprobada. No rediseñar páginas existentes sin pedir confirmación.
- Construir por módulos y preservar los flujos que ya funcionan. Las migraciones de base de datos deben ser aditivas y reversibles cuando sea posible.
- Separar páginas y áreas funcionales; evitar convertir la web en una única página interminable.

## 2. Cuentas, perfiles y permisos

- Hay tres roles de aplicación: CUSTOMER, CREATOR y ADMIN.
- El alta de creador recoge nombre artístico, email, disciplina principal, visión principal, hasta dos visiones secundarias y visión del proyecto a cinco años.
- Un creador puede gestionar únicamente su perfil, obras, archivos, ventas y contenidos.
- Un cliente puede explorar las publicaciones públicas e interactuar con ellas según las reglas de cada módulo.
- Las acciones administrativas deben quedar reservadas a ADMIN y no deben confiar en controles visuales del navegador: deben validarse también en Supabase.
- Los datos privados de una cuenta no deben hacerse públicos por el mero hecho de existir un perfil.
- El creador puede solicitar el cierre/eliminación de su cuenta. Para proteger la autoría y el legado artístico, el cierre conservará su nombre artístico y sus publicaciones públicas, pero estas pasarán a ser de consulta: no se podrán comprar, pujar ni iniciar nuevas transacciones sobre ellas. El perfil debe identificarse claramente como inactivo y el creador perderá el acceso de inicio de sesión y la capacidad de editar contenido.
- El cierre de cuenta de creador debe implementarse como un proceso seguro de baja lógica/retirada de acceso, no como un borrado directo desde el navegador. Debe bloquear nuevas ventas y subastas en el servidor/base de datos, cancelar o resolver de forma segura operaciones pendientes y conservar solo los datos necesarios para autoría, obligaciones legales y seguridad. La política de eliminación de cuentas CUSTOMER se definirá por separado.

## 3. Obras y publicaciones

- Se permiten obras físicas y digitales.
- Una publicación puede contener varias imágenes y vídeos.
- La primera imagen debe poder actuar como portada; el resto debe permitir mostrar otros ángulos, detalles y vistas ampliadas.
- El creador puede editar título, modalidad, descripción y visibilidad.
- El creador puede añadir más fotos o vídeos después de publicar, sin tener que borrar los archivos existentes.
- El creador puede eliminar sus propias publicaciones; la operación debe confirmar la intención y limpiar los archivos asociados sin afectar a otras cuentas.
- Visibilidad prevista: PUBLIC, PRIVATE y SCHEDULED. Una publicación programada solo se muestra cuando llega su fecha/hora.
- Las publicaciones públicas pueden aparecer en el muro público. Las privadas solo deben ser accesibles por su propietario y por funciones administrativas autorizadas.
- La modalidad artística se puede proponer desde el área creador. Una modalidad nueva no pasa al catálogo general hasta que ADMIN la revise y apruebe.

## 4. Interacciones y descubrimiento

- Se contemplan interacciones LIKE y SAVE.
- Cada usuario solo puede tener una interacción de cada tipo por publicación.
- Los usuarios pueden retirar sus propias interacciones.
- El creador puede consultar las interacciones agregadas de sus propias obras, sin acceder a datos privados ajenos que no necesite.
- El muro debe permitir descubrir obras por disciplina/categoría y mostrar contenido editorial o seleccionado para THE WALL IS YOURS.

## 5. Literatura

- Debe existir una sección Writer dentro del espacio creador para redactar y publicar obras literarias.
- Debe existir una sección Literature para que los clientes descubran y lean esas obras.
- La literatura debe integrarse como modalidad propia, sin forzarla dentro del formulario de obras visuales.
- Deben respetarse autoría, visibilidad y permisos de edición del escritor.

## 6. Ventas y pedidos

- El creador podrá indicar si una obra está a la venta y fijar su precio.
- Debe existir un área My Sales para gestionar ventas y pedidos.
- Estados previstos: pending, payment, shipped y completed; el flujo final deberá definir también cancelaciones, reembolsos y disputas antes de activar pagos reales.
- El checkout debe desglosar claramente precio del artículo, envío, comisión de THE WALL, impuestos aplicables y total.
- No aplicar un porcentaje fiscal universal. Los impuestos dependen del país, ubicación de comprador/vendedor, naturaleza del producto y normativa aplicable.
- Las comisiones de THE WALL deben poder configurarse por región, tipo de venta o categoría de producto.
- Stripe Connect es una opción técnica futura a evaluar para pagos a vendedores; no está conectado ni debe anunciarse como activo hasta completar configuración, verificación y pruebas.
- No almacenar datos de tarjetas en la base de datos de THE WALL.

## 7. Subastas

- Se contemplan subastas de una o varias unidades.
- El creador define precio inicial, incremento mínimo y número máximo de unidades disponibles.
- El creador puede definir el máximo de unidades que cada participante puede adquirir.
- Puede existir una opción de compra inmediata, si el creador la activa.
- Debe mostrarse un contador de tiempo y notificarse a un participante cuando otra puja supere la suya.
- En subastas con varias unidades, ganan los mejores pujadores hasta cubrir las unidades disponibles, respetando el límite por participante.
- Cada ganador paga el importe de su propia puja ganadora; no se igualan automáticamente todos los precios.
- En caso de empate, prevalece la puja registrada primero.
- En una obra única solo puede haber un ganador.
- El cierre, asignación de ganadores, reservas de inventario y pagos deben resolverse en servidor/transacción para evitar dobles adjudicaciones o manipulación del navegador.

## 8. Envíos, divisas y países

- Diseñar para múltiples monedas, idiomas, métodos de pago locales y destinos de envío.
- Los productos físicos pueden requerir tarifas, plazos, aduanas, restricciones y seguimiento según origen y destino.
- Los productos digitales requieren entrega segura y reglas propias de descarga/acceso.
- Habilitar países progresivamente según disponibilidad legal, fiscal, bancaria y logística.
- No prometer disponibilidad mundial hasta que cada país y proveedor correspondiente esté validado.

## 9. Seguridad, privacidad y moderación

- Mantener Row Level Security (RLS) activado en tablas con datos de usuarios.
- Un usuario solo puede modificar o borrar sus propios registros, salvo operaciones administrativas expresamente autorizadas.
- Los archivos de obras se guardan en el bucket privado `wall media`; el acceso público a medios de publicaciones públicas se concede mediante la política correspondiente y URLs firmadas de duración limitada.
- Las claves secretas de servidor nunca deben incluirse en HTML, JavaScript público o repositorios. La clave publishable del cliente no sustituye a RLS.
- Validar rol, propiedad, visibilidad, precio, inventario, pujas y estados de pago en el servidor/base de datos, no solo en el frontend.
- Las funciones administrativas y de moderación deben registrar quién realizó cambios relevantes.
- Antes de abrir el marketplace al público deben redactarse y publicar términos de uso, política de privacidad, cookies, propiedad intelectual, devoluciones/reembolsos, envíos y reglas de subastas, con revisión jurídica adecuada para los países habilitados.

## 10. Estado técnico conocido a 28-11-2026

### Verificado durante el desarrollo
- GitHub Pages publica la web desde el repositorio `The-Wall-Marketplace`.
- Supabase Auth está conectado mediante la clave publishable.
- El alta y login de creador funcionan en las pruebas realizadas.
- Existe el panel privado del creador.
- La publicación de obras con múltiples archivos está implementada.
- La galería de imágenes/vídeos de las obras propias está implementada.
- La edición de metadatos de una obra funciona en la prueba realizada.
- La edición del panel se ha ampliado para permitir añadir nuevos archivos multimedia a una obra existente. Pendiente de prueba manual en navegador.
- La eliminación de obras está implementada en la interfaz, pero no se debe considerar verificada hasta probarla cuidadosamente.

### Base de datos y seguridad ya configuradas según las comprobaciones realizadas
- Tablas `profiles`, `wall_posts`, `wall_post_media` y `wall_post_interactions`.
- Trigger de creación de perfil al registrar usuario.
- Políticas RLS para que cada creador gestione sus propias obras y archivos.
- Lectura de publicaciones públicas y programadas cuando ya son visibles.
- Bucket privado `wall media` y políticas de acceso a medios públicos/propios.
- Interacciones LIKE/SAVE y función RPC para recuentos públicos.
- No se ha realizado desde este repositorio una auditoría directa en vivo de las políticas de Supabase en esta sesión.

### Aún no implementado o no verificado
- Aprobación administrativa de nuevas modalidades.
- Panel ADMIN y herramientas de moderación.
- Writer y Literature funcionales.
- Checkout, pagos reales, Stripe Connect, comisiones y reembolsos.
- My Sales y ciclo completo de pedidos.
- Subastas y adjudicación transaccional.
- Motor fiscal, aduanas, envíos, multi-moneda y habilitación por país.
- Estadísticas completas y notificaciones.
- Textos legales finales y consentimiento de usuario.

## 11. Regla para futuros cambios

Antes de cada cambio:
1. Revisar el archivo y la estructura existentes.
2. Evitar duplicar páginas, tablas, columnas, políticas o triggers.
3. No sobrescribir ni borrar datos de usuarios.
4. Preferir cambios pequeños, verificables y reversibles.
5. Comprobar el resultado después de guardar y distinguir claramente entre código publicado, configuración de Supabase y función probada en navegador.
