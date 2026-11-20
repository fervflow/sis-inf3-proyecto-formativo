# AGENTS.md — la web del sistema

Guía operativa para agentes y modelos que trabajen en `web/`. **No forma
parte del informe**: es documentación de trabajo.

## Qué es este módulo

La aplicación web de Vizcacha Tours. Atiende dos canales con el mismo
proceso validado: la atención del personal y el acceso del cliente.

- **Marco:** Nuxt 4 (Vue 3, Nitro), con Nuxt UI.
- **Base de datos:** PostgreSQL en Neon, con Drizzle ORM.
- **Identidad:** Better Auth, con las tablas de sesión en la misma base.

## Reglas que no se negocian

1. **Ningún texto de la interfaz va en la plantilla.** Todo pasa por
   `useTexto()` y sus claves viven en `app/i18n/locales/`. Ver
   `docs/i18n.md`.
2. **El sistema de diseño manda sobre la biblioteca.** Colores, radios y
   tipografías salen de `app/design/tokens.css`. Ver
   `docs/design-system.md`.
3. **Los componentes propios son la puerta de entrada.** Un patrón repetido
   va en `app/components/base/`. Ver `docs/componentes.md`.
4. **La regla de negocio manda.** `sistema/reglas-negocio.md` es la fuente
   canónica; el esquema la aplica y la aplicación no la contradice.
5. **El SQL es la fuente canónica del esquema.** `bd/esquema.sql` manda;
   `web/db/schema.ts` lo refleja. Cambian juntos. Ver
   `docs/base-de-datos.md`.
6. **Las reglas críticas se validan en la base.** Cupos y bloqueos son
   funciones PL/pgSQL; la aplicación las llama, no las reimplementa.
7. **Todo dato que cruza la red va validado.** Zod en el servidor y tipos
   en `shared/types/`. Ver `docs/tipos-y-datos.md` y `docs/seguridad.md`.
8. **Se escribe en español**: textos, comentarios y nombres de dominio. Las
   palabras del framework van en inglés.

## Comandos

| Qué | Comando |
|---|---|
| Instalar dependencias | `npm install` (en la raíz) |
| Traer variables de Neon | `neon env pull` o `make neon-env` |
| Levantar en desarrollo | `make web-dev` |
| Comprobar tipos | `npm run typecheck --workspace web` |
| Compilar | `make web-build` |
| Comprobar el esquema | `npm run db:check --workspace web` |
| Crear el esquema | `make db-crear` (conexión directa) |
| Actualizar una base existente | `make db-actualizar` |
| Probar reglas de paquetes y salidas | `make db-probar` |

## Variables de entorno

La CLI de Neon deja las variables en `.env.local`, en la raíz, y la
aplicación las carga sola (`nuxt.config.ts`).

En Node **gana el primer valor**: se carga `web/.env`, el `.env` de la raíz
y `.env.local` de la raíz. Un `web/.env` con valores de ejemplo tapa los de
Neon.

Los valores se leen en **tiempo de ejecución** (`server/utils/config.ts`),
no al compilar: las credenciales no quedan dentro del paquete.

## Antes de terminar

1. `npm run typecheck --workspace web` sin errores.
2. `npm run build --workspace web` compila.
3. Si se tocó el esquema, `bd/esquema.sql` y `web/db/schema.ts` están
   alineados.
4. Un texto nuevo existe en `es.ts` y en los demás idiomas.
5. Un componente nuevo está en `app/components/base/` y documentado en
   `docs/componentes.md`.
6. Con la aceptación del usuario, se registra en `docs/changelog/`.

## Índice

| Vas a… | Lee |
|---|---|
| Entender la estructura y el flujo de datos | `docs/arquitectura.md` |
| Escribir código como el existente | `docs/convenciones.md` |
| Tocar colores, tipografía o espaciado | `docs/design-system.md` |
| Crear o modificar un componente | `docs/componentes.md` |
| Agregar o cambiar un tipo | `docs/tipos-y-datos.md` |
| Agregar o cambiar un texto | `docs/i18n.md` |
| Consultar o cambiar una regla de negocio | `../sistema/reglas-negocio.md` |
| Tocar tablas, columnas o funciones | `docs/base-de-datos.md` |
| Tocar ingreso, roles o sesión | `docs/autenticacion.md` |
| Escribir pruebas | `docs/pruebas.md` |
| Revisar la seguridad | `docs/seguridad.md` |
| Saber cómo se entrega | `docs/flujo-de-trabajo.md` |

## Estructura

```text
web/
├── app/                   Interfaz (Nuxt 4)
│   ├── components/        base/ y por módulo
│   ├── composables/       Lógica reutilizable
│   ├── design/            Tokens y tema
│   ├── i18n/              Textos centralizados
│   └── pages/             Vistas
├── server/                Nitro: api/, middleware/ y utils/
├── shared/types/          Tipos compartidos
└── db/schema.ts           Esquema en TypeScript
```
