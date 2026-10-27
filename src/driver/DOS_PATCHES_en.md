# What this project changes in DOS 3.3

> 한국어: [DOS_PATCHES.md](DOS_PATCHES.md)


`DIST\K-HANGEUL.DSK` is built from `disk\dos33blank.dsk`, a blank standard DOS 3.3 disk (`mkdist.py` deletes any files on it and adds the project's files). The disk's DOS tracks are not modified. Every change is made in RAM, while the driver loads or starts, so booting another DOS disk gives a normal DOS. DOS 3.3 sits at `$9D00-$BFFF` (file buffers from `$9600`). Addresses below were read from a booted disk in MAME.


## 1. Patches made by the loader (`driver.s`, segment LOADER)

The loader copies these bytes into DOS before it enters `INIT`. They are the same as stock Hangeul2's.

| address | new bytes | meaning |
|---|---|---|
| `$A8F1-$A8F3` | `48 41 CE` ("HAN", last letter with the high bit) | A name in DOS's command table, between `FP` (`$A8EF`) and `BSAVE`. It replaces the Integer BASIC command, so the command `HAN` exists. |
| `$A59E-$A59F` (and `$A5A0` = `$20`, unchanged) | `D0 BB` | The handler of that command branches (`BNE`) to `$A55B`. |
| `$A55B-$A560` | `4C lo hi EA EA EA` | `JMP HANMAIN` (a routine in the banner segment, main RAM) and three NOPs. (Stock had `STA $C080 / JMP INIT` here. The loader now leaves the card writable and jumps to `INIT`; `INIT` copies the English font into the card and then write protects it with `LDA $C080`.) |

`HAN` starts the Hangul driver again: it switches the language card on, fills the driver's state with spaces, and runs the stock init (hooks, 46 x 16 window, hi-res screen, banner). Checked in MAME: after `PR#0` and `IN#0` (driver off, ROM text output) typing `HAN` brings the driver back, with the driver's own routines in `$36-$39` and in DOS's saved copy `$AA53-$AA56` exactly as after a normal boot. Ctrl-Reset also turns the driver off (the ROM hooks and its 40 x 24 text window come back) and `HAN` brings it back, with the hooks, window and screen as after a boot; checked in MAME with its real Ctrl-Reset key (the `Ctrl` and `Reset` fields of `:kbd:nkbd:keyb_special`). `m:soft_reset()` in MAME is a machine reset, not Ctrl-Reset, and gave misleading results. Not tried on a real machine. It redraws the banner and clears the screen but keeps the BASIC program. It was broken before (the old `INIT` copied the banner and font from memory BASIC had reused); `HAN` now skips those copies. The overwritten DOS bytes are not recorded in this project.


## 2. Patches made by `INIT` (CATALOG paging)

`INIT` changes two places in the CATALOG command, only after checking the old bytes are the DOS 3.3 ones (otherwise it leaves DOS alone):

| address | stock | now | meaning |
|---|---|---|---|
| `$ADA3-$ADA7` | `LDA #$18 / STA $B39D` | `JSR CATINIT / NOP / NOP` | The line counter for the first page starts from the cursor row and the window height, not 24, so the page fills without scrolling first. |
| `$AE3C-$AE3D` | `LDA #$17` | `LDA #$0B` | Lines on each later page. |
| `$AE39-$AE3B` | `JSR $FD0C` (RDKEY) | `JSR CATWAIT` | The wait for a key between pages. `CATWAIT` marks `NOPR` so the `]` is not drawn during the wait. |

`CATINIT` and `CATWAIT` are in the banner segment (`$1CC0`).


## 3. Memory DOS uses that the driver moves

- `HIMEM` and `FRETOP` (`$73/$74`, `$6F/$70`) are set to `$9400` by `INIT`. Stock DOS leaves `$9600`. The 512 bytes between (`$9400-$95FF`) hold the driver's stubs and variables. `INIT` and `HAN` first fill all 512 bytes with spaces (`$A0`), because the stock code expects spaces in what used to be the text page, and then copy the six stub blocks over the start. `MAXFILES` would recompute `HIMEM` from the number of buffers and expose them again, so do not use it.
- The program starts at `$4001` (`TXTTAB`), with a `0` at `$4000`.
- The keyboard and screen hooks (`$36-$39`) point at stubs at `$9400` (input) and `$940A` (output). DOS puts its own hook in front of them when it runs a command and keeps the real ones in `$AA53-$AA56`.


## 4. What TYPE and TYPEC rely on (they change nothing permanent)

- `TYPE` checks the bytes at `$A6D2` (`8D 5C AA 20 E6 BF AD`, DOS's error routine) before it installs, and raises errors by jumping to `$A6D2` with the error code in A. Before that it copies `$AA53-$AA56` to `$36-$39`, because the error routine expects to run inside DOS's own hook.
- It reads files with the RWTS entry `$03D9` and the parameter list from `$03E3`, so it uses the slot and drive of the last disk access. It never opens a DOS file.
- `TYPEC` runs inside DOS's output hook (BRUN is executed from there). Calling that hook a second time overwrites the stack pointer it saved in `$AA59`, and DOS then hangs at `$9FB6-$9FC4`. So TYPEC copies the real hooks from `$AA53-$AA56` to `$36-$39` first and leaves with `JMP $03D0` (DOS warm start, which reconnects the hook and prints the prompt).
- Other DOS facts used: `Ctrl-D` in a DOS command must be `$84`, a text file ends with error 5, `OPEN` creates a missing file, `OPEN` and `READ` are refused at the prompt (`ERROR #15`). `TYPE` avoids all of these by reading sectors.
