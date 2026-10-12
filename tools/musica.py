#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `PIDE_UN_SONIDO` (0x6A92, A = numero; no suena en la demo) y
corre `MUEVE_EL_SONIDO` (0x6B1A), que la interrupcion llama cada cuadro (0x404C).
Los tres canales son tres fichas de 11 bytes desde 0xE162.
Uso:  musica.py registros 0x96 [cuadros] | mp3 0x96 f.mp3 | todas docs/audio
      musica.py barrido 0x80 0xFF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

PIEZAS = [
    P(0x96, "La música del título", "The title tune",
      "`TITULO_SIN_PARPADEO`"),
    P(0x02, "La fanfarria de clasificación", "The qualifying fanfare",
      "la rutina de 0x451F; `PIDE_UN_SONIDO` lo reparte en tres: el 2, el "
      "0x47 y el 0x49"),
    P(0x99, "Récord nuevo", "New record", "`GUARDA_EL_RECORD_NUEVO`"),
    P(0x9C, "La prueba nueva", "The new event", "`SUENA_LA_PRUEBA_NUEVA`"),
    P(0x9F, "El cartel de fin", "The end sign", "`CARTEL_DE_FIN`"),
    P(0x92, "La música que se espera", "The tune that is waited for",
      "`ESPERA_A_QUE_ACABE_LA_MUSICA`"),
    P(0x91, "Una pista de la tabla", "A track in the table",
      "ninguna llamada directa: está en la tabla de pistas"),
    P(0x95, "Otra pista de la tabla", "Another track in the table",
      "ninguna llamada directa: está en la tabla de pistas"),
    P(0xA8, "Una tercera pista de la tabla", "A third track in the table",
      "ninguna llamada directa: está en la tabla de pistas"),
    P(0xA9, "Una cuarta pista de la tabla", "A fourth track in the table",
      "ninguna llamada directa: está en la tabla de pistas"),
]

PAGINA = motor_musica.pagina_basica(
    "`MUEVE_EL_SONIDO`, 0x6B1A, y `PIDE_UN_SONIDO`, 0x6A92, que le reparte "
    "los canales; lo llama la interrupción en 0x404C",
    "`MUEVE_EL_SONIDO`, 0x6B1A, and `PIDE_UN_SONIDO`, 0x6A92, which hands it "
    "the channels; the interrupt calls it at 0x404C",
    "C-BIOS MSX1 japonés",
    [("la música del título (0x96) entera, 642 cuadros",
      "the title tune (0x96), whole, 642 frames"),
     ("la pista 0x91 entera, 511 cuadros, con su vuelta",
      "track 0x91, whole, 511 frames, with its repeat")],
    [("Cómo se pide una pieza",
      "`PIDE_UN_SONIDO` recibe el número en A y no suena en la demo. Los "
      "efectos van por debajo de 0x81 y tienen una, dos o tres voces según "
      "su número; de 0x81 a 0x95 la música usa dos voces y del 0x96 en "
      "adelante tres. Las fichas de los canales están en 0xE162, 0xE16D y "
      "0xE178. Las 0x91, 0x95, 0xA8 y 0xA9 son pistas de la tabla que ninguna "
      "rutina pide con un `ld a`. El motor no escribe el mezclador del PSG: "
      "lo deja el arranque, y aquí se parte de su mismo valor, 0xB8.",
      "How a piece is asked for",
      "`PIDE_UN_SONIDO` takes the number in A and makes no sound in the demo. "
      "Effects are below 0x81 and take one, two or three voices depending on "
      "their number; from 0x81 to 0x95 music uses two voices and from 0x96 "
      "up three. The channel records are at 0xE162, 0xE16D and 0xE178. "
      "Tracks 0x91, 0x95, 0xA8 and 0xA9 are in the table but no routine asks "
      "for them with an `ld a`. The engine never writes the PSG mixer: "
      "start-up leaves it set, and here it starts from that same value, "
      "0xB8.")])

CFG = dict(rom="hyperolympic1.rom", org=0x4000, frame=0x6B1A, pide=0x6A92,
           ram=(0xE162, 0xE184), hz=60, psg0={7: 0xB8}, piezas=PIEZAS,
           pagina=PAGINA, cotejado=[(0x96, 642, None), (0x91, 511, 257)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
