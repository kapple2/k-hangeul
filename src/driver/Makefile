# K-HANGEUL driver: make [all|disk|clean]
#   all    build/K-HANGEUL.bin (the driver, BRUN address $0F94), build/FONT12.bin (Hangul font, loaded at $6000) and build/FONT6X10.bin (English font, loaded at $7200)
#   disk   all, then copy both files and HELLO to the project disk
# Change CC65, ACX, PYTHON or DISK on the command line if your tools are elsewhere.
CC65     ?= D:/opt/devtools/asm/cc65/bin
ACX      ?= C:/bin/acx.exe
PYTHON   ?= py -3
FONTJSON ?= ../fonteditor/font.json
DISK     ?= ../../disk/NEWHANGEUL.DSK

CA65 = $(CC65)/ca65.exe
LD65 = $(CC65)/ld65.exe

all: build/K-HANGEUL.bin build/FONT12.bin build/FONT6X10.bin

build/FONT12.bin build/FONT6X10.bin build/jungclass.inc: $(FONTJSON) fontgen.py
	$(PYTHON) fontgen.py $(FONTJSON) build

build/driver.o: driver.s defs.inc build/jungclass.inc
	$(CA65) -t none -I build -l build/driver.lst -o $@ driver.s

build/K-HANGEUL.bin: build/driver.o driver.cfg
	$(LD65) -C driver.cfg -m build/driver.map -Ln build/driver.lbl -o $@ build/driver.o

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
	$(PYTHON) -c "import shutil; shutil.rmtree('build', ignore_errors=True)"

.PHONY: all disk clean
