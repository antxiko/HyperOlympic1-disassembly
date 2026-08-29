# What is still not settled, listed one by one

The budget is at 100 %: the cartridge's 16,384 bytes are split between traced
code (9,335) and named data ranges (7,049), and `make sanity` checks it. What
follows is not unassigned bytes but things that are explained with less
certainty than I would like.

## 1. Twelve dead bytes at 0x4E7B

`00 70 38 70 / 00 A0 38 70 / 00 F0 38 F0`. They have the shape of three rows of
the sprite attribute table (row, column, pattern, colour), and they sit right
next to the eight VDP registers. NOBODY reads them: 0x410C only uploads eight
bytes, and no pointer in the ROM lands there. They are also present, byte for
byte identical and just as dead, in Hyper Olympic 2 (at 0x4E64). ASSUMPTION:
they are left over from an earlier version that uploaded three sprites at
start-up.

## 2. INIT sets a VRAM address and writes nothing behind it

At 0x40A6 there is `ld de,081a2h` and a `call` to the routine that sets the VDP
write address. No write to VRAM follows: next comes PSG register 15, the CAPS
lamp and the copy of the records. The address stays set until some other routine
sets it again. ASSUMPTION: it is left over from an earlier version. What IS
measured is that the PSG is not touched there, whatever this listing's comment
said until 2026-08-29.

## 3. The type 0 labels that overlap

0x629E, 0x62B0 and 0x62BE declare 24 bytes of length and only carry 16 of their
own. The decoder (0x4C63) keeps reading and takes the first eight of the
following block. That much is MEASURED in the code —the length byte is 0x18 and
the count goes down once per output byte— but it has not been checked in VRAM
that the eight borrowed bytes are the ones the drawing needs. ASSUMPTION: the
saving is deliberate, because those last eight bytes only contribute bits to
0x4CAB's third pass.

## 3. The two patterns at 0x6222 overlap by one byte

The second starts on the last byte of the first. That is what the script's
pointers say; it has not been checked on screen that the result is what is
expected.

## 4. The melodies are not broken down note by note

The block at 0x6D76-0x702D is walked in full from the pointer table and not a
byte is left loose, but the listing publishes it as a single data range. Pulling
each melody out with its own name would be needed to hear them separately.

## 5. Exactly what each bit of 0xE02E does

Bits 0, 1 and 2 are clear (attempt over, event over, time up) because there is
code that sets them and code that reads them. Bits 3, 5, 6 and 7 are used inside
the race motor and are commented for what they do at each site, but they have
not been given a single name.

## 6. Fifteen large-letter labels go by address

The NINETEEN large-letter labels, from 0x619A to 0x6362, are delimited by the
walk over the scripts, but only FOUR have a name of their own: the four events'.
The other FIFTEEN are published as `rotulo_XXXX`. Naming them would mean drawing
them one by one.
