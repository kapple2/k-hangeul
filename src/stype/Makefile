# STYPE (the & command with smooth rows): make [all|disk|clean]
#   all    build/STYPE.bin, loaded at $8A00
#   disk   all, then copy STYPE and the STYPEDEMO program to the project disk
# core.inc (the file reader) is shared with TYPE and lives in ../type.
# Change CC65, ACX, PYTHON or DISK on the command line if your tools are elsewhere.
CC65   ?= D:/opt/devtools/asm/cc65/bin
ACX    ?= C:/bin/acx.exe
PYTHON ?= py -3
DISK   ?= ../../disk/NEWHANGEUL.DSK

CA65 = $(CC65)/ca65.exe
LD65 = $(CC65)/ld65.exe

all: build/STYPE.bin

build:
	$(PYTHON) -c "import os; os.makedirs('build', exist_ok=True)"

build/stype.o: stype.s score.inc ../type/core.inc | build
	$(CA65) -t none -I . -I ../type -l build/stype.lst -o $@ stype.s

build/STYPE.bin: build/stype.o stype.cfg
	$(LD65) -C stype.cfg -m build/stype.map -o $@ build/stype.o

disk: all
	-$(ACX) -d $(DISK) STYPE
	$(ACX) -p $(DISK) STYPE bin 0x8A00 < build/STYPE.bin
	-$(ACX) -d $(DISK) STYPEDEMO
	$(ACX) -bas $(DISK) STYPEDEMO < stypedemo.bas

clean:
	$(PYTHON) -c "import shutil; shutil.rmtree('build', ignore_errors=True)"

.PHONY: all disk clean
