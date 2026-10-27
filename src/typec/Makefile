# TYPEC (the command-line TYPE program): make [all|disk|clean]
#   all    build/TYPEC.bin, loaded at $8E00
#   disk   all, then copy TYPEC to the project disk
# Change CC65, ACX, PYTHON or DISK on the command line if your tools are elsewhere.
CC65   ?= D:/opt/devtools/asm/cc65/bin
ACX    ?= C:/bin/acx.exe
PYTHON ?= py -3
DISK   ?= ../../disk/NEWHANGEUL.DSK

CA65 = $(CC65)/ca65.exe
LD65 = $(CC65)/ld65.exe

all: build/TYPEC.bin

build:
	$(PYTHON) -c "import os; os.makedirs('build', exist_ok=True)"

# core.inc is shared with TYPE
build/typec.o: typec.s ../type/core.inc | build
	$(CA65) -t none -I ../type -l build/typec.lst -o $@ typec.s

build/TYPEC.bin: build/typec.o typec.cfg
	$(LD65) -C typec.cfg -m build/typec.map -o $@ build/typec.o

disk: all
	-$(ACX) -d $(DISK) TYPEC
	$(ACX) -p $(DISK) TYPEC bin 0x8E00 < build/TYPEC.bin

clean:
	$(PYTHON) -c "import shutil; shutil.rmtree('build', ignore_errors=True)"

.PHONY: all disk clean
