; Names for zero page, I/O, ROM, the driver's main RAM variables and its state.

; SATURN = 0 builds the stock driver (this is the build that is shipped). SATURN = 1 is for the Saturn 128KB card
; arrangement (see docs/MEMORY_LAYOUT.md, draft). Nothing in the source tests it yet, so both give the same output.
; Set it from the command line with  ca65 -D SATURN=1 ...  (build.bat sat does this).
; SATLOAD = 1 makes the loader look for a Saturn card and, if there is one, patch the driver for it (the patch list is
; appended to the file by tools/satpack.py). SATLOAD = 0 is the stock loader (build-stock, the regression baseline).
.ifndef SATLOAD
SATLOAD = 0
.endif
.ifndef SATURN
SATURN = 0
.endif
SATSELK = $C08F                 ; the switch that selects the K-HANGEUL bank: bank 7 (the top bank of a 128KB Saturn). $C084+n for banks 0-3, $C088+n for 4-7

P0L = $0000
P0H = $0001
P1L = $0002
P1H = $0003
P2L = $0004
P2H = $0005
WNDLFT = $0020
WNDWDTH = $0021
WNDTOP = $0022
WNDBTM = $0023
CH = $0024
CV = $0025
BASL = $0028
BASH = $0029
INVFLG = $0032
PROMPTCH = $0033
CSWL = $0036
CSWH = $0037
KSWL = $0038
KSWH = $0039
TXTTAB = $0067
VARTAB = $0069
FRETOP = $006F
HIMEMZ = $0073
INBUF = $0200
; The text buffer, the row flags and the variables. Stock: in main RAM under the screen. Saturn: in the bank, in the page the
; driver runs in (the driver then runs with the card write enabled). GLY and GLYHI are in $E000-$FFFF because they are written
; while the other $D000 page is selected. BELL (a routine that calls the ROM), SHMACH and NOPR stay in main RAM for now.
.if SATURN
BUF = $DC2A                     ; 736 bytes, 16 rows of 46; right behind the packed English font
FLAGS = BUF + $2E0              ; 32 bytes
VARB = $DF2A                    ; 64 bytes: the stock variables $1C80-$1CBF
BLITB = $DF6A                   ; 11 bytes: the stock blit variables $1FF0-$1FFA
GLY = $E000 + SATTAIL - 24
GLYHI = GLY + 12
.else
BUF = $1980
FLAGS = $1C60
VARB = $1C80
BLITB = $1FF0
GLY = $1C90
GLYHI = $1C9C
.endif
C = VARB + 6
V = VARB + 7
T = VARB + 8
CL = VARB + 9
TMP = VARB + 10
SUMLO = VARB + 11
SUMHI = VARB + 12
IDX = VARB + 13
MODE = VARB + $28
BOFF = VARB + $29
TMP2 = VARB + $2A
HIBIT = VARB + $2B
MASKV = VARB + $2C
PIXON = VARB + $2D
OLD = VARB + $2E
COUNT = VARB + $2F
BELL = $1CB0
MODESAVE = VARB + $3A
MODECAP = VARB + $3B
CASEMODE = VARB + $3C
M0 = BLITB
M1 = BLITB + 1
M2 = BLITB + 2
NM0 = BLITB + 3
NM1 = BLITB + 4
NM2 = BLITB + 5
NB = BLITB + 6
TV = BLITB + 7
ROWI = BLITB + 8
IXL = BLITB + 9
IXH = BLITB + 10
NOPR = NOPRA
.if SATURN
NOPRA = BLITB + 11
.else
NOPRA = $1FFB
.endif
KBD = $C000
KBDSTRB = $C010
SPKR = $C030
TXTCLR = $C050
TXTSET = $C051
MIXCLR = $C052
MIXSET = $C053
LOWSCR = $C054
HISCR = $C055
LORES = $C056
HIRES = $C057
LCRAMRD = $C080
LCROMWR = $C081
LCROMRD = $C082
LCRAMRW = $C083
LCRAMRD2 = $C088
LCRAMRW2 = $C08B
MON_BELL1 = $FBDD
MON_HOME = $FC58
MON_RDKEY = $FD0C
MON_KEYIN = $FD1B
MON_GETLN = $FD6A
MON_CROUT = $FD8E
MON_COUT = $FDED
MON_COUT1 = $FDF0

STATEBASE = $9400
S_0450 = $9400            ; was $0450 in the text page
S_045A = $940A            ; was $045A in the text page
S_0464 = $9414            ; was $0464 in the text page
S_046E = $941E            ; was $046E in the text page
S_0470 = $9420            ; was $0470 in the text page
S_04D0 = $9428            ; was $04D0 in the text page
S_04D1 = $9429            ; was $04D1 in the text page
S_04D2 = $942A            ; was $04D2 in the text page
S_04D3 = $942B            ; was $04D3 in the text page
S_04D4 = $942C            ; was $04D4 in the text page
S_04D5 = $942D            ; was $04D5 in the text page
S_04D6 = $942E            ; was $04D6 in the text page
S_04D7 = $942F            ; was $04D7 in the text page
S_04D8 = $9430            ; was $04D8 in the text page
S_04DA = $9432            ; was $04DA in the text page
S_04DB = $9433            ; was $04DB in the text page
S_04DC = $9434            ; was $04DC in the text page
S_04DE = $9436            ; was $04DE in the text page
S_04E2 = $943A            ; was $04E2 in the text page
S_04E3 = $943B            ; was $04E3 in the text page
S_0550 = $9450            ; was $0550 in the text page
S_0551 = $9451            ; was $0551 in the text page
S_0552 = $9452            ; was $0552 in the text page
S_0553 = $9453            ; was $0553 in the text page
S_0554 = $9454            ; was $0554 in the text page
S_0555 = $9455            ; was $0555 in the text page
S_0556 = $9456            ; was $0556 in the text page
S_0557 = $9457            ; was $0557 in the text page
S_0558 = $9458            ; was $0558 in the text page
S_0559 = $9459            ; was $0559 in the text page
S_055A = $945A            ; was $055A in the text page
S_055B = $945B            ; was $055B in the text page
S_055C = $945C            ; was $055C in the text page
S_055E = $945E            ; was $055E in the text page
S_0563 = $9463            ; was $0563 in the text page
S_0564 = $9464            ; was $0564 in the text page
S_0565 = $9465            ; was $0565 in the text page
S_0566 = $9466            ; was $0566 in the text page
S_0567 = $9467            ; was $0567 in the text page
S_0577 = $9477            ; was $0577 in the text page
S_05D0 = $9580            ; was $05D0: 46 bytes (one per column), moved clear of the other state
S_065B = $9488            ; was $065B in the text page
S_065C = $9489            ; was $065C in the text page
S_065D = $948A            ; was $065D in the text page
S_0663 = $9490            ; was $0663 in the text page
S_0664 = $9491            ; was $0664 in the text page
S_0665 = $9492            ; was $0665 in the text page
S_0666 = $9493            ; was $0666 in the text page
S_0667 = $9494            ; was $0667 in the text page
S_0668 = $9495            ; was $0668 in the text page
S_0669 = $9496            ; was $0669 in the text page
S_066A = $9497            ; was $066A in the text page
S_066B = $9498            ; was $066B in the text page
S_066C = $9499            ; was $066C in the text page
S_06A8 = $949D            ; was $06A8 in the text page
LEAD = $949E            ; was $06A9 in the text page
TRAIL = $949F            ; was $06AA in the text page
CHOI = $94A0            ; was $06AB in the text page
JUNGI = $94A1            ; was $06AC in the text page
JONGI = $94A2            ; was $06AD in the text page
S_06AE = $94A3            ; was $06AE in the text page
S_06AF = $94A4            ; was $06AF in the text page
S_06B0 = $94A5            ; was $06B0 in the text page
CURKEY = $94A6            ; was $06B1 in the text page
STATE = $94A7            ; was $06B2 in the text page
CHO = $94A8            ; was $06B3 in the text page
JONG = $94A9            ; was $06B4 in the text page
JONG2 = $94AA            ; was $06B5 in the text page
JUNG = $94AB            ; was $06B6 in the text page
HMODE = $94AC            ; was $06B7 in the text page
CHAR = $94AD            ; was $06B8 in the text page
PENDING = $94AE            ; was $06B9 in the text page
S_06BA = $94AF            ; was $06BA in the text page
S_06BB = $94B0            ; was $06BB in the text page
S_06C2 = $94B7            ; was $06C2 in the text page
S_06C3 = $94B8            ; was $06C3 in the text page
S_06C4 = $94B9            ; was $06C4 in the text page
S_06C5 = $94BA            ; was $06C5 in the text page
S_06C6 = $94BB            ; was $06C6 in the text page
S_06C7 = $94BC            ; was $06C7 in the text page
S_06D0 = $95AE            ; was $06D0: 46 bytes (one per column)
S_0728 = $94C9            ; was $0728 in the text page
S_0750 = $94F1            ; was $0750 in the text page
S_0751 = $94F2            ; was $0751 in the text page
S_0759 = $94FA            ; was $0759 in the text page
S_075F = $9500            ; was $075F in the text page
S_0761 = $9502            ; was $0761 in the text page
S_0769 = $950A            ; was $0769 in the text page
S_076F = $9510            ; was $076F in the text page
S_077F = $9520            ; was $077F in the text page
S_07A8 = $9549            ; was $07A8 in the text page
S_07D0 = $9571            ; was $07D0 in the text page
S_07DA = $957B            ; was $07DA in the text page
S_07DB = $957C            ; was $07DB in the text page
S_07DC = $957D            ; was $07DC in the text page
S_0569 = $9469            ; was $0569 in the text page
S_0568 = $9468            ; was $0568 in the text page
S_056A = $946A            ; was $056A in the text page
S_04D9 = $9431            ; was $04D9 in the text page
S_04E8 = $9440            ; was $04E8 in the text page
S_055F = $945F            ; was $055F in the text page
S_0560 = $9460            ; was $0560 in the text page
S_055D = $945D            ; was $055D in the text page
S_0561 = $9461            ; was $0561 in the text page
S_0562 = $9462            ; was $0562 in the text page
S_056C = $946C            ; was $056C in the text page
S_056E = $946E            ; was $056E in the text page
S_056D = $946D            ; was $056D in the text page
S_056F = $946F            ; was $056F in the text page
S_04DD = $9435            ; was $04DD in the text page
S_06BC = $94B1            ; was $06BC in the text page
S_06BE = $94B3            ; was $06BE in the text page
S_06BF = $94B4            ; was $06BF in the text page
S_056B = $946B            ; was $056B in the text page
ENGSRC = $7200            ; where HELLO loads FONT6X10, 2048 bytes
SW2 = $C063                ; pushbutton 2: the Shift key mod (bit 7 set while Shift is held)
SHMACHL = $1CBD            ; bit 7 set on an Apple IIe, IIc or IIgs (ROM ID $FBB3 = $06), found by the loader; $1CBD-$1CBF were unused
.if SATURN
SHMACH = VARB + $3D          ; the loader copies it into the bank
.else
SHMACH = SHMACHL
.endif
OAPPLE = $C061             ; pushbutton 0 = Open-Apple on a IIe-family machine (bit 7 set while it is held)
SHIDLE = $95DC             ; bit 7 of $C063 at start-up (Shift not held); the state area is filled with $A0 before INIT sets it
STRIPF = $95DD             ; bit 6 set ($40) while the glyph drawing goes to the strip buffer (STYPE); 0 or $A0 otherwise
STRIPLO = $95DE            ; address of the strip buffer (set by STYPE)
STRIPHI = $95DF
STRIPVEC = $95E0           ; address of the routine called at the end of every row in strip mode (2 bytes)
STRIPSTRIDE = 42           ; bytes from one pixel row of the strip to the next (40 and room for a glyph's third byte)

; Saturn card, loader and driver (docs/MEMORY_LAYOUT.md, draft)
SATPROBE = $FFF9                ; a byte in every bank that the card detection saves, tags and restores
SATSIG   = $FFF5                ; 4 bytes: the K-HANGEUL signature "KHG1" in the K-HANGEUL bank (the image ends at $FFF4)
SATSELV  = $D3FF                ; the last byte of the zero padding at $D14F-$D3FF: the select switch of the K-HANGEUL bank, written by the loader
SATDATASIZE = 3072              ; room reserved at the end of the file for the patch lists

; The fonts. Stock: the Korean font is in main RAM at $0800 (24 bytes a glyph: 12 rows of low byte, high byte). Saturn: the
; Korean font is packed to 18 bytes a glyph (12 low bytes, then 6 bytes of two 4-bit high parts each) in the other $D000
; page of the bank, which is selected only while a glyph is read. The shift masks and the English font stay in the page the
; driver runs in. The English font is 10 bytes a glyph (stock: 16).
.if SATURN
FCHOB   = $D000                 ; first (initial consonant) glyph; 114 glyphs
FJUNGB  = $D804                 ; first vowel glyph; 42 glyphs
FJONGB  = $DAF8                 ; first final consonant glyph; 27 glyphs
FZEROG  = $DCDE                 ; the empty glyph (18 zero bytes)
FONTEND = $DCF0                 ; the end of the packed font
FMASK   = $D3D0                 ; the 42 shift mask bytes, in the zero padding of the driver page
SATTAIL = 96                    ; bytes at $E000-$E05F, the end of the old English font area, hold the glyph reading code
.else
FCHOB   = $0800
FJUNGB  = $12B0
FJONGB  = $16A0
FZEROG  = $1928
FMASK   = $1940
.endif

; Saturn, stage 3: the variables of the bank that the loader (assembled for any card) also has to know
SATVARB = $DF2A                 ; VARB of the Saturn arrangement: the loader (assembled for any card) writes the machine flag and the banner flag there
SHMACHB = SATVARB + $3D         ; the machine flag in the bank
SATBANOK = SATVARB + $3E        ; 1 while the start-up banner is still waiting to be shown
SATHAN  = $9481                 ; the HAN command's entry in main RAM (Saturn)
SATCATI = $9470                 ; the entry that DOS calls for CATALOG (CATINIT) (Saturn)
SATCATW = $9571                 ; the entry that DOS calls while CATALOG waits for a key (CATWAIT) (Saturn)
BANOK = SATBANOK
BELLDX = BELL
.if SATURN
BELLD = VARB + $30            ; INIT copies the stock bell image here; the real bell is SatBell
.else
BELLD = BELL                    ; stock: INIT copies the bell routine to $1CB0
.endif
SATREINIT = $D3FA                ; the frozen rebuild entry in the K-HANGEUL bank (page 2): jmp STATEINIT; $D3FD version $01, $D3FE magic $5A
