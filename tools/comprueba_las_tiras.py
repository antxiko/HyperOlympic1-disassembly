#!/usr/bin/env python3
"""Comprueba que las tiras de bytes que se publican estan DONDE se dice.

EL AGUJERO QUE TAPA. tools/repasa_el_porte.py comprueba que una direccion
citada EXISTA en este cartucho. No puede comprobar que diga lo que la frase
dice. Y esa es otra clase de fallo: la pagina de este cartucho publicaba

    el rotulo QUALIFY del marcador, que en 0x5F88 es la tira
    `2C 1E 0B 16 13 10 21`

y la tira empieza en 0x5F87. Un byte. La direccion existia -cae dentro de un
rango de datos-, asi que el guardian la daba por buena; en 0x5F88 lo que hay es
`1E 0B 16 13 10 21 FF`, o sea la misma palabra sin la Q, que era justo la letra
de la que hablaba el parrafo.

LA REGLA, sin heuristica: cuando una pagina cita una direccion y, cerca, una
tira de tres o mas bytes en hexadecimal, esos bytes tienen que estar en la ROM
EN ESA DIRECCION. Si no estan, se busca donde estan de verdad y se dice.

No inventa nada ni adivina: si no encuentra la tira en toda la ROM, lo dice
tambien, porque entonces o la tira esta mal copiada o no es de este cartucho.

Uso: comprueba_las_tiras.py
"""
import glob
import os
import re
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(AQUI)
ORG = 0x4000

CARTUCHOS = ("hyperolympic1", "hyperolympic2")
CUAL = next((c for c in CARTUCHOS
             if os.path.exists(os.path.join(RAIZ, c + ".rom"))), None)

# Una direccion, y detras -en la misma frase- una tira de bytes. La tira admite
# las barras con las que se separan los grupos ("00 09 95 / 00 08 90").
DIRECCION = re.compile(r"0x([0-9A-Fa-f]{4})")
TIRA = re.compile(r"((?:[0-9A-F]{2}[ /]+){2,}[0-9A-F]{2})")
VECINDAD = 220          # lo que dura una frase larga

# Si entre la direccion y la tira hay OTRA direccion, la tira es de esa otra y
# no de esta. Sin esta regla, un parrafo que nombra 0x6332 y el siguiente que
# publica la tabla de 0x5174 se emparejan mal y sale un rojo falso.
CRUZA = DIRECCION

# La direccion citada puede ser la del BLOQUE y la tira empezar unos bytes mas
# alla, detras de una cabecera. Eso es legitimo cuando la frase lo dice, y aqui
# se acepta mientras el desplazamiento sea pequeno: se avisa con su valor para
# que se pueda mirar, pero no es un fallo.
CABECERA = 8

# Las paginas que comparan las dos compilaciones citan direcciones y tiras del
# OTRO binario a proposito. Misma lista que tools/repasa_el_porte.py.
PAGINAS_COMPARATIVAS = ("COMPARISON-TRACK-AND-FIELD.md",
                        "COMPARATIVA-TRACK-AND-FIELD.md")


def bytes_de(t):
    return [int(x, 16) for x in t.replace("/", " ").split()]


def main(argv):
    if CUAL is None:
        print("  (no esta la ROM: no se puede comprobar)")
        return 0
    rom = open(os.path.join(RAIZ, CUAL + ".rom"), "rb").read()

    mirados = malos = 0
    for patron in ("docs/*.md", "docs/es/*.md"):
        for ruta in sorted(glob.glob(os.path.join(RAIZ, patron))):
            if os.path.basename(ruta) in PAGINAS_COMPARATIVAS:
                continue
            fich = os.path.relpath(ruta, RAIZ).replace("\\", "/")
            texto = open(ruta, encoding="utf-8").read()
            for m in DIRECCION.finditer(texto):
                d = int(m.group(1), 16)
                if not ORG <= d < ORG + len(rom):
                    continue
                cerca = texto[m.end():m.end() + VECINDAD]
                t = TIRA.search(cerca)
                if not t:
                    continue
                otra = CRUZA.search(cerca[:t.start()])
                if otra:
                    continue        # la tira es de esa otra direccion
                b = bytes_de(t.group(1))
                if len(b) < 3:
                    continue
                mirados += 1
                hay = list(rom[d - ORG:d - ORG + len(b)])
                if hay == b:
                    continue
                # detras de una cabecera del propio bloque: legitimo
                dentro = [k for k in range(1, CABECERA)
                          if list(rom[d - ORG + k:d - ORG + k + len(b)]) == b]
                if dentro:
                    print("  (aviso) %s: la tira de 0x%04X empieza %d byte(s) "
                          "mas alla, detras de la cabecera del bloque"
                          % (fich, d, dentro[0]))
                    continue
                malos += 1
                print("  FALLO en %s: dice que en 0x%04X esta" % (fich, d))
                print("      %s" % " ".join("%02X" % x for x in b))
                print("    y lo que hay es")
                print("      %s" % " ".join("%02X" % x for x in hay))
                donde = bytes(b)
                i = rom.find(donde)
                if i < 0:
                    print("    esa tira NO esta en ninguna parte de la ROM")
                else:
                    sitios = []
                    while i >= 0 and len(sitios) < 4:
                        sitios.append(ORG + i)
                        i = rom.find(donde, i + 1)
                    print("    esta en %s"
                          % ", ".join("0x%04X" % s for s in sitios))

    print("  %d tiras de bytes citadas con su direccion" % mirados)
    if malos:
        print("  %d NO estan donde se dice" % malos)
        return 1
    print("  OK: todas estan donde se dice")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
