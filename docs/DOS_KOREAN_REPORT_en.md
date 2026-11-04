# Korean DOS 3.3: messages, command names and file names

> 한국어: [DOS_KOREAN_REPORT.md](DOS_KOREAN_REPORT.md)

This report is for your review. It asks what in DOS 3.3 is worth showing or accepting in Korean, what each piece costs in memory and work, and what cannot be done. **Nothing here is built into the driver or DOS.** Three things were tried in MAME (section 5.3): Korean file names, `RUN` and `BRUN` with them, and the comma problem. Everything else is read from the DOS dump or estimated, and says "estimate".

How the facts were found: the DOS on `disk\K-HANGEUL.DSK` was booted in MAME and its memory (`$9600-$BFFF`) was dumped and disassembled with `da65`. Addresses are for that DOS (patched by this project as in `DOS_PATCHES_en.md`). Message sizes were computed with `src\tools\nbyte.py`.

This report replaces `DOS_ANALYSIS`, the first version of `DOS_KOREAN_REPORT` and `DOS_KOREAN_FILENAME_ANALYSIS`.


## 1. Summary

| what | possible? | cost | my advice |
|---|---|---|---|
| **14 error messages + `CATALOG` header in Korean** | yes | about 380-410 bytes of card space, about 1.5 days | **do it first** |
| **Hangul inside file names** (name starts with an English letter) | **works today** | nothing (one paragraph in the manual) | document it |
| Hangul file names that **start** with Hangul | yes, with one small DOS patch | about 20-30 bytes, about half a day | do it together with the messages |
| **Korean command names** (`목록` for `CATALOG`) | probably yes, one open question | about 160-240 bytes, 1-2 days | check first (half a day), then decide |

Free card space is **669 bytes** (`$D133-$D3CF`; the Saturn bank was not re-measured). The messages alone take more than half of it. All of the above together are 560-680 bytes: at the top of the range it does not fit. You need to choose.

BASIC memory is not touched by any of these (`HIMEM` stays `$9400`, 21,501 bytes free).


## 2. All DOS commands

DOS 3.3 has 28 commands. The names are in a table at `$A884`. On this disk `INT` is replaced by `HAN` (see `DOS_PATCHES_en.md`).

| command | what it does | prints anything? | worth localizing? |
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
| `MON` / `NOMON` | shows or hides a trace of disk I/O | trace lines only while `MON` is on | no (rarely used) |
| `PR#` / `IN#` | selects the output or input slot | nothing | no |
| `MAXFILES` | sets the number of file buffers | nothing | no (it also breaks `HIMEM`, see `DOS_PATCHES_en.md`) |
| `FP` / `HAN` | switches to Applesoft / restarts the Hangul driver | the `HAN` banner (already Korean) | already done |
| `BSAVE` / `BLOAD` / `BRUN` | saves, loads or runs a binary file | nothing (errors only) | no |
| `VERIFY` | checks a file can be read | nothing (errors only) | no |

Most commands print nothing when they work. What a user reads is the **error messages** (14, shared by all commands) and the **`CATALOG` list**. There is no cost per command: localizing the messages covers every command at once.


## 3. What DOS prints, and where

### 3.1 Error messages (14)

- The text is at `$A971-$AA3E` (202 letters) with an offset table at `$AA3F`. Each message ends with a letter that has its high bit set.
- One routine at `$A702` prints a message: `X` is the message number; it reads the offset, then sends each letter to `JSR $9FC5` (DOS's own output, which ends in the driver's output hook) until it reaches the letter with the high bit set. All 14 messages, and the CR / bell that start every error, pass through it.

### 3.2 The `CATALOG` list

- The header "DISK VOLUME " is stored backwards at `$B3A7` (after eight file type letters `T I A B S R A B` in the same table). The routine at `$ADB0` prints it with an 11-byte loop: `LDX #$0B / LDA $B3AF,X / JSR $FDED / DEX / BPL`.
- After it: the volume number (3 digits), then for each file the lock mark `*`, the type letter, the size in sectors (3 digits), and the 30 characters of the name.
- The paging between screens (the `CATINIT` and `CATWAIT` patches in `DOS_PATCHES_en.md`) is already done.

### 3.3 Not DOS

The Applesoft messages (`?SYNTAX ERROR`, `?OUT OF MEMORY`, ...) are in the Apple II ROM and belong to the K-BASIC project.


## 4. Korean error messages and the `CATALOG` header

### 4.1 How a Korean message is printed

The driver already shows Korean when it is sent the same keystroke text a user would type: Ctrl-K (`$8B`) starts a Hangul run, the jamo keys follow, Ctrl-A (`$81`) ends it. A Korean message is just a different string sent through the same output hook. No change to the driver's drawing is needed. The English text cannot be overwritten in place, because the Korean version is longer.

Plan:
1. DOS calls `$A702` to print message `X`. Patch its first 3 bytes to `JMP` to a routine in the language card.
2. The routine prints the Korean message with the same `JSR $9FC5` loop.
3. If the Hangul driver is not the active output (after `PR#0`, or Ctrl-Reset), the routine hands over to the original English routine, so a Korean string is never sent to a plain text screen.

The `CATALOG` header works the same way: replace the 11-byte loop at `$ADB0` with a call that prints `디스크 볼륨 ` (same fallback).

The hook must not be lost when a program overwrites `$9400-$95FF` (kScheme does). The existing DOS patches (`CATINIT`, `CATWAIT`) point into that block and the rebuild entry `$D3FA` recreates them; a new hook must be recreated there too.

### 4.2 Proposed wording

Please mark what you want changed.

| # | English now | Proposed Korean | bytes | other wording |
|---|---|---|---|---|
| 1 | LANGUAGE NOT AVAILABLE | 언어를 쓸 수 없음 | 31 | 언어 없음 |
| 2 | RANGE ERROR | 범위 오류 | 15 | |
| 3 | WRITE PROTECTED | 쓰기 금지됨 | 18 | 쓰기 보호됨 |
| 4 | END OF DATA | 데이터 끝 | 14 | 자료 끝 |
| 5 | FILE NOT FOUND | 파일 없음 | 17 | 파일을 찾을 수 없음 |
| 6 | VOLUME MISMATCH | 볼륨 번호 다름 | 24 | 볼륨 불일치 |
| 7 | I/O ERROR | 입출력 오류 | 18 | |
| 8 | DISK FULL | 디스크 가득 참 | 22 | 디스크 꽉 참 |
| 9 | FILE LOCKED | 파일 잠김 | 16 | |
| 10 | SYNTAX ERROR | 문법 오류 | 15 | 구문 오류 |
| 11 | NO BUFFERS AVAILABLE | 버퍼 부족 | 14 | |
| 12 | FILE TYPE MISMATCH | 파일 종류 다름 | 23 | 파일 형식 불일치 |
| 13 | PROGRAM TOO LARGE | 프로그램이 너무 큼 | 26 | |
| 14 | NOT DIRECT COMMAND | 직접 명령 아님 | 25 | |
| – | `DISK VOLUME ` (header) | 볼륨 ("디스크" dropped for lack of room, see 9) | 9 | |

Questions: (a) "오류" or "에러"; (b) "볼륨" or "디스크 번호"; (c) I left out polite endings (…합니다) because they cost bytes. Is that OK?

### 4.3 Cost

| item | English now | Korean |
|---|---|---|
| the 14 messages | 202 bytes | 278 bytes |
| `CATALOG` header | 12 bytes | 18 bytes |
| offset table | 15 bytes | 14 bytes |
| new routines (message print, header print, fallback test) | – | about 60-80 bytes (estimate) |
| stub to enter the card from DOS | – | 7-15 bytes (estimate) |
| **total in the card** | | **about 380-410 bytes** |

- **The stub.** On the plain card, main RAM `$0800-$1FFF` has only 93 bytes free, enough for one stub. On a Saturn card the stub goes into the `$9400-$95FF` block, which has about 49 bytes free in fragments; one stub of 7-15 bytes fits.
- **Free space.** The plain 16 KB card has 717 bytes free at `$D133-$D3FF`; `$D3D0-$D3FF` holds the shift masks and the rebuild entry, so **669 bytes** are free. The Saturn bank has the same room at the same addresses but was not re-measured. Measure it before building.
- **The English text** stays in DOS, so the fallback needs no extra copy.

Work (estimate): about 1.5 days.

| step | effort |
|---|---|
| wording review (you) and writing the strings | small |
| message routine, header routine, the two DOS patches, the stub | about half a day |
| make the patches safe: check the DOS bytes first (as `CATINIT` does), keep the English path, add the hook to the rebuild entry | about half a day |
| MAME tests for each message, plain and Saturn card | about half a day |

### 4.4 Risks

- When the Korean driver is off, no Korean works, and plain English messages are fine. The case to guard is this: the driver was loaded, so the DOS patch is installed, and then output is switched away from the driver (`PR#0`, Ctrl-Reset). The patch is still in DOS and would send Hangul codes to the plain text screen, which shows garbage. The fallback test (is the output hook the driver's?) sends the English message instead; test it with `PR#0` and with Ctrl-Reset. If the driver was never loaded, the patch is not installed and DOS prints English as before. English commands work in every case.
- Korean is wider than English; error lines are short and should not wrap on the 46-column screen, but each needs a look.
- Each message must be reachable in a test. Easy: FILE NOT FOUND (`LOAD X`), SYNTAX ERROR, VOLUME MISMATCH (`CATALOG,V99`), RANGE ERROR, WRITE PROTECTED (write-protected image), NO BUFFERS AVAILABLE, NOT DIRECT COMMAND (`READ` at the prompt). Needs set-up: DISK FULL, I/O ERROR, LANGUAGE NOT AVAILABLE, END OF DATA, PROGRAM TOO LARGE.
- This disk has a DOS that pages at 22/21 lines, not stock 24/23 (`DOS_PATCHES_en.md`). Other DOS versions need the opcode check before patching.
- The K-BASIC add-on has its own messages; ask that session whether it needs to know about the hook.


## 5. Korean file names

**Short answer: a name made only of Hangul is not possible today, but it is possible with one small DOS patch (about 20-30 bytes, section 5.2).** DOS refuses a name whose first character is not a letter. Today a name must start with an English letter (`A한` works). With the patch, a full Hangul name such as `한글` works, with the limits in 5.5: about 7-9 syllables, Ctrl-K ... Ctrl-A typed around the Hangul, and the comma problem in 5.4.

### 5.1 How DOS reads a file name

DOS copies the typed name into a 30-byte area padded with spaces (`$A0`). The loop is at `$A043-$A061`:

1. `$A043`: read the first character of the name (`JSR $A1A4`, skips spaces). If the name is empty, stop.
2. `$A048`: `ASL A; BCC $A050; BMI $A050; JMP $A000`. **The first character must be `$C0-$FF`**, a letter with the high bit set. Anything else (digit, punctuation, a control code such as Ctrl-K `$8B`) goes to `$A000`, which reports `?SYNTAX ERROR`. This is DOS's rule that a name must begin with a letter.
3. `$A054-$A061`: **every other character is copied without any check**, up to the comma or end of line. A name longer than 30 bytes gives a syntax error (`$A078`, `$A092`).

The driver puts Ctrl-K (`$8B`), jamo keys (high bit set, like English capitals) and Ctrl-A (`$81`) into the typed line. The tense-consonant keys are `- = * < > ; +`; none is a comma, so a Hangul run never ends a name early. The only obstacle is the first-character check. The name is stored as is in the catalog.

`CATALOG` prints the 30 name bytes one by one with `JSR $FDED` (the output hook) at `$AE18`. Nothing filters them, so Ctrl-K, jamo and Ctrl-A reach the driver and show as Hangul. `CATALOG` needs no change.

### 5.2 What it takes

**Names that begin with an English letter: works now, no change.** The user types the first letter in English mode, then switches: `SAVE A`, Ctrl-K, Hangul keys, Ctrl-A. Only a manual paragraph is needed.

**Names that begin with Hangul.** Replace the `JMP $A000` at `$A04D` with a `JMP` into a card routine. After the `ASL A`, Ctrl-K is `$16`: the routine does `CMP #$16`, `BEQ $A050`, otherwise `JMP $A000`.

| item | bytes (estimate) |
|---|---|
| routine in the card | 8-12 |
| stub (same kind as `CATINIT`) | 7-15 (can share the stub with the messages if the same entry is used) |
| rebuild entry | a few |
| **total** | **about 20-30** |

Work: about half a day including tests (check the original DOS bytes first; recreate the patch in the rebuild entry). The alternative of removing the first-character check costs no card space, but then DOS also accepts names that begin with a digit or punctuation, and a typing mistake at the start of a name is saved. Not recommended.

### 5.3 MAME tests

DOS booted from a copy of `disk\K-HANGEUL.DSK` (plain 16 KB card), commands typed through the keyboard with Ctrl-K and Ctrl-A, screen read from the hi-res page, disk read with `acx`.

| test | result |
|---|---|
| `SAVE A` Ctrl-K `GKS` Ctrl-A (name `A한`) | saved; catalog entry is `A`, `$8B`, `GKS` |
| the same with `B각`, `R한`, `C한` | saved |
| `SAVE` Ctrl-K `SKR` Ctrl-A (starts with Hangul) | `?SYNTAX ERROR`, nothing saved |
| `NEW`, then `LOAD A한` | program came back (end of program `$0440` to `$0940`) |
| `DELETE A한` | file gone from the catalog |
| `CATALOG` | lines `A 002 A한` and `B 002 B각`; the Hangul is drawn correctly |
| `RUN R한` (program `10 POKE 785,77`) | ran: `PEEK(785)` went from 0 to 77 |
| `BSAVE B,A768,L4`, `RENAME B,C한`, then `BRUN C한` (machine code that adds 1 to `$0310`) | loaded into `$0300` and ran: `$0310` went from 0 to 1 |
| `BSAVE B한,A768,L4` (comma after a Hangul name) | **`?SYNTAX ERROR`**, see 5.4 |
| name typed with Ctrl-A left out | saved and loaded, but **the driver stays in Hangul mode**: the next line you type comes out as Hangul and gives `?SYNTAX ERROR` until you press Ctrl-A |

Not verified: `LOCK` / `UNLOCK` and `RENAME` with a Hangul first name (the same comma problem hit my test lines); the text-file commands (`OPEN`, `READ`, `WRITE`) and `BLOAD`; what `CATALOG` looks like for a name saved without its Ctrl-A (the driver may keep its Hangul run open into the next columns); the Saturn card and IIe and later machines.

### 5.4 The comma problem (fixed, see 9.7)

The driver's line editor does **not** write the closing Ctrl-A (`$81`) into the line right away. It writes it just before the next **letter**, or at Return (code at `CLOSERUN` and `L_E70C` in `driver.s`). A comma, a space or a digit does not trigger it. So `BSAVE B` Ctrl-K `GKS` Ctrl-A `,A768,L4` ends up in the line as `B`, `$8B`, `GKS`, `,`, `$81`, `A768,L4`. DOS ends the name at the comma and then reads the stray `$81` at the start of the option field: syntax error. The same happens with any command that has something after a Hangul name on the line.

Ways around it today: put the Hangul name **last** on the line, or save with an English name and `RENAME old,new` (the Hangul new name is last). That is what the `BRUN` test above did.

A real fix would be a small change in the line editor so that a comma (and maybe space) also writes the closing Ctrl-A. That is a driver change; I have not touched the driver. The same issue would hit Korean command aliases (section 6): `목록,D2` would arrive as `$8B`, jamo, `,`, `$81`, `D2`, and the alias routine would have to cope with it.

### 5.5 Limits and risks

- **Length.** A syllable takes 2-4 key codes (`한` = `GKS`, 3 bytes; double final consonants take 4); Ctrl-K and Ctrl-A take 2 more. With the 30-byte limit a name holds about **7-9 syllables**, fewer when mixed with English.
- **Other computers and tools.** The disk holds keystroke codes, not a standard Hangul encoding. On a stock Apple II, `CATALOG` prints a control code and letters; `acx` shows `A<Ctrl-K>GKS`. The files still work, but the names look like noise outside this driver. Keep English names for disks given to others.
- **Ctrl-A is needed**, as in the table in 5.3.
- **Match is by bytes.** The driver's composition rules give one key sequence per syllable, so I expect the same word to match every time, but this was not tested with different typing orders.
- **Programs.** `PRINT CHR$(4);"LOAD A..."` inside a program needs the Hangul codes put into the string (`CHR$(11)` and so on). That is for the program's author.
- **Sorting.** DOS does not sort the catalog, so there is no problem.


## 6. Korean command names

`목록` instead of `CATALOG`, `저장 NAME` instead of `SAVE NAME`.

All 28 commands, one per line, with a Korean suggestion. "Alias?" is my advice: **yes** = typed at the prompt often, worth an alias; **maybe** = mostly used inside programs, cheap to add later (6-12 bytes each); **no** = leave in English. The names are drafts for your review. **Decision of 2026-11-02: `PR#`, `IN#` and `FP` are AS IS (left unchanged), and all the other 25 get a Korean name.** So the "no" in the "alias?" column was my advice, and all 25 will be done (changed to "yes (decided)" in the table). The last column is for the answer of the K-BASIC session (asked, see the note below the table).

| # | English | suggested Korean | what it does | alias? | covered by K-BASIC? |
|---|---|---|---|---|---|
| 1 | INIT | 포맷 | formats a disk | yes | no |
| 2 | LOAD | 불러오기 | loads a BASIC program | yes | no |
| 3 | SAVE | 저장 | saves a BASIC program | yes | no |
| 4 | RUN | 실행 | loads and runs a program | yes | yes, as the Applesoft keyword: 실행 (same word) |
| 5 | CHAIN | 연결 | runs a program, keeps the variables | maybe | no |
| 6 | DELETE | 지우기 | removes a file | yes | no |
| 7 | LOCK | 잠금 | protects a file | yes | no |
| 8 | UNLOCK | 풀기 | frees a protected file | yes | no |
| 9 | RENAME | 이름바꿈 | renames a file | yes | no |
| 10 | OPEN | 열기 | opens a text file | maybe | no |
| 11 | CLOSE | 닫기 | closes a text file | maybe | no |
| 12 | READ | 읽기 | reads from a text file | maybe | yes, as the Applesoft keyword: 읽기 (same word) |
| 13 | WRITE | 쓰기 | writes to a text file | maybe | no |
| 14 | APPEND | 이어쓰기 | adds to the end of a text file | maybe | no |
| 15 | POSITION | 자리 | moves inside a text file | maybe | no |
| 16 | EXEC | 일괄 | runs a text file as typed commands | maybe | no |
| 17 | CATALOG | 목록 | lists the files | yes | no |
| 18 | MON | 감시 | shows disk I/O trace | yes (decided) | no |
| 19 | NOMON | 감시끝 | hides it | yes (decided) | no |
| 20 | PR# | **AS IS** (stays English, not changed) | selects the output slot | no | no |
| 21 | IN# | **AS IS** (stays English, not changed) | selects the input slot | no | no |
| 22 | MAXFILES | 최대파일 | sets the number of file buffers | yes (decided) | no |
| 23 | FP | **AS IS** (stays English, not changed) | switches to Applesoft | no | no |
| 24 | HAN | 한글 | restarts the Hangul driver (replaces `INT`) | yes (decided) | no |
| 25 | BSAVE | 이진저장 | saves a binary file | maybe | no |
| 26 | BLOAD | 이진불러오기 | loads a binary file | maybe | no |
| 27 | BRUN | 이진가동 | loads and runs a binary file | maybe | no |
| 28 | VERIFY | 검사 | checks that a file can be read | yes (decided) | no |

Notes on the names: `읽기` is used for READ so LOAD gets `불러오기`. Names that start with `이어`, like `이어쓰기` (APPEND), are fine. So that no K-BASIC word sits inside a name, CHAIN is `연결`, EXEC is `일괄`, BRUN is `이진가동` and BLOAD is `이진불러오기` (see the check below). `PR#` and `IN#` contain `#`, which is awkward to type after a Hangul word, so they stay English.

**K-BASIC answer (asked, read from its source):** no DOS command has a Korean name in K-BASIC; all stay English (its docs say "Korean DOS commands: not done"). The only overlap is with Applesoft keywords: **`실행` = RUN and `읽기` = READ** are already K-BASIC words. K-BASIC rewrites the typed line (in its `KB_IN` hook, called from the driver's line input) before Applesoft tokenizes, so with K-BASIC loaded `실행 이름` becomes `RUN 이름` before DOS or Applesoft see it (I have not tested this with DOS). Text inside double quotes is copied as is, so `PRINT CHR$(4);"..."` is never touched. `PR#` and `IN#` are Applesoft tokens K-BASIC leaves alone. So these two words in the table must stay exactly `실행` and `읽기`.


**Check against K-BASIC words:** I compared the suggested Korean names with K-BASIC's `keywords.tsv` (98 lines), and the K-BASIC session re-checked them against its own source (`kbasic.s`).

- **How K-BASIC matches:** not whole words. It scans the line key by key and tests its table at every position inside a Hangul run (no word-boundary check). It takes the first match in table order, not the longest. So a name that contains a K-BASIC word is rewritten in part (text inside double quotes, REM and DATA is left alone).
- **Clashes in my first draft, changed (3):** INIT `초기화` (CLEAR) is now `포맷`; DELETE keeps only `지우기` (`삭제` is DEL); POSITION `위치` (POS) is now `자리`.
- **Found by the K-BASIC session (4):** names that contain a K-BASIC word: `이어실행` becomes `이어RUN`, `일괄실행` becomes `일괄RUN`, `이진실행` becomes `이진RUN` (all contain `실행` = RUN), `이진읽기` becomes `이진READ` (contains `읽기` = READ). So CHAIN is now `연결`, EXEC `일괄`, BRUN `이진가동`, BLOAD `이진불러오기`. I compared these four with the K-BASIC list, but the K-BASIC session has not re-tested them.
- **Words left in common:** only `실행` (RUN) and `읽기` (READ), the same command in both, so no problem. `저장` is not a start of K-BASIC's `테이프저장` (STORE).
- **Safety net:** if the driver replaces the first word of the line with the English command first, K-BASIC's scan never sees it. That fits the decision to keep aliases in the driver. Where one name is the start of another (`감시` / `감시끝`), the longer one must be matched first.

### 6.1 Why it is harder than the messages

- **The parser compares letters.** DOS looks the word up in the table at `$A884`. A Korean word typed in Hangul mode arrives as `$8B`, jamo keys, `$81`, so the table never matches (`?SYNTAX ERROR`). The user also has to turn Hangul mode on before the command word and off again for the file name (Ctrl-K ... Ctrl-A), about the same number of key presses as the English word.
- **Method: alias before DOS sees the line.** When the line is finished (Return), the driver looks at its first word; if it is a known Korean alias, it replaces it with the English command in the line buffer. DOS and Applesoft work unchanged. This needs a table of 10-14 aliases (6-12 bytes each) and a compare routine. (A second name table inside DOS's parser would be bigger and riskier. Not recommended.)
- **Checked in MAME:** DOS reads both typed lines and program lines from the `$0200` buffer (a program line starts with Ctrl-D), and an unknown word goes to `$A000`. So replacing at `$A000` is simpler than in the line input. Test results are in 6.4.
- **The comma problem (5.4)** applies: the alias routine has to cope with `$81` arriving after a comma or space, or the line editor has to be changed.
- **Inside programs** (`PRINT CHR$(4);"CATALOG"`) the strings are English, written by the program author. Replacing in the output path would cover them too, but that is a separate, larger decision.

### 6.2 Cost (estimate)

| item | bytes |
|---|---|
| alias table, 10 commands | 80-120 |
| compare and replace routine | 70-100 |
| stub / hook in the trampoline block | 7-15 |
| rebuild-entry change | a few |
| **total** | **about 160-240** |

Each extra alias later costs about 6-12 bytes. Effort: 1-2 days, because of the open question and the number of cases to test (alias at line start only; `목록,D2`; letter case; mixing English and Korean; driver switched off).

### 6.3 Who should do the aliases: the card or K-BASIC?

K-BASIC already rewrites the typed line before DOS sees it, so the same mechanism could carry the Korean DOS words instead of the card. The K-BASIC session agrees it is possible but says it would be a separate table (not `keywords.tsv`, which is for Applesoft keywords) and a separate piece of code, and that its module has about 1 spare byte below `$9400`.

| | in the driver card (6.2) | in K-BASIC |
|---|---|---|
| memory used | card space, 160-240 bytes, of only 669 free | BASIC memory (`HIMEM` goes down by the same kind of amount, out of 21,501 free) |
| works without K-BASIC | yes | no (K-BASIC users only) |
| quotes, comments | has to be written | already handled (text in quotes is left alone) |
| the comma problem (5.4) | has to be handled | has to be checked in its line rewrite |
| two projects | one | the DOS word list lives in K-BASIC; this report only proposes the words |

**Decision (2026-11-02, user): the driver does both the Korean commands and the messages. K-BASIC does not.** The K-BASIC session was told to stop its analysis. Reasons: it works without K-BASIC, and everything about DOS stays in one project. The price is free card space (size table in section 8). The comparison table above stays for reference.

### 6.4 Korean DOS commands inside BASIC programs (requirements, analysis, test results)

**Goal:** a program line such as `PRINT CHR$(4);"저장 NAME"` with a Korean command inside the quotes is understood by DOS, with or without K-BASIC loaded.

**What the `$A000` hook is, and what it is for.** DOS collects one line (typed, or text a program prints after `CHR$(4)`) in the `$0200` buffer, then compares its first word with the 28 command names in the table at `$A884`. If none matches, it goes to `$A000`. There DOS (1) hands a typed line to Applesoft, or (2) for a program line (one that starts with Ctrl-D) gives `SYNTAX ERROR`. So `$A000` is **the exit where "a word DOS does not know" arrives.** Our code placed there checks whether the word is a Korean alias. If it is, it replaces the Korean word in the buffer with the English command and puts the line back into DOS's parser (`$9FCD`). DOS processes it as if it were typed in English.

Why this is good: (a) it runs only when DOS would have failed anyway, so English commands see no change and no slowdown; (b) typed lines and program lines both pass through the same `$0200` buffer, so one hook covers both; (c) neither the line editor nor K-BASIC has to change.

**Why the line-input method (6.1) does not work for programs.** Replacing aliases in the line input applies only to lines the user types. Text a program sends with `PRINT` does not pass through the line input; it goes into DOS's output intercept. K-BASIC cannot do it either, for the same reason (see "Could K-BASIC be changed to do it?" below).

**What "K-BASIC leaves quoted text alone" means:** K-BASIC turns Korean BASIC words (such as `출력`) into the real words (`PRINT`) in a typed line. Text between double quotes is data, not a command, so it is left as typed. In `PRINT CHR$(4);"저장 NAME"`, `PRINT` and `CHR$(4)` are code and would be converted, but `저장 NAME` is inside the quotes and goes to DOS unchanged. So K-BASIC cannot damage a Korean command word in a program, but it also does not turn `저장` into `SAVE`.

#### Test results (MAME, a sample routine loaded into RAM; nothing in the repository was changed)

I patched a `JMP` into `$A000` and loaded a test hook of about 210 bytes into RAM (with only two aliases, `목록` = CATALOG and `저장` = SAVE). The test ran on the K-HANGEUL v1.1b disk (Apple II+, plain 16 KB card, no K-BASIC).

| # | Input | Result |
|---|---|---|
| 0 | typing `목록` without the hook | `?SYNTAX ERROR` (baseline) |
| 1 | typed `목록` | the catalog is listed ✓ |
| 2 | typed `저장 T1` | file `T1` appears on the disk ✓ (checked with the disk listing) |
| 3 | typed `저장 T2,D1` (comma in English arguments) | `T2` appears ✓ |
| 4 | `목록` with Return pressed but no Ctrl-A to end Hangul mode | the catalog is listed ✓ (the line editor closes it at Return) |
| 5 | program `10 PRINT CHR$(4);"목록"`, then `RUN` | the catalog is listed ✓ |
| 6 | program `PRINT CHR$(4);"저장 T1"`, then `RUN` | file `T1` appears ✓ |
| 7 | program `PRINT CHR$(4);"CATALOG"` (English, hook present) | the catalog is listed ✓ (English unchanged) |
| 8 | program line `10 PRINT CHR$(4);"목록"` typed with no Ctrl-A before the closing quote, then `RUN` | the catalog is listed ✓ (the line editor closes it at Return). But Hangul mode stays on after that line, so the next `RUN` I typed came out as jamo (see 3 below) |

What the tests showed (to be respected by the real code):

1. **A program line starts with Ctrl-D (`$84`) and the command text begins at `$0201`** (a typed line begins at `$0200`). The hook must decide the start by checking whether `$0200` is Ctrl-D. DOS's `$AA5D` is not the start; it is the read position and cannot be used (my first attempt was wrong).
2. **The line editor puts the closing Ctrl-A (`$81`) after the space.** `저장 T1` arrives as `...word keys A0 81 T1`, so the `$81` stays in front of the file name and DOS rejects the name (same cause as the comma problem in 5.4). The hook must delete the first `$81` after the alias (before any Hangul run starts). With that added, tests 2 and 3 passed.
3. **There is no need to press Ctrl-A before the closing quote.** The line editor closes the `$81` at Return (tests 4 and 8; I first wrote this up as a failure, but what looked like a failure was Hangul mode staying on after that line, so the `RUN` I typed next came out as jamo `ㄱㅜㅕ`). That is existing behavior, unrelated to the hook: after typing a line with Hangul inside quotes, press Ctrl-A to turn Hangul mode off before typing the next line. This was tested without K-BASIC.
4. **Where the test code sat:** I first put the test code at `$0360`; at 176 bytes it overwrote `$03D0-$03FF` (DOS's reconnect entry and vectors) and every program broke, even English commands. The real code must not touch that area; it goes on the card.
5. English program commands (`"CATALOG"`) and English typed lines still work with the hook present (test 7).

Not tested: with K-BASIC loaded (K-BASIC is not in this repository; what its session checked in its source is in 8.2a), the Saturn card, the Apple IIe, other DOS commands (`OPEN`, `READ`, `WRITE`, `APPEND`, `EXEC`, `BLOAD` and so on), and a Hangul file name after an alias. They all go through the same parser, so I expect the first-word replacement to work for them, but that is not confirmed.

#### Size (measured on the test code)

The test code was about 176 bytes (generic, not tuned) plus 17 bytes per alias (fixed size). Tuned, I expect 110-130 bytes of code and about 12 bytes per alias with variable-length entries (an estimate). For 9 aliases that is about 220-240 bytes, the upper end of the 160-240 in 6.2. Together with the messages (380-410) that is 600-650 bytes, which just fits the free space of the plain card (about 670-685 bytes). **The `$D000` image of the Saturn build has only 186 contiguous free bytes (7.4).** That is a real problem.

#### Could K-BASIC be changed to do it?

Yes, but only in a limited form. When K-BASIC meets a quote in a typed line it copies the contents unchanged (the `@out` / `QUOTE` handling in `kbasic.s`). A rule could be added: "if the quote follows `CHR$(4);` and the first word inside is a Korean alias, store the English word instead". The program would then hold English `SAVE`, so it would also run on machines without the driver (an advantage). The limits:

- It applies **only to typed lines.** It misses programs loaded from disk, text built at run time such as `D$ = "저장 " + N$`, and the common way of keeping `CHR$(4)` in `D$` and writing `PRINT D$;"..."` (the "right after `CHR$(4)`" condition fails).
- **`LIST` shows English**, because the stored text is English.
- It is a **change to the K-BASIC project**, and its module has only about 1 spare byte below `$9400`, so `HIMEM` would have to go down.
- It works only for people who use K-BASIC.

The `$A000` hook, in contrast, sees the text DOS receives at run time, so it has none of these limits. So for Korean commands inside programs the driver's `$A000` hook is the right place, and K-BASIC could at most serve as a typing-time translation helper.

**Is one hook enough?** As tests 1-4 show, the `$A000` hook also catches typed lines, so a separate line-input hook looks unnecessary (saves card space). K-BASIC scans a typed line first, but after the renames in section 6 no alias word contains a K-BASIC word. This combination (hook + K-BASIC) has not been tested. **Your decision is item 5 in 8.3.**

## 7. What is not possible, limits, and what not to do

### 7.1 Not possible, whatever we do

- **Korean commands or Korean messages on a machine without the driver.** DOS knows only English. A program with Korean commands stops with `?SYNTAX ERROR` without the driver. Korean messages come out in English without the driver (accepted).
- **Korean commands inside programs with K-BASIC alone.** K-BASIC leaves quoted text alone and only rewrites typed lines. It cannot reach text built while the program runs or a program loaded from disk (6.4).
- **Korean names for `PR#`, `IN#` and `FP`.** They stay English (`#` is awkward to type after a Hangul word, and `FP` is a silent command).
- **Code beyond the card's free space.** Messages plus all 28 aliases plus Hangul-first names may not fit in the ~670 free bytes (8.2). The `./name` command was dropped by the user's decision.

### 7.2 Limits, or needs a workaround

- **A comma after a Hangul file name.** `BSAVE B한,A768,L4` gives `?SYNTAX ERROR`. Put the Hangul name last on the line, or save with an English name and then use `RENAME` (5.4). Fixing the line editor solves it (a driver change, needs the user's permission).
- **Hangul name length.** DOS allows 30 bytes, so 7-9 syllables (5.5).
- **File names that contain a K-BASIC word.** K-BASIC rewrites the keys of a word in a typed line, so `LOAD 읽기파일` becomes `LOAD READ...` (8.2a). Avoid such names.
- **Hangul mode stays on after a line with Hangul in it.** If a line with Hangul inside quotes is typed without Ctrl-A, the line is stored correctly but Hangul mode stays on, so English typed next (such as `RUN`) comes out as jamo. Turn it off with Ctrl-A first (6.4, item 3). This already happens today and has nothing to do with this change.
- **Hangul names saved without Ctrl-A.** Noise shows on plain DOS (5.5).

### 7.3 What not to do

- A second command-name table inside DOS's parser (6.1).
- `MON` / `NOMON`, `FP`, `INIT` and other silent commands: nothing to translate.
- Changing the type letters (`T I A B S R`) of `CATALOG` to Korean letters: possible with the same loop patch, but they are single letters people know; little gain.
- Letting test code straddle `$03D0-$03FF` (DOS vectors) (6.4, item 4).

### 7.4 The "not yet checked" items, now checked

| item | result |
|---|---|
| the `$A000` hook | works for typed lines and program lines in the test (table in 6.4) |
| whether `SATREINIT` removes K-BASIC's CHRGET patch | the driver source has no code that writes `$C5-$C7` or `$0350`. The driver only calls CHRGET (`$B1`, `$B7`). So by the source, the rebuild entry has no reason to remove K-BASIC's patch. (Checked in the source; I did not run it with K-BASIC loaded.) |
| free space on the Saturn card | the `$D000` image of the Saturn build has only 186 contiguous free bytes, starting at `$D316` (the plain build has 685 bytes from `$D153`). Besides the 186 bytes in bank 7, the `$D000` first page (4 KB) of the cache bank (bank 6) is unused and can hold data tables (8.2). |
| Apple IIe | not tested. DOS 3.3's parser is the same, so I expect the DOS-side hook to be the same, but whether the driver runs on a IIe is a separate matter outside this report. |
| text-file commands (`OPEN`, `READ`, `WRITE`, `APPEND`, `EXEC`) and `BLOAD` | not tested. They go through the same parser and the same hook, so I expect the first-word replacement to work. In a program the text goes to DOS one line at a time (`D$;"OPEN NAME"`), so the Ctrl-A rule in 6.4 applies as is. |
| the hook with K-BASIC loaded | not tested (K-BASIC is not in this repository). What the K-BASIC session checked in its source is in 8.2a. |


## 8. Decisions made and decisions for you

### 8.1 Decided so far

| # | Decision | Reason |
|---|---|---|
| 1 | The error messages and the `CATALOG` header are done by the **driver** | DOS prints them from `$A702` through normal output (COUT). K-BASIC's output hook is for LIST only; the output hook that draws Hangul and the "English if output was switched away" fallback are in the driver. |
| 2 | The Korean command names (aliases) are also done by the **driver**, not K-BASIC (user decision, 2026-11-02) | Works without K-BASIC, and everything about DOS stays in one place. The K-BASIC session was told to stop. |
| 3 | 7 names were changed so none clashes with a K-BASIC word | `초기화`→`포맷`, `삭제` dropped, `위치`→`자리`, `이어실행`→`연결`, `일괄실행`→`일괄`, `이진실행`→`이진가동`, `이진읽기`→`이진불러오기` (see the check in section 6). The exceptions are `실행` (RUN) and `읽기` (READ), the same command in both. |
| 4 | An alias looks only at the **first word** of the line. Where one name is the start of another (`감시` / `감시끝`), the longer is matched first | The method confirmed by the tests in 6.4. |
| 5 | The `./name` run command is not done (user decision, 2026-11-02) | Not enough card space. |
| 6 | Hangul in file names that start with an English letter works today, so document it | MAME tests in section 5. |
| 7 | The hook is **one hook at DOS's `$A000`** (user decision, 2026-11-02) | In the tests in 6.4 it handled both typed lines and program lines. It saves card space. |
| 8 | On Saturn the data (message text, alias table) goes in **free space in bank 7 first**; if that is not enough, the `$D000` first page of the cache bank (6) (user decision, 2026-11-02) | Option C in 8.2b, then A. The bank-switching read code has to be designed and tested. |
| 9 | **Fix the line editor's comma and Ctrl-A problems, as a separate change, later** (user approval, 2026-11-02) | The same fix could remove the Hangul-name-after-comma problem, the stray `$81` after an alias, and Hangul mode staying on. It needs the Hangul-input regression tests and a check by the K-BASIC session. |
| 10 | **No code is changed until the user says so** (user instruction, 2026-11-02) | The test code so far lives only in a scratch folder; nothing in the repository was changed. |
| 11 | A plain 16 KB card with K-BASIC is K-BASIC's original target and is expected to work | Korean messages and Hangul-first names do not involve K-BASIC, and the aliases were renamed so they do not clash (decision 3). The hook with K-BASIC loaded has not been tested. K-BASIC on Saturn needs separate changes. |
| 12 | The Korean command names (aliases) are done for **all 25**. `PR#`, `IN#` and `FP` are AS IS (stay English) (user decision, 2026-11-02) | Three of the 28 have no Korean name. For the size see 8.2: even on the plain card it does not fit in one block, so the small free fragments are used or something is shortened. |

**Not decided yet:** the list of the 25 Korean names (needs review), and what to shorten if space is short (8.2).

### 8.2 Size: does it all fit?

| item | bytes | note |
|---|---|---|
| messages + header | 380-410 | the plain card has 685 contiguous free bytes from `$D153` (669 measured earlier as usable) |
| 25 aliases, compact format (estimate) | about 340-380 | 110-130 of code + about 9 per alias (Korean key + DOS command number) |
| **both together** | **about 720-790** | more than the 670-715 contiguous free bytes on the plain card. The missing 30-120 bytes come from the small free fragments (about 165 bytes) or from shortening |
| 25 aliases in the uncompressed format (about 12-17 per alias) | about 410-550 | does not fit, so the compact format is a must |
| Hangul-first file names | 20-30 | nearly full if added |

**Saturn build:** the `$D000` image has only 186 contiguous free bytes starting at `$D316` (plus a few small pieces). The total above does not fit in this image. The Saturn card is 128 KB (8 banks of 16 KB), but K-HANGEUL uses only bank 7. The kScheme session's answer (details in kScheme's `src/docs/KSCHEME-MEMORY.md`): bank 0 is kScheme's own layout (a hard need); banks 1-5 hold vectors and strings ("use all 128 KB" is a design rule, not a hard need); bank 6 is the cache bank (when K-HANGEUL holds bank 7). At start-up it writes a detection tag at `$FF80` in banks 1-7 temporarily and restores it. So on Saturn the places we can use are: (1) free space in bank 7: 186 bytes from `$D316` (the free tail of the Korean-font page has not been measured). (2) In the cache bank (bank 6), the `$D000` first page (4 KB) and `$FF00-$FFFF` (256 bytes) that kScheme does not use: kScheme says no change is needed on its side. This suits data tables (message text, the alias table), but the driver needs extra code to switch the bank and read it (I estimate tens of bytes; not designed). (3) kScheme giving up its top vector bank: about 3 bytes of kScheme code, and 16 KB (about 17-20%) less vector space. (4) About 256 bytes of kScheme's main RAM (its hash table `$1400-$17FF` or the top of its stack `$1000-$11FF`). Other ways to shrink: shorten the message wording further; use the free block at `$0800-$1FFF` on the plain card (93 bytes) and the Saturn `$9400` fragments. Each new DOS hook also costs a few bytes in the rebuild entry (`SATREINIT=$D3FA`).

### 8.2a Effect on K-BASIC (checked by the K-BASIC session in its own source)

- **Order.** `KB_IN` scans the line in the line input (`CLOSERUN`), then DOS reads it (not tested with a DOS command line). So a line that reaches the `$A000` hook has already been scanned by K-BASIC. The names were changed so that no alias word contains a K-BASIC word (decision 3). The other way is to replace the alias in the line input before the `KB_IN` call (the K-BASIC session's suggestion).
- **File names are affected.** DOS arguments are not quoted, so `KB_IN` rewrites the keys of a K-BASIC word inside a file name. Example: `LOAD 읽기파일` becomes `LOAD READ...`. This applies to Hangul file names (section 5), so choose names that avoid K-BASIC words (`읽기`, `실행`, `출력` and so on). This is a problem today whenever K-BASIC is loaded. Plain English DOS lines are untouched.
- **Messages.** K-BASIC's `LIST` (`KB_OUT`) does not use DOS's `$A702`. It prints through the driver's `DRV_COUT` (`$EE63`) and is simply not called if the output hook is not the driver's. K-BASIC does not depend on the English DOS error text, `$A702` or the name parser (`$A043-$A061`). So the messages patch and the Hangul-first names patch do not break K-BASIC.
- **K-BASIC's install messages** (`BRUN KBASIC` only) print through DOS's output path and show Hangul as raw keys if the output behind DOS is not the driver (no guard). This is existing behavior, unrelated to this change.
- **What the driver side must keep:** (i) K-BASIC hard-codes `$F6D1` and `$F6A2` in card code to recognize `LIST`. If card code moves before these, `LIST` silently shows English; tell the K-BASIC session if it moves. (ii) The stubs at `$9400` / `$940A`, the "KB" mark at `$8A03` with entries at `$8A05` / `$8A08`, and `KBBASE=$8A00` must stay. (iii) K-BASIC patches the zero-page CHRGET (`$C5-$C7` = `JMP $0350`) and a 30-byte stub at `$0350`. If the rebuild entry (`SATREINIT`) re-installs the driver's own CHRGET patch, K-BASIC's is removed. **I checked the source: the driver has no code that writes `$C5-$C7` or `$0350` (7.4).** (iv) DOS-side patches such as `$A702`, `$A04D` and `$A000` do not touch K-BASIC memory (`$8A00-$93FF`, `$0350`, `$C5-$C7`) or the Saturn bank logic.

### 8.2b Saturn bank split (the kScheme session's proposal and answers)

These are the answers of the kScheme session, from its own source and documents (`src/docs/KSCHEME-MEMORY.md`, `KSCHEME-MEMORY.ko.md`). Its design rule "use all 128 KB" is a default policy, not an obligation, and it can leave banks or parts of banks to K-HANGEUL. It will report the cost before any change if we give it the exact range.

**How much it uses:** a typical program uses almost nothing of banks 1-5 (0 KB with no vectors; strings are in main RAM). The cache fills as modules are loaded: 7.8 KB in one test (capacity 11.75 KB). The worst case is a program that allocates up to about 80 KB of vectors.

**Proposed split (with K-HANGEUL present)**

| Bank | Use | Whose |
|---|---|---|
| 0 | heap, plus one 4 KB vector arena (page 2) | kScheme (a hard need) |
| 1-3 | vectors, 48 KB | kScheme |
| 4 | kept free for kScheme code later (not designed; about 16 KB estimated) | kScheme |
| 5 | free | K-HANGEUL or the user |
| 6 | file cache. But its `$D000` first page (4 KB) and `$FF00-$FFFF` (256 bytes) stay free | K-HANGEUL may use them |
| 7 | K-HANGEUL | K-HANGEUL |

- To leave banks 4 and 5 free, kScheme sets `nbanks` to 4 in `far_detect`: a few bytes of boot-only code, with no growth in the core. The price is that vector capacity drops from 80 KB to 48 KB (from 96 KB to 48 KB without K-HANGEUL). A vector program that needs more than 48 KB gets a "no memory" error.
- The code bank (4) and K-HANGEUL's places (5, the free parts of 6, and 7) do not overlap.
- The standalone compiler `SCC` runs by itself with neither kScheme nor K-HANGEUL, so it needs no banks.
- Bank 6 is the cache bank only when `KHG1` is found in bank 7. Otherwise the cache is in bank 7.

**Rules K-HANGEUL must follow when it reads a bank (from the kScheme session)**

1. Leave Saturn bank 0 selected on return (`$C084`). kScheme assumes bank 0 whenever it is outside its own `far_getw` / `far_putw` / `far_getb`. The driver's trampoline already returns that way (ROM visible, write protected, bank 0).
2. Restore the card state from `SATSTATE` (`$95E2`): `$08` = ROM visible, `$38` = card RAM read/write. kScheme keeps that byte current.
3. Only switch the bank and read `$D000` page 1. Do not write to banks 1-5, and in the cache bank write nothing except `$D000` page 1 and `$FF00-$FFFF`.
4. On return, **leave `$D000` page 1 selected.** kScheme's `ram_on` does not re-select page 1 itself; it expects page 1 (the heap). The kScheme session did not verify this part, so it must be tested.
5. kScheme never calls the driver from inside a `far_*` access and runs with interrupts off, so there is no IRQ race.

**What K-HANGEUL needs is small** (about 420 bytes: the Korean DOS message text and the command-name table, and a few hundred bytes more later). Where the data can go:

| Option | Place | Change on kScheme's side | Cost and risk |
|---|---|---|---|
| A | cache bank (6), `$D000` first page, 4 KB | none | the driver needs extra code to switch the bank and read (tens of bytes estimated, not designed). The number 6 depends on the number of banks on the card and where `KHG1` is |
| B | the whole of bank 5 (16 KB) | `nbanks` = 4, 0 bytes of core code | 32 KB less vector space. Only if much more is needed later |
| C | free space in bank 7 | none | the simplest (no bank number needed). Only 186 contiguous free bytes, which may not be enough. The free tail of the Korean-font page and `$DF75-$DFFF` have not been measured |

The kScheme session recommended C (it is our own bank, so we don't depend on where the cache bank sits). My recommendation is to measure C first (whether the free space covers the code and the data together), and use A if it is not enough.

### 8.3 Recommendation and decisions for you

1. **Do the messages and the `CATALOG` header** (section 4). Do it on both cards and add the hook to the rebuild entry.
2. **Document Hangul in file names** that start with an English letter (it works now) and mention the Ctrl-A rule and the comma workaround in the manual.
3. **Allow Hangul-first names** (5.2) together with the messages: only 20-30 bytes.
4. **Aliases**: decided to do all 25 (8.1, item 12). Because they do not fit in one block (8.2), (a) shrink the alias table by storing the DOS command number and dropping the first Ctrl-K, (b) shorten the message wording, and (c) if still short, split the table over the small free fragments of the plain card (about 165 bytes: `$FA42` and others, and the 93 bytes of main RAM `$0800-$1FFF`). Which shortening to use will be measured while building, and reported.
5. **Where the hook goes (6.4)**: (a) one hook at DOS's `$A000`, (b) one hook in the line input, (c) both. My recommendation is (a): the tests show it handles typed lines and program lines, and it saves card space. A test with K-BASIC loaded has to be done on the K-BASIC side (not in this repository), so the K-BASIC session must be asked. If Korean commands inside programs are not needed, (b) is also fine.
6. **Space on the Saturn card**: the plain card just fits, but the Saturn `$D000` image does not. Please choose among options A (cache bank 6), B (bank 5) and C (free space in bank 7) in 8.2b. My recommendation is to measure C first and use A if it is not enough. The bank-switching read code has to be designed and tested.
7. **Fix the comma problem in the line editor** if you want file names (or aliases) followed by options to work. Depending on how it is fixed, the same change could also remove the stray `$81` after an alias (6.4, item 2) and Hangul mode staying on after a line (item 3). Say if you want that; it is a driver change.
8. Before building: review the Korean wording, ask the K-BASIC session to test the four renamed names, and test the Hangul-first-name hook, the untested commands (`OPEN`/`READ`/`WRITE`/`APPEND`/`EXEC`/`BLOAD`) and the IIe.
9. Under the version rules this is a change. VERSION goes up only when you say so.

## 9. Implementation status (branch `dos-korean`, 2026-11-03) and what could not be tested

### 9.1 What is done (plain 16 KB card)

- **Korean error messages:** the first 3 bytes of DOS's message printing routine at `$A702` become `jmp KSTUB`. `KSTUB` lives in main RAM (end of the banner area, `$1FCF`, 22 bytes). If DOS's output is the driver's, it runs `KMSGC` on the card, which prints the Korean text through `COUT`; otherwise DOS prints its English text unchanged. All 15 message numbers have text (`KOFF`, `KSTR1`, `KSTR2`).
- **`CATALOG` header:** done with data only, no extra code. DOS prints the 12 bytes at `$B3AF` backwards in a loop; the count (the operand at `$ADAF`) is cut to 9 and the bytes are replaced by `볼륨 ` (keystroke text), stored backwards. So the header reads `볼륨 254`. **"디스크 볼륨" is 17 bytes and does not fit, so "디스크" was dropped** (this replaces the 18-byte plan in the 4.2 table).
- **Install:** the end of INIT (`DPX`) now goes to `KPATCH` in the card's free block. `KPATCH` patches DOS only when its bytes are exactly as expected, then returns with `jmp STATEINIT`. Installing again with the HAN command leaves what is already patched alone (the byte checks).
- **File names that start with Hangul:** the `jmp $A000` at `$A04D` (DOS's first-character check) becomes `jmp KFN`. `KFN` is 10 bytes in main RAM (after `KSTUB`, ends at `$1FEF`, the banner limit is `$1FF0`): Ctrl-K continues to `$A050`, anything else goes to `$A000` as before. `KPATCH` installs it only if the bytes at `$A04D` are `4C 00 A0`. The card cost is about 24 bytes of code in `KPATCH`.
- **Korean command names (all 25):** `$A000` (DOS's code for a line it does not know, both typed lines and `CHR$(4)` program lines) becomes `jmp KALS`. If the line (from `$0201` after a Ctrl-D, else from `$0200`) starts with a Hangul run, the first word is looked up by a 16-bit hash of its keystrokes (`h = rotate-left(h) xor key`, 28 slots in the order of DOS's command table, `$FFFF` for the AS IS `PR#`, `IN#`, `FP`; the 25 hashes were checked to differ). On a match the Korean word is replaced in place by the English word, read from DOS's own table at `$A884` (so the English words cost nothing), the rest of the line is moved up or down, and DOS parses the line again at `$9FCD`. Anything else goes the way the original `$A000` code went (typed line to Applesoft, program line to DOS's SYNTAX ERROR).
  - **The run's closing Ctrl-A:** the line editor puts it after the space or at Return. The first `$81` after the word (before any new Ctrl-K) becomes a space, so `저장 T1` and `최대파일 2` work.
  - **A Hangul file name in the same run:** if the word is followed by a space and a Hangul key (jamo letter or tense key), the replacement is `SAVE`, space, Ctrl-K, then the name, so the name keeps its Ctrl-K (`저장 한글` saves a file named `한글`).
  - **Line length:** for a typed line DOS hands Applesoft the saved X (`$AA5A`) as the line length; after a rewrite it is set to the new Return position. Without this a bare `실행` gave `?UNDEF'D STATEMENT ERROR`.
  - **Where the code is:** the 405 bytes of the command-name code are in the first 512 bytes of `ENGFONT` (`$D860`), the glyphs of control codes 0-31, which are all empty. `ENGCOPY` now copies only glyphs 32-127. This is the plain build only; on Saturn those bytes are the packed English font (the Saturn patch list restores them).
  - **Main RAM stubs:** the stubs were reworked to share one exit (`KEXIT`: card off, `rts`). Each entry is `bit LCRAMRD` / `jmp` into the card; the card routine pushes the address to continue at. The four pieces take 22 bytes, 10 fewer than before (`KFN` was 10 bytes on its own).
- **Saturn build:** the code above is only in the plain build. Saturn still prints the English messages and header (it needs a path through the bank trampoline, 8.2b).
- **Size:** the contiguous free space on the card went from 685 to 251 bytes (from `$D305`). The messages, header and install code use about 434 bytes. `KSTUB` in main RAM is 22 bytes.
- **Only `src/driver/driver.s` was changed, and the build was done with `build.bat` (without the disk step).** The disk images in `disk/` were not changed.

### 9.2 What was confirmed in MAME (Apple II+, plain 16 KB card)

| Test | Result |
|---|---|
| `LOAD NOSUCH` (no. 6, FILE NOT FOUND) | `파일 없음` ✓ |
| `MAXFILES 0` (no. 2, RANGE ERROR) | `범위 오류` ✓ |
| `LOAD K-HANGEUL` (no. 13, FILE TYPE MISMATCH) | `파일 종류 다름` ✓ |
| `LOCK HELLO`, then `DELETE HELLO` (no. 10, FILE LOCKED) | `파일 잠김` ✓ |
| program `10 PRINT CHR$(4);"FOO"`, then `RUN` (no. 11, SYNTAX ERROR) | `문법 오류` ✓ |
| `LOAD HELLO,V1` (no. 7, VOLUME MISMATCH) | `볼륨 번호 다름` ✓ |
| `LOAD HELLO,D2` with drive 2 empty (no. 8, I/O ERROR) | `입출력 오류` ✓ |
| `MAXFILES 1`, then a program opening two files (no. 12, NO BUFFERS AVAILABLE) | `버퍼 부족` ✓ |
| reading the text file `SAMPLE1` to its end (no. 5, END OF DATA) | `데이터 끝` ✓ |
| `BSAVE` filling the disk (no. 9, DISK FULL) | `디스크 가득 참` ✓ |
| `SAVE T9` on a disk mounted read-only (no. 4, WRITE PROTECTED) | `쓰기 금지됨` ✓ |
| `HIMEM:16450`, then `LOAD DEMO` (no. 14, PROGRAM TOO LARGE) | `프로그램이 너무 큼` ✓ |
| `READ X` in direct mode (no. 15, NOT DIRECT COMMAND) | `직접 명령 아님` ✓ |
| `CATALOG` | header `볼륨 254` and the file list ✓ |
| `CATALOG` with two or more pages, advancing by key | the second page looks normal ✓ |
| `HAN` typed twice, then `LOAD NOSUCH` | still `파일 없음` ✓ |
| `SAVE `Ctrl-K`GKSRMF`Ctrl-A (name `한글`), then `CATALOG` | the entry `한글` in the list ✓ |
| `NEW`, then `LOAD 한글` | loads with no error ✓ |
| `LOCK 한글`, then `CATALOG` | `*A 002 한글` ✓ |
| `RENAME 한글,글한` | `?SYNTAX ERROR` (the known comma problem, 5.4; not a new fault) |
| `저장 T1` (typed, `SAVE`) | saved, `T1` in the list ✓ |
| `목록` (`CATALOG`), also `목록,D1` | Korean header and the list ✓ |
| `저장 한글`, `10 PRINT 9`, `불러오기 한글`, `LIST` | `10 PRINT 1` (the Hangul-named file was saved and loaded) ✓ |
| `실행` with no name (`RUN`) | runs the program, prints `1` ✓ |
| `실행 DEMO` | the demo runs ✓ |
| program `20 PRINT CHR$(4);"저장 T8"`, then `실행` | prints `1` and saves `T8` ✓ |
| `잠금 T8`, then `지우기 T8` (`LOCK`, `DELETE`) | `파일 잠김` ✓ |
| `자리 T8` (`POSITION`, the English word is longer than the Korean one) | `직접 명령 아님` (DOS's correct answer) ✓ |
| `이진저장 B1,A$300,L4`, `이진불러오기 B1`, `검사 B1`, `이름바꿈 B1,B2` | no error ✓ |
| `최대파일 2` (digit inside the run) and `최대파일 ` Ctrl-A `3` | no error ✓ |
| `감시`, `감시끝` (`MON`, `NOMON`) | no error ✓ |
| `한글` (`HAN`), then `LOAD NOSUCH` | the banner again, then `파일 없음` ✓ |
| `안녕 GO` (not a command name) | `?SYNTAX ERROR` as before ✓ |
| K-BASIC loaded (copy of `KBASIC.DSK`): `저장 T1`, `불러오기 T1`, `실행` | no error ✓ |
| the previous commit's build against this one: `RUN DEMO`, control codes `CHR$(1)` etc., a Hangul line | the screens are the same except the last line: `한글 ...` is now the `HAN` command, so DOS answers `문법 오류` instead of Applesoft's `?SYNTAX ERROR` ✓ |
| Saturn card: boot, `LOAD NOSUCH`, `RUN DEMO` | works, English message (as designed) ✓ |
| `PR#0`, then `LOAD NOSUCH` | English `FILE NOT FOUND` ✓ (the English fallback) |
| the driver on a blank DOS 3.3 disk (`dos33blank.dsk`), `LOAD NOSUCH` and `CATALOG` | `파일 없음`, header `볼륨 254` ✓ |
| the new driver on a copy of the K-BASIC disk (`KBASIC.DSK`; K-BASIC itself only read), `EXEC KSTART`, then `LOAD NOSUCH` | `파일 없음` after `KBASIC V1.0 OK` ✓. K-BASIC's `LIST` still shows `출력` ✓ |
| a driver built from the previous commit (`349603e`) against the new one, same input (three Hangul lines and `RUN DEMO`), comparing the 8192 hi-res bytes | 0 bytes differ ✓ |
| Saturn card (`-sl0 ssram`): boot and `LOAD NOSUCH` | boots, English message (as designed) ✓ |

### 9.3 What could not be tested, or is not done yet

**Could not be tested (with a reason)**

1. **Apple IIe:** the MAME folder on this machine has only the Apple II+ ROM set (`apple2p.zip`) and no IIe set, so `apple2ee` stops with "romset not found". There was no way to test a IIe, IIc or IIgs.
2. **The Korean text of no. 1 (`LANGUAGE NOT AVAILABLE`, `언어를 쓸 수 없음`):** DOS prints it when `INT` or `FP` asks for a language that is not there. This driver uses the `INT` command's slot for `HAN`, and `FP` always works, so I found no way to provoke it. The text comes from the same converter and was only checked by reading it back, not on screen.
3. **With kScheme loaded:** kScheme runs only on the Saturn card, and the Saturn build has no Korean messages yet, so there is nothing to test now.
4. **The repository's regression tool `tools/perf/diff_sim.py`:** it needs a Python 6502 simulator (py65, not in the repository, must be installed), a `pack_story` module that is not in the repository, and a memory dump, so it cannot run as it is. Instead I did the screen comparison of the previous and new builds in 9.2. It is not a test that draws all 11,172 syllables.

**Not tested (but could be)**

5. **The path that skips the patch when DOS's bytes are not as expected:** the checks exist, but I did not build a different DOS to prove it. (Both DOS disks I tried, the project disk and the blank DOS 3.3 disk, have matching bytes, so the patch applied on both.)
6. **Programs that catch DOS errors with `ONERR GOTO`:** the error codes are unchanged, so I expect no effect, but I did not test it. A program that reads or interprets DOS error text will now receive Hangul.
7. **The `CATALOG` header and other messages with K-BASIC loaded:** only `LOAD NOSUCH` was checked.

**A limit that is not fixed**

8. **The `CATALOG` header after `PR#0`:** because only data was changed, when output is not the driver the Hangul key letters show as they are, as `QHFFBA 254` (confirmed). Messages fall back to English; the header does not.

**Not built yet**

9. Korean messages, header, Hangul-first file names and Korean command names on the Saturn card.
   - **Limits of the command names:** (a) a Hangul word that is not a name but has the same 16-bit hash as one would be taken as that command (about 25 in 65,536). (b) After a name, a Hangul file name typed in the same run must start with a jamo or tense key; a name that starts with a digit or a sign is taken as English arguments. (c) The comma problem (5.4) still applies to a Hangul file name followed by a comma. (d) The test harness drops keys while typing Hangul fast (after `NEW` especially); those runs were repeated with slower typing, and are not driver faults.
   - **Space left (before 9.4; see 9.4 for now):** the card's free block had 166 bytes (from `$D35A`); the command-name area has 107 of 512 bytes (91 below glyph 31); main RAM `$1CC0-$1FEF` has 11 bytes.
10. A review of the message wording (the translations are the 4.2 draft as it was). The distribution disk `disk/K-HANGEUL.DSK` has been rebuilt with the driver of section 9.5 (commit `5b11c24`); booted in MAME on a 16K card (`파일 없음`, `목록,D1`) and on a Saturn card (`RUN DEMO`).

### 9.4 INIT (`포맷`) and the INIT guard (plain card)

**What was found.** Since the original Hangeul2, the loader wrote `jmp HANMAIN` into the middle of DOS's `INIT` code (`$A55B`) so that the `HAN` command (in the slot of `INT`, `$A59E`) could branch there. So `INIT` never formatted a disk while the driver was loaded: it re-ran the driver like `HAN` (confirmed in MAME with the build of commit `349603e` and with the new one; the disk was unchanged).

**What changed (user decision, option 2).**
- `HAN` now has its own `jmp HANMAIN` at `$A59E`; DOS's `INIT` code is no longer touched. On the Saturn card `INIT` still runs `HAN` as before (the loader writes `jmp SATHAN` at `$A55B` there), until the Saturn work (B) gives it the guard too.
- **The guard.** DOS's handler table entry for `INIT` (`$9D1E`) points to `KINITS` in DOS's unused bytes `$BCDF-$BCFF`. It swaps every byte the driver changed in DOS with the stock byte kept in a table (`KSWT`: `$A000`, `$A04E`, `$A59E`, `$A8F1`, `$ADA3`, `$ADAF`, `$AE3A`, `$B3B0`, `$9D1E`), so DOS is stock while `INIT` writes the disk. `INIT`'s handler returns to `KPOST`, which swaps back.
- **When `INIT` fails**, DOS jumps away and does not return to `KPOST`; it prints its error message. The message routine `$A702` is not swapped: it jumps to `KSTUBD`, also in `$BCDF`, which goes to the driver only while DOS's output is the driver's (`$37 = $94`), and otherwise does what stock DOS did. The driver's message code swaps back first. So a failed `INIT` prints a Korean message and the patches are back right away.
- **What a new disk gets.** The stock DOS, except `$A702` (`jmp $BCEF`) and the 31 bytes at `$BCDF`, which without the driver just print DOS's own English message. The flag that says "DOS is stock now" is a byte in the card, so `HAN` (which refills the `$9400` block) does not lose it.
- If `$BCDF-$BCFF` is not all zero (another DOS or a program uses it), the guard is not installed and `INIT` runs `HAN`, as it always did.

**Tests in MAME (plain card).**

| Test | Result |
|---|---|
| `10 PRINT "HI"`, `INIT HELLO` | disk formatted, only `HELLO` on it ✓ |
| then `LOAD NOSUCH`, `목록` in the same session | `파일 없음`, `볼륨 254` (the patches are back) ✓ |
| boot that disk without the driver: the screen | `HI` (HELLO runs) ✓ |
| `LOAD NOSUCH`, `CATALOG`, `LIST`, `RUN` there | `FILE NOT FOUND`, `DISK VOLUME 254`, `10 PRINT "HI"`, `HI` ✓ |
| its DOS in memory against stock DOS 3.3 | only `$A702-$A704` and `$BCDF-$BCFD` differ (plus DOS's working bytes) ✓ |
| `INIT HELLO` on a write-protected disk | `입출력 오류`, the disk is unchanged; then `LOAD NOSUCH` gives `파일 없음` ✓ |
| `포맷 HELLO` | formats, then `파일 없음` and `목록` work ✓ |
| `HAN` twice, then `LOAD NOSUCH`, `목록` | the banner, `파일 없음`, the Korean catalog ✓ |
| Saturn card: `INIT HELLO` | runs `HAN`, the disk is unchanged (as before) ✓ |

**Limits.**
- A program that catches an `INIT` error with `ONERR GOTO` gets no message, so DOS stays stock (English messages, no Korean command names) until the next DOS message or the next `INIT`.
- On a DOS that is not stock 3.3 at one of the patched places, the patch there was skipped, but the swap still writes the stock byte while `INIT` runs, so that disk gets a stock byte there.
- **Card space is now almost gone on the plain card:** 6 bytes in the free block, 1 byte in the command-name area.

### 9.5 The Saturn card (B)

**How it is built.**
- The message code and texts and the command-name code are in two include files (`src/driver/kdos_msg.inc`, `kdos_cmd.inc`), assembled twice: in the 16K card build as before, and in a new segment `BANK6` (scope `K6`) that runs at `$D000` of bank 6, page 1 (769 bytes, `$D000-$D300`). kScheme leaves that page alone when K-HANGEUL is in bank 7 (its answer in this session). The two copies differ only in how they leave (`KEXIT` or `SatLeave1`) and print (`COUT` or `K6PUT`); the Saturn copy has no INIT guard.
- The loader (`SatFinish`) copies `BANK6` into bank 6 page 1, only when the driver goes into bank 7 (a 128K card).
- `KPATCH6` (bank 7, in the free bytes before the shift masks; 1 byte left there) runs at the end of `SATCOPY`, so at start-up, at `HAN` and at the rebuild entry `$D3FA`. It writes the stubs and makes the DOS patches, each only if DOS has the stock bytes.
- Stubs: `$BCDF-$BCFA` in DOS's unused bytes (28 bytes, outside the `$9400` block, so kScheme's load does not wipe them): `K6IN` counts the entry in `SATDEPTH` and maps bank 6 page 1, `K6MSG` (`$A702`), `K6AL` (`$A000`), `K6PUT` (prints through `$940A`, which enters and leaves bank 7, then maps bank 6 again). The file-name stub `K6FN` is at `$95A6-$95AB` in the `$9400` block (free bytes after the trampoline's piece 2), written by every `SATCOPY`, so `$D3FA` makes it again.
- Each routine leaves with `jmp SatLeave1` after pushing the address to go on at: the outermost leave selects bank 0 and the caller's card state (`SATSTATE`), as kScheme expects.
- `INIT` on a Saturn card still runs `HAN` (the loader writes `jmp SATHAN` at `$A55B`), so these patches never reach a new disk. The INIT guard for Saturn needs more main RAM than is free (the `$BCDF` area is full).

**MAME tests (`-sl0 ssram`).**

| Test | Result |
|---|---|
| boot, `LOAD NOSUCH` | the Saturn banner line, `파일 없음` ✓ |
| `저장 한글`, `10 PRINT 9`, `불러오기 한글`, `LIST`, `실행` | `10 PRINT 1`, then `1` ✓ |
| `목록` | header `볼륨 254` and the list ✓ |
| program `20 PRINT CHR$(4);"저장 T8"`, `실행`, `잠금 T8`, `지우기 T8` | `1`, then `파일 잠김` ✓ |
| `HAN` twice, then `LOAD NOSUCH` | `파일 없음` ✓ |
| `INIT HELLO` | runs `HAN`, the disk is unchanged (as designed) ✓ |
| 16K card after the change: messages, `저장 한글` / `불러오기 한글` / `실행`, `INIT HELLO` with the guard | as before ✓ |

**With kScheme (tested by the kScheme session, its own MAME setup, `-sl0 ssram`, this build).** kScheme starts normally (banner, `khg_attach` / `$D3FA`); Hangul output (`한글`) and numbers print; file I/O works (a text file written on drive 2 reads back correctly). After `(exit)`, at the `]` prompt, `LOAD NOSUCH` prints `파일 없음` and `CATALOG` shows `볼륨 254` and the list. Bank 6 `$D000-$D3FF` page 1 (the Korean DOS code) was dumped after boot and again after `(exit)`: all 1024 bytes identical. (Bank 6 page 2 changed, as expected: kScheme's file cache.) A `?UNBOUND ERROR` when reading the file back is a kScheme bug; it happens the same with the old driver and without K-HANGEUL.

**Not tested yet.** `PR#0` on a Saturn card (the text page after `PR#0` was hard to read in the test); a 64K Saturn card (by design DOS stays English there).

**Space left on Saturn:** bank 7 free block 1 byte; DOS `$BCFB-$BCFF` 5 bytes; `$95AC-$95AD` 2 bytes; bank 6 page 1 about 3.3 KB.

### 9.6 Message wording (user decision, 2026-11-03)

The user marked the wanted text of each message in the 4.2 table. Changed from what was built: no. 1 `LANGUAGE NOT AVAILABLE` is `언어 없음` (was `언어를 쓸 수 없음`), no. 4 `END OF DATA` is `자료 끝` (was `데이터 끝`), no. 5 `FILE NOT FOUND` is `파일을 찾을 수 없음` (was `파일 없음`). The other eleven and the header `볼륨` stay. The texts together grow by 1 byte (17 + 12 + 34 bytes instead of 31 + 14 + 17): the 16K card's free block has 5 bytes left now. Checked in MAME on a 16K card and on a Saturn card: `LOAD NOSUCH` and `불러오기 NOSUCH` print `파일을 찾을 수 없음`, reading `SAMPLE1` past its end prints `자료 끝`. No. 1 still cannot be provoked (section 9.3). The test results in 9.2-9.5 show `파일 없음` and `데이터 끝` because they were made before this change.

### 9.7 The comma fix in the line editor (approved earlier; done)

**Change.** In `FETCHLINE` (`L_E6D6`..), when a Hangul run is open and the character is a comma, the closing Ctrl-A (`$81`) is written first (`cmp #$AC` / `beq L_E70C`, 4 bytes). So `BSAVE B` Ctrl-K `GKS` `,A$300,L4` reaches DOS as `B`, `$8B`, `GKS`, `$81`, `,A$300,L4`: DOS ends the name at the comma and the options are clean. It is the stock editor code, shared by the 16K and Saturn builds.

**Where the 4 bytes came from.** The image is full up to the vectors, so the same routine gave up 4 NOPs (2 after `jsr SAVECLR`, 2 after `jsr CLOSERUN`); nothing after `L_E715` moved. One thing needed care: `D_E5E5` is data that the old source wrote as `bcs L_E61E+1` (the assembler computes `$38`, the distance to a label); moving code before it changed that byte and broke Hangul typing at first. It is now written as `.byte $B0,$38`.

**Tests in MAME (16K and Saturn).**

| Test | Result |
|---|---|
| `BSAVE B한,A$300,L4`, `BLOAD B한,A$300` | saved and loaded (before: `?SYNTAX ERROR`) ✓ |
| `목록,D1` | the Korean header and the list ✓ |
| `이름바꿈 ` Ctrl-A `B한,B글` (`RENAME`), then `LOAD B글` | renamed and loaded ✓ |
| `20 DATA 한,글` and `10 PRINT "한, 글, ABC, 123"`, `RUN`, `LIST` | prints and lists the same as the build before; the screen is the same (10 hi-res bytes differ: the cursor) ✓ |

**Limits.** (a) A string or `DATA` item typed in Hangul with a comma is stored as separate runs: 2 bytes more per comma (`LEN`). (b) A comma inside Hangul text typed in the middle of a run closes the run; the next Hangul letter opens a new one with Ctrl-K automatically. (c) Section 5.5's other limits are unchanged. (d) A program that compares an answer with a string that has a comma must have the same runs (type it the same way).
