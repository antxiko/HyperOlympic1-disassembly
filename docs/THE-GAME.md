# The game

Hyper Olympic 1 is the MSX conversion of Konami's athletics arcade machine,
known in the West as *Track & Field*. You play it by hammering keys: two to run
and one to jump or throw.

## Four events, twelve rounds

`0xE016` runs from 1 to 4 and picks the event; `0xE015` counts up to twelve. So
**the four events, three times each**. Photographed one by one in the emulator
(`medidas/pruebas.txt`):

| | event | record it shows |
|---|---|---|
| 1 | 100 METER DASH | 09 SEC 95 |
| 2 | LONG JUMP | 08 M 90 |
| 3 | HAMMER THROW | 83 M 98 |
| 4 | 400 METER DASH | 43 SEC 86 |

**The 400 metres does not exist in the arcade.** Event 4 reuses event 1's screen
list and scoreboard; the only thing that changes is the label on the board, and
that label (0x6332) is the 100 metres one with its first glyph changed from "1"
to "4". A new event for the price of one character.

## You have to qualify

Every round has a mark to beat, and they live in `marcas_de_clasificacion`
(0x5008): two BCD bytes per round, which 0x4625 reads with `2*(round-1)`. They
come out as

```
14.00  06.00  80.00  55.00
12.00  07.00  85.00  50.00
11.00  08.00  95.00  40.00
```

The four events repeat three times and **each lap tightens the screw**: in the
100 metres you have to get under 14, then under 12, then under 11; in the long
jump, past 6, 7 and 8 metres.

Fail to qualify and that is that. `0xE021` carries one bit per player saying
whether they are still in, and `0xE022` who goes through to the next round.

## The attempts

In the throwing and jumping events there is not one run and done: there are four
attempts. `0xE023`/`0xE024` count the ones used up per player and
`0xE025`/`0xE026` the one under way. Each result goes in `0xE02A`/`0xE02B`:
**1 foul, 2 valid, 3 record**.

When an attempt does not count, the scoreboard writes the foul label
(`rotulo_de_fallo`, 0x5133), and two different places ask for it: 0x433A and
0x44D0.

## The clock lies in Europe

The routine that counts the time (0x5695) adds **1.665 hundredths per frame**,
that is, one sixtieth of a second. It was worked out for a 60 Hz machine.

Measured with `tools/omsx_reloj.tcl` on both:

| machine | Hz | game clock per real second |
|---|---|---|
| Philips VG-8020 (PAL) | 50 | **0.8325 s** |
| C-BIOS MSX1 JP (NTSC) | 60 | 0.9990 s |

On a European MSX, **a "12.00" is really 14.4 seconds**. And it is not that the
game runs slow: it is that the clock counts short. The qualifying marks and the
world records are meant for the Japanese machine.

Careful reading that backwards: it is a **period**, not a **speed**. The detail
and the raw tables are in [In the emulator](IN-THE-EMULATOR.md).

## Two players, alternating frames

`0xE010` says whether two are playing and `0xE011` whose turn it is. When both
run at once, 0x51AD looks at bit 0 of the frame counter: **on even frames it
moves player 1's athlete and on odd ones player 2's**. Half the work per frame,
and at 50 or 60 Hz nobody notices.

## The demo plays itself, and plays badly

When nobody touches anything a demo starts. It does not carry a recorded game:
**the interrupt plays it**, and the pilot is about as dumb as you can write.
With `0xE002` at 1, the routine at 0x4030 drops into `0xE00B` a value from
`ld a,r` —the memory refresh register— masked to two bits, once every four
frames. That is all of it: **random keypresses**.

There is one detail that misleads, and it is measured, not assumed. Bit 7 of
`0xE029` looks like the demo switch, because 0x5849 sets it and 0x4030 reads it;
but in the emulator (`medidas/demo.txt`) it is set **the same in the demo and in
a real game**: 0xE029 holds 0x82 in both. The one in charge is `0xE002`, which
is 1 in the demo and 0 in a game, and is the first thing the interrupt looks at.

## The controls

`0xE004` says whether you play with joystick or keyboard, and `0xE005` carries
what was read this frame: bit 0 up, bit 1 down, bit 4 space, bit 5 F5. With a
joystick, the two buttons. For each player **both the previous and the current
controls** are kept (0xE008-0xE00F), which is how you detect an edge rather than
a held key — indispensable in a game built on mashing one.
