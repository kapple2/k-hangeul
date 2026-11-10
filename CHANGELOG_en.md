# Changelog

> 한국어: [CHANGELOG.md](CHANGELOG.md)

The version number is written in one place only, the `VERSION` file at the top of the repository. The build takes the `v1.2b` text of the start-up banner from it.
To raise the version, write a new entry at the top of this file and change the version text in the user manual (`docs/MANUAL.md`, `docs/MANUAL_en.md`) too.

## 1.2b (branch `saturn`)

- Korean DOS on a 16K language card: Korean error messages and `CATALOG` header, file names that start with Hangul, Korean names for 25 DOS commands (`PR#`, `IN#`, `FP` stay English). See `docs/MANUAL_en.md` section 8.
- The same Korean DOS on a 128K Saturn card (code in bank 6, `$D000` page 1).
- `INIT` formats a disk again while the driver is loaded on a 16K card (since Hangeul2 it restarted the driver instead), and the new disk gets stock DOS 3.3. On a Saturn card `INIT` still restarts the driver.
- A comma ends a Hangul run in the line editor, so a Hangul file name can be followed by a comma (`BSAVE B한,A$300,L4`).
- The empty glyphs of control codes 0-31 in the English font area are used for code (16K card build).
- When `CATALOG` (`목록`) has paused at the end of a page, Ctrl-C ends the listing and returns to the `]` prompt (16K card and Saturn card).
- Ctrl-Reset starts the Hangul driver again by itself (no `HAN` needed). The loader sets this up only if the reset vector (`$03F2`) is still DOS's own warm start. On a Saturn card the same six bytes are written into the unused `INT` handler of DOS (`$A5A1`).
- Fixed: the loader stored the Apple IIe flag (`$1CBD`) inside the driver image *before* the image was copied into the card, which zeroed one byte of it (in the 16K build the last line of the INIT guard's table `KSWT`, the high byte of the stock INIT handler address). So a disk made by `INIT` carried a DOS whose INIT handler address pointed to `$004E` instead of `$A54E` (`$9D1F` was `$00` instead of `$A5`). It now stores after the copy, and `$9D1E-$9D1F` on a new disk equals stock DOS 3.3 (checked in MAME).

## 1.1b

- Saturn 128K card support. One `K-HANGEUL.bin` works on a plain 16 KB language card and on a Saturn card.
  On a Saturn card the driver, fonts and data live in the top bank, so `$0800-$1FFF` is free, and BASIC `HIMEM` stays at `$9400`.
  On a plain card the behavior and the memory layout are the same as 1.0b.
- The start-up banner has a Saturn card line (`$D000 Saturn card bank N loaded`, in Korean).
- A frozen entry `$D3FA` (`jmp STATEINIT`) that rebuilds the `$9400-$95FF` block after a program load has wiped it; version byte `$D3FD=$01`, check byte `$D3FE=$5A`. Details in `docs/MEMORY_LAYOUT.md`.

## 1.0b

- The first release of the modified Hangeul2. 16 KB language card, DOS 3.3.
