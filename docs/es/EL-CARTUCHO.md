# El cartucho

Dieciséis kilobytes en la página 1, sin un solo cambio de banco. Todo lo que
hace el juego cabe entre 0x4000 y 0x7FFF.

## La cabecera

Los dieciséis primeros bytes son la cabecera que lee la BIOS: la firma `AB` y
cuatro punteros. **Solo INIT tiene valor** (0x4081); STATEMENT, DEVICE y TEXT
van a cero. O sea que el cartucho no añade órdenes al BASIC ni se declara como
dispositivo: arranca y se queda con la máquina.

## Lo que hace INIT, y por qué no vuelve

INIT se prepara la casa y se va:

1. engancha la interrupción en **H.KEYI** (0xFD9A) con un `jp` a 0x4010;
2. limpia 0xE000-0xE3FE y pone la pila justo encima, en 0xE3FE;
3. calla el PSG —los tres registros de tono a cero— y lo deja con el canal A a
   volumen 8 y el mezclador a 0xA2;
4. apaga el piloto de CAPS;
5. copia los cuatro récords del mundo de 0x5174 a 0xE040;
6. coloca la flecha del menú en la primera línea.

A partir de ahí **el programa principal y la interrupción se reparten el
trabajo**. La interrupción lleva el reloj, los mandos y lo que tiene que ir a
ritmo de pantalla; el principal, la máquina de estados del juego.

## El mapa de la memoria

La RAM de trabajo es 0xE000-0xE3FE, con la pila arriba del todo. Está repartida
por zonas, y cada una tiene su explicación en el listado:

| tramo | qué es |
|---|---|
| 0xE000-0xE001 | contador de cuadros y espera en unidades de 32 |
| 0xE002-0xE017 | el estado de la partida: quién juega, con qué, ronda y prueba |
| 0xE019-0xE01C | el menú: dónde está la flecha y qué línea elegida |
| 0xE01D-0xE01E | los dos semáforos de la interrupción |
| 0xE020-0xE02E | el estado del intento y de la prueba, bit a bit |
| 0xE040-0xE04B | los cuatro récords del mundo, tres bytes BCD cada uno |
| 0xE051-0xE052 | la marca a batir de esta ronda |
| 0xE060-0xE09F | los marcadores que se pintan |
| 0xE0A0-0xE0FF | los dos atletas: velocidad, ángulo, marca y postura |
| 0xE120-0xE15F | cuatro fichas de actor de 16 bytes |
| 0xE160-0xE190 | los tres canales del reproductor de sonido |
| 0xE200-0xE22F | el estado de las pruebas de distancia |
| 0xE230-0xE2CF | el papel donde se montan las figuras antes de subirlas |

## Los dos semáforos de la interrupción

Merecen párrafo aparte porque son la clave de que esto no se rompa.

- **0xE01E, el candado.** Si está puesto, la interrupción se va sin tocar nada.
  Lo usa quien no puede permitirse que le interrumpan a mitad.
- **0xE01D, el aviso.** La interrupción lo pone al entrar. Lo mira quien
  estuviera fijando una dirección de VRAM: si la interrupción ha pasado por
  medio, la dirección ya no vale y hay que repetirla.

Ese segundo es el truco fino. Fijar una dirección en el VDP son dos escrituras
al puerto de control, y si la interrupción se cuela entre ellas —y ella también
escribe en el VDP— lo que venga detrás se escribe en el sitio equivocado. En vez
de prohibir la interrupción, se deja pasar y se comprueba después.

## La pantalla

SCREEN 2, con los tres tercios:

| tabla | dirección |
|---|---|
| nombres | 0x3800 |
| patrones | 0x2000 |
| color | 0x0000 |
| atributos de sprite | 0x3B00 |
| patrones de sprite | 0x1800, de 16x16 |

Los ocho registros del VDP salen de `registros_del_vdp` (0x4E73).

En el listado, las direcciones de VRAM aparecen **con el bit 14 puesto**
(sumado 0x4000) cuando se va a escribir, que es como lo pide el VDP: por eso
0x7800 es la tabla de nombres y 0x5800 los patrones de sprite. Al leer un
volcado conviene tenerlo presente o los números no cuadran.

## Tres tablas indexadas desde uno

Un patrón que se repite y que despista al leer el listado: hay tablas cuya
dirección registrada cae **dos bytes por delante** de la primera casilla útil,
porque el índice empieza en uno y el código avanza `2*indice` antes de leer.

| tabla | lo que dice el código | dónde empieza de verdad |
|---|---|---|
| pantallas (0x49BA) | — | dos bytes después |
| melodías | 0x6D26 | 0x6D28 |
| fichas de actor | 0x7B44 | 0x7B46 |

No es un error: la casilla cero no se usa nunca. Y en el caso de la tabla de
pantallas esos dos bytes **sirven además para otra cosa**: son el `FF FF` que
cierra el último mensaje del menú. Dos bytes con dos oficios.

## Los actores se empujan unos a otros

Las cuatro fichas de actor viven **seguidas** en 0xE120, 0xE130, 0xE140 y
0xE150, de dieciséis bytes cada una. Y eso no es casualidad: el bit 2 de una
ficha hace que ese actor suba el contador de la que tiene **0x11 bytes por
detrás**, y el bit 3 el de la que tiene **0x0F por delante**.

Así el decorado se arrastra en cadena sin que nadie lleve una lista de quién
empuja a quién: la relación está en la distancia entre las fichas.

## Lo que no lleva

**La marca oculta de Konami no está.** Muchos cartuchos de la casa esconden al
final de la ROM su número de catálogo RC-7xx y el título en katakana, detrás del
relleno; lo descubrió **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)). Aquí el último byte útil
es código del reproductor de sonido y solo queda un `0xFF` de relleno. Se
comprobó con `tools/marca_konami.py`, que en el mismo tiro **sí** la encuentra
en otro cartucho de la casa, así que el método funciona.
