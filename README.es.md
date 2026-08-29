# Hyper Olympic 1 (Konami, RC-710) — desensamblado comentado

Desensamblado comentado del cartucho de MSX de 16 KB, reproducible byte a byte.

**[Leer el trabajo →](https://antxiko.github.io/HyperOlympic1-disassembly/es/)**
· [In English](README.md)

    make            # traza, genera el listado, lo reensambla y pasa los tests
    make verify     # la prueba que decide: reensamblar tiene que dar la ROM
    make sanity     # que ningun byte se quede sin explicar
    make densidad   # cuanto esta comentado, rutina por rutina
    make web        # regenera la web

La ROM **no se distribuye aqui**. Hace falta en la raiz como `hyperolympic1.rom`,
16384 bytes, sha256

    0cd8a7928e10a8551d7f6fd68943a6d4a008e04a254d258413c120dda18b792e

`make comprueba` lo verifica.

## Como esta

| | |
|---|---|
| reensambla byte a byte | si |
| bytes explicados | 16.384 de 16.384 (100 %) |
| codigo trazado | 9.335 bytes, 5.032 instrucciones |
| datos identificados | 7.049 bytes en 92 rangos con nombre |
| comentado | 1.681 comentarios de linea, 33,4 % |
| rutinas flojas (por debajo del 10 %) | 0 de 569 |

Las anotaciones viven aparte del listado, ancladas a la direccion que
describen. Lo que hay en el fichero `.notes`:

| | |
|---|---|
| etiquetas con nombre | 569 |
| comentarios anclados | 1.668 |
| rangos de datos con explicación | 92 |

## Que hay dentro

- `src/hyperolympic1.asm` — el listado, generado; no se edita a mano
- `src/hyperolympic1.notes` — las anotaciones, ancladas a direccion
- `src/hyperolympic1.entries` — los puntos de entrada, cada uno justificado
- `src/hyperolympic1.nocode` — las zonas que el trazador tiene prohibidas
- `docs/` — la web, en ingles y en castellano
- `medidas/` — lo que se midio en openMSX, con las tablas en crudo
- `tools/` — el trazador, el generador del listado y los recorredores de datos

## El trabajo escrito

| | |
|---|---|
| [Empezar](docs/es/EMPEZAR.md) | lo que hace falta y que hace cada orden |
| [El juego](docs/es/EL-JUEGO.md) | cuatro pruebas, doce rondas y un reloj que miente |
| [El cartucho](docs/es/EL-CARTUCHO.md) | la cabecera, el mapa de memoria y la pantalla |
| [El codigo](docs/es/EL-CODIGO.md) | como esta montado el programa |
| [Hallazgos](docs/es/HALLAZGOS.md) | lo que dice el binario |
| [En el emulador](docs/es/EN-EL-EMULADOR.md) | lo que se midio, y como repetirlo |
| [Preguntas abiertas](docs/es/PREGUNTAS-ABIERTAS.md) | lo que queda sin cerrar |
| [Hyper Olympic contra Track & Field](docs/es/COMPARATIVA-TRACK-AND-FIELD.md) | las dos compilaciones de este cartucho, comparadas |

Ver `AVISO-LEGAL.md`.
