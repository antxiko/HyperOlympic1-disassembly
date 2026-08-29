# El juego

Hyper Olympic 1 es la conversión para MSX del arcade de atletismo de Konami que
en occidente se llamó *Track & Field*. Se juega aporreando: dos teclas para
correr y una para saltar o lanzar.

## Cuatro pruebas, doce rondas

`0xE016` va de 1 a 4 y elige la prueba; `0xE015` cuenta hasta doce. O sea **las
cuatro pruebas, tres veces**. Fotografiadas una a una en el emulador
(`medidas/pruebas.txt`):

| | prueba | récord que enseña |
|---|---|---|
| 1 | 100 METER DASH | 09 SEC 95 |
| 2 | LONG JUMP | 08 M 90 |
| 3 | HAMMER THROW | 83 M 98 |
| 4 | 400 METER DASH | 43 SEC 86 |

**Los 400 metros no existen en el arcade.** La prueba 4 reaprovecha la lista de
pantallas y el marcador de la 1; lo único que cambia es el rótulo de la pizarra,
y ese rótulo (0x6332) es el de los 100 metros con el primer glifo cambiado de
«1» a «4». Una prueba nueva por el precio de un carácter.

## Hay que clasificarse

Cada ronda tiene una marca que batir, y están en `marcas_de_clasificacion`
(0x5008): dos bytes en BCD por ronda, que 0x4625 lee con `2*(ronda-1)`. Salen

```
14.00  06.00  80.00  55.00
12.00  07.00  85.00  50.00
11.00  08.00  95.00  40.00
```

Las cuatro pruebas se repiten tres veces y **cada vuelta aprieta**: en los 100
metros hay que bajar de 14, luego de 12, luego de 11; en longitud pasar de 6, de
7 y de 8 metros.

Si no te clasificas, se acabó. `0xE021` lleva un bit por jugador diciendo si
sigue en juego, y `0xE022` quién pasa a la ronda siguiente.

## Los intentos

En las pruebas de lanzamiento y salto no hay una carrera y ya: hay cuatro
intentos. `0xE023`/`0xE024` cuentan los gastados por jugador y
`0xE025`/`0xE026` el que está en curso. El resultado de cada uno va en
`0xE02A`/`0xE02B`: **1 nulo, 2 vale, 3 récord**.

Cuando un intento no vale, el marcador escribe el rótulo de fallo
(`rotulo_de_fallo`, 0x5133), y lo piden dos sitios distintos: 0x433A y 0x44D0.

## El reloj miente en Europa

La rutina que cuenta el tiempo (0x5695) suma **1,665 centésimas por cuadro**, o
sea un sesentavo de segundo. Está calculada para una máquina de 60 Hz.

Medido con `tools/omsx_reloj.tcl` en las dos:

| máquina | Hz | reloj del juego por segundo real |
|---|---|---|
| Philips VG-8020 (PAL) | 50 | **0,8325 s** |
| C-BIOS MSX1 JP (NTSC) | 60 | 0,9990 s |

En un MSX europeo, **un «12,00» son 14,4 segundos de verdad**. Y no es que el
juego vaya lento: es que el reloj cuenta corto. Las marcas de clasificación y
los récords del mundo están pensados para la máquina japonesa.

Cuidado con leerlo al revés: eso es un **periodo**, no una velocidad. El detalle
y las tablas en crudo están en [En el emulador](EN-EL-EMULADOR.md).

## Dos jugadores, cuadros alternos

`0xE010` dice si juegan dos y `0xE011` a quién le toca. Cuando corren los dos a
la vez, 0x51AD mira el bit 0 del contador de cuadros: **en los pares mueve al
atleta del jugador 1 y en los impares al del 2**. La mitad del trabajo por
cuadro, y a 50 o 60 Hz no se nota.

## La demo se juega sola, y muy mal

Cuando nadie toca nada arranca una demo. No lleva una partida grabada: la
**juega la interrupción**, y el piloto es de lo más tonto que se puede escribir.
Con `0xE002` a 1, la rutina de 0x4030 mete en `0xE00B` un valor de `ld a,r` —el
registro de refresco de la memoria— enmascarado a dos bits, una vez cada cuatro
cuadros. Eso es todo: **pulsaciones al azar**.

Hay un detalle que despista y que está medido, no supuesto. El bit 7 de
`0xE029` parece el interruptor de la demo, porque 0x5849 lo pone y 0x4030 lo
mira; pero en el emulador (`medidas/demo.txt`) está puesto **igual en la demo y
en una partida de verdad**: 0xE029 vale 0x82 en las dos. El que manda es
`0xE002`, que vale 1 en la demo y 0 en partida, y es lo primero que mira la
interrupción.

## Los mandos

`0xE004` dice si se juega con joystick o con teclado, y `0xE005` lleva lo leído
en este cuadro: bit 0 arriba, bit 1 abajo, bit 4 espacio, bit 5 F5. Con joystick,
los dos botones. De cada jugador se guardan **los mandos de antes y los de
ahora** (0xE008-0xE00F), que es como se detecta el flanco y no la pulsación
mantenida — imprescindible en un juego que se basa en machacar una tecla.
