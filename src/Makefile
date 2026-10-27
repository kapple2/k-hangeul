# Build everything into ..\DIST: make [all|clean]
#   builds the driver, TYPE, TYPEC, STYPE and STYPEC from assembly, then DIST\K-HANGEUL.DSK, bin\ and docs\.
# Change CC65, ACX or PYTHON on the command line if your tools are elsewhere.
CC65   ?= D:/opt/devtools/asm/cc65/bin
ACX    ?= C:/bin/acx.exe
PYTHON ?= py -3
SUB     = CC65=$(CC65) ACX=$(ACX) PYTHON="$(PYTHON)"

all: programs
	$(PYTHON) tools/mkdist.py .. $(ACX)

programs:
	$(MAKE) -C driver $(SUB)
	$(MAKE) -C type $(SUB)
	$(MAKE) -C typec $(SUB)
	$(MAKE) -C stype $(SUB)
	$(MAKE) -C stypec $(SUB)

clean:
	$(MAKE) -C driver clean $(SUB)
	$(MAKE) -C type clean $(SUB)
	$(MAKE) -C typec clean $(SUB)
	$(MAKE) -C stype clean $(SUB)
	$(MAKE) -C stypec clean $(SUB)
	$(PYTHON) -c "import shutil; shutil.rmtree('../DIST', ignore_errors=True)"

.PHONY: all programs clean
