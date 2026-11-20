# Reglas de negocio, paquetes y salidas

- **Fecha:** 20 de noviembre de 2026, 01:16 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios; el trabajo no modifica el informe)
- **Alcance:** consolidación de las reglas de negocio, corrección de la
  gestión de paquetes (HU-01), implementación de salidas (HU-02) y
  alineación de los diagramas de secuencia, clases, objetos y casos de uso.

## Antecedente

La tarea T-HU-01.1 figuraba como hecha, pero su propio enunciado pedía
registrar paquetes con destino e itinerario. El esquema no tenía destino, el
itinerario era opcional y el precio admitía cero. Las reglas estaban
repartidas entre el esquema, las historias de usuario, la aplicación y el
informe, sin una fuente única ni trazabilidad.

## Decisiones aplicadas

1. **Cliente** queda como término canónico para quien contrata y paga;
   **pasajero** para quien viaja; **turista** solo como sinónimo comercial.
   El rol `TURISTA` se renombró a `CLIENTE`.
2. El **itinerario** es opcional en borrador y obligatorio para publicar.
   Se complementa con una lista de actividades comunes marcadas con casillas.
3. El alcance de esta iteración se limita a **paquetes y salidas**. Reservas,
   pagos, cotizaciones, pasajeros, proveedores y avisos quedan para sus
   propios tickets.
4. **`sistema/reglas-negocio.md`** es la fuente canónica de las reglas;
   `bd/diccionario-datos.md` queda como referencia del esquema físico.
5. Las reglas no se incorporan todavía al informe; quedan en la
   documentación de trabajo.

## Cambios de formato

No hubo cambios de formato en el informe. No se modificó ningún archivo
LaTeX y el PDF conserva sus 21 páginas.

## Cambios de contenido

### Catálogo de reglas

- Se creó `sistema/reglas-negocio.md` con:
  - términos canónicos y convenciones;
  - reglas generales, de paquetes, actividades, salidas y roles;
  - matriz de campos obligatorios por estado;
  - máquinas de estado de paquete y salida;
  - trazabilidad con HU-01, HU-02, HU-03, HU-09 y HU-08;
  - reglas pendientes de otros módulos;
  - gobierno del catálogo y definición de terminado.
- `bd/diccionario-datos.md` pasó a describir el esquema físico y a
  referenciar el catálogo. Se corrigieron los conteos: 20 tablas, 3 vistas,
  12 funciones (9 de negocio) y 5 disparadores.
- `AGENTS.md`, `web/AGENTS.md`, `README.md` y la documentación de la web
  apuntan al catálogo.

### Paquetes turísticos

- Se agregó `destino` a `paquete`.
- El estado `activo` exige destino, descripción, itinerario y servicios
  incluidos no vacíos. El borrador puede quedar incompleto.
- El precio base debe ser mayor que cero.
- El código debe estar en mayúsculas.
- Se agregó `id_usuario_actualizacion`.
- Se validan las transiciones `borrador → activo/inactivo`,
  `activo → inactivo` e `inactivo → activo`.
- Un paquete activo que no cumple el contenido mínimo pasa a `borrador`
  durante la migración.

### Actividades del itinerario

- Se agregaron las tablas `actividad` y `paquete_actividad`.
- El catálogo inicial incluye desayuno, almuerzo, cena, transporte,
  alojamiento, guía, entradas, traslado, seguro, bebidas y actividades
  recreativas.
- La interfaz permite marcarlas con casillas; el texto libre del itinerario
  se conserva.

### Salidas programadas

- Se implementó el alta y la edición de salidas.
- Solo un paquete `activo` admite salidas.
- Se valida que la fecha de salida no sea pasada, que el retorno no sea
  anterior y que la duración coincida con la del paquete.
- Se impide más de una salida del mismo paquete en la misma fecha.
- Capacidad y precio deben ser mayores que cero.
- Se implementaron las transiciones `programada → confirmada`,
  `programada → cancelada`, `confirmada → realizada` y
  `confirmada → cancelada`.
- La cancelación exige motivo.
- Se auditan fecha, retorno, capacidad, precio, punto de encuentro y estado.
- Una salida realizada o cancelada no se modifica.
- El paquete de una salida existente no se cambia.

### Disponibilidad

- `vista_disponibilidad_salida` expone `estado_paquete` y el estado de la
  salida.
- `/api/disponibilidad` filtra paquetes activos y salidas programadas o
  confirmadas desde la fecha actual.

### Roles

- El rol `TURISTA` se renombró a `CLIENTE` en el esquema, los tipos, la API,
  la interfaz, los textos y la documentación.
- La migración reasigna las cuentas si existen ambos roles.

### Diagramas

- Se agregaron los diagramas de secuencia de HU-01 y HU-02, completos y
  ligeros.
- Se alinearon HU-03, HU-05, HU-06, HU-09 y el subflujo de disponibilidad.
- Se renombró el actor «Turista» a «Cliente» en los diagramas.
- Se agregaron `destino`, `Actividad` y `PaqueteActividad` al diagrama de
  clases y al de objetos.
- `make verificar` revisa 33 archivos `.puml` sin problemas.

## Archivos modificados

### Nuevos

- `sistema/reglas-negocio.md`
- `bd/actualizaciones/2026-11-20-reglas-paquetes.sql`
- `bd/pruebas/reglas-paquetes.sql`
- `web/server/utils/salidas.ts`
- `web/server/api/admin/actividades.get.ts`
- `web/server/api/admin/salidas.get.ts`
- `web/server/api/admin/salidas.post.ts`
- `web/server/api/admin/salidas/[id].patch.ts`
- `web/app/pages/admin/salidas.vue`
- `sistema/diagramas/uml/secuencia/hu-01-gestionar-paquetes.puml`
- `sistema/diagramas/uml/secuencia/hu-02-programar-salida.puml`
- `sistema/diagramas/uml/secuencia-light/hu-01-gestionar-paquetes.puml`
- `sistema/diagramas/uml/secuencia-light/hu-02-programar-salida.puml`

### Modificados

- `Makefile`: objetivos `db-actualizar` y `db-probar`; carga de `.env.local`.
- `bd/esquema.sql`, `bd/diccionario-datos.md`.
- `web/db/schema.ts`, `web/shared/types/api.ts`,
  `web/shared/types/domain.ts`.
- `web/server/utils/paquetes.ts`,
  `web/server/api/admin/paquetes.get.ts`,
  `web/server/api/admin/paquetes.post.ts`,
  `web/server/api/admin/paquetes/[id].patch.ts`,
  `web/server/api/disponibilidad.get.ts`.
- `web/server/api/admin/usuarios.post.ts`,
  `web/server/api/admin/usuarios/[id].patch.ts`,
  `web/server/api/cuenta.get.ts`, `web/server/utils/usuarios.ts`,
  `web/server/middleware/sesion.ts`.
- `web/app/pages/admin/paquetes.vue`,
  `web/app/pages/admin/usuarios.vue`,
  `web/app/components/BarraNavegacion.vue`,
  `web/app/composables/useMensajeError.ts`,
  `web/app/i18n/locales/es.ts`, `web/app/i18n/locales/en.ts`.
- `web/docs/arquitectura.md`, `web/docs/autenticacion.md`,
  `web/docs/base-de-datos.md`, `web/docs/pruebas.md`.
- `web/CONFIGURACION.md`, `web/README.md`, `README.md`, `AGENTS.md`,
  `web/AGENTS.md`.
- `sistema/historias-usuario/historias-usuario.md`.
- Diagramas de secuencia, secuencia ligera, fusionados, comunes,
  estructurales, de procesos y de casos de uso.
- `sistema/diagramas/README.md` y los README de las carpetas de diagramas.

## Validación

- `npm run typecheck --workspace web`: sin errores.
- `npm run build --workspace web`: compila.
- `make verificar`: 33 diagramas revisados, 0 problemas.
- `make diagramas`: genera los PDF de todos los diagramas.
- `make`: compila y publica el PDF de 21 páginas.
- `make db-probar`: 8 comprobaciones SQL correctas.
- Migración probada sobre:
  - una base creada desde cero;
  - una base con el esquema anterior;
  - una base con rol `TURISTA` y una cuenta asignada;
  - una base con un paquete activo incompleto, que pasó a `borrador`.
- Migración ejecutada dos veces para comprobar idempotencia.
- `make db-actualizar` probado contra un PostgreSQL local con el esquema
  anterior.
- La migración no se aplicó a la base de Neon.

## Pendientes

- Aplicar la migración a Neon con `make db-actualizar`.
- Mover T-HU-02.1 y T-HU-02.2 en el tablero; T-HU-01.1 y T-HU-01.2 ya
  estaban en `Hecho`.
- Implementar las reglas de reservas, pagos, cotizaciones, pasajeros,
  proveedores y avisos en sus propios tickets.
- Vincular automáticamente una cuenta `CLIENTE` con su ficha; por ahora el
  panel permite crear el rol sin ficha.
- Resolver los roles por `codigo` en lugar de identificadores fijos.
- Configurar Vitest para las pruebas de API e interfaz.
- Incorporar las reglas al informe cuando se solicite; en esta iteración
  quedaron solo en la documentación de trabajo.
