# Memory layout

> 한국어: [MEMORY_LAYOUT.md](MEMORY_LAYOUT.md)


## Short version

- Font, text buffer, banner, and the driver's blit variables sit under the screen at `$0800–$1FFB`.
- The screen is hi-res page 1, `$2000–$3FFF`. It no longer sits in the middle of BASIC memory.
- BASIC is one block, `$4001–$93FF`, 21,504 bytes. `HIMEM` is `$9400` and 21,501 bytes show free at the prompt.
- DOS 3.3 stays at `$9600`. The driver is in the language card, `$D000–$FFFF`; the English font sits at `$D860–$E05F` inside it.
- Before, the screen was on page 2 and `HIMEM` was `$7400`, so a program was capped near 14KB with strings in a separate 5,120-byte block. Moving the font, buffer, and banner under page 1 removed that cap.
- `HGR` clears the Hangul picture. `HGR2` clears the BASIC program. Neither can be blocked: they are Applesoft ROM statements and the ROM has no RAM hook to catch them.

See `DOS_PATCHES_en.md` for the changes made to DOS 3.3 in RAM.


## Where the pieces sit

| Piece | Address |
|---|---|
| 12×12 font and shift masks | `$0800–$1969`, 4,458 bytes |
| Text buffer, 46 columns × 16 rows | `$1980–$1C5F` |
| Row flags | `$1C60` |
| Blit scratch | `$1C80–$1CAF` |
| ROM bell and mode bytes | `$1CB0–$1CBC` |
| Startup banner and the prompt and CATALOG helpers | `$1CC0–$1FCE`, 783 bytes |
| Blit variables (masks, byte count, row index, inverse masks) | `$1FF0–$1FFB`, 12 bytes |
| Screen, 16 rows × 12 pixels | hi-res page 1, `$2000–$3FFF` |
| BASIC program, variables, and strings | `$4001–$93FF` |
| Driver stubs and variables (not in the text page, so `HOME`, `TEXT`, `GR` cannot hit them) | `$9400–$95FF` (of these, `$95DC` Shift mod idle level, `$95DD` strip mode, `$95DE/$95DF` strip address, `$95E0/$95E1` row-end routine) |
| DOS 3.3 | `$9600` |
| Hangeul2 driver | language card, `$D000–$FFFF` |
| English font, 128 glyphs × 16 bytes (10 lines used) | language card, `$D860–$E05F`, 2,048 bytes (loaded from `FONT6X10` at `$7200`, copied by `INIT`) |

`$7200–$79FF` is only a staging area: `HELLO` loads `FONT6X10` there and `INIT` copies it into the card, so the BASIC program may use that area afterwards. `$D000–$D0AF` holds the Shift mod, Ctrl-A and strip-mode routines (`FIXCONT` to `SHREPL`). `$1CBD` is one byte of the driver's state: bit 7 set on an Apple IIe, IIc or IIgs (set by the loader). `$D0B0–$D132` holds `CATFIX` (the `CATALOG` prompt fix) and the two hooks for the optional KBASIC add-on (`KBIN`, `KBOUT`); `$D133–$D3FF` (717 bytes) is free. The old 6×8 English table that was there is gone. When the KBASIC add-on is loaded it sits in main RAM at `$8A00–$93FF` and lowers `HIMEM` to `$8A00` (see the KBASIC documents in the Korean BASIC project). The English glyph is found with `base + code × 16`.

`$0800–$1FFF` is 6,144 bytes. The pieces above use 6,051 of them; 93 bytes are free.

At the prompt the program is empty. `$4000` is `0`, `TXTTAB` is `$4001`, and `VARTAB` is `$4003`. `HIMEM` is `$9400` (37888). The banner’s free-memory count is `$9400 − VARTAB`, which is **21,501** bytes. The whole block from `$4000` through `$93FF` is 21,504 bytes.

Original Hangeul2 drew on hi-res page 2 and left the program under that page, about 14KB, with strings in a separate block above it. A program can now grow past 14KB because the screen is no longer in the middle.

`HGR` clears the Hangul picture. `HGR2` clears the BASIC program.


## Boot

`HELLO` loads `FONT12` at `$6000`, then `BRUN`s the driver at `$0F94`. The driver image is 13,191 bytes and passes through `$4000` while it loads. Init copies the font from `$6000` to `$0800`, then starts an empty program at `$4001`. The parser is pointed at that zero so line 20 of `HELLO` is not resumed after the font has covered it.

`MIXED` and `STORY` read keystroke text files with `GET` and `PRINT`. Nothing is loaded at `$8000` now.


## The previous build

Before this move the same driver kept the screen on page 2 and set `HIMEM` to `$7400`. That was 8,704 bytes below original Hangeul2’s `$9600`: 4,458 for the font at `$7400`, 1,432 for the buffer and banner at `$8C00`, and 2,814 of gaps closed by the single `HIMEM` ceiling. String space was 5,120 bytes and the program was still capped near 14KB. Those pieces now live under page 1, and `HIMEM` was back at `$9600`. Later the driver stubs moved out of the text page to `$9400–$95FF`, so `HIMEM` is now `$9400`.

The driver stays in the language card. DOS stays at `$9600`. Putting DOS in that card would need a second bank and a switch on every disk call and every character.


## Programs that sit above the BASIC memory

| Program | Load address | Size | What it takes |
|---|---|---|---|
| `TYPE` | `$8E00` | 800 bytes | `$8E00-$93FF` (code, then the sector buffers `$9200` and `$9300`); `HIMEM` is lowered to `$8E00` |
| `TYPEC` | `$8E00` | 486 bytes | the same area, overwritten while it runs |
| `STYPE` | `$8A00` | 1,224 bytes | `$8A00-$93FF`: code to `$8EC7`, the 512-byte strip buffer to `$90C7`, the sector buffers `$9200` and `$9300`; `HIMEM` is lowered to `$8A00`. It cannot share the area with `TYPE` |
| `STYPEC` | `$8A00` | 951 bytes | the same area as `STYPE`, overwritten while it runs |

The strip buffer is 12 pixel rows of 42 bytes for the text row `STYPE` is drawing (see `STYPE.md`). The driver's strip mode adds about 200 bytes of code to `$D000-$D0AF` (`LINEX`, `NEXTROW`, `NLHOOK`, `CALLSTRIP`, together with the Shift and Ctrl-A routines).
