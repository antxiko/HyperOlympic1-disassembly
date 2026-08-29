#!/usr/bin/env python3
"""Ejecuta un guion corto y devuelve LO QUE PINTA, no como lo pinta.

Sirve para decidir si dos guiones distintos dan la misma pantalla. El formato
lo interpreta GUION_CORTO (HO1 0x4AFE):

    [dirVRAM de dos bytes, BYTE ALTO PRIMERO][bytes tal cual]
    [0xFE cuenta valor]* [0xFF]

y detras otro bloque igual; dos 0xFF seguidos cierran el guion. La direccion
lleva el bit 14 puesto porque es una escritura, asi que se queda con los
catorce bits de abajo.

Uso: pinta_corto.py <romA> <iniA> <romB> <iniB>
     compara lo que pintan los dos y dice si sale la misma VRAM.
"""
import sys

ORG = 0x4000


def pinta(rom, p):
    """{direccion de VRAM: byte} y cuantos bytes ha escrito."""
    vram, escritos, bloques = {}, 0, 0
    while True:
        d = (rom[p - ORG] << 8) | rom[p - ORG + 1]
        a = d & 0x3FFF
        p += 2
        bloques += 1
        while True:
            v = rom[p - ORG]
            if v == 0xFF:
                p += 1
                break
            if v == 0xFE:
                n, b = rom[p - ORG + 1], rom[p - ORG + 2]
                for _ in range(n):
                    vram[a] = b
                    a += 1
                    escritos += 1
                p += 3
                continue
            vram[a] = v
            a += 1
            escritos += 1
            p += 1
        if rom[p - ORG] == 0xFF:
            p += 1
            break
    return vram, escritos, bloques, p


def main():
    ra, pa, rb, pb = sys.argv[1], int(sys.argv[2], 0), sys.argv[3], int(sys.argv[4], 0)
    A = open(ra, "rb").read()
    B = open(rb, "rb").read()
    va, na, ba, fa = pinta(A, pa)
    vb, nb, bb, fb = pinta(B, pb)
    print("A 0x%04X-0x%04X  %d bytes de guion  %d bloques  %d bytes a la VRAM"
          % (pa, fa - 1, fa - pa, ba, na))
    print("B 0x%04X-0x%04X  %d bytes de guion  %d bloques  %d bytes a la VRAM"
          % (pb, fb - 1, fb - pb, bb, nb))
    ka, kb = set(va), set(vb)
    if ka != kb:
        print("PINTAN SITIOS DISTINTOS: solo A %d, solo B %d"
              % (len(ka - kb), len(kb - ka)))
        for x in sorted(ka - kb)[:20]:
            print("   solo A: VRAM 0x%04X = %02X" % (x, va[x]))
        for x in sorted(kb - ka)[:20]:
            print("   solo B: VRAM 0x%04X = %02X" % (x, vb[x]))
        return
    dif = [x for x in sorted(ka) if va[x] != vb[x]]
    print("las dos escriben las mismas %d direcciones de VRAM (0x%04X-0x%04X)"
          % (len(ka), min(ka), max(ka)))
    if not dif:
        print("VEREDICTO: la VRAM que queda es IDENTICA. Solo cambia la"
              " compresion del guion (%+d bytes)." % ((fb - pb) - (fa - pa)))
    else:
        print("VEREDICTO: %d direcciones con VALOR DISTINTO" % len(dif))
        for x in dif[:40]:
            print("   VRAM 0x%04X: A %02X  B %02X" % (x, va[x], vb[x]))



if __name__ == "__main__":
    main()
