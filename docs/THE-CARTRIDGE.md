# The cartridge

Sixteen kilobytes on page 1, without a single bank switch. Everything the game
does fits between 0x4000 and 0x7FFF.

## The header

The first sixteen bytes are the header the BIOS reads: the `AB` signature and
four pointers. **Only INIT has a value** (0x4081); STATEMENT, DEVICE and TEXT
are all zero. So the cartridge adds no commands to BASIC and does not declare
itself as a device: it boots and keeps the machine.

## What INIT does, and why it never returns

INIT sets up house and leaves:

1. hooks the interrupt at **H.KEYI** (0xFD9A) with a `jp` to 0x4010;
2. clears 0xE000-0xE3FE and puts the stack right above it, at 0xE3FE;
3. silences the PSG —the three tone registers to zero— and leaves it with
   channel A at volume 8 and the mixer at 0xA2;
4. turns off the CAPS lamp;
5. copies the four world records from 0x5174 to 0xE040;
6. puts the menu arrow on the first line.

From then on **the main program and the interrupt split the work**. The
interrupt carries the clock, the controls and anything that has to go at screen
rate; the main program, the game's state machine.

## The memory map

Working RAM is 0xE000-0xE3FE, with the stack at the very top. It is laid out in
zones, and each one has its explanation in the listing:

| range | what it is |
|---|---|
| 0xE000-0xE001 | frame counter and wait in units of 32 |
| 0xE002-0xE017 | the state of the game: who plays, with what, round and event |
| 0xE019-0xE01C | the menu: where the arrow is and which line is picked |
| 0xE01D-0xE01E | the interrupt's two semaphores |
| 0xE020-0xE02E | the state of the attempt and the event, bit by bit |
| 0xE040-0xE04B | the four world records, three BCD bytes each |
| 0xE051-0xE052 | this round's mark to beat |
| 0xE060-0xE09F | the scoreboards as painted |
| 0xE0A0-0xE0FF | the two athletes: speed, angle, mark and pose |
| 0xE120-0xE15F | four 16-byte actor records |
| 0xE160-0xE190 | the sound player's three channels |
| 0xE200-0xE22F | the state of the distance events |
| 0xE230-0xE2CF | the scratch area where figures are assembled before upload |

## The interrupt's two semaphores

They deserve their own section, because they are the reason this does not fall
apart.

- **0xE01E, the lock.** If it is set, the interrupt leaves without touching
  anything. It is used by whoever cannot afford to be interrupted halfway.
- **0xE01D, the flag.** The interrupt sets it on the way in. It is read by
  whoever was setting a VRAM address: if the interrupt went through in the
  middle, that address is no longer valid and has to be set again.

The second one is the fine trick. Setting an address in the VDP is two writes to
the control port, and if the interrupt slips in between them —and it writes to
the VDP too— whatever comes next gets written in the wrong place. Rather than
forbid the interrupt, you let it through and check afterwards.

## The screen

SCREEN 2, with its three thirds:

| table | address |
|---|---|
| names | 0x3800 |
| patterns | 0x2000 |
| colour | 0x0000 |
| sprite attributes | 0x3B00 |
| sprite patterns | 0x1800, 16x16 |

The eight VDP registers come from `registros_del_vdp` (0x4E73).

In the listing, VRAM addresses appear **with bit 14 set** (0x4000 added) when
they are about to be written, which is how the VDP wants them: that is why
0x7800 is the name table and 0x5800 the sprite patterns. Worth keeping in mind
when reading a dump, or the numbers will not add up.

## Three tables indexed from one

A pattern that repeats and that misleads when reading the listing: there are
tables whose recorded address falls **two bytes ahead** of the first useful
slot, because the index starts at one and the code advances `2*index` before
reading.

| table | what the code says | where it really starts |
|---|---|---|
| screens (0x49BA) | — | two bytes later |
| melodies | 0x6D26 | 0x6D28 |
| actor records | 0x7B44 | 0x7B46 |

It is not a mistake: slot zero is never used. And in the case of the screen
table those two bytes **do double duty**: they are the `FF FF` that closes the
last menu message. Two bytes with two jobs.

## The actors shove each other

The four actor records live **back to back** at 0xE120, 0xE130, 0xE140 and
0xE150, sixteen bytes each. And that is no accident: bit 2 of a record makes
that actor bump the counter of the one **0x11 bytes behind it**, and bit 3 the
one **0x0F ahead**.

That is how the scenery drags itself along in a chain with nobody keeping a list
of who pushes whom: the relationship is the distance between the records.

## What it does not carry

**Konami's hidden mark is not there.** Many cartridges from the house hide their
RC-7xx catalogue number and the title in katakana at the end of the ROM, behind
the filler; it was **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)) who found that out. Here
the last useful byte is sound player code and only one `0xFF` of filler is left.
It was checked with `tools/marca_konami.py`, which in the same run **does** find
it in another cartridge from the house, so the method works.
