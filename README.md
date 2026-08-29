# Hyper Olympic 1 (Konami, RC-710) — commented disassembly

A commented disassembly of the 16 KB MSX cartridge, reproducible byte for byte.

**[Read the write-up →](https://antxiko.github.io/HyperOlympic1-disassembly/)**
· [En castellano](README.es.md)

    make            # trace, generate the listing, reassemble it and run the tests
    make verify     # the test that decides: reassembling has to give the ROM back
    make sanity     # that not one byte is left unexplained
    make densidad   # how much is commented, routine by routine
    make web        # rebuild the website

The ROM is **not distributed here**. It goes in the root as `hyperolympic1.rom`,
16384 bytes, sha256

    0cd8a7928e10a8551d7f6fd68943a6d4a008e04a254d258413c120dda18b792e

`make comprueba` checks it.

## Where it stands

| | |
|---|---|
| reassembles byte for byte | yes |
| bytes explained | 16,384 of 16,384 (100 %) |
| traced code | 9,335 bytes, 5,032 instructions |
| identified data | 7,049 bytes in 92 named ranges |
| commented | 1,681 line comments, 33.4 % |
| thin routines (under 10 %) | 0 of 569 |

The annotations live apart from the listing, anchored to the address they
describe. What the `.notes` file holds:

| | |
|---|---|
| named labels | 569 |
| anchored comments | 1.668 |
| explained data ranges | 92 |

## What is in here

- `src/hyperolympic1.asm` — the listing; generated, not hand-edited
- `src/hyperolympic1.notes` — the annotations, anchored to addresses
- `src/hyperolympic1.entries` — the entry points, each one justified
- `src/hyperolympic1.nocode` — the areas the tracer is forbidden to enter
- `docs/` — the website, in English and Spanish
- `medidas/` — what was measured in openMSX, with the raw tables
- `tools/` — the tracer, the listing generator and the data walkers

## The write-up

| | |
|---|---|
| [Getting started](docs/GETTING-STARTED.md) | what you need and what each command does |
| [The game](docs/THE-GAME.md) | four events, twelve rounds, and a clock that lies |
| [The cartridge](docs/THE-CARTRIDGE.md) | the header, the memory map and the screen |
| [The code](docs/THE-CODE.md) | how the program is put together |
| [Findings](docs/FINDINGS.md) | what the binary says |
| [In the emulator](docs/IN-THE-EMULATOR.md) | what was measured, and how to repeat it |
| [Open questions](docs/OPEN-QUESTIONS.md) | what is still not settled |
| [Hyper Olympic vs Track & Field](docs/COMPARISON-TRACK-AND-FIELD.md) | the two builds of this cartridge, compared |

See `LEGAL-NOTICE.md`.
