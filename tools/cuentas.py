#!/usr/bin/env python3
"""Las cifras del informe, medidas y no estimadas.

Cuatro numeros por pareja de ROM:
  - bytes que difieren en la MISMA posicion (el diff crudo, que no dice nada
    porque toda la ROM esta desplazada);
  - bytes que difieren una vez ALINEADAS las dos compilaciones;
  - bytes que cambian de verdad: los de los tramos de codigo que no casan
    instruccion a instruccion y los de los bloques de datos cuyo contenido
    cambia;
  - de esos, cuantos caen en el bloque del logotipo.

Uso: cuentas.py <romA> <trazaA> <notasA> <romB> <trazaB> <desp.json> <logo_ini> <logo_fin>
"""
import difflib
import json
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
sys.path.insert(0, r"C:/Users/Antxiko/Documents/DES_ASM/HYPEROLYMPIC1_DISAM/tools")
from desplazamiento import Mapa, instrucciones                 # noqa: E402
from informe import lee_notas                                  # noqa: E402

ORG = 0x4000


def main():
    ra, ta, na, rb, tb, dj = sys.argv[1:7]
    logo = (int(sys.argv[7], 0), int(sys.argv[8], 0))
    romA = open(ra, "rb").read()
    romB = open(rb, "rb").read()
    mp = Mapa(json.load(open(dj)))
    rangos, _, _, anchos = lee_notas(na)

    crudo = sum(1 for i in range(len(romA)) if romA[i] != romB[i])

    sm = difflib.SequenceMatcher(None, romA, romB, autojunk=False)
    ig = sum(i2 - i1 for t, i1, i2, _, _ in sm.get_opcodes() if t == "equal")

    A = instrucciones(romA, ta, ORG)
    B = instrucciones(romB, tb, ORG)
    sm2 = difflib.SequenceMatcher(None, [x[2] for x in A], [x[2] for x in B],
                                  autojunk=False)
    cod_a = cod_b = 0
    tramos = 0
    for t, i1, i2, j1, j2 in sm2.get_opcodes():
        if t == "equal":
            continue
        tramos += 1
        cod_a += sum(len(A[k][1]) for k in range(i1, i2))
        cod_b += sum(len(B[k][1]) for k in range(j1, j2))

    dat_a = dat_b = 0
    cambian = []
    for x, y, nom, _ in rangos:
        d1, d2 = mp.desp(x), mp.desp(y - 1)
        jx, jy = x + (d1 or 0), y + (d2 or 0)
        DA, DB = romA[x - ORG:y - ORG], romB[jx - ORG:jy - ORG]
        if DA == DB:
            continue
        w = anchos.get(x, "")
        if w.startswith("w") and len(DA) == len(DB) and len(DA) % 2 == 0:
            mal = False
            for k in range(0, len(DA), 2):
                va = DA[k] | (DA[k + 1] << 8)
                vb = DB[k] | (DB[k + 1] << 8)
                if va != vb and not mp.cuadra(va, vb):
                    mal = True
                    break
            if not mal:
                continue
        if len(DA) == len(DB):
            mal, k = 0, 0
            while k < len(DA):
                if DA[k] == DB[k]:
                    k += 1
                    continue
                puesto = False
                for base in (k, k - 1):
                    if base < 0 or base + 2 > len(DA):
                        continue
                    va = DA[base] | (DA[base + 1] << 8)
                    vb = DB[base] | (DB[base + 1] << 8)
                    if va != vb and mp.cuadra(va, vb):
                        k = base + 2
                        puesto = True
                        break
                if puesto:
                    continue
                mal += 1
                k += 1
            if not mal:
                continue
        dat_a += len(DA)
        dat_b += len(DB)
        cambian.append((x, y, jx, jy, nom, len(DA), len(DB)))

    ll = [c for c in cambian if c[0] < logo[1] and c[1] > logo[0]]
    logo_a = sum(c[5] for c in ll)
    logo_b = sum(c[6] for c in ll)

    print("bytes en la misma posicion que difieren : %5d de %d (%.1f %%)"
          % (crudo, len(romA), 100.0 * crudo / len(romA)))
    print("bytes que ya no casan una vez alineadas : %5d de %d (%.1f %%)"
          % (len(romA) - ig, len(romA), 100.0 * (len(romA) - ig) / len(romA)))
    print()
    print("CODIGO que cambia de verdad : %d tramos, %d bytes en A y %d en B"
          % (tramos, cod_a, cod_b))
    print("DATOS que cambian de verdad : %d bloques, %d bytes en A y %d en B"
          % (len(cambian), dat_a, dat_b))
    for x, y, jx, jy, nom, la, lb in cambian:
        print("   %-34s A 0x%04X-0x%04X (%d)  B 0x%04X-0x%04X (%d)"
              % (nom, x, y - 1, la, jx, jy - 1, lb))
    print()
    print("TOTAL que cambia de verdad  : %d bytes de A (%.2f %% de la ROM)"
          % (cod_a + dat_a, 100.0 * (cod_a + dat_a) / len(romA)))
    print("   de ellos, en el logotipo : %d bytes (%.1f %% de lo que cambia)"
          % (logo_a, 100.0 * logo_a / max(1, cod_a + dat_a)))
    print("   fuera del logotipo       : %d bytes"
          % (cod_a + dat_a - logo_a))


main()
