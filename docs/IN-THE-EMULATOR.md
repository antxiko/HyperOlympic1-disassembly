# In the emulator

Reading the binary tells you what the code **does**. Some things only tell you
what the code is **worth** once it runs, and that is what openMSX is for.
Everything on this page is measured, and the raw tables are in `medidas/`.

## The house rule

The scripts in `tools/omsx_*.tcl` **only read memory**. The ROM is never
touched: no patches, no changed bytes, nothing forced to execute.

The one exception is declared and is a measurement, not a modification:
`tools/omsx_prueba_n.tcl` stops the machine at 0x4220 —right after
`PARTIDA_NUEVA` (0x4218) sets the round and the event to 1— and writes into
0xE016 the number of the event you want to see. 0xE016 is the game's own
variable, and from there on the cartridge runs by itself, with its data and its
code. What you save is having to qualify in the three previous events to reach
the fourth.

## The four events

With that, they were photographed one by one (`medidas/pruebas.txt`, captures in
`docs/imagenes/`):

| 0xE016 | label that comes up | record it paints |
|---|---|---|
| 1 | 100 METER DASH | 09 SEC 95 |
| 2 | LONG JUMP | 08 M 90 |
| 3 | HAMMER THROW | 83 M 98 |
| 4 | 400 METER DASH | 43 SEC 86 |

All four records match byte for byte the table at 0x5174, which INIT copies to
0xE040: `00 09 95 / 00 08 90 / 00 83 98 / 00 43 86`. So what is on screen and
what the binary says are the same thing, checked from both ends.

## The clock was worked out for 60 Hz

This is the measurement that most changes what you think of the game.

`SUMA_AL_RELOJ` (0x5695) adds to the BCD counter at 0xE0A9-0xE0AB once per
frame, alternating 0x0167 and 0x0166. If the top byte is seconds and the middle
one hundredths, that is 1.67 and 1.66 hundredths: an average of **1.665**, which
is one sixtieth of a second to four figures.

`tools/omsx_reloj.tcl` runs the 100 metres mashing the space bar and samples
0xE0A9-0xE0AB once per emulated second. On two machines:

| machine | Hz | game clock per real second |
|---|---|---|
| Philips VG-8020 (PAL) | 50 | **0.8325 s** — runs 16.75 % short |
| C-BIOS MSX1 JP (NTSC) | 60 | 0.9990 s — spot on |

Both figures come from subtracting two consecutive samples in `reloj_pal.txt`
and `reloj_ntsc.txt`, and they agree with the arithmetic: 50 × 1.665 = 83.25 and
60 × 1.665 = 99.9.

**The consequence:** on a European MSX the times the cartridge shows are not
seconds. A 100 metres timed at 12.00 by the game took 14.4 real seconds. The
qualifying marks at 0x5008 and the world records at 0x5174 are meant for the
Japanese machine.

**And mind reading it backwards.** That is a *period*, not a *speed*: the game
does not run slower in Europe —the athlete moves across the screen at whatever
speed 50 Hz allows— what happens is that **the stopwatch counts short**. Those
are two different claims and only one of them is measured.

## The demo: who is really in charge

When nobody touches anything, the cartridge falls into a demo that plays itself.
The pilot is `INT_CON_MANDOS` (0x4027) dropping into 0xE00B a value from
`ld a,r` masked to two bits, once every four frames: random keypresses.

Reading the listing, the switch **looks** like bit 7 of 0xE029, because 0x5849
sets it and 0x4030 reads it. `tools/omsx_demo.tcl` samples both situations
without touching anything, first letting the demo run and then starting a real
game, and this comes out (`medidas/demo.txt`, abridged):

| | 0xE002 | 0xE029 |
|---|---|---|
| demo | **01** | 0x82 |
| game | **00** | 0x82 |

**0xE029 holds the same value in both.** The one in charge is 0xE002, which is
the first thing the interrupt looks at: if it is zero it reads the real
controls, and if not it makes the keypresses up. In a real game the made-up ones
never reach 0xE00B.

It is a good example of why you have to measure: reading the code, the bit 7
hypothesis was reasonable, well built, and false.

## The menu, measured on the title capture

Four lines, and what each one leaves in memory:

| line | 0xE01B |
|---|---|
| 1PLAYER with JOYSTICK | 1 |
| 2PLAYERS with JOYSTICK | 2 |
| 1PLAYER with KEYBOARD | 3 |
| 2PLAYERS with KEYBOARD | 4 |

`EMPIEZA_LA_PARTIDA` (0x41BC) splits it up: bit 0 of 0xE01B gives the number of
players (0xE010) and the value being below 3 gives the controller (0xE004). One
variable with both answers inside it.

## How to repeat it

```sh
openmsx -machine Philips_VG_8020 -cart hyperolympic1.rom \
        -script tools/omsx_reloj.tcl
PRUEBA=3 openmsx -machine Philips_VG_8020 -cart hyperolympic1.rom \
        -script tools/omsx_prueba_n.tcl
```

The tables that come out land in `work/omsx/`. The ones in `medidas/` are the
ones this page was written from.
