#!/usr/bin/env python3
"""Comprobaciones sobre el listado generado.

Ninguna de estas necesita el cartucho: se hacen sobre src/hyperolympic1.asm y
src/hyperolympic1.notes. Lo que vigilan es que el listado
no se degrade sin que nadie se entere: que no desaparezcan comentarios, que no
vuelvan a aparecer bloques de datos sin identificar, y que las cifras que se
publican sean las del arbol.
"""
import os
import re
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASM = os.path.join(RAIZ, "src", "hyperolympic1.asm")
NOTES = os.path.join(RAIZ, "src", "hyperolympic1.notes")
DOCS = os.path.join(RAIZ, "docs")
# Los demas juegos de la serie. Que el nombre de otro aparezca en una pagina de
# este es casi siempre un copia y pega. NO esta el cartucho hermano: nombrarlo
# es legitimo -comparten el 67,5 % del codigo y la web lo cuenta-, y lo que de
# verdad no puede cruzarse, los nombres de SUS cuatro pruebas, lo vigila
# tools/repasa_el_porte.py, que mira las notas y las paginas.
OTROS_JUEGOS = ("Pitfall", "Temptations", "Stardust", "Ale Hop", "Colt 36",
                "Middle Earth", "Monkey", "F-1 Spirit", "Athletic",
                "Antarctic", "Pippols", "Frogger", "Time Pilot",
                "Super Cobra", "Billiards", "Mahjong")

# Las paginas que comparan las dos compilaciones del cartucho. Su asunto es el
# otro binario, asi que nombran cosas suyas a proposito. Es la misma lista que
# tools/repasa_el_porte.py.
COMPARATIVAS = ("COMPARISON-TRACK-AND-FIELD.md",
                "COMPARATIVA-TRACK-AND-FIELD.md")

ORG, FIN = 0x4000, 0x8000


def asm():
    with open(ASM, encoding="utf-8") as f:
        return f.read()


def notas():
    with open(NOTES, encoding="utf-8") as f:
        return f.read().splitlines()


def directivas(clave):
    return [l for l in notas() if l.startswith(clave + " ")]


def direcciones_vivas():
    """Las direcciones del cartucho que existen de verdad en el listado.

    Son las que mkasm.py escribe en la columna de la derecha, mas las de los
    `equ` de la cabecera: los destinos que caen dentro de otra instruccion no
    tienen linea propia y aun asi son direcciones buenas.
    """
    texto = asm()
    vivas = set(re.findall(r";([0-9a-f]{4})(?:\s|$)", texto, re.M))
    vivas |= set(re.findall(r"^\s*(?:defb|defw).*?;\s*([0-9a-f]{4})",
                            texto, re.M))
    vivas |= {d[-4:].lower()
              for d in re.findall(r"equ\s+0x0?([0-9A-Fa-f]{4,5})", texto)}
    # y las que nombran las propias anotaciones: las bases de tabla que caen
    # dentro de una instruccion (0x6B58, 0x7652...) son direcciones buenas y no
    # tienen linea propia en el listado
    todas_las_notas = chr(10).join(notas())
    vivas |= {d.lower()
              for d in re.findall(r"0x([0-9A-Fa-f]{4})", todas_las_notas)}
    vivas.add("7fff")                       # el ultimo byte del cartucho
    return vivas


class TestListado(unittest.TestCase):

    def test_ningun_bloque_de_datos_sin_identificar(self):
        """Cada zona de datos tiene que tener nombre y explicacion."""
        n = asm().count("DATOS sin identificar")
        self.assertEqual(n, 0, "hay %d bloques de datos sin identificar" % n)

    def test_todas_las_rutinas_con_call_tienen_nombre(self):
        """Si algo se llama con CALL es una rutina, y una rutina se bautiza."""
        sueltas = sorted(set(re.findall(
            r"\bcall (?:n?[zc],|p[oe],|[mp],)?(L_[0-9A-F]{4})", asm())))
        self.assertEqual(sueltas, [], "rutinas llamadas y sin nombre: %s"
                         % " ".join(sueltas[:12]))

    def test_no_queda_ninguna_etiqueta_sin_bautizar(self):
        """Aqui se bautizaron las 569, incluidos los destinos de salto."""
        sueltas = sorted(set(re.findall(r"\bL_[0-9A-F]{4}\b", asm())))
        self.assertEqual(sueltas, [], "etiquetas sin nombre: %s"
                         % " ".join(sueltas[:12]))

    def test_ninguna_etiqueta_declarada_dos_veces(self):
        """Dos etiquetas con el mismo nombre y el ensamblador se queja."""
        nombres = re.findall(r"^([A-Za-z_][\w]*):", asm(), re.M)
        repetidas = sorted({n for n in nombres if nombres.count(n) > 1})
        self.assertEqual(repetidas, [], "etiquetas repetidas: %s"
                         % " ".join(repetidas))

    def test_ningun_comentario_de_linea_repetido(self):
        """Dos C en la misma direccion: la segunda pisa a la primera."""
        dirs = [l.split()[1].upper() for l in directivas("C")]
        repes = sorted({d for d in dirs if dirs.count(d) > 1})
        self.assertEqual(repes, [], "comentarios repetidos en %s" % " ".join(repes))

    def test_ninguna_direccion_bautizada_dos_veces(self):
        """Dos L para la misma direccion: una de las dos se pierde en silencio."""
        dirs = [l.split()[1] for l in directivas("L")]
        repes = sorted({d for d in dirs if dirs.count(d) > 1})
        self.assertEqual(repes, [], "direcciones con dos nombres: %s"
                         % " ".join(repes))

    def test_todos_los_comentarios_llegan_al_listado(self):
        """Un comentario anclado a una direccion que ya no existe se pierde."""
        vivas = set(re.findall(r";([0-9a-f]{4})(?:\s|$)", asm(), re.M))
        perdidos = [l.split()[1] for l in directivas("C")
                    if l.split()[1][2:].lower() not in vivas]
        self.assertEqual(perdidos, [], "comentarios que no llegan: %s"
                         % " ".join(perdidos[:12]))

    def test_todas_las_cabeceras_llegan_al_listado(self):
        """Igual con las cabeceras de bloque."""
        vivas = set(re.findall(r";([0-9a-f]{4})(?:\s|$)", asm(), re.M))
        perdidas = sorted({l.split()[1] for l in directivas("B")
                           if l.split()[1][2:].lower() not in vivas})
        self.assertEqual(perdidas, [], "cabeceras que no llegan: %s"
                         % " ".join(perdidas[:12]))

    def test_todas_las_etiquetas_llegan_al_listado(self):
        """Una L cuyo nombre no aparece definido en el .asm es una L perdida."""
        texto = asm()
        perdidas = [l.split()[2] for l in directivas("L")
                    if not re.search(r"^%s:" % re.escape(l.split()[2]), texto, re.M)
                    and not re.search(r"^%s:\s+equ" % re.escape(l.split()[2]),
                                      texto, re.M)]
        self.assertEqual(perdidas, [], "etiquetas que no llegan: %s"
                         % " ".join(perdidas[:12]))

    def test_los_rangos_no_se_solapan(self):
        """Dos D que pisan los mismos bytes: uno de los dos esta mal."""
        rangos = sorted((int(l.split()[1], 16), int(l.split()[2], 16),
                         l.split()[3]) for l in directivas("D"))
        for (a1, b1, n1), (a2, b2, n2) in zip(rangos, rangos[1:]):
            self.assertLessEqual(b1, a2, "%s (%04X-%04X) pisa a %s (%04X-%04X)"
                                 % (n1, a1, b1, n2, a2, b2))

    def test_todos_los_rangos_van_al_derecho_y_dentro(self):
        """Un rango acaba despues de empezar, y cae dentro del cartucho."""
        for l in directivas("D"):
            a, b, nombre = int(l.split()[1], 16), int(l.split()[2], 16), l.split()[3]
            self.assertLess(a, b, "%s va del reves" % nombre)
            self.assertGreaterEqual(a, ORG, "%s empieza fuera" % nombre)
            self.assertLessEqual(b, FIN, "%s acaba fuera" % nombre)

    def test_todos_los_rangos_estan_explicados(self):
        """Un nombre no basta: cada D lleva su explicacion detras."""
        pelados = [l.split()[3] for l in directivas("D") if len(l.split()) < 5]
        self.assertEqual(pelados, [], "rangos sin explicacion: %s"
                         % " ".join(pelados))

    def test_cada_anchura_cae_en_un_rango(self):
        """Una F cuya direccion no es el principio de una D no hace nada."""
        inicios = {l.split()[1].lower() for l in directivas("D")}
        sueltas = [l.split()[1] for l in directivas("F")
                   if l.split()[1].lower() not in inicios]
        self.assertEqual(sueltas, [], "anchuras sin rango: %s"
                         % " ".join(sueltas[:12]))

    def test_el_listado_lo_genera_la_herramienta(self):
        """El .asm no se edita a mano: sale de mkasm.py."""
        self.assertIn("Generado por tools/mkasm.py", asm())

    def test_no_queda_nada_por_repartir(self):
        """Mientras haya un 'formato pendiente' el trabajo no esta hecho."""
        pendientes = [l for l in notas()
                      if "formato pendiente" in l or "reparto por" in l]
        self.assertEqual(pendientes, [], "quedan %d zonas por repartir"
                         % len(pendientes))

    def test_el_listado_no_habla_de_otro_juego(self):
        """Los comentarios prestados de otro desensamblado se cuelan solos."""
        for juego in OTROS_JUEGOS:
            self.assertNotIn(juego, asm(), "el listado nombra %s" % juego)

    def test_la_raiz_no_habla_de_otro_juego(self):
        """Ni el README, ni el aviso legal, ni los documentos del scroll."""
        otros = OTROS_JUEGOS
        for fichero in ("README.md", "README.es.md", "AVISO-LEGAL.md",
                        "LEGAL-NOTICE.md", "LICENSE"):
            ruta = os.path.join(RAIZ, fichero)
            if not os.path.exists(ruta):
                continue
            with open(ruta, encoding="utf-8") as f:
                texto = f.read()
            for juego in otros:
                self.assertNotIn(juego, texto, "%s nombra %s" % (fichero, juego))



# La web NO entra en este repositorio: el encargo llega hasta el desensamblado
# reproducible y comentado. Los controles de la web se quedan escritos, pero se
# saltan mientras no haya docs/index.html; el dia que se publique, vuelven a
# correr solos y avisan si las dos lenguas se separan.
# La web es parte del repositorio: docs/index.html esta versionado, asi que
# estos tests corren siempre. Mientras no existia, la clase entera se saltaba
# con un skipUnless; se quito al publicarla, porque un skip condicional y un
# test desactivado se parecen demasiado -el analisis forense no los distingue-
# y porque ahora la falta de la portada SI es un fallo que hay que ver en rojo.
class TestWeb(unittest.TestCase):
    """La web es bilingue y se genera: lo que se vigila es que no se separe."""

    PAGINAS = [("GETTING-STARTED.md", "EMPEZAR.md"),
               ("THE-GAME.md", "EL-JUEGO.md"),
               ("THE-CARTRIDGE.md", "EL-CARTUCHO.md"),
               ("THE-CODE.md", "EL-CODIGO.md"),
               ("FINDINGS.md", "HALLAZGOS.md"),
               ("IN-THE-EMULATOR.md", "EN-EL-EMULADOR.md"),
               ("OPEN-QUESTIONS.md", "PREGUNTAS-ABIERTAS.md")]

    def test_cada_pagina_tiene_su_pareja_en_el_otro_idioma(self):
        for en, es in self.PAGINAS:
            self.assertTrue(os.path.exists(os.path.join(DOCS, en)),
                            "falta docs/%s" % en)
            self.assertTrue(os.path.exists(os.path.join(DOCS, "es", es)),
                            "falta docs/es/%s" % es)

    # La pagina de hallazgos SI puede nombrar a los otros cartuchos, y tiene que
    # poder: el hallazgo gordo de este proyecto es la MEDIDA de cuanto codigo
    # comparte con cada uno, y sin decir con quien se compara no es una medida.
    # En las otras trece, un nombre ajeno es un copia y pega.
    PUEDEN_COMPARAR = ("FINDINGS.md", "HALLAZGOS.md")

    def test_las_paginas_no_hablan_de_otro_juego(self):
        for raiz, _, ficheros in os.walk(DOCS):
            for fn in ficheros:
                if not fn.endswith(".md") or fn in self.PUEDEN_COMPARAR:
                    continue
                with open(os.path.join(raiz, fn), encoding="utf-8") as f:
                    texto = f.read()
                for juego in OTROS_JUEGOS:
                    self.assertNotIn(juego, texto,
                                     "%s nombra %s" % (fn, juego))

    def test_las_herramientas_de_la_web_no_hablan_de_otro_juego(self):
        for fn in ("make_web.py", "md2html.py", "graficos.py"):
            with open(os.path.join(RAIZ, "tools", fn), encoding="utf-8") as f:
                texto = f.read()
            for juego in OTROS_JUEGOS:
                self.assertNotIn(juego, texto, "tools/%s nombra %s"
                                 % (fn, juego))

    def test_la_portada_publica_las_cifras_del_arbol(self):
        with open(os.path.join(RAIZ, "tools", "make_web.py"),
                  encoding="utf-8") as f:
            texto = f.read()
        self.assertIn("CODIGO = 9335", texto)
        self.assertIn("DATOS = 7049", texto)

    def test_los_readme_publican_las_cuentas_de_las_notas(self):
        """Las cifras de los README se quedan viejas solas: aqui se atan.

        Se cuentan las directivas del .notes y se exige que los dos README
        publiquen esos mismos numeros. Si se comenta mas codigo y no se toca
        el README, este test se pone rojo.
        """
        cuentas = {clave: len(directivas(clave)) for clave in "LCD"}
        for fichero, filas in (
                ("README.md", (("named labels", "L"),
                               ("anchored comments", "C"),
                               ("explained data ranges", "D"))),
                ("README.es.md", (("etiquetas con nombre", "L"),
                                  ("comentarios anclados", "C"),
                                  ("rangos de datos con explicación", "D")))):
            with open(os.path.join(RAIZ, fichero), encoding="utf-8") as f:
                texto = f.read()
            for rotulo, clave in filas:
                fila = re.search(r"\|\s*%s\s*\|\s*([0-9.,]+)\s*\|"
                                 % re.escape(rotulo), texto)
                self.assertIsNotNone(fila, "%s no publica '%s'"
                                     % (fichero, rotulo))
                dice = int(fila.group(1).replace(".", "").replace(",", ""))
                self.assertEqual(dice, cuentas[clave],
                                 "%s dice %d %s y en las notas hay %d"
                                 % (fichero, dice, rotulo, cuentas[clave]))

    def test_las_paginas_no_inventan_direcciones(self):
        """Cada 0xNNNN del cartucho que se cite tiene que existir de verdad.

        La regla la pone tools/repasa_el_porte.py y aqui se REUTILIZA entera
        -su mapa, su expresion y sus dos excepciones-, no se vuelve a escribir.
        Tener dos reglas parecidas para lo mismo es como se cuelan los rojos
        falsos: la primera version de este test daba por inventada 0x668E, que
        es el ultimo byte del bloque de guiones y existe perfectamente.

        Vale una direccion que sea arranque de instruccion o caiga en un rango
        de datos; una casilla cero declarada; o una del hermano cuando la frase
        que la cita lo nombra. Las dos paginas comparativas se quedan fuera,
        porque su asunto ES el otro cartucho y estan cubiertas por el control
        del OTRO repositorio.
        """
        sys.path.insert(0, os.path.join(RAIZ, "tools"))
        from repasa_el_porte import (mapa_del_cartucho, EXCEPCIONES, CITA,
                                     VECINDAD, NOMBRE_DEL_HERMANO,
                                     RC_DEL_HERMANO)
        arranques, datos = mapa_del_cartucho()
        for raiz, _, ficheros in os.walk(DOCS):
            for fn in ficheros:
                if not fn.endswith(".md") or fn in COMPARATIVAS:
                    continue
                with open(os.path.join(raiz, fn), encoding="utf-8") as f:
                    pagina = f.read()
                for m in CITA.finditer(pagina):
                    v = int(m.group(1) or m.group(2), 16)
                    if not ORG <= v < FIN:
                        continue
                    if v in arranques or v in datos or v in EXCEPCIONES:
                        continue
                    cerca = pagina[max(0, m.start() - VECINDAD):
                                   m.start() + VECINDAD]
                    if NOMBRE_DEL_HERMANO in cerca or RC_DEL_HERMANO in cerca:
                        continue
                    self.fail("%s nombra 0x%04X y no existe" % (fn, v))


if __name__ == "__main__":
    unittest.main()
