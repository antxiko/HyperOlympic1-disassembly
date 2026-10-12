# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`MUEVE_EL_SONIDO`, 0x6B1A, y `PIDE_UN_SONIDO`, 0x6A92, que le reparte los canales; lo llama la interrupción en 0x404C) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la música del título (0x96) entera, 642 cuadros;
- la pista 0x91 entera, 511 cuadros, con su vuelta.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`PIDE_UN_SONIDO` recibe el número en A y no suena en la demo. Los efectos van por debajo de 0x81 y tienen una, dos o tres voces según su número; de 0x81 a 0x95 la música usa dos voces y del 0x96 en adelante tres. Las fichas de los canales están en 0xE162, 0xE16D y 0xE178. Las 0x91, 0x95, 0xA8 y 0xA9 son pistas de la tabla que ninguna rutina pide con un `ld a`. El motor no escribe el mezclador del PSG: lo deja el arranque, y aquí se parte de su mismo valor, 0xB8.

## Las músicas

**La música del título** (0x96)

Lo pide `TITULO_SIN_PARPADEO`; dura 10,7 s.

<audio controls preload="none" src="../audio/musica_96.mp3?v=918f6723"></audio>

**La fanfarria de clasificación** (0x02)

Lo pide la rutina de 0x451F; `PIDE_UN_SONIDO` lo reparte en tres: el 2, el 0x47 y el 0x49; dura 4,1 s.

<audio controls preload="none" src="../audio/musica_02.mp3?v=741888b0"></audio>

**Récord nuevo** (0x99)

Lo pide `GUARDA_EL_RECORD_NUEVO`; dura 4,0 s.

<audio controls preload="none" src="../audio/musica_99.mp3?v=37ff5580"></audio>

**La prueba nueva** (0x9C)

Lo pide `SUENA_LA_PRUEBA_NUEVA`; dura 2,0 s.

<audio controls preload="none" src="../audio/musica_9C.mp3?v=4f4a6ddd"></audio>

**El cartel de fin** (0x9F)

Lo pide `CARTEL_DE_FIN`; dura 3,0 s.

<audio controls preload="none" src="../audio/musica_9F.mp3?v=d0f0f403"></audio>

**La música que se espera** (0x92)

Lo pide `ESPERA_A_QUE_ACABE_LA_MUSICA`; dura 1,0 s.

<audio controls preload="none" src="../audio/musica_92.mp3?v=307ac8b2"></audio>

**Una pista de la tabla** (0x91)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 8,5 s y vuelve a empezar en el segundo 4,3.

<audio controls preload="none" src="../audio/musica_91.mp3?v=1e36a5c0"></audio>

**Otra pista de la tabla** (0x95)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 17,1 s y vuelve a empezar en el segundo 12,8.

<audio controls preload="none" src="../audio/musica_95.mp3?v=fddbaa8f"></audio>

**Una tercera pista de la tabla** (0xA8)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 21,3 s y vuelve a empezar en el segundo 17,1.

<audio controls preload="none" src="../audio/musica_A8.mp3?v=d0e5aef3"></audio>

**Una cuarta pista de la tabla** (0xA9)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 13,9 s.

<audio controls preload="none" src="../audio/musica_A9.mp3?v=3f01504c"></audio>
