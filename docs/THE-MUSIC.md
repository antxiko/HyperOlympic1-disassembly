# The music

Everything you hear here comes from running the cartridge's own sound engine (`MUEVE_EL_SONIDO`, 0x6B1A, and `PIDE_UN_SONIDO`, 0x6A92, which hands it the channels; the interrupt calls it at 0x404C) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- the title tune (0x96), whole, 642 frames;
- track 0x91, whole, 511 frames, with its repeat.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`PIDE_UN_SONIDO` takes the number in A and makes no sound in the demo. Effects are below 0x81 and take one, two or three voices depending on their number; from 0x81 to 0x95 music uses two voices and from 0x96 up three. The channel records are at 0xE162, 0xE16D and 0xE178. Tracks 0x91, 0x95, 0xA8 and 0xA9 are in the table but no routine asks for them with an `ld a`. The engine never writes the PSG mixer: start-up leaves it set, and here it starts from that same value, 0xB8.

## The tunes

**The title tune** (0x96)

Asked for by `TITULO_SIN_PARPADEO`; lasts 10.7 s.

<audio controls preload="none" src="audio/musica_96.mp3?v=918f6723"></audio>

**The qualifying fanfare** (0x02)

Asked for by la rutina de 0x451F; `PIDE_UN_SONIDO` lo reparte en tres: el 2, el 0x47 y el 0x49; lasts 4.1 s.

<audio controls preload="none" src="audio/musica_02.mp3?v=741888b0"></audio>

**New record** (0x99)

Asked for by `GUARDA_EL_RECORD_NUEVO`; lasts 4.0 s.

<audio controls preload="none" src="audio/musica_99.mp3?v=37ff5580"></audio>

**The new event** (0x9C)

Asked for by `SUENA_LA_PRUEBA_NUEVA`; lasts 2.0 s.

<audio controls preload="none" src="audio/musica_9C.mp3?v=4f4a6ddd"></audio>

**The end sign** (0x9F)

Asked for by `CARTEL_DE_FIN`; lasts 3.0 s.

<audio controls preload="none" src="audio/musica_9F.mp3?v=d0f0f403"></audio>

**The tune that is waited for** (0x92)

Asked for by `ESPERA_A_QUE_ACABE_LA_MUSICA`; lasts 1.0 s.

<audio controls preload="none" src="audio/musica_92.mp3?v=307ac8b2"></audio>

**A track in the table** (0x91)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 8.5 s and starts again at second 4.3.

<audio controls preload="none" src="audio/musica_91.mp3?v=1e36a5c0"></audio>

**Another track in the table** (0x95)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 17.1 s and starts again at second 12.8.

<audio controls preload="none" src="audio/musica_95.mp3?v=fddbaa8f"></audio>

**A third track in the table** (0xA8)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 21.3 s and starts again at second 17.1.

<audio controls preload="none" src="audio/musica_A8.mp3?v=d0e5aef3"></audio>

**A fourth track in the table** (0xA9)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 13.9 s.

<audio controls preload="none" src="audio/musica_A9.mp3?v=3f01504c"></audio>
