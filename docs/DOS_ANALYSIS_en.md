# Koreanizing DOS 3.3 commands: cost and feasibility

> 한국어: [DOS_ANALYSIS.md](DOS_ANALYSIS.md)


This note asks which parts of DOS 3.3 are worth showing in Korean, what each would cost in memory and work, and what cannot be done. It is an analysis only: nothing here is built yet.

How the facts below were found: the DOS in `disk\K-HANGEUL.DSK` was booted in MAME and its memory (`$9600-$BFFF`) was dumped and read. Addresses are for that DOS (patched by this project as in `DOS_PATCHES_en.md`). Where something was tested in MAME it says so; everything else is read from the dump or estimated, and says "estimate".


## 1. All DOS commands

DOS 3.3 has 28 commands. The names are in a table at `$A884`. On this disk `INT` is replaced by `HAN` (see `DOS_PATCHES_en.md`).

| command | what it does | does it print anything? | worth localizing? |
|---|---|---|---|
| `INIT` | formats a disk and writes DOS on it | nothing (errors only) | no |
| `LOAD` | loads a BASIC program | nothing (errors only) | no |
| `SAVE` | saves a BASIC program | nothing (errors only) | no |
| `RUN` | loads and runs a program | nothing (errors only) | no |
| `CHAIN` | runs a program and keeps the variables | nothing (errors only) | no |
| `DELETE` | removes a file | nothing (errors only) | no |
| `LOCK` / `UNLOCK` | protects or frees a file | nothing (errors only) | no |
| `RENAME` | changes a file name | nothing (errors only) | no |
| `OPEN` / `CLOSE` | opens or closes a text file | nothing (errors only) | no |
| `READ` / `WRITE` / `APPEND` / `POSITION` | text file access | nothing (errors only) | no |
| `EXEC` | runs a text file as typed commands | nothing (errors only) | no |
| `CATALOG` | lists the files on the disk | **the list** (header, volume number, type, size, name) | **yes** |
| `MON` / `NOMON` | shows or hides a trace of disk I/O on the screen | trace lines only while `MON` is on | no (rarely used) |
| `PR#` / `IN#` | selects the output or input slot | nothing | no |
| `MAXFILES` | sets the number of file buffers | nothing | no (it also breaks `HIMEM`, see `DOS_PATCHES_en.md`) |
| `FP` / `HAN` | switches to Applesoft / restarts the Hangul driver | the `HAN` banner (already Korean) | already done |
| `BSAVE` / `BLOAD` / `BRUN` | saves, loads or runs a binary file | nothing (errors only) | no |
| `VERIFY` | checks a file can be read | nothing (errors only) | no |

Result: most commands print nothing when they work. Two things are visible to the user: the **error messages** (14 of them, shared by all commands) and the **`CATALOG` list**. Everything worth localizing is in those two.


## 2. What DOS prints, and where

### 2.1 Error messages (14)

- The text is at `$A971-$AA3E` (202 letters) with an offset table at `$AA3F`. Each message ends with a letter that has its high bit set.
- One routine at `$A702` prints a message: `X` is the message number, it reads the offset, then sends each letter to `JSR $9FC5` (DOS's own output, which ends in the driver's output hook) until it reaches the letter with the high bit set. All 14 error messages and the CR / bell that start every error pass through it.
- The messages: LANGUAGE NOT AVAILABLE, RANGE ERROR, WRITE PROTECTED, END OF DATA, FILE NOT FOUND, VOLUME MISMATCH, I/O ERROR, DISK FULL, FILE LOCKED, SYNTAX ERROR, NO BUFFERS AVAILABLE, FILE TYPE MISMATCH, PROGRAM TOO LARGE, NOT DIRECT COMMAND.

### 2.2 The `CATALOG` list

- The header "DISK VOLUME " is stored backwards at `$B3A7` (after eight file type letters `T I A B S R A B` in the same table). The routine at `$ADB0` prints it with a loop of 11 bytes: `LDX #$0B / LDA $B3AF,X / JSR $FDED / DEX / BPL`.
- After it: the volume number (3 digits), then for each file the lock mark `*`, the type letter, the size in sectors (3 digits) and the 30-character name.
- The paging between screens (the `CATINIT` and `CATWAIT` patches in `DOS_PATCHES_en.md`) is already done.

### 2.3 Not DOS

The Applesoft messages (`?SYNTAX ERROR`, `?OUT OF MEMORY`, …) are in the Apple II ROM and belong to the K-BASIC project. They are not part of this analysis.


## 3. How a Korean message would be printed

The driver already shows Korean when it is sent the same keystroke text a user would type: `$8B` (Ctrl-K) starts a Hangul run, the jamo keys follow, `$81` (Ctrl-A) ends it. So a Korean message is just a different string sent through the same output hook. No change to the driver's drawing is needed.

The English text cannot simply be overwritten in place: the Korean version is longer (see 4.1).

**Plan:** replace the message routine with a short routine of ours.

1. DOS calls `$A702` to print message `X`. Patch the first 3 bytes of that routine to `JMP` to a routine in the language card.
2. The new routine prints the Korean message with the same `JSR $9FC5` loop.
3. If the Hangul driver is not the active output (after `PR#0`, or Ctrl-Reset), the new routine hands over to the original English routine, so a Korean string is never sent to a plain text screen.

The `CATALOG` header works the same way: replace the 11-byte loop at `$ADB0` with a call that prints `디스크 볼륨 ` (the same fallback applies).

The hook must not be lost when a program overwrites `$9400-$95FF` (kScheme does). The DOS patches already in use (`CATINIT`, `CATWAIT`) point into that block, and the rebuild entry `$D3FA` recreates them; a new hook has to be one of the things the rebuild entry recreates.


## 4. Cost

### 4.1 Size

Korean wording is a draft; the sizes were computed by encoding each message with `src\tools\nbyte.py`.

| item | English now | Korean as keystroke text |
|---|---|---|
| the 14 error messages | 202 bytes | 312 bytes |
| `CATALOG` header | 12 bytes | 18 bytes |
| offset table | 15 bytes | 14 bytes |
| new routines (message print, header print, fallback test) | – | about 60-80 bytes (estimate) |
| stub in main RAM / trampoline block to enter the card from DOS | – | 7-15 bytes (estimate) |

- Total in the card: about **410-430 bytes**. The plain 16 KB card has 717 bytes free at `$D133-$D3FF`; on this build `$D3D0-$D3FF` is taken by the shift masks and the rebuild entry, so about 669 bytes are free (`$D133-$D3CF`). It fits with about 240 bytes to spare. The Saturn bank has the same room at the same addresses. (The free count was not re-measured in the bank; it should be before building.)
- The stub: on the plain card, main RAM `$0800-$1FFF` has only 93 bytes free, enough for one stub. On a Saturn card the stub goes into the `$9400-$95FF` block, which has about 49 bytes free in fragments; one stub of 7-15 bytes fits.
- BASIC memory: **no change** (`HIMEM` stays `$9400`, 21,501 bytes free).
- The original English text stays in DOS, so the fallback needs no extra copy.

### 4.2 Work (estimate)

| step | effort |
|---|---|
| write and check the 14 Korean messages and the header (wording review by you) | small |
| the message routine, the header routine, the two DOS patches, the stub | about half a day |
| make the patches safe: check the DOS bytes first (as `CATINIT` does), keep the English path, add the hook to the rebuild entry | about half a day |
| MAME tests for each message (see below), plain and Saturn card | about half a day |

### 4.3 Risks

- A hook that sends Korean text while the driver is off would show garbage. The fallback test (is the output hook the driver's?) prevents it; it has to be tested with `PR#0` and with Ctrl-Reset.
- Korean text is wider than English on screen; error lines are short, so none should wrap, but each one needs a look in the 46-column screen.
- Each message must be reachable in a test: FILE NOT FOUND (`LOAD X`), SYNTAX ERROR, VOLUME MISMATCH (`CATALOG,V99`), RANGE ERROR, WRITE PROTECTED (write-protected disk image), NO BUFFERS AVAILABLE, NOT DIRECT COMMAND (`READ` at the prompt) are easy. DISK FULL, I/O ERROR, LANGUAGE NOT AVAILABLE, END OF DATA and PROGRAM TOO LARGE need set-up work.
- This disk has a DOS that pages at 22/21 lines, not stock 24/23 (`DOS_PATCHES_en.md`). Other DOS versions would need the opcode check before patching.


## 5. What not to do

- **Korean command names** (`목록` for `CATALOG`): the parser matches the letters in the table at `$A884` and a Korean word would need Hangul mode to be switched on before every command. It would need a new parser path and a second name table (more than 100 bytes), for little gain. Not recommended.
- **Korean file names**: tested once in MAME: `SAVE` followed by Ctrl-K and Hangul keys gave `?SYNTAX ERROR` (the control code `$8B` is not accepted in a name). Making DOS accept them would mean changing its name parser and the catalog's 30-byte name format. Not recommended.
- **`MON` / `NOMON`**, `FP`, `INIT` and the other silent commands: nothing to translate.
- Changing the type letters (`T I A B S R`) of `CATALOG` to Korean letters: possible with the same loop patch, but the letters are a column of single characters that people know; the gain is small.


## 6. Recommendation

1. **Error messages (14)** and the **`CATALOG` header**: do these. They are the only things DOS shows that a user reads, the cost is about 420 bytes of card space that is free today, and no BASIC memory.
2. Do it on both cards together, with the English fallback, and add it to the rebuild entry.
3. Skip everything in section 5.

Before building: review the Korean wording; re-measure the free space in the Saturn bank; decide with the K-BASIC session whether its add-on (which has its own messages) needs to know about the hook.
