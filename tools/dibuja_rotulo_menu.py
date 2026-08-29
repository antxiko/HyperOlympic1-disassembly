#!/usr/bin/env python3
"""Dibuja el rotulo grande del menu, que es lo unico grafico que cambia.

Los patrones los sube el guion del titulo a 0x2100 y en adelante; los coloca el
guion del menu en las filas 3 a 6, columnas 12 a 21 de la tabla de nombres. Se
ejecutan los dos guiones y se pinta el trozo, en blanco sobre negro: aqui lo
que importa es la FORMA, no el color.

Uso: dibuja_rotulo_menu.py <rom> <guion_titulo> <fuente> <guion_menu> <sal.png>

NOTA DE DEPENDENCIA: esta es la unica herramienta de la serie que necesita
Pillow (`pip install pillow`). Las demas escriben el PNG a mano con zlib. Los
seis PNG que produce estan ya en docs/imagenes/, asi que solo hace falta para
volver a generarlos.
"""
import sys

from PIL import Image

from pinta_largo import ejecuta
from pinta_corto import pinta

E = 4          # escala
import os
COL0 = int(os.environ.get('C0', 12)); COL1 = int(os.environ.get('C1', 22))
FIL0 = int(os.environ.get('F0', 3)); FIL1 = int(os.environ.get('F1', 7))


def main():
    rom, gt, fu, gm, sal = (sys.argv[1], int(sys.argv[2], 0),
                            int(sys.argv[3], 0), int(sys.argv[4], 0), sys.argv[5])
    m, _ = ejecuta(rom, gt, fu)
    nombres, _, _, _ = pinta(open(rom, "rb").read(), gm)
    an, al = (COL1 - COL0) * 8, (FIL1 - FIL0) * 8
    im = Image.new("RGB", (an, al), (0, 0, 0))
    px = im.load()
    puestos = 0
    for f in range(FIL0, FIL1):
        for c in range(COL0, COL1):
            d = 0x3800 + f * 32 + c
            if d not in nombres:
                continue
            puestos += 1
            n = nombres[d]
            base = 0x2000 + (f // 8) * 0x800 + n * 8
            for y in range(8):
                b = m.vram.get(base + y, 0)
                for x in range(8):
                    if (b >> (7 - x)) & 1:
                        px[(c - COL0) * 8 + x, (f - FIL0) * 8 + y] = (255, 255, 255)
    im.resize((an * E, al * E), Image.NEAREST).save(sal)
    print("%s  %d celdas puestas" % (sal, puestos))


main()
