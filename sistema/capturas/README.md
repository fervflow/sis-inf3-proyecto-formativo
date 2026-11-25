# Capturas de la web del sistema

Capturas de pantalla de la aplicación web tomadas en desarrollo local.
Sirven de materia prima para los documentos del proyecto (informe,
anexos, presentación); todavía no se usan en el informe compilado.

## Procedencia

- Aplicación: `web/` en desarrollo (`make web-dev`), 25 de noviembre de
  2026, con la base de Neon y los datos de `bd/datos-prueba.sql`.
- Ventana de 1440×900, Chromium sin interfaz dirigido con Playwright
  (MCP). Las capturas son de pantalla completa salvo los modales.
- Sesiones con las cuentas de prueba de `bd/datos-prueba.sql`
  (contraseña «prueba1234»): cliente `maria.rojas@gmail.com`, personal
  `asesor` y un administrador temporal creado y borrado para la ocasión.
- La reserva `R00000520` nació en estas capturas: solicitud web, pago
  simulado del anticipo, manifiesto y confirmación del personal.
- Los campos de fecha muestran el formato del navegador sin interfaz
  (mm/dd/yyyy); si el documento los necesita en dd/mm/aaaa, retomar las
  páginas con el locale en español.

## Grupos

| Carpeta | Propósito | Contenido |
|---|---|---|
| `01-publico/` | Lo que ve quien no ha ingresado | Inicio, ingreso, creación de cuenta y disponibilidad pública. |
| `02-flujo-reserva-web/` | Solicitud y reserva por el canal web, de punta a punta | Disponibilidad del cliente, formulario de solicitud, pasarela del anticipo, aviso de pago, «Mis reservas» pendiente, manifiesto de pasajeros y «Mis reservas» confirmada. |
| `03-personal/` | Atención del personal de agencia | Bandeja de solicitudes, pagos y validación, confirmación, alta de reserva por oficina, clientes, cotizaciones, reportes, disponibilidad y ficha de la salida. |
| `04-administracion/` | Gestión del administrador | Paquetes, salidas, proveedores y usuarios. |

Dentro de cada carpeta el número indica el orden del recorrido; el
flujo de reserva es el orden del proceso, no de las páginas.
