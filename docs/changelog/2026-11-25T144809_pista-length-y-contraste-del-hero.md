# Pista `length` en los tokens de tamaño de texto y contraste del hero

## Fecha y alcance

25 de noviembre de 2026. Corrección del contraste del texto de la
portada de la web en modo claro y, por raíz común, de la interpretación
de todos los tokens de tamaño de texto (`--vt-texto-*`) de la
aplicación. No cambió el informe, el esquema ni los textos.

## Documento generado

El informe no cambió en este trabajo; no se regeneró el PDF.

## Diagnóstico

El título «Your next adventures leave from Potosí» y su párrafo se veían
negros sobre el panel oscuro del hero en modo claro (y legibles en modo
oscuro, donde el color heredado es claro). La causa no era un color mal
elegido: la abreviatura de Tailwind `text-(--var)` es ambigua entre
color y tamaño, y Tailwind la resuelve como **color**. En el CSS
compilado, `text-(--vt-texto-3xl)` llegaba como
`color: var(--vt-texto-3xl)`: un valor inválido para color que, al
hacerse efectivo en la cascada (ganaba por orden de fuente a
`text-white`), hacía que el texto heredara el color del cuerpo de la
página. En modo claro, ese color es oscuro.

El mismo diagnóstico destapó un defecto latente en toda la aplicación:
con el patrón habitual `text-(--vt-texto-sm)
text-(--vt-color-texto-suave)`, la declaración inválida del token de
tamaño ganaba la cascada y el texto heredaba el color del cuerpo en
lugar del gris suave previsto.

## Decisión adoptada

Los tokens de tamaño de texto llevan ahora la **pista de tipo
`length:`** de Tailwind: `text-(length:--vt-texto-3xl)` compila a
`font-size: var(--vt-texto-3xl)`. Fue un reemplazo mecánico y completo
(136 apariciones en 28 archivos `.vue`); los tokens de color
(`text-(--vt-color-*)`) no la necesitan y quedaron como estaban. La
regla quedó documentada para que no reaparezca.

Consecuencia visible esperada: los encabezados de la aplicación
realmente toman ahora sus tamaños de token (antes los tamaños nunca se
aplicaban), y los textos suaves recuperan su gris previsto.

## Cambios de contenido

### Web

- 28 archivos `.vue` de `web/app/`: `text-(--vt-texto-…)` sustituido
  por `text-(length:--vt-texto-…)`, incluida la portada nueva.
- `web/docs/design-system.md`: regla 6 nueva sobre la pista `length`
  para los tokens de tamaño de texto.

### Repositorio

- `.gitignore`: el material PDF local de `sistema/` ya no se versiona.

### Documentación

- `docs/changelog/`: este registro.

## Validación realizada

- `npm run typecheck --workspace web` sin errores.
- `npm run build --workspace web` compila sin errores; en el CSS de
  salida se comprobó que existen reglas `font-size: var(--vt-texto-3xl)`
  y `font-size: var(--vt-texto-4xl)` y que el título del hero conserva
  `text-white` en blanco.

## Archivos modificados

Web: 28 componentes y vistas de `web/app/`, `web/docs/design-system.md`.
Repositorio: `.gitignore`. Documentación: `docs/changelog/`.

## Pendientes o decisiones para el siguiente trabajo

- Revisar visualmente las pantallas de gestión con los tamaños de
  token ya activos: si algún encabezado quedó demasiado grande, se
  ajusta el token en `tokens.css`, no la pantalla.
- Las capturas de `sistema/capturas/` reflejan los tamaños previos a la
  corrección; retomarlas si el documento final las publica.
