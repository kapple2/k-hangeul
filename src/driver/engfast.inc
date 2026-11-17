; ===========================================================================
; engfast.inc: the fast English draw, in the second 4K bank ($D000) of the 16K language card.
; Included by driver.s into segment LCB1 (run address $D000, loaded by the loader into bank 1 on a plain card).
;
; The font itself is in bank 2 ($D860 and up), which bank-1 code cannot see: ENBLIT (in $E000+) first copies the 10 font rows
; of the glyph to GLY..GLY+9 (main RAM), and ENGFAST reads them from there.
;
; Why a second bank: the first bank ($D000-$FFFF, bank 2 in card terms) has 5 free bytes. Bank 1 is not used by anything
; else. The driver runs with bank 2 read ($C080); ENBLIT (in $E000+, which both banks share) switches to bank 1
; ($C088), calls ENGFAST, and switches back. Bank-1 code can call only what is in $E000-$FFFF or in main RAM.
; (SETUPX, MUL12, HGRLO and HGRHI are in $E000+.)
;
; What it does: draws one English character (6x10 font, 6 pixels wide) at the cursor, the same pixels as the old path
; (ENBLIT building GLY, then BLIT). It is faster because
;   - the glyph is not expanded to 12 rows of 16 bits first (and BLIT's loop over the rows is not used),
;   - the shift to the pixel position is a table lookup (B0_k, B1_k: the glyph row shifted left by k, as the two screen
;     bytes it falls into) instead of a loop of 3-byte shifts, and each k has its own loop with constant masks,
;   - the screen address of each pixel line comes from the HGRLO/HGRHI tables.
; It does the ordinary case only. If the screen is the STYPE strip buffer (STRIPF), or overstrike (S_06AF bit 7), or
; underline (S_06B0) is on, it does the old thing in bank 1 (builds GLY) and returns with carry set: ENBLIT then jumps
; to BLIT as before. Carry clear on return = the character is drawn.
; Inverse (S_066B) is done here: the glyph rows are eored with $3F, rows 0 and 1 (blank) become $3F.
; SETUPX (a divide-by-7 loop, 150 cycles) is replaced by two 46-byte tables, COLK and COLB.
; Variables: ELINE = ROWI ($1FF8), EINV = IXL ($1FF9): the old blit's own bytes, free while this runs.
; ===========================================================================
ELINE = ROWI
EINV  = IXL

ENGFAST:
        bit  STRIPF
        bvs  @slow
        bit  S_06AF
        bmi  @slow
        lda  S_06B0
        bne  @slow
        ldy  CH                     ; the same as SETUPX (x = CH * 6; BOFF = x / 7, P1H = x mod 7), by table: no divide loop
        cpy  #$2E
        bcs  @slow                  ; (a column beyond the 46: the old way)
        lda  COLK,y
        sta  P1H                    ; the bit offset k (0-6)
        lda  COLB,y
        sta  BOFF                   ; the byte offset
        lda  CV
        jsr  MUL12
        clc
        adc  S_06AE
        sta  ELINE                  ; the first of the 12 pixel lines
        ldx  #$00
        lda  S_066B
        beq  @ni
        ldx  #$3F                   ; inverse
@ni:    stx  EINV
        cpx  #$00
        bne  @go                    ; inverse: the ordinary way
        lda  CHAR                   ; a space (not inverse): every row is blank, so there is nothing to build: GLY and GLYHI
        and  #$7F                   ; are zeros and the draw goes straight to its 12-line loop (ENGBk), which clears the cell
        cmp  #$20
        bne  @go
        ldx  #$0B
        lda  #$00
@z:     sta  GLY,x
        sta  GLYHI,x
        dex
        bpl  @z
        ldx  P1H
        lda  EBL,x
        sta  $06
        lda  EBH,x
        sta  $07
        jmp  ($0006)
@go:    ldx  P1H
        lda  EDL,x
        sta  $06
        lda  EDH,x
        sta  $07
        jmp  ($0006)
; the old ENBLIT: build the 12 rows of GLY (rows 0 and 1 blank, then the 10 font rows, which ENBLIT put in GLY..GLY+9).
; From the last row to the first, so that a row is made before its font byte is overwritten.
@slow:  ldx  #$0B
@el:    lda  #$00
        sta  GLYHI,x
        cpx  #$02
        bcc  @es2
        lda  GLY-2,x
        cpx  #$0B
        bne  @es
        ora  S_06B0
@es:    and  #$3F
@es2:   sta  GLY,x
        dex
        bpl  @el
        lda  #$06
        sta  P1L
        sec
        rts

; one draw routine for the shift K (the glyph moves K pixels to the left in the 7-pixel screen bytes)
.macro ENGK K
.ident(.sprintf("ENGK%d", K)):
        ldy  #$09                   ; the 10 font rows (GLY..GLY+9) go to GLY+2.. (low byte) and GLYHI+2.. (high byte), shifted
:       lda  GLY,y
        and  #$3F
        eor  EINV
        tax
        lda  .ident(.sprintf("B0_%d", K)),x
        sta  GLY+2,y
.if (($3F << K) >> 7) <> 0
        lda  .ident(.sprintf("B1_%d", K)),x
        sta  GLYHI+2,y
.endif
        dey
        bpl  :-
        ldx  EINV                   ; the two blank rows (all ones when inverse)
        lda  .ident(.sprintf("B0_%d", K)),x
        sta  GLY
        sta  GLY+1
.if (($3F << K) >> 7) <> 0
        lda  .ident(.sprintf("B1_%d", K)),x
        sta  GLYHI
        sta  GLYHI+1
.endif
.ident(.sprintf("ENGB%d", K)):
        ldx  #$00                   ; the 12 pixel lines
:       ldy  ELINE
        lda  HGRLO,y
        clc
        adc  BOFF
        sta  $26
        lda  HGRHI,y
        adc  #$00
        ora  $E6
        sta  $27
        ldy  #$00
        lda  ($26),y
        and  #(((~(($3F << K) & $7F)) | $80) & $FF)
        ora  GLY,x
        sta  ($26),y
.if (($3F << K) >> 7) <> 0
        iny
        lda  ($26),y
        and  #(((~(($3F << K) >> 7)) | $80) & $FF)
        ora  GLYHI,x
        sta  ($26),y
.endif
        inc  ELINE
        inx
        cpx  #$0C
        bne  :-
        clc
        rts
.endmacro

        ENGK 0
        ENGK 1
        ENGK 2
        ENGK 3
        ENGK 4
        ENGK 5
        ENGK 6

COLK:
.repeat 46, C
        .byte (C * 6) - ((C * 6) / 7) * 7
.endrepeat
COLB:
.repeat 46, C
        .byte (C * 6) / 7
.endrepeat

EBL:    .byte <ENGB0, <ENGB1, <ENGB2, <ENGB3, <ENGB4, <ENGB5, <ENGB6
EBH:    .byte >ENGB0, >ENGB1, >ENGB2, >ENGB3, >ENGB4, >ENGB5, >ENGB6
EDL:    .byte <ENGK0, <ENGK1, <ENGK2, <ENGK3, <ENGK4, <ENGK5, <ENGK6
EDH:    .byte >ENGK0, >ENGK1, >ENGK2, >ENGK3, >ENGK4, >ENGK5, >ENGK6

; ===========================================================================
; HANFAST: the fast Hangul draw, in the same bank. Called by KOFAST (in ENBLIT's spare bytes, $E000+) in place of
; KOFILL + BLIT. Carry set on return = it did not draw (strip buffer, overstrike, a column beyond 45, a vowel code beyond 21):
; KOFAST then does the old KOBLIT.
;
; The old way: KOFILL finds the three jamo glyphs (initial, vowel, final: 12 rows of 12 bits each, in the font at $0800+),
; ORs them into GLY/GLYHI (OL), BLIT shifts each row with a bit loop, three bytes a row, with SETUPX's divide loop first.
; Here: the same three glyphs (the same arithmetic as KOFILL, ca. 24 * index by shifts), ORed and eored for inverse, split
; into a 6-bit low part L and a 6-bit high part H of the 12-bit row (V = H * 64 + L), and then V << k comes from tables:
; (L << k) is B0_k and B1_k, the English tables of engfast.inc, and (H << (k + 6)) is HB0 (k = 0 only), HB1_k and HB2_k
; (k >= 3), added by OR (the bit positions do not overlap). One draw routine for each pixel offset k, with constant masks.
; Variables: GLY = L of each row, GLYHI = H of each row (12 bytes each); ELINE = ROWI; EIL, EIH = IXL, IXH (the xor mask of
; the row: 0 or $FF / $0F); EK = TV (the offset k); HT0-HT2 = M0-M2 (the bytes of one row).
; ===========================================================================
EIL = IXL
EIH = IXH
EK  = TV
HT0 = M0
HT1 = M1
HT2 = M2

HANFAST:
        jmp  @go
@no:    sec
        rts
@go:    bit  STRIPF
        bvs  @no
        bit  S_06AF
        bmi  @no
        ldy  CH
        cpy  #$2E
        bcs  @no
        lda  COLK,y
        sta  EK
        lda  COLB,y
        sta  BOFF
        ldy  JUNGI
        cpy  #$16
        bcs  @no
        lda  CLS,y                  ; the class of the vowel (+ 3 when there is a final) picks the initial glyph set
        ldx  JONGI
        stx  T
        beq  @c1
        clc
        adc  #$03
@c1:    sta  CL
        lda  CV                     ; the first pixel line
        jsr  MUL12
        clc
        adc  S_06AE
        sta  ELINE
        ldx  #$00                   ; inverse: the 12 bits of every row are eored
        ldy  #$00
        lda  S_066B
        beq  @ni
        ldx  #$FF
        ldy  #$0F
@ni:    stx  EIL
        sty  EIH
; ---- the three glyph addresses: P0 initial, P1 vowel, P2 final (the same choices as KOFILL)
        lda  CHOI
        beq  @zi
        cmp  #$14
        bcs  @zi
        sec
        sbc  #$01
        ldx  CL
        clc
        adc  M19,x
        jsr  M24
        lda  SUMLO
        sta  P0L
        lda  SUMHI
        clc
        adc  #>FCHOB
        sta  P0H
        jmp  @v
@zi:    lda  #<FZEROG
        sta  P0L
        lda  #>FZEROG
        sta  P0H
@v:     lda  JUNGI
        beq  @zv
        sec
        sbc  #$01
        ldx  T
        beq  @v1
        clc
        adc  #$15
@v1:    jsr  M24
        lda  SUMLO
        clc
        adc  #<FJUNGB
        sta  P1L
        lda  SUMHI
        adc  #>FJUNGB
        sta  P1H
        jmp  @f
@zv:    lda  #<FZEROG
        sta  P1L
        lda  #>FZEROG
        sta  P1H
@f:     lda  T
        beq  @zf
        cmp  #$1C
        bcs  @zf
        sec
        sbc  #$01
        jsr  M24
        lda  SUMLO
        clc
        adc  #<FJONGB
        sta  P2L
        lda  SUMHI
        adc  #>FJONGB
        sta  P2H
        jmp  @a
@zf:    lda  #<FZEROG
        sta  P2L
        lda  #>FZEROG
        sta  P2H
; ---- the 12 rows: OR the three glyphs, split V into L (GLY) and H (GLYHI)
@a:     ldx  #$00
        ldy  #$00
@r:     lda  (P0L),y
        ora  (P1L),y
        ora  (P2L),y
        eor  EIL
        sta  HT0                    ; the low byte of the row
        iny
        lda  (P0L),y
        ora  (P1L),y
        ora  (P2L),y
        eor  EIH
        sta  HT1                    ; the high 4 bits
        iny
        lda  HT0
        asl  a
        rol  HT1
        asl  a
        rol  HT1                    ; HT1 = V >> 6
        lda  HT0
        and  #$3F
        sta  GLY,x                  ; L
        lda  HT1
        sta  GLYHI,x                ; H
        inx
        cpx  #$0C
        bne  @r
        ldx  EK
        lda  HDL,x
        sta  $06
        lda  HDH,x
        sta  $07
        jmp  ($0006)

; SUMLO/SUMHI = A * 24 (A up to 113)
M24:    sta  TMP
        lda  #$00
        sta  SUMHI
        lda  TMP
        asl  a
        rol  SUMHI
        asl  a
        rol  SUMHI
        asl  a
        rol  SUMHI                  ; * 8
        sta  SUMLO
        ldy  SUMHI
        asl  a
        rol  SUMHI                  ; * 16
        clc
        adc  SUMLO
        sta  SUMLO
        tya
        adc  SUMHI
        sta  SUMHI
        rts

M19:    .byte $00,$13,$26,$39,$4C,$5F
CLS:
.include "jungclass.inc"            ; the same 22 bytes as CLASS in bank 2

; one draw routine for the shift K
.macro HANK K
.ident(.sprintf("HANK%d", K)):
        ldx  #$00
:       ldy  ELINE
        lda  HGRLO,y
        clc
        adc  BOFF
        sta  $26
        lda  HGRHI,y
        adc  #$00
        ora  $E6
        sta  $27
.if K = 0
        ldy  GLY,x
        lda  B0_0,y
        ldy  GLYHI,x
        ora  HB0,y
        sta  HT0
        lda  HB1_0,y
        sta  HT1
.elseif K = 1
        ldy  GLY,x
        lda  B0_1,y
        sta  HT0
        ldy  GLYHI,x
        lda  HB1_1,y
        sta  HT1
.else
        ldy  GLY,x
        lda  .ident(.sprintf("B0_%d", K)),y
        sta  HT0
        lda  .ident(.sprintf("B1_%d", K)),y
        ldy  GLYHI,x
        ora  .ident(.sprintf("HB1_%d", K)),y
        sta  HT1
.if K >= 3
        lda  .ident(.sprintf("HB2_%d", K)),y
        sta  HT2
.endif
.endif
        ldy  #$00
        lda  ($26),y
        and  #(((~((($FFF << K)) & $7F)) | $80) & $FF)
        ora  HT0
        sta  ($26),y
        iny
        lda  ($26),y
        and  #(((~((($FFF << K) >> 7) & $7F)) | $80) & $FF)
        ora  HT1
        sta  ($26),y
.if K >= 3
        iny
        lda  ($26),y
        and  #(((~(($FFF << K) >> 14)) | $80) & $FF)
        ora  HT2
        sta  ($26),y
.endif
        inc  ELINE
        inx
        cpx  #$0C
        bne  :-
        clc
        rts
.endmacro

        HANK 0
        HANK 1
        HANK 2
        HANK 3
        HANK 4
        HANK 5
        HANK 6

HDL:    .byte <HANK0, <HANK1, <HANK2, <HANK3, <HANK4, <HANK5, <HANK6
HDH:    .byte >HANK0, >HANK1, >HANK2, >HANK3, >HANK4, >HANK5, >HANK6

; ===========================================================================
; PACKF: the packing of a typed or printed Hangul syllable into its two code bytes LEAD and TRAIL (called by PACK, in place
; of its three table scans; PACK in bank 2 then plots LEAD and TRAIL). The stock code scanned the tables D_E2DB (19 initial
; consonants), D_E2EF with D_E305 (21 vowels and their codes) and D_E31B (the final consonants) for the key and used the
; position; here the same tables are indexed by the key. Same result, including for a key that is not in a table (code 1 for
; an initial or final, 2 for a vowel). JONG2 (a second final consonant) is looked for among the 11 pairs of D_E27C/D_E287
; first, and a pair replaces JONG by $B1 + its number. Tables made from the stock ones by a script (python, 2026-11-12):
; if D_E2DB, D_E2EF, D_E305, D_E27C, D_E287 or D_E31B ever change, make these again.
; LEAD = $80 | (initial code << 2) | (vowel code >> 3);  TRAIL = (vowel code << 5) | final code.
; ===========================================================================
PACKF:
        lda  CHO
        sec
        sbc  #$80
        cmp  #$13
        bcs  @c0
        tax
        lda  PCT,x
        bne  @c1
@c0:    lda  #$01
@c1:    asl  a
        asl  a
        ora  #$80
        sta  LEAD
        lda  JUNG
        sec
        sbc  #$93
        cmp  #$15
        bcs  @j0
        tax
        lda  PJT,x
        bne  @j1
@j0:    lda  #$02
@j1:    pha
        lsr  a
        lsr  a
        lsr  a
        ora  LEAD
        sta  LEAD
        pla
        asl  a
        asl  a
        asl  a
        asl  a
        asl  a
        sta  TRAIL
        lda  JONG2
        beq  @g
        ldx  #$0A
@cl:    lda  JONG
        cmp  PCL1,x
        bne  @cn
        lda  JONG2
        cmp  PCL2,x
        beq  @cf
@cn:    dex
        bpl  @cl
        bmi  @g
@cf:    txa
        clc
        adc  #$B1
        sta  JONG
@g:     lda  JONG
        sec
        sbc  #$80
        cmp  #$3C
        bcs  @g0
        tax
        lda  PGT,x
        bne  @g1
@g0:    lda  #$01
@g1:    ora  TRAIL
        sta  TRAIL
        rts

PCT:    .byte $02,$04,$05,$07,$08,$09,$0B,$0D,$0E,$10,$11,$12,$13,$14,$03,$06,$0A,$0C,$0F
PJT:    .byte $0D,$13,$14,$1A,$1B,$03,$05,$07,$0B,$1D,$04,$06,$0A,$0C,$0E,$0F,$12,$15,$16,$17,$1C
PGT:    .byte $02,$05,$08,$09,$11,$13,$15,$17,$18,$19,$1A,$1B,$1C,$1D,$03,$00,$00,$16,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$12,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$06,$07,$0A,$0B,$0C,$0D,$0E,$0F,$10,$14
PCL1:   .byte $80,$81,$81,$83,$83,$83,$83,$83,$83,$83,$85
PCL2:   .byte $86,$88,$8D,$80,$84,$85,$86,$8B,$8C,$8D,$86

; ---------------------------------------------------------------------------------------------------------------
; The shift tables are not in the file: the loader makes them (GenTabs in driver.s), in the part of bank 1 that this
; segment reserves. 64 entries each, for a 6-bit value v (a glyph row of 6 bits, or the low or the high half of a 12-bit row):
;   B0_k  = (v << k) and $7F                  the first screen byte of the glyph row shifted by k
;   B1_k  = (v << k) >> 7                     the second
;   HB1_k = ((v << (k + 6)) >> 7) and $7F     for the high half H of a 12-bit row: H << (k + 6) as screen bytes
;   HB2_k = (v << (k + 6)) >> 14
;   HB0   = (v << 6) and $7F                  (k = 0 only)
; for k = 0-6 in blocks of 256 bytes from TABS: B0_k, B1_k, HB1_k, HB2_k; then HB0. (B1_0, B1_1 and HB2_0-2 are all zeros
; and not used; they are there so that the loader's loop is the same for every k.)
; ---------------------------------------------------------------------------------------------------------------
.assert * - ENGFAST <= TABS - $D000, error, "the code of engfast.inc overlaps its tables"
.segment "LCB1T"
.repeat 7, K
.ident(.sprintf("B0_%d", K)):  .res 64
.ident(.sprintf("B1_%d", K)):  .res 64
.ident(.sprintf("HB1_%d", K)): .res 64
.ident(.sprintf("HB2_%d", K)): .res 64
.endrepeat
HB0:    .res 64
