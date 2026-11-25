# Registro de cambios

Bitácora de los trabajos aceptados en el proyecto: correcciones de formato y
de contenido aplicadas al informe. **No forma parte de `main.tex`** ni del
PDF final.

Este archivo es la **referencia canónica** de la convención.

## Convención de nombres

Cada trabajo aceptado se guarda en un archivo independiente:

```text
YYYY-MM-DDTHHMMSS_descripcion-breve.md
```

Ejemplo:

```text
2026-11-17T104129_correcciones-formato-contenido.md
```

La hora es la hora local del equipo. El nombre descriptivo debe resumir el
alcance principal del trabajo.

## Estructura de cada registro

Cada archivo debe incluir, como mínimo:

1. **Fecha y alcance** del trabajo.
2. **Documento generado** y número de páginas.
3. **Cambios de formato**.
4. **Cambios de contenido**, organizados por sección.
5. **Archivos modificados**.
6. **Validación realizada**.
7. **Pendientes o decisiones** para el siguiente trabajo.

## Reglas

- El registro se escribe **una vez que el usuario acepta el trabajo**, no al
  cerrar cada iteración técnica. Un trabajo aceptado genera **un** registro.
- Si un trabajo se corrige antes de ser aceptado, las correcciones quedan en
  el árbol de trabajo y no generan entradas adicionales.
- No se modifican los registros ya aceptados, salvo que el usuario pida
  explícitamente fusionarlos.
- Los cambios deben describirse en tercera persona y sin datos sensibles.
- Si un cambio se revierte, se registra la reversión en la iteración
  correspondiente, no se borra el registro anterior.
- Los archivos de esta carpeta no se incluyen en el informe LaTeX.

## Iteraciones

| Fecha | Archivo | Alcance |
|---|---|---|
| 2026-11-17 10:41 | `2026-11-17T104129_correcciones-formato-contenido.md` | Formato general y correcciones de contenido de las secciones 1 a 10. |
| 2026-11-17 11:23 | `2026-11-17T112357_canal-autoservicio-turista.md` | Canal de autoservicio del cliente en el informe y en la base de datos temporal. |
| 2026-11-17 11:44 | `2026-11-17T114408_backlog-y-diagramas-de-secuencia.md` | Backlog de historias de usuario revisado y diagramas de secuencia regenerados. |
| 2026-11-17 12:03 | `2026-11-17T120305_exportacion-png.md` | Exportación de diagramas a PNG y corrección de los diagramas de secuencia. |
| 2026-11-17 13:12 | `2026-11-17T131205_verificacion-y-correccion-de-la-documentacion.md` | Verificación de la reagrupación y corrección de la documentación que no había cambiado. |
| 2026-11-17 13:16 | `2026-11-17T131626_reorganizacion-del-proyecto.md` | Reagrupación de carpetas, publicación del PDF final y regla del registro de cambios. |
| 2026-11-17 14:05 | `2026-11-17T140522_refactorizacion-de-la-documentacion.md` | Refactorización de la documentación: `AGENTS.md` como punto de entrada breve y documentos de referencia. |
| 2026-11-17 14:28 | `2026-11-17T142834_titulo-en-los-diagramas.md` | Título de la historia de usuario en la parte superior de los diagramas. |
| 2026-11-17 15:04 | `2026-11-17T150433_colocacion-de-titulos-y-portada.md` | Colocación de los títulos sin huecos y portada con dos autores. |
| 2026-11-17 17:16 | `2026-11-17T171611_criterios-y-desglose-de-tareas.md` | Criterios de aceptación de las 17 historias y desglose de las 39 tareas del backlog. |
| 2026-11-17 17:53 | `2026-11-17T175303_tablero-kanban.md` | Tablero kanban generado desde el backlog, con comandos de regeneración, verificación y requisitos de visualización. |
| 2026-11-18 13:44 | `2026-11-18T134441_monorepo-y-web-del-sistema.md` | Monorepo: la web del sistema (Nuxt, Drizzle, Better Auth, Neon), el esquema con Better Auth y la reorganización del repositorio. |
| 2026-11-18 14:57 | `2026-11-18T145700_estructura-de-desarrollo-de-la-web.md` | Estructura de desarrollo agéntico de la web: sistema de diseño, textos centralizados, componentes base, tipos compartidos y documentación. |
| 2026-11-18 17:37 | `2026-11-18T173757_neon-y-ajuste-del-esquema.md` | Base de datos en Neon (São Paulo) y ajuste del esquema, las funciones y la configuración para el pooler. |
| 2026-11-19 14:25 | `2026-11-19T142508_configuracion-multiplataforma-y-readmes-concisos.md` | Configuración de VS Code sin rutas locales y READMEs reducidos y sin duplicación. |
| 2026-11-19 15:18 | `2026-11-19T151851_cuentas-internas-y-gestion-de-usuarios.md` | Cuentas internas sin correo, cambio obligatorio de contraseña y panel de administración de usuarios. |
| 2026-11-19 15:46 | `2026-11-19T154655_paquetes-y-fichas-de-clientes.md` | Gestión de paquetes turísticos (HU-01) y fichas de clientes (HU-04), con permiso de personal. |
| 2026-11-19 16:05 | `2026-11-19T160504_portada-navegacion-y-estados-de-carga.md` | Convenciones de la interfaz, encabezado nuevo, portada sin prueba de conexión y aviso de carga. |
| 2026-11-19 17:30 | `2026-11-19T173017_tablero-planificacion-prioridades-y-etiquetas.md` | Tablero con fechas, costos, prioridades reequilibradas y etiquetas de prioridad. |
| 2026-11-19 19:38 | `2026-11-19T193822_tablero-como-fuente-y-exportador.md` | El tablero pasa a ser la fuente; validador, resumen y exportador al backlog. |
| 2026-11-20 01:16 | `2026-11-20T011659_reglas-paquetes-y-salidas.md` | Catálogo de reglas, paquetes con destino e itinerario, actividades, salidas y rol `CLIENTE`. |
| 2026-11-20 11:56 | `2026-11-20T115641_paquetes-lugares-servicios-y-mapa.md` | Lugares, recorrido, servicios incluidos, código automático y mapa en la ficha del paquete. |
| 2026-11-23 14:33 | `2026-11-23T143302_cierre-hu-02-y-hu-03.md` | Salidas como tarjetas, precio efectivo con precarga, desglose de disponibilidad para el personal y cierre de HU-02/HU-03. |
| 2026-11-23 14:53 | `2026-11-23T145312_proveedores-y-cotizaciones.md` | Proveedores con vínculos a paquetes, cotizaciones con número automático, condiciones y datos de ejemplo. |
| 2026-11-23 16:30 | `2026-11-23T163056_reservas-y-solicitudes.md` | Reservas en los dos canales con validación de cupos, página de solicitudes del personal, confirmación y vencimiento de las pendientes. |
| 2026-11-23 17:09 | `2026-11-23T170900_cupos-en-cotizaciones-y-tarjetas-de-disponibilidad.md` | Control de cupos en cotizaciones, tarjetas informativas en la disponibilidad y botón de envío en la solicitud web. |
| 2026-11-23 17:46 | `2026-11-23T174644_topes-del-canal-web-y-desglose-publico.md` | Tope de pasajeros y de retención para las solicitudes web, desglose público de confirmados y pendientes, y prueba con alcance corregido. |
| 2026-11-23 18:15 | `2026-11-23T181551_proveedores-multitipo-y-vinculo-seleccionable.md` | Proveedores con varios tipos de servicio, vínculo que usa un tipo declarado con detalle opcional, y pruebas de la FK compuesta. |
| 2026-11-23 18:25 | `2026-11-23T182513_correccion-casillas-de-verificacion.md` | Corrección de la asociación de etiquetas: el clic sobre el texto ya conmuta la casilla propia en proveedores y paquetes. |
| 2026-11-24 01:21 | `2026-11-24T012148_barra-navegacion-salidas-fusionadas-tema.md` | Barra de navegación reorganizada, salidas fusionadas con «Próximas salidas», selector de tema y banderas de idioma. |
| 2026-11-24 12:52 | `2026-11-24T125224_cuentas-de-cliente-pagos-simulados-y-reserva-con-cuenta.md` | Registro público de cuentas de cliente con ficha, fin de la solicitud anónima, pagos con pasarela simulada, anticipo del 30% y vencimiento de 24 horas. |
| 2026-11-24 14:37 | `2026-11-24T143747_ciclo-completo-de-la-reserva.md` | Manifiesto de pasajeros, modificación con revalidación de cupos, cancelaciones en dos pasos, avisos derivados del historial y reportes por fecha y paquete. |
| 2026-11-24 16:46 | `2026-11-24T164635_cierre-del-backlog-de-historias.md` | Cierre del backlog 44/44: finalización de reservas con la salida realizada, retención web revalidada al modificar, barrido manual desde la bandeja, reservas originadas desde cotizaciones e historias en formato Scrum. |
| 2026-11-24 17:09 | `2026-11-24T170946_codigo-propio-de-las-salidas.md` | Corrección del doble código en «Próximas salidas»: código único e inmutable por salida (RN-SAL-22), derivado del paquete con un ordinal, expuesto en la vista de disponibilidad y en las tarjetas. |
| 2026-11-25 11:12 | `2026-11-25T111259_pagos-por-partes-retencion-70-y-avisos-flotantes.md` | Pagos por partes con tope por saldo, retención web del 70% de los cupos disponibles, colores de estado reparados en el sistema de diseño, avisos flotantes en solicitudes y pagos, indicadores de manifiesto y saldo, y cadena de actualizaciones de la base idempotente. |
| 2026-11-25 12:19 | `2026-11-25T121932_ficha-de-la-salida-y-detalles-de-proveedores.md` | Ficha clicable de la salida con mapa de ruta, itinerario por días y proveedores con detalles por servicio (HU-18 y HU-19), asignaciones operativas por salida, itinerario estructurado en el paquete y datos de demostración regionales renovados. |
| 2026-11-25 13:04 | `2026-11-25T130439_ficha-de-la-salida-legible.md` | Ficha de la salida legible: detalles compactos con iconos en lugar de mini-bloques, paradas al lado del mapa, diálogo más ancho y subtítulos de sección uniformes; sustituye la iteración descartada sobre la copia desactualizada. |
| 2026-11-25 13:11 | `2026-11-25T131141_ficha-proveedores-y-solicitud.md` | Proveedores de la ficha con formato (chip de tipo, detalles estructurados, dos columnas), insignias de asignaciones con icono y botón de solicitud dentro de la ficha. |
| 2026-11-25 13:42 | `2026-11-25T134225_capturas-de-la-web-por-proposito.md` | Capturas de la web agrupadas por propósito (público, flujo de reserva web, personal y administración) con índice de procedencia, flujo principal capturado entero y actualización de la base desfasada. |
| 2026-11-25 14:36 | `2026-11-25T143609_landing-page-de-cliente.md` | Portada del sistema reorientada al cliente: hero con degradado de la marca, beneficios y pasos de la reserva, textos nuevos en español e inglés y contraste robusto en modo claro. |
