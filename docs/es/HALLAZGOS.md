# Hyper Olympic 1 (Konami, RC-710) - lo que dice el binario

Todo lo de aqui sale de leer el cartucho o de medirlo en openMSX. Lo que es
suposicion lleva la palabra SUPOSICION delante.

## 1. Son CUATRO pruebas, y una no es del arcade

0xE016 va de 1 a 4 y 0xE015 cuenta doce rondas, o sea las cuatro pruebas tres
veces. Fotografiadas una a una (`medidas/pruebas.txt`):

    1  100 METER DASH      record 09 SEC 95
    2  LONG JUMP           record 08 M 90
    3  HAMMER THROW        record 83 M 98
    4  400 METER DASH      record 43 SEC 86

Los 400 metros no existen en el arcade de Konami del que viene el juego. La
prueba 4 reaprovecha la lista de pantallas y el marcador de la 1: lo unico que
cambia es el rotulo de la pizarra, y ese rotulo (0x6332) es el de los 100
metros con el primer glifo cambiado de "1" a "4".

## 2. Los records son de verdad, pero la tabla se hizo ANTES de 1983

MEDIDO en el binario: 0x5174 lleva `00 09 95 / 00 08 90 / 00 83 98 / 00 43 86`,
que INIT copia a 0xE040. O sea 9,95 s en los 100 m, 8,90 m en longitud, 83,98 m
en martillo y 43,86 s en los 400.

Los cuatro son records del mundo de verdad. Lo que **no** es verdad es que
fueran los vigentes cuando salio el cartucho, que es lo que decia aqui antes:

| prueba | el cartucho | de quien y de cuando | ¿seguia en pie en 1984? |
|---|---|---|---|
| 100 m | 9,95 | Jim Hines, Mexico, octubre de 1968 | **no**: Calvin Smith corrio 9,93 el 3 de julio de 1983 |
| longitud | 8,90 | Bob Beamon, Mexico, octubre de 1968 | si, y hasta 1991 |
| martillo | 83,98 | Sergey Litvinov, 1982 | **no**: el propio Litvinov lo dejo en 84,14 en 1983 |
| 400 m | 43,86 | Lee Evans, Mexico, octubre de 1968 | si, y hasta 1988 |

**La tabla se compilo antes de la temporada de 1983.** Los dos que seguian en
pie son los de Mexico 68, que llevaban quince anos sin que nadie los tocara; los
otros dos ya estaban batidos cuando el cartucho llego a las tiendas. El mismo
patron sale en el cartucho hermano, y alli es aun mas claro.

El error de los 100 m lo caza **Araubi**, y es un error de los que ensenan algo:
la parte medible -que la ROM guarda 9,95- estaba bien; lo que estaba mal era la
frase de alrededor, que anadia al binario una afirmacion que el binario no hace.
Las fechas de esta tabla no salen del cartucho, sino de las progresiones
publicas de records; se dan como lo que son, un cotejo externo.

## 3. El reloj esta calculado para 60 Hz, y en Europa miente

0x5695 suma 1,665 centesimas por cuadro. Medido: en un MSX de 50 Hz el reloj
del juego avanza 0,8325 segundos por segundo real, y en uno de 60 Hz avanza
0,9990. En una maquina europea un "12,00" son 14,4 segundos de verdad. Las
cifras y el metodo estan en `medidas/reloj.md`.

## 4. El cartucho no guarda pantallas: guarda guiones

Hay cuatro interpretes distintos, cada uno con su formato:

  - 0x4D09 el guion largo, con cinco tipos de orden (bytes con RLE, tiras de
    glifos, rotulos de letra grande, rellenos y repeticion de un patron)
  - 0x4AFE el guion corto, para textos sueltos
  - 0x4C63 el rotulo, que se estira despues a letra grande
  - 0x7A1F la figura, que se expande a codigos de caracter

Los 2,5 KB de 0x5C96 a 0x668E son enteramente guiones y datos de guion. Un
recorrido desde las raices los cubre sin dejar un byte suelto
(`tools/cobertura.py`).

## 5. Las letras grandes se fabrican, no se guardan

0x4C49 copia glifos NORMALES de 8x8 a 0xE230 y luego 0x4CAB da tres pasadas
sacando los dos bits altos de cada byte y metiendolos en el byte de ocho
posiciones antes. Con eso una tira de ocho glifos da cuatro filas de patron: la
letra sale al doble sin ocupar el doble en la ROM.

Efecto secundario medido: los rotulos de tipo 0 declaran 24 bytes de largo y
solo llevan 16 suyos; los ocho que faltan salen del bloque de detras. Los tres
bloques de 0x629E, 0x62B0 y 0x62BE se pisan asi, uno detras de otro.

## 6. La fuente se quedo sin X y sin Z, y la Q llego tarde

Los 51 glifos de 0x6002 empiezan ordenados: 0..9, el espacio, y luego el
alfabeto **de la A a la Y saltandose la Q, la X y la Z**. Con A en el indice
0x0B, la P cae en 0x1A y la siguiente, en 0x1B, ya es la R.

Y sin embargo **la Q existe**. Esta al final, en el indice **0x2C**, fuera del
alfabeto y entre los simbolos, y el motivo se ve en la unica palabra del juego
que la necesita: el rotulo **QUALIFY** del marcador, que en 0x5F88 es la tira
`2C 1E 0B 16 13 10 21`. Alguien monto el alfabeto sin las tres letras que no
hacian falta, y despues tuvo que anadir una.

X y Z no aparecen ni asi: ninguna palabra del cartucho las usa.

La hoja entera esta en `docs/imagenes/fuente.png`, y la dibuja
`tools/graficos.py` leyendo el rango que declara el listado. Esto es de lo que
solo se ve DIBUJANDO: leyendo el bloque, los 51 glifos son 408 bytes iguales.

## 7. Tres tablas indexadas desde uno

0x49BA avanza 2*0xE016 posiciones ANTES de leer, asi que la direccion que
registra el codigo cae dos bytes por delante de la primera casilla util. Pasa
lo mismo con la tabla de melodias (el codigo dice 0x6D26 y la tabla empieza en
0x6D28) y con la de fichas de actor (0x7B44 por 0x7B46). En el caso de la
tabla de pantallas, esos dos bytes de "casilla cero" son el 0xFF 0xFF que
cierra el ultimo mensaje del menu: dos bytes que sirven para dos cosas.

## 8. El piloto de la demo aporrea el boton al azar

La demo no lleva una partida grabada: la juega la interrupcion. Cuando 0xE002
vale 1, 0x4030 mete en 0xE00B un valor de `ld a,r` -el registro de refresco de
la memoria- enmascarado a dos bits, una vez cada cuatro cuadros. Eso es todo el
piloto: pulsaciones al azar.

OJO CON EL BIT 7 DE 0xE029. Da la impresion de ser el interruptor, porque
0x5849 lo pone y 0x4030 lo mira, pero MEDIDO en el emulador
(`medidas/demo.txt`) esta puesto igual en la demo y en una partida de verdad:
0xE029 vale 0x82 en las dos. El que manda es 0xE002, que vale 1 en la demo y 0
en partida, y es lo primero que mira la interrupcion. En partida las
pulsaciones inventadas no llegan nunca a 0xE00B.

## 9. Los dos atletas se mueven en cuadros alternos

0x51AD mira el bit 0 del contador de cuadros: en los pares mueve al atleta del
jugador 1 y en los impares al del 2. La mitad del trabajo por cuadro.

## 10. Los actores se empujan unos a otros

Las cuatro fichas de actor viven SEGUIDAS en 0xE120, 0xE130, 0xE140 y 0xE150.
El bit 2 de la ficha hace que el actor suba el contador de la ficha que tiene
0x11 bytes por detras, y el bit 3 el de la que tiene 0x0F por delante. Asi el
decorado se arrastra en cadena sin que nadie lleve una lista.

## 11. La marca oculta de Konami NO esta

El truco que destapo Manuel Pazos -el codigo RC-7xx y el titulo en katakana
escondidos detras del relleno del final de la ROM- no aparece en este
cartucho: el ultimo byte util es codigo del reproductor de sonido y solo queda
un 0xFF de relleno. Se comprobo con `tools/marca_konami.py`, que en el mismo
tiro SI la encuentra en Pippols (RC-729). Tampoco la llevan Time Pilot,
Frogger ni Athletic Land, asi que el cartucho no es raro por esto.

## 12. Este cartucho no se parece a ningun otro Konami de la serie

### El metodo

`tools/comun_konami.py`, que compara bytes crudos, solo encuentra una rutina
compartida si ademas cayo en la MISMA direccion. Para esto se escribio
`tools/comun_normalizado.py`: traza las dos ROM con sus desensamblados ya
hechos, decodifica las instrucciones, pone a cero los operandos de dieciseis
bits -que son los que llevan direcciones- y busca los tramos comunes sobre esa
tira. Asi una rutina reensamblada en otro sitio SI se ve.

Control, para saber que el metodo mide algo: Frogger contra Time Pilot, que ya
se sabia que comparten reproductor, da 667 bytes en 15 tramos (13,7 % de
Frogger, 7,5 % de Time Pilot). El metodo crudo daba 354.

### Las cifras

    contra                bytes en comun   % de Hyper Olympic 1   tramo mayor
    -------------------   --------------   --------------------   -----------
    Hyper Olympic 2                6.298                 67,5 %        63 B
    Frogger                          175                  1,9 %        21 B
    Super Cobra                      173                  1,9 %        21 B
    Athletic Land                    120                  1,3 %        21 B
    Billiards de Konami              105                  1,1 %        23 B
    Monkey Academy                   103                  1,1 %        20 B
    Pippols                           64                  0,7 %        20 B
    Time Pilot                        21                  0,2 %        21 B

### Lo que sale de ahi

Hyper Olympic 1 y 2 son el MISMO programa: dos tercios del codigo es comun. Con
cualquier otro cartucho Konami de MSX de la serie no comparten NADA: los tramos
mas largos son de veinte bytes, que es lo que dan por casualidad dos programas
escritos por la misma casa (un `ldir` de relleno, un bucle de espera). No hay
ni rastro del reproductor de sonido de Frogger y Time Pilot, ni del armazon de
Athletic Land.

O sea: los dos Hyper Olympic no pertenecen a ninguno de los dos armazones
Konami que ya estaban medidos en esta serie. Son un TERCERO, y de momento solo
tiene dos miembros.
