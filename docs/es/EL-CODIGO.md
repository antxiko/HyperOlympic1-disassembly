# El código

Dieciséis kilobytes repartidos en 9.335 bytes de código y 7.049 de datos. No
hay ningún cambio de banco ni ningún truco de carga: el programa entero está a
la vista entre 0x4000 y 0x7FFF, y esta página cuenta cómo está montado.

## Dos hilos que se reparten el trabajo

El cartucho tiene un programa principal y una interrupción, y la frontera entre
los dos es nítida.

**La interrupción** (`INTERRUPCION`, 0x4010) entra por el gancho H.KEYI que
INIT rellena con un `jp`, y hace todo lo que tiene que ir a ritmo de pantalla:
lee los mandos, mueve el reproductor de sonido, cuenta el reloj y llama al
motor de la prueba que se esté jugando. Es donde ocurre el juego.

**El principal** lleva la máquina de estados: montar el decorado, esperar a que
acabe el intento, repartir puntos, pasar de ronda. Casi siempre está esperando
a que la interrupción le ponga un bit.

El reparto tiene una consecuencia bonita: si paras el programa principal, el
atleta sigue corriendo.

## La vida de una prueba

`MONTA_LA_PRUEBA` (0x4234) es la cabecera de todo lo que pasa entre dos
pruebas. El recorrido es siempre el mismo:

1. `MONTA_EL_DECORADO` (0x4253) pide el guion de pantalla que le toque a esta
   prueba y lo interpreta;
2. `MONTA_LOS_ACTORES_DE_LA_PRUEBA` (0x7B2C) copia las fichas de actor de la
   tabla de la ROM a la RAM;
3. `EMPIEZA_EL_INTENTO` (0x4296) coloca a los atletas y suelta el semáforo;
4. `BUCLE_DE_LA_PRUEBA` (0x4396) se queda mirando 0xE02E hasta que la
   interrupción diga que el intento se acabó;
5. `PUNTUA_EL_INTENTO` (0x4F4D) convierte la marca en puntos;
6. `MIRA_SI_SE_ACABO_LA_PRUEBA` (0x45A1) decide si hay otro intento, otro
   jugador, otra ronda o se acabó la partida.

Los puntos merecen una nota, porque el cálculo cambia de signo según la prueba:
salen de la diferencia entre la marca y una referencia fija por prueba
(0x5020). **En las pruebas de tiempo la referencia está arriba** y se le resta
la marca —cuanto menos tardas, más puntos—; **en las de distancia está abajo** y
es la marca la que le gana. Después se multiplica por dieciséis, y en las
pruebas impares se dobla otra vez.

## Cuatro motores, y uno hace de dos

Cada prueba tiene su motor, y la interrupción llama al que toque:

| prueba | motor | qué hace |
|---|---|---|
| 100 y 400 metros | `MOTOR_DE_LA_CARRERA` (0x5180) | correr, la separación entre los dos y la llegada |
| longitud | `MOTOR_DEL_SALTO` (0x668F) | la carrera, la batida, el vuelo y la caída |
| martillo | `MOTOR_DEL_MARTILLO` (0x68B3) | las vueltas, el ángulo y el vuelo |

El de la carrera vale para las dos pruebas de tiempo tal cual, y además **el
salto de longitud reaprovecha su carrera**: lo propio del salto es la batida y
lo que pasa después.

Y hay un cuarto trozo que no es un motor pero se comporta como si lo fuera:
`AVANZA_EL_TIRO` (0x7D2C), que calcula el vuelo. Lo usan el salto y el martillo,
y es lo único del cartucho que hace cuentas de verdad.

## La única cuenta de verdad

`CALCULA_EL_TIRO` (0x7D39) coge la velocidad de carrera y el ángulo y saca de
ahí el avance y la altura de cada cuadro, y al final la marca en metros. Para
eso hay tres rutinas de aritmética escritas a mano, porque el Z80 no trae
ninguna:

- `DIVIDE` (0x7E76), desplazando y restando;
- `MULTIPLICA` (0x7E94), desplazando y sumando;
- `PASA_A_BCD` (0x7EB8), que convierte un número binario a BCD doblándolo en
  BCD, bit a bit, para poder imprimirlo.

Y el seno sale de una tabla, `EL_SENO_DEL_ANGULO` (0x7E54): un byte por grado.
Nada de aproximaciones en tiempo real.

El resto del cartucho no calcula: consulta tablas o suma en BCD directamente,
que es como se llevan las marcas y los marcadores sin tener que convertir nada
para pintarlo.

## El cartucho no guarda pantallas: guarda guiones

Ninguna pantalla está dibujada en la ROM tal cual. Lo que hay son **guiones**, y
cuatro intérpretes distintos que los leen, cada uno con su formato:

**El guion largo** (`GUION_LARGO`, 0x4D09) es el gordo: un byte con el número de
órdenes y detrás las órdenes, cada una empezando por su tipo.

| tipo | qué hace |
|---|---|
| 0 | bytes a VRAM, con 0x11 como marca de racha (RLE) |
| 1 | tiras de glifos de la fuente, subidos como patrón |
| 2 | rótulos de letra grande |
| 3 | rellenos de un byte |
| 4+ | repetir un patrón de ocho bytes N veces |

**El guion corto** (`GUION_CORTO`, 0x4AFE) es para textos sueltos, como los del
menú. **El rótulo** (`LLENA_EL_PAPEL`, 0x4C63) prepara un texto que después se
estira a letra grande. Y **la figura** (`MONTA_LA_FIGURA`, 0x7A1F) expande la
descripción de un actor a códigos de carácter.

Los 2,5 KB que van de 0x5C96 a 0x668E son enteramente guiones y datos de guion,
y un recorrido desde las raíces los cubre sin dejar un byte suelto.

## Las letras grandes se fabrican

Un rótulo de letra grande no está dibujado en ningún sitio: se monta al vuelo.
`MONTA_UN_ROTULO` (0x4C49) copia los glifos **normales** de 8x8 a un papel en
0xE230, y luego `ESTIRA_LAS_LETRAS` (0x4CAB) da **tres pasadas** que van sacando
los dos bits altos de cada byte y metiéndolos en el byte de ocho posiciones
antes.

Con eso una fila de ocho glifos da cuatro filas de patrón: la letra sale al
doble de tamaño sin ocupar el doble en la ROM. El precio está contado en
[Preguntas abiertas](PREGUNTAS-ABIERTAS.md): tres rótulos declaran veinticuatro
bytes de largo y solo llevan dieciséis suyos, así que se llevan ocho del bloque
de detrás.

## Escribir en el VDP sin que la interrupción lo pise

Este es el detalle más fino del cartucho, y hay cuatro rutinas dedicadas a él
(`FIJA_ESCRITURA_CON_CANDADO` 0x4DFC, `FIJA_LECTURA` 0x4E14, `FIJA_ESCRITURA`
0x4E25 y las que las usan).

El problema: fijar una dirección en el VDP son **dos escrituras seguidas** al
puerto de control, y la interrupción también escribe en el VDP. Si se cuela
entre las dos, la dirección que queda puesta es la suya, y lo que venga detrás
se escribe en el sitio equivocado.

La solución no es prohibir la interrupción, sino **darse cuenta**:

1. se borra 0xE01D;
2. se fija la dirección;
3. se mira 0xE01D: si la interrupción ha entrado por en medio, lo habrá puesto,
   y entonces se repite.

Es más barato que apagar y encender las interrupciones en cada escritura, y no
pierde ni un cuadro. El otro semáforo, 0xE01E, es el candado de verdad: cuando
está puesto, la interrupción se va sin tocar nada.

## El reproductor de sonido

Tres canales, once bytes de ficha cada uno, en 0xE160, 0xE16B y 0xE176:

| desplazamiento | qué es |
|---|---|
| +0 | cuenta de la nota |
| +1 | duración base |
| +2 | número de sonido |
| +3/+4 | puntero a la tira |
| +5 | octava |
| +6 | caída |
| +7 | volumen |
| +8 | cuenta de la caída |
| +9 | repeticiones que quedan |
| +0x0A | duración |

Lo interesante es **el número de sonido**, que lleva la información en sus bits
altos: el bit 7 dice que la nota va en un solo byte, el bit 6 que el canal 3 se
usa como ruido, y **los seis de abajo son la prioridad**. `MIRA_LA_PRIORIDAD`
(0x6AE8) es lo que impide que el pitido de una tecla se cargue la música de
final de prueba: un sonido no interrumpe a otro de prioridad más alta.

`DOBLA_LA_MELODIA` (0x6B7E) hace lo que dice: reproduce la misma tira una octava
por encima o por debajo, que es como se consigue que suene a dos voces sin
gastar otra.

## Los actores

Un actor es una ficha de dieciséis bytes en RAM, y hay cuatro: 0xE120, 0xE130,
0xE140 y 0xE150.

| desplazamiento | qué es |
|---|---|
| +0 | banderas |
| +1 | cuenta |
| +2 | escalón |
| +6 | columna dentro de la figura |
| +7/+8 | dirección de VRAM |
| +9/+0A | la ficha que le releva |
| +0B | fila de la tabla de ajuste |
| +0C | columna calculada |
| +0D/+0E | la figura |
| +0F | cuántos caracteres se pintan |

Las cuatro fichas van **seguidas** en memoria, y de ahí sale el truco:
`MIRA_SI_EMPUJA_AL_DE_DETRAS` (0x79CF) mira el bit 2 y el bit 3 de las banderas
y, según cuál esté puesto, suma o resta 0x11 al puntero para subir el contador
de la ficha vecina.

Así el decorado se arrastra en cadena sin que nadie lleve una lista de quién
empuja a quién: **la relación está en la distancia entre las fichas**.

## El atleta son siete sprites

`FICHA_DEL_QUE_JUEGA` (0x7F52) y lo que hay debajo montan al corredor. No es un
sprite: son **siete**, y cada postura los coloca a mano.

`SUBE_LOS_PATRONES` (0x7F9C) sube a VRAM los patrones que hagan falta para la
postura, y después `UN_SPRITE_DEL_ATLETA` (0x7FD5) escribe las siete filas de la
tabla de atributos, sumando a cada una la fila y la columna donde está el
atleta. Cambiar de postura es cambiar los patrones; mover al atleta es sumar a
las siete filas.

## Cómo leerlo

El listado se genera; no se edita a mano. Los comentarios viven aparte, en
`src/hyperolympic1.notes`, anclados a la dirección que describen, y `make
listado` los pega donde toca. Eso quiere decir que si mañana el trazador
reparte el binario de otra forma, los comentarios siguen cayendo en su sitio.

Las direcciones de VRAM aparecen en el listado **con el bit 14 puesto** (sumado
0x4000) cuando se va a escribir, que es como lo pide el VDP. Por eso la tabla de
nombres, que está en 0x3800, se ve escrita como 0x7800.
