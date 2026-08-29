# Getting started

This repository does not ship the game: it ships the way to build it back from
your own copy and to check that what comes out is exactly the cartridge.

## What you need

Your own dump of the cartridge, in the root and with this name:

| | |
|---|---|
| file | `hyperolympic1.rom` |
| size | 16,384 bytes |
| sha256 | `0cd8a7928e10a8551d7f6fd68943a6d4a008e04a254d258413c120dda18b792e` |

Plus `pasmo`, `z80dasm` and Python 3. For the emulator measurements, openMSX.

## The one command that does it all

```sh
make comprueba   # is this the right dump?
make             # trace, generate the listing, reassemble it and run the tests
```

`make` finishes green or it does not finish. The line that matters is this one:

```
  ensamblado : 16384 bytes  0cd8a792...a18b792e
  original   : 16384 bytes  0cd8a792...a18b792e
OK: reproducible byte a byte
```

## The other commands

```sh
make verify     # the test that decides: reassembling has to give the ROM back
make sanity     # what reassembling CANNOT catch
make densidad   # how much is commented, routine by routine
make imagenes   # draw blocks of the ROM so you can look at them
make test       # the listing tests
make web        # rebuild this website
```

## Why `verify` is not enough

Reassembling and getting the same bytes proves the listing is **faithful**, not
that it is **correct**. If some graphics were being read as instructions the
bytes would come out identical all the same: the only thing lying would be the
listing.

That is why `make sanity` runs three more checks, and those three are the ones
that really earn their keep:

- **no byte declared as data may come out as code**, and the other way round;
- **no entry point may fall inside a data area**;
- **not one byte of the cartridge left unassigned** — the budget has to add up
  to 16,384, split between code the tracer actually reaches and data ranges with
  a name and an explanation.

And a fourth one, born in this project for a specific reason: **no annotation
may cite an address from the sibling cartridge**. Hyper Olympic 1 and 2 are
nearly the same program, so the annotations are ported from one to the other
with `tools/porta_notas.py`; that puts them at the right address but does not
change what they say. `tools/repasa_el_porte.py` checks that every address cited
inside a comment —or inside a page of this website— is the start of an
instruction or falls in a data range **of this cartridge**.

## What is inside

| | |
|---|---|
| `src/hyperolympic1.asm` | the listing; generated, not hand-edited |
| `src/hyperolympic1.notes` | the annotations, anchored to addresses |
| `src/hyperolympic1.entries` | the entry points, each one justified |
| `src/hyperolympic1.nocode` | the areas the tracer is forbidden to enter |
| `medidas/` | what was measured in openMSX, with the raw tables |
| `tools/` | the tracer, the listing generator and the data walkers |
| `docs/` | this website |

The comments live **apart** from the listing, anchored to the address they
describe. That way they survive a re-trace: if tomorrow the tracer splits the
binary differently, the comments still land where they belong.

## What is not here

The cartridge image. Neither this one nor any other: it belongs to Konami and
is not distributed. See [LEGAL-NOTICE.md](../LEGAL-NOTICE.md).
