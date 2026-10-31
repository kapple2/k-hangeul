# How to build K-HANGEUL

> 한국어: [BUILD.md](BUILD.md)

This guide goes step by step from the source to the boot disk `disk/K-HANGEUL.DSK`. It is written for Windows.

Short version (tools installed and paths set):

```
build.bat
```

The result is `disk\K-HANGEUL.DSK`.


## 1. What you need

| tool | used for | version tested |
|---|---|---|
| cc65 (`ca65`, `ld65`) | turns assembly into machine code | 2.19 |
| AppleCommander (`acx.exe`) | puts files on a disk image | 14.1 |
| Python 3 | font conversion, disk building, the font editor | 3.12.10, 3.13.7 |
| GNU make | optional. If it is installed the build uses `make`; if not, it calls the `.bat` files in turn | |
| an emulator | optional, to try the disk (AppleWin or MAME, an Apple II Plus with a language card) | |

Building the disk needs no Python packages. The font pictures (`src/tools/render/`) need Pillow and the speed tests (`tools/perf/`) need py65 (see `requirements.txt`).


## 2. Step by step

### 2-1. Get the source

```
git clone https://github.com/kapple2/k-hangeul.git
cd k-hangeul
```

If you already have it, go to the top folder of the repository (where `build.bat`, `src`, `docs` and `disk` are). Run every command in this guide from that folder.

### 2-2. Install cc65

1. Download a cc65 Windows snapshot (https://cc65.github.io/) and unpack it, for example to `D:\opt\devtools\asm\cc65`.
2. Check that its `bin` folder holds `ca65.exe` and `ld65.exe`.

### 2-3. Install AppleCommander

1. Download the command-line tool `acx.exe` from AppleCommander (https://applecommander.github.io/), for example to `C:\bin\acx.exe`.
2. Check it: `C:\bin\acx.exe -h`

### 2-4. Check Python

```
py -3 --version
py -3 -c "import tkinter; print('tkinter ok')"
```

If the second line fails, reinstall Python from python.org and tick **tcl/tk and IDLE** in the feature list (the font editor needs it). If you only build the disk, the first line is enough.

### 2-5. Create a virtual environment (optional, recommended)

A virtual environment keeps this project's Python packages apart from everything else on your computer. In the top folder of the repository:

```
py -3 -m venv .venv
.venv\Scripts\activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

In PowerShell use `.venv\Scripts\Activate.ps1` instead of the second line (if scripts are blocked, run `Set-ExecutionPolicy -Scope Process RemoteSigned` first). Type `deactivate` to leave it.

- `.venv` is listed in `.gitignore`, so it is not committed.
- The font editor (`src\fonteditor\run_editor.bat`) uses `.venv` if it exists.
- The disk build (`build.bat`) uses `py -3`, so it works without activating the environment.

### 2-6. Set the tool paths

The defaults are `D:\opt\devtools\asm\cc65\bin` for cc65 and `C:\bin\acx.exe` for AppleCommander. If yours are elsewhere, change the `CC65` and `ACX` lines in these files:

| file | when it is used |
|---|---|
| `src\make_all.bat` | always (`build.bat` calls it) |
| `src\driver\build.bat`, `src\type\build.bat`, `src\typec\build.bat`, `src\stype\build.bat`, `src\stypec\build.bat` | when GNU make is not installed (each has its own paths) |
| the `Makefile` in the same folders | when you run `make` inside a folder yourself, or pass `make CC65=... ACX=...` on the command line |

### 2-7. Build

```
build.bat
```

What `build.bat` does:

1. It runs `src\make_all.bat`:
   1. It builds the driver. `src\driver\fontgen.py` turns `src\fonteditor\font.json` into `FONT12.bin` (Hangul) and `FONT6X10.bin` (English), and cc65 turns `driver.s` into `K-HANGEUL.bin`.
   2. It builds `TYPE`, `TYPEC`, `STYPE` and `STYPEC`.
   3. `src\tools\mkdist.py` converts the sample text (`src\samples\utf8txt\`) to N-byte files, then puts the programs and samples on a copy of the blank DOS 3.3 disk (`disk\dos33blank.dsk`) to make `DIST\K-HANGEUL.DSK`.
2. It copies `DIST\K-HANGEUL.DSK` to `disk\K-HANGEUL.DSK`.

If the last line says `disk\K-HANGEUL.DSK is ready`, the build worked. On failure it prints `BUILD FAILED`; the cause is in the messages above it.

### 2-8. Check the result

```
C:\bin\acx.exe -l disk\K-HANGEUL.DSK
```

You should see `HELLO`, `K-HANGEUL`, `FONT12`, `FONT6X10`, `TYPE`, `TYPEC`, `STYPE`, `STYPEC` and the sample files. Put the disk in an emulator (Apple II Plus, 16K language card, drive 1) and boot it: the banner appears, then the `]` prompt. See `docs\MANUAL_en.md` for how to use it.

| what is made | where |
|---|---|
| the finished disk | `disk\K-HANGEUL.DSK` |
| for ordinary users: only a copy of the disk and the user manual (`MANUAL.md`, `MANUAL_en.md`) | `DIST\` (rebuilt every time, not committed) |
| the intermediate files of each program | `src\<folder>\build\` (not committed) |


## 3. Common tasks

**Change the font.** Run `src\fonteditor\run_editor.bat`, edit `font.json`, then run `build.bat` again.

**Change the driver.** Edit `src\driver\driver.s` and `defs.inc`, then run `build.bat`. Do not patch the binaries: the source is assembly.

**Change the sample text.** Edit the UTF-8 files in `src\samples\utf8txt\`, then run `build.bat` (see `src\samples\README.md`).

**Build one program only.** Run `build.bat` or `make` inside its folder, for example `cd src\driver` and then `build.bat`. The result goes to that folder's `build\`. To get a disk, use the top-level `build.bat`.

**Remove the build output.** `clean.bat` (or `build.bat clean`) removes every `src\<folder>\build\` (object files and program files), the Python caches, and the contents of `DIST\`. It keeps `disk\K-HANGEUL.DSK` and all source. It needs neither GNU make nor cc65.

**Speed tests (optional).** See `tools\perf\README.md`. They need `py65`, so install `requirements.txt` into the virtual environment from step 2-5.


## 4. If something goes wrong

| symptom | cause and fix |
|---|---|
| `cannot write ...K-HANGEUL.DSK: another program (an emulator?) has it open` | An emulator has the disk open. Close it and run again. |
| `missing ...: build the programs first` | An earlier assemble step failed. Read the cc65 error above it. |
| `ca65.exe` or `ld65.exe` not found | Fix the `CC65` path (step 2-6). |
| `acx failed` or `acx.exe` not found | Fix the `ACX` path (step 2-6). |
| `'py' is not recognized...` | The Python launcher is missing. Install Python from python.org and keep the "py launcher" option. |
| the font editor says `No module named tkinter` | Reinstall Python as in step 2-4 and tick **tcl/tk and IDLE**. |
| only `BUILD FAILED` is visible | Look for the first error message above it. The last line is only a summary. |
