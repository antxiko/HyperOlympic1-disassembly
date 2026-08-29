# Lo que queda sin cerrar, contado uno a uno

El presupuesto esta al 100 %: los 16.384 bytes del cartucho estan repartidos
entre codigo trazado (9.335) y rangos de datos con nombre (7.049), y
`make sanity` lo comprueba. Lo que sigue no son bytes sin repartir, sino cosas
que se explican con menos certeza de la que me gustaria.

## 1. Doce bytes muertos en 0x4E7B

`00 70 38 70 / 00 A0 38 70 / 00 F0 38 F0`. Tienen la forma de tres filas de la
tabla de atributos de sprite (fila, columna, patron, color), y estan pegados a
los ocho registros del VDP. NADIE los lee: 0x410C solo sube ocho bytes, y
ningun puntero de la ROM cae ahi. Estan tambien, byte a byte iguales y igual de
muertos, en Hyper Olympic 2 (en 0x4E64). SUPOSICION: son restos de una version
anterior que subia tres sprites al arrancar.

## 2. Los rotulos de tipo 0 que se pisan

0x629E, 0x62B0 y 0x62BE declaran 24 bytes de largo y solo llevan 16 suyos. El
decodificador (0x4C63) sigue leyendo y se lleva los ocho primeros del bloque
siguiente. Eso esta MEDIDO en el codigo -el byte de longitud es 0x18 y la
cuenta baja una vez por byte de salida-, pero no se ha comprobado en la VRAM
que los ocho bytes prestados sean los que el dibujo necesita. SUPOSICION: el
ahorro es deliberado, porque esos ocho ultimos bytes solo aportan bits a la
tercera pasada de 0x4CAB.

## 3. Los dos patrones de 0x6222 se solapan en un byte

El segundo empieza en el ultimo byte del primero. Es lo que dicen los punteros
del guion; no se ha comprobado en pantalla que el resultado sea el que se
espera.

## 4. Las melodias no estan despiezadas nota a nota

El bloque 0x6D76-0x702D esta recorrido entero desde la tabla de punteros y no
queda un byte suelto, pero el listado lo publica como un solo rango de datos.
Sacar cada melodia con su nombre haria falta para poder oirlas por separado.

## 5. Que hace exactamente cada bit de 0xE02E

Los bits 0, 1 y 2 estan claros (intento acabado, prueba acabada, tiempo
agotado) porque hay codigo que los pone y codigo que los mira. Los bits 3, 5, 6
y 7 se usan dentro del motor de la carrera y estan comentados por lo que hacen
en cada sitio, pero no se les ha puesto un nombre unico.

## 6. Los 31 rotulos de letra grande van por direccion

Los bloques de 0x619A a 0x6361 estan delimitados por el recorrido de los
guiones, pero solo cuatro tienen nombre propio: los de las cuatro pruebas. Los
demas se publican como `rotulo_XXXX`. Para bautizarlos habria que dibujarlos
uno a uno.
