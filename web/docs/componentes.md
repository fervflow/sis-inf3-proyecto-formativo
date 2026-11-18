# Componentes

## Cuándo extraer un componente

Extrae cuando un patrón se repite, cuando un bloque de plantilla se
complica, o cuando el mismo concepto aparece con nombres distintos.

| Situación | Qué hacer |
|---|---|
| Se repite en dos o más vistas | Componente en `app/components/base/` |
| Es propio de una historia | Componente en `app/components/<módulo>/` |
| Es lógica con estado | Composable en `app/composables/` |
| Es un texto | Clave en `app/i18n/locales/es.ts` |

## Anatomía de un componente

```vue
<script setup lang="ts">
/**
 * Qué hace y por qué existe.
 *
 * El comentario va arriba: es lo primero que se lee.
 */
withDefaults(
  defineProps<{
    /** Etiqueta visible. */
    titulo: string
    /** Texto secundario, opcional. */
    descripcion?: string
    /** Variante compacta. */
    compacto?: boolean
  }>(),
  { descripcion: undefined, compacto: false },
)

const emit = defineEmits<{
  /** Se emite cuando se elige una fila. */
  seleccionar: [id: number]
}>()
</script>

<template>
  <div :class="{ 'py-1': compacto }">
    <h2 class="text-(--vt-texto-lg) font-(--vt-texto-peso-fuerte)">{{ titulo }}</h2>
    <p v-if="descripcion" class="text-(--vt-texto-sm) text-(--vt-color-texto-suave)">
      {{ descripcion }}
    </p>
    <slot name="acciones" />
    <slot />
  </div>
</template>
```

Reglas:

- **Sin datos.** Un componente no llama a la API ni usa `useApi`. Recibe
  props y emite eventos.
- **Sin textos.** Los textos llegan como props ya traducidas, o el
  componente usa `useTexto()` si son suyos.
- **Sin estilos sueltos.** Se usan tokens; si hace falta una variación,
  se declara en el tema (`app/design/tema.ts`), no en la plantilla.
- **Tipos siempre.** Las props, los eventos y los slots se declaran.
- **Accesible.** Etiquetas asociadas, foco visible, tablas con
  `scope="col"`.

## Componentes base

En `app/components/base/`, con prefijo `Base`:

| Componente | Uso |
|---|---|
| `BaseEncabezadoPagina` | Primer bloque de una vista: título, descripción, acciones |
| `BaseTarjeta` | Contenedor con título, cuerpo y pie |
| `BaseTablaDatos` | Tabla genérica con columnas declarativas y plantilla por celda |
| `BaseEstadoVacio` | Lo que se ve cuando no hay nada |
| `BaseDato` | Indicador con etiqueta |

Ejemplo de tabla con plantilla por celda:

```vue
<BaseTablaDatos :columnas="columnas" :filas="reservas" :cargando="pendiente">
  <template #celda="{ columna, fila, valor }">
    <UBadge
      v-if="columna.clave === 'estado'"
      :label="t(`reservas.estados.${valor}`)"
      color="neutral"
    />
  </template>
</BaseTablaDatos>
```

La tabla entrega a la plantilla `columna`, `fila` y `valor`, para que cada
celda decida qué dibujar.

## Componentes por módulo

Cuando una historia tenga varias vistas, sus componentes viven con ella:

```text
app/components/reservas/
├── ListaReservas.vue
├── FormularioReserva.vue
└── DetalleReserva.vue
```

Se usan con el prefijo de la carpeta: `<ListaReservas />`. Cuando el
componente se usa en un solo lugar, puede vivir junto a la vista.

## Slots

- El slot por omisión es el contenido principal.
- Los slots con nombre son para las zonas: `#acciones`, `#pie`,
  `#celda`, `#vacio`.
- Un slot con valor por omisión recibe el contexto: en la tabla, la
  plantilla recibe `{ columna, fila, valor }`.

## Props y eventos

- Las props que son un conjunto de valores usan un tipo, no `string[]`.
- Un evento con carga útil declara sus argumentos:
  `defineEmits<{ seleccionar: [id: number] }>()`.
- El componente no muta las props: emite.

## Accesibilidad

- Todo elemento interactivo tiene foco visible (los estilos globales se
  encargan).
- Los iconos solos llevan `aria-label`.
- Los estados vacíos y de error se anuncian con texto.
- Las tablas llevan encabezados con `scope="col"`.

## Al agregar un componente

1. Decide si es base o de módulo.
2. Escribe el comentario que explica qué hace.
3. Declara props, eventos y slots con tipos.
4. Usa tokens, no colores.
5. Usa textos de `useTexto()`.
6. Agrégalo a la tabla de este documento si es un componente base.
