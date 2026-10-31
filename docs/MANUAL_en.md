# K-HANGEUL (캐플한글) v1.0b user manual

> 한국어: [MANUAL.md](MANUAL.md)


## 1. What it is

**K-HANGEUL** is a driver for the Apple II Plus that draws **small but readable 12×12 Hangul** on the hi-res screen. It is a modified Hangeul2. Its main use is **writing text BASIC programs in Korean**: the Hangul shows in the `LIST` and in the running program.

- Screen: 46 columns × 16 rows. English and digits take one column, a Hangul syllable two, so a line holds 23 syllables.
- Glyphs: Hangul 12×12, English 6×10 (drawn in the lower 10 lines of the 12-line cell; the English font is its own file, `FONT6X10`).
- BASIC memory: about 21.5 KB (`HIMEM` is `$9400`). The free byte count is shown at start-up.


## 2. What you need

- Apple II Plus, 48K RAM, and a **language card (16K)**: the driver lives in the card.
- DOS 3.3 (48K). Use this disk's DOS, or copy the files to your own disk (section 8).


## 3. Files on the disk

`CATALOG` shows 33 files. The first eight are the driver and the basic files; the rest are examples. The old Hangeul2 files (`ASCII`, `MASKS`, `SHOW12`) are not needed and are not included.

| file | type | what it is |
|---|---|---|
| `HELLO` | BASIC | Runs at boot. Loads `FONT12` and `FONT6X10`, then runs `K-HANGEUL`. |
| `K-HANGEUL` | binary, `$0F94` | The Hangul driver. Goes into the language card and handles screen output and keyboard input. |
| `FONT12` | binary, `$6000` | The 12×12 Hangul font, copied into memory at boot. Replace this file to change the Hangul font. |
| `FONT6X10` | binary, `$7200` | The 6×10 English font (128 glyphs), copied into the language card at boot. Replace this file to change the English font. |
| `TYPE` | binary, `$8E00` | Optional. Adds the BASIC command `& TYPE`, which prints a Hangul text file. |
| `TYPEC` | binary, `$8E00` | Optional. A program that asks `FILE NAME` at the `]` prompt and prints a Hangul text file. |
| `STYPE` | binary, `$8A00` | Optional. Like `TYPE`, but each row of text appears smoothly, one pixel row at a time from top to bottom: adds the command `& STYPE`. It cannot be loaded together with `TYPE`. |
| `STYPEC` | binary, `$8A00` | Optional. The smooth version of `TYPEC` (a wait can follow the file name as `,number`). |
| `SAMPLE1` | text | A Hangul text file to try `TYPE` and `TYPEC`. |
| `DEMO` | BASIC | A short BASIC program with Hangul in it. `RUN DEMO`, or `LOAD DEMO` then `LIST`. |
| `MIXED` | BASIC | Reads the short mixed text (`SAMPLE1`: double final consonants, double consonants, English, digits) with **plain BASIC only**. `RUN MIXED`. |
| `NALGAE1` … `NALGAE16` | text | The long text: the whole story 날개 (Yi Sang, about 57 KB in 16 files). |
| `STORY` | BASIC | Reads `NALGAE1`…`16` with **plain BASIC only**. `RUN STORY`. |
| `SAMPLEB` | binary `$8000` | A short text for the print-from-memory example. |
| `TYPEDEMO` | BASIC | `& TYPE` example: prints a file (`SAMPLE1`) and a text in memory (`SAMPLEB`). `RUN TYPEDEMO`. |
| `STORYT` | BASIC | A three-line program that prints the story with `& TYPE`. `RUN STORYT`. |
| `STYPEDEMO` | BASIC | `& STYPE` example: with no wait, with a wait of 20, and from memory. `RUN STYPEDEMO`. |
| `STORYS` | BASIC | Prints the story smoothly with `& STYPE`. `RUN STORYS`. |


## 4. Getting started

Put the disk in drive 1 and switch on. The screen shows `캐플한글 v1.0b 2026년 (한글2 수정버전)`, the free memory and the `]` prompt.

> Starting the driver clears the BASIC program in memory (like `NEW`). Load your program after booting.

Try `RUN DEMO`.


## 5. Typing Hangul

**Ctrl-K** starts Hangul mode and **Ctrl-A** ends it. Between them, type the letters of the standard Korean two-set (2-beolsik) keyboard in capitals (the II+ default).

Top: the key to press. Bottom: the jamo it types. The keys are laid out as on the real keyboard.

```
┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐
│ Q  ││ W  ││ E  ││ R  ││ T  ││ Y  ││ U  ││ I  ││ O  ││ P  │
│ ㅂ ││ ㅈ ││ ㄷ ││ ㄱ ││ ㅅ ││ ㅛ ││ ㅕ ││ ㅑ ││ ㅐ ││ ㅔ │
└────┘└────┘└────┘└────┘└────┘└────┘└────┘└────┘└────┘└────┘
  ┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐
  │ A  ││ S  ││ D  ││ F  ││ G  ││ H  ││ J  ││ K  ││ L  │
  │ ㅁ ││ ㄴ ││ ㅇ ││ ㄹ ││ ㅎ ││ ㅗ ││ ㅓ ││ ㅏ ││ ㅣ │
  └────┘└────┘└────┘└────┘└────┘└────┘└────┘└────┘└────┘
    ┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐
    │ Z  ││ X  ││ C  ││ V  ││ B  ││ N  ││ M  │
    │ ㅋ ││ ㅌ ││ ㅊ ││ ㅍ ││ ㅠ ││ ㅜ ││ ㅡ │
    └────┘└────┘└────┘└────┘└────┘└────┘└────┘
```


- Tense consonants ㄲ ㄸ ㅃ ㅆ ㅉ are the keys `-` `=` `*` `<` `>`; ㅒ is `;` and ㅖ is `+`. **On a machine without the Shift key mod** (see below), do not use Ctrl: type each symbol the way the Apple II Plus keyboard types it:
  (`Sh-` means: hold Shift and press the `-` key.)

  ```
  ┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐
  │ -  ││Sh- ││Sh: ││Sh, ││Sh. ││ ;  ││Sh; │
  │ ㄲ ││ ㄸ ││ ㅃ ││ ㅆ ││ ㅉ ││ ㅒ ││ ㅖ │
  └────┘└────┘└────┘└────┘└────┘└────┘└────┘
  ```

  (On the Apple II Plus the Shift key only selects the upper symbol of a key; the computer itself cannot tell it is held. So all of these can be typed without the Shift key mod.)

  **On an Apple IIe, IIc or IIgs** the keyboard is different: Shift+`-` gives `_` and Shift+`;` gives `:`, and `*` is Shift+8. The driver knows this and, in Hangul mode, turns `_` into `=` (ㄸ) and `:` into `+` (ㅖ), so the chart above works on those machines too. (The `:` key therefore does not type ₩ in Hangul mode on them.) ㅃ is Shift+8 (`*`) on a IIe, as it is Shift+`:` on the II Plus.
- **With the Shift key mod**, the tense consonants and ㅒ ㅖ can also be typed with Shift, as on a normal 2-set keyboard: Shift+R = ㄲ, Shift+E = ㄸ, Shift+Q = ㅃ, Shift+T = ㅆ, Shift+W = ㅉ, Shift+O = ㅒ, Shift+P = ㅖ. Without the mod use the `-` `=` `*` `<` `>` `;` `+` keys above (both work). It acts only in Hangul mode, and the text is stored as before, so existing programs and text files do not change.

  The keys used with the Shift key mod, as they sit on the keyboard:

  ```
  ┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐
  │ R  ││ E  ││ Q  ││ T  ││ W  ││ O  ││ P  │
  │ ㄲ ││ ㄸ ││ ㅃ ││ ㅆ ││ ㅉ ││ ㅒ ││ ㅖ │
  └────┘└────┘└────┘└────┘└────┘└────┘└────┘
  ```
  - The Shift key mod connects the Shift key to game-port pushbutton 2 (`$C063`). It was checked in MAME (the Apple II Plus default "SW2 = Shift"). The driver remembers the state of this button at start-up as "Shift not held", so **do not hold Shift or game button 2 while booting.**
  - Holding game button 2 looks like Shift. It also works in the AppleWin emulator, as long as joystick 2 is disabled there.
  - **On an Apple IIe, IIc or IIgs the Shift key cannot be read by software** (on the IIe and the Enhanced IIe the board pad that would connect it is open), so the driver detects these machines at start-up and uses the **Open-Apple key** instead: hold Open-Apple and press R E Q T W O P to get ㄲ ㄸ ㅃ ㅆ ㅉ ㅒ ㅖ. In AppleWin, Open-Apple is the Left Alt key (Solid-Apple is Right Alt). The Shift key itself is ignored for this on those machines, and the `-` `=` `*` `<` `>` `;` `+` keys work everywhere.
- Compound vowels and final clusters are typed as the two letters in a row: ㅘ = H K, ㅝ = N J, ㅢ = M L, ㄳ = R T, ㄺ = F R.
- Example: `한글` is **Ctrl-K** `G K S R M F` **Ctrl-A**; `까따빠` is **Ctrl-K** `- K = K * K` **Ctrl-A**.
- The left arrow (backspace) deletes.

**Editing keys** (the keys carried over from Hangeul2 that were checked on this driver)

Ctrl plus the key (the letter on top). The bottom label is what it does. Keys with no label are not used.

```
┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐
│ Q  ││ W  ││ E  ││ R  ││ T  ││ Y  ││ U  ││ I  ││ O  ││ P  │
│    ││    ││DEL>││INS ││    ││HOME││ -> ││INV ││NRM ││    │
└────┘└────┘└────┘└────┘└────┘└────┘└────┘└────┘└────┘└────┘
  ┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐
  │ A  ││ S  ││ D  ││ F  ││ G  ││ H  ││ J  ││ K  ││ L  │
  │ENG ││    ││    ││    ││    ││ <- ││    ││HAN ││CLR │
  └────┘└────┘└────┘└────┘└────┘└────┘└────┘└────┘└────┘
    ┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐
    │ Z  ││ X  ││ C  ││ V  ││ B  ││ N  ││ M  │
    │    ││DEL ││CAN ││ UP ││BOL ││EOL ││    │
    └────┘└────┘└────┘└────┘└────┘└────┘└────┘
```

Labels: HOME home position · DEL delete one character · DEL> delete to end of line · INS insert mode on/off · INV/NRM inverse/normal · <- -> one column left/right · BOL/EOL start/end of line · CAN drop the typed line and go to the next · UP move the screen down one line · CLR clear the window · ENG/HAN English/Hangul mode

Keys not yet checked on this driver: Ctrl-F, Ctrl-P, Ctrl-J, Ctrl-G, Ctrl-T, Ctrl-@, Ctrl-]. Ctrl-Z does nothing while you are editing. Ctrl-S does not stop typing (pausing works only in `TYPE` and `STYPE`).


## 6. Hangul in BASIC programs

Type Hangul inside a string with Ctrl-K … Ctrl-A. The program stores Ctrl-K, the letters and Ctrl-A; `LIST` shows them as Hangul, and `SAVE`, `LOAD` and `RUN` work as for any BASIC file. A program with Hangul only looks right while the driver is loaded; without it you see the plain letters, such as `GKSRMF`. `LIST` the `DEMO` program to see an example.

**Text styles: inverse, underline, overlay**

They work for both Hangul and English, in a program or at the `]` prompt.

- **Inverse**: text printed after `INVERSE` is black on white. `NORMAL` goes back to normal text. `FLASH` looks the same as inverse (it does not blink).

  ```
  PRINT "A ";: INVERSE: PRINT "INV";: NORMAL: PRINT " B"
  ```

- **Underline**: `CALL 38257;UL ON` draws a line under the text printed after it, and `CALL 38257;UL OFF` ends it. The line fills the bottom row of the character cell, so it looks continuous across letters.

  ```
  CALL 38257;UL ON: PRINT "UNDER": CALL 38257;UL OFF
  ```

- **Overlay** (draw over what is there): normally a character first clears its cell and then draws. After `CALL 38257;OR ON` it does not clear the cell and draws on top of whatever is already there. For example, print `O`, return to the same place with `HTAB`, and print `/`: you get `Ø`. `CALL 38257;OR OFF` goes back to the normal way.

  ```
  CALL 38257;OR ON: PRINT "O";: HTAB 1: PRINT "/": CALL 38257;OR OFF
  ```

The number **38257** after `CALL` is where this driver takes its commands. The old Hangeul2 manual says `CALL 2000;`, but this driver moved that block out of the text screen, so `CALL 2000;` drops into the monitor. Always use 38257.


## 7. Printing Hangul text files: `TYPE` and `TYPEC`

A Hangul text file uses the "N-byte" form: Hangul as Ctrl-K, two-set letters and Ctrl-A, English and digits as they are. It must be a DOS text file (type T); `SAMPLE1` is an example.

**`TYPEC`, from the command line:** `BRUN TYPEC`, then type a file name at the `]` prompt (lower case is fine). It asks again after each file; an empty line ends it. A missing file gives `FILE NOT FOUND`.

**`& TYPE`, in a program or at the prompt:** `BRUN TYPE` once, then `& TYPE,"SAMPLE1"`. No `OPEN`, `READ` or `CLOSE` is needed. Text already in memory can be printed with an address: `& TYPE,"$8000"` or `& TYPE,32768` (the text ends with a `$00` byte).

Both use memory just under `HIMEM`, so run `BRUN TYPE` at the start of a program.

**A complete BASIC program that uses `& TYPE`** (run as it stands on this disk):

```
10 REM &TYPE DEMO
20 PRINT CHR$(4);"BRUN TYPE"
30 ONERR GOTO 100
40 HOME
50 & TYPE,"SAMPLE1"
60 PRINT "-----"
70 INPUT "FILE NAME? ";F$
80 & TYPE,F$
90 END
100 IF PEEK(222) = 6 THEN PRINT "FILE NOT FOUND": END
110 PRINT "ERROR ";PEEK(222): END
```

- Line 20 loads `TYPE`, once, at the start.
- Line 30 sends any error, such as a missing file, to line 100 (`ONERR GOTO`).
- Line 50 gives the file name as a string. `& TYPE` itself reads the file and prints it.
- Line 70 asks for a file name. Line 80 passes it as a string variable, `& TYPE,F$`. A name that is not on the disk goes to line 100.
- Line 100: `PEEK(222)` is the error number; 6 is `FILE NOT FOUND`.


**Long and mixed text examples**

- `RUN MIXED`: reads `SAMPLE1` and prints it. Hangul (double final consonants 값 밝 앉 읽 훑 짧, double consonants), English and digits are mixed on one screen.
- `RUN STORY`: reads the 16 files of the story 날개 one after another and prints them. The text scrolls without stopping and takes a while to reach the end. To see just one file, `BRUN TYPEC` and give its name (for example `NALGAE1`).
- `RUN STORYT`: prints the same story with `& TYPE`. The program is three lines (`BRUN TYPE`, `FOR`, `& TYPE,"NALGAE"+STR$(N)`), short and faster.

`MIXED` and `STORY` are plain BASIC with no machine code and no `POKE` of a routine: only `OPEN`, `READ`, `GET A$` and `PRINT A$;` (the one exception is `ONERR GOTO`, which catches the end of the file, and `POKE 216,0`, which clears that error). `LIST` them to see how a program reads a Hangul text file by itself:

```
10 REM PRINT SAMPLE, KEYSTROKES PLUS ENGLISH
20 D$ = CHR$ (4)
30 N = 1
40 F$ = "SAMPLE" + STR$ (N)
50 PRINT D$;"OPEN ";F$
60 PRINT D$;"READ ";F$
70 ONERR  GOTO 100
80 GET A$: PRINT A$;: GOTO 80
100 POKE 216,0: PRINT D$;"CLOSE":N = N + 1: IF N <= 1 THEN 40
110 END
```

**Smooth printing: `STYPE` and `STYPEC`**

They do what `TYPE` does, but instead of typing each letter they **draw a whole row first where it cannot be seen and then show it one pixel row at a time from top to bottom**, so the row seems to unroll. The screen scrolls up as usual.

```
]BRUN STYPE
]& STYPE,"NALGAE1"          <- no wait
]& STYPE,"NALGAE1",5        <- about 5 ms after each pixel row
]& STYPE,"$8000",5          <- text in memory (hex or decimal address)
```

- The third value (0 to 255, any number expression) is the **wait**. Without it the wait is 0: the row appears almost at once, so to see the effect give 5 or more. A row has 12 pixel rows, so a wait of 5 takes about 60 ms per row.
- Lines wider than 46 columns are cut into rows of 46 columns, and every row has its own smooth effect.
- `STYPE` reads the file the same way as `TYPE` (the drawing is as fast as `TYPE`'s); each row costs about 8 ms more (0.7 s on story part 1, measured in MAME), and the wait comes on top.
- **Stopping**: press **Ctrl-C** while it prints and `TYPE`, `STYPE`, `TYPEC` and `STYPEC` all stop (`TYPEC` and `STYPEC` return to `FILE NAME`). Ctrl-S pauses (any key continues) and Ctrl-Reset breaks out (then `HAN`). In a BASIC loop such as `STORYT`, Ctrl-C stops only the file being printed and the loop goes on with the next one, so use Ctrl-Reset to stop the whole program.
- `TYPE` and `STYPE` **cannot be loaded together**. `STYPE` uses about 3 KB of BASIC memory (`TYPE` 1.5 KB). Run `BRUN STYPE` at the start of the program.
- `STYPEC` is the smooth `TYPEC`: `BRUN STYPEC`, then at `FILE NAME` type a name followed by a comma and the wait, such as `NALGAE1,5`. It overwrites the top 2.5 KB of BASIC memory, so use it at the `]` prompt with no program.
- `RUN STYPEDEMO` and `RUN STORYS` on the disk are examples.


## 8. Using it on your own DOS 3.3 disk

Copy four things to your disk with AppleCommander, CiderPress or similar:

| file | type, address |
|---|---|
| `FONT12` | binary, `A$6000` |
| `FONT6X10` | binary, `A$7200` |
| `K-HANGEUL` | binary, `A$0F94` |
| `HELLO`, or the first three lines of your boot program | `10 PRINT CHR$(4)"BLOAD FONT12,A$6000"` / `20 PRINT CHR$(4)"BLOAD FONT6X10,A$7200"` / `30 PRINT CHR$(4)"BRUN K-HANGEUL"` |

It needs standard 48K DOS 3.3. `BRUN K-HANGEUL` clears the BASIC program in memory, so run these three lines first and `RUN` your own program afterwards.


## 9. Good to know

- **`HAN`**: if the driver is switched off by `PR#0` or `IN#0`, type `HAN` to switch it on again (the screen is cleared). The same works after Ctrl-Reset (checked with MAME's Ctrl-Reset key; not tried on a real machine).
- **`HOME`** clears the Hangul screen. `CATALOG` pauses after each 16-row page.
- **Do not use `HGR2`.** Applesoft's `HGR` and `HGR2` are in ROM and cannot be blocked. `HGR2` clears the memory where the BASIC program lives (`$4000–$5FFF`). **`HGR`** clears the Hangul screen and turns the bottom four rows into the text window. `TEXT` and `GR` also change the display mode. If you used one by mistake, try `HAN`: it sets the hi-res screen up again (not tested after `HGR`; a program that `HGR2` has cleared does not come back).
- **Do not use `MAXFILES`**: it removes the protection of the memory the driver uses.
- **An `INPUT` answer typed in Hangul** starts with Ctrl-K, and if the Hangul run was still open when you pressed Return, the closing Ctrl-A is added to the end of the string automatically, so printing it does not leave Hangul mode on. The string is one character longer for that (`LEN` of `한글` is 8). To compare an answer with a Hangul string stored in the program, that string must end with Ctrl-A too.
- The II+ keyboard has no lower case. Print lower case letters and `|` with `CHR$` or from a text file.


## 10. About

Made by **KAPPLE**.

K-HANGEUL is Hangeul2 modified for a 12×12 font, a hi-res page 1 screen, faster drawing and a 6×10 English font. It is written in assembly (cc65); the fonts are made from `font.json` with the font editor. More detail is in the project's `docs` folder.
