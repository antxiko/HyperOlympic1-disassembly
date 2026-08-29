#!/usr/bin/env python3
"""Vista compacta del listado: una instruccion por linea, sin columnas.

Uso: ver.py <ini> <fin>   (direcciones hex, sobre src/<juego>.asm)
"""
import re, sys, os, glob
asm = glob.glob(os.path.join(os.path.dirname(__file__), "..", "src", "*.asm"))[0]
ini = int(sys.argv[1], 0); fin = int(sys.argv[2], 0)
pend = []
for ln in open(asm, encoding="utf-8"):
    ln = ln.rstrip()
    if not ln: continue
    m = re.search(r";([0-9a-f]{4})\b", ln)
    if m:
        a = int(m.group(1), 16)
        if not (ini <= a < fin): continue
        cod, _, cmt = ln.partition(";")
        cod = " ".join(cod.split())
        resto = cmt[4:].strip().lstrip("; ")
        for q in pend:
            print(q)
        pend = []
        print(f"{a:04x} {cod}" + (f"   ; {resto}" if resto else ""))
    elif ln.endswith(":") or ":" in ln.split()[0] if ln.split() else False:
        # etiqueta o cabecera
        s = ln.strip()
        if s.startswith(";"): continue
        pend = [s]
    elif ln.lstrip().startswith("; DATOS") or ln.lstrip().startswith("; CODIGO"):
        pend.append(ln.strip())
