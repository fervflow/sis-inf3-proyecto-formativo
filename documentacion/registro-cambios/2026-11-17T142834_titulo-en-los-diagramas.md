# Título en los diagramas

- **Fecha:** 17 de noviembre de 2026, 14:28 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios)
- **Alcance:** los diagramas de secuencia llevan, en la parte superior y antes
  de los participantes, el título de la historia de usuario que representan.

## Antecedente

Los diagramas se identificaban por el nombre del archivo: `hu-06-registrar-reserva.puml`.
Para quien los abre en un visor o en un PDF, el diagrama no indicaba a qué
historia de usuario pertenecía, porque esa información solo estaba en el
comentario de cabecera del código fuente, que no se ve en la imagen.

## Cambios de contenido

No hubo cambios en el contenido del informe.

## Cambios de formato

### El título en los diagramas

Los 22 diagramas del proyecto declaran ahora su título con la palabra clave
`title` de PlantUML, declarada justo después de `@startuml`, de modo que se
dibuja centrado sobre los participantes y antes del inicio del diagrama.

El texto reutiliza el que cada archivo ya tenía como comentario de cabecera,
por lo que no se duplicó información: el comentario invisible se convirtió en
el título visible.

| Carpeta | Diagramas | Título |
|---|---|---|
| `sistema/diagramas/uml/secuencia/` | 7 | `HU-NN · Nombre de la historia`, con el texto exacto del backlog |
| `sistema/diagramas/uml/secuencia-light/` | 7 | Igual, con el sufijo «(versión ligera)» |
| `sistema/diagramas/uml/secuencia-comunes/` | 5 | «Común · …», con la descripción del subflujo |
| `sistema/diagramas/uml/secuencia-fusionados/` | 2 | «HU-03 + HU-05 · …» y «HU-07 + HU-13 · …», con «(variante fusionada)» |
| `sistema/diagramas/uml/procesos/` | 1 | El mapa de actividades, por coherencia del conjunto |

PlantUML no aplica los parámetros de fuente al título de los diagramas de
secuencia: se comprobó que `titleFontSize`, `titleFont` y `titleAlignment`
no modifican su renderizado. El resultado visual cumple lo pedido: el título
sale al mismo tamaño que las etiquetas de los participantes, de modo que se
lee como un pie de figura y no compite con el diagrama.

## Cambios de proceso

- Se documentó la convención en `sistema/diagramas/README.md`, con la forma
  exacta de declararla, para que los diagramas futuros la sigan.
- Se comprende que los diagramas se incorporarán al informe en una entrega
  posterior. El formato que tendrán como figuras queda por decidir en ese
  momento: si el título se conserva dentro de la imagen o se traslada al pie
  de la figura numerada.

## Archivos modificados

- Los 22 archivos `.puml` de `sistema/diagramas/uml/`.
- `sistema/diagramas/README.md`

## Validación

- `make diagramas` y `make png` regeneraron las 22 salidas sin errores ni
  advertencias de PlantUML.
- Se comprobó que los 22 diagramas tienen título y que no queda ninguno sin
  él.
- `make verificar` terminó con cero problemas: 22 diagramas, 20 rutas LaTeX
  y 24 entradas del árbol del README.
- Se revisaron visualmente un diagrama completo, una variante fusionada y un
  fragmento común: el título aparece centrado sobre los participantes.
- El informe no se vio afectado: todavía no incorpora ningún diagrama, y la
  compilación mantiene 21 páginas.

## Pendientes

- Incorporar los diagramas al informe en una entrega posterior y decidir su
  formato como figuras: si el título se mantiene dentro de la imagen o pasa
  al pie de la figura numerada.
- Generar el diagrama de HU-17, que es la única de las historias del canal
  del cliente sin representación propia.
