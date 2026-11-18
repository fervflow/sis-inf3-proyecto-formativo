# AGENTS.md — la web del sistema

Guía operativa para agentes y modelos que trabajen en `web/`. Es el punto de
entrada: dice qué aplica siempre y a qué documento leer según la tarea.

**No forma parte del informe**: es documentación de trabajo del segundo
módulo del monorepo.

## Qué es este módulo

La aplicación web del sistema de gestión de paquetes turísticos y reservas de
Vizcacha Tours. Atiende a dos canales con el mismo proceso validado: la
atención del personal de agencia y el acceso directo del cliente.

- **Marco:** Nuxt 4 (Vue 3, Nitro), con Nuxt UI para los componentes.
- **Base de datos:** PostgreSQL en Neon, con Drizzle ORM como capa de tipos.
- **Identidad:** Better Auth, con las tablas de sesión en la misma base.

## Reglas que no se negocian

1. **Ningún texto de la interfaz va escrito en la plantilla.** Todo pasa por
   `useTexto()` y sus claves viven en `app/i18n/locales/`. Ver
   `docs/i18n.md`.
2. **El sistema de diseño manda sobre la biblioteca.** Los colores, los
   radios y las tipografías salen de `app/design/tokens.css`. Un componente
   nunca escribe un color. Ver `docs/design-system.md`.
3. **Los componentes propios son la puerta de entrada.** Si un patrón se
   repite, va en un componente de `app/components/base/`; la vista no
   improvisa. Ver `docs/componentes.md`.
4. **El SQL es la fuente canónica del esquema.** `bd/esquema.sql` manda;
   `web/db/schema.ts` lo refleja. Las dos cambian juntas. Ver
   `docs/base-de-datos.md`.
5. **Las reglas críticas se validan en la base.** La validación de cupos y
   las demás reglas con bloqueo de fila son funciones PL/pgSQL. La
   aplicación las llama; no las reimplementa.
6. **Todo dato que cruza la red va validado.** Entradas con Zod en el
   servidor, tipos en `shared/types/`. Ver `docs/tipos-y-datos.md` y
   `docs/seguridad.md`.
7. **Se escribe en español**: los textos, los comentarios y los nombres de
   las variables de dominio. Las palabras del framework van en inglés.

## Comandos

| Qué | Comando |
|---|---|
| Instalar dependencias | `npm install` (en la raíz del repositorio) |
| Levantar en desarrollo | `npm run dev --workspace web` o `make web-dev` |
| Comprobar los tipos | `npm run typecheck --workspace web` |
| Compilar | `npm run build --workspace web` o `make web-build` |
| Comprobar el esquema | `npm run db:check --workspace web` |
| Crear el esquema de la base | `make db-crear` |

## Antes de terminar

1. `npm run typecheck --workspace web` termina sin errores.
2. `npm run build --workspace web` compila.
3. Si se tocó el esquema: `bd/esquema.sql` y `web/db/schema.ts` están
   alineados.
4. Si se agregó un texto: existe en `es.ts` **y** en los demás idiomas.
5. Si se agregó un componente: está en `app/components/base/` y tiene su
   ejemplo de uso en `docs/componentes.md`.
6. Con la aceptación del usuario, el trabajo se registra en la bitácora
   del repositorio (`docs/changelog/`, en la raíz).

## Índice: qué leer según la tarea

| Vas a… | Lee |
|---|---|
| Entender la estructura y el flujo de datos | `docs/arquitectura.md` |
| Escribir código que se parezca al existente | `docs/convenciones.md` |
| Tocar colores, tipografía o espaciado | `docs/design-system.md` |
| Crear o modificar un componente | `docs/componentes.md` |
| Agregar o cambiar un tipo | `docs/tipos-y-datos.md` |
| Agregar o cambiar un texto de la interfaz | `docs/i18n.md` |
| Tocar tablas, columnas o funciones | `docs/base-de-datos.md` |
| Tocar el ingreso, los roles o la sesión | `docs/autenticacion.md` |
| Escribir pruebas | `docs/pruebas.md` |
| Revisar la seguridad | `docs/seguridad.md` |
| Saber qué se está haciendo y cómo se entrega | `docs/flujo-de-trabajo.md` |

## Estructura de carpetas

```text
web/
├── AGENTS.md              Esta guía
├── docs/                  Documentación de la web
├── app/                   Interfaz (Nuxt 4 usa app/ como carpeta de origen)
│   ├── app.vue            Marco de la aplicación
│   ├── app.config.ts      Tema de Nuxt UI
│   ├── assets/css/        Estilos globales
│   ├── components/        Componentes: base/ y luego por módulo
│   ├── composables/       Lógica reutilizable de la interfaz
│   ├── design/            Sistema de diseño: tokens y tema
│   ├── i18n/              Textos centralizados de la interfaz
│   └── pages/             Vistas
├── server/                Servidor Nitro
│   ├── api/               Rutas de la API
│   ├── middleware/        Sesión y control de acceso
│   └── utils/             Base de datos y autenticación
├── shared/types/          Tipos compartidos entre interfaz y servidor
└── db/schema.ts           El esquema en TypeScript (refleja bd/esquema.sql)
```
