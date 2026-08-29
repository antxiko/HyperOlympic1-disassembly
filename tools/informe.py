#!/usr/bin/env python3
"""El informe: que difiere de verdad entre dos compilaciones hermanas.

Usa el mapa de desplazamiento por tramos (tools/desplazamiento.py) para separar
lo que solo se ha MOVIDO de lo que ha CAMBIADO:

  - una instruccion cuyo unico cambio es el operando de dieciseis bits, y ese
    operando apunta en B exactamente adonde apuntaba en A, es una REUBICACION;
  - un byte de datos que forma parte de un puntero con la misma propiedad, lo
    mismo;
  - todo lo demas es un CAMBIO REAL y sale con su nombre del .notes.

Uso: informe.py <romA> <trazaA> <notasA> <romB> <trazaB> <desp.json> <salida>
"""
import bisect
import difflib
import json
import os
import re
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
sys.path.insert(0, r"C:/Users/Antxiko/Documents/DES_ASM/HYPEROLYMPIC1_DISAM/tools")
from desplazamiento import (Mapa, destino_rel8, instrucciones,   # noqa: E402
                            lleva_abs16, lleva_rel8)

ORG = 0x4000


def lee_notas(notas):
    rangos, etiq, cab, anchos = [], {}, {}, {}
    for ln in open(notas, encoding="utf-8"):
        m = re.match(r"^D (0x[0-9A-Fa-f]+) (0x[0-9A-Fa-f]+)\s+(\S+)\s*(.*)$", ln)
        if m:
            rangos.append([int(m.group(1), 0), int(m.group(2), 0),
                           m.group(3), m.group(4).strip()])
            continue
        m = re.match(r"^F (0x[0-9A-Fa-f]+)\s+(\S+)", ln)
        if m:
            anchos[int(m.group(1), 0)] = m.group(2)
            continue
        m = re.match(r"^L (0x[0-9A-Fa-f]+)\s+(\S+)", ln)
        if m:
            etiq[int(m.group(1), 0)] = m.group(2)
            continue
        m = re.match(r"^B (0x[0-9A-Fa-f]+)\s+(.*)$", ln)
        if m:
            cab[int(m.group(1), 0)] = m.group(2).strip()
    return rangos, etiq, cab, anchos


def main():
    ra, ta, na, rb, tb, dj, sal = sys.argv[1:8]
    org = ORG
    romA = open(ra, "rb").read()
    romB = open(rb, "rb").read()
    mp = Mapa(json.load(open(dj)))
    rangos, etiq, cab, anchos = lee_notas(na)
    dirs_etiq = sorted(etiq)
    dirs_cab = sorted(cab)

    def rutina(x):
        i = bisect.bisect_right(dirs_etiq, x) - 1
        nom = etiq[dirs_etiq[i]] if i >= 0 else "?"
        d = dirs_etiq[i] if i >= 0 else x
        j = bisect.bisect_right(dirs_cab, x) - 1
        return nom, x - d, (cab[dirs_cab[j]] if j >= 0 else "")

    # ------------------------------------------------------------- CODIGO
    A = instrucciones(romA, ta, org)
    B = instrucciones(romB, tb, org)
    sm = difflib.SequenceMatcher(None, [x[2] for x in A], [x[2] for x in B],
                                 autojunk=False)
    ops = sm.get_opcodes()
    par = {}
    for t, i1, i2, j1, j2 in ops:
        if t == "equal":
            for k in range(i2 - i1):
                par[i1 + k] = j1 + k

    ig_c = reub_c = 0
    real_c = []
    for i, (pa, cra, _) in enumerate(A):
        if i not in par:
            continue
        pb, crb, _ = B[par[i]]
        if cra == crb:
            ig_c += 1
            continue
        if lleva_abs16(cra) and len(cra) == len(crb):
            oa = cra[-2] | (cra[-1] << 8)
            ob = crb[-2] | (crb[-1] << 8)
            fuera = not (org <= oa < org + len(romA))
            if (fuera and oa == ob) or mp.cuadra(oa, ob):
                reub_c += 1
                continue
        if lleva_rel8(cra) and lleva_rel8(crb):
            if mp.cuadra(destino_rel8(pa, cra), destino_rel8(pb, crb)):
                reub_c += 1
                continue
        real_c.append((pa, pb, cra, crb))
    estr_c = [o for o in ops if o[0] != "equal"]

    # -------------------------------------------------------------- DATOS
    filas = []
    for x, y, nom, txt in rangos:
        w = anchos.get(x, "")
        d1, d2 = mp.desp(x), mp.desp(y - 1)
        jx = x + (d1 if d1 is not None else 0)
        jy = y + (d2 if d2 is not None else 0)
        DA, DB = romA[x - org:y - org], romB[jx - org:jy - org]
        if w.startswith("w") and len(DA) == len(DB) and len(DA) % 2 == 0:
            mal = []
            for k in range(0, len(DA), 2):
                va = DA[k] | (DA[k + 1] << 8)
                vb = DB[k] | (DB[k + 1] << 8)
                if va == vb or mp.cuadra(va, vb):
                    continue
                mal.append((x + k, va, vb))
            if not mal:
                filas.append(("=", x, y, jx, jy, nom, txt,
                              "tabla de punteros", mal, len(DA) // 2))
                continue
            # el .notes lo declara en palabras pero la fila lleva ademas algun
            # byte suelto (una cuenta al principio): se cae al metodo por bytes,
            # que prueba el puntero empezando en k y en k-1.
        if len(DA) != len(DB):
            filas.append(("TAM", x, y, jx, jy, nom, txt,
                          "%+d bytes" % (len(DB) - len(DA)), [], 0))
            continue
        mal, k = [], 0
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
            mal.append((x + k, DA[k], DB[k]))
            k += 1
        filas.append(("=" if not mal else "DIF", x, y, jx, jy, nom, txt,
                      "%d bytes" % len(DA), mal, 0))

    with open(sal, "w", encoding="utf-8") as f:
        w_ = f.write
        w_("A = %s\n" % os.path.basename(ra))
        w_("B = %s\n" % os.path.basename(rb))
        w_("\nCODIGO (por instruccion)\n")
        w_("  instrucciones A / B      : %d / %d\n" % (len(A), len(B)))
        w_("  alineadas                : %d\n" % len(par))
        w_("    identicas              : %d\n" % ig_c)
        w_("    solo reubicadas        : %d\n" % reub_c)
        w_("    CAMBIO REAL            : %d\n" % len(real_c))
        w_("  tramos estructurales     : %d\n" % len(estr_c))
        w_("\nDATOS (por bloque con nombre del .notes)\n")
        w_("  bloques                  : %d\n" % len(filas))
        w_("    identicos o reubicados : %d\n"
           % sum(1 for r in filas if r[0] == "="))
        w_("    con cambio real        : %d\n"
           % sum(1 for r in filas if r[0] == "DIF"))
        w_("    de otro tamano         : %d\n"
           % sum(1 for r in filas if r[0] == "TAM"))
        w_("\n" + "=" * 76 + "\nCODIGO: tramos estructurales\n" + "=" * 76 + "\n")
        for t, i1, i2, j1, j2 in estr_c:
            pa = A[min(i1, len(A) - 1)][0]
            nom, off, blo = rutina(pa)
            pb = B[j1][0] if j1 < len(B) else 0
            w_("\n-- %s   A 0x%04X   B 0x%04X   [%s+%d]\n"
               % (t.upper(), pa, pb, nom, off))
            if blo:
                w_("   %s\n" % blo[:110])
            for k in range(i1, i2):
                w_("   A 0x%04X  %s\n"
                   % (A[k][0], " ".join("%02X" % v for v in A[k][1])))
            for k in range(j1, j2):
                w_("   B 0x%04X  %s\n"
                   % (B[k][0], " ".join("%02X" % v for v in B[k][1])))
        w_("\n" + "=" * 76 + "\nCODIGO: cambios reales en instrucciones alineadas\n"
           + "=" * 76 + "\n")
        for pa, pb, cra, crb in real_c:
            nom, off, _ = rutina(pa)
            w_("A 0x%04X %-12s  B 0x%04X %-12s  [%s+%d]\n"
               % (pa, " ".join("%02X" % v for v in cra), pb,
                  " ".join("%02X" % v for v in crb), nom, off))
        w_("\n" + "=" * 76 + "\nDATOS: bloque a bloque\n" + "=" * 76 + "\n")
        w_("%-4s %-13s %-13s %-34s %s\n"
           % ("", "A", "B", "nombre", "que pasa"))
        for est, x, y, jx, jy, nom, txt, com, mal, n in filas:
            extra = com
            if est == "DIF" and n:
                extra = "%s: %d de %d entradas CAMBIAN" % (com, len(mal), n)
            elif est == "DIF":
                extra = "%s, %d con CAMBIO REAL" % (com, len(mal))
            w_("%-4s 0x%04X-0x%04X 0x%04X-0x%04X %-34s %s\n"
               % (est, x, y - 1, jx, jy - 1, nom[:34], extra))
        w_("\n" + "=" * 76 + "\nDATOS: detalle de los bloques que cambian\n"
           + "=" * 76 + "\n")
        for est, x, y, jx, jy, nom, txt, com, mal, n in filas:
            if est == "=":
                continue
            w_("\n-- %s   A 0x%04X-0x%04X -> B 0x%04X-0x%04X   %s\n"
               % (nom, x, y - 1, jx, jy - 1, com))
            if txt:
                w_("   %s\n" % txt[:300])
            for it in mal[:60]:
                if n:
                    w_("   entrada A 0x%04X: A apunta a 0x%04X, B a 0x%04X\n" % it)
                else:
                    w_("   A 0x%04X: %02X -> %02X\n" % it)
            if len(mal) > 60:
                w_("   ... y %d mas\n" % (len(mal) - 60))
        w_("\n")
    print("CODIGO  alineadas=%d identicas=%d reubicadas=%d REAL=%d estruct=%d"
          % (len(par), ig_c, reub_c, len(real_c), len(estr_c)))
    print("DATOS   bloques=%d  iguales=%d  cambian=%d  otro_tamano=%d"
          % (len(filas), sum(1 for r in filas if r[0] == "="),
             sum(1 for r in filas if r[0] == "DIF"),
             sum(1 for r in filas if r[0] == "TAM")))
    print("  -> %s" % sal)



if __name__ == "__main__":
    main()
