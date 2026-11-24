# Cierre del backlog: finalización de reservas, retención web revalidada, barrido manual y reservas desde cotización

## Fecha y alcance

24 de noviembre de 2026. Implementación de las cuatro tareas que quedaban
en «Por hacer» del tablero — T-HU-06.4, T-HU-17.4, T-HU-07.4 y T-HU-05.3 —
y verificación completa del backlog contra las 17 historias de usuario y
el catálogo de reglas de negocio. Con esto el tablero queda 44 de 44
tareas en «Hecho». Alcanza al esquema y a las funciones de la base, las
pruebas SQL, la API y la interfaz de la web, el catálogo de reglas, el
tablero y el README de la web.

## Documento generado

El informe no cambió en este trabajo; no se regeneró el PDF.

## Decisiones adoptadas

- **Retención web revalidada al modificar (RN-RES-16, T-HU-06.4):**
  `fn_revalidar_reserva` comprueba, junto con el tope de 4 pasajeros,
  que las solicitudes web pendientes vigentes de la salida no retengan
  más de la mitad del cupo, sin contar la reserva propia. Lo heredan la
  modificación de salida y el guardado del manifiesto, que son sus
  dos llamadas.
- **Finalización con la salida (T-HU-07.4):** cuando la salida pasa a
  `realizada`, sus reservas confirmadas pasan a `finalizada` con su
  auditoría; las pendientes no cambian, porque vencen por su propio
  plazo. La máquina de estados del catálogo incorpora la transición
  `confirmada → finalizada`.
- **Barrido manual con auditoría (T-HU-17.4):**
  `fn_vencer_solicitudes_pendientes` admite la cuenta que lo ejecuta;
  el cron diario sigue llamándola sin argumentos. La baja del antiguo
  overload de cero argumentos evita la llamada ambigua.
- **Reserva desde cotización aceptada (RN-COT-08, T-HU-05.3):** la
  bandeja de cotizaciones lista la reserva originada
  (`idReservaOriginada`) y ofrece «Originar reserva» solo a las
  aceptadas sin reserva; el vínculo único de `reserva.id_cotizacion`
  impide repetirla. El monto nace congelado con el precio vigente de la
  salida (RN-RES-06), no con el total de la cotización.
- **Reporte con finalizadas (RN-REP-02):** `vista_reservas_por_fecha`
  añade `reservas_finalizadas` al final de la columna, porque
  `CREATE OR REPLACE VIEW` solo admite columnas nuevas al final.

## Cambios de contenido

### Base de datos

- `fn_revalidar_reserva`: retención web del canal revalidada
  (T-HU-06.4).
- `fn_actualizar_salida`: finaliza las reservas confirmadas al pasar la
  salida a `realizada` (T-HU-07.4).
- `fn_vencer_solicitudes_pendientes`: parámetro opcional con la cuenta
  que ejecuta el barrido y observación diferenciada en la auditoría
  (T-HU-17.4).
- `vista_reservas_por_fecha`: columna nueva `reservas_finalizadas`.
- Actualización `2026-11-24-finalizacion-retencion-web.sql`, aplicada
  sobre la base viva.
- Pruebas nuevas en `bd/pruebas/reglas-reservas.sql` (14 y 15): la
  retención web se revalida al modificar y la salida realizada finaliza
  sus reservas confirmadas.

### Web

- API: `POST /api/reservas/vencer` (barrido manual del personal);
  `GET /api/cotizaciones` reporta la reserva originada;
  `GET /api/reportes` incluye `reservasFinalizadas`; docstring del cron
  `/api/vencer-solicitudes` corregida (24 horas y vía manual).
- Interfaz: botón «Vencer vencidas» en la bandeja de solicitudes con
  aviso del resultado; «Originar reserva» y distintivo «Reserva
  originada» en la tarjeta de cotización; columna «Finalizadas» en el
  reporte. Textos nuevos en español e inglés.

### Documentación y tablero

- `sistema/reglas-negocio.md`: máquina de estados de la reserva con
  `finalizada`; RN-RES-09, RN-RES-16 y RN-SAL-15 actualizadas a la
  implementación; los cuatro pendientes que se resolvieron salieron de
  la sección 15.
- `web/README.md`: páginas y rutas del resto de historias marcadas
  hechas y total corregido a 44 tareas.
- `tablero/tablero.md`: T-HU-06.4, T-HU-17.4, T-HU-07.4 y T-HU-05.3
  pasan a «Hecho»; 44 de 44 tareas.
- Archivo nuevo `sistema/historias-usuario/historias-scrum.md`: tabla
  consolidada de las 17 historias con título, descripción y criterios
  de aceptación, en el orden del backlog.

## Validación realizada

- `db-probar` completo: paquetes, pagos y las quince pruebas de
  reservas, incluidas las dos nuevas; sin errores y con `ROLLBACK`
  final.
- Aplicación de la actualización SQL sobre la base viva; se corrigió en
  el camino la ambigüedad del barrido (overload de cero argumentos) y
  la posición de la columna nueva de la vista.
- `npm run typecheck --workspace web`, `npm run build --workspace web`
  y `npm run db:check --workspace web` sin errores.
- `py tablero/validar.py`: 44 tarjetas, «Por hacer» vacío;
  `py tablero/exportar.py` sin diferencias en el backlog.

## Archivos modificados

Base: `bd/esquema.sql`,
`bd/actualizaciones/2026-11-24-finalizacion-retencion-web.sql`,
`bd/pruebas/reglas-reservas.sql`.
Web: `web/shared/types/api.ts`, `web/server/utils/cotizaciones.ts`,
`web/server/api/reservas/vencer.post.ts`,
`web/server/api/reportes.get.ts`,
`web/server/api/vencer-solicitudes.post.ts`,
`web/app/pages/{solicitudes,cotizaciones,reportes}.vue`,
`web/app/components/cotizaciones/Tarjeta.vue`,
`web/app/i18n/locales/{es,en}.ts`.
Documentación: `sistema/reglas-negocio.md`,
`sistema/historias-usuario/historias-scrum.md` (nuevo),
`web/README.md`, `tablero/tablero.md`, `.gitignore`.

## Pendientes o decisiones para el siguiente trabajo

- Registro del PDF si el informe incorpora el cierre del backlog; el
  documento no cambió en esta iteración.
- Reutilizar un pasajero entre fichas de clientes distintos; hoy el
  manifiesto se arma dentro de la ficha del cliente de la reserva.
- Aviso al cliente cuando el personal mueve su reserva de salida; hoy
  lo ve en «Mis reservas» por el cambio de salida y fecha.
- Ejecución y registro de las devoluciones (RN-PAG-07) y pasarela real.
- Diagrama de secuencia de HU-17, sin representación propia en
  `sistema/diagramas/uml/secuencia/`.
