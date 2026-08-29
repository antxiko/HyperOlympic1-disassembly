#!/usr/bin/env python3
"""Recorre los dos formatos de guion de pantalla del cartucho y dice hasta
donde llega cada uno. Sin esto, los 2,5 KB de 0x5C96 son un mazacote.

  - guion largo  (lo lee 0x4D09): [N] y N ordenes de cinco tipos.
  - guion corto  (lo lee 0x4AFE): [dir][bytes..][0xFE n b]*[0xFF] y otro
                                  bloque detras, hasta un 0xFF suelto.

Uso: guion.py <rom> <org> largo|corto <dir> [<dir> ...]
"""
import sys

rom = open(sys.argv[1], "rb").read()
ORG = int(sys.argv[2], 0)
B = lambda a: rom[a - ORG]
W = lambda a: B(a) | (B(a + 1) << 8)


def largo(p, prof=0):
    ini = p
    n = B(p); p += 1
    salida = [f"{ini:04X}  guion de {n} ordenes"]
    k = 0
    for _ in range(n):
        k += 1
        op = B(p); p += 1
        o = p - 1
        if op == 0:                                   # bytes a VRAM, con RLE 0x11
            m = B(p); p += 1
            for _ in range(m):
                dst = (B(p) << 8) | B(p + 1); p += 2
                c = B(p) or 256; c0 = c; p += 1
                while c:
                    v = B(p)
                    if v == 0x11:
                        rep = B(p + 1) or 256
                        p += 3
                        c -= min(rep, c)
                    else:
                        p += 1; c -= 1
                salida.append(f"   {k:2d}  op0 VRAM {dst&0x3FFF:04X}  {c0} bytes")
        elif op == 1:                                 # tiras de glifos de la fuente
            m = B(p)
            for _ in range(m):
                p += 1
                dst = (B(p) << 8) | B(p + 1); p += 2
                while B(p) != 0xFF:
                    p += 1
                salida.append(f"      op1 VRAM {dst&0x3FFF:04X} (glifos)")
            p += 1
        elif op == 2:                                 # letras grandes
            m = B(p); p += 1
            dst = (B(p) << 8) | B(p + 1); p += 2
            for _ in range(m):
                q = W(p); p += 2
                salida.append(f"      op2 VRAM {dst&0x3FFF:04X} <- {q:04X}")
        elif op == 3:                                 # relleno de un byte
            m = B(p); p += 1
            dst = (B(p) << 8) | B(p + 1); p += 1
            for _ in range(m):
                p += 2
            p += 1
            salida.append(f"      op3 VRAM {dst&0x3FFF:04X} (rellenos x{m})")
        else:                                         # repetir un patron de 8
            dst = (B(p) << 8) | B(p + 1); p += 2
            cnt = B(p); p += 1
            src = W(p); p += 2
            salida.append(f"      op{op} VRAM {dst&0x3FFF:04X} x{cnt} <- {src:04X}")
    return p, salida


def corto(p):
    ini = p
    n = 0
    while True:
        p += 2                                        # direccion de VRAM
        while True:
            v = B(p)
            if v == 0xFE:
                p += 3
                continue
            if v == 0xFF:
                p += 1
                break
            p += 1
        n += 1
        if B(p) == 0xFF:
            p += 1
            break
    return p, [f"{ini:04X}  guion corto de {n} bloques"]


def lista(p):
    """[N] y detras N guiones largos seguidos (lo recorre 0x425A)."""
    ini = p
    n = B(p); p += 1
    out = [f"{ini:04X}  lista de {n} guiones largos"]
    for i in range(n):
        q = p
        p, _t = largo(p)
        out.append(f"      {i+1:2d}  {q:04X}..{p-1:04X}  ({p-q} bytes)")
    return p, out


modo = sys.argv[3]
for s in sys.argv[4:]:
    a = int(s, 0)
    fin, txt = {"largo": largo, "corto": corto, "lista": lista}[modo](a)
    print("\n".join(txt))
    print(f"  -> {a:04X}..{fin-1:04X}  ({fin-a} bytes)")
