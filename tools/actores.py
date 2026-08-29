#!/usr/bin/env python3
"""Recorre las fichas de actor y las figuras que dibujan, y dice donde acaban.

Una ficha son 16 bytes que 0x7B4E copia a la RAM descomprimiendo las rachas de
ceros ([0x00][cuantos]). Las cadenas de fichas acaban en 0xFF. En +0x0D/+0x0E
lleva el puntero a la FIGURA, que 0x7A1F expande a la tira de codigos de
caracter de 0xE230: 0x00 repite un codigo, 0x01 lo repite subiendo de uno en
uno, 0x02 cambia el desplazamiento, 0xFF acaba la fila y 0xFF 0xFF la figura.

Uso: actores.py <rom> <org> <ficha> [<ficha> ...]
"""
import sys

rom = open(sys.argv[1], "rb").read()
ORG = int(sys.argv[2], 0)
b = lambda a: rom[a - ORG] if 0 <= a - ORG < len(rom) else None
w = lambda a: b(a) | (b(a + 1) << 8)

marcas = {}


def marca(a, f, que):
    marcas[a] = (f, que)


def figura(p):
    ini = p
    for _ in range(2000):
        v = b(p)
        if v is None:
            return p
        if v in (0x00, 0x01):
            p += 3
        elif v == 0x02:
            p += 2
        elif v == 0xFF:
            p += 1
            if b(p) == 0xFF:
                return p + 1
        else:
            p += 1
    return p


def ficha(p):
    """Una ficha comprimida de 16 bytes. Devuelve (fin, puntero_a_figura)."""
    ini, c, out = p, 16, []
    for _ in range(40):
        if c <= 0:
            break
        v = b(p)
        if v == 0:
            n = b(p + 1)
            out += [0] * n
            c -= n
            p += 2
        else:
            out.append(v)
            c -= 1
            p += 1
    return p, (out[0x0D] | (out[0x0E] << 8)), (out[0x09] | (out[0x0A] << 8))


def una(p):
    """Una ficha y todo lo que cuelga: su figura y la ficha que la releva."""
    if p in marcas:
        return None
    f, fig, sig = ficha(p)
    marca(p, f, "ficha")
    if ORG <= fig < ORG + len(rom):
        marca(fig, figura(fig), "figura")
    if ORG <= sig < ORG + len(rom):
        una(sig)
    return f


def cadena(p):
    n = 0
    while b(p) != 0xFF:
        f = una(p)
        if f is None:
            f, _fg, _sg = ficha(p)
        p = f
        n += 1
        if n > 60:
            break
    return p + 1, n


for s in sys.argv[3:]:
    a = int(s, 0)
    f, n = cadena(a)
    print("  cadena %04X..%04X  %d fichas" % (a, f - 1, n))

print()
for a in sorted(marcas):
    f, q = marcas[a]
    print("    %-7s %04X..%04X  (%d B)" % (q, a, f - 1, f - a))
