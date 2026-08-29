#!/usr/bin/env python3
"""Dibuja para la web los graficos que el cartucho lleva DENTRO.

Las imagenes de esta web no son ilustraciones traidas de fuera. Las dos que
salen de aqui se dibujan leyendo los propios bytes del cartucho, en el rango que
dice el listado, y son parte de la prueba de que la lectura del binario es
correcta: si el rango estuviera mal declarado, saldria ruido en vez de letras.

Y no se escribe aqui NINGUNA direccion a mano. El rango se busca por el NOMBRE
del bloque en las anotaciones (`D <inicio> <fin> <nombre> ...`), asi que si un
retrazado mueve la fuente, la imagen sigue saliendo bien sin tocar esto. Es la
misma regla que en el resto del proyecto: el listado manda.

Lo que dibuja:

  fuente.png   los 51 glifos de 8x8 con los que se escribe todo el cartucho,
               dieciseis por fila. Sirve para ver de un vistazo lo que se
               afirma en la web: que no hay Q, ni X, ni Z.

El resto de las imagenes de la web son capturas de openMSX y no se hacen aqui:
los patrones del atleta van comprimidos con rachas de ceros y se solapan entre
figuras, asi que dibujarlos en crudo no ensenaria un atleta, ensenaria trozos.

Uso: graficos.py <rom> <org> <notas> <docs/imagenes>
"""
import os
import re
import struct
import sys
import zlib

FONDO = (0x20, 0x20, 0x30)
TINTA = (0xF0, 0xF0, 0xE0)
REJA = (0x38, 0x38, 0x4A)


def png(w, h, px, fn):
    raw = b"".join(b"\0" + bytes(px[y * w * 3:(y + 1) * w * 3]) for y in range(h))

    def chunk(t, d):
        return (struct.pack(">I", len(d)) + t + d
                + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF))
    with open(fn, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n"
                + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


def rango_por_nombre(notas, nombre):
    """El (inicio, fin) del bloque de datos que se llama asi, del .notes."""
    for linea in open(notas, encoding="utf-8"):
        m = re.match(r"^D\s+0x([0-9A-Fa-f]+)\s+0x([0-9A-Fa-f]+)\s+(\S+)", linea)
        if m and m.group(3) == nombre:
            return int(m.group(1), 16), int(m.group(2), 16)
    raise SystemExit("  no hay ningun bloque llamado %r en %s" % (nombre, notas))


def hoja_de_glifos(rom, org, ini, fin, cols=16, esc=3, margen=1):
    """Los glifos de 8x8 del rango, en una rejilla de `cols` columnas."""
    n = (fin - ini) // 8
    filas = (n + cols - 1) // cols
    celda = 8 * esc + margen
    w, h = cols * celda + margen, filas * celda + margen
    px = bytearray(bytes(REJA) * (w * h))

    def pon(x, y, c):
        if 0 <= x < w and 0 <= y < h:
            i = (y * w + x) * 3
            px[i:i + 3] = bytes(c)

    for k in range(n):
        gx = margen + (k % cols) * celda
        gy = margen + (k // cols) * celda
        datos = rom[ini - org + k * 8: ini - org + k * 8 + 8]
        for f in range(8):
            v = datos[f] if f < len(datos) else 0
            for c in range(8):
                col = TINTA if (v >> (7 - c)) & 1 else FONDO
                for a in range(esc):
                    for b in range(esc):
                        pon(gx + c * esc + b, gy + f * esc + a, col)
    return w, h, px


def main(argv):
    if len(argv) < 5:
        print(__doc__)
        return 2
    rom = open(argv[1], "rb").read()
    org = int(argv[2], 0)
    notas, destino = argv[3], argv[4]
    os.makedirs(destino, exist_ok=True)

    ini, fin = rango_por_nombre(notas, "fuente")
    w, h, px = hoja_de_glifos(rom, org, ini, fin)
    salida = os.path.join(destino, "fuente.png")
    png(w, h, px, salida)
    print("  fuente.png: %d glifos de 0x%04X a 0x%04X, %dx%d"
          % ((fin - ini) // 8, ini, fin, w, h))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
