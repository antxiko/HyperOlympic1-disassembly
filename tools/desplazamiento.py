#!/usr/bin/env python3
"""Saca el MAPA DE DESPLAZAMIENTO entre dos compilaciones hermanas.

No es un mapa direccion a direccion sino por TRAMOS: "de 0x40BA a 0x472B, lo de
A esta en B cuatro bytes mas alla". Sale de dos clases de ancla, las dos de
fiar:

  - el codigo alineado por instruccion normalizada (tools/porta_notas.py),
  - las rachas de 16 bytes o mas identicas dentro de un bloque de datos.

Las rachas cortas dentro de los datos NO se usan: en una tabla de punteros o en
unos graficos hay coincidencias de dos y tres bytes por casualidad, y meterlas
en el mapa lo estropea. Con los tramos, cualquier direccion de A se traduce a B
aunque el byte concreto haya cambiado, que es justo lo que hace falta para
saber si un puntero solo se ha reubicado o de verdad apunta a otro sitio.

Uso: desplazamiento.py <romA> <trazaA> <romB> <trazaB> <salida.json>
"""
import bisect
import difflib
import json
import sys

sys.path.insert(0, r"C:/Users/Antxiko/Documents/DES_ASM/HYPEROLYMPIC1_DISAM/tools")
from z80trace import Tracer                                   # noqa: E402

ABS16 = ({0x01, 0x11, 0x21, 0x31, 0x22, 0x2A, 0x32, 0x3A, 0xC3, 0xCD}
         | {0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA}
         | {0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC})
ORG = 0x4000
RACHA = 16
# JR y DJNZ: el desplazamiento tambien se normaliza, porque si entre el salto y
# su destino se ha metido o quitado codigo cambia sin que cambie el salto.
REL8 = {0x10, 0x18, 0x20, 0x28, 0x30, 0x38}


def lleva_rel8(q):
    return q[0] in REL8 and len(q) == 2


def destino_rel8(p, q):
    d = q[1] - 256 if q[1] > 127 else q[1]
    return p + 2 + d


def lleva_abs16(q):
    op = q[0]
    if op in ABS16 and len(q) >= 3:
        return True
    if op in (0xDD, 0xFD) and len(q) >= 4 and q[1] in ABS16:
        return True
    if op == 0xED and len(q) == 4:
        return True
    return False


def instrucciones(rom, traza, org):
    t = Tracer(rom, org)
    out = []
    for k, a, b in json.load(open(traza))["blocks"]:
        if k != "c":
            continue
        p = a
        while p < b:
            n = t.ilen(p)
            if not n or p + n > b:
                break
            crudo = bytes(rom[p - org:p - org + n])
            q = bytearray(crudo)
            if lleva_abs16(q):
                q[-2] = q[-1] = 0
            elif lleva_rel8(q):
                q[1] = 0
            out.append((p, crudo, bytes(q)))
            p += n
    return out


def construye(ra, ta, rb, tb, org=ORG):
    romA = open(ra, "rb").read()
    romB = open(rb, "rb").read()
    A = instrucciones(romA, ta, org)
    B = instrucciones(romB, tb, org)
    sm = difflib.SequenceMatcher(None, [x[2] for x in A], [x[2] for x in B],
                                 autojunk=False)
    anclas = []
    for t, i1, i2, j1, j2 in sm.get_opcodes():
        if t != "equal":
            continue
        for k in range(i2 - i1):
            pa, cra = A[i1 + k][0], A[i1 + k][1]
            pb = B[j1 + k][0]
            anclas.append((pa, pa + len(cra), pb - pa))
    anclas.sort()

    # desplazamiento provisional para situar los bloques de datos
    ini = [x[0] for x in anclas]

    def prov(x):
        i = bisect.bisect_right(ini, x) - 1
        return anclas[i][2] if i >= 0 else 0

    def prov_sig(x):
        i = bisect.bisect_left(ini, x)
        return anclas[i][2] if i < len(anclas) else prov(x)

    for k, a, b in json.load(open(ta))["blocks"]:
        if k != "d":
            continue
        ja, jb = a + prov(a), b + prov_sig(b)
        DA = romA[a - org:b - org]
        DB = romB[ja - org:jb - org]
        s = difflib.SequenceMatcher(None, DA, DB, autojunk=False)
        for t, i1, i2, j1, j2 in s.get_opcodes():
            if t == "equal" and (i2 - i1) >= RACHA:
                anclas.append((a + i1, a + i2, (ja + j1) - (a + i1)))
    anclas.sort()

    # fundir tramos consecutivos con el mismo desplazamiento
    tramos = []
    for a, b, d in anclas:
        if tramos and tramos[-1][2] == d and a <= tramos[-1][1] + 4096:
            tramos[-1][1] = max(tramos[-1][1], b)
        else:
            tramos.append([a, b, d])
    return tramos


class Mapa:
    def __init__(self, tramos):
        self.t = tramos
        self.ini = [x[0] for x in tramos]

    def desp(self, x):
        i = bisect.bisect_right(self.ini, x) - 1
        if i < 0:
            return None
        return self.t[i][2]

    def destino(self, x):
        d = self.desp(x)
        return None if d is None else x + d

    def cuadra(self, va, vb):
        """True si vb es donde va ha ido a parar, mirando el tramo de antes y
        el de despues (una direccion justo en la frontera vale por los dos)."""
        i = bisect.bisect_right(self.ini, va) - 1
        for j in (i, i + 1, i - 1):
            if 0 <= j < len(self.t) and va + self.t[j][2] == vb:
                return True
        return False


def main():
    ra, ta, rb, tb, sal = sys.argv[1:6]
    tramos = construye(ra, ta, rb, tb)
    json.dump(tramos, open(sal, "w"))
    print("%d tramos de desplazamiento" % len(tramos))
    for a, b, d in tramos:
        print("  A 0x%04X-0x%04X  ->  B 0x%04X-0x%04X   %+d"
              % (a, b - 1, a + d, b - 1 + d, d))


if __name__ == "__main__":
    main()
