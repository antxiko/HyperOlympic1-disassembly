#!/usr/bin/env python3
"""Recorre las melodias del reproductor PSG y dice donde acaba cada una.

La tabla de punteros esta en 0x6D28 y se indexa DESDE UNO (el codigo registra
0x6D26, dos bytes antes, el mismo truco que las tablas de pantalla). El indice
sale del numero de sonido: por debajo de 0x81 es `id & 0x3F`; por encima, el
`add a,a` pierde el acarreo y queda `id & 0x7F`. Un sonido de varias voces
ocupa entradas SEGUIDAS.

Las tiras terminan en 0xFF; un 0xFE con su cuenta detras vuelve a empezar. Los
sonidos con el bit 7 puesto llevan la nota en UN byte (nibble alto = nota en la
tabla de doce periodos de 0x6D1C, nibble bajo = cuantas duraciones); los demas
la llevan en DOS (nibble alto = duracion, los doce bits restantes = periodo).

Uso: musica.py <rom> <org>
"""
import sys

rom = open(sys.argv[1], "rb").read()
ORG = int(sys.argv[2], 0)
TAB = 0x6D28
b = lambda a: rom[a - ORG] if 0 <= a - ORG < len(rom) else None
w = lambda a: b(a) | (b(a + 1) << 8)

IDS = [0x01, 0x02, 0x04, 0x43, 0x45, 0x47, 0x48, 0x49, 0x4A, 0x4C, 0x4F,
       0x92, 0x96, 0x99, 0x9C, 0x9F, 0xA5]


def voces(a):
    if a == 1:
        return 2
    if a >= 0x96:
        return 3
    if a >= 0x81:
        return 2
    t = a & 0x3F
    return 1 if t < 0x0A else (2 if t < 0x0C else 3)


def indice(a):
    return 1 if a == 1 else (a & 0x7F if a >= 0x81 else a & 0x3F)


def tira(p, compacta):
    """Fin de una tira de melodia y por que acaba."""
    for _ in range(3000):
        v = b(p)
        if v is None:
            return p, "SE SALE"
        if v == 0xFF:
            return p + 1, "fin"
        if v == 0xFE:
            return p + 2, "repite"
        if compacta:
            while b(p) is not None and b(p) >= 0xD0:
                p += 1
            p += 1
        else:
            if (v & 0xF0) == 0x20:
                p += 1
                v = b(p)
            if (v & 0xF0) == 0x10:
                p += 1
            p += 2
    return p, "?"


def main():
    ent = {}
    for i in IDS:
        for k in range(voces(i)):
            ent[indice(i) + k] = (w(TAB + 2 * (indice(i) + k - 1)), i & 0x80)
    usado = bytearray(len(rom))
    res = {}
    for k in sorted(ent):
        d, comp = ent[k]
        f, m = tira(d, comp)
        for x in range(d, f):
            if 0 <= x - ORG < len(rom):
                usado[x - ORG] = 1
        res.setdefault((d, f, m), []).append(k)
    for (d, f, m), ks in sorted(res.items()):
        print("  %04X..%04X %4dB %-7s entradas %s"
              % (d, f - 1, f - d, m, ks))
    lo = min(d for d, _, _ in res)
    hi = max(f for _, f, _ in res)
    print("\n  cubierto %04X..%04X" % (lo, hi - 1))
    h = None
    for i in range(lo, min(hi, ORG + len(rom))):
        if not usado[i - ORG] and h is None:
            h = i
        elif usado[i - ORG] and h is not None:
            print("    hueco %04X..%04X (%d B)" % (h, i - 1, i - h))
            h = None
    if h is not None:
        print("    hueco %04X..%04X (%d B)" % (h, hi - 1, hi - h))


main()
