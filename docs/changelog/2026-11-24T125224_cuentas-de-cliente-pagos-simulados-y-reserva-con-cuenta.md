# Cuentas de cliente, pagos simulados y flujo de reserva con cuenta

## Fecha y alcance

24 de noviembre de 2026. Rediseño del manejo de usuarios del canal web y
del proceso de reserva: registro público de cuentas de cliente con ficha,
fin de la solicitud anónima, pagos con pasarela simulada y anticipo como
condición de confirmación. Alcanza al catálogo de reglas, las historias de
usuario, el esquema y las funciones de la base, la API y la interfaz de la
web, los diagramas y el informe.

## Documento generado

`entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes
Turísticos y Reservas.pdf`, 21 páginas.

## Decisiones adoptadas

- Modelo A de cupos: la solicitud `pendiente` retiene el cupo desde su
  creación; el pago no toca los cupos y condiciona la confirmación.
- Anticipo mínimo del 30% del total; pagar la totalidad se registra como
  un anticipo por el monto completo; el saldo paga el resto exacto y
  también puede pagarse por la web.
- El vencimiento de una solicitud pendiente baja de 48 a 24 horas.
- Devoluciones por cancelación del cliente: 100% a 15 días o más de la
  salida, 50% entre 8 y 14 días, nada con 7 días o menos o por
  inasistencia; 100% si la cancela la agencia o la solicitud vence sin
  confirmarse por falta de atención. La ejecución queda fuera del sistema.
- Registro público abierto: cuenta de Better Auth y ficha del cliente se
  crean juntas, con correo y documento obligatorios y únicos; si el
  documento ya tiene ficha, la cuenta se vincula a ella.
- El panel de usuarios deja de crear cuentas de `CLIENTE`: solo `ADMIN` y
  `PERSONAL`.
- El pago web queda `registrado` y el personal lo valida antes de
  confirmar la reserva (RN-RES-18, exigida por `fn_confirmar_reserva`).

## Cambios de contenido

### Catálogo de reglas (`sistema/reglas-negocio.md`)

- Términos nuevos: anticipo, saldo y pasarela simulada.
- RN-USU-02 a Vigente y ampliada; nuevas RN-USU-03, RN-USU-04 y RN-USU-05.
- RN-RES-05 a 24 horas; RN-RES-10, RN-RES-11 reescritas; nuevas
  RN-RES-17 y RN-RES-18; RN-RES-13 con el estado del anticipo.
- Sección nueva «14. Pagos» con RN-PAG-01 a RN-PAG-08 y la máquina de
  estados del pago; secciones renumeradas.
- Alcance del catálogo ampliado a cuentas de cliente y pagos.

### Historias de usuario (`sistema/historias-usuario/historias-usuario.md`)

- Criterios de HU-15 reescritos (registro propio, vinculación de ficha),
  HU-06 (canal web con cuenta), HU-14 (mínimo, simulación, saldo exacto),
  HU-17 (confirmación con anticipo), HU-13 (tramos de devolución) y
  HU-04 (correo obligatorio). Observación 19 nueva.

### Base de datos

- `bd/esquema.sql`: `cliente.correo NOT NULL` con índice único
  `ux_cliente_correo`; `pago.metodo` admite `banca_movil` y `qr`;
  vencimiento por omisión a 24 horas; `fn_registrar_pago` reescrita con
  mínimo del anticipo, saldo previo y exacto, tope del pendiente, reserva
  pagable y alta validada del personal; `fn_confirmar_reserva` exige el
  anticipo validado. Semilla depurada: los clientes y proveedores de
  ejemplo pasan al archivo de datos de prueba.
- `bd/actualizaciones/2026-11-24-reservas-pagos-cuentas.sql` nuevo, con
  guardia de correos faltantes.
- `bd/permisos.sql` nuevo: permisos del rol de la aplicación sobre el
  esquema; se ejecuta desde `make db-crear` y `make db-actualizar`.
- `bd/datos-prueba.sql` nuevo: proveedores, clientes con cuentas de prueba
  (contraseña «prueba1234»), paquetes de la región (Salar de Uyuni,
  Potosí histórico, circuito de lagunas), salidas, reservas y pagos de
  demostración y una cotización.
- `bd/pruebas/reglas-reservas.sql` actualizado (24 horas, firma de
  solicitudes web con cuenta de prueba, anticipo antes de confirmar) y
  `bd/pruebas/reglas-pagos.sql` nuevo, con diez comprobaciones de las
  reglas de pagos y de la confirmación condicionada.

### Web

- Registro público: `web/server/api/registro.post.ts` crea cuenta y ficha
  en un paso, con rol `CLIENTE`, correo real, dominio interno reservado y
  sesión abierta por cookie. La página `/crear-cuenta` es nueva y
  `/ingresar` acepta usuario o correo y soporta el retorno con `volver`.
- `/api/reservas`: canal web solo con sesión de cliente y ficha vinculada
  (sin ficha anónima); anónimo responde 401. `GET /api/reservas` devuelve
  las propias del cliente. Cada reserva reporta el estado de su anticipo
  y su saldo pendiente.
- Pagos nuevos: `/api/pagos` (registrar, con referencia simulada
  `MOCK-*`), `/api/pagos?reserva=` (listar con resumen del saldo) y
  `/api/pagos/[id]/validar` (validar o anular, solo personal).
- Interfaz nueva: paso de pago simulado tras la solicitud
  (`pagos/FormularioPago.vue`), página `/mis-reservas` con pago y consulta
  de pagos, columna de anticipo, pagos de oficina y acciones de validar o
  anular en `/solicitudes`, cuenta vinculada y correo obligatorio en
  `/clientes`, y enlace «Mis reservas» en la navegación del cliente.
- Middleware: redirección de visitantes anónimos a `/ingresar` con
  retorno; `/crear-cuenta` pública; `/mis-reservas` solo para clientes.
- Panel de usuarios sin el rol `CLIENTE`.

### Diagramas e informe

- Diagrama de secuencia HU-15 nuevo (registro y vinculación de ficha);
  HU-06 con los canales nuevos, firma y 24 horas; HU-14 con la pasarela
  simulada y la validación; versiones ligeras actualizadas; mapa de
  procesos con la apertura de cuenta; casos de uso con las
  precondiciones nuevas; notas de los objetos simplificados a 24 horas.
- `informe/capitulos/10-alcances-sistema.tex`: módulo de pagos con el
  mínimo del anticipo y los tramos de devolución, acceso del cliente con
  registro propio, y confirmación condicionada al anticipo con plazo de
  24 horas.

## Archivos modificados

Documentación: `AGENTS.md`, `sistema/reglas-negocio.md`,
`sistema/historias-usuario/historias-usuario.md`, `sistema/diagramas/README.md`,
`web/docs/autenticacion.md`, `web/docs/seguridad.md`, `web/CONFIGURACION.md`,
`bd/diccionario-datos.md`.
Base de datos: `bd/esquema.sql`, `bd/actualizaciones/2026-11-24-reservas-pagos-cuentas.sql`,
`bd/permisos.sql`, `bd/datos-prueba.sql`, `bd/pruebas/reglas-reservas.sql`,
`bd/pruebas/reglas-pagos.sql`.
Web: `web/db/schema.ts`, `web/shared/pagos.ts`, `web/shared/types/domain.ts`,
`web/shared/types/api.ts`, `web/server/utils/{clientes,reservas,pagos}.ts`,
`web/server/api/registro.post.ts`, `web/server/api/reservas.post.ts`,
`web/server/api/reservas.get.ts`, `web/server/api/reservas/[id]/confirmar.post.ts`,
`web/server/api/pagos.post.ts`, `web/server/api/pagos.get.ts`,
`web/server/api/pagos/[id]/validar.post.ts`,
`web/server/api/admin/usuarios.post.ts`,
`web/server/api/clientes{.get,.post}.ts`,
`web/server/api/clientes/[id].patch.ts`, `web/server/middleware/sesion.ts`,
`web/app/pages/{crear-cuenta,ingresar,disponibilidad,mis-reservas,solicitudes,clientes}.vue`,
`web/app/pages/admin/usuarios.vue`, `web/app/components/BarraNavegacion.vue`,
`web/app/components/solicitudes/FormularioCliente.vue`,
`web/app/components/pagos/{FormularioPago,ResumenPagos}.vue`,
`web/app/composables/useMensajeError.ts`,
`web/app/i18n/locales/{es,en}.ts`.
Diagramas: `uml/secuencia/hu-06-registrar-reserva.puml`,
`uml/secuencia/hu-14-registrar-pago.puml`,
`uml/secuencia/hu-15-abrir-cuenta.puml`, versiones ligeras de HU-06 y
HU-14, `uml/casos-uso/casos-uso.puml`, `uml/procesos/mapa-procesos.puml`,
objetos simplificado y completo.
Informe: `informe/capitulos/10-alcances-sistema.tex`.

## Validación realizada

- `make db-probar`: las pruebas de paquetes, salidas, reservas y pagos
  pasan completas (24 horas, anticipo mínimo, saldo exacto, reserva
  pagable, confirmación condicionada).
- `npm run typecheck --workspace web` y `npm run build --workspace web`
  sin errores.
- Prueba en vivo con el servidor compilado: registro de cliente con
  sesión automática, solicitud web con vencimiento a 24 horas, pago
  simulado con referencia generada y mínimo del 30% aplicado, bandeja del
  personal con estado del anticipo, rechazo de la confirmación sin
  anticipo validado, validación del pago y confirmación posterior, pago
  del saldo exacto por la web, permisos por rol en páginas y API.
- `make verificar` sin problemas (34 diagramas) y `make` compila y
  publica el PDF de 21 páginas.
- La base se reconstruyó desde cero con el nuevo esquema; se conservaron
  las cuentas de administrador `erick.vel` y `roberto.c` con sus
  contraseñas y se cargaron los datos de demostración de la región.

## Pendientes o decisiones para el siguiente trabajo

- Movimientos del tablero: las tarjetas T-HU-06.1/2/3 y T-HU-17.1/2/3
  pasan de «En pruebas / QA» a «Hecho» (la verificación en vivo de esta
  iteración cubrió su criterio) y las tarjetas T-HU-15.1/2/3 y
  T-HU-14.1/2 pasan de «Por hacer» a «Hecho» (se implementaron y
  comprobaron en esta iteración). Tras moverlas, el backlog se sincroniza
  con `make tablero-backlog`; no hubo tarjetas nuevas, porque el trabajo
  correspondió a tareas ya existentes de HU-14 y HU-15.
- Registro de la devolución como dato del sistema (estado del pago) si se
  decide dejar de gestionarla fuera.
- Verificación de correo y avisos por correo (HU-16) cuando entre el
  proveedor de envíos.
- Revisar la estimación de HU-15 y HU-14 en el tablero para reflejar el
  alcance nuevo del registro y los pagos simulados.
