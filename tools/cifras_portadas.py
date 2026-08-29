#!/usr/bin/env python3
"""Caza comentarios portados que describen la instruccion DEL OTRO cartucho.

EL FALLO QUE BUSCA. tools/porta_notas.py alinea los dos cartuchos instruccion a
instruccion y trae los comentarios del hermano. Los coloca en la direccion
buena, pero NO cambia lo que dicen. Cuando las dos instrucciones alineadas son
la misma, el comentario vale igual. Cuando NO lo son -porque en este cartucho el
operando es otro-, el comentario publica una cifra que aqui es falsa.

Paso de verdad, y no lo cazaba nada: en 0x4389 este cartucho carga
`ld bc,01afeh`, o sea 26, y el comentario portado seguia diciendo "32 sprites",
que es lo que carga el hermano. Dos comentarios mintiendo con una cifra
concreta, en el listado y a punto de salir en la web.

LA REGLA, sin heuristica: si un comentario de este cartucho es IDENTICO a uno
del hermano, las dos instrucciones que anotan tienen que ser tambien iguales una
vez puestos a cero los operandos de dieciseis bits -que son direcciones, y
cambian de sitio por definicion-. Si el mnemonico o un inmediato de ocho bits
difieren, el comentario esta describiendo la del hermano.

Lo que NO es: una prueba de que el comentario mienta. Es una lista de sitios
donde el porte pudo colar una cifra, para MIRARLOS uno a uno. Los que se revisan
y son correctos se apuntan en REVISADOS, con su razon.

Uso: cifras_portadas.py [<asm del hermano>] [<notes del hermano>]
"""
import os
import re
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(AQUI)

CARTUCHOS = ("hyperolympic1", "hyperolympic2")
CUAL = next(c for c in CARTUCHOS
            if os.path.exists(os.path.join(RAIZ, c + ".rom")))
HERMANO = next(c for c in CARTUCHOS if c != CUAL)

ASM = os.path.join(RAIZ, "src", CUAL + ".asm")
# El hermano vive fuera de este repositorio, asi que su ruta se puede dar por
# argumento. Sin el, la herramienta dice lo que le falta y se va en verde: es
# una comprobacion de mantenimiento, no una puerta de publicacion.
ASM_HERMANO = os.path.join(RAIZ, "..", HERMANO.upper().replace("HYPEROLYMPIC",
                                                               "HYPEROLYMPIC"),
                           "src", HERMANO + ".asm")
_DIR = {"hyperolympic1": "HYPEROLYMPIC1_DISAM",
        "hyperolympic2": "HYPEROLYMPIC2_DISAM"}
ASM_HERMANO = os.path.join(RAIZ, "..", _DIR[HERMANO], "src", HERMANO + ".asm")

# Una linea del listado: la instruccion, su direccion y su comentario.
LINEA = re.compile(r"^\s+(.+?)\s*;([0-9a-f]{4})(?:\s+;\s*(.*))?$")

# Los operandos de dieciseis bits son direcciones y cambian de sitio entre los
# dos cartuchos por definicion. Se ponen a cero, que es el mismo criterio con
# el que se alinean las dos ROM en todo el proyecto.
HEX16 = re.compile(r"\b0[0-9a-f]{4}h\b")
ETIQUETA = re.compile(r"\b[A-Z][A-Z0-9_]{2,}\b")

# Sitios ya mirados a mano en los que el comentario vale para los dos aunque la
# instruccion difiera. Cada uno con su razon.
REVISADOS = {
    # Los ocho de RC-711, mirados uno a uno en el listado el 2026-08-29. En los
    # ocho el comentario describe bien SU instruccion: son notas de sentido
    # ("el byte de abajo", "la ficha del que juega") que valen para las dos
    # formas de escribir lo mismo, y ninguna cita una cifra del operando.
    0x456A: "dec hl para bajar al byte alto: el acarreo va ahi igual",
    0x48B3: "inc hl llega al byte de abajo, que es lo que dice",
    0x5A6C: "ld l,04bh mueve el puntero a la valla del jugador 2 (0xE14B)",
    0x5BF8: "pop hl recupera la ficha del que juega, que es lo que dice",
    0x68BB: "lee 0xE02A, el resultado; el hermano lo tenia ya en A",
    0x6955: "ld a,(hl) sobre la cuenta en binario, que es lo que dice",
    0x6994: "ld hl,0xE117 apunta a la altura de este cuadro",
    0x69AF: "lee 0xE116, el contador del vuelo, que es lo que dice",
}


def lee(ruta):
    """{direccion: (instruccion normalizada, comentario)}."""
    out = {}
    with open(ruta, encoding="utf-8") as f:
        for linea in f:
            m = LINEA.match(linea.rstrip("\n"))
            if not m:
                continue
            ins, addr, com = m.group(1), int(m.group(2), 16), m.group(3)
            ins = HEX16.sub("0", ins)
            ins = ETIQUETA.sub("X", ins)
            out[addr] = (" ".join(ins.split()), (com or "").strip())
    return out


def main(argv):
    # Solo tiene sentido en el cartucho que RECIBIO el porte. En el otro los
    # comentarios se escribieron leyendo SU listado, asi que describen su
    # instruccion por construccion, y esta comparacion solo devolveria el
    # reflejo -las mismas parejas, vistas del otro lado- como si fueran fallos.
    # La senal de quien recibio el porte es objetiva: quien tiene la herramienta
    # que lo hizo.
    if not os.path.exists(os.path.join(AQUI, "porta_notas.py")):
        print("  (aqui no se porto ninguna anotacion: nada que comprobar)")
        return 0
    ruta_hermano = argv[1] if len(argv) > 1 else ASM_HERMANO
    mio = lee(ASM)
    if not os.path.exists(ruta_hermano):
        print("  (no esta el listado del hermano en %s: no se puede comparar)"
              % os.path.normpath(ruta_hermano))
        return 0
    suyo = lee(ruta_hermano)

    # Los comentarios del hermano, con la instruccion que anotan. Un mismo
    # comentario puede repetirse; se guardan todas sus instrucciones.
    suyos = {}
    for ins, com in suyo.values():
        if com:
            suyos.setdefault(com, set()).add(ins)

    iguales = sospechosos = 0
    malos = []
    for addr, (ins, com) in sorted(mio.items()):
        if not com or com not in suyos:
            continue
        iguales += 1
        if ins in suyos[com]:
            continue
        if addr in REVISADOS:
            continue
        sospechosos += 1
        malos.append((addr, ins, sorted(suyos[com]), com))

    print("  %d comentarios identicos a uno del hermano" % iguales)
    if not malos:
        print("  OK: en todos, la instruccion anotada es la misma")
        return 0
    print("  %d anotan una instruccion DISTINTA de la del hermano:"
          % sospechosos)
    for addr, ins, suyas, com in malos:
        print("    0x%04X  %-28s  %s" % (addr, ins, com))
        for s in suyas:
            print("            el hermano: %s" % s)
    print()
    print("  Mirar uno a uno: si el comentario cita una cifra que viene del")
    print("  operando, es la del OTRO cartucho. Los que esten bien, a REVISADOS.")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
