# Monorepo: la web del sistema y la reorganización del repositorio

- **Fecha:** 18 de noviembre de 2026, 13:44 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios; el trabajo no modifica el informe)
- **Alcance:** el repositorio pasa a ser un monorepo con dos módulos —el
  informe y la web—, el esquema de la base de datos se reescribe para la
  identidad con Better Auth y las reglas críticas pasan a funciones
  PL/pgSQL, y el tablero, la bitácora y la base de datos se mudan a la raíz.

## Antecedente

El proyecto tenía el informe, sus diagramas, el backlog, el tablero y el
esquema de la base de datos, pero ninguna implementación. Con el alcance ya
definido —17 historias, 39 tareas y 188 horas-persona de esfuerzo
estimado— se decidió la pila de la web: **Nuxt 4** con **Drizzle ORM**,
**Better Auth** para la identidad y **Neon** como PostgreSQL, desplegada en
**Vercel**.

Deliberadamente **no** se movió el proyecto LaTeX a una carpeta propia: vive
en la raíz y desde ahí se compila con `make`. Reorganizarlo habría roto el
`Makefile`, el `build.ps1`, la clase `si3apa7.cls` y el verificador
de rutas, sin ganancia funcional. El monorepo se logra agregando la carpeta
`web/` y un espacio de trabajo de npm.

## Decisiones de diseño

| Decisión | Motivo |
|---|---|
| Las reglas críticas en PL/pgSQL | La validación de cupos necesita bloquear la fila de la salida. Con la regla en la base, la atomicidad no depende del transporte con el que se conecte. |
| El estado de vencimiento es derivado | Una solicitud pendiente cuyo plazo venció deja de ocupar cupo en el momento en que expira, porque así lo calculan las vistas. El barrido diario solo limpia el estado guardado. |
| Better Auth como biblioteca | Las tablas de sesión y cuentas viven en la base del negocio. Neon también ofrece su Better Auth alojado, pero se perdió a favor de mantener el control del esquema. |
| Identificadores de texto | Better Auth genera el identificador de la cuenta, de modo que las claves foráneas hacia `usuario` son de texto. |
| `pg` y no el controlador de Neon | El controlador sin estado de Neon no acepta un PostgreSQL local, que es lo que se usa en desarrollo. Con la cadena *pooled* de Neon, `pg` funciona en los dos lados. |

## Cambios de formato

No hubo cambios de formato en el informe: no se modificó ningún archivo
LaTeX y el PDF conserva sus 21 páginas. En los diagramas estructurales, la
clase `Usuario` pasó de `idUsuario : BIGINT` a `id : String` y se agregó la
clase `Sesion`; en los diagramas de objetos, los identificadores de cuenta
son ahora de texto.

## Cambios de contenido

### Reorganización del repositorio

| Antes | Ahora |
|---|---|
| `documentacion/` | `docs/` |
| `documentacion/registro-cambios/` | `docs/changelog/` |
| `sistema/tablero/` | `tablero/` |
| `sistema/base-de-datos/` | `bd/` |
| `sistema/base-de-datos/esquema-temporal.sql` | `bd/esquema.sql` |
| `app/` (la web del sistema) | `web/` |

El tablero y la base de datos suben a la raíz porque son material de trabajo
del día a día, no especificación del sistema; `sistema/` queda con lo que
es: el diseño (diagramas, backlog y estimación). La carpeta de la web se
llama `web/`, no `app/`: dentro de ella, `web/app/` es la carpeta de origen
de Nuxt 4, que usa ese nombre por convención propia. El `verificador-rutas.py`
se invirtió: `docs/` es ahora la ruta vigente y `documentacion/` pasó a
ser la obsoleta, junto con `sistema/tablero/`, `sistema/base-de-datos/` y
`esquema-temporal.sql`.

### El esquema de la base de datos

`bd/esquema.sql` se reescribió como script de creación —la base todavía no
existía, así que no hay migraciones ni cambios `ALTER`— con tres cambios:

1. **Identidad con Better Auth.** `usuario` es la tabla `user` de la
   biblioteca, renombrada porque `user` es palabra reservada en SQL, con
   los campos del dominio como campos adicionales. Se agregaron `session`,
   `account` y `verification`, más `acceso`, que registra los ingresos como
   exige el criterio de HU-08.
2. **Las reglas críticas pasaron a funciones.** `fn_crear_reserva`,
   `fn_confirmar_reserva`, `fn_actualizar_salida`,
   `fn_solicitar_cancelacion`, `fn_ejecutar_cancelacion`,
   `fn_registrar_pago` y `fn_validar_pago` aplican las reglas dentro de la
   base, con bloqueo de fila y auditoría.
3. **El vencimiento es derivado.** Las vistas de disponibilidad y de
   ocupación excluyen las solicitudes cuyo plazo venció, aunque su estado
   guardado siga siendo `pendiente`. `fn_vencer_solicitudes_pendientes()`
   queda como el barrido diario de limpieza.

`bd/diccionario-datos.md` se reescribió para describir el esquema nuevo,
sus reglas y el mapeo con Better Auth.

### La web del sistema

`web/` contiene el esqueleto de la aplicación Nuxt 4:

- `db/schema.ts`: el esquema en TypeScript, que refleja `bd/esquema.sql`.
- `server/utils/db.ts` y `server/utils/auth.ts`: la conexión y Better Auth
  con el adaptador de Drizzle.
- `server/api/`: las rutas de Better Auth, la disponibilidad, el estado de
  salud y el barrido diario de solicitudes vencidas.
- `server/middleware/sesion.ts`: la sesión de la petición.
- `web/pages/`: la portada y la disponibilidad.
- `vercel.json`: el planificador del barrido diario, con el secreto
  `CRON_SECRET`.

En la raíz se agregó un `package.json` con el espacio de trabajo de npm y
cuatro atajos del `Makefile`: `app-install`, `app-dev`, `app-build` y
`db-crear`.

## Archivos modificados

- `bd/esquema.sql` y `bd/diccionario-datos.md`: esquema y diccionario.
- `web/**`: la aplicación.
- `package.json` (nuevo): espacio de trabajo de npm.
- `tablero/`, `docs/` y `bd/`: renombres desde `sistema/` y `documentacion/`.
- `sistema/verificar-rutas.py`: rutas vigentes y obsoletas.
- `sistema/diagramas/uml/estructural/*.puml`: el modelo de acceso.
- `Makefile`, `AGENTS.md`, `README.md`, `informe/README.md`,
  `docs/INSTALACION-WINDOWS.md`, `sistema/estimacion/*` y
  `sistema/historias-usuario/historias-usuario.md`: rutas y documentación.
- `.gitignore`: dependencias, salidas de la aplicación y volcados de sesión.

## Validación

- `bd/esquema.sql` se ejecutó contra PostgreSQL 18 y creó el esquema
  completo sin errores: 18 tablas, 3 vistas, 10 funciones y 5 disparadores.
- Se probaron las reglas críticas contra la base real: la reserva de 8
  pasajeros sobre un cupo de 10 se acepta; una segunda reserva de 5 se
  rechaza por cupo insuficiente; la segunda solicitud del mismo cliente
  para la misma salida se rechaza por solicitud duplicada; la confirmación
  funciona dentro del plazo y falla fuera de él; una solicitud vencida no
  ocupa cupo en la vista; bajar la capacidad por debajo de lo reservado se
  rechaza; el cambio de fecha queda auditado; la cancelación pasa por la
  solicitud del cliente y la ejecución del personal; el pago registrado por
  el cliente no cuenta como abonado hasta que el personal lo valida.
- La aplicación se compiló y se levantó contra esa base: `/api/health`
  responde con la conexión correcta, `/api/disponibilidad` devuelve las
  salidas de la vista, el alta de una cuenta crea el usuario con sus campos
  del dominio, la sesión se recupera con la cookie y el ingreso queda
  registrado en `acceso`. El barrido diario responde con el número de
  solicitudes vencidas y rechaza las peticiones sin `CRON_SECRET`.
- `npx nuxt typecheck` terminó sin errores.
- `make verificar` terminó con cero problemas: 29 archivos revisados, 20
  rutas LaTeX y 29 entradas del árbol del README.
- `make diagramas` regeneró los diagramas sin errores de PlantUML.
- El PDF sigue en 21 páginas.

## Pendientes

- Instalar las dependencias de la aplicación: la partición del repositorio
  está en exFAT, que no admite enlaces simbólicos, y npm necesita esos
  enlaces para el espacio de trabajo. En desarrollo conviene trabajar en una
  partición con ext4 o instalar dentro de `web/`.
- Crear la primera cuenta de administrador y su rol.
- Formulario de ingreso y cierre de sesión en la interfaz.
- Páginas y rutas de la API de cada historia, con la semilla de datos de
  prueba.
- Elaborar los diagramas de secuencia de HU-15, HU-16 y HU-17, que no
  tienen representación propia en `sistema/diagramas/uml/secuencia/`.
- Decidir si los diagramas de secuencia se incorporan al cuerpo del informe
  o a los anexos.
