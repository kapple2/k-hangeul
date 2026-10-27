# TYPE: the `&TYPE` command

> 한국어: [TYPE.md](TYPE.md)


`TYPE` adds one command to Applesoft BASIC. It prints N-byte (keystroke) Hangul text, either from a DOS text file or from memory. It is optional: a program that does not want it never loads it. The word can be written plain (`& TYPE,...` or `&TYPE,...`) or quoted (`& "TYPE",...`); spaces do not matter.

N-byte text is what the keyboard would produce for Hangul: Ctrl-K (`$0B`), uppercase two-set letters, Ctrl-A (`$01`). ASCII, digits and punctuation sit outside the run. Every byte goes through the screen routine, so the K-HANGEUL driver composes the Hangul. Without the driver the bytes print as plain letters.


## Use

```basic
10 PRINT CHR$(4);"BRUN TYPE"          : REM load and install, once, near the start
20 & TYPE,"NALGAE1"                  : REM a DOS text file
30 & TYPE,"NALGAE" + STR$(N)         : REM any string expression
40 PRINT CHR$(4);"BLOAD MYTEXT,A$8000"
50 & TYPE,"$8000"                    : REM text in memory, hex address
60 & TYPE,"A$8000"                   : REM the same, in DOS style
70 & TYPE,32768                      : REM the same, decimal
```

| second argument | meaning |
|---|---|
| a string that starts with `$` or `A$` and then 1 to 4 hex digits | an address in hex |
| any other string | a DOS file name (up to 30 characters) |
| a number | an address in decimal |

The disk has two demos: `RUN TYPEDEMO` prints the sample three ways, and `RUN STORYT` prints the whole story with one `&TYPE` line in a loop.


### From a file

`& TYPE,"name"` reads the file itself. It looks the name up in the disk catalog and reads the data sectors with DOS's own RWTS routine, so it does not use `OPEN` or `READ`. That has three consequences:

- It works typed at the `]` prompt as well as inside a program: `& TYPE,"SAMPLE1"`.
- It cannot leave a file open, and it needs no `CLOSE`, `ONERR`, or buffer.
- It uses the slot and drive of the last disk access, as DOS does.

The name is made upper case, so `"nalgae1"` works. The file must be a DOS text file (type T); anything else gives `FILE TYPE MISMATCH`. A name that is not on the disk gives the normal DOS error `FILE NOT FOUND` (error 6), or your `ONERR` line inside a program. A disk read error gives I/O ERROR. The text ends at the first `$00` byte, which is how DOS pads the last sector of a text file.


### From memory

The text ends at a `$00` byte. `$0D` is printed as a carriage return. This form uses no disk at all.


## Stopping

Press **Ctrl-C** while it prints: the printing stops after the byte being drawn, the key is taken, and control returns to the caller: the next BASIC statement. In a BASIC loop such as `STORYT` Ctrl-C ends only the file being printed and the loop goes on with the next one; use Ctrl-Reset to stop the whole program. Before this, Ctrl-C was ignored while printing and stayed in the keyboard buffer, where the next `FILE NAME` prompt took it as a file name (`ERROR #6`). **Ctrl-S** pauses (any key continues; this is the driver's own pause) and **Ctrl-Reset** breaks out (type `HAN` to switch the driver on again). The check costs about 10 cycles per byte (drawing a byte takes about 7,000).


## Where it lives

| item | value |
|---|---|
| source | `src/type/type.s` (ca65) and `core.inc`, the file reader that `typec` shares |
| build | `src\type\build.bat` (or `make` in that folder); `build.bat disk` also copies `TYPE`, `SAMPLEB`, `TYPEDEMO`, `STORYT` to the project disk |
| link config | `type.cfg` |
| load address | `$8E00`, 800 bytes (`$8E00-$911F`) |
| sector buffers | `$9200` (catalog and track/sector list) and `$9300` (data), 256 bytes each |
| disk file | `TYPE` (binary, type B) |


## What loading does

`BRUN TYPE` loads the file and starts it at `$8E00`. The start code:

1. Does nothing if `&` is already installed by TYPE, or if the DOS is not the 3.3 it was written for (it checks the first bytes of DOS's error routine at `$A6D2`).
2. Lowers `HIMEM` and the string top to `$8E00` so BASIC strings cannot overwrite the code or the buffers. If the string top is already below `$9300` it stops with `?OUT OF MEMORY`, so run `BRUN TYPE` early in the program.
3. Writes `JMP` to its handler at `$03F5`, the Applesoft `&` vector, and keeps the previous vector.

For any `&` statement that is not `&TYPE`, the handler hands the line to the previous `&` routine, so other `&` libraries keep working.


## How the file form works

- It reads the VTOC (track 17, sector 0), walks the catalog sectors, and compares the 30-character name with each entry.
- It follows the file's track/sector list and reads each data sector into `$9300`, printing the bytes through `COUT` (high bit cleared, `$0D` sent as `$8D`).
- Errors go through DOS's own error routine at `$A6D2`. DOS keeps the real input and output hooks in `$AA53-$AA56`, so TYPE copies them to `$36-$39` first. Otherwise the message would pass through DOS's hook again and print the wrong error number.


## Memory and conflicts

- Code and data: `$8E00-$9103`, buffers `$9200-$93FF`. All are protected by the lowered `HIMEM`. The driver's own state is at `$9400-$95FF`.
- Zero page: `$06/$07` as a scratch pointer, `$50/$51` for the decimal address (ROM `GETADR`), `$5E/$5F` for the string (ROM `FRESTR`).
- It clears the driver's compose state (Hangul mode and the pending syllable, at `$94A7-$94AE`) before each text so a text starts clean.
- It leaves `$0300-$03CF` free, and does not touch the language card.


## Speed

On story part 1 (3,767 bytes), emulated seconds:

| way | time |
|---|---:|
| BASIC `GET A$: PRINT A$;` loop over the text file | 45.3 |
| `& TYPE,"NALGAE1"` | 24.6 |
| text already in memory, `& TYPE,"$8000"` | 19.7 |

Most of the time is drawing the Hangul. Reading the sectors directly leaves only about 5 seconds for the disk.


## Limits

- File name: 30 characters, as DOS allows. A `,D2` or `,S6` suffix is not understood.
- A file of text that contains a `$00` byte would stop early.
- Only DOS 3.3 text files (type T) are read. Binary and Applesoft files give `FILE TYPE MISMATCH`.


## See also

`TYPEC` (`../typec/TYPEC.md`) is the same reader as a program of its own: `BRUN TYPEC` asks for a file name, for use at the `]` prompt without loading the `&` command.
