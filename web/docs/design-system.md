# Sistema de diseño

## La idea

Nuxt UI es la **implementación**, no la identidad. Los componentes de la
biblioteca se usan, pero todos leen sus colores, radios y tipografías de
los tokens del proyecto. Cambiar la identidad visual es cambiar un
archivo: `app/design/tokens.css`.

```text
app/design/tokens.css   ← la identidad (fuente única)
        │
        ├── --vt-*        tokens propios, con nombre del dominio
        │
        └── --ui-color-*  mapeo a las variables que lee Nuxt UI
                 │
                 └── los componentes de Nuxt UI y los propios
```

## Capas de tokens

### 1. Tokens del proyecto (`--vt-*`)

Con nombre del dominio, no del color. Hoy hay tres familias:

| Familia | Para qué |
|---|---|
| `--vt-color-marca-*` | El color de la agencia (verde azulado) |
| `--vt-color-neutro-*` | Grises cálidos, el papel y el texto |
| `--vt-color-exito/advertencia/error/info-*` | Estados |

Y además: `--vt-color-fondo`, `--vt-color-superficie`,
`--vt-color-superficie-alterna`, `--vt-color-texto`,
`--vt-color-texto-suave`, `--vt-color-borde`; la escala de espaciado
(`--vt-espaciado-*`), los radios (`--vt-radio-*`), las sombras
(`--vt-sombra-*`), la tipografía (`--vt-fuente-*`, `--vt-texto-*`) y las
transiciones (`--vt-transicion`).

### 2. Mapeo a Nuxt UI (`--ui-color-*`)

Nuxt UI lee variables `--ui-color-primary-50…950` y `--ui-color-neutral-*`.
El mapeo vive al final de `tokens.css`:

```css
--ui-color-primary-50: var(--vt-color-marca-50);
--ui-color-primary-100: var(--vt-color-marca-100);
/* … */
```

## Reglas

1. **Ningún componente escribe un color.** Ni en la plantilla, ni en el
   `<style>`. Se usa un token, una variable de Nuxt UI o un componente
   base.
2. **El espaciado sale de la escala.** `--vt-espaciado-2`, `-4`, `-6`,
   `-8`. No hay `padding: 13px`.
3. **Un componente propio cubre un patrón, no un caso.** Si aparece dos
   veces, se extrae.
4. **La jerarquía la hace el borde y el espacio**, no la sombra. Las sombras
   son discretas y solo en superficies elevadas.
5. **Accesibilidad:** contraste suficiente, foco visible (ya está en los
   estilos globales), y todo elemento interactivo se puede usar con el
   teclado.

## Componentes base

Viven en `app/components/base/` y se usan con el prefijo `Base`:

| Componente | Para qué |
|---|---|
| `BaseEncabezadoPagina` | Título, descripción y acciones de una vista |
| `BaseTarjeta` | Contenedor con título, cuerpo y pie |
| `BaseTablaDatos` | Tabla con columnas declarativas, carga y estado vacío |
| `BaseEstadoVacio` | Mensaje cuando una lista no tiene nada |
| `BaseDato` | Un indicador con su etiqueta (los datos de la página de estado) |

Uso:

```vue
<BaseEncabezadoPagina :titulo="t('reservas.titulo')" :descripcion="t('reservas.descripcion')">
  <template #acciones>
    <UButton color="primary" :label="t('comun.guardar')" />
  </template>
</BaseEncabezadoPagina>

<BaseTablaDatos :columnas="columnas" :filas="reservas" :cargando="pendiente">
  <template #celda="{ columna, fila, valor }">
    <UBadge v-if="columna.clave === 'estado'" :label="valor" color="neutral" />
  </template>
</BaseTablaDatos>
```

## Nuxt UI: cuándo usarlo directo

Nuxt UI se usa directamente cuando no hay un patrón propio: un `UButton`,
un `UInput`, un `UBadge`, un `USelect`, un `UModal`, un `UTable` cuando
sirva su modo de tabla, un `USkeleton` para la carga.

Cuando un componente de Nuxt UI se usa mucho o necesita un comportamiento
propio, se **envuelve** en un componente base, no se modifica.

## Reestilizar

1. Editar los valores de `--vt-color-marca-*` y `--vt-color-neutro-*` en
   `tokens.css`.
2. Si el cambio es de forma y no de color, tocar `--vt-radio-*` y
   `--vt-sombra-*`.
3. Si un componente de Nuxt UI tiene una variante que no encaja, se ajusta
   el tema de `app/design/tema.ts` (que se aplica en `app/app.config.ts`).
4. No se tocan las plantillas de los componentes para cambiarles el color:
   eso rompe el sistema y anula el punto del tokens.

## Accesibilidad

- Los textos de error y de estado no dependen solo del color: llevan texto.
- Los estados de carga usan `USkeleton`, no un spinner sin contexto.
- Las tablas llevan `scope="col"` en las cabeceras.
- Los iconos que portan significado llevan texto o `aria-label`.
