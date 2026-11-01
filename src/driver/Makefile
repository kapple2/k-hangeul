# K-HANGEUL driver: make [all|disk|clean]
#   all    build/K-HANGEUL.bin (the driver, BRUN address $0F94), build/FONT12.bin (Hangul font, loaded at $6000) and build/FONT6X10.bin (English font, loaded at $7200)
#   disk   all, then copy both files and HELLO to the project disk
# Three assemblies of the same source (see ../../docs/MEMORY_LAYOUT.md, the Saturn section):
#   build-stock/  SATLOAD=0 SATURN=0  the stock driver and loader: the regression baseline, not shipped
#   build-sat/    SATLOAD=1 SATURN=1  the Saturn arrangement: only compared with build/, not shipped
#   build/        SATLOAD=1 SATURN=0  the shipped driver. ../tools/satpack.py then writes the differences from build-sat/
#                                     into its last bytes, which the loader applies when it finds a Saturn card
# Change CC65, ACX, PYTHON or DISK on the command line if your tools are elsewhere.
CC65     ?= D:/opt/devtools/asm/cc65/bin
ACX      ?= C:/bin/acx.exe
PYTHON   ?= py -3
FONTJSON ?= ../fonteditor/font.json
DISK     ?= ../../disk/NEWHANGEUL.DSK

CA65 = $(CC65)/ca65.exe
LD65 = $(CC65)/ld65.exe
SRC  = driver.s defs.inc build/jungclass.inc build/version.inc

all: build/K-HANGEUL.bin build/FONT12.bin build/FONT6X10.bin build-stock/K-HANGEUL.bin

build/FONT12.bin build/FONT6X10.bin build/jungclass.inc: $(FONTJSON) fontgen.py
	$(PYTHON) fontgen.py $(FONTJSON) build

build/version.inc: ../../VERSION ../tools/mkversion.py
	$(PYTHON) ../tools/mkversion.py ../../VERSION $@

build-stock/K-HANGEUL.bin: $(SRC) driver.cfg
	mkdir -p build-stock
	$(CA65) -t none -I build -l build-stock/driver.lst -o build-stock/driver.o driver.s
	$(LD65) -C driver.cfg -m build-stock/driver.map -Ln build-stock/driver.lbl -o $@ build-stock/driver.o

build-sat/K-HANGEUL.bin: $(SRC) driver_sat.cfg
	mkdir -p build-sat
	$(CA65) -t none -D SATLOAD=1 -D SATURN=1 -I build -l build-sat/driver.lst -o build-sat/driver.o driver.s
	$(LD65) -C driver_sat.cfg -m build-sat/driver.map -Ln build-sat/driver.lbl -o $@ build-sat/driver.o

build/K-HANGEUL.bin: $(SRC) driver.cfg build-sat/K-HANGEUL.bin ../tools/satpack.py
	$(CA65) -t none -D SATLOAD=1 -I build -l build/driver.lst -o build/driver.o driver.s
	$(LD65) -C driver.cfg -m build/driver.map -Ln build/driver.lbl -o $@ build/driver.o
	$(PYTHON) ../tools/satpack.py build build-sat

disk: all
	-$(ACX) -d $(DISK) FONT12
	$(ACX) -p $(DISK) FONT12 bin 0x6000 < build/FONT12.bin
	-$(ACX) -d $(DISK) NEWHANGEUL
	-$(ACX) -d $(DISK) FONT6X10
	$(ACX) -p $(DISK) FONT6X10 bin 0x7200 < build/FONT6X10.bin
	-$(ACX) -d $(DISK) K-HANGEUL
	$(ACX) -p $(DISK) K-HANGEUL bin 0x0F94 < build/K-HANGEUL.bin
	-$(ACX) -d $(DISK) HELLO
	$(ACX) -bas $(DISK) HELLO < hello.bas

clean:
	$(PYTHON) -c "import shutil; [shutil.rmtree(d, ignore_errors=True) for d in ('build', 'build-sat', 'build-stock')]"

.PHONY: all disk clean
