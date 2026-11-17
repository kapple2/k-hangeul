# Changelog

> 한국어: [CHANGELOG.md](CHANGELOG.md)

The version number is written in one place only, the `VERSION` file at the top of the repository. The build takes the `v1.2b` text of the start-up banner from it.
To raise the version, write a new entry at the top of this file and change the version text in the user manual (`docs/MANUAL.md`, `docs/MANUAL_en.md`) too.

## 1.6 (2026-11-17)

- **`BREAK` (Ctrl-C, `STOP`) is in Korean: `BREAK IN 10` shows as `중단 줄 10`.** This fixes a 1.5 mistake: the filter did not know that `BREAK` is printed by the same call as ` ERROR` (`$D431`), so it swallowed `BREAK` and only ` 줄 10` was left. Now the CR is the ROM's, `중단` is printed at the `B`, the other characters are swallowed and the beep is the ROM's.
- **The `INPUT` messages `?EXTRA IGNORED` and `?REENTER` are in Korean: `?입력 무시`, `?다시 입력`.** The `?` is the ROM's (INPUT's prompt `?` has the same return address as `?EXTRA IGNORED`, so the `?` is let through), the Korean text is printed at one character (the `X` of `EXTRA`, the `N` of `REENTER`) and the rest is swallowed. The return addresses are `$DB $96` for `?REENTER` (the `JSR` at `$DB94`) and `$D8 $22` for `?EXTRA IGNORED` (where the `INPUT` handler returns to `NEWSTT`). They were read from the stack in MAME. A scan of the Applesoft ROM (II Plus) shows that the 17 errors, ` ERROR`, ` IN `, `BREAK`, `?EXTRA IGNORED` and `?REENTER` are all its texts.
- **The filter is table driven.** The four callers of `STROUT` (`TH`, `TL`, `TC`, `TK`: return address high and low byte, the character that gets the Korean text, the key in `KEK`) are a table searched by one loop (before, a chain of compares). Both cards are 56 bytes smaller. `Y` is saved in `KEY` when the filter starts and restored when it leaves; the Saturn card keeps `X` and `Y` on the stack.
- **Shorter texts and no spaces** (to make room: the file must end before `$6000`). On the Saturn card a space in keystroke text costs 3 bytes (leave Hangul mode, space, enter it again). DOS: `파일없음` (was `파일을 찾을 수 없음`), `용량초과` (`프로그램이 너무 큼`), `형식다름` (`파일 종류 다름`), `공간부족` (`디스크 가득 참`), `직접 불가` (`직접 명령 아님`), `언어없음`, `쓰기금지`, `볼륨다름`, `파일잠김`, `버퍼부족`, `자료끝`. Applesoft: `자료끝`, `줄없음`, `메모리부족`, `배열중복`, `직접불가`, `형식다름`, `계속불가`. New texts: `중단`, `입력 무시`, `다시 입력`. (`범위 오류`, `입출력 오류`, `문법 오류` and the two-word names keep their space.)
- **The Saturn card's DOS texts are made by `genkerr.py` too** (`kdos6_text.inc`; before, hand-written bytes in `kdos_msg.inc`). If they fit one table the second is not used (`KMSGK2`); they do now.
- **Saturn card: the text table (`KET`) is longer than 256 bytes.** `kerr6.inc` counts the texts with a 16-bit pointer now (an 8-bit `Y` wrapped and `?REENTER` showed `문법`).
- **File size:** 20,581 bytes (7 bytes left below `$6000`). `KERRRES` is 398 of 401 bytes.
- **Checked:** in MAME on the II Plus (16K card) and the II Plus with the Saturn card (`-sl0 ssram`): `STOP`, `1/0`, `GOTO 99`, `LOAD NOFILE`, `INPUT` with `1,2` and with `X`. On the enhanced IIe and the IIc only `?REENTER` was checked; `BREAK` and `?EXTRA IGNORED` were not, because of a key-typing problem of the test tool (the ROM text is the same).
- **Not done** (`MANUAL_en.md` section 8b): Monitor ROM text (cassette `ERR` and so on), Integer BASIC, ProDOS messages, use without DOS's output hook, a Saturn card that is not 128K, `BREAK` / `?EXTRA IGNORED` on the IIe and IIc, real machines.
- Manual: the tables of the Korean DOS command names and DOS messages (section 8), the Applesoft message table and its limits (sections 8a, 8b). Fixed a tab character that had got into `src	ools` in `BUILD.md`.
- Version 1.6.

## 1.5 (2026-11-17)

- **Korean Applesoft error messages on the Saturn 128K card too.** The code and the text (as Hangul-mode keystrokes, printed through `K6PUT` like the Korean DOS messages) are in bank 6, page 1 (`src/driver/kerr6.inc`). `KBOUT` calls the stub `K6FN` (`$951A`), which now goes to `KDISP` in bank 6: it tells DOS's file name check from the error filter by the high byte of the return address (`$D1` is `KBOUT`), then does the same as `KEFILT` (the stack frames at `COUT` are the same on both cards). It returns to the driver by `jmp SatEnter` after two `dec SATDEPTH`; a swallowed character drops its return into `KBOUT` first. While it prints, `COUT` comes back through the filter for every character and overwrites `KEA/KEX`, so the ROM's X is kept on the stack. Without bank 6 code (the driver not in bank 7) `KPATCH6` makes `K6FN` an `rts`. Tested in MAME with `-sl0 ssram`.
- **Shorter texts and a smaller table** (both cards): `범위` (ILLEGAL QUANTITY), `첨자` (BAD SUBSCRIPT) and `줄 없음` (UNDEF'D STATEMENT). The text is found by counting off `$00` ends (keys in `KEK`) instead of a table of addresses, which saved 19 bytes of the file.
- **File size.** The file must end before `$6000`: `MAIN` in `driver.cfg` now ends there (`$506C` bytes), `SATDATASIZE` is 2784, and `satpack.py` merges runs closer than 3 bytes (it was 4). The file is 20,566 bytes (ends at `$5FE9`: 22 bytes left).
- `KBIN` and `KBOUT` share the add-on's signature check (`KBCHK`), and `KBOUT` no longer stores `CHAR` first (3 bytes less on the Saturn card, where the driver page was full).
- Version 1.5.

## 1.4 (2026-11-17)

- **Korean Applesoft error messages (16K card).** `?UNDEF'D STATEMENT ERROR IN 10` now shows as `?없는 문장 오류 줄 10`; all 17 Applesoft errors have a Korean text (`FOR 없음`, `문법`, `GOSUB 없음`, `자료 끝`, `값 범위`, `넘침`, `메모리 부족`, `없는 문장`, `첨자 범위`, `배열 중복`, `0으로 나눔`, `직접 불가`, `형 다름`, `문자열 김`, `식 복잡`, `계속 불가`, `없는 함수`). ` ERROR` becomes ` 오류` and ` IN ` becomes ` 줄 `; the line number and the bell are the ROM's. The ROM's English text is not changed: `KBOUT` (the start of `COUT`) calls `KEFILT` (`src/driver/kerr.inc`), which recognises the ROM's error printer by the return addresses on the stack (`$66 $DB`, then the caller of `OUTDO`: `$D425` the message loop, `$D433` ` ERROR`, `$ED1F` ` IN `; the same on the II Plus, IIe and IIc ROMs) and prints the Korean text instead. Any other output goes on unchanged. Without DOS's output hook in the chain (CSW set to the driver directly) the frames differ and the text stays English. Tested on the II Plus, enhanced IIe and IIc (MAME), with and without the KBASIC add-on.
- **The text is johab pairs** (2 bytes a syllable, made by `src/tools/genkerr.py` into `kerr_text.inc`) drawn with `PLOTCH`, not Hangul-mode keystrokes. The Korean DOS messages of the 16K card (`kdos_msg.inc`) use the same form now (`kdos_johab.inc`, 185 bytes instead of about 340), printed by `KPUTS`: the screen is the same, and 95 bytes of the `$D000-$D3FF` block came free. The Saturn card keeps the keystroke text in bank 6.
- **HAN, Ctrl-Reset and INIT no longer print the start-up banner again** (the Saturn arrangement already did not). The banner code runs once, at boot, from `$1CC0`; then `KRC` copies the error filter (segment `KERRRES`, in the file behind the banner) over it, `jmp PBAN` at `$E42C` (it was `jmp BN`) skips the banner when `PBANOK` (`$1CBE`) is clear, and `KBOUT` calls the filter only then. `BHEX`, `BPAR`, `BDEC` and `NUM`, which the KBASIC add-on calls, stay at `$1E51-$1ED0`. The file grew by 379 bytes (20,150 bytes).
- **Saturn card: not in 1.4** (see 1.5).
- Version 1.4.

## 1.3 (2026-11-16)

- **Version 1.3.** The start-up banner shows `v1.3`. The version text in the `VERSION` file may now be 3 or 4 characters (`1.3`, `1.2b`): a 3 character text gets one space after it, so the banner keeps its length and nothing in the memory map moves. From this version every change to the driver raises the version number.
- **Text prints faster.** In the simulator, one English character takes 2,199 cycles instead of 4,252 (**1.93 times faster**) and one Hangul syllable 5,432 instead of 9,678 (**1.78 times**); a space 2,035. Every picture is the same, pixel for pixel (174 test cases, see below).
- **Hangul, both cards:** `DRAWKO` used to build the glyph pieces the stock Hangeul2 way into the 32 bytes at `$94F1-$9510` before drawing, and nothing reads that buffer any more (`KOFILL` builds the glyph from the font by itself). That work (about 2,000 cycles a syllable, 20%) is skipped: `L_F1CE` is now `jmp DRAWKO2`. This part also speeds up the Saturn arrangement.
- **16K card only: a fast draw in the card's second 4K bank** (`$D000`, bank 1 in card terms), which nothing used before: `src/driver/engfast.inc`, segment `LCB1` (2,140 bytes). `ENBLIT` (English) copies the glyph's 10 font rows to `GLY` and calls `ENGFAST` there; `KOFAST` (Hangul) calls `HANFAST`. Both draw through shift tables with one routine for each of the 7 pixel offsets, instead of the 3-byte shift loop, the divide-by-7 loop and `BLIT`'s row loop; `HANFAST` also finds and ORs the three jamo glyphs itself (it replaces `KOFILL` and `OL`). If the strip buffer (`STYPE`), overstrike or underline is on, or a column or vowel code is out of range, they decline (carry set) and the old code runs (`BLIT` / `KOBLIT`).
- **The tables are not in the file.** The loader (`GenTabs` in `driver.s`) makes the shift tables into bank 1 at `$D880-$DFBF` (1,856 bytes) when it loads, so `K-HANGEUL` grew by only 2,371 bytes (19,617 bytes, 77 sectors). The file must end before `$6000` (HELLO loads `FONT12` there first): it ends at `$5C34`.
- **16K card, Hangul typing/printing:** `PACK` (packs a finished syllable into its two code bytes) now looks the codes up in tables (`PACKF` in bank 1) instead of scanning three tables: about 600 cycles a syllable. A space (not inverse) skips the glyph build.
- **The cursor shows the mode (16K card):** a solid whole-cell block in English mode, the upper half of the cell in Hangul mode (`CURSOR` takes its line count from `HMODE` through `CURHK`, which sits in the dead body of `PACK`). The width still follows the cell under it. The Saturn arrangement keeps the whole block in both modes. Tested with `curtest.py`, a test script kept outside this repository.
- The Saturn arrangement keeps the old English and Hangul drawing (the satpack lists restore it) and does not copy the bank-1 code or make the tables.
- Details: `docs/MEMORY_LAYOUT_en.md` ("The second 4K bank"), the analysis record `SPEED-ANALYSIS_2026-11-12.md` is kept outside this repository.
- Tested with `pixtest.py`, a test script kept outside this repository (174 cases: every English glyph at every column, normal and inverse, 46 columns, all 11,172 syllables, scroll windows) in the simulator, in MAME on a 16K card and in MAME with a Saturn card, and with `abrun.py` (`CATALOG`, `PRINT`, `LIST`, `RUN`, `STYPE`, `TYPE` on both cards). Not tested: real hardware, Apple IIe/IIc/IIgs, K-BASIC and kScheme on this build.
- **Line editing like the stock Apple II (16K card and Saturn card).** The line editor reads the typed line back from the screen, so these keys did not do what stock GETLN does:
  - **Left arrow, then Return:** the line is now only the text up to where the typed text ends. `ABC`, left arrow twice, Return gives `A` at `INPUT` and at the `]` prompt, as on a stock Apple II (before, the whole row `ABC` was read). It works over a Hangul syllable too (one syllable is one step). The right arrow copies the character under the cursor again.
  - **ESC cursor keys** (`A B C D`, `I J K M`) and the ESC clears (`E`, `F`, `@`) do not change the line, as in stock: `ABCD`, ESC `J` three times, Return still gives `ABCD`. The driver keeps the end of the typed text (`ENDV`/`ENDH`) for this; only typing, the left arrow and the right arrow move it.
  - **Ctrl-X** cancels the line: it prints `\`, goes to a new row and starts the line again (no prompt is printed, as on the stock Apple II). It was ignored before.
  - **ESC E and ESC F** cleared the hi-res bytes from the byte with the column's number, but a cell is 6 pixels wide and a byte holds 7, so pixels of the cell at the cursor (or, further right, of many cells) were left on the screen. They now clear from the exact pixel (`CLRROW`).
  - Fixed on the way: a Hangul syllable still being composed when Return was pressed was cut off.
  - How: the code is in the unreachable stock glyph code after `DRAWKO` (192 bytes from `FCHK` to `DRAWKO2`, same size, nothing after it moved) and in the unreachable `L_F304` (now `CLRTAIL`, 22 bytes). The hooks replace instructions with the same number of bytes (`L_E656`, `L_E7F2`, `L_E872`, `L_ED60`). New state bytes `$94F1-$94F7` (`STOPCV STOPCH CRB CRM ENDV ENDH LESC`) in the dead glyph buffer. Details: `docs/MEMORY_LAYOUT_en.md`.
  - Still different from stock: the line is what is on the screen, not a separate buffer. After ESC `A`/`B`/`@` or ESC `E` and typing, or Return after ESC `D`/`I` (cursor on an older row), the line is the screen text, where stock keeps what was typed. Ctrl-S pauses printing as in stock (it did already).
  - Tested in MAME (16K card and Saturn card) against a stock DOS 3.3 disk and against the old driver: 15 of 19 `INPUT` cases give the stock result (the other 4 are the screen-versus-buffer cases above), all Hangul cases without a left arrow give the old result, ESC E and ESC F match a line typed only up to that column pixel for pixel (8 columns), and 40 printed screens (`ALLTEST1-3`, `MODETEST`) are unchanged. Not tested: real hardware, Apple IIe/IIc/IIgs, K-BASIC and kScheme on this build.

## 1.2b (branch `saturn`)

- Korean DOS on a 16K language card: Korean error messages and `CATALOG` header, file names that start with Hangul, Korean names for 25 DOS commands (`PR#`, `IN#`, `FP` stay English). See `docs/MANUAL_en.md` section 8.
- The same Korean DOS on a 128K Saturn card (code in bank 6, `$D000` page 1).
- `INIT` formats a disk again while the driver is loaded on a 16K card (since Hangeul2 it restarted the driver instead), and the new disk gets stock DOS 3.3. On a Saturn card `INIT` still restarts the driver.
- A comma ends a Hangul run in the line editor, so a Hangul file name can be followed by a comma (`BSAVE B한,A$300,L4`).
- The empty glyphs of control codes 0-31 in the English font area are used for code (16K card build).
- When `CATALOG` (`목록`) has paused at the end of a page, Ctrl-C ends the listing and returns to the `]` prompt (16K card and Saturn card).
- Ctrl-Reset starts the Hangul driver again by itself (no `HAN` needed). The loader sets this up only if the reset vector (`$03F2`) is still DOS's own warm start. On a Saturn card the same six bytes are written into the unused `INT` handler of DOS (`$A5A1`).
- Fixed: the loader stored the Apple IIe flag (`$1CBD`) inside the driver image *before* the image was copied into the card, which zeroed one byte of it (in the 16K build the last line of the INIT guard's table `KSWT`, the high byte of the stock INIT handler address). So a disk made by `INIT` carried a DOS whose INIT handler address pointed to `$004E` instead of `$A54E` (`$9D1F` was `$00` instead of `$A5`). It now stores after the copy, and `$9D1E-$9D1F` on a new disk equals stock DOS 3.3 (checked in MAME).
- Fixed: when a typed line ran past the last column, the row it continued on got another `]` in its first cell. The driver now draws no `]` there when the last thing it drew was a typed character (16K card, Saturn card).
- Fixed (Saturn card, present since 1.1b): pressing the left arrow (backspace) while typing a line and then Return dropped into the monitor (`*`). Two stubs in main memory (the exit at the end of the line input, `$9599`, and DOS's file name check, `$95A6`) were inside an array the line editor writes (`$9580-$95A8`). They moved to free bytes at `$95CE` and `$951A`.

## 1.1b

- Saturn 128K card support. One `K-HANGEUL.bin` works on a plain 16 KB language card and on a Saturn card.
  On a Saturn card the driver, fonts and data live in the top bank, so `$0800-$1FFF` is free, and BASIC `HIMEM` stays at `$9400`.
  On a plain card the behavior and the memory layout are the same as 1.0b.
- The start-up banner has a Saturn card line (`$D000 Saturn card bank N loaded`, in Korean).
- A frozen entry `$D3FA` (`jmp STATEINIT`) that rebuilds the `$9400-$95FF` block after a program load has wiped it; version byte `$D3FD=$01`, check byte `$D3FE=$5A`. Details in `docs/MEMORY_LAYOUT.md`.

## 1.0b

- The first release of the modified Hangeul2. 16 KB language card, DOS 3.3.
