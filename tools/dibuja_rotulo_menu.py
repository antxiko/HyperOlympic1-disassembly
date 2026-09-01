#!/usr/bin/env python3
"""Dibuja el rotulo grande del menu, que es lo unico grafico que cambia.

Los patrones -Y SUS COLORES- los sube el guion del titulo; las casillas las
coloca el guion del menu. Se ejecutan los dos y se pinta lo que queda, leyendo
la VRAM como la lee el VDP en SCREEN 2: patrones en 0x2000 y colores en 0x0000,
cada uno con sus tres tercios.

EL COLOR NO SE INVENTA NI SE OMITE. El rotulo de estos cartuchos no es blanco:
sus tiles llevan 0x60, 0x80, 0x90, 0xA0 y 0xF0, o sea rojo oscuro, rojo claro,
rojo vivo, amarillo oscuro y blanco sobre papel transparente, que es el
degradado que se ve en la captura de titulo.png. Una version anterior de esta
herramienta pintaba todo en blanco "porque lo que importa es la forma"; no
importaba solo la forma.

EL RECORTE TAMPOCO SE PONE A MANO. Antes venia de variables de entorno, y por
eso los PNG salieron cada uno de un tamano. Ahora se mide: el guion del menu
escribe el rotulo con los tiles de dibujo -por debajo de 0x80- y el copyright y
el PLAY SELECT con los glifos de la fuente -de 0x80 arriba-, asi que el marco
de los tiles bajos ES el del rotulo. Con `todo` se toman todas las casillas
escritas, que es lo que hace falta cuando el guion es un rotulo de texto.

Uso: dibuja_rotulo_menu.py <rom> <guion_titulo> <fuente> <guion_menu> <sal.png>
                           [rotulo|todo] [escala]

NOTA DE DEPENDENCIA: esta es la unica herramienta de la serie que necesita
Pillow (`pip install pillow`).
"""
import sys

from PIL import Image

from pinta_largo import ejecuta
from pinta_corto import pinta

# La paleta del TMS9918 tal como la miden las tablas al uso.
PALETA = [
    (0, 0, 0), (0, 0, 0), (62, 184, 73), (116, 208, 125),
    (89, 85, 224), (128, 118, 241), (185, 94, 81), (101, 219, 239),
    (219, 101, 89), (255, 137, 125), (204, 195, 94), (222, 208, 135),
    (58, 162, 65), (183, 102, 181), (204, 204, 204), (255, 255, 255),
]

NOMBRES = 0x3800
PATRONES = 0x2000
COLORES = 0x0000


def celdas(nombres, que):
    """Las casillas de la tabla de nombres que interesan, y su marco."""
    tope = 0x80 if que == "rotulo" else 0x100
    c = {d: n for d, n in nombres.items()
         if NOMBRES <= d < NOMBRES + 0x300 and 0 < n < tope}
    if not c:
        raise SystemExit("  el guion no escribe ninguna casilla con tile < %#04x"
                         % tope)
    sitios = [((d - NOMBRES) // 32, (d - NOMBRES) % 32) for d in c]
    return c, (min(f for f, _ in sitios), max(f for f, _ in sitios),
               min(x for _, x in sitios), max(x for _, x in sitios))


def main():
    rom, gt, fu, gm, sal = (sys.argv[1], int(sys.argv[2], 0),
                            int(sys.argv[3], 0), int(sys.argv[4], 0), sys.argv[5])
    que = sys.argv[6] if len(sys.argv) > 6 else "rotulo"
    esc = int(sys.argv[7]) if len(sys.argv) > 7 else 4

    m, _ = ejecuta(rom, gt, fu)
    nombres, _, _, _ = pinta(open(rom, "rb").read(), gm)
    puestas, (f0, f1, c0, c1) = celdas(nombres, que)

    an, al = (c1 - c0 + 1) * 8, (f1 - f0 + 1) * 8
    im = Image.new("RGB", (an, al), (0, 0, 0))
    px = im.load()
    for f in range(f0, f1 + 1):
        tercio = (f // 8) * 0x800
        for c in range(c0, c1 + 1):
            n = puestas.get(NOMBRES + f * 32 + c)
            if n is None:
                continue
            for y in range(8):
                linea = m.vram.get(PATRONES + tercio + n * 8 + y, 0)
                color = m.vram.get(COLORES + tercio + n * 8 + y, 0)
                tinta, papel = PALETA[color >> 4], PALETA[color & 15]
                for x in range(8):
                    px[(c - c0) * 8 + x, (f - f0) * 8 + y] = (
                        tinta if (linea >> (7 - x)) & 1 else papel)
    im.resize((an * esc, al * esc), Image.NEAREST).save(sal)
    print("%s  %d casillas, filas %d-%d columnas %d-%d, %dx%d"
          % (sal, len(puestas), f0, f1, c0, c1, an * esc, al * esc))


if __name__ == "__main__":
    main()
