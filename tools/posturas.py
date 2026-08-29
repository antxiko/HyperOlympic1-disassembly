#!/usr/bin/env python3
"""Recorre la tabla de posturas del atleta y los patrones de sprite que gasta.

0x7F86 lee 0x702E+2*postura y saca un registro: [cuantos trozos][puntero]*N
[puntero a la lista de atributos]. Cada puntero apunta a 32 bytes de patron de
sprite comprimidos con la racha de ceros de 0x5A78 ([0x00][cuantos]).

Uso: posturas.py <rom> <org> <tabla> <primera> <ultima> [<tabla2> <a> <b> ...]
"""
import sys

rom = open(sys.argv[1], "rb").read()
ORG = int(sys.argv[2], 0)
b = lambda a: rom[a - ORG] if 0 <= a - ORG < len(rom) else None
w = lambda a: b(a) | (b(a + 1) << 8)

marcas = {}


def patron(p):
    """32 bytes de patron comprimido. Devuelve el fin."""
    c = 0x20
    for _ in range(64):
        if c <= 0:
            break
        v = b(p)
        if v is None:
            break
        if v == 0:
            c -= b(p + 1)
            p += 2
        else:
            c -= 1
            p += 1
    return p


def registro(p):
    n = b(p)
    q = p + 1
    for _ in range(n):
        d = w(q)
        if ORG <= d < ORG + len(rom):
            marcas[d] = (patron(d), "patron")
        q += 2
    at = w(q)
    q += 2
    if ORG <= at < ORG + len(rom):
        marcas[at] = (at + 4 * 7, "atributos")
    marcas[p] = (q, "registro de %d trozos" % n)
    return q


args = sys.argv[3:]
while args:
    modo, tab, a, z = args[0], int(args[1], 0), int(args[2], 0), int(args[3], 0)
    args = args[4:]
    marcas[tab + 2 * a] = (tab + 2 * z + 2, "tabla")
    for i in range(a, z + 1):
        d = w(tab + 2 * i)
        if ORG <= d < ORG + len(rom):
            if modo == "reg":
                registro(d)
            else:
                marcas[d] = (patron(d), "patron")

for a in sorted(marcas):
    f, q = marcas[a]
    print("    %-22s %04X..%04X  (%d B)" % (q, a, f - 1, f - a))
print()
ini = min(marcas)
fin = max(f for f, _ in marcas.values())
h = None
for i in range(ini, fin):
    dentro = any(a <= i < f for a, (f, _) in marcas.items())
    if not dentro and h is None:
        h = i
    elif dentro and h is not None:
        print("    hueco %04X..%04X (%d B)" % (h, i - 1, i - h))
        h = None
if h is not None:
    print("    hueco %04X..%04X (%d B)" % (h, fin - 1, fin - h))
