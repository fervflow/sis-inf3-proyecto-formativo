# Paquetes con lugares, servicios incluidos y mapa

- **Fecha:** 20 de noviembre de 2026, 11:56 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios; el trabajo no modifica el informe)
- **Alcance:** coherencia del modelo y de la ficha del paquete turístico
  (HU-01): catálogo de lugares, recorrido con origen y paradas, servicios
  incluidos separados del itinerario, código automático, mapa y rediseño del
  diálogo.

## Antecedente

La revisión de la web detectó siete problemas de coherencia en el alta y la
edición de paquetes:

1. el código se escribía a mano y no había un criterio para que dos personas
   lo escribieran igual;
2. el destino era un texto único, insuficiente para tours con origen,
   recorrido y regreso;
3. el texto del destino no tenía coordenadas ni apoyo visual;
4. la duración usaba el campo numérico nativo y no aprovechaba el rango de
   fechas;
5. el precio era un número genérico, sin formato de moneda;
6. las «actividades del itinerario» eran en realidad servicios incluidos y
   convivían con un texto libre que repetía la misma información;
7. el diálogo era angosto y obligaba a desplazarse aunque hubiera espacio.

El único paquete existente, `POT-001`, confirmaba el problema: tenía cuatro
servicios marcados y un `servicios_incluidos = 'abc'` que no aportaba nada.

## Decisiones aplicadas

1. **Código automático e inmutable.** Se genera con
   `fn_generar_codigo_paquete` como `PREFIJO-AAAA-NNN`, con el código del
   lugar de destino o, si el borrador no lo tiene, con las primeras letras
   del nombre. La secuencia es global y los códigos existentes se conservan.
2. **El destino es un lugar.** Se creó el catálogo `lugar` y el paquete
   guarda `id_lugar_destino` e `id_lugar_origen`. Las paradas viven en
   `paquete_parada`, ordenadas y sin repetición. `tipo_recorrido` distingue
   el viaje sencillo del circuito; el regreso al origen no se duplica como
   parada.
3. **Mapa con OpenStreetMap.** Leaflet muestra los lugares y permite elegir
   un punto. La búsqueda usa Photon, sin clave, y el lugar se guarda en el
   catálogo antes de asociarlo al paquete. Se sembraron nueve lugares de la
   operación para que el mapa y el autocompletado funcionen sin red.
4. **Duración como días inclusivos, con calculadora.** El paquete sigue
   guardando `duracion_dias`; el rango de fechas solo calcula el valor y
   muestra «días / noches». Se reemplazó el campo numérico nativo por
   `UInputNumber`.
5. **Precio con formato de moneda.** `BaseCampoMoneda` envuelve
   `UInputNumber` con bolivianos, dos decimales y locale de la aplicación.
6. **Servicios separados del itinerario.** El catálogo `actividad` pasó a
   `servicio` y el vínculo a `paquete_servicio`. Las casillas son la lista
   canónica de lo que cubre el precio; el itinerario es el relato día por
   día. `servicios_detalle` y `servicios_excluidos` son textos opcionales.
7. **Diálogo de 5xl con secciones.** Identidad, ubicación y recorrido,
   contenido, datos comerciales y publicación. El estado se cambió por
   acciones —guardar borrador, publicar, retirar, reactivar— y se agregó
   validación por campo, contadores y checklist de publicación.
8. **Compatibilidad de las migraciones.** La migración anterior se ajustó
   para que, cuando el modelo de lugares ya está aplicado, no vuelva a crear
   `destino` ni `actividad`. Así `make db-actualizar` sigue siendo
   idempotente.

## Cambios de formato

No hubo cambios de formato en el informe: no se modificó ningún archivo
LaTeX y el PDF conserva sus 21 páginas.

## Cambios de contenido

### Reglas de negocio

- Se agregaron `RN-LUG-01` a `RN-LUG-03` para el catálogo de lugares, las
  coordenadas y la restricción de borrado.
- `RN-PAQ-01` pasó al código generado e inmutable.
- `RN-PAQ-03` ahora exige una referencia a un lugar para publicar.
- Se agregaron `RN-PAQ-16` y `RN-PAQ-17` para el circuito y las paradas.
- `RN-PAQ-08` y `RN-PAQ-09` separan los servicios incluidos de sus detalles.
- Las reglas `RN-ACT-*` se reemplazaron por `RN-SER-*`.
- Se actualizaron la matriz de campos, los términos canónicos y la
  trazabilidad de HU-01.

### Esquema y migración

- `lugar` con código único, nombre normalizado, tipo, coordenadas opcionales
  y referencia de OpenStreetMap.
- `paquete` con `id_lugar_destino`, `id_lugar_origen`, `tipo_recorrido`,
  `servicios_detalle` y `servicios_excluidos`.
- `paquete_parada`, `servicio` y `paquete_servicio`.
- Disparador diferido `tr_paquete_publicado`: un paquete activo exige
  destino, descripción, itinerario y al menos un servicio.
- `fn_generar_codigo_paquete` con la secuencia global.
- Restricción de duración entre 1 y 365 días.
- La migración conservó `POT-001`, convirtió su destino en el lugar «Salar
  de Uyuni», mantuvo sus cuatro servicios y movió `'abc'` a
  `servicios_detalle`.
- Se sembraron Potosí, Cerro Rico, Uyuni, Salar de Uyuni, Isla Incahuasi,
  Laguna Colorada, Tupiza, Sucre y La Paz, con coordenadas.

### Web

- `FormularioPaquete` como componente del módulo, con secciones, dos
  columnas y pie fijo.
- `BaseCampoMoneda` y `BaseMapa` como componentes base.
- `SelectorLugar` con catálogo local, Photon y alta desde el mapa.
- `BaseTablaDatos` muestra el recorrido resumido en lugar del destino de
  texto.
- El formulario ya no permite elegir transiciones inválidas de estado: las
  acciones dependen del estado actual.
- La API de paquetes devuelve lugares, paradas y servicios; se agregaron las
  rutas de lugares, servicios y geocodificación.
- La ruta `actividades` se retiró y se reemplazó por `servicios`.
- Se corrigió el SSR autenticado con `useRequestFetch` en paquetes, salidas y
  usuarios.
- Nuxt UI usa el mismo idioma que la aplicación; el calendario y los
  controles aparecen en español.

### Diagramas y documentación

- Se actualizaron el diagrama de clases, el simplificado, el de objetos y
  los dos diagramas de secuencia de HU-01.
- Se actualizaron `bd/diccionario-datos.md`, la documentación de la web y
  los criterios de aceptación y tareas de HU-01.

### Tablero y backlog

- Se agregó la tarjeta `T-HU-01.3` en `Hecho`.
- `make tablero-backlog` actualizó HU-01 a 3 tareas y el total a 40 tareas,
  con 21 para el programador A.

## Archivos modificados

- **Base de datos:** `bd/esquema.sql`,
  `bd/actualizaciones/2026-11-20-lugares-servicios.sql` (nuevo),
  `bd/actualizaciones/2026-11-20-reglas-paquetes.sql`,
  `bd/diccionario-datos.md` y `bd/pruebas/reglas-paquetes.sql`.
- **Reglas y seguimiento:** `sistema/reglas-negocio.md`,
  `sistema/historias-usuario/historias-usuario.md`,
  `sistema/diagramas/uml/estructural/*`,
  `sistema/diagramas/uml/secuencia/hu-01-gestionar-paquetes.puml` y
  `sistema/diagramas/uml/secuencia-light/hu-01-gestionar-paquetes.puml`.
- **Esquema y tipos:** `web/db/schema.ts`, `web/shared/types/api.ts` y
  `web/shared/types/domain.ts`.
- **Servidor:** `web/server/utils/paquetes.ts`,
  `web/server/utils/lugares.ts` (nuevo), las rutas de paquetes, las rutas
  nuevas de lugares, servicios y geocodificación, y la baja de
  `web/server/api/admin/actividades.get.ts`.
- **Interfaz:** `web/app/pages/admin/paquetes.vue`,
  `web/app/components/paquetes/FormularioPaquete.vue` (nuevo),
  `web/app/components/paquetes/SelectorLugar.vue` (nuevo),
  `web/app/components/base/BaseCampoMoneda.vue` (nuevo),
  `web/app/components/base/BaseMapa.vue` (nuevo), `web/app/app.vue`,
  `web/app/composables/useMensajeError.ts` y los dos archivos de textos.
- **Configuración y documentación:** `web/nuxt.config.ts`,
  `web/package.json`, `package-lock.json`, `web/README.md`,
  `web/CONFIGURACION.md` y `web/docs/`.
- **Tablero:** `tablero/tablero.md`.
- **Registro:** este archivo y la tabla de `docs/changelog/README.md`.

## Validación realizada

- `npm run typecheck --workspace web`: sin errores.
- `npm run build --workspace web`: compila y genera el cliente y el servidor.
- `make db-actualizar`: se ejecuta completo e idempotente sobre la base.
- `make db-probar`: pasan los casos de publicación incompleta, código en
  minúsculas, precio cero, circuito sin origen, parada repetida, salidas
  duplicadas, duración incoherente, paquete inactivo, cancelación sin motivo
  y salida realizada no modificable.
- `make verificar`: 33 archivos y 20 rutas LaTeX revisadas, sin problemas.
- `make` y `make ver`: el PDF conserva 21 páginas y las fuentes embebidas.
- Prueba de extremo a extremo en Chromium: ingreso, apertura del formulario,
  carga del mapa con tiles de OpenStreetMap, búsqueda de «Uyuni» con
  resultados locales y de Photon, selección del lugar, guardado como
  borrador y generación del código. El paquete de prueba y la cuenta
  temporal se borraron después.
- Estado final de la base: `POT-001` se conserva activo, 9 lugares y 11
  servicios. La secuencia de códigos se reinició para que el siguiente
  código nuevo sea `PREFIJO-2026-001`.

## Pendientes o decisiones

- `salida.punto_encuentro` sigue siendo texto. La migración a `lugar` quedó
  para una etapa posterior, porque toca las funciones PL/pgSQL y la
  auditoría de salidas.
- El itinerario estructurado por día (`paquete_dia` y actividades por día)
  queda para otra historia; en esta iteración el itinerario es el texto
  narrativo.
- Los tiles públicos de OpenStreetMap y Photon alcanzan para el MVP. Si el
  tráfico crece, conviene pasar a un proveedor con capa gratuita y proxy
  por Nitro.
- El informe no se modifica en esta iteración: el alcance sigue diciendo
  «registro de destinos», que es correcto a nivel de propuesta. El detalle
  del modelo vive en `sistema/`, `bd/` y la documentación de la web.
