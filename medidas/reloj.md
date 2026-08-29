# El reloj del juego esta calculado para 60 Hz

0x5695 suma al contador BCD de 0xE0A9-0xE0AB una vez por cuadro, alternando
0x0167 y 0x0166. Si el byte de arriba son segundos y el de en medio
centesimas, eso es 1,67 y 1,66 centesimas: media 1,665, que es un sesentavo de
segundo con cuatro cifras.

Medido corriendo los 100 metros con `tools/omsx_reloj.tcl`, que machaca el
espacio y muestrea 0xE0A9-0xE0AB una vez por segundo emulado:

    maquina                    Hz    reloj del juego por segundo real
    ------------------------   --    --------------------------------
    Philips VG-8020 (PAL)      50    0,8325 s   (se queda un 16,75 % corto)
    C-BIOS MSX1 JP (NTSC)      60    0,9990 s   (clavado)

Las dos cifras salen de restar dos muestras seguidas de las tablas de
`reloj_pal.txt` y `reloj_ntsc.txt`, y coinciden con la cuenta: 50 x 1,665 =
83,25 y 60 x 1,665 = 99,9.

CONSECUENCIA: en un MSX europeo los tiempos que ensena el cartucho no son
segundos. Un 100 metros cronometrado en 12,00 por el juego ha durado 14,4
segundos de verdad. Las marcas de clasificacion de 0x5008 y los records del
mundo de 0x5174 estan pensados para la maquina japonesa.
