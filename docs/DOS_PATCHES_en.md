# What this project changes in DOS 3.3

> 한국어: [DOS_PATCHES.md](DOS_PATCHES.md)


`DIST\K-HANGEUL.DSK` is built from `disk\dos33blank.dsk`, a blank standard DOS 3.3 disk (`mkdist.py` deletes any files on it and adds the project's files). The disk's DOS tracks are not modified. Every change is made in RAM, while the driver loads or starts, so booting another DOS disk gives a normal DOS. DOS 3.3 sits at `$9D00-$BFFF` (file buffers from `$9600`). Addresses below were read from a booted disk in MAME.


## 1. Patches made by the loader (`driver.s`, segment LOADER)

The loader copies these bytes into DOS before it enters `INIT`. They are the same as stock Hangeul2's.

| address | new bytes | meaning |
|---|---|---|
| `$A8F1-$A8F3` | `48 41 CE` ("HAN", last letter with the high bit) | A name in DOS's command table, between `FP` (`$A8EF`) and `BSAVE`. It replaces the Integer BASIC command, so the command `HAN` exists. |
| `$A59E-$A5A0` | `4C lo hi` | The handler of that command: `JMP HANMAIN` (a routine in the banner segment, main RAM). |
| `$03F2-$03F4` | `lo hi` of `HANRST`, and `hi EOR $A5` | The reset vector (page 3, not part of the DOS image). The loader points it at `HANRST` (banner segment: `JSR HANMAIN` / `JMP $9DBF`) so Ctrl-Reset starts the driver again before DOS's own warm start, but only if the vector is still `$9DBF`. On a Saturn card there is no room in main RAM: the loader writes the same six bytes (`20 9E A5 4C BF 9D`) into the unused rest of the `INT` handler at `$A5A1` and points the vector there (a Saturn `INIT` never writes a disk, so DOS stays unchanged on disks). |
| `$AE39-$AE41` (code in `CATWAIT`) | not a DOS patch | The `CATALOG` page pause calls `CATWAIT` (it already did). `CATWAIT` now ends the listing when the key is Ctrl-C (`$83`) by jumping to DOS's own end of `CATALOG` (`$AE2C`, `JMP $B37F`); the file manager restores its own stack pointer (`$B39B`) when it leaves, so nothing is popped. On a Saturn card the check is `SatCw` (in the padding of `ENGPTR`): it pushes `$AE2B` so that `SatLeave1`'s `RTS` goes to `$AE2C`. |
| `$A55B-$A560` | not changed | Stock Hangeul2 (and this driver before the `dos-korean` work) wrote `JMP HANMAIN` here, inside DOS's `INIT` code, and branched to it from `$A59E`; so `INIT` never formatted a disk while the driver was loaded, it restarted the driver. `INIT` works now (section 5: on the 16K card since the DOS work, on the Saturn card since 1.7). Only on a Saturn card that is not 128K (the driver not in bank 7), or when `$BCDF-$BCFF` is not free, does `KPATCH6` write `JMP SATHAN` here, so that `INIT` restarts the driver. |

`HAN` starts the Hangul driver again: it switches the language card on, fills the driver's state with spaces, and runs the stock init (hooks, 46 x 16 window, hi-res screen; the banner only at boot since 1.4 on the 16K card, as on the Saturn card). Checked in MAME: after `PR#0` and `IN#0` (driver off, ROM text output) typing `HAN` brings the driver back, with the driver's own routines in `$36-$39` and in DOS's saved copy `$AA53-$AA56` exactly as after a normal boot. Ctrl-Reset also turns the driver off (the ROM hooks and its 40 x 24 text window come back) and `HAN` brings it back, with the hooks, window and screen as after a boot; checked in MAME with its real Ctrl-Reset key (the `Ctrl` and `Reset` fields of `:kbd:nkbd:keyb_special`). `m:soft_reset()` in MAME is a machine reset, not Ctrl-Reset, and gave misleading results. Not tried on a real machine. It redraws the banner and clears the screen but keeps the BASIC program. It was broken before (the old `INIT` copied the banner and font from memory BASIC had reused); `HAN` now skips those copies. The overwritten DOS bytes are not recorded in this project.


## 2. Patches made by `INIT` (CATALOG paging)

`INIT` changes two places in the CATALOG command, only after checking the instructions are the expected ones (otherwise it leaves DOS alone). It checks the opcodes, not the line counts, because the DOS on the project disk pages at 22 and 21 lines (`$16`, `$15`) where stock DOS 3.3 uses 24 and 23 (`$18`, `$17`); both get the same patch:

| address | stock | now | meaning |
|---|---|---|---|
| `$ADA3-$ADA7` | `LDA #$18` (stock) or `#$16` `/ STA $B39D` | `JSR CATINIT / NOP / NOP` | The line counter for the first page starts from the cursor row and the window height, not 24, so the page fills without scrolling first. |
| `$AE3C-$AE3D` | `LDA #$17` (stock) or `#$15` | `LDA #$0B` | Lines on each later page. |
| `$AE39-$AE3B` | `JSR $FD0C` (RDKEY) | `JSR CATWAIT` | The wait for a key between pages. `CATWAIT` marks `NOPR` so the `]` is not drawn during the wait, and first calls `CATFIX`: a full page leaves the cursor on an empty row, where the driver had already drawn a `]` before the wait began, so `CATFIX` draws a space over it. |

`CATINIT` and `CATWAIT` are in the banner segment (`$1CC0`); `CATFIX` is in the free part of the card (`$D000` area).


## 3. Memory DOS uses that the driver moves

- `HIMEM` and `FRETOP` (`$73/$74`, `$6F/$70`) are set to `$9400` by `INIT`. Stock DOS leaves `$9600`. The 512 bytes between (`$9400-$95FF`) hold the driver's stubs and variables. `INIT` and `HAN` first fill all 512 bytes with spaces (`$A0`), because the stock code expects spaces in what used to be the text page, and then copy the six stub blocks over the start. `MAXFILES` would recompute `HIMEM` from the number of buffers and expose them again, so do not use it.
- The program starts at `$4001` (`TXTTAB`), with a `0` at `$4000`.
- The keyboard and screen hooks (`$36-$39`) point at stubs at `$9400` (input) and `$940A` (output). DOS puts its own hook in front of them when it runs a command and keeps the real ones in `$AA53-$AA56`.


## 4. What TYPE and TYPEC rely on (they change nothing permanent)

- `TYPE` checks the bytes at `$A6D2` (`8D 5C AA 20 E6 BF AD`, DOS's error routine) before it installs, and raises errors by jumping to `$A6D2` with the error code in A. Before that it copies `$AA53-$AA56` to `$36-$39`, because the error routine expects to run inside DOS's own hook.
- It reads files with the RWTS entry `$03D9` and the parameter list from `$03E3`, so it uses the slot and drive of the last disk access. It never opens a DOS file.
- `TYPEC` runs inside DOS's output hook (BRUN is executed from there). Calling that hook a second time overwrites the stack pointer it saved in `$AA59`, and DOS then hangs at `$9FB6-$9FC4`. So TYPEC copies the real hooks from `$AA53-$AA56` to `$36-$39` first and leaves with `JMP $03D0` (DOS warm start, which reconnects the hook and prints the prompt).
- Other DOS facts used: `Ctrl-D` in a DOS command must be `$84`, a text file ends with error 5, `OPEN` creates a missing file, `OPEN` and `READ` are refused at the prompt (`ERROR #15`). `TYPE` avoids all of these by reading sectors.

## 5. Korean DOS (16K card; made by `INIT`'s last step, `KPATCH`)

Each patch is made only if the DOS bytes are the stock ones shown (otherwise that one is left alone). Saturn card: at the end (since 1.7). User-level description: `MANUAL_en.md` section 8; design and tests: `DOS_KOREAN_REPORT_en.md` section 9.

| address | stock | now | meaning |
|---|---|---|---|
| `$A702-$A704` | `LDA $AA3F,X` (`BD 3F AA`) | `JMP $BCEF` (`KSTUBD`) | DOS's message routine (X = message number). `KSTUBD` goes to the driver only while DOS's output is the driver's (`$37 = $94`); the driver prints the Korean text (on the 16K card, since 1.4, as johab pairs through `KPUTS`: `kdos_johab.inc`; on a Saturn card as keystroke text through `K6PUT`). Otherwise it does what stock DOS did (English). |
| `$A04E-$A04F` | `JMP $A000` (`4C 00 A0`, at `$A04D`) | `JMP KFN` | The first-character check of a file name: Ctrl-K (a Hangul name) is let through to `$A050`. |
| `$A000-$A002` | `LDA $0200` (`AD 00 02`) | `JMP KALS` | DOS's code for a line it does not know: the Korean command names (the first word is replaced by DOS's English word and the line is parsed again from `$9FCD`). |
| `$ADAF` | `$0B` | `$08` | The `CATALOG` header prints 9 bytes, not 12. |
| `$B3B0-$B3B7` | `DISK VOLUME` text (stored backwards) | `볼륨` as Hangul keys | The `CATALOG` header text (`$B3AF` stays a space). |
| `$9D1E-$9D1F` | `$A54E` | `$BCDE` | DOS's handler table entry for `INIT`: the INIT guard (`KINITS`). |
| `$BCDF-$BCFD` | zeros (unused by DOS 3.3) | 31 bytes | `KINITS`, `KPOST` and `KSTUBD`. Installed only if all of `$BCDF-$BCFF` is zero; otherwise `INIT` restarts the driver as before. |

**The INIT guard.** While `INIT` runs, the bytes in the table above (except `$A702` and `$BCDF`) and the loader's and `CATALOG` patches (`$A59E`, `$A8F1`, `$ADA3`, `$AE3A-$AE3D`) are exchanged with the stock bytes kept in the card, so the new disk gets stock DOS 3.3, plus `$A702` and `$BCDF`, which without the driver just print DOS's English message. `INIT`'s handler returns through `KPOST`, which exchanges them back; if `INIT` fails, the driver's message code exchanges them back before it prints. Checked in MAME: a new disk boots without the driver, and its DOS differs from stock only at `$A702-$A704` and `$BCDF-$BCFD`.

**On a Saturn card** (driver in bank 7) `KPATCH6` (in the driver, bank 7) writes the stubs and calls `K6GD`, which makes `KPAT` in bank 6 (`kinit6.inc`) do the same patches. They jump to other stubs: `$A702` is `JSR K6MSG` (`$BCE9`: it goes into bank 6 only while DOS's output is the driver's, otherwise `lda $AA3F,x / rts`; a new disk gets this stub too, so it boots without the driver), `$A000` goes to `$94FB` (`K6AL`), `$A04E` to `$951A` (`K6FN`; since 1.5 it also serves the Korean Applesoft error filter: `KBOUT` calls it, and `KDISP` in bank 6 tells the two apart by the return address; `KPATCH6` always installs it, as an `rts` when there is no bank 6 code), and `$9D1E` (INIT's handler) to `$BCF9` (`K6GD`). The stubs at `$BCDF-$BCFE` (`K6IN`, `K6MSG`, `K6GD`) map bank 6, where the code is (`DOS_KOREAN_REPORT_en.md` section 9.5).

**The Saturn INIT guard (since 1.7)** is the same idea as the 16K card's. While `INIT` runs, the patches above (except `$A702` and `$BCDF`) and the loader's patches (`$A59E`, the reset stub at `$A5A1-$A5A6`, `$A8F1`, `$ADA3`, `$AE3A`) are exchanged with the stock DOS bytes kept in `KSWT` in bank 6, and exchanged back when `INIT` is over (`KGD`, `KSWAP`, `KBACKC` in `kinit6.inc`). `KGD` tells its two entries apart by the top of the stack: the first time it is DOS's return address; when `INIT` has run it is the `$0000` that `KGD` pushed under it. For a failed `INIT`, `KMSGC` calls `KBACKC` before it prints, which puts the patches back. Checked in MAME (`-sl0 ssram`): the disk is formatted, the new disk boots plain DOS 3.3 without the driver (it differs only at `$A702-$A704` and `$BCDF-$BCFE`), and a failed `INIT` (empty drive 2) prints `입출력 오류` in Korean and Korean commands go on working. When the driver is not in bank 7, or `$BCDF-$BCFF` is not free, `INIT` runs `HAN` (`$A55B`, section 1).
