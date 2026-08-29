#!/usr/bin/env python3
"""Caza las anotaciones que se portaron del cartucho HERMANO y aqui son mentira.

Vale para los dos: mira que .rom hay en la raiz y se configura solo.

DE DONDE SALE ESTO. El 83,4 % del codigo de Hyper Olympic 2 es el de Hyper
Olympic 1 con trozos metidos y quitados, asi que las anotaciones se trajeron con
tools/porta_notas.py, que alinea las dos listas de instrucciones y mueve las L,
las C y las B a la direccion que les toca aqui. Eso pone el comentario en el
sitio correcto, pero **no cambia lo que dice**. Un comentario que en HO1 era
verdad puede ser mentira aqui, y el reensamblado no lo va a notar: los bytes
salen identicos igual, porque un comentario no es un byte.

LO QUE SE COMPRUEBA, y las tres cosas son exactas, no heuristicas:

  1. DIRECCIONES CITADAS EN EL TEXTO. Un comentario que dice "-> 0x5A3F" esta
     apuntando a un sitio, y ese sitio tiene que existir AQUI. Si la direccion
     cae fuera del cartucho, o cae dentro de un rango de datos, o cae en medio
     de una instruccion en vez de en su primer byte, es que viene del hermano.

  2. NOMBRES DE PRUEBA CRUZADOS. Las cuatro de HO1 son 100 METER DASH, LONG
     JUMP, HAMMER THROW y 400 METER; las de HO2, 110 HURDLERS, JAVELIN THROW,
     HIGH JUMP y 1500 METER. Ninguna de las del hermano puede aparecer aqui.

  3. EL NUMERO DE CARTUCHO. RC-710 es HO1 y RC-711 es HO2.

Las tres se miran en las anotaciones Y en las paginas de la web, que es
donde el copia y pega entre hermanos es mas facil y menos visible.

Y ademas informa de cuantos comentarios son IDENTICOS a uno del hermano, que es
la medida del riesgo: no son un fallo por si mismos -la mayoria describen codigo
que de verdad es el mismo- pero son el conjunto donde puede haberlo.

Uso:
  repasa_el_porte.py                     comprueba este cartucho
  repasa_el_porte.py <notas del hermano> ademas, mide cuantas son identicas
"""
import glob
import json
import os
import re
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(AQUI)
sys.path.insert(0, AQUI)

ORG = 0x4000

# El mismo guion sirve para los dos cartuchos: se mira cual hay aqui. Lo que
# cambia entre ellos son los nombres de las cuatro pruebas y el numero de
# catalogo, y es justo lo que no puede cruzarse.
# Las pruebas van en los DOS idiomas a proposito. Los rotulos que pinta el
# cartucho estan en ingles, pero las anotaciones y la web se escriben en
# castellano, y un comentario portado del hermano habla de SU prueba en
# castellano: el ingles solo no lo caza. Paso de verdad -la cabecera del bloque
# 0x7D2B de RC-711 se publico diciendo "EL VUELO DEL SALTO Y DEL MARTILLO",
# heredada del hermano, y en este cartucho no hay martillo-. Los terminos son
# los que solo pueden significar la prueba: "altura" a secas no entra, porque
# aqui es tambien la del vuelo, y daria doce rojos falsos.
CARTUCHOS = {
    "hyperolympic1": dict(
        rc="RC-710",
        pruebas=["100 METER DASH", "LONG JUMP", "HAMMER THROW", "400 METER",
                 "martillo", "salto de longitud", "100 metros", "400 metros"]),
    "hyperolympic2": dict(
        rc="RC-711",
        pruebas=["110 HURDLERS", "JAVELIN", "HIGH JUMP", "1500 METER",
                 "jabalina", "salto de altura", "110 vallas", "1500 metros"]),
}
CUAL = next(c for c in CARTUCHOS
            if os.path.exists(os.path.join(RAIZ, c + ".rom")))
HERMANO = next(c for c in CARTUCHOS if c != CUAL)

NOTAS = os.path.join(RAIZ, "src", CUAL + ".notes")
ROM = os.path.join(RAIZ, CUAL + ".rom")
TRAZA = os.path.join(RAIZ, "work", CUAL + ".trace.json")

DEL_HERMANO = CARTUCHOS[HERMANO]["pruebas"]
RC_DEL_HERMANO = CARTUCHOS[HERMANO]["rc"]
NOMBRE_DEL_HERMANO = "Hyper Olympic %s" % HERMANO[-1]

# LAS DOS FORMAS LEGITIMAS DE CITAR UNA DIRECCION QUE AQUI NO EXISTE.
#
# La primera es una CASILLA CERO: hay tablas que el cartucho indexa desde uno,
# asi que la direccion que calcula el codigo cae dos bytes por delante de la
# primera casilla util. Esa direccion no es un byte al que se pueda apuntar
# -cae a mitad de la instruccion de antes- y aun asi hay que nombrarla, porque
# es la que registra el codigo. Cada una va aqui CON SU RAZON.
CASILLAS_CERO = {
    "hyperolympic1": {
        0x7B44: "casilla cero de fichas_de_la_prueba: 0x7B35 indexa desde uno "
                "y calcula esta direccion, dos bytes antes de la tabla (0x7B46)",
    },
    "hyperolympic2": {
        0x7B6B: "casilla cero de fichas_de_la_prueba: 0x7B5C indexa desde uno "
                "y calcula esta direccion, dos bytes antes de la tabla (0x7B6D)",
        0x4F1C: "casilla cero de rotulo_de_la_prueba: 0x49AF indexa desde uno "
                "y calcula esta direccion, dos bytes antes de la tabla (0x4F1E)",
        0x4F24: "casilla cero de pantallas_de_la_prueba: 0x4261 la carga asi, "
                "dos bytes antes de la tabla (0x4F26)",
        0x4F2C: "casilla cero de marcador_de_la_prueba: 0x4933 la carga asi, "
                "dos bytes antes de la tabla (0x4F2E)",
        0x6E62: "casilla cero de punteros_de_melodia: 0x6C32 indexa desde uno "
                "y registra esta direccion, dos bytes antes (0x6E64)",
    },
}
EXCEPCIONES = CASILLAS_CERO[CUAL]

# La segunda es citar una direccion DEL HERMANO al compararse con el. Es
# legitimo y es de lo mejor que tiene este proyecto -los doce bytes muertos
# estan en los dos, en direcciones distintas-, asi que se permite cuando la
# frase nombra al hermano. Se mira la vecindad de la cita, no el documento
# entero: nombrarlo en el primer parrafo no da barra libre para el resto.
VECINDAD = 160

# Una direccion citada dentro del texto de un comentario. El listado las escribe
# de las dos formas, asi que se buscan las dos.
CITA = re.compile(r"0x([0-9A-Fa-f]{4})\b|\b([0-9A-Fa-f]{4})h\b")


def lee_notas(ruta):
    """(directiva, direccion, texto) de cada linea con ancla."""
    out = []
    for n, linea in enumerate(open(ruta, encoding="utf-8"), 1):
        m = re.match(r"^([LCBDF])\s+0x([0-9A-Fa-f]+)\s?(.*)$", linea.rstrip("\n"))
        if m:
            out.append((m.group(1), int(m.group(2), 16), m.group(3), n))
    return out


def mapa_del_cartucho():
    """Que direcciones son PRIMER BYTE de instruccion, y cuales son datos."""
    from z80trace import Tracer
    rom = open(ROM, "rb").read()
    t = Tracer(rom, ORG)
    arranques, datos = set(), set()
    for k, a, b in json.load(open(TRAZA))["blocks"]:
        if k == "c":
            p = a
            while p < b:
                n = t.ilen(p)
                if not n:
                    break
                arranques.add(p)
                p += n
        else:
            datos.update(range(a, b))
    return arranques, datos


# LAS PAGINAS QUE COMPARAN LAS DOS COMPILACIONES. Su asunto ES el otro
# cartucho, asi que nombrar sus pruebas y citar sus direcciones no es un copia y
# pega: es de lo que hablan. Se quedan fuera de este control, y solo ellas.
PAGINAS_COMPARATIVAS = ("COMPARISON-TRACK-AND-FIELD.md",
                        "COMPARATIVA-TRACK-AND-FIELD.md")


def vecindad_del_ancla(notas, directiva, addr):
    """Todo el texto que cuelga de una direccion, junto.

    Una cabecera de bloque son varias lineas B con el mismo ancla, y la razon
    por la que una de ellas nombra al hermano puede estar escrita en la de
    arriba. Mirar linea a linea daria un rojo falso.
    """
    return chr(10).join(t for d, a, t, n in notas
                        if a == addr and d == directiva)


def lee_las_paginas():
    """El texto de las paginas de la web, si las hay. (fichero, texto)."""
    out = []
    for patron in ("docs/*.md", "docs/es/*.md"):
        for r in sorted(glob.glob(os.path.join(RAIZ, patron))):
            if os.path.basename(r) in PAGINAS_COMPARATIVAS:
                continue
            out.append((os.path.relpath(r, RAIZ).replace("\\", "/"),
                        open(r, encoding="utf-8").read()))
    return out


def main(argv):
    notas = lee_notas(NOTAS)
    arranques, datos = mapa_del_cartucho()
    fin = ORG + os.path.getsize(ROM)
    print("  %d anotaciones con ancla; %d arranques de instruccion"
          % (len(notas), len(arranques)))

    malas = []
    perdonadas = []

    # 1. Las direcciones que cita el TEXTO
    citadas = 0
    for d, addr, texto, n in notas:
        for m in CITA.finditer(texto):
            v = int(m.group(1) or m.group(2), 16)
            if not (ORG <= v < fin):
                continue            # BIOS, RAM, VRAM: no son de este cartucho
            citadas += 1
            if v in arranques or v in datos:
                continue
            if v in EXCEPCIONES:
                perdonadas.append(("notas linea %d" % n, v, EXCEPCIONES[v]))
                continue
            malas.append((n, d, addr, v, texto.strip()))
    print("  %d direcciones del cartucho citadas dentro de un comentario"
          % citadas)

    # 2. Los nombres de prueba del hermano. Nombrarlos es legitimo cuando la
    # frase se esta COMPARANDO con el -"es el motor que en el cartucho hermano
    # movia el martillo"-, igual que en las paginas de la web: se perdona si el
    # comentario nombra al hermano, y solo entonces.
    cruzados = []
    for d, addr, texto, n in notas:
        for nombre in DEL_HERMANO:
            if nombre.lower() not in texto.lower():
                continue
            # La vecindad es el ANCLA entera, no la linea: una cabecera de
            # bloque se escribe en varias lineas B seguidas y la palabra
            # "hermano" suele caer en la de al lado.
            entero = vecindad_del_ancla(notas, d, addr)
            if NOMBRE_DEL_HERMANO in entero or RC_DEL_HERMANO in entero                     or "hermano" in entero.lower():
                perdonadas.append(("notas linea %d" % n, addr,
                                   "nombra %r comparandose con el hermano"
                                   % nombre))
                continue
            cruzados.append((n, addr, nombre, texto.strip()))
    # 3. El numero de catalogo
    for d, addr, texto, n in notas:
        if RC_DEL_HERMANO in texto and NOMBRE_DEL_HERMANO not in texto:
            cruzados.append((n, addr, RC_DEL_HERMANO, texto.strip()))


    # 4. Y LO MISMO EN LAS PAGINAS DE LA WEB. Los dos cartuchos se parecen
    # tanto que una pagina escrita para uno se copia al otro sin darse cuenta,
    # y entonces publica las pruebas del hermano o una direccion que aqui no
    # existe. Es el mismo fallo que el de las notas, un piso mas arriba.
    paginas = lee_las_paginas()
    if paginas:
        citadas_web = 0
        for fich, texto in paginas:
            for m in CITA.finditer(texto):
                v = int(m.group(1) or m.group(2), 16)
                if not (ORG <= v < fin):
                    continue
                citadas_web += 1
                if v in arranques or v in datos:
                    continue                    # existe aqui: nada que perdonar
                # No existe. Solo entonces se mira si hay razon para citarla.
                cerca = texto[max(0, m.start() - VECINDAD):m.start() + VECINDAD]
                if NOMBRE_DEL_HERMANO in cerca or RC_DEL_HERMANO in cerca                         or "hermano" in cerca.lower():
                    perdonadas.append((fich, v, "la frase compara con el hermano"))
                    continue
                if v in EXCEPCIONES:
                    perdonadas.append((fich, v, EXCEPCIONES[v]))
                    continue
                if True:
                    trozo = texto[max(0, m.start() - 60):m.start() + 20]
                    malas.append((0, "web", 0, v,
                                  "%s: %s" % (fich, " ".join(trozo.split()))))
            for m in re.finditer("|".join(re.escape(x) for x in DEL_HERMANO),
                                 texto, re.I):
                cerca = texto[max(0, m.start() - VECINDAD):m.start() + VECINDAD]
                if NOMBRE_DEL_HERMANO in cerca or RC_DEL_HERMANO in cerca                         or "hermano" in cerca.lower():
                    perdonadas.append((fich, 0, "nombra %r comparandose con "
                                       "el hermano" % m.group(0)))
                    continue
                cruzados.append((0, 0, m.group(0), "en la pagina %s" % fich))
            if RC_DEL_HERMANO in texto:
                cruzados.append((0, 0, RC_DEL_HERMANO, "en la pagina %s" % fich))
        print("  %d paginas de la web; %d direcciones del cartucho citadas en ellas"
              % (len(paginas), citadas_web))

    # La medida del riesgo, si se pasan las notas del hermano
    if len(argv) > 1 and os.path.exists(argv[1]):
        suyas = {t.strip() for d, a, t, n in lee_notas(argv[1])
                 if d == "C" and t.strip()}
        mias = [(a, t.strip(), n) for d, a, t, n in notas
                if d == "C" and t.strip()]
        iguales = [x for x in mias if x[1] in suyas]
        print("  de %d comentarios de linea, %d (%.1f %%) son IDENTICOS a uno "
              "del hermano" % (len(mias), len(iguales),
                               100.0 * len(iguales) / max(1, len(mias))))

    fallo = False
    print()
    for fich, v, por in perdonadas:
        print("  perdonada 0x%04X en %s: %s" % (v, fich, por))
    if malas:
        fallo = True
        print("  FALLO: %d comentarios citan una direccion que en ESTE cartucho"
              " no es ni instruccion ni datos:" % len(malas))
        for n, d, addr, v, texto in malas:
            print("    linea %-5d %s 0x%04X  cita 0x%04X" % (n, d, addr, v))
            print("        %s" % texto[:100])
    else:
        print("  OK: todas las direcciones citadas existen en este cartucho")

    if cruzados:
        fallo = True
        print("  FALLO: %d anotaciones nombran algo del cartucho HERMANO:"
              % len(cruzados))
        for n, addr, nombre, texto in cruzados:
            print("    linea %-5d 0x%04X  dice %r" % (n, addr, nombre))
            print("        %s" % texto[:100])
    else:
        print("  OK: ni un nombre de prueba ni un numero de catalogo del hermano")

    return 1 if fallo else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
