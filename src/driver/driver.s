; ===========================================================================
; K-HANGEUL: 12x12 Hangul on hi-res page 1 for the Apple II Plus (DOS 3.3).
;
; This is the source of K-HANGEUL.bin. It was made once from the binary that
; a legacy build script, not in this repository, produced from the stock Hangeul2 image, so
; the first build was byte-for-byte the old file. From here on, change this file,
; build, and test; do not patch the binary.
;
; Build:  build.bat   (or make)      Disk:  build.bat disk   (or make disk)
; Font:   font.json -> build/FONT12.bin and build/jungclass.inc, by fontgen.py.
;
; The file is a DOS binary, BRUN at $0F94, three segments (driver.cfg):
;   LOADER  $0F94  108 bytes. Copies LCIMG to $D000 in the language card, patches DOS, jumps to INIT.
;   LCIMG   $D000  the driver. The card is left "RAM read, write protected", so the driver
;                  cannot change its own code or hold variables; those live in main RAM.
;   BANNER  $1CC0  startup banner and the prompt and CATALOG helpers, under the hi-res screen.
;
; Main RAM used (see MEMORY_LAYOUT.md): $0800 font, $1980 text buffer, $1C60 row flags,
; $1C80 blit scratch, $1FF0 blit variables, $9400-$95FF the driver's stubs and variables
; (state; named S_xxxx, xxxx being the stock text-page address it replaced).
;
; Changes from stock Hangeul2: 46 x 16 window on hi-res page 1; faster blit, cursor and
; scroll; 6-pixel ASCII in ASCIIFONT; state moved out of the text page so HOME,
; TEXT and GR cannot hit it (HOMECK, canary at $0400); CATALOG paging (CATINIT, CATWAIT);
; prompt kept out of the typed line; startup banner.
;
; Names: labels without a prefix are routines or tables that existed in the generator or
; in the stock Hangeul2 listing. L_xxxx and D_xxxx are code and data at
; address xxxx that have no name yet; B_ marks the banner segment. Give them a name when
; you learn what they do. Code that nothing in the disassembly reaches (stock BASIC
; extension handlers, tables) is shown as .byte rows or as code, as found.
; ===========================================================================

.include "defs.inc"

.import __LCIMG_LOAD__, __LCIMG_SIZE__
.import __BANNER_LOAD__, __BANNER_RUN__, __BANNER_SIZE__

; ---------------------------------------------------------------------------
; Loader. DOS BRUN loads the whole file at $0F94 and starts here.
; It copies LCIMG (the driver, loaded at $1000) to $D000 in the language card,
; copies the 3-byte and 6-byte patches below into DOS 3.3 in RAM, and enters INIT.
; The patches are those of stock Hangeul2 and are described in DOS_PATCHES.md in this
; folder: they add the DOS command HAN, which runs "sta $C080 / jmp INIT" (it only
; works while the banner and font sources are still in memory, i.e. not after boot).
; ---------------------------------------------------------------------------
.segment "LOADER"
Loader:
        lda  LCROMWR                ; $C081 twice: language card RAM write enabled
        lda  LCROMWR
        lda  #<__LCIMG_LOAD__
        sta  $06
        lda  #>__LCIMG_LOAD__
        sta  $07
        lda  #$00
        sta  $08
        lda  #$D0                   ; destination $D000
        sta  $09
        lda  #>__LCIMG_SIZE__       ; byte count: high byte in $FF, low byte in X
        sta  $FF
        ldx  #<__LCIMG_SIZE__
        jsr  CopyBytes
        ldx  #$05
@patch1:
        lda  VecData,x              ; reset, NMI and IRQ vectors into $FFFA-$FFFF
        sta  $FFFA,x
        lda  DosPatch1,x            ; "sta $C080 / jmp INIT" into DOS at $A55B
        sta  $A55B,x
        dex
        bpl  @patch1
        ldx  #$02
@patch2:
        lda  DosPatch2,x            ; "HAN", a command name in DOS's table at $A8F1
        sta  $A8F1,x
        lda  DosPatch3,x            ; at $A59E: bne $A55B, so the command HAN runs DosPatch1
        sta  $A59E,x
        dex
        bpl  @patch2
        lda  LCRAMRW                ; $C083 twice: language card RAM read and write; INIT write protects it
        lda  LCRAMRW
        jmp  INIT
DosPatch1:                          ; copied into DOS: jmp HANMAIN (the HAN command), padded with NOPs
        .byte $4C,<HANMAIN,>HANMAIN,$EA,$EA,$EA
VecData:
        .byte $FB,$03,$5F,$FA,$38,$FA
DosPatch2:
        .byte $48,$41,$CE
DosPatch3:
        .byte $D0,$BB,$20

; copy X + 256 * ($FF - 1) bytes from ($06) to ($08)
CopyBytes:
        beq  @go
        inc  $FF
@go:
        ldy  #$00
@loop:
        lda  ($06),y
        sta  ($08),y
        iny
        bne  @next
        inc  $07
        inc  $09
@next:
        dex
        bne  @loop
        dec  $FF
        bne  @loop
        rts

.segment "LCIMG"
FREE_D000:                              ; was the English table; the table is ENGFONT now
; A row after the first of a typed line starts with the "]" mark that CHECK draws. FETCHLINE must not keep it
; in the line: start reading at column 1 when column 0 holds the mark. Keeps X and Y.
FIXCONT:
        tya
        pha
        ldy  #$00
        lda  (BASL),y
        ldy  #$00
        cmp  #$DD
        bne  @col
        iny
@col:
        sty  CH
        pla
        tay
        rts

; The Shift key mod (Shift wired to pushbutton 2, bit 7 of $C063): in Hangul mode, Shift+R E Q T W O P give the
; keys that the tables use for the double consonants and vowels: - = * < > ; +   (ㄲ ㄸ ㅃ ㅆ ㅉ ㅒ ㅖ).
; Called instead of "bit HMODE" where the editor gets a key: A is the key, and the flags are those of "bit HMODE"
; on return. The mod's polarity differs between machines and emulators (MAME: bit 7 is low while Shift is held),
; so INIT stores the level of $C063 at start-up (SHIDLE, Shift not held) and Shift is any change from it. Without
; the mod the input never changes and nothing happens.
SHFIX:
        bit  HMODE
        bpl  @out
        stx  P2H
        sta  P2L
        lda  SW2
        eor  SHIDLE                     ; differs from the level at start-up: Shift is held
        bpl  @back
        lda  P2L
        and  #$5F                       ; the letter, in capitals
        ldx  #$07
@look:
        cmp  SHKEYS,x
        beq  @hit
        dex
        bpl  @look
        bmi  @back
@hit:
        lda  SHREPL,x
        sta  P2L
@back:
        lda  P2L
        ldx  P2H
        bit  HMODE
@out:
        rts
; The key read for the line editor (GETLN, GET): the keys come back here, not through L_E7F9.
; End of a typed line (FETCHLINE): if a Hangul run (Ctrl-K ...) is still open, add the closing Ctrl-A ($81) before
; the CR, as is done when text follows the run. Without it an INPUT answer typed in Hangul has no Ctrl-A and
; printing it leaves Hangul mode on. X is the buffer index. Same as the code at L_E70C.
CLOSERUN:
        bit  S_0665
        bpl  @cr
        lda  #$81
        sta  INBUF,x
        inx
        lsr  S_0665
@cr:
        lda  #$8D
        sta  INBUF,x
        rts
; ---------------------------------------------------------------------------
; Strip mode, for the STYPE and STYPEC programs: smooth rendering of one text row.
; While bit 6 of STRIPF is set ($40; the state page is filled with $A0 at start, which is "off") the glyph drawing writes the 12 pixel rows of the current text row into a buffer
; in main RAM (rows 42 bytes apart, address in STRIPLO/STRIPHI) instead of the screen. STYPE shows the
; buffer on the screen one pixel row at a time. At the end of every row (a carriage return or the wrap
; at the right edge: the code at L_EC9A) the routine whose address is in STRIPVEC is called first.
; ---------------------------------------------------------------------------
LINEX:
        bit  STRIPF
        bvc  @screen
        lda  STRIPLO
        sta  $26
        lda  STRIPHI
        sta  $27
        rts
@screen:
        lda  HGRLO,x
        sta  $26
        lda  HGRHI,x
        ora  $E6
        sta  $27
        rts
NEXTROW:
        bit  STRIPF
        bvc  @screen
        lda  $26
        clc
        adc  #STRIPSTRIDE
        sta  $26
        bcc  @done
        inc  $27
@done:
        rts
@screen:
        jmp  L_F367
NLHOOK:
        bit  STRIPF
        bvc  @go
        txa
        pha
        tya
        pha
        jsr  CALLSTRIP
        pla
        tay
        pla
        tax
@go:
        inc  CV
        lda  CV
        rts
CALLSTRIP:
        jmp  (STRIPVEC)
SHFIN:
        jsr  SHFIX
        jmp  L_EAEB
SHKEYS:
        .byte $52,$45,$51,$54,$57,$4F,$50,$40   ; R E Q T W O P, and @ (an Apple II Plus keyboard gives @ for Shift+P)
SHREPL:
        .byte $AD,$BD,$AA,$BC,$BE,$BB,$AB,$AB   ; - = * < > ; + +  (high bit set, as a key arrives)
        .res 1024-(*-FREE_D000)

; ==========================================================================
; Hi-res drawing: blit a 12x12 glyph, cursor, inverse, scroll, case mode
; ==========================================================================
BLIT:
        jsr  SETUPX                 ; D400  20 B7 ED
        lda  #$00                   ; D403  A9 00
        sta  MODE                   ; D405  8D A8 1C
        bit  S_06AF                 ; D408  2C A4 94
        bpl  BL1                    ; D40B  10 05
        lda  #$01                   ; D40D  A9 01
        sta  MODE                   ; D40F  8D A8 1C
BL1:
        jsr  INVALL                 ; D412  20 08 D5
BLITGO:
        jsr  PSETUP                 ; D415  20 59 FE
        lda  CV                     ; D418  A5 25
        jsr  MUL12                  ; D41A  20 93 F1
        clc                         ; D41D  18
        adc  S_06AE                 ; D41E  6D A3 94
        tax                         ; D421  AA
        jsr  LINEX                  ; was jsr LINE (strip mode, see STYPE)
        jsr  ADDOFF                 ; D425  20 AB F2
        lda  #$00                   ; D428  A9 00
        sta  ROWI                   ; D42A  8D F8 1F
BL2:
        ldx  ROWI                   ; D42D  AE F8 1F
        lda  GLY,x                  ; D430  BD 90 1C
        sta  $06                    ; D433  85 06
        lda  GLYHI,x                ; D435  BD 9C 1C
        sta  $07                    ; D438  85 07
        lda  #$00                   ; D43A  A9 00
        sta  $08                    ; D43C  85 08
        ldx  P1H                    ; D43E  A6 03
        beq  BS0                    ; D440  F0 09
BSH:
        asl  $06                    ; D442  06 06
        rol  $07                    ; D444  26 07
        rol  $08                    ; D446  26 08
        dex                         ; D448  CA
        bne  BSH                    ; D449  D0 F7
BS0:
        ldy  #$00                   ; D44B  A0 00
        lda  $06                    ; D44D  A5 06
        and  M0                     ; D44F  2D F0 1F
        sta  TV                     ; D452  8D F7 1F
        lda  ($26),y                ; D455  B1 26
        and  NM0                    ; D457  2D F3 1F
        ora  TV                     ; D45A  0D F7 1F
        sta  ($26),y                ; D45D  91 26
        ldx  NB                     ; D45F  AE F6 1F
        cpx  #$02                   ; D462  E0 02
        bcc  BND                    ; D464  90 36
        lda  $06                    ; D466  A5 06
        asl  a                      ; D468  0A
        lda  $07                    ; D469  A5 07
        rol  a                      ; D46B  2A
        and  M1                     ; D46C  2D F1 1F
        sta  TV                     ; D46F  8D F7 1F
        iny                         ; D472  C8
        lda  ($26),y                ; D473  B1 26
        and  NM1                    ; D475  2D F4 1F
        ora  TV                     ; D478  0D F7 1F
        sta  ($26),y                ; D47B  91 26
        cpx  #$03                   ; D47D  E0 03
        bcc  BND                    ; D47F  90 1B
        lda  $07                    ; D481  A5 07
        asl  a                      ; D483  0A
        rol  $08                    ; D484  26 08
        asl  a                      ; D486  0A
        rol  $08                    ; D487  26 08
        lda  $08                    ; D489  A5 08
        and  M2                     ; D48B  2D F2 1F
        sta  TV                     ; D48E  8D F7 1F
        iny                         ; D491  C8
        lda  ($26),y                ; D492  B1 26
        and  NM2                    ; D494  2D F5 1F
        ora  TV                     ; D497  0D F7 1F
        sta  ($26),y                ; D49A  91 26
BND:
        jsr  NEXTROW                ; was jsr L_F367
        inc  ROWI                   ; D49F  EE F8 1F
        lda  ROWI                   ; D4A2  AD F8 1F
        cmp  #$0C                   ; D4A5  C9 0C
        beq  BL9                    ; D4A7  F0 03
        jmp  BL2                    ; D4A9  4C 2D D4
BL9:
        rts                         ; D4AC  60
CURSOR:
        ldy  CH                     ; D4AD  A4 24
        lda  (BASL),y               ; D4AF  B1 28
        bmi  CU6                    ; D4B1  30 04
        lda  #$0C                   ; D4B3  A9 0C
        bne  CUW                    ; D4B5  D0 02
CU6:
        lda  #$06                   ; D4B7  A9 06
CUW:
        sta  P1L                    ; D4B9  85 02
        lda  #$00                   ; D4BB  A9 00
        sta  MODE                   ; D4BD  8D A8 1C
        jsr  SETUPX                 ; D4C0  20 B7 ED
        jsr  PSETUP                 ; D4C3  20 59 FE
        lda  CV                     ; D4C6  A5 25
        jsr  MUL12                  ; D4C8  20 93 F1
        clc                         ; D4CB  18
        adc  S_06AE                 ; D4CC  6D A3 94
        tax                         ; D4CF  AA
        jsr  LINEX                  ; was jsr LINE
        jsr  ADDOFF                 ; D4D3  20 AB F2
        lda  #$0C                   ; D4D6  A9 0C
        sta  ROWI                   ; D4D8  8D F8 1F
CU3:
        ldy  #$00                   ; D4DB  A0 00
        lda  ($26),y                ; D4DD  B1 26
        eor  M0                     ; D4DF  4D F0 1F
        sta  ($26),y                ; D4E2  91 26
        ldx  NB                     ; D4E4  AE F6 1F
        cpx  #$02                   ; D4E7  E0 02
        bcc  CU4                    ; D4E9  90 14
        iny                         ; D4EB  C8
        lda  ($26),y                ; D4EC  B1 26
        eor  M1                     ; D4EE  4D F1 1F
        sta  ($26),y                ; D4F1  91 26
        cpx  #$03                   ; D4F3  E0 03
        bcc  CU4                    ; D4F5  90 08
        iny                         ; D4F7  C8
        lda  ($26),y                ; D4F8  B1 26
        eor  M2                     ; D4FA  4D F2 1F
        sta  ($26),y                ; D4FD  91 26
CU4:
        jsr  NEXTROW                ; was jsr L_F367
        dec  ROWI                   ; D502  CE F8 1F
        bne  CU3                    ; D505  D0 D4
        rts                         ; D507  60
INVALL:
        lda  S_066B                 ; D508  AD 98 94
        beq  IV9                    ; D50B  F0 2B
        ldy  #$3F                   ; D50D  A0 3F
        lda  #$00                   ; D50F  A9 00
        ldx  P1L                    ; D511  A6 02
        cpx  #$0C                   ; D513  E0 0C
        bne  IVS                    ; D515  D0 04
        ldy  #$FF                   ; D517  A0 FF
        lda  #$0F                   ; D519  A9 0F
IVS:
        sty  IXL                    ; D51B  8C F9 1F
        sta  IXH                    ; D51E  8D FA 1F
        ldx  #$0B                   ; D521  A2 0B
IVL:
        lda  GLY,x                  ; D523  BD 90 1C
        eor  IXL                    ; D526  4D F9 1F
        sta  GLY,x                  ; D529  9D 90 1C
        lda  GLYHI,x                ; D52C  BD 9C 1C
        eor  IXH                    ; D52F  4D FA 1F
        sta  GLYHI,x                ; D532  9D 9C 1C
        dex                         ; D535  CA
        bpl  IVL                    ; D536  10 EB
IV9:
        rts                         ; D538  60
SET2A:
        tax                         ; D539  AA
        lda  HGRLO,x                ; D53A  BD DC E0
        sta  $2A                    ; D53D  85 2A
        lda  HGRHI,x                ; D53F  BD 9C E1
        ora  $E6                    ; D542  05 E6
        sta  $2B                    ; D544  85 2B
        rts                         ; D546  60
SETFC:
        lda  HGRLO,x                ; D547  BD DC E0
        sta  $FC                    ; D54A  85 FC
        lda  HGRHI,x                ; D54C  BD 9C E1
        ora  $E6                    ; D54F  05 E6
        sta  $FD                    ; D551  85 FD
        rts                         ; D553  60
C40:
        ldy  #$00                   ; D554  A0 00
C41:
        lda  ($2A),y                ; D556  B1 2A
        sta  ($FC),y                ; D558  91 FC
        iny                         ; D55A  C8
        lda  ($2A),y                ; D55B  B1 2A
        sta  ($FC),y                ; D55D  91 FC
        iny                         ; D55F  C8
        lda  ($2A),y                ; D560  B1 2A
        sta  ($FC),y                ; D562  91 FC
        iny                         ; D564  C8
        lda  ($2A),y                ; D565  B1 2A
        sta  ($FC),y                ; D567  91 FC
        iny                         ; D569  C8
        lda  ($2A),y                ; D56A  B1 2A
        sta  ($FC),y                ; D56C  91 FC
        iny                         ; D56E  C8
        lda  ($2A),y                ; D56F  B1 2A
        sta  ($FC),y                ; D571  91 FC
        iny                         ; D573  C8
        lda  ($2A),y                ; D574  B1 2A
        sta  ($FC),y                ; D576  91 FC
        iny                         ; D578  C8
        lda  ($2A),y                ; D579  B1 2A
        sta  ($FC),y                ; D57B  91 FC
        iny                         ; D57D  C8
        cpy  #$28                   ; D57E  C0 28
        bne  C41                    ; D580  D0 D4
        ldx  S_0552                 ; D582  AE 52 94
        rts                         ; D585  60
COPYPLUS:
        stx  S_0552                 ; D586  8E 52 94
        txa                         ; D589  8A
        clc                         ; D58A  18
        adc  #$0C                   ; D58B  69 0C
        jsr  SET2A                  ; D58D  20 39 D5
        ldx  S_0552                 ; D590  AE 52 94
        jsr  SETFC                  ; D593  20 47 D5
        jmp  C40                    ; D596  4C 54 D5
COPYMINUS:
        stx  S_0552                 ; D599  8E 52 94
        txa                         ; D59C  8A
        sec                         ; D59D  38
        sbc  #$0C                   ; D59E  E9 0C
        jsr  SET2A                  ; D5A0  20 39 D5
        ldx  S_0552                 ; D5A3  AE 52 94
        jsr  SETFC                  ; D5A6  20 47 D5
        jmp  C40                    ; D5A9  4C 54 D5
HSUP:
        lda  WNDBTM                 ; D5AC  A5 23
        sec                         ; D5AE  38
        sbc  WNDTOP                 ; D5AF  E5 22
        beq  HSU9                   ; D5B1  F0 1E
        bcc  HSU9                   ; D5B3  90 1C
        sec                         ; D5B5  38
        sbc  #$01                   ; D5B6  E9 01
        beq  HSU9                   ; D5B8  F0 17
        bcc  HSU9                   ; D5BA  90 15
        jsr  MUL12                  ; D5BC  20 93 F1
        sta  S_0553                 ; D5BF  8D 53 94
        lda  WNDTOP                 ; D5C2  A5 22
        jsr  MUL12                  ; D5C4  20 93 F1
        tax                         ; D5C7  AA
HSU1:
        jsr  COPYPLUS               ; D5C8  20 86 D5
        inx                         ; D5CB  E8
        dec  S_0553                 ; D5CC  CE 53 94
        bne  HSU1                   ; D5CF  D0 F7
HSU9:
        rts                         ; D5D1  60
HSDN:
        lda  WNDBTM                 ; D5D2  A5 23
        sec                         ; D5D4  38
        sbc  WNDTOP                 ; D5D5  E5 22
        beq  HSD9                   ; D5D7  F0 21
        bcc  HSD9                   ; D5D9  90 1F
        sec                         ; D5DB  38
        sbc  #$01                   ; D5DC  E9 01
        beq  HSD9                   ; D5DE  F0 1A
        bcc  HSD9                   ; D5E0  90 18
        jsr  MUL12                  ; D5E2  20 93 F1
        sta  S_0553                 ; D5E5  8D 53 94
        lda  WNDBTM                 ; D5E8  A5 23
        jsr  MUL12                  ; D5EA  20 93 F1
        sec                         ; D5ED  38
        sbc  #$01                   ; D5EE  E9 01
        tax                         ; D5F0  AA
HSD1:
        jsr  COPYMINUS              ; D5F1  20 99 D5
        dex                         ; D5F4  CA
        dec  S_0553                 ; D5F5  CE 53 94
        bne  HSD1                   ; D5F8  D0 F7
HSD9:
        rts                         ; D5FA  60
CASEIN:
        pha                         ; D5FB  48
        cmp  #$12                   ; D5FC  C9 12
        bne  CAG                    ; D5FE  D0 18
        lda  CASEMODE               ; D600  AD BC 1C
        beq  CA1                    ; D603  F0 08
        cmp  #$01                   ; D605  C9 01
        beq  CA2                    ; D607  F0 08
        lda  #$00                   ; D609  A9 00
        beq  CAS                    ; D60B  F0 06
CA1:
        lda  #$01                   ; D60D  A9 01
        bne  CAS                    ; D60F  D0 02
CA2:
        lda  #$02                   ; D611  A9 02
CAS:
        sta  CASEMODE               ; D613  8D BC 1C
        pla                         ; D616  68
        rts                         ; D617  60
CAG:
        pla                         ; D618  68
        ldx  #$00                   ; D619  A2 00
        bit  a:INVFLG               ; D61B  2C 32 00
        jmp  L_F112                 ; D61E  4C 12 F1
FIXCASE:
        lda  CHAR                   ; D621  AD AD 94
        cmp  #$41                   ; D624  C9 41
        bcc  FXD                    ; D626  90 1C
        cmp  #$5B                   ; D628  C9 5B
        bcs  FXD                    ; D62A  B0 18
        lda  CASEMODE               ; D62C  AD BC 1C
        beq  FXD                    ; D62F  F0 13
        cmp  #$02                   ; D631  C9 02
        bne  FXL                    ; D633  D0 07
        lda  #$01                   ; D635  A9 01
        sta  CASEMODE               ; D637  8D BC 1C
        bne  FXD                    ; D63A  D0 08
FXL:
        lda  CHAR                   ; D63C  AD AD 94
        ora  #$20                   ; D63F  09 20
        sta  CHAR                   ; D641  8D AD 94
FXD:
        lda  CHAR                   ; D644  AD AD 94
        rts                         ; D647  60
SAVECLR:
        lda  MODECAP                ; D648  AD BB 1C
        beq  SC0                    ; D64B  F0 0B
        lda  HMODE                  ; D64D  AD AC 94
        sta  MODESAVE               ; D650  8D BA 1C
        lda  #$00                   ; D653  A9 00
        sta  MODECAP                ; D655  8D BB 1C
SC0:
        lda  #$00                   ; D658  A9 00
        sta  HMODE                  ; D65A  8D AC 94
        rts                         ; D65D  60
SKIPPR:
        cpx  #$00                   ; D65E  E0 00
        bne  SPK                    ; D660  D0 04
        cmp  PROMPTCH               ; D662  C5 33
        beq  SPD                    ; D664  F0 04
SPK:
        sta  INBUF,x                ; D666  9D 00 02
        inx                         ; D669  E8
SPD:
        rts                         ; D66A  60
NOLEFT:
        txa                         ; D66B  8A
        pha                         ; D66C  48
        lda  CV                     ; D66D  A5 25
        jsr  ROWPTR                 ; D66F  20 7F F1
        ldy  CH                     ; D672  A4 24
        beq  NL0                    ; D674  F0 0E
        dey                         ; D676  88
        lda  (BASL),y               ; D677  B1 28
        eor  PROMPTCH               ; D679  45 33
        and  #$7F                   ; D67B  29 7F
        beq  NL9                    ; D67D  F0 14
        dec  CH                     ; D67F  C6 24
        pla                         ; D681  68
        tax                         ; D682  AA
        rts                         ; D683  60
NL0:
        lda  (BASL),y               ; D684  B1 28
        eor  PROMPTCH               ; D686  45 33
        and  #$7F                   ; D688  29 7F
        beq  NL9                    ; D68A  F0 07
        pla                         ; D68C  68
        tax                         ; D68D  AA
        dec  CH                     ; D68E  C6 24
        jmp  L_E9A8                 ; D690  4C A8 E9
NL9:
        pla                         ; D693  68
        tax                         ; D694  AA
        rts                         ; D695  60
PROMPT:
        lda  #$00                   ; D696  A9 00
        tay                         ; D698  A8
        jsr  L_EE1D                 ; D699  20 1D EE
        beq  PHIT                   ; D69C  F0 03
        jmp  L_EE87                 ; D69E  4C 87 EE
PHIT:
        txa                         ; D6A1  8A
        pha                         ; D6A2  48
        lda  MODESAVE               ; D6A3  AD BA 1C
        sta  HMODE                  ; D6A6  8D AC 94
        lda  #$01                   ; D6A9  A9 01
        sta  MODECAP                ; D6AB  8D BB 1C
        jsr  FIXPR                  ; D6AE  20 DB ED
        jsr  DISP                   ; D6B1  20 AA EE
        jsr  L_EB41                 ; D6B4  20 41 EB
        pla                         ; D6B7  68
        tax                         ; D6B8  AA
        jmp  L_EEC1                 ; D6B9  4C C1 EE

; ==========================================================================
; Driver start: banner copy, font relocation, DOS CATALOG patches, then the stock init
; ==========================================================================
INIT:
        lda  BSRCL                  ; D6BC  AD AD D7
        sta  $06                    ; D6BF  85 06
        lda  BSRCH                  ; D6C1  AD AE D7
        sta  $07                    ; D6C4  85 07
        lda  #<__BANNER_RUN__
        sta  $08                    ; D6C8  85 08
        lda  #>__BANNER_RUN__
        sta  $09                    ; D6CC  85 09
        lda  #<__BANNER_SIZE__
        sta  $1C80                  ; D6D0  8D 80 1C
        lda  #>__BANNER_SIZE__
        sta  $1C81                  ; D6D5  8D 81 1C
        ldy  #$00                   ; D6D8  A0 00
BCP2:
        lda  ($06),y                ; D6DA  B1 06
        sta  ($08),y                ; D6DC  91 08
        iny                         ; D6DE  C8
        bne  BCPN                   ; D6DF  D0 04
        inc  $07                    ; D6E1  E6 07
        inc  $09                    ; D6E3  E6 09
BCPN:
        lda  $1C80                  ; D6E5  AD 80 1C
        bne  BCD                    ; D6E8  D0 03
        dec  $1C81                  ; D6EA  CE 81 1C
BCD:
        dec  $1C80                  ; D6ED  CE 80 1C
        lda  $1C80                  ; D6F0  AD 80 1C
        ora  $1C81                  ; D6F3  0D 81 1C
        bne  BCP2                   ; D6F6  D0 E2
        jsr  RELOC                  ; D6F8  20 5E 1F
        lda  #$A0                   ; D6FB  A9 A0
        ldx  #$00                   ; D6FD  A2 00
IF1:
        sta  BUF,x                  ; D6FF  9D 80 19
        sta  $1A80,x                ; D702  9D 80 1A
        sta  $1B80,x                ; D705  9D 80 1B
        inx                         ; D708  E8
        bne  IF1                    ; D709  D0 F4
        lda  #$FF                   ; D70B  A9 FF
        ldx  #$11                   ; D70D  A2 11
IF3:
        sta  FLAGS,x                ; D70F  9D 60 1C
        dex                         ; D712  CA
        bpl  IF3                    ; D713  10 FA
        lda  #$00                   ; D715  A9 00
        sta  HIMEMZ                 ; D717  85 73
        sta  FRETOP                 ; D719  85 6F
        lda  #$94                   ; D71B  A9 94
        sta  $74                    ; D71D  85 74
        sta  $70                    ; D71F  85 70
        jsr  ENGCOPY                ; copies the English font, clears CASEMODE, write protects the card
        nop
        nop
        ldx  #$00                   ; D726  A2 00
BCP:
        lda  BELLIMG,x              ; D728  BD AF D7
        sta  BELL,x                 ; D72B  9D B0 1C
        inx                         ; D72E  E8
        cpx  #$0A                   ; D72F  E0 0A
        bne  BCP                    ; D731  D0 F5
        lda  #$00                   ; D733  A9 00
        sta  MODESAVE               ; D735  8D BA 1C
        sta  MODECAP                ; D738  8D BB 1C
        sta  NOPR                   ; D73B  8D FB 1F
        lda  $ADA3                  ; D73E  AD A3 AD
        cmp  #$A9                   ; D741  C9 A9
        bne  DPX                    ; D743  D0 65
        lda  $ADA4                  ; D745  AD A4 AD
        cmp  #$18                   ; D748  C9 18
        bne  DPX                    ; D74A  D0 5E
        lda  $ADA5                  ; D74C  AD A5 AD
        cmp  #$8D                   ; D74F  C9 8D
        bne  DPX                    ; D751  D0 57
        lda  $ADA6                  ; D753  AD A6 AD
        cmp  #$9D                   ; D756  C9 9D
        bne  DPX                    ; D758  D0 50
        lda  $ADA7                  ; D75A  AD A7 AD
        cmp  #$B3                   ; D75D  C9 B3
        bne  DPX                    ; D75F  D0 49
        lda  $AE3C                  ; D761  AD 3C AE
        cmp  #$A9                   ; D764  C9 A9
        bne  DPX                    ; D766  D0 42
        lda  $AE3D                  ; D768  AD 3D AE
        cmp  #$17                   ; D76B  C9 17
        bne  DPX                    ; D76D  D0 3B
        lda  $AE39                  ; D76F  AD 39 AE
        cmp  #$20                   ; D772  C9 20
        bne  DPX                    ; D774  D0 34
        lda  $AE3A                  ; D776  AD 3A AE
        cmp  #$0C                   ; D779  C9 0C
        bne  DPX                    ; D77B  D0 2D
        lda  $AE3B                  ; D77D  AD 3B AE
        cmp  #$FD                   ; D780  C9 FD
        bne  DPX                    ; D782  D0 26
        lda  #$20                   ; D784  A9 20
        sta  $ADA3                  ; D786  8D A3 AD
        lda  #<CATINIT
        sta  $ADA4                  ; D78B  8D A4 AD
        lda  #>CATINIT
        sta  $ADA5                  ; D790  8D A5 AD
        lda  #$EA                   ; D793  A9 EA
        sta  $ADA6                  ; D795  8D A6 AD
        sta  $ADA7                  ; D798  8D A7 AD
        lda  #$0B                   ; D79B  A9 0B
        sta  $AE3D                  ; D79D  8D 3D AE
        lda  #<CATWAIT
        sta  $AE3A                  ; D7A2  8D 3A AE
        lda  #>CATWAIT
        sta  $AE3B                  ; D7A7  8D 3B AE
DPX:
        jmp  STATEINIT              ; D7AA  4C DA E3
BSRCL:
        .byte <__BANNER_LOAD__
BSRCH:
        .byte >__BANNER_LOAD__
BELLIMG:
        .byte $8D,$82,$C0,$20,$DD,$FB,$8D,$80,$C0,$60; D7AF
ROWLO:
        .byte $80,$AE,$DC,$0A,$38,$66,$94,$C2,$F0,$1E,$4C,$7A,$A8,$D6,$04,$32; D7B9
ROWHI:
        .byte $19,$19,$19,$1A,$1A,$1A,$1A,$1A,$1A,$1B,$1B,$1B,$1B,$1B,$1C,$1C; D7C9
MASK:
        .byte $01,$02,$04,$08,$10,$20,$40; D7D9
MUL19:
        .byte $00,$13,$26,$39,$4C,$5F; D7E0
CLASS:
        .include "jungclass.inc"        ; 22 bytes made from font.json
        .byte $14,$2A,$00,$00          ; D7FC
; The state ($9400-$95FF) starts as spaces, as the text page it used to live in was, then the stock init
; copies its six blocks over it. INIT and the HAN command both come here. The 16 bytes were stock data
; for the old Hangul font that no screen uses now.
STATEINIT:
        lda  #$A0
        ldx  #$00
@fill:
        sta  STATEBASE,x
        sta  STATEBASE+$100,x
        inx
        bne  @fill
        jmp  STOCKINIT
; ---------------------------------------------------------------------------
; The English font: FONT6X10 is loaded at ENGSRC ($7200) by HELLO and copied here by INIT while the card
; is still writable. 128 glyphs of 16 bytes: the 10 lines of the glyph, then 6 unused bytes (so a glyph
; is found with 4 shifts). The glyph pointer S_07DB/S_07DC starts at ENGFONT (stub block FE31).
; These bytes were stock data for the old Hangul font; zeroing them changed no screen.
; ---------------------------------------------------------------------------
; P0 = P0 + A * 16
ENGPTR:
        sta  P2L
        lsr  a
        lsr  a
        lsr  a
        lsr  a
        sta  P2H
        lda  P2L
        asl  a
        asl  a
        asl  a
        asl  a
        clc
        adc  P0L
        sta  P0L
        lda  P2H
        adc  P0H
        sta  P0H
        rts

; INIT calls this with the card writable: copy FONT6X10 from ENGSRC to ENGFONT, then write protect the card
ENGCOPY:
        lda  #<ENGSRC
        sta  $06
        lda  #>ENGSRC
        sta  $07
        lda  #<ENGFONT
        sta  $08
        lda  #>ENGFONT
        sta  $09
        ldx  #$08                       ; 8 pages
        ldy  #$00
@copy:
        lda  ($06),y
        sta  ($08),y
        iny
        bne  @copy
        inc  $07
        inc  $09
        dex
        bne  @copy
        lda  #$00
        sta  CASEMODE
        sta  STRIPF                     ; strip mode off (see LINEX)
        lda  SW2                        ; the level of the Shift mod input while Shift is not held (see SHFIX)
        and  #$80
        sta  SHIDLE
        lda  LCRAMRD                    ; $C080: RAM read, write protected
        rts
ENGFONT:
        .res 2048
.assert ENGFONT = $D860, error, "ENGFONT must be at $D860: the stock data after it starts at $E060"
        .byte $02,$02,$83,$05,$00,$00,$00,$00,$07,$07,$02,$02          ; E060
        .byte $83,$05,$02,$07,$83,$05,$83,$07,$00,$00,$00,$07,$07,$04,$07,$00; E06C
        .byte $07,$07,$04,$04,$04,$04,$07,$05,$05,$05,$07,$05,$05,$07,$05,$07; E07C
        .byte $02,$02,$02,$83,$05,$07,$01,$07,$01,$07,$07,$03,$03,$03,$07,$02; E08C
        .byte $07,$83,$05,$83,$07,$04,$04,$04,$07,$04,$04,$07,$04,$07,$02,$02; E09C
        .byte $02,$83,$05,$00,$00,$01,$02,$04,$02,$02,$02,$83,$05,$03,$04,$04; E0AC
        .byte $04,$03,$07,$00,$01,$02,$04,$01,$07,$01,$02,$04,$07,$04,$07,$04; E0BC
        .byte $04,$07,$00,$07,$00,$07,$07,$02,$02,$02,$07,$01,$07,$03,$04,$03; E0CC
HGRLO:
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$80,$80,$80; E0DC
L_E0E7:
        .byte $80,$80,$80,$80,$80,$00,$00,$00,$00,$00,$00,$00,$00,$80,$80,$80; E0E7
        .byte $80,$80,$80,$80,$80,$00,$00,$00,$00,$00,$00,$00,$00,$80,$80,$80; E0F7
        .byte $80,$80,$80,$80,$80,$00,$00,$00,$00,$00,$00,$00,$00,$80,$80,$80; E107
        .byte $80,$80,$80,$80,$80,$28,$28,$28,$28,$28,$28,$28,$28,$A8,$A8,$A8; E117
        .byte $A8,$A8,$A8,$A8,$A8,$28,$28,$28,$28,$28,$28,$28,$28,$A8,$A8,$A8; E127
        .byte $A8,$A8,$A8,$A8,$A8,$28,$28,$28,$28,$28,$28,$28,$28,$A8,$A8,$A8; E137
        .byte $A8,$A8,$A8,$A8,$A8,$28,$28,$28,$28,$28,$28,$28,$28,$A8,$A8,$A8; E147
        .byte $A8,$A8,$A8,$A8,$A8,$50,$50,$50,$50,$50,$50,$50,$50,$D0,$D0,$D0; E157
        .byte $D0,$D0,$D0,$D0,$D0,$50,$50,$50,$50,$50,$50,$50,$50,$D0,$D0,$D0; E167
        .byte $D0,$D0,$D0,$D0,$D0,$50,$50,$50,$50,$50,$50,$50,$50,$D0,$D0,$D0; E177
        .byte $D0,$D0,$D0,$D0,$D0,$50,$50,$50,$50,$50,$50,$50,$50,$D0,$D0,$D0; E187
        .byte $D0,$D0,$D0,$D0,$D0   ; E197
HGRHI:
        .byte $00,$04,$08,$0C,$10,$14,$18,$1C,$00,$04,$08,$0C,$10,$14,$18,$1C; E19C
        .byte $01,$05,$09,$0D,$11,$15,$19,$1D,$01,$05,$09,$0D,$11,$15,$19,$1D; E1AC
        .byte $02,$06,$0A,$0E,$12,$16,$1A,$1E,$02,$06,$0A,$0E,$12,$16,$1A,$1E; E1BC
        .byte $03,$07,$0B,$0F,$13,$17,$1B,$1F,$03,$07,$0B,$0F,$13,$17,$1B,$1F; E1CC
        .byte $00,$04,$08,$0C,$10,$14,$18,$1C,$00,$04,$08,$0C,$10,$14,$18,$1C; E1DC
        .byte $01,$05,$09,$0D,$11,$15,$19,$1D,$01,$05,$09,$0D,$11,$15,$19,$1D; E1EC
        .byte $02,$06,$0A,$0E,$12,$16,$1A,$1E,$02,$06,$0A,$0E,$12,$16,$1A,$1E; E1FC
        .byte $03,$07,$0B,$0F,$13,$17,$1B,$1F,$03,$07,$0B,$0F,$13,$17,$1B,$1F; E20C
        .byte $00,$04,$08,$0C,$10,$14,$18,$1C,$00,$04,$08,$0C,$10,$14,$18,$1C; E21C
        .byte $01,$05,$09,$0D,$11,$15,$19,$1D,$01,$05,$09,$0D,$11,$15,$19,$1D; E22C
        .byte $02,$06,$0A,$0E,$12,$16,$1A,$1E,$02,$06,$0A,$0E,$12,$16,$1A,$1E; E23C
        .byte $03,$07,$0B,$0F,$13,$17,$1B,$1F,$03,$07,$0B,$0F,$13,$17,$1B,$1F; E24C
D_E25C:
        .byte $00                   ; E25C
D_E25D:
        .byte $D8,$DC,$D8,$CC,$D9,$58,$DA,$D0,$DA,$98,$DB; E25D
D_E268:
        .byte $FC                   ; E268
D_E269:
        .byte $DB,$38,$DE           ; E269
D_E26C:
        .byte $0B                   ; E26C
D_E26D:
        .byte $00,$06,$FF,$07,$00,$06,$00,$05,$FF,$05,$00; E26D
D_E278:
        .byte $0D,$FF,$09,$FF       ; E278
D_E27C:
        .byte $80,$81,$81,$83,$83,$83,$83,$83,$83,$83,$85; E27C
D_E287:
        .byte $86,$88,$8D,$80,$84,$85,$86,$8B,$8C,$8D,$86; E287
D_E292:
        .byte $93,$93,$93,$95,$95,$95,$97; E292
D_E299:
        .byte $98,$9D,$9C,$9A,$9F,$9C,$9C; E299
D_E2A0:
        .byte $20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$90,$A0,$2C,$8E,$2E,$2F; E2A0
        .byte $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$9E,$91,$8F,$92,$3F; E2B0
        .byte $40,$84,$96,$89,$87,$82,$83,$8D,$93,$99,$9A,$98,$9C,$97,$95,$9D; E2C0
        .byte $9F,$85,$80,$81,$86,$9B,$8C,$88,$8B,$94,$8A; E2D0
D_E2DB:
        .byte $80,$8E,$81,$82,$8F,$83,$84,$85,$90,$86,$91,$87,$88,$92,$89,$8A; E2DB
        .byte $8B,$8C,$8D,$00       ; E2EB
D_E2EF:
        .byte $98,$9D,$99,$9E,$9A,$9F,$9B,$A0,$93,$A1,$A2,$A3,$94,$95,$A4,$A5; E2EF
        .byte $A6,$96,$97,$A7,$9C,$00; E2FF
D_E305:
        .byte $03,$04,$05,$06,$07,$0A,$0B,$0C,$0D,$0E,$0F,$12,$13,$14,$15,$16; E305
        .byte $17,$1A,$1B,$1C,$1D,$00; E315
D_E31B:
        .byte $80,$8E,$B1,$81,$B2,$B3,$82,$83,$B4,$B5,$B6,$B7,$B8,$B9,$BA,$84; E31B
        .byte $A0,$85,$BB,$86,$91,$87,$88,$89,$8A,$8B,$8C,$8D,$00; E32B
D_E338:
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$02,$02,$01,$01,$02; E338
        .byte $02,$02,$01,$01,$02,$00; E348
JUNGOF:
        .byte $00,$00,$00,$01,$02,$03,$04,$05,$00,$00,$06,$07,$08,$09,$0A,$0B; E34E
        .byte $00,$00,$0C,$0D,$0E,$0F,$10,$11,$00,$00,$12,$13,$14,$15; E35E
D_E36C:
        .byte $40,$52,$2D,$53,$45,$3D,$46,$41,$51,$2A,$54,$3C,$44,$57,$3E,$43; E36C
        .byte $5A,$58,$56,$47       ; E37C
D_E380:
        .byte $40,$4B,$4F,$49,$3B,$4A,$50,$55,$2B,$48,$C8,$C8,$C8,$59,$4E,$CE; E380
        .byte $CE,$CE,$42,$4D,$CD,$4C; E390
D_E396:
        .byte $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$4B,$4F,$4C,$40,$40,$4A; E396
        .byte $50,$4C,$40,$40,$4C   ; E3A6
D_E3AB:
        .byte $40,$52,$2D,$D2,$53,$D3,$D3,$45,$46,$C6,$C6,$C6,$C6,$C6,$C6,$C6; E3AB
        .byte $41,$51,$D1,$54,$3C,$44,$57,$43,$5A,$58,$56,$47; E3BB
D_E3C7:
        .byte $40,$40,$40,$54,$40,$57,$47,$40,$40,$52,$41,$51,$54,$58,$56,$47; E3C7
        .byte $40,$40,$54           ; E3D7

; ==========================================================================
; Stock Hangeul2 code starts here (init, line editor, scroll, key handling)
; ==========================================================================
STOCKINIT:
        ldx  #$27                   ; E3DA  A2 27
L_E3DC:
        lda  $FD69,x                ; E3DC  BD 69 FD
        sta  S_06A8,x               ; E3DF  9D 9D 94
        lda  $FD91,x                ; E3E2  BD 91 FD
        sta  S_0728,x               ; E3E5  9D C9 94
        lda  $FDB9,x                ; E3E8  BD B9 FD
        sta  S_07A8,x               ; E3EB  9D 49 95
        lda  $FDE1,x                ; E3EE  BD E1 FD
        sta  S_0450,x               ; E3F1  9D 00 94
        lda  $FE09,x                ; E3F4  BD 09 FE
        sta  S_04D0,x               ; E3F7  9D 28 94
        lda  $FE31,x                ; E3FA  BD 31 FE
        sta  S_07D0,x               ; E3FD  9D 71 95
        dex                         ; E400  CA
        bpl  L_E3DC                 ; E401  10 D9
        jsr  SETWINDOW              ; E403  20 59 E4
        sta  LOWSCR,x               ; E406  9D 54 C0
        lda  MIXCLR                 ; E409  AD 52 C0
        lda  HIRES                  ; E40C  AD 57 C0
        lda  TXTCLR                 ; E40F  AD 50 C0
        jsr  CLEARHOME              ; E412  20 37 EA
        lda  #$7F                   ; E415  A9 7F
        sta  $E4                    ; E417  85 E4
        lda  #$0A                   ; E419  A9 0A
        sta  CSWL                   ; E41B  85 36
        lda  #$94                   ; E41D  A9 94
        sta  CSWH                   ; E41F  85 37
        lda  #$00                   ; E421  A9 00
        sta  KSWL                   ; E423  85 38
        lda  #$94                   ; E425  A9 94
        sta  KSWH                   ; E427  85 39
        jsr  L_E480                 ; E429  20 80 E4
        jmp  BN                     ; E42C  4C C0 1C
        .byte $20,$95,$E4,$89,$FE,$20,$95,$E4,$93,$FE,$20,$95,$E4,$2F,$FB,$4C; E42F
        .byte $80,$E4               ; E43F
WNDCLAMP:
        jsr  HOMECK                 ; E441  20 B8 F2
        nop                         ; E444  EA
        nop                         ; E445  EA
        beq  L_E449                 ; E446  F0 01
        dex                         ; E448  CA
L_E449:
        cpx  WNDBTM                 ; E449  E4 23
        bcs  L_E44F                 ; E44B  B0 02
        stx  WNDBTM                 ; E44D  86 23
L_E44F:
        dex                         ; E44F  CA
        cpx  CV                     ; E450  E4 25
        bcs  L_E472                 ; E452  B0 1E
        stx  CV                     ; E454  86 25
        jmp  L_EC71                 ; E456  4C 71 EC
SETWINDOW:
        lda  #$2E                   ; E459  A9 2E
        sta  WNDWDTH                ; E45B  85 21
        ldx  #$00                   ; E45D  A2 00
        stx  WNDLFT                 ; E45F  86 20
        stx  WNDTOP                 ; E461  86 22
        lda  #$10                   ; E463  A9 10
        sta  WNDBTM                 ; E465  85 23
        lda  #$20                   ; E467  A9 20
        cmp  $E6                    ; E469  C5 E6
        beq  L_E472                 ; E46B  F0 05
        lda  #$20                   ; E46D  A9 20
        nop                         ; E46F  EA
        sta  $E6                    ; E470  85 E6
L_E472:
        rts                         ; E472  60
L_E473:
        lda  $03D0                  ; E473  AD D0 03
        cmp  #$4C                   ; E476  C9 4C
        sec                         ; E478  38
        bne  L_E47F                 ; E479  D0 04
        lda  $03D1                  ; E47B  AD D1 03
        clc                         ; E47E  18
L_E47F:
        rts                         ; E47F  60
L_E480:
        jsr  L_E473                 ; E480  20 73 E4
        bcs  L_E47F                 ; E483  B0 FA
        beq  L_E492                 ; E485  F0 0B
        lda  $AA5E                  ; E487  AD 5E AA
        ora  #$20                   ; E48A  09 20
        sta  $AA5E                  ; E48C  8D 5E AA
        jmp  $03EA                  ; E48F  4C EA 03
L_E492:
        jmp  $9A17                  ; E492  4C 17 9A
L_E495:
        php                         ; E495  08
        sta  S_0565                 ; E496  8D 65 94
        stx  S_0566                 ; E499  8E 66 94
        sty  S_0567                 ; E49C  8C 67 94
        ldx  $0E                    ; E49F  A6 0E
        ldy  $0F                    ; E4A1  A4 0F
        stx  S_0563                 ; E4A3  8E 63 94
        sty  S_0564                 ; E4A6  8C 64 94
        tsx                         ; E4A9  BA
        lda  $0102,x                ; E4AA  BD 02 01
        sta  $0E                    ; E4AD  85 0E
        clc                         ; E4AF  18
        adc  #$02                   ; E4B0  69 02
        sta  $0102,x                ; E4B2  9D 02 01
        lda  $0103,x                ; E4B5  BD 03 01
        sta  $0F                    ; E4B8  85 0F
        adc  #$00                   ; E4BA  69 00
        sta  $0103,x                ; E4BC  9D 03 01
        ldy  #$01                   ; E4BF  A0 01
        lda  ($0E),y                ; E4C1  B1 0E
        sta  S_04E2                 ; E4C3  8D 3A 94
        iny                         ; E4C6  C8
        lda  ($0E),y                ; E4C7  B1 0E
        sta  S_04E3                 ; E4C9  8D 3B 94
        ldx  S_0563                 ; E4CC  AE 63 94
        ldy  S_0564                 ; E4CF  AC 64 94
        stx  $0E                    ; E4D2  86 0E
        sty  $0F                    ; E4D4  84 0F
        ldy  S_0567                 ; E4D6  AC 67 94
        ldx  S_0566                 ; E4D9  AE 66 94
        lda  S_0565                 ; E4DC  AD 65 94
        plp                         ; E4DF  28
        jmp  S_04DE                 ; E4E0  4C 36 94
L_E4E3:
        ldy  CH                     ; E4E3  A4 24
        lda  (BASL),y               ; E4E5  B1 28
        cmp  #$A0                   ; E4E7  C9 A0
        beq  L_E4F2                 ; E4E9  F0 07
        jsr  L_FD27                 ; E4EB  20 27 FD
        bcc  L_E4E3                 ; E4EE  90 F3
        bcs  L_E4F5                 ; E4F0  B0 03
L_E4F2:
        jsr  L_FD19                 ; E4F2  20 19 FD
L_E4F5:
        jmp  L_EA7D                 ; E4F5  4C 7D EA
L_E4F8:
        ldy  CH                     ; E4F8  A4 24
        lda  (BASL),y               ; E4FA  B1 28
        cmp  #$A0                   ; E4FC  C9 A0
        beq  L_E507                 ; E4FE  F0 07
        jsr  L_FCF5                 ; E500  20 F5 FC
        bcc  L_E4F8                 ; E503  90 F3
        bcs  L_E51C                 ; E505  B0 15
L_E507:
        jsr  L_FCE7                 ; E507  20 E7 FC
L_E50A:
        ldy  CH                     ; E50A  A4 24
        lda  (BASL),y               ; E50C  B1 28
        cmp  #$A0                   ; E50E  C9 A0
        beq  L_E519                 ; E510  F0 07
        jsr  L_FCF5                 ; E512  20 F5 FC
        bcc  L_E50A                 ; E515  90 F3
        bcs  L_E51C                 ; E517  B0 03
L_E519:
        jsr  L_FD27                 ; E519  20 27 FD
L_E51C:
        jmp  L_EA7D                 ; E51C  4C 7D EA
L_E51F:
        ldy  CV                     ; E51F  A4 25
        bpl  L_E528                 ; E521  10 05
L_E523:
        lda  $1C61,y                ; E523  B9 61 1C
        bmi  L_E53C                 ; E526  30 14
L_E528:
        iny                         ; E528  C8
        cpy  WNDBTM                 ; E529  C4 23
        bcc  L_E523                 ; E52B  90 F6
        bcs  L_E53C                 ; E52D  B0 0D
L_E52F:
        ldy  CV                     ; E52F  A4 25
        lda  $1C61,y                ; E531  B9 61 1C
        bmi  L_E553                 ; E534  30 1D
        lda  WNDTOP                 ; E536  A5 22
        cmp  CV                     ; E538  C5 25
        bcs  L_E553                 ; E53A  B0 17
L_E53C:
        dey                         ; E53C  88
        tya                         ; E53D  98
        sta  CV                     ; E53E  85 25
        jsr  L_EC73                 ; E540  20 73 EC
        ldy  WNDWDTH                ; E543  A4 21
L_E545:
        dey                         ; E545  88
        bmi  L_E52F                 ; E546  30 E7
        lda  (BASL),y               ; E548  B1 28
        cmp  #$A0                   ; E54A  C9 A0
        sty  CH                     ; E54C  84 24
        beq  L_E545                 ; E54E  F0 F5
        jsr  L_EBF1                 ; E550  20 F1 EB
L_E553:
        jmp  L_EA7D                 ; E553  4C 7D EA
        jsr  L_EA7A                 ; E556  20 7A EA
        ldy  CH                     ; E559  A4 24
        iny                         ; E55B  C8
        cpy  WNDWDTH                ; E55C  C4 21
        bne  L_E567                 ; E55E  D0 07
        ldy  CV                     ; E560  A4 25
        lda  #$00                   ; E562  A9 00
        sta  $1C62,y                ; E564  99 62 1C
L_E567:
        bit  S_04D5                 ; E567  2C 2D 94
        bmi  L_E56F                 ; E56A  30 03
        jsr  L_EA93                 ; E56C  20 93 EA
L_E56F:
        ldy  CH                     ; E56F  A4 24
        lda  (BASL),y               ; E571  B1 28
        bpl  L_E577+1               ; E573  10 03
        lda  #$01                   ; E575  A9 01
L_E577:
        bit  $02A9                  ; E577  2C A9 02
        bit  S_04D5                 ; E57A  2C 2D 94
        bmi  L_E585                 ; E57D  30 06
        jsr  L_E729                 ; E57F  20 29 E7
        jmp  L_E9C9                 ; E582  4C C9 E9
L_E585:
        clc                         ; E585  18
        adc  S_04D7                 ; E586  6D 2F 94
        jmp  L_EABE                 ; E589  4C BE EA
L_E58C:
        lda  #$00                   ; E58C  A9 00
        jsr  L_E729                 ; E58E  20 29 E7
        ldy  CH                     ; E591  A4 24
L_E593:
        bit  a:$00A0                ; E593  2C A0 00
        jsr  L_EC4E                 ; E596  20 4E EC
        jsr  L_ED38                 ; E599  20 38 ED
        jsr  L_E7C1                 ; E59C  20 C1 E7
        bcc  L_E593+1               ; E59F  90 F3
        jmp  RESTCUR                ; E5A1  4C 02 EE
L_E5A4:
        lda  #$00                   ; E5A4  A9 00
        sta  CH                     ; E5A6  85 24
        lda  WNDTOP                 ; E5A8  A5 22
        sta  CV                     ; E5AA  85 25
        jmp  L_EC73                 ; E5AC  4C 73 EC
        lda  S_04D2                 ; E5AF  AD 2A 94
        eor  #$80                   ; E5B2  49 80
        sta  S_04D2                 ; E5B4  8D 2A 94
        rts                         ; E5B7  60
        lda  S_04DC                 ; E5B8  AD 34 94
        eor  #$80                   ; E5BB  49 80
        sta  S_04DC                 ; E5BD  8D 34 94
        jmp  L_E5FC                 ; E5C0  4C FC E5
        jsr  SAVECUR                ; E5C3  20 F7 ED
        lda  #$00                   ; E5C6  A9 00
        jsr  L_E729                 ; E5C8  20 29 E7
        jmp  RESTCUR                ; E5CB  4C 02 EE
L_E5CE:
        lda  #$00                   ; E5CE  A9 00
        sta  CH                     ; E5D0  85 24
        jsr  L_E7D4                 ; E5D2  20 D4 E7
        jmp  L_EA7D                 ; E5D5  4C 7D EA
        lda  #$3F                   ; E5D8  A9 3F
        bit  ZJ+1                   ; E5DA  2C A9 FF
        ldx  #$00                   ; E5DD  A2 00
        sta  INVFLG                 ; E5DF  85 32
        stx  $F3                    ; E5E1  86 F3
        rts                         ; E5E3  60
        clc                         ; E5E4  18
D_E5E5:
        bcs  L_E61E+1               ; E5E5  B0 38
        ror  HMODE                  ; E5E7  6E AC 94
        rts                         ; E5EA  60
        jsr  L_EC93                 ; E5EB  20 93 EC
        jmp  L_EA7D                 ; E5EE  4C 7D EA
        lda  PROMPTCH               ; E5F1  A5 33
        cmp  #$AA                   ; E5F3  C9 AA
        bne  L_E5FC                 ; E5F5  D0 05
        jsr  L_E495                 ; E5F7  20 95 E4
        .byte $03,$E0               ; E5FA
L_E5FC:
        jsr  L_E51F                 ; E5FC  20 1F E5
        jmp  L_EC8F                 ; E5FF  4C 8F EC
L_E602:
        sec                         ; E602  38
L_E603:
        pha                         ; E603  48
L_E604:
        sbc  #$01                   ; E604  E9 01
        bne  L_E604                 ; E606  D0 FC
        pla                         ; E608  68
        sbc  #$01                   ; E609  E9 01
        bne  L_E603                 ; E60B  D0 F6
        rts                         ; E60D  60
L_E60E:
        ldx  #$06                   ; E60E  A2 06
L_E610:
        lda  D_E720,x               ; E610  BD 20 E7
        sta  S_06BB,x               ; E613  9D B0 94
        dex                         ; E616  CA
        bpl  L_E610                 ; E617  10 F7
        jsr  SAVECLR                ; E619  20 48 D6
        nop                         ; E61C  EA
        nop                         ; E61D  EA
L_E61E:
        sta  S_0665                 ; E61E  8D 92 94
        sta  S_0664                 ; E621  8D 91 94
        sta  S_0555                 ; E624  8D 55 94
        lsr  S_04D5                 ; E627  4E 2D 94
        ldx  PROMPTCH               ; E62A  A6 33
        cpx  #$80                   ; E62C  E0 80
        bne  L_E63A                 ; E62E  D0 0A
        ldx  CV                     ; E630  A6 25
        cpx  S_055C                 ; E632  EC 5C 94
        bne  L_E63A                 ; E635  D0 03
        lda  S_055B                 ; E637  AD 5B 94
L_E63A:
        sta  CH                     ; E63A  85 24
L_E63C:
        bit  ZJ+1                   ; E63C  2C A9 FF
        sta  S_0666                 ; E63F  8D 93 94
        ldx  #$00                   ; E642  A2 00
FETCHLINE:
        ldy  WNDBTM                 ; E644  A4 23
        lda  #$FF                   ; E646  A9 FF
        sta  $1C61,y                ; E648  99 61 1C
        lda  WNDWDTH                ; E64B  A5 21
        pha                         ; E64D  48
        ldy  CV                     ; E64E  A4 25
        bpl  L_E6AD                 ; E650  10 5B
L_E652:
        sty  WNDWDTH                ; E652  84 21
L_E654:
        ldy  CH                     ; E654  A4 24
L_E656:
        lda  (BASL),y               ; E656  B1 28
        cmp  #$9F                   ; E658  C9 9F
        beq  L_E69F                 ; E65A  F0 43
        bit  S_0666                 ; E65C  2C 93 94
        bmi  L_E697                 ; E65F  30 36
        lda  (BASL),y               ; E661  B1 28
        bmi  L_E6D6                 ; E663  30 71
        sta  LEAD                   ; E665  8D 9E 94
        iny                         ; E668  C8
        tya                         ; E669  98
        pha                         ; E66A  48
        lda  (BASL),y               ; E66B  B1 28
        sta  TRAIL                  ; E66D  8D 9F 94
        bit  S_0665                 ; E670  2C 92 94
        bmi  L_E67F                 ; E673  30 0A
        lda  #$8B                   ; E675  A9 8B
        sta  INBUF,x                ; E677  9D 00 02
        sec                         ; E67A  38
        ror  S_0665                 ; E67B  6E 92 94
        inx                         ; E67E  E8
L_E67F:
        jsr  EMITKEY                ; E67F  20 94 F3
        pla                         ; E682  68
        tay                         ; E683  A8
L_E684:
        cpx  #$F0                   ; E684  E0 F0
        bcc  L_E69F                 ; E686  90 17
        pla                         ; E688  68
        sta  WNDWDTH                ; E689  85 21
L_E68B:
        sty  CH                     ; E68B  84 24
        jsr  L_F417+2               ; E68D  20 19 F4
        ldx  S_0556                 ; E690  AE 56 94
        ldy  CH                     ; E693  A4 24
        sec                         ; E695  38
        rts                         ; E696  60
L_E697:
        sta  INBUF,x                ; E697  9D 00 02
        inx                         ; E69A  E8
        cpx  #$FC                   ; E69B  E0 FC
        bcs  L_E6C0                 ; E69D  B0 21
L_E69F:
        iny                         ; E69F  C8
        cpy  WNDWDTH                ; E6A0  C4 21
        bcc  L_E656                 ; E6A2  90 B2
        jsr  L_E7C1                 ; E6A4  20 C1 E7
        bcs  L_E6C0                 ; E6A7  B0 17
        jsr  FIXCONT                ; was lda #0 / sta CH: start at column 0, or 1 after the "]" mark
        nop
L_E6AD:
        lda  $1C62,y                ; E6AD  B9 62 1C
        bpl  L_E654                 ; E6B0  10 A2
        ldy  WNDWDTH                ; E6B2  A4 21
L_E6B4:
        dey                         ; E6B4  88
        bmi  L_E6C0                 ; E6B5  30 09
        lda  (BASL),y               ; E6B7  B1 28
        cmp  #$A0                   ; E6B9  C9 A0
        beq  L_E6B4                 ; E6BB  F0 F7
        iny                         ; E6BD  C8
        bne  L_E652                 ; E6BE  D0 92
L_E6C0:
        pla                         ; E6C0  68
        ldy  WNDWDTH                ; E6C1  A4 21
        sty  CH                     ; E6C3  84 24
        sta  WNDWDTH                ; E6C5  85 21
        lda  #$00                   ; E6C7  A9 00
        sta  S_04D7                 ; E6C9  8D 2F 94
        jsr  CLOSERUN               ; was lda #$8D / sta INBUF,x: close an open Hangul run, then the CR
        nop
        nop
        stx  S_066C                 ; E6D1  8E 99 94
        clc                         ; E6D4  18
        rts                         ; E6D5  60
L_E6D6:
        sty  S_0552                 ; E6D6  8C 52 94
        pha                         ; E6D9  48
        cmp  #$A2                   ; E6DA  C9 A2
        bne  L_E6ED                 ; E6DC  D0 0F
        lda  S_0555                 ; E6DE  AD 55 94
        eor  #$FF                   ; E6E1  49 FF
        sta  S_0555                 ; E6E3  8D 55 94
        bmi  L_E715                 ; E6E6  30 2D
        bit  S_0665                 ; E6E8  2C 92 94
        bmi  L_E70C                 ; E6EB  30 1F
L_E6ED:
        bit  S_0665                 ; E6ED  2C 92 94
        bpl  L_E715                 ; E6F0  10 23
        cmp  #$A1                   ; E6F2  C9 A1
        bcc  L_E715                 ; E6F4  90 1F
        cmp  #$E1                   ; E6F6  C9 E1
        bcc  L_E6FC                 ; E6F8  90 02
        eor  #$20                   ; E6FA  49 20
L_E6FC:
        cmp  #$DB                   ; E6FC  C9 DB
        bcs  L_E715                 ; E6FE  B0 15
        cmp  #$C1                   ; E700  C9 C1
        bcs  L_E70C                 ; E702  B0 08
        sbc  #$9F                   ; E704  E9 9F
        tay                         ; E706  A8
        lda  D_E2A0,y               ; E707  B9 A0 E2
        bpl  L_E715                 ; E70A  10 09
L_E70C:
        lda  #$81                   ; E70C  A9 81
        sta  INBUF,x                ; E70E  9D 00 02
        lsr  S_0665                 ; E711  4E 92 94
        inx                         ; E714  E8
L_E715:
        pla                         ; E715  68
        ldy  S_0552                 ; E716  AC 52 94
        jsr  SKIPPR                 ; E719  20 5E D6
        nop                         ; E71C  EA
        jmp  L_E684                 ; E71D  4C 84 E6
D_E720:
        ora  #$80                   ; E720  09 80
        sta  INBUF,x                ; E722  9D 00 02
        inx                         ; E725  E8
        rts                         ; E726  60
L_E727:
        pla                         ; E727  68
        rts                         ; E728  60
L_E729:
        clc                         ; E729  18
        adc  S_04D7                 ; E72A  6D 2F 94
        sta  S_0663                 ; E72D  8D 90 94
        jsr  L_EB41                 ; E730  20 41 EB
L_E733:
        lda  #$FF                   ; E733  A9 FF
        ldy  WNDBTM                 ; E735  A4 23
        sta  $1C61,y                ; E737  99 61 1C
L_E73A:
        ldy  CV                     ; E73A  A4 25
        lda  $1C62,y                ; E73C  B9 62 1C
        pha                         ; E73F  48
        ldx  S_0663                 ; E740  AE 90 94
        cpx  S_0664                 ; E743  EC 91 94
        bcs  L_E727                 ; E746  B0 DF
        lda  INBUF,x                ; E748  BD 00 02
        eor  #$80                   ; E74B  49 80
        sta  CHAR                   ; E74D  8D AD 94
        bpl  L_E772                 ; E750  10 20
        sta  LEAD                   ; E752  8D 9E 94
        lda  $0201,x                ; E755  BD 01 02
        sta  TRAIL                  ; E758  8D 9F 94
        lda  WNDWDTH                ; E75B  A5 21
        clc                         ; E75D  18
        sbc  CH                     ; E75E  E5 24
        beq  L_E76A                 ; E760  F0 08
        jsr  DRAWKO                 ; E762  20 BC F1
        inc  S_0663                 ; E765  EE 90 94
        bne  L_E775                 ; E768  D0 0B
L_E76A:
        lda  #$9F                   ; E76A  A9 9F
        jsr  COUT                   ; E76C  20 63 EE
        jmp  L_E778                 ; E76F  4C 78 E7
L_E772:
        jsr  L_F164                 ; E772  20 64 F1
L_E775:
        inc  S_0663                 ; E775  EE 90 94
L_E778:
        jsr  L_EB41                 ; E778  20 41 EB
        pla                         ; E77B  68
        bpl  L_E73A                 ; E77C  10 BC
        lda  CH                     ; E77E  A5 24
        bne  L_E73A                 ; E780  D0 B8
        ldy  CV                     ; E782  A4 25
        lda  #$FF                   ; E784  A9 FF
        sta  $1C61,y                ; E786  99 61 1C
        lda  WNDTOP                 ; E789  A5 22
        pha                         ; E78B  48
        lda  CV                     ; E78C  A5 25
        sta  WNDTOP                 ; E78E  85 22
        jsr  L_ED82                 ; E790  20 82 ED
        pla                         ; E793  68
        sta  WNDTOP                 ; E794  85 22
        ldy  CV                     ; E796  A4 25
        lda  #$00                   ; E798  A9 00
        sta  $1C61,y                ; E79A  99 61 1C
        iny                         ; E79D  C8
        cpy  WNDBTM                 ; E79E  C4 23
        bcc  L_E73A                 ; E7A0  90 98
        lda  $1C61,y                ; E7A2  B9 61 1C
        bmi  L_E73A                 ; E7A5  30 93
        lda  WNDTOP                 ; E7A7  A5 22
        cmp  S_0559                 ; E7A9  CD 59 94
        dec  S_0559                 ; E7AC  CE 59 94
        bcc  L_E733                 ; E7AF  90 82
        inc  S_0559                 ; E7B1  EE 59 94
        lda  S_04D7                 ; E7B4  AD 2F 94
        clc                         ; E7B7  18
        adc  WNDWDTH                ; E7B8  65 21
        sta  S_04D7                 ; E7BA  8D 2F 94
        jmp  L_E733                 ; E7BD  4C 33 E7
L_E7C0:
        rts                         ; E7C0  60
L_E7C1:
        ldy  CV                     ; E7C1  A4 25
        iny                         ; E7C3  C8
        cpy  WNDBTM                 ; E7C4  C4 23
        beq  L_E7C0                 ; E7C6  F0 F8
        sec                         ; E7C8  38
        lda  $1C61,y                ; E7C9  B9 61 1C
        bmi  L_E7C0                 ; E7CC  30 F2
L_E7CE:
        tya                         ; E7CE  98
        sta  CV                     ; E7CF  85 25
        jmp  L_EC73                 ; E7D1  4C 73 EC
L_E7D4:
        ldy  CV                     ; E7D4  A4 25
L_E7D6:
        lda  $1C61,y                ; E7D6  B9 61 1C
        bmi  L_E7CE                 ; E7D9  30 F3
        dey                         ; E7DB  88
        bmi  L_E7E2                 ; E7DC  30 04
        cpy  WNDTOP                 ; E7DE  C4 22
        bcs  L_E7D6                 ; E7E0  B0 F4
L_E7E2:
        iny                         ; E7E2  C8
        sty  CV                     ; E7E3  84 25
        ldy  #$00                   ; E7E5  A0 00
        jmp  L_E68B                 ; E7E7  4C 8B E6
L_E7EA:
        bit  S_04D1                 ; E7EA  2C 29 94
        bpl  L_E7F2                 ; E7ED  10 03
        jsr  L_E948                 ; E7EF  20 48 E9
L_E7F2:
        jsr  L_EAF1                 ; E7F2  20 F1 EA
        cmp  #$A0                   ; E7F5  C9 A0
        bcc  L_E83E                 ; E7F7  90 45
L_E7F9:
        jsr  SHFIX                  ; was bit HMODE: Shift+R E Q T W O P become the double consonant keys
        bpl  L_E82B                 ; E7FC  10 2D
        pha                         ; E7FE  48
        and  #$7F                   ; E7FF  29 7F
        jsr  MAPKEY                 ; E801  20 FD EE
        bcc  L_E82C                 ; E804  90 26
        bpl  L_E82C                 ; E806  10 24
        lda  CH                     ; E808  A5 24
        sta  S_0557                 ; E80A  8D 57 94
        ldx  S_04D0                 ; E80D  AE 28 94
        beq  L_E820                 ; E810  F0 0E
        ldx  #$00                   ; E812  A2 00
L_E814:
        lda  S_065D,x               ; E814  BD 8A 94
        jsr  COUT                   ; E817  20 63 EE
        inx                         ; E81A  E8
        cpx  S_04D0                 ; E81B  EC 28 94
        bcc  L_E814                 ; E81E  90 F4
L_E820:
        pla                         ; E820  68
        sta  S_065D,x               ; E821  9D 8A 94
        inc  S_04D0                 ; E824  EE 28 94
        sec                         ; E827  38
        ror  S_04D1                 ; E828  6E 29 94
L_E82B:
        rts                         ; E82B  60
L_E82C:
        lda  S_04D0                 ; E82C  AD 28 94
        beq  L_E83C                 ; E82F  F0 0B
        jsr  L_EBF1                 ; E831  20 F1 EB
        jsr  L_EBF1                 ; E834  20 F1 EB
L_E837:
        lda  #$00                   ; E837  A9 00
        sta  S_04D0                 ; E839  8D 28 94
L_E83C:
        pla                         ; E83C  68
        rts                         ; E83D  60
L_E83E:
        bit  S_04D8                 ; E83E  2C 30 94
        bmi  L_E7F9                 ; E841  30 B6
        cmp  #$8D                   ; E843  C9 8D
        beq  L_E857                 ; E845  F0 10
        pha                         ; E847  48
        cmp  #$9B                   ; E848  C9 9B
        beq  L_E837                 ; E84A  F0 EB
        pla                         ; E84C  68
        cmp  #$80                   ; E84D  C9 80
        bne  L_E7F9                 ; E84F  D0 A8
        ror  S_04D8                 ; E851  6E 30 94
        bmi  L_E7EA                 ; E854  30 94
        rts                         ; E856  60
L_E857:
        bit  S_04D6                 ; E857  2C 2E 94
        bpl  L_E7F9                 ; E85A  10 9D
        jsr  L_E473                 ; E85C  20 73 E4
        bcs  L_E863                 ; E85F  B0 02
        bne  L_E86E                 ; E861  D0 0B
L_E863:
        jsr  L_E872                 ; E863  20 72 E8
        stx  S_0556                 ; E866  8E 56 94
        bcc  L_E86E                 ; E869  90 03
        jmp  L_E7EA                 ; E86B  4C EA E7
L_E86E:
        lda  #$8D                   ; E86E  A9 8D
L_E870:
        clc                         ; E870  18
L_E871:
        rts                         ; E871  60
L_E872:
        lda  #$00                   ; E872  A9 00
        sta  S_04D0                 ; E874  8D 28 94
        jsr  L_E7D4                 ; E877  20 D4 E7
        bcs  L_E871                 ; E87A  B0 F5
        jsr  L_E60E                 ; E87C  20 0E E6
        bcs  L_E871                 ; E87F  B0 F0
        rts                         ; E881  60
L_E882:
        lda  PROMPTCH               ; E882  A5 33
        cmp  #$DD                   ; E884  C9 DD
        bne  L_E870                 ; E886  D0 E8
        ldx  #$00                   ; E888  A2 00
        stx  S_055A                 ; E88A  8E 5A 94
        dex                         ; E88D  CA
L_E88E:
        ldy  #$FF                   ; E88E  A0 FF
L_E890:
        iny                         ; E890  C8
        lda  INBUF,y                ; E891  B9 00 02
        cmp  #$A0                   ; E894  C9 A0
        beq  L_E890                 ; E896  F0 F8
L_E898:
        bit  $C8                    ; E898  24 C8
        inx                         ; E89A  E8
        lda  INBUF,y                ; E89B  B9 00 02
        sec                         ; E89E  38
        sbc  D_E92C,x               ; E89F  FD 2C E9
        beq  L_E898+1               ; E8A2  F0 F5
        asl  a                      ; E8A4  0A
        beq  L_E8CB                 ; E8A5  F0 24
        lda  INBUF,y                ; E8A7  B9 00 02
        cmp  #$A0                   ; E8AA  C9 A0
        beq  L_E8B2                 ; E8AC  F0 04
        cmp  #$8D                   ; E8AE  C9 8D
        bne  L_E8BC                 ; E8B0  D0 0A
L_E8B2:
        txa                         ; E8B2  8A
        ldx  S_055A                 ; E8B3  AE 5A 94
        cmp  D_E928,x               ; E8B6  DD 28 E9
        tax                         ; E8B9  AA
        bcs  L_E8CC                 ; E8BA  B0 10
L_E8BC:
        inc  S_055A                 ; E8BC  EE 5A 94
        bne  L_E8C2                 ; E8BF  D0 01
L_E8C1:
        inx                         ; E8C1  E8
L_E8C2:
        lda  D_E92C,x               ; E8C2  BD 2C E9
        beq  L_E870                 ; E8C5  F0 A9
        bmi  L_E8C1                 ; E8C7  30 F8
        bne  L_E88E                 ; E8C9  D0 C3
L_E8CB:
        iny                         ; E8CB  C8
L_E8CC:
        lda  INBUF,y                ; E8CC  B9 00 02
        cmp  #$A0                   ; E8CF  C9 A0
        beq  L_E8CB                 ; E8D1  F0 F8
        lsr  S_04D6                 ; E8D3  4E 2E 94
        lda  #$8D                   ; E8D6  A9 8D
        ldx  #$FF                   ; E8D8  A2 FF
        jsr  L_F6CC                 ; E8DA  20 CC F6
        lda  #$00                   ; E8DD  A9 00
        ldx  S_066C                 ; E8DF  AE 99 94
        sta  INBUF,x                ; E8E2  9D 00 02
        lda  #$E8                   ; E8E5  A9 E8
        pha                         ; E8E7  48
        lda  #$FE                   ; E8E8  A9 FE
        pha                         ; E8EA  48
        lda  S_055A                 ; E8EB  AD 5A 94
        asl  a                      ; E8EE  0A
        tax                         ; E8EF  AA
        lda  D_E941,x               ; E8F0  BD 41 E9
        pha                         ; E8F3  48
        lda  D_E940,x               ; E8F4  BD 40 E9
        pha                         ; E8F7  48
        lsr  S_055E                 ; E8F8  4E 5E 94
        lda  INBUF,y                ; E8FB  B9 00 02
        rts                         ; E8FE  60
        bcc  L_E909                 ; E8FF  90 08
        jsr  L_F6DA                 ; E901  20 DA F6
        lda  #$8D                   ; E904  A9 8D
        jsr  L_F6CC                 ; E906  20 CC F6
L_E909:
        sec                         ; E909  38
        ror  S_04D6                 ; E90A  6E 2E 94
        lsr  S_04D8                 ; E90D  4E 30 94
        sec                         ; E910  38
        rts                         ; E911  60
L_E912:
        sty  $B8                    ; E912  84 B8
        lda  #$02                   ; E914  A9 02
        sta  $B9                    ; E916  85 B9
L_E918:
        lda  INBUF,y                ; E918  B9 00 02
        beq  L_E925                 ; E91B  F0 08
        and  #$7F                   ; E91D  29 7F
        sta  INBUF,y                ; E91F  99 00 02
        iny                         ; E922  C8
        bne  L_E918                 ; E923  D0 F3
L_E925:
        jmp  a:$00B7                ; E925  4C B7 00
D_E928:
        .byte $01,$07,$0C,$10       ; E928
D_E92C:
        .byte $CC,$C9,$D3,$54,$C3,$CF,$CE,$D6,$C5,$D2,$54,$C6,$C9,$CE,$44,$C5; E92C
        .byte $C4,$C9,$54,$00       ; E93C
D_E940:
        .byte $00                   ; E940
D_E941:
        .byte $F6,$98,$F4,$15,$F8,$E8,$F5; E941
L_E948:
        lda  #$8B                   ; E948  A9 8B
        jsr  COUT                   ; E94A  20 63 EE
        lsr  S_04D1                 ; E94D  4E 29 94
        jsr  L_E9A4                 ; E950  20 A4 E9
        jsr  L_E9A4                 ; E953  20 A4 E9
        sec                         ; E956  38
        lda  CH                     ; E957  A5 24
        sbc  S_0557                 ; E959  ED 57 94
        beq  L_E98B                 ; E95C  F0 2D
        ldx  #$00                   ; E95E  A2 00
        ldy  CH                     ; E960  A4 24
        lda  (BASL),y               ; E962  B1 28
        bit  D_E98C                 ; E964  2C 8C E9
        beq  L_E97E                 ; E967  F0 15
        and  #$03                   ; E969  29 03
        bne  L_E974                 ; E96B  D0 07
        iny                         ; E96D  C8
        lda  (BASL),y               ; E96E  B1 28
        cmp  #$41                   ; E970  C9 41
        beq  L_E97E                 ; E972  F0 0A
L_E974:
        ldy  S_04D0                 ; E974  AC 28 94
        lda  S_065B,y               ; E977  B9 88 94
        sta  S_065D,x               ; E97A  9D 8A 94
        inx                         ; E97D  E8
L_E97E:
        ldy  S_04D0                 ; E97E  AC 28 94
        lda  S_065C,y               ; E981  B9 89 94
        sta  S_065D,x               ; E984  9D 8A 94
        inx                         ; E987  E8
        stx  S_04D0                 ; E988  8E 28 94
L_E98B:
        rts                         ; E98B  60
D_E98C:
        sei                         ; E98C  78
L_E98D:
        ldy  #$00                   ; E98D  A0 00
L_E98F:
        lda  (BASL),y               ; E98F  B1 28
        bmi  L_E99B                 ; E991  30 08
        lda  #$00                   ; E993  A9 00
        sta  S_05D0,y               ; E995  99 78 94
        iny                         ; E998  C8
        lda  #$01                   ; E999  A9 01
L_E99B:
        sta  S_05D0,y               ; E99B  99 78 94
        iny                         ; E99E  C8
        cpy  WNDWDTH                ; E99F  C4 21
        bcc  L_E98F                 ; E9A1  90 EC
L_E9A3:
        rts                         ; E9A3  60
L_E9A4:
        jmp  NOLEFT                 ; E9A4  4C 6B D6
        .byte $FB                   ; E9A7
L_E9A8:
        inc  CH                     ; E9A8  E6 24
        lda  CV                     ; E9AA  A5 25
        cmp  WNDTOP                 ; E9AC  C5 22
        beq  L_E9A3                 ; E9AE  F0 F3
        ldy  WNDWDTH                ; E9B0  A4 21
        dey                         ; E9B2  88
        sty  CH                     ; E9B3  84 24
L_E9B5:
        lda  WNDTOP                 ; E9B5  A5 22
        cmp  CV                     ; E9B7  C5 25
        bcs  L_E9A3                 ; E9B9  B0 E8
        dec  CV                     ; E9BB  C6 25
        jsr  L_EC71                 ; E9BD  20 71 EC
        ldy  CH                     ; E9C0  A4 24
        lda  (BASL),y               ; E9C2  B1 28
        cmp  #$9F                   ; E9C4  C9 9F
        beq  L_E9A4                 ; E9C6  F0 DC
        rts                         ; E9C8  60
L_E9C9:
        ldy  CH                     ; E9C9  A4 24
L_E9CB:
        bit  a:$00A0                ; E9CB  2C A0 00
        jsr  L_EC4E                 ; E9CE  20 4E EC
        jsr  L_ED38                 ; E9D1  20 38 ED
        jsr  L_E7C1                 ; E9D4  20 C1 E7
        bcs  L_E9E2                 ; E9D7  B0 09
        ldy  CV                     ; E9D9  A4 25
        lda  #$FF                   ; E9DB  A9 FF
        sta  $1C61,y                ; E9DD  99 61 1C
        bcc  L_E9CB+1               ; E9E0  90 EA
L_E9E2:
        jmp  RESTCUR                ; E9E2  4C 02 EE
L_E9E5:
        jsr  SAVECUR                ; E9E5  20 F7 ED
        jsr  L_E9C9                 ; E9E8  20 C9 E9
        bcc  L_EA5F                 ; E9EB  90 72
L_E9ED:
        jsr  L_E9F3                 ; E9ED  20 F3 E9
        jmp  L_EA0B                 ; E9F0  4C 0B EA
L_E9F3:
        txa                         ; E9F3  8A
        ldy  #$03                   ; E9F4  A0 03
L_E9F6:
        cmp  D_FC47,y               ; E9F6  D9 47 FC
        beq  L_EA1D                 ; E9F9  F0 22
        cmp  D_FC4F,y               ; E9FB  D9 4F FC
        beq  L_EA1D                 ; E9FE  F0 1D
        cmp  D_FC53,y               ; EA00  D9 53 FC
        beq  L_EA1D                 ; EA03  F0 18
        dey                         ; EA05  88
        bpl  L_E9F6                 ; EA06  10 EE
        pla                         ; EA08  68
        pla                         ; EA09  68
        rts                         ; EA0A  60
L_EA0B:
        lda  #$00                   ; EA0B  A9 00
        sta  S_04D0                 ; EA0D  8D 28 94
        sta  S_04D1                 ; EA10  8D 29 94
        jsr  L_EAF1                 ; EA13  20 F1 EA
        tax                         ; EA16  AA
        eor  #$C0                   ; EA17  49 C0
        beq  CLEARHOME              ; EA19  F0 1C
        tay                         ; EA1B  A8
        dey                         ; EA1C  88
L_EA1D:
        iny                         ; EA1D  C8
        dey                         ; EA1E  88
        beq  L_EA9F                 ; EA1F  F0 7E
        dey                         ; EA21  88
        beq  L_EA7A                 ; EA22  F0 56
        dey                         ; EA24  88
        beq  L_EA6B                 ; EA25  F0 44
        dey                         ; EA27  88
        beq  L_EA65                 ; EA28  F0 3B
        dey                         ; EA2A  88
        beq  L_E9E5                 ; EA2B  F0 B8
        dey                         ; EA2D  88
        bne  L_E9ED                 ; EA2E  D0 BD
        jsr  SAVECUR                ; EA30  20 F7 ED
        ldy  CH                     ; EA33  A4 24
        bpl  L_EA47                 ; EA35  10 10
CLEARHOME:
        ldy  WNDTOP                 ; EA37  A4 22
        sty  CV                     ; EA39  84 25
        lda  #$FF                   ; EA3B  A9 FF
        sta  $1C61,y                ; EA3D  99 61 1C
        ldy  #$00                   ; EA40  A0 00
        sty  CH                     ; EA42  84 24
        jsr  SAVECUR                ; EA44  20 F7 ED
L_EA47:
        jsr  L_EC4E                 ; EA47  20 4E EC
        jsr  L_ED38                 ; EA4A  20 38 ED
        ldy  #$00                   ; EA4D  A0 00
        ldx  CV                     ; EA4F  A6 25
        inx                         ; EA51  E8
        cpx  WNDBTM                 ; EA52  E4 23
        bcs  L_EA5F                 ; EA54  B0 09
        stx  CV                     ; EA56  86 25
        lda  #$FF                   ; EA58  A9 FF
        sta  $1C61,x                ; EA5A  9D 61 1C
        bmi  L_EA47                 ; EA5D  30 E8
L_EA5F:
        lsr  S_04D5                 ; EA5F  4E 2D 94
        jmp  RESTCUR                ; EA62  4C 02 EE
L_EA65:
        jsr  L_E9B5                 ; EA65  20 B5 E9
        jmp  L_EA7D                 ; EA68  4C 7D EA
L_EA6B:
        ldy  CV                     ; EA6B  A4 25
        iny                         ; EA6D  C8
        cpy  WNDBTM                 ; EA6E  C4 23
        bcs  L_EAD2                 ; EA70  B0 60
        tya                         ; EA72  98
        sta  CV                     ; EA73  85 25
        jsr  L_EC73                 ; EA75  20 73 EC
        bcc  L_EA7D                 ; EA78  90 03
L_EA7A:
        jsr  L_E9A4                 ; EA7A  20 A4 E9
L_EA7D:
        jsr  L_E98D                 ; EA7D  20 8D E9
        ldy  CH                     ; EA80  A4 24
        lda  S_05D0,y               ; EA82  B9 78 94
        bmi  L_EA8D                 ; EA85  30 06
        lsr  a                      ; EA87  4A
        bcc  L_EA8D                 ; EA88  90 03
        jsr  L_E9A4                 ; EA8A  20 A4 E9
L_EA8D:
        bit  S_04D5                 ; EA8D  2C 2D 94
        clc                         ; EA90  18
        bpl  L_EAD2                 ; EA91  10 3F
L_EA93:
        jsr  SAVECUR                ; EA93  20 F7 ED
        jsr  L_E63C+1               ; EA96  20 3D E6
        stx  S_0664                 ; EA99  8E 91 94
        jmp  RESTCUR                ; EA9C  4C 02 EE
L_EA9F:
        jsr  L_EBF1                 ; EA9F  20 F1 EB
        jsr  L_E98D                 ; EAA2  20 8D E9
        clc                         ; EAA5  18
        ldy  CH                     ; EAA6  A4 24
        lda  S_05D0,y               ; EAA8  B9 78 94
        bmi  L_EAB4                 ; EAAB  30 07
        lsr  a                      ; EAAD  4A
        bcc  L_EAB4                 ; EAAE  90 04
        jsr  L_EBF1                 ; EAB0  20 F1 EB
        sec                         ; EAB3  38
L_EAB4:
        bit  S_04D5                 ; EAB4  2C 2D 94
        bpl  L_EAD2                 ; EAB7  10 19
        lda  S_04D7                 ; EAB9  AD 2F 94
        adc  #$01                   ; EABC  69 01
L_EABE:
        cmp  S_0664                 ; EABE  CD 91 94
        bcc  L_EACF                 ; EAC1  90 0C
        lda  #$01                   ; EAC3  A9 01
        sta  S_0664                 ; EAC5  8D 91 94
        lda  #$A0                   ; EAC8  A9 A0
        sta  INBUF                  ; EACA  8D 00 02
        lda  #$00                   ; EACD  A9 00
L_EACF:
        sta  S_04D7                 ; EACF  8D 2F 94
L_EAD2:
        rts                         ; EAD2  60
KEYREAD:
        stx  S_0556                 ; EAD3  8E 56 94
        sta  (BASL),y               ; EAD6  91 28
        tsx                         ; EAD8  BA
        inx                         ; EAD9  E8
        inx                         ; EADA  E8
        ldy  #$0C                   ; EADB  A0 0C
        jsr  L_EE22                 ; EADD  20 22 EE
        beq  L_EAE8                 ; EAE0  F0 06
        jsr  L_EAF1                 ; EAE2  20 F1 EA
        jmp  SHFIN                  ; was jmp L_EAEB: the Shift mod remap, then L_EAEB
L_EAE8:
        jsr  L_E7EA                 ; EAE8  20 EA E7
L_EAEB:
        ldx  S_0556                 ; EAEB  AE 56 94
        ldy  CH                     ; EAEE  A4 24
        rts                         ; EAF0  60
L_EAF1:
        jsr  DRAWPR                 ; EAF1  20 28 1F
        nop                         ; EAF4  EA
L_EAF5:
        jsr  WRAP                   ; EAF5  20 30 1F
        inc  S_0554                 ; EAF8  EE 54 94
        ldy  #$00                   ; EAFB  A0 00
L_EAFD:
        jsr  L_EB7C                 ; EAFD  20 7C EB
        bmi  L_EB28                 ; EB00  30 26
        inc  $4E                    ; EB02  E6 4E
        bne  L_EB08                 ; EB04  D0 02
        inc  $4F                    ; EB06  E6 4F
L_EB08:
        lda  PROMPTCH               ; EB08  A5 33
        cmp  #$AA                   ; EB0A  C9 AA
        beq  L_EAFD                 ; EB0C  F0 EF
        lda  #$11                   ; EB0E  A9 11
        jsr  L_E602                 ; EB10  20 02 E6
        tya                         ; EB13  98
        pha                         ; EB14  48
        and  #$03                   ; EB15  29 03
        tay                         ; EB17  A8
        lda  D_EB3D,y               ; EB18  B9 3D EB
        sta  S_0550                 ; EB1B  8D 50 94
        sta  S_0577                 ; EB1E  8D 77 94
        pla                         ; EB21  68
        tay                         ; EB22  A8
        dey                         ; EB23  88
        bne  L_EAFD                 ; EB24  D0 D7
        beq  L_EAF5                 ; EB26  F0 CD
L_EB28:
        pha                         ; EB28  48
        php                         ; EB29  08
        lsr  S_0554                 ; EB2A  4E 54 94
        bcs  L_EB32                 ; EB2D  B0 03
        jsr  L_EB98                 ; EB2F  20 98 EB
L_EB32:
        plp                         ; EB32  28
        bcs  L_EB3B                 ; EB33  B0 06
        bit  KBDSTRB                ; EB35  2C 10 C0
        jsr  L_F3C9                 ; EB38  20 C9 F3
L_EB3B:
        pla                         ; EB3B  68
        rts                         ; EB3C  60
D_EB3D:
        .byte $A1,$AF,$AD,$DC       ; EB3D
L_EB41:
        tya                         ; EB41  98
        pha                         ; EB42  48
        lda  KBD                    ; EB43  AD 00 C0
        bpl  L_EB79                 ; EB46  10 31
        cmp  #$83                   ; EB48  C9 83
        beq  L_EB50                 ; EB4A  F0 04
        cmp  #$93                   ; EB4C  C9 93
        bne  L_EB57                 ; EB4E  D0 07
L_EB50:
        lda  #$00                   ; EB50  A9 00
        sta  S_04D3                 ; EB52  8D 2B 94
        beq  L_EB79                 ; EB55  F0 22
L_EB57:
        ldy  S_04D3                 ; EB57  AC 2B 94
        cpy  #$1F                   ; EB5A  C0 1F
        beq  L_EB79                 ; EB5C  F0 1B
        iny                         ; EB5E  C8
        sty  S_04D3                 ; EB5F  8C 2B 94
        lda  S_04D4                 ; EB62  AD 2C 94
        adc  #$01                   ; EB65  69 01
        and  #$1F                   ; EB67  29 1F
        sta  S_04D4                 ; EB69  8D 2C 94
        tay                         ; EB6C  A8
        lda  KBD                    ; EB6D  AD 00 C0
        bit  KBDSTRB                ; EB70  2C 10 C0
        sta  S_06D0,y               ; EB73  99 C5 94
        jsr  L_F3C9                 ; EB76  20 C9 F3
L_EB79:
        pla                         ; EB79  68
        tay                         ; EB7A  A8
        rts                         ; EB7B  60
L_EB7C:
        clc                         ; EB7C  18
        lda  S_04D3                 ; EB7D  AD 2B 94
        beq  L_EB94                 ; EB80  F0 12
        dec  S_04D3                 ; EB82  CE 2B 94
        lda  S_04D4                 ; EB85  AD 2C 94
        sec                         ; EB88  38
        sbc  S_04D3                 ; EB89  ED 2B 94
        and  #$1F                   ; EB8C  29 1F
        tay                         ; EB8E  A8
        lda  S_06D0,y               ; EB8F  B9 C5 94
        sec                         ; EB92  38
        rts                         ; EB93  60
L_EB94:
        lda  KBD                    ; EB94  AD 00 C0
        rts                         ; EB97  60
L_EB98:
        ldy  CH                     ; EB98  A4 24
        lda  (BASL),y               ; EB9A  B1 28
        cmp  #$9F                   ; EB9C  C9 9F
        bne  L_EBA3                 ; EB9E  D0 03
        jsr  L_EBF1                 ; EBA0  20 F1 EB
L_EBA3:
        jsr  L_EC4E                 ; EBA3  20 4E EC
        jsr  CURSOR                 ; EBA6  20 AD D4
        rts                         ; EBA9  60

; ==========================================================================
; Stock draw routines, patched to jump to the faster blit above
; ==========================================================================
ENBLIT:
        ldx  #$00                   ; EBAA  A2 00
EL:
        cpx  #$02                   ; EBAC  E0 04
        bcs  ER                     ; EBAE  B0 04
        lda  #$00                   ; EBB0  A9 00
        beq  ES2                    ; EBB2  F0 10
ER:
        txa                         ; EBB4  8A
        sec                         ; EBB5  38
        sbc  #$02                   ; EBB6  E9 04
        tay                         ; EBB8  A8
        lda  (P0L),y                ; EBB9  B1 00
        cpx  #$0B                   ; EBBB  E0 0B
        bne  ES                     ; EBBD  D0 03
        ora  S_06B0                 ; EBBF  0D A5 94
ES:
        and  #$3F                   ; EBC2  29 3F
ES2:
        sta  GLY,x                  ; EBC4  9D 90 1C
        lda  #$00                   ; EBC7  A9 00
        sta  GLYHI,x                ; EBC9  9D 9C 1C
        inx                         ; EBCC  E8
        cpx  #$0C                   ; EBCD  E0 0C
        bne  EL                     ; EBCF  D0 DB
        lda  #$06                   ; EBD1  A9 06
        sta  P1L                    ; EBD3  85 02
        jmp  BLIT                   ; EBD5  4C 00 D4
KOBLIT:
        jsr  KOFILL                 ; EBD8  20 F1 FE
        lda  #$0C                   ; EBDB  A9 0C
        sta  P1L                    ; EBDD  85 02
        jmp  BLIT                   ; EBDF  4C 00 D4
        .byte $53                   ; EBE2
        ora  $C9                    ; EBE3  05 C9
        ora  ($90),y                ; EBE5  11 90
L_EBE7:
        cmp  $60,x                  ; EBE7  D5 60
L_EBE9:
        ldy  CH                     ; EBE9  A4 24
        lda  (BASL),y               ; EBEB  B1 28
        cmp  #$9F                   ; EBED  C9 9F
        bne  L_EBE7+1               ; EBEF  D0 F7
L_EBF1:
        inc  CH                     ; EBF1  E6 24
        lda  CH                     ; EBF3  A5 24
        cmp  WNDWDTH                ; EBF5  C5 21
        bcc  L_EBE9                 ; EBF7  90 F0
        jmp  L_EC8F                 ; EBF9  4C 8F EC
        ldy  KBD                    ; EBFC  AC 00 C0
        bpl  L_EC14                 ; EBFF  10 13
        cpy  #$93                   ; EC01  C0 93
        bne  L_EC14                 ; EC03  D0 0F
        bit  KBDSTRB                ; EC05  2C 10 C0
L_EC08:
        ldy  KBD                    ; EC08  AC 00 C0
        bpl  L_EC08                 ; EC0B  10 FB
        cpy  #$83                   ; EC0D  C0 83
        beq  L_EC14                 ; EC0F  F0 03
        bit  KBDSTRB                ; EC11  2C 10 C0
L_EC14:
        lda  #$06                   ; EC14  A9 06
        tay                         ; EC16  A8
        jsr  L_EE1D                 ; EC17  20 1D EE
        bne  L_EC27                 ; EC1A  D0 0B
        ldy  $0102,x                ; EC1C  BC 02 01
        dey                         ; EC1F  88
        beq  L_EC8F                 ; EC20  F0 6D
        dec  $0102,x                ; EC22  DE 02 01
        bne  L_EC8F                 ; EC25  D0 68
L_EC27:
        ldy  CH                     ; EC27  A4 24
        bne  L_EC8F                 ; EC29  D0 64
        lda  #$04                   ; EC2B  A9 04
        ldy  #$02                   ; EC2D  A0 02
        jsr  L_EE1D                 ; EC2F  20 1D EE
        bne  L_EC8F                 ; EC32  D0 5B
L_EC34:
        rts                         ; EC34  60
L_EC35:
        ldy  CH                     ; EC35  A4 24
        sta  (BASL),y               ; EC37  91 28
        inc  CH                     ; EC39  E6 24
        lda  CH                     ; EC3B  A5 24
        cmp  WNDWDTH                ; EC3D  C5 21
        bcc  L_EC34                 ; EC3F  90 F3
        ldy  CV                     ; EC41  A4 25
        lda  #$00                   ; EC43  A9 00
        sta  $1C62,y                ; EC45  99 62 1C
        lda  #$00                   ; EC48  A9 00
        sta  CH                     ; EC4A  85 24
        beq  L_EC9A                 ; EC4C  F0 4C
L_EC4E:
        lda  CV                     ; EC4E  A5 25
L_EC50:
        stx  S_0551                 ; EC50  8E 51 94
        pha                         ; EC53  48
        jsr  L_EC7B                 ; EC54  20 7B EC
        stx  S_0555                 ; EC57  8E 55 94
        pla                         ; EC5A  68
L_EC5B:
        jmp  ROWPTR                 ; EC5B  4C 7F F1
        tax                         ; EC5E  AA
        lda  HGRLO,x                ; EC5F  BD DC E0
        adc  WNDLFT                 ; EC62  65 20
        sta  BASL                   ; EC64  85 28
        lda  HGRHI,x                ; EC66  BD 9C E1
        adc  #$04                   ; EC69  69 04
        sta  BASH                   ; EC6B  85 29
        ldx  S_0551                 ; EC6D  AE 51 94
        rts                         ; EC70  60
L_EC71:
        lda  CV                     ; EC71  A5 25
L_EC73:
        stx  S_0551                 ; EC73  8E 51 94
        jmp  L_EC5B                 ; EC76  4C 5B EC
        .byte $A5,$25               ; EC79
L_EC7B:
        jmp  PIXY                   ; EC7B  4C 98 F2
        asl  a                      ; EC7E  0A
        tax                         ; EC7F  AA
        lda  HGRLO,x                ; EC80  BD DC E0
        adc  WNDLFT                 ; EC83  65 20
        sta  $FC                    ; EC85  85 FC
        lda  HGRHI,x                ; EC87  BD 9C E1
        ora  $E6                    ; EC8A  05 E6
        sta  $FD                    ; EC8C  85 FD
        rts                         ; EC8E  60
L_EC8F:
        lda  #$00                   ; EC8F  A9 00
        sta  CH                     ; EC91  85 24
L_EC93:
        ldy  WNDBTM                 ; EC93  A4 23
        lda  #$FF                   ; EC95  A9 FF
        sta  $1C61,y                ; EC97  99 61 1C
L_EC9A:
        jsr  NLHOOK                 ; was inc CV / lda CV: in strip mode the row is shown first
        nop
        cmp  WNDBTM                 ; EC9E  C5 23
        bcc  L_EC4E                 ; ECA0  90 AC
        dec  CV                     ; ECA2  C6 25
        ldx  WNDTOP                 ; ECA4  A6 22
        txa                         ; ECA6  8A
        jsr  L_EC73                 ; ECA7  20 73 EC
L_ECAA:
        lda  BASL                   ; ECAA  A5 28
        sta  $2A                    ; ECAC  85 2A
        lda  BASH                   ; ECAE  A5 29
        sta  $2B                    ; ECB0  85 2B
        inx                         ; ECB2  E8
        lda  $1C61,x                ; ECB3  BD 61 1C
        sta  FLAGS,x                ; ECB6  9D 60 1C
        txa                         ; ECB9  8A
        cmp  WNDBTM                 ; ECBA  C5 23
        bcs  L_ECCD                 ; ECBC  B0 0F
        ldy  WNDWDTH                ; ECBE  A4 21
        dey                         ; ECC0  88
        jsr  L_EC73                 ; ECC1  20 73 EC
L_ECC4:
        lda  (BASL),y               ; ECC4  B1 28
        sta  ($2A),y                ; ECC6  91 2A
        dey                         ; ECC8  88
        bpl  L_ECC4                 ; ECC9  10 F9
        bmi  L_ECAA                 ; ECCB  30 DD
L_ECCD:
        jsr  HSUP                   ; ECCD  20 AC D5
        jmp  L_ED2C                 ; ECD0  4C 2C ED
SWAP6:
        lda  P0L                    ; ECD3  A5 00
        ldx  S_06C2                 ; ECD5  AE B7 94
        stx  P0L                    ; ECD8  86 00
        sta  S_06C2                 ; ECDA  8D B7 94
        lda  P0H                    ; ECDD  A5 01
        ldx  S_06C3                 ; ECDF  AE B8 94
        stx  P0H                    ; ECE2  86 01
        sta  S_06C3                 ; ECE4  8D B8 94
        lda  P1L                    ; ECE7  A5 02
        ldx  S_06C4                 ; ECE9  AE B9 94
        stx  P1L                    ; ECEC  86 02
        sta  S_06C4                 ; ECEE  8D B9 94
        lda  P1H                    ; ECF1  A5 03
        ldx  S_06C5                 ; ECF3  AE BA 94
        stx  P1H                    ; ECF6  86 03
        sta  S_06C5                 ; ECF8  8D BA 94
        lda  P2L                    ; ECFB  A5 04
        ldx  S_06C6                 ; ECFD  AE BB 94
        stx  P2L                    ; ED00  86 04
        sta  S_06C6                 ; ED02  8D BB 94
        lda  P2H                    ; ED05  A5 05
        ldx  S_06C7                 ; ED07  AE BC 94
        stx  P2H                    ; ED0A  86 05
        sta  S_06C7                 ; ED0C  8D BC 94
        rts                         ; ED0F  60
HOMEFIX:
        lda  #$2E                   ; ED10  A9 2E
        sta  WNDWDTH                ; ED12  85 21
        lda  #$00                   ; ED14  A9 00
        sta  WNDLFT                 ; ED16  85 20
        sta  WNDTOP                 ; ED18  85 22
        lda  #$10                   ; ED1A  A9 10
        sta  WNDBTM                 ; ED1C  85 23
        jsr  CLEARHOME              ; ED1E  20 37 EA
        lda  #$00                   ; ED21  A9 00
        sta  $0400                  ; ED23  8D 00 04
        rts                         ; ED26  60
        .byte $A3,$E1               ; ED27
        bne  HOMEFIX                ; ED29  D0 E5
        rts                         ; ED2B  60
L_ED2C:
        lda  WNDBTM                 ; ED2C  A5 23
        sec                         ; ED2E  38
        sbc  #$01                   ; ED2F  E9 01
        sta  CV                     ; ED31  85 25
        jsr  L_EC4E                 ; ED33  20 4E EC
L_ED36:
        ldy  #$00                   ; ED36  A0 00
L_ED38:
        sty  S_0552                 ; ED38  8C 52 94
        lda  #$A0                   ; ED3B  A9 A0
L_ED3D:
        sta  (BASL),y               ; ED3D  91 28
        iny                         ; ED3F  C8
        cpy  WNDWDTH                ; ED40  C4 21
        bcc  L_ED3D                 ; ED42  90 F9
        lda  #$0C                   ; ED44  A9 0C
        sta  S_0553                 ; ED46  8D 53 94
        lda  S_0555                 ; ED49  AD 55 94
        clc                         ; ED4C  18
        adc  S_06AE                 ; ED4D  6D A3 94
        tax                         ; ED50  AA
L_ED51:
        lda  HGRLO,x                ; ED51  BD DC E0
        clc                         ; ED54  18
        adc  #$00                   ; ED55  69 00
        sta  $FC                    ; ED57  85 FC
        lda  HGRHI,x                ; ED59  BD 9C E1
        ora  $E6                    ; ED5C  05 E6
        sta  $FD                    ; ED5E  85 FD
        lda  #$00                   ; ED60  A9 00
        ldy  S_0552                 ; ED62  AC 52 94
L_ED65:
        sta  ($FC),y                ; ED65  91 FC
        iny                         ; ED67  C8
        cpy  #$28                   ; ED68  C0 28
        bcc  L_ED65                 ; ED6A  90 F9
        inx                         ; ED6C  E8
        dec  S_0553                 ; ED6D  CE 53 94
        bne  L_ED51                 ; ED70  D0 DF
        rts                         ; ED72  60
        jsr  SAVECUR                ; ED73  20 F7 ED
        jsr  L_ED82                 ; ED76  20 82 ED
        lsr  S_04D5                 ; ED79  4E 2D 94
        jsr  RESTCUR                ; ED7C  20 02 EE
        jmp  L_EA7D                 ; ED7F  4C 7D EA
L_ED82:
        ldx  WNDBTM                 ; ED82  A6 23
        dex                         ; ED84  CA
        txa                         ; ED85  8A
        jsr  L_EC73                 ; ED86  20 73 EC
L_ED89:
        lda  BASL                   ; ED89  A5 28
        sta  $2A                    ; ED8B  85 2A
        lda  BASH                   ; ED8D  A5 29
        sta  $2B                    ; ED8F  85 2B
        ldy  WNDWDTH                ; ED91  A4 21
        dey                         ; ED93  88
        cpx  WNDTOP                 ; ED94  E4 22
        beq  L_EDAC                 ; ED96  F0 14
        dex                         ; ED98  CA
        lda  $1C61,x                ; ED99  BD 61 1C
        sta  $1C62,x                ; ED9C  9D 62 1C
        txa                         ; ED9F  8A
        jsr  L_EC73                 ; EDA0  20 73 EC
L_EDA3:
        lda  (BASL),y               ; EDA3  B1 28
        sta  ($2A),y                ; EDA5  91 2A
        dey                         ; EDA7  88
        bpl  L_EDA3                 ; EDA8  10 F9
        bmi  L_ED89                 ; EDAA  30 DD
L_EDAC:
        lda  #$FF                   ; EDAC  A9 FF
        sta  $1C61,x                ; EDAE  9D 61 1C
        jsr  HSDN                   ; EDB1  20 D2 D5
        jmp  L_EDEF                 ; EDB4  4C EF ED
SETUPX:
        lda  CH                     ; EDB7  A5 24
        asl  a                      ; EDB9  0A
        sta  TMP                    ; EDBA  8D 8A 1C
        asl  a                      ; EDBD  0A
        clc                         ; EDBE  18
        adc  TMP                    ; EDBF  6D 8A 1C
        ldx  #$00                   ; EDC2  A2 00
L_EDC4:
        bcc  SX0                    ; EDC4  90 05
        ldx  #$24                   ; EDC6  A2 24
        clc                         ; EDC8  18
        adc  #$04                   ; EDC9  69 04
SX0:
        sec                         ; EDCB  38
SX1:
        sbc  #$07                   ; EDCC  E9 07
        bcc  SX2                    ; EDCE  90 03
        inx                         ; EDD0  E8
        bcs  SX1                    ; EDD1  B0 F9
SX2:
        adc  #$07                   ; EDD3  69 07
        sta  P1H                    ; EDD5  85 03
        stx  BOFF                   ; EDD7  8E A9 1C
        rts                         ; EDDA  60
FIXPR:
        lda  CHAR                   ; EDDB  AD AD 94
        ; The prompt that INPUT uses is $80 (an invisible character: CHAR is 0 here). It used to be
        ; replaced by "]" and $33 by $DD, which put a "]" after the "?" and made the line fetch return
        ; the prompt text in the answer. The stock code remembers where the answer starts ($055B/$055C)
        ; when CHAR is 0, and the line fetch uses that while $33 is $80, so leave both alone.
        ; The 11 bytes of the old code stay as NOPs so nothing after them moves.
        .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA
FPR:
        lda  CHAR                   ; EDE9  AD AD 94
        rts                         ; EDEC  60
        beq  L_EDC4                 ; EDED  F0 D5
L_EDEF:
        lda  WNDTOP                 ; EDEF  A5 22
        jsr  L_EC50                 ; EDF1  20 50 EC
        jmp  L_ED36                 ; EDF4  4C 36 ED
SAVECUR:
        lda  CH                     ; EDF7  A5 24
        sta  S_0558                 ; EDF9  8D 58 94
        lda  CV                     ; EDFC  A5 25
        sta  S_0559                 ; EDFE  8D 59 94
        rts                         ; EE01  60
RESTCUR:
        lda  S_0558                 ; EE02  AD 58 94
        sta  CH                     ; EE05  85 24
        lda  S_0559                 ; EE07  AD 59 94
        sta  CV                     ; EE0A  85 25
        jmp  L_EC50                 ; EE0C  4C 50 EC
D_EE0F:
        .byte $6E                   ; EE0F
D_EE10:
        .byte $FD,$3E,$D4,$0D,$D7,$66,$FE,$04,$D7,$33,$D4,$CD,$94; EE10
L_EE1D:
        clc                         ; EE1D  18
        adc  S_0669                 ; EE1E  6D 96 94
        tax                         ; EE21  AA
L_EE22:
        lda  D_EE0F,y               ; EE22  B9 0F EE
        cmp  $0101,x                ; EE25  DD 01 01
        beq  L_EE31                 ; EE28  F0 07
        inx                         ; EE2A  E8
        inx                         ; EE2B  E8
        cmp  $0101,x                ; EE2C  DD 01 01
        bne  L_EE38                 ; EE2F  D0 07
L_EE31:
        inx                         ; EE31  E8
        lda  D_EE10,y               ; EE32  B9 10 EE
        cmp  $0101,x                ; EE35  DD 01 01
L_EE38:
        rts                         ; EE38  60
        bit  S_04D5                 ; EE39  2C 2D 94
        bpl  L_EE38                 ; EE3C  10 FA
        cmp  #$88                   ; EE3E  C9 88
        beq  L_EE38                 ; EE40  F0 F6
        cmp  #$95                   ; EE42  C9 95
        beq  L_EE38                 ; EE44  F0 F2
        bit  S_04D1                 ; EE46  2C 29 94
        bpl  L_EE50                 ; EE49  10 05
        lda  #$8B                   ; EE4B  A9 8B
        jsr  COUT                   ; EE4D  20 63 EE
L_EE50:
        jsr  SAVECUR                ; EE50  20 F7 ED
        jmp  L_E58C                 ; EE53  4C 8C E5
        lda  S_04D5                 ; EE56  AD 2D 94
        eor  #$FF                   ; EE59  49 FF
        sta  S_04D5                 ; EE5B  8D 2D 94
        bpl  L_EE38                 ; EE5E  10 D8
        jmp  L_EA93                 ; EE60  4C 93 EA

; ==========================================================================
; COUT: the character output routine behind CSW
; ==========================================================================
COUT:
        pha                         ; EE63  48
        and  #$7F                   ; EE64  29 7F
        sta  CHAR                   ; EE66  8D AD 94
        stx  S_0667                 ; EE69  8E 94 94
        sty  S_0668                 ; EE6C  8C 95 94
        tsx                         ; EE6F  BA
        inx                         ; EE70  E8
        inx                         ; EE71  E8
        inx                         ; EE72  E8
        stx  S_0669                 ; EE73  8E 96 94
        jsr  WNDCLAMP               ; EE76  20 41 E4
        bit  S_04DC                 ; EE79  2C 34 94
        bpl  L_EE87                 ; EE7C  10 09
        lda  PROMPTCH               ; EE7E  A5 33
        and  #$7F                   ; EE80  29 7F
        cmp  CHAR                   ; EE82  CD AD 94
        beq  L_EEB9                 ; EE85  F0 32
L_EE87:
        lda  CHAR                   ; EE87  AD AD 94
        jsr  DISP                   ; EE8A  20 AA EE
        jsr  L_EB41                 ; EE8D  20 41 EB
        ldx  S_0667                 ; EE90  AE 94 94
        ldy  S_0668                 ; EE93  AC 95 94
        pla                         ; EE96  68
        rts                         ; EE97  60
L_EE98:
        lda  #$04                   ; EE98  A9 04
        tay                         ; EE9A  A8
        jsr  L_EE1D                 ; EE9B  20 1D EE
        php                         ; EE9E  08
        lda  #$0D                   ; EE9F  A9 0D
        plp                         ; EEA1  28
        bne  L_EEB1                 ; EEA2  D0 0D
        lda  #$11                   ; EEA4  A9 11
        sta  $0100,x                ; EEA6  9D 00 01
        rts                         ; EEA9  60
DISP:
        lsr  S_04D8                 ; EEAA  4E 30 94
        cmp  #$0D                   ; EEAD  C9 0D
        beq  L_EE98                 ; EEAF  F0 E7
L_EEB1:
        bit  HMODE                  ; EEB1  2C AC 94
        bmi  COMPOSE                ; EEB4  30 61
        jmp  PLOTCH                 ; EEB6  4C 0E F1
L_EEB9:
        jmp  PROMPT                 ; EEB9  4C 96 D6
        jsr  L_EE1D                 ; EEBC  20 1D EE
        bne  L_EE87                 ; EEBF  D0 C6
L_EEC1:
        inx                         ; EEC1  E8
        txs                         ; EEC2  9A
        lda  CHAR                   ; EEC3  AD AD 94
        bne  L_EED2                 ; EEC6  D0 0A
        lda  CV                     ; EEC8  A5 25
        sta  S_055C                 ; EECA  8D 5C 94
        lda  CH                     ; EECD  A5 24
        sta  S_055B                 ; EECF  8D 5B 94
L_EED2:
        jsr  L_E480                 ; EED2  20 80 E4
L_EED5:
        lda  #$00                   ; EED5  A9 00
        sta  S_04D5                 ; EED7  8D 2D 94
        sec                         ; EEDA  38
        ror  S_04D6                 ; EEDB  6E 2E 94
        jsr  S_0728                 ; EEDE  20 C9 94
        jsr  L_E473                 ; EEE1  20 73 E4
        bcs  L_EEED                 ; EEE4  B0 07
        beq  L_EEED                 ; EEE6  F0 05
        jsr  L_E872                 ; EEE8  20 72 E8
        bcs  L_EED5                 ; EEEB  B0 E8
L_EEED:
        jsr  L_E882                 ; EEED  20 82 E8
        bcs  L_EED5                 ; EEF0  B0 E3
        lda  #$8D                   ; EEF2  A9 8D
        lsr  S_04D6                 ; EEF4  4E 2E 94
        ldx  S_066C                 ; EEF7  AE 99 94
        jmp  S_0470                 ; EEFA  4C 20 94
MAPKEY:
        cmp  #$20                   ; EEFD  C9 20
        bcc  L_EF16                 ; EEFF  90 15
        cmp  #$61                   ; EF01  C9 61
        bcc  L_EF0B                 ; EF03  90 06
        cmp  #$7B                   ; EF05  C9 7B
        bcs  L_EF0B                 ; EF07  B0 02
        and  #$DF                   ; EF09  29 DF
L_EF0B:
        cmp  #$5B                   ; EF0B  C9 5B
        clc                         ; EF0D  18
        bpl  L_EF16                 ; EF0E  10 06
        sbc  #$1F                   ; EF10  E9 1F
        tax                         ; EF12  AA
        lda  D_E2A0,x               ; EF13  BD A0 E2
L_EF16:
        rts                         ; EF16  60
COMPOSE:
        jsr  MAPKEY                 ; EF17  20 FD EE
        bcc  L_EF28                 ; EF1A  90 0C
        bpl  L_EF28                 ; EF1C  10 0A
        sta  CURKEY                 ; EF1E  8D A6 94
        cmp  #$93                   ; EF21  C9 93
        bcc  L_EF38                 ; EF23  90 13
        jmp  L_EF87                 ; EF25  4C 87 EF
L_EF28:
        pha                         ; EF28  48
        ldx  STATE                  ; EF29  AE A7 94
        beq  L_EF31                 ; EF2C  F0 03
        jsr  PACK                   ; EF2E  20 24 F0
L_EF31:
        jsr  CLRCOMP                ; EF31  20 DA EF
        pla                         ; EF34  68
        jmp  PLOTCH                 ; EF35  4C 0E F1
L_EF38:
        ldy  STATE                  ; EF38  AC A7 94
        beq  L_EF48                 ; EF3B  F0 0B
        dey                         ; EF3D  88
        beq  L_EF55                 ; EF3E  F0 15
        dey                         ; EF40  88
        beq  L_EF5A                 ; EF41  F0 17
        dey                         ; EF43  88
        beq  L_EF70                 ; EF44  F0 2A
        bne  L_EF55                 ; EF46  D0 0D
L_EF48:
        jsr  CLRCOMP                ; EF48  20 DA EF
        lda  CURKEY                 ; EF4B  AD A6 94
        sta  CHO                    ; EF4E  8D A8 94
        inc  STATE                  ; EF51  EE A7 94
        rts                         ; EF54  60
L_EF55:
        jsr  PACK                   ; EF55  20 24 F0
        beq  L_EF48                 ; EF58  F0 EE
L_EF5A:
        lda  CURKEY                 ; EF5A  AD A6 94
        cmp  #$8F                   ; EF5D  C9 8F
        beq  L_EF55                 ; EF5F  F0 F4
        cmp  #$90                   ; EF61  C9 90
        beq  L_EF55                 ; EF63  F0 F0
        cmp  #$92                   ; EF65  C9 92
        beq  L_EF55                 ; EF67  F0 EC
        sta  JONG                   ; EF69  8D A9 94
        inc  STATE                  ; EF6C  EE A7 94
        rts                         ; EF6F  60
L_EF70:
        lda  CURKEY                 ; EF70  AD A6 94
        sta  JONG2                  ; EF73  8D AA 94
        jsr  L_EFF2                 ; EF76  20 F2 EF
        bcs  L_EF7F                 ; EF79  B0 04
        inc  STATE                  ; EF7B  EE A7 94
        rts                         ; EF7E  60
L_EF7F:
        lda  #$00                   ; EF7F  A9 00
        sta  JONG2                  ; EF81  8D AA 94
        jmp  L_EF55                 ; EF84  4C 55 EF
L_EF87:
        ldy  STATE                  ; EF87  AC A7 94
        beq  L_EF97                 ; EF8A  F0 0B
        dey                         ; EF8C  88
        beq  L_EF9A                 ; EF8D  F0 0B
        dey                         ; EF8F  88
        beq  L_EFA4                 ; EF90  F0 12
        dey                         ; EF92  88
        beq  L_EFB6                 ; EF93  F0 21
        bne  L_EFCE                 ; EF95  D0 37
L_EF97:
        inc  STATE                  ; EF97  EE A7 94
L_EF9A:
        lda  CURKEY                 ; EF9A  AD A6 94
        sta  JUNG                   ; EF9D  8D AB 94
        inc  STATE                  ; EFA0  EE A7 94
        rts                         ; EFA3  60
L_EFA4:
        jsr  L_F00B                 ; EFA4  20 0B F0
        bcs  L_EFB0                 ; EFA7  B0 07
        txa                         ; EFA9  8A
        adc  #$A1                   ; EFAA  69 A1
        sta  JUNG                   ; EFAC  8D AB 94
        rts                         ; EFAF  60
L_EFB0:
        jsr  PACK                   ; EFB0  20 24 F0
        jmp  L_EF97                 ; EFB3  4C 97 EF
L_EFB6:
        lda  JONG                   ; EFB6  AD A9 94
        pha                         ; EFB9  48
        lda  #$00                   ; EFBA  A9 00
        sta  JONG                   ; EFBC  8D A9 94
L_EFBF:
        jsr  PACK                   ; EFBF  20 24 F0
        pla                         ; EFC2  68
        sta  CHO                    ; EFC3  8D A8 94
        lda  #$01                   ; EFC6  A9 01
        sta  STATE                  ; EFC8  8D A7 94
        jmp  L_EF9A                 ; EFCB  4C 9A EF
L_EFCE:
        lda  JONG2                  ; EFCE  AD AA 94
        pha                         ; EFD1  48
        lda  #$00                   ; EFD2  A9 00
        sta  JONG2                  ; EFD4  8D AA 94
        jmp  L_EFBF                 ; EFD7  4C BF EF
CLRCOMP:
        lda  #$00                   ; EFDA  A9 00
        sta  CHO                    ; EFDC  8D A8 94
        sta  JONG                   ; EFDF  8D A9 94
        sta  JONG2                  ; EFE2  8D AA 94
        sta  JUNG                   ; EFE5  8D AB 94
        sta  STATE                  ; EFE8  8D A7 94
        sta  LEAD                   ; EFEB  8D 9E 94
        sta  TRAIL                  ; EFEE  8D 9F 94
        rts                         ; EFF1  60
L_EFF2:
        ldx  #$0B                   ; EFF2  A2 0B
L_EFF4:
        lda  JONG                   ; EFF4  AD A9 94
        cmp  D_E27C,x               ; EFF7  DD 7C E2
        bne  L_F006                 ; EFFA  D0 0A
        lda  JONG2                  ; EFFC  AD AA 94
        cmp  D_E287,x               ; EFFF  DD 87 E2
        bne  L_F006                 ; F002  D0 02
        clc                         ; F004  18
        rts                         ; F005  60
L_F006:
        dex                         ; F006  CA
        bpl  L_EFF4                 ; F007  10 EB
        sec                         ; F009  38
        rts                         ; F00A  60
L_F00B:
        ldx  #$07                   ; F00B  A2 07
L_F00D:
        lda  JUNG                   ; F00D  AD AB 94
        cmp  D_E292,x               ; F010  DD 92 E2
        bne  L_F01F                 ; F013  D0 0A
        lda  CURKEY                 ; F015  AD A6 94
        cmp  D_E299,x               ; F018  DD 99 E2
        bne  L_F01F                 ; F01B  D0 02
        clc                         ; F01D  18
        rts                         ; F01E  60
L_F01F:
        dex                         ; F01F  CA
        bpl  L_F00D                 ; F020  10 EB
        sec                         ; F022  38
        rts                         ; F023  60
PACK:
        lda  #$80                   ; F024  A9 80
        sta  LEAD                   ; F026  8D 9E 94
        ldx  #$00                   ; F029  A2 00
L_F02B:
        lda  D_E2DB,x               ; F02B  BD DB E2
        beq  L_F038                 ; F02E  F0 08
        cmp  CHO                    ; F030  CD A8 94
        beq  L_F03C                 ; F033  F0 07
        inx                         ; F035  E8
        bne  L_F02B                 ; F036  D0 F3
L_F038:
        lda  #$01                   ; F038  A9 01
        bne  L_F03F                 ; F03A  D0 03
L_F03C:
        inx                         ; F03C  E8
        inx                         ; F03D  E8
        txa                         ; F03E  8A
L_F03F:
        asl  a                      ; F03F  0A
        asl  a                      ; F040  0A
        ora  LEAD                   ; F041  0D 9E 94
        sta  LEAD                   ; F044  8D 9E 94
        ldx  #$00                   ; F047  A2 00
L_F049:
        lda  D_E2EF,x               ; F049  BD EF E2
        beq  L_F056                 ; F04C  F0 08
        cmp  JUNG                   ; F04E  CD AB 94
        beq  L_F05A                 ; F051  F0 07
        inx                         ; F053  E8
        bne  L_F049                 ; F054  D0 F3
L_F056:
        lda  #$02                   ; F056  A9 02
        bne  L_F05D                 ; F058  D0 03
L_F05A:
        lda  D_E305,x               ; F05A  BD 05 E3
L_F05D:
        pha                         ; F05D  48
        lsr  a                      ; F05E  4A
        lsr  a                      ; F05F  4A
        lsr  a                      ; F060  4A
        ora  LEAD                   ; F061  0D 9E 94
        sta  LEAD                   ; F064  8D 9E 94
        pla                         ; F067  68
        asl  a                      ; F068  0A
        asl  a                      ; F069  0A
        asl  a                      ; F06A  0A
        asl  a                      ; F06B  0A
        asl  a                      ; F06C  0A
L_F06D:
        sta  TRAIL                  ; F06D  8D 9F 94
        jsr  L_EFF2                 ; F070  20 F2 EF
        bcs  L_F07B                 ; F073  B0 06
        txa                         ; F075  8A
        adc  #$B1                   ; F076  69 B1
        sta  JONG                   ; F078  8D A9 94
L_F07B:
        ldx  #$00                   ; F07B  A2 00
L_F07D:
        lda  D_E31B,x               ; F07D  BD 1B E3
        beq  L_F08A                 ; F080  F0 08
        cmp  JONG                   ; F082  CD A9 94
        beq  L_F08E                 ; F085  F0 07
        inx                         ; F087  E8
        bne  L_F07D                 ; F088  D0 F3
L_F08A:
        lda  #$01                   ; F08A  A9 01
        bne  L_F091                 ; F08C  D0 03
L_F08E:
        inx                         ; F08E  E8
        inx                         ; F08F  E8
        txa                         ; F090  8A
L_F091:
        ora  TRAIL                  ; F091  0D 9F 94
        sta  TRAIL                  ; F094  8D 9F 94
L_F097:
        lda  LEAD                   ; F097  AD 9E 94
        jsr  PLOTCH                 ; F09A  20 0E F1
        lda  TRAIL                  ; F09D  AD 9F 94
        jsr  PLOTCH                 ; F0A0  20 0E F1
        jmp  CLRCOMP                ; F0A3  4C DA EF
D_F0A6:
        .byte $E5                   ; F0A6
D_F0A7:
        .byte $F0,$E3,$E5,$CD,$E5,$F0,$E5,$E5,$F0,$E4,$E9,$2F,$EA,$FF,$F3,$79; F0A7
        .byte $EA,$D7               ; F0B7
        sbc  $EA                    ; F0B9  E5 EA
        sbc  $E5                    ; F0BB  E5 E5
        sbc  CSWL                   ; F0BD  E5 36
        nop                         ; F0BF  EA
        .byte $FB,$EB,$1E,$E5       ; F0C0
L_F0C4:
        .byte $DA,$E5,$5F,$E5,$F7,$E4; F0C4
L_F0CA:
        sbc  $F0                    ; F0CA  E5 F0
        ldx  D_E5E5                 ; F0CC  AE E5 E5
        beq  L_F06D+2               ; F0CF  F0 9E
        nop                         ; F0D1  EA
        .byte $72,$ED,$E2           ; F0D2
        cpx  $66                    ; F0D5  E4 66
        sbc  $A3                    ; F0D7  E5 A3
        sbc  $2E                    ; F0D9  E5 2E
        cpx  $E5                    ; F0DB  E4 E5
        beq  L_F0C4                 ; F0DD  F0 E5
        beq  L_F097+1               ; F0DF  F0 B7
        sbc  $E5                    ; F0E1  E5 E5
        beq  L_F0CA                 ; F0E3  F0 E5
        beq  L_F147                 ; F0E5  F0 60
L_F0E7:
        jsr  L_F0F6                 ; F0E7  20 F6 F0
        cmp  #$0D                   ; F0EA  C9 0D
        bne  L_F0F5                 ; F0EC  D0 07
        pha                         ; F0EE  48
        lda  #$0A                   ; F0EF  A9 0A
        jsr  L_F0F6                 ; F0F1  20 F6 F0
        pla                         ; F0F4  68
L_F0F5:
        rts                         ; F0F5  60
L_F0F6:
        bit  $C1C1                  ; F0F6  2C C1 C1
        bpl  L_F10A                 ; F0F9  10 0F
        ldx  KBD                    ; F0FB  AE 00 C0
        cpx  #$9B                   ; F0FE  E0 9B
        bne  L_F0F6                 ; F100  D0 F4
        ldx  KBDSTRB                ; F102  AE 10 C0
        ldx  #$00                   ; F105  A2 00
        stx  S_07DA                 ; F107  8E 7B 95
L_F10A:
        sta  $C090                  ; F10A  8D 90 C0
        rts                         ; F10D  60
PLOTCH:
        jmp  CASEIN                 ; F10E  4C FB D5
        .byte $32                   ; F111
L_F112:
        bmi  PLOT2                  ; F112  30 02
        ldx  #$7F                   ; F114  A2 7F
PLOT2:
        stx  S_066B                 ; F116  8E 98 94
        bit  S_07DA                 ; F119  2C 7B 95
        bpl  L_F121                 ; F11C  10 03
        jsr  L_F0E7                 ; F11E  20 E7 F0
L_F121:
        ldx  PENDING                ; F121  AE AE 94
        bne  L_F15B                 ; F124  D0 35
        cmp  #$80                   ; F126  C9 80
        bcs  L_F152                 ; F128  B0 28
        cmp  #$1F                   ; F12A  C9 1F
        bcs  L_F164                 ; F12C  B0 36
        cmp  #$0B                   ; F12E  C9 0B
        beq  L_F147                 ; F130  F0 15
        cmp  #$02                   ; F132  C9 02
        bcc  L_F147                 ; F134  90 11
        lda  #$02                   ; F136  A9 02
        ldy  #$08                   ; F138  A0 08
        jsr  L_EE1D                 ; F13A  20 1D EE
        beq  L_F164                 ; F13D  F0 25
        bit  S_04D8                 ; F13F  2C 30 94
        bvs  L_F164                 ; F142  70 20
        lda  CHAR                   ; F144  AD AD 94
L_F147:
        asl  a                      ; F147  0A
        tay                         ; F148  A8
        lda  D_F0A7,y               ; F149  B9 A7 F0
        pha                         ; F14C  48
        lda  D_F0A6,y               ; F14D  B9 A6 F0
        pha                         ; F150  48
        rts                         ; F151  60
L_F152:
        ldx  #$FF                   ; F152  A2 FF
        stx  PENDING                ; F154  8E AE 94
        sta  LEAD                   ; F157  8D 9E 94
        rts                         ; F15A  60
L_F15B:
        inc  PENDING                ; F15B  EE AE 94
        sta  TRAIL                  ; F15E  8D 9F 94
        jmp  DRAWKO                 ; F161  4C BC F1
L_F164:
        jsr  L_F31A                 ; F164  20 1A F3
        lda  S_07DB                 ; F167  AD 7C 95
        sta  P0L                    ; F16A  85 00
        lda  S_07DC                 ; F16C  AD 7D 95
        sta  P0H                    ; F16F  85 01
        jsr  FIXCASE                ; F171  20 21 D6
        jsr  ENGPTR                 ; P0 = base + code * 16 (was ldy #8 / jsr L_F2DD)
        nop
        nop
        jsr  ENBLIT                 ; F179  20 AA EB
        jmp  L_F1B1                 ; F17C  4C B1 F1
ROWPTR:
        tax                         ; F17F  AA
        lda  ROWLO,x                ; F180  BD B9 D7
        clc                         ; F183  18
        adc  WNDLFT                 ; F184  65 20
        sta  BASL                   ; F186  85 28
        lda  ROWHI,x                ; F188  BD C9 D7
        adc  #$00                   ; F18B  69 00
        sta  BASH                   ; F18D  85 29
        ldx  S_0551                 ; F18F  AE 51 94
        rts                         ; F192  60
MUL12:
        sta  TMP                    ; F193  8D 8A 1C
        asl  a                      ; F196  0A
        asl  a                      ; F197  0A
        sta  IDX                    ; F198  8D 8D 1C
        asl  a                      ; F19B  0A
        clc                         ; F19C  18
        adc  IDX                    ; F19D  6D 8D 1C
        rts                         ; F1A0  60
LINE:
        lda  HGRLO,x                ; F1A1  BD DC E0
        sta  $26                    ; F1A4  85 26
        lda  HGRHI,x                ; F1A6  BD 9C E1
        ora  $E6                    ; F1A9  05 E6
        sta  $27                    ; F1AB  85 27
        rts                         ; F1AD  60
        .byte $10                   ; F1AE
        bne  MUL12+1                ; F1AF  D0 E3
L_F1B1:
        jsr  L_F31A                 ; F1B1  20 1A F3
        lda  CHAR                   ; F1B4  AD AD 94
        ora  #$80                   ; F1B7  09 80
        jmp  L_EC35                 ; F1B9  4C 35 EC
DRAWKO:
        jsr  L_F31A                 ; F1BC  20 1A F3
        lda  WNDWDTH                ; F1BF  A5 21
        clc                         ; F1C1  18
        sbc  CH                     ; F1C2  E5 24
        bne  L_F1CB                 ; F1C4  D0 05
        lda  #$9F                   ; F1C6  A9 9F
        jsr  L_EC35                 ; F1C8  20 35 EC
L_F1CB:
        jsr  DECODE                 ; F1CB  20 2E F3
        lda  #$00                   ; F1CE  A9 00
        ldx  #$1F                   ; F1D0  A2 1F
L_F1D2:
        sta  S_0750,x               ; F1D2  9D F1 94
        dex                         ; F1D5  CA
        bpl  L_F1D2                 ; F1D6  10 FA
        ldy  JUNGI                  ; F1D8  AC A1 94
        lda  D_E338,y               ; F1DB  B9 38 E3
        ldx  JONGI                  ; F1DE  AE A2 94
        beq  L_F1E6                 ; F1E1  F0 03
        clc                         ; F1E3  18
        adc  #$03                   ; F1E4  69 03
L_F1E6:
        asl  a                      ; F1E6  0A
        tax                         ; F1E7  AA
        lda  D_E25C,x               ; F1E8  BD 5C E2
        sta  P0L                    ; F1EB  85 00
        lda  D_E25D,x               ; F1ED  BD 5D E2
        sta  P0H                    ; F1F0  85 01
        lda  D_E26C,x               ; F1F2  BD 6C E2
        ldy  CHOI                   ; F1F5  AC A0 94
        jsr  L_F2DD                 ; F1F8  20 DD F2
        lda  P0L                    ; F1FB  A5 00
        sta  P1L                    ; F1FD  85 02
        lda  P0H                    ; F1FF  A5 01
        sta  P1H                    ; F201  85 03
        lda  D_E26D,x               ; F203  BD 6D E2
        bne  L_F212                 ; F206  D0 0A
        lda  #$00                   ; F208  A9 00
        sta  P0L                    ; F20A  85 00
        lda  #$D8                   ; F20C  A9 D8
        sta  P0H                    ; F20E  85 01
        bne  L_F21A                 ; F210  D0 08
L_F212:
        lda  D_E26C,x               ; F212  BD 6C E2
        ldy  #$14                   ; F215  A0 14
        jsr  L_F2DD                 ; F217  20 DD F2
L_F21A:
        ldy  D_E26C,x               ; F21A  BC 6C E2
        jsr  L_F304                 ; F21D  20 04 F3
        ldx  JONGI                  ; F220  AE A2 94
        beq  L_F227                 ; F223  F0 02
        ldx  #$02                   ; F225  A2 02
L_F227:
        lda  D_E268,x               ; F227  BD 68 E2
        sta  P0L                    ; F22A  85 00
        lda  D_E269,x               ; F22C  BD 69 E2
        sta  P0H                    ; F22F  85 01
        lda  D_E278,x               ; F231  BD 78 E2
        ldy  JUNGI                  ; F234  AC A1 94
        jsr  L_F2DD                 ; F237  20 DD F2
        lda  P0L                    ; F23A  A5 00
        sta  P1L                    ; F23C  85 02
        lda  P0H                    ; F23E  A5 01
        sta  P1H                    ; F240  85 03
        lda  D_E278,x               ; F242  BD 78 E2
        ldy  #$16                   ; F245  A0 16
        jsr  L_F2DD                 ; F247  20 DD F2
        ldy  D_E278,x               ; F24A  BC 78 E2
        jsr  L_F304                 ; F24D  20 04 F3
        ldy  JONGI                  ; F250  AC A2 94
        beq  L_F289                 ; F253  F0 34
        lda  #$C4                   ; F255  A9 C4
        sta  P0L                    ; F257  85 00
        lda  #$DF                   ; F259  A9 DF
        sta  P0H                    ; F25B  85 01
        lda  #$05                   ; F25D  A9 05
        jsr  L_F2DD                 ; F25F  20 DD F2
        lda  P0L                    ; F262  A5 00
        sta  P1L                    ; F264  85 02
        lda  P0H                    ; F266  A5 01
        sta  P1H                    ; F268  85 03
        lda  #$8C                   ; F26A  A9 8C
        ldy  #$00                   ; F26C  A0 00
        clc                         ; F26E  18
        jsr  L_F2FA                 ; F26F  20 FA F2
        ldy  #$05                   ; F272  A0 05
L_F274:
        dey                         ; F274  88
        lda  (P1L),y                ; F275  B1 02
        ora  S_0759,y               ; F277  19 FA 94
        sta  S_0759,y               ; F27A  99 FA 94
        lda  (P0L),y                ; F27D  B1 00
        ora  S_0769,y               ; F27F  19 0A 95
        sta  S_0769,y               ; F282  99 0A 95
        cpy  #$00                   ; F285  C0 00
        bne  L_F274                 ; F287  D0 EB
L_F289:
        lda  S_06B0                 ; F289  AD A5 94
        sta  S_076F                 ; F28C  8D 10 95
        sta  S_075F                 ; F28F  8D 00 95
        jsr  KOBLIT                 ; F292  20 D8 EB
        jmp  L_F2CC                 ; F295  4C CC F2
PIXY:
        lda  CV                     ; F298  A5 25
        jsr  MUL12                  ; F29A  20 93 F1
        tax                         ; F29D  AA
        lda  HGRLO,x                ; F29E  BD DC E0
        sta  $FC                    ; F2A1  85 FC
L_F2A3:
        lda  HGRHI,x                ; F2A3  BD 9C E1
        ora  $E6                    ; F2A6  05 E6
        sta  $FD                    ; F2A8  85 FD
        rts                         ; F2AA  60
ADDOFF:
        lda  $26                    ; F2AB  A5 26
        clc                         ; F2AD  18
        adc  BOFF                   ; F2AE  6D A9 1C
        sta  $26                    ; F2B1  85 26
        bcc  AO1                    ; F2B3  90 02
        inc  $27                    ; F2B5  E6 27
AO1:
        rts                         ; F2B7  60
HOMECK:
        lda  $0400                  ; F2B8  AD 00 04
        cmp  #$A0                   ; F2BB  C9 A0
        bne  HC9                    ; F2BD  D0 03
        jsr  HOMEFIX                ; F2BF  20 10 ED
HC9:
        ldx  #$10                   ; F2C2  A2 10
        lda  S_06AE                 ; F2C4  AD A3 94
        rts                         ; F2C7  60
        cpx  #$10                   ; F2C8  E0 10
        bne  L_F2A3+1               ; F2CA  D0 D8
L_F2CC:
        jsr  L_F31A                 ; F2CC  20 1A F3
        lda  LEAD                   ; F2CF  AD 9E 94
        and  #$7F                   ; F2D2  29 7F
        jsr  L_EC35                 ; F2D4  20 35 EC
        lda  TRAIL                  ; F2D7  AD 9F 94
        jmp  L_EC35                 ; F2DA  4C 35 EC
L_F2DD:
        jmp  FASTMUL                ; F2DD  4C D0 FF
        .byte $EA                   ; F2E0
L_F2E1:
        lda  #$00                   ; F2E1  A9 00
        sta  S_06BA                 ; F2E3  8D AF 94
        ldy  #$08                   ; F2E6  A0 08
L_F2E8:
        lsr  P2L                    ; F2E8  46 04
        bcc  L_F2EF                 ; F2EA  90 03
        clc                         ; F2EC  18
        adc  P2H                    ; F2ED  65 05
L_F2EF:
        ror  a                      ; F2EF  6A
        ror  S_06BA                 ; F2F0  6E AF 94
        dey                         ; F2F3  88
        bne  L_F2E8                 ; F2F4  D0 F2
        tay                         ; F2F6  A8
        lda  S_06BA                 ; F2F7  AD AF 94
L_F2FA:
        adc  P0L                    ; F2FA  65 00
        sta  P0L                    ; F2FC  85 00
        tya                         ; F2FE  98
        adc  P0H                    ; F2FF  65 01
        sta  P0H                    ; F301  85 01
        rts                         ; F303  60
L_F304:
        dey                         ; F304  88
        lda  (P1L),y                ; F305  B1 02
        ora  S_0751,y               ; F307  19 F2 94
        sta  S_0751,y               ; F30A  99 F2 94
        lda  (P0L),y                ; F30D  B1 00
        ora  S_0761,y               ; F30F  19 02 95
        sta  S_0761,y               ; F312  99 02 95
        cpy  #$00                   ; F315  C0 00
        bne  L_F304                 ; F317  D0 EB
        rts                         ; F319  60
L_F31A:
        jmp  SWAP6                  ; F31A  4C D3 EC
        .byte $00,$00               ; F31D
        tax                         ; F31F  AA
        lda  S_06C2,y               ; F320  B9 B7 94
        sta  a:P0L,y                ; F323  99 00 00
        txa                         ; F326  8A
        sta  S_06C2,y               ; F327  99 B7 94
        dey                         ; F32A  88
        bpl  L_F31A+2               ; F32B  10 EF
        rts                         ; F32D  60
DECODE:
        lda  TRAIL                  ; F32E  AD 9F 94
        and  #$1F                   ; F331  29 1F
        tay                         ; F333  A8
        dey                         ; F334  88
        cpy  #$12                   ; F335  C0 12
        bcc  L_F33A                 ; F337  90 01
        dey                         ; F339  88
L_F33A:
        sty  JONGI                  ; F33A  8C A2 94
        lda  LEAD                   ; F33D  AD 9E 94
        ldy  TRAIL                  ; F340  AC 9F 94
        sty  P0L                    ; F343  84 00
        rol  P0L                    ; F345  26 00
        rol  a                      ; F347  2A
        rol  P0L                    ; F348  26 00
        rol  a                      ; F34A  2A
        rol  P0L                    ; F34B  26 00
        rol  a                      ; F34D  2A
        and  #$1F                   ; F34E  29 1F
        tay                         ; F350  A8
        lda  JUNGOF,y               ; F351  B9 4E E3
        sta  JUNGI                  ; F354  8D A1 94
        lda  LEAD                   ; F357  AD 9E 94
        and  #$7C                   ; F35A  29 7C
        clc                         ; F35C  18
        ror  a                      ; F35D  6A
        ror  a                      ; F35E  6A
        sta  CHOI                   ; F35F  8D A0 94
        dec  CHOI                   ; F362  CE A0 94
        rts                         ; F365  60
D_F366:
        .byte $1C                   ; F366
L_F367:
        clc                         ; F367  18
        lda  $27                    ; F368  A5 27
L_F36A:
        adc  #$04                   ; F36A  69 04
        bit  D_F366                 ; F36C  2C 66 F3
        bne  L_F391                 ; F36F  D0 20
        asl  $26                    ; F371  06 26
        bcc  L_F38D                 ; F373  90 18
        adc  #$E0                   ; F375  69 E0
        clc                         ; F377  18
        bit  L_F36A+1               ; F378  2C 6B F3
        beq  L_F38F                 ; F37B  F0 12
        lda  $26                    ; F37D  A5 26
        adc  #$50                   ; F37F  69 50
        eor  #$F0                   ; F381  49 F0
        beq  L_F387                 ; F383  F0 02
        eor  #$F0                   ; F385  49 F0
L_F387:
        sta  $26                    ; F387  85 26
        lda  $E6                    ; F389  A5 E6
        bcc  L_F38F                 ; F38B  90 02
L_F38D:
        adc  #$E0                   ; F38D  69 E0
L_F38F:
        ror  $26                    ; F38F  66 26
L_F391:
        sta  $27                    ; F391  85 27
        rts                         ; F393  60
EMITKEY:
        jsr  DECODE                 ; F394  20 2E F3
        ldy  CHOI                   ; F397  AC A0 94
        beq  L_F3A2                 ; F39A  F0 06
        lda  D_E36C,y               ; F39C  B9 6C E3
        jsr  S_06BB                 ; F39F  20 B0 94
L_F3A2:
        ldy  JUNGI                  ; F3A2  AC A1 94
        beq  L_F3C8                 ; F3A5  F0 21
        lda  D_E380,y               ; F3A7  B9 80 E3
        bpl  L_F3B2                 ; F3AA  10 06
        jsr  S_06BB                 ; F3AC  20 B0 94
        lda  D_E396,y               ; F3AF  B9 96 E3
L_F3B2:
        jsr  S_06BB                 ; F3B2  20 B0 94
        ldy  JONGI                  ; F3B5  AC A2 94
        beq  L_F3C8                 ; F3B8  F0 0E
        lda  D_E3AB,y               ; F3BA  B9 AB E3
        bpl  L_F3C5                 ; F3BD  10 06
        jsr  S_06BB                 ; F3BF  20 B0 94
        lda  D_E3C7,y               ; F3C2  B9 C7 E3
L_F3C5:
        jsr  S_06BB                 ; F3C5  20 B0 94
L_F3C8:
        rts                         ; F3C8  60
L_F3C9:
        rts                         ; F3C9  60
        .byte $D2,$04               ; F3CA
        bpl  L_F3DB                 ; F3CC  10 0D
        txa                         ; F3CE  8A
        pha                         ; F3CF  48
        tya                         ; F3D0  98
        pha                         ; F3D1  48
        ldx  #$12                   ; F3D2  A2 12
        jsr  L_F3DC                 ; F3D4  20 DC F3
        pla                         ; F3D7  68
        tay                         ; F3D8  A8
        pla                         ; F3D9  68
        tax                         ; F3DA  AA
L_F3DB:
        rts                         ; F3DB  60
L_F3DC:
        stx  S_066A                 ; F3DC  8E 97 94
L_F3DF:
        txa                         ; F3DF  8A
        tay                         ; F3E0  A8
        lda  SPKR                   ; F3E1  AD 30 C0
L_F3E4:
        dey                         ; F3E4  88
        bne  L_F3E4                 ; F3E5  D0 FD
        dex                         ; F3E7  CA
        bne  L_F3DF                 ; F3E8  D0 F5
        rts                         ; F3EA  60
L_F3EB:
        stx  S_066A                 ; F3EB  8E 97 94
L_F3EE:
        txa                         ; F3EE  8A
        eor  #$FF                   ; F3EF  49 FF
        sec                         ; F3F1  38
        adc  S_066A                 ; F3F2  6D 97 94
        tay                         ; F3F5  A8
        lda  SPKR                   ; F3F6  AD 30 C0
L_F3F9:
        dey                         ; F3F9  88
        bne  L_F3F9                 ; F3FA  D0 FD
        dex                         ; F3FC  CA
        bne  L_F3EE                 ; F3FD  D0 EF
        rts                         ; F3FF  60
        lda  #$04                   ; F400  A9 04
        ldy  #$0A                   ; F402  A0 0A
        jsr  L_EE1D                 ; F404  20 1D EE
        bne  L_F417                 ; F407  D0 0E
        lda  $76                    ; F409  A5 76
        cmp  #$FF                   ; F40B  C9 FF
        beq  L_F417                 ; F40D  F0 08
        sta  S_04DB                 ; F40F  8D 33 94
        lda  $75                    ; F412  A5 75
        sta  S_04DA                 ; F414  8D 32 94
L_F417:
        jsr  BELL                   ; F417  20 B0 1C
        rts                         ; F41A  60
        jsr  L_F3DC                 ; F41B  20 DC F3
        ldx  #$D0                   ; F41E  A2 D0
        jsr  L_F3EB                 ; F420  20 EB F3
        ldx  #$50                   ; F423  A2 50
        jsr  L_F3EB                 ; F425  20 EB F3
        ldx  #$30                   ; F428  A2 30
        jsr  L_F3EB                 ; F42A  20 EB F3
        pla                         ; F42D  68
        tax                         ; F42E  AA
        rts                         ; F42F  60
L_F430:
        ldy  #$00                   ; F430  A0 00
L_F432:
        sty  S_0569                 ; F432  8C 69 05
        sta  $9F                    ; F435  85 9F
        stx  $9E                    ; F437  86 9E
        ldx  #$09                   ; F439  A2 09
        stx  S_0568                 ; F43B  8E 68 05
L_F43E:
        ldy  #$B0                   ; F43E  A0 B0
L_F440:
        lda  $9E                    ; F440  A5 9E
        cmp  D_F479,x               ; F442  DD 79 F4
        lda  $9F                    ; F445  A5 9F
        sbc  D_F47A,x               ; F447  FD 7A F4
        bcc  L_F458                 ; F44A  90 0C
        sta  $9F                    ; F44C  85 9F
        lda  $9E                    ; F44E  A5 9E
        sbc  D_F479,x               ; F450  FD 79 F4
        sta  $9E                    ; F453  85 9E
        iny                         ; F455  C8
        bne  L_F440                 ; F456  D0 E8
L_F458:
        tya                         ; F458  98
        dex                         ; F459  CA
        beq  L_F46D                 ; F45A  F0 11
        cmp  #$B0                   ; F45C  C9 B0
        beq  L_F463                 ; F45E  F0 03
        sta  S_0568                 ; F460  8D 68 05
L_F463:
        bit  S_0568                 ; F463  2C 68 05
        bmi  L_F46D                 ; F466  30 05
        lda  S_0569                 ; F468  AD 69 05
        bpl  L_F476                 ; F46B  10 09
L_F46D:
        stx  S_056A                 ; F46D  8E 6A 05
        jsr  L_F6AE                 ; F470  20 AE F6
        ldx  S_056A                 ; F473  AE 6A 05
L_F476:
        dex                         ; F476  CA
        bpl  L_F43E                 ; F477  10 C5
D_F479:
        rts                         ; F479  60
D_F47A:
        .byte $01,$00,$0A,$00,$64,$00,$E8,$03; F47A
        bpl  L_F4AA+1               ; F482  10 27
L_F484:
        ldx  #$0F                   ; F484  A2 0F
L_F486:
        asl  $50                    ; F486  06 50
        rol  $51                    ; F488  26 51
        lda  #$B0                   ; F48A  A9 B0
        adc  #$00                   ; F48C  69 00
        jsr  L_F6CC                 ; F48E  20 CC F6
        dex                         ; F491  CA
        bpl  L_F486                 ; F492  10 F2
        rts                         ; F494  60
L_F495:
        ldx  #$45                   ; F495  A2 45
        sec                         ; F497  38
        rts                         ; F498  60
        beq  L_F495                 ; F499  F0 FA
        jsr  L_F4FC                 ; F49B  20 FC F4
        lda  #$A4                   ; F49E  A9 A4
        jsr  L_F6CC                 ; F4A0  20 CC F6
        ldx  $50                    ; F4A3  A6 50
        lda  $51                    ; F4A5  A5 51
        jsr  L_E495                 ; F4A7  20 95 E4
L_F4AA:
        eor  ($F9,x)                ; F4AA  41 F9
        ldy  #$A0                   ; F4AC  A0 A0
        tya                         ; F4AE  98
        jsr  L_F6CC                 ; F4AF  20 CC F6
        jsr  L_F6CC                 ; F4B2  20 CC F6
        ldx  $50                    ; F4B5  A6 50
        lda  $51                    ; F4B7  A5 51
        jsr  L_F432                 ; F4B9  20 32 F4
        sec                         ; F4BC  38
        lda  #$00                   ; F4BD  A9 00
        sbc  $50                    ; F4BF  E5 50
        tax                         ; F4C1  AA
        lda  #$00                   ; F4C2  A9 00
        sbc  $51                    ; F4C4  E5 51
        bcs  L_F4E0                 ; F4C6  B0 18
        bmi  L_F4E0                 ; F4C8  30 16
        tay                         ; F4CA  A8
        lda  #$A8                   ; F4CB  A9 A8
        jsr  L_F6CC                 ; F4CD  20 CC F6
        lda  #$AD                   ; F4D0  A9 AD
        jsr  L_F6CC                 ; F4D2  20 CC F6
        tya                         ; F4D5  98
        ldy  #$00                   ; F4D6  A0 00
        jsr  L_F432                 ; F4D8  20 32 F4
        lda  #$A9                   ; F4DB  A9 A9
        jsr  L_F6CC                 ; F4DD  20 CC F6
L_F4E0:
        lda  #$A0                   ; F4E0  A9 A0
        jsr  L_F6CC                 ; F4E2  20 CC F6
        jsr  L_F6CC                 ; F4E5  20 CC F6
        lda  #$A5                   ; F4E8  A9 A5
        jsr  L_F6CC                 ; F4EA  20 CC F6
        jsr  L_F484                 ; F4ED  20 84 F4
        lda  #$05                   ; F4F0  A9 05
        jsr  L_F6CC                 ; F4F2  20 CC F6
        lda  #$8D                   ; F4F5  A9 8D
        jsr  L_F6CC                 ; F4F7  20 CC F6
        clc                         ; F4FA  18
L_F4FB:
        rts                         ; F4FB  60
L_F4FC:
        cmp  #$A4                   ; F4FC  C9 A4
        beq  L_F520                 ; F4FE  F0 20
        cmp  #$A5                   ; F500  C9 A5
        beq  L_F533                 ; F502  F0 2F
        cmp  #$AD                   ; F504  C9 AD
        bne  L_F51A                 ; F506  D0 12
        iny                         ; F508  C8
        jsr  L_F51A                 ; F509  20 1A F5
        sec                         ; F50C  38
        lda  #$00                   ; F50D  A9 00
        sbc  $50                    ; F50F  E5 50
        sta  $50                    ; F511  85 50
        lda  #$00                   ; F513  A9 00
        sbc  $51                    ; F515  E5 51
        sta  $51                    ; F517  85 51
        rts                         ; F519  60
L_F51A:
        jsr  L_E912                 ; F51A  20 12 E9
        jmp  L_F54F                 ; F51D  4C 4F F5
L_F520:
        iny                         ; F520  C8
        lda  #$00                   ; F521  A9 00
        sta  $31                    ; F523  85 31
        jsr  L_E495                 ; F525  20 95 E4
        .byte $A7,$FF               ; F528
        ldx  $3E                    ; F52A  A6 3E
        lda  $3F                    ; F52C  A5 3F
        stx  $50                    ; F52E  86 50
        sta  $51                    ; F530  85 51
        rts                         ; F532  60
L_F533:
        lda  #$00                   ; F533  A9 00
        sta  $50                    ; F535  85 50
        sta  $51                    ; F537  85 51
L_F539:
        lda  $0201,y                ; F539  B9 01 02
        beq  L_F54E                 ; F53C  F0 10
        cmp  #$B0                   ; F53E  C9 B0
        clc                         ; F540  18
        beq  L_F547                 ; F541  F0 04
        cmp  #$B1                   ; F543  C9 B1
        bne  L_F54E                 ; F545  D0 07
L_F547:
        rol  $50                    ; F547  26 50
        rol  $51                    ; F549  26 51
        iny                         ; F54B  C8
        bne  L_F539                 ; F54C  D0 EB
L_F54E:
        rts                         ; F54E  60
L_F54F:
        ldx  #$00                   ; F54F  A2 00
        stx  $50                    ; F551  86 50
        stx  $51                    ; F553  86 51
        jsr  a:$00B7                ; F555  20 B7 00
        bcc  L_F56D                 ; F558  90 13
        beq  L_F56D                 ; F55A  F0 11
        cmp  #$2E                   ; F55C  C9 2E
        bne  L_F4FB                 ; F55E  D0 9B
        lda  S_04DA                 ; F560  AD DA 04
        ldx  S_04DB                 ; F563  AE DB 04
        sta  $50                    ; F566  85 50
        stx  $51                    ; F568  86 51
        jmp  a:$00B1                ; F56A  4C B1 00
L_F56D:
        bcs  L_F4FB                 ; F56D  B0 8C
        sbc  #$2F                   ; F56F  E9 2F
        sta  $0D                    ; F571  85 0D
        lda  $51                    ; F573  A5 51
        sta  $5E                    ; F575  85 5E
        lda  $50                    ; F577  A5 50
        asl  a                      ; F579  0A
        rol  $5E                    ; F57A  26 5E
        asl  a                      ; F57C  0A
        rol  $5E                    ; F57D  26 5E
        adc  $50                    ; F57F  65 50
        sta  $50                    ; F581  85 50
        lda  $5E                    ; F583  A5 5E
        adc  $51                    ; F585  65 51
        sta  $51                    ; F587  85 51
        asl  $50                    ; F589  06 50
        rol  $51                    ; F58B  26 51
        lda  $50                    ; F58D  A5 50
        adc  $0D                    ; F58F  65 0D
        sta  $50                    ; F591  85 50
        bcc  L_F597                 ; F593  90 02
        inc  $51                    ; F595  E6 51
L_F597:
        jsr  a:$00B1                ; F597  20 B1 00
        jmp  L_F56D                 ; F59A  4C 6D F5
L_F59D:
        pla                         ; F59D  68
        pla                         ; F59E  68
        ldx  #$06                   ; F59F  A2 06
        sec                         ; F5A1  38
        rts                         ; F5A2  60
L_F5A3:
        ror  S_055E                 ; F5A3  6E 5E 05
        jsr  L_E912                 ; F5A6  20 12 E9
        bcc  L_F5C7                 ; F5A9  90 1C
        beq  L_F5C7                 ; F5AB  F0 1A
        cmp  #$2E                   ; F5AD  C9 2E
        beq  L_F5C7                 ; F5AF  F0 16
        cmp  #$2D                   ; F5B1  C9 2D
        beq  L_F5C7                 ; F5B3  F0 12
        cmp  #$2C                   ; F5B5  C9 2C
        beq  L_F5C7                 ; F5B7  F0 0E
        cmp  #$49                   ; F5B9  C9 49
        bne  L_F59D                 ; F5BB  D0 E0
        jsr  a:$00B1                ; F5BD  20 B1 00
        cmp  #$4E                   ; F5C0  C9 4E
        bne  L_F59D                 ; F5C2  D0 D9
        jsr  a:$00B1                ; F5C4  20 B1 00
L_F5C7:
        jsr  L_F54F                 ; F5C7  20 4F F5
        jsr  L_E495                 ; F5CA  20 95 E4
        .byte $1A,$D6               ; F5CD
        jsr  a:$00B7                ; F5CF  20 B7 00
        beq  L_F5DC                 ; F5D2  F0 08
        jsr  a:$00B1                ; F5D4  20 B1 00
        jsr  L_F54F                 ; F5D7  20 4F F5
        bne  L_F59D                 ; F5DA  D0 C1
L_F5DC:
        lda  $50                    ; F5DC  A5 50
        ora  $51                    ; F5DE  05 51
        bne  L_F5E8                 ; F5E0  D0 06
        lda  #$FF                   ; F5E2  A9 FF
        sta  $50                    ; F5E4  85 50
        sta  $51                    ; F5E6  85 51
L_F5E8:
        rts                         ; F5E8  60
        jsr  L_E912                 ; F5E9  20 12 E9
        .byte $20,$4F               ; F5EC
        sbc  $D0,x                  ; F5EE  F5 D0
        ldx  S_077F                 ; F5F0  AE 20 95
        cpx  $1A                    ; F5F3  E4 1A
        dec  $90,x                  ; F5F5  D6 90
        adc  $0520,y                ; F5F7  79 20 05
        inc  WNDLFT,x               ; F5FA  F6 20
        adc  $EA                    ; F5FC  65 EA
        jmp  L_E5CE                 ; F5FE  4C CE E5
        clc                         ; F601  18
        jsr  L_F5A3                 ; F602  20 A3 F5
L_F605:
        ldy  #$01                   ; F605  A0 01
        lsr  HMODE                  ; F607  4E B7 06
        lda  ($9B),y                ; F60A  B1 9B
        beq  L_F671                 ; F60C  F0 63
        lda  KBD                    ; F60E  AD 00 C0
        cmp  #$83                   ; F611  C9 83
        bne  L_F61C                 ; F613  D0 07
        bit  KBDSTRB                ; F615  2C 10 C0
        ldx  #$00                   ; F618  A2 00
        sec                         ; F61A  38
        rts                         ; F61B  60
L_F61C:
        iny                         ; F61C  C8
        lda  ($9B),y                ; F61D  B1 9B
        tax                         ; F61F  AA
        iny                         ; F620  C8
        lda  ($9B),y                ; F621  B1 9B
        cmp  $51                    ; F623  C5 51
        bne  L_F62B                 ; F625  D0 04
        cpx  $50                    ; F627  E4 50
        beq  L_F62D                 ; F629  F0 02
L_F62B:
        bcs  L_F671                 ; F62B  B0 44
L_F62D:
        sty  $85                    ; F62D  84 85
        stx  S_04DA                 ; F62F  8E DA 04
        sta  S_04DB                 ; F632  8D DB 04
        jsr  L_F430                 ; F635  20 30 F4
        lda  #$20                   ; F638  A9 20
        ldy  $85                    ; F63A  A4 85
L_F63C:
        sec                         ; F63C  38
        ror  S_04D8                 ; F63D  6E D8 04
        jsr  L_F6AE                 ; F640  20 AE F6
L_F643:
        iny                         ; F643  C8
        lda  ($9B),y                ; F644  B1 9B
        bne  L_F673                 ; F646  D0 2B
        tay                         ; F648  A8
        lda  ($9B),y                ; F649  B1 9B
        tax                         ; F64B  AA
        iny                         ; F64C  C8
        lda  ($9B),y                ; F64D  B1 9B
        stx  $9B                    ; F64F  86 9B
        sta  $9C                    ; F651  85 9C
        bit  S_055E                 ; F653  2C 5E 05
        bpl  L_F669                 ; F656  10 11
        lda  #$00                   ; F658  A9 00
        tay                         ; F65A  A8
        sta  ($FE),y                ; F65B  91 FE
        lda  SPKR                   ; F65D  AD 30 C0
        lda  SPKR                   ; F660  AD 30 C0
        jsr  L_F749                 ; F663  20 49 F7
        jmp  L_F605                 ; F666  4C 05 F6
L_F669:
        lda  #$0D                   ; F669  A9 0D
        jsr  L_F6CC                 ; F66B  20 CC F6
        jmp  L_F605                 ; F66E  4C 05 F6
L_F671:
        clc                         ; F671  18
        rts                         ; F672  60
L_F673:
        bpl  L_F63C                 ; F673  10 C7
        sec                         ; F675  38
        sbc  #$7F                   ; F676  E9 7F
        tax                         ; F678  AA
        cmp  #$49                   ; F679  C9 49
        lda  #$20                   ; F67B  A9 20
        bcc  L_F681                 ; F67D  90 02
        lda  #$00                   ; F67F  A9 00
L_F681:
        sta  S_04D9                 ; F681  8D D9 04
        sty  $85                    ; F684  84 85
        ldy  #$D0                   ; F686  A0 D0
        sty  $9D                    ; F688  84 9D
        dey                         ; F68A  88
        sty  $9E                    ; F68B  84 9E
        ldy  #$FF                   ; F68D  A0 FF
L_F68F:
        dex                         ; F68F  CA
        beq  L_F699                 ; F690  F0 07
L_F692:
        jsr  L_F6D2                 ; F692  20 D2 F6
        bpl  L_F692                 ; F695  10 FB
        bmi  L_F68F                 ; F697  30 F6
L_F699:
        jsr  L_F6C4                 ; F699  20 C4 F6
L_F69C:
        jsr  L_F6D2                 ; F69C  20 D2 F6
        php                         ; F69F  08
        jsr  L_F6AE                 ; F6A0  20 AE F6
        plp                         ; F6A3  28
        bpl  L_F69C                 ; F6A4  10 F6
        jsr  L_F6C4                 ; F6A6  20 C4 F6
        ldy  $85                    ; F6A9  A4 85
        jmp  L_F643                 ; F6AB  4C 43 F6
L_F6AE:
        bit  S_055E                 ; F6AE  2C 5E 05
        bpl  L_F6CC                 ; F6B1  10 19
        ldx  #$00                   ; F6B3  A2 00
        ora  #$80                   ; F6B5  09 80
        cmp  #$80                   ; F6B7  C9 80
        beq  L_F6C3                 ; F6B9  F0 08
        sta  ($FE,x)                ; F6BB  81 FE
        inc  $FE                    ; F6BD  E6 FE
        bne  L_F6C3                 ; F6BF  D0 02
        inc  $FF                    ; F6C1  E6 FF
L_F6C3:
        rts                         ; F6C3  60
L_F6C4:
        bit  S_055E                 ; F6C4  2C 5E 05
        bmi  L_F6D1                 ; F6C7  30 08
        lda  S_04D9                 ; F6C9  AD D9 04
L_F6CC:
        jsr  L_E495                 ; F6CC  20 95 E4
        .byte $5C,$DB               ; F6CF
L_F6D1:
        rts                         ; F6D1  60
L_F6D2:
        iny                         ; F6D2  C8
        bne  L_F6D7                 ; F6D3  D0 02
        inc  $9E                    ; F6D5  E6 9E
L_F6D7:
        jmp  S_04E8                 ; F6D7  4C E8 04
L_F6DA:
        lda  D_F6E6,x               ; F6DA  BD E6 F6
        php                         ; F6DD  08
        jsr  L_F6CC                 ; F6DE  20 CC F6
        inx                         ; F6E1  E8
        plp                         ; F6E2  28
        bpl  L_F6DA                 ; F6E3  10 F5
        rts                         ; F6E5  60
D_F6E6:
        .byte $42,$52,$45,$41,$4B,$87,$53,$79,$6E,$74,$61,$78,$20,$45,$72,$72; F6E6
        .byte $6F,$72,$87,$4D,$65,$6D,$6F,$72,$79,$20; F6F6
        lsr  $746F                  ; F700  4E 6F 74
        jsr  $7641                  ; F703  20 41 76
        adc  (VARTAB,x)             ; F706  61 69
        jmp  ($6261)                ; F708  6C 61 62
        .byte $6C,$65,$87,$46,$49,$4E,$44,$22,$73,$74,$72,$69,$6E,$67,$22,$20; F70B
        .byte $5B,$49,$4E,$5D,$20,$73,$74,$61,$72,$74,$23,$2C,$65,$6E,$64,$A3; F71B
        .byte $43,$4F,$4E,$56,$45,$52,$54,$20,$28,$2D,$29,$64,$65,$63,$69,$6D; F72B
        .byte $61,$6C,$20,$28,$24,$68,$65,$78,$2C,$25,$62,$69,$6E,$A9; F73B
L_F749:
        lda  S_055F                 ; F749  AD 5F 05
        ldy  S_0560                 ; F74C  AC 60 05
        sta  $FE                    ; F74F  85 FE
        sty  $FF                    ; F751  84 FF
        lsr  S_055D                 ; F753  4E 5D 05
L_F756:
        ldy  #$00                   ; F756  A0 00
        ldx  S_0561                 ; F758  AE 61 05
L_F75B:
        lda  INBUF,x                ; F75B  BD 00 02
        cmp  #$DE                   ; F75E  C9 DE
        beq  L_F777                 ; F760  F0 15
        cmp  #$AA                   ; F762  C9 AA
        beq  L_F795                 ; F764  F0 2F
        eor  ($FE),y                ; F766  51 FE
        beq  L_F77B                 ; F768  F0 11
        cmp  INBUF,x                ; F76A  DD 00 02
        beq  L_F7C8                 ; F76D  F0 59
L_F76F:
        inc  $FE                    ; F76F  E6 FE
        bne  L_F75B                 ; F771  D0 E8
        inc  $FF                    ; F773  E6 FF
        bne  L_F75B                 ; F775  D0 E4
L_F777:
        lda  ($FE),y                ; F777  B1 FE
        beq  L_F7C8                 ; F779  F0 4D
L_F77B:
        inx                         ; F77B  E8
        lda  INBUF,x                ; F77C  BD 00 02
        beq  L_F7AB                 ; F77F  F0 2A
        iny                         ; F781  C8
        cmp  #$DE                   ; F782  C9 DE
        beq  L_F777                 ; F784  F0 F1
        cmp  #$AA                   ; F786  C9 AA
        beq  L_F795                 ; F788  F0 0B
        cmp  ($FE),y                ; F78A  D1 FE
        beq  L_F77B                 ; F78C  F0 ED
        ldx  S_0561                 ; F78E  AE 61 05
        ldy  #$00                   ; F791  A0 00
        beq  L_F76F                 ; F793  F0 DA
L_F795:
        inx                         ; F795  E8
        lda  INBUF,x                ; F796  BD 00 02
        beq  L_F7AC                 ; F799  F0 11
        cmp  #$AA                   ; F79B  C9 AA
        beq  L_F795                 ; F79D  F0 F6
L_F79F:
        lda  ($FE),y                ; F79F  B1 FE
        beq  L_F7C8                 ; F7A1  F0 25
        cmp  INBUF,x                ; F7A3  DD 00 02
        beq  L_F77B                 ; F7A6  F0 D3
        iny                         ; F7A8  C8
        bne  L_F79F                 ; F7A9  D0 F4
L_F7AB:
        clc                         ; F7AB  18
L_F7AC:
        tya                         ; F7AC  98
        pha                         ; F7AD  48
L_F7AE:
        lda  ($FE),y                ; F7AE  B1 FE
        and  #$7F                   ; F7B0  29 7F
        sta  ($FE),y                ; F7B2  91 FE
        dey                         ; F7B4  88
        bpl  L_F7AE                 ; F7B5  10 F7
        sty  S_055D                 ; F7B7  8C 5D 05
        pla                         ; F7BA  68
        bcs  L_F7C8                 ; F7BB  B0 0B
        sec                         ; F7BD  38
        adc  $FE                    ; F7BE  65 FE
        sta  $FE                    ; F7C0  85 FE
        bcc  L_F756                 ; F7C2  90 92
        inc  $FF                    ; F7C4  E6 FF
        bne  L_F756                 ; F7C6  D0 8E
L_F7C8:
        asl  S_055D                 ; F7C8  0E 5D 05
        bcc  L_F7F8                 ; F7CB  90 2B
        lda  S_055F                 ; F7CD  AD 5F 05
        sta  $FE                    ; F7D0  85 FE
        lda  S_0560                 ; F7D2  AD 60 05
        sta  $FF                    ; F7D5  85 FF
        ldy  #$00                   ; F7D7  A0 00
L_F7D9:
        ldx  #$FF                   ; F7D9  A2 FF
        lda  ($FE),y                ; F7DB  B1 FE
        beq  L_F7F3                 ; F7DD  F0 14
        bmi  L_F7E3                 ; F7DF  30 02
        ldx  #$3F                   ; F7E1  A2 3F
L_F7E3:
        stx  INVFLG                 ; F7E3  86 32
        sec                         ; F7E5  38
        ror  S_04D8                 ; F7E6  6E D8 04
        jsr  L_F6CC                 ; F7E9  20 CC F6
        iny                         ; F7EC  C8
        bne  L_F7D9                 ; F7ED  D0 EA
        inc  $FF                    ; F7EF  E6 FF
        bne  L_F7D9                 ; F7F1  D0 E6
L_F7F3:
        lda  #$8D                   ; F7F3  A9 8D
        jsr  L_F6CC                 ; F7F5  20 CC F6
L_F7F8:
        ldy  #$00                   ; F7F8  A0 00
        sty  CH                     ; F7FA  84 24
        dey                         ; F7FC  88
        sty  INVFLG                 ; F7FD  84 32
        lda  S_055F                 ; F7FF  AD 5F 05
        sta  $FE                    ; F802  85 FE
        lda  S_0560                 ; F804  AD 60 05
        sta  $FF                    ; F807  85 FF
        rts                         ; F809  60
L_F80A:
        ldx  #$13                   ; F80A  A2 13
        sec                         ; F80C  38
        rts                         ; F80D  60
L_F80E:
        ldx  #$06                   ; F80E  A2 06
        sec                         ; F810  38
        rts                         ; F811  60
L_F812:
        ldx  #$28                   ; F812  A2 28
        sec                         ; F814  38
        rts                         ; F815  60
        beq  L_F812                 ; F816  F0 FA
        sta  S_0562                 ; F818  8D 62 05
        iny                         ; F81B  C8
        sty  S_0561                 ; F81C  8C 61 05
        ldx  #$FF                   ; F81F  A2 FF
L_F821:
        inx                         ; F821  E8
        lda  INBUF,y                ; F822  B9 00 02
        beq  L_F82F                 ; F825  F0 08
        cmp  S_0562                 ; F827  CD 62 05
        beq  L_F834                 ; F82A  F0 08
        iny                         ; F82C  C8
        bne  L_F821                 ; F82D  D0 F2
L_F82F:
        lda  #$00                   ; F82F  A9 00
        sta  $0201,y                ; F831  99 01 02
L_F834:
        cpx  #$00                   ; F834  E0 00
        beq  L_F80E                 ; F836  F0 D6
        lda  #$00                   ; F838  A9 00
        sta  INBUF,y                ; F83A  99 00 02
        iny                         ; F83D  C8
        sec                         ; F83E  38
        jsr  L_F5A3                 ; F83F  20 A3 F5
        jsr  L_E495                 ; F842  20 95 E4
        eor  #$D8                   ; F845  49 D8
        lda  #$00                   ; F847  A9 00
        sta  $7A                    ; F849  85 7A
        sta  $14                    ; F84B  85 14
        ldx  VARTAB                 ; F84D  A6 69
        ldy  $6A                    ; F84F  A4 6A
        stx  $6B                    ; F851  86 6B
        sty  $6C                    ; F853  84 6C
        stx  $6D                    ; F855  86 6D
        sty  $6E                    ; F857  84 6E
        ldx  HIMEMZ                 ; F859  A6 73
        lda  $74                    ; F85B  A5 74
        stx  FRETOP                 ; F85D  86 6F
        sta  $70                    ; F85F  85 70
        sec                         ; F861  38
        sbc  #$02                   ; F862  E9 02
        sta  $FF                    ; F864  85 FF
        stx  $FE                    ; F866  86 FE
        sta  S_0560                 ; F868  8D 60 05
        stx  S_055F                 ; F86B  8E 5F 05
        lda  $FE                    ; F86E  A5 FE
        cmp  VARTAB                 ; F870  C5 69
        lda  $FF                    ; F872  A5 FF
        sbc  $6A                    ; F874  E5 6A
        bcc  L_F80A                 ; F876  90 92
        lda  $FF                    ; F878  A5 FF
        sbc  $E6                    ; F87A  E5 E6
        sbc  #$20                   ; F87C  E9 20
        bcc  L_F80A                 ; F87E  90 8A
        jmp  L_F605                 ; F880  4C 05 F6
        ldy  #$00                   ; F883  A0 00
        ldx  #$FF                   ; F885  A2 FF
        jsr  a:$00B7                ; F887  20 B7 00
        cmp  #$3B                   ; F88A  C9 3B
        bne  L_F8B9                 ; F88C  D0 2B
        jsr  a:$00B1                ; F88E  20 B1 00
L_F891:
        jsr  a:$00B7                ; F891  20 B7 00
L_F894:
        inx                         ; F894  E8
        pha                         ; F895  48
        lda  D_F8DC,x               ; F896  BD DC F8
        beq  L_F8A7                 ; F899  F0 0C
        pla                         ; F89B  68
        cmp  D_F8DC,x               ; F89C  DD DC F8
        bne  L_F8B4                 ; F89F  D0 13
        jsr  a:$00B1                ; F8A1  20 B1 00
        jmp  L_F894                 ; F8A4  4C 94 F8
L_F8A7:
        pla                         ; F8A7  68
        tya                         ; F8A8  98
        asl  a                      ; F8A9  0A
        tax                         ; F8AA  AA
        lda  D_F92A,x               ; F8AB  BD 2A F9
        pha                         ; F8AE  48
        lda  D_F929,x               ; F8AF  BD 29 F9
        pha                         ; F8B2  48
        rts                         ; F8B3  60
L_F8B4:
        iny                         ; F8B4  C8
        cpy  #$0E                   ; F8B5  C0 0E
        bne  L_F8BE                 ; F8B7  D0 05
L_F8B9:
        jsr  L_E495                 ; F8B9  20 95 E4
        cmp  #$DE                   ; F8BC  C9 DE
L_F8BE:
        lda  #$06                   ; F8BE  A9 06
        sta  $C1                    ; F8C0  85 C1
L_F8C2:
        dec  $B8                    ; F8C2  C6 B8
        jsr  a:$00B7                ; F8C4  20 B7 00
        cmp  #$3B                   ; F8C7  C9 3B
        bne  L_F8C2                 ; F8C9  D0 F7
        lda  #$EF                   ; F8CB  A9 EF
        sta  $C1                    ; F8CD  85 C1
        pha                         ; F8CF  48
L_F8D0:
        inx                         ; F8D0  E8
        lda  D_F8DC,x               ; F8D1  BD DC F8
        bne  L_F8D0                 ; F8D4  D0 FA
        pla                         ; F8D6  68
        inc  $B8                    ; F8D7  E6 B8
        jmp  L_F891                 ; F8D9  4C 91 F8
D_F8DC:
        .byte $BA,$B4,$00,$BA,$4F,$46,$46,$00,$57; F8DC
        eor  #$4E                   ; F8E5  49 4E
        .byte $44,$4F,$57,$00,$59,$4F,$46,$46,$53,$45,$54,$00,$CE,$B4,$00,$CE; F8E7
        .byte $4F,$46,$46,$00,$55,$4C,$B4,$00,$55,$4C,$4F,$46,$46,$00,$BE,$89; F8F7
        .byte $00,$BE,$57,$CE,$44,$00,$BE,$43,$48,$41,$52,$00,$45; F907
        lsr  $5447                  ; F914  4E 47 54
        eor  ($42,x)                ; F917  41 42
        jmp  a:$0045                ; F919  4C 45 00
        .byte $53,$45,$54,$50,$41,$47,$45,$00,$87,$57,$CE,$44,$00; F91C
D_F929:
        .byte $44                   ; F929
D_F92A:
        .byte $F9,$4A,$F9,$61,$FA,$50,$F9,$63,$F9,$69,$F9,$6F,$F9,$75,$F9,$7B; F92A
        .byte $F9,$BB,$F9,$E3,$F9,$10,$FA,$C4,$FA,$CF,$FB; F93A
        lda  #$FF                   ; F945  A9 FF
        sta  S_07DA                 ; F947  8D DA 07
        rts                         ; F94A  60
        lda  #$00                   ; F94B  A9 00
        sta  S_07DA                 ; F94D  8D DA 07
        rts                         ; F950  60
        ldx  #$00                   ; F951  A2 00
        jsr  a:$00B7                ; F953  20 B7 00
        beq  L_F95C+1               ; F956  F0 05
        jsr  L_E495                 ; F958  20 95 E4
        sed                         ; F95B  F8
L_F95C:
        inc  $8A                    ; F95C  E6 8A
        and  #$0F                   ; F95E  29 0F
        sta  S_06AE                 ; F960  8D AE 06
        rts                         ; F963  60
        lda  #$FF                   ; F964  A9 FF
        sta  S_06AF                 ; F966  8D AF 06
        rts                         ; F969  60
        lda  #$00                   ; F96A  A9 00
        sta  S_06AF                 ; F96C  8D AF 06
        rts                         ; F96F  60
        lda  #$7F                   ; F970  A9 7F
        sta  S_06B0                 ; F972  8D B0 06
        rts                         ; F975  60
        lda  #$00                   ; F976  A9 00
        sta  S_06B0                 ; F978  8D B0 06
        rts                         ; F97B  60
        jsr  L_FAF1                 ; F97C  20 F1 FA
        jsr  L_E495                 ; F97F  20 95 E4
        jmp  L_E0E7                 ; F982  4C E7 E0
        plp                         ; F985  28
        bcc  L_F98A                 ; F986  90 02
        ldx  #$28                   ; F988  A2 28
L_F98A:
        stx  S_0551                 ; F98A  8E 51 05
        ldy  #$00                   ; F98D  A0 00
        lda  #$2C                   ; F98F  A9 2C
        cmp  ($B8),y                ; F991  D1 B8
        beq  L_F9A0                 ; F993  F0 0B
        lda  #$3B                   ; F995  A9 3B
        cmp  ($B8),y                ; F997  D1 B8
        beq  L_F9A0                 ; F999  F0 05
        jsr  L_E495                 ; F99B  20 95 E4
        cmp  #$DE                   ; F99E  C9 DE
L_F9A0:
        jsr  a:$00B1                ; F9A0  20 B1 00
        jsr  L_E495                 ; F9A3  20 95 E4
        .byte $E3,$DF,$AD,$51,$05,$F0,$0B,$0A,$0A,$20,$95; F9A6
L_F9B1:
        cpx  $52                    ; F9B1  E4 52
        cpx  WNDLFT                 ; F9B3  E4 20
        bpl  L_F9B1+1               ; F9B5  10 FB
        txa                         ; F9B7  8A
        ldy  #$00                   ; F9B8  A0 00
        beq  L_FA04                 ; F9BA  F0 48
        jsr  L_FAF1                 ; F9BC  20 F1 FA
L_F9BF:
        ldx  #$00                   ; F9BF  A2 00
        ldy  CH                     ; F9C1  A4 24
        lda  #$A0                   ; F9C3  A9 A0
        cmp  S_05D0,y               ; F9C5  D9 D0 05
        beq  L_F9DE                 ; F9C8  F0 14
        dex                         ; F9CA  CA
L_F9CB:
        iny                         ; F9CB  C8
        cpy  WNDWDTH                ; F9CC  C4 21
        bcs  L_F9D5                 ; F9CE  B0 05
        cmp  S_05D0,y               ; F9D0  D9 D0 05
        bne  L_F9CB                 ; F9D3  D0 F6
L_F9D5:
        inx                         ; F9D5  E8
        dey                         ; F9D6  88
        bmi  L_F9DE                 ; F9D7  30 05
        cmp  S_05D0,y               ; F9D9  D9 D0 05
        bne  L_F9D5                 ; F9DC  D0 F7
L_F9DE:
        iny                         ; F9DE  C8
        sty  CH                     ; F9DF  84 24
        jmp  L_F98A                 ; F9E1  4C 8A F9
        jsr  L_FAF1                 ; F9E4  20 F1 FA
        jsr  L_E495                 ; F9E7  20 95 E4
        ldx  $20DE,y                ; F9EA  BE DE 20
        sta  $E4,x                  ; F9ED  95 E4
        .byte $E3,$DF,$A9,$01,$20,$95; F9EF
        cpx  $52                    ; F9F5  E4 52
        cpx  $A4                    ; F9F7  E4 A4
        bit  $B1                    ; F9F9  24 B1
        plp                         ; F9FB  28
        eor  #$80                   ; F9FC  49 80
        ldy  #$00                   ; F9FE  A0 00
        sta  (FRETOP),y             ; FA00  91 6F
        lda  #$01                   ; FA02  A9 01
L_FA04:
        sta  ($83),y                ; FA04  91 83
        iny                         ; FA06  C8
        lda  FRETOP                 ; FA07  A5 6F
        sta  ($83),y                ; FA09  91 83
        iny                         ; FA0B  C8
        lda  $70                    ; FA0C  A5 70
        sta  ($83),y                ; FA0E  91 83
        rts                         ; FA10  60
        jsr  a:$00B7                ; FA11  20 B7 00
        bne  L_FA1C                 ; FA14  D0 06
        ldy  #$00                   ; FA16  A0 00
        lda  #$D0                   ; FA18  A9 D0
        bne  L_FA26                 ; FA1A  D0 0A
L_FA1C:
        jsr  L_E495                 ; FA1C  20 95 E4
        .byte $67,$DD,$20,$95,$E4,$52,$E7; FA1F
L_FA26:
        sty  S_07DB                 ; FA26  8C DB 07
        sta  S_07DC                 ; FA29  8D DC 07
        rts                         ; FA2C  60
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$85,$45,$A9,$FF,$8D; FA2D
        .byte $F7,$07,$8D,$82,$C0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; FA3D
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; FA4D
        .byte $00,$00               ; FA5D
        sta  LCROMRD                ; FA5F  8D 82 C0
        ldx  #$00                   ; FA62  A2 00
        stx  S_056C                 ; FA64  8E 6C 05
        stx  S_056E                 ; FA67  8E 6E 05
        ldx  #$2E                   ; FA6A  A2 2E
        stx  S_056D                 ; FA6C  8E 6D 05
        ldx  #$10                   ; FA6F  A2 10
        stx  S_056F                 ; FA71  8E 6F 05
        jsr  a:$00B7                ; FA74  20 B7 00
        beq  L_FA98+1               ; FA77  F0 20
        jsr  L_E495                 ; FA79  20 95 E4
        sed                         ; FA7C  F8
        inc  $8E                    ; FA7D  E6 8E
        jmp  ($2005)                ; FA7F  6C 05 20
        sta  $E4,x                  ; FA82  95 E4
        jmp  $8EE7                  ; FA84  4C E7 8E
        adc  $2005                  ; FA87  6D 05 20
        sta  $E4,x                  ; FA8A  95 E4
        jmp  $8EE7                  ; FA8C  4C E7 8E
        ror  $2005                  ; FA8F  6E 05 20
        sta  $E4,x                  ; FA92  95 E4
        jmp  $8EE7                  ; FA94  4C E7 8E
        .byte $6F                   ; FA97
L_FA98:
        ora  $AD                    ; FA98  05 AD
        jmp  ($1805)                ; FA9A  6C 05 18
        adc  S_056D                 ; FA9D  6D 6D 05
        bcs  L_FAD8                 ; FAA0  B0 36
        cmp  #$2F                   ; FAA2  C9 2F
        bcs  L_FAD8                 ; FAA4  B0 32
        lda  S_056E                 ; FAA6  AD 6E 05
        cmp  S_056F                 ; FAA9  CD 6F 05
        bcs  L_FAD8                 ; FAAC  B0 2A
        lda  S_056C                 ; FAAE  AD 6C 05
        sta  WNDLFT                 ; FAB1  85 20
        lda  S_056D                 ; FAB3  AD 6D 05
        sta  WNDWDTH                ; FAB6  85 21
        lda  S_056E                 ; FAB8  AD 6E 05
        sta  WNDTOP                 ; FABB  85 22
        lda  S_056F                 ; FABD  AD 6F 05
        sta  WNDBTM                 ; FAC0  85 23
        jmp  WNDCLAMP               ; FAC2  4C 41 E4
        jsr  L_E495                 ; FAC5  20 95 E4
        sed                         ; FAC8  F8
        .byte $E6,$E0,$00,$F0,$11,$A9,$20,$CA,$F0,$0A,$A9,$40,$CA,$F0,$05; FAC9
L_FAD8:
        .byte $20,$95,$E4,$99,$E1,$85,$E6,$20,$95,$E4,$4C,$E7,$E0,$00; FAD8
        beq  L_FAF0                 ; FAE6  F0 08
        dex                         ; FAE8  CA
        cpx  #$02                   ; FAE9  E0 02
        bcs  L_FAD8                 ; FAEB  B0 EB
        lda  LOWSCR,x               ; FAED  BD 54 C0
L_FAF0:
        rts                         ; FAF0  60
L_FAF1:
        jsr  L_E495                 ; FAF1  20 95 E4
        sed                         ; FAF4  F8
        inc  $CA                    ; FAF5  E6 CA
        cpx  WNDWDTH                ; FAF7  E4 21
        bcs  L_FAD8                 ; FAF9  B0 DD
        stx  CH                     ; FAFB  86 24
        jsr  L_E495                 ; FAFD  20 95 E4
        jmp  $CAE7                  ; FB00  4C E7 CA
        cpx  #$10                   ; FB03  E0 10
        bcs  L_FAD8                 ; FB05  B0 D1
        txa                         ; FB07  8A
        sta  CV                     ; FB08  85 25
        jsr  L_EC73                 ; FB0A  20 73 EC
        jmp  L_EA7D                 ; FB0D  4C 7D EA
        ldx  #$00                   ; FB10  A2 00
        stx  S_04DD                 ; FB12  8E DD 04
        lda  #$29                   ; FB15  A9 29
        sta  S_06BB                 ; FB17  8D BB 06
        lda  #$7F                   ; FB1A  A9 7F
        sta  S_06BC                 ; FB1C  8D BC 06
        lda  FRETOP                 ; FB1F  A5 6F
        sta  S_06BE                 ; FB21  8D BE 06
        lda  $70                    ; FB24  A5 70
        sta  S_06BF                 ; FB26  8D BF 06
        ldy  CH                     ; FB29  A4 24
        sty  S_056B                 ; FB2B  8C 6B 05
L_FB2E:
        ldy  S_056B                 ; FB2E  AC 6B 05
        cpy  WNDWDTH                ; FB31  C4 21
        bcs  L_FB74                 ; FB33  B0 3F
        lda  (BASL),y               ; FB35  B1 28
        bpl  L_FB49                 ; FB37  10 10
        jsr  L_FB74                 ; FB39  20 74 FB
        jsr  S_06BB                 ; FB3C  20 BB 06
        inc  S_056B                 ; FB3F  EE 6B 05
        dec  S_0551                 ; FB42  CE 51 05
        bne  L_FB2E                 ; FB45  D0 E7
        beq  L_FB74                 ; FB47  F0 2B
L_FB49:
        bit  S_04DD                 ; FB49  2C DD 04
        bmi  L_FB58                 ; FB4C  30 0A
        lda  #$FF                   ; FB4E  A9 FF
        sta  S_04DD                 ; FB50  8D DD 04
        lda  #$0B                   ; FB53  A9 0B
        jsr  S_06BB                 ; FB55  20 BB 06
L_FB58:
        lda  (BASL),y               ; FB58  B1 28
        sta  LEAD                   ; FB5A  8D A9 06
        iny                         ; FB5D  C8
        lda  (BASL),y               ; FB5E  B1 28
        sta  TRAIL                  ; FB60  8D AA 06
        iny                         ; FB63  C8
        sty  S_056B                 ; FB64  8C 6B 05
        jsr  EMITKEY                ; FB67  20 94 F3
        dec  S_0551                 ; FB6A  CE 51 05
        beq  L_FB74                 ; FB6D  F0 05
        dec  S_0551                 ; FB6F  CE 51 05
        bne  L_FB2E                 ; FB72  D0 BA
L_FB74:
        pha                         ; FB74  48
        bit  S_04DD                 ; FB75  2C DD 04
        bpl  L_FB84                 ; FB78  10 0A
        lda  #$00                   ; FB7A  A9 00
        sta  S_04DD                 ; FB7C  8D DD 04
        lda  #$01                   ; FB7F  A9 01
        jsr  S_06BB                 ; FB81  20 BB 06
L_FB84:
        pla                         ; FB84  68
        rts                         ; FB85  60
L_FB86:
        ldy  CH                     ; FB86  A4 24
L_FB88:
        dey                         ; FB88  88
        bmi  L_FB91                 ; FB89  30 06
        lda  (BASL),y               ; FB8B  B1 28
        cmp  #$A0                   ; FB8D  C9 A0
        bne  L_FB88                 ; FB8F  D0 F7
L_FB91:
        iny                         ; FB91  C8
        sty  CH                     ; FB92  84 24
        rts                         ; FB94  60
L_FB95:
        lda  CV                     ; FB95  A5 25
        jsr  L_EC4E                 ; FB97  20 4E EC
        lda  S_0555                 ; FB9A  AD 55 05
        clc                         ; FB9D  18
        adc  S_06AE                 ; FB9E  6D AE 06
        tax                         ; FBA1  AA
        lda  #$0C                   ; FBA2  A9 0C
        sta  S_0553                 ; FBA4  8D 53 05
L_FBA7:
        lda  HGRLO,x                ; FBA7  BD DC E0
        clc                         ; FBAA  18
        adc  #$00                   ; FBAB  69 00
        sta  $FC                    ; FBAD  85 FC
        lda  HGRHI,x                ; FBAF  BD 9C E1
        ora  $E6                    ; FBB2  05 E6
        sta  $FD                    ; FBB4  85 FD
        ldy  CH                     ; FBB6  A4 24
L_FBB8:
        lda  (BASL),y               ; FBB8  B1 28
        cmp  #$A0                   ; FBBA  C9 A0
        beq  L_FBC9                 ; FBBC  F0 0B
        lda  ($FC),y                ; FBBE  B1 FC
        eor  #$7F                   ; FBC0  49 7F
        sta  ($FC),y                ; FBC2  91 FC
        iny                         ; FBC4  C8
        cpy  #$28                   ; FBC5  C0 28
        bcc  L_FBB8                 ; FBC7  90 EF
L_FBC9:
        inx                         ; FBC9  E8
        dec  S_0553                 ; FBCA  CE 53 05
        bne  L_FBA7                 ; FBCD  D0 D8
        rts                         ; FBCF  60
        jsr  L_FAF1                 ; FBD0  20 F1 FA
        lda  CV                     ; FBD3  A5 25
        cmp  WNDTOP                 ; FBD5  C5 22
        ldy  WNDTOP                 ; FBD7  A4 22
        bcc  L_FBE2                 ; FBD9  90 07
        cmp  WNDBTM                 ; FBDB  C5 23
        bcc  L_FBE7                 ; FBDD  90 08
        ldy  WNDBTM                 ; FBDF  A4 23
        dey                         ; FBE1  88
L_FBE2:
        sty  CV                     ; FBE2  84 25
        jsr  L_EC71                 ; FBE4  20 71 EC
L_FBE7:
        jsr  L_FC0D                 ; FBE7  20 0D FC
        bcs  L_FBFD                 ; FBEA  B0 11
        ldy  #$00                   ; FBEC  A0 00
        lda  #$3B                   ; FBEE  A9 3B
        cmp  ($B8),y                ; FBF0  D1 B8
        beq  L_FBF7                 ; FBF2  F0 03
        jsr  L_FB95                 ; FBF4  20 95 FB
L_FBF7:
        jsr  L_EA7D                 ; FBF7  20 7D EA
        jmp  L_F9BF                 ; FBFA  4C BF F9
L_FBFD:
        ldx  #$00                   ; FBFD  A2 00
        jmp  L_F98A                 ; FBFF  4C 8A F9
L_FC02:
        lda  #$20                   ; FC02  A9 20
        jsr  L_E602                 ; FC04  20 02 E6
        lda  KBD                    ; FC07  AD 00 C0
        bmi  L_FC10                 ; FC0A  30 04
L_FC0C:
        rts                         ; FC0C  60
L_FC0D:
        jsr  L_FCBA                 ; FC0D  20 BA FC
L_FC10:
        jsr  L_FB86                 ; FC10  20 86 FB
        jsr  L_FB95                 ; FC13  20 95 FB
L_FC16:
        lda  KBD                    ; FC16  AD 00 C0
        bpl  L_FC16                 ; FC19  10 FB
        bit  KBDSTRB                ; FC1B  2C 10 C0
        cmp  #$8D                   ; FC1E  C9 8D
        clc                         ; FC20  18
        beq  L_FC0C                 ; FC21  F0 E9
        pha                         ; FC23  48
        jsr  L_FB95                 ; FC24  20 95 FB
        pla                         ; FC27  68
        cmp  #$9B                   ; FC28  C9 9B
        beq  L_FC02                 ; FC2A  F0 D6
        ldy  #$03                   ; FC2C  A0 03
L_FC2E:
        cmp  D_FC47,y               ; FC2E  D9 47 FC
        beq  L_FC57                 ; FC31  F0 24
        cmp  D_FC4B,y               ; FC33  D9 4B FC
        beq  L_FC57                 ; FC36  F0 1F
        cmp  D_FC4F,y               ; FC38  D9 4F FC
        beq  L_FC57                 ; FC3B  F0 1A
        cmp  D_FC53,y               ; FC3D  D9 53 FC
        beq  L_FC57                 ; FC40  F0 15
        dey                         ; FC42  88
        bpl  L_FC2E                 ; FC43  10 E9
        bmi  L_FC10                 ; FC45  30 C9
D_FC47:
        .byte $CB                   ; FC47
        dex                         ; FC48  CA
        .byte $CD,$C9               ; FC49
D_FC4B:
        cmp  ($C2,x)                ; FC4B  C1 C2
        .byte $C3,$C4               ; FC4D
D_FC4F:
        .byte $95                   ; FC4F
        dey                         ; FC50  88
        txa                         ; FC51  8A
        .byte $8B                   ; FC52
D_FC53:
        .byte $B6                   ; FC53
        ldy  $B2,x                  ; FC54  B4 B2
        clv                         ; FC56  B8
L_FC57:
        lda  #$FC                   ; FC57  A9 FC
        pha                         ; FC59  48
        lda  #$0F                   ; FC5A  A9 0F
        pha                         ; FC5C  48
        dey                         ; FC5D  88
        beq  L_FCCE                 ; FC5E  F0 6E
        dey                         ; FC60  88
        beq  L_FCA4                 ; FC61  F0 41
        dey                         ; FC63  88
        beq  L_FC68                 ; FC64  F0 02
        bne  L_FC89                 ; FC66  D0 21
L_FC68:
        jsr  L_FD0E                 ; FC68  20 0E FD
        bcc  L_FC75                 ; FC6B  90 08
        ldy  WNDBTM                 ; FC6D  A4 23
        dey                         ; FC6F  88
        sty  CV                     ; FC70  84 25
        jsr  L_EC71                 ; FC72  20 71 EC
L_FC75:
        jsr  L_FD4E                 ; FC75  20 4E FD
        bcc  L_FCBA                 ; FC78  90 40
        jsr  L_FD5B                 ; FC7A  20 5B FD
        bcs  L_FC68                 ; FC7D  B0 E9
L_FC7F:
        jsr  L_FD19                 ; FC7F  20 19 FD
L_FC82:
        bcc  L_FCFC                 ; FC82  90 78
        jsr  L_E5A4                 ; FC84  20 A4 E5
        bcc  L_FC7F                 ; FC87  90 F6
L_FC89:
        ldy  CH                     ; FC89  A4 24
        lda  #$A0                   ; FC8B  A9 A0
L_FC8D:
        cmp  (BASL),y               ; FC8D  D1 28
        beq  L_FC9F                 ; FC8F  F0 0E
        iny                         ; FC91  C8
        cpy  WNDWDTH                ; FC92  C4 21
        bcc  L_FC8D                 ; FC94  90 F7
        dey                         ; FC96  88
        sty  CH                     ; FC97  84 24
        jsr  L_FD21                 ; FC99  20 21 FD
        jmp  L_FC82                 ; FC9C  4C 82 FC
L_FC9F:
        sty  CH                     ; FC9F  84 24
        jmp  L_FC7F                 ; FCA1  4C 7F FC
L_FCA4:
        jsr  L_FD42                 ; FCA4  20 42 FD
        bcc  L_FCB0                 ; FCA7  90 07
        lda  WNDTOP                 ; FCA9  A5 22
        sta  CV                     ; FCAB  85 25
        jsr  L_EC73                 ; FCAD  20 73 EC
L_FCB0:
        jsr  L_FD5B                 ; FCB0  20 5B FD
        bcc  L_FC7F                 ; FCB3  90 CA
        jsr  L_FD4E                 ; FCB5  20 4E FD
        bcs  L_FCA4                 ; FCB8  B0 EA
L_FCBA:
        jsr  L_FCE7                 ; FCBA  20 E7 FC
L_FCBD:
        bcc  L_FCFC                 ; FCBD  90 3D
        ldy  WNDWDTH                ; FCBF  A4 21
        dey                         ; FCC1  88
        sty  CH                     ; FCC2  84 24
        ldy  WNDBTM                 ; FCC4  A4 23
        dey                         ; FCC6  88
        sty  CV                     ; FCC7  84 25
        jsr  L_EC4E                 ; FCC9  20 4E EC
        bcc  L_FCBA                 ; FCCC  90 EC
L_FCCE:
        ldy  CH                     ; FCCE  A4 24
        lda  #$A0                   ; FCD0  A9 A0
L_FCD2:
        cmp  (BASL),y               ; FCD2  D1 28
        beq  L_FCE2                 ; FCD4  F0 0C
        dey                         ; FCD6  88
        bpl  L_FCD2                 ; FCD7  10 F9
        iny                         ; FCD9  C8
        sty  CH                     ; FCDA  84 24
        jsr  L_FCEF                 ; FCDC  20 EF FC
        jmp  L_FCBD                 ; FCDF  4C BD FC
L_FCE2:
        sty  CH                     ; FCE2  84 24
        jmp  L_FCBA                 ; FCE4  4C BA FC
L_FCE7:
        ldy  CH                     ; FCE7  A4 24
        lda  (BASL),y               ; FCE9  B1 28
        cmp  #$A0                   ; FCEB  C9 A0
        bne  L_FCFC                 ; FCED  D0 0D
L_FCEF:
        jsr  L_FCF5                 ; FCEF  20 F5 FC
        bcc  L_FCE7                 ; FCF2  90 F3
        rts                         ; FCF4  60
L_FCF5:
        ldy  CH                     ; FCF5  A4 24
        dey                         ; FCF7  88
        bmi  L_FCFE                 ; FCF8  30 04
        sty  CH                     ; FCFA  84 24
L_FCFC:
        clc                         ; FCFC  18
        rts                         ; FCFD  60
L_FCFE:
        ldy  CV                     ; FCFE  A4 25
        cpy  WNDTOP                 ; FD00  C4 22
        beq  L_FD0D                 ; FD02  F0 09
        ldy  WNDWDTH                ; FD04  A4 21
        dey                         ; FD06  88
        sty  CH                     ; FD07  84 24
        jsr  L_E9B5                 ; FD09  20 B5 E9
L_FD0C:
        clc                         ; FD0C  18
L_FD0D:
        rts                         ; FD0D  60
L_FD0E:
        ldy  CV                     ; FD0E  A4 25
        cpy  WNDTOP                 ; FD10  C4 22
        beq  L_FD0D                 ; FD12  F0 F9
        jsr  L_E9B5                 ; FD14  20 B5 E9
        clc                         ; FD17  18
        rts                         ; FD18  60
L_FD19:
        ldy  CH                     ; FD19  A4 24
        lda  (BASL),y               ; FD1B  B1 28
        cmp  #$A0                   ; FD1D  C9 A0
        bne  L_FCFC                 ; FD1F  D0 DB
L_FD21:
        jsr  L_FD27                 ; FD21  20 27 FD
        bcc  L_FD19                 ; FD24  90 F3
        rts                         ; FD26  60
L_FD27:
        ldy  CH                     ; FD27  A4 24
        iny                         ; FD29  C8
        cpy  WNDWDTH                ; FD2A  C4 21
        bcs  L_FD31                 ; FD2C  B0 03
        sty  CH                     ; FD2E  84 24
        rts                         ; FD30  60
L_FD31:
        ldy  CV                     ; FD31  A4 25
        iny                         ; FD33  C8
        cpy  WNDBTM                 ; FD34  C4 23
        bcc  L_FD39                 ; FD36  90 01
        rts                         ; FD38  60
L_FD39:
        sty  CV                     ; FD39  84 25
        lda  #$00                   ; FD3B  A9 00
        sta  CH                     ; FD3D  85 24
        jmp  L_EC4E                 ; FD3F  4C 4E EC
L_FD42:
        ldy  CV                     ; FD42  A4 25
        iny                         ; FD44  C8
        cpy  WNDBTM                 ; FD45  C4 23
        bcs  L_FD0D                 ; FD47  B0 C4
        sty  CV                     ; FD49  84 25
        jmp  L_EC4E                 ; FD4B  4C 4E EC
L_FD4E:
        ldy  CH                     ; FD4E  A4 24
        lda  #$A0                   ; FD50  A9 A0
L_FD52:
        cmp  (BASL),y               ; FD52  D1 28
        bne  L_FCFC                 ; FD54  D0 A6
        dey                         ; FD56  88
        bpl  L_FD52                 ; FD57  10 F9
        sec                         ; FD59  38
        rts                         ; FD5A  60
L_FD5B:
        ldy  CH                     ; FD5B  A4 24
        lda  #$A0                   ; FD5D  A9 A0
L_FD5F:
        cmp  (BASL),y               ; FD5F  D1 28
        bne  L_FCFC                 ; FD61  D0 99
        iny                         ; FD63  C8
        cpy  WNDWDTH                ; FD64  C4 21
        bcc  L_FD5F                 ; FD66  90 F7
L_FD68:
        rts                         ; FD68  60
; ---- stub block, copied by INIT to $949D (old text page $06A8), 40 bytes ----
;   949D  10 00     bpl $949F
;   949F  00        brk

        .byte $10,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; FD69
        .byte $00,$00,$00,$09,$80,$9D,$00,$02,$E8,$60,$00,$00,$00,$00,$00,$00; FD79
        .byte $00,$00,$00,$00,$00,$00,$00,$00; FD89
; ---- stub block, copied by INIT to $94C9 (old text page $0728), 40 bytes ----
;   94C9  A2 01     ldx #$01
;   94CB  20 14 94  jsr S_0464
;   94CE  8D 80 C0  sta LCRAMRD
;   94D1  CA        dex
;   94D2  F0 0A     beq $94DE
;   94D4  C9 88     cmp #$88
;   94D6  D0 06     bne $94DE
;   94D8  20 1E 94  jsr S_046E
;   94DB  4C C9 94  jmp S_0728
;   94DE  20 49 95  jsr S_07A8
;   94E1  4C C9 94  jmp S_0728

        .byte $A2,$01,$20,$14,$94,$8D,$80,$C0,$CA,$F0,$0A,$C9,$88,$D0,$06,$20; FD91
        .byte $1E,$94,$4C,$C9,$94,$20,$49,$95,$4C,$C9,$94,$68,$68,$60,$4C,$0B; FDA1
        .byte $EA,$4C,$C3,$E5,$4C,$56,$EE,$00; FDB1
; ---- stub block, copied by INIT to $9549 (old text page $07A8), 40 bytes ----
;   9549  C9 9F     cmp #$9F
;   954B  F0 99     beq $94E6
;   954D  2C 30 94  bit S_04D8
;   9550  30 14     bmi $9566
;   9552  C9 8D     cmp #$8D
;   9554  F0 8E     beq $94E4
;   9556  C9 92     cmp #$92
;   9558  F0 93     beq $94ED
;   955A  C9 9A     cmp #$9A
;   955C  F0 88     beq $94E6
;   955E  C9 9B     cmp #$9B
;   9560  F0 85     beq $94E7
;   9562  C9 94     cmp #$94
;   9564  F0 84     beq $94EA
;   9566  20 20 94  jsr S_0470
;   9569  8D 80 C0  sta LCRAMRD
;   956C  4C 39 EE  jmp D_EE39+0

        .byte $C9,$9F,$F0,$99,$2C,$30,$94,$30,$14,$C9,$8D,$F0,$8E,$C9,$92,$F0; FDB9
        .byte $93,$C9,$9A,$F0,$88,$C9,$9B,$F0,$85,$C9,$94,$F0,$84,$20,$20,$94; FDC9
        .byte $8D,$80,$C0,$4C,$39,$EE,$00,$00; FDD9
; ---- stub block, copied by INIT to $9400 (old text page $0450), 40 bytes ----
;   9400  8D 80 C0  sta LCRAMRD
;   9403  20 D3 EA  jsr KEYREAD
;   9406  8D 82 C0  sta LCROMRD
;   9409  60        rts

        .byte $8D,$80,$C0,$20,$D3,$EA,$8D,$82,$C0,$60,$8D,$80,$C0,$20,$63,$EE; FDE1
        .byte $8D,$82,$C0,$60,$8D,$82,$C0,$A4,$24,$B1,$28,$6C,$38,$00,$A9,$80; FDF1
        .byte $8D,$82,$C0,$6C,$36,$00,$00,$00; FE01
; ---- stub block, copied by INIT to $9428 (old text page $04D0), 40 bytes ----
;   9428  00        brk

        .byte $00,$00,$FF,$00,$00,$00,$00,$00,$00,$20,$00,$00,$FF,$00,$8D,$82; FE09
        .byte $C0,$20,$00,$D0,$8D,$80,$C0,$60,$8D,$82,$C0,$B1,$9D,$8D,$80,$C0; FE19
        .byte $60,$00,$00,$00,$00,$00,$00,$00; FE29
; ---- stub block, copied by INIT to $9571 (old text page $07D0), 40 bytes ----
;   9571  8D 80 C0  sta LCRAMRD
;   9574  20 83 F8  jsr D_F883+0
;   9577  8D 82 C0  sta LCROMRD
;   957A  60        rts

        .byte $8D,$80,$C0,$20,$83,$F8,$8D,$82,$C0,$60,$00,<ENGFONT,>ENGFONT,$00,$00,$00; FE31
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; FE41
        .byte $00,$00,$00,$00,$00,$00,$00,$00; FE51

; ==========================================================================
; Hangul syllable pieces: pick and combine the initial, vowel and final glyphs
; ==========================================================================
PSETUP:
        ldy  P1H                    ; FE59  A4 03
        lda  P1L                    ; FE5B  A5 02
        cmp  #$0C                   ; FE5D  C9 0C
        bne  PW6                    ; FE5F  D0 05
        tya                         ; FE61  98
        clc                         ; FE62  18
        adc  #$07                   ; FE63  69 07
        tay                         ; FE65  A8
PW6:
        lda  $1940,y                ; FE66  B9 40 19
        sta  M0                     ; FE69  8D F0 1F
        lda  $194E,y                ; FE6C  B9 4E 19
        sta  M1                     ; FE6F  8D F1 1F
        lda  $195C,y                ; FE72  B9 5C 19
        sta  M2                     ; FE75  8D F2 1F
        ldx  #$01                   ; FE78  A2 01
        lda  M1                     ; FE7A  AD F1 1F
        beq  PNB                    ; FE7D  F0 07
        inx                         ; FE7F  E8
        lda  M2                     ; FE80  AD F2 1F
        beq  PNB                    ; FE83  F0 01
        inx                         ; FE85  E8
PNB:
        stx  NB                     ; FE86  8E F6 1F
        lda  MODE                   ; FE89  AD A8 1C
        beq  PKM                    ; FE8C  F0 0C
        lda  #$FF                   ; FE8E  A9 FF
        sta  NM0                    ; FE90  8D F3 1F
        sta  NM1                    ; FE93  8D F4 1F
        sta  NM2                    ; FE96  8D F5 1F
        rts                         ; FE99  60
PKM:
        lda  M0                     ; FE9A  AD F0 1F
        eor  #$FF                   ; FE9D  49 FF
        ora  #$80                   ; FE9F  09 80
        sta  NM0                    ; FEA1  8D F3 1F
        lda  M1                     ; FEA4  AD F1 1F
        eor  #$FF                   ; FEA7  49 FF
        ora  #$80                   ; FEA9  09 80
        sta  NM1                    ; FEAB  8D F4 1F
        lda  M2                     ; FEAE  AD F2 1F
        eor  #$FF                   ; FEB1  49 FF
        ora  #$80                   ; FEB3  09 80
        sta  NM2                    ; FEB5  8D F5 1F
        rts                         ; FEB8  60
MUL24:
        sta  TMP                    ; FEB9  8D 8A 1C
        lda  #$00                   ; FEBC  A9 00
        sta  SUMHI                  ; FEBE  8D 8C 1C
        lda  TMP                    ; FEC1  AD 8A 1C
        asl  a                      ; FEC4  0A
        rol  SUMHI                  ; FEC5  2E 8C 1C
        asl  a                      ; FEC8  0A
        rol  SUMHI                  ; FEC9  2E 8C 1C
        asl  a                      ; FECC  0A
        rol  SUMHI                  ; FECD  2E 8C 1C
        sta  SUMLO                  ; FED0  8D 8B 1C
        lda  SUMHI                  ; FED3  AD 8C 1C
        sta  IDX                    ; FED6  8D 8D 1C
        lda  SUMLO                  ; FED9  AD 8B 1C
        asl  a                      ; FEDC  0A
        rol  SUMHI                  ; FEDD  2E 8C 1C
        clc                         ; FEE0  18
        adc  SUMLO                  ; FEE1  6D 8B 1C
        sta  SUMLO                  ; FEE4  8D 8B 1C
        lda  SUMHI                  ; FEE7  AD 8C 1C
        adc  IDX                    ; FEEA  6D 8D 1C
        sta  SUMHI                  ; FEED  8D 8C 1C
        rts                         ; FEF0  60
KOFILL:
        lda  JONGI                  ; FEF1  AD A2 94
        sta  T                      ; FEF4  8D 88 1C
        ldy  JUNGI                  ; FEF7  AC A1 94
        lda  CLASS,y                ; FEFA  B9 E6 D7
        sta  CL                     ; FEFD  8D 89 1C
        lda  T                      ; FF00  AD 88 1C
        beq  NO3                    ; FF03  F0 09
        lda  CL                     ; FF05  AD 89 1C
        clc                         ; FF08  18
        adc  #$03                   ; FF09  69 03
        sta  CL                     ; FF0B  8D 89 1C
NO3:
        lda  CHOI                   ; FF0E  AD A0 94
        beq  ZCHO                   ; FF11  F0 2B
        cmp  #$14                   ; FF13  C9 14
        bcs  ZCHO                   ; FF15  B0 27
        sec                         ; FF17  38
        sbc  #$01                   ; FF18  E9 01
        sta  C                      ; FF1A  8D 86 1C
        ldx  CL                     ; FF1D  AE 89 1C
        lda  MUL19,x                ; FF20  BD E0 D7
        clc                         ; FF23  18
        adc  C                      ; FF24  6D 86 1C
        jsr  MUL24                  ; FF27  20 B9 FE
        lda  SUMLO                  ; FF2A  AD 8B 1C
        clc                         ; FF2D  18
        adc  #$00                   ; FF2E  69 00
        sta  a:P0L                  ; FF30  8D 00 00
        lda  SUMHI                  ; FF33  AD 8C 1C
        adc  #$08                   ; FF36  69 08
        sta  a:P0H                  ; FF38  8D 01 00
        jmp  CHOD                   ; FF3B  4C 48 FF
ZCHO:
        lda  #$28                   ; FF3E  A9 28
        sta  a:P0L                  ; FF40  8D 00 00
        lda  #$19                   ; FF43  A9 19
        sta  a:P0H                  ; FF45  8D 01 00
CHOD:
        lda  JUNGI                  ; FF48  AD A1 94
        beq  ZJU                    ; FF4B  F0 2E
        cmp  #$16                   ; FF4D  C9 16
        bcs  ZJU                    ; FF4F  B0 2A
        sec                         ; FF51  38
        sbc  #$01                   ; FF52  E9 01
        sta  V                      ; FF54  8D 87 1C
        lda  #$00                   ; FF57  A9 00
        ldx  T                      ; FF59  AE 88 1C
        beq  JB                     ; FF5C  F0 02
        lda  #$15                   ; FF5E  A9 15
JB:
        clc                         ; FF60  18
        adc  V                      ; FF61  6D 87 1C
        jsr  MUL24                  ; FF64  20 B9 FE
        lda  SUMLO                  ; FF67  AD 8B 1C
        clc                         ; FF6A  18
        adc  #$B0                   ; FF6B  69 B0
        sta  a:P1L                  ; FF6D  8D 02 00
        lda  SUMHI                  ; FF70  AD 8C 1C
        adc  #$12                   ; FF73  69 12
        sta  a:P1H                  ; FF75  8D 03 00
        jmp  JUD                    ; FF78  4C 85 FF
ZJU:
        lda  #$28                   ; FF7B  A9 28
        sta  a:P1L                  ; FF7D  8D 02 00
        lda  #$19                   ; FF80  A9 19
        sta  a:P1H                  ; FF82  8D 03 00
JUD:
        lda  T                      ; FF85  AD 88 1C
        beq  ZJ                     ; FF88  F0 1E
        cmp  #$1C                   ; FF8A  C9 1C
        bcs  ZJ                     ; FF8C  B0 1A
        sec                         ; FF8E  38
        sbc  #$01                   ; FF8F  E9 01
        jsr  MUL24                  ; FF91  20 B9 FE
        lda  SUMLO                  ; FF94  AD 8B 1C
        clc                         ; FF97  18
        adc  #$A0                   ; FF98  69 A0
        sta  a:P2L                  ; FF9A  8D 04 00
        lda  SUMHI                  ; FF9D  AD 8C 1C
        adc  #$16                   ; FFA0  69 16
        sta  a:P2H                  ; FFA2  8D 05 00
        jmp  ORL                    ; FFA5  4C B2 FF
ZJ:
        lda  #$28                   ; FFA8  A9 28
        sta  a:P2L                  ; FFAA  8D 04 00
        lda  #$19                   ; FFAD  A9 19
        sta  a:P2H                  ; FFAF  8D 05 00
ORL:
        ldx  #$00                   ; FFB2  A2 00
        ldy  #$00                   ; FFB4  A0 00
OL:
        lda  (P0L),y                ; FFB6  B1 00
        ora  (P1L),y                ; FFB8  11 02
        ora  (P2L),y                ; FFBA  11 04
        sta  GLY,x                  ; FFBC  9D 90 1C
        iny                         ; FFBF  C8
        lda  (P0L),y                ; FFC0  B1 00
        ora  (P1L),y                ; FFC2  11 02
        ora  (P2L),y                ; FFC4  11 04
        sta  GLYHI,x                ; FFC6  9D 9C 1C
        iny                         ; FFC9  C8
        inx                         ; FFCA  E8
        cpx  #$0C                   ; FFCB  E0 0C
        bne  OL                     ; FFCD  D0 E7
        rts                         ; FFCF  60
FASTMUL:
        cpy  #$08                   ; FFD0  C0 08
        bne  FM1                    ; FFD2  D0 1A
        sta  P2L                    ; FFD4  85 04
        lsr  a                      ; FFD6  4A
        lsr  a                      ; FFD7  4A
        lsr  a                      ; FFD8  4A
        lsr  a                      ; FFD9  4A
        lsr  a                      ; FFDA  4A
        sta  P2H                    ; FFDB  85 05
        lda  P2L                    ; FFDD  A5 04
        asl  a                      ; FFDF  0A
        asl  a                      ; FFE0  0A
        asl  a                      ; FFE1  0A
        clc                         ; FFE2  18
        adc  P0L                    ; FFE3  65 00
        sta  P0L                    ; FFE5  85 00
        lda  P2H                    ; FFE7  A5 05
        adc  P0H                    ; FFE9  65 01
        sta  P0H                    ; FFEB  85 01
        rts                         ; FFED  60
FM1:
        sta  P2L                    ; FFEE  85 04
        sty  P2H                    ; FFF0  84 05
        jmp  L_F2E1                 ; FFF2  4C E1 F2

.segment "BANNER"
BN:
        lda  #$00                   ; 1CC0  A9 00
        sta  HMODE                  ; 1CC2  8D AC 94
        sta  PENDING                ; 1CC5  8D AE 94
        sta  S_07DA                 ; 1CC8  8D 7B 95
        sta  $0400                  ; 1CCB  8D 00 04
        jsr  BLINE                  ; 1CCE  20 60 1D
        jsr  BFREE                  ; 1CD1  20 73 1E
        jsr  BTAIL                  ; 1CD4  20 FD 1D
        lda  a:$0074                ; 1CD7  AD 74 00
        jsr  BHEX                   ; 1CDA  20 58 1E
        lda  a:HIMEMZ               ; 1CDD  AD 73 00
        jsr  BHEX                   ; 1CE0  20 58 1E
        lda  a:HIMEMZ               ; 1CE3  AD 73 00
        sta  NUM                    ; 1CE6  8D D8 1E
        lda  a:$0074                ; 1CE9  AD 74 00
        sta  NUMHI                  ; 1CEC  8D D9 1E
        jsr  BPAR                   ; 1CEF  20 86 1E
        jsr  BLOM                   ; 1CF2  20 2E 1E
        lda  a:$006A                ; 1CF5  AD 6A 00
        jsr  BHEX                   ; 1CF8  20 58 1E
        lda  a:VARTAB               ; 1CFB  AD 69 00
        jsr  BHEX                   ; 1CFE  20 58 1E
        lda  a:VARTAB               ; 1D01  AD 69 00
        sta  NUM                    ; 1D04  8D D8 1E
        lda  a:$006A                ; 1D07  AD 6A 00
        sta  NUMHI                  ; 1D0A  8D D9 1E
        jsr  BPAR                   ; 1D0D  20 86 1E
        lda  #$0D                   ; 1D10  A9 0D
        jsr  BEMIT                  ; 1D12  20 2B 1D
        lda  #$FF                   ; 1D15  A9 FF
        sta  a:$0075                ; 1D17  8D 75 00
        sta  a:$0076                ; 1D1A  8D 76 00
        lda  #$00                   ; 1D1D  A9 00
        sta  a:$00B8                ; 1D1F  8D B8 00
        lda  #$40                   ; 1D22  A9 40
        sta  a:$00B9                ; 1D24  8D B9 00
        sta  LCROMRD                ; 1D27  8D 82 C0
        rts                         ; 1D2A  60
BEMIT:
        ora  #$80                   ; 1D2B  09 80
        stx  BTMPX                  ; 1D2D  8E DF 1E
        sty  BTMPY                  ; 1D30  8C E0 1E
        jsr  S_045A                 ; 1D33  20 0A 94
        ldx  BTMPX                  ; 1D36  AE DF 1E
        ldy  BTMPY                  ; 1D39  AC E0 1E
        rts                         ; 1D3C  60
BHANG:
        stx  BTMPX                  ; 1D3D  8E DF 1E
        sta  HOLD                   ; 1D40  8D E2 1E
        sty  BTMPY                  ; 1D43  8C E0 1E
        sta  LCRAMRD                ; 1D46  8D 80 C0
        ldx  #$00                   ; 1D49  A2 00
        lda  HOLD                   ; 1D4B  AD E2 1E
        jsr  PLOT2                  ; 1D4E  20 16 F1
        ldx  #$00                   ; 1D51  A2 00
        lda  BTMPX                  ; 1D53  AD DF 1E
        jsr  PLOT2                  ; 1D56  20 16 F1
        sta  LCROMRD                ; 1D59  8D 82 C0
        ldy  BTMPY                  ; 1D5C  AC E0 1E
        rts                         ; 1D5F  60
BLINE:
        ldy  #$00                   ; 1D60  A0 00
BLINEL:
        lda  BLINES,y               ; 1D62  B9 81 1D
        beq  BLINEX                 ; 1D65  F0 19
        bpl  BLINEA                 ; 1D67  10 11
        sta  HOLD                   ; 1D69  8D E2 1E
        iny                         ; 1D6C  C8
        lda  BLINES,y               ; 1D6D  B9 81 1D
        tax                         ; 1D70  AA
        lda  HOLD                   ; 1D71  AD E2 1E
        jsr  BHANG                  ; 1D74  20 3D 1D
        jmp  BLINEN                 ; 1D77  4C 7D 1D
BLINEA:
        jsr  BEMIT                  ; 1D7A  20 2B 1D
BLINEN:
        iny                         ; 1D7D  C8
        bne  BLINEL                 ; 1D7E  D0 E2
BLINEX:
        rts                         ; 1D80  60
BLINES:
; the first lines of the banner (before the free memory): johab pairs for Hangul, ASCII otherwise, $0D between lines
        .byte $C4,$81,$CF,$69,$D0,$65,$8B,$69,$20,$76,$31,$2E,$30,$62,$20,$32
        .byte $30,$32,$36,$91,$65,$20,$28,$D0,$65,$8B,$69,$32,$20,$AE,$81,$B8
        .byte $F7,$A4,$E1,$B8,$E5,$29,$0D,$24,$44,$30,$30,$30,$20,$A4,$E5,$BB
        .byte $A1,$20,$9C,$97,$8A,$E1,$BB,$A1,$20,$C4,$61,$97,$61,$B5,$41,$20
        .byte $9D,$A1,$97,$61,$96,$51,$0D,$97,$A1,$AF,$61,$CF,$69,$9D,$41,$B7
        .byte $A1,$B6,$77,$B7,$61,$9D,$A1,$20,$48,$47,$52,$31,$20,$AC,$61,$B6
        .byte $77,$0D
; the screen size: English 6x10, 46 columns by 16 rows; Hangul 12x12, 23 columns by 16 rows
        .byte $B5,$77,$A2,$85,$28,$36,$78,$31,$30,$29,$3A,$20,$34,$36,$B5,$69
        .byte $31,$36,$D0,$97,$2C,$20,$D0,$65,$8B,$69,$28,$31,$32,$78,$31,$32
        .byte $29,$3A,$20,$32,$33,$B5,$69,$31,$36,$D0,$97,$0D
        .byte $B4,$81,$CF,$69,$AD,$A1,$CF,$61,$CB,$61,$20,$A5,$41,$B7
        .byte $A1,$BB,$A2,$20,$B5,$61,$B7,$41,$20,$A1,$41,$A1,$A1,$9F,$A1,$20
        .byte $00
BTAILS:
; after the free-memory number
        .byte $20,$A4,$61,$B7,$A1,$CB,$61,$0D,$48,$49,$4D,$45,$4D,$20,$24,$00
BLOMS:
; after the HIMEM line
        .byte $20,$4C,$4F,$4D,$45,$4D,$20,$24,$00
; the three banner strings share the BLINE loop: the entries start at their offsets in the table
BTAIL:
        ldy  #<(BTAILS-BLINES)
        jmp  BLINEL
BLOM:
        ldy  #<(BLOMS-BLINES)
        jmp  BLINEL
BHEX:
        sta  HNIB                   ; 1E58  8D E1 1E
        lsr  a                      ; 1E5B  4A
        lsr  a                      ; 1E5C  4A
        lsr  a                      ; 1E5D  4A
        lsr  a                      ; 1E5E  4A
        jsr  BNIB                   ; 1E5F  20 67 1E
        lda  HNIB                   ; 1E62  AD E1 1E
        and  #$0F                   ; 1E65  29 0F
BNIB:
        cmp  #$0A                   ; 1E67  C9 0A
        bcc  BN1                    ; 1E69  90 02
        adc  #$06                   ; 1E6B  69 06
BN1:
        adc  #$30                   ; 1E6D  69 30
        jsr  BEMIT                  ; 1E6F  20 2B 1D
        rts                         ; 1E72  60
BFREE:
        sec                         ; 1E73  38
        lda  #$00                   ; 1E74  A9 00
        sbc  VARTAB                 ; 1E76  E5 69
        sta  NUM                    ; 1E78  8D D8 1E
        lda  #$94                   ; 1E7B  A9 94
        sbc  $6A                    ; 1E7D  E5 6A
        sta  NUMHI                  ; 1E7F  8D D9 1E
        jsr  BDEC                   ; 1E82  20 99 1E
        rts                         ; 1E85  60
BPAR:
        lda  #$20                   ; 1E86  A9 20
        jsr  BEMIT                  ; 1E88  20 2B 1D
        lda  #$28                   ; 1E8B  A9 28
        jsr  BEMIT                  ; 1E8D  20 2B 1D
        jsr  BDEC                   ; 1E90  20 99 1E
        lda  #$29                   ; 1E93  A9 29
        jsr  BEMIT                  ; 1E95  20 2B 1D
        rts                         ; 1E98  60
BDEC:
        ldx  #$04                   ; 1E99  A2 04
BDIVS:
        jsr  BDIV                   ; 1E9B  20 C0 1E
        sta  DIG,x                  ; 1E9E  9D DA 1E
        dex                         ; 1EA1  CA
        bpl  BDIVS                  ; 1EA2  10 F7
        ldx  #$00                   ; 1EA4  A2 00
BPR:
        lda  DIG,x                  ; 1EA6  BD DA 1E
        bne  BDIG                   ; 1EA9  D0 07
        cpx  #$04                   ; 1EAB  E0 04
        beq  BDIG                   ; 1EAD  F0 03
        inx                         ; 1EAF  E8
        bne  BPR                    ; 1EB0  D0 F4
BDIG:
        lda  DIG,x                  ; 1EB2  BD DA 1E
        ora  #$30                   ; 1EB5  09 30
        jsr  BEMIT                  ; 1EB7  20 2B 1D
        inx                         ; 1EBA  E8
        cpx  #$05                   ; 1EBB  E0 05
        bne  BDIG                   ; 1EBD  D0 F3
        rts                         ; 1EBF  60
BDIV:
        ldy  #$10                   ; 1EC0  A0 10
        lda  #$00                   ; 1EC2  A9 00
BD1:
        asl  NUM                    ; 1EC4  0E D8 1E
        rol  NUMHI                  ; 1EC7  2E D9 1E
        rol  a                      ; 1ECA  2A
        cmp  #$0A                   ; 1ECB  C9 0A
        bcc  BD2                    ; 1ECD  90 05
        sbc  #$0A                   ; 1ECF  E9 0A
        inc  NUM                    ; 1ED1  EE D8 1E
BD2:
        dey                         ; 1ED4  88
        bne  BD1                    ; 1ED5  D0 ED
        rts                         ; 1ED7  60
NUM:
        .byte $00                   ; 1ED8
NUMHI:
        .byte $00                   ; 1ED9
DIG:
        .byte $00,$00,$00,$00,$00   ; 1EDA
BTMPX:
        .byte $00                   ; 1EDF
BTMPY:
        .byte $00                   ; 1EE0
HNIB:
        .byte $00                   ; 1EE1
HOLD:
        .byte $00                   ; 1EE2
CHECK:
        lda  NOPR                   ; 1EE3  AD FB 1F
        bne  CKX                    ; 1EE6  D0 3F
        lda  PROMPTCH               ; INPUT's prompt character is $80: its answer starts right after the text
        cmp  #$80                   ; BASIC printed, so draw no "]" (direct mode has $DD here)
        beq  CKX
        ldy  #$00                   ; 1EE8  A0 00
        lda  (BASL),y               ; 1EEA  B1 28
        and  #$7F                   ; 1EEC  29 7F
        cmp  #$21                   ; 1EEE  C9 21
        bcs  CKX                    ; 1EF0  B0 35
        cmp  #$20                   ; 1EF2  C9 20
        bne  CKN                    ; 1EF4  D0 06
        lda  CH                     ; 1EF6  A5 24
        bne  CKX                    ; 1EF8  D0 2D
        beq  CKP                    ; 1EFA  F0 0A
CKN:
        lda  CH                     ; 1EFC  A5 24
        cmp  #$02                   ; 1EFE  C9 02
        bcs  CKX                    ; 1F00  B0 25
        lda  #$00                   ; 1F02  A9 00
        sta  CH                     ; 1F04  85 24
CKP:
        lda  HMODE                  ; 1F06  AD AC 94
        pha                         ; 1F09  48
        lda  #$00                   ; 1F0A  A9 00
        sta  HMODE                  ; 1F0C  8D AC 94
        txa                         ; 1F0F  8A
        pha                         ; 1F10  48
        tya                         ; 1F11  98
        pha                         ; 1F12  48
        lda  #$DD                   ; 1F13  A9 DD
        sta  PROMPTCH               ; 1F15  85 33
        lda  #$5D                   ; 1F17  A9 5D
        sta  CHAR                   ; 1F19  8D AD 94
        jsr  DISP                   ; 1F1C  20 AA EE
        pla                         ; 1F1F  68
        tay                         ; 1F20  A8
        pla                         ; 1F21  68
        tax                         ; 1F22  AA
        pla                         ; 1F23  68
        sta  HMODE                  ; 1F24  8D AC 94
CKX:
        rts                         ; 1F27  60
DRAWPR:
        jsr  CHECK                  ; 1F28  20 E3 1E
        sec                         ; 1F2B  38
        rol  S_0554                 ; 1F2C  2E 54 05
        rts                         ; 1F2F  60
WRAP:
        jsr  CHECK                  ; 1F30  20 E3 1E
        jmp  L_EB98                 ; 1F33  4C 98 EB
CATWAIT:
        lda  #$01                   ; 1F36  A9 01
        sta  NOPR                   ; 1F38  8D FB 1F
        jsr  L_FD0C                 ; 1F3B  20 0C FD
        pha                         ; 1F3E  48
        lda  #$00                   ; 1F3F  A9 00
        sta  NOPR                   ; 1F41  8D FB 1F
        pla                         ; 1F44  68
        rts                         ; 1F45  60
CATINIT:
        sec                         ; 1F46  38
        lda  WNDBTM                 ; 1F47  A5 23
        sbc  CV                     ; 1F49  E5 25
        bcc  CIF                    ; 1F4B  90 08
        cmp  #$02                   ; 1F4D  C9 02
        bcc  CIF                    ; 1F4F  90 04
        sbc  #$01                   ; 1F51  E9 01
        bne  CIS                    ; 1F53  D0 05
CIF:
        sec                         ; 1F55  38
        lda  WNDBTM                 ; 1F56  A5 23
        sbc  #$01                   ; 1F58  E9 01
CIS:
        sta  $B39D                  ; 1F5A  8D 9D B3
        rts                         ; 1F5D  60
RELOC:
        lda  #$00                   ; 1F5E  A9 00
        sta  $06                    ; 1F60  85 06
        lda  #$60                   ; 1F62  A9 60
        sta  $07                    ; 1F64  85 07
        lda  #$00                   ; 1F66  A9 00
        sta  $08                    ; 1F68  85 08
        lda  #$08                   ; 1F6A  A9 08
        sta  $09                    ; 1F6C  85 09
        lda  #$6A                   ; 1F6E  A9 6A
        sta  $1C80                  ; 1F70  8D 80 1C
        lda  #$11                   ; 1F73  A9 11
        sta  $1C81                  ; 1F75  8D 81 1C
        ldy  #$00                   ; 1F78  A0 00
FCP:
        lda  ($06),y                ; 1F7A  B1 06
        sta  ($08),y                ; 1F7C  91 08
        iny                         ; 1F7E  C8
        bne  FCPN                   ; 1F7F  D0 04
        inc  $07                    ; 1F81  E6 07
        inc  $09                    ; 1F83  E6 09
FCPN:
        lda  $1C80                  ; 1F85  AD 80 1C
        bne  FCD                    ; 1F88  D0 03
        dec  $1C81                  ; 1F8A  CE 81 1C
FCD:
        dec  $1C80                  ; 1F8D  CE 80 1C
        lda  $1C80                  ; 1F90  AD 80 1C
        ora  $1C81                  ; 1F93  0D 81 1C
        bne  FCP                    ; 1F96  D0 E2
        lda  #$00                   ; 1F98  A9 00
        sta  $4000                  ; 1F9A  8D 00 40
        sta  $4001                  ; 1F9D  8D 01 40
        sta  $4002                  ; 1FA0  8D 02 40
        lda  #$01                   ; 1FA3  A9 01
        sta  TXTTAB                 ; 1FA5  85 67
        lda  #$40                   ; 1FA7  A9 40
        sta  $68                    ; 1FA9  85 68
        lda  #$03                   ; 1FAB  A9 03
        sta  VARTAB                 ; 1FAD  85 69
        sta  $6B                    ; 1FAF  85 6B
        sta  $6D                    ; 1FB1  85 6D
        sta  $AF                    ; 1FB3  85 AF
        lda  #$40                   ; 1FB5  A9 40
        sta  $6A                    ; 1FB7  85 6A
        sta  $6C                    ; 1FB9  85 6C
        sta  $6E                    ; 1FBB  85 6E
        sta  $B0                    ; 1FBD  85 B0
        rts                         ; 1FBF  60

; ---------------------------------------------------------------------------
; The HAN command: start the driver again (after Ctrl-Reset, PR#0 or IN#0). It must be in main RAM,
; because the banner stub switches the language card off before it returns. Fill the state, then run
; the stock init (hooks, window, hi-res screen, banner). The init registers the driver's input and
; output routines with DOS ($AA53-$AA56) itself.
; ---------------------------------------------------------------------------
HANMAIN:
        sta  LCRAMRD                ; $C080: language card RAM read
        jsr  STATEINIT
        rts
