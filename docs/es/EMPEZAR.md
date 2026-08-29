# Empezar

Este repositorio no trae el juego: trae la manera de volver a montarlo desde tu
propia copia y de comprobar que lo que sale es exactamente el cartucho.

## Lo que hace falta

Tu propio volcado del cartucho, en la raíz y con este nombre:

| | |
|---|---|
| fichero | `hyperolympic1.rom` |
| tamaño | 16.384 bytes |
| sha256 | `0cd8a7928e10a8551d7f6fd68943a6d4a008e04a254d258413c120dda18b792e` |

Y `pasmo`, `z80dasm` y Python 3. Para las medidas del emulador, openMSX.

## La orden que lo hace todo

```sh
make comprueba   # ¿es este el volcado bueno?
make             # traza, genera el listado, lo reensambla y pasa los tests
```

`make` acaba en verde o no acaba. La línea que importa es ésta:

```
  ensamblado : 16384 bytes  0cd8a792...a18b792e
  original   : 16384 bytes  0cd8a792...a18b792e
OK: reproducible byte a byte
```

## Las otras órdenes

```sh
make verify     # la prueba que decide: reensamblar tiene que dar la ROM
make sanity     # lo que el reensamblado NO puede cazar
make densidad   # cuánto está comentado, rutina por rutina
make imagenes   # dibuja bloques de la ROM para mirarlos
make test       # los tests del listado
make web        # regenera esta web
```

## Por qué `verify` no basta

Reensamblar y obtener los mismos bytes demuestra que el listado es **fiel**, no
que sea **correcto**. Si unos gráficos se leyeran como instrucciones, los bytes
saldrían idénticos igual: lo único que mentiría es el listado.

Por eso `make sanity` hace tres comprobaciones más, y las tres son las que de
verdad se ganan el sueldo:

- **ningún byte declarado como datos puede salir como código**, y al revés;
- **ningún punto de entrada puede caer dentro de una zona de datos**;
- **ni un byte del cartucho sin asignar** — el presupuesto tiene que sumar
  16.384, repartidos entre código al que el trazador llega de verdad y rangos
  de datos con nombre y explicación.

Y una cuarta, que nació en este proyecto por un motivo concreto: **ninguna
anotación puede citar una dirección del cartucho hermano**. Hyper Olympic 1 y 2
son casi el mismo programa, así que las anotaciones se portan de uno a otro con
`tools/porta_notas.py`; eso las coloca en la dirección buena pero no cambia lo
que dicen. `tools/repasa_el_porte.py` comprueba que toda dirección citada dentro
de un comentario —o dentro de una página de esta web— sea arranque de
instrucción o caiga en un rango de datos **de este cartucho**.

## Qué hay dentro

| | |
|---|---|
| `src/hyperolympic1.asm` | el listado, generado; no se edita a mano |
| `src/hyperolympic1.notes` | las anotaciones, ancladas a dirección |
| `src/hyperolympic1.entries` | los puntos de entrada, cada uno justificado |
| `src/hyperolympic1.nocode` | las zonas que el trazador tiene prohibidas |
| `medidas/` | lo medido en openMSX, con las tablas en crudo |
| `tools/` | el trazador, el generador del listado y los recorredores |
| `docs/` | esta web |

Los comentarios viven **aparte** del listado, anclados a la dirección que
describen. Así sobreviven a un retrazado: si mañana el trazador reparte el
binario de otra forma, los comentarios siguen cayendo donde tienen que caer.

## Lo que no está aquí

La imagen del cartucho. Ni ésta ni ninguna otra: es de Konami y no se
distribuye. Ver [AVISO-LEGAL.md](../AVISO-LEGAL.md).
