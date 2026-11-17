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
| Startup banner and the prompt and CATALOG helpers | `$1CC0–$1FCE`, 783 bytes. Since 1.4 (16K card) `$1CC0–$1E50` holds the banner code only until it has run, then the Korean error filter (see below) |
| Blit variables (masks, byte count, row index, inverse masks) | `$1FF0–$1FFB`, 12 bytes |
| Screen, 16 rows × 12 pixels | hi-res page 1, `$2000–$3FFF` |
| BASIC program, variables, and strings | `$4001–$93FF` |
| Driver stubs and variables (not in the text page, so `HOME`, `TEXT`, `GR` cannot hit them) | `$9400–$95FF` (of these, `$95DC` Shift mod idle level, `$95DD` strip mode, `$95DE/$95DF` strip address, `$95E0/$95E1` row-end routine) |
| DOS 3.3 | `$9600` |
| Hangeul2 driver | language card, `$D000–$FFFF` |
| English font, 128 glyphs × 16 bytes (10 lines used) | language card, `$D860–$E05F`, 2,048 bytes (loaded from `FONT6X10` at `$7200`, copied by `INIT`) |

`$7200–$79FF` is only a staging area: `HELLO` loads `FONT6X10` there and `INIT` copies it into the card, so the BASIC program may use that area afterwards. `$D000–$D0AF` holds the Shift mod, Ctrl-A and strip-mode routines (`FIXCONT` to `SHREPL`). `$1CBD` is one byte of the driver's state: bit 7 set on an Apple IIe, IIc or IIgs (set by the loader). `$D0B0–$D132` holds `CATFIX` (the `CATALOG` prompt fix) and the two hooks for the optional KBASIC add-on (`KBIN`, `KBOUT`); `$D133–$D3FF` was free (717 bytes); the Korean DOS messages, the CATALOG header, `KPATCH` and the INIT guard now use it, and since 1.4 the Korean DOS texts are johab pairs (95 bytes less) and `KBOUT` calls the Korean error filter, `PBAN` and `KRC` are here: 87 bytes are left (16K card build), 1 on the Saturn card (the same block is full there). In 1.6 the Korean DOS texts shrank (185 → 141 bytes), so about 131 bytes should be left on the 16K card (computed as 87 + 44, not measured again). The first 512 bytes of the English font area, `$D860–$DA5F` (the empty glyphs of control codes 0–31, which `INIT` no longer copies), hold the Korean command-name code and the INIT guard's table and flag; 1 byte is left. See `DOS_PATCHES_en.md` section 5. The old 6×8 English table that was there is gone. When the KBASIC add-on is loaded it sits in main RAM at `$8A00–$93FF` and lowers `HIMEM` to `$8A00` (see the KBASIC documents in the Korean BASIC project). The English glyph is found with `base + code × 16`.

`$0800–$1FFF` is 6,144 bytes. The pieces above use 6,051 of them. Of the 93 free bytes, `$1FCF–$1FE4` (22 bytes) now hold the main RAM stubs of the Korean DOS work (`KEXIT`, `KSTUB`, `KFN`, `KALS`), so 71 bytes were left; the 11 right after the stubs (`$1FE5–$1FEF`) are now used by the Ctrl-C check in `CATWAIT` (5 bytes) and by `HANRST`, the Ctrl-Reset stub (6 bytes). The banner segment (`$1CC0–$1FEF`) is full, and the stubs moved to `$1FDA–$1FEF`. DOS's unused bytes `$BCDF–$BCFD` hold the INIT guard's stubs.

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


## The second 4K bank of a 16K language card (since the speed work of 2026-11-12)

A 16K language card has its `$D000-$DFFF` in two 4K banks: bank 2 (the one the driver runs in: `$C080` reads it) and bank 1 (`$C088` reads it, `$C089` twice write-enables it). Nothing used bank 1 before. Now:

- **Code and small tables, `$D000-$D85B` (2,140 bytes, in the file):** `ENGFAST` (English) and `HANFAST` (Hangul), the 7 draw routines of each (`ENGK0`-`ENGK6`, `HANK0`-`HANK6`, one for each pixel offset of a glyph in its 7-pixel screen byte, with constant masks), the column tables `COLK` and `COLB` (`CH * 6` as a bit offset and a byte offset, 46 entries each), the jamo class table, `M24`, and `PACKF` with its tables (below). About 36 bytes are free before `$D880` (an assert in `engfast.inc` checks). Source: `src/driver/engfast.inc`, linker segment `LCB1` (run `$D000`).
- **Shift tables, `$D880-$DFBF` (1,856 bytes, NOT in the file):** made by the loader (`GenTabs` in `driver.s`) after it copies the code. For a 6-bit value v and shift k = 0-6, in blocks of 256 bytes from `TABS` ($D880, not on a page: `GenTabs` works out the page of each of its four stores): `B0_k` = `(v << k) and $7F`, `B1_k` = `(v << k) >> 7`, `HB1_k` = `((v << (k + 6)) >> 7) and $7F`, `HB2_k` = `(v << (k + 6)) >> 14`; then `HB0` = `(v << 6) and $7F`. A glyph row of 6 bits (English) uses `B0`/`B1`; a Hangul row of 12 bits is `H * 64 + L` and uses `B0`/`B1` for L and `HB0`/`HB1`/`HB2` for H. Linker segment `LCB1T` (type bss, memory area `B1TMEM` at `$D880`).
- **The file must end before `$6000`:** HELLO loads `FONT12` at `$6000` and the English font at `$7200` before `BRUN K-HANGEUL`, which loads at `$0F94`. A first version stored the tables in the file, ran past that limit (`SATDATA overflows MAIN`), and was changed to make them at load time. The file is 19,617 bytes and ends at `$5C34`.
- **How it gets there:** the loader copies segment `LCB1` with `$C089` twice, calls `GenTabs`, and goes back to the usual `$C081` state, only when no Saturn card is found.
- **How it is used:** `ENBLIT` (`$EBAA`, in the `$E000+` part that both banks share) copies the glyph's 10 font rows to `GLY` (the font is in bank 2, where bank 1 cannot see it), does `bit $C088`, `jsr ENGFAST`, `bit $C080`, and then returns (carry clear) or jumps to `BLIT` (carry set). `KOFAST` (in the spare bytes of `ENBLIT`'s 46) does the same for Hangul with `HANFAST` and jumps to `KOBLIT` when it declines (strip buffer `STRIPF`, overstrike `S_06AF`, `CH` >= 46, vowel code >= 22). The two stubs and `DRAWKO2` (`jsr KOFAST`) are the only changes in bank 2 and `$E000+`, apart from `DRAWKO` skipping the dead glyph-piece work (below).
- **Rules for code in bank 1:** it can call only what is in `$E000-$FFFF` or in main RAM (`MUL12`, `HGRLO`, `HGRHI`, the font at `$0800+`); it cannot read the English font, `CLASS`, the CATALOG code or anything else in `$D000-$DFFF` of bank 2. The driver always runs with bank 2 selected (`$C080`, set by every entry stub), so a stub that switches must switch back. The card is write protected, so no self-modifying code in the card (`GenTabs` modifies itself, but it runs from main RAM).
- **A space** (not inverse) in `ENGFAST` skips building the glyph rows (they are all zero) and goes to the 12-line loop of its shift (`ENGBk`).
- **`PACK` and `PACKF`:** `PACK` (`$F024`, the end of a typed or printed Hangul syllable: it packs `CHO`, `JUNG`, `JONG`, `JONG2` into the two code bytes `LEAD` and `TRAIL` and plots them) scanned three tables (about 600 cycles). On the plain card its first 12 bytes are now `bit $C088 / jsr PACKF / bit $C080 / jmp L_F097`; `PACKF` in bank 1 gets the same `LEAD`/`TRAIL` (and the new `JONG` when `JONG2` makes a pair) by lookup in tables made from the stock ones (`PCT`, `PJT`, `PGT`, `PCL1`, `PCL2`; comment in `engfast.inc`: remake them if `D_E2DB`, `D_E2EF`, `D_E305`, `D_E27C`, `D_E287` or `D_E31B` change). The rest of the old `PACK` body is not reached: its 103 bytes now hold `CURHK` (12 bytes: the line count of the cursor, 12 in English mode and 6 in Hangul mode; `CURSOR` calls it where it used to load 12), then NOPs (91 bytes free); the old labels are equates. Checked against the stock scans for 119,240 key combinations.
- **Saturn:** not used. The Saturn arrangement keeps the old `ENBLIT`, `KOBLIT` and `PACK` (the satpack lists restore them; `.if SATURN` in `driver.s`) and the loader neither copies `LCB1` nor makes the tables.
- **`DRAWKO` and the buffer at `$94F1-$9510`:** `DRAWKO` (the Hangul path, both arrangements) used to build the stock glyph pieces into `S_0750`-`S_076F` before calling `KOBLIT`. `KOFILL` does not read them and nothing else does (checked by searching the source), so `jmp DRAWKO2` at `L_F1CE` skips the work; the bytes after it stay where they were.
- **The dead buffer `$94F1-$9510` is partly used now (line editing).** Seven bytes of it hold the line editor's state: `STOPCV`/`STOPCH` (`$94F1/2`, where the fetch of a line stops), `CRB`/`CRM` (`$94F3/4`, scratch of `CLRROW`), `ENDV`/`ENDH` (`$94F5/6`, where the typed text of the line being edited ends) and `LESC` (`$94F7`, the last key was ESC). The other bytes stay unused. The only writer of the old buffer is code that nothing reaches. The state page is filled with `$A0` at start, so `ENDV = $A0` means "not known" and `STOPCV = $A0` means "no stop".
- **The unreachable stock glyph code after `DRAWKO` is the home of the line editor's new code.** Its 192 bytes (from `FCHK` to `DRAWKO2`) hold `FCHK`, `FETCHCUR`, `CXREAD` and `CLRROW`; the 22 bytes of the unreachable `L_F304` hold `CLRTAIL`. The sizes are kept (`.assert`, `.res`) because the stock code behind them must not move: raw `.byte` blocks in it hold absolute addresses (deleting the dead block alone stops the boot). The hooks are `jsr`/`jmp` plus `nop`s at `L_E656` (`jsr FCHK`), `L_E7F2` (`jsr CXREAD`), `L_E872` (`jmp FETCHCUR`) and `L_ED60` (`jsr CLRROW`).
- **Risk:** another program that writes to bank 1 of the card (a RAM disk, a card utility) would break drawing. Nothing in this project does.

## The Korean Applesoft error filter and the banner's place (16K card, since 1.4)

- `$1CC0-$1E50` (401 bytes) holds the start-up banner code only until the banner has run. `INIT` copies the banner segment there as before; `BN` prints it; its last instruction is `jmp KRC` (card on). `KRC` (in the `$D000-$D3FF` block) copies the segment `KERRRES` from the file (behind the banner, 379 bytes at the end of the first file part: `KEFILT`, `KPUTS`, the callers table `TH/TL/TC/TK`, the text table `KEK/KET`: the 17 texts + ` 오류` + ` 줄 ` + `중단` + `입력 무시` + `다시 입력`, source `kerr.inc` and `kerr_text.inc`) over it, clears `PBANOK` (`$1CBE`, 0 once the banner has run) and leaves with the card off, as `BN`'s `rts` did. Free in that place: 3 bytes (1.6: 398 of 401).
- `$E42C` (the end of `STATEINIT`) is `jmp PBAN`, it was `jmp BN`: `PBAN` jumps to `BN` only while `PBANOK` is `$80` (set by the loader, in the plain-card path after `GenTabs`), otherwise it leaves through `KEXIT`. So `HAN`, Ctrl-Reset and DOS's `INIT` do not print the banner again.
- `KBOUT` (the start of `COUT`) does `bit PBANOK / bmi` and calls `KEFILT` only when the banner has run: before that the filter's place still holds the banner. `KEFILT` keeps `A`, `X` and `Y` and uses `KEA/KEX/KEY` (`$94F8-$94FA`, the dead glyph buffer) and the zero page pointer `KPL` (`$1A/$1B`; the draw code clobbers `$06/$07`, so those cannot be used). `KBASIC`'s `BHEX`, `BPAR`, `BDEC` and `NUM` stay at `$1E51-$1ED0`.
- Saturn card (1.5): the filter is in bank 6, page 1 (`kerr6.inc`, scope `K6`, keystroke text); see the 1.5 entry of `CHANGELOG_en.md`. The file carries `KERRRES` there too (so both builds have the same layout) but nothing copies it. The file must end before `$6000` (7 bytes left in 1.6: `MAIN` in `driver.cfg` enforces it). The 1.6 Saturn text table (`KET`) is longer than 256 bytes, so `kerr6.inc` counts with a 16-bit pointer.

## Saturn 128KB card (the design, as built; the heading is from the draft)

> Status: a design draft on the `saturn` branch. No code has changed, and anything marked "undecided" below has not been settled. It is written down first so that the kScheme side can design its console hook against it.

### Goals

- One file (`K-HANGEUL.bin`). The arrangement is chosen once, at load time. The file holds the plain driver and, at its end, a list of byte patches for the Saturn arrangement (written by `src/tools/satpack.py`); the loader applies them only when it finds a Saturn card, so a plain card loads exactly the plain driver.
- On a 16KB language card (or when no Saturn card is found) it behaves exactly as today. The memory map is the same too.
- On a Saturn card the driver, fonts, text buffer and variables go into the top bank of the card, and main RAM `$0800–$1FFF` is freed.
- BASIC's `HIMEM` stays at `$9400` or better.

### The bank

- K-HANGEUL uses the top bank (the eighth on a 128KB card, bank 7). It is found at load time.
- The bank holds the driver code, the English and Korean fonts (in a packed form on Saturn), the 46×16 text buffer, the row flags, the variables, and the prompt and `CATALOG` helper code.
- A signature marks this bank: the four bytes `KHG1` at `$FFF5–$FFF8` (the driver image ends at `$FFF4`, and `$FFFA–$FFFF` are the vectors). `$FF80`, where kScheme writes its detection tag, lies inside the driver code, so kScheme must save and restore that byte.
- The detection that finds banks must not destroy a bank's contents (save the byte before writing the tag, then restore it, last bank first). K-HANGEUL's loader does so with the byte at `$FFF9` of banks 1–7. It takes the highest bank that kept its own tag as the top bank, and writes the switch that selects it to `$D3FF` of that bank (the driver reads it to set the operand of `SatEnter`).
- kScheme does not use this bank as its file cache.

### What stays in main RAM: `$9400–$95FF` (the same in both arrangements)

- The five entry addresses are the same as today: `$9400`, `$940A`, `$9414`, `$941E`, `$9571`. The I/O hooks (CSW, KSW) point at them.
- In the Saturn arrangement each entry becomes `lda #n` / `jmp TRAMP` (5 bytes). The address of `TRAMP` is undecided and lies inside this block.
- What `TRAMP` does: it reads the caller's card state from the state byte below, selects the K-HANGEUL bank, maps the image, calls the routine, and returns to the state the state byte describes.
- Registers: A, X, Y and the flags go in and come out the same way as with today's stubs.
- On a Saturn card the driver runs with the card write enabled (`$C083` twice), because its text buffer and variables are in the bank. There is no self-modifying code. On a plain card the driver is write protected as before.

### State byte `$95E2`

Saturn bank selects are write-only, and an Apple II+ cannot read back the state of a language card. So the caller writes its "resting state" into this byte, and `TRAMP` reads the state to restore from it.

| Bits | Meaning |
|---|---|
| 0–2 | Reserved, must be 0: the caller is in Saturn bank 0 (home). `TRAMP` always returns to bank 0 |
| 3 | `$D000` page: 1 = first page (the `$C08B` family), 0 = second page |
| 4 | 1 = reads card RAM, 0 = reads ROM |
| 5 | 1 = card write enabled, 0 = write protected |
| 6–7 | Unused (0) |

- BASIC value (card ROM read, write protected, bank 0, first page): `$08`. This is the default that `INIT` sets.
- kScheme value (bank 0, first page, RAM read, write enabled): `$38`.
- The byte must always be true: whoever switches the card keeps it matching what the card really is. `TRAMP` restores from it on every call.
- kScheme writes it when it takes over the console (`$38`), and sets it back to `$08` when it hands the console back to BASIC. Around every ROM call kScheme's `romcall` also writes `$08` before it switches the card out and `$38` after it switches the card back in. This matters because the ROM `COUT` and `RDKEY` reach the console through CSW and KSW, so `TRAMP` is then entered with the ROM visible.
- Saturn bank changes inside kScheme's arena access (`far_sel`) do not call the console, so they need no update.

### Nested entries and the depth byte

The driver calls its own input hook from inside itself (the line input), so entries nest. `SATDEPTH` (`$9511`) counts them. An inner leave only switches the ROM in and keeps the bank, as the stock stubs do. Only the outermost leave selects bank 0 and sets the caller's card state from `$95E2`. The end of the line input rewinds the stack and skips the outer leave, so it goes through a separate exit that sets the depth to 1 first. While the driver waits for a key inside a line input the count reads 2 (the line input rewinds the stack and so skips one leave); in the caller's domain it reads 0. When kScheme takes over the console it writes `SATDEPTH` = 0 together with `SATSTATE` = `$38`, and it writes 0 and `$08` when it gives the console back. Status: built and tested in MAME with `-sl0 ssram` (the driver in bank 7 gives the same text buffer and the same visible screen as the stock driver after boot, `PRINT`, and `CATALOG`). The bytes used inside `$9400–$95FF` are `$9511–$951F`, `$9521–$9547`, `$95CE–$95DA` and `$95E2–$95F7`.

### What stays as it is

- The K-BASIC hooks `KBBASE=$8A00` (signature "KB" at `+3`, entries at `+5` and `+8`).
- The `$95DD–$95E1` bytes used by STYPE.
- `HELLO` loading `FONT12` at `$6000` and `FONT6X10` at `$7200`. Rule: these are only staging areas. The driver's `INIT` copies both fonts into the bank before anything else uses that memory, so kScheme may load over `$6000–$99C0` only after K-HANGEUL has been loaded. Load order is K-HANGEUL first, then kScheme.

### What changes (not built yet)

- K-BASIC reads `$C080` from main RAM to check that `COUT` is a `JMP`. On Saturn that shows whichever bank is selected, so it must select the K-HANGEUL bank first. Also `BHEX`, `BPAR`, `BDEC` and `NUM` move into the bank, so they need entries that go through `TRAMP`.
- kScheme: it must leave this block (`$9400–$95FF`) free, and plans its own layout with the hi-res screen (page 1, `$2000–$3FFF`) and `$0800–$1FFF` free of K-HANGEUL.

### Undecided

- Status of the implementation: built and tested in MAME (`-sl0 ssram`): card and top-bank detection, the signature, the patch lists, the trampoline, and the Saturn banner line (`$D000 새턴 카드 뱅크7에 로드됨`: loaded at `$D000` in the Saturn card, bank 7). Not built yet: moving the fonts, the text buffer, the variables and the banner out of `$0800–$1FFF` into the bank. See "What is left" below.
- Whether to shrink the state block below `$9400–$95FF` (to about 250 bytes, which would also move the plain-card state addresses).
- All Saturn test results. Bank switching has not yet been tried in MAME (`-sl0 ssram`).


### What is built

All of it is built and tested in MAME (`-sl0 ssram`; the stock build on a plain card and this build on a Saturn card give the same screens for boot, Hangul typing, `RUN`, `CATALOG` with paging, the bell, `HAN`, `& TYPE`, `& STYPE`, and all 11,172 syllables):

- The Korean font (packed to 18 bytes a glyph) and the English font (glyphs 31–127, 10 bytes each) are in the bank. The Korean font is in the other `$D000` page, which `SatUnpack` (at `$E000`) selects only while it reads a glyph.
- The text buffer (`BUF`, 736 bytes), the row flags and the variables are in the bank, in the page the driver runs in, behind the English font (`$DC2A–$DF75`). The driver runs with the card write enabled while it is inside. `GLY` and `GLYHI` are at `$E048–$E05F` because they are written while the other page is selected.
- The prompt routines (`CHECK`, `DRAWPR`, `WRAP`), the bell (`SatBell`, no ROM call) and the `CATALOG` page routines (`CatwaitB`, `CatinitB`) are in the bank, in the padding of the driver page. The machine flag (`SHMACH`) and the banner flag (`BANOK`) are bank variables; the loader copies `SHMACH` there.
- The start-up banner runs once, at boot, from `$6000–$630F` (free after the loader has packed the fonts). On the `HAN` command the banner is not shown again.
- DOS reaches three small stubs in the `$9400–$95FF` block: `CATWAIT` at `$9571` (6 bytes), `CATINIT` at `$9470` (6 bytes) and `HAN` at `$9481` (7 bytes). The loader writes the `HAN` address into DOS.
- One thing needed care: the ROM's `RDKEY` reads and writes the cursor cell of the text buffer through `BASL/BASH` while the ROM is visible. With the buffer in the bank that reads ROM bytes. The stub at `$9414` therefore reads the cell before it switches the ROM in; the ROM's own write is dropped, which is harmless. Any other ROM routine that reads the text screen through `BASL` also sees ROM bytes on a Saturn card.

After boot, K-HANGEUL uses no main RAM in `$0800–$1FFF` on a Saturn card (checked by filling that range with a pattern after boot and running Hangul input, `RUN`, `CATALOG`, `BRUN TYPE`, `& TYPE`, `BRUN STYPE` and `& STYPE`: not one byte changed). Its only main RAM is the `$9400–$95FF` block.

### K-BASIC on a Saturn card (not changed yet)

K-BASIC is a separate project and has not been touched. On a Saturn card two things it relies on are different:

- `BHEX`, `BPAR`, `BDEC` and `NUM`, which K-BASIC calls at install to print the memory report, are in the banner, which no longer stays in main RAM. K-BASIC has to carry its own copies (about 128 bytes, used only at install), which also work on a plain card, so one K-BASIC can serve both.
- K-BASIC's check that `COUT` in the language card is a `JMP` reads `$C080` from main RAM. On a Saturn card that shows whichever bank is selected. It has to be replaced by a check that works on both cards, for example that the `COUT` entry at `$940A` is a `JSR` or `JMP`.

K-BASIC's hooks (`KBBASE=$8A00`, signature "KB" at `+3`, entries at `+5` and `+8`) are unchanged.


### Rebuilding the block after a program load (frozen interface)

A program that is loaded over `$9400–$95FF` (kScheme's file has 512 zero bytes there) destroys the trampoline, the stubs and the driver state in main RAM, but not the driver in the bank. Its first action can rebuild all of it with the rebuild entry, which is the `HAN` command without DOS:

- **Find the bank.** Look for the four bytes `KHG1` at `$FFF5–$FFF8` of a bank. `KHG1` only says that an image exists in that bank (card RAM keeps its contents over a warm reset). To be sure that K-HANGEUL was loaded in this session, also check that DOS's saved output hook `$AA53/$AA54` is `$0A/$94` (the `$940A` entry), and read the three frozen bytes below.
- **Check the entry.** With the bank selected and RAM read on, `$D3FA` is `4C` (a `jmp`), `$D3FD` is the interface version `$01` and `$D3FE` is the magic byte `$5A`. Refuse to call it if they differ.
- **Call it.** Select the bank (its switch byte is also at `$D3FF` of that bank), then set the card to `$D000` page 2, RAM read and write (`bit $C083` twice), then `jsr $D3FA`. Do nothing that prints between the end of the load and this call (BRUN prints nothing; `CSW` and `KSW` still point to `$940A` and `$9400`, which hold zeros in the filler).
- **On return:** the block is rebuilt (state, trampoline, stubs, DOS hooks, `CSW`/`KSW`). The card is ROM read, write protected, `$D000` page 1, Saturn bank 0 (`SATSTATE` is `$08`, `SATDEPTH` is 1 and ends at 0 after the leave). A, X, Y and the flags are undefined. The stack is balanced; it needs at most about 20 bytes while it runs. There is no error return. The caller then writes `SATSTATE` = `$38` and `SATDEPTH` = 0 when it takes over the console, and sets the card to its own resting state.
- **Side effects:** the text window and cursor (`$20–$25`), `$33`, `$36–$39` (`CSW`/`KSW`), `$E4` and `$E6` (= `$20`, hi-res page 1) are set again, the display switches go to full-screen hi-res page 1, the DOS hooks are reconnected, and the Hangul state (modes, cursor, flags) is reset. It does not clear the screen or the text buffer; they keep what they had.
- **Tested** in MAME: after the whole block was overwritten with zeros, `BRUN` of a test program that calls the entry returned to BASIC, `PRINT` worked, and `CSW`/`KSW` pointed to the stubs again. Not tested with a real kScheme load.

The addresses `$D3FA`, `$D3FD`, `$D3FE`, `$D3FF` and `$FFF5–$FFF8` do not move; the build has an assert for the entry.

## Korean DOS on a Saturn card

- Bank 6, `$D000` page 1, `$D000-$D300` (769 bytes): the Korean DOS code (segment `BANK6`), copied by the loader when the driver is in bank 7. kScheme leaves this page alone when K-HANGEUL is in bank 7.
- DOS's unused bytes `$BCDF-$BCFA`: the stubs `K6IN`, `K6SEL`, `K6MSG`, `K6AL`, `K6PUT`.
- `$951A-$951F` in the `$9400-$95FF` block: the stub `K6FN`, written by every `SATCOPY` (so the rebuild entry `$D3FA` makes it again).
- Bank 7: `KPATCH6` and its data fill the free bytes before the shift masks (`$D316-$D3CF`).
- Main RAM `$0800-$1FFF` is still not used on a Saturn card.
