# The two builds of each cartridge: HYPER OLYMPIC and TRACK & FIELD

Two different 16,384-byte dumps circulate for Hyper Olympic 1 (RC-710) and two
for Hyper Olympic 2 (RC-711). This document measures how they differ, byte by
byte, cross-referencing every stretch against the disassembly, which accounts
for 100 % of each cartridge.

The short answer, number first: **no, it is not only the logo — although by
volume it nearly is.** In Hyper Olympic 1, 1,143 bytes out of 16,384 really
change (6.98 %), and 860 of them are the title-screen script, where the logo
lives: that leaves **283 bytes of change outside the logo**. In Hyper Olympic
2, 1,047 bytes change (6.39 %), 850 in the title script and **197 outside**.
And among those outside bytes there is **code**, not just decoration.

---

## The four files

| cartridge | build | sha256 | bytes |
|---|---|---|---|
| RC-710 | HYPER OLYMPIC 1 | `0cd8a7928e10a8551d7f6fd68943a6d4a008e04a254d258413c120dda18b792e` | 16384 |
| RC-710 | TRACK & FIELD 1 | `b8988e622d10461140951ef5d072ce4f1ef66e6a8b8d795788cb3e2988338eb6` | 16384 |
| RC-711 | HYPER OLYMPIC 2 | `f254764f4bd1634f50abcdabe5813d133d719197216071772845983ffabad22d` | 16384 |
| RC-711 | TRACK & FIELD 2 | `b0cb044eb80c0cdd359e39a0f1b8727dba91de3e6de28a3ba4426a474eeafc52` | 16384 |

Below, **A** is the HYPER OLYMPIC build (the one that is disassembled) and
**B** the TRACK & FIELD build.

### About the publisher's name

MEASURED: **not one byte in any of the four ROMs says who published it.** There
is no ASCII text in any of them: searching for `SONY`, `KONAMI`, `HITBIT`,
`TRACK`, `FIELD`, `OLYMPIC`, `HYPER`, `1984` and `(C) 19` with `strings -n 3`
returns nothing. Nor do they carry Konami's hidden mark (see below). The only
thing the binary states about identity is **the label it draws on screen**, and
that does change: one build shows HYPER OLYMPIC and the other TRACK & FIELD.

That is why this document names them after their on-screen label. If one of
them is called "the Sony one", that comes from outside the binary, not from the
binary.

---

## Why the raw diff is useless

MEASURED: compared byte for byte at the same offset, **15,107 of 16,384** bytes
differ on the RC-710 (92.2 %) and **15,696 of 16,384** on the RC-711 (95.8 %).
That number means nothing: the cartridge header already declares a different
INIT — **0x4081 in A and 0x4080 in B** — and from there **the whole ROM is
shifted**, so nearly every 16-bit operand lands a little further along or a
little further back.

Aligning the two builds first, the bytes that fail to match drop to **1,379
(8.4 %)** on the RC-710 and **1,263 (7.7 %)** on the RC-711. Separating what
has merely moved from what has changed leaves the 1,143 and 1,047 bytes of the
summary.

The shift between the two RC-710 builds keeps changing along the cartridge:

```
A 0x4010-0x407E  ->  B 0x4010-0x407E    +0
A 0x4081-0x4099  ->  B 0x4080-0x4098    -1     (INIT starts one byte earlier)
A 0x409A-0x474F  ->  B 0x409E-0x4753    +4
A 0x4750-0x476D  ->  B 0x4757-0x4774    +7
A 0x4771-0x4775  ->  B 0x4777-0x477B    +6
A 0x4779-0x4793  ->  B 0x477E-0x4798    +5
A 0x4797-0x4E8F  ->  B 0x479B-0x4E93    +4
A 0x4EB7-0x52E3  ->  B 0x4EB8-0x52E4    +1
A 0x52EC-0x5580  ->  B 0x52EC-0x5580     0
A 0x5584-0x55DB  ->  B 0x5583-0x55DA    -1
A 0x55DF-0x5664  ->  B 0x55DD-0x5662    -2
A 0x566A-0x569A  ->  B 0x5667-0x5697    -3
A 0x569F-0x56AD  ->  B 0x569B-0x56A9    -4
A 0x56B0-0x56B2  ->  B 0x56AA-0x56AC    -6
A 0x56B5-0x5730  ->  B 0x56AE-0x5729    -7
A 0x5734-0x578C  ->  B 0x572B-0x5783    -9
A 0x5790-0x5E21  ->  B 0x5786-0x5E17   -10
A 0x5F27-0x65C5  ->  B 0x5F1B-0x65B9   -12
A 0x65CA-0x65E2  ->  B 0x65BB-0x65D3   -15
A 0x65F2-0x660F  ->  B 0x65DD-0x65FA   -21
A 0x6645-0x6B19  ->  B 0x6622-0x6AF6   -35
A 0x6B1A-0x6B58  ->  B 0x6AFA-0x6B38   -32
A 0x6B5E-0x6B77  ->  B 0x6B3C-0x6B55   -34
A 0x6B78-0x7FFE  ->  B 0x6B59-0x7FDF   -31
```

MEASURED: at the end of the cartridge, A leaves **1 byte** of 0xFF padding and
B leaves **32** on the RC-710; on the RC-711, A leaves **2** and B leaves
**12**. The TRACK & FIELD build takes up less room.

---

## 1. The logo

MEASURED. The logo is not stored as a picture: its patterns are uploaded by the
**title-screen long script** (`pantalla_del_titulo`) and placed by the first
four orders of the **menu short script** (`pantalla_del_menu`), on rows 3 to 6
and columns 12 to 21 of the name table.

Running both scripts and comparing the VRAM they leave behind (tool
`tools/pinta_largo.py`, a Python translation of `GUION_LARGO`,
`MONTA_UN_ROTULO`, `LLENA_EL_PAPEL` and `ESTIRA_LAS_LETRAS`), **the entire
graphical difference of the title script falls into 26 stretches, and every one
of them belongs to the logo**:

| VRAM stretch | what it is |
|---|---|
| 0x2100-0x2217 | patterns 0x20-0x43, the logo tiles |
| 0x0178-0x017E, 0x01F0-0x01F7, 0x0210-0x0217 | the colour of patterns 0x2F, 0x3E and 0x42 |

Not one byte of difference in the scenery patterns, the font, the event labels
or the athlete sprites.

The label that comes out:

| cartridge | A | B |
|---|---|---|
| RC-710 | `HYPER 1 / OLYMPIC` | `TRACK 1 / & FIELD` |
| RC-711 | `HYPER 2 / OLYMPIC` | `TRACK 2 / & FIELD` |

![HYPER 1 OLYMPIC](imagenes/ho1_rotulo_A.png) ![TRACK 1 &
FIELD](imagenes/ho1_rotulo_B.png)

![HYPER 2 OLYMPIC](imagenes/ho2_rotulo_A.png) ![TRACK 2 &
FIELD](imagenes/ho2_rotulo_B.png)

The menu script changes too, because the new label uses fewer cells: A writes
59 name-table cells and B writes 56; the three spare ones are 0x38B4, 0x38B5
(row 5, columns 20 and 21) and 0x38D4 (row 6, column 20). Same figure on both
cartridges.

> Note for the `.notes`: the `pantalla_del_menu` block is described as "the
> PLAY SELECT label and the four numbers down the left", but **its first four
> blocks place the game logo**, not PLAY SELECT. PLAY SELECT and the numbers are
> the two blocks behind them (VRAM 0x390B and 0x39AB).

---

## 2. The code

MEASURED. Aligning both builds instruction by instruction — every instruction
normalised, with 16-bit operands and JR/DJNZ displacements zeroed, which is the
method of `porta_notas.py`, which lives in the sibling's repository because
that is the one that received the port, — the result is:

| | RC-710 | RC-711 |
|---|---|---|
| instructions in A / in B | 5032 / 5038 | 5345 / 5348 |
| aligned | 5014 | 5328 |
| identical byte for byte | 4439 | 4700 |
| merely relocated (same destination) | 575 | 628 |
| genuinely changed while aligned | **0** | **0** |
| stretches that do not match | **19** | **14** |

In other words: **of the instructions that pair up, not a single one points
somewhere else.** All the code change sits in 19 stretches (RC-710) and 14
(RC-711), 48 and 39 bytes of A respectively. Here they are.

### 2.1 What changes behaviour

**a) A RAM shadow of the PSG mixer.** On both cartridges.

| | A | B |
|---|---|---|
| RC-710 | `0x6B59  ld a,7 / call 0x0096` (BIOS RDPSG) | `0x6B39  ld a,(0E09Fh)` |
| RC-710 | `0x6B78  ESCRIBE_EL_MEZCLADOR` | `0x6B56  ld (0E09Fh),a` in front |
| RC-710 | INIT, nothing there | `0x4099  ld a,0B8h / call 6B56h` |
| RC-711 | `0x6C95  ld a,7 / call 0x0096` | `0x6C8A  ld a,(0E09Fh)` |
| RC-711 | `0x6CB4  ESCRIBE_EL_MEZCLADOR` | `0x6CA7  ld (0E09Fh),a` in front |
| RC-711 | INIT, nothing there | `0x4099  ld a,0B8h / call 6CA7h` |

A **reads PSG register 7 back** (the mixer) through the BIOS every time it
turns a voice on or off. B **does not read it: it keeps a copy in RAM at
0xE09F** and reads that. INIT seeds the copy with 0xB8, the normal MSX mixer
value (all three tones open, noise off, port A input, port B output), and
writes it to the PSG on the way.

MEASURED: in A's disassembly **no instruction names 0xE09F**; 0xE09F is the
last byte of the 0xE060-0xE09F block, the scoreboards being painted. B
repurposes it as the shadow.

ASSESSMENT (not measured on real hardware): this looks like a compatibility
fix. Reading PSG register 7 back does not behave the same on every machine, and
a RAM copy sidesteps the question.

There is an asymmetry between the two cartridges, and it is MEASURED:

- On the RC-711, `MUEVE_EL_SONIDO` starts in B with
`0x6C45 ld a,(0E09Fh) / 0x6C48 call 6CA7h`: **it rewrites the mixer from the
shadow on every pass.**
- On the RC-710, `MUEVE_EL_SONIDO` starts in B with `0x6AF7 ld a,(0E09Fh)` **and
nothing else**. Register A is overwritten at `0x6B27 ld a,(ix+002h)` before
anyone reads it: that instruction **does nothing**. Three dead bytes.

**b) 0xE022 is cleared when the attempt is retried.** On both cartridges.

```
RC-710   A  0x474A  OTRA_VEZ_A_LA_LINEA:  ld hl,0 / ld (0E02Ch),hl / jp PINTA_EL_TURNO
         B  0x474E                        xor a / ld l,a / ld h,a / ld (0E02Ch),hl
                                          ld (0E022h),a / jp PINTA_EL_TURNO
RC-711   A  0x476F   same as above
         B  0x4773   same as above, with the ld (0E022h),a inserted
```

According to the disassembly, 0xE022 is **who qualifies for the next round**. A
does not touch it when setting the event up again after a failed attempt; B
zeroes it. It is the only code difference that changes a game variable.

**c) RC-711 only: a threshold goes up by one.**

```
A  0x530C  cp 011h        ; "with the other one below 0x11"
B  0x530F  cp 012h
```

This is in `MIRA_SI_HAY_QUE_REFRESCAR`, right after `pop bc / ld a,c`. The
condition "C below 0x11" becomes "C below 0x12". On the RC-710 the same place
(`0x52D2` in A, `0x52D3` in B) carries `cp 011h` in both builds: **the change
is RC-711 only.**

### 2.2 What does not change behaviour

Everything else is either a shorter instruction doing exactly the same thing,
or dead code removed. Each one checked against the state it is reached with:

| where | A | B | why it makes no difference |
|---|---|---|---|
| RC-710 0x407F, RC-711 0x407F | `reti` (`ED 4D`) | `ret` (`C9`) | the H.KEYI hook is entered with CALL; both pop the return address. RETI additionally emits the acknowledge cycle for Z80-family peripherals, which standard MSX hardware does not use. One byte less |
| RC-710 0x476E / 0x4776 | `ld de,0E07Ah` / `ld de,0E094h` | `ld e,7Ah` / `ld e,94h` | D already holds 0xE0 from `0x4765 ld de,0E08Fh` |
| RC-710 0x4794 | `ld hl,0E0A7h` | `ld l,0A7h` | H already holds 0xE0 from `0x478F ld hl,0E020h` |
| RC-710 0x5581 | `ld hl,0E141h` | `ld l,41h` | HL holds 0xE151 from `0x5572` |
| RC-710 0x55DC | `ld hl,0E151h` | `ld l,51h` | HL holds 0xE141 from `0x55CD` |
| RC-710 0x5667, RC-711 0x56A9 | `ld hl,0E0A7h` | `ld l,0A7h` | HL holds 0xE0ED from the preceding `bit 6,(hl)` |
| RC-710 0x5731 | `ld hl,0E02Eh` | `inc l` | HL holds 0xE02D |
| RC-710 0x578D | `ld hl,0E02Eh` | `ld l,2Eh` | HL holds 0xE02C |
| RC-710 0x52E4, RC-711 0x5325 | `ld a,(0E02Eh) / set 5,a / ld (0E02Eh),a` | `push hl / ld hl,0E02Eh / set 5,(hl) / pop hl` | same effect on 0xE02E, one byte less. It changes what is left in A, but what follows is `call GASTA_Y_APUNTA`, which starts with `push de / push hl / ld b,002h` and never looks at it |
| RC-710 0x569D, RC-711 0x56DF | `ld a,066h` | `dec a` | it is reached with A = 0x67 |
| RC-710 0x56B3 | `cp 001h` | `dec a` | only the Z flag is used, and A is overwritten right after |
| RC-711 0x49C6 and 0x4BB7 | `ld b,001h` | `inc b` | reached from a `call` that ends in `djnz`, so B = 0 |
| RC-711 0x4AAD | `dec a / or a / jr nz` | `dec a / jr nz` | `dec a` already sets the Z flag: the `or a` is redundant |
| RC-710 0x56AE | `jr nc,+0` | removed | it jumps to the next instruction: it does nothing |
| RC-711 0x56F0 | `jr nc,+7 / ld a,(0E02Eh) / bit 6,a / jr z,+0` | removed | both paths end up at 0x56F9, where A is reloaded |

---

## 3. The data

MEASURED, block by block from the `.notes`, using the shift map to tell a
relocated pointer from a pointer that really points elsewhere:

| | RC-710 | RC-711 |
|---|---|---|
| named blocks | 92 | 98 |
| identical or merely relocated | 88 | 94 |
| with changed content | **4** | **4** |

The ones that change:

| cartridge | block | A | B | bytes that differ |
|---|---|---|---|---|
| RC-710 | `pantalla_del_titulo` | 860 | 858 | 200 (23 %) |
| RC-710 | `pantalla_del_menu` | 78 | 75 | 7 (9 %) |
| RC-710 | `marcador_del_salto_de_longitud` | 73 | 64 | 11 (15 %) |
| RC-710 | `marcador_del_martillo` | 84 | 70 | 28 (33 %) |
| RC-711 | `pantalla_del_titulo` | 850 | 848 | 200 (24 %) |
| RC-711 | `pantalla_del_menu` | 78 | 75 | 7 (9 %) |
| RC-711 | `marcador_de_la_jabalina` | 64 | 58 | 8 (12 %) |
| RC-711 | `rotulo_110_vallas` | 16 | 16 | 1 (6 %) |

The first two on each cartridge are the logo, already covered. Two things are
left.

### 3.1 The scoreboards: same screen, better packed

MEASURED by running both scripts (`tools/pinta_corto.py`): in all three cases
**the resulting VRAM is identical**, the same 416 addresses (0x3960-0x3AFF) with
the same values. All that changes is the packing.

- `marcador_del_salto_de_longitud`: A paints it in **two blocks** (384 bytes from
0x3960 and 32 from 0x3AE0, which are contiguous) and also splits runs that
could be joined: `32 x 0xB0` plus `32 x 0xB0` in A is `64 x 0xB0` in B. B does
it in **one block**. -9 bytes.
- `marcador_del_martillo`: same with the runs. Where A writes
`run of 10 x 0xC0 / 2 literal bytes C0 C1 / run of 20 x 0xC1`, B writes `run of
11 x 0xC0 / run of 21 x 0xC1`. -14 bytes.
- `marcador_de_la_jabalina` (RC-711): likewise. -6 bytes.

As a control, `marcador_de_los_100_metros` (RC-710) comes out identical in both
builds, the same 74 bytes.

### 3.2 RC-711 only: HURDLERS is corrected

MEASURED. The big-letter label of RC-711's FIRST event, `rotulo_110_vallas`, is
a list of glyph indices closed with 0xFF (the leading 0x11 is the label type).
Indices 0-9 are the digits, 10 is the space, and from 11 up come the letters A
to Y with no Q, X or Z.

```
A  0x64B1   11 0A 01 01 00 0A 12 1E 1B 0E 16 0F 1B 1C 0A FF
                  1  1  0     H  U  R  D  L  E  R  S
B  0x64A6   11 0A 01 01 00 0A 12 1E 1B 0E 16 0F 1C 0A 0A FF
                  1  1  0     H  U  R  D  L  E  S
```

**The HYPER OLYMPIC 2 build writes "110 HURDLERS". The TRACK & FIELD 2 build
writes "110 HURDLES", which is how it is spelt.** It is the only text change on
either cartridge.

![110 HURDLERS](imagenes/ho2_vallas_A.png) ![110
HURDLES](imagenes/ho2_vallas_B.png)

(Both labels drawn with the cartridge's own font at normal size: the cartridge
stretches them to double height before uploading.)

(The glyph table is checked against other labels in the same format: `0x6320`
gives " 100 METER DASH ", `0x6344` gives " LONG JUMP " and `0x6351` gives "
HAMMER THROW " on the RC-710.)

---

## 4. Konami's hidden mark

MEASURED with `tools/marca_konami.py`, the tool that extracts the katakana
title and the RC number Konami hid behind the padding at the end of some
cartridges — a finding by Manuel Pazos (@ManuelPazosMSX), September 2021:
**none of the four ROMs carries it.** The tool exits with code 1 for all four.
This was already known for the two HYPER OLYMPIC builds; the two TRACK & FIELD
ones do not carry it either.

The last useful bytes are 0x7FFE (HYPER OLYMPIC 1), 0x7FDF (TRACK & FIELD 1),
0x7FFD (HYPER OLYMPIC 2) and 0x7FF3 (TRACK & FIELD 2), and what follows is 0xFF
padding, not a mark.

---

## 5. The disassembly serves both

MEASURED, and this is the hardest proof of the lot.

1. Trace the TRACK & FIELD build with `tools/z80trace.py` from its INIT
(0x4080) and its interrupt routine (0x4010). Both come out **with no blind
spots**: 9332 bytes of code on the RC-710 and 9871 on the RC-711. 2. Carry the
annotations across with `porta_notas.py`, which lives in the sibling's
repository because that is the one that received the port. **2307 of 2315**
land on the RC-710 (99.65 %) and **2311 of 2323** on the RC-711 (99.48 %). 3.
Generate the listing with `tools/mkasm.py` and assemble it with pasmo.

```
b8988e622d10461140951ef5d072ce4f1ef66e6a8b8d795788cb3e2988338eb6  ho1sony.bin
b8988e622d10461140951ef5d072ce4f1ef66e6a8b8d795788cb3e2988338eb6  TRACK & FIELD 1
b0cb044eb80c0cdd359e39a0f1b8727dba91de3e6de28a3ba4426a474eeafc52  ho2sony.bin
b0cb044eb80c0cdd359e39a0f1b8727dba91de3e6de28a3ba4426a474eeafc52  TRACK & FIELD 2
```

**Both TRACK & FIELD builds reassemble byte for byte** from the listing that
comes out of the HYPER OLYMPIC disassembly.

The annotations that find no home in the sibling are **exactly the points that
change**, which is a good cross-check:

```
RC-710: OTRA_VEZ_A_LA_LINEA (0x474A), 0x52E7, 0x5667, 0x569D,
        ENCIENDE_O_APAGA_LA_VOZ (0x6B59), 0x55DC
RC-711: OTRA_VEZ_A_LA_LINEA (0x476F), 0x49C6, 0x4AAD, 0x530C, 0x5328,
        0x56A9, 0x56DF, MIRA_EL_LIMITE_DEL_RELOJ (0x56F2),
        ENCIENDE_O_APAGA_LA_VOZ (0x6C95)
```

What `porta_notas.py` does NOT carry across are the D and F directives, that
is, the name and row width of the data blocks: closing a TRACK & FIELD
disassembly properly would mean placing those again — mechanical work, using
the shift map above.

---

## 6. Which one came first

SUPPOSITION, not measured. The binary carries no date and no version number, so
this cannot be settled from the ROM. What is measured is the direction the
changes run in, and it all points the same way:

- the TRACK & FIELD build **removes dead code** the other one has (RC-710
0x56AE, RC-711 0x56F0);
- it **shortens instructions** without changing what they do, in the seventeen
places listed in 2.2;
- it **fixes a spelling mistake** (HURDLERS for HURDLES);
- it **replaces a PSG read-back with a RAM copy**, which is what you do when
something misbehaves on some machine;
- and it ends up smaller: 32 free bytes at the end instead of 1.

All of that is typical of a later revision, but **it is a reading, not a
measurement**: nothing in the binary says which was manufactured first. And in
particular, nothing in the binary says who published which.

One measured detail argues against that reading: on the RC-710, the TRACK &
FIELD build leaves **three dead bytes** in `MUEVE_EL_SONIDO` (`0x6AF7 ld
a,(0E09Fh)`, with A overwritten immediately after) that on the RC-711 are part
of a meaningful `ld a,(0E09Fh) / call ESCRIBE_EL_MEZCLADOR`. Either the patch
was applied to the RC-710 half-finished, or the RC-711 got the rest of it
later. It cannot be decided from here.

---

## Reproducing the measurements

Every tool used in this document lives in `tools/` and writes nothing outside
its own working directory. No ROM is distributed.

```sh
# the shift map between the two builds
python tools/desplazamiento.py A.rom A.trace.json B.rom B.trace.json desp.json

# the full report: code instruction by instruction, data block by block
python tools/informe.py A.rom A.trace.json A.notes B.rom B.trace.json desp.json out.txt

# the summary figures
python tools/cuentas.py A.rom A.trace.json A.notes B.rom B.trace.json desp.json <logo_start> <logo_end>

# what a short script paints, to tell whether two different scripts agree
python tools/pinta_corto.py A.rom 0x65BA B.rom 0x65AE

# what a long script paints, and drawing it
python tools/pinta_largo.py A.rom 0x5C96 0x6002 B.rom 0x5C8C 0x5FF6
python tools/dibuja_rotulo_menu.py A.rom 0x5C96 0x6002 0x4E87 logo.png

# Konami's hidden mark
python tools/marca_konami.py *.rom
```
