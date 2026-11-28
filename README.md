# THE WALL !

**Creative people, everywhere.**  
Marketplace creativo internacional para descubrir, compartir y comercializar obras y talento independiente.

Web publicada: https://mikustreet1313.github.io/The-Wall-Marketplace/

## Estado del proyecto

THE WALL ! se desarrolla por módulos. El código publicado incluye actualmente:

- Portada y navegación principal.
- Registro e inicio de sesión de creadores y clientes mediante Supabase Auth.
- Panel privado de creador.
- Publicación de obras con varias imágenes y vídeos.
- Galería pública y galería privada del creador.
- Edición de título, modalidad, descripción y visibilidad.
- Preparación para añadir más imágenes y vídeos a obras existentes.
- Interacciones públicas Me gusta y Guardar.
- Área de cliente con acceso a creaciones propias y favoritos.

Las ventas, los pagos, las subastas, Writer/Literature, la administración y la logística internacional son requisitos del producto en desarrollo; no deben considerarse activos hasta que se implementen y prueben.

## Tecnología

- Frontend: HTML, CSS y JavaScript.
- Publicación: GitHub Pages.
- Backend: Supabase Auth, PostgreSQL, Row Level Security y Storage.
- Bucket de archivos: `wall media` (privado).
- La web usa una clave publishable en el navegador. Nunca introducir una clave `service_role` en el frontend.

## Documentación del proyecto

- [Reglas de producto y decisiones acordadas](docs/THE_WALL_PRODUCT_RULES.md)
- [Hoja de ruta y dependencias](docs/IMPLEMENTATION_ROADMAP.md)
- [Plan de pruebas de aceptación](docs/ACCEPTANCE_TEST_PLAN.md)
- [Consultas SQL de auditoría de solo lectura](docs/SQL_SECURITY_AUDIT_READ_ONLY.sql)
- [Borrador SQL de Writer y modalidades (NO EJECUTADO)](docs/PROPOSED_SCHEMA_WRITER_MODALITIES.sql)

## Criterios de desarrollo

1. Preservar el diseño y los flujos ya aprobados.
2. Cambios pequeños, aditivos y verificables.
3. No eliminar ni sobrescribir datos reales para probar funciones.
4. No activar pagos ni subastas reales sin controles de servidor, pruebas y revisión legal.
5. Distinguir entre función diseñada, código guardado, configuración aplicada y función probada en navegador.
