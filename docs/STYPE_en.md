# STYPE: the `&STYPE` command

> 한국어: [STYPE.md](STYPE.md)


`STYPE` is `TYPE` with a smooth effect: each row of text is drawn off screen first and then shown on the screen **one pixel row at a time, from top to bottom**, so the row seems to unroll instead of being typed letter by letter. Everything else is as in `TYPE` (see `TYPE.md`): it prints N-byte (keystroke) Hangul text from a DOS text file or from memory, and the text goes through the K-HANGEUL driver.

Only the drawing of each row is smooth. The old text scrolls up one text row at a time, as always.


## Use

```basic
10 PRINT CHR$(4);"BRUN STYPE"          : REM load and install, once, near the start
20 & STYPE,"NALGAE1"                   : REM a DOS text file, no wait between pixel rows
30 & STYPE,"NALGAE1",5                 : REM the same, a wait of 5 between pixel rows
40 PRINT CHR$(4);"BLOAD MYTEXT,A$8000"
50 & STYPE,"$8000",5                   : REM text in memory (hex address), with a wait
60 & STYPE,32768                       : REM the same, decimal address
```

The word can be written plain (`& STYPE,...`, `&STYPE,...`) or quoted (`& "STYPE",...`). The second argument is a file name or an address, exactly as for `TYPE`. The optional **third argument is the wait**, a number from 0 to 255 (any numeric expression); the default is 0 (no wait).

| wait | meaning |
|---|---|
| 0 (default) | the 12 pixel rows of a text row are copied one after another with no pause: the row appears almost at once, so there is little to see |
| 1 to 255 | after each pixel row the program waits about that many milliseconds (a delay loop of about 1,000 cycles per unit); 12 pixel rows per text row, so a text row takes about 12 times the wait |

Examples: a wait of 5 shows a text row in about 60 ms (a 15 row screen in about 1 s); a wait of 30 takes about 0.36 s per row. Measured in MAME on story part 1 (`NALGAE1`, about 90 screen rows, emulated seconds, 1/3 s resolution): `& TYPE` 26.3 s, `& STYPE` with no wait 27.0 s, with a wait of 5 31.7 s, so one unit of wait is about 1 ms per pixel row, as designed.

The disk has two demos: `RUN STYPEDEMO` (the sample with no wait, with a wait of 20, and from memory) and `RUN STORYS` (the whole story, one `&STYPE` line in a loop).


## Rows wider than the screen

A text line of more than 46 columns is shown as rows of 46 columns (23 Hangul syllables) as with `TYPE`. Each screen row is its own smooth effect, so the first 46 columns appear, then the rest of the text line appears on the next row.


## How it works

1. The K-HANGEUL driver has a **strip mode**. While the byte at `$95DD` has bit 6 set, the routines that find the address of a pixel row (`LINEX` and `NEXTROW` in `driver.s`) point into a buffer in main RAM, 12 rows of 42 bytes, instead of the hi-res screen. The glyph drawing is otherwise unchanged, so Hangul composing, English, inverse, underline and overlay work the same.
2. `STYPE` sends the text to the driver one byte at a time (`soutc` in `score.inc`) and turns strip mode on only while the driver prints that one byte. Strip mode is therefore always off when a disk error happens between two bytes.
3. At the end of every text row (a carriage return, or the wrap at the right edge) the driver calls `scb` in `STYPE` before it scrolls or moves the cursor (`NLHOOK`). `scb` copies the strip to the screen one pixel row at a time with the wait, then fills the strip for the next row: with that row of the screen, or blank if the screen is about to scroll.
4. When printing starts, the strip is filled with the current screen row, so printing can start in the middle of a row (after `PRINT "ABC";`). At the end the last row is shown.
5. The ROM `HOME` only writes spaces into the old text page; the driver clears the hi-res screen on the next character it prints. `STYPE` forces that clearing first (a space and a backspace) so a `HOME` just before `&STYPE` works.

The drawing itself costs the same as `TYPE`. The added work per text row is two copies of 480 bytes (screen to strip, strip to screen), about 8 ms measured (0.7 s over the 90 rows of story part 1), plus the wait.


## Stopping

Press **Ctrl-C** while it prints: the printing stops after the byte being drawn, the key is taken, and control returns to the caller: the next BASIC statement. In a BASIC loop such as `STORYT` Ctrl-C ends only the file being printed and the loop goes on with the next one; use Ctrl-Reset to stop the whole program. Before this, Ctrl-C was ignored while printing and stayed in the keyboard buffer, where the next `FILE NAME` prompt took it as a file name (`ERROR #6`). Ctrl-C during a wait also skips the remaining waits, so the last row finishes at once. **Ctrl-S** pauses (any key continues; this is the driver's own pause) and **Ctrl-Reset** breaks out (type `HAN` to switch the driver on again). The check costs about 10 cycles per byte (drawing a byte takes about 7,000).


## Where it lives

| item | value |
|---|---|
| source | `src/stype/stype.s` (the `&` command, from `type.s`), `score.inc` (the strip routines, shared with `STYPEC`), `src/type/core.inc` (the file reader, shared with `TYPE` and `TYPEC`) |
| driver | `LINEX`, `NEXTROW`, `NLHOOK`, `CALLSTRIP` in the free `$D000` area of `driver.s`; state bytes `$95DD` (strip mode), `$95DE/$95DF` (strip address), `$95E0/$95E1` (the routine called at the end of a row) |
| build | `src\stype\build.bat` (or `make` in that folder); `make_all.bat` builds it with everything else |
| link config | `stype.cfg` |
| load address | `$8A00`, 1,224 bytes of code and data (`$8A00-$8EC7`) |
| strip buffer | 512 bytes right after the code (not stored in the file) |
| sector buffers | `$9200` (catalog and track/sector list) and `$9300` (data), 256 bytes each, as in `TYPE` |
| disk file | `STYPE` (binary, type B) |


## What loading does

`BRUN STYPE` loads the file at `$8A00` and starts it. It checks for DOS 3.3 like `TYPE`, lowers `HIMEM` and the string top to `$8A00` (so about 3 KB of BASIC memory is used: `TYPE` takes 1.5 KB), and puts its handler on the Applesoft `&` vector (`$03F5`), keeping the previous routine; any `&` word that is not `STYPE` is passed on. As with `TYPE`, run `BRUN STYPE` early in the program; it stops with `?OUT OF MEMORY` if the string area has already grown more than 256 bytes down from `HIMEM`.

**`TYPE` and `STYPE` cannot both be loaded** (`STYPE` also needs the room that `TYPE` uses). Use whichever you want.


## Limits

- The wait is 0 to 255; a larger number gives `?ILLEGAL QUANTITY`.
- File name 30 characters, DOS 3.3 text files only; text ends at the first `$00` byte; errors are as for `TYPE` (`FILE NOT FOUND` for a missing file).
- The strip is built for the text window at its normal size (46 columns from column 0). A narrower window or a left margin (`WNDLFT`) is not supported.
- The speed of the drawing is that of `TYPE` (about 20 seconds for story part 1); the wait comes on top.


## See also

`STYPEC` (`STYPEC.md`) is the same effect as a program of its own, asking for a file name. `TYPE.md` describes the file reader and the text format.
