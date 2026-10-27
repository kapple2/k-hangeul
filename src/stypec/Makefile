# STYPEC (the command-line STYPE): make [all|disk|clean]
#   all    build/STYPEC.bin, loaded at $8A00
#   disk   all, then copy STYPEC to the project disk
# core.inc (the file reader) is shared with TYPE (../type); score.inc (the strip rendering) with STYPE (../stype).
# Change CC65, ACX, PYTHON or DISK on the command line if your tools are elsewhere.
CC65   ?= D:/opt/devtools/asm/cc65/bin
ACX    ?= C:/bin/acx.exe
PYTHON ?= py -3
DISK   ?= ../../disk/NEWHANGEUL.DSK

CA65 = $(CC65)/ca65.exe
LD65 = $(CC65)/ld65.exe

all: build/STYPEC.bin

build:
	$(PYTHON) -c "import os; os.makedirs('build', exist_ok=True)"

build/stypec.o: stypec.s ../stype/score.inc ../type/core.inc | build
	$(CA65) -t none -I ../stype -I ../type -l build/stypec.lst -o $@ stypec.s

build/STYPEC.bin: build/stypec.o stypec.cfg
	$(LD65) -C stypec.cfg -m build/stypec.map -o $@ build/stypec.o

disk: all
	-$(ACX) -d $(DISK) STYPEC
	$(ACX) -p $(DISK) STYPEC bin 0x8A00 < build/STYPEC.bin

clean:
	$(PYTHON) -c "import shutil; shutil.rmtree('build', ignore_errors=True)"

.PHONY: all disk clean
