# En el emulador

Leer el binario dice lo que el código **hace**. Hay cosas que solo dicen lo que
el código **vale** cuando corre, y para ésas está openMSX. Todo lo de esta
página está medido, y las tablas en crudo están en `medidas/`.

## La regla de la casa

Los guiones de `tools/omsx_*.tcl` **solo leen memoria**. La ROM no se toca en
ningún caso: no hay parches, ni bytes cambiados, ni ejecución forzada de nada.

La única excepción está declarada y es una medida, no una modificación:
`tools/omsx_prueba_n.tcl` para la máquina en 0x4220 —justo después de que
`PARTIDA_NUEVA` (0x4218) ponga la ronda y la prueba a 1— y escribe en 0xE016 el
número de la prueba que se quiere ver. 0xE016 es una variable del propio juego,
y de ahí en adelante corre el cartucho solo, con sus datos y su código. Lo que
se ahorra es tener que clasificarse en las tres pruebas anteriores para llegar a
la cuarta.

## Las cuatro pruebas

Con eso se fotografiaron una a una (`medidas/pruebas.txt`, capturas en
`docs/imagenes/`):

| 0xE016 | rótulo que sale | récord que pinta |
|---|---|---|
| 1 | 100 METER DASH | 09 SEC 95 |
| 2 | LONG JUMP | 08 M 90 |
| 3 | HAMMER THROW | 83 M 98 |
| 4 | 400 METER DASH | 43 SEC 86 |

Los cuatro récords coinciden byte a byte con la tabla de 0x5174, que INIT copia
a 0xE040: `00 09 95 / 00 08 90 / 00 83 98 / 00 43 86`. O sea que lo que se ve en
pantalla y lo que dice el binario son lo mismo, comprobado por los dos lados.

## El reloj está calculado para 60 Hz

Ésta es la medida que más cambia lo que uno cree del juego.

`SUMA_AL_RELOJ` (0x5695) suma al contador BCD de 0xE0A9-0xE0AB una vez por
cuadro, alternando 0x0167 y 0x0166. Si el byte de arriba son segundos y el de en
medio centésimas, eso es 1,67 y 1,66 centésimas: media **1,665**, que es un
sesentavo de segundo con cuatro cifras.

`tools/omsx_reloj.tcl` corre los 100 metros machacando el espacio y muestrea
0xE0A9-0xE0AB una vez por segundo emulado. En dos máquinas:

| máquina | Hz | reloj del juego por segundo real |
|---|---|---|
| Philips VG-8020 (PAL) | 50 | **0,8325 s** — se queda un 16,75 % corto |
| C-BIOS MSX1 JP (NTSC) | 60 | 0,9990 s — clavado |

Las dos cifras salen de restar dos muestras seguidas de `reloj_pal.txt` y
`reloj_ntsc.txt`, y coinciden con la cuenta: 50 × 1,665 = 83,25 y 60 × 1,665 =
99,9.

**La consecuencia:** en un MSX europeo los tiempos que enseña el cartucho no son
segundos. Un 100 metros cronometrado en 12,00 por el juego ha durado 14,4
segundos de verdad. Las marcas de clasificación de 0x5008 y los récords del
mundo de 0x5174 están pensados para la máquina japonesa.

**Y cuidado con leerlo al revés.** Eso es un *periodo*, no una *velocidad*: el
juego no va más despacio en Europa —el atleta corre a la misma velocidad de
pantalla que le permitan los 50 Hz—, lo que pasa es que **el cronómetro cuenta
corto**. Son dos afirmaciones distintas y solo una está medida.

## La demo: quién manda de verdad

Cuando nadie toca nada, el cartucho cae en una demo que se juega sola. El piloto
es `INT_CON_MANDOS` (0x4027) metiendo en 0xE00B un valor de `ld a,r` enmascarado
a dos bits, una vez cada cuatro cuadros: pulsaciones al azar.

Leyendo el listado, el interruptor **parece** el bit 7 de 0xE029, porque 0x5849
lo pone y 0x4030 lo mira. `tools/omsx_demo.tcl` muestrea las dos situaciones sin
tocar nada, primero dejando correr la demo y después arrancando una partida de
verdad, y sale esto (`medidas/demo.txt`, resumido):

| | 0xE002 | 0xE029 |
|---|---|---|
| demo | **01** | 0x82 |
| partida | **00** | 0x82 |

**0xE029 vale igual en las dos.** El que manda es 0xE002, que es lo primero que
mira la interrupción: si vale cero, lee los mandos de verdad; si no, se inventa
las pulsaciones. En partida, las inventadas no llegan nunca a 0xE00B.

Es un buen ejemplo de por qué hay que medir: leyendo el código, la hipótesis del
bit 7 era razonable, estaba bien construida y era falsa.

## El menú, medido en la captura del título

Cuatro líneas, y lo que cada una deja en memoria:

| línea | 0xE01B |
|---|---|
| 1PLAYER with JOYSTICK | 1 |
| 2PLAYERS with JOYSTICK | 2 |
| 1PLAYER with KEYBOARD | 3 |
| 2PLAYERS with KEYBOARD | 4 |

`EMPIEZA_LA_PARTIDA` (0x41BC) lo reparte: el bit 0 de 0xE01B da el número de
jugadores (0xE010) y el valor por debajo de 3 da el mando (0xE004). Una sola
variable con las dos respuestas dentro.

## Cómo repetirlo

```sh
openmsx -machine Philips_VG_8020 -cart hyperolympic1.rom \
        -script tools/omsx_reloj.tcl
PRUEBA=3 openmsx -machine Philips_VG_8020 -cart hyperolympic1.rom \
        -script tools/omsx_prueba_n.tcl
```

Las tablas que salen se quedan en `work/omsx/`. Las que están en `medidas/` son
las que se usaron para escribir esto.
