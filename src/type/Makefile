# TYPE (the & command): make [all|disk|clean]
#   all    build/TYPE.bin, loaded at $8E00
#   disk   all, then copy TYPE, SAMPLEB, TYPEDEMO and STORYT to the project disk
# Change CC65, ACX, PYTHON or DISK on the command line if your tools are elsewhere.
CC65   ?= D:/opt/devtools/asm/cc65/bin
ACX    ?= C:/bin/acx.exe
PYTHON ?= py -3
DISK   ?= ../../disk/NEWHANGEUL.DSK

CA65 = $(CC65)/ca65.exe
LD65 = $(CC65)/ld65.exe

all: build/TYPE.bin

build:
	$(PYTHON) -c "import os; os.makedirs('build', exist_ok=True)"

build/type.o: type.s core.inc | build
	$(CA65) -t none -I . -l build/type.lst -o $@ type.s

build/TYPE.bin: build/type.o type.cfg
	$(LD65) -C type.cfg -m build/type.map -o $@ build/type.o

disk: all
	-$(ACX) -d $(DISK) TYPE
	$(ACX) -p $(DISK) TYPE bin 0x8E00 < build/TYPE.bin
	-$(ACX) -d $(DISK) SAMPLEB
	$(ACX) -p $(DISK) SAMPLEB bin 0x8000 < sampleb.bin
	-$(ACX) -d $(DISK) TYPEDEMO
	$(ACX) -bas $(DISK) TYPEDEMO < typedemo.bas
	-$(ACX) -d $(DISK) STORYT
	$(ACX) -bas $(DISK) STORYT < storyt.bas

clean:
	$(PYTHON) -c "import shutil; shutil.rmtree('build', ignore_errors=True)"

.PHONY: all disk clean
