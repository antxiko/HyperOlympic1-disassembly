# The code

Sixteen kilobytes split into 9,335 bytes of code and 7,049 of data. There is no
bank switching and no loading trick: the whole program is in plain sight between
0x4000 and 0x7FFF, and this page is about how it is put together.

## Two threads sharing the work

The cartridge has a main program and an interrupt, and the line between them is
sharp.

**The interrupt** (`INTERRUPCION`, 0x4010) comes in through the H.KEYI hook that
INIT fills with a `jp`, and does everything that has to run at screen rate: it
reads the controls, moves the sound player, counts the clock and calls the motor
of whichever event is being played. It is where the game happens.

**The main program** carries the state machine: set up the scenery, wait for the
attempt to end, hand out points, move to the next round. Most of the time it is
waiting for the interrupt to set a bit.

The split has one nice consequence: stop the main program and the athlete keeps
running.

## The life of an event

`MONTA_LA_PRUEBA` (0x4234) heads everything that happens between two events. The
route is always the same:

1. `MONTA_EL_DECORADO` (0x4253) fetches this event's screen script and
   interprets it;
2. `MONTA_LOS_ACTORES_DE_LA_PRUEBA` (0x7B2C) copies the actor records from the
   ROM table into RAM;
3. `EMPIEZA_EL_INTENTO` (0x4296) places the athletes and releases the semaphore;
4. `BUCLE_DE_LA_PRUEBA` (0x4396) sits watching 0xE02E until the interrupt says
   the attempt is over;
5. `PUNTUA_EL_INTENTO` (0x4F4D) turns the mark into points;
6. `MIRA_SI_SE_ACABO_LA_PRUEBA` (0x45A1) decides whether there is another
   attempt, another player, another round, or the game is over.

The points deserve a note, because the arithmetic flips sign depending on the
event: they come from the difference between the mark and a fixed per-event
reference (0x5020). **In timed events the reference is on top** and the mark is
subtracted from it —the less you take, the more points—; **in distance events it
is underneath** and the mark is what beats it. Then it is multiplied by sixteen,
and in odd-numbered events doubled once more.

## Four motors, and one does double duty

Each event has its motor, and the interrupt calls whichever applies:

| event | motor | what it does |
|---|---|---|
| 100 and 400 metres | `MOTOR_DE_LA_CARRERA` (0x5180) | running, the gap between the two and the finish |
| long jump | `MOTOR_DEL_SALTO` (0x668F) | the run-up, the take-off, the flight and the landing |
| hammer | `MOTOR_DEL_MARTILLO` (0x68B3) | the spins, the angle and the flight |

The race motor covers both timed events as it stands, and on top of that **the
long jump reuses its run-up**: what belongs to the jump is the take-off and what
happens after.

And there is a fourth piece that is not a motor but behaves like one:
`AVANZA_EL_TIRO` (0x7D2C), which computes the flight. Both the jump and the
hammer use it, and it is the only part of the cartridge that does real
arithmetic.

## The only real piece of arithmetic

`CALCULA_EL_TIRO` (0x7D39) takes the running speed and the angle and gets from
them the advance and the height for each frame, and finally the mark in metres.
For that there are three arithmetic routines written by hand, because the Z80
brings none:

- `DIVIDE` (0x7E76), shifting and subtracting;
- `MULTIPLICA` (0x7E94), shifting and adding;
- `PASA_A_BCD` (0x7EB8), which converts a binary number to BCD by doubling it in
  BCD, bit by bit, so that it can be printed.

And the sine comes from a table, `EL_SENO_DEL_ANGULO` (0x7E54): one byte per
degree. No real-time approximations.

The rest of the cartridge does not compute: it looks things up in tables or adds
in BCD directly, which is how the marks and the scoreboards are carried without
having to convert anything to paint it.

## The cartridge does not store screens: it stores scripts

Not one screen is drawn in the ROM as such. What there is are **scripts**, and
four different interpreters that read them, each with its own format:

**The long script** (`GUION_LARGO`, 0x4D09) is the big one: a byte with the
number of orders and then the orders, each starting with its type.

| type | what it does |
|---|---|
| 0 | bytes to VRAM, with 0x11 as the run marker (RLE) |
| 1 | strings of font glyphs, uploaded as patterns |
| 2 | large-letter labels |
| 3 | fills of one byte |
| 4+ | repeat an eight-byte pattern N times |

**The short script** (`GUION_CORTO`, 0x4AFE) is for loose text, like the menu's.
**The label** (`LLENA_EL_PAPEL`, 0x4C63) prepares text that is later stretched
into large letters. And **the figure** (`MONTA_LA_FIGURA`, 0x7A1F) expands an
actor's description into character codes.

The 2.5 KB running from 0x5C96 to 0x668E are entirely scripts and script data,
and a walk from the roots covers them without leaving a byte loose.

## The large letters are manufactured

A large-letter label is not drawn anywhere: it is assembled on the fly.
`MONTA_UN_ROTULO` (0x4C49) copies the **normal** 8x8 glyphs into a scratch area
at 0xE230, and then `ESTIRA_LAS_LETRAS` (0x4CAB) makes **three passes** pulling
the top two bits out of each byte and pushing them into the byte eight positions
earlier.

With that, a row of eight glyphs yields four rows of pattern: the letter comes
out twice the size without taking twice the ROM. The price is written up in
[Open questions](OPEN-QUESTIONS.md): three labels declare twenty-four bytes of
length and only carry sixteen of their own, so they take eight from the block
behind.

## Writing to the VDP without the interrupt stepping on it

This is the finest detail in the cartridge, and there are four routines devoted
to it (`FIJA_ESCRITURA_CON_CANDADO` 0x4DFC, `FIJA_LECTURA` 0x4E14,
`FIJA_ESCRITURA` 0x4E25, and the ones that use them).

The problem: setting an address in the VDP is **two consecutive writes** to the
control port, and the interrupt writes to the VDP too. If it slips in between
the two, the address left standing is its own, and whatever comes next gets
written in the wrong place.

The solution is not to forbid the interrupt but to **notice**:

1. clear 0xE01D;
2. set the address;
3. look at 0xE01D: if the interrupt went through in the middle it will have set
   it, and then you do it again.

It is cheaper than disabling and re-enabling interrupts on every write, and it
does not lose a frame. The other semaphore, 0xE01E, is the real lock: while it
is set, the interrupt leaves without touching anything.

## The sound player

Three channels, an eleven-byte record each, at 0xE160, 0xE16B and 0xE176:

| offset | what it is |
|---|---|
| +0 | note countdown |
| +1 | base duration |
| +2 | sound number |
| +3/+4 | pointer to the string |
| +5 | octave |
| +6 | decay |
| +7 | volume |
| +8 | decay countdown |
| +9 | repeats left |
| +0x0A | duration |

The interesting part is **the sound number**, which carries information in its
top bits: bit 7 says the note takes a single byte, bit 6 that channel 3 is used
as noise, and **the bottom six are the priority**. `MIRA_LA_PRIORIDAD` (0x6AE8)
is what stops a key beep from wiping out the end-of-event music: a sound does
not interrupt another one of higher priority.

`DOBLA_LA_MELODIA` (0x6B7E) does what it says: it plays the same string an
octave above or below, which is how you get two voices out of one.

## The actors

An actor is a sixteen-byte record in RAM, and there are four: 0xE120, 0xE130,
0xE140 and 0xE150.

| offset | what it is |
|---|---|
| +0 | flags |
| +1 | counter |
| +2 | step |
| +6 | column within the figure |
| +7/+8 | VRAM address |
| +9/+0A | the record that relieves it |
| +0B | row of the adjustment table |
| +0C | computed column |
| +0D/+0E | the figure |
| +0F | how many characters get painted |

The four records sit **back to back** in memory, and that is where the trick
comes from: `MIRA_SI_EMPUJA_AL_DE_DETRAS` (0x79CF) looks at bits 2 and 3 of the
flags and, depending on which is set, adds or subtracts 0x11 from the pointer to
bump the neighbouring record's counter.

That is how the scenery drags itself along in a chain with nobody keeping a list
of who pushes whom: **the relationship is the distance between the records**.

## The athlete is seven sprites

`FICHA_DEL_QUE_JUEGA` (0x7F52) and what sits under it assemble the runner. He is
not a sprite: he is **seven**, and every pose places them by hand.

`SUBE_LOS_PATRONES` (0x7F9C) uploads to VRAM whatever patterns the pose needs,
and then `UN_SPRITE_DEL_ATLETA` (0x7FD5) writes the seven rows of the attribute
table, adding to each the row and column the athlete is at. Changing pose is
changing the patterns; moving the athlete is adding to the seven rows.

## How to read it

The listing is generated; it is not hand-edited. The comments live apart, in
`src/hyperolympic1.notes`, anchored to the address they describe, and `make
listado` pastes them where they belong. Which means that if tomorrow the tracer
splits the binary differently, the comments still land in the right place.

VRAM addresses appear in the listing **with bit 14 set** (0x4000 added) when
they are about to be written, which is how the VDP wants them. That is why the
name table, which lives at 0x3800, is seen being written as 0x7800.
