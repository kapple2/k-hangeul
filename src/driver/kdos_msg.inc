; Korean DOS error messages: the routine and the texts.
; Included twice by driver.s: in the 16K card build (KX = KEXIT, KGUARD = 1) and, for a Saturn card, in the
; BANK6 segment (scope K6: KX = SatLeave1, KGUARD = 0; its KPUTS prints through bank 7's PLOTCH, see kerr6.inc). See docs/DOS_KOREAN_REPORT.md section 9.
KMSGC:                          ; entered from KSTUB (16K) or K6MSG (Saturn) with the card on; X = message number
        jsr  KBACKC                 ; INIT failed (the INIT guard): the patches again
.if KGUARD
        lda  CSWH
        cmp  #$94                   ; DOS's output is not the driver's (PR#n): leave the English text
        beq  @k
        lda  #$A7                   ; go on at $A705, the  tax  that DOS's routine runs after  lda $AA3F,x
        pha
        lda  #$04
        pha
        lda  $AA3F,x
        jmp  KX
@k:
.else
        cpx  #$00                   ; (K6MSG made the same test of DOS's output: this is only reached while it is the driver's)
        bne  @k                     ; message 0 is CR, bell, CR: DOS's own text prints it the same
        lda  $AA3F,x                ; what the  lda $AA3F,x  that K6MSG replaced did
        jmp  KX                     ; leave: the rts goes to $A705, DOS's  tax
@k:     pla                         ; the Korean text takes the place of DOS's: drop the return into DOS's routine
        pla
.endif
        lda  KOFF,x                 ; the text is in KSTR1 (johab pairs): KPUTS prints it
        clc
        adc  #<KSTR1
        sta  KPL
        lda  #>KSTR1
        adc  #0
        sta  KPL+1
        jsr  KPUTS
        jmp  KX                     ; leave (card off), then rts to the caller
.if KGUARD
.include "kdos_johab.inc"             ; (the Saturn card has its own copy of these bytes, put after the code by SatFinish)
.endif
