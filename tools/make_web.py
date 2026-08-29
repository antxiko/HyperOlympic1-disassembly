#!/usr/bin/env python3
"""Genera la portada de la web, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Las imagenes NO son ilustraciones ni montajes. Unas son capturas del cartucho
corriendo en openMSX -hechas con tools/omsx_prueba_n.tcl, que solo cambia el
numero de prueba de 0xE016 y deja que el juego dibuje con sus datos-, y otras
estan dibujadas a partir de los propios bytes de la ROM por tools/graficos.py y
por el interprete de guiones traducido a Python. Ninguna se ha retocado.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras salen de contar sobre el listado generado, no de escribirlas aqui
# a ojo: 16384 = 9335 + 7049, que es lo que imprime tools/presupuesto.py
# (make sanity). RUTINAS son las etiquetas de codigo con nombre propio, las
# mismas que cuenta el .notes con su directiva L. PRUEBAS son los cuatro
# valores que toma 0xE016.
CODIGO = 9335
DATOS = 7049
RUTINAS = 569
PRUEBAS = 4


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Hyper Olympic 1 — desensamblado comentado",
        aviso="<b>Aquí no hay ninguna ilustración.</b> Las pantallas son "
              "capturas del cartucho corriendo en openMSX, tomadas por un "
              "guion que solo cambia el número de prueba que el propio juego "
              "usa como índice; el logotipo y la hoja de la fuente están "
              "<b>dibujados desde los bytes de la ROM</b>, ejecutando en "
              "Python el mismo intérprete de guiones que ejecuta el Z80. El "
              "listado y las cifras salen del binario y se reproducen con "
              "<code>make</code>.",
        claim="Dieciséis kilobytes de atletismo en los que casi nada está "
              "dibujado: las pantallas son guiones que se interpretan, las "
              "letras grandes se fabrican estirando las pequeñas, y el "
              "cronómetro —calculado para una máquina de 60 Hz— cuenta corto "
              "en toda Europa.",
        ficha=["Konami · <b>© Konami 1984</b>",
               "Cartucho <b>RC-710</b>, 16 KB",
               "MSX1 · <b>página 1</b>", "Volcado <b>0cd8a792…</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El código"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("EN-EL-EMULADOR.html", "En el emulador"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El cartucho en cifras", h_find="Lo que apareció al desmontarlo",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(RUTINAS), "rutinas identificadas"),
                (str(PRUEBAS), "pruebas de atletismo"),
                (mil(CODIGO, "es"), "bytes de código"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Debajo de cada imagen está de dónde sale y qué se está "
                 "viendo.",
        pie_leg="Esto es trabajo de documentación y preservación: el código y "
                "los gráficos siguen siendo de sus autores y de Konami, y la "
                "imagen del cartucho no se distribuye.",
    ),
    "en": dict(
        titulo="Hyper Olympic 1 — a commented disassembly",
        aviso="<b>There is not one illustration here.</b> The screens are "
              "captures of the cartridge running in openMSX, taken by a script "
              "that only changes the event number the game itself uses as an "
              "index; the logo and the font sheet are <b>drawn from the bytes "
              "of the ROM</b>, by running in Python the same script "
              "interpreter the Z80 runs. The listing and the numbers come from "
              "the binary and are reproducible with <code>make</code>.",
        claim="Sixteen kilobytes of track and field in which almost nothing is "
              "drawn: the screens are scripts that get interpreted, the large "
              "letters are manufactured by stretching the small ones, and the "
              "stopwatch —worked out for a 60 Hz machine— runs short all over "
              "Europe.",
        ficha=["Konami · <b>© Konami 1984</b>",
               "An <b>RC-710</b> 16 KB cartridge",
               "MSX1 · <b>page 1</b>", "Dump <b>0cd8a792…</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("IN-THE-EMULATOR.html", "In the emulator"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The cartridge in numbers",
        h_find="What turned up when we took it apart",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(RUTINAS), "routines identified"),
                (str(PRUEBAS), "track and field events"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Under each picture is where it comes from and what is on it.",
        pie_leg="This is documentation and preservation work: the code and "
                "artwork still belong to their authors and to Konami, and the "
                "cartridge image is not distributed.",
    ),
}

HALLAZGOS = {
    "es": [
        ("Una prueba nueva por el precio de un carácter",
         "<p>El cartucho tiene cuatro pruebas y <b>los 400 metros no existen "
         "en el arcade</b> del que viene. Aparecen aquí sin costar casi nada: "
         "la prueba 4 reaprovecha la lista de pantallas y el marcador de la 1, "
         "y lo único que cambia es el rótulo de la pizarra.</p>"
         "<p>Ese rótulo, en 0x6332, <b>es el de los 100 metros con el primer "
         "glifo cambiado de «1» a «4»</b>. Un byte.</p>"),
        ("El cronómetro está calculado para 60 Hz",
         "<p>0x5695 suma al reloj de la prueba 1,665 centésimas por cuadro, "
         "que es un sesentavo de segundo. Medido en openMSX en dos máquinas, "
         "con el mismo guion:</p>"
         "<pre class=\"asm\">Philips VG-8020 (PAL)   50 Hz   0,8325 s de juego por segundo real\n"
         "C-BIOS MSX1 JP (NTSC)   60 Hz   0,9990 s de juego por segundo real</pre>"
         "<p>En un MSX europeo <b>un «12,00» son 14,4 segundos de verdad</b>. "
         "Y ojo con leerlo al revés: eso es un periodo, no una velocidad. El "
         "juego no va lento; el que cuenta corto es el cronómetro. Las marcas "
         "de clasificación y los récords están pensados para la máquina "
         "japonesa.</p>"),
        ("La tabla de récords se compiló antes de la temporada de 1983",
         "<p>0x5174 lleva <code>00 09 95 / 00 08 90 / 00 83 98 / 00 43 86</code>, "
         "que INIT copia a 0xE040: 9,95 en los 100 m, 8,90 en longitud, 83,98 "
         "en martillo y 43,86 en los 400. Los cuatro son récords del mundo de "
         "verdad, pero <b>dos ya estaban batidos</b> cuando el cartucho llegó a "
         "las tiendas: Calvin Smith corrió 9,93 el 3 de julio de 1983 y "
         "Litvinov dejó el martillo en 84,14 ese mismo año.</p>"
         "<p>Los dos que aguantaban eran los de México 68, que llevaban quince "
         "años sin que nadie los tocara. Las fechas no salen del cartucho: son "
         "un cotejo con las progresiones públicas. Del cartucho sale la "
         "cifra.</p>"),
        ("La fuente se quedó sin X y sin Z, y la Q llegó tarde",
         "<p>Los 51 glifos de 0x6002 van ordenados: 0..9, el espacio, y luego "
         "el alfabeto <b>de la A a la Y saltándose la Q, la X y la Z</b>. Con "
         "la A en el índice 0x0B, la P cae en 0x1A y la siguiente ya es la "
         "R.</p>"
         "<p>Y sin embargo la Q existe: está al final, en el índice "
         "<b>0x2C</b>, fuera del alfabeto y entre los símbolos. El motivo es la "
         "única palabra del juego que la necesita, el rótulo <b>QUALIFY</b> del "
         "marcador, que en 0x5F87 es la tira <code>2C 1E 0B 16 13 10 21</code>. "
         "Alguien montó el alfabeto sin las tres letras que no hacían falta, y "
         "después tuvo que añadir una.</p>"
         "<p>Esto es de lo que solo se ve <b>dibujando</b>: leyendo el bloque, "
         "los 51 glifos son 408 bytes iguales. La hoja está más abajo.</p>"),
        ("Las letras grandes no están guardadas: se fabrican",
         "<p>0x4C49 copia los glifos <b>normales</b> de 8x8 a un papel en RAM, "
         "y 0x4CAB da tres pasadas sacando los dos bits altos de cada byte y "
         "metiéndolos en el byte de ocho posiciones antes. Una fila de ocho "
         "glifos da cuatro filas de patrón: la letra sale al doble sin ocupar "
         "el doble en la ROM.</p>"
         "<p>El ahorro tiene precio, y está medido: tres rótulos declaran "
         "veinticuatro bytes de largo y solo llevan dieciséis suyos, así que "
         "<b>se llevan ocho del bloque de detrás</b>.</p>"),
        ("El piloto de la demo aporrea el botón al azar",
         "<p>La demo no lleva una partida grabada: la juega la interrupción. "
         "Con 0xE002 a 1, 0x4030 mete en 0xE00B un valor de <code>ld a,r</code> "
         "—el registro de refresco de la memoria— enmascarado a dos bits, una "
         "vez cada cuatro cuadros. Eso es todo el piloto.</p>"
         "<p>Y hay una trampa que solo caza el emulador. El bit 7 de 0xE029 "
         "<b>parece</b> el interruptor de la demo, porque 0x5849 lo pone y "
         "0x4030 lo mira; pero muestreado en las dos situaciones vale igual en "
         "la demo y en una partida de verdad. El que manda es 0xE002.</p>"),
        ("Los actores se empujan unos a otros por su posición en la RAM",
         "<p>Las cuatro fichas de actor viven <b>seguidas</b> en 0xE120, "
         "0xE130, 0xE140 y 0xE150, de dieciséis bytes cada una. El bit 2 de una "
         "ficha hace que ese actor suba el contador de la que tiene 0x11 bytes "
         "por detrás, y el bit 3 el de la que tiene 0x0F por delante.</p>"
         "<p>Así el decorado se arrastra en cadena sin que nadie lleve una "
         "lista de quién empuja a quién: <b>la relación está en la distancia "
         "entre las fichas</b>.</p>"),
        ("No pertenece a ninguna de las dos familias Konami ya medidas",
         "<p>Comparando el código con los operandos de dieciséis bits puestos a "
         "cero —para que una rutina reensamblada en otro sitio también se "
         "vea—, este cartucho comparte <b>6.298 bytes, el 67,5 %</b>, con su "
         "cartucho hermano. Con cualquier otro cartucho Konami de MSX de esta "
         "serie no llega al 2 %, y el tramo común más largo es de veintitrés "
         "bytes: lo que dan por casualidad dos programas de la misma casa.</p>"
         "<p>O sea que los dos Hyper Olympic no son ni el armazón de unos ni el "
         "de los otros. Son un <b>tercero</b>, y de momento solo tiene dos "
         "miembros. Las cifras completas, una por cartucho, están en "
         "Hallazgos.</p>"),
        ("No lleva la marca oculta de Konami",
         "<p>Muchos cartuchos de la casa esconden al final de la ROM su número "
         "de catálogo RC-7xx y el título en katakana, detrás del relleno; lo "
         "descubrió <b>Manuel Pazos</b> "
         "(<a href=\"https://twitter.com/ManuelPazosMSX\">@ManuelPazosMSX</a>).</p>"
         "<p>Aquí no está: el último byte útil es código del reproductor de "
         "sonido y solo queda un <code>0xFF</code> de relleno. Se comprobó con "
         "<code>tools/marca_konami.py</code>, que en el mismo tiro <b>sí</b> la "
         "encuentra en otro cartucho de la casa, así que el método funciona. El "
         "RC-710 viene del catálogo, no del binario.</p>"),
    ],
    "en": [
        ("A new event for the price of one character",
         "<p>The cartridge has four events and <b>the 400 metres does not "
         "exist in the arcade</b> it comes from. It shows up here at almost no "
         "cost: event 4 reuses event 1's screen list and scoreboard, and the "
         "only thing that changes is the label on the board.</p>"
         "<p>That label, at 0x6332, <b>is the 100 metres one with its first "
         "glyph changed from “1” to “4”</b>. One byte.</p>"),
        ("The stopwatch was worked out for 60 Hz",
         "<p>0x5695 adds 1.665 hundredths to the event clock every frame, which "
         "is one sixtieth of a second. Measured in openMSX on two machines, "
         "with the same script:</p>"
         "<pre class=\"asm\">Philips VG-8020 (PAL)   50 Hz   0.8325 s of game time per real second\n"
         "C-BIOS MSX1 JP (NTSC)   60 Hz   0.9990 s of game time per real second</pre>"
         "<p>On a European MSX <b>a “12.00” is really 14.4 seconds</b>. And "
         "mind reading that backwards: it is a period, not a speed. The game is "
         "not running slow; the stopwatch is counting short. The qualifying "
         "marks and the records are meant for the Japanese machine.</p>"),
        ("The record table was compiled before the 1983 season",
         "<p>0x5174 holds <code>00 09 95 / 00 08 90 / 00 83 98 / 00 43 86</code>, "
         "which INIT copies to 0xE040: 9.95 in the 100 m, 8.90 in the long "
         "jump, 83.98 in the hammer and 43.86 in the 400 m. All four are real "
         "world records, but <b>two had already been beaten</b> by the time the "
         "cartridge reached the shops: Calvin Smith ran 9.93 on 3 July 1983 and "
         "Litvinov took the hammer to 84.14 that same year.</p>"
         "<p>The two that were still standing were the Mexico 68 marks, "
         "untouched for fifteen years. The dates do not come from the "
         "cartridge: they are a cross-check against the published progressions. "
         "What comes from the cartridge is the figure.</p>"),
        ("The font ran out of X and Z, and the Q arrived late",
         "<p>The 51 glyphs at 0x6002 are in order: 0..9, the space, and then "
         "the alphabet <b>from A to Y skipping Q, X and Z</b>. With A at index "
         "0x0B, P falls at 0x1A and the next one is already R.</p>"
         "<p>And yet the Q exists: it sits at the end, at index <b>0x2C</b>, "
         "outside the alphabet and among the symbols. The reason is the one "
         "word in the game that needs it, the scoreboard's <b>QUALIFY</b>, "
         "which at 0x5F87 is the string <code>2C 1E 0B 16 13 10 21</code>. "
         "Somebody laid out an alphabet without the three letters that were not "
         "needed, and then had to add one back.</p>"
         "<p>This is the kind of thing you only see by <b>drawing it</b>: read "
         "as a block, the 51 glyphs are 408 bytes that all look alike. The "
         "sheet is further down.</p>"),
        ("The large letters are not stored: they are manufactured",
         "<p>0x4C49 copies the <b>normal</b> 8x8 glyphs into a scratch area in "
         "RAM, and 0x4CAB makes three passes pulling the top two bits out of "
         "each byte and pushing them into the byte eight positions earlier. A "
         "row of eight glyphs yields four rows of pattern: the letter comes out "
         "twice the size without taking twice the ROM.</p>"
         "<p>The saving has a price, and it is measured: three labels declare "
         "twenty-four bytes of length and only carry sixteen of their own, so "
         "<b>they take eight from the block behind</b>.</p>"),
        ("The demo's pilot mashes the button at random",
         "<p>The demo does not carry a recorded game: the interrupt plays it. "
         "With 0xE002 at 1, 0x4030 drops into 0xE00B a value from "
         "<code>ld a,r</code> —the memory refresh register— masked to two bits, "
         "once every four frames. That is the whole pilot.</p>"
         "<p>And there is a trap only the emulator catches. Bit 7 of 0xE029 "
         "<b>looks</b> like the demo switch, because 0x5849 sets it and 0x4030 "
         "reads it; but sampled in both situations it holds the same value in "
         "the demo and in a real game. The one in charge is 0xE002.</p>"),
        ("The actors shove each other by where they sit in RAM",
         "<p>The four actor records live <b>back to back</b> at 0xE120, 0xE130, "
         "0xE140 and 0xE150, sixteen bytes each. Bit 2 of a record makes that "
         "actor bump the counter of the one 0x11 bytes behind it, and bit 3 the "
         "one 0x0F ahead.</p>"
         "<p>That is how the scenery drags itself along in a chain with nobody "
         "keeping a list of who pushes whom: <b>the relationship is the "
         "distance between the records</b>.</p>"),
        ("It belongs to neither of the two Konami families already measured",
         "<p>Comparing the code with all sixteen-bit operands zeroed —so that a "
         "routine reassembled somewhere else still shows up— this cartridge "
         "shares <b>6,298 bytes, 67.5 %</b>, with its sibling cartridge. With "
         "any other Konami MSX cartridge in this series it does not reach 2 %, "
         "and the longest common run is twenty-three bytes: what two programs "
         "from the same house give by coincidence.</p>"
         "<p>So the two Hyper Olympics are neither one framework nor the other. "
         "They are a <b>third</b>, and so far it has just two members. The full "
         "figures, one row per cartridge, are in Findings.</p>"),
        ("It does not carry Konami's hidden mark",
         "<p>Many cartridges from the house hide their RC-7xx catalogue number "
         "and the game's title in katakana at the end of the ROM, behind the "
         "filler; it was <b>Manuel Pazos</b> "
         "(<a href=\"https://twitter.com/ManuelPazosMSX\">@ManuelPazosMSX</a>) "
         "who found that out.</p>"
         "<p>Not here: the last useful byte is sound player code and only one "
         "<code>0xFF</code> of filler is left. It was checked with "
         "<code>tools/marca_konami.py</code>, which in the same run <b>does</b> "
         "find it in another cartridge from the house, so the method works. The "
         "RC-710 comes from the catalogue, not from the binary.</p>"),
    ],
}

GALERIA = [
    ("titulo.png",
     "La pantalla del título, con el logotipo que monta el guion de "
     "<code>pantalla_del_menu</code> y las cuatro líneas del menú. La que se "
     "elija deja en 0xE01B un número del 1 al 4, y de ahí salen el número de "
     "jugadores y el mando",
     "The title screen, with the logo assembled by the "
     "<code>pantalla_del_menu</code> script and the four menu lines. Whichever "
     "you pick leaves a number from 1 to 4 in 0xE01B, and from that come the "
     "number of players and the controller"),
    ("prueba1-100m.png",
     "Prueba 1, los 100 metros lisos, con el récord del mundo que guarda el "
     "cartucho: 09 SEC 95. Es la única prueba en la que los dos atletas corren "
     "a la vez, y se mueven en cuadros alternos",
     "Event 1, the 100 metre dash, showing the world record the cartridge "
     "keeps: 09 SEC 95. It is the only event where both athletes run at once, "
     "and they move on alternating frames"),
    ("prueba2-longitud.png",
     "Prueba 2, el salto de longitud, con el 08 M 90 de Beamon. La carrera es "
     "la misma rutina que la de los 100 metros; lo propio del salto es la "
     "batida y el vuelo, que sale de la única cuenta de verdad del cartucho",
     "Event 2, the long jump, with Beamon's 08 M 90. The run-up is the very "
     "routine used by the 100 metres; what belongs to the jump is the take-off "
     "and the flight, which comes out of the only real piece of arithmetic in "
     "the cartridge"),
    ("prueba3-martillo.png",
     "Prueba 3, el lanzamiento de martillo, con 83 M 98. El atleta gira "
     "mientras se pulsa el botón y suelta con el ángulo que marca la barra; el "
     "vuelo lo calcula el mismo trozo de código que el salto",
     "Event 3, the hammer throw, with 83 M 98. The athlete spins while the "
     "button is held and lets go at the angle the bar shows; the flight is "
     "computed by the same piece of code as the jump"),
    ("prueba4-400m.png",
     "Prueba 4, los 400 metros, con 43 SEC 86. Ésta no existe en el arcade: "
     "reaprovecha entero el decorado y el marcador de la prueba 1, y su rótulo "
     "es el de los 100 metros con el primer glifo cambiado",
     "Event 4, the 400 metres, with 43 SEC 86. This one does not exist in the "
     "arcade: it reuses event 1's scenery and scoreboard whole, and its label "
     "is the 100 metres one with the first glyph swapped"),
    ("fuente.png",
     "Los 51 glifos de la fuente, dibujados desde la ROM por "
     "<code>tools/graficos.py</code>. Se ve de un vistazo lo que el listado "
     "afirma: no hay X ni Z, y la Q está al final, fuera del alfabeto",
     "The 51 glyphs of the font, drawn straight from the ROM by "
     "<code>tools/graficos.py</code>. You can see at a glance what the listing "
     "claims: there is no X and no Z, and the Q sits at the end, outside the "
     "alphabet"),
]


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    # El "logotipo" de la cabecera no es un montaje: es el rotulo que el propio
    # cartucho dibuja en su pantalla de titulo, sacado ejecutando su guion.
    ruta_logo = os.path.join(imgdir, "ho1_rotulo_A.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Hyper Olympic 1">'
                if os.path.exists(ruta_logo) else "<h1>Hyper Olympic 1</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' · '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
