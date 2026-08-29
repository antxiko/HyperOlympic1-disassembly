# Hyper Olympic 1 (Konami, RC-710) — what the binary says

Everything here comes from reading the cartridge or from measuring it in
openMSX. Anything that is a guess is labelled ASSUMPTION.

## 1. There are FOUR events, and one is not from the arcade

0xE016 runs from 1 to 4 and 0xE015 counts twelve rounds, so the four events
three times each. Photographed one by one (`medidas/pruebas.txt`):

    1  100 METER DASH      record 09 SEC 95
    2  LONG JUMP           record 08 M 90
    3  HAMMER THROW        record 83 M 98
    4  400 METER DASH      record 43 SEC 86

The 400 metres does not exist in the Konami arcade machine the game comes from.
Event 4 reuses event 1's screen list and scoreboard: the only thing that changes
is the label on the board, and that label (0x6332) is the 100 metres one with
its first glyph changed from "1" to "4".

## 2. The records are real, but the table was compiled BEFORE 1983

MEASURED in the binary: 0x5174 holds `00 09 95 / 00 08 90 / 00 83 98 /
00 43 86`, which INIT copies to 0xE040. That is 9.95 s in the 100 m, 8.90 m in
the long jump, 83.98 m in the hammer and 43.86 s in the 400 m.

All four are genuine world records. What is **not** true is that they were the
standing records when the cartridge came out, which is what this page used to
say:

| event | the cartridge | whose and when | still standing in 1984? |
|---|---|---|---|
| 100 m | 9.95 | Jim Hines, Mexico, October 1968 | **no**: Calvin Smith ran 9.93 on 3 July 1983 |
| long jump | 8.90 | Bob Beamon, Mexico, October 1968 | yes, and until 1991 |
| hammer | 83.98 | Sergey Litvinov, 1982 | **no**: Litvinov himself took it to 84.14 in 1983 |
| 400 m | 43.86 | Lee Evans, Mexico, October 1968 | yes, and until 1988 |

**The table was compiled before the 1983 season.** The two still standing were
the Mexico 68 marks, untouched for fifteen years; the other two had already been
beaten by the time the cartridge reached the shops. The same pattern shows up in
the sibling cartridge, and there it is even clearer.

The 100 m error was caught by **Araubi**, and it is the kind of error that
teaches something: the measurable part —that the ROM holds 9.95— was right; what
was wrong was the sentence around it, which added to the binary a claim the
binary does not make. The dates in this table do not come from the cartridge but
from the published record progressions; they are given as what they are, an
outside cross-check.

## 3. The clock was worked out for 60 Hz, and in Europe it lies

0x5695 adds 1.665 hundredths per frame. Measured: on a 50 Hz MSX the game clock
advances 0.8325 seconds per real second, and on a 60 Hz one it advances 0.9990.
On a European machine a "12.00" is really 14.4 seconds. The figures and the
method are in `medidas/reloj.md`.

## 4. The cartridge does not store screens: it stores scripts

There are four different interpreters, each with its own format:

  - 0x4D09 the long script, with five kinds of order (bytes with RLE, strings of
    glyphs, large-letter labels, fills and repeating a pattern)
  - 0x4AFE the short script, for loose text
  - 0x4C63 the label, which is stretched into large letters afterwards
  - 0x7A1F the figure, which expands into character codes

The 2.5 KB from 0x5C96 to 0x668E are entirely scripts and script data. A walk
from the roots covers them without leaving a byte loose (`tools/cobertura.py`).

## 5. The large letters are manufactured, not stored

0x4C49 copies NORMAL 8x8 glyphs to 0xE230 and then 0x4CAB makes three passes
pulling the top two bits out of each byte and pushing them into the byte eight
positions earlier. With that, a string of eight glyphs yields four rows of
pattern: the letter comes out at double size without taking double the ROM.

A measured side effect: type 0 labels declare 24 bytes of length and only carry
16 of their own; the missing eight come from the block behind. The three blocks
at 0x629E, 0x62B0 and 0x62BE overlap this way, one after another.

## 6. The font ran out of X and Z, and the Q arrived late

The 51 glyphs at 0x6002 start out in order: 0..9, the space, and then the
alphabet **from A to Y skipping Q, X and Z**. With A at index 0x0B, P falls at
0x1A and the next one, at 0x1B, is already R.

And yet **the Q exists**. It sits at the end, at index **0x2C**, outside the
alphabet and among the symbols, and the reason shows up in the one word in the
game that needs it: the scoreboard's **QUALIFY**, which at 0x5F87 is the string
`2C 1E 0B 16 13 10 21`. Somebody laid out an alphabet without the three letters
that were not needed, and then had to add one back.

X and Z do not turn up even then: no word in the cartridge uses them.

The whole sheet is in `docs/imagenes/fuente.png`, drawn by `tools/graficos.py`
reading the range the listing declares. This is the kind of thing you only see
by DRAWING it: read as a block, the 51 glyphs are 408 bytes that all look alike.

## 7. Five tables indexed from one

0x49BA advances 2*0xE016 positions BEFORE reading, so the address the code
records falls two bytes ahead of the first useful slot. There are five: the
event labels (the code records 0x4F33 and the table starts at 0x4F35), the
screens (0x4F3B for 0x4F3D), the scoreboards (0x4F43 for 0x4F45), the melodies
(0x6D26 for 0x6D28) and the actor records (0x7B44 for 0x7B46). In the LABEL
table, those two "slot zero" bytes are the 0xFF 0xFF that closes the last menu
message: two bytes doing two jobs.

## 8. The demo's pilot mashes the button at random

The demo does not carry a recorded game: the interrupt plays it. When 0xE002 is
1, 0x4030 drops into 0xE00B a value from `ld a,r` —the memory refresh register—
masked to two bits, once every four frames. That is the whole pilot: random
keypresses.

MIND BIT 7 OF 0xE029. It gives the impression of being the switch, because
0x5849 sets it and 0x4030 reads it, but MEASURED in the emulator
(`medidas/demo.txt`) it is set the same in the demo and in a real game: 0xE029
holds 0x82 in both. The one in charge is 0xE002, which is 1 in the demo and 0 in
a game, and is the first thing the interrupt looks at. In a real game the
made-up keypresses never reach 0xE00B.

## 9. The two athletes move on alternating frames

0x51AD looks at bit 0 of the frame counter: on even frames it moves player 1's
athlete and on odd ones player 2's. Half the work per frame.

## 10. The actors shove each other

The four actor records live BACK TO BACK at 0xE120, 0xE130, 0xE140 and 0xE150.
Bit 2 of the record makes the actor bump the counter of the record 0x11 bytes
behind it, and bit 3 the one 0x0F ahead. That is how the scenery drags itself
along in a chain with nobody keeping a list.

## 11. Konami's hidden mark is NOT there

The trick Manuel Pazos uncovered —the RC-7xx code and the title in katakana
hidden behind the filler at the end of the ROM— does not show up in this
cartridge: the last useful byte is sound player code and only one 0xFF of filler
is left. It was checked with `tools/marca_konami.py`, which in the same run DOES
find it in Pippols (RC-729). Time Pilot, Frogger and Athletic Land do not carry
it either, so this cartridge is not odd on that count.

## 12. This cartridge does not resemble any other Konami in the series

### The method

`tools/comun_konami.py`, which compares raw bytes, only finds a shared routine
if it also landed at the SAME address. For this, `tools/comun_normalizado.py`
was written: it traces both ROMs with their existing disassemblies, decodes the
instructions, zeroes the sixteen-bit operands —which are the ones carrying
addresses— and looks for common runs over that stream. That way a routine
reassembled somewhere else DOES show up.

A control, so we know the method measures something: Frogger against Time Pilot,
already known to share a sound player, gives 667 bytes in 15 runs (13.7 % of
Frogger, 7.5 % of Time Pilot). The raw method gave 354.

### The figures

    against               bytes in common   % of Hyper Olympic 1   longest run
    -------------------   ---------------   --------------------   -----------
    Hyper Olympic 2                 6,298                 67.5 %       681 B
    Frogger                           175                  1.9 %        42 B
    Super Cobra                       173                  1.9 %        37 B
    Monkey Academy                    103                  1.1 %        37 B
    Konami's Billiards                105                  1.1 %        36 B
    Athletic Land                     120                  1.3 %        32 B
    Pippols                            64                  0.7 %        22 B
    Time Pilot                         21                  0.2 %        21 B

### What comes out of that

Hyper Olympic 1 and 2 are the SAME program: two thirds of the code is shared,
and the longest run is 681 consecutive bytes (0x7B27 here, 0x7B52 there) — whole
routines reassembled somewhere else.

With the other Konami MSX cartridges in the series the difference is two orders
of magnitude: none goes past 2 %, and their longest runs go from 21 to 42 bytes.
There is NO trace of Frogger and Time Pilot's sound player, nor of Athletic
Land's framework: 175 bytes spread over scattered runs is not a shared
component.

Frogger's 42 bytes are the exception worth looking at, and it is noted here: it
is more than two programs from the same house give by coincidence, and the
routine has not been identified. Even so, it is 42 against 681.

So: the two Hyper Olympics belong to neither of the two Konami frameworks
already measured in this series. They are a THIRD, and so far it has just two
members.
