# Sistema de diseño

## La idea

Nuxt UI es la **implementación**, no la identidad. Todos sus componentes
leen colores, radios y tipografías de los tokens del proyecto. Cambiar la
identidad visual es cambiar un archivo: `app/design/tokens.css`.

```text
app/design/tokens.css   ← la identidad (fuente única)
        ├── --vt-*        tokens propios, con nombre del dominio
        └── --ui-color-*  mapeo a las variables de Nuxt UI
```

## Capas de tokens

### 1. Tokens del proyecto (`--vt-*`)

| Familia | Para qué |
|---|---|
| `--vt-color-marca-*` | El color de la agencia (verde azulado) |
| `--vt-color-neutro-*` | Grises cálidos, papel y texto |
| `--vt-color-exito/advertencia/error/info-*` | Estados |

Además: fondos y superficies (`--vt-color-fondo`, `--vt-color-superficie`,
`--vt-color-texto`, `--vt-color-borde`), espaciado (`--vt-espaciado-*`),
radios (`--vt-radio-*`), sombras (`--vt-sombra-*`), tipografía
(`--vt-fuente-*`, `--vt-texto-*`) y transiciones (`--vt-transicion`).

### 2. Mapeo a Nuxt UI (`--ui-color-*`)

Nuxt UI lee `--ui-color-primary-50…950`, `--ui-color-neutral-*` y los
semánticos de estado `--ui-color-success-*`, `--ui-color-warning-*`,
`--ui-color-error-*` e `--ui-color-info-*`. El mapeo está al final de
`tokens.css`:

```css
--ui-color-primary-50: var(--vt-color-marca-50);
--ui-color-primary-100: var(--vt-color-marca-100);
/* … */
--ui-color-success-500: var(--vt-color-exito-500);
--ui-color-error-500: var(--vt-color-error-500);
/* … */
```

**El mapeo semántico es obligatorio.** Sin él, Nuxt UI genera una
referencia circular (`--ui-color-error-500 → --color-error-500 →
--ui-color-error-500`) y los componentes con esos colores salen sin
fondo ni color de texto: botones invisibles, avisos como texto suelto y
badges sin chip. Por eso los semánticos tienen escala completa 50 a 950,
como la marca: cada variante de Nuxt UI (solid, soft, subtle) usa tonos
distintos.

## Reglas

1. **Ningún componente escribe un color.** Ni en la plantilla ni en
   `<style>`: se usa un token o un componente base.
2. **El espaciado sale de la escala:** `--vt-espaciado-2`, `-4`, `-6`, `-8`.
3. **Un componente propio cubre un patrón, no un caso.**
4. **La jerarquía la hace el borde y el espacio**, no la sombra.
5. **Accesibilidad:** contraste suficiente, foco visible y uso con teclado.

## Componentes base

Viven en `app/components/base/` y se usan con prefijo `Base`:
`BaseEncabezadoPagina`, `BaseTarjeta`, `BaseTablaDatos`, `BaseEstadoVacio`
y `BaseDato`. La tabla de uso y los ejemplos están en `docs/componentes.md`.

## Nuxt UI directo

Se usa directamente cuando no hay un patrón propio: `UButton`, `UInput`,
`UBadge`, `USelect`, `UModal`, `UTable` o `USkeleton`. Cuando un componente
de Nuxt UI se repite o necesita comportamiento propio, se **envuelve** en un
componente base; no se modifica.

## Reestilizar

1. Editar `--vt-color-marca-*` y `--vt-color-neutro-*` en `tokens.css`.
2. Para cambios de forma, tocar `--vt-radio-*` y `--vt-sombra-*`.
3. Si una variante de Nuxt UI no encaja, ajustar el tema en
   `app/design/tema.ts` (se aplica en `app/app.config.ts`).
4. No cambiar colores desde las plantillas: rompe el sistema.

## Tema claro y oscuro

El interruptor de la barra de navegación fija la preferencia (claro, oscuro
o la del sistema) y Nuxt UI la aplica como clase `.dark` en `<html>`. Los
tokens de superficie y texto se invierten en el bloque `.dark` de
`tokens.css`; el resto de la paleta es única para ambos temas. No usar
`prefers-color-scheme` en CSS: haría que el interruptor no manda.

## Accesibilidad

- Los estados no dependen solo del color: llevan texto.
- La carga usa `USkeleton`, no un spinner sin contexto.
- Las tablas llevan `scope="col"`.
- Los iconos con significado llevan texto o `aria-label`.
