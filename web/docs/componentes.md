# Componentes

## Cuándo extraer

| Situación | Qué hacer |
|---|---|
| Se repite en dos o más vistas | Componente en `app/components/base/` |
| Es propio de una historia | Componente en `app/components/<módulo>/` |
| Es lógica con estado | Composable en `app/composables/` |
| Es un texto | Clave en `app/i18n/locales/es.ts` |

## Anatomía

```vue
<script setup lang="ts">
/**
 * Qué hace y por qué existe.
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

- **Sin datos.** No llama a la API: recibe props y emite.
- **Sin textos sueltos.** Llegan como props traducidas o usa `useTexto()`.
- **Sin estilos sueltos.** Usa tokens; las variantes van en el tema.
- **Tipos siempre.** Props, eventos y slots declarados.
- **Accesible.** Etiquetas asociadas, foco visible y `scope="col"`.

## Componentes base

En `app/components/base/`, con prefijo `Base`:

| Componente | Uso |
|---|---|
| `BaseEncabezadoPagina` | Título, descripción y acciones de una vista |
| `BaseTarjeta` | Contenedor con título, cuerpo y pie |
| `BaseTablaDatos` | Tabla con columnas declarativas y plantilla por celda |
| `BaseEstadoVacio` | Lo que se ve cuando no hay nada |
| `BaseDato` | Indicador con etiqueta |
| `BaseCampoMoneda` | Importe en bolivianos con formato y dos decimales |
| `BaseMapa` | Mapa de OpenStreetMap con marcadores; solo se carga en el cliente |

Ejemplo de tabla:

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

La tabla entrega `columna`, `fila` y `valor` a la plantilla.

## La barra de navegación

`app/components/BarraNavegacion.vue` es la cabecera de toda la aplicación.
Recibe la cuenta de la sesión y emite `salir`; no pide datos ni llama a la
API. Los enlaces de gestión dependen del rol, y el menú de la cuenta
incluye el cierre de sesión.

## Componentes por módulo

Cuando una historia tenga varias vistas, sus componentes viven con ella:

```text
app/components/reservas/
├── ListaReservas.vue
├── FormularioReserva.vue
└── DetalleReserva.vue
```

Se usan con el prefijo de la carpeta en PascalCase: `reservas/ListaReservas.vue`
se usa como `<ReservasListaReservas />`. Si se usa en un solo lugar, puede
vivir junto a la vista. En `paquetes/` viven `FormularioPaquete` y
`SelectorLugar`, que sí consultan la API y por eso no son componentes base.
En `solicitudes/` vive `FormularioPublico`, el formulario de solicitud de
reserva del canal web: recibe la salida elegida, registra al cliente por
documento y emite `registrada` con la reserva creada. En `disponibilidad/`
vive `Tarjeta`, el espejo público de la tarjeta de salidas: muestra el
paquete, fechas, ocupación y precio, y emite `solicitar` para pedir cupo.

## Slots

- El slot por omisión es el contenido principal.
- Los slots con nombre cubren zonas: `#acciones`, `#pie`, `#celda`,
  `#vacio`.
- Un slot con valor por omisión recibe contexto; en la tabla,
  `{ columna, fila, valor }`.

## Props y eventos

- Las props de un conjunto de valores usan un tipo, no `string[]`.
- Un evento con carga útil declara sus argumentos:
  `defineEmits<{ seleccionar: [id: number] }>()`.
- El componente no muta las props: emite.

## Accesibilidad

- Todo elemento interactivo tiene foco visible.
- Los iconos solos llevan `aria-label`.
- Los estados vacíos y de error se anuncian con texto.
- Las tablas llevan encabezados con `scope="col"`.

## Al agregar un componente

1. Decidir si es base o de módulo.
2. Escribir el comentario que explica qué hace.
3. Declarar props, eventos y slots con tipos.
4. Usar tokens, no colores.
5. Usar textos de `useTexto()`.
6. Agregarlo a la tabla de este documento si es base.
